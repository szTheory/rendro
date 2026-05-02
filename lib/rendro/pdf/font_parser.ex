defmodule Rendro.PDF.FontParser do
  @moduledoc false

  import Bitwise

  @spec parse(binary()) ::
          {:ok,
           %{
             base_font: String.t(),
             units_per_em: pos_integer(),
             ascent: integer(),
             descent: integer(),
             default_width: non_neg_integer(),
             widths: %{non_neg_integer() => non_neg_integer()}
           }}
          | {:error, term()}
  def parse(bytes) when is_binary(bytes) do
    with {:ok, version, num_tables, directory} <- parse_offset_table(bytes),
         :ok <- validate_version(version),
         {:ok, tables} <- parse_table_directory(directory, num_tables, bytes),
         {:ok, head} <- fetch_required_table(tables, "head"),
         {:ok, hhea} <- fetch_required_table(tables, "hhea"),
         {:ok, hmtx} <- fetch_required_table(tables, "hmtx"),
         {:ok, maxp} <- fetch_required_table(tables, "maxp"),
         {:ok, cmap} <- fetch_required_table(tables, "cmap"),
         {:ok, os2} <- fetch_required_table(tables, "OS/2"),
         {:ok, units_per_em} <- parse_units_per_em(head),
         {:ok, {ascent, descent, number_of_h_metrics}} <- parse_hhea(hhea),
         {:ok, num_glyphs} <- parse_maxp(maxp),
         {:ok, widths_by_glyph} <- parse_hmtx(hmtx, number_of_h_metrics, num_glyphs),
         :ok <- parse_embeddability(os2),
         {:ok, codepoint_to_glyph} <- parse_cmap(cmap),
         widths when map_size(widths) > 0 <- build_width_map(codepoint_to_glyph, widths_by_glyph),
         {:ok, base_font} <- parse_base_font_name(tables) do
      {:ok,
       %{
         base_font: base_font,
         units_per_em: units_per_em,
         ascent: ascent,
         descent: descent,
         default_width: default_width(widths, widths_by_glyph),
         widths: widths
       }}
    else
      %{} = widths when map_size(widths) == 0 -> {:error, :missing_character_map}
      {:error, _} = error -> error
      false -> {:error, :non_embeddable_font}
    end
  end

  def parse(_bytes), do: {:error, :unsupported_font_source}

  defp parse_offset_table(
         <<version::binary-size(4), num_tables::16, _search_range::16, _entry_selector::16,
           _range_shift::16, directory::binary>>
       ) do
    {:ok, version, num_tables, directory}
  end

  defp parse_offset_table(_), do: {:error, :unsupported_font_format}

  defp validate_version(<<0, 1, 0, 0>>), do: :ok
  defp validate_version("true"), do: :ok
  defp validate_version("OTTO"), do: {:error, :unsupported_outline_format}
  defp validate_version("ttcf"), do: {:error, :unsupported_font_collection}
  defp validate_version(_), do: {:error, :unsupported_font_format}

  defp parse_table_directory(directory, num_tables, bytes) do
    required_size = num_tables * 16

    if byte_size(directory) < required_size do
      {:error, :unsupported_font_format}
    else
      tables =
        directory
        |> binary_part(0, required_size)
        |> do_parse_table_directory(num_tables, bytes, %{})

      {:ok, tables}
    end
  end

  defp do_parse_table_directory(_directory, 0, _bytes, tables), do: tables

  defp do_parse_table_directory(
         <<tag::binary-size(4), _checksum::32, offset::32, length::32, rest::binary>>,
         remaining,
         bytes,
         tables
       ) do
    table =
      if offset + length <= byte_size(bytes) do
        binary_part(bytes, offset, length)
      else
        :invalid
      end

    do_parse_table_directory(rest, remaining - 1, bytes, Map.put(tables, tag, table))
  end

  defp fetch_required_table(tables, tag) do
    case Map.fetch(tables, tag) do
      {:ok, :invalid} -> {:error, {:invalid_table_range, tag}}
      {:ok, table} -> {:ok, table}
      :error -> {:error, {:missing_required_table, tag}}
    end
  end

  defp parse_units_per_em(<<_::binary-size(18), units_per_em::16, _::binary>>)
       when units_per_em > 0 do
    {:ok, units_per_em}
  end

  defp parse_units_per_em(_), do: {:error, :missing_required_metrics}

  defp parse_hhea(
         <<_version::32, ascent::signed-16, descent::signed-16, _line_gap::signed-16,
           _rest::binary-size(24), number_of_h_metrics::16, _::binary>>
       )
       when number_of_h_metrics > 0 do
    {:ok, {ascent, descent, number_of_h_metrics}}
  end

  defp parse_hhea(_), do: {:error, :missing_required_metrics}

  defp parse_maxp(<<_version::32, num_glyphs::16, _::binary>>) when num_glyphs > 0 do
    {:ok, num_glyphs}
  end

  defp parse_maxp(_), do: {:error, :missing_required_metrics}

  defp parse_hmtx(hmtx, number_of_h_metrics, num_glyphs) do
    required_bytes = number_of_h_metrics * 4

    if byte_size(hmtx) < required_bytes do
      {:error, :missing_required_metrics}
    else
      metrics =
        for <<advance_width::16, _lsb::signed-16 <- binary_part(hmtx, 0, required_bytes)>>,
          do: advance_width

      last_width = List.last(metrics)

      widths =
        metrics
        |> Enum.with_index()
        |> Map.new(fn {width, glyph_id} -> {glyph_id, width} end)
        |> add_trailing_widths(number_of_h_metrics, num_glyphs, last_width)

      {:ok, widths}
    end
  end

  defp add_trailing_widths(widths, number_of_h_metrics, num_glyphs, last_width) do
    if num_glyphs <= number_of_h_metrics do
      widths
    else
      Enum.reduce(number_of_h_metrics..(num_glyphs - 1), widths, fn glyph_id, acc ->
        Map.put(acc, glyph_id, last_width)
      end)
    end
  end

  defp parse_embeddability(
         <<_version::16, _avg_width::signed-16, _weight_class::16, _width_class::16, fs_type::16,
           _::binary>>
       ) do
    if (fs_type &&& 0x0002) == 0, do: :ok, else: {:error, :non_embeddable_font}
  end

  defp parse_embeddability(_), do: {:error, :missing_required_metrics}

  defp parse_cmap(<<0::16, num_tables::16, encoding_records::binary>>) do
    records_size = num_tables * 8

    if byte_size(encoding_records) < records_size do
      {:error, :missing_character_map}
    else
      cmap = <<0::16, num_tables::16, encoding_records::binary>>

      encoding_records
      |> binary_part(0, records_size)
      |> parse_encoding_records([])
      |> Enum.sort_by(&record_priority/1)
      |> Enum.reduce_while({:error, :missing_character_map}, fn record, _acc ->
        case parse_cmap_subtable(cmap, record) do
          {:ok, mapping} when map_size(mapping) > 0 -> {:halt, {:ok, mapping}}
          {:ok, _mapping} -> {:cont, {:error, :missing_character_map}}
          {:error, _reason} = error -> {:cont, error}
        end
      end)
    end
  end

  defp parse_cmap(_), do: {:error, :missing_character_map}

  defp parse_encoding_records(<<>>, acc), do: acc

  defp parse_encoding_records(
         <<platform_id::16, encoding_id::16, offset::32, rest::binary>>,
         acc
       ) do
    parse_encoding_records(rest, [
      %{platform_id: platform_id, encoding_id: encoding_id, offset: offset} | acc
    ])
  end

  defp record_priority(%{platform_id: 3, encoding_id: 10}), do: 0
  defp record_priority(%{platform_id: 0, encoding_id: 4}), do: 1
  defp record_priority(%{platform_id: 3, encoding_id: 1}), do: 2
  defp record_priority(%{platform_id: 0, encoding_id: 3}), do: 3
  defp record_priority(%{platform_id: 0}), do: 4
  defp record_priority(_record), do: 10

  defp parse_cmap_subtable(cmap, %{offset: offset}) do
    if offset + 2 > byte_size(cmap) do
      {:error, :missing_character_map}
    else
      subtable = binary_part(cmap, offset, byte_size(cmap) - offset)

      case subtable do
        <<4::16, _::binary>> -> parse_format_4(subtable)
        <<12::16, _::binary>> -> parse_format_12(subtable)
        _ -> {:error, :unsupported_character_map}
      end
    end
  end

  defp parse_format_4(
         <<4::16, length::16, _language::16, seg_count_x2::16, _search_range::16,
           _entry_selector::16, _range_shift::16, rest::binary>>
       ) do
    seg_count = div(seg_count_x2, 2)
    needed_bytes = seg_count * 8 + 2

    if seg_count == 0 or byte_size(rest) + 14 < length or byte_size(rest) < needed_bytes do
      {:error, :missing_character_map}
    else
      subtable =
        binary_part(
          <<4::16, length::16, 0::16, seg_count_x2::16, 0::16, 0::16, 0::16, rest::binary>>,
          0,
          length
        )

      parse_format_4_subtable(subtable, seg_count)
    end
  end

  defp parse_format_4(_), do: {:error, :missing_character_map}

  defp parse_format_4_subtable(subtable, seg_count) do
    offset = 14
    {end_counts, offset} = uint16_array(subtable, offset, seg_count)
    offset = offset + 2
    {start_counts, offset} = uint16_array(subtable, offset, seg_count)
    {id_deltas_raw, offset} = uint16_array(subtable, offset, seg_count)
    {id_range_offsets, id_range_offsets_pos} = uint16_array(subtable, offset, seg_count)
    id_deltas = Enum.map(id_deltas_raw, &signed16/1)

    mapping =
      0..(seg_count - 1)
      |> Enum.reduce(%{}, fn index, acc ->
        start_code = Enum.at(start_counts, index)
        end_code = Enum.at(end_counts, index)
        delta = Enum.at(id_deltas, index)
        range_offset = Enum.at(id_range_offsets, index)
        id_range_word_pos = id_range_offsets_pos + index * 2

        if start_code > end_code or start_code == 0xFFFF do
          acc
        else
          Enum.reduce(start_code..end_code, acc, fn codepoint, segment_acc ->
            glyph_id =
              if range_offset == 0 do
                rem(codepoint + delta, 65_536)
              else
                glyph_offset = id_range_word_pos + range_offset + 2 * (codepoint - start_code)

                if glyph_offset + 2 <= byte_size(subtable) do
                  glyph = uint16_at(subtable, glyph_offset)
                  if glyph == 0, do: 0, else: rem(glyph + delta, 65_536)
                else
                  0
                end
              end

            if glyph_id == 0 do
              segment_acc
            else
              Map.put(segment_acc, codepoint, glyph_id)
            end
          end)
        end
      end)

    {:ok, mapping}
  end

  defp parse_format_12(
         <<12::16, _reserved::16, length::32, _language::32, num_groups::32, groups::binary>>
       ) do
    required_bytes = num_groups * 12

    if byte_size(groups) + 16 < length or byte_size(groups) < required_bytes do
      {:error, :missing_character_map}
    else
      mapping =
        groups
        |> binary_part(0, required_bytes)
        |> do_parse_format_12(%{})

      {:ok, mapping}
    end
  end

  defp parse_format_12(_), do: {:error, :missing_character_map}

  defp do_parse_format_12(<<>>, acc), do: acc

  defp do_parse_format_12(
         <<start_char::32, end_char::32, start_glyph::32, rest::binary>>,
         acc
       ) do
    updated =
      Enum.reduce(start_char..end_char, acc, fn codepoint, map ->
        Map.put(map, codepoint, start_glyph + (codepoint - start_char))
      end)

    do_parse_format_12(rest, updated)
  end

  defp build_width_map(codepoint_to_glyph, widths_by_glyph) do
    Map.new(codepoint_to_glyph, fn {codepoint, glyph_id} ->
      {codepoint, Map.get(widths_by_glyph, glyph_id, Map.get(widths_by_glyph, 0, 0))}
    end)
  end

  defp default_width(widths, widths_by_glyph) do
    cond do
      Map.has_key?(widths, 32) -> Map.fetch!(widths, 32)
      Map.has_key?(widths_by_glyph, 0) -> Map.fetch!(widths_by_glyph, 0)
      true -> 556
    end
  end

  defp parse_base_font_name(tables) do
    with {:ok, name} <- Map.fetch(tables, "name"),
         {:ok, base_font} <- parse_name_table(name) do
      {:ok, base_font}
    else
      :error -> {:ok, "EmbeddedFont"}
      {:error, _reason} -> {:ok, "EmbeddedFont"}
    end
  end

  defp parse_name_table(<<format::16, count::16, string_offset::16, records::binary>>) do
    required_bytes = count * 12

    if byte_size(records) < required_bytes do
      {:error, :invalid_name_table}
    else
      name_table = <<format::16, count::16, string_offset::16, records::binary>>

      records
      |> binary_part(0, required_bytes)
      |> parse_name_records([])
      |> Enum.find(&(&1.name_id == 6))
      |> case do
        nil -> {:error, :missing_postscript_name}
        record -> decode_name_record(record, string_offset, name_table)
      end
    end
  end

  defp parse_name_table(_), do: {:error, :invalid_name_table}

  defp parse_name_records(<<>>, acc), do: Enum.reverse(acc)

  defp parse_name_records(
         <<platform_id::16, encoding_id::16, language_id::16, name_id::16, length::16, offset::16,
           rest::binary>>,
         acc
       ) do
    parse_name_records(rest, [
      %{
        platform_id: platform_id,
        encoding_id: encoding_id,
        language_id: language_id,
        name_id: name_id,
        length: length,
        offset: offset
      }
      | acc
    ])
  end

  defp decode_name_record(record, string_offset, name_table) do
    start = string_offset + record.offset

    if start + record.length > byte_size(name_table) do
      {:error, :invalid_name_table}
    else
      bytes = binary_part(name_table, start, record.length)

      case record.platform_id do
        platform when platform in [0, 3] ->
          {:ok, decode_utf16be(bytes)}

        _ ->
          {:ok, String.trim(bytes)}
      end
    end
  end

  defp decode_utf16be(bytes) do
    bytes
    |> :unicode.characters_to_binary({:utf16, :big})
    |> String.trim()
  rescue
    _ -> "EmbeddedFont"
  end

  defp uint16_array(binary, offset, count) do
    slice = binary_part(binary, offset, count * 2)

    values =
      for <<value::16 <- slice>> do
        value
      end

    {values, offset + count * 2}
  end

  defp uint16_at(binary, offset) do
    <<value::16>> = binary_part(binary, offset, 2)
    value
  end

  defp signed16(value) when value >= 0x8000, do: value - 0x1_0000
  defp signed16(value), do: value
end

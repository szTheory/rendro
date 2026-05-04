defmodule Rendro.PDF.FontSubsetter do
  @moduledoc """
  Pure Elixir TrueType binary subsetter.
  Strips unused glyphs and updates `loca` / `glyf` tables correctly to minimize PDF size.
  """

  import Bitwise

  @doc """
  Subsets a TrueType binary by dropping unused glyphs and truncating the font.
  Returns `{:ok, subsetted_ttf_bytes}` or `{:error, reason}`.
  """
  @spec subset(binary(), [non_neg_integer()]) :: {:ok, binary()} | {:error, term()}
  def subset(bytes, used_glyphs) when is_binary(bytes) and is_list(used_glyphs) do
    with {:ok, version, num_tables, directory} <- parse_offset_table(bytes),
         :ok <- validate_version(version),
         {:ok, tables} <- parse_table_directory(directory, num_tables, bytes),
         {:ok, head} <- fetch_required_table(tables, "head"),
         {:ok, maxp} <- fetch_required_table(tables, "maxp"),
         {:ok, hhea} <- fetch_required_table(tables, "hhea"),
         {:ok, loca} <- fetch_required_table(tables, "loca"),
         {:ok, glyf} <- fetch_required_table(tables, "glyf"),
         {:ok, hmtx} <- fetch_required_table(tables, "hmtx"),
         {:ok, index_to_loc_format} <- parse_index_to_loc_format(head),
         {:ok, num_glyphs} <- parse_num_glyphs(maxp),
         {:ok, number_of_h_metrics} <- parse_number_of_h_metrics(hhea),
         {:ok, offsets} <- parse_loca(loca, index_to_loc_format, num_glyphs),
         {:ok, required_glyphs} <- resolve_dependencies(used_glyphs, offsets, glyf, num_glyphs),
         max_used_glyph <- Enum.max([0 | required_glyphs]),
         new_num_glyphs <- max_used_glyph + 1 do
      
      {new_glyf, new_loca} = rebuild_glyf_and_loca(required_glyphs, new_num_glyphs, offsets, glyf, index_to_loc_format)
      new_maxp = rebuild_maxp(maxp, new_num_glyphs)
      {new_hhea, new_hmtx} = rebuild_hmtx_and_hhea(hhea, hmtx, new_num_glyphs, number_of_h_metrics)
      
      updated_tables =
        tables
        |> Map.put("glyf", new_glyf)
        |> Map.put("loca", new_loca)
        |> Map.put("maxp", new_maxp)
        |> Map.put("hhea", new_hhea)
        |> Map.put("hmtx", new_hmtx)
        |> Map.put("head", clear_head_checksum(head))

      final_bytes = assemble_font(version, updated_tables)
      {:ok, final_bytes}
    else
      {:error, _} = error -> error
    end
  end

  defp parse_offset_table(<<version::binary-size(4), num_tables::16, _search_range::16, _entry_selector::16, _range_shift::16, directory::binary>>) do
    {:ok, version, num_tables, directory}
  end
  defp parse_offset_table(_), do: {:error, :unsupported_font_format}

  defp validate_version(<<0, 1, 0, 0>>), do: :ok
  defp validate_version("true"), do: :ok
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
  defp do_parse_table_directory(<<tag::binary-size(4), _checksum::32, offset::32, length::32, rest::binary>>, remaining, bytes, tables) do
    table = if offset + length <= byte_size(bytes), do: binary_part(bytes, offset, length), else: :invalid
    do_parse_table_directory(rest, remaining - 1, bytes, Map.put(tables, tag, table))
  end

  defp fetch_required_table(tables, tag) do
    case Map.fetch(tables, tag) do
      {:ok, :invalid} -> {:error, {:invalid_table_range, tag}}
      {:ok, table} -> {:ok, table}
      :error -> {:error, {:missing_required_table, tag}}
    end
  end

  defp parse_index_to_loc_format(<<_::binary-size(50), format::signed-16, _::binary>>), do: {:ok, format}
  defp parse_index_to_loc_format(_), do: {:error, :invalid_head_table}

  defp parse_num_glyphs(<<_::binary-size(4), num_glyphs::16, _::binary>>), do: {:ok, num_glyphs}
  defp parse_num_glyphs(_), do: {:error, :invalid_maxp_table}

  defp parse_number_of_h_metrics(<<_::binary-size(34), num::16>>), do: {:ok, num}
  defp parse_number_of_h_metrics(_), do: {:error, :invalid_hhea_table}

  defp parse_loca(loca, format, num_glyphs) do
    expected_size = if format == 0, do: (num_glyphs + 1) * 2, else: (num_glyphs + 1) * 4
    if byte_size(loca) < expected_size do
      {:error, :invalid_loca_table}
    else
      offsets =
        0..num_glyphs
        |> Enum.map(fn i ->
          if format == 0 do
            <<val::16>> = binary_part(loca, i * 2, 2)
            val * 2
          else
            <<val::32>> = binary_part(loca, i * 4, 4)
            val
          end
        end)
      {:ok, List.to_tuple(offsets)}
    end
  end

  defp resolve_dependencies(used_glyphs, offsets, glyf, num_glyphs) do
    initial = [0 | used_glyphs] |> Enum.filter(&(&1 < num_glyphs)) |> MapSet.new()
    {:ok, do_resolve_dependencies(MapSet.to_list(initial), offsets, glyf, initial)}
  end

  defp do_resolve_dependencies([], _offsets, _glyf, acc), do: MapSet.to_list(acc)
  defp do_resolve_dependencies([gid | rest], offsets, glyf, acc) do
    start_offset = elem(offsets, gid)
    end_offset = elem(offsets, gid + 1)
    len = end_offset - start_offset

    if len > 0 and start_offset + len <= byte_size(glyf) do
      glyph_data = binary_part(glyf, start_offset, len)
      composites = extract_composites(glyph_data)
      new_composites = Enum.reject(composites, &MapSet.member?(acc, &1))
      new_acc = Enum.reduce(new_composites, acc, &MapSet.put(&2, &1))
      do_resolve_dependencies(new_composites ++ rest, offsets, glyf, new_acc)
    else
      do_resolve_dependencies(rest, offsets, glyf, acc)
    end
  end

  defp extract_composites(<<num_contours::signed-16, _xmin::signed-16, _ymin::signed-16, _xmax::signed-16, _ymax::signed-16, rest::binary>>) when num_contours < 0 do
    parse_composite_components(rest, [])
  end
  defp extract_composites(_), do: []

  defp parse_composite_components(<<flags::16, glyph_index::16, rest::binary>>, acc) do
    args_len = if (flags &&& 0x0001) != 0, do: 4, else: 2
    
    scale_len = cond do
      (flags &&& 0x0008) != 0 -> 2
      (flags &&& 0x0040) != 0 -> 4
      (flags &&& 0x0080) != 0 -> 8
      true -> 0
    end

    skip = args_len + scale_len
    if byte_size(rest) >= skip do
      <<_::binary-size(skip), next::binary>> = rest
      if (flags &&& 0x0020) != 0 do
        parse_composite_components(next, [glyph_index | acc])
      else
        [glyph_index | acc]
      end
    else
      [glyph_index | acc]
    end
  end
  defp parse_composite_components(_, acc), do: acc

  defp rebuild_glyf_and_loca(required_glyphs, new_num_glyphs, offsets, glyf, index_to_loc_format) do
    req_set = MapSet.new(required_glyphs)
    
    {new_glyf_io, new_loca_io, final_offset} =
      0..(new_num_glyphs - 1)
      |> Enum.reduce({[], [], 0}, fn gid, {glyf_acc, loca_acc, current_offset} ->
        loca_entry = encode_loca(current_offset, index_to_loc_format)
        
        if MapSet.member?(req_set, gid) do
          start_offset = elem(offsets, gid)
          end_offset = elem(offsets, gid + 1)
          len = end_offset - start_offset
          
          if len > 0 and start_offset + len <= byte_size(glyf) do
            glyph_data = binary_part(glyf, start_offset, len)
            { [glyph_data | glyf_acc], [loca_entry | loca_acc], current_offset + len }
          else
            { glyf_acc, [loca_entry | loca_acc], current_offset }
          end
        else
          { glyf_acc, [loca_entry | loca_acc], current_offset }
        end
      end)
      
    final_loca_entry = encode_loca(final_offset, index_to_loc_format)
    
    new_glyf = new_glyf_io |> Enum.reverse() |> IO.iodata_to_binary()
    new_loca = [final_loca_entry | new_loca_io] |> Enum.reverse() |> IO.iodata_to_binary()
    
    {new_glyf, new_loca}
  end

  defp encode_loca(offset, 0), do: <<div(offset, 2)::16>>
  defp encode_loca(offset, _), do: <<offset::32>>

  defp rebuild_maxp(<<prefix::binary-size(4), _old_num::16, suffix::binary>>, new_num_glyphs) do
    prefix <> <<new_num_glyphs::16>> <> suffix
  end

  defp rebuild_hmtx_and_hhea(hhea, hmtx, new_num_glyphs, old_number_of_h_metrics) do
    new_number_of_h_metrics = min(old_number_of_h_metrics, new_num_glyphs)
    
    <<hhea_prefix::binary-size(34), _::16>> = hhea
    new_hhea = hhea_prefix <> <<new_number_of_h_metrics::16>>
    
    # hmtx structure: [advanceWidth (2 bytes), lsb (2 bytes)] * numberOfHMetrics
    # then [lsb (2 bytes)] * (numGlyphs - numberOfHMetrics)
    
    new_hmtx =
      if new_num_glyphs <= old_number_of_h_metrics do
        binary_part(hmtx, 0, new_num_glyphs * 4)
      else
        metrics_size = old_number_of_h_metrics * 4
        lsb_size = (new_num_glyphs - old_number_of_h_metrics) * 2
        binary_part(hmtx, 0, metrics_size + lsb_size)
      end
      
    {new_hhea, new_hmtx}
  end

  defp clear_head_checksum(<<prefix::binary-size(8), _old_checksum::32, suffix::binary>>) do
    prefix <> <<0::32>> <> suffix
  end

  defp assemble_font(version, tables) do
    num_tables = map_size(tables)
    
    # Calculate binary search parameters
    search_range = max_power_of_2_leq(num_tables) * 16
    entry_selector = log2(div(search_range, 16))
    range_shift = num_tables * 16 - search_range
    
    header = <<version::binary, num_tables::16, search_range::16, entry_selector::16, range_shift::16>>
    
    # We must sort tags to be valid TTF
    sorted_tags = tables |> Map.keys() |> Enum.sort()
    
    # Write table directory and tables, padding tables to 4-byte boundaries
    directory_size = 12 + num_tables * 16
    
    {records, table_data_io, _offset} =
      Enum.reduce(sorted_tags, {[], [], directory_size}, fn tag, {recs, data, offset} ->
        table = Map.fetch!(tables, tag)
        len = byte_size(table)
        padded_table = pad_table(table)
        padded_len = byte_size(padded_table)
        checksum = calc_checksum(padded_table)
        
        record = <<tag::binary-size(4), checksum::32, offset::32, len::32>>
        
        {[record | recs], [padded_table | data], offset + padded_len}
      end)
      
    table_records = records |> Enum.reverse() |> IO.iodata_to_binary()
    all_table_data = table_data_io |> Enum.reverse() |> IO.iodata_to_binary()
    
    font_without_head_checksum = header <> table_records <> all_table_data
    
    # Calculate final font checksum
    font_checksum = calc_checksum(font_without_head_checksum)
    checksum_adjustment = 0xB1B0AFBA - font_checksum
    
    # Inject checksum adjustment into the new head table (which is already inside font_without_head_checksum)
    inject_head_checksum(font_without_head_checksum, checksum_adjustment)
  end
  
  defp inject_head_checksum(bytes, adjustment) do
    # Find head table offset
    {:ok, _, num_tables, _} = parse_offset_table(bytes)
    
    offset_of_head_record = find_table_record(bytes, 12, num_tables, "head")
    if offset_of_head_record do
      <<_::binary-size(offset_of_head_record), "head", _checksum::32, head_offset::32, _len::32, _::binary>> = bytes
      <<prefix::binary-size(head_offset), head_prefix::binary-size(8), _old_csum::32, suffix::binary>> = bytes
      
      prefix <> head_prefix <> <<adjustment::32>> <> suffix
    else
      bytes
    end
  end
  
  defp find_table_record(_bytes, _pos, 0, _target_tag), do: nil
  defp find_table_record(bytes, pos, num_tables, target_tag) do
    <<tag::binary-size(4), _::binary-size(12)>> = binary_part(bytes, pos, 16)
    if tag == target_tag do
      pos
    else
      find_table_record(bytes, pos + 16, num_tables - 1, target_tag)
    end
  end

  defp pad_table(table) do
    rem = rem(byte_size(table), 4)
    if rem == 0, do: table, else: table <> :binary.copy(<<0>>, 4 - rem)
  end

  defp calc_checksum(bytes) do
    bytes
    |> pad_table()
    |> do_calc_checksum(0)
  end

  defp do_calc_checksum(<<>>, acc), do: acc &&& 0xFFFFFFFF
  defp do_calc_checksum(<<val::32, rest::binary>>, acc) do
    do_calc_checksum(rest, (acc + val) &&& 0xFFFFFFFF)
  end

  defp max_power_of_2_leq(n, pow \\ 1)
  defp max_power_of_2_leq(n, pow) when pow * 2 <= n, do: max_power_of_2_leq(n, pow * 2)
  defp max_power_of_2_leq(_n, pow), do: pow

  defp log2(n, acc \\ 0)
  defp log2(n, acc) when n > 1, do: log2(div(n, 2), acc + 1)
  defp log2(_n, acc), do: acc
end

defmodule Rendro.Pipeline.Measure do
  @moduledoc false

  alias Rendro.FontRegistry
  alias Rendro.PDF.Font
  alias Rendro.Pipeline.MeasuredText
  alias Rendro.Region

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    with {:ok, pages} <- measure_pages(doc, doc.pages),
         {:ok, content} <- measure_content(doc, doc.content),
         {:ok, measured_doc} <- measure_layout(doc, doc.options[:layout]) do
      {:ok, %{measured_doc | pages: pages, content: content}}
    end
  end

  defp measure_pages(doc, pages) do
    map_ok(pages, &measure_page(doc, &1))
  end

  defp measure_content(doc, content) do
    map_ok(content, &measure_block(doc, &1))
  end

  defp measure_page(doc, %Rendro.Page{blocks: blocks} = page) do
    with {:ok, measured_blocks} <- map_ok(blocks, &measure_block(doc, &1)) do
      {:ok, %{page | blocks: measured_blocks}}
    end
  end

  defp measure_block(doc, block, container_width \\ nil)

  defp measure_block(
         doc,
         %Rendro.Block{content: %Rendro.Table{} = table} = block,
         container_width
       ) do
    width = block.width || container_width || 595.28

    col_count = max_columns(table)
    col_widths = resolve_columns(table.columns, col_count, width)

    with {:ok, {measured_header, header_h}} <- measure_table_row(doc, table.header, col_widths),
         {:ok, {measured_rows, row_heights}} <- measure_table_rows(doc, table.rows, col_widths) do
      rows_h = Enum.sum(row_heights)
      height = header_h + rows_h

      table = %{
        table
        | header: measured_header,
          rows: measured_rows,
          column_widths: col_widths,
          row_heights: row_heights,
          header_height: header_h
      }

      {:ok, %{block | content: table, width: width, height: height}}
    end
  end

  defp measure_block(doc, %Rendro.Block{content: %Rendro.Text{} = text} = block, _container_width) do
    with [] <- Rendro.I18n.Analyzer.analyze(text.content),
         {:ok, font_chain} <- resolve_font_chain(doc, text),
         {:ok, lines} <- wrap_text(text.content, block.width, font_chain, text.size) do
      measured_width = measured_text_width(lines)
      width = block.width || measured_width
      measured_height = text.size * text.line_height * length(lines)
      height = block.height || measured_height

      measured_text = %MeasuredText{
        source: text,
        lines: lines,
        line_height: text.line_height,
        width: measured_width,
        height: measured_height,
        resolved_font: hd(font_chain)
      }

      {:ok, %{block | content: measured_text, width: width, height: height}}
    else
      [%{type: :unsupported_script, reason: reason} | _] ->
        {:error, {:unsupported_script, reason}}

      {:error, _} = err ->
        err
    end
  end

  defp measure_block(
         doc,
         %Rendro.Block{content: %Rendro.Image{} = image} = block,
         _container_width
       ) do
    with {:ok, %{width: intrinsic_w, height: intrinsic_h}} <-
           Rendro.AssetRegistry.fetch(doc.asset_registry, image.logical_name) do
      aspect_ratio = intrinsic_w / intrinsic_h

      {width, height} =
        case {block.width, block.height, image.fit} do
          {nil, nil, {fit_w, fit_h}} ->
            fit_aspect = fit_w / fit_h

            if aspect_ratio > fit_aspect do
              {fit_w, fit_w / aspect_ratio}
            else
              {fit_h * aspect_ratio, fit_h}
            end

          {w, nil, nil} when not is_nil(w) ->
            {w, w / aspect_ratio}

          {nil, h, nil} when not is_nil(h) ->
            {h * aspect_ratio, h}

          {w, h, nil} when not is_nil(w) and not is_nil(h) ->
            {w, h}

          _ ->
            {intrinsic_w, intrinsic_h}
        end

      {:ok, %{block | width: width, height: height}}
    else
      :error ->
        {:error, {:missing_asset, image.logical_name}}
    end
  end

  defp measure_block(_doc, block, _container_width), do: {:ok, block}

  defp measure_table_row(_doc, nil, _col_widths), do: {:ok, {nil, 0}}

  defp measure_table_row(doc, row, col_widths) do
    with {:ok, measured_cells} <-
           row
           |> Enum.zip(col_widths)
           |> map_ok(fn {cell_block, c_width} ->
             measure_block(doc, %{cell_block | width: c_width}, c_width)
           end) do
      max_height =
        measured_cells
        |> Enum.map(&(&1.height || 0))
        |> Enum.max(fn -> 0 end)

      {:ok, {measured_cells, max_height}}
    end
  end

  defp measure_table_rows(doc, rows, col_widths) do
    Enum.reduce_while(rows, {:ok, {[], []}}, fn row, {:ok, {measured_rows, heights}} ->
      case measure_table_row(doc, row, col_widths) do
        {:ok, {measured_row, row_height}} ->
          {:cont, {:ok, {measured_rows ++ [measured_row], heights ++ [row_height]}}}

        {:error, _} = err ->
          {:halt, err}
      end
    end)
  end

  defp max_columns(%Rendro.Table{header: header, rows: rows}) do
    rows
    |> Enum.map(&length/1)
    |> Kernel.++([if(header, do: length(header), else: 0)])
    |> Enum.max(fn -> 0 end)
  end

  defp resolve_columns(nil, count, total_width) when count > 0 do
    w = total_width / count
    List.duplicate(w, count)
  end

  defp resolve_columns(nil, 0, _total_width), do: []

  defp resolve_columns(columns, count, total_width) do
    fixed_total =
      columns
      |> Enum.map(fn
        {:fixed, w} -> w
        _ -> 0
      end)
      |> Enum.sum()

    shares_total =
      columns
      |> Enum.map(fn
        {:share, s} -> s
        _ -> 0
      end)
      |> Enum.sum()

    remaining_width = max(total_width - fixed_total, 0)

    resolved =
      columns
      |> Enum.map(fn
        {:fixed, w} -> w
        {:share, s} -> if shares_total > 0, do: remaining_width * (s / shares_total), else: 0
      end)

    if length(resolved) < count do
      resolved ++ List.duplicate(0, count - length(resolved))
    else
      Enum.take(resolved, count)
    end
  end

  defp measure_layout(%Rendro.Document{} = doc, nil), do: {:ok, doc}

  defp measure_layout(%Rendro.Document{} = doc, layout) do
    with {:ok, measured_region_blocks} <- measure_region_blocks(doc, layout) do
      measured_layout =
        layout
        |> Map.put(:region_blocks, measured_region_blocks)
        |> Map.put(:body_capacity, body_capacity(layout))

      if measured_layout.body_capacity <= 0 do
        {:error, :no_body_capacity}
      else
        body_blocks = Map.get(measured_region_blocks, :body, [])
        header_blocks = Map.get(measured_region_blocks, :header, [])
        footer_blocks = Map.get(measured_region_blocks, :footer, [])

        {:ok,
         doc
         |> put_in([Access.key(:options), :layout], measured_layout)
         |> Map.put(:content, body_blocks)
         |> Map.put(:header, header_blocks)
         |> Map.put(:footer, footer_blocks)}
      end
    end
  end

  defp measure_region_blocks(doc, layout) do
    Enum.reduce_while(layout.region_blocks, {:ok, %{}}, fn {name, blocks}, {:ok, acc} ->
      region_width =
        case name do
          :body ->
            layout.body_region.width

          _ ->
            region = Enum.find(layout.template.regions, &(&1.name == name))
            if region, do: region.width, else: nil
        end

      case map_ok(blocks, &measure_block(doc, &1, region_width)) do
        {:ok, measured_blocks} ->
          {:cont, {:ok, Map.put(acc, name, measured_blocks)}}

        {:error, _} = err ->
          {:halt, err}
      end
    end)
  end

  defp body_capacity(%{body_region: %Region{height: height}}) when is_number(height), do: height
  defp body_capacity(_layout), do: 0

  defp wrap_text(text, nil, font_chain, font_size) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reduce_while({:ok, []}, fn segment, {:ok, lines} ->
      case measure_text_into_runs(segment, font_chain, font_size) do
        {:ok, runs} -> {:cont, {:ok, lines ++ [runs]}}
        err -> {:halt, err}
      end
    end)
  end

  defp wrap_text(text, max_width, font_chain, font_size) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reduce_while({:ok, []}, fn segment, {:ok, lines} ->
      case wrap_segment(segment, max_width, font_chain, font_size) do
        {:ok, segment_lines} -> {:cont, {:ok, lines ++ segment_lines}}
        err -> {:halt, err}
      end
    end)
  end

  defp wrap_segment("", _max_width, _font_chain, _font_size), do: {:ok, [[]]}

  defp wrap_segment(segment, max_width, font_chain, font_size) do
    chunks = Regex.scan(~r/\s+|\S+/, segment) |> List.flatten()

    case chunks do
      [] ->
        {:ok, [[]]}

      [chunk | rest] ->
        with {:ok, split_lines} <- split_chunk(chunk, max_width, font_chain, font_size),
             {:ok, wrapped_lines} <-
               wrap_chunks(split_lines, rest, max_width, font_chain, font_size) do
          {:ok, wrapped_lines}
        end
    end
  end

  defp wrap_chunks(lines, chunks, max_width, font_chain, font_size) do
    Enum.reduce_while(chunks, {:ok, lines}, fn chunk, {:ok, acc_lines} ->
      {leading_lines, [current_line]} = Enum.split(acc_lines, length(acc_lines) - 1)

      case measure_text_into_runs(chunk, font_chain, font_size) do
        {:ok, chunk_runs} ->
          candidate_line = merge_runs(current_line, chunk_runs)
          candidate_width = runs_width(candidate_line)

          if candidate_width <= max_width do
            {:cont, {:ok, leading_lines ++ [candidate_line]}}
          else
            case split_chunk(chunk, max_width, font_chain, font_size) do
              {:ok, chunk_lines} ->
                {:cont, {:ok, acc_lines ++ chunk_lines}}

              err ->
                {:halt, err}
            end
          end

        err ->
          {:halt, err}
      end
    end)
  end

  defp split_chunk(chunk, max_width, font_chain, font_size) do
    case measure_text_into_runs(chunk, font_chain, font_size) do
      {:ok, chunk_runs} ->
        if runs_width(chunk_runs) <= max_width do
          {:ok, [chunk_runs]}
        else
          split_graphemes(chunk, max_width, font_chain, font_size)
        end

      err ->
        err
    end
  end

  defp resolve_font_chain(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Text{font: font}
       ) do
    FontRegistry.resolve_pdf_font_chain(registry, font, default_font)
  end

  defp map_ok(enum, fun) do
    Enum.reduce_while(enum, {:ok, []}, fn item, {:ok, acc} ->
      case fun.(item) do
        {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp split_graphemes(text, max_width, font_chain, font_size) do
    result =
      Enum.reduce_while(String.graphemes(text), {:ok, {[], []}}, fn grapheme,
                                                                    {:ok, {lines, current_line}} ->
        case find_font_for_grapheme(grapheme, font_chain) do
          {:ok, font} ->
            width = Font.text_width(font, grapheme, font_size)
            grapheme_run = [%{font: font, text: grapheme, width: width}]

            candidate_line = merge_runs(current_line, grapheme_run)

            cond do
              current_line == [] and width <= max_width ->
                {:cont, {:ok, {lines, candidate_line}}}

              current_line == [] ->
                {:cont, {:ok, {[candidate_line | lines], []}}}

              runs_width(candidate_line) <= max_width ->
                {:cont, {:ok, {lines, candidate_line}}}

              true ->
                {:cont, {:ok, {[current_line | lines], grapheme_run}}}
            end

          :error ->
            {:halt, {:error, {:unsupported_glyph, grapheme}}}
        end
      end)

    case result do
      {:ok, {lines, current_line}} ->
        final_lines =
          case current_line do
            [] -> Enum.reverse(lines)
            _ -> Enum.reverse([current_line | lines])
          end

        {:ok, final_lines}

      err ->
        err
    end
  end

  defp measured_text_width(lines) do
    lines
    |> Enum.map(&runs_width/1)
    |> Enum.max(fn -> 0 end)
  end

  defp measure_text_into_runs(text, font_chain, font_size) do
    result =
      Enum.reduce_while(String.graphemes(text), {:ok, []}, fn grapheme, {:ok, runs} ->
        case find_font_for_grapheme(grapheme, font_chain) do
          {:ok, font} ->
            width = Font.text_width(font, grapheme, font_size)
            {:cont, {:ok, append_to_runs(runs, font, grapheme, width)}}

          :error ->
            {:halt, {:error, {:unsupported_glyph, grapheme}}}
        end
      end)

    case result do
      {:ok, runs} -> {:ok, Enum.reverse(runs)}
      err -> err
    end
  end

  defp find_font_for_grapheme(grapheme, font_chain) do
    Enum.find_value(font_chain, :error, fn font ->
      if Font.has_glyph?(font, grapheme) do
        {:ok, font}
      else
        nil
      end
    end)
  end

  defp append_to_runs([], font, text, width) do
    [%{font: font, text: text, width: width}]
  end

  defp append_to_runs([%{font: f, text: t, width: w} | rest], font, text, width) when f == font do
    [%{font: f, text: t <> text, width: w + width} | rest]
  end

  defp append_to_runs(runs, font, text, width) do
    [%{font: font, text: text, width: width} | runs]
  end

  defp merge_runs(runs1, []) do
    runs1
  end

  defp merge_runs([], runs2) do
    runs2
  end

  defp merge_runs(runs1, runs2) do
    last_run1 = List.last(runs1)
    [first_run2 | rest2] = runs2

    if last_run1.font == first_run2.font do
      merged_run = %{
        font: last_run1.font,
        text: last_run1.text <> first_run2.text,
        width: last_run1.width + first_run2.width
      }

      Enum.slice(runs1, 0, length(runs1) - 1) ++ [merged_run] ++ rest2
    else
      runs1 ++ runs2
    end
  end

  defp runs_width(runs) do
    Enum.reduce(runs, 0, fn run, acc -> acc + run.width end)
  end
end

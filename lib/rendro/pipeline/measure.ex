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

    normalized_header = normalize_header(table.header)
    normalized_rows = normalize_rows(table.rows)

    col_count = max_columns(normalized_header, normalized_rows)
    col_widths = resolve_columns(table.columns, col_count, width)

    with {:ok, {measured_header, header_h}} <-
           measure_table_header(doc, normalized_header, col_widths),
         {:ok, {measured_rows, row_heights, grid_layout}} <-
           project_and_measure_grid(doc, normalized_rows, col_widths) do
      rows_h = Enum.sum(row_heights)
      height = header_h + rows_h

      table = %{
        table
        | header: measured_header,
          rows: measured_rows,
          column_widths: col_widths,
          row_heights: row_heights,
          header_height: header_h,
          _grid_layout: grid_layout
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
        resolved_font: hd(font_chain),
        widows: text.widows,
        orphans: text.orphans
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
         _doc,
         %Rendro.Block{content: %Rendro.FormField{} = field} = block,
         _container_width
       ) do
    {default_width, default_height} =
      case field.type do
        type when type in [:checkbox, :radio] -> {20.0, 20.0}
        _ -> {150.0, 20.0}
      end

    {:ok, %{block | width: block.width || default_width, height: block.height || default_height}}
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

  defp normalize_header(nil), do: nil

  defp normalize_header(header) do
    [row] = normalize_rows([header])
    row
  end

  defp normalize_rows(rows) do
    Enum.map(rows, fn
      %Rendro.Row{} = row ->
        %{row | cells: normalize_cells(row.cells)}

      cells when is_list(cells) ->
        %Rendro.Row{cells: normalize_cells(cells)}
    end)
  end

  defp normalize_cells(cells) do
    Enum.map(cells, fn
      %Rendro.Cell{} = cell -> cell
      content -> %Rendro.Cell{content: content}
    end)
  end

  defp max_columns(header, rows) do
    row_cols =
      Enum.map(rows, fn row ->
        Enum.reduce(row.cells, 0, fn c, acc -> acc + c.colspan end)
      end)

    header_cols =
      if header do
        Enum.reduce(header.cells, 0, fn c, acc -> acc + c.colspan end)
      else
        0
      end

    [header_cols | row_cols] |> Enum.max(fn -> 0 end)
  end

  defp measure_table_header(_doc, nil, _col_widths), do: {:ok, {nil, 0}}

  defp measure_table_header(doc, header, col_widths) do
    case project_and_measure_grid(doc, [header], col_widths) do
      {:ok, {[measured_header], [header_h], _grid}} ->
        {:ok, {measured_header, header_h}}

      {:error, _} = err ->
        err
    end
  end

  defp project_and_measure_grid(_doc, [], _col_widths), do: {:ok, {[], [], []}}

  defp project_and_measure_grid(doc, rows, col_widths) do
    col_count = length(col_widths)

    total_cells =
      Enum.reduce(rows, 0, fn row, acc ->
        acc + Enum.reduce(row.cells, 0, fn c, acc2 -> acc2 + c.rowspan * c.colspan end)
      end)

    if total_cells > 100_000 do
      {:error, :grid_too_large}
    else
      do_build_grid(doc, rows, col_widths, col_count)
    end
  end

  defp do_build_grid(doc, rows, col_widths, col_count) do
    result =
      Enum.reduce_while(Enum.with_index(rows), {:ok, {%{}, [], []}}, fn {row, r},
                                                                        {:ok,
                                                                         {grid, m_rows, r_heights}} ->
        case fill_row_cells(doc, row, r, col_widths, grid, col_count) do
          {:ok, {new_grid, measured_cells, row_height}} ->
            measured_row = %{row | cells: measured_cells, height: row_height}
            {:cont, {:ok, {new_grid, m_rows ++ [measured_row], r_heights ++ [row_height]}}}

          {:error, _} = err ->
            {:halt, err}
        end
      end)

    case result do
      {:ok, {grid_map, measured_rows, row_heights}} ->
        grid_layout =
          for r <- 0..(length(rows) - 1) do
            for c <- 0..(col_count - 1) do
              Map.get(grid_map, {r, c}, %{is_continuation: false, cell: nil})
            end
          end

        {:ok, {measured_rows, row_heights, grid_layout}}

      err ->
        err
    end
  end

  defp fill_row_cells(doc, row, r, col_widths, grid, col_count) do
    state = {:ok, {grid, [], 0, 0}}

    Enum.reduce_while(row.cells, state, fn cell, {:ok, {g, m_cells, c, max_h}} ->
      next_c = find_next_empty_col(g, r, c, col_count)

      if next_c >= col_count do
        {:cont, {:ok, {g, m_cells ++ [cell], next_c, max_h}}}
      else
        cell_width = calculate_cell_width(col_widths, next_c, cell.colspan)

        block_to_measure =
          case cell.content do
            %Rendro.Block{} = b ->
              %{b | width: cell_width}

            str when is_binary(str) ->
              %Rendro.Block{content: %Rendro.Text{content: str}, width: cell_width}

            other ->
              %Rendro.Block{content: other, width: cell_width}
          end

        case measure_block(doc, block_to_measure, cell_width) do
          {:ok, measured_block} ->
            measured_cell = %{
              cell
              | content: measured_block,
                x: 0,
                y: 0,
                width: cell_width,
                height: measured_block.height
            }

            new_g =
              for r_offset <- 0..(cell.rowspan - 1),
                  c_offset <- 0..(cell.colspan - 1),
                  reduce: g do
                acc_g ->
                  is_cont = r_offset > 0 or c_offset > 0

                  cell_data = %{
                    is_continuation: is_cont,
                    cell: measured_cell,
                    ref_r: r,
                    ref_c: next_c
                  }

                  Map.put(acc_g, {r + r_offset, next_c + c_offset}, cell_data)
              end

            new_max_h = max(max_h, measured_block.height || 0)

            {:cont, {:ok, {new_g, m_cells ++ [measured_cell], next_c + cell.colspan, new_max_h}}}

          {:error, _} = err ->
            {:halt, err}
        end
      end
    end)
    |> case do
      {:ok, {final_grid, final_m_cells, _final_c, final_max_h}} ->
        {:ok, {final_grid, final_m_cells, final_max_h}}

      err ->
        err
    end
  end

  defp find_next_empty_col(grid, r, c, col_count) do
    if c >= col_count do
      c
    else
      if Map.has_key?(grid, {r, c}) do
        find_next_empty_col(grid, r, c + 1, col_count)
      else
        c
      end
    end
  end

  defp calculate_cell_width(col_widths, start_c, colspan) do
    col_widths
    |> Enum.slice(start_c, colspan)
    |> Enum.sum()
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
            {:ok, glyphs} = Rendro.Text.Shaper.shape(font, grapheme)

            width =
              glyphs
              |> Enum.reduce(0, fn g, acc -> acc + g.x_advance end)
              |> Kernel.*(font_size / font.units_per_em)

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
    bidi_runs = Rendro.Text.Bidi.split_runs(text)

    result =
      Enum.reduce_while(bidi_runs, {:ok, []}, fn bidi_run, {:ok, acc_runs} ->
        case resolve_fonts_for_run(bidi_run.text, font_chain) do
          {:ok, font_runs} ->
            measured =
              Enum.map(font_runs, fn {font, sub_text} ->
                {:ok, glyphs} = Rendro.Text.Shaper.shape(font, sub_text)

                width =
                  glyphs
                  |> Enum.reduce(0, fn g, acc -> acc + g.x_advance end)
                  |> Kernel.*(font_size / font.units_per_em)

                %{font: font, text: sub_text, width: width}
              end)

            {:cont, {:ok, acc_runs ++ measured}}

          {:error, _} = err ->
            {:halt, err}
        end
      end)

    case result do
      {:ok, runs} -> {:ok, merge_contiguous_runs(runs)}
      err -> err
    end
  end

  defp merge_contiguous_runs(runs) do
    Enum.reduce(runs, [], fn run, acc ->
      merge_runs(acc, [run])
    end)
  end

  defp resolve_fonts_for_run(text, font_chain) do
    result =
      text
      |> String.graphemes()
      |> Enum.reduce_while({:ok, []}, fn grapheme, {:ok, acc} ->
        case find_font_for_grapheme(grapheme, font_chain) do
          {:ok, font} ->
            {:cont, {:ok, append_font_run(acc, font, grapheme)}}

          :error ->
            {:halt, {:error, {:unsupported_glyph, grapheme}}}
        end
      end)

    case result do
      {:ok, runs} -> {:ok, Enum.reverse(runs)}
      err -> err
    end
  end

  defp append_font_run([], font, text), do: [{font, text}]
  defp append_font_run([{f, t} | rest], font, text) when f == font, do: [{f, t <> text} | rest]
  defp append_font_run(runs, font, text), do: [{font, text} | runs]

  defp find_font_for_grapheme(grapheme, font_chain) do
    Enum.find_value(font_chain, :error, fn font ->
      if Font.has_glyph?(font, grapheme) do
        {:ok, font}
      else
        nil
      end
    end)
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

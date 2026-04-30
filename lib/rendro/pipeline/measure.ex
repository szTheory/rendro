defmodule Rendro.Pipeline.Measure do
  @moduledoc """
  Calculates dimensions for blocks that don't have explicit sizes.

  Operates on the normalized tree from `Rendro.Pipeline.Compose` — every
  table row already contains `%Rendro.Block{}` entries. Measure fills
  missing widths via font metrics and missing heights from font size.
  Idempotent: running twice on the same input yields the same result
  (each `block.width || ...` keeps user-supplied values).
  """

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
    with {:ok, font} <- resolve_font(doc, text) do
      lines = wrap_text(text.content, block.width, font, text.size)
      measured_width = measured_text_width(lines, font, text.size)
      width = block.width || measured_width
      measured_height = text.size * text.line_height * length(lines)
      height = block.height || measured_height

      measured_text = %MeasuredText{
        source: text,
        lines: lines,
        line_height: text.line_height,
        width: measured_width,
        height: measured_height,
        resolved_font: font
      }

      {:ok, %{block | content: measured_text, width: width, height: height}}
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
          :body -> layout.body_region.width
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

  defp wrap_text(text, nil, _font, _font_size), do: String.split(text, "\n", trim: false)

  defp wrap_text(text, max_width, font, font_size) do
    text
    |> String.split("\n", trim: false)
    |> Enum.flat_map(&wrap_segment(&1, max_width, font, font_size))
  end

  defp wrap_segment("", _max_width, _font, _font_size), do: [""]

  defp wrap_segment(segment, max_width, font, font_size) do
    chunks = Regex.scan(~r/\s+|\S+/, segment) |> List.flatten()

    case chunks do
      [] ->
        [""]

      [chunk | rest] ->
        chunk
        |> split_chunk(max_width, font, font_size)
        |> wrap_chunks(rest, max_width, font, font_size)
    end
  end

  defp wrap_chunks(lines, chunks, max_width, font, font_size) do
    Enum.reduce(chunks, lines, fn chunk, acc_lines ->
      {leading_lines, [current_line]} = Enum.split(acc_lines, length(acc_lines) - 1)
      candidate = current_line <> chunk

      if Font.text_width(font, candidate, font_size) <= max_width do
        leading_lines ++ [candidate]
      else
        acc_lines ++ split_chunk(chunk, max_width, font, font_size)
      end
    end)
  end

  defp split_chunk(chunk, max_width, font, font_size) do
    if Font.text_width(font, chunk, font_size) <= max_width do
      [chunk]
    else
      split_graphemes(chunk, max_width, font, font_size)
    end
  end

  defp resolve_font(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Text{font: font}
       ) do
    FontRegistry.resolve_pdf_font(registry, font, default_font)
  end

  defp map_ok(enum, fun) do
    Enum.reduce_while(enum, {:ok, []}, fn item, {:ok, acc} ->
      case fun.(item) do
        {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp split_graphemes(text, max_width, font, font_size) do
    {lines, current_line} =
      Enum.reduce(String.graphemes(text), {[], ""}, fn grapheme, {lines, current_line} ->
        candidate = current_line <> grapheme

        cond do
          current_line == "" and Font.text_width(font, candidate, font_size) <= max_width ->
            {lines, candidate}

          current_line == "" ->
            {[candidate | lines], ""}

          Font.text_width(font, candidate, font_size) <= max_width ->
            {lines, candidate}

          true ->
            {[current_line | lines], grapheme}
        end
      end)

    case current_line do
      "" -> Enum.reverse(lines)
      _ -> Enum.reverse([current_line | lines])
    end
  end

  defp measured_text_width(lines, font, font_size) do
    lines
    |> Enum.map(&Font.text_width(font, &1, font_size))
    |> Enum.max(fn -> 0 end)
  end
end

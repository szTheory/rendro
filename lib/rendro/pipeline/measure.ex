defmodule Rendro.Pipeline.Measure do
  @moduledoc """
  Calculates dimensions for blocks that don't have explicit sizes.

  Operates on the normalized tree from `Rendro.Pipeline.Compose` — every
  table row already contains `%Rendro.Block{}` entries. Measure fills
  missing widths via font metrics and missing heights from font size.
  Idempotent: running twice on the same input yields the same result
  (each `block.width || ...` keeps user-supplied values).
  """

  alias Rendro.PDF.Font
  alias Rendro.Pipeline.MeasuredText
  alias Rendro.Region

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    font = Font.helvetica()

    doc
    |> measure_pages(font)
    |> measure_content(font)
    |> measure_layout(font)
  end

  defp measure_pages(%Rendro.Document{pages: pages} = doc, font) do
    measured_pages = Enum.map(pages, &measure_page(&1, font))
    %{doc | pages: measured_pages}
  end

  defp measure_content(%Rendro.Document{content: content} = doc, font) do
    measured_content = Enum.map(content, &measure_block(&1, font))
    %{doc | content: measured_content}
  end

  defp measure_page(%Rendro.Page{blocks: blocks} = page, font) do
    measured_blocks = Enum.map(blocks, &measure_block(&1, font))
    %{page | blocks: measured_blocks}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Table{} = table, width: nil} = block, font) do
    # For now, simple table measurement
    row_height = 14.4
    col_width = 100
    header_h = if table.header, do: row_height, else: 0
    rows_h = length(table.rows) * row_height
    height = header_h + rows_h
    width = table_width(table, col_width)

    # Rows are already normalized into %Rendro.Block{} entries by Compose (D-02/D-03).
    measured_header = if table.header, do: measure_row(table.header, font), else: nil
    measured_rows = Enum.map(table.rows, &measure_row(&1, font))

    table = %{table | header: measured_header, rows: measured_rows}
    %{block | content: table, width: width, height: height}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, font) do
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
      height: measured_height
    }

    %{block | content: measured_text, width: width, height: height}
  end

  defp measure_block(block, _font), do: block

  defp measure_row(row, font) do
    Enum.map(row, &measure_block(&1, font))
  end

  defp measure_layout(%Rendro.Document{options: %{layout: layout}} = doc, font) do
    measured_region_blocks =
      Enum.into(layout.region_blocks, %{}, fn {name, blocks} ->
        {name, Enum.map(blocks, &measure_block(&1, font))}
      end)

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

  defp measure_layout(%Rendro.Document{} = doc, _font), do: {:ok, doc}

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
    tokens = Regex.split(~r/\s+/, segment, trim: true)

    case tokens do
      [] ->
        [""]

      [token | rest] ->
        token
        |> split_token(max_width, font, font_size)
        |> wrap_tokens(rest, max_width, font, font_size)
    end
  end

  defp wrap_tokens(lines, tokens, max_width, font, font_size) do
    Enum.reduce(tokens, lines, fn token, acc_lines ->
      {leading_lines, [current_line]} = Enum.split(acc_lines, length(acc_lines) - 1)
      candidate = current_line <> " " <> token

      if Font.text_width(font, candidate, font_size) <= max_width do
        leading_lines ++ [candidate]
      else
        acc_lines ++ split_token(token, max_width, font, font_size)
      end
    end)
  end

  defp split_token(token, max_width, font, font_size) do
    {lines, current_line} =
      Enum.reduce(String.graphemes(token), {[], ""}, fn grapheme, {lines, current_line} ->
        candidate = current_line <> grapheme

        cond do
          current_line == "" ->
            if Font.text_width(font, candidate, font_size) <= max_width do
              {lines, candidate}
            else
              {[candidate | lines], ""}
            end

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

  defp table_width(%Rendro.Table{header: header, rows: rows}, col_width) do
    max_columns =
      rows
      |> Enum.map(&length/1)
      |> Kernel.++([if(header, do: length(header), else: 0)])
      |> Enum.max(fn -> 0 end)

    max_columns * col_width
  end
end

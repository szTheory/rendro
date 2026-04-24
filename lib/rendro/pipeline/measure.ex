defmodule Rendro.Pipeline.Measure do
  @moduledoc """
  Calculates dimensions for blocks that don't have explicit sizes.

  Uses font metrics to compute text width and derives height from font size.
  """

  alias Rendro.PDF.Font

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    font = Font.helvetica()

    doc =
      doc
      |> measure_pages(font)
      |> measure_content(font)

    {:ok, doc}
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
    header_h = if table.header, do: row_height, else: 0
    rows_h = length(table.rows) * row_height
    height = header_h + rows_h

    # Normalize rows to blocks
    normalized_header = if table.header, do: normalize_row(table.header), else: nil
    normalized_rows = Enum.map(table.rows, &normalize_row/1)

    # Measure row cells
    measured_header = if normalized_header, do: measure_row(normalized_header, font), else: nil
    measured_rows = Enum.map(normalized_rows, &measure_row(&1, font))

    table = %{table | header: measured_header, rows: measured_rows}
    %{block | content: table, width: 500, height: height}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text, width: nil} = block, font) do
    width = Font.text_width(font, text.content, text.size)
    height = text.size * 1.2
    %{block | width: width, height: height}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text, height: nil} = block, _font) do
    %{block | height: text.size * 1.2}
  end

  defp measure_block(block, _font), do: block

  defp normalize_row(row) do
    Enum.map(row, fn
      %Rendro.Block{} = b -> b
      content when is_binary(content) -> Rendro.block(Rendro.text(content))
      other -> Rendro.block(other)
    end)
  end

  defp measure_row(row, font) do
    Enum.map(row, &measure_block(&1, font))
  end
end

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
    header_h = if table.header, do: row_height, else: 0
    rows_h = length(table.rows) * row_height
    height = header_h + rows_h

    # Rows are already normalized into %Rendro.Block{} entries by Compose (D-02/D-03).
    measured_header = if table.header, do: measure_row(table.header, font), else: nil
    measured_rows = Enum.map(table.rows, &measure_row(&1, font))

    table = %{table | header: measured_header, rows: measured_rows}
    %{block | content: table, width: 500, height: height}
  end

  defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, font) do
    width = block.width || Font.text_width(font, text.content, text.size)
    height = block.height || text.size * 1.2
    %{block | width: width, height: height}
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
end

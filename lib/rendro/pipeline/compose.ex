defmodule Rendro.Pipeline.Compose do
  @moduledoc """
  Resolves document content into positioned elements.

  In the fixed-position API, blocks already carry explicit x/y coordinates,
  so compose passes them through. This stage is the extension point for the
  future flow API where content positions are computed from layout rules.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) do
    composed_pages = Enum.map(pages, &compose_page/1)
    {:ok, %{doc | pages: composed_pages}}
  end

  defp compose_page(%Rendro.Page{blocks: blocks} = page) do
    {composed_blocks, _} =
      Enum.reduce(blocks, {[], 0}, fn block, {acc, current_y} ->
        y = block.y || current_y
        composed_block = compose_block(%{block | y: y})
        next_y = y + (block.height || 0)
        {acc ++ [composed_block], next_y}
      end)

    %{page | blocks: composed_blocks}
  end

  defp compose_block(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
    row_height = 14.4
    col_width = 100

    composed_header =
      if table.header, do: compose_row(table.header, 0, row_height, col_width), else: nil

    header_offset = if table.header, do: row_height, else: 0

    {composed_rows, _} =
      Enum.reduce(table.rows, {[], header_offset}, fn row, {acc, y} ->
        composed_row = compose_row(row, y, row_height, col_width)
        {acc ++ [composed_row], y + row_height}
      end)

    %{block | content: %{table | header: composed_header, rows: composed_rows}}
  end

  defp compose_block(block), do: block

  defp compose_row(row, y, _h, col_width) do
    {composed_row, _} =
      Enum.reduce(row, {[], 0}, fn cell_block, {acc, x} ->
        composed_cell = %{cell_block | x: x, y: y}
        {acc ++ [composed_cell], x + col_width}
      end)

    composed_row
  end
end

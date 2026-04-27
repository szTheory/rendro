defmodule Rendro.Pipeline.Compose do
  @moduledoc """
  Assembles the logical document tree.

  Walks pages and blocks, normalizes table rows so every cell is a
  `%Rendro.Block{}` (D-02), and attaches header/footer templates.
  Compose does NOT assign y-coordinates or compute heights — those
  are Paginate's and Measure's responsibilities.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages, content: content} = doc) do
    composed_pages = Enum.map(pages, &compose_page/1)
    composed_content = Enum.map(content, &compose_block/1)
    {:ok, %{doc | pages: composed_pages, content: composed_content}}
  end

  defp compose_page(%Rendro.Page{blocks: blocks} = page) do
    composed_blocks = Enum.map(blocks, &compose_block/1)
    %{page | blocks: composed_blocks}
  end

  defp compose_block(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
    normalized_header = if table.header, do: normalize_row(table.header), else: nil
    normalized_rows = Enum.map(table.rows, &normalize_row/1)
    %{block | content: %{table | header: normalized_header, rows: normalized_rows}}
  end

  defp compose_block(block), do: block

  defp normalize_row(row) do
    Enum.map(row, fn
      %Rendro.Block{} = b -> b
      content when is_binary(content) -> Rendro.block(Rendro.text(content))
      other -> Rendro.block(other)
    end)
  end
end

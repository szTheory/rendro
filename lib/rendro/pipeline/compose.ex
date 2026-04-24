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
    composed_blocks = Enum.map(blocks, &compose_block(&1, page))
    %{page | blocks: composed_blocks}
  end

  defp compose_block(%Rendro.Block{} = block, %Rendro.Page{}) do
    block
  end
end

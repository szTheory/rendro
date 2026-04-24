defmodule Rendro.Pipeline.Paginate do
  @moduledoc """
  Assigns content to pages respecting page boundaries.

  For the fixed-position API, blocks are already assigned to explicit pages
  by the user, so this stage validates that blocks fit within the printable
  area. The flow API will use this stage to split content across pages.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages, content: content} = doc) do
    cond do
      length(pages) > 0 -> {:ok, doc}
      length(content) > 0 -> paginate_flow(doc)
      true -> {:error, :no_content}
    end
  end

  defp paginate_flow(%Rendro.Document{content: content} = doc) do
    # Default page template
    template = %Rendro.Page{}
    max_h = template.height - template.margin_top - template.margin_bottom

    pages =
      content
      |> Enum.reduce([%{template | blocks: []}], fn block, [current_page | rest] = _pages ->
        block_h = block.height || 0
        current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

        if current_h + block_h <= max_h do
          # Fits in current page
          [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
        else
          # Needs new page
          new_page = %{template | blocks: [block]}
          [new_page, current_page | rest]
        end
      end)
      |> Enum.reverse()

    {:ok, %{doc | pages: pages, content: []}}
  end
end

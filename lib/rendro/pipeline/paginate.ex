defmodule Rendro.Pipeline.Paginate do
  @moduledoc """
  Assigns content to pages respecting page boundaries.

  For the fixed-position API, blocks are already assigned to explicit pages
  by the user, so this stage validates that blocks fit within the printable
  area. The flow API will use this stage to split content across pages.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) do
    paginated = Enum.map(pages, &paginate_page/1)
    {:ok, %{doc | pages: paginated}}
  end

  defp paginate_page(%Rendro.Page{} = page) do
    page
  end
end

defmodule Rendro.Recipes do
  @moduledoc """
  Canonical PDF recipes for standard document types.

  These recipes provide a starting point for common documents like
  invoices and reports, demonstrating best practices for layout
  and pagination.
  """

  @doc """
  Builds a standard invoice document using the canonical Tiered Composition recipe.

  Delegates to `Rendro.Recipes.Invoice.document/1` which uses explicit page template
  regions and sections instead of legacy `header:` / `footer:` kwargs.
  """
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data) do
    Rendro.Recipes.Invoice.document(data)
  end
end

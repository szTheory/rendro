defmodule Rendro.Recipes do
  @moduledoc """
  Canonical PDF recipes for standard document types.

  These recipes provide a starting point for common documents like
  invoices and reports, demonstrating best practices for layout
  and pagination.
  """
  @moduledoc tags: [:stable]

  @doc """
  Builds a standard invoice document using the canonical Tiered Composition recipe.

  Delegates to `Rendro.Recipes.Invoice.document/1` which uses explicit page template
  regions and sections instead of legacy `header:` / `footer:` kwargs.
  """
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data) do
    Rendro.Recipes.Invoice.document(data)
  end

  @doc """
  Builds a branded invoice document using the canonical branded recipe.

  Delegates to `Rendro.Recipes.BrandedInvoice.document/1`, which registers the
  shipped demo brand font and logo before composing the document.
  """
  @spec branded_invoice(map()) :: Rendro.Document.t()
  def branded_invoice(data) do
    Rendro.Recipes.BrandedInvoice.document(data)
  end
end

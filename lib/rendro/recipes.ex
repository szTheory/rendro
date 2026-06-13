defmodule Rendro.Recipes do
  @moduledoc """
  Canonical PDF recipes for standard document types.

  These recipes provide a starting point for common documents like
  invoices and reports, demonstrating best practices for layout
  and pagination.
  """
  @moduledoc tags: [:stable]

  @doc """
  Builds a branded invoice document.

  Delegates to `branded_invoice/2` with an empty opts list.
  See `Rendro.Recipes.BrandedInvoice` for the accepted `## Options`.
  """
  @spec branded_invoice(map()) :: Rendro.Document.t()
  def branded_invoice(data), do: branded_invoice(data, [])

  @doc """
  Builds a branded invoice document with options.

  Delegates to `Rendro.Recipes.BrandedInvoice.document/2`, forwarding `opts` verbatim.
  The recipe module is the single authority for accepted option keys.
  See `Rendro.Recipes.BrandedInvoice` for the `## Options` section.
  """
  @spec branded_invoice(map(), keyword()) :: Rendro.Document.t()
  def branded_invoice(data, opts), do: Rendro.Recipes.BrandedInvoice.document(data, opts)

  @doc """
  Builds a certificate document.

  Delegates to `certificate/2` with an empty opts list.
  See `Rendro.Recipes.Certificate` for the accepted `## Options`.
  """
  @spec certificate(map()) :: Rendro.Document.t()
  def certificate(data), do: certificate(data, [])

  @doc """
  Builds a certificate document with options.

  Delegates to `Rendro.Recipes.Certificate.document/2`, forwarding `opts` verbatim.
  The recipe module is the single authority for accepted option keys.
  See `Rendro.Recipes.Certificate` for the `## Options` section.
  """
  @spec certificate(map(), keyword()) :: Rendro.Document.t()
  def certificate(data, opts), do: Rendro.Recipes.Certificate.document(data, opts)

  @doc """
  Builds a standard invoice document.

  Delegates to `invoice/2` with an empty opts list.
  See `Rendro.Recipes.Invoice` for the accepted `## Options`.
  """
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data), do: invoice(data, [])

  @doc """
  Builds a standard invoice document with options.

  Delegates to `Rendro.Recipes.Invoice.document/2`, forwarding `opts` verbatim.
  The recipe module is the single authority for accepted option keys.
  See `Rendro.Recipes.Invoice` for the `## Options` section.
  """
  @spec invoice(map(), keyword()) :: Rendro.Document.t()
  def invoice(data, opts), do: Rendro.Recipes.Invoice.document(data, opts)

  @doc """
  Builds a receipt document.

  Delegates to `receipt/2` with an empty opts list.
  See `Rendro.Recipes.Receipt` for the accepted `## Options`.
  """
  @spec receipt(map()) :: Rendro.Document.t()
  def receipt(data), do: receipt(data, [])

  @doc """
  Builds a receipt document with options.

  Delegates to `Rendro.Recipes.Receipt.document/2`, forwarding `opts` verbatim.
  The recipe module is the single authority for accepted option keys.
  See `Rendro.Recipes.Receipt` for the `## Options` section.
  """
  @spec receipt(map(), keyword()) :: Rendro.Document.t()
  def receipt(data, opts), do: Rendro.Recipes.Receipt.document(data, opts)

  @doc """
  Builds a statement document.

  Delegates to `statement/2` with an empty opts list.
  See `Rendro.Recipes.Statement` for the accepted `## Options`.
  """
  @spec statement(map()) :: Rendro.Document.t()
  def statement(data), do: statement(data, [])

  @doc """
  Builds a statement document with options.

  Delegates to `Rendro.Recipes.Statement.document/2`, forwarding `opts` verbatim.
  The recipe module is the single authority for accepted option keys.
  See `Rendro.Recipes.Statement` for the `## Options` section.
  """
  @spec statement(map(), keyword()) :: Rendro.Document.t()
  def statement(data, opts), do: Rendro.Recipes.Statement.document(data, opts)
end

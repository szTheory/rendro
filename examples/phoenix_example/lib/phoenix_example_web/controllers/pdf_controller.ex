defmodule PhoenixExampleWeb.PDFController do
  use PhoenixExampleWeb, :controller
  alias Rendro.Adapters.Phoenix, as: RendroPhoenix

  # Realistic dummy invoice data used for the download and preview examples.
  @demo_invoice %{
    id: "INV-2026-001",
    date: ~D[2026-04-30],
    items: [
      %{name: "Consulting Services", qty: 10, price: 2_500},
      %{name: "Support Plan", qty: 1, price: 500}
    ]
  }
  @demo_branded_invoice Map.put(@demo_invoice, :brand, %{
                          font_name: :brand_heading,
                          logo_name: :company_logo
                        })

  def download(conn, _params) do
    doc = Rendro.Recipes.Invoice.document(@demo_invoice)

    RendroPhoenix.render_pdf(conn, doc, "example.pdf")
  end

  def preview(conn, _params) do
    doc = Rendro.Recipes.Invoice.document(@demo_invoice)

    RendroPhoenix.preview_pdf(conn, doc)
  end

  def branded_download(conn, _params) do
    doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)

    RendroPhoenix.render_pdf(conn, doc, "branded_example.pdf")
  end

  def branded_preview(conn, _params) do
    doc = Rendro.Recipes.BrandedInvoice.document(@demo_branded_invoice)

    RendroPhoenix.preview_pdf(conn, doc)
  end
end

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

  def download(conn, _params) do
    doc = Rendro.Recipes.Invoice.document(@demo_invoice)

    RendroPhoenix.render_pdf(conn, doc, "example.pdf")
  end

  def preview(conn, _params) do
    doc = Rendro.Recipes.Invoice.document(@demo_invoice)

    RendroPhoenix.preview_pdf(conn, doc)
  end
end

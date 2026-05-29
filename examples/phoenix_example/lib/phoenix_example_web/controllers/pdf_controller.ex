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

  @demo_statement %{
    period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
    account: %{name: "Acme Corp"},
    opening_balance: Decimal.new("1000.00"),
    lines: [
      %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
      %{date: ~D[2026-05-15], description: "Payment", amount: Decimal.new("-200.00")}
    ]
  }

  @demo_receipt %{
    title: "Payment Receipt",
    date: ~D[2026-05-29],
    customer: %{name: "Acme Corp"},
    lines: [
      %{description: "Widget A", amount: Decimal.new("29.99")},
      %{description: "Widget B", amount: Decimal.new("49.99")}
    ],
    totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
  }

  @demo_certificate %{
    title: "Certificate of Completion",
    recipient: "Jane Smith",
    date: ~D[2026-05-29],
    body: "For outstanding contribution to deterministic PDF generation.",
    seal_line: "Authorized Signature"
  }

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

  def statement_download(conn, _params) do
    doc = Rendro.Recipes.Statement.document(@demo_statement)

    RendroPhoenix.render_pdf(conn, doc, "statement.pdf")
  end

  def statement_preview(conn, _params) do
    doc = Rendro.Recipes.Statement.document(@demo_statement)

    RendroPhoenix.preview_pdf(conn, doc)
  end

  def receipt_download(conn, _params) do
    doc = Rendro.Recipes.Receipt.document(@demo_receipt)

    RendroPhoenix.render_pdf(conn, doc, "receipt.pdf")
  end

  def receipt_preview(conn, _params) do
    doc = Rendro.Recipes.Receipt.document(@demo_receipt)

    RendroPhoenix.preview_pdf(conn, doc)
  end

  def certificate_download(conn, _params) do
    doc = Rendro.Recipes.Certificate.document(@demo_certificate)

    RendroPhoenix.render_pdf(conn, doc, "certificate.pdf")
  end

  def certificate_preview(conn, _params) do
    doc = Rendro.Recipes.Certificate.document(@demo_certificate)

    RendroPhoenix.preview_pdf(conn, doc)
  end
end

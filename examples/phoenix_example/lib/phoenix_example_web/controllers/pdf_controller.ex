defmodule PhoenixExampleWeb.PDFController do
  use Phoenix.Controller, formats: [:html, :json]
  alias Rendro.Adapters.Phoenix, as: RendroPhoenix

  def download(conn, _params) do
    doc = Rendro.flow([
      Rendro.block(Rendro.text("Hello from Phoenix Example!"))
    ])

    RendroPhoenix.render_pdf(conn, doc, "example.pdf")
  end

  def preview(conn, _params) do
    doc = Rendro.flow([
      Rendro.block(Rendro.text("Preview from Phoenix Example!"))
    ])

    RendroPhoenix.preview_pdf(conn, doc)
  end
end

defmodule Rendro.Adapters.Phoenix do
  @moduledoc """
  Phoenix integration for Rendro.

  This module provides helpers for serving PDFs in Phoenix controllers.
  It requires `:phoenix` and `:plug` to be available.
  """

  import Plug.Conn

  @doc """
  Renders a PDF and sends it as a download.
  """
  def render_pdf(conn, doc, filename \\ "document.pdf") do
    case Rendro.render(doc) do
      {:ok, binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, binary)

      {:error, error} ->
        # For now, let Phoenix handle the error or handle it here
        # Ideally, we should provide a way to render a custom error page
        # or return a 500.
        send_resp(conn, 500, "PDF Rendering Error: #{error.reason}")
    end
  end

  @doc """
  Renders a PDF and sends it for inline preview.
  """
  def preview_pdf(conn, doc) do
    case Rendro.render(doc) do
      {:ok, binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "inline")
        |> send_resp(200, binary)

      {:error, error} ->
        send_resp(conn, 500, "PDF Rendering Error: #{error.reason}")
    end
  end
end

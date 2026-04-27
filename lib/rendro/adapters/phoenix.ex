if Code.ensure_loaded?(Plug.Conn) and Code.ensure_loaded?(Phoenix) do
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

        {:error, %Rendro.Error{} = error} ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(500, to_string(error))
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

        {:error, %Rendro.Error{} = error} ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(500, to_string(error))
      end
    end
  end
else
  defmodule Rendro.Adapters.Phoenix do
    @moduledoc false

    def render_pdf(_conn, _doc, _filename \\ "document.pdf") do
      raise RuntimeError, """
      The Rendro Phoenix adapter requires :plug and :phoenix dependencies.
      Please add them to your mix.exs to use Rendro.Adapters.Phoenix.
      """
    end

    def preview_pdf(_conn, _doc) do
      raise RuntimeError, """
      The Rendro Phoenix adapter requires :plug and :phoenix dependencies.
      Please add them to your mix.exs to use Rendro.Adapters.Phoenix.
      """
    end
  end
end

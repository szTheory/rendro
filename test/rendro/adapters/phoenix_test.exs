defmodule Rendro.Adapters.PhoenixTest do
  use ExUnit.Case, async: true

  if Code.ensure_loaded?(Plug.Conn) and Code.ensure_loaded?(Phoenix) do
    import Plug.Test

    alias Rendro.Adapters.Phoenix, as: Adapter

    defp sample_document do
      Rendro.flow([
        Rendro.block(Rendro.text("Phoenix boundary proof"))
      ])
    end

    test "render_pdf/3 sends a PDF attachment response" do
      conn = conn(:get, "/download")

      conn = Adapter.render_pdf(conn, sample_document(), "proof.pdf")

      assert conn.status == 200
      assert conn.state == :sent
      assert conn.resp_body =~ "%PDF-1.4"
      assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/pdf; charset=utf-8"]

      assert Plug.Conn.get_resp_header(conn, "content-disposition") == [
               "attachment; filename=\"proof.pdf\""
             ]
    end

    test "preview_pdf/2 sends an inline PDF response" do
      conn = conn(:get, "/preview")

      conn = Adapter.preview_pdf(conn, sample_document())

      assert conn.status == 200
      assert conn.state == :sent
      assert conn.resp_body =~ "%PDF-1.4"
      assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/pdf; charset=utf-8"]
      assert Plug.Conn.get_resp_header(conn, "content-disposition") == ["inline"]
    end
  else
    test "phoenix adapter boundary proof is unavailable without phoenix and plug" do
      flunk("Phoenix adapter test requires optional :phoenix and :plug deps in the test environment")
    end
  end
end

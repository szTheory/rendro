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

    defp error_document do
      Rendro.flow([
        Rendro.block(Rendro.text("Too big"), height: 2000)
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

    test "error response uses text format by default" do
      conn = conn(:get, "/download")
      
      conn = Adapter.render_pdf(conn, error_document(), "proof.pdf")

      assert conn.status == 500
      assert conn.state == :sent
      assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body =~ "What:  Pagination failed"
      assert conn.resp_body =~ "Why:   content overflow"
    end

    test "error response uses JSON format when requested" do
      conn =
        conn(:get, "/download")
        |> Plug.Conn.put_private(:phoenix_format, "json")

      conn = Adapter.render_pdf(conn, error_document(), "proof.pdf")

      assert conn.status == 500
      assert conn.state == :sent
      assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      
      json = Phoenix.json_library().decode!(conn.resp_body)
      
      assert json["what"] == "Content overflow"
      assert is_binary(json["where"])
      assert is_binary(json["why"])
      assert is_binary(json["next"])
      assert json["stage"] == "paginate"
      assert is_binary(json["render_id"])
      
      refute Map.has_key?(json, "reason")
      refute Map.has_key?(json, "details")
    end
  else
    test "phoenix adapter boundary proof is unavailable without phoenix and plug" do
      flunk(
        "Phoenix adapter test requires optional :phoenix and :plug deps in the test environment"
      )
    end
  end
end

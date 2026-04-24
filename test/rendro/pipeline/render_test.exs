defmodule Rendro.Pipeline.RenderTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Render

  describe "run/1" do
    test "returns {:ok, binary} containing valid PDF" do
      text = %Rendro.Text{content: "Rendered", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, pdf} = Render.run(doc)
      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-1.4")
    end

    test "PDF contains the rendered text" do
      text = %Rendro.Text{content: "Find Me", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      {:ok, pdf} = Render.run(doc)
      assert pdf =~ "(Find Me) Tj"
    end

    test "delegates to PDF.Writer for serialization" do
      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{}
      }

      {:ok, pdf} = Render.run(doc)
      assert pdf =~ "xref"
      assert pdf =~ "trailer"
      assert pdf =~ "%%EOF"
    end
  end
end

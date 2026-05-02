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

    test "handles images and delegates to PDF.Writer for drawing" do
      png_bytes = <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR", 100::32, 50::32>>

      doc =
        Rendro.document()
        |> Rendro.Document.register_image(:logo_png, {:binary, png_bytes})
        |> Map.put(:pages, [
          %Rendro.Page{
            width: 612,
            height: 792,
            margin_left: 72,
            margin_top: 72,
            blocks: [
              %Rendro.Block{
                content: %Rendro.Image{logical_name: :logo_png},
                x: 10,
                y: 20,
                width: 200,
                height: 150
              }
            ]
          }
        ])

      {:ok, pdf} = Render.run(doc)

      assert pdf =~ "/IM_LOGO_PNG Do"
    end
  end
end

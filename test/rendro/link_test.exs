defmodule Rendro.LinkTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, Link, Page}
  alias Rendro.Pipeline.{Measure, MeasuredText}

  describe "measurement" do
    test "measures linked text through the normal block pipeline" do
      linked_block =
        Rendro.block(Rendro.text("Read the guide"), width: 180)
        |> Rendro.link(uri: "https://example.com/guide")

      doc = %Document{pages: [%Page{blocks: [linked_block]}]}

      assert {:ok, measured_doc} = Measure.run(doc)

      [page] = measured_doc.pages
      [measured_block] = page.blocks

      assert %Block{
               width: 180,
               height: height,
               content:
                 %Link{
                   target: {:uri, "https://example.com/guide"},
                   content:
                     %MeasuredText{
                       source: %Rendro.Text{content: "Read the guide"},
                       lines: [[%{text: "Read the guide"} | _]],
                       height: measured_height
                     }
                 }
             } = measured_block

      assert is_number(height)
      assert height > 0
      assert height == measured_height
    end

    test "preserves outer block geometry ownership for linked text" do
      linked_block =
        Rendro.block(Rendro.text("Jump to appendix"), width: 200, height: 28)
        |> Rendro.link(page: 3)

      doc = %Document{pages: [%Page{blocks: [linked_block]}]}

      assert {:ok, measured_doc} = Measure.run(doc)

      [page] = measured_doc.pages
      [measured_block] = page.blocks

      assert %Block{
               width: 200,
               height: 28,
               content:
                 %Link{
                   target: {:page, 3},
                   content: %MeasuredText{}
                 }
             } = measured_block
    end
  end
end

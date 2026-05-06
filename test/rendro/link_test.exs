defmodule Rendro.LinkTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, Link, Page}
  alias Rendro.PDF.Font
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

  describe "fragmentation" do
    test "splits linked measured text into two link-wrapped fragments" do
      linked_text = %Link{content: measured_text(["Line 1", "Line 2", "Line 3"]), target: {:page, 2}}
      block = %Block{content: linked_text, width: 180, height: 36}

      assert {
               %Block{
                 height: 24.0,
                 content: %Link{target: {:page, 2}, content: %MeasuredText{lines: [_, _]}}
               },
               %Block{
                 height: 12.0,
                 content: %Link{target: {:page, 2}, content: %MeasuredText{lines: [_]}}
               }
             } = Rendro.Fragmentable.split(block, 24)
    end

    test "keeps unsplittable linked content in the existing nil-or-component contract" do
      block = %Block{
        content: %Link{content: "static", target: {:uri, "https://example.com/guide"}},
        width: 180,
        height: 36
      }

      assert {nil, ^block} = Rendro.Fragmentable.split(block, 24)
    end
  end

  defp measured_text(lines) do
    %MeasuredText{
      source: Rendro.text(Enum.join(lines, "\n")),
      lines: Enum.map(lines, &[line_run(&1)]),
      line_height: 1.2,
      width: 180,
      height: length(lines) * 12,
      resolved_font: %Font{name: "F1", base_font: "Helvetica"},
      widows: 1,
      orphans: 1
    }
  end

  defp line_run(text), do: %{font: %Font{name: "F1", base_font: "Helvetica"}, text: text, width: 60}
end

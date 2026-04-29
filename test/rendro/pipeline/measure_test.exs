defmodule Rendro.Pipeline.MeasureTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.Compose
  alias Rendro.Pipeline.Measure
  alias Rendro.Pipeline.MeasuredText

  describe "run/1" do
    test "computes width and height for blocks with nil dimensions" do
      text = %Rendro.Text{content: "Hello", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [measured_page] = result.pages
      [measured_block] = measured_page.blocks

      assert is_number(measured_block.width)
      assert measured_block.width > 0
      assert measured_block.height == 12 * 1.2
      assert %MeasuredText{lines: ["Hello"]} = measured_block.content
    end

    test "preserves explicit width, fills in nil height" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 14, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: 200, height: nil}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      [block] = page.blocks

      assert block.width == 200
      assert block.height == 14 * 1.2
    end

    test "preserves explicit width and height" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: 100, height: 50}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      [block] = page.blocks

      assert block.width == 100
      assert block.height == 50
    end

    test "handles empty blocks list" do
      page = %Rendro.Page{blocks: []}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      assert page.blocks == []
    end

    test "measures body capacity from the explicit body region instead of header/footer block heights" do
      template =
        %PageTemplate{
          name: :statement,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 72,
              y: 72,
              width: 451.28,
              height: 48
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 120,
              width: 451.28,
              height: 540
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 72,
              y: 732,
              width: 451.28,
              height: 36
            }
          ]
        }

      doc =
        %Rendro.Document{
          page_template: :statement,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Line item"))],
          header: [Rendro.block(Rendro.text("Tall header"), height: 120)],
          footer: [Rendro.block(Rendro.text("Tall footer"), height: 80)],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, result} = Measure.run(composed)

      layout = result.options.layout

      assert layout.body_capacity == 540
      assert hd(result.header).height == 120
      assert hd(result.footer).height == 80
      assert_in_delta hd(result.content).height, 14.4, 1.0e-9
    end

    test "identical input yields identical wrapped lines" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("alpha beta gamma delta", size: 12, line_height: 1.4),
                  width: 60
                )
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, first} = Measure.run(doc)
      assert {:ok, second} = Measure.run(doc)

      [first_block] = hd(first.pages).blocks
      [second_block] = hd(second.pages).blocks

      assert %MeasuredText{lines: lines} = first_block.content
      assert lines == second_block.content.lines
      assert length(lines) > 1
    end

    test "preserves explicit newlines as distinct measured lines" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("alpha beta\ngamma delta", size: 12), width: 200)
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks

      assert %MeasuredText{lines: ["alpha beta", "gamma delta"]} = block.content
    end

    test "falls back to grapheme wrapping for an oversized token" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("supercalifragilistic", size: 12), width: 25)
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks
      assert %MeasuredText{lines: lines} = block.content

      assert length(lines) > 1
      assert Enum.all?(lines, &(String.length(&1) >= 1))
      assert Enum.join(lines, "") == "supercalifragilistic"
    end

    test "constrained wrapping increases measured height while keeping authored width" do
      text = Rendro.text("alpha beta gamma delta epsilon", size: 12, line_height: 1.5)

      unconstrained_doc =
        %Rendro.Document{
          pages: [%Rendro.Page{blocks: [Rendro.block(text)]}],
          metadata: %Rendro.Metadata{}
        }

      constrained_doc =
        %Rendro.Document{
          pages: [%Rendro.Page{blocks: [Rendro.block(text, width: 70)]}],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, unconstrained} = Measure.run(unconstrained_doc)
      assert {:ok, constrained} = Measure.run(constrained_doc)

      [unconstrained_block] = hd(unconstrained.pages).blocks
      [constrained_block] = hd(constrained.pages).blocks

      assert constrained_block.width == 70
      assert constrained_block.height > unconstrained_block.height
      assert length(constrained_block.content.lines) > 1
    end
  end
end

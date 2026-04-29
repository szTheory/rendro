defmodule Rendro.Pipeline.MeasureTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.Compose
  alias Rendro.Pipeline.Measure

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
  end
end

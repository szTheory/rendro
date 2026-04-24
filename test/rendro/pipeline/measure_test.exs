defmodule Rendro.Pipeline.MeasureTest do
  use ExUnit.Case, async: true

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
  end
end

defmodule Rendro.Pipeline.ComposeTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Compose

  describe "run/1" do
    test "returns {:ok, document} preserving block positions" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 50, y: 100}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Compose.run(doc)
      [composed_page] = result.pages
      [composed_block] = composed_page.blocks
      assert composed_block.x == 50
      assert composed_block.y == 100
      assert composed_block.content == text
    end

    test "handles page with no blocks" do
      page = %Rendro.Page{blocks: []}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Compose.run(doc)
      [composed_page] = result.pages
      assert composed_page.blocks == []
    end

    test "preserves multiple blocks on a page" do
      text1 = %Rendro.Text{content: "First", font: "Helvetica", size: 12, color: {0, 0, 0}}
      text2 = %Rendro.Text{content: "Second", font: "Helvetica", size: 14, color: {255, 0, 0}}

      doc = %Rendro.Document{
        pages: [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: text1, x: 10, y: 20},
              %Rendro.Block{content: text2, x: 30, y: 40}
            ]
          }
        ],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, result} = Compose.run(doc)
      [page] = result.pages
      assert length(page.blocks) == 2
    end
  end
end

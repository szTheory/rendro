defmodule Rendro.Pipeline.PaginateTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Paginate

  describe "run/1" do
    test "returns {:ok, document} passing through pages" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Paginate.run(doc)
      assert length(result.pages) == 1
    end

    test "preserves multiple pages" do
      page1 = %Rendro.Page{blocks: []}
      page2 = %Rendro.Page{blocks: []}

      doc = %Rendro.Document{
        pages: [page1, page2],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, result} = Paginate.run(doc)
      assert length(result.pages) == 2
    end

    test "preserves block content through pagination" do
      text = %Rendro.Text{content: "Keep Me", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 10, y: 20, width: 100, height: 14.4}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Paginate.run(doc)
      [page] = result.pages
      [block] = page.blocks
      assert block.content.content == "Keep Me"
    end
  end
end

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

  describe "y-stacking with per-page reset (D-04 regression)" do
    test "page-2 remainder rows have y reset to page top, not inherited from page-1 last block" do
      # 50 text blocks at 14.4pt line height = ~720pt — overflows a default
      # 841.89pt page (after margin_top + footer reservation). Should produce
      # 2 pages.
      content = for i <- 1..50, do: Rendro.block(Rendro.text("Line #{i}"))
      doc = Rendro.flow(content)

      # Run through the full pre-paginate chain so blocks have heights:
      {:ok, doc} = Rendro.Pipeline.Build.run(doc)
      {:ok, doc} = Rendro.Pipeline.Compose.run(doc)
      {:ok, doc} = Rendro.Pipeline.Measure.run(doc)
      assert {:ok, paginated} = Rendro.Pipeline.Paginate.run(doc)

      assert length(paginated.pages) >= 2,
             "expected ≥2 pages from 50 lines; got #{length(paginated.pages)}"

      # Find the first non-template (non-header/footer) block on page 2 and
      # assert its y is NOT in the bottom half of page 1.
      [page1, page2 | _] = paginated.pages
      page1_max_y = page1.blocks |> Enum.map(&(&1.y || 0)) |> Enum.max()
      page2_min_y = page2.blocks |> Enum.map(&(&1.y || 0)) |> Enum.min()

      assert page2_min_y < page1_max_y,
             "page-2 first block y=#{page2_min_y} should reset (not inherit from page-1 max y=#{page1_max_y})"

      # Tighter check: page-2 first content block y should be near the page top
      # (margin_top + a small offset for the first block height).
      assert page2_min_y <= (page2.margin_top || 0) + 50,
             "page-2 first block y=#{page2_min_y} should be near page top (margin_top=#{page2.margin_top})"
    end
  end
end

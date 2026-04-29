defmodule Rendro.Pipeline.PaginateTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}

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

    test "returns structured overflow details when a fixed-position block exceeds page bounds" do
      oversized =
        %Rendro.Block{
          content: Rendro.text("Outside"),
          x: 440,
          y: 20,
          width: 120,
          height: 14.4
        }

      page = %Rendro.Page{blocks: [oversized]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:error, %Rendro.Error{} = error} = Paginate.run(doc)
      assert error.stage == :paginate
      assert error.reason == :content_overflow
      assert error.details.overflow_source == :fixed_page
      assert error.details.page_index == 1
      assert error.details.block_index == 0
      assert error.details.block == %{x: 440, y: 20, width: 120, height: 14.4}
      assert error.details.bounds == %{x: 0, y: 0, width: 451.28, height: 697.89}
    end

    test "uses authored page-template geometry for flow pagination" do
      template =
        %PageTemplate{
          name: :compact,
          width: 420,
          height: 240,
          margin_top: 20,
          margin_right: 24,
          margin_bottom: 28,
          margin_left: 24,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 24,
              y: 24,
              width: 372,
              height: 20
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 24,
              y: 52,
              width: 372,
              height: 28.8
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 24,
              y: 188,
              width: 372,
              height: 16
            }
          ]
        }

      doc =
        Rendro.flow(
          for(i <- 1..5, do: Rendro.block(Rendro.text("Line #{i}"))),
          page_template: :compact,
          page_templates: [template]
        )

      {:ok, doc} = Build.run(doc)
      {:ok, doc} = Compose.run(doc)
      {:ok, doc} = Measure.run(doc)
      assert {:ok, paginated} = Paginate.run(doc)

      assert length(paginated.pages) == 3
      assert Enum.map(paginated.pages, & &1.width) == [420, 420, 420]
      assert Enum.map(paginated.pages, & &1.margin_top) == [20, 20, 20]

      line_blocks =
        Enum.map(paginated.pages, fn page ->
          Enum.filter(page.blocks, fn
            %Rendro.Block{content: %Rendro.Text{content: <<"Line ", _::binary>>}} -> true
            _ -> false
          end)
        end)

      assert Enum.map(line_blocks, &length/1) == [2, 2, 1]
      assert Enum.map(hd(line_blocks), & &1.y) == [32, 46.4]
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
      {:ok, doc} = Build.run(doc)
      {:ok, doc} = Compose.run(doc)
      {:ok, doc} = Measure.run(doc)
      assert {:ok, paginated} = Paginate.run(doc)

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

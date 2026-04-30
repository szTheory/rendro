defmodule Rendro.Pipeline.PaginateTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.{Build, Compose, Measure, MeasuredText, Paginate}

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
            %Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: <<"Line ", _::binary>>}}} ->
              true

            %Rendro.Block{content: %Rendro.Text{content: <<"Line ", _::binary>>}} ->
              true

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

  describe "flow break semantics" do
    test "moves a chained keep_with_next group intact onto the next page" do
      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Intro")),
            Rendro.block(Rendro.text("Chapter"), keep_with_next: true),
            Rendro.block(Rendro.text("Subhead"), keep_with_next: true),
            Rendro.block(Rendro.text("Body"))
          ],
          page_template: :flow_keep_chain,
          page_templates: [flow_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)

      assert length(paginated.pages) == 2
      assert page_texts(Enum.at(paginated.pages, 0)) == ["Intro"]
      assert page_texts(Enum.at(paginated.pages, 1)) == ["Chapter", "Subhead", "Body"]
    end

    test "forces a fresh page after a block with break_after" do
      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("First"), break_after: true),
            Rendro.block(Rendro.text("Second"))
          ],
          page_template: :flow_keep_chain,
          page_templates: [flow_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)

      assert length(paginated.pages) == 2
      assert page_texts(Enum.at(paginated.pages, 0)) == ["First"]
      assert page_texts(Enum.at(paginated.pages, 1)) == ["Second"]
    end
  end

  describe "typed paginate diagnostics" do
    test "uses authored :row_atomic split policy for table continuation" do
      table =
        %Rendro.Table{
          header: [%Rendro.Block{content: Rendro.text("Header")}],
          rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
          split_policy: :row_atomic,
          column_widths: [100]
        }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :flow_keep_chain,
          page_templates: [flow_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2
      assert Enum.any?(paginated.diagnostics, &(&1.type == :table_split))
    end

    test "treats the temporary :atomic alias as runtime-equivalent to :row_atomic" do
      table =
        %Rendro.Table{
          header: [%Rendro.Block{content: Rendro.text("Header")}],
          rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
          split_policy: :atomic,
          column_widths: [100]
        }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :flow_keep_chain,
          page_templates: [flow_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2
      assert Enum.any?(paginated.diagnostics, &(&1.type == :table_split))
    end

    test "returns a typed paginate error for unsupported table split policies" do
      table =
        %Rendro.Table{
          header: [%Rendro.Block{content: Rendro.text("Header")}],
          rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
          split_policy: :whole_table,
          column_widths: [100]
        }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :flow_keep_chain,
          page_templates: [flow_keep_chain_template()]
        )

      assert {:error, %Rendro.Error{} = error} = paginate_flow(doc)
      assert error.stage == :paginate
      assert error.reason == :unsupported_table_split_policy
      assert error.details.split_policy == :whole_table
      assert error.details.supported_split_policies == [:row_atomic]
      assert error.next =~ "split_policy: :row_atomic"
    end

    test "records table split diagnostics" do
      table = %Rendro.Table{
        rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
        column_widths: [100]
      }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.diagnostics) > 0
      
      first_diag = Enum.find(paginated.diagnostics, &(&1.type == :table_split))
      assert first_diag
      assert first_diag.level == :info
      assert first_diag.page_index == 1
      assert first_diag.reason == :insufficient_height
    end

    test "records keep rule break diagnostics" do
      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Line 1")),
            Rendro.block(Rendro.text("Line 2"), keep_with_next: true),
            Rendro.block(Rendro.text("Line 3")),
            Rendro.block(Rendro.text("Line 4"))
          ],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      
      diag = Enum.find(paginated.diagnostics, &(&1.type == :keep_rule_break))
      assert diag
      assert diag.level == :info
      assert diag.keep_rule == :keep_with_next
      assert diag.page_index == 2
    end

    test "returns keep-rule details when a chained keep_with_next group cannot fit on any page" do
      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Intro")),
            Rendro.block(Rendro.text("Chapter"), keep_with_next: true),
            Rendro.block(Rendro.text("Subhead"), keep_with_next: true),
            Rendro.block(Rendro.text("Body"))
          ],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:error, %Rendro.Error{} = error} = paginate_flow(doc)

      assert error.stage == :paginate
      assert error.reason == :content_overflow
      assert error.details.keep_rule == :keep_with_next
      assert_in_delta error.details.kept_height, 43.2, 0.001
      assert error.details.max_height == 30
      assert error.details.page_index == 2
      assert error.details.region == :body
      assert error.details.overflow_source == :bounded_region
      assert error.details.block_indexes == [1, 2, 3]
    end

    test "rejects flow directives on fixed-position pages with a typed paginate error" do
      page =
        %Rendro.Page{
          blocks: [
            %Rendro.Block{
              content: Rendro.text("Fixed"),
              x: 10,
              y: 10,
              width: 80,
              height: 14.4,
              break_before: true
            }
          ]
        }

      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:error, %Rendro.Error{} = error} = Paginate.run(doc)
      assert error.stage == :paginate
      assert error.reason == :invalid_flow_directive
      assert error.details.directive == :break_before
      assert error.details.page_index == 1
      assert error.details.block_index == 0
      assert error.next =~ "Rendro.flow/2"
    end

    test "rejects nested flow directives inside fixed-page tables" do
      page =
        %Rendro.Page{
          blocks: [
            %Rendro.Block{
              content: %Rendro.Table{
                rows: [
                  [
                    %Rendro.Block{
                      content: Rendro.text("Nested fixed"),
                      x: 0,
                      y: 0,
                      width: 80,
                      height: 14.4,
                      break_before: true
                    }
                  ]
                ]
              },
              x: 10,
              y: 10,
              width: 100,
              height: 14.4
            }
          ]
        }

      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:error, %Rendro.Error{} = error} = Paginate.run(doc)
      assert error.stage == :paginate
      assert error.reason == :invalid_flow_directive
      assert error.details.directive == :break_before
      assert error.details.page_index == 1
      assert error.details.block_index == 0
    end
  end

  defp paginate_flow(doc) do
    {:ok, doc} = Build.run(doc)
    {:ok, doc} = Compose.run(doc)
    {:ok, doc} = Measure.run(doc)
    Paginate.run(doc)
  end

  defp page_texts(page) do
    Enum.map(page.blocks, fn
      %Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: content}}} -> content
      %Rendro.Block{content: %Rendro.Text{content: content}} -> content
    end)
  end

  defp flow_keep_chain_template do
    %PageTemplate{
      name: :flow_keep_chain,
      width: 420,
      height: 240,
      margin_top: 20,
      margin_right: 24,
      margin_bottom: 28,
      margin_left: 24,
      regions: [
        %Region{
          name: :body,
          role: :body,
          anchor: :flow,
          x: 24,
          y: 52,
          width: 372,
          height: 50
        }
      ]
    }
  end

  defp tiny_keep_chain_template do
    %{flow_keep_chain_template() | name: :tiny_keep_chain, regions: [%Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 30}]}
  end
end

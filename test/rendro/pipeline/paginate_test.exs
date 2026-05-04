defmodule Rendro.Pipeline.PaginateTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.{Build, Compose, Measure, MeasuredText, Paginate}
  alias Rendro.TestSupport.FontFixture

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
            %Rendro.Block{
              content: %MeasuredText{source: %Rendro.Text{content: <<"Line ", _::binary>>}}
            } ->
              true

            %Rendro.Block{content: %Rendro.Text{content: <<"Line ", _::binary>>}} ->
              true

            _ ->
              false
          end)
        end)

      assert Enum.map(line_blocks, &length/1) == [2, 2, 1]
      assert Enum.map(hd(line_blocks), & &1.y) == [32, 46.4]
    end

    test "paginates from embedded-font-derived measured heights deterministically" do
      %{bytes: bytes} = FontFixture.supported_font()
      template = embedded_wrap_template()
      content = "alpha beta gamma delta"

      built_in_doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text(content, font: :default, size: 12), width: 100),
            Rendro.block(Rendro.text(content, font: :default, size: 12), width: 100)
          ],
          page_template: :embedded_wrap,
          page_templates: [template]
        )

      embedded_doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})
        |> Map.put(:content, [
          Rendro.block(Rendro.text(content, font: :brand, size: 12), width: 100),
          Rendro.block(Rendro.text(content, font: :brand, size: 12), width: 100)
        ])
        |> Map.put(:page_template, :embedded_wrap)
        |> Map.put(:page_templates, [template])

      assert {:ok, built_in_paginated} = paginate_flow(built_in_doc)
      assert {:ok, embedded_paginated} = paginate_flow(embedded_doc)

      assert length(built_in_paginated.pages) == 2
      assert length(embedded_paginated.pages) == 2

      [built_in_page_1, built_in_page_2] = built_in_paginated.pages
      [built_in_block_1] = built_in_page_1.blocks
      [built_in_block_2] = built_in_page_2.blocks

      lines_text = fn b ->
        Enum.map(b.content.lines, fn l -> Enum.map_join(l, "", & &1.text) end)
      end

      assert lines_text.(built_in_block_1) == ["alpha beta gamma", " delta"]
      assert lines_text.(built_in_block_2) == ["alpha beta gamma", " delta"]

      embedded_page_lines =
        Enum.map(embedded_paginated.pages, fn page ->
          Enum.map(page.blocks, lines_text)
        end)

      embedded_line_sets = Enum.flat_map(embedded_page_lines, & &1)

      assert embedded_page_lines == [
               [["alpha beta ", "gamma delta"]],
               [["alpha beta ", "gamma delta"]]
             ]

      assert Enum.all?(embedded_line_sets, &(length(&1) == 2))

      assert Enum.all?(List.flatten(Enum.map(embedded_paginated.pages, & &1.blocks)), fn block ->
               %MeasuredText{resolved_font: resolved_font, height: height} = block.content
               resolved_font.source == :embedded and abs(height - 28.8) < 1.0e-9
             end)
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

      assert [%{level: :info, type: :table_split, page_index: 1, reason: :insufficient_height}] =
               paginated.diagnostics
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

      assert [%{level: :info, type: :table_split, page_index: 1, reason: :insufficient_height}] =
               paginated.diagnostics
    end

    test "emits keep-rule diagnostics when a keep_with_next group moves to a fresh page" do
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

      assert [%{level: :info, type: :keep_rule_break, keep_rule: :keep_with_next, page_index: 2}] =
               paginated.diagnostics
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
      assert error.details.supported_split_policies == [:row_atomic, :fragment]
      assert error.next =~ "split_policy: :row_atomic"
    end

    test "rejects unsupported table split policies even when the table fits on the current page" do
      table =
        %Rendro.Table{
          header: [%Rendro.Block{content: Rendro.text("Header")}],
          rows: [[%Rendro.Block{content: Rendro.text("Only row")}]],
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
      assert error.details.supported_split_policies == [:row_atomic, :fragment]
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
      assert paginated.diagnostics != []

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

  describe "predictive text splitting" do
    test "splits a MeasuredText block across pages" do
      # Create a template with a body region that holds exactly 2 lines of text
      # at 14.4 line height (e.g. height 30)
      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Line 1\nLine 2\nLine 3\nLine 4", widows: 1, orphans: 1))
          ],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2

      page1 = Enum.at(paginated.pages, 0)
      page2 = Enum.at(paginated.pages, 1)

      assert length(page1.blocks) == 1
      assert length(page2.blocks) == 1

      [block1] = page1.blocks
      [block2] = page2.blocks

      assert length(block1.content.lines) == 2
      assert length(block2.content.lines) == 2

      # Check for diagnostics
      diag = Enum.find(paginated.diagnostics, &(&1.type == :text_split))
      assert diag
      assert diag.level == :info
      assert diag.page_index == 1
    end

    test "respects orphans constraint: pushes entire block if it would leave orphans" do
      # 4 lines total, body region height 20 (fits 1 line)
      # Orphans constraint is 2. So it can't split leaving 1 line on page 1.
      # Must push entirely to page 2 and error on overflow.
      template = %{
        tiny_keep_chain_template()
        | name: :tiny_height,
          regions: [
            %Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 20}
          ]
      }

      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Line 1\nLine 2\nLine 3\nLine 4", widows: 1, orphans: 2))
          ],
          page_template: :tiny_height,
          page_templates: [template]
        )

      assert {:error, %Rendro.Error{} = error} = paginate_flow(doc)
      assert error.reason == :content_overflow
      # It failed on the first page initially pushing to page 2? Wait, the unfittable rule:
      # If current_h == 0 and it can't split, throw error.
      # On page 1, current_h is 0, so it will throw content_overflow immediately, right?
      # Or it tries to push to next page. The logic: if current_h > 0, we can push to next page.
      # If current_h == 0, we are already at the top of the page. If it can't fit/split, it's an error.
      assert error.details.page_index == 1
    end

    test "respects widows constraint: reduces lines on current page" do
      # 4 lines total, body height fits 3 lines.
      # Widows = 2 (meaning we need at least 2 lines on the next page).
      # It should split after 2 lines, pushing 2 to the next page.
      template = %{
        tiny_keep_chain_template()
        | name: :medium_height,
          regions: [
            %Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 45}
          ]
      }

      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Line 1\nLine 2\nLine 3\nLine 4", widows: 2, orphans: 1))
          ],
          page_template: :medium_height,
          page_templates: [template]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2

      page1 = Enum.at(paginated.pages, 0)
      page2 = Enum.at(paginated.pages, 1)

      [block1] = page1.blocks
      [block2] = page2.blocks

      # Should be 2 and 2, not 3 and 1
      assert length(block1.content.lines) == 2
      assert length(block2.content.lines) == 2
    end

    test "re-checks orphans constraint after widows adjustment" do
      # 5 lines total. Body height is 80.
      # On page 1: "Previous line" takes ~14.4, leaving ~65.6 available.
      # 65.6 fits 4 lines (4 * 14.4 = 57.6).
      # Widows = 2 (needs 2 on next page). Total=5, fitting=4. So we need 2 on next page,
      # which means we can only put 5 - 2 = 3 lines on page 1.
      # But Orphans = 4 (needs 4 on page 1). So 3 is not enough for orphans!
      # It must push the entire block to the next page.
      # On page 2: full 80 height available, 5 lines (72.0) will fit perfectly.
      template = %{
        tiny_keep_chain_template()
        | name: :medium_height_4,
          regions: [
            %Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 80}
          ]
      }

      doc =
        Rendro.flow(
          [
            # takes up 1 line (approx 14.4 height). Leaves ~45 height (fits 3 lines).
            Rendro.block(Rendro.text("Previous line")),
            Rendro.block(
              Rendro.text("Line 1\nLine 2\nLine 3\nLine 4\nLine 5", widows: 3, orphans: 3)
            )
          ],
          page_template: :medium_height_4,
          page_templates: [template]
        )

      # 1st block takes 14.4. Remaining height ~45.6 (fits 3 lines).
      # So we try to fit 3 lines of block 2.
      # Widows=3. Total=5. 5 - 3 = 2. So we can only fit 2 lines on page 1.
      # But orphans=3! So fitting 2 lines violates orphans.
      # It should push the whole block 2 to next page.

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2

      page1 = Enum.at(paginated.pages, 0)
      page2 = Enum.at(paginated.pages, 1)

      # Only "Previous line"
      assert length(page1.blocks) == 1
      # The whole 5 lines
      assert length(page2.blocks) == 1

      [block2] = page2.blocks
      assert length(block2.content.lines) == 5
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
    %{
      flow_keep_chain_template()
      | name: :tiny_keep_chain,
        regions: [
          %Region{name: :body, role: :body, anchor: :flow, x: 24, y: 52, width: 372, height: 30}
        ]
    }
  end

  defp embedded_wrap_template do
    %PageTemplate{
      name: :embedded_wrap,
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
          height: 30
        }
      ]
    }
  end

  describe "Table Fragmentation (:fragment policy)" do
    test "slices the 2D grid horizontally at available_h" do
      table = %Rendro.Table{
        rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
        split_policy: :fragment,
        column_widths: [100]
      }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      assert length(paginated.pages) == 2

      # The first page should have the first part of the table
      page1 = Enum.at(paginated.pages, 0)
      [block1] = page1.blocks
      assert length(block1.content.rows) < 3

      page2 = Enum.at(paginated.pages, 1)
      [block2] = page2.blocks
      assert block2.content.rows != []
    end

    test "continuation tables include the header if repeat_header: true" do
      table = %Rendro.Table{
        header: [%Rendro.Block{content: Rendro.text("Header")}],
        rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
        split_policy: :fragment,
        repeat_header: true,
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

      page2 = Enum.at(paginated.pages, 1)
      [block2] = page2.blocks
      # The continued table on page 2 should have the header
      assert block2.content.header != nil
      %Rendro.Row{cells: [header_cell]} = block2.content.header
      assert header_cell.content.content.source.content == "Header"
    end

    test "border definitions respect decoration_break: :slice" do
      table = %Rendro.Table{
        rows: for(i <- 1..3, do: [%Rendro.Block{content: Rendro.text("Row #{i}")}]),
        split_policy: :fragment,
        decoration_break: :slice,
        column_widths: [100]
      }

      doc =
        Rendro.flow(
          [Rendro.block(table)],
          page_template: :tiny_keep_chain,
          page_templates: [tiny_keep_chain_template()]
        )

      assert {:ok, paginated} = paginate_flow(doc)
      page1 = Enum.at(paginated.pages, 0)
      [block1] = page1.blocks
      assert block1.content.decoration_break == :slice
    end
  end
end

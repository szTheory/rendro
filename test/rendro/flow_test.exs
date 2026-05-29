defmodule Rendro.FlowTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}
  alias Rendro.Pipeline.MeasuredText

  test "flow document paginates correctly" do
    content =
      for i <- 1..50 do
        Rendro.block(Rendro.text("Line #{i}"))
      end

    doc = Rendro.flow(content)
    {:ok, pdf} = Rendro.render(doc)

    # 50 lines at ~14.4 units each (12 * 1.2)
    # Page height is 841.89, margins are 72+72=144. Available: 697.89
    # 50 * 14.4 = 720. Should be 2 pages.

    assert pdf =~ "Line 1"
    assert pdf =~ "Line 50"

    # Check that we have two pages in the PDF
    # The PDF structure has /Type /Page
    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2
  end

  test "fixed document still works" do
    page = Rendro.page(blocks: [Rendro.block(Rendro.text("Fixed!"), x: 10, y: 10)])
    doc = Rendro.fixed([page])
    {:ok, pdf} = Rendro.render(doc)

    assert pdf =~ "Fixed!"
    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 1
  end

  test "flow document with table" do
    table =
      Rendro.table(
        [
          ["A1", "B1"],
          ["A2", "B2"]
        ],
        header: ["Col A", "Col B"],
        columns: [{:fixed, 50}, {:share, 1}]
      )

    doc =
      Rendro.flow([
        Rendro.block(Rendro.text("Above Table")),
        Rendro.block(table),
        Rendro.block(Rendro.text("Below Table"))
      ])

    {:ok, pdf} = Rendro.render(doc)

    assert pdf =~ "Above Table"
    assert pdf =~ "Col A"
    assert pdf =~ "Col B"
    assert pdf =~ "A1"
    assert pdf =~ "B1"
    assert pdf =~ "A2"
    assert pdf =~ "B2"
    assert pdf =~ "Below Table"
  end

  test "table splitting and header repetition" do
    # 50 rows, each ~14.4 units. Total ~720 units.
    # Header is another 14.4 units. Total ~734.4 units.
    # Page available: 697.89.
    # Should split across 2 pages.

    rows = for i <- 1..50, do: ["A#{i}", "B#{i}"]
    table = Rendro.table(rows, header: ["Col A", "Col B"], split_policy: :row_atomic)

    doc = Rendro.flow([Rendro.block(table)])
    {:ok, pdf} = Rendro.render(doc)

    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2

    # "Col A" and "Col B" should appear twice (once per page)
    assert length(Regex.scan(~r/\(Col A\) Tj/, pdf)) == 2
    assert length(Regex.scan(~r/\(Col B\) Tj/, pdf)) == 2

    assert pdf =~ "(A1) Tj"
    assert pdf =~ "(A50) Tj"
  end

  test "returns overflow error when block is too large" do
    # Huge block height (e.g. 2000 units on a 841 unit page)
    block = %Rendro.Block{content: Rendro.text("Too big"), height: 2000}
    doc = Rendro.flow([block])

    assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
    assert error.stage == :paginate
    assert error.reason == :content_overflow
    assert error.details.overflow_source == :bounded_region
    assert error.details.region == :body
    assert error.next =~ "expand the declared page/region bounds"
  end

  test "headers, footers and page numbers" do
    header = [Rendro.block(Rendro.text("My Report"))]
    footer = [Rendro.block(Rendro.text("Page {{page_number}}"))]

    content =
      for i <- 1..50 do
        Rendro.block(Rendro.text("Line #{i}"))
      end

    doc = Rendro.flow(content, header: header, footer: footer)
    {:ok, pdf} = Rendro.render(doc)

    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2

    # "My Report" on both pages
    assert length(Regex.scan(~r/\(My Report\) Tj/, pdf)) == 2

    # Page numbers
    assert pdf =~ "(Page 1) Tj"
    assert pdf =~ "(Page 2) Tj"
  end

  test "{{total_pages}} substitutes the real page count on every page (PAGE-01)" do
    footer = [Rendro.block(Rendro.text("Page {{page_number}} of {{total_pages}}"))]

    content =
      for i <- 1..50 do
        Rendro.block(Rendro.text("Line #{i}"))
      end

    doc = Rendro.flow(content, footer: footer)
    {:ok, pdf} = Rendro.render(doc)

    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2

    # PAGE-01: {{total_pages}} replaced with real page count on every page
    assert pdf =~ "(Page 1 of 2) Tj"
    assert pdf =~ "(Page 2 of 2) Tj"

    # Sanity: raw tokens must not appear in the output
    refute pdf =~ "{{page_number}}"
    refute pdf =~ "{{total_pages}}"
  end

  test "suppress_on: :first suppresses footer on first page only" do
    flunk "not yet implemented"
  end

  test "body blocks do not overlap footer region (y + height <= footer.y)" do
    flunk "not yet implemented"
  end

  test "explicit page templates anchor repeated header and footer regions deterministically" do
    template =
      Rendro.page_template(
        name: :statement,
        width: 420,
        height: 220,
        margin_top: 20,
        margin_right: 24,
        margin_bottom: 20,
        margin_left: 24,
        regions: [
          Rendro.region(
            name: :header,
            role: :header,
            anchor: :top,
            x: 24,
            y: 24,
            width: 372,
            height: 20
          ),
          Rendro.region(
            name: :body,
            role: :body,
            anchor: :flow,
            x: 24,
            y: 52,
            width: 372,
            height: 60
          ),
          Rendro.region(
            name: :footer,
            role: :footer,
            anchor: :bottom,
            x: 24,
            y: 180,
            width: 372,
            height: 16
          )
        ]
      )

    content =
      for i <- 1..8 do
        Rendro.block(Rendro.text("Line #{i}"))
      end

    doc =
      Rendro.flow(content,
        page_template: :statement,
        page_templates: [template],
        header: [Rendro.block(Rendro.text("Statement Header"))],
        footer: [Rendro.block(Rendro.text("Page {{page_number}}"))]
      )

    {:ok, built} = Build.run(doc)
    {:ok, composed} = Compose.run(built)
    {:ok, measured} = Measure.run(composed)
    assert {:ok, paginated} = Paginate.run(measured)

    assert length(paginated.pages) == 2

    [page1, page2] = paginated.pages

    header1 =
      Enum.find(
        page1.blocks,
        &match?(
          %Rendro.Block{
            content: %MeasuredText{source: %Rendro.Text{content: "Statement Header"}}
          },
          &1
        )
      )

    header2 =
      Enum.find(
        page2.blocks,
        &match?(
          %Rendro.Block{
            content: %MeasuredText{source: %Rendro.Text{content: "Statement Header"}}
          },
          &1
        )
      )

    footer1 =
      Enum.find(
        page1.blocks,
        &match?(
          %Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: "Page 1"}}},
          &1
        )
      )

    footer2 =
      Enum.find(
        page2.blocks,
        &match?(
          %Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: "Page 2"}}},
          &1
        )
      )

    assert header1.y == 4
    assert header2.y == 4
    assert footer1.y == 160
    assert footer2.y == 160

    {:ok, pdf} = Rendro.render(doc)
    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2
    assert length(Regex.scan(~r/\(Statement Header\) Tj/, pdf)) == 2
    assert pdf =~ "(Page 1) Tj"
    assert pdf =~ "(Page 2) Tj"
  end

  test "render/1 returns truthful bounded-region overflow details" do
    template =
      Rendro.page_template(
        name: :tight_body,
        width: 420,
        height: 220,
        margin_top: 20,
        margin_right: 24,
        margin_bottom: 20,
        margin_left: 24,
        regions: [
          Rendro.region(
            name: :body,
            role: :body,
            anchor: :flow,
            x: 24,
            y: 52,
            width: 372,
            height: 10
          )
        ]
      )

    doc =
      Rendro.flow([Rendro.block(Rendro.text("Too tall for the body region"))],
        page_template: :tight_body,
        page_templates: [template]
      )

    assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
    assert error.stage == :paginate
    assert error.reason == :content_overflow
    assert error.details.overflow_source == :bounded_region
    assert error.details.region == :body
    assert error.details.page_index == 1
    assert error.next =~ "expand the declared page/region bounds"
    assert error.next =~ "does not auto-fit"
  end

  test "flow render uses measured wrapped lines and keeps page counts stable" do
    long_line =
      "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi"

    content = [
      Rendro.block(
        Rendro.text(long_line, size: 12, line_height: 1.4),
        width: 100,
        keep_with_next: true
      ),
      Rendro.block(Rendro.text("Summary block", size: 12), break_after: true),
      Rendro.block(Rendro.text("Next page", size: 12))
    ]

    doc = Rendro.flow(content)

    assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)

    wrapped_ops = Regex.scan(~r/\) Tj/, pdf1)

    assert length(wrapped_ops) >= 4
    assert pdf1 =~ "(Summary block) Tj"
    assert pdf1 =~ "(Next page) Tj"
    refute pdf1 =~ "(" <> long_line <> ") Tj"
    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf1)) == 2
    assert length(Regex.scan(~r"/Type\s*/Page\b", pdf2)) == 2
  end
end

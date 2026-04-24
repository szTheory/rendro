defmodule Rendro.FlowTest do
  use ExUnit.Case, async: true

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
    table = Rendro.table([
      ["A1", "B1"],
      ["A2", "B2"]
    ], header: ["Col A", "Col B"])

    doc = Rendro.flow([
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
    table = Rendro.table(rows, header: ["Col A", "Col B"])

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
    assert error.next =~ "Reduce the height"
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
end

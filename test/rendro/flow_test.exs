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
end

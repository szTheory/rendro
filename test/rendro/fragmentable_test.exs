defmodule Rendro.FragmentableTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Table, Row, Cell}
  alias Rendro.Pipeline.MeasuredText

  test "splitting a block that fits returns the block and nil" do
    block = %Block{height: 100, content: "static"}
    assert {^block, nil} = Rendro.Fragmentable.split(block, 150)
  end

  test "splitting a block that doesn't fit and has unfragmentable content returns nil and block" do
    block = %Block{height: 100, content: "static"}
    assert {nil, ^block} = Rendro.Fragmentable.split(block, 50)
  end

  test "splitting measured text correctly slices lines" do
    text = %MeasuredText{
      height: 100,
      width: 100,
      line_height: 25,
      resolved_font: %Rendro.PDF.Font{},
      lines: [[:run1], [:run2], [:run3], [:run4]],
      widows: 1,
      orphans: 1,
      source: %Rendro.Text{content: "..."}
    }

    # line height is 25. 60 available height fits 2 lines.
    {tb, rb} = Rendro.Fragmentable.split(text, 60)
    assert length(tb.lines) == 2
    assert tb.height == 50
    assert length(rb.lines) == 2
    assert rb.height == 50
  end

  test "splitting a table at row boundary" do
    table = %Table{
      header_height: 20,
      repeat_header: true,
      row_heights: [40, 40, 40],
      rows: [
        %Row{cells: [%Cell{content: %Block{height: 40, content: "1"}}]},
        %Row{cells: [%Cell{content: %Block{height: 40, content: "2"}}]},
        %Row{cells: [%Cell{content: %Block{height: 40, content: "3"}}]}
      ],
      split_policy: :row_atomic
    }

    # Available height is 100. Header is 20, fits 2 rows (80).
    {tb, rb} = Rendro.Fragmentable.split(table, 100)

    assert tb.header_height == 20
    assert length(tb.rows) == 2
    assert tb.row_heights == [40, 40]

    # repeat_header is true, but table split returns it with original table structure. Wait,
    # split_table puts header_height: 20 on both? Yes, if repeat_header is true.
    assert rb.header_height == 20
    assert length(rb.rows) == 1
    assert rb.row_heights == [40]
  end
end

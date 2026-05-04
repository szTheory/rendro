defmodule Rendro.TableTest do
  use ExUnit.Case, async: true

  describe "Table data models" do
    test "Table supports :fragment, repeat_header, and decoration_break" do
      table = %Rendro.Table{
        rows: [],
        split_policy: :fragment,
        repeat_header: true,
        decoration_break: :clone
      }

      assert table.split_policy == :fragment
      assert table.repeat_header == true
      assert table.decoration_break == :clone
    end

    test "Table default values for new fields" do
      table = %Rendro.Table{rows: []}
      assert table.split_policy == :row_atomic
      assert table.repeat_header == true
      assert table.decoration_break == :slice
    end

    test "Row implements Block attributes, requires :cells, and accepts split_policy" do
      row = %Rendro.Row{
        cells: [],
        split_policy: :fragment,
        x: 10,
        y: 20,
        width: 100,
        height: 50,
        keep_together: true,
        break_before: true,
        break_after: false
      }

      assert row.cells == []
      assert row.split_policy == :fragment
      assert row.x == 10
      assert row.y == 20
      assert row.keep_together == true
    end

    test "Cell implements Block attributes, requires :content, and accepts split_policy" do
      cell = %Rendro.Cell{
        content: "Hello",
        split_policy: :atomic,
        colspan: 2,
        rowspan: 3,
        x: 0,
        y: 0,
        width: 50,
        height: 25,
        keep_together: false,
        break_before: false,
        break_after: false
      }

      assert cell.content == "Hello"
      assert cell.split_policy == :atomic
      assert cell.colspan == 2
      assert cell.rowspan == 3
      assert cell.x == 0
    end
  end
end

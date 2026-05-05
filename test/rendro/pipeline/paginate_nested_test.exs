defmodule Rendro.Pipeline.PaginateNestedTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}
  alias Rendro.{PageTemplate, Region}

  defp paginate_flow(doc) do
    {:ok, doc} = Build.run(doc)
    {:ok, doc} = Compose.run(doc)
    {:ok, doc} = Measure.run(doc)
    Paginate.run(doc)
  end

  defp nested_template do
    %PageTemplate{
      name: :nested,
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
          height: 60
        }
      ]
    }
  end

  test "splits a table nested inside another table" do
    inner_table = %Rendro.Table{
      split_policy: :fragment,
      rows: for(i <- 1..5, do: [%Rendro.Block{content: Rendro.text("Inner Row #{i}")}]),
      column_widths: [100]
    }

    outer_table = %Rendro.Table{
      split_policy: :fragment,
      rows: [
        [%Rendro.Block{content: Rendro.text("Outer Row 1")}],
        [%Rendro.Block{content: inner_table}],
        [%Rendro.Block{content: Rendro.text("Outer Row 3")}]
      ],
      column_widths: [150]
    }

    doc =
      Rendro.flow(
        [Rendro.block(outer_table)],
        page_template: :nested,
        page_templates: [nested_template()]
      )

    assert {:ok, paginated} = paginate_flow(doc)
    
    assert length(paginated.pages) >= 2
    
    page1 = Enum.at(paginated.pages, 0)
    page2 = Enum.at(paginated.pages, 1)

    [block1] = page1.blocks
    assert %Rendro.Table{} = outer_table_part1 = block1.content
    assert length(outer_table_part1.rows) == 2
    
    [_, %Rendro.Row{cells: [%Rendro.Cell{content: %Rendro.Block{content: inner_table_part1}}]}] = outer_table_part1.rows
    assert length(inner_table_part1.rows) == 3

    [block2] = page2.blocks
    assert %Rendro.Table{} = outer_table_part2 = block2.content
    
    [%Rendro.Row{cells: [%Rendro.Cell{content: %Rendro.Block{content: inner_table_part2}}]} | _rest] = outer_table_part2.rows
    assert length(inner_table_part2.rows) == 2
  end
end

defmodule Rendro.InspectorTest do
  use ExUnit.Case, async: true

  alias Rendro.Document
  alias Rendro.Page
  alias Rendro.Block
  alias Rendro.Text
  alias Rendro.Table
  alias Rendro.Inspector

  test "inspect/1 returns an ASCII layout tree representation" do
    doc = %Document{
      pages: [
        %Page{
          width: 595.28,
          height: 841.89,
          blocks: [
            %Block{
              content: %Text{content: "Header"},
              x: 72,
              y: 72,
              width: 451.28,
              height: 20
            },
            %Block{
              content: %Table{rows: [["A", "B"]]},
              x: 72,
              y: 100,
              width: 451.28,
              height: 50
            }
          ]
        },
        %Page{
          width: 595.28,
          height: 841.89,
          blocks: [
            %Block{
              content: "String Block",
              x: 72,
              y: 72,
              width: 100,
              height: 20
            }
          ]
        }
      ],
      diagnostics: [
        %{level: :info, type: "table_split", message: "table_split on page 2"}
      ]
    }

    expected_output = """
    Page 1 (595.28x841.89)
    ├── Block: Text (x: 72, y: 72, w: 451.28, h: 20)
    ├── Block: Table (x: 72, y: 100, w: 451.28, h: 50)
    Page 2 (595.28x841.89)
    ├── Block: String (x: 72, y: 72, w: 100, h: 20)

    Diagnostics:
    - [info] table_split: table_split on page 2
    """

    assert Inspector.inspect(doc) == String.trim_trailing(expected_output)
  end

  test "inspect/1 renders runtime diagnostics without requiring a message field" do
    doc = %Document{
      pages: [
        %Page{
          width: 220,
          height: 180,
          blocks: [
            %Block{
              content: %Text{content: "Heading"},
              x: 12,
              y: 12,
              width: 100,
              height: 14.4
            }
          ]
        }
      ],
      diagnostics: [
        %{level: :info, type: :keep_rule_break, keep_rule: :keep_with_next, page_index: 2},
        %{level: :info, type: :table_split, page_index: 1, reason: :insufficient_height}
      ]
    }

    expected_output = """
    Page 1 (220x180)
    ├── Block: Text (x: 12, y: 12, w: 100, h: 14.4)

    Diagnostics:
    - [info] keep_rule_break: keep_rule=keep_with_next, page_index=2
    - [info] table_split: page_index=1, reason=insufficient_height
    """

    assert Inspector.inspect(doc) == String.trim_trailing(expected_output)
  end
end

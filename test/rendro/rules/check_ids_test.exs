defmodule Rendro.Rules.CheckIdsTest do
  use ExUnit.Case, async: true

  alias Rendro.Rules.CheckIds
  alias Rendro.{Block, Document, Page, Text, Table, Row, Cell}

  describe "check/2" do
    test "returns :ok for unique IDs" do
      doc = %Document{
        pages: [
          %Page{
            blocks: [
              %Block{id: "id1", content: %Text{content: "A"}},
              %Block{id: "id2", content: %Text{content: "B"}},
              %Block{id: nil, content: %Text{content: "C"}}
            ]
          }
        ]
      }

      assert CheckIds.check(doc, doc) == :ok
    end

    test "returns duplicate IDs nested in tables" do
      doc = %Document{
        pages: [
          %Page{
            blocks: [
              %Block{id: "dup1", content: %Text{content: "A"}},
              %Block{
                id: "dup2",
                content: %Table{
                  rows: [
                    %Row{
                      cells: [
                        %Cell{content: %Block{id: "dup1", content: %Text{content: "B"}}}
                      ]
                    }
                  ]
                }
              },
              %Block{id: "dup2", content: %Text{content: "C"}}
            ]
          }
        ]
      }

      assert CheckIds.check(doc, doc) ==
               {:errors, [{:duplicate_id, "dup1"}, {:duplicate_id, "dup2"}]}
    end
  end
end

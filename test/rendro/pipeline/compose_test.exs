defmodule Rendro.Pipeline.ComposeTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region, Section}
  alias Rendro.Pipeline.Compose

  describe "run/1" do
    test "returns {:ok, document} preserving block positions" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 50, y: 100}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Compose.run(doc)
      [composed_page] = result.pages
      [composed_block] = composed_page.blocks
      assert composed_block.x == 50
      assert composed_block.y == 100
      assert composed_block.content == text
    end

    test "handles page with no blocks" do
      page = %Rendro.Page{blocks: []}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Compose.run(doc)
      [composed_page] = result.pages
      assert composed_page.blocks == []
    end

    test "preserves multiple blocks on a page" do
      text1 = %Rendro.Text{content: "First", font: "Helvetica", size: 12, color: {0, 0, 0}}
      text2 = %Rendro.Text{content: "Second", font: "Helvetica", size: 14, color: {255, 0, 0}}

      doc = %Rendro.Document{
        pages: [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: text1, x: 10, y: 20},
              %Rendro.Block{content: text2, x: 30, y: 40}
            ]
          }
        ],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, result} = Compose.run(doc)
      [page] = result.pages
      assert length(page.blocks) == 2
    end

    test "normalizes sections into explicit body and anchored regions before pagination" do
      template =
        %PageTemplate{
          name: :invoice,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 72,
              y: 72,
              width: 451.28,
              height: 40
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 112,
              width: 451.28,
              height: 620
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 72,
              y: 760,
              width: 451.28,
              height: 28
            },
            %Region{
              name: :sidebar,
              role: :sidebar,
              anchor: :fixed,
              x: 420,
              y: 112,
              width: 80,
              height: 120
            }
          ]
        }

      header_section =
        %Section{
          name: :report_header,
          region: :header,
          content: [Rendro.block(Rendro.text("Header"))]
        }

      sidebar_section =
        %Section{name: :totals, region: :sidebar, content: [Rendro.block(Rendro.text("Sidebar"))]}

      body_section =
        %Section{
          name: :body_copy,
          region: :body,
          content: [Rendro.block(Rendro.text("Body from section"))]
        }

      doc =
        %Rendro.Document{
          page_template: :invoice,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Lead paragraph"))],
          header: [Rendro.block(Rendro.text("Legacy header"))],
          sections: [header_section, sidebar_section, body_section],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Compose.run(doc)
      layout = result.options.layout

      assert layout.template.name == :invoice
      assert layout.body_region.name == :body

      assert Enum.map(layout.entries, & &1.name) == [
               :content,
               :report_header,
               :totals,
               :body_copy
             ]

      assert Enum.map(result.content, & &1.content.content) == [
               "Lead paragraph",
               "Body from section"
             ]

      assert Enum.map(result.header, & &1.content.content) == ["Legacy header", "Header"]
      assert Enum.map(layout.region_blocks.sidebar, & &1.content.content) == ["Sidebar"]
    end
  end
end

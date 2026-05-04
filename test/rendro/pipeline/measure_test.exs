defmodule Rendro.Pipeline.MeasureTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Region}
  alias Rendro.Pipeline.Compose
  alias Rendro.Pipeline.Measure
  alias Rendro.Pipeline.MeasuredText
  alias Rendro.TestSupport.FontFixture

  defp lines_text(%MeasuredText{lines: lines}) do
    Enum.map(lines, fn line -> Enum.map_join(line, "", & &1.text) end)
  end

  describe "run/1" do
    test "computes width and height for blocks with nil dimensions" do
      text = %Rendro.Text{content: "Hello", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [measured_page] = result.pages
      [measured_block] = measured_page.blocks

      assert is_number(measured_block.width)
      assert measured_block.width > 0
      assert measured_block.height == 12 * 1.2
      assert lines_text(measured_block.content) == ["Hello"]
    end

    test "preserves explicit width, fills in nil height" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 14, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: 200, height: nil}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      [block] = page.blocks

      assert block.width == 200
      assert block.height == 14 * 1.2
    end

    test "preserves explicit width and height" do
      text = %Rendro.Text{content: "Test", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: 100, height: 50}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      [block] = page.blocks

      assert block.width == 100
      assert block.height == 50
    end

    test "handles empty blocks list" do
      page = %Rendro.Page{blocks: []}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, result} = Measure.run(doc)
      [page] = result.pages
      assert page.blocks == []
    end

    test "measures body capacity from the explicit body region instead of header/footer block heights" do
      template =
        %PageTemplate{
          name: :statement,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 72,
              y: 72,
              width: 451.28,
              height: 48
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 120,
              width: 451.28,
              height: 540
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 72,
              y: 732,
              width: 451.28,
              height: 36
            }
          ]
        }

      doc =
        %Rendro.Document{
          page_template: :statement,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Line item"))],
          header: [Rendro.block(Rendro.text("Tall header"), height: 120)],
          footer: [Rendro.block(Rendro.text("Tall footer"), height: 80)],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, result} = Measure.run(composed)

      layout = result.options.layout

      assert layout.body_capacity == 540
      assert hd(result.header).height == 120
      assert hd(result.footer).height == 80
      assert_in_delta hd(result.content).height, 14.4, 1.0e-9
    end

    test "identical input yields identical wrapped lines" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("alpha beta gamma delta", size: 12, line_height: 1.4),
                  width: 60
                )
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, first} = Measure.run(doc)
      assert {:ok, second} = Measure.run(doc)

      [first_block] = hd(first.pages).blocks
      [second_block] = hd(second.pages).blocks

      assert lines_text(first_block.content) == lines_text(second_block.content)
      assert length(first_block.content.lines) > 1
    end

    test "preserves explicit newlines as distinct measured lines" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("alpha beta\ngamma delta", size: 12), width: 200)
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks

      assert lines_text(block.content) == ["alpha beta", "gamma delta"]
    end

    test "preserves authored repeated whitespace when width-constrained" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("alpha  beta", size: 12), width: 200)
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks

      assert lines_text(block.content) == ["alpha  beta"]
    end

    test "falls back to grapheme wrapping for an oversized token" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("supercalifragilistic", size: 12), width: 25)
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks
      lines = lines_text(block.content)

      assert length(lines) > 1
      assert Enum.all?(lines, &(String.length(&1) >= 1))
      assert Enum.join(lines, "") == "supercalifragilistic"
    end

    test "constrained wrapping increases measured height while keeping authored width" do
      text = Rendro.text("alpha beta gamma delta epsilon", size: 12, line_height: 1.5)

      unconstrained_doc =
        %Rendro.Document{
          pages: [%Rendro.Page{blocks: [Rendro.block(text)]}],
          metadata: %Rendro.Metadata{}
        }

      constrained_doc =
        %Rendro.Document{
          pages: [%Rendro.Page{blocks: [Rendro.block(text, width: 70)]}],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, unconstrained} = Measure.run(unconstrained_doc)
      assert {:ok, constrained} = Measure.run(constrained_doc)

      [unconstrained_block] = hd(unconstrained.pages).blocks
      [constrained_block] = hd(constrained.pages).blocks

      assert constrained_block.width == 70
      assert constrained_block.height > unconstrained_block.height
      assert length(constrained_block.content.lines) > 1
    end

    test "routes a registered logical font through measurement" do
      doc =
        Rendro.document()
        |> Rendro.register_font(:heading, built_in: :helvetica)
        |> Map.put(:pages, [
          %Rendro.Page{
            blocks: [
              Rendro.block(Rendro.text("Heading", font: :heading), x: 0, y: 0)
            ]
          }
        ])

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks

      assert %MeasuredText{resolved_font: %{name: "F_HEADING", base_font: "Helvetica"}} =
               block.content
    end

    test "uses embedded font metrics for deterministic wrapping and carries the resolved font" do
      %{bytes: bytes} = FontFixture.supported_font()
      constrained_width = 135
      content = "alpha beta gamma delta"

      built_in_doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text(content, font: :default, size: 12),
                  width: constrained_width
                )
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      embedded_doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})
        |> Map.put(:pages, [
          %Rendro.Page{
            blocks: [
              Rendro.block(Rendro.text(content, font: :brand, size: 12), width: constrained_width)
            ]
          }
        ])

      assert {:ok, built_in_result} = Measure.run(built_in_doc)
      assert {:ok, embedded_result} = Measure.run(embedded_doc)

      [built_in_block] = hd(built_in_result.pages).blocks
      [embedded_block] = hd(embedded_result.pages).blocks

      assert lines_text(built_in_block.content) == ["alpha beta gamma delta"]
      assert %MeasuredText{resolved_font: built_in_font} = built_in_block.content

      assert lines_text(embedded_block.content) == ["alpha beta gamma ", "delta"]
      assert %MeasuredText{resolved_font: embedded_font} = embedded_block.content

      assert_in_delta embedded_block.height, 28.8, 1.0e-9
      assert embedded_block.height > built_in_block.height
      assert embedded_font.source == :embedded
      assert embedded_font.logical_name == :brand
      assert embedded_font.name == "F_BRAND"
      assert embedded_font.base_font != built_in_font.base_font
    end

    test "measures image missing height from intrinsic aspect ratio" do
      doc = %Rendro.Document{
        asset_registry: %Rendro.AssetRegistry{
          assets: %{logo: %{binary: <<0>>, width: 400, height: 200, mime: "image/png"}}
        },
        pages: [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: %Rendro.Image{logical_name: :logo}, width: 200}
            ]
          }
        ],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks
      assert block.width == 200
      assert block.height == 100
    end

    test "measures image missing width from intrinsic aspect ratio" do
      doc = %Rendro.Document{
        asset_registry: %Rendro.AssetRegistry{
          assets: %{logo: %{binary: <<0>>, width: 400, height: 200, mime: "image/png"}}
        },
        pages: [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: %Rendro.Image{logical_name: :logo}, height: 50}
            ]
          }
        ],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, result} = Measure.run(doc)
      [block] = hd(result.pages).blocks
      assert block.width == 100
      assert block.height == 50
    end

    test "fails image measurement if logical_name is not found in AssetRegistry" do
      doc = %Rendro.Document{
        asset_registry: %Rendro.AssetRegistry{},
        pages: [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: %Rendro.Image{logical_name: :unknown}, width: 200}
            ]
          }
        ],
        metadata: %Rendro.Metadata{}
      }

      assert {:error, {:missing_asset, :unknown}} = Measure.run(doc)
    end

    test "resolves authored column rules deterministically against block width" do
      table =
        Rendro.table(
          [["a", "b", "c"]],
          columns: [{:fixed, 100}, {:share, 1}, {:share, 2}]
        )

      doc = Rendro.flow([Rendro.block(table, width: 400)])

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, measured} = Measure.run(composed)

      [measured_block] = measured.content
      measured_table = measured_block.content

      assert measured_block.width == 400
      assert measured_table.column_widths == [100.0, 100.0, 200.0]
    end

    test "measured row height follows the tallest cell in the row" do
      table =
        Rendro.table(
          [["short", "very very very very very long text that must wrap"]],
          columns: [{:fixed, 100}, {:fixed, 50}]
        )

      doc = Rendro.flow([Rendro.block(table, width: 150)])

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, measured} = Measure.run(composed)

      [measured_block] = measured.content
      measured_table = measured_block.content

      [row_h] = measured_table.row_heights

      assert row_h > 15
      assert measured_block.height == row_h
    end
  end
end

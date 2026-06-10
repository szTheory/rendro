defmodule Rendro.Pipeline.MeasureTest.CollapsingShaper do
  @moduledoc false
  @behaviour Rendro.Text.Shaper

  # Always collapses the entire shaped text into ONE glyph with cluster: 0,
  # simulating a whole-run ligature from a shaper exposing no cluster data.
  @impl Rendro.Text.Shaper
  def shape(_font, text, _opts) do
    {:ok,
     [
       %{
         gid: 0,
         cluster: 0,
         name: text,
         x_advance: 600 * String.length(text),
         y_advance: 0,
         x_offset: 0,
         y_offset: 0
       }
     ]}
  end
end

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
      assert measured_block.content.widows == 2
      assert measured_block.content.orphans == 2
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

    test "subtracts header and footer region heights from body region height" do
      template =
        %PageTemplate{
          name: :with_footer,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 72,
              y: 72,
              width: 451.28,
              height: 0
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 72,
              width: 451.28,
              height: 540
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 72,
              y: 612,
              width: 451.28,
              height: 36
            }
          ]
        }

      doc =
        %Rendro.Document{
          page_template: :with_footer,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Line item"))],
          header: [],
          footer: [Rendro.block(Rendro.text("Footer text"), height: 36)],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, result} = Measure.run(composed)

      layout = result.options.layout

      assert_in_delta layout.body_capacity, 504, 1.0e-9
    end

    test "CR-02 regression: header positioned entirely below body bottom is not subtracted from body_capacity" do
      # body: y=100, height=400 (bottom=500). Header: y=600, height=30.
      # The header does NOT overlap the body, so header_h must be 0.
      # body_capacity should equal body_h (400), not 400-30=370.
      template =
        %PageTemplate{
          name: :header_below_body,
          regions: [
            %Region{
              name: :header,
              role: :header,
              anchor: :top,
              x: 72,
              y: 600,
              width: 451.28,
              height: 30
            },
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 100,
              width: 451.28,
              height: 400
            }
          ]
        }

      doc =
        %Rendro.Document{
          page_template: :header_below_body,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Line item"))],
          header: [],
          footer: [],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, result} = Measure.run(composed)

      layout = result.options.layout
      # header (y=600) is entirely below body bottom (y+h=500) => no subtraction
      assert layout.body_capacity == 400
    end

    test "CR-02 regression: footer positioned entirely above body top is not subtracted from body_capacity" do
      # body: y=200, height=400 (top=200). Footer: y=50, height=30 (bottom=80).
      # The footer does NOT overlap the body, so footer_h must be 0.
      # body_capacity should equal body_h (400), not 400-30=370.
      template =
        %PageTemplate{
          name: :footer_above_body,
          regions: [
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 72,
              y: 200,
              width: 451.28,
              height: 400
            },
            %Region{
              name: :footer,
              role: :footer,
              anchor: :bottom,
              x: 72,
              y: 50,
              width: 451.28,
              height: 30
            }
          ]
        }

      doc =
        %Rendro.Document{
          page_template: :footer_above_body,
          page_templates: [template],
          content: [Rendro.block(Rendro.text("Line item"))],
          header: [],
          footer: [],
          metadata: %Rendro.Metadata{}
        }

      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, result} = Measure.run(composed)

      layout = result.options.layout
      # footer (y=50, h=30, bottom=80) is entirely above body top (y=200) => no subtraction
      assert layout.body_capacity == 400
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

  describe "HYG-02: shaping_required error propagation" do
    # Build a fake font that reports Arabic codepoints as present (so font resolution passes)
    # but has source: :built_in so the HarfBuzz adapter delegates to Shaper.Simple,
    # which returns {:error, {:shaping_required, :arab, hint}} for Arabic script.
    defp arabic_capable_fake_font do
      # Arabic codepoints for "مرحبا" (م ر ح ب ا) and space
      arabic_widths =
        [32, 1575, 1576, 1581, 1585, 1605, 1576, 1575]
        |> Enum.uniq()
        |> Map.new(fn cp -> {cp, 500} end)

      %Rendro.PDF.Font{
        source: :built_in,
        logical_name: :fake_arabic,
        name: "F_FAKE_ARABIC",
        base_font: "FakeArabic",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 800,
        descent: -200,
        default_width: 500,
        widths: arabic_widths,
        cmap: nil,
        font_bytes: nil
      }
    end

    # Build a document with a fake Arabic-capable font registered in the font registry.
    # The descriptor uses source: :embedded with a pre-built pdf_font to inject the
    # fake font struct directly (bypasses font byte loading).
    defp doc_with_arabic_text do
      fake_font = arabic_capable_fake_font()

      fake_descriptor = %{
        source: :embedded,
        source_kind: :binary,
        variant: :regular,
        source_data: %{status: :ok, kind: :binary, bytes: <<>>, byte_size: 0},
        pdf_font: fake_font
      }

      base_registry = Rendro.FontRegistry.new()

      custom_registry = %Rendro.FontRegistry{
        base_registry
        | fonts: Map.put(base_registry.fonts, :fake_arabic, fake_descriptor),
          default_font: :fake_arabic
      }

      text = %Rendro.Text{content: "مرحبا", font: :fake_arabic, size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
      page = %Rendro.Page{blocks: [block]}

      %Rendro.Document{
        pages: [page],
        font_registry: custom_registry,
        default_font: :fake_arabic,
        metadata: %Rendro.Metadata{}
      }
    end

    test "Arabic text with Shaper.Simple returns a raw shaping_required tuple from Measure.run/1" do
      # HarfBuzz adapter delegates source: :built_in fonts to Shaper.Simple.
      # Shaper.Simple returns {:error, {:shaping_required, :arab, hint}} for Arabic script.
      # Measure propagates the raw tuple; the pipeline boundary (Pipeline.span/4)
      # wraps it in Rendro.Error WITH base_meta so render_id is never lost (WR-02).
      result = Measure.run(doc_with_arabic_text())

      assert {:error, {:shaping_required, :arab, hint}} = result
      assert is_binary(hint)
    end

    test "shaping_required error from a full render carries render_id and correlation metadata (WR-02)" do
      assert {:error, %Rendro.Error{stage: :measure} = error} =
               Rendro.render(doc_with_arabic_text())

      assert {:shaping_required, :arab, _hint} = error.reason
      assert is_binary(error.render_id)
      assert error.details.document_type == :pdf
      assert is_boolean(error.details.deterministic)
      assert error.why =~ "requires a shaping adapter"
      assert error.why =~ ":arab"
      assert error.next =~ "shaping adapter"
    end

    test "CR-03: a run collapsing to a single glyph keeps every grapheme in measured lines" do
      text = %Rendro.Text{content: "abcdef", font: "Helvetica", size: 12, color: {0, 0, 0}}
      # Narrow width forces split_graphemes on the oversized token; the
      # CollapsingShaper then returns one glyph (cluster: 0) for the whole run,
      # which previously dropped all graphemes after the first in the zip path.
      block = %Rendro.Block{content: text, x: 0, y: 0, width: 20, height: nil}
      page = %Rendro.Page{blocks: [block]}

      doc = %Rendro.Document{
        pages: [page],
        metadata: %Rendro.Metadata{},
        options: %{render: [shaper: Rendro.Pipeline.MeasureTest.CollapsingShaper]}
      }

      assert {:ok, result} = Measure.run(doc)
      [measured_page] = result.pages
      [measured_block] = measured_page.blocks

      all_text = measured_block.content |> lines_text() |> Enum.join("")
      assert all_text == "abcdef"
    end

    test "Latin text measured returns ok unchanged" do
      text = %Rendro.Text{content: "Hello", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:ok, _result} = Measure.run(doc)
    end
  end

  describe "Grid Projection" do
    test "measure_block/3 normalizes lists into Row/Cell structs and builds 2D Grid" do
      table = %Rendro.Table{
        rows: [
          ["A", "B"],
          %Rendro.Row{cells: [%Rendro.Cell{content: "C"}, "D"]}
        ],
        columns: [{:fixed, 50}, {:fixed, 50}]
      }

      doc = Rendro.flow([Rendro.block(table, width: 100)])
      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, measured} = Measure.run(composed)

      measured_table = hd(measured.content).content

      assert [row1, row2] = measured_table.rows
      assert %Rendro.Row{} = row1

      assert [%Rendro.Cell{content: %Rendro.Block{content: %MeasuredText{}}}, %Rendro.Cell{}] =
               row1.cells

      assert %Rendro.Row{} = row2
      assert [%Rendro.Cell{}, %Rendro.Cell{}] = row2.cells

      assert is_list(measured_table._grid_layout)
      assert length(measured_table._grid_layout) == 2
      assert length(hd(measured_table._grid_layout)) == 2
    end

    test "spanning cells generate continuation grid slots" do
      table = %Rendro.Table{
        rows: [
          [%Rendro.Cell{content: "Spans 2x2", colspan: 2, rowspan: 2}],
          []
        ],
        columns: [{:fixed, 50}, {:fixed, 50}]
      }

      doc = Rendro.flow([Rendro.block(table, width: 100)])
      assert {:ok, composed} = Compose.run(doc)
      assert {:ok, measured} = Measure.run(composed)

      measured_table = hd(measured.content).content
      grid = measured_table._grid_layout

      assert [row1, row2] = grid
      assert [%{is_continuation: false, cell: _}, %{is_continuation: true}] = row1
      assert [%{is_continuation: true}, %{is_continuation: true}] = row2
    end

    test "tables exceeding maximum cell limit return error" do
      table = %Rendro.Table{
        rows: [
          [%Rendro.Cell{content: "Huge", colspan: 1000, rowspan: 101}]
        ],
        columns: [{:fixed, 10}]
      }

      doc = Rendro.flow([Rendro.block(table, width: 100)])
      assert {:ok, composed} = Compose.run(doc)
      assert {:error, :grid_too_large} = Measure.run(composed)
    end
  end
end

defmodule Rendro.DeterministicTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Rendro.Test.Generators

  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}
  alias Rendro.TestSupport.FontFixture

  @moduletag :deterministic

  describe "property: deterministic byte-identity" do
    property "two deterministic renders of the same document produce identical binaries" do
      check all(doc <- renderable_document_gen(), max_runs: 100) do
        {:ok, pdf1} = Rendro.render(doc, deterministic: true)
        {:ok, pdf2} = Rendro.render(doc, deterministic: true)
        assert pdf1 == pdf2
      end
    end

    property "deterministic output is stable across 10 sequential renders" do
      check all(doc <- renderable_document_gen(), max_runs: 25) do
        {:ok, reference} = Rendro.render(doc, deterministic: true)

        for _ <- 1..9 do
          {:ok, pdf} = Rendro.render(doc, deterministic: true)
          assert pdf == reference
        end
      end
    end

    property "non-deterministic mode produces valid PDF output" do
      check all(doc <- renderable_document_gen(), max_runs: 50) do
        {:ok, pdf} = Rendro.render(doc)
        assert String.starts_with?(pdf, "%PDF-1.4")
        assert String.contains?(pdf, "%%EOF")
      end
    end
  end

  describe "unit: fixed timestamp" do
    test "deterministic PDFs contain fixed epoch timestamp" do
      doc = simple_doc()
      {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "D:20000101000000Z"
    end

    test "non-deterministic PDFs do not contain fixed epoch timestamp" do
      doc = simple_doc()
      {:ok, pdf} = Rendro.render(doc)
      refute pdf =~ "D:20000101000000Z"
    end
  end

  describe "unit: sorted dictionary keys" do
    test "deterministic output has dictionary keys in alphabetical order" do
      doc = simple_doc()
      {:ok, pdf} = Rendro.render(doc, deterministic: true)

      groups = dictionary_key_groups(pdf)

      for group <- groups, length(group) > 1 do
        assert group == Enum.sort(group),
               "Dictionary keys not sorted: #{inspect(group)}"
      end
    end
  end

  describe "embedded file ordering" do
    test "deterministic output stays identical across embedded-file registration order" do
      {:ok, pdf1} = Rendro.render(embedded_file_order_doc(:alpha_first), deterministic: true)
      {:ok, pdf2} = Rendro.render(embedded_file_order_doc(:zeta_first), deterministic: true)

      assert pdf1 == pdf2
      assert offset_of(pdf1, "(alpha.txt)") < offset_of(pdf1, "(zeta.txt)")
    end
  end

  describe "link annotation determinism" do
    test "deterministic output stays byte-identical for the same linked document" do
      doc = linked_text_doc()
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)

      assert pdf1 == pdf2
      assert pdf1 =~ "/Subtype /Link"
      assert pdf1 =~ "/URI (https://example.com/docs?q=keep)"
      assert pdf1 =~ "(Linked body) Tj"
    end

    test "multiple curated links stay in page order across repeated deterministic renders" do
      doc = ordered_links_doc()
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)

      assert pdf1 == pdf2

      assert annotation_offsets(pdf1, ["/URI (https://example.com/alpha)", "/Dest [4 0 R /Fit]"]) ==
               annotation_offsets(pdf2, ["/URI (https://example.com/alpha)", "/Dest [4 0 R /Fit]"])

      assert pdf1 =~ "(Alpha link) Tj"
      assert pdf1 =~ "(Beta table) Tj"
    end
  end

  describe "signature widget determinism" do
    test "deterministic output stays byte-identical for the same unsigned signature document" do
      doc = signature_field_doc()
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)

      assert pdf1 == pdf2
      assert pdf1 =~ "/Subtype /Widget"
      assert pdf1 =~ "/FT /Sig"
      refute pdf1 =~ "/ByteRange"
      refute pdf1 =~ "/Contents <"
      refute pdf1 =~ "/Contents ("
      refute pdf1 =~ "/V"
    end
  end

  describe "embedded font parity" do
    test "the same resolved embedded font drives deterministic wrapping, pagination, and final PDF resources" do
      %{bytes: bytes} = FontFixture.supported_font()
      template = embedded_wrap_template()

      doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})
        |> Map.put(:content, [
          Rendro.block(Rendro.text("alpha beta gamma delta", font: :brand, size: 12), width: 100),
          Rendro.block(Rendro.text("alpha beta gamma delta", font: :brand, size: 12), width: 100)
        ])
        |> Map.put(:page_template, :embedded_wrap)
        |> Map.put(:page_templates, [template])

      runs =
        for _ <- 1..3 do
          {:ok, built} = Build.run(doc)
          {:ok, composed} = Compose.run(built)
          {:ok, measured} = Measure.run(composed)
          {:ok, paginated} = Paginate.run(measured)
          {:ok, pdf} = Rendro.render(doc, deterministic: true)

          line_sets =
            paginated.pages
            |> Enum.map(fn page ->
              Enum.map(page.blocks, fn block ->
                Enum.map(block.content.lines, fn line ->
                  Enum.map_join(line, "", & &1.text)
                end)
              end)
            end)

          resolved_fonts =
            paginated.pages
            |> Enum.flat_map(fn page -> Enum.map(page.blocks, & &1.content.resolved_font) end)

          {line_sets, length(paginated.pages), resolved_fonts, pdf}
        end

      [{reference_lines, reference_pages, reference_fonts, reference_pdf} | rest] = runs

      assert reference_lines == [
               [["alpha beta ", "gamma delta"]],
               [["alpha beta ", "gamma delta"]]
             ]

      assert reference_pages == 2
      assert Enum.all?(reference_fonts, &(&1.source == :embedded and &1.logical_name == :brand))

      [reference_font | _] = reference_fonts
      assert reference_pdf =~ "/F_BRAND"
      assert reference_pdf =~ "/FontDescriptor"
      assert reference_pdf =~ "/FontFile2"
      assert reference_pdf =~ "/BaseFont /#{reference_font.base_font}"

      Enum.each(rest, fn {line_sets, page_count, fonts, pdf} ->
        assert line_sets == reference_lines
        assert page_count == reference_pages

        assert Enum.map(fonts, &{&1.base_font, &1.logical_name, &1.name}) ==
                 Enum.map(reference_fonts, &{&1.base_font, &1.logical_name, &1.name})

        assert pdf == reference_pdf
      end)
    end
  end

  describe "running-region determinism (D-11)" do
    test "(a) two deterministic renders with running footer are byte-identical" do
      doc = running_footer_doc("Page {{page_number}} of {{total_pages}}")
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      # Confirm the footer substitution path was exercised
      assert pdf1 =~ "(Page 1 of"
      assert pdf1 == pdf2
    end

    test "(b) body_capacity is identical for 9-page vs 100-page document" do
      # D-09: body_capacity is a pure function of declared geometry, not page count or content volume.
      # Use a template with footer_height: 30 to verify the subtraction is geometry-only.
      cap_9 = measure_body_capacity(9)
      cap_100 = measure_body_capacity(100)
      assert_in_delta cap_9, cap_100, 1.0e-9
    end

    test "(c) page count and body-block assignment identical with total_pages vs static placeholder" do
      # D-11(c): {{total_pages}} token presence does NOT affect pagination geometry.
      doc_token = running_footer_doc("Page {{page_number}} of {{total_pages}}")
      doc_static = running_footer_doc("Page {{page_number}} of 999")

      {:ok, built_t} = Build.run(doc_token)
      {:ok, composed_t} = Compose.run(built_t)
      {:ok, measured_t} = Measure.run(composed_t)
      {:ok, paginated_token} = Paginate.run(measured_t)

      {:ok, built_s} = Build.run(doc_static)
      {:ok, composed_s} = Compose.run(built_s)
      {:ok, measured_s} = Measure.run(composed_s)
      {:ok, paginated_static} = Paginate.run(measured_s)

      assert length(paginated_token.pages) == length(paginated_static.pages)

      token_counts = body_block_counts(paginated_token)
      static_counts = body_block_counts(paginated_static)
      assert token_counts == static_counts
    end

    test "(d) replace_page_numbers does not change MeasuredText geometry" do
      # D-11(d) / D-10: run.width and block.height must be frozen at measure time.
      # Geometry on page 1 and page 2 must be identical (both measured from token string,
      # not re-measured from the substituted digit string).
      doc = running_footer_doc("Page {{page_number}} of {{total_pages}}")

      {:ok, built} = Build.run(doc)
      {:ok, composed} = Compose.run(built)
      {:ok, measured} = Measure.run(composed)
      {:ok, paginated} = Paginate.run(measured)

      assert length(paginated.pages) >= 2

      [page1, page2 | _] = paginated.pages

      footer1 = find_footer_block(page1)
      footer2 = find_footer_block(page2)

      assert footer1 != nil, "expected footer block on page 1"
      assert footer2 != nil, "expected footer block on page 2"

      # Geometry must be frozen: run widths identical across pages
      runs1 = footer_run_widths(footer1)
      runs2 = footer_run_widths(footer2)

      assert runs1 == runs2,
             "expected run widths to be identical on page 1 and page 2 (geometry frozen at measure), got p1=#{inspect(runs1)} p2=#{inspect(runs2)}"

      # Block height also frozen
      assert footer1.height == footer2.height,
             "expected block height identical on page 1 and page 2, got p1=#{footer1.height} p2=#{footer2.height}"
    end
  end

  defp simple_doc do
    text = %Rendro.Text{content: "Hello World", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 0, y: 0}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Test"}}
  end

  defp embedded_wrap_template do
    %Rendro.PageTemplate{
      name: :embedded_wrap,
      width: 612,
      height: 792,
      margin_top: 0,
      margin_right: 0,
      margin_bottom: 0,
      margin_left: 0,
      regions: [
        %Rendro.Region{
          name: :body,
          role: :body,
          anchor: :flow,
          x: 0,
          y: 0,
          width: 200,
          height: 45
        }
      ]
    }
  end

  defp linked_text_doc do
    block =
      Rendro.block(Rendro.text("Linked body", font: "Helvetica", size: 12),
        x: 10,
        y: 20,
        width: 120,
        height: 24
      )
      |> Rendro.link(uri: "https://example.com/docs?q=keep")

    %Rendro.Document{
      pages: [
        %Rendro.Page{
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [block]
        }
      ],
      metadata: %Rendro.Metadata{title: "Linked Determinism"}
    }
  end

  defp ordered_links_doc do
    alpha =
      Rendro.block(Rendro.text("Alpha link", font: "Helvetica", size: 12),
        x: 10,
        y: 20,
        width: 120,
        height: 24
      )
      |> Rendro.link(uri: "https://example.com/alpha")

    beta_table =
      %Rendro.Table{
        rows: [
          %Rendro.Row{
            cells: [
              %Rendro.Cell{
                content:
                  Rendro.block(
                    Rendro.text("Beta table", font: "Helvetica", size: 12),
                    x: 0,
                    y: 0,
                    width: 120,
                    height: 24
                  ),
                width: 120,
                height: 24
              }
            ]
          }
        ],
        row_heights: [24],
        split_policy: :none,
        repeat_header: false
      }

    beta =
      Rendro.block(beta_table, x: 10, y: 60, width: 120, height: 24)
      |> Rendro.link(page: 2)

    target = %Rendro.Page{
      blocks: [%Rendro.Block{content: Rendro.text("Target page"), x: 0, y: 0}]
    }

    %Rendro.Document{
      pages: [
        %Rendro.Page{
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [alpha, beta]
        },
        target
      ],
      metadata: %Rendro.Metadata{title: "Ordered Links"}
    }
  end

  defp embedded_file_order_doc(order) do
    registrations =
      case order do
        :alpha_first ->
          [
            {:alpha, "alpha.txt", "alpha-data"},
            {:zeta, "zeta.txt", "zeta-data"}
          ]

        :zeta_first ->
          [
            {:zeta, "zeta.txt", "zeta-data"},
            {:alpha, "alpha.txt", "alpha-data"}
          ]
      end

    Enum.reduce(registrations, simple_doc(), fn {logical_name, filename, bytes}, doc ->
      Rendro.register_embedded_file(doc, logical_name, {:binary, bytes},
        filename: filename,
        mime_type: "text/plain"
      )
    end)
  end

  defp signature_field_doc do
    signature =
      Rendro.signature_field("customer_signature",
        x: 10,
        y: 20,
        width: 180,
        height: 48
      )

    %Rendro.Document{
      pages: [
        %Rendro.Page{
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [signature]
        }
      ],
      metadata: %Rendro.Metadata{title: "Signature Determinism"}
    }
  end

  defp dictionary_key_groups(pdf) do
    Regex.scan(~r/<<\n(.*?)\n>>/s, pdf, capture: :all_but_first)
    |> Enum.map(fn [body] -> body end)
    |> Enum.map(&top_level_keys/1)
    |> Enum.filter(&(length(&1) > 1))
  end

  defp top_level_keys(dict_body) do
    {_, keys} =
      dict_body
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce({0, []}, fn line, {depth, acc} ->
        key = top_level_key(line, depth)
        depth_delta = token_count(line, "<<") - token_count(line, ">>")
        next_depth = max(depth + depth_delta, 0)
        {next_depth, if(key, do: [key | acc], else: acc)}
      end)

    Enum.reverse(keys)
  end

  defp top_level_key(line, 0) do
    case Regex.run(~r/^\/([A-Za-z0-9]+)/, line, capture: :all_but_first) do
      [found] -> found
      _ -> nil
    end
  end

  defp top_level_key(_line, _depth), do: nil

  defp token_count(line, token) do
    line
    |> String.split(token)
    |> length()
    |> Kernel.-(1)
  end

  defp annotation_offsets(pdf, needles) do
    Enum.map(needles, &offset_of(pdf, &1))
  end

  defp offset_of(pdf, needle) do
    case :binary.match(pdf, needle) do
      {offset, _length} -> offset
      :nomatch -> raise "missing #{needle} in PDF output"
    end
  end

  # --- D-11 helpers ---

  # Builds a multi-page flow document with a running footer containing footer_text.
  # Uses an explicit template with footer_height=20 so body_capacity is geometry-driven.
  # Generates 60 body lines to ensure at least 2 pages with the small body region.
  defp running_footer_doc(footer_text) do
    template =
      %Rendro.PageTemplate{
        name: :d11_test,
        width: 420,
        height: 300,
        margin_top: 20,
        margin_right: 24,
        margin_bottom: 20,
        margin_left: 24,
        regions: [
          %Rendro.Region{
            name: :body,
            role: :body,
            anchor: :flow,
            x: 24,
            y: 40,
            width: 372,
            height: 220
          },
          %Rendro.Region{
            name: :footer,
            role: :footer,
            anchor: :bottom,
            x: 24,
            y: 268,
            width: 372,
            height: 20
          }
        ]
      }

    footer_section =
      Rendro.section(
        region: :footer,
        content: [Rendro.block(Rendro.text(footer_text))]
      )

    content = for i <- 1..60, do: Rendro.block(Rendro.text("Line #{i}"))

    Rendro.flow(
      content,
      page_template: :d11_test,
      page_templates: [template],
      sections: [footer_section]
    )
  end

  # Runs Build → Compose → Measure on a doc with `n` body lines and
  # an explicit template with footer_height=30, then returns body_capacity.
  defp measure_body_capacity(n) do
    template =
      %Rendro.PageTemplate{
        name: :d11_cap_test,
        width: 420,
        height: 300,
        margin_top: 20,
        margin_right: 24,
        margin_bottom: 20,
        margin_left: 24,
        regions: [
          %Rendro.Region{
            name: :body,
            role: :body,
            anchor: :flow,
            x: 24,
            y: 40,
            width: 372,
            height: 220
          },
          %Rendro.Region{
            name: :footer,
            role: :footer,
            anchor: :bottom,
            x: 24,
            y: 268,
            width: 372,
            height: 30
          }
        ]
      }

    footer_section =
      Rendro.section(
        region: :footer,
        content: [Rendro.block(Rendro.text("Page {{page_number}} of {{total_pages}}"))]
      )

    content = for i <- 1..n, do: Rendro.block(Rendro.text("Line #{i}"))

    doc =
      Rendro.flow(
        content,
        page_template: :d11_cap_test,
        page_templates: [template],
        sections: [footer_section]
      )

    {:ok, built} = Build.run(doc)
    {:ok, composed} = Compose.run(built)
    {:ok, measured} = Measure.run(composed)
    measured.options.layout.body_capacity
  end

  # Counts body blocks per page (blocks that are NOT footer/header blocks).
  # A body block is any block whose content was placed by the body region (not a running region).
  # We use a heuristic: after paginate, body blocks appear before region blocks in page.blocks;
  # we count blocks whose x/y matches body region positioning (non-zero y from body stack).
  # Simpler: count blocks NOT having the substituted footer text pattern.
  defp body_block_counts(%{pages: pages}) do
    Enum.map(pages, fn page ->
      Enum.count(page.blocks, &body_block?/1)
    end)
  end

  defp body_block?(%Rendro.Block{content: %Rendro.Pipeline.MeasuredText{source: source}}) do
    # Footer blocks contain page-number tokens (substituted) — body blocks do not
    not (String.contains?(source.content, "Page") and
           String.contains?(source.content, "of"))
  end

  defp body_block?(%Rendro.Block{content: %Rendro.Text{content: text}}) do
    not (String.contains?(text, "Page") and String.contains?(text, "of"))
  end

  defp body_block?(_), do: true

  # Finds a footer block (MeasuredText containing page number pattern) on a page.
  defp find_footer_block(%Rendro.Page{blocks: blocks}) do
    Enum.find(blocks, fn block ->
      case block.content do
        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text}} ->
          String.contains?(text, "Page") or String.contains?(text, "{{page_number}}")

        _ ->
          false
      end
    end)
  end

  # Extracts run widths from a footer block's MeasuredText lines.
  defp footer_run_widths(%Rendro.Block{content: %Rendro.Pipeline.MeasuredText{lines: lines}}) do
    Enum.flat_map(lines, fn line -> Enum.map(line, & &1.width) end)
  end

  defp footer_run_widths(_), do: []
end

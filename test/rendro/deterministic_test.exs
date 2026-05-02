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

  describe "embedded font parity" do
    test "the same resolved embedded font drives deterministic wrapping, pagination, and final PDF resources" do
      %{bytes: bytes} = FontFixture.supported_font()
      template = embedded_wrap_template()

      doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})
        |> Map.put(:content, [
          Rendro.block(Rendro.text("alpha beta gamma delta", font: :brand, size: 12), width: 150),
          Rendro.block(Rendro.text("alpha beta gamma delta", font: :brand, size: 12), width: 150)
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
end

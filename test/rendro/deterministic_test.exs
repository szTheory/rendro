defmodule Rendro.DeterministicTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Rendro.Test.Generators

  @moduletag :deterministic

  describe "property: deterministic byte-identity" do
    property "two deterministic renders of the same document produce identical binaries" do
      check all(doc <- document_gen(), max_runs: 100) do
        {:ok, pdf1} = Rendro.render(doc, deterministic: true)
        {:ok, pdf2} = Rendro.render(doc, deterministic: true)
        assert pdf1 == pdf2
      end
    end

    property "deterministic output is stable across 10 sequential renders" do
      check all(doc <- document_gen(), max_runs: 25) do
        {:ok, reference} = Rendro.render(doc, deterministic: true)

        for _ <- 1..9 do
          {:ok, pdf} = Rendro.render(doc, deterministic: true)
          assert pdf == reference
        end
      end
    end

    property "non-deterministic mode produces valid PDF output" do
      check all(doc <- document_gen(), max_runs: 50) do
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

      trailer_match = Regex.scan(~r"/(\w+)\s", pdf) |> Enum.map(&List.last/1)

      groups = chunk_by_dict(trailer_match)

      for group <- groups, length(group) > 1 do
        assert group == Enum.sort(group),
               "Dictionary keys not sorted: #{inspect(group)}"
      end
    end
  end

  defp simple_doc do
    text = %Rendro.Text{content: "Hello World", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 0, y: 0}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Test"}}
  end

  defp chunk_by_dict(keys) do
    keys
    |> Enum.chunk_while(
      [],
      fn key, acc ->
        if key in ["obj", "endobj", "stream", "endstream", "xref", "trailer", "startxref", "PDF", "EOF", "R"] do
          if acc == [], do: {:cont, acc}, else: {:cont, Enum.reverse(acc), []}
        else
          {:cont, [key | acc]}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.reverse(acc), []}
      end
    )
    |> Enum.filter(&(length(&1) > 1))
  end
end

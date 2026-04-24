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

      groups = dictionary_key_groups(pdf)

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
        key =
          if depth == 0 do
            case Regex.run(~r/^\/([A-Za-z0-9]+)/, line, capture: :all_but_first) do
              [found] -> found
              _ -> nil
            end
          end

        depth_delta = token_count(line, "<<") - token_count(line, ">>")
        next_depth = max(depth + depth_delta, 0)
        {next_depth, if(key, do: [key | acc], else: acc)}
      end)

    Enum.reverse(keys)
  end

  defp token_count(line, token) do
    line
    |> String.split(token)
    |> length()
    |> Kernel.-(1)
  end
end

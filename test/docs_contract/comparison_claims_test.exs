defmodule Rendro.DocsContract.ComparisonClaimsTest do
  use ExUnit.Case, async: true

  @guide_path "guides/comparison.md"

  test "comparison static contract is current" do
    assert Rendro.Comparison.static_contract_errors() == []
  end

  test "manifest records the required comparator ids" do
    manifest = Rendro.Comparison.read_manifest!()
    ids = Enum.map(manifest["comparators"], & &1["id"])

    for id <- ~w(rendro chromic_pdf chromic_pdf_warm_pool pdf_generator typst_cli) do
      assert id in ids
    end
  end

  test "public claim ids are unique and resolve to guide citations when the guide exists" do
    manifest = Rendro.Comparison.read_manifest!()
    public_claims = Enum.filter(manifest["claims"], &(Map.get(&1, "public", true) != false))
    public_ids = Enum.map(public_claims, & &1["id"])

    assert public_ids == Enum.uniq(public_ids)

    if File.exists?(@guide_path) do
      guide = File.read!(@guide_path)
      citations = Regex.scan(~r/\[bench:(CMP-[A-Z0-9-]+)\]/, guide, capture: :all_but_first)
      cited_ids = citations |> List.flatten() |> Enum.uniq()

      for id <- cited_ids do
        assert id in public_ids
      end

      for id <- public_ids do
        assert "[bench:#{id}]" in guide
      end
    end
  end

  test "comparison guide has no uncited comparative phrases when it exists" do
    if File.exists?(@guide_path) do
      guide = File.read!(@guide_path)

      forbidden_phrases = [
        "faster",
        "smaller",
        "lower RSS",
        "fewer dependencies",
        "lighter",
        "no Chrome runtime"
      ]

      guide
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.each(fn {line, number} ->
        for phrase <- forbidden_phrases do
          if String.contains?(line, phrase) do
            assert line =~ ~r/\[bench:CMP-[A-Z0-9-]+\]/,
                   "line #{number} has uncited comparative phrase #{inspect(phrase)}"
          end
        end
      end)
    end
  end

  test "docs verification script includes the comparison claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~r/\{"Comparison claims lane",\s*\["test",\s*"test\/docs_contract\/comparison_claims_test\.exs"\]\}/s
  end
end

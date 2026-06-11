defmodule Rendro.ComparisonTest do
  use ExUnit.Case, async: true

  @fixture_hash "8b8fbf820b7183fcc182f8c65714b618196f6d21bcbcd95661a7459034a3e0e9"

  test "read_manifest!/0 reads the comparison manifest" do
    assert %{} = Rendro.Comparison.read_manifest!()
  end

  test "static contract accepts the scaffold manifest" do
    assert Rendro.Comparison.static_contract_errors() == []
  end

  test "static contract catches missing schema version" do
    manifest = Map.delete(Rendro.Comparison.read_manifest!(), "schema_version")

    assert "schema_version must be 1" in Rendro.Comparison.static_contract_errors(manifest)
  end

  test "static contract catches missing comparator ids" do
    manifest =
      update_in(Rendro.Comparison.read_manifest!(), ["comparators"], fn comparators ->
        Enum.reject(comparators, &(&1["id"] == "chromic_pdf_warm_pool"))
      end)

    assert Enum.any?(
             Rendro.Comparison.static_contract_errors(manifest),
             &String.contains?(&1, "chromic_pdf_warm_pool")
           )
  end

  test "static contract catches missing metric ids" do
    manifest =
      update_in(Rendro.Comparison.read_manifest!(), ["results"], fn results ->
        Enum.reject(results, &(&1["metric"] == "dependency_count"))
      end)

    assert Enum.any?(
             Rendro.Comparison.static_contract_errors(manifest),
             &String.contains?(&1, "dependency_count")
           )
  end

  test "static contract catches invalid public claim ids" do
    manifest =
      Map.put(Rendro.Comparison.read_manifest!(), "claims", [
        %{
          "id" => "bad-claim",
          "public" => true,
          "text" => "Claim text",
          "scope" => "Scope",
          "evidence" => [%{"metric" => "cold_start_ms"}]
        }
      ])

    assert Enum.any?(
             Rendro.Comparison.static_contract_errors(manifest),
             &String.contains?(&1, "CMP-[A-Z0-9-]+")
           )
  end

  test "static contract catches missing raw artifacts" do
    manifest =
      put_in(
        Rendro.Comparison.read_manifest!(),
        ["results", Access.at(0), "raw_artifact"],
        "bench/results/raw/missing-static-fixture.json"
      )

    assert Enum.any?(
             Rendro.Comparison.static_contract_errors(manifest),
             &String.contains?(&1, "missing-static-fixture.json")
           )
  end

  test "static contract catches raw SHA-256 drift" do
    manifest =
      put_in(
        Rendro.Comparison.read_manifest!(),
        ["results", Access.at(0), "raw_sha256"],
        String.duplicate("0", 64)
      )

    assert Enum.any?(
             Rendro.Comparison.static_contract_errors(manifest),
             &String.contains?(&1, "bench/results/raw/plan01-static-fixture.json")
           )
  end

  @tag :tmp_dir
  test "static contract accepts an in-memory result pointing at a temp raw file", %{
    tmp_dir: tmp_dir
  } do
    raw_path = Path.join(tmp_dir, "raw.json")
    File.write!(raw_path, ~s({"ok":true}\n))
    hash = :crypto.hash(:sha256, File.read!(raw_path)) |> Base.encode16(case: :lower)

    manifest =
      put_in(Rendro.Comparison.read_manifest!(), ["results", Access.at(0)], %{
        "comparator" => "rendro",
        "metric" => "cold_start_ms",
        "median" => 1,
        "p95" => 1,
        "samples" => 1,
        "unit" => "ms",
        "raw_artifact" => raw_path,
        "raw_sha256" => hash
      })

    assert Rendro.Comparison.static_contract_errors(manifest) == []
  end

  test "generated blocks include markers and public claim citations" do
    manifest =
      Map.put(Rendro.Comparison.read_manifest!(), "claims", [
        %{
          "id" => "CMP-COLD-START-001",
          "public" => true,
          "text" => "A measured claim.",
          "scope" => "Pinned invoice harness.",
          "evidence" => [%{"metric" => "cold_start_ms"}]
        }
      ])

    fit = Rendro.Comparison.fit_block(manifest)
    results = Rendro.Comparison.results_block(manifest)
    evidence = Rendro.Comparison.evidence_block(manifest)

    assert fit =~ "<!-- rendro-comparison-fit-start -->"
    assert fit =~ "<!-- rendro-comparison-fit-end -->"
    assert fit =~ "[bench:CMP-COLD-START-001]"

    assert results =~ "<!-- rendro-comparison-results-start -->"
    assert results =~ "<!-- rendro-comparison-results-end -->"
    assert results =~ "[bench:CMP-COLD-START-001]"

    assert evidence =~ "<!-- rendro-comparison-evidence-start -->"
    assert evidence =~ "<!-- rendro-comparison-evidence-end -->"
    assert evidence =~ "[bench:CMP-COLD-START-001]"
  end

  test "static contract does not shell out or reference external advisory tools" do
    source = File.read!("lib/rendro/comparison.ex")

    refute source =~ "System.cmd"
    refute source =~ "Req."
    refute source =~ "HTTPoison"
    refute source =~ ":httpc"
  end

  test "scaffold raw artifact hash matches the manifest" do
    assert @fixture_hash ==
             "bench/results/raw/plan01-static-fixture.json"
             |> File.read!()
             |> then(&:crypto.hash(:sha256, &1))
             |> Base.encode16(case: :lower)
  end
end

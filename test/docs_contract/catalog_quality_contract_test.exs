defmodule Rendro.DocsContract.CatalogQualityContractTest do
  use ExUnit.Case, async: true

  alias Rendro.Catalog

  defp catalog_cells do
    Enum.map(Catalog.catalog_specs(), fn spec ->
      %{
        "id" => spec.id,
        "family" => Atom.to_string(spec.family),
        "brand" => spec.brand,
        "preset" => spec.preset,
        "mode" => spec.mode,
        "png_path" => spec.png_path,
        "png_sha256" => String.duplicate("a", 64),
        "source_pdf_sha256" => String.duplicate("b", 64)
      }
    end)
  end

  defp unscored(cell) do
    %{
      "catalog_id" => cell["id"],
      "family" => cell["family"],
      "brand" => cell["brand"],
      "preset" => cell["preset"],
      "mode" => cell["mode"],
      "evidence_ref" => cell["png_path"],
      "png_sha256" => cell["png_sha256"],
      "source_pdf_sha256" => cell["source_pdf_sha256"],
      "recorded_at" => "2026-08-17",
      "review_status" => "unscored",
      "reason" => "Awaiting the bounded human-review pass for this exact artifact."
    }
  end

  defp rubric(dispositions), do: %{"catalog_dispositions" => dispositions}

  test "exact ordered join accepts one disposition per cell and projects unscored without approval" do
    cells = catalog_cells()

    assert Catalog.quality_contract_errors(
             %{"cells" => cells},
             rubric(Enum.map(cells, &unscored/1))
           ) == []
  end

  test "missing, duplicate, orphan, and stale dispositions fail closed with the catalog ID" do
    [first | rest] = catalog_cells()

    missing =
      Catalog.quality_contract_errors(
        %{"cells" => [first | rest]},
        rubric(Enum.map(rest, &unscored/1))
      )

    assert Enum.any?(missing, &String.contains?(&1, "#{first["id"]}: missing disposition"))

    duplicate =
      Catalog.quality_contract_errors(
        %{"cells" => [first | rest]},
        rubric([unscored(first), unscored(first) | Enum.map(rest, &unscored/1)])
      )

    assert Enum.any?(
             duplicate,
             &String.contains?(&1, "#{first["id"]}: expected exactly one disposition")
           )

    orphan = %{unscored(first) | "catalog_id" => "invoice--orphan--swiss--light"}

    orphan_errors =
      Catalog.quality_contract_errors(
        %{"cells" => [first | rest]},
        rubric([orphan | Enum.map([first | rest], &unscored/1)])
      )

    assert Enum.any?(
             orphan_errors,
             &String.contains?(&1, "orphan disposition invoice--orphan--swiss--light")
           )

    stale = %{unscored(first) | "png_sha256" => String.duplicate("c", 64)}

    stale_errors =
      Catalog.quality_contract_errors(
        %{"cells" => [first | rest]},
        rubric([stale | Enum.map(rest, &unscored/1)])
      )

    assert Enum.any?(stale_errors, &String.contains?(&1, "#{first["id"]}: PNG hash is stale"))
  end

  test "scored dispositions preserve valid failed evidence and enforce threshold arithmetic" do
    [cell | rest] = catalog_cells()

    scored =
      Map.merge(unscored(cell), %{
        "review_status" => "scored",
        "dimension_scores" => %{
          "information_architecture" => 5,
          "content_hierarchy" => 5,
          "domain_fit" => 5,
          "reader_affordances" => 5,
          "typographic_craft" => 5,
          "restraint_cohesion" => 5
        },
        "gate_results" => %{"reading_order" => true, "print_safety" => false},
        "passed" => false,
        "signed_off_by" => "reviewer",
        "signed_off_at" => "2026-08-17",
        "justifications" => %{"print_safety" => "Observed a concrete issue."}
      })

    assert Catalog.quality_contract_errors(
             %{"cells" => [cell | rest]},
             rubric([scored | Enum.map(rest, &unscored/1)])
           ) == []
  end

  test "candidate cells remain free of projected quality and reviewer sign-off fields" do
    source = File.read!("dev/rendro/catalog.ex")

    assert source =~ "def generate_candidate"

    assert source =~
             "def candidate_manifest(cells, baseline, rubric, renderer_version, commit_sha)"

    assert source =~ "\"review_required\""
    refute source =~ "apply_quality_projections(candidate"
  end
end

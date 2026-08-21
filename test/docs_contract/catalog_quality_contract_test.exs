defmodule Rendro.DocsContract.CatalogQualityContractTest do
  use ExUnit.Case, async: true

  alias Rendro.Catalog

  @rubric_path "priv/quality/rubric_scores.json"
  @catalog_manifest_path "assets/rendro/catalog.json"
  @justification_keys ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)

  defp checked_in_rubric, do: @rubric_path |> File.read!() |> JSON.decode!()
  defp checked_in_catalog, do: @catalog_manifest_path |> File.read!() |> JSON.decode!()

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

  defp replace_catalog_disposition(dispositions, replacement) do
    Enum.map(dispositions, fn disposition ->
      if disposition["catalog_id"] == replacement["catalog_id"],
        do: replacement,
        else: disposition
    end)
  end

  defp mutate_scored_record(record, {:delete, field}), do: Map.delete(record, field)
  defp mutate_scored_record(record, {:blank, field}), do: Map.put(record, field, "")
  defp mutate_scored_record(record, {:date, value}), do: Map.put(record, "signed_off_at", value)

  defp mutate_scored_record(record, {:delete_justification, key}) do
    update_in(record, ["justifications"], &Map.delete(&1, key))
  end

  defp mutate_scored_record(record, {:blank_justification, key}) do
    put_in(record, ["justifications", key], "")
  end

  defp mutate_scored_record(record, :extra_justification) do
    put_in(record, ["justifications", "unsupported_dimension"], "Not approved.")
  end

  defp scored_evidence_mutations do
    Enum.map(
      ~w(signed_off_by signed_off_at resolution_ref supersedes_evidence_ref justifications),
      &{:delete, &1}
    ) ++
      Enum.map(
        ~w(signed_off_by signed_off_at resolution_ref supersedes_evidence_ref),
        &{:blank, &1}
      ) ++
      [{:date, "not-a-date"}, {:date, "2026-02-30"}] ++
      Enum.map(@justification_keys, &{:delete_justification, &1}) ++
      Enum.map(@justification_keys, &{:blank_justification, &1}) ++ [:extra_justification]
  end

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

  test "scored passed and failed records fail closed for every incomplete evidence mutation" do
    rubric = checked_in_rubric()
    catalog = checked_in_catalog()

    for passed <- [true, false] do
      record =
        Enum.find(
          rubric["catalog_dispositions"],
          &(&1["review_status"] == "scored" and &1["passed"] == passed)
        )

      for mutation <- scored_evidence_mutations() do
        mutated_record = mutate_scored_record(record, mutation)

        mutated_rubric =
          Map.put(
            rubric,
            "catalog_dispositions",
            replace_catalog_disposition(rubric["catalog_dispositions"], mutated_record)
          )

        errors = Catalog.quality_contract_errors(catalog, mutated_rubric)

        assert Enum.any?(errors, &String.contains?(&1, record["catalog_id"])),
               "#{record["catalog_id"]}: #{inspect(mutation)} must report its catalog ID, got: #{inspect(errors)}"
      end
    end
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

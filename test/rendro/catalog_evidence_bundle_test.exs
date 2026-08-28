defmodule Rendro.CatalogEvidenceBundleTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogEvidenceBundle

  @sha String.duplicate("a", 40)

  test "builds and validates a closed review bundle with candidate cells and image manifests" do
    root = temporary_root("review")

    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)
    assert :ok = CatalogEvidenceBundle.validate(root, :review)

    manifest = root |> Path.join("manifest.json") |> File.read!() |> JSON.decode!()
    assert manifest["schema_version"] == 1
    assert manifest["operation"] == "review"
    assert manifest["candidate_sha"] == @sha

    assert Enum.map(manifest["payloads"], & &1["role"]) == [
             "candidate/catalog.json",
             "final-review/final.json",
             "multipage-review/multipage.json",
             "preset-review/preset.json"
           ]

    checksums =
      root |> Path.join("checksums.sha256") |> File.read!() |> String.split("\n", trim: true)

    assert checksums == Enum.sort(checksums)
  end

  test "builds exactly the canonical catalog role and count" do
    root = temporary_root("canonical")

    assert :ok =
             CatalogEvidenceBundle.build(:canonical, canonical_sources(root), provenance(), root)

    assert :ok = CatalogEvidenceBundle.validate(root, :canonical)
  end

  test "rejects invalid operation, SHA binding, unsafe roles, and candidate approval" do
    root = temporary_root("invalid")

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(:invalid, review_sources(root), provenance(), root)

    assert :invalid_operation in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               review_sources(root),
               %{provenance() | candidate_sha: "A" <> String.duplicate("a", 39)},
               root
             )

    assert :invalid_candidate_sha in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               [
                 %{
                   role: "../escape.json",
                   source: write_source(root, "bad", "x"),
                   media_type: "application/json",
                   count: 1
                 }
               ],
               provenance(),
               root
             )

    assert :invalid_payload_roles in reasons

    assert {:error, reasons} =
             CatalogEvidenceBundle.build(
               :review,
               review_sources(root),
               Map.put(provenance(), :reviewer_approval, true),
               root
             )

    assert :candidate_reviewer_approval_forbidden in reasons
  end

  test "fails closed on manifest, role, count, and payload hash drift" do
    root = temporary_root("drift")
    assert :ok = CatalogEvidenceBundle.build(:review, review_sources(root), provenance(), root)

    manifest_path = Path.join(root, "manifest.json")
    manifest = JSON.decode!(File.read!(manifest_path))

    for mutated <- [
          Map.put(manifest, "checked_out_head", String.duplicate("b", 40)),
          Map.update!(manifest, "payloads", &Enum.reverse/1),
          put_in(manifest, ["payloads", Access.at(0), "count"], 31)
        ] do
      File.write!(manifest_path, Jason.encode!(mutated, pretty: true))
      assert {:error, _reasons} = CatalogEvidenceBundle.validate(root, :review)
    end

    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
    File.write!(Path.join(root, "candidate/catalog.json"), "tampered")
    assert {:error, reasons} = CatalogEvidenceBundle.validate(root, :review)
    assert :payload_hash_mismatch in reasons
  end

  test "derives every closed role count from its actual payload records" do
    root = temporary_root("actual-count")
    sources = review_sources(root)

    candidate = List.first(sources)
    File.write!(candidate.source, cells_json(31))

    assert {:error, reasons} = CatalogEvidenceBundle.build(:review, sources, provenance(), root)
    assert :invalid_payload_counts in reasons
  end

  defp provenance do
    %{
      candidate_sha: @sha,
      checked_out_head: @sha,
      control_sha: String.duplicate("b", 40),
      event: "workflow_dispatch",
      run_id: "12345",
      run_attempt: 1,
      dpi: 96
    }
  end

  defp review_sources(root) do
    [
      {"candidate/catalog.json", cells_json(32), 32},
      {"final-review/final.json", images_json(12), 12},
      {"multipage-review/multipage.json", checksums(4), 4},
      {"preset-review/preset.json", images_json(12), 12}
    ]
    |> Enum.map(fn {role, contents, count} ->
      %{
        role: role,
        source: write_source(root, role, contents),
        media_type: "application/json",
        count: count
      }
    end)
  end

  defp canonical_sources(root) do
    [
      %{
        role: "canonical/catalog.json",
        source: write_source(root, "canonical", images_json(32)),
        media_type: "application/json",
        count: 32
      }
    ]
  end

  defp write_source(root, name, contents) do
    path = Path.join([root <> "-inputs", name])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    path
  end

  defp images_json(count),
    do: Jason.encode!(%{"images" => Enum.map(1..count, &%{"id" => "item-#{&1}"})})

  defp cells_json(count),
    do: Jason.encode!(%{"cells" => Enum.map(1..count, &%{"id" => "item-#{&1}"})})

  defp checksums(count) do
    Enum.map_join(1..count, "\n", fn index ->
      "#{String.duplicate("a", 64)}  page-#{index}.png"
    end) <> "\n"
  end

  defp temporary_root(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-catalog-evidence-#{label}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    root
  end
end

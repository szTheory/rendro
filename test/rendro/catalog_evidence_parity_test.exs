defmodule Rendro.CatalogEvidenceParityTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogEvidenceParity

  @record ".planning/phases/135-test-ci-cd-simplification/135-parity-comparator-record.json"
  @routes ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)

  test "sealed retained record mechanically derives every route as matched" do
    record = record()

    assert {:ok, results} = CatalogEvidenceParity.verify_record(record)
    assert Enum.sort(Map.keys(results)) == Enum.sort(@routes)
    assert Enum.all?(results, fn {_route, result} -> result["status"] == "matched" end)
  end

  test "rejects malformed transport facts and fabricated result status" do
    record = record()

    mutations = [
      put_in(record, ["transport", "candidate_sha"], "bad"),
      put_in(
        record,
        ["routes", "phase126_preset_review", "legacy", "transport", "run_url"],
        "http://bad"
      ),
      put_in(
        record,
        ["routes", "phase127_catalog_review", "generic", "transport", "run_attempt"],
        0
      ),
      put_in(
        record,
        [
          "routes",
          "phase130_review",
          "legacy",
          "transport",
          "artifacts",
          Access.at(0),
          "identity"
        ],
        ""
      ),
      put_in(
        record,
        [
          "routes",
          "phase130_canonical",
          "generic",
          "transport",
          "artifacts",
          Access.at(0),
          "archive_sha256"
        ],
        "bad"
      ),
      put_in(
        record,
        ["routes", "phase126_preset_review", "generic", "transport", "reviewer_required"],
        true
      ),
      put_in(record, ["routes", "phase130_review", "status"], "matched-but-fabricated")
    ]

    for mutated <- mutations,
        do: assert({:error, _} = CatalogEvidenceParity.verify_record(mutated))
  end

  test "rejects missing and duplicate typed transport artifact entries" do
    record = record()
    path = ["routes", "phase130_review", "legacy", "transport", "artifacts"]
    artifacts = get_in(record, path)

    assert {:error, [:invalid_transport]} =
             CatalogEvidenceParity.verify_record(
               put_in(record, path, []),
               "phase130_review"
             )

    assert {:error, [:invalid_transport]} =
             CatalogEvidenceParity.verify_record(
               put_in(record, path, [hd(artifacts) | artifacts]),
               "phase130_review"
             )
  end

  test "rejects a syntactically valid route-side candidate SHA that differs from the sealed candidate" do
    mutated =
      put_in(
        record(),
        ["routes", "phase127_catalog_review", "legacy", "transport", "candidate_sha"],
        String.duplicate("b", 40)
      )

    assert {:error, [:candidate_identity_mismatch]} = CatalogEvidenceParity.verify_record(mutated)
  end

  @tag :tmp_dir
  test "malformed scalar records fail closed at sealed and raw artifact boundaries", %{
    tmp_dir: tmp_dir
  } do
    malformed =
      put_in(
        record(),
        ["routes", "phase130_canonical", "legacy", "roles", "canonical32"],
        [42]
      )

    assert {:error, _} = CatalogEvidenceParity.verify_record(malformed)

    legacy_root = Path.join(tmp_dir, "legacy")
    generic_root = Path.join(tmp_dir, "generic")
    File.mkdir_p!(legacy_root)
    File.mkdir_p!(Path.join(generic_root, "canonical"))

    File.write!(
      Path.join(legacy_root, "manifest.txt"),
      "#{String.duplicate("a", 64)}  assets/rendro/catalog/invoice/default/default-light.png\n"
    )

    File.write!(
      Path.join(generic_root, "canonical/catalog.json"),
      Jason.encode!(%{"images" => [42]})
    )

    assert {:error, [:invalid_json_role]} =
             CatalogEvidenceParity.compare(
               %{"root" => legacy_root},
               %{"root" => generic_root},
               "phase130_canonical"
             )

    File.write!(
      Path.join(legacy_root, "manifest.txt"),
      "#{String.duplicate("a", 64)}  assets/rendro/catalog/one-segment.png\n"
    )

    assert {:error, [:invalid_legacy_manifest]} =
             CatalogEvidenceParity.compare(
               %{"root" => legacy_root},
               %{"root" => generic_root},
               "phase130_canonical"
             )
  end

  test "fails closed for each route's duplicate identifier, changed hash, and cardinality" do
    record = record()

    for route <- @routes do
      [role | _] = Map.keys(record["routes"][route]["legacy"]["roles"])
      records = get_in(record, ["routes", route, "legacy", "roles", role])

      duplicate =
        put_in(record, ["routes", route, "legacy", "roles", role], [hd(records) | records])

      changed =
        put_in(
          record,
          ["routes", route, "legacy", "roles", role, Access.at(0), "sha256"],
          String.duplicate("f", 64)
        )

      assert {:error, _} = CatalogEvidenceParity.verify_record(duplicate, route)

      assert {:error, [:fabricated_status]} = CatalogEvidenceParity.verify_record(changed, route)
    end
  end

  defp record, do: @record |> File.read!() |> Jason.decode!()
end

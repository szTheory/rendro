defmodule Rendro.CatalogEvidenceParityTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogEvidenceParity

  @routes ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)a

  test "accepts all locked routes with distinct valid per-side transport provenance" do
    for route <- @routes do
      legacy = evidence("legacy", route)
      generic = evidence("generic", route)

      assert {:ok, normalized} = CatalogEvidenceParity.compare(legacy, generic, route)
      assert normalized["route"] == Atom.to_string(route)
      assert normalized["legacy"]["run_id"] != normalized["generic"]["run_id"]
    end
  end

  test "rejects each shared authority mutation" do
    legacy = evidence("legacy", :phase130_review)

    mutations = [
      put_in(legacy, ["payloads", Access.at(0), "sha256"], String.duplicate("f", 64)),
      put_in(legacy, ["payloads", Access.at(0), "count"], 31),
      Map.put(legacy, "candidate_sha", String.duplicate("c", 40)),
      put_in(legacy, ["renderer", "dpi"], 72),
      put_in(legacy, ["reviewer", "required"], true),
      put_in(legacy, ["actions", "checkout"], "not-pinned"),
      put_in(legacy, ["permissions", "contents"], "write")
    ]

    for mutated <- mutations do
      assert {:error, reasons} =
               CatalogEvidenceParity.compare(
                 mutated,
                 evidence("generic", :phase130_review),
                 :phase130_review
               )

      assert reasons != []
    end
  end

  test "rejects missing, malformed, and misbound side-specific provenance" do
    generic = evidence("generic", :phase130_review)

    for mutated <- [
          Map.delete(generic, "run_id"),
          Map.put(generic, "run_attempt", 0),
          Map.put(generic, "upload_digest", "not-a-digest"),
          Map.put(generic, "artifact_identity", " "),
          Map.put(generic, "provenance_candidate_sha", String.duplicate("b", 40))
        ] do
      assert {:error, reasons} =
               CatalogEvidenceParity.compare(
                 evidence("legacy", :phase130_review),
                 mutated,
                 :phase130_review
               )

      assert Enum.any?(reasons, &(&1 in [:invalid_provenance, :misbound_provenance]))
    end
  end

  defp evidence(side, route) do
    %{
      "candidate_sha" => String.duplicate("a", 40),
      "checked_out_head" => String.duplicate("a", 40),
      "renderer" => %{
        "version" => "v0.11.0",
        "binary_sha256" => String.duplicate("b", 64),
        "dpi" => 96
      },
      "payloads" => [%{"role" => "catalog", "sha256" => String.duplicate("c", 64), "count" => 32}],
      "actions" => %{"checkout" => "df4cb1c069e1874edd31b4311f1884172cec0e10"},
      "permissions" => %{"contents" => "read"},
      "reviewer" =>
        if(route == :phase130_canonical, do: %{"required" => true}, else: %{"required" => false}),
      "run_id" => "#{side}-12345",
      "run_attempt" => if(side == "legacy", do: 1, else: 2),
      "run_url" => "https://example.invalid/#{side}/12345",
      "artifact_identity" => "#{side}-artifact",
      "upload_digest" => String.duplicate(if(side == "legacy", do: "d", else: "e"), 64),
      "provenance_candidate_sha" => String.duplicate("a", 40)
    }
  end
end

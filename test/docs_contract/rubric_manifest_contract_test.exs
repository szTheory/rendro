# Compile Rendro.EdgeMatrixTest so stress_fixture_ids/0 is available even when this
# file runs in isolation (`mix test test/docs_contract/rubric_manifest_contract_test.exs`).
# `.exs` test files outside test/support/ are not on elixirc_paths(:test), so without
# this require the module would be undefined. Mirrors test/scripts/release_preflight_proof_test.exs:1.
Code.require_file("test/rendro/edge_matrix_test.exs", File.cwd!())

defmodule Rendro.DocsContract.RubricManifestContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @manifest_path "priv/quality/rubric_scores.json"
  @schema_path "priv/schemas/rubric_scores.schema.json"

  defp manifest do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp rubric_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  # Test-only pass/fail helper. Mirrors Rendro.Comparison's accumulator style but is
  # scoped entirely to this test file — per Phase 114's "no `lib/` product change
  # except the loader" boundary, the threshold arithmetic lives nowhere in `lib/`.
  #
  # Returns true only when the hierarchy dimension is exactly 5, every other core
  # dimension is >= 4, and every gate result is true.
  defp passed?(dimension_scores, gate_results) do
    hierarchy_ok? = dimension_scores["content_hierarchy"] == 5

    other_cores_ok? =
      dimension_scores
      |> Map.delete("content_hierarchy")
      |> Map.values()
      |> Enum.all?(&(&1 >= 4))

    gates_ok? = gate_results |> Map.values() |> Enum.all?(&(&1 == true))

    hierarchy_ok? and other_cores_ok? and gates_ok?
  end

  test "schema validation: checked-in manifest validates against rubric_scores.schema.json" do
    assert {:ok, _} = JSV.validate(manifest(), rubric_schema()),
           "#{@manifest_path} failed validation against #{@schema_path}"
  end

  test "structural enumeration: 6 dimensions, 2 gates, hierarchy/core thresholds" do
    m = manifest()

    assert length(m["dimensions"]) == 6
    assert length(m["gates"]) == 2
    assert m["thresholds"]["hierarchy_min"] == 5
    assert m["thresholds"]["core_min"] >= 4
  end

  test "threshold-arithmetic correctness, not the subjective score" do
    # Synthetic (not real) inputs — `scores` is empty this phase, so this proves the
    # arithmetic itself is enforced independent of any demo's subjective rating.
    all_pass_scores = %{
      "information_architecture" => 5,
      "content_hierarchy" => 5,
      "domain_fit" => 5,
      "reader_affordances" => 5,
      "typographic_craft" => 5,
      "restraint_cohesion" => 5
    }

    all_pass_gates = %{"reading_order" => true, "print_safety" => true}

    assert passed?(all_pass_scores, all_pass_gates),
           "an all-5s / all-true synthetic input must pass"

    # Near-miss 1: hierarchy = 4 (fails the hierarchy=5 rule)
    refute passed?(%{all_pass_scores | "content_hierarchy" => 4}, all_pass_gates),
           "content_hierarchy below 5 must fail even when every other core is 5"

    # Near-miss 2: one other core dimension = 3 (fails core>=4)
    refute passed?(%{all_pass_scores | "typographic_craft" => 3}, all_pass_gates),
           "a core dimension below 4 must fail"

    # Near-miss 3: one gate = false (fails gates-pass)
    refute passed?(all_pass_scores, %{all_pass_gates | "print_safety" => false}),
           "a failing gate must fail regardless of dimension scores"
  end

  # --- D-15 fail-loud-in-both-directions stress-exemption guards ------------

  test "D-15i: stress_exemption is present, exempt, and carries a non-empty reason" do
    exemption = manifest()["stress_exemption"]

    assert exemption["exempt"] == true,
           "stress_exemption.exempt must be true"

    assert is_binary(exemption["reason"]) and exemption["reason"] != "",
           "stress_exemption.reason must be a non-empty string"
  end

  test "D-15ii: no scores entry may set stress_exempt to dodge the beauty gate" do
    refute Enum.any?(manifest()["scores"], &Map.get(&1, "stress_exempt", false)),
           "the per-entry stress_exempt field is a loophole tripwire — no real demo " <>
             "score may set it true to bypass the reader-quality rubric"
  end

  test "D-15iii: stress-fixture ID set is disjoint from the scores array's demo_ids" do
    stress_ids = Rendro.EdgeMatrixTest.stress_fixture_ids()
    score_ids = MapSet.new(Enum.map(manifest()["scores"], & &1["demo_id"]))

    assert MapSet.disjoint?(stress_ids, score_ids),
           "stress-matrix fixture IDs must never collide with curated demo demo_ids; " <>
             "overlap: #{inspect(MapSet.intersection(stress_ids, score_ids))}"
  end

  test "D-15iv teeth guard: the stress-fixture ID set is non-empty (62 cells)" do
    assert MapSet.size(Rendro.EdgeMatrixTest.stress_fixture_ids()) == 62,
           "disjointness must not pass vacuously — the imported stress-fixture set " <>
             "must be the full 62 :applies cells"
  end
end

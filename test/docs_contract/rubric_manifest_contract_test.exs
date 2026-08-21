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
  @gallery_manifest_path "assets/rendro/artifacts.json"
  @non_prose_fixture_path "test/fixtures/quality/rubric_scores_phase130_non_prose.json"
  @justification_keys ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)

  defp manifest do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp gallery_png_paths do
    @gallery_manifest_path
    |> File.read!()
    |> JSON.decode!()
    |> Map.fetch!("gallery")
    |> MapSet.new(& &1["png_path"])
  end

  defp rubric_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end

  defp non_prose_fixture do
    @non_prose_fixture_path
    |> File.read!()
    |> JSON.decode!()
  end

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

  test "schema rejects incomplete scored evidence for both passing and failed Phase 130 rows" do
    m = manifest()

    for passed <- [true, false] do
      record =
        Enum.find(
          m["catalog_dispositions"],
          &(&1["review_status"] == "scored" and &1["passed"] == passed)
        )

      for mutation <- scored_evidence_mutations() do
        mutated_record = mutate_scored_record(record, mutation)

        mutated =
          put_in(
            m,
            ["catalog_dispositions"],
            replace_catalog_disposition(m["catalog_dispositions"], mutated_record)
          )

        refute match?({:ok, _}, JSV.validate(mutated, rubric_schema())),
               "#{record["catalog_id"]}: #{inspect(mutation)} must fail schema validation"
      end
    end
  end

  test "the independent pre-fix snapshot preserves every non-prose manifest value" do
    stripped =
      manifest()
      |> update_in(["catalog_dispositions"], fn dispositions ->
        Enum.map(dispositions, fn
          %{"review_status" => "scored"} = disposition ->
            Map.delete(disposition, "justifications")

          disposition ->
            disposition
        end)
      end)

    assert stripped == non_prose_fixture()
  end

  test "structural enumeration: 6 dimensions, 2 gates, hierarchy/core thresholds" do
    m = manifest()

    assert length(m["dimensions"]) == 6
    assert length(m["gates"]) == 2
    assert m["thresholds"]["hierarchy_min"] == 5
    assert m["thresholds"]["core_min"] >= 4
  end

  test "catalog dispositions are additive while the six legacy rubric records remain intact" do
    m = manifest()

    assert length(m["scores"]) == 6,
           "catalog review records must not replace or rewrite the six legacy gallery scores"

    assert Enum.map(m["scores"], & &1["demo_id"]) == [
             "invoice-acme-phoenix-saas",
             "statement-northwind-ledger-co",
             "receipt-harbor-and-oak-cafe",
             "certificate-summit-training-institute",
             "payslip-aurora-live",
             "ticket-aurora-live"
           ]

    assert length(m["catalog_dispositions"]) == 32
    assert Enum.count(m["catalog_dispositions"], &(&1["review_status"] == "scored")) == 12
    assert Enum.count(m["catalog_dispositions"], &(&1["review_status"] == "unscored")) == 20
  end

  test "catalog dispositions recompute from frozen thresholds before projection generation" do
    dispositions = manifest()["catalog_dispositions"]

    for disposition <- dispositions, disposition["review_status"] == "scored" do
      assert disposition["passed"] ==
               passed?(disposition["dimension_scores"], disposition["gate_results"])

      if disposition["passed"] do
        assert is_binary(disposition["supersedes_evidence_ref"])
        assert is_binary(disposition["resolution_ref"])
      end
    end
  end

  test "Phase 130 transcribes the twelve reviewed catalog records with frozen dark boundaries" do
    dispositions = manifest()["catalog_dispositions"]

    expected = %{
      "invoice--cedar-mutual--corporate-classic--light" => {"4/5/4/4/4/4", true},
      "invoice--cedar-mutual--corporate-classic--dark" => {"4/5/4/3/3/3", false},
      "statement--signal-ledger--minimal-mono--light" => {"5/5/4/4/4/5", true},
      "statement--signal-ledger--minimal-mono--dark" => {"4/5/4/3/3/3", false},
      "receipt--poppy-and-grain--humanist--light" => {"5/5/4/5/4/5", true},
      "receipt--poppy-and-grain--humanist--dark" => {"5/5/4/5/4/5", false},
      "certificate--meridian-arts-fellowship--editorial--light" => {"5/5/4/4/4/5", true},
      "certificate--meridian-arts-fellowship--editorial--dark" => {"5/5/4/4/4/5", false},
      "payslip--northline-logistics--swiss--light" => {"4/5/4/3/3/4", false},
      "payslip--northline-logistics--swiss--dark" => {"4/5/4/2/3/3", false},
      "ticket--aurora-live--brutalist--light" => {"4/5/4/3/3/4", false},
      "ticket--aurora-live--brutalist--dark" => {"4/5/4/2/3/3", false}
    }

    scored = Enum.filter(dispositions, &(&1["review_status"] == "scored"))
    assert MapSet.new(Enum.map(scored, & &1["catalog_id"])) == MapSet.new(Map.keys(expected))

    for disposition <- scored do
      {scores, expected_passed} = Map.fetch!(expected, disposition["catalog_id"])

      assert disposition["dimension_scores"]
             |> Map.take(
               ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)
             )
             |> then(fn dimensions ->
               ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)
               |> Enum.map_join("/", &Integer.to_string(dimensions[&1]))
             end) == scores

      assert disposition["passed"] == expected_passed

      assert disposition["passed"] ==
               passed?(disposition["dimension_scores"], disposition["gate_results"])

      assert disposition["signed_off_by"] == "Jon"
      assert disposition["signed_off_at"] == "2026-08-20"
      assert is_binary(disposition["supersedes_evidence_ref"])
      assert is_binary(disposition["resolution_ref"])
    end

    for disposition <- scored, disposition["mode"] == "dark" do
      refute disposition["passed"]
      refute disposition["gate_results"]["print_safety"]
    end
  end

  test "threshold-arithmetic correctness, not the subjective score" do
    # Synthetic (not real) inputs — the near-miss cases below can't be expressed by the
    # real all-passing demo data, so this proves the arithmetic itself rejects each
    # failure mode independent of any demo's subjective rating. The companion test
    # "recorded `passed` matches recomputation ..." applies the same rule to the real
    # scores[] entries.
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

  test "recorded `passed` matches recomputation from each entry's own dimensions/gates" do
    # Regression guard for SHOW-01's original failure mode: a manifest entry recorded
    # `passed: true` that did NOT satisfy the passed?/2 arithmetic. This recomputes the
    # verdict from each entry's own dimension_scores/gate_results and asserts it equals
    # the recorded `passed`, so the field can never again be asserted independently.
    scores = manifest()["scores"]

    assert scores != [],
           "manifest scores[] must not be empty once demos are recorded — an empty " <>
             "array would make this tripwire pass vacuously"

    for entry <- scores do
      recomputed = passed?(entry["dimension_scores"], entry["gate_results"])

      assert entry["passed"] == recomputed,
             "demo #{entry["demo_id"]}: recorded passed=#{inspect(entry["passed"])} " <>
               "but recomputation from its own dimension_scores/gate_results yields " <>
               "#{inspect(recomputed)} — the manifest's passed field must equal the " <>
               "passed?/2 arithmetic, never an independent assertion (SHOW-01 honesty gate)"
    end
  end

  test "every passed:true entry carries a live, hash-checked human sign-off (DEFAULT-02 honesty gate)" do
    # D-02 machine-enforced sign-off teeth: a `passed: true` verdict may never be recorded
    # without provenance. This is the load-bearing guard (schema if/then is the secondary
    # layer) — it must fail loud in BOTH directions: a passed:true without a live
    # hash-checked evidence_ref fails the build; a passed:false must never be blocked by
    # this loop (an honest failing finding, e.g. Ticket, must still pass the contract test).
    scores = manifest()["scores"]
    known_png_paths = gallery_png_paths()

    for entry <- scores do
      if entry["passed"] == true do
        signed_off_by = entry["signed_off_by"]
        signed_off_at = entry["signed_off_at"]
        evidence_ref = entry["evidence_ref"]

        assert is_binary(signed_off_by) and signed_off_by != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty signed_off_by"

        assert is_binary(signed_off_at) and signed_off_at != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty signed_off_at"

        assert is_binary(evidence_ref) and evidence_ref != "",
               "demo #{entry["demo_id"]}: passed:true requires a non-empty evidence_ref"

        assert File.exists?(evidence_ref),
               "demo #{entry["demo_id"]}: evidence_ref #{inspect(evidence_ref)} does not " <>
                 "exist on disk — a passed:true verdict must point at a real artifact"

        assert MapSet.member?(known_png_paths, evidence_ref),
               "demo #{entry["demo_id"]}: evidence_ref #{inspect(evidence_ref)} is not " <>
                 "present in the hash-checked #{@gallery_manifest_path} gallery — a " <>
                 "passed:true verdict must point at a manifest-covered, hash-verified " <>
                 "raster, not an untracked file"
      end
    end
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

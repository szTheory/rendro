defmodule Rendro.Quality.BaselineLedgerContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @moduletag :quality_ledger_contract

  @ledger_path ".planning/QUALITY.md"
  @schema_path ".planning/quality/schema/baseline-v1.schema.json"
  @snapshot_path ".planning/quality/baselines/132-initial.json"
  @required_domains MapSet.new([
                      "architecture",
                      "dependency",
                      "test",
                      "ci_cd",
                      "documentation",
                      "packaging",
                      "release_evidence",
                      "catalog"
                    ])

  defp valid_snapshot?(snapshot, schema) do
    evidence_items = snapshot["evidence_items"]
    signal_candidates = Enum.flat_map(evidence_items, & &1["signal_candidates"])

    match?({:ok, _}, JSV.validate(snapshot, schema)) and
      Enum.uniq_by(evidence_items, & &1["id"]) == evidence_items and
      Enum.uniq_by(signal_candidates, & &1["id"]) == signal_candidates
  end

  defp signal_candidates(snapshot) do
    snapshot["evidence_items"]
    |> Enum.flat_map(& &1["signal_candidates"])
  end

  defp signal_domains(snapshot) do
    snapshot
    |> signal_candidates()
    |> Enum.map(& &1["domain"])
    |> MapSet.new()
  end

  defp discovered_signal_ids(snapshot) do
    snapshot
    |> signal_candidates()
    |> Enum.map(& &1["id"])
    |> Enum.sort()
  end

  defp classified_signal_ids(ledger) do
    Regex.scan(~r/\*\*Signal:\*\* `(SIG-[A-Z]+-\d{3})`/, ledger, capture: :all_but_first)
    |> List.flatten()
  end

  defp record_blocks(ledger, "QL") do
    Regex.scan(
      ~r/^#### (QL-\d{3})[^\n]*\n(.*?)(?=^#### QL-\d{3}|^### NS-\d{3}|^## |\z)/ms,
      ledger,
      capture: :all_but_first
    )
  end

  defp record_blocks(ledger, "NS") do
    Regex.scan(~r/^### (NS-\d{3})[^\n]*\n(.*?)(?=^### NS-\d{3}|^## |\z)/ms, ledger,
      capture: :all_but_first
    )
  end

  defp field(block, label) do
    case Regex.run(~r/^- \*\*#{Regex.escape(label)}:\*\* (.+)$/m, block, capture: :all_but_first) do
      [value] -> value
      nil -> nil
    end
  end

  defp ids_in(value, prefix) do
    Regex.scan(~r/#{prefix}-[A-Z]+-\d{3}/, value || "") |> List.flatten()
  end

  test "one quality finding resolves through the ledger, snapshot, and schema" do
    assert File.exists?(@ledger_path)
    assert File.exists?(@schema_path)
    assert File.exists?(@snapshot_path)

    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    ledger = File.read!(@ledger_path)

    assert valid_snapshot?(snapshot, schema)
    assert snapshot["snapshot_id"] == "baseline-132-initial"
    assert Enum.any?(snapshot["evidence_items"], &(&1["id"] == "EV-ARCH-001"))
    assert ledger =~ "QL-001"
    assert ledger =~ "EV-ARCH-001"
    assert ledger =~ @snapshot_path
  end

  test "evidence and signal identities carry explicit provenance" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    [evidence | _] = snapshot["evidence_items"]
    [signal | _] = evidence["signal_candidates"]

    assert evidence["registered_command"]["invocation"] ==
             "mix xref graph --format stats --label compile-connected"

    assert evidence["provenance"]["source_sha"] == snapshot["source_sha"]
    assert signal["source_evidence_id"] == evidence["id"]
  end

  test "baseline captures every required domain with stable, non-vacuous signals" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    evidence_items = snapshot["evidence_items"]
    signals = signal_candidates(snapshot)

    assert length(evidence_items) >= MapSet.size(@required_domains)
    assert MapSet.subset?(@required_domains, signal_domains(snapshot))
    assert signals != []
    assert Enum.all?(signals, &String.match?(&1["id"], ~r/^SIG-[A-Z]+-\d{3}$/))

    assert Enum.all?(
             signals,
             &(&1["source_evidence_id"] in Enum.map(evidence_items, fn item -> item["id"] end))
           )

    Enum.each(evidence_items, fn evidence ->
      assert evidence["provenance"]["source_sha"] == snapshot["source_sha"]
      assert evidence["provenance"]["environment_id"] == snapshot["environment"]["id"]
      assert evidence["registered_command"]["invocation"] != ""
      assert evidence["raw_output"]["sha256"] =~ ~r/^[0-9a-f]{64}$/

      if evidence["status"] == "unavailable" do
        assert evidence["unavailability_reason"] != ""
        assert evidence["rerun_trigger"] != ""
      end
    end)
  end

  test "baseline contract rejects a capture with a required domain or all signals removed" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    without_catalog =
      Map.update!(snapshot, "evidence_items", fn items ->
        Enum.reject(items, fn item ->
          Enum.any?(item["signal_candidates"], &(&1["domain"] == "catalog"))
        end)
      end)

    without_signals =
      put_in(snapshot, ["evidence_items", Access.at(0), "signal_candidates"], [])

    assert valid_snapshot?(without_catalog, schema)
    refute MapSet.subset?(@required_domains, signal_domains(without_catalog))
    refute valid_snapshot?(without_signals, schema)
  end

  test "schema rejects malformed or duplicated evidence facts" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    [evidence | _] = snapshot["evidence_items"]

    for {path, value} <- [
          {["source_sha"], "not-a-sha"},
          {["evidence_items", Access.at(0), "id"], "EV-bad"},
          {["evidence_items", Access.at(0), "lane"], "primary_ci"},
          {["evidence_items", Access.at(0), "status"], "unknown"},
          {["evidence_items", Access.at(0), "raw_output", "sha256"], "bad"},
          {["evidence_items", Access.at(0), "signal_candidates", Access.at(0), "id"], "SIG-bad"}
        ] do
      mutated = put_in(snapshot, path, value)
      refute match?({:ok, _}, JSV.validate(mutated, schema)), "#{inspect(path)} must fail"
    end

    unavailable =
      put_in(snapshot, ["evidence_items"], [Map.put(evidence, "status", "unavailable")])

    refute match?({:ok, _}, JSV.validate(unavailable, schema))

    duplicate_evidence = Map.put(snapshot, "evidence_items", [evidence, evidence])
    refute valid_snapshot?(duplicate_evidence, schema)

    duplicate_signal =
      put_in(snapshot, ["evidence_items", Access.at(0), "signal_candidates"], [
        hd(evidence["signal_candidates"]),
        hd(evidence["signal_candidates"])
      ])

    refute valid_snapshot?(duplicate_signal, schema)
  end

  test "focused validation does not mutate the initial snapshot" do
    original = File.read!(@snapshot_path)

    assert valid_snapshot?(
             JSON.decode!(original),
             @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
           )

    assert File.read!(@snapshot_path) == original
  end

  test "ledger exposes durable lifecycle, rubric, and closure governance" do
    ledger = File.read!(@ledger_path)

    for heading <- [
          "## Finding lifecycle and relationships",
          "## Qualitative rubric and dispositions",
          "## Routing and closure",
          "## Resolved, rejected, deferred, and superseded findings"
        ] do
      assert ledger =~ heading
    end

    assert ledger =~ "observed -> triaged -> accepted -> in_progress -> verified -> closed"
    assert ledger =~ "`repair`, `defer`, `reject_signal`, `accept_risk`, and `superseded`"
    assert ledger =~ "evidence_authority"

    ids = Regex.scan(~r/^#### (QL-\d{3})/m, ledger, capture: :all_but_first) |> List.flatten()
    assert ids == Enum.sort(ids)
    assert ids == ["QL-001", "QL-002", "QL-003", "QL-004"]

    for label <- [
          "Opened:",
          "Evidence:",
          "Impact:",
          "Confidence:",
          "Compatibility risk:",
          "Evidence quality:",
          "Priority:",
          "Disposition:",
          "Owner phase:",
          "Verification:",
          "Status:",
          "Scope:",
          "Trigger:",
          "Closure:",
          "Relationships/history:"
        ] do
      assert ledger =~ label
    end

    refute ledger =~ ".planning/phases/"
    refute ledger =~ ".planning/milestones/"
  end

  test "every captured signal is classified exactly once in the durable ledger" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    ledger = File.read!(@ledger_path)
    discovered = discovered_signal_ids(snapshot)
    classified = classified_signal_ids(ledger)

    assert discovered != []
    assert classified != []
    assert Enum.sort(classified) == discovered
    assert Enum.uniq(classified) == classified

    omitted =
      String.replace(ledger, ~r/\n- \*\*Signal:\*\* `SIG-[A-Z]+-\d{3}`/, "", global: false)

    duplicated = ledger <> "\n- **Signal:** `SIG-ARCH-001`\n"

    refute Enum.sort(classified_signal_ids(omitted)) == discovered
    refute Enum.uniq(classified_signal_ids(duplicated)) == classified_signal_ids(duplicated)
  end

  test "findings resolve evidence and retain complete qualitative disposition facts" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    ledger = File.read!(@ledger_path)
    evidence_ids = snapshot["evidence_items"] |> Enum.map(& &1["id"]) |> MapSet.new()
    finding_blocks = Regex.scan(~r/^#### QL-\d{3}.*?(?=^#### |\z)/ms, ledger) |> List.flatten()

    assert finding_blocks != []

    for block <- finding_blocks do
      for label <- [
            "Opened:",
            "Evidence:",
            "Impact:",
            "Confidence:",
            "Compatibility risk:",
            "Evidence quality:",
            "Priority:",
            "Disposition:",
            "Owner phase:",
            "Verification:",
            "Status:",
            "Scope:",
            "Trigger:",
            "Closure:",
            "Relationships/history:"
          ] do
        assert block =~ label
      end

      for evidence_id <- Regex.scan(~r/EV-[A-Z]+-\d{3}/, block) |> List.flatten() do
        assert evidence_id in evidence_ids
      end
    end

    assert ledger =~ "Phase 137 adds a separate final snapshot and a before/after comparison"
    assert ledger =~ "None recorded"
  end

  test "bounded QL and NS records pin decision bases and record-local evidence" do
    ledger = File.read!(@ledger_path)

    expected = %{
      "QL-001" =>
        {"reject_signal", "diagnostic_signal_only", ["EV-ARCH-001", "EV-ARCH-002"],
         ["SIG-ARCH-001", "SIG-ARCH-002"]},
      "QL-002" => {"repair", "supported_contract_risk", ["EV-CI-001"], ["SIG-CI-001"]},
      "QL-003" => {"repair", "bounded_maintenance_cost", ["EV-CI-002"], ["SIG-CI-002"]},
      "QL-004" => {"repair", "supported_contract_risk", ["EV-CATALOG-001"], ["SIG-CATALOG-001"]},
      "NS-001" => {"reject_signal", "diagnostic_signal_only", ["EV-DEP-001"], ["SIG-DEP-001"]},
      "NS-002" => {"reject_signal", "diagnostic_signal_only", ["EV-TEST-001"], ["SIG-TEST-001"]},
      "NS-003" => {"reject_signal", "diagnostic_signal_only", ["EV-CI-002"], ["SIG-CI-003"]},
      "NS-004" => {"reject_signal", "diagnostic_signal_only", ["EV-DOC-001"], ["SIG-DOC-001"]},
      "NS-005" => {"reject_signal", "diagnostic_signal_only", ["EV-PKG-001"], ["SIG-PKG-001"]},
      "NS-006" => {"defer", "explicit_unavailability", ["EV-REL-001"], ["SIG-REL-001"]},
      "NS-007" => {"defer", "explicit_unavailability", ["EV-ADV-001"], ["SIG-CATALOG-002"]}
    }

    records = record_blocks(ledger, "QL") ++ record_blocks(ledger, "NS")

    assert Enum.map(records, &hd/1) == [
             "QL-001",
             "QL-002",
             "QL-003",
             "QL-004",
             "NS-001",
             "NS-002",
             "NS-003",
             "NS-004",
             "NS-005",
             "NS-006",
             "NS-007"
           ]

    for [id, block] <- records do
      {disposition, basis, evidence_ids, signal_ids} = Map.fetch!(expected, id)
      assert field(block, "Disposition") == disposition
      assert field(block, "Decision basis") == basis
      assert ids_in(field(block, "Evidence"), "EV") == evidence_ids
      assert ids_in(block, "SIG") == signal_ids
    end

    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()

    signal_sources =
      snapshot
      |> signal_candidates()
      |> Map.new(fn signal -> {signal["id"], signal["source_evidence_id"]} end)

    for [id, _block] <- records do
      {_disposition, _basis, evidence_ids, signal_ids} = Map.fetch!(expected, id)
      assert Enum.all?(signal_ids, &(signal_sources[&1] in evidence_ids))
    end
  end

  test "bounded record parsing rejects malformed boundaries and non-local evidence mutations" do
    ledger = File.read!(@ledger_path)
    ql_ids = record_blocks(ledger, "QL") |> Enum.map(&hd/1)
    ns_ids = record_blocks(ledger, "NS") |> Enum.map(&hd/1)

    duplicate = ledger <> "\n#### QL-001 — duplicate identity\n\n- **Evidence:** `EV-ARCH-001`\n"
    assert Enum.count(record_blocks(duplicate, "QL"), &(hd(&1) == "QL-001")) == 2

    misplaced =
      String.replace(
        ledger,
        "- **Signal:** `SIG-ARCH-002`",
        "- **Signal:** `SIG-ARCH-002`\n- **Signal:** `SIG-CI-001`",
        global: false
      )

    [[_id, misplaced_ql] | _] = record_blocks(misplaced, "QL")
    refute ids_in(misplaced_ql, "SIG") == ["SIG-ARCH-001", "SIG-ARCH-002"]

    empty_evidence =
      String.replace(
        ledger,
        "- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`",
        "- **Evidence:**",
        global: false
      )

    [[_id, empty_ql] | _] = record_blocks(empty_evidence, "QL")
    assert ids_in(field(empty_ql, "Evidence"), "EV") == []

    unknown_evidence = String.replace(ledger, "`EV-ARCH-001`", "`EV-UNKNOWN-999`", global: false)
    [[_id, unknown_ql] | _] = record_blocks(unknown_evidence, "QL")
    assert ids_in(field(unknown_ql, "Evidence"), "EV") == ["EV-UNKNOWN-999", "EV-ARCH-002"]

    globally_resolvable_but_non_local =
      String.replace(ledger, "- **Evidence:** `EV-CI-001`", "- **Evidence:** `EV-ARCH-001`",
        global: false
      )

    [_, [_id, ql_two] | _] = record_blocks(globally_resolvable_but_non_local, "QL")
    assert ids_in(field(ql_two, "Evidence"), "EV") == ["EV-ARCH-001"]

    assert ql_ids == ["QL-001", "QL-002", "QL-003", "QL-004"]
    assert ns_ids == ["NS-001", "NS-002", "NS-003", "NS-004", "NS-005", "NS-006", "NS-007"]
  end
end

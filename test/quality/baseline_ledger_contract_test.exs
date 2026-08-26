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

    ids = Regex.scan(~r/QL-\d{3}/, ledger) |> List.flatten() |> Enum.uniq()
    assert ids == Enum.sort(ids)
    assert ids == ["QL-001"]

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
end

defmodule Rendro.Quality.BaselineLedgerContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @moduletag :quality_ledger_contract

  @ledger_path ".planning/QUALITY.md"
  @schema_path ".planning/quality/schema/baseline-v1.schema.json"
  @snapshot_path ".planning/quality/baselines/132-initial.json"

  test "one quality finding resolves through the ledger, snapshot, and schema" do
    assert File.exists?(@ledger_path)
    assert File.exists?(@schema_path)
    assert File.exists?(@snapshot_path)

    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    ledger = File.read!(@ledger_path)

    assert {:ok, _} = JSV.validate(snapshot, schema)
    assert snapshot["snapshot_id"] == "baseline-132-initial"
    assert Enum.any?(snapshot["evidence_items"], &(&1["id"] == "EV-ARCH-001"))
    assert ledger =~ "QL-001"
    assert ledger =~ "EV-ARCH-001"
    assert ledger =~ @snapshot_path
  end

  test "evidence and signal identities carry explicit provenance" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    [evidence] = snapshot["evidence_items"]
    [signal] = evidence["signal_candidates"]

    assert evidence["registered_command"]["invocation"] ==
             "mix xref graph --format stats --label compile-connected"

    assert evidence["provenance"]["source_sha"] == snapshot["source_sha"]
    assert signal["source_evidence_id"] == evidence["id"]
  end

  test "schema rejects malformed or duplicated evidence facts" do
    snapshot = @snapshot_path |> File.read!() |> JSON.decode!()
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    [evidence] = snapshot["evidence_items"]

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

    assert Enum.uniq_by(snapshot["evidence_items"], & &1["id"]) == snapshot["evidence_items"]

    signals = Enum.flat_map(snapshot["evidence_items"], & &1["signal_candidates"])
    assert Enum.uniq_by(signals, & &1["id"]) == signals
  end

  test "focused validation does not mutate the initial snapshot" do
    original = File.read!(@snapshot_path)

    assert {:ok, _} =
             JSV.validate(
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

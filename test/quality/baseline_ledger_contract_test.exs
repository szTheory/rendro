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
end

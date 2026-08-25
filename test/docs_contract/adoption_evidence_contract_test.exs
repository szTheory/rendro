Code.require_file(Path.expand("../../scripts/adoption_snapshot.exs", __DIR__))

defmodule Rendro.DocsContract.AdoptionEvidenceContractTest do
  use ExUnit.Case, async: true

  test "AVAILABLE Hex metadata retains exact totals and threshold classification" do
    assert {:ok, family} =
             Rendro.AdoptionSnapshot.hex_family(
               %{
                 "downloads" => %{"all" => 3_149, "week" => 182}
               },
               "2026-08-21T12:00:00Z"
             )

    assert family.retrieval == "AVAILABLE"
    assert family.decision == "ACCUMULATING"
    assert family.raw == %{all: 3_149, week: 182}
    assert family.query == "https://hex.pm/api/packages/rendro"
  end

  test "UNAVAILABLE input has no raw totals and cannot trigger" do
    family = Rendro.AdoptionSnapshot.unavailable_family("downloads", "network failure")

    assert family.retrieval == "UNAVAILABLE"
    assert family.decision == "HOLD"
    refute Map.has_key?(family, :raw)
    refute Rendro.AdoptionSnapshot.triggerable?(family)
  end

  test "empty available candidates are HOLD while nil or malformed candidates fail closed" do
    assert {:ok, family} =
             Rendro.AdoptionSnapshot.candidate_family("demand", [], "2026-08-21T12:00:00Z")

    assert family.candidate_count == 0
    assert family.decision == "HOLD"

    assert {:error, _} =
             Rendro.AdoptionSnapshot.candidate_family("demand", nil, "2026-08-21T12:00:00Z")

    assert {:error, _} =
             Rendro.AdoptionSnapshot.candidate_family(
               "demand",
               [%{"number" => nil}],
               "2026-08-21T12:00:00Z"
             )
  end

  test "canonical UTF-8 digests ignore map ordering" do
    left = %{"b" => [2, 1], "a" => %{"z" => true, "y" => "\u00e9"}}
    right = %{"a" => %{"y" => "\u00e9", "z" => true}, "b" => [2, 1]}

    assert Rendro.AdoptionSnapshot.digest(left) == Rendro.AdoptionSnapshot.digest(right)
    assert Rendro.AdoptionSnapshot.digest(left) =~ ~r/^[0-9a-f]{64}$/
  end

  test "exclusive writer leaves no partial target or temp file after interruption" do
    path =
      Path.join(System.tmp_dir!(), "rendro-adoption-#{System.unique_integer([:positive])}.json")

    payload = %{"schema_version" => 1, "review_date" => "2026-08-21"}

    assert :ok = Rendro.AdoptionSnapshot.write_snapshot(path, payload)
    assert {:error, :target_exists} = Rendro.AdoptionSnapshot.write_snapshot(path, payload)
    assert {:ok, ^payload} = path |> File.read!() |> Jason.decode()
    assert [] == Path.wildcard(path <> ".tmp-*")
  end

  test "parallel writers produce one complete authoritative target" do
    directory =
      Path.join(
        System.tmp_dir!(),
        "rendro-adoption-parallel-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(directory) end)
    assert :ok = File.mkdir_p(directory)

    path = Path.join(directory, "2026-08-21.json")
    payload = %{"schema_version" => 1, "review_date" => "2026-08-21"}
    parent = self()

    tasks =
      for _ <- 1..4 do
        Task.async(fn ->
          send(parent, {:writer_ready, self()})

          receive do
            :write_snapshot -> Rendro.AdoptionSnapshot.write_snapshot(path, payload)
          end
        end)
      end

    writers =
      for _ <- tasks do
        assert_receive {:writer_ready, writer}, 5_000
        writer
      end

    Enum.each(writers, &send(&1, :write_snapshot))
    results = Enum.map(tasks, &Task.await(&1, 5_000))

    assert Enum.count(results, &(&1 == :ok)) == 1
    assert Enum.all?(results, &(&1 in [:ok, {:error, :target_exists}]))
    assert {:ok, ^payload} = path |> File.read!() |> Jason.decode()
    assert [] == Path.wildcard(path <> ".tmp-*")
  end

  test "dated sidecar is bounded, conjunctive, and bound to the public index" do
    path = "priv/adoption_evidence/2026-08-21.json"
    adoption = File.read!("ADOPTION.md")
    snapshot = path |> File.read!() |> Jason.decode!()

    assert snapshot["review_date"] == "2026-08-21"
    assert snapshot["composite"] == %{"decision" => "HOLD", "rule" => "minimum family decision"}
    assert adoption =~ "priv/adoption_evidence/2026-08-21.json"

    for family <- ["downloads", "demand", "contributor"] do
      record = snapshot["families"][family]
      assert record["retrieval"] in ["AVAILABLE", "UNAVAILABLE"]
      assert record["decision"] in ["HOLD", "ACCUMULATING", "TRIGGER"]
      assert is_binary(record["source"])
      assert is_binary(record["query"])
      assert is_integer(record["pagination_limit"])
      assert is_binary(record["result_digest"]) or is_binary(record["failure_reason"])

      if record["retrieval"] == "UNAVAILABLE" do
        assert record["decision"] == "HOLD"
        refute Map.has_key?(record, "raw")
      end
    end

    assert snapshot["families"]["downloads"]["raw"] == %{"all" => 3_149, "week" => 182}
    assert snapshot["families"]["demand"]["candidate_count"] == 0
    assert snapshot["families"]["contributor"]["candidate_count"] == 0
    refute File.read!(path) =~ ~r/"body"|authorization|HEX_API_KEY|HOME|\/Users\//
  end

  test "adoption ledger uses truthful contributor empty states without debt markers" do
    adoption = File.read!("ADOPTION.md")

    assert adoption =~ "| No alternate accounts are currently recorded |"
    assert adoption =~ "| No rejected candidates were recorded for the 2026-08-21 review |"
    refute adoption =~ ~r/\bTBD\b/
  end

  test "package allowlist ships the evidence linked from ADOPTION.md" do
    assert File.read!("mix.exs") =~ "priv/adoption_evidence"
  end
end

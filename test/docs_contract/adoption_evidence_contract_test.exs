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
    path =
      Path.join(
        System.tmp_dir!(),
        "rendro-adoption-parallel-#{System.unique_integer([:positive])}.json"
      )

    payload = %{"schema_version" => 1, "review_date" => "2026-08-21"}

    results =
      1..4
      |> Task.async_stream(fn _ -> Rendro.AdoptionSnapshot.write_snapshot(path, payload) end,
        ordered: false,
        timeout: 5_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &(&1 == :ok)) == 1
    assert Enum.all?(results, &(&1 in [:ok, {:error, :target_exists}]))
    assert {:ok, ^payload} = path |> File.read!() |> Jason.decode()
  end
end

defmodule Mix.Tasks.VerifyTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify

  test "run_with_lanes executes advisory steps even after deterministic failure" do
    lanes = [
      {"DETERMINISTIC (CORE)", [{"CI", fn -> {:error, 2, "ci failed"} end}]},
      {"ADVISORY (ADAPTERS)", [{"Phoenix Example", fn -> :ok end}]}
    ]

    assert {:error, results} = Verify.run_with_lanes(lanes)
    assert Enum.map(results, & &1.lane) == ["DETERMINISTIC (CORE)", "ADVISORY (ADAPTERS)"]
    assert Enum.map(results, & &1.step) == ["CI", "Phoenix Example"]
    assert Enum.map(results, & &1.status) == [:fail, :pass]
  end
end

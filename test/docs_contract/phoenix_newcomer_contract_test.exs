defmodule Rendro.DocsContract.PhoenixNewcomerContractTest do
  use ExUnit.Case, async: true

  test "README owns the ordered public Phoenix newcomer route without copying the formatter snippet" do
    readme = File.read!("README.md")

    for label <- ["Install", "Select", "Customize", "Serve", "Verify"] do
      assert readme =~ "### #{label}"
    end

    assert ordered?(readme, [
             "### Install",
             "### Select",
             "### Customize",
             "### Serve",
             "### Verify"
           ])

    assert readme =~ "{:rendro, \"~> 1.3\"}"
    assert readme =~ "https://hexdocs.pm/rendro"
    assert readme =~ "guides/presets.md"
    assert readme =~ "assets/rendro/configurator/index.html"
    assert readme =~ "examples/phoenix_example/README.md"
    assert readme =~ "Invoice / Swiss / `#2C6BED` / light"
    assert readme =~ "formatter-owned"
    assert readme =~ "broader runnable reference, not clean-room authority"
    refute readme =~ "Rendro.Theme.preset(:swiss"
  end

  test "clean-room evidence preserves all failed attempts and retains no sensitive run state" do
    assert {:ok, index} = Rendro.RepositoryEvidence.load_role(:journey_index)

    assert index["release"]["version"] == "1.3.4"
    assert length(index["entries"]) == 9
    assert List.first(index["entries"]) == "RE-V134-JOURNEY-001"
    assert List.last(index["entries"]) == "RE-V134-JOURNEY-009"
    assert index["lane"] == "advisory"
  end

  test "retained clean-room result proves the exact public PDF journey with dual HTTP facts" do
    assert {:ok, evidence} = Rendro.RepositoryEvidence.load_public_prerequisite()

    assert evidence["version"] == "1.3.4"
    assert evidence["candidate_commit_sha"] == "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
    assert evidence["public_prerequisite"] == "VERIFIED"
    assert evidence["hexdocs_provenance"] == "hexdocs_workflow_dispatch"
    assert evidence["release_conclusion"] == "success"
  end

  test "published validation evidence identities are retained in the capsule" do
    assert {:ok, validation} = Rendro.RepositoryEvidence.load_role(:validation)

    assert validation["candidate_commit_sha"] == "f03c78bab54efe1cd1596d51cf3f28193232e2a3"

    assert Enum.map(validation["successful_journeys"], & &1["id"]) == [
             "phase-131-focused-suite",
             "phase-131-full-deterministic-lane"
           ]
  end

  defp ordered?(text, values) do
    values
    |> Enum.map(&:binary.match(text, &1))
    |> Enum.reduce_while(-1, fn
      {index, _length}, previous when index > previous -> {:cont, index}
      _, _previous -> {:halt, :error}
    end)
    |> Kernel.!=(:error)
  end
end

defmodule Mix.Tasks.CiAliasContractTest do
  use ExUnit.Case, async: true

  test "ci aliases match the required split-gate contract" do
    project = Rendro.MixProject.project()
    aliases = Keyword.fetch!(project, :aliases)
    ci_steps = Keyword.fetch!(aliases, :ci)
    ci_fast_steps = Keyword.fetch!(aliases, :"ci.fast")

    assert ci_steps == ["ci.fast", "ci.proofs"]

    assert ci_fast_steps == [
             "format --check-formatted",
             "hex.build",
             "compile --warnings-as-errors",
             "test --exclude quarantine --slowest 10",
             "docs --warnings-as-errors",
             "credo --strict",
             "dialyzer"
           ]
  end

  test "scoped ci aliases run in MIX_ENV=test for local parity" do
    preferred_envs = Keyword.fetch!(Rendro.MixProject.cli(), :preferred_envs)

    assert Keyword.fetch!(preferred_envs, :ci) == :test
    assert Keyword.fetch!(preferred_envs, :"ci.fast") == :test
    assert Keyword.fetch!(preferred_envs, :"ci.proofs") == :test
    assert Keyword.fetch!(preferred_envs, :"ci.advisory") == :test
    assert Keyword.fetch!(preferred_envs, :"verify.flake") == :test
    assert Keyword.fetch!(preferred_envs, :"test.all") == :test
  end

  test "ex_doc is available in test so mix ci can run docs in MIX_ENV=test" do
    deps = Keyword.fetch!(Rendro.MixProject.project(), :deps)

    assert {:ex_doc, _requirement, options} =
             Enum.find(deps, fn
               {:ex_doc, _, _} -> true
               _ -> false
             end)

    assert Keyword.fetch!(options, :only) == [:dev, :test]
    assert Keyword.fetch!(options, :runtime) == false
  end
end

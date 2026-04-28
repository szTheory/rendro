defmodule Mix.Tasks.CiAliasContractTest do
  use ExUnit.Case, async: true

  test "ci alias matches the documented QUAL-01 contract" do
    project = Rendro.MixProject.project()
    aliases = Keyword.fetch!(project, :aliases)
    ci_steps = Keyword.fetch!(aliases, :ci)

    assert ci_steps == [
             "format --check-formatted",
             "compile --warnings-as-errors",
             "test",
             "docs",
             "hex.build",
             "credo --strict",
             "dialyzer"
           ]
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

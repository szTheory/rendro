defmodule Rendro.DocsContract.DxLocalReproducibilityClaimsTest do
  use ExUnit.Case, async: true

  test "docs verification script includes exactly one DX local reproducibility claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"DX local reproducibility claims lane"/, script)) == 1

    assert script =~
             ~r/\{"DX local reproducibility claims lane",\s*\["test",\s*"test\/docs_contract\/dx_local_reproducibility_claims_test\.exs"\]\}/s
  end

  test "scoped CI aliases and split workflow steps stay wired to the required gate" do
    aliases = Keyword.fetch!(Rendro.MixProject.project(), :aliases)
    preferred_envs = Keyword.fetch!(Rendro.MixProject.cli(), :preferred_envs)
    workflow = File.read!(".github/workflows/ci.yml")

    assert Keyword.fetch!(aliases, :ci) == ["ci.fast", "ci.proofs"]

    assert Keyword.fetch!(aliases, :"ci.fast") == [
             "format --check-formatted",
             "hex.build",
             "compile --warnings-as-errors",
             "test --exclude quarantine --slowest 10",
             "docs --warnings-as-errors",
             "credo --strict",
             "dialyzer"
           ]

    assert Keyword.fetch!(preferred_envs, :ci) == :test
    assert Keyword.fetch!(preferred_envs, :"ci.fast") == :test
    assert Keyword.fetch!(preferred_envs, :"ci.proofs") == :test
    assert Keyword.fetch!(preferred_envs, :"ci.advisory") == :test

    for step <- ["Format", "Hex Build", "Compile", "Test", "Docs", "Credo", "Dialyzer"] do
      assert workflow =~ "name: #{step}"
    end

    assert workflow =~ "tee /tmp/mix-test-output.log"
    assert workflow =~ "grep -A 25 'Top [0-9]* slowest' /tmp/mix-test-output.log"
    assert workflow =~ "ci-success:"
    assert workflow =~ "needs: [test, configurator-browser, integration-proofs, quality-governance]"
    assert workflow =~ "configurator-browser:"

    assert workflow =~
             "mcr.microsoft.com/playwright:v1.62.0-noble@sha256:baed2032d533817f3dbe6425de795788430ba345e819a1201337009ba17c9d07"

    assert workflow =~ "node-version: '22.14.0'"
    assert workflow =~ "retention-days: 14"
  end

  test "public contributor docs point to ci-success and scoped local reproduction commands" do
    readme = File.read!("README.md")
    contributing = File.read!("CONTRIBUTING.md")

    assert readme =~ "name=ci-success"

    for command <- [
          "mix ci",
          "mix ci.fast",
          "mix ci.proofs",
          "mix ci.advisory",
          "mix verify.flake",
          "mix test --seed"
        ] do
      assert contributing =~ command
    end

    assert contributing =~ "Full required merge gate"
    assert contributing =~ "deterministic local command for the required fast merge gate"
    assert contributing =~ "only when the local machine has the same proof tools"

    assert contributing =~
             "GitHub Actions is the authoritative environment for `integration-proofs`"

    assert contributing =~ "Optional advisory lane"
    assert contributing =~ "Quarantined flaky-test lane"
  end

  # The 2 test cases previously here ("validation reports keep local and remote
  # evidence boundaries truthful" and "Phase 113 UAT is completed from automated
  # evidence with no human prompt remaining") asserted only frozen, archive-specific
  # historical facts (GitHub Actions run IDs, a specific p50/p95 timing pair, a
  # specific UAT pass count) from the Phase-113/C1-milestone evidence trail, deleted
  # by milestone-cleanup commit 0de2de8. Neither had forward-looking regression
  # value -- see 124-RESEARCH.md Target 1 for the full rationale.
end

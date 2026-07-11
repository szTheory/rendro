defmodule Rendro.DocsContract.DxLocalReproducibilityClaimsTest do
  use ExUnit.Case, async: true

  @uat_path ".planning/phases/113-dx-local-reproducibility-validation/113-UAT.md"
  @metrics_path ".planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md"
  @audit_path ".planning/milestones/C1-AUDIT.md"

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
    assert workflow =~ "needs: [test, integration-proofs]"
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

  test "validation reports keep local and remote evidence boundaries truthful" do
    metrics = File.read!(@metrics_path)
    audit = File.read!(@audit_path)

    assert metrics =~ "mix ci.fast"
    assert metrics =~ "ci.fast_exit=0"
    assert metrics =~ "1219 tests, 12 doctests, 4 properties, 0 failures"
    assert metrics =~ "29133061301"
    assert metrics =~ "29133777702"
    assert metrics =~ "29134266708"
    assert metrics =~ "p50 783s"
    assert metrics =~ "nearest-rank p95 1013s"
    assert metrics =~ "deps exact hit 3/3"
    assert metrics =~ "`_build` restored 3/3"
    assert metrics =~ "PLT exact hit 3/3"
    assert metrics =~ "intentionally advisory/non-required"

    assert audit =~ "## Phase 113 Validation Summary"
    assert audit =~ "The final local validation gate is green"
    assert audit =~ "Remote GitHub timing improvement is now claimed"
    assert audit =~ "three green `ci.yml` runs"
    assert audit =~ "p50 783s"
    assert audit =~ "nearest-rank p95 1013s"
    assert audit =~ "advisory `security-audit` job remains non-required signal"
  end

  test "Phase 113 UAT is completed from automated evidence with no human prompt remaining" do
    uat = File.read!(@uat_path)

    assert uat =~ "status: complete"
    assert uat =~ "[testing complete]"
    assert uat =~ "verifier: automated"
    assert uat =~ "passed: 5"
    assert uat =~ "issues: 0"
    assert uat =~ "pending: 0"
    assert uat =~ "Gaps\n\nNone."
    assert length(Regex.scan(~r/^result: pass$/m, uat)) == 5

    refute uat =~ "result: [pending]"
    refute uat =~ "awaiting: user response"
    refute uat =~ "Type `pass`"
  end
end

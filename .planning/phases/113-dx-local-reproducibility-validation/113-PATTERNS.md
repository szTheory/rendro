# Phase 113: DX, Local Reproducibility & Validation - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `README.md` | doc | static | `README.md` | exact |
| `CONTRIBUTING.md` | doc | static | `ADOPTION.md` | role-match |
| `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md` | doc | static | `.planning/milestones/C1-AUDIT.md` | role-match |
| `.planning/milestones/C1-AUDIT.md` | doc | static | `.planning/milestones/C1-AUDIT.md` | exact |
| `test/guardrails/required_checks_contract_test.exs` | test | batch | `test/guardrails/required_checks_contract_test.exs` | exact |

## Pattern Assignments

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Alias definition pattern** (lines 68-79):
```elixir
  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "hex.build",
        "compile --warnings-as-errors",
        "test --exclude quarantine --slowest 10",
        "docs --warnings-as-errors",
        "credo --strict",
        "dialyzer"
      ],
      "verify.flake": ["test --include quarantine --only quarantine --slowest 10"],
      "test.all": ["test --include quarantine --include live_pdf_tools --include live_signing --include raster_snapshot --slowest 10"]
    ]
  end
```

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Step execution and log teeing pattern** (lines 81-86):
```yaml
      - name: Run CI
        if: matrix.primary == true
        shell: bash
        # `shell: bash` runs `bash --noprofile --norc -eo pipefail {0}`, so pipefail
        # is on by default — `mix ci`'s exit code propagates through `tee` (gate-neutral).
        # Single-line `run:` keeps the literal `run: mix ci` lane that the
        # required-checks guardrail (test/guardrails/required_checks_contract_test.exs) asserts.
        run: mix ci 2>&1 | tee /tmp/mix-ci-output.log
```

**Step summary aggregation pattern** (lines 98-111):
```yaml
      - name: CI Baseline Summary
        if: always()
        continue-on-error: true
        shell: bash
        # Pass setup-beam outputs via env (values, not inlined script text) to avoid
        # ${{ }} template-expression injection into the shell (WR-01 / GitHub hardening guide).
        env:
          OTP_VERSION: ${{ steps.setup-beam.outputs.otp-version }}
          ELIXIR_VERSION: ${{ steps.setup-beam.outputs.elixir-version }}
        run: |
          {
            echo "## CI Baseline"
            echo ""
            echo "| Property | Value |"
            echo "|----------|-------|"
            echo "| OTP | ${OTP_VERSION:-n/a} |"
          } >> "$GITHUB_STEP_SUMMARY"
```

**Problem matchers auto-registration pattern** (RESEARCH.md insight):
Use `erlef/setup-beam` which automatically registers problem matchers for Elixir standard tools (`credo`, `dialyzer`, `elixirc`, `ex_unit`).

---

### `README.md` (doc, static)

**Analog:** `README.md`

**Status badge pattern** (lines 3-5):
```markdown
[![CI](https://github.com/szTheory/rendro/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/rendro/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/rendro.svg)](https://hex.pm/packages/rendro)
[![HexDocs](https://img.shields.io/badge/hex--docs-2C6BED.svg)](https://hexdocs.pm/rendro)
```
*(To be replaced with Shields.io check-runs API endpoint for `ci-success`)*

---

### `CONTRIBUTING.md` (doc, static)

**Analog:** `ADOPTION.md`

**Document structure pattern** (lines 1-7):
```markdown
# Adoption Signals

## Purpose

This ledger records public, reviewable signals for Rendro's conditional global text shaping gate. It is intentionally low-maintenance: Rendro is quietly public, and signals are reviewed when people find the project and open concrete issues.
```
*(Apply the same clear heading and explanatory purpose structure for contributing and local reproduction).*

---

### `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md` (doc, static)

**Analog:** `.planning/milestones/C1-AUDIT.md`

**Metrics documentation pattern** (lines 28-36):
```markdown
### ci.yml — Trigger: `push`, `pull_request`

| Job | Runner | Command | Avg Duration | p95 Duration | Required-for-merge | Cache (deps) | Cache (_build) | Quality Signal | Likely Bottleneck | Notes |
|-----|--------|---------|-------------|-------------|-------------------|--------------|----------------|----------------|-------------------|-------|
| `test` | ubuntu-latest | `mix ci` (format → hex.build → compile → test → docs → credo → dialyzer) | ~345s job total; `mix ci` inner step avg 327s (local proxy — 18 schedulers; not runner-absolute) | insufficient green-run data (n=3) | Yes | none — `mix deps.get` runs cold every job | none — full recompile every run | Gate: format, compile warnings-as-errors, full test suite, docs, credo, dialyzer | Full cold recompile + zero deps caching; entire `mix ci` chain opaque in single step |
```

---

### `test/guardrails/required_checks_contract_test.exs` (test, batch)

**Analog:** `test/guardrails/required_checks_contract_test.exs`

**Alias structural validation pattern** (lines 139-152):
```elixir
  describe "mix ci alias structural validation" do
    test "ci alias includes structural validation steps folded into test context" do
      project = Rendro.MixProject.project()
      aliases = Keyword.fetch!(project, :aliases)
      ci_steps = Keyword.fetch!(aliases, :ci)

      assert ci_steps == [
               "format --check-formatted",
               "hex.build",
               "compile --warnings-as-errors",
               "test --exclude quarantine --slowest 10",
               "docs --warnings-as-errors",
               "credo --strict",
               "dialyzer"
             ]
    end
  end
```

**Workflow pipeline structural validation pattern** (lines 156-163):
```elixir
  describe "required/advisory CI separation" do
    test "required test job runs only the deterministic mix ci lane" do
      ci = File.read!(@ci_path)
      test_block = ci_job_block!(ci, "test")

      assert test_block =~ "run: mix ci"
```
*(These guardrails MUST be updated to reflect the new `ci.fast`/`ci.proofs` alias structure and the decomposed `run` steps).*

## Shared Patterns

### Error Handling & Actionability
**Source:** `RESEARCH.md`
**Apply to:** GitHub Actions Pipeline
Split steps (e.g., `mix format`, `mix compile`, `mix test`) explicitly in `ci.yml` rather than hiding them inside `mix ci`, so that GitHub Groups logs correctly and the setup-beam matchers can annotate inline. Ensure guardrail tests are updated in lockstep.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | | | All files have exact or role-based analogs. |

## Metadata

**Analog search scope:** `**/*`
**Files scanned:** 7
**Pattern extraction date:** 2026-06-16
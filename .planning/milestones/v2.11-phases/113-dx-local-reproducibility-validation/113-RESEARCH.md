<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Decompose `mix ci` into scoped aliases.** Introduce `mix ci.fast` (format, compile, credo, fast tests), `mix ci.proofs` (integration and live proofs), and `mix ci.advisory` (advisory checks).
- **D-02:** **The root `mix ci` alias runs `ci.fast` followed by `ci.proofs`.** It should represent the *required* merge gate, omitting advisory checks.
- **D-03:** **Utilize both GitHub Problem Matchers AND Step Summaries.** 
- **D-04:** Use Problem Matchers for warnings (e.g., compiler warnings, Credo, Dialyzer) so they appear inline on the PR diff.
- **D-05:** Use Step Summaries (`$GITHUB_STEP_SUMMARY`) to consolidate test timings, cache hits, and overall pipeline health.
- **D-06:** **The README status badge MUST target the `ci-success` job, not the overall workflow.**
- **D-07:** **Record final before/after metrics in `113-METRICS.md` and append a summary to `C1-AUDIT.md`.**

### the agent's Discretion
- The user delegated deep-dive architectural decisions entirely to Claude. All decisions above reflect a cohesive, one-shot "perfect" recommendation optimized for developer ergonomics, CI efficiency, and Elixir ecosystem best practices, directly leveraging the Rendro OSS DNA and brand constraints.

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | `mix ci` reproduces the CI merge gate locally with 1:1 parity; any divergence is eliminated or explicitly documented. | Mapped to `mix ci.fast` and `mix ci.proofs` architecture. |
| DX-02 | CONTRIBUTING documents the required checks, how to run them locally, and how to reproduce a flaky failure (seed). | Identified need to create `CONTRIBUTING.md` detailing the aliases. |
| DX-03 | CI failures are actionable — grouped logs, GitHub annotations for warnings, clear job names, and service/container failures distinguishable from test failures. | Handled via `ci.yml` step splitting and native `setup-beam` matchers. |
| DX-04 | README status badge reflects the meaningful required check(s). | Solved via Shields.io Check-Runs API (`?name=ci-success`). |
| VAL-01 | Before/after metrics are recorded vs Phase 108 baseline. | Need to execute pipeline and measure vs `C1-AUDIT.md` metrics. |
| VAL-02 | A final integrated target-pipeline description documents the steady-state design. | Output artifact `113-METRICS.md` and pipeline summary. |
</phase_requirements>

# Phase 113: DX, Local Reproducibility & Validation - Research

**Researched:** 2026-06-16
**Domain:** CI/CD Developer Experience & Pipeline Validation
**Confidence:** HIGH

## Summary

This phase finalizes the CI/CD pipeline by ensuring local reproducibility, actionable failures, and accurate badging, followed by proving the improvements against the Phase 108 baseline. The core change is decomposing the monolithic `mix ci` command into distinct steps in GitHub Actions while maintaining a unified `mix ci` alias for local ergonomics. This creates a tension between DRY (Don't Repeat Yourself) and UX: GitHub Actions needs separated steps for step-level timing and log grouping, but developers need a single command. We resolve this by declaring the GitHub Actions `run` steps and `mix.exs` aliases in parallel and strictly enforcing their alignment via the `required_checks_contract_test.exs` guardrail.

**Primary recommendation:** Split the `test` job's `Run CI` monolith into individual named steps (Format, Compile, Credo, Test, Dialyzer) to get grouped logs and UI step timings, while updating `mix ci` to run `ci.fast` + `ci.proofs` for 1:1 local reproduction. Use Shields.io for the `ci-success` badge.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Local PR Validation | `mix.exs` aliases | `mix ci` command | Developers use pure Mix to reproduce the exact merge gate (`ci.fast` + `ci.proofs`). |
| Inline PR Annotations | `erlef/setup-beam` | GitHub Matchers | `setup-beam` automatically registers matchers for `elixirc`, `ex_unit`, `dialyzer`, and `credo`. |
| Step Timings & Grouping | `ci.yml` Steps | — | Splitting the CI execution into distinct GitHub steps is the only way to get step-level timings and folded logs in the GitHub UI. |
| Pipeline Status Badge | Shields.io API | `README.md` | GitHub's native badges cannot target a specific job (`ci-success`); Shields.io `check-runs` endpoint bridges this gap. |
| Configuration Enforcement | ExUnit Guardrails | `test/guardrails/` | Prevents the CI pipeline and local `mix ci` alias from drifting apart. |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Shields.io | API | Job-specific Badging | GitHub native badges only support full workflows. `ci.yml` has `continue-on-error` jobs, making the native badge yellow. Shields solves this. |
| `erlef/setup-beam` | v1 (Pinned) | Problem Matchers | Automatically registers problem matchers for Elixir standard tools, satisfying DX-03 inline annotations without custom scripts. |

## Architecture Patterns

### The "Split-Step + Local Alias" Pattern
**What:** The CI workflow defines individual `run` steps (Format, Compile, Test, Lint) rather than executing a single `mix ci` alias. Concurrently, `mix.exs` defines a `mix ci` alias that runs the exact same commands serially.
**When to use:** When you need step-level timing and isolated log grouping in GitHub Actions (for actionability), but still want developers to have a one-shot `mix ci` command locally.
**Example:**
```yaml
# In .github/workflows/ci.yml
- name: Format
  run: mix format --check-formatted
- name: Compile
  run: mix compile --warnings-as-errors
- name: Test
  run: mix test --exclude quarantine --slowest 10 2>&1 | tee /tmp/mix-test-output.log
```
```elixir
# In mix.exs
defp aliases do
  [
    ci: ["ci.fast", "ci.proofs"],
    "ci.fast": [
      "format --check-formatted",
      "compile --warnings-as-errors",
      "test --exclude quarantine --slowest 10"
      # ...
    ]
  ]
end
```

### The "Shields.io Check-Run" Badge Pattern
**What:** Replacing the native GitHub Actions workflow badge with a Shields.io Check-Run badge.
**When to use:** When a workflow contains `continue-on-error` advisory jobs that cause the overall workflow to appear as failing, but a specific aggregate job (`ci-success`) represents the true merge gate.
**Example:**
```markdown
[![CI](https://img.shields.io/github/check-runs/szTheory/rendro/main?name=ci-success)](https://github.com/szTheory/rendro/actions/workflows/ci.yml)
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Inline PR Warnings | Custom `::warning::` awk parsers | `erlef/setup-beam` | The pinned action natively injects problem matchers for `credo`, `dialyzer`, `elixirc`, and `ex_unit`. |
| Job-Specific Badges | Custom GitHub Actions state-export endpoints | Shields.io `check-runs` API | Shields.io natively supports querying the GitHub Checks API by specific job name. |

## Common Pitfalls

### Pitfall 1: Guardrail Contract Breakage
**What goes wrong:** Modifying the `test` job in `ci.yml` to split steps will instantly fail the `Guardrails.RequiredChecksContractTest`.
**Why it happens:** The test strictly asserts that the `test` job block contains the literal string `run: mix ci` and that the `mix ci` alias contains a very specific hardcoded list of 7 commands.
**How to avoid:** You MUST update `test/guardrails/required_checks_contract_test.exs` in the same commit that modifies `ci.yml` and `mix.exs`. The guardrail should be updated to assert that the `test` block contains the individual separated steps and that `ci.fast` contains the expected sub-commands.

### Pitfall 2: Breaking the Step Summary Pipeline
**What goes wrong:** The `$GITHUB_STEP_SUMMARY` script fails to parse the slowest tests.
**Why it happens:** In Phase 108, the summary script relies on `/tmp/mix-ci-output.log`, which was piped from `mix ci`. If you split the steps, `mix ci` is no longer run natively.
**How to avoid:** Pipe the specific test step (`mix test ... 2>&1 | tee /tmp/mix-test-output.log`) and update the Step Summary bash script to read from `/tmp/mix-test-output.log` instead.

### Pitfall 3: `ci.proofs` Execution Environment
**What goes wrong:** Adding `ci.proofs` to the `test` job fails because PyHanko and pdfium-cli are missing.
**Why it happens:** The `test` job is a standard ubuntu-latest runner. The heavy system dependencies are only installed in the `integration-proofs` job.
**How to avoid:** In GitHub Actions, ensure the `test` job ONLY runs the equivalent of `mix ci.fast`. The `integration-proofs` job handles the proofs. The `mix ci` (running both) is specifically for the *local* developer environment.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (1.19.5) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix ci` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Guardrail aligns CI YAML steps with mix aliases | unit | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ Yes (needs update) |

### Sampling Rate
- **Per task commit:** `mix test test/guardrails/required_checks_contract_test.exs`
- **Per wave merge:** `mix ci`
- **Phase gate:** Full `mix ci` green locally before metric generation.

### Wave 0 Gaps
- [x] `test/guardrails/required_checks_contract_test.exs` MUST be updated to expect the split steps in `ci.yml` and the new `ci.fast`/`ci.proofs` aliases.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Native Workflow Badge | Shields.io Check-Runs Badge | GitHub limits | Allows accurate badging of repositories that use `continue-on-error` advisory lanes. |
| Monolithic `mix ci` | Split Steps + Local `mix ci` Alias | Modern DX | Provides step-level timing and clean GitHub UI logs while retaining local ergonomics. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/113-dx-local-reproducibility-validation/113-CONTEXT.md` - Locked architectural decisions for pipeline DX.
- `test/guardrails/required_checks_contract_test.exs` - Source code exposing the strict structural validations that must be updated.
- `erlef/setup-beam` Documentation - Confirmed automatic registration of Elixir problem matchers.
- Shields.io API Documentation - Confirmed `check-runs` endpoint for job-level GitHub Actions badging.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified GitHub actions matcher behavior and Shields API limits.
- Architecture: HIGH - Split-step pattern accurately reflects Phase 108 audit recommendations.
- Pitfalls: HIGH - Guardrail test explicitly reviewed and confirmed.

**Research date:** 2026-06-16
**Valid until:** 2026-07-16
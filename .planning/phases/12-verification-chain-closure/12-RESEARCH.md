# Phase 12: Verification Chain Closure - Research

**Researched:** 2026-04-28
**Domain:** verification-lane completion, hosted CI proof, and Phoenix example adoption evidence
**Confidence:** HIGH

## Summary

Phase 12 is not a greenfield quality phase. The repo already contains most of the required surfaces, but the proof chain is still broken in three places: `.github/workflows/ci.yml` is untracked, `mix verify` still exits on deterministic-lane failure before the advisory segment can finish, and the current hosted CI workflow only runs `mix ci`, so the Phoenix example path is still local-only proof instead of committed CI-backed evidence.

**Primary recommendation:** plan this phase as a verification-chain repair, not as broad quality hardening. Keep scope on three outcomes only: commit and stabilize the CI workflow, change `mix verify` so deterministic and advisory lanes both run and report their results before the command exits, and extend committed CI evidence so the Phoenix example path is exercised from automation rather than inferred from local compilation.

## Project Constraints

- Keep `rendro` core pure: no new hard dependency on Phoenix, Oban, or admin tooling.
- Preserve deterministic and advisory verification lane separation in CI and docs.
- Treat documentation and verification claims as contracts; do not claim hosted proof that is not actually exercised.
- Distinguish committed-code gaps from incidental dirty-worktree state when selecting proof commands and acceptance criteria.

## Current State

### Proof surfaces already present

| Surface | Current state | Evidence |
|---------|---------------|----------|
| `mix ci` | Defined and includes format, compile, test, docs, credo, dialyzer, and `hex.build` | `mix.exs` |
| Hosted CI workflow | File exists locally but is untracked | `.github/workflows/ci.yml`, `git status --short` |
| Verification entrypoint | `mix verify` prints deterministic and advisory lane headings | `lib/mix/tasks/verify.ex` |
| Phoenix example app | Example project exists and compiles locally when deps are fetched | `examples/phoenix_example/mix.exs`, Phase 4/11 artifacts |

### Gaps Phase 12 must close

| Gap ID | Requirement(s) | What is still broken | Evidence |
|--------|----------------|----------------------|----------|
| `INT-CI-TRACKING` | `QUAL-01`, `QUAL-03` | Hosted CI proof is not part of committed repo history because `.github/workflows/ci.yml` is untracked | `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`, `git status --short` |
| `INT-VERIFY-LANES` | `QUAL-01`, `QUAL-05` | `mix verify` exits on deterministic failure instead of completing both lanes and reporting all failures together | `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`, `lib/mix/tasks/verify.ex` |
| example proof drift | `QUAL-03` | Current workflow only runs `mix ci`, so CI does not prove the Phoenix example path | `.github/workflows/ci.yml`, `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Merge-blocking verification | Mix aliases/tasks | GitHub Actions | `mix ci` remains the canonical deterministic lane; CI hosts it |
| End-to-end verification reporting | `lib/mix/tasks/verify.ex` | example app commands | This task owns deterministic vs advisory sequencing and exit semantics |
| Hosted adoption proof | GitHub Actions workflow | Phoenix example app | `QUAL-03` needs committed automation evidence, not just local compile proof |

## Implementation Patterns

### Pattern 1: Accumulate failures across lanes before exiting

`mix verify` should run each deterministic and advisory step, record pass/fail state, print a lane-by-lane summary, and exit non-zero only after all intended steps have run. This preserves separation while avoiding premature aborts that hide advisory results.

### Pattern 2: Keep deterministic authority in `mix ci`

Do not duplicate the `mix ci` contract in CI YAML. The workflow should continue to call `mix ci` as the canonical deterministic lane and then run any additional advisory/example verification explicitly.

### Pattern 3: Hosted example proof must be explicit

`QUAL-03` is not closed by checking in a workflow file alone. The committed workflow must contain a concrete step that fetches deps and exercises the Phoenix example path so CI logs prove it.

## Common Pitfalls

### Pitfall 1: Treating untracked workflow files as proof

The audits already called out that `.github/workflows/ci.yml` existed only in the working tree. Planning must require tracked workflow content and verification that the committed file still runs the expected commands.

### Pitfall 2: Failing fast in `mix verify`

The current `run_step/2` implementation exits immediately for most failures. That behavior is correct for strict lane steps like `mix ci` in isolation, but it defeats the product contract for a report-oriented `mix verify` command that promises deterministic and advisory separation.

### Pitfall 3: Proving only local compilation of the example app

Phase 11 already established that local example compilation is supporting evidence, not hosted proof. Phase 12 must move that proof into the committed CI workflow or an equivalent committed automation surface.

## File-Level Scope

| File | Why it matters |
|------|----------------|
| `.github/workflows/ci.yml` | Hosted CI proof surface for `QUAL-01` and `QUAL-03` |
| `lib/mix/tasks/verify.ex` | Owns deterministic/advisory execution order, reporting, and exit semantics |
| `mix.exs` | Canonical `mix ci` contract; read before changing workflow semantics |
| `examples/phoenix_example/mix.exs` | Defines the example app dependency/runtime surface used in CI proof |
| `scripts/verify_docs.exs` | Adjacent verification surface; read for consistency but likely not a Phase 12 edit target |
| `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` | Baseline evidence ceiling that Phase 12 is intended to raise |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix task integration commands |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix verify` |
| Hosted proof command | GitHub Actions workflow running `mix ci` plus Phoenix example step |

### Phase Requirements -> Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists? |
|-------------|----------|-----------|-------------------|--------------|
| `QUAL-01` | committed CI workflow runs canonical deterministic lane | workflow + integration | `mix ci` and committed `.github/workflows/ci.yml` | partial |
| `QUAL-03` | hosted CI exercises Phoenix example adoption proof | workflow + integration | CI step running `cd examples/phoenix_example && mix deps.get && mix compile` or equivalent | missing in committed proof |
| `QUAL-05` | `mix verify` completes both lanes and reports combined outcome | mix task integration | `mix verify` | partial |

### Sampling Rate

- After every task commit: targeted command for touched surface (`mix verify`, workflow lint/readback, example compile).
- After every plan wave: `mix verify`.
- Before phase close: clean-worktree run of `mix verify` and review of committed workflow steps.

### Wave 0 Gaps

- [ ] Committed workflow proof must be re-established from `.github/workflows/ci.yml`
- [ ] `mix verify` exit/report semantics need regression coverage or command-proof capture
- [ ] Hosted example proof must be added to committed automation

## Recommended Plan Shape

Two execution plans are enough:

1. CI proof surface: make `.github/workflows/ci.yml` a committed, truthful verification surface for deterministic lane plus Phoenix example evidence.
2. Verification runner semantics: refactor `mix verify` so deterministic and advisory lanes always finish and return an aggregated verdict with actionable output.

This keeps the phase narrow, maps cleanly to `QUAL-01`, `QUAL-03`, and `QUAL-05`, and avoids bleeding into the still-open docs/release concerns reserved for Phase 13.

## Sources

- `mix.exs`
- `lib/mix/tasks/verify.ex`
- `.github/workflows/ci.yml`
- `examples/phoenix_example/mix.exs`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`
- `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md`
- `.planning/phases/09-ci-and-release-hardening/09-01-PLAN.md`
- `.planning/phases/09-ci-and-release-hardening/09-02-PLAN.md`

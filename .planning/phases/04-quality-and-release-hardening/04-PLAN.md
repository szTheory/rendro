---
phase: 04-quality-and-release-hardening
plan: "04"
type: reconstructed
status: closed-from-live-evidence
requirements:
  - QUAL-01
  - QUAL-02
  - QUAL-03
  - QUAL-04
  - QUAL-05
artifacts:
  - 04-VERIFICATION.md
  - 04-SUMMARY.md
  - 04-PLAN.md
---

# Phase 04: Quality and Release Hardening Plan Record

## Objective

Record what the live codebase currently proves for the original Phase 4 scope, using `04-VERIFICATION.md` as the canonical evidence source and `04-SUMMARY.md` as the reader-facing closeout.

## Delivered Scope

- `QUAL-01`: the current `mix ci` lane exists and runs in a clean worktree, but it currently fails on committed repo quality findings and therefore remains partial.
- `QUAL-02`: the docs-contract command runs successfully, but it still skips partial README examples and therefore remains partial.
- `QUAL-03`: the Phoenix example app compiles in a clean worktree, but committed CI workflow proof for that path remains incomplete.
- `QUAL-04`: the release-preflight task is currently blocked before a tagged-release happy path or publish dry-run proof can complete.
- `QUAL-05`: deterministic and advisory lane labels exist in `mix verify`, but the clean command currently exits before a full separated verification run completes.

## Verification Contract

The reconstructed Phase 4 verdicts live in `04-VERIFICATION.md` and are summarized in `04-SUMMARY.md`. Traceability updates for `QUAL-01` through `QUAL-05`, plus the final coverage totals in `.planning/REQUIREMENTS.md`, must come only from the final verdicts in `04-VERIFICATION.md` together with the completed `01-VERIFICATION.md`, `02-VERIFICATION.md`, and `03-VERIFICATION.md`.

## Evidence Map

| Requirement | Primary proof | Supporting evidence |
|-------------|---------------|---------------------|
| QUAL-01 | temporary clean worktree run of `mix ci` | `mix.exs`, `.github/workflows/ci.yml` |
| QUAL-02 | temporary clean worktree run of `mix run scripts/verify_docs.exs` | `scripts/verify_docs.exs`, `README.md` |
| QUAL-03 | temporary clean worktree run of `cd examples/phoenix_example && mix deps.get && mix compile` | `.github/workflows/ci.yml`, `examples/phoenix_example/mix.exs` |
| QUAL-04 | temporary clean worktree run of `mix release.preflight` | `lib/mix/tasks/release/preflight.ex`, `11-VALIDATION.md` |
| QUAL-05 | temporary clean worktree run of `mix verify` | `lib/mix/tasks/verify.ex` |

## Artifact Record

- `04-VERIFICATION.md` provides the requirement-first proof and final verdicts.
- `04-SUMMARY.md` provides the reconstructed outcome summary derived from `04-VERIFICATION.md`.
- `04-PLAN.md` records the live evidence mapping for the reconstructed Phase 4 slice.

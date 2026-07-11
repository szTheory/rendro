---
phase: 108-baseline-audit-report
plan: "01"
subsystem: ci-cd
tags: [observability, ci, github-actions, job-summary, base-05]
dependency_graph:
  requires: []
  provides: [BASE-05]
  affects: [.github/workflows/ci.yml]
tech_stack:
  added: []
  patterns:
    - "set -o pipefail + tee pipeline for exit-code-preserving stdout capture"
    - "Single brace-group { … } >> $GITHUB_STEP_SUMMARY write (house style)"
    - "if: always() + continue-on-error: true observability step guard"
key_files:
  created: []
  modified:
    - .github/workflows/ci.yml
decisions:
  - "Used set -o pipefail (bash-idiomatic) over ${PIPESTATUS[0]} for readability (both equivalent)"
  - "Single brace-group redirect per house style (mailglass sibling pattern, avoids multi-write rendering inconsistency)"
  - "TODO(109) comment retained as explicit Phase 109 cache-row handoff seam"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-14"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 108 Plan 01: BASE-05 CI Job Summary Instrumentation Summary

One-liner: Gate-neutral `$GITHUB_STEP_SUMMARY` observability added to `test` job via `id: setup-beam`, `set -o pipefail` tee capture, and single brace-group CI Baseline panel with OTP/Elixir/schedulers/cache/slowest-test rows.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Instrument the `test` job with BASE-05 summary observability | 5658433 | `.github/workflows/ci.yml` |

## What Was Built

Three targeted mutations to the `test` job stanza in `.github/workflows/ci.yml`:

**Mutation 1 — `id: setup-beam`:** Added `id: setup-beam` as the second line of the Setup Beam step. This exposes `steps.setup-beam.outputs.otp-version` and `steps.setup-beam.outputs.elixir-version` to downstream steps. The `erlef/setup-beam@v1` ref is unchanged (SEC-01/Phase 112 scope).

**Mutation 2 — Tee-capturing Run CI step:** Replaced `run: mix ci` with a `shell: bash` block using `set -o pipefail` followed by `mix ci 2>&1 | tee /tmp/mix-ci-output.log`. The `set -o pipefail` is mandatory — without it, `tee`'s always-zero exit code would silently swallow a `mix ci` failure. The job exit code behavior is preserved exactly.

**Mutation 3 — CI Baseline Summary step:** New step appended after Run CI with `if: always()` (runs even on `mix ci` failure), `continue-on-error: true` (cannot fail the job), and a single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` write containing:
- `## CI Baseline` H2 header
- Markdown table: OTP version, Elixir version, `System.schedulers_online()` (with `|| echo 'n/a'` fallback), cache placeholders (`cold / none` with `# TODO(109)` seam comment)
- `### Slowest Tests` block from `grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log`

No other job, file, or gate outcome was modified.

## Acceptance Criteria Results

| Check | Result |
|-------|--------|
| `grep -n "id: setup-beam" .github/workflows/ci.yml` | Line 23: exactly one match in `test` job |
| `grep -nE "pipefail\|PIPESTATUS" .github/workflows/ci.yml` | Line 35: `set -o pipefail` |
| `grep -nE "if: always\(\)" .github/workflows/ci.yml` | Line 39: CI Baseline Summary step |
| `grep -n "continue-on-error" .github/workflows/ci.yml` | Line 40: CI Baseline Summary step |
| `grep -c "GITHUB_STEP_SUMMARY" .github/workflows/ci.yml` | `1` (single brace-group write confirmed) |
| `grep -n "TODO(109)" .github/workflows/ci.yml` | Line 51: Phase 109 seam comment present |
| `git diff --name-only` | `.github/workflows/ci.yml` only |
| `mix format --check-formatted` | Pre-existing failures in unrelated Elixir files (not introduced by this plan); YAML/ci.yml not Elixir-formatted |

## Deviations from Plan

None — plan executed exactly as written. Applied the verbatim YAML from 108-PATTERNS.md Steps 1/2/3 to the letter.

## Threat Surface Scan

No new threat surface introduced. The CI Baseline Summary step reads only:
- `steps.setup-beam.outputs.otp-version` (resolved by GitHub Actions before shell runs — not user input)
- `steps.setup-beam.outputs.elixir-version` (same)
- `System.schedulers_online()` (runner-local BEAM call, no secrets)
- grep of `/tmp/mix-ci-output.log` (stdout of `mix ci`, no secrets material)

No `${{ secrets.* }}` references. T-108-02 disposition confirmed: `mitigate` applied correctly.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `cold / none` cache rows | `.github/workflows/ci.yml` | 51-52 | Intentional Phase 109 seam — Phase 109 adds `actions/cache` with `id: cache` and replaces these rows with `${{ steps.cache.outputs.cache-hit == 'true' && 'hit' || 'miss' }}`. The `# TODO(109)` comment marks the handoff. |

## Self-Check: PASSED

- `.github/workflows/ci.yml` exists and is modified: FOUND
- Commit `5658433` exists: FOUND (`git log --oneline -1` → `5658433 feat(108-01): add BASE-05 gate-neutral job-summary instrumentation to test job`)
- All 6 smoke-grep assertions: PASSED
- `git diff --name-only`: only `.github/workflows/ci.yml`
- No deletions in commit: CONFIRMED (`1 file changed, 27 insertions(+), 1 deletion(-)` — the 1 deletion is replacing `run: mix ci` with the block scalar form)

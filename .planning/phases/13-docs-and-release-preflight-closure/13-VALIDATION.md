---
phase: 13
slug: docs-and-release-preflight-closure
status: human_needed
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for docs closure and strict release-preflight work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix task integration commands |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/release_preflight_test.exs` |
| **Full suite command** | `mix test`, `mix run scripts/verify_docs.exs`, and `mix release.preflight` from a controlled clean/tagged worktree when exercising the strict happy path |
| **Estimated runtime** | ~60-180 seconds depending on docs and release-worktree setup |

---

## Sampling Rate

- **After every task commit:** Run the narrowest relevant docs-contract or preflight regression command, plus `mix run scripts/verify_docs.exs` when the docs harness or contract docs change.
- **After every plan wave:** Run `mix test` and the relevant `mix release.preflight` failure-mode checks.
- **Before `$gsd-verify-work`:** Run strict preflight happy-path proof from a clean exact-tag ref or disposable release-like worktree.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | QUAL-02 | T-13-01 | `README.md` `iex>` examples execute in an explicit doctest lane and fail truthfully when public quickstart behavior drifts. | doctest | `mix test test/docs_contract/readme_doctest_test.exs` | ✅ | ✅ green |
| 13-01-02 | 01 | 1 | QUAL-02 | T-13-02 | Selected `guides/integrations.md` happy-path snippets stay executable while schematic snippets are reclassified or explicitly rejected from verified `elixir` fences. | unit/integration | `mix test test/docs_contract/integrations_contract_test.exs` | ✅ | ✅ green |
| 13-01-03 | 01 | 1 | QUAL-02 | T-13-03 | Guide semantic claims are enforced by direct ExUnit tests against live adapter/runtime behavior rather than compile-only checks. | unit/integration | `mix test test/docs_contract/integrations_claims_test.exs` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | QUAL-04 | T-13-04 | `mix release.preflight` fails on dirty worktrees, tag/version mismatch, or missing release prerequisites before expensive checks run. | task regression | `mix test test/mix/tasks/release_preflight_test.exs` and live `mix release.preflight` dirty-worktree run | ✅ | ✅ green |
| 13-02-02 | 02 | 2 | QUAL-04 | T-13-05 | `mix release.preflight` aggregates `mix ci`, docs contract, package build, and publish dry-run into one final summary and one final exit after boundary checks pass. | task regression | `mix test test/mix/tasks/release_preflight_test.exs` plus controlled `mix release.preflight` proof from a clean tagged worktree | ✅ partial | ⚠ human-needed |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/docs_contract/readme_doctest_test.exs` — README doctest entrypoint for the explicit `iex>` lane.
- [x] `test/docs_contract/integrations_contract_test.exs` — curated guide happy-path compile/eval coverage.
- [x] `test/docs_contract/integrations_claims_test.exs` — semantic-claim regressions for guide behavior that compile checks cannot prove.
- [x] `test/mix/tasks/release_preflight_test.exs` — phase-1 boundary-failure and phase-2 aggregated-summary coverage.
- [x] A minimal command-runner seam or fixture helper so preflight tests do not invoke the real Hex publish path during unit runs.
- [x] Clean/tagged proof instructions or helper workflow for exercising the strict happy path outside the active dirty workspace.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strict tagged-release happy path reaches `mix hex.publish --dry-run --yes` after boundary checks pass | QUAL-04 | The active workspace is dirty and `HEAD` is untagged, so truthful proof requires an isolated clean exact-tag ref rather than the current branch state | Create or reuse a clean worktree at an exact `vX.Y.Z` tag matching `Mix.Project.config()[:version]`, then run `mix release.preflight` and capture the final summary as verification evidence |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing docs-contract and preflight regressions
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; strict tagged-release happy path remains manual by design

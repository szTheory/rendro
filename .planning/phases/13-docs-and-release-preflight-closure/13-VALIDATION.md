---
phase: 13
slug: docs-and-release-preflight-closure
status: approved
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
| **Full suite command** | `mix test`, `mix run scripts/verify_docs.exs`, and `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree <isolated-path>` |
| **Estimated runtime** | ~60-180 seconds depending on docs and release-worktree setup |

---

## Sampling Rate

- **After every task commit:** Run the narrowest relevant docs-contract or preflight regression command, plus `mix run scripts/verify_docs.exs` when the docs harness or contract docs change.
- **After every plan wave:** Run `mix test` and the relevant `mix release.preflight` failure-mode checks.
- **Before `$gsd-verify-work`:** Run the synthetic exact-tag release proof helper from an isolated worktree path.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | QUAL-02 | T-13-01 | `README.md` `iex>` examples execute in an explicit doctest lane and fail truthfully when public quickstart behavior drifts. | doctest | `mix test test/docs_contract/readme_doctest_test.exs` | ✅ | ✅ green |
| 13-01-02 | 01 | 1 | QUAL-02 | T-13-02 | Selected `guides/integrations.md` happy-path snippets stay executable while schematic snippets are reclassified or explicitly rejected from verified `elixir` fences. | unit/integration | `mix test test/docs_contract/integrations_contract_test.exs` | ✅ | ✅ green |
| 13-01-03 | 01 | 1 | QUAL-02 | T-13-03 | Guide semantic claims are enforced by direct ExUnit tests against live adapter/runtime behavior rather than compile-only checks. | unit/integration | `mix test test/docs_contract/integrations_claims_test.exs` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | QUAL-04 | T-13-04 | `mix release.preflight` fails on dirty worktrees, tag/version mismatch, or missing release prerequisites before expensive checks run. | task regression | `mix test test/mix/tasks/release_preflight_test.exs` and live `mix release.preflight` dirty-worktree run | ✅ | ✅ green |
| 13-02-02 | 02 | 2 | QUAL-04 | T-13-05 | `mix release.preflight` aggregates `mix ci`, docs contract, package build, and publish dry-run into one final summary and one final exit after boundary checks pass. | task regression + proof helper | `mix test test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` plus `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree <isolated-path>` | ✅ | ✅ green |

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

None. The exact-tag happy path is now exercised through the synthetic-tag helper and the dedicated CI `release-proof` job.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing docs-contract and preflight regressions
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; no manual release-proof step remains

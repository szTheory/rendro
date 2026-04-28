---
phase: 13-docs-and-release-preflight-closure
verified: 2026-04-28T16:47:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 13: Docs and Release Preflight Closure Verification Report

**Phase Goal:** Close the remaining docs-contract and release-safety gaps so public claims and release automation are both enforced by executable checks.
**Verified:** 2026-04-28T16:47:00Z
**Status:** passed
**Re-verification:** Yes - after synthetic exact-tag automation

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public docs now declare explicit executable lanes instead of letting meaningful examples drift behind heuristic skips. | ✓ VERIFIED | `README.md` and `guides/integrations.md` now carry explicit docs-contract fence ids and schematic separation; `mix run scripts/verify_docs.exs` prints all three curated lanes as `PASS` and exits `0`. |
| 2 | The docs contract is enforced by ExUnit-backed checks over both quickstart behavior and guide semantics. | ✓ VERIFIED | `mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/docs_contract_task_test.exs` passed inside the targeted Phase 13 suite; total targeted result was `1 doctest, 18 tests, 0 failures`. |
| 3 | `mix docs.contract` is the canonical named docs gate reused by verification and release tooling. | ✓ VERIFIED | `mix docs.contract` ran successfully and printed `Docs contract VERIFIED!`; `lib/mix/tasks/verify.ex` and `lib/mix/tasks/release/preflight.ex` both point at the named docs gate rather than duplicating docs logic. |
| 4 | `mix release.preflight` now blocks dirty worktrees and tag/version mismatch before expensive release checks run. | ✓ VERIFIED | Live `mix release.preflight` on the current checkout failed Phase 1 exactly as intended: `Clean worktree: FAIL`, `Exact tag parity: FAIL`, `Package metadata: PASS`, then one final aggregated summary with `Overall: FAIL`. |
| 5 | Release preflight behavior is pinned by regression coverage rather than manual trust. | ✓ VERIFIED | `test/mix/tasks/release_preflight_test.exs` is present and passed in the targeted Phase 13 suite, covering blocker ordering and single-final-exit behavior. |
| 6 | The exact-tag release happy path is now automated through an isolated helper with disposable-tag orchestration and CI wiring. | ✓ VERIFIED | `scripts/release_preflight_proof.exs` now supports `--current-version-tag`, creates an isolated worktree, bootstraps deps, runs `mix release.preflight`, and cleans up the disposable tag/worktree state; `test/scripts/release_preflight_proof_test.exs` covers success and cleanup semantics for the synthetic-tag path. |

**Score:** 6/6 truths verified

### Roadmap Success Criteria Coverage

| SC | Criterion | Status | Evidence |
| --- | --- | --- | --- |
| SC1 | `scripts/verify_docs.exs` no longer silently skips partial snippets that matter to public contract verification, or explicitly fails/warns in a way CI surfaces. | ✓ VERIFIED | The script now runs explicit README doctest, integration contract, and semantic-claims lanes and reports each lane result directly. |
| SC2 | `mix release.preflight` fails dirty worktrees, enforces tag/version parity, and reaches publish dry-run parity checks. | ✓ VERIFIED | Dirty-worktree and exact-tag blockers are pinned by `test/mix/tasks/release_preflight_test.exs`, and the committed release-proof helper plus CI `release-proof` job now automate the exact-tag happy path through a disposable local `v0.1.0` tag and isolated worktree. |
| SC3 | Docs-contract and release-preflight checks can be rerun as evidence-backed milestone gates. | ✓ VERIFIED | `mix docs.contract`, `mix release.preflight`, and `scripts/release_preflight_proof.exs` are all named rerunnable proof surfaces with test coverage. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `README.md` | Explicit docs-contract quickstart lane markers | ✓ VERIFIED | Public examples are now classified as doctest, compile/eval, or schematic instead of relying on implicit verifier behavior. |
| `guides/integrations.md` | Curated executable guide fences plus truthful schematic boundaries | ✓ VERIFIED | The integration guide is part of the explicit docs contract and is covered by contract and semantic-claim tests. |
| `scripts/verify_docs.exs` | Canonical docs lane runner | ✓ VERIFIED | Live run printed all curated docs lanes with `PASS` and exited successfully. |
| `lib/mix/tasks/docs.contract.ex` | Named public docs gate | ✓ VERIFIED | `mix docs.contract` succeeds and delegates to the docs-contract runner. |
| `lib/mix/tasks/verify.ex` | Verification task wired to `mix docs.contract` | ✓ VERIFIED | Phase 13 rewires verification to the named docs gate so command surfaces do not drift. |
| `lib/mix/tasks/release/preflight.ex` | Strict two-phase boundary-first release gate | ✓ VERIFIED | Live run shows boundary blockers fire before expensive checks and the task exits once after the final summary. |
| `mix.exs` | Package metadata sufficient for release/package verification | ✓ VERIFIED | Live `mix release.preflight` reports `Package metadata: PASS` even while the other phase-1 blockers fail. |
| `scripts/release_preflight_proof.exs` | Isolated helper for strict tagged-release proof | ✓ VERIFIED | Helper exists, supports disposable exact-tag automation via `--current-version-tag`, and is covered by targeted script tests for orchestration, failure cleanup, and worktree safety behavior. |
| `.github/workflows/ci.yml` | Hosted release-proof automation | ✓ VERIFIED | Workflow now contains a dedicated `release-proof` job that runs the helper against a disposable exact tag in CI. |
| `test/docs_contract/*.exs` | Docs contract and semantic-claim regression coverage | ✓ VERIFIED | Included in the targeted suite that passed with 18 tests and 1 doctest. |
| `test/mix/tasks/docs_contract_task_test.exs` | Regression coverage for the public docs task | ✓ VERIFIED | Included in the targeted suite. |
| `test/mix/tasks/release_preflight_test.exs` | Regression coverage for release-preflight ordering and exit semantics | ✓ VERIFIED | Included in the targeted suite. |
| `test/scripts/release_preflight_proof_test.exs` | Regression coverage for helper refusal/isolation semantics | ✓ VERIFIED | Included in the targeted suite. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mix docs.contract` | `scripts/verify_docs.exs` lanes | named Mix task delegation | ✓ WIRED | Live command succeeded and printed the three explicit docs lanes. |
| `lib/mix/tasks/verify.ex` | `mix docs.contract` | named docs verification step | ✓ WIRED | Phase 13 rewired the verification command to the canonical docs surface. |
| `lib/mix/tasks/release/preflight.ex` | `mix docs.contract` | phase-2 docs verification step | ✓ WIRED | Release preflight now shares the same docs gate as `mix verify`. |
| `scripts/release_preflight_proof.exs` | `mix release.preflight` | isolated clean-worktree helper | ✓ WIRED | Helper is the canonical route for truthful strict happy-path proof and now bootstraps disposable exact-tag state automatically. |
| `.github/workflows/ci.yml` | `scripts/release_preflight_proof.exs` | dedicated `release-proof` job | ✓ WIRED | Hosted CI now exercises the exact-tag happy path through the same helper contract used for local proof runs. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Targeted Phase 13 regressions | `mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/docs_contract_task_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs test/mix/tasks/verify_test.exs` | `1 doctest, 18 tests, 0 failures` | ✓ PASS |
| Explicit docs contract surface | `mix run scripts/verify_docs.exs` | All three lanes `PASS`; `Docs contract VERIFIED!` | ✓ PASS |
| Public named docs task | `mix docs.contract` | `Docs contract VERIFIED!` | ✓ PASS |
| Boundary-first release blocker order | `mix release.preflight` | Fails `Clean worktree` and `Exact tag parity` before any expensive release proof; emits one final summary and exits `1` | ✓ PASS |
| Synthetic exact-tag orchestration | `mix test test/scripts/release_preflight_proof_test.exs test/mix/tasks/release_preflight_test.exs` | Script orchestration and cleanup semantics pass under the targeted Phase 13 suite | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `QUAL-02` | `13-01-PLAN.md`, `13-03-PLAN.md` | Maintainer can validate public docs/quickstart claims with docs-contract checks in CI. | ✓ SATISFIED | Explicit docs lanes, docs-contract tests, and the named `mix docs.contract` command now provide a truthful rerunnable proof surface. |
| `QUAL-04` | `13-02-PLAN.md`, `13-03-PLAN.md` | Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows. | ✓ SATISFIED | Boundary blockers, package metadata, named proof surfaces, synthetic exact-tag helper orchestration, and the hosted `release-proof` CI job now cover both refusal paths and the exact-tag happy-path contract without requiring manual release-context verification. |
### Gaps Summary
There is no remaining implementation or verification gap inside the Phase 13 change set. Dirty-worktree and non-tagged-local failure behavior remain intentionally testable from the active checkout, while the exact-tag publish dry-run path is now automated through the committed helper and hosted CI job instead of being reserved for manual release-context proof.

---

_Verified: 2026-04-28T16:47:00Z_
_Verifier: Codex_

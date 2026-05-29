---
phase: 72-closure-audit-polish-and-ship
plan: 03
subsystem: docs
tags: [hex, changelog, semver, docs-contract, release-preflight, viewer-evidence, guardrail-02]

# Dependency graph
requires:
  - phase: 72-01
    provides: GUARDRAIL-02 durable baseline (required_status_checks.json, branch-protection audit script)
  - phase: 72-02
    provides: validate --strict staleness gate, machine matrix ledger, 72-VERIFICATION draft
provides:
  - Surgical viewer_evidence guide polish (Phase 71 record commands, exit-0 manual step, Appendix D --strict row)
  - Docs-contract lane 8 hardening (chrome_pdfium supported paths + verbatim deferral-substring mirror)
  - CHANGELOG split 0.3.0 (frozen 2026-05-08) vs 0.3.1 (v2.3 Viewer Evidence) + @version 0.3.1
  - Negative hex.build test refuting operator-only priv paths in tarball
  - release.yml hardened with mix release.preflight before hex.publish
  - Finalized 72-VERIFICATION with full v0.3.1 ship-gate results
affects: [hex-publish, v2.3-milestone-close, audit-milestone]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Verbatim matrix-mirrored deferral reasons block in api_stability.md (RECIPE-05 honesty)"
    - "CHANGELOG release-tail bound to the in-progress version section for preflight check_changelog_release_tail"
    - "Synthetic exact-tag preflight proof in isolated worktree as authoritative pre-tag ship signal"

key-files:
  created:
    - .planning/phases/72-closure-audit-polish-and-ship/72-03-SUMMARY.md
  modified:
    - guides/viewer_evidence.md
    - guides/api_stability.md
    - test/docs_contract/viewer_evidence_claims_test.exs
    - test/docs_contract/branding_claims_test.exs
    - CHANGELOG.md
    - mix.exs
    - .github/workflows/release.yml
    - .planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md
    - lib/mix/tasks/rendro/viewer_evidence.ex
    - test/mix/tasks/viewer_evidence_task_test.exs
    - test/mix/tasks/release_preflight_test.exs

key-decisions:
  - "0.3.1 CHANGELOG section uses '- Unreleased' (not a date) so preflight check_changelog_release_tail binds to the current release; tag-time dating is an operator step."
  - "Protected-delivery pointer string moved to the 0.3.1 release-tail boundary so check_changelog_release_tail validates the in-progress version."
  - "api_stability.md gets a verbatim 'Explicit Deferral Reasons (matrix-mirrored)' block rather than a prose rewrite — minimal, honest, satisfies the substring mirror test."
  - "Hex files: whitelist left unchanged (D-29); negative tarball test documents the operator-priv omission instead of expanding the package."
  - "No v0.3.1 git tag created; tag/publish/audit-milestone are operator post-execute steps (D-15)."

patterns-established:
  - "Deferral-substring mirror test: for each explicit_deferral row, assert guides/api_stability.md contains String.slice(evidence_deferred, 0, 40)."
  - "Release-preflight proof script (--current-version-tag) is the canonical green gate; direct mix release.preflight Phase 1 fails by design pre-tag in a dirty/untagged tree."

requirements-completed: [GUARDRAIL-02]

# Metrics
duration: 35min
completed: 2026-05-29
---

# Phase 72 Plan 03: Closure Polish and v0.3.1 Ship Gate Summary

**Polished guides and docs-contract for the v2.3 viewer-evidence close, split the conflated CHANGELOG into a frozen 0.3.0 and a new 0.3.1 section, bumped `@version` to 0.3.1, locked Hex packaging honesty with a negative tarball test, hardened `release.yml` with a preflight step, and drove the full ship gate green (including the isolated-worktree preflight proof at a synthetic v0.3.1 exact tag).**

## Performance

- **Duration:** ~35 min
- **Tasks:** 5/5
- **Files modified:** 11 (8 plan files + 3 pre-existing blocking-issue fixes)

## Accomplishments

- **Task 1 — guide polish (already-done, verified + committed):** The crash-resume working tree already contained correct `guides/viewer_evidence.md` edits (Phase 71 trust-sensitive `record` commands, manual step 1 → exit 0, manual step 6 → tier-B promotion-complete, `trust_sensitive_viewer_evidence_live_test.exs` link + 7 CI live-test files, Appendix D `validate --strict` row). All acceptance criteria verified satisfied; no gap fixes needed. Committed as `2b1140f`. `guides/api_stability.md` needed no Task-1 drift fix at this stage.
- **Task 2 — docs-contract hardening:** Added `forms/chrome_pdfium.md` and `signature_widget/chrome_pdfium.md` to the api_stability path-assert loop, and a new deferral-substring mirror test asserting each of the 9 `explicit_deferral` `evidence_deferred` reasons (first 40 chars) appears in `guides/api_stability.md`. Added a verbatim matrix-mirrored deferral-reasons block to the guide so the substring test passes honestly. `mix test viewer_evidence_claims_test.exs` 21/21; `mix docs.contract` 8/8.
- **Task 3 — CHANGELOG split + version bump:** Froze `## [0.3.0] - 2026-05-08` with tag-accurate pre-v2.3 content (restored the v0.3.0-tag "rows without recorded proof remain unverified" wording), created `## [0.3.1] - Unreleased` with all v2.3 Viewer Evidence bullets (plus the `validate --strict` add and the protected-delivery release-tail pointer), bumped `@version` to `0.3.1`. `files:` whitelist unchanged.
- **Task 4 — Hex honesty + release hardening:** Added `built tarball excludes operator-only priv paths` refuting `priv/viewer_evidence/` and `priv/support_matrix.json`; inserted `mix release.preflight` into `release.yml` between `mix ci` and `mix hex.publish`.
- **Task 5 — ship gate + verification:** Ran the full closure gate green and finalized `72-VERIFICATION.md` with 72-03 must-haves, ship-gate command results, deviation log, and the D-15 operator sequence.

## Ship-gate results

| Command | Result |
|---------|--------|
| `mix ci` | PASS (format, hex.build, compile --warnings-as-errors, test, docs, credo --strict, dialyzer 0 errors) |
| `mix docs.contract` | PASS (8/8 lanes) |
| `mix rendro.viewer_evidence missing` | PASS (exit 0) |
| `mix rendro.viewer_evidence validate` | PASS (exit 0) |
| `mix rendro.viewer_evidence validate --strict` | PASS (exit 0) |
| `mix test test/guardrails/` | PASS (11 tests) |
| `mix test test/docs_contract/` | PASS (1 doctest, 59 tests) |
| `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-preflight-72` | PASS (Overall: PASS, exit 0) |
| `mix release.preflight` (direct) | Phase 2 PASS; Phase 1 Clean-worktree/Exact-tag FAIL by design (no real v0.3.1 tag yet; proof script is the authoritative gate) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `viewer_evidence.ex` record dispatch was broken (pre-existing from 72-02/Phase 71)**
- **Found during:** Task 5 (`mix ci` dialyzer)
- **Issue:** `parse_args!` returned a 4-tuple `{:record, json?, false, opts}` for the `record` subcommand, but `normalize_parsed/1` only matched the 3-tuple `{:record, json?, record_opts}`. The `record` path would raise `FunctionClauseError` at runtime; dialyzer flagged `:record` in `run/2`, the `{:record, ...}` clause, and `run_record/2` as unreachable.
- **Fix:** Changed the `record` branch of `parse_args!` to return the 3-tuple form matching `normalize_parsed`.
- **Files modified:** `lib/mix/tasks/rendro/viewer_evidence.ex`
- **Commit:** `3beaf1a`

**2. [Rule 3 - Blocking] Prior-wave test file unformatted**
- **Found during:** Task 5 (`mix ci` format check)
- **Issue:** `test/mix/tasks/viewer_evidence_task_test.exs` was committed unformatted in 72-02 (`7adeae7`); `mix format --check-formatted` (inside `mix ci`/preflight) failed.
- **Fix:** `mix format` on that file only.
- **Files modified:** `test/mix/tasks/viewer_evidence_task_test.exs`
- **Commit:** `3beaf1a`

**3. [Rule 1 - Bug] Preflight test stub tags stale after version bump**
- **Found during:** Task 5 (preflight proof Phase 2 CI run)
- **Issue:** `release_preflight_test.exs` stubbed `git describe --exact-match` as `v0.3.0`; after the Task-3 bump to `0.3.1`, `check_exact_tag` compared against `v0.3.1`, so Phase 1 failed and Phase 2 assertions never ran inside the nested `mix ci` of the preflight proof worktree.
- **Fix:** Updated the two stub responses needing Phase 1 to pass from `v0.3.0` to `v0.3.1`; left the explicit-`0.2.0`-context changelog-tail test unchanged.
- **Files modified:** `test/mix/tasks/release_preflight_test.exs`
- **Commit:** `68f56c5`

## Known Stubs

None. No placeholder/empty-data stubs introduced; the `missing` command reporting "0 cells" is correct terminal state (zero `unverified` cells), not a stub.

## Out-of-scope items left untouched (per plan)

- `guides/user_flows_and_jtbd.md` — untracked stray, left untracked and uncommitted.
- `priv/support_matrix.json` cell statuses — unchanged.
- `mix.exs` `package files:` whitelist — unchanged (D-29).
- No `v0.3.1` git tag created — operator step (D-15).

## Remaining gap (accepted)

- Live GitHub branch-protection audit (`mix run scripts/audit_branch_protection.exs`) requires `GITHUB_TOKEN`, unset in this environment. Documented in `72-VERIFICATION.md` as an operator action before the `v0.3.1` tag push. All in-repo automated ship-gate checks are green.

## Self-Check: PASSED

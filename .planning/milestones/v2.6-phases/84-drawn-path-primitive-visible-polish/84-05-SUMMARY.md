---
phase: 84-drawn-path-primitive-visible-polish
plan: "05"
subsystem: docs-contract
tags: [manifests, support-matrix, public-api, path-primitive, docs-contract]
dependency_graph:
  requires: [84-03, 84-04]
  provides: [path_primitive support-matrix rows, regenerated public_api.json manifest]
  affects: [priv/support_matrix.json, priv/public_api.json, guides/api_stability.md]
tech_stack:
  added: []
  patterns: [support-matrix explicit_deferral, docs-contract lane, mix rendro.api.gen regen]
key_files:
  created: []
  modified:
    - priv/support_matrix.json
    - priv/public_api.json
    - guides/api_stability.md
decisions:
  - "path_primitive deferral entries (transforms_cm, clipping_W, gradients) follow viewer_evidence_claims_test contract requiring api_stability.md mirrors — Rule 2 auto-fix applied"
  - "Rendro.Path was already in @public_modules in api.gen.ex from Plan 01; only manifest regen needed"
  - "ROADMAP.md D-05 correction and plan list update were already applied by prior waves — confirmed present in worktree, no changes needed (worktree-mode artifact, deferred section below)"
requirements-completed:
  - PATH-04
metrics:
  duration: "~10 minutes"
  completed: "2026-06-10"
  tasks_completed: 2
  files_modified: 3
---

# Phase 84 Plan 05: Manifests — support_matrix path_primitive rows + public_api regen + ROADMAP D-05 fix Summary

docs-contract closure for Phase 84: path_primitive section with three explicit_deferral rows added to support_matrix.json, public_api.json regenerated to include Rendro.Path stable tier + Rendro.path/2 function, api_stability.md deferral mirrors added; all 1070 tests GREEN.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | support_matrix.json path_primitive section + api.gen.ex @public_modules + manifest regen | 96ca277 | priv/support_matrix.json, priv/public_api.json, guides/api_stability.md |
| 2 | ROADMAP.md D-05 correction + Phase 84 plan list + full suite gate | (no commit — changes already present; full test suite verified GREEN) | .planning/ROADMAP.md (deferred to orchestrator) |

## Decisions Made

1. **Rendro.Path already in @public_modules** — `api.gen.ex` line 63 already had `Rendro.Path` from Plan 01. No modification to `api.gen.ex` was needed; only manifest regeneration via `mix rendro.api.gen` was required to make `public_api.json` byte-match the generated output.

2. **guides/api_stability.md update required** — The `viewer_evidence_claims_test.exs` test recursively collects ALL `evidence_deferred` strings from the full support matrix (not just viewer rows) and asserts each first-40-char substring appears in `api_stability.md`. The `path_primitive.explicit_deferrals` objects match the same node structure, so they were collected too. Applied Rule 2 (missing critical functionality for test correctness) and added the three path_primitive deferral mirrors to `api_stability.md`.

3. **ROADMAP.md state confirmed** — Both the D-05 correction (`{0, 0, 0}` not `"#000"`) and the 5-plan wave structure were already present in the worktree's ROADMAP.md, applied by the orchestrator during prior waves. No changes were needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] api_stability.md deferral mirrors for path_primitive**
- **Found during:** Task 1 verification (`mix test` full suite)
- **Issue:** `viewer_evidence_claims_test.exs` "api stability guide contains deferral reason substrings from matrix" test failed — it collects ALL `evidence_deferred` strings from the matrix recursively, including the new `path_primitive.explicit_deferrals` entries. The test checks that the first 40 chars of each appear in `guides/api_stability.md`. Missing: "Clipping paths (W/W* operators) deferred", "Affine transforms (cm operator) deferred", "Gradients (PDF shading dictionaries) def".
- **Fix:** Added three `path_primitive` deferral entries to the mirrors section in `guides/api_stability.md` (lines after `text_shaping × thai`).
- **Files modified:** `guides/api_stability.md`
- **Commit:** 96ca277 (included in Task 1 commit)

## Deferred to Orchestrator

### ROADMAP.md edits (worktree mode — orchestrator-owned file)

Both ROADMAP.md changes specified in Task 2 were already applied in the worktree (by the orchestrator or prior wave commits). No diff is needed. Confirmed state in `.planning/ROADMAP.md`:

**Edit 1 — D-05 correction (ALREADY DONE):**
- Old: `stroke: %{color: "#000", width: 1.0}`
- New (current): `stroke: %{color: {0, 0, 0}, width: 1.0}`
- Location: Phase 84 success criterion 1 (line 86)
- Verification: `grep '"#000"' .planning/ROADMAP.md` returns no match

**Edit 2 — Plan list update (ALREADY DONE):**
- Current ROADMAP.md Phase 84 "Plans" section already shows: `**Plans**: 5 plans` with Wave 1-4 structure and all five plan entries (84-01 through 84-05).
- Location: Lines 91-110 of ROADMAP.md

**Orchestrator action required:** None — ROADMAP.md is already correct. No further edits needed post-merge.

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/docs_contract/path_claims_test.exs` | 2 tests, 0 failures |
| `mix test test/docs_contract/public_api_contract_test.exs` | 6 tests, 0 failures |
| `grep '"path_primitive"' priv/support_matrix.json` | Match found |
| `grep '"Elixir.Rendro.Path"' priv/public_api.json` | Match found |
| `grep '0, 0, 0' .planning/ROADMAP.md \| grep stroke` | Corrected line found |
| `grep '"#000"' .planning/ROADMAP.md` | No match (GOOD) |
| `mix test` (full suite) | 1070 tests, 0 failures (10 excluded) |
| PATH quick tests (path, table_borders, certificate, deterministic) | 82 tests, 0 failures |

## Requirements Satisfied

- **PATH-04:** Terminal `priv/support_matrix.json` rows for path_primitive with explicit_deferral entries for transforms, clipping, and gradients per D-23.
- **PATH-01, PATH-02, PATH-03:** Verified GREEN via full test suite gate.

## Known Stubs

None — all plan goals achieved. The `path_primitive` section is fully populated with correct data; no placeholder text or hardcoded empty values.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

## Self-Check: PASSED

Files created/modified:
- `priv/support_matrix.json` — FOUND (verified contains "path_primitive")
- `priv/public_api.json` — FOUND (verified contains "Elixir.Rendro.Path")
- `guides/api_stability.md` — FOUND (verified contains path_primitive deferral substrings)

Commits:
- `96ca277` — FOUND (`git log --oneline -1` confirms)

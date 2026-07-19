---
phase: 117-edge-case-stress-matrix
plan: 07
subsystem: quality-manifest
tags: [rubric, stress-exemption, json-schema, contract-test, disjointness, elixir]

# Dependency graph
requires:
  - phase: 117-04
    provides: "Rendro.EdgeMatrixTest.stress_fixture_ids/0 — public 62-element MapSet of 'family/dimension' stress-fixture IDs, imported here as the single source of truth for the D-15 disjointness guard"
provides:
  - "priv/quality/rubric_scores.json stress_exemption block — the one explicit, reviewer-visible EDGE-03 beauty-gate exemption (exempt: true + reasoned rationale)"
  - "priv/schemas/rubric_scores.schema.json stress_exemption definition + root-required enforcement — deleting the exemption now fails schema validation (hard anti-silent-loss)"
  - "4 D-15 fail-loud-in-both-directions contract guards in rubric_manifest_contract_test.exs proving exemption presence, loophole closure, disjointness, and non-vacuity"
affects: [118-real-demonstration-scores]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single top-level exemption block (D-13) rather than N per-fixture entries — one reasoned reviewer-visible statement, keeping the scores array free of stress noise for Phase 118"
    - "Dual-layer enforcement (D-15): JSON Schema root-required (structural, fails JSV.validate/2) AND a contract-test assertion (semantic, fails mix test) — neither can be silently removed without a red-CI diff"
    - "Code.require_file/2 cross-test-file import mirroring test/scripts/release_preflight_proof_test.exs:1 — resolves Rendro.EdgeMatrixTest in isolated single-file runs since .exs test files are off elixirc_paths(:test)"

key-files:
  created: []
  modified:
    - priv/quality/rubric_scores.json
    - priv/schemas/rubric_scores.schema.json
    - test/docs_contract/rubric_manifest_contract_test.exs

key-decisions:
  - "Added exactly ONE top-level stress_exemption block (D-13), not per-fixture entries — the exemption is a single reasoned, reviewer-visible fact; the scores array stays empty and stress-noise-free for Phase 118."
  - "Appended stress_exemption to the schema root required array (D-14) so the manifest cannot validate if the block is ever deleted — closing the silent-loss gap structurally, not just via a test."
  - "Left the pre-existing per-entry $defs.score_entry.stress_exempt field untouched and repurposed it as the D-15(ii) loophole tripwire — the contract test forbids any real scores entry from setting it true to dodge the beauty gate."

requirements-completed: [EDGE-03]

coverage:
  - id: M1
    description: "The manifest carries exactly one top-level stress_exemption block (exempt: true, non-empty reason) — D-13/D-15i"
    requirement: "EDGE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#D-15i: stress_exemption is present, exempt, and carries a non-empty reason"
        status: pass
    human_judgment: false
  - id: M2
    description: "Deleting stress_exemption fails schema validation — the schema root required array includes it (D-14)"
    requirement: "EDGE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#schema validation: checked-in manifest validates against rubric_scores.schema.json"
        status: pass
    human_judgment: false
  - id: M3
    description: "No scores entry may set stress_exempt to bypass the beauty gate — loophole tripwire (D-15ii)"
    requirement: "EDGE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#D-15ii: no scores entry may set stress_exempt to dodge the beauty gate"
        status: pass
    human_judgment: false
  - id: M4
    description: "The stress-fixture ID set (62, imported from 117-04) is disjoint from and non-vacuous relative to the scores demo_ids (D-15iii/iv)"
    requirement: "EDGE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#D-15iii disjoint + D-15iv teeth guard (62 cells)"
        status: pass
    human_judgment: false

# Metrics
duration: ~4min
completed: 2026-07-19
status: complete
---

# Phase 117 Plan 07: Rubric Beauty-Gate Stress Exemption Summary

**Recorded EDGE-03's rubric beauty-gate exemption as a single explicit, schema-enforced `stress_exemption` block (D-13/D-14) and added 4 D-15 fail-loud-in-both-directions contract guards proving the exemption is present, that no real demo entry can hijack the per-entry `stress_exempt` loophole, and that the 62-entry stress-fixture ID set (imported from 117-04 as the single source of truth) is provably disjoint from — and non-vacuous relative to — Phase 118's future `scores` entries. Zero `lib/` changes.**

## Performance
- **Duration:** ~4 min
- **Completed:** 2026-07-19
- **Tasks:** 2 of 2
- **Files modified:** 3 (2 priv config/schema + 1 test)

## Accomplishments
- **D-13:** Added ONE top-level `stress_exemption` object to `priv/quality/rubric_scores.json` (sibling of `thresholds`): `{exempt: true, reason: <robustness-not-aesthetics rationale>, fixture_source: "test/rendro/edge_matrix_test.exs", gate_scope: "scores"}`. No per-fixture noise entries — the `scores` array stays empty for Phase 118.
- **D-14:** Extended `priv/schemas/rubric_scores.schema.json` — appended `"stress_exemption"` to the ROOT `required` array (deleting the block now fails `JSV.validate/2`) and added `properties.stress_exemption` (`required: ["exempt","reason"]`, `exempt` const `true`, `reason` non-empty string). Left the per-entry `$defs.score_entry.stress_exempt` field untouched as the D-15(ii) loophole tripwire. Manifest still validates against the updated schema.
- **D-15 (4 guards):** Extended `test/docs_contract/rubric_manifest_contract_test.exs`:
  - (i) `stress_exemption.exempt == true` + non-empty `reason`.
  - (ii) no `scores` entry sets `stress_exempt` (loophole tripwire; passes vacuously today, guards Phase 118).
  - (iii) `MapSet.disjoint?` between `Rendro.EdgeMatrixTest.stress_fixture_ids()` and the `scores` demo_id set.
  - (iv) teeth guard: `MapSet.size(...) == 62` so disjointness can't pass vacuously.
- Added `Code.require_file("test/rendro/edge_matrix_test.exs", File.cwd!())` above `defmodule`, mirroring `test/scripts/release_preflight_proof_test.exs:1`, so `stress_fixture_ids/0` resolves in isolated single-file runs.

## Task Commits
1. **Task 1: stress_exemption manifest + schema edits (D-13/D-14)** — `f5d1d52` (feat)
2. **Task 2: 4 D-15 fail-loud contract-test guards (both directions)** — `4cf262e` (test)

Task 2 was `tdd="true"`; for this test-authoring plan the tests ARE the artifact. Task 1 established the manifest/schema truth first, then Task 2's guards were run green before commit. (Plan-level TDD mode is off in config — `tdd_mode: false` — so the strict RED-before-implementation gate did not apply.)

## Files Created/Modified
- `priv/quality/rubric_scores.json` — new top-level `stress_exemption` block.
- `priv/schemas/rubric_scores.schema.json` — `stress_exemption` in root `required` + new `properties.stress_exemption` definition; per-entry `stress_exempt` field left as tripwire.
- `test/docs_contract/rubric_manifest_contract_test.exs` — `Code.require_file/2` at top + 4 new D-15 tests.

## Verification
`mix test test/docs_contract/rubric_manifest_contract_test.exs` run in isolation: **72 tests, 0 failures** (7 in this file = 3 existing + 4 new D-15 guards; plus 65 from `Rendro.EdgeMatrixTest` registered via the `Code.require_file/2` import — expected and documented, mirroring the existing precedent file's behavior). The isolated single-file run proves the cross-file dependency resolves without the rest of the suite.

## Decisions Made
See `key-decisions` frontmatter. Load-bearing: one reasoned exemption block over per-fixture noise (D-13); schema root-required enforcement as a structural anti-silent-loss layer independent of the test (D-14); the per-entry `stress_exempt` field repurposed as a loophole tripwire rather than a legitimate escape hatch (D-15ii).

## Deviations from Plan
None — plan executed exactly as written. `stress_fixture_ids/0` from 117-04 matched its documented 62-element contract; the manifest validated against the updated schema on the first attempt and all 4 D-15 guards passed green immediately.

## Issues Encountered
None affecting the artifact. The `state record-metric` helper rejected positional args and was recorded via its flag form (`--phase/--plan/--duration/--tasks/--files`); no impact on the plan output.

## User Setup Required
None — no external service configuration required.

## Known Stubs
None. The `scores` array is intentionally empty this phase (Phase 118 appends real family × domain demonstration scores); this is a documented sequencing decision, not a stub. The D-15(ii) loophole guard and D-15(iii/iv) disjointness guards exist precisely to protect those future entries.

## Threat Flags
None. Both `priv/` files are repo-local, non-`lib/`, non-shipped config/schema (confirmed excluded from the Hex tarball); the test file is test-only. No new runtime surface, no untrusted input. The two enforcement layers (schema root-required + contract-test assertion) fulfill T-117-07-01 (silent-deletion) and T-117-07-02 (quality-gate-bypass loophole) from the plan's threat register.

## Self-Check: PASSED
- `priv/quality/rubric_scores.json` — FOUND (stress_exemption present)
- `priv/schemas/rubric_scores.schema.json` — FOUND (stress_exemption in root required + properties)
- `test/docs_contract/rubric_manifest_contract_test.exs` — FOUND (require_file + 4 D-15 tests)
- Commit `f5d1d52` — FOUND
- Commit `4cf262e` — FOUND
- No file deletions in either task commit
- `mix test test/docs_contract/rubric_manifest_contract_test.exs` (isolated) — 72 tests, 0 failures

---
*Phase: 117-edge-case-stress-matrix*
*Completed: 2026-07-19*

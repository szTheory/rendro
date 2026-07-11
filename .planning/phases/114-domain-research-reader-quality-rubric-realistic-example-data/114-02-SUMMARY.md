---
phase: 114
plan: 02
subsystem: schemas
tags: [json-schema, contracts, rubric, examples, repo-only]
requires:
  - priv/schemas/support_matrix.schema.json (header/$defs convention mirrored)
provides:
  - priv/schemas/examples.schema.json (EXL-03 fixture contract, S4 brand seam)
  - priv/schemas/rubric_scores.schema.json (RUB-03 manifest contract, S5 appendable seam)
affects:
  - test/docs_contract/examples_schema_contract_test.exs (Plan 114-03 consumer)
  - test/docs_contract/rubric_manifest_contract_test.exs (Plan 114-06 consumer)
tech_stack:
  added: []
  patterns:
    - JSON Schema draft 2020-12 (mirrors existing repo schemas exactly, no new lib)
    - Money-as-decimal-string via shared $defs/money_string (never JSON float)
key_files:
  created:
    - priv/schemas/examples.schema.json
    - priv/schemas/rubric_scores.schema.json
  modified: []
decisions:
  - Money fields reference shared $defs/money_string (type string, pattern ^-?[0-9]+\.[0-9]{2}$) — Pitfall 6 trap avoided.
  - rubric thresholds fixed as const 5 (hierarchy_min) and integer minimum 4 (core_min) so 114-06 arithmetic is structurally enforced.
  - stress_exempt pre-declared as optional score_entry field — forward-compat seam for Phase 117 EDGE-03 without a non-additive schema change.
metrics:
  duration: 3min
  completed: 2026-07-11
status: complete
---

# Phase 114 Plan 02: Repo-Only JSON Schema Contracts Summary

Two repo-only draft-2020-12 JSON Schemas that back this phase's structural contracts: `examples.schema.json` validates every `priv/examples/` fixture (forbidding JSON-float money via a shared decimal-string `$defs`, reserving the S4 optional `brand`/`logo` slot) and `rubric_scores.schema.json` validates the appendable rubric manifest (exactly 6 dimensions, 2 gates, and the RUB-03 hierarchy=5/core>=4 threshold constants).

## What Was Built

### Task 1 (previously committed — `3468f38`)
`priv/schemas/examples.schema.json` — structural contract for `priv/examples/{domain}/{business}/{family}.json`. Requires `fixture_id`, `issuer`/`customer` (`$defs/party`), `invoice` (ISO-8601 date/due_date), and `items`. All money fields (`items[].price`, optional `totals.*`) reference `$defs/money_string` (string + `^-?[0-9]+\.[0-9]{2}$`). Optional top-level `brand.logo` (`["string","null"]`) is the S4/EXL-06 seam. Top-level `additionalProperties: true`.

### Task 2 (this session — `4be5e28`)
`priv/schemas/rubric_scores.schema.json` — structural contract for `priv/quality/rubric_scores.json`. Top-level requires `schema_version` (const `1`), `dimensions`, `gates`, `thresholds`, `scores`:
- `dimensions`: array `minItems`/`maxItems` 6, each item's `id` enumerated to the 6 canonical dimensions, plus non-empty `label` and `anchors` object requiring keys `"1"`,`"3"`,`"4"`,`"5"`.
- `gates`: array `minItems`/`maxItems` 2, each `id` enumerated to `reading_order`/`print_safety`, plus `label` + `description`.
- `thresholds`: requires `hierarchy_dimension` (const `content_hierarchy`), `hierarchy_min` (const `5`), `core_min` (integer 4–5).
- `scores`: array of `$defs/score_entry` (empty at end of this phase; populated by Phase 118). `score_entry` requires `demo_id`/`domain`/`family`, `dimension_scores` (all 6 ids, ints 1–5, `additionalProperties: false`), `gate_results` (both gate ids booleans, `additionalProperties: false`), `passed`, `recorded_at`, plus optional `stress_exempt` (Phase 117 seam).

## Verification

| Check | Result |
|-------|--------|
| `JSV.build!/1` smoke (rubric schema) | `SCHEMA_OK` |
| dimensions/gates grep (dimensions >= 6) | 19 |
| gate ids grep (>= 2) | 4 |
| Task 1 schema previously verified | `SCHEMA_OK` (committed 3468f38) |

## Deviations from Plan

None — plan executed exactly as written. Task 1 was completed and committed in a prior session; this session executed Task 2 only.

## Commits

- `3468f38` feat(114-02): add examples.schema.json fixture contract (Task 1, prior session)
- `4be5e28` feat(114-02): add rubric_scores.schema.json manifest contract (Task 2)

## Self-Check: PASSED
- FOUND: priv/schemas/examples.schema.json
- FOUND: priv/schemas/rubric_scores.schema.json
- FOUND commit: 3468f38
- FOUND commit: 4be5e28

---
phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane
plan: 01
subsystem: testing
tags: [jsv, json-schema, viewer-evidence, yaml_elixir, validation]

requires: []
provides:
  - Draft 2020-12 JSON Schema contracts for support matrix viewer rows and evidence frontmatter
  - Shared Rendro.ViewerEvidence.* validation modules (Matrix, Frontmatter, Lint, Validator)
  - priv/viewer_evidence/ scaffolding with canonical _template.md
affects: [68-02, 68-03]

tech-stack:
  added: [jsv ~> 0.18, yaml_elixir ~> 2.12]
  patterns:
    - Two-tier validation (Tier A JSV structural, Tier B Elixir promotion-complete)
    - Legacy supported rows emit warnings not errors in run_full/3 until Phase 70

key-files:
  created:
    - priv/schemas/support_matrix.schema.json
    - priv/schemas/viewer_evidence.schema.json
    - lib/rendro/viewer_evidence/matrix.ex
    - lib/rendro/viewer_evidence/frontmatter.ex
    - lib/rendro/viewer_evidence/lint.ex
    - lib/rendro/viewer_evidence/validator.ex
    - priv/viewer_evidence/_template.md
    - test/rendro/viewer_evidence/validator_test.exs
    - test/support/viewer_evidence/fixtures/
  modified:
    - mix.exs

key-decisions:
  - "Tier A/B split: JSON Schema accepts legacy supported rows without evidence; Tier B enforced in Elixir + fixtures until Phase 70"
  - "Use yaml_elixir (not ymlr) for frontmatter decode per Hex capability audit"
  - "_template.md skips path alignment; canonical path rule applies to promoted evidence files only"

requirements-completed: [MATRIX-01, MATRIX-02, MATRIX-03, GUARDRAIL-03]

duration: 25min
completed: 2026-05-28
---

# Phase 68 Plan 01: Viewer Evidence Schema Foundation Summary

**Shared JSV + Elixir validator infrastructure with two-tier matrix validation, lint modules, and evidence scaffolding — production matrix unchanged and Tier-A valid.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-28T18:33:24Z
- **Completed:** 2026-05-28T19:00:00Z
- **Tasks:** 5 completed
- **Files modified:** 15

## Accomplishments

- Added dev/test-only `jsv` and `yaml_elixir` dependencies with Draft 2020-12 schemas documenting `explicit_deferral`, promotion keys, and 65536-byte evidence budget.
- Implemented matrix walker enumerating all 26 viewer cells across 8 maps with evidence-path surface segments (`signed_artifact`, `signature_widget`, etc.).
- Built shared validation core: Tier-A JSV structural pass on unchanged production matrix; Tier-B promotion-complete rules with fixture-driven negative cases; body/deferral lint; orphan scan; staleness warnings.
- Shipped `priv/viewer_evidence/_template.md` with valid schema_version 1 frontmatter excluded from orphan detection.

## Task Commits

Each task was committed atomically:

1. **Task 1: Dev/test deps and JSON Schema contracts** - `e9f04e8` (feat)
2. **Task 2: Matrix walker and surface mapping** - `7ca44a4` (feat)
3. **Task 3: Frontmatter parser and lint module** - `91d5938` (feat)
4. **Task 4: Validator core (Tier A + Tier B)** - `fa7aa3a` (feat)
5. **Task 5: Evidence directory scaffolding** - `6490f4b` (feat)

## Files Created/Modified

- `priv/schemas/support_matrix.schema.json` - `$defs/viewer_row` with status enum and conditional branches
- `priv/schemas/viewer_evidence.schema.json` - Frontmatter schema_version 1 contract
- `lib/rendro/viewer_evidence/matrix.ex` - 26-cell walker with surface mapping table
- `lib/rendro/viewer_evidence/frontmatter.ex` - YAML fence split + path alignment
- `lib/rendro/viewer_evidence/lint.ex` - Body, deferral, and byte-budget lint
- `lib/rendro/viewer_evidence/validator.ex` - JSV + cross-artifact orchestration entry point
- `priv/viewer_evidence/_template.md` - Canonical evidence template
- `test/rendro/viewer_evidence/validator_test.exs` - Tagged tests: schema_contract, matrix_walker, lint, validator, template

## Verification

```bash
mix deps.get
mix test test/rendro/viewer_evidence/
# 28 tests, 0 failures

git diff priv/support_matrix.json
# (empty — unchanged)
```

Production matrix: **5 supported**, **21 unverified**, **0 explicit_deferral**, **26 cells**. `Validator.run_full/3` returns `{:ok, warnings}` with 5 legacy-supported promotion warnings.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- All 5 tasks committed atomically with `feat(68-01): task N` messages
- `mix test test/rendro/viewer_evidence/` — 28 tests, 0 failures
- `git diff priv/support_matrix.json` — empty
- Tier-A JSV validates production matrix unchanged
- Tier-B negative fixtures fail in isolated tests

## Next Steps

Ready for **68-02** (Mix task `rendro.viewer_evidence` + docs-contract lane).

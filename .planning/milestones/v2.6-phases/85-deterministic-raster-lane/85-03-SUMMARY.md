---
phase: 85-deterministic-raster-lane
plan: "03"
subsystem: testing
tags: [elixir, json-schema, pdfium, raster, docs-contract, viewer-evidence]

requires:
  - phase: 85-deterministic-raster-lane plan 01
    provides: raster_claims_test.exs with 3 @tag :skip RED stubs for Plan 03

provides:
  - viewer_kind enum in priv/schemas/support_matrix.schema.json extended with "pdfium-render"
  - "@viewer_kinds sigil in lib/rendro/viewer_evidence/validator.ex extended with pdfium-render (atomic sync)"
  - "priv/support_matrix.json has top-level raster section with renderer, capabilities, boundaries, and evidence"
  - raster_claims_test.exs test 1 un-skipped and green (RAST-03d)
  - raster_claims_test.exs test 5 updated to use parsed JSON (regex broke when raster section added pdfium-render)

affects:
  - 85-04 (guardrails and verify_docs — tests 4 and 6 of raster_claims_test still @tag :skip)
  - 86-self-proving-launch-artifacts (depends on raster lane being complete)

tech-stack:
  added: []
  patterns:
    - "Atomic dual-schema sync: schema enum and @viewer_kinds sigil must be updated in the same commit (Pitfall 1 enforcement)"
    - "Top-level support_matrix.json section for non-viewer evidence (raster section at root level, not inside viewer_map)"
    - "GUI-viewer boundary assertion via parsed JSON (not regex) when pdfium-render appears in non-viewer parts of the matrix"

key-files:
  created: []
  modified:
    - priv/schemas/support_matrix.schema.json
    - lib/rendro/viewer_evidence/validator.ex
    - priv/support_matrix.json
    - test/docs_contract/raster_claims_test.exs

key-decisions:
  - "Atomic commit for schema enum + @viewer_kinds: both files land in one commit; one without the other would fail mix test (Pitfall 1 enforced)"
  - "Raster section placed at root of support_matrix.json, not inside any viewer_map — schema additionalProperties: true at root allows new top-level keys; viewer_map would trigger promotion-complete failures"
  - "evidence.viewer_kind: pdfium-render in the raster section records what the pdfium engine renders; does not claim GUI-viewer visual fidelity (boundary disclaimer in evidence.notes)"
  - "Test 5 GUI-viewer boundary assertion rewritten to use parsed JSON instead of raw-text regex — the regex approach broke once pdfium-render appeared in the raster section's evidence block"

patterns-established:
  - "Pattern: Non-viewer evidence sections at root of support_matrix.json reference viewer_kind in their evidence sub-object (not in a viewer_map viewer_row)"
  - "Pattern: GUI-viewer boundary assertions should use parsed JSON to check viewer_map rows, not raw-text regex that can match across sections"

requirements-completed:
  - RAST-03

duration: 8min
completed: 2026-06-11
---

# Phase 85 Plan 03: Atomic Dual-Schema Sync & Raster Section Summary

**viewer_kind enum extended with pdfium-render in JSON schema and @viewer_kinds sigil (atomic), plus raster top-level section added to support_matrix.json with GUI-viewer boundary declarations**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-11T00:11:00Z
- **Completed:** 2026-06-11T00:19:16Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Extended `priv/schemas/support_matrix.schema.json` viewer_kind enum to include `"pdfium-render"` — JSV validation now accepts pdfium-render as a valid viewer_kind for any viewer_row
- Extended `lib/rendro/viewer_evidence/validator.ex` `@viewer_kinds` sigil to include `pdfium-render` — both edits land atomically in one commit per Pitfall 1 constraint
- Added `"raster"` top-level key to `priv/support_matrix.json` with renderer, capabilities (pdf_to_png, dpi_configurable, page_range, byte_deterministic_on_pinned_container), boundaries (gui_viewer_equivalence, adobe_acrobat_visual_fidelity_claim, apple_preview_visual_fidelity_claim all unsupported), and evidence with viewer_kind: "pdfium-render"
- Un-skipped `raster_claims_test.exs` test 1 — now passes (RAST-03d green)
- Fixed test 5 GUI-viewer boundary assertion — rewrote from regex to parsed JSON approach (Rule 1 auto-fix)

## Task Commits

Each task was committed atomically:

1. **Task 1: Atomic dual-schema sync — add pdfium-render to schema enum and @viewer_kinds** - `b43bef3` (feat)
2. **Task 2: Add raster top-level section to support_matrix.json + un-skip test 1** - `0cc172b` (feat)

## Files Created/Modified

- `priv/schemas/support_matrix.schema.json` - viewer_kind enum extended: `["manual", "pdfium-cli", "pdfjs-dist", "pdfium-render"]`
- `lib/rendro/viewer_evidence/validator.ex` - `@viewer_kinds ~w(manual pdfium-cli pdfjs-dist pdfium-render)`
- `priv/support_matrix.json` - Added `"raster"` top-level section (after `"unsupported"` array)
- `test/docs_contract/raster_claims_test.exs` - Un-skipped test 1; fixed test 5 to use parsed JSON

## Decisions Made

- **Atomic commit for schema sync:** Both `priv/schemas/support_matrix.schema.json` and `lib/rendro/viewer_evidence/validator.ex` updated in the same commit — one without the other causes `mix test` failures (viewer_evidence_claims_test.exs JSV validation gate).
- **Raster section at root level:** The `"raster"` key is placed at the top level of `support_matrix.json`, not under `forms`, `signing`, or any other section. The schema has `"additionalProperties": true` at root, which permits this. Placing it inside a viewer_map would falsely trigger promotion-complete validation checks.
- **GUI-viewer boundary assertion approach:** Test 5 needed to be rewritten from a raw-text regex to parsed JSON because the regex `~r/"forms".*?"viewer_kind"\s*:\s*"pdfium-render"/s` falsely matched once the raster section's `evidence.viewer_kind` became `"pdfium-render"`. Parsed JSON approach is more precise and durable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test 5 GUI-viewer boundary regex matched raster section's pdfium-render value**
- **Found during:** Task 2 (adding raster section to support_matrix.json)
- **Issue:** The existing test `refute matrix =~ ~r/"forms".*?"viewer_kind"\s*:\s*"pdfium-render"/s` falsely matched after adding the raster section — the regex spans from `"forms"` (near the top of the file) to `"pdfium-render"` in `raster.evidence.viewer_kind` (near the bottom). With the `s` dotall flag, `.*?` matched the entire intervening file content.
- **Fix:** Rewrote the test to parse the JSON and iterate over `viewer_map` viewer rows directly for the sections of concern (forms, signing, signing_preparation, embedded_files, links, protection). The assertion is now semantically correct: it checks the viewer_row objects inside viewer_map sections, not arbitrary text matches across the whole file.
- **Files modified:** test/docs_contract/raster_claims_test.exs
- **Verification:** `mix test test/docs_contract/raster_claims_test.exs` exits 0 (4 passing, 2 skipped)
- **Committed in:** 0cc172b (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — Bug: test regex produced false positive after raster section added pdfium-render)
**Impact on plan:** Single-function rewrite in one test; no scope change. All Plan 03 success criteria satisfied.

## Issues Encountered

None beyond the test 5 regex deviation documented above.

## Known Stubs

The following stubs remain @tag :skip pending Plan 04:

| File | Stub | Plan to un-skip |
|------|------|-----------------|
| `test/docs_contract/raster_claims_test.exs:37` | `@tag :skip "advisory lane is in advisory_contexts"` | Plan 04 (after guardrails JSON updated) |
| `test/docs_contract/raster_claims_test.exs:66` | `@tag :skip "docs verification script includes the raster claims lane"` | Plan 04 (after verify_docs.exs updated) |

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The `raster.evidence.viewer_kind` value in support_matrix.json is `"pdfium-render"`, not a GUI-viewer claim. The GUI-viewer boundary assertions in raster.boundaries confirm `unsupported` for all three GUI-viewer fidelity claims (T-85-08 mitigation complete). T-85-10 mitigation enforced by atomic commit.

## Next Phase Readiness

- Plan 04 can proceed: raster_claims_test.exs tests 4 and 6 remain @tag :skip awaiting guardrails JSON and verify_docs.exs updates
- Phase 85 Plan 04 is the final plan: adds raster-advisory CI job, guardrails advisory_contexts entry, and verify_docs.exs lane registration

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*

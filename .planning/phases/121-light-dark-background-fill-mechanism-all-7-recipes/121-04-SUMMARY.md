---
phase: 121-light-dark-background-fill-mechanism-all-7-recipes
plan: 04
subsystem: docs
tags: [support-matrix, docs-contract, json-schema, elixir, honesty-gate]

# Dependency graph
requires:
  - phase: 121-01
    provides: Rendro.Theme.dark/1 (colors.background dark-mode role tuple)
provides:
  - "priv/support_matrix.json theming.light/theming.dark rows with a boundaries flat-map (D-09)"
  - "Rendro.Theme.dark/1 @doc boundary sentence: screen-oriented, not recommended for print"
  - "test/docs_contract/theming_claims_test.exs — the honesty-law gate for the dark-mode claim"
affects: [122-typography-type-scale, 123-from-brand-e2e-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Boundary flat-map idiom (mirrors signing_preparation.boundaries) for declaring what a supported* mode does NOT claim"
    - "Docs-contract overclaim tripwire: parse support_matrix.json, flatten to key-path/value leaves, flag any print/PDF-UA/WCAG term paired with a supported* status"

key-files:
  created: [test/docs_contract/theming_claims_test.exs]
  modified: [priv/support_matrix.json, lib/rendro/theme.ex]

key-decisions:
  - "theming section added as a new top-level support_matrix.json key (schema's additionalProperties: true covers it; no viewers sub-key needed since dark is screen-oriented advisory, not a per-GUI-viewer claim)"
  - "Overclaim predicate scans by key-path term match (print/pdf_ua/wcag/accessibility) rather than the literal 4 boundary keys only, so any future theming key with those terms is caught automatically, not just the ones named in this plan"

patterns-established:
  - "theming_claims_test.exs: co-occurrence overclaim tripwire + non-vacuity teeth, direct sibling of accessibility_overclaim_test.exs and raster_claims_test.exs"

requirements-completed: [MODE-03]

coverage:
  - id: D1
    description: "priv/support_matrix.json gains a theming section (light=supported, dark=supported_screen_oriented) with all four boundary keys set to unsupported"
    requirement: "MODE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#priv/support_matrix.json theming rows (D-09)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rendro.Theme.dark/1's @doc carries the explicit screen-oriented, not-for-print boundary sentence"
    requirement: "MODE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#Rendro.Theme.dark/1 @doc boundary sentence (D-09)"
        status: pass
    human_judgment: false
  - id: D3
    description: "theming_claims_test.exs self-defends against overclaim (any print/PDF-UA/WCAG term paired with a supported* status) and against going vacuous"
    requirement: "MODE-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#tripwire integrity (non-vacuity / teeth)"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-27
status: complete
---

# Phase 121 Plan 04: Dark-Mode Boundary Claim Summary

**Support-matrix `theming` rows + `Rendro.Theme.dark/1` @doc boundary sentence + a self-defending `theming_claims_test.exs` overclaim tripwire, so dark mode can never silently imply print/accessibility/WCAG support.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-28T00:26:34Z
- **Completed:** 2026-07-28T00:30:20Z
- **Tasks:** 2 completed
- **Files modified:** 3 (2 modified, 1 created)

## Accomplishments
- `priv/support_matrix.json` now has a `theming` section: `light` = `supported` (`no_background_rect`, `byte_identical_to_v2_10`, `deterministic_output`); `dark` = `supported_screen_oriented` with capabilities plus a `boundaries` flat-map (mirroring the `signing_preparation` idiom) where `print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, and `gui_viewer_visual_fidelity_claim` are all `"unsupported"`.
- `Rendro.Theme.dark/1`'s `@doc` extended with one explicit sentence: "Dark is screen-oriented, not recommended for print: it carries no print, accessibility, PDF/UA, or WCAG contrast support claim."
- New `test/docs_contract/theming_claims_test.exs` (10 tests) binds every boundary claim to proof, traps any future overclaim via a key-path term-match predicate (not just the 4 named keys), and carries non-vacuity teeth mirroring `accessibility_overclaim_test.exs`.
- Verified `guides/theming.md` was not created (deferred to Phase 123 per CONTRACT-02).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the theming support-matrix rows and the dark/1 @doc boundary sentence** - `ac07279` (docs)
2. **Task 2: Author theming_claims_test.exs (boundary assertions + overclaim tripwire + non-vacuity teeth)** - `935b5ad` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified
- `priv/support_matrix.json` - Added the `theming.light` / `theming.dark` rows with the `boundaries` flat-map
- `lib/rendro/theme.ex` - Extended `dark/1`'s `@doc` with the explicit non-print boundary sentence
- `test/docs_contract/theming_claims_test.exs` - New docs-contract lane: boundary-key proof, overclaim tripwire, non-vacuity teeth, `@doc` assertion, `guides/theming.md` absence check

## Decisions Made
- Added `theming` as a new top-level `support_matrix.json` key rather than nesting under an existing section — the schema's `additionalProperties: true` at the top level covers this with no schema edit needed, and `theming` is a genuinely new capability family (not a variant of an existing one).
- The overclaim predicate in `theming_claims_test.exs` matches by term-in-key-path (`print`, `pdf_ua`, `pdf-ua`, `wcag`, `accessibility`) rather than hardcoding only the 4 boundary keys named in the plan, so any future addition to the `theming` section that introduces a print/PDF-UA/WCAG-related key is automatically caught if it is ever set to a `supported*` status — the guard's scope is broader than literally required, in the spirit of the honesty-law gate.
- No `viewers` sub-key was added to `theming.dark` — the schema's `viewer_row` shape (`required: ["status"]`, `additionalProperties: false`, `supported` requiring `evidence`/`recorded_at`/`viewer_kind`) is designed for per-GUI-viewer proof rows, which is out of scope for a screen-oriented mode boundary declaration (D-09 is a claim boundary, not a viewer-evidence claim).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The dark-mode boundary claim is now proof-backed and self-defending; Phase 122 (typography) and Phase 123 (`from_brand/2` E2E + docs) can build on `Rendro.Theme` without reopening the print/accessibility honesty question.
- `guides/theming.md` remains explicitly not created — Phase 123 (CONTRACT-02) owns authoring it, and this plan's test now guards against it being created prematurely with an overclaim.
- No blockers.

---
*Phase: 121-light-dark-background-fill-mechanism-all-7-recipes*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: priv/support_matrix.json
- FOUND: lib/rendro/theme.ex
- FOUND: test/docs_contract/theming_claims_test.exs
- FOUND: .planning/phases/121-light-dark-background-fill-mechanism-all-7-recipes/121-04-SUMMARY.md
- FOUND commit: ac07279 (Task 1)
- FOUND commit: 935b5ad (Task 2)

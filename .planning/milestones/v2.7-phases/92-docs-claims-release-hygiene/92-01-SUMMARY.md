---
phase: 92-docs-claims-release-hygiene
plan: 01
subsystem: docs-release
tags: [hexdocs, support-matrix, docs-contract, github-actions, release]

requires:
  - phase: 89-page-context-primitive
    provides: section-local PAGE context and tokens
  - phase: 90-duplex-running-content
    provides: physical odd/even running content
  - phase: 91-pdf-js-advisory-proof-lane
    provides: pinned PDF.js advisory observations and CI guardrails
provides:
  - Public docs and support rows for v2.7 page context and duplex running content
  - Demand-gated global text-shaping wording across public docs and roadmap contract tests
  - Hex package and HexDocs inclusion for ADOPTION.md and CHANGELOG.md
  - Read-only CI and release workflow permissions
affects: [docs-contract, support-matrix, hex-package, release-workflows, future-milestones]

tech-stack:
  added: []
  patterns:
    - Docs claims backed by support-matrix rows plus docs-contract assertions
    - Advisory evidence vocabulary kept separate from support-matrix promotion
    - Public linked root docs included in both Hex package files and ExDoc extras

key-files:
  created:
    - .planning/phases/92-docs-claims-release-hygiene/92-01-PLAN.md
    - .planning/phases/92-docs-claims-release-hygiene/92-02-PLAN.md
    - .planning/phases/92-docs-claims-release-hygiene/92-03-PLAN.md
    - .planning/phases/92-docs-claims-release-hygiene/92-VALIDATION.md
  modified:
    - guides/page_primitive.md
    - guides/api_stability.md
    - ADOPTION.md
    - README.md
    - guides/comparison.md
    - guides/upgrading_to_1.0.md
    - priv/support_matrix.json
    - mix.exs
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - CHANGELOG.md
    - test/docs_contract/page_primitive_claims_test.exs
    - test/docs_contract/adoption_claims_test.exs
    - test/docs_contract/script_support_claims_test.exs
    - test/docs_contract/pdfjs_advisory_claims_test.exs
    - test/docs_contract/launch_artifacts_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "Use guides/page_primitive.md as the canonical public home for section-local numbering and duplex running content."
  - "Add separate section_page_numbering and duplex_running_content support rows instead of overloading page_numbering."
  - "Include ADOPTION.md and CHANGELOG.md in ExDoc extras so public README/guide links resolve."
  - "Add read-only contents permissions to CI and release workflows without adding release automation."

patterns-established:
  - "Top-level non-viewer support rows can document engine features with surface/status/evidence/recorded_at/capabilities."
  - "Public demand gates should be named by capability, not by milestone labels that may drift."
  - "Package-linked public docs need both package.files inclusion and ExDoc extras when referenced from HexDocs pages."

requirements-completed: [DOC-01, DOC-02, DOC-03]

duration: single session
completed: 2026-06-13
---

# Phase 92: Docs, Claims, Release Hygiene Summary

**v2.7 public claims now match shipped page-context, duplex, and PDF.js advisory behavior, with HexDocs/package and workflow guardrails backing the release posture.**

## Performance

- **Duration:** Single session
- **Started:** 2026-06-13T04:00:00Z
- **Completed:** 2026-06-13T05:13:57Z
- **Tasks:** 5 across 3 plans
- **Files modified:** 21

## Accomplishments

- Expanded `guides/page_primitive.md` with verified examples for `page_numbering: [restart: true]`, `{{section_page_number}}`, `{{section_total_pages}}`, and `only_on: :odd | :even`.
- Added proof-backed support rows for `section_page_numbering` and `duplex_running_content` while keeping PDF.js evidence advisory-only.
- Retitled global text shaping as a conditional demand gate in public docs and tests, removing stale v2.7 shaping language from public-facing claims.
- Included `ADOPTION.md` and `CHANGELOG.md` in package/docs contexts and added read-only `contents: read` permissions to CI and release workflows.

## Task Commits

1. **Planning package:** `f70dde4` docs(92): plan docs claims release hygiene
2. **Plan 92-01: Public claims and support rows:** `8b9d46d` docs(92-01): align public claims and support rows
3. **Plan 92-02: Package, HexDocs, and workflow hygiene:** `a0eb1b1` ci(92-02): harden docs package and workflow hygiene

## Files Created/Modified

- `guides/page_primitive.md` - Canonical section-local numbering and duplex running content guide.
- `priv/support_matrix.json` - Added v2.7 feature rows and removed stale v2.7 shaping deferral wording.
- `ADOPTION.md`, `README.md`, `guides/comparison.md`, `guides/api_stability.md` - Demand-gated shaping and advisory PDF.js wording.
- `mix.exs`, `guides/upgrading_to_1.0.md` - Package/docs inclusion and resolvable public links.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml` - Read-only workflow token permissions.
- `test/docs_contract/*`, `test/guardrails/required_checks_contract_test.exs` - Claim, package, and workflow guardrails.

## Decisions Made

- Separate support rows are clearer than stretching `page_numbering` into a broad catch-all.
- PDF.js observations stay out of the support matrix; docs use advisory vocabulary only.
- `CHANGELOG.md` is an ExDoc extra to resolve public links, but is listed in the ExDoc skip list to avoid introducing new hidden-internal warning noise from historic entries.
- Release hygiene is limited to permission minimization and package/docs correctness; full release automation remains deferred.

## Deviations from Plan

### Auto-fixed Issues

**1. ExDoc warnings from CHANGELOG as a new extra**
- **Found during:** Plan 92-02 docs build
- **Issue:** Adding `CHANGELOG.md` as an ExDoc extra made historical hidden-internal references emit warnings.
- **Fix:** Added `CHANGELOG.md` to `skip_undefined_reference_warnings_on`, matching existing treatment for other docs with intentional internal references.
- **Files modified:** `mix.exs`
- **Verification:** `mix docs` exits 0 and no longer reports missing `ADOPTION.md` or missing `../CHANGELOG.md`.
- **Committed in:** `a0eb1b1`

**Total deviations:** 1 auto-fixed warning-noise issue.
**Impact on plan:** No scope expansion; the fix was necessary for the docs hygiene goal.

## Issues Encountered

- `mix docs` still reports the pre-existing hidden-module/type warnings for `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.PDF.Font.t()`, and `Rendro.Format`. Phase 92 removed the targeted missing-file warnings but did not refactor hidden internal references.
- `mix ci` still prints the existing telemetry local-handler notices, adapter redefinition warnings, and stale Apple Preview viewer-evidence warning. These remain baseline noise and did not fail CI.

## Verification

- `mix test test/docs_contract/page_primitive_claims_test.exs test/docs_contract/adoption_claims_test.exs test/docs_contract/script_support_claims_test.exs test/docs_contract/pdfjs_advisory_claims_test.exs test/docs_contract/launch_artifacts_claims_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/recipes_contract_test.exs` - 67 tests, 0 failures.
- `mix run scripts/verify_docs.exs` - all 21 docs-contract lanes passed.
- `mix hex.build --unpack /tmp/rendro_hex_phase92` - passed; package includes `ADOPTION.md`.
- `mix docs` - passed; targeted missing `ADOPTION.md` and `../CHANGELOG.md` warnings gone.
- `mix ci` - passed; 12 doctests, 4 properties, 1190 tests, 0 failures, Credo no issues, Dialyzer total errors 0.

## Self-Check

Self-Check: PASSED

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

v2.7 requirements are complete and ready for milestone audit/closeout. Global text shaping remains conditional and should only become an active milestone if the `ADOPTION.md` gate triggers.

---
*Phase: 92-docs-claims-release-hygiene*
*Completed: 2026-06-13*

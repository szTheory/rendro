---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 09
subsystem: demo-composition
tags: [rubric, gallery, artifacts, pdfium, gap-closure, SHOW-01]
status: complete

# Dependency graph
requires:
  - phase: 118-08
    provides: "Reworked invoice/statement/receipt/certificate/payslip/ticket compositions (dominant key-facts, faithful money, native-A6 ticket)"
provides:
  - "Re-blessed assets/rendro/artifacts.json + gallery/*.png (7 tiles) from the improved 118-08 compositions, zero drift"
  - "Honest all-passing priv/quality/rubric_scores.json (six entries, every passed:true)"
  - "REQUIREMENTS.md SHOW-01 reconciled to Complete; Phase 118 reaches 4/4"
affects: [milestone-v2.10-closure]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pixel-row glyph-height measurement (ImageMagick `txt:` pixel enumeration + Python row-band grouping) as an objective evidence trail for content_hierarchy scoring, supplementing direct visual inspection"

key-files:
  created: []
  modified:
    - assets/rendro/artifacts.json
    - assets/rendro/gallery/invoice.png
    - assets/rendro/gallery/branded_invoice.png
    - assets/rendro/gallery/statement.png
    - assets/rendro/gallery/receipt_report.png
    - assets/rendro/gallery/certificate.png
    - assets/rendro/gallery/payslip.png
    - assets/rendro/gallery/ticket.png
    - assets/rendro/manual.pdf
    - README.md
    - guides/recipes.md
    - lib/rendro/launch_artifacts.ex
    - priv/quality/rubric_scores.json
    - .planning/REQUIREMENTS.md

key-decisions:
  - "pdfium-cli (v0.11.0 mac-arm64 wasm build, matching priv/pdfium_pin.json's pinned version) was located in a prior session's scratchpad directory on this same host and re-verified via the forms_support_fixture raster-snapshot determinism gate (test/rendro/adapters/pdfium_raster_snapshot_test.exs:31) before use — passed, proving byte-identical rasterization to the CI-blessed reference. This mirrors 118-05's documented precedent (native mac-arm64 wasm module execution is host-independent and deterministic), so the container-gated regen was NOT deferred this round; it ran locally with the same pinned binary version."
  - "Fixed a stale @expected_gallery_dimensions['ticket'] constant (794x1123 A4 placeholder) to {397, 560}, the ticket's actual native-A6 gallery-preview dimensions now that 118-08 landed the real page-size change — the code's own comment had explicitly flagged this as the anticipated correction once `.gen` ran with the improved compositions. Rule 1 (bug: stale constant blocking correct verification)."
  - "All six demos re-scored using direct visual inspection of the new gallery PNGs PLUS objective pixel-row glyph-height measurement (via ImageMagick + Python) for the content_hierarchy dimension specifically, since that dimension's 4-vs-5 threshold is the hardest hard gate and the one D-11 warns hardest against inflating."

requirements-completed: [SHOW-01]

coverage:
  - id: D1
    description: "Gallery + artifacts.json re-blessed from the improved 118-08 compositions with zero drift"
    requirement: "SHOW-01"
    verification:
      - kind: integration
        ref: "mix rendro.launch_artifacts.check -> 'Launch artifacts VERIFIED'"
        status: pass
      - kind: integration
        ref: "mix test test/docs_contract/launch_artifacts_claims_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "All six demos re-scored honestly; every priv/quality/rubric_scores.json entry is passed:true under the exact passed?/2 arithmetic"
    requirement: "SHOW-01"
    verification:
      - kind: integration
        ref: "mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/demo_cites_domain_md_test.exs"
        status: pass
    human_judgment: true
    rationale: "The dimension_scores themselves are a subjective visual-quality rating (per D-09/D-11) recorded by the executing agent from re-rendered rasters, not derivable from an automated assertion. The contract tests prove the arithmetic/schema/disjointness are honestly wired, but a human should confirm the visual judgment calls (especially the content_hierarchy=5 gate) against the actual PNGs before treating SHOW-01 as unconditionally closed."
  - id: D3
    description: "REQUIREMENTS.md SHOW-01 reconciled to Complete with no regression across the six docs-contract lanes"
    requirement: "SHOW-01"
    verification:
      - kind: integration
        ref: "mix test test/docs_contract/ (293 tests, 0 failures) and full mix test (1569 tests, 0 failures, 26 excluded)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-07-19
status: complete
---

# Phase 118 Plan 09: Gallery re-bless + honest rubric re-score (SHOW-01 closure) Summary

Regenerated the launch gallery/artifacts from the improved 118-08 compositions, re-scored all
six demonstration documents honestly against the new rasters (every entry now `passed:true`
under the exact `passed?/2` arithmetic), and reconciled `REQUIREMENTS.md` SHOW-01 to Complete
— closing Phase 118 at 4/4 and milestone v2.10.

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-07-19
- **Tasks:** 3/3
- **Files modified:** 14

## Accomplishments

- Regenerated all 7 gallery tiles + `artifacts.json` + `manual.pdf` + generated README/`recipes.md`
  blocks via `mix rendro.launch_artifacts.gen`, picking up the 118-08 composition rework.
  `mix rendro.launch_artifacts.check` reports zero drift ("Launch artifacts VERIFIED").
- Fixed a stale `@expected_gallery_dimensions["ticket"]` placeholder (794x1123 A4) to the ticket's
  real native-A6 dims (397x560px @ 96 DPI) — the exact correction the code's own comment
  anticipated once `.gen` ran against the 118-08 page-size change.
- Re-scored all six demos against the new renders using direct visual inspection plus objective
  pixel-row glyph-height measurement (ImageMagick pixel enumeration + Python row-banding) for the
  content_hierarchy dimension. Every demo's dominant key fact is now measurably the single largest
  element on its page:
  - Invoice: "Total Due: $696.60" — 24px glyph height vs. 19px title, ~10-16px body
  - Statement: boxed "Closing balance $6,647.56" — 26px vs. 19px account title, 16px ledger rows
  - Receipt: "Total: $30.78" — 22px vs. 17-19px merchant name/address, 10-13px item rows
  - Certificate: recipient "Alex Rivera" — 34px vs. 26px title, 11-15px body/date/signature
  - Payslip: boxed "NET PAY $3,292.50" — already dominant; header-collision + wrapped-YTD-figure
    defects visually confirmed fixed (clean "YTD Deductions" spacing, "$25,200.00" on one line)
  - Ticket: locator readout "GA H 24 B" — 27px vs. ~14px event title, ~10-11px terms footer
- Every `scores[]` entry's `passed` boolean is the exact `passed?/2` computation (content_hierarchy
  == 5 AND every other core >= 4 AND both gates true) — never asserted independently. All six are
  honestly `passed:true`.
- Reconciled `.planning/REQUIREMENTS.md`: SHOW-01 checkbox flips to `[x]`, stale "GAP (2026-07-19)"
  note replaced with the closure rationale; coverage row updated to "Complete".
- Proved no regression: the six docs-contract lanes (rubric manifest, demo-cites-DOMAIN.md,
  DOMAIN.md contract, examples schema, accessibility overclaim, launch-artifacts claims) are green
  (104 tests, 0 failures). Full `mix test`: 12 doctests, 4 properties, 1569 tests, 0 failures (26
  excluded) — the 118-08 known container-gated failure is now resolved.

## Task Commits

1. **Task 1: Re-render gallery + artifacts.json from the improved compositions** - `e8b1c16` (feat)
2. **Task 2: Re-score all six demos honestly** - `65c0bd3` (feat)
3. **Task 3: Reconcile REQUIREMENTS.md + prove no regression** - `8e96745` (docs)

## Files Created/Modified

- `assets/rendro/artifacts.json` - re-blessed 7-entry manifest, S6 keys intact, hashes match new renders
- `assets/rendro/gallery/*.png` (7 files) - re-rendered from the 118-08 improved compositions
- `assets/rendro/manual.pdf` - re-blessed
- `README.md`, `guides/recipes.md` - regenerated `@readme_start`/`@recipes_start` generated blocks
- `lib/rendro/launch_artifacts.ex` - fixed stale `@expected_gallery_dimensions["ticket"]` (794x1123 -> 397x560, native A6)
- `priv/quality/rubric_scores.json` - all six `scores[]` entries re-scored honestly, every `passed:true`
- `.planning/REQUIREMENTS.md` - SHOW-01 checkbox + coverage row reconciled to Complete

## Decisions Made

- **pdfium-cli was located and re-verified rather than deferred to a container.** A prior session on
  this same macOS host had already downloaded the pinned v0.11.0 mac-arm64 wasm build into its
  scratchpad directory. Before using it for the re-bless, I re-ran the exact determinism gate 118-05
  established (`test/rendro/adapters/pdfium_raster_snapshot_test.exs:31`, the forms_support_fixture
  raster snapshot) — it passed, proving this binary rasterizes byte-identically to the CI-blessed
  amd64 reference. Only after that proof did I run `mix rendro.launch_artifacts.gen`/`.check` with it
  via `--pdfium <path>`. This is the same "pinned version, cross-platform wasm determinism proven"
  precedent 118-05 documented, not a substitution or an unverified install — no new binary was
  downloaded or installed for this plan.
- **Ticket's `@expected_gallery_dimensions` stale-constant fix (Rule 1).** `mix rendro.launch_artifacts.check`
  failed on the first run with "gallery ticket dimensions must be 794x1123" — a direct, mechanical
  consequence of 118-08's legitimate native-A6 ticket change that the code comment had explicitly
  called out as needing a future correction ("ticket is A6, so its actual dims will differ"). Fixed
  the constant to {397, 560} rather than treating this as a regression to revert.
- **Content_hierarchy scored with pixel evidence, not just eyeballing.** Since content_hierarchy=5 is
  the single hardest, most inflation-prone gate (D-11's explicit warning), I supplemented direct
  visual inspection with objective pixel-row glyph-height measurements for every demo's dominant
  element vs. its next-largest competitor, and recorded the measured pixel heights directly in each
  entry's justification string for auditability.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stale `@expected_gallery_dimensions["ticket"]` blocked `launch_artifacts.check`**
- **Found during:** Task 1, first `mix rendro.launch_artifacts.check` run after `.gen`
- **Issue:** the constant still held the provisional A4-portrait placeholder `{794, 1123}` for
  ticket; 118-08's native-A6 page-size change made the actual rendered dims `{397, 560}`, so the
  advisory-tier dimension check failed.
- **Fix:** updated `@expected_gallery_dimensions["ticket"]` to `{397, 560}` and replaced the
  now-stale "provisional" comment with an explanation of the real A6 sizing.
- **Files:** `lib/rendro/launch_artifacts.ex`
- **Verification:** `mix rendro.launch_artifacts.check` -> "Launch artifacts VERIFIED"; `mix test test/docs_contract/launch_artifacts_claims_test.exs test/rendro/launch_artifacts_test.exs` -> 21 tests, 0 failures
- **Committed in:** `e8b1c16` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Necessary to make the plan's own required verification (`launch_artifacts.check` VERIFIED) pass; no scope creep beyond the plan's Task 1 acceptance criteria.

## Issues Encountered

None beyond the deviation above. The plan's execution-context anticipated `pdfium-cli` might be
"genuinely unavailable locally," requiring a container-gated deferral. In this session it was
available (previously downloaded to a scratchpad on this host) and its determinism was re-proven
before use, so no deferral was needed this round — Task 1/2/3 all completed with real re-rendered
evidence, not a deferred placeholder.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 118 is 4/4 (SHOW-01..04 all Complete). Milestone v2.10 (114-118) is ready to close.
- No blockers. The two pre-existing `deferred-items.md` entries (Statement unicode fallback font;
  pre-existing `mix format` debt on 10 unrelated files) remain open but are explicitly out of this
  plan's and this phase's scope — logged for a future phase, not required for v2.10 closure.

---
*Phase: 118-rubric-gated-demonstration-set-gallery-docs-closure*
*Completed: 2026-07-19*

## Self-Check: PASSED

- FOUND: assets/rendro/artifacts.json
- FOUND: assets/rendro/gallery/ticket.png
- FOUND: lib/rendro/launch_artifacts.ex
- FOUND: priv/quality/rubric_scores.json
- FOUND: .planning/REQUIREMENTS.md
- FOUND commit: e8b1c16 (Task 1: gallery re-bless)
- FOUND commit: 65c0bd3 (Task 2: honest re-score)
- FOUND commit: 8e96745 (Task 3: REQUIREMENTS.md reconciliation)

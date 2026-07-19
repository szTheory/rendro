---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 04
subsystem: launch-artifacts
tags: [gallery, fixtures, recipes, launch-artifacts, s6-seam, elixir]

# Dependency graph
requires:
  - phase: 118-03
    provides: "Rendro.ExamplesData per-family transform seam (transform_<family>/1) feeding each recipe's document/2"
  - phase: 118-01
    provides: six priv/examples fixtures (invoice/statement/receipt/certificate/payslip/ticket)
provides:
  - "Rendro.LaunchArtifacts gallery repointed to priv/examples/** through Rendro.Examples + Rendro.ExamplesData (D-06) — no inline toy *_data/* builder feeds the gallery"
  - "Seven gallery tiles in fixed order: invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket (D-07)"
  - "S6 theme/mode/preset optional seam tags on every gallery entry with a tolerant, non-required shape check (D-13)"
  - "Render-free manifest_shape_errors/1 helper (hidden) for pdfium-free shape assertions"
affects: [118-05, 118-06, 118-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Launch-only document post-processors (apply_launch_table_style/1 idiom) extended: wrap_section_text_to_region/3 constrains unbounded recipe paragraph text to its region width so realistic long copy wraps instead of overflowing — recipe byte goldens untouched"
    - "Optional-seam contract: keys emitted on every entry + appended after a stable anchor key for deterministic order, but deliberately absent from the required-keys set; a tolerant per-key shape check validates type-when-present and never errors on absence"

key-files:
  created: []
  modified:
    - lib/rendro/launch_artifacts.ex
    - test/rendro/launch_artifacts_test.exs
    - priv/examples/certificate/summit-training-institute/certificate.json
    - priv/examples/ticket/aurora-live/ticket.json

key-decisions:
  - "branded_invoice tile renders a bounded 8-item slice of the invoice fixture (@branded_invoice_item_count) — the BrandedInvoice recipe body is a single non-paginating table; the full 60-item fixture overflows. Multi-page pagination is demonstrated by the plain invoice tile. Still fixture-sourced (D-06)."
  - "S6 placeholder convention: theme => nil, mode => \"light\", preset => nil. Explicit null for theme/preset means 'seam present, not yet populated'; \"light\" is the one defensible non-null default for mode. Keys appended after \"caption\" for deterministic order; NOT added to @gallery_required_keys (optional, D-13)."
  - "Two shared fixtures ASCII-ified (certificate seal_line em-dash, ticket subtitle middots) — the Certificate and Ticket recipes render built-in Helvetica with no unicode fallback (same class as the Statement fix in 118-03). Recipe-level unicode fallback remains the deferred alternative."
  - "Certificate body + ticket terms wrapped via a launch-only post-processor (wrap_section_text_to_region/3): both recipes emit long paragraph text as a single unbounded block that overflows the region horizontally with realistic multi-clause fixture copy."

requirements-completed: [SHOW-03]

# Metrics
duration: 14min
completed: 2026-07-19
status: complete
---

# Phase 118 Plan 04: Gallery Repoint to the Realistic Fixture Library Summary

**`Rendro.LaunchArtifacts` now sources all seven gallery tiles (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket) from `priv/examples/**` through `Rendro.Examples` + `Rendro.ExamplesData` (D-06), in a fixed enforced order (D-07), with optional S6 `theme`/`mode`/`preset` seam tags on every entry (D-13) — proven at the document-shape level via `Rendro.render(deterministic: true)`; the byte re-baseline and PNG rasters are container-gated to 118-05.**

## Performance
- **Duration:** ~14 min
- **Started:** 2026-07-19T16:05:42Z
- **Completed:** 2026-07-19
- **Tasks:** 3
- **Files modified:** 4 (0 created, 4 modified)

## Accomplishments
- **Task 1 (D-06):** Repointed `build_source_document/1` for the five existing tiles to `Rendro.Examples.load!/1 |> Rendro.ExamplesData.transform_<family>/1 |> Recipes.<Family>.document/2`. Removed the inline toy `*_data/*` builders (confirmed no other consumers). Preserved `apply_launch_table_style/1` for the table families, certificate's `border: true`, and branded_invoice's synthesized brand refs + launch header.
- **Task 2 (D-07):** Added `payslip` and `ticket` `@gallery_specs` entries after `certificate`, giving exactly seven tiles in the enforced fixed order. Manual pages and image registration auto-wire off `@gallery_specs`. Added fixture-sourced build clauses and provisional `@expected_gallery_dimensions` for both.
- **Task 3 (D-13):** Added `theme`/`mode`/`preset` to every gallery entry map, appended them after `caption` in `ordered_gallery_entry/1` for deterministic key order, kept them out of `@gallery_required_keys`, and added a tolerant `s6_seam_errors/2` shape check (absence valid; present value must be null or string).
- All seven tiles render cleanly through `render_source_pdf/1`; `mix test test/rendro/launch_artifacts_test.exs` green (12 tests); `mix compile --warnings-as-errors` clean; public-API hidden contract intact (LaunchArtifacts + the new `manifest_shape_errors/1` stay absent from `priv/public_api.json`).

## Task Commits
1. **Task 1: Repoint gallery tiles to priv/examples fixtures (D-06)** — `72bffcf` (feat)
2. **Task 2: Add payslip + ticket gallery tiles (D-07)** — `cb0bf34` (feat)
3. **Task 3: Emit S6 theme/mode/preset seam tags (D-13)** — `2bd9219` (feat)

## Files Modified
- `lib/rendro/launch_artifacts.ex` — fixture-path attrs; repointed 5 build clauses + 2 new (payslip/ticket); removed 5 inline builders; 2 new `@gallery_specs`; extended `@expected_gallery_dimensions`; S6 keys in `build_gallery_entries/1` + `ordered_gallery_entry/1`; `@gallery_optional_s6_keys` + `s6_seam_errors/2`; `wrap_section_text_to_region/3` post-processor (certificate body + ticket terms); bounded branded-invoice item slice; corrected statement/receipt captions+alt; render-free `manifest_shape_errors/1`.
- `test/rendro/launch_artifacts_test.exs` — dropped toy-data multi-page assertion; fixture-sourcing assertions (invoice/certificate/payslip/ticket); 7-tile fixed-order test; S6 seam tolerance + shape-check tests; `all_texts/1` helper.
- `priv/examples/certificate/summit-training-institute/certificate.json` — seal_line em-dash → hyphen (deviation).
- `priv/examples/ticket/aurora-live/ticket.json` — subtitle middots → hyphens (deviation).

## Decisions Made
- **S6 placeholder convention:** `theme => nil, mode => "light", preset => nil`. Explicit null = "seam present, not yet populated"; `"light"` is the single defensible non-null default for `mode`. Documented inline and enforced as optional (never required).
- **branded_invoice item slice (8):** the BrandedInvoice recipe body is a single non-paginating table; the full 60-item invoice fixture overflows its fixed body region. The branded tile is a branding showcase (logo + embedded font), so it renders a bounded fixture slice while remaining fixture-sourced. Multi-page behavior is demonstrated by the plain `invoice` tile (2 pages).
- **Provisional payslip/ticket dimensions `{794,1123}`:** `@expected_gallery_dimensions` is advisory-tier. The container `.gen` in 118-05 must confirm/correct the real pixel dims — **ticket is A6**, so its actual raster dimensions will differ from the A4-portrait placeholder.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Certificate fixture em-dash aborts the certificate render**
- **Found during:** Task 1 (certificate render via `render_source_pdf`).
- **Issue:** `certificate.json` `seal_line` contained an em-dash (`—`); the Certificate recipe renders built-in Helvetica (ASCII-only, no unicode fallback), raising `{:unsupported_glyph, "—"}` — identical class to the Statement fix in 118-03.
- **Fix:** ASCII-ified the em-dash to a hyphen (`Program Director - Summit Training Institute`).
- **Files modified:** `priv/examples/certificate/summit-training-institute/certificate.json`
- **Committed in:** `72bffcf`

**2. [Rule 3 - Blocking] Certificate body + ticket terms overflow their regions as unwrapped single lines**
- **Found during:** Tasks 1 & 2 (certificate/ticket render).
- **Issue:** The Certificate body statement and Ticket terms are emitted as single unbounded text blocks (no wrap width). The short toy fixtures fit on one line; the realistic multi-clause fixture copy measures wider than the region (876pt body vs 697.89pt region; 560pt terms vs 451.28pt region) → horizontal `:content_overflow`.
- **Fix:** Added a launch-only post-processor `wrap_section_text_to_region/3` (mirroring `apply_launch_table_style/1`) that constrains each flow text block in the named section to its region width so long lines wrap. Kept out of the shared recipes to leave their byte goldens untouched. Recipe-level wrapping/unicode-fallback is the deferred realism-maximizing alternative.
- **Files modified:** `lib/rendro/launch_artifacts.ex`
- **Committed in:** `72bffcf` (certificate), `cb0bf34` (ticket, generalized helper)

**3. [Rule 3 - Blocking] Ticket subtitle middots abort the ticket render**
- **Found during:** Task 2 (ticket render).
- **Issue:** `ticket.json` `subtitle` used middot separators (`·`); the Ticket recipe renders built-in Helvetica with no unicode fallback (unlike Payslip's B612 fallback from 116-02), raising `{:unsupported_glyph, "·"}`.
- **Fix:** ASCII-ified the subtitle separators to hyphens (`Doors 7:00 PM - Show 8:00 PM - Saturday 27 June 2026`).
- **Files modified:** `priv/examples/ticket/aurora-live/ticket.json`
- **Committed in:** `cb0bf34`

**4. [Rule 1 - Bug] Stale toy-data captions/alt falsely claimed multi-page output**
- **Found during:** Task 1.
- **Issue:** With the realistic single-page statement (8 lines) and receipt (4 lines) fixtures, the `statement`/`receipt_report` gallery captions ("Multi-page statement…", "…multi-page tabular report") and alt text ("Page 1 of 2 footer") became factually wrong — a demonstration-set honesty regression.
- **Fix:** Rewrote both captions and alt strings to describe the actual single-page realistic documents.
- **Files modified:** `lib/rendro/launch_artifacts.ex`
- **Committed in:** `72bffcf`

**5. [Rule 3 - Blocking, test-support] Exposed a render-free shape validator for S6 unit tests**
- **Found during:** Task 3.
- **Issue:** The pure shape-validation path is private, and `static_contract_errors/1` renders the manual — which now registers the not-yet-generated payslip/ticket PNGs and fails. S6 tolerance could not be unit-tested through it.
- **Fix:** Added `manifest_shape_errors/1` (`@doc false`, runs only `collect_manifest_shape_errors/2`, no render/hashing). Stays hidden (whole module is `@moduledoc false`; verified absent from `public_api.json`).
- **Files modified:** `lib/rendro/launch_artifacts.ex`
- **Committed in:** `2bd9219`

**Total deviations:** 5 (3 blocking glyph/overflow fixes consistent with the 118-03 precedent, 1 caption-honesty correction, 1 test-support helper). No architectural (Rule 4) changes; no scope creep — recipe-level unicode/wrap upgrades were explicitly NOT taken on.

## Container-Gated / Deferred to 118-05

The plan explicitly defers the source-PDF/PNG hash re-baseline and PNG raster dims to the container wave 118-05 (they need pdfium, unavailable locally per 117-06). As a direct consequence, **two `test/docs_contract/launch_artifacts_claims_test.exs` tests are expected-red until 118-05 regenerates `assets/rendro/artifacts.json` and the PNGs**:

- `:8` "launch artifacts static contract is current" — source-PDF + manual byte drift (the five existing tiles now render different, realistic bytes; artifacts.json still records the old toy hashes).
- `:24` "static contract catches manifest shape and hash drifts without pdfium" — `static_contract_errors/1` renders the manual, which registers `payslip.png`/`ticket.png` that do not exist on disk yet.

**118-05 MUST:**
1. Run `mix rendro.launch_artifacts.gen` in the pinned pdfium container to regenerate `artifacts.json` (7 tiles incl. S6 keys), the 7 gallery PNGs, `manual.pdf`, and the README/`guides/recipes.md` blocks.
2. Update `test/docs_contract/launch_artifacts_claims_test.exs` — the "records exactly the five … previews" assertion (`:12`) and the hex-package asset list must move from five to seven; re-green `:8` and `:24`.
3. Confirm/correct the provisional `@expected_gallery_dimensions` for `payslip` and `ticket` (ticket is A6 — dims will differ from the `{794,1123}` placeholder).

## Verification Results
- `mix test test/rendro/launch_artifacts_test.exs` — 12 tests, 0 failures.
- `mix test test/docs_contract/public_api_contract_test.exs` — 6 tests, 0 failures (no new public surface).
- `mix compile --warnings-as-errors` — clean.
- `mix test` (full) — 1531 tests, 2 failures, both the container-gated `launch_artifacts_claims_test.exs` cases documented above.

## Next Phase Readiness
- **118-05 (container re-baseline):** regenerate artifacts + PNGs + docs blocks, update the claims test to seven tiles, confirm payslip/ticket pixel dims. See the container-gated section above.
- **118-06 (demonstration set):** the seven fixtures now render cleanly through their recipes (with the ASCII/wrap accommodations); the certificate and ticket fixtures are ASCII-safe.

## Self-Check: PASSED
- All modified files verified present on disk.
- All three task commits verified in git history (`72bffcf`, `cb0bf34`, `2bd9219`).
- Seven tiles render via `render_source_pdf/1`; gallery order enforced by test.

---
*Phase: 118-rubric-gated-demonstration-set-gallery-docs-closure*
*Completed: 2026-07-19*

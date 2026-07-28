---
phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
plan: 03
subsystem: docs
tags: [gallery, theme, launch-artifacts, pdfium, rubric, dark-mode]

# Dependency graph
requires:
  - phase: 122-typography-type-scale-application-font-role-leading-wiring
    provides: uniform typography/1 seam (scale/fonts/leading) on all 7 recipes; leading 1.35 realized in 123-02
  - phase: 121-light-dark-background-fill-mechanism-all-7-recipes
    provides: Theme.dark/1 + the shared :background region/section mechanism
  - phase: 119-rendro-theme-core-module-the-one-way-door
    provides: Rendro.Theme.default/0, Theme.dark/1, Theme.from_brand/2
provides:
  - 11-row curated hash-checked gallery (7 retagged theme:"default" + invoice_dark + certificate_dark + ticket_dark + invoice_brand), preset:null on all
  - readme_hero S7 seam (README hero subset vs. full 11-row manifest)
  - fresh themed glyph-height deltas for all 6 rubric demos, computed from the actual themed bytes (not the stale 2026-07-19 native-scale numbers)
  - 3 newly-discovered, explicitly-deferred honesty findings (Invoice dark-mode table illegibility, Ticket hierarchy inversion, Payslip numeric wrap) recorded in WINDOWS.md for the Plan 05 human sign-off
affects: [123-04, 123-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "readme_hero/theme_tag/mode_tag spec fields, structural twins of the existing S6 theme/mode/preset seam, read by build_gallery_entries/1 instead of a hardcoded literal"
    - "theme-gated header/footer geometry budget (case opts[:theme]) mirrored from Statement (123-02) onto Receipt for the themed multi-page repeating header"

key-files:
  created:
    - assets/rendro/gallery/invoice_dark.png
    - assets/rendro/gallery/certificate_dark.png
    - assets/rendro/gallery/ticket_dark.png
    - assets/rendro/gallery/invoice_brand.png
  modified:
    - lib/rendro/launch_artifacts.ex
    - lib/rendro/recipes/receipt.ex
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
    - test/docs_contract/launch_artifacts_claims_test.exs

key-decisions:
  - "Retagged all 7 existing gallery rows to theme: Rendro.Theme.default() (not just leading) — the Big Finding confirmed this re-blesses all 7, not only the 3 prose rows, because every recipe's native type scale differs from the theme's uniform scale."
  - "Certificate content_hierarchy checkpoint: measured themed recipient/title ratio is 21/16.5 = 1.27 (matches research's ~1.27 prediction); visually confirmed 'Alex Rivera' still reads as the single unambiguous dominant focal point on the themed raster — NO emphasis fix applied in this commit."
  - "3 new honesty findings discovered while regenerating the themed gallery (Invoice dark-mode table illegibility, Ticket display/title hierarchy inversion, Payslip numeric-cell wrap) were NOT silently fixed — each is out of this plan's gallery-closure scope (would touch a frozen byte-identity golden, a locked Phase-122 role decision, or a column-width retune) and is recorded in WINDOWS.md + this SUMMARY for the Plan 05 human checkpoint."

patterns-established:
  - "S7 readme_hero seam: a boolean spec/manifest field, structurally parallel to but independent of the S6 theme/mode/preset seam, filtering which manifest rows a doc-generation function shows."

requirements-completed: [DEFAULT-03]

coverage:
  - id: D1
    description: "artifacts.json has 11 ordered gallery rows (7 retagged + 3 dark + 1 brand), every row preset:null"
    requirement: "DEFAULT-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/launch_artifacts_claims_test.exs#manifest records exactly the eleven recipe previews"
        status: pass
      - kind: integration
        ref: "mix rendro.launch_artifacts.check"
        status: pass
    human_judgment: false
  - id: D2
    description: "The 7 retagged rows render via theme: Rendro.Theme.default() so the 'default' tag is literally true; all 7 re-bless because the theme swaps each recipe's native type scale"
    requirement: "DEFAULT-03"
    verification:
      - kind: unit
        ref: "mix test test/rendro/recipes/ (no-theme byte-identity goldens unaffected)"
        status: pass
    human_judgment: false
  - id: D3
    description: "invoice_brand renders via from_brand(accent: \"#0E7C76\") accent-only; the 3 dark rows render via Theme.dark(Theme.default()); S6 tags theme/mode valid on all 11"
    requirement: "DEFAULT-03"
    verification:
      - kind: integration
        ref: "mix rendro.launch_artifacts.check"
        status: pass
    human_judgment: false
  - id: D4
    description: "No rubric_scores.json change in this commit set (D-05 Commit 2 isolation)"
    requirement: "DEFAULT-03"
    verification:
      - kind: other
        ref: "git diff --cached --stat (both commits) contains no priv/quality/rubric_scores.json path"
        status: pass
    human_judgment: false
  - id: D5
    description: "Certificate content_hierarchy checkpoint: themed recipient/title ratio measured and judged against the rendered raster"
    verification: []
    human_judgment: true
    rationale: "Whether a 1.27 dominance ratio honestly reads as 'one unambiguous focal point' for the reader-quality rubric is a subjective visual judgment the plan explicitly reserves for the Plan 05 human sign-off, not an automatable pass/fail."
  - id: D6
    description: "3 newly-discovered dark/themed-render honesty findings (Invoice table illegibility, Ticket hierarchy inversion, Payslip numeric wrap) flagged for human review, not silently fixed"
    verification: []
    human_judgment: true
    rationale: "Each finding requires a human decision on remediation approach (engine-adjacent Table color seam, a locked Phase-122 role-mapping change, or a column-width retune) that is out of this plan's narrow gallery-closure scope."

duration: 26min
completed: 2026-07-28
status: complete
---

# Phase 123 Plan 03: Gallery closure — 11-row themed/dark/brand gallery + fresh honest hierarchy deltas Summary

**Regenerated the launch gallery to 11 hash-checked rows (7 retagged `theme:"default"` + invoice_dark/certificate_dark/ticket_dark + invoice_brand), fixed a themed-overflow bug in Receipt's repeating header, and measured fresh glyph-height deltas from the actual themed rasters — surfacing 3 new honesty findings (Invoice dark-table illegibility, Ticket hierarchy inversion, Payslip numeric wrap) for the Plan 05 human sign-off instead of silently patching them.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-07-28T19:19:34Z
- **Completed:** 2026-07-28T19:45:00Z
- **Tasks:** 3 (Task 3 produced no code diff — see below)
- **Files modified:** 18 (14 from Task 2 + `lib/rendro/launch_artifacts.ex` further amended in Task 2 for a caption-length fix, `lib/rendro/recipes/receipt.ex` for the header-overflow fix)

## Accomplishments

- `Rendro.LaunchArtifacts.gallery_specs()` now returns 11 ordered specs (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket, invoice_dark, certificate_dark, ticket_dark, invoice_brand), each carrying `readme_hero`/`theme_tag`/`mode_tag`.
- `assets/rendro/artifacts.json` holds 11 hash-checked rows: `theme` is `"default"` (×10) / `"brand"` (×1, invoice_brand), `mode` is `"light"`/`"dark"`, `preset` is `null` on every row.
- `readme_block/1` now filters to the `readme_hero` subset (9 of 11 rows) for the README; `recipes_block/1` still renders all 11 with SHA-256s.
- All 7 existing rows re-bless (confirmed the Big Finding: theming swaps every recipe's native type scale, not just leading) + 4 new rasters hashed.
- `mix rendro.launch_artifacts.check` and the updated `launch_artifacts_claims_test.exs` (7→11 ids) both pass; no `priv/quality/rubric_scores.json` in either commit's diff.
- Fresh themed glyph-height deltas computed for all 6 rubric demos from the actual re-blessed bytes (not the stale 2026-07-19 native-scale numbers) — see below.
- Certificate's compressed hierarchy risk (research's #1 concern) was measured (ratio 1.27) and visually judged still honestly dominant; no emphasis fix was needed.
- 3 new, more severe honesty findings were discovered while regenerating the themed gallery and recorded (not silently patched) for the Plan 05 human checkpoint.

## Task Commits

1. **Task 1: Add 4 gallery specs + dims + build_source_document clauses + retag 7 + readme_hero filter** - `be64152` (feat)
2. **Task 2: Regenerate the gallery (re-bless 7 + 4 new), update the count test 7->11, verify hashes** - `53e1ba7` (feat) — includes the Receipt header-overflow fix and the caption-length/glyph fix as in-task deviations (see below)
3. **Task 3: Pre-compute themed glyph-height deltas + confront the Certificate hierarchy checkpoint** - no separate commit (measurement-only; produced no tracked file changes — the deltas below are the task's output, and the 3 findings it surfaced are recorded via `gsd-tools windows append`, not a code diff)

**Plan metadata:** _pending — recorded after this SUMMARY is committed_

## Files Created/Modified

- `lib/rendro/launch_artifacts.ex` - 11 `@gallery_specs` (readme_hero/theme_tag/mode_tag), 4 new `build_source_document/1` clauses, 7 retagged clauses, `readme_block/1` hero filter, `@expected_gallery_dimensions` +4
- `lib/rendro/recipes/receipt.ex` - `computed_header_height/2` now takes `opts` and widens the merchant-block budget under a theme (mirrors Statement's 123-02 idiom)
- `assets/rendro/artifacts.json` - regenerated, 11 rows
- `assets/rendro/gallery/*.png` - 7 re-blessed + 4 new (`invoice_dark`, `certificate_dark`, `ticket_dark`, `invoice_brand`)
- `assets/rendro/manual.pdf` - regenerated (now includes a manual page per spec, 11 pages of recipe content)
- `README.md`, `guides/recipes.md` - regenerated doc blocks
- `test/docs_contract/launch_artifacts_claims_test.exs` - id-list assertion 7→11; README/recipes accessibility test split (README checks only the hero subset); tarball `expected_assets` includes the 4 new PNGs

## Decisions Made

- Threaded `theme: Rendro.Theme.default()` into all 7 existing `build_source_document/1` clauses per-spec (Claude's Discretion on mechanism), rather than a shared module-attribute helper — keeps each clause's diff self-explanatory.
- `readme_hero` was added as a manifest-emitted field (not a spec-only lookup at doc-generation time) per the research's Open Q2 recommendation, so `readme_block/1` filters purely on the manifest.
- Certificate's themed hierarchy checkpoint (ratio 1.27) was judged sufficient without an emphasis fix — see "Certificate hierarchy checkpoint" below for the reasoning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Receipt's themed multi-page header overflowed by ~0.4pt**
- **Found during:** Task 2 (running `mix rendro.launch_artifacts.gen`)
- **Issue:** `receipt_report`'s themed render raised `{:content_overflow, ...}` on the header region of page 2+ — the frozen 88pt no-theme merchant-block budget (`@default_header_height 48 + 40`) was sized for the native scale (title 14/body 12/small 10/merchant-title 16 at leading 1.2 ≈ 81.6pt); at the themed scale (subtitle 13/body 10.5/small 9/merchant-title 16.5 at leading 1.35) the same 4 lines need ≈88.4pt — 0.4pt over budget.
- **Fix:** Mirrored Statement's 123-02 `header_height/1` idiom: `computed_header_height/2` now takes `opts` and widens the merchant-block budget from +40 to +48 only when `opts[:theme]` is present; the no-theme path is untouched (verified byte-identical via `mix test test/rendro/recipes/receipt_test.exs`, 48/48 green).
- **Files modified:** `lib/rendro/recipes/receipt.ex`
- **Verification:** `mix rendro.launch_artifacts.gen`/`.check` succeed; `mix test test/rendro/recipes/` (379 tests, 0 failures).
- **Committed in:** `53e1ba7` (Task 2 commit)

**2. [Rule 1 - Bug] 4 new spec captions overflowed the manual.pdf's unwrapped text block and used an unsupported glyph**
- **Found during:** Task 2 (running `mix rendro.launch_artifacts.gen`)
- **Issue:** The manual.pdf's `body_text/1` helper renders `spec.caption` with no explicit width (unlike the gallery's `apply_certificate_body_wrap`/`apply_ticket_terms_wrap` post-processors) — the 4 new captions (98–112 chars, vs. the existing captions' 53–82-char range) measured wider than the manual's 487pt body region, raising `:content_overflow`. Separately, the em dash (`—`, U+2014) used in 3 captions has no glyph in the built-in Helvetica font, raising `{:unsupported_glyph, "—"}`.
- **Fix:** Shortened all 4 new captions to plain-ASCII strings within the existing captions' length range (max 83 chars), replacing the em dash with a hyphen-minus.
- **Files modified:** `lib/rendro/launch_artifacts.ex`
- **Verification:** `mix rendro.launch_artifacts.gen` succeeds; manual.pdf renders all 11 recipe pages.
- **Committed in:** `53e1ba7` (Task 2 commit)

### Discovered, Deferred Findings (NOT fixed — flagged for Plan 05 human sign-off)

These were found while visually inspecting the freshly-blessed themed rasters during Task 3's measurement work. None blocks `mix rendro.launch_artifacts.check` (the renders succeed and hash-verify); each is a genuine honesty/quality regression that this narrow gallery-closure plan is not the right place to fix. All 3 are recorded in `.planning/WINDOWS.md` (kind: `deviation`) so they surface at ship time.

**1. Invoice dark-mode table illegibility (invoice_dark)**
- Invoice's item/qty/price table body rows are built as bare strings (`lib/rendro/recipes/invoice.ex` `body_section/2`, `formatted_rows`), so `Rendro.Table` renders them with a fixed default text color, never sourced from `colors.ink`. Measured on `invoice_dark.png`: cell text luminance ≈0–2 against a background luminance ≈23.6 — effectively invisible (WCAG contrast ≈1.1:1).
- Root cause: `Rendro.Table` cells accept `Rendro.Block.t() | String.t()`, but only `Block`-wrapped cells can carry a themed color; a fix would need Invoice's row-builder to wrap each cell in a themed `Block`+`Text`, which risks the frozen INV-01 byte-identity golden if the wrapped cell's font/size/color doesn't exactly reproduce the current bare-string defaults — not something to improvise inside a gallery-closure task.
- **Not fixed.** Recorded in WINDOWS.md (id 1).

**2. Ticket display/title hierarchy inversion (ticket, ticket_dark)**
- Ticket's typography seam (122-03, Q3) deliberately maps the tiny reference-code text to `scale.display` (native 8pt, "the SOLE anchor" for API consistency) while the visually-dominant placement-grid values (`SECTION/ROW/SEAT/GATE`, the element the 2026-07-19 rubric actually scored as dominant) use `scale.title` (native 26pt). Themed, the uniform scale makes `display` (21pt) LARGER than `title` (16.5pt) — inverting which element visually dominates. The reference code (now 21pt in a ~180pt-wide stub column) also wraps awkwardly across 3 lines (`AUR-8` / `8213-` / `GA`), confirmed visually on both `ticket.png` and `ticket_dark.png`.
- This is a real regression against the original rubric's content_hierarchy justification, not merely a compression like Certificate's.
- **Not fixed** — re-mapping Ticket's non-monotone role assignment is a locked Phase-122 (Q3) decision, an architectural call outside this plan's scope. Recorded in WINDOWS.md (id 2).

**3. Payslip numeric-cell wrap (payslip)**
- The earnings/deductions table's Current/YTD numeric cells (e.g. `$4,200.00`, `$4,550.00`) wrap mid-number onto a second line (`$4,200.0` / `0`) at the themed 10.5pt body scale + 1.35 leading, visually confirmed on `payslip.png` — a new typographic_craft awkward-break regression vs. the native 11pt no-theme render (which fits on one line).
- **Not fixed** — a column-width retune is out of this plan's gallery-closure scope. Recorded in WINDOWS.md (id 3).

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug) + 3 discovered-and-deferred findings (flagged, not fixed)
**Impact on plan:** Both auto-fixes were necessary for `mix rendro.launch_artifacts.gen` to succeed at all; no scope creep. The 3 deferred findings are genuine new information the Plan 05 human sign-off needs — silently patching any of them would have either risked a frozen golden, second-guessed a locked prior-phase decision, or expanded this plan's file list beyond gallery closure.

## Certificate Hierarchy Checkpoint (Task 3, D-02/Big Finding risk)

Per the research's #1 flagged risk: does the themed Certificate honestly clear `content_hierarchy == 5`?

- **Themed recipient/title ratio:** `scale.display` (21pt) / `scale.title` (16.5pt) = **1.27** (matches the research's predicted ~1.27 exactly — confirmed via `Rendro.Theme.resolve(Theme.default()).typography.scale`).
- **Visual confirmation** (re-rendered `certificate.png`, the themed default bytes blessed in Task 2): "Alex Rivera" (recipient, display anchor) is clearly, unambiguously the largest and most prominent text on the page. The next-largest element ("Certificate of Completion", title) sits at ~79% of its height, and every other element (subtitle/body/date/signatory) is markedly smaller (~50–62% of the title's height). No other element competes for visual weight.
- **Judgment recorded here (not a final score):** the compressed 1.27 ratio still reads, on the actual rendered raster, as one unambiguous focal point — the same conclusion the research flagged as plausible but requiring visual confirmation, not assumption. **No emphasis fix was applied in this commit.** The final `content_hierarchy` score remains the human's call in Plan 05 — this task supplies the measured number and the visual evidence, nothing more.

## Fresh Themed Glyph-Height Deltas (Task 3 — for the Plan 05 human sign-off)

**Methodology (disclosed, not reused from 2026-07-19):** every themed demo now shares the SAME uniform type scale (`Rendro.Theme.default().typography.scale`), since theming swaps the native per-recipe scale onto one common scale (the Big Finding). Glyph-height figures below are the Helvetica glyph bounding-box height — `(ascent − descent) / 1000 × size_pt × (96/72)` using the engine's own `Rendro.PDF.Font.helvetica/0` metrics (ascent 718, descent −207 per 1000 em) — at the gallery's 96 DPI, i.e. the same units-per-em box the engine itself reasons about, not a manual antialiased-pixel count of the raster (which proved unreliable to isolate cleanly across differing table/multi-column layouts). Every demo's anchor/comparison pair was also **visually confirmed** against the actual re-blessed PNG (see screenshots reviewed during this task). None of these numbers is copied from the 2026-07-19 native-scale justifications.

| Demo | Key-fact anchor (role, themed size) | Computed height | Next-largest (role, themed size) | Computed height | Delta | Ratio | Visual confirmation |
|---|---|---|---|---|---|---|---|
| Invoice | "Total Due: $696.60" (`display`, 21pt) | 25.9px | "INVOICE #INV-CMP-2026-001" (`title`, 16.5pt) | 20.4px | 5.6px | 1.27 | Confirmed dominant (also accent-colored) |
| Statement | "$6,647.56" closing balance (`display`, 21pt) | 25.9px | "Northwind Ledger Co - Operating Account ****8140" (`title`, 16.5pt) | 20.4px | 5.6px | 1.27 | Confirmed dominant |
| Receipt/Report | "Total: $30.78" (`display`, 21pt) | 25.9px | "Harbor & Oak Cafe / 214 Wharf Street..." merchant block (`title`, 16.5pt) | 20.4px | 5.6px | 1.27 | Confirmed dominant |
| Certificate | "Alex Rivera" (`display`, 21pt) | 25.9px | "Certificate of Completion" (`title`, 16.5pt) | 20.4px | 5.6px | 1.27 | Confirmed dominant (see checkpoint above) |
| Payslip | "$3,292.50" Net Pay (`display`, 21pt) | 25.9px | "Employer: Aurora Live / 18 Northgate Road..." (`title`, 16.5pt) | 20.4px | 5.6px | 1.27 | Confirmed dominant |
| Ticket | Reference code "AUR-88213-GA" (`display`, 21pt) | 25.9px | Placement-grid values "GA H 24 B" (`title`, 16.5pt) | 20.4px | 5.6px | **1.27 — but INVERTED**: `display` is now larger than `title`, whereas natively `title` (26pt) was 3.25x larger than `display` (8pt) and was the element the 2026-07-19 rubric scored as dominant | **Hierarchy inversion — see Deviations §2 above; flagged for Plan 05, not scored here** |

**Invoice-before/after (D-05 Commit 1 survival, cited here for the Plan 05 evidence bundle):** the themed `invoice.png` still shows the full issuer/customer/totals anatomy (Rendro Systems letterhead, Bill To: Acme Phoenix SaaS, Due/Terms, Subtotal/Tax/Total) — the Phase-115 DATA fix (locked as a test in 123-01) visibly survived into the themed render.

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The 11-row gallery, its `theme_tag`/`mode_tag`/`readme_hero` seam, and the fresh themed glyph-height deltas are ready for Plan 05's honest re-score and human sign-off (D-02).
- Plan 05's evidence bundle should draw on this SUMMARY's glyph-height table AND the 3 newly-discovered findings (Invoice dark illegibility, Ticket inversion, Payslip wrap) — the human sign-off should explicitly consider whether these affect the `passed:true` re-score for Ticket and Payslip specifically (Certificate and the other 4 demos are unaffected by new findings).
- `priv/quality/rubric_scores.json` is untouched — Commit-2 isolation (D-05) is intact; Plan 05 is free to do the score-flip commit independently.
- 3 open items in `.planning/WINDOWS.md` (ids 1–3, kind `deviation`) will block `/gsd-ship` until triaged — a future phase/plan should either fix or explicitly waive each.

## Self-Check: PASSED

All 4 new gallery PNGs, `artifacts.json`, `lib/rendro/launch_artifacts.ex`, `lib/rendro/recipes/receipt.ex`, the updated claims test, and `.planning/WINDOWS.md` were verified present on disk; both task commits (`be64152`, `53e1ba7`) were verified present in `git log`.

---
*Phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani*
*Completed: 2026-07-28*

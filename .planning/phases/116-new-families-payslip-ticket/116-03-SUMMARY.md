---
phase: 116-new-families-payslip-ticket
plan: 03
subsystem: recipes
tags: [elixir, pdf, ticket, image-validation, decimal-free, tdd]

# Dependency graph
requires:
  - phase: 116-new-families-payslip-ticket (plan 01)
    provides: "Rendro.Recipes.Pagination.label_resolver/2, validate_labels!/2, validate_formatters!/2 (D-18/D-19 shared opts seams)"
provides:
  - "Rendro.Recipes.Ticket.document/2 (3-rung pattern) -- archetype-agnostic event/boarding-pass ticket, D-02 placement-grid anchor, D-05/D-06/D-07/D-08/D-09 stub composition"
  - "D-10: the first caller-supplied (not library-shipped) image asset pre-validation pattern in this codebase -- Rendro.AssetRegistry.InvalidAssetError never leaks past validate_data!/1"
affects: [116-04-registration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Zero-height Path-block overlay mechanic (paginate.ex anchor_region_blocks/3) reused for a THIRD time (after Certificate's frame, Payslip's summary band) -- perforation + code-box backdrop both height: 0 so following content overlays them"
    - "D-02 placement grid as a single-row Rendro.table/2 with Block-styled header cells (small caps labels) and large value cells, borders: :none -- not manual multi-column block stacking"
    - "Caller-supplied image pre-validation: mirror asset_registry.ex's exact {:binary,_}/{:path,_} source-resolution logic inside validate_data!/1, pre-parse with the pure Rendro.ImageParser.parse/1, raise a four-part ArgumentError naming the exact data path before register_image/3 ever runs"

key-files:
  created:
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/ticket_test.exs
    - test/rendro/recipes/ticket_byte_identity_test.exs
  modified: []

key-decisions:
  - "main_section/2's D-02 anchor uses Rendro.table/2 with ONE data row and Block-wrapped header cells (not a hand-stacked multi-column layout) -- sidesteps anchor_region_blocks/3's shared per-region Y cursor, exactly as the plan's read_first anticipated"
  - "stub_section/2's code-box side length is min(stub_width, band_h) - 2*12.0pt, computed from D-03 geometry (never hardcoded) -- verified >= 100pt at A4-default (120.41pt actual)"
  - "Full-render PNG tests use priv/branded/images/rendro-logo.png ({:path, ...}) instead of the minimal 2x2 base64 fixture from image_parser_test.exs -- the minimal fixture's IDAT stream passes ImageParser.parse/1's header-only check (used for validate_data!/1 tests) but is not decodable by the PDF writer's stricter Rendro.PDF.PNG chunk decoder, which only surfaces when a document with the image is actually rendered"

patterns-established:
  - "Ticket is the second recipe (after Payslip) to consume Pagination.label_resolver/2's arity-2 default_labels seam and the D-19 validate_labels!/validate_formatters! opts guards from 116-01"
  - "D-10's caller-image pre-validation pattern (resolve source bytes -> pure ImageParser.parse/1 -> instructive ArgumentError, before any register_image/3 call) is now available as a template for any future recipe accepting caller-supplied image assets"

requirements-completed: [FAM-02, FAM-03]

coverage:
  - id: D1
    description: "Ticket.page_template/1 derives geometry-free landscape band (:main/:stub, anchor: :fixed, role: :custom) + :terms (anchor: :flow, role: :body) from PageSize.resolve/2 with zero hardcoded A4 numerics; A4 vs US Letter differ"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#page_template/1"
        status: pass
    human_judgment: false
  - id: D2
    description: "validate_data!/1 enforces D-04 byte guards (title/subtitle/terms/placement label+value/code.reference) and D-10's caller-image pre-validation -- malformed code.image raises an instructive ArgumentError naming data.code.image, Rendro.AssetRegistry.InvalidAssetError never leaks"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#validate_data!/1 (D-04/D-10 shape/type checks)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-02 placement-grid anchor via Rendro.table/2 (single row, 22pt values under 8pt caps labels) is the single largest text on the page; the SAME code renders an event-shaped or boarding-pass-shaped :placement with zero lib/ branching (D-01)"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#sections/2 and document/2"
        status: pass
    human_judgment: false
  - id: D4
    description: "Stub composition: bordered code box always drawn (>= 100x100pt, D-05), human-readable reference ALWAYS renders even with a PNG supplied (D-06), no-PNG fallback never draws a faux barcode/QR pattern (D-07), PNG supplied fits-contain under the fixed :ticket_code logical name (D-08), dashed perforation separates :main/:stub (D-09)"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#stub_section/2 — code box, reference, perforation (D-05/D-06/D-07/D-09)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Content that cannot fit a fixed region after validate_data!/1's byte guards surfaces as the pipeline's typed :content_overflow error -- never silent truncation, never a raw crash (D-04)"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#a placement value that cannot fit the grid table's narrow column at 22pt raises :content_overflow, never a crash"
        status: pass
    human_judgment: false
  - id: D6
    description: "code.image: nil renders byte-identical to omitting :image entirely (D-08); byte-identity holds across two deterministic renders and matches a frozen sha256 golden computed by actually running the render"
    requirement: "FAM-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_byte_identity_test.exs#D-08/D-09 byte-identity baseline"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/ticket_byte_identity_test.exs#D-08: code.image nil vs omitted byte-identity"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every color read in Ticket's section builders resolves a role from palette(opts) (S1) -- no inlined color:{...}/fill:{...} literal outside palette/1"
    requirement: "FAM-03"
    verification:
      - kind: other
        ref: "grep -v '^\\s*#' lib/rendro/recipes/ticket.ex | grep -E -c 'color: \\{[0-9]|fill: \\{[0-9]' == 0"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-18
status: complete
---

# Phase 116 Plan 03: Ticket Recipe (Event/Boarding-Pass, D-02 Placement Grid, D-10 Caller-Image Pre-Validation) Summary

**`Rendro.Recipes.Ticket.document/2` on the 3-rung pattern -- a geometry-derived fixed landscape band with a D-02 placement-grid anchor (single Rendro.table/2 row, 22pt values), a D-05/D-06/D-07/D-08/D-09 stub (bordered code box, always-on human-readable reference, optional caller-supplied PNG, dashed perforation), and D-10's genuinely-new caller-image pre-validation plumbing that guarantees `Rendro.AssetRegistry.InvalidAssetError` never leaks.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-07-18T19:58:35-04:00 (approx.)
- **Completed:** 2026-07-18T20:05:36-04:00 (approx.)
- **Tasks:** 3
- **Files modified:** 3 (all created: 1 lib, 2 test)

## Accomplishments
- `Rendro.Recipes.Ticket` module: `page_template/1` (geometry-derived `:main`/`:stub` fixed landscape band + `:terms` flow region, zero hardcoded A4 numerics), `palette/1` (S1, verbatim from Invoice), `@default_labels` (7 D-18 keys), `document/2`, `sections/2`
- D-02 placement-grid anchor implemented via `Rendro.table/2` (single data row of 22pt values under 8pt small-caps labels) -- confirmed the SAME code renders an event-shaped (Section/Row/Seat) or boarding-pass-shaped (Gate/Seat/Group) `:placement` with zero `lib/` branching (D-01)
- D-10's caller-image pre-validation: the first recipe in this codebase to register a caller-supplied (not library-shipped) image asset; `validate_data!/1` mirrors `asset_registry.ex`'s exact source-resolution logic, pre-parses with the pure `Rendro.ImageParser.parse/1`, and raises an instructive four-part `ArgumentError` naming `data.code.image` on any failure -- bad path or malformed bytes -- so `Rendro.AssetRegistry.InvalidAssetError` never leaks
- Stub composition: dashed perforation (D-09) + bordered code box (D-05, >= 100x100pt derived from D-03 geometry, verified 120.41pt at A4 default) + always-on human-readable reference (D-06) + no-PNG fallback that never draws a faux barcode/QR pattern (D-07) + PNG-supplied fit-contain placement under the fixed `:ticket_code` logical name (D-08)
- `code.image: nil` renders byte-identical to omitting `:image` entirely (D-08); byte-identity holds across two deterministic renders, matching a frozen sha256 golden computed by actually running the render
- A long unbroken placement value that fits the byte guard but cannot fit the grid table's narrow column surfaces the pipeline's typed `:content_overflow` error -- confirmed empirically, never a crash
- 30 new tests (`ticket_test.exs` + `ticket_byte_identity_test.exs`), full suite green: 1340 tests / 0 failures; `mix compile --warnings-as-errors` clean

## Task Commits

Each task was committed atomically (TDD RED/GREEN pairs):

1. **Task 1: Geometry, palette, @default_labels, and validate_data!/1 (byte guards + D-10 image pre-validation)**
   - `ed4efa0` (test) -- RED: 14 failing tests for page_template/1 and validate_data!/1
   - `59c6db7` (feat) -- GREEN: page_template/1, palette/1, @default_labels, validate_data!/1, minimal document/2 stub
2. **Task 2: sections/2, document/2, and the D-02 placement-grid anchor (via Rendro.table, not manual block stacking)**
   - `22e084e` (test) -- RED: 6 failing tests for sections/2, document/2, D-02 anchor, D-01 zero-branching proof
   - `18840ee` (feat) -- GREEN: sections/2, full document/2, main_section/2 (Rendro.table anchor), stub_section/2 + terms_section/2 stubs
3. **Task 3: Stub composition (code box, reference, perforation, PNG fit-contain), overflow, byte-identity**
   - `46cdb3f` (test) -- RED: 4 failing tests + new ticket_byte_identity_test.exs (placeholder golden)
   - `d5fa5a7` (feat) -- GREEN: full stub_section/2 + terms_section/2, computed real sha256 golden

**Plan metadata:** (final docs commit follows this SUMMARY)

## Files Created/Modified
- `lib/rendro/recipes/ticket.ex` -- new module, `@moduledoc tags: [:adapter]`: `page_template/1`, `document/2`, `sections/2`, private `palette/1`, `validate_data!/1` (+ D-10 image sub-validators), `main_section/2`, `stub_section/2` (+ `code_area_blocks/6`, `reference_blocks/4`, `present_code_caption/3`), `terms_section/2`, `geometry/1`
- `test/rendro/recipes/ticket_test.exs` -- new file, 24 tests across `page_template/1`, `validate_data!/1 (D-04/D-10)`, `sections/2 and document/2`, `stub_section/2 (D-05/D-06/D-07/D-09)`, plus a recursive table-aware `collect_text_sizes/1` size collector mirroring `payslip_test.exs`'s established pattern
- `test/rendro/recipes/ticket_byte_identity_test.exs` -- new file, 3 tests: two-deterministic-renders-equal, frozen sha256 golden match, D-08 nil-vs-omitted byte-identity

## Decisions Made
- Implemented `main_section/2`'s D-02 anchor exactly per the plan's `read_first` guidance: `Rendro.table/2` with one data row and `Block`-wrapped header cells, sidestepping `anchor_region_blocks/3`'s shared per-region Y cursor that a hand-stacked multi-column layout would fight
- `stub_section/2`'s code box uses the verified zero-height overlay mechanic (already established by Certificate's frame and Payslip's summary band in this same phase) for both the perforation and the code-box backdrop
- Full-render PNG tests (Task 2's registration test, Task 3's "PNG-supplied: reference still appears" test) use `{:path, "priv/branded/images/rendro-logo.png"}` instead of the minimal 2x2 base64 PNG borrowed from `image_parser_test.exs` -- the minimal fixture's IDAT stream satisfies `ImageParser.parse/1`'s header-only check (sufficient for `validate_data!/1`'s D-10 pre-validation tests, which never render) but is not decodable by the PDF writer's stricter `Rendro.PDF.PNG` chunk decoder, which only runs when a document containing the image is actually rendered to bytes
- `code.code.label` default resolution uses `Map.get(data.code, :label) || lbl.(:reference)` rather than a three-way `case`, since both `nil` and (theoretically) an absent key collapse to the same default via `Map.get/3`'s own default-arg semantics

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Switched full-render PNG test fixtures from the minimal 2x2 base64 PNG to a real embeddable PNG file**
- **Found during:** Task 3 (GREEN implementation, running the full test suite)
- **Issue:** The minimal 2x2 base64 PNG fixture (borrowed from `image_parser_test.exs`, valid for `ImageParser.parse/1`'s header-only check) caused a `FunctionClauseError` in `Rendro.PDF.PNG.parse_chunks/2` when the PDF writer attempted to actually decode and embed it during a full `Rendro.render/1` call -- its IDAT chunk is not a genuinely well-formed compressed stream, a gap the header-only `ImageParser.parse/1` check does not catch
- **Fix:** Switched the two full-render PNG tests (Task 2's `:ticket_code` registration test, Task 3's D-06 always-on reference test) to `{:path, "priv/branded/images/rendro-logo.png"}`, a genuinely well-formed PNG the codebase already uses for this exact purpose in `test/rendro/pipeline/render_test.exs`. The minimal fixture remains in use for Task 1's `validate_data!/1` no-raise test, which only calls `ImageParser.parse/1`'s header check via `document/2` and never renders
- **Files modified:** `test/rendro/recipes/ticket_test.exs`
- **Verification:** `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs` -- 30 tests, 0 failures; full suite `mix test` -- 1340 tests, 0 failures
- **Committed in:** `d5fa5a7` (Task 3 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Test-fixture-only fix; no `lib/` behavior changed. No scope creep.

## Issues Encountered
None beyond the deviation documented above.

## User Setup Required
None -- no external service configuration required.

## Next Phase Readiness
- `Rendro.Recipes.Ticket.document/2`, `page_template/1`, and `sections/2` are fully implemented and tested, ready for 116-04's registration work (`priv/public_api.json` `@public_modules` allowlist edit + `mix rendro.api.gen`, `priv/support_matrix.json` `ticket` row)
- D-10's caller-image pre-validation pattern is now available as a reusable template for any future recipe accepting caller-supplied image assets
- Full suite (1340 tests) and `mix compile --warnings-as-errors` both green -- no regression risk carried forward into 116-04

---
*Phase: 116-new-families-payslip-ticket*
*Completed: 2026-07-18*

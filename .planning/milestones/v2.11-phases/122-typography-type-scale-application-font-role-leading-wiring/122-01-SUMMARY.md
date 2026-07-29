---
phase: 122-typography-type-scale-application-font-role-leading-wiring
plan: 01
subsystem: recipes
tags: [typography, type-scale, font-roles, leading, theme, invoice, byte-identity]

# Dependency graph
requires:
  - phase: 120-s1-retrofit-theme-swap
    provides: "per-recipe palette/1 seam + theme: threaded through all 3 rungs"
  - phase: 119-rendro-theme-core
    provides: "%Theme{} typography contract (scale/fonts/leading/widows/orphans) + Rendro.Theme.resolve/1"
provides:
  - "defp typography/1 seam on Invoice (structural twin of palette/1): no-theme literal-default scale/fonts/leading, theme branch reads Rendro.Theme.resolve(theme).typography, Map.merge :typography override layer"
  - "Every Invoice %Text{} threaded through the seam: size via scale.<role>, font via fonts.<role>, line_height/widows/orphans via leading/widows/orphans"
  - "Exactly one display-anchored Invoice element (Total Due) per D-01"
  - "TYPE-02 raise-path test proving an unregistered font role raises the exact {:unknown_text_font, _} tuple, never a silent Helvetica fallback"
  - "Retired Phase-120 D-04 'no .typography read' guard (pre-declared red->green)"
  - "Proven typography mechanism ready for mechanical replication across the remaining 6 recipes"
affects: [122-02, 122-03, 123-from-brand-rubric-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "typography/1 per-recipe seam mirroring palette/1 (case opts[:theme] nil/theme + Map.merge override tail)"
    - "no-theme literal-default typography map carrying the recipe's CURRENT size/font/leading literals (byte-identity), never Rendro.Theme.default().typography"
    - "font role atoms (:default) normalize identically to the implicit \"Helvetica\" default → byte-identical font wiring"

key-files:
  created:
    - test/rendro/recipes/invoice_typography_test.exs
  modified:
    - lib/rendro/recipes/invoice.ex
    - test/rendro/recipes/invoice_opts_threading_test.exs
    - test/rendro/recipes/no_inline_color_literals_test.exs

key-decisions:
  - "Separate typography/1 seam (not folded into palette/1) — keeps color and type concerns distinct, mirrors palette/1 verbatim"
  - "Invoice reads fonts.mono (title/totals amounts/IDs) and fonts.body (prose/labels); fonts.heading is unused on Invoice, so the TYPE-02 raise-path targets fonts.mono/fonts.body (behavior explicitly permits .mono/.body)"
  - "Live-seam test overrides typography leading (threaded onto every block) rather than scale.display (only present with totals) to guarantee the assertion is non-vacuous for any data"

patterns-established:
  - "typography/1 seam: the exact template the remaining 6 recipes replicate mechanically"
  - "no-theme literal-default map dictated by (not designed from) each recipe's current typographic literals"

requirements-completed: [TYPE-01, TYPE-02, TYPE-03]

coverage:
  - id: D1
    description: "Invoice type scale (display 20 / title 18 / subtitle 12 / body 10 / small 9) materialized in a defp typography/1 seam and threaded into every %Text{size}, with exactly one display anchor (Total Due)"
    requirement: TYPE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_byte_identity_test.exs#fresh render sha256 matches the frozen pre-Phase-115 golden"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/invoice_opts_threading_test.exs#a :typography override changes the output (live seam)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invoice font roles resolve through FontRegistry; an unregistered role in theme.typography.fonts raises {:unknown_text_font, _} via Build.run/1, never a silent Helvetica substitute"
    requirement: TYPE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_typography_test.exs#an unregistered fonts.mono atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1"
        status: pass
    human_judgment: false
  - id: D3
    description: "leading -> %Text{line_height} plus widows/orphans threaded onto every Invoice text block; no-theme path reproduces today's exact 1.2/2/2 (metric no-op)"
    requirement: TYPE-03
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs (leading/widows/orphans no-op, byte-identical)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/invoice_byte_identity_test.exs#two deterministic renders are byte-identical"
        status: pass
    human_judgment: false
  - id: D4
    description: "Phase-120 D-04 'no .typography read' guard relaxed/removed so the .typography read is legal; color-literal scan stays green"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs#no recipe section builder inlines a literal {r,g,b} color tuple (PLUMB-02)"
        status: pass
    human_judgment: false

# Metrics
duration: 18min
completed: 2026-07-27
status: complete
---

# Phase 122 Plan 01: Seam Invoice typography end-to-end Summary

**Invoice fully typography-seamed across TYPE-01/02/03 via a new `defp typography/1` (twin of `palette/1`) — type scale, font roles, and leading/widows/orphans threaded through every `%Text{}` with byte-identity preserved (zero re-bless) and a TYPE-02 raise-path proven with teeth.**

## Performance

- **Duration:** ~18 min
- **Tasks:** 2 (1 tracer + 1 TDD test task)
- **Files modified:** 3 modified + 1 created

## Accomplishments
- Added `defp typography/1` to `invoice.ex` — a structural twin of `palette/1`: `case opts[:theme]` split (nil → per-recipe literal defaults, theme → `Rendro.Theme.resolve(theme).typography`) with a `Map.merge(base, Keyword.get(opts, :typography, %{}))` override tail.
- Threaded every Invoice `%Text{}` call site through the seam: Total Due amount → `scale.display` (the **sole** D-01 anchor) + `fonts.mono`; `INVOICE #<id>` → `title` + `mono`; party name → `subtitle` + `body`; Date/thank-you/due/terms/muted → `body` + `body`; minor totals → `small` + `mono`. Every block also gained `line_height`/`widows`/`orphans`.
- Preserved the frozen INV-01 byte-identity golden with **zero re-bless** (literal defaults equal the prior 18/10/12/10/9/20 sizes; `:default` fonts normalize identically to the implicit `"Helvetica"`; leading/widows/orphans equal the `%Text{}` struct defaults).
- Proved the TYPE-02 raise-path: an unregistered `fonts.mono`/`fonts.body` atom in a themed Invoice surfaces the exact `{:error, {:unknown_text_font, :no_such_font}}` from `Build.run/1`.
- Retired the Phase-120 D-04 "no `.typography` read" guard (pre-declared red→green); the color-literal scan test stays intact and green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Seam Invoice typography end-to-end (tracer)** - `21a3005` (feat)
2. **Task 2: Prove the seam live + TYPE-02 raise-path (TDD, test-only)** - `e027732` (test)

## Files Created/Modified
- `lib/rendro/recipes/invoice.ex` - Added `defp typography/1` seam; threaded every `%Text{}` (header pair, footer, issuer/customer/due/terms anatomy blocks, minor + dominant totals) through it; retired `@minor_totals_size`/`@dominant_total_size` (folded into the scale seam); updated the INV-01 freeze comment.
- `test/rendro/recipes/invoice_typography_test.exs` - NEW: TYPE-02 raise-path proof (`Build.run/1` exact typed tuple) on `fonts.mono` and `fonts.body`, plus a clean-build no-false-raise guard.
- `test/rendro/recipes/invoice_opts_threading_test.exs` - Added a `typography(opts) seam` describe: `typography: %{}` no-op + `:typography` leading-override live-seam.
- `test/rendro/recipes/no_inline_color_literals_test.exs` - Removed the D-04 `.typography`-read assertion and its moduledoc claim.

## Decisions Made
- **Separate `typography/1` seam** rather than folding into `palette/1` — keeps color and type concerns distinct and copies `palette/1` verbatim (research primary recommendation).
- **Raise-path targets `fonts.mono`/`fonts.body`, not `fonts.heading`.** Invoice reads only `mono` (title/totals) and `body` (prose/labels); `heading` is never read on Invoice, so a bad atom in `heading` would not surface. The plan's behavior explicitly permits `.mono`/`.body`.
- **Live-seam test overrides `leading`** (threaded onto every block) instead of `scale.display` (only rendered when `:totals` present) so the `refute equal` assertion is non-vacuous for the toy sample data.

## Deviations from Plan

None - plan executed exactly as written. (The plan's own `<behavior>` explicitly permitted targeting `.mono`/`.body` for the raise-path; selecting `mono`/`body` — the roles Invoice actually reads — is within the plan, not a deviation.)

## Issues Encountered
None. Byte-identity held on the first run; the `:default` font atom normalizing to the document default logical font (verified in `font_registry.ex` `normalize_reference/2`) was confirmed before wiring, so no re-bless was ever at risk.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The `typography/1` mechanism is proven end-to-end on one recipe (no-theme byte-identical, themed live, raise-path with teeth). Wave-2 expansion (plans 122-02/122-03) is now pure mechanical replication of this seam across BrandedInvoice/Statement/Receipt/Certificate/Payslip/Ticket.
- Known replication risks already flagged in RESEARCH: BrandedInvoice (no Total-Due `%Text` run + brand-font literal-default), Certificate (measurement-coupled `@*_size` attrs), Ticket (7 distinct sizes vs 6 roles). All three resolved in `122-03-PLAN.md` per RESEARCH Open Questions Q1/Q2/Q3.

## Self-Check: PASSED

All created/modified files exist on disk; both task commits (`21a3005`, `e027732`) are present in git history.

---
*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Completed: 2026-07-27*

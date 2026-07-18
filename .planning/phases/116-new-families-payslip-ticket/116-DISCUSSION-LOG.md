# Phase 116: New families — Payslip & Ticket - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 116-new-families-payslip-ticket
**Areas discussed:** Ticket archetype & geometry, Payslip anchor & layout, Jurisdiction/label contract, Ticket code-area & no-PNG fallback

**Method:** User selected all four gray areas and requested a deep parallel-subagent research pass producing a single coherent, one-shot locked recommendation set — evaluated through software-architecture, API/DX (consumer's perspective), graphic-design/creative-direction, user-psychology (JTBD who/what/where/when/why), and the design pillars (accessibility, determinism, print-safety, coherence, DX). Four `general-purpose` agents ran concurrently; findings synthesized into CONTEXT.md.

---

## Ticket archetype & geometry

| Option | Description | Selected |
|--------|-------------|----------|
| Airline boarding pass | Landscape strip, vertical tear-off stub, gate/seat/group + route | |
| Event/admission ticket (default) + generic data-driven anchor under the hood | Section/Row/Seat anchor as an ordered labeled placement grid; boarding-pass/transit reachable by data + labels, no archetype logic in `lib/` | ✓ |
| Transit/rail | Origin→destination + class/zone; weakest anchor | |
| Fully generic pass with no concrete default | Maximum reach but renders shapeless without a default archetype | |

**Research choice:** One `Rendro.Recipes.Ticket` family; concrete default = event/admission ticket (Aurora Live fixture); anchor = data-driven `:placement => [%{label, value}]` with oversized values. Geometry derived from `PageSize.resolve/2` (Certificate idiom), A4 portrait default with a fixed landscape band at the top, vertical perforation splitting main (~68%) / stub (~32%). See CONTEXT D-01..D-04.
**Notes:** Tie-breakers — the milestone's fixture business is a live-events company, REQUIREMENTS names the anchor "seat/**gate**/section" (event-first, air-reachable), and event/admission is the most universally recognizable "ticket." Keeps family-not-industry + locale-free-by-data.

---

## Payslip anchor & layout

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full-width tinted NET PAY band under identity header + one combined ledger table (Earnings·Cur·YTD ‖ Deductions·Cur·YTD), per-line YTD column | Paginates natively via the existing chunker; reuses `cell_align`; answer-first reading order; hierarchy=5 | ✓ |
| B — Two truly separate `anchor:fixed` earnings/deductions tables | Most domain-true but cannot paginate; harder shared baseline | |
| C — Top-right net-pay box (Statement-style) | Competes with pay-period block; weaker anchor | |
| D — Bottom summary line | Matches literal ADP order but forces the reader to hunt for the #1 fact | |

**Research choice:** Option A. Net-pay as a full-width tinted band (26–28pt, second in reading order); one combined ledger table with mid vertical rule and right-aligned money; per-line YTD columns; kept-with-last reconciliation (`Gross − Deductions = Net`, asserted via `Decimal.equal?/2`) + YTD summary trio; 4-region template. See CONTEXT D-11..D-15.
**Notes:** Single-table pagination is the decisive factor — it reuses `Pagination.chunk_rows_into_pages/2`; fixed side-by-side regions can't paginate. `cell_align: :right` (Phase 115) obsoletes the old "fake right-align" caveat. PII masking mandatory in fixtures (acute risk for this family). No new engine surface.

---

## Jurisdiction/label contract

| Option | Description | Selected |
|--------|-------------|----------|
| A — Reuse incumbent `:labels`(map)/`:formatters`(keyword)/`:palette`(map) seams; statutory content in line `:description`; ship recipe-owned `@default_labels` | Zero new mechanism; byte-coherent with Statement/Invoice; engine never learns a jurisdiction; forward-compat with B theming | ✓ |
| B — Payslip-specific "jurisdiction profile" / named `:profile` atom | Forks the recipe opts convention; pushes jurisdiction knowledge toward the engine (out of scope) | |
| C — Labels embedded per line item only | Correct for line content but the chrome labels still need a home | partial (line content only) |

**Research choice:** A + statutory line content as `:description` data + `:formatters` for money/date. Generalize `Pagination.label_resolver` to arity-2 (`opts[:labels] → recipe @default_labels → Format.label/1`), keeping `Rendro.Format` frozen at its 5 keys. Add errors-as-product opts-shape validation (labels = map of non-empty binaries; formatters = keyword of arity-1 fns). No jurisdiction profile. See CONTEXT D-16..D-19.
**Notes:** "This is a UK payslip" = UK line `:description`s + a `£` money formatter + a `DD/MM` date formatter + optional label overrides — same recipe, zero engine change. Never render a blank/humanized label fallback (would destroy the anchor).

---

## Ticket code-area & no-PNG fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Bordered code box + always-present human-readable reference; no faux code | Reads as a ticket via box presence; honest; deterministic; reference is the resilience/accessibility affordance | ✓ |
| Hatched/diagonal placeholder | Looks broken/missing-asset, not intentional | |
| Reference text only, no box | Loses the ticket motif | |
| Faux drawn barcode/QR | Dishonest — fails at a real scanner; violates brand voice | rejected hard |

**Research choice:** Always draw a bordered `{:rounded_rect}` code box (≥100×100pt) with the human-readable reference always rendered (even with a PNG). No PNG → centered reference + optional caption. PNG → deterministic fit-contain, never stretch. Perforation = dashed `%Rendro.Path{}` (`dash:[3,3]`, 0.75pt) derived from the stub boundary, omitted when no stub. Bad image → instructive `ArgumentError` via pure `ImageParser.parse/1`; overflow → typed `:content_overflow`. All existing primitives — no new engine surface. See CONTEXT D-05..D-10.
**Notes:** Emulates IATA BCBP / Apple Wallet `altText` (reference always beside the code). Honesty guard: no faux scannable codes, no accessibility overclaim.

---

## Claude's Discretion

- Exact point sizes, tint depth, gutter widths, caption default strings, column-share ratios — refinable within the locked hierarchy/pattern (anchor stays dominant, money right-aligned, colors via `palette(opts)`).
- Optional accent element (ticket-type pill / emphasis bar) — discretionary if sourced from `palette.accent`/`on_accent`.

## Deferred Ideas

- Live barcode/QR generation primitive — out of scope.
- Engine locale-awareness (CLDR/gettext/ex_money) — out of scope by construction.
- Boarding-pass/transit as distinct recipes or named jurisdiction profiles — rejected; same recipe via data. Opinionated presets belong to Milestone C.
- Ticket tear-notch half-circles (`{:curve}`) — gold-plate, defer.
- Invoice/Statement retrofitting arity-2 `label_resolver` + opts validation — additive, out of scope here.
- `Rendro.Theme` palette threading — Milestone B; seam already shaped for a one-line swap.

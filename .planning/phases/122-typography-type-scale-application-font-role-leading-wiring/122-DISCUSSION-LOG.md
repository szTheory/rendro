# Phase 122: Typography type-scale application + font-role/leading wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 122-typography-type-scale-application-font-role-leading-wiring
**Areas discussed:** Approach (research-first lock of all 3 gray areas)

---

## Approach — how to proceed after research

Claude analyzed the phase, established that the byte-identity mechanism is
**forced** (no-theme path keeps per-recipe literal metrics; theme's `typography`
read only when `theme:` is passed — confirmed by un-themed edge/recipe goldens),
and presented locked recommendations for the 3 genuine gray areas.

| Option | Description | Selected |
|--------|-------------|----------|
| Lock all 3 & write CONTEXT | Accept all three recommendations as-is (research-first one-shot); write CONTEXT.md with per-recipe display-anchor mapping, full font-role seam incl. mono, uniform leading/widows/orphans threading. | ✓ |
| Open ① scale mapping | Discuss per-recipe role assignments + display-anchor dominance. | |
| Open ② font-role / mono | Discuss font-role breadth + exact mono elements. | |
| Open ③ leading breadth | Discuss leading/widows/orphans breadth + pulling `leading:1.35` forward. | |

**User's choice:** Lock all 3 & write CONTEXT.
**Notes:** Consistent with the established Rendro posture (research-first, locked
recommendations, minimal asking — matches Phase 119/120/121 zero-deferral pattern).

### Gray areas locked (recommendations presented and accepted)

**① Per-recipe role-assignment mapping (TYPE-01):** seam `size: scale.<role>`;
per-recipe literal defaults reproduce current sizes (byte-identical no-theme
path); exactly one `display` anchor per recipe (the "one key fact": invoice/
branded Total Due, receipt total, statement closing balance, payslip net pay,
ticket confirmation code, certificate recipient name); everything else mapped
down by current size rank. → CONTEXT D-01.

**② Font-role wiring breadth + mono (TYPE-02):** seam every text run to
`heading`/`body`/`mono` now (byte-identical via `:default`); `mono` for machine/
reference strings (codes, IDs, amounts); prove the unregistered-role raise-path
(`{:unknown_text_font,_}`, never silent Helvetica) with a dedicated test. →
CONTEXT D-02.

**③ leading / widows / orphans breadth (TYPE-03):** thread onto all text blocks
(metric no-op on the default 1.2/2/2 path); leave `leading:1.35` as a Phase-123
one-line change, not pulled forward. → CONTEXT D-03.

---

## Claude's Discretion

- Exact per-recipe `defp` typography seam helper naming (mirror `palette/1` or fold in).
- The precise per-element role/mono mapping tables (subject to the one-`display`-anchor
  rule + byte identity).
- Whether the 7 recipes are one slice or split.

## Deferred Ideas

- `leading: 1.35` prose realization → Phase 123 (re-bless within version).
- `default/0` value tuning, themed/dark gallery renders, support-matrix `theming.*`
  rows, `guides/theming.md`, honest SHOW-01 re-score → Phase 123.
- `density: :compact` deep multipliers → Milestone C.
- Tabular figures / small-caps / OpenType mono refinements → demand-gated.
- Applying Certificate's registered-but-unapplied brand font → planner's call within
  D-02 (byte-identity binding) or defer.

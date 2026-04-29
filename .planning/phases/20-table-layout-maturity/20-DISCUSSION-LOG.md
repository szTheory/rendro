# Phase 20: Table Layout Maturity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 20-table-layout-maturity
**Areas discussed:** column sizing, row split policy, continuation behavior, truthful public table API surface

---

## Column sizing

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed equal-width columns | Simplest deterministic model; stays close to current implementation | |
| Deterministic measured auto-sizing | Widths derive from measured cell content | |
| Explicit authored column rules | Caller authors deterministic widths/shares directly | ✓ |
| Hybrid auto + explicit overrides | Auto-sizing default with authored escape hatches | |

**User's choice:** Delegated to the agent; recommendation selected after research synthesis.
**Notes:** Recommendation selected explicit authored column rules over auto-sizing to keep width ownership obvious, deterministic, and coherent with Rendro's existing block-geometry contract.

---

## Row split policy

| Option | Description | Selected |
|--------|-------------|----------|
| Never split rows | Rows are atomic; oversized rows fail | ✓ |
| Split rows automatically | Engine fragments tall rows across pages | |
| Author-selectable split policy | Explicit policy surface with default | |
| Best-effort hidden fallback | Engine chooses splitting heuristically | |

**User's choice:** Delegated to the agent; recommendation selected after research synthesis.
**Notes:** Recommendation selected atomic rows and truthful failure over cell fragmentation. Future policy surface can evolve later, but Phase 20 should not ship hidden fallback behavior.

---

## Continuation behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Repeat headers only | Continuation pages repeat the table header row | |
| Repeat headers + automatic continuation labels | Core table injects "continued"-style chrome | |
| Manual continuation only | Caller authors all continuation behavior | |
| Region-aware repeated headers + authored continuation chrome | Core repeats headers; continuation labels stay outside the table primitive | ✓ |

**User's choice:** Delegated to the agent; recommendation selected after research synthesis.
**Notes:** Recommendation selected repeated headers as the core default while keeping continuation copy authored via templates/regions/recipes to avoid opinionated hidden chrome.

---

## Truthful public table API surface

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current fields and document them better | Preserve `width`/`border` despite limited semantics | |
| Remove or deprecate unsupported fields | Shrink surface until behavior is real and tested | ✓ |
| Redefine current fields narrowly | Keep names but assign new constrained semantics | |
| Add a richer styling DSL now | Broaden table API substantially in Phase 20 | |

**User's choice:** Delegated to the agent; recommendation selected after research synthesis.
**Notes:** Recommendation selected truthful surface cleanup over documentation-only mitigation. Current `%Rendro.Table{}` fields imply behavior the engine does not actually honor.

---

## the agent's Discretion

- Exact field names and syntax for the explicit column-rule API.
- Whether unsupported table fields are hard-removed immediately or first deprecated before removal.
- Exact error-detail payload for impossible single-row fits.

## Deferred Ideas

- Hybrid or measured auto-sizing as a later ergonomics layer.
- True split-row / cell-fragmentation support.
- Automatic continuation labels or localized continuation chrome in core.
- Rich table styling DSL and broader border semantics.

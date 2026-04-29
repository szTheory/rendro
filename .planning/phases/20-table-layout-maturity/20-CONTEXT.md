# Phase 20: Table Layout Maturity - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace Rendro's demo-grade table sizing and split logic with a deterministic multi-page table contract suitable for invoices and reports. This phase covers explicit column sizing rules, row-integrity pagination, repeated headers on continuation pages, and public API/docs cleanup where the current table surface implies unsupported behavior. It does not broaden into break diagnostics, rich table styling, automatic continuation copy, or true cell-fragmentation layout.

</domain>

<decisions>
## Implementation Decisions

### Column Geometry Contract
- **D-01:** Table column sizing should become an explicit authored contract, not a content-heuristic auto-layout algorithm.
- **D-02:** Phase 20 should support a narrow deterministic column-rule model based on explicit authored widths/shares rather than measured auto-sizing defaults.
- **D-03:** Table geometry resolves inside the enclosing block/body-region width; table width should not remain an independent implied layout system on `%Rendro.Table{}`.

### Row Integrity and Split Policy
- **D-04:** Rows are atomic by default. Phase 20 should never fragment a single row across pages as an implicit fallback.
- **D-05:** If a measured row cannot fit even on a fresh page/body region, Rendro should fail truthfully through the existing typed paginate overflow contract rather than splitting, shrinking, clipping, or silently relaxing constraints.
- **D-06:** Best-effort or hidden fallback row splitting is explicitly out of scope because it conflicts with Rendro's deterministic hard-constraint posture from Phase 19.

### Continuation Behavior
- **D-07:** Split tables should repeat header rows automatically on every continuation page.
- **D-08:** Header repetition must remain body-region-aware and deterministic under the Phase 18 page-template/region model.
- **D-09:** Rendro should not inject automatic "continued" labels or other continuation chrome inside the core table primitive.
- **D-10:** If callers want continuation copy or branded page chrome, that should be authored through page templates, regions, or higher-level recipes outside the core table primitive.

### Public Surface Truthfulness
- **D-11:** Unsupported `%Rendro.Table{}` affordances that currently imply behavior the engine does not honor (`width`, `border`) must be removed or deprecated in Phase 20 rather than retained as misleading no-op surface area.
- **D-12:** Phase 20 should not introduce a rich table styling DSL. The focus is deterministic layout maturity, not broad styling semantics.
- **D-13:** Public docs and examples must teach the truthful table contract: explicit column rules, repeated headers, atomic rows, and typed overflow failure when authored content cannot fit.

### Recommendation-First Workflow Posture
- **D-14:** The user delegated all Phase 20 gray areas to research-backed recommendations and wants this recommendation-first posture shifted left within future GSD discuss/research/planning flows by default, except for unusually high-impact policy decisions.

### the agent's Discretion
- Exact public field names and builder syntax for the explicit column-rule contract, as long as sizing remains authored and deterministic rather than heuristic.
- Whether unsupported table fields are hard-removed immediately or first deprecated with narrow migration guidance, as long as the public contract is truthful by the end of Phase 20.
- Exact overflow detail keys for impossible single-row fits, as long as the failure stays typed and actionable through the existing paginate error surface.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 20 goal, success criteria, and dependency on Phase 19.
- `.planning/REQUIREMENTS.md` — `LAY-10` requirement for deterministic multi-page tables.
- `.planning/PROJECT.md` — milestone constraints, architecture boundaries, and truthful-scope posture.

### Prior Phase Contracts
- `.planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md` — bounded-region fit validation, region-aware overflow metadata, and renderer-aligned table measurement precedent.
- `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md` — hard keep/fail semantics, explicit break surface, and recommendation-first posture.
- `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-RESEARCH.md` — notes that table-row integrity belongs in Phase 20 and should build on measured flow semantics.
- `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md` — impossible keep groups fail truthfully rather than relaxing constraints.
- `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-03-SUMMARY.md` — measured line rendering path and docs-truthfulness precedent for public semantics.

### Current Public Contract and Integration Framing
- `README.md` — current narrow-contract public guidance and examples that Phase 20 must keep truthful.
- `guides/integrations.md` — adapters do not define layout semantics; core table behavior must remain a Rendro-core contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/pipeline/measure.ex`: already owns deterministic text measurement and is the natural place to resolve explicit column widths plus measured row heights.
- `lib/rendro/pipeline/paginate.ex`: already owns flow pagination, table splitting, repeated headers, and typed overflow failures; Phase 20 should extend this seam rather than invent a second pagination path.
- `lib/rendro/pdf/writer.ex`: already renders measured text lines deterministically and is the existing seam for table-cell rendering once column/row geometry becomes real.
- `lib/rendro/error.ex`: already exposes stable paginate failure guidance and details; impossible row fits should extend this contract instead of creating a new top-level error family.
- `test/rendro/flow_test.exs`, `test/rendro/pipeline/measure_test.exs`, `test/rendro/pipeline/paginate_test.exs`: existing public and pipeline-level regression surfaces for Phase 20 semantics.

### Established Patterns
- Geometry is measured before pagination and then enforced in `Paginate`; table behavior should follow the same `measure -> paginate -> render` flow already established for wrapped text.
- Phase 19 locked a hard-constraint posture: impossible authored layout should fail truthfully instead of silently relaxing semantics.
- Phase 18 locked region-aware flow pagination and actionable overflow metadata; table continuation must remain aligned with authored body regions.
- Public docs are treated as contract, so API fields that are not fully honored should not remain visible as implied capability.

### Integration Points
- `%Rendro.Table{}` and `Rendro.table/2` are the public surface where the explicit column-rule contract must land.
- `Rendro.Recipes.invoice/1` and `Rendro.Adapters.Accrue.recipe/1` are immediate business-document consumers that should benefit from the new table contract.
- README and docs-contract tests will need to move from today's demo table examples to Phase 20's truthful serious-table surface.

</code_context>

<specifics>
## Specific Ideas

- User preference for this phase: delegate routine tradeoff resolution to research-backed recommendations rather than interactive option menus.
- Recommendation synthesis for Phase 20:
  - explicit authored column rules, not auto-sizing magic
  - atomic rows by default with truthful overflow on impossible fits
  - repeated headers on continuation pages
  - no automatic continuation labels in core
  - remove or deprecate misleading table fields instead of documenting around them
- Key ecosystem lessons captured during discussion:
  - mature libraries often support repeated headers and explicit widths, but auto-layout and cell fragmentation are common footguns
  - successful systems expose styling/continuation chrome only when semantics are explicit and fully implemented

</specifics>

<deferred>
## Deferred Ideas

- Measured content-based auto-sizing or hybrid auto-sizing as future sugar once diagnostics and invariants are stronger.
- True cell fragmentation / split-row layout for tall prose cells.
- Automatic continuation labels, localized continuation copy, or other built-in continuation chrome.
- Rich table styling DSL or broad border system beyond the minimal truthful layout contract.

</deferred>

---

*Phase: 20-table-layout-maturity*
*Context gathered: 2026-04-29*

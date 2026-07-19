# Phase 118: Rubric-gated demonstration set, gallery & docs closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-19
**Phase:** 118-Rubric-gated demonstration set, gallery & docs closure
**Areas discussed:** Corpus scope, Gallery source & membership, Rubric scoring process, S6 tags + accessibility/wording guards

---

## Corpus scope

| Option | Description | Selected |
|--------|-------------|----------|
| 6 families, 1 business each (+DOMAIN.md) | Author one realistic priv/examples fixture + co-located DOMAIN.md per family; six demos total. | ✓ |
| New families only, cite existing DOMAIN.md | Only build Payslip+Ticket fixtures; render legacy families from toy-ish data citing the shared DOMAIN.md. | |
| True grid (families × multiple businesses) | Multiple named businesses per family. | |

**User's choice:** 6 families, 1 business each (+DOMAIN.md)
**Notes:** Reuse the already-named businesses (Invoice = acme-phoenix-saas; Payslip/Ticket = Aurora Live); one business per family. The multi-business catalog grid is deferred to Milestone C.

---

## Gallery source & membership

| Option | Description | Selected |
|--------|-------------|----------|
| Repoint to priv/examples via Rendro.Examples | Gallery loads realistic fixtures through the loader; demos + gallery share one data source; add Payslip+Ticket. | ✓ |
| Add Payslip/Ticket, keep inline data realistic | Keep hardcoded @gallery_specs, enrich inline data, append the 2 new families. | |
| Keep branded_invoice in gallery? | Orthogonal sub-question (not separately answered). | |

**User's choice:** Repoint to priv/examples via Rendro.Examples
**Notes:** branded_invoice sub-question was not separately answered → Claude locked a default: keep branded_invoice (dropping a shipped asset would regress the gallery + manual). Net gallery = 7 tiles.

---

## Rubric scoring process

| Option | Description | Selected |
|--------|-------------|----------|
| Claude renders→rasterizes→self-scores w/ justification | Render → pdfium raster → score each dimension against anchors + record per-dimension justification. | ✓ |
| Scores authored, justification light | Assign passing scores with minimal rationale. | |
| Human UAT scores the demos | Defer subjective scoring to a human review pass. | |

**User's choice:** Claude renders→rasterizes→self-scores w/ justification
**Notes:** Passing is a hard, earned gate (D-11) — a demo that can't honestly reach thresholds is improved, not inflated. `justifications` object added via the schema's `additionalProperties: true`. demo_ids kept disjoint from Phase-117 stress-fixture ids.

---

## S6 tags + accessibility/wording guards

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit-null seams + new overclaim docs-contract test | theme/mode/preset as explicit-null keys now; add a "production-grade" vs PDF-UA/tagged-PDF overclaim guard test. | ✓ |
| Omit tags until populated, guard via README review only | Defer S6 keys to C; manual README review for the wording guard. | |

**User's choice:** Explicit-null seams + new overclaim docs-contract test
**Notes:** Mirrors the existing branding_claims_test.exs tripwire discipline. Reading-order stays a rubric gate, never a public accessibility claim.

---

## Claude's Discretion

- Exact fictional business names + data content for the three legacy-family fixtures (Statement/Receipt/Certificate).
- Whether the demonstration set is a dedicated module/manifest or folds into `@gallery_specs` (shared fixture source required either way).
- Whether to strengthen `DomainMdContractTest` to require a DOMAIN.md per demonstrated domain.
- `justifications` wording, the S6 placeholder convention (null vs "default"), and the "production-grade" guard word list.
- Whether the demos exercise A4/Letter geometry variation (showcase nicety).

## Deferred Ideas

- Families × multiple-businesses catalog grid → Milestone C.
- Real S6 theme/mode/preset values → Milestones B/C.
- brand/logo S4 slot population → Milestone C.
- A4/Letter geometry showcase variation → optional.
- Invoice/Statement opts-shape typed-error retrofit → future additive phase.
- Wire-or-delete `Rendro.I18n.Analyzer.analyze/1` → future cleanup phase.

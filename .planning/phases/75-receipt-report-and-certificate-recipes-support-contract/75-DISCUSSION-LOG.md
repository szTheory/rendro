# Phase 75: Receipt/Report and Certificate Recipes + Support Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 75-receipt-report-and-certificate-recipes-support-contract
**Areas discussed:** Receipt/Report recipe topology, Certificate orientation
**Mode:** advisor (`minimal_decisive` tier — opinionated vendor philosophy). Two genuinely owner-level decisions (new public API + product look) surfaced to the user; the rest researched/grounded in the Phase 73/74 codebase and locked decisively per profile.

---

## Receipt/Report recipe topology (RCPT-01/02/03)

| Option | Description | Selected |
|--------|-------------|----------|
| One Receipt recipe | Single `Rendro.Recipes.Receipt` scaling 1→N pages; report = receipt that overflows; reuses Statement's table-continuation + page-number machinery. Smallest public surface, one mental model/guide. | ✓ |
| Two recipes: Receipt + Report | Separate `Receipt` (single-page) + `Report` (multi-page tabular). Matches literal naming, focused contracts, but doubles public surface/docs and shares ~all machinery. | |

**User's choice:** One Receipt recipe.
**Notes:** New public API on a shipped lib — escalated per user profile. Multi-page "report" behavior (RCPT-03) proven by feeding many line items through the same recipe.

---

## Certificate orientation (CERT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Landscape default | Classic diploma/award look; coords still fully geometry-derived so portrait stays reachable; multi-size test covers A4-landscape vs US-Letter-landscape. | ✓ |
| Portrait default | Consistent with all existing recipes/templates; landscape reachable via swapped dims; less certificate-like default. | |

**User's choice:** Landscape default.
**Notes:** Implemented as geometry only (width/height swap) — orientation is not a separate engine concept. Visual/product choice owned by the user.

---

## Claude's Discretion (locked decisively, not asked)

- **`Recipes.Base`-style shared-helper extraction** (D-04): extract Statement's chunking/measure/footer machinery into a private shared module; refactor Statement onto it; keep private (public would need escalation). Architecture decision per profile.
- **Support-matrix row shape for recipe/PAGE surfaces** (D-09/D-10): recipes are non-viewer-sensitive surfaces → `supported` with determinism + structural-proof evidence, not a per-viewer matrix; five terminal rows; backfill Statement; satisfy JSON-Schema validator + docs-contract lane.
- **Certificate geometry derivation + page-size helper** (D-06/D-07): all coords derived from `width`/`height`/margins; add a pure `:a4`/`:us_letter` page-size helper for the multi-size test.
- Module layouts, validation message wording, required-key sets, evidence-file layout, exact support-matrix key names — all standard within the established recipe pattern.

## Deferred Ideas

- Public `Rendro.Recipes.Base` module (ships private this phase).
- Separate `Rendro.Recipes.Report` module (folded into Receipt).
- Conventional Debit/Credit display columns; locale-aware formatting in core (carried from Phase 74; `:formatters` is the i18n path).
- Aligning Invoice/BrandedInvoice onto `Rendro.Format` and geometry-derived coords.
- Reference Phoenix app + HexDocs guides + CONTRACT-02 (Phase 76).
</content>

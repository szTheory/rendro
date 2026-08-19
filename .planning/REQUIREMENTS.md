# Requirements: Rendro — v2.13 Quality Ratchet & Adoption Readiness

**Defined:** 2026-08-19
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

This is a stewardship milestone. It strengthens the shipped catalog and public Phoenix evaluation path using current evidence, without adding a new core capability family, runtime dependency, or outreach program.

## v2.13 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Catalog Quality

- [ ] **CATALOG-06**: Maintainer applies targeted visual-hierarchy improvements to all 12 currently scored `needs_work` catalog cells without adding recipes, presets, or catalog entries.
- [ ] **CATALOG-07**: The Humanist dark Receipt specifically addresses its recorded reader-affordance, typographic-craft, and cohesion deficits while retaining its screen-oriented, non-print-safe boundary.
- [ ] **CATALOG-08**: The complete 32-cell catalog regenerates deterministically and passes the existing artifact, hash, schema, and coverage checks after the visual changes.
- [ ] **CATALOG-09**: A human re-reviews all 12 current pinned-raster outputs at full size; each disposition is tied to the reviewed artifacts, and any cell that still misses a threshold remains honestly marked `needs_work`.

### Adoption Evidence

- [ ] **SIGNAL-02**: Maintainer records a dated Hex download snapshot from the public package API, including source and raw totals.
- [ ] **SIGNAL-03**: Maintainer reviews public issues for qualifying text-shaping demand using the existing requester, organization, use-case, and blocking criteria.
- [ ] **SIGNAL-04**: Maintainer reviews merged contributions for a qualifying non-maintainer contributor signal using the existing exclusions.
- [ ] **SIGNAL-05**: `ADOPTION.md` records source-backed decisions for demand, downloads, contributor activity, and the conjunctive composite gate as `HOLD`, `ACCUMULATING`, or `TRIGGER`; unavailable evidence is never treated as zero.

### Phoenix Newcomer Proof

- [ ] **JOURNEY-01**: A newcomer can install the public Rendro package in a clean Phoenix environment without relying on the repository checkout or warm dependency caches.
- [ ] **JOURNEY-02**: A newcomer can follow public discovery surfaces to select and customize the canonical Swiss/light Invoice using the documented preset/configurator path.
- [ ] **JOURNEY-03**: The clean Phoenix application serves that customized document through the optional Phoenix adapter as a successful `application/pdf` response containing valid `%PDF-` bytes.
- [ ] **JOURNEY-04**: The journey records exact versions, commands, results, and any repaired documentation or integration handoff; fixes remain confined to existing surfaces.

## Future Requirements

Deferred to future milestones. Tracked but not included in this roadmap.

### Demand-Gated Capabilities

- **SHAPE-01**: Productize global text shaping, RTL/bidi behavior, and broader OpenType support only if the refreshed conjunctive adoption gate triggers.
- **STUDIO-01**: Build the optional Rendro Studio live playground only when adopter demand justifies a server-backed developer surface beyond the shipped static configurator.
- **CHART-01**: Add deterministic chart primitives only after concrete reporting demand proves their product value.

## Out of Scope

Explicit exclusions for v2.13.

| Feature | Reason |
|---------|--------|
| New runtime dependencies or a new core capability family | This milestone strengthens shipped surfaces; it does not widen the pure-core product contract. |
| Analytics, scheduled polling, campaigns, or proactive outreach | Adoption remains quiet, pull-based, source-backed, and read-only. |
| New recipes, presets, catalog entries, or catalog expansion | The quality target is the exact existing set of 12 `needs_work` cells inside the fixed 32-cell catalog. |
| Automated aesthetic scoring or a generalized review product | Quality dispositions remain bounded human judgments; existing evidence machinery is sufficient unless execution proves a narrow helper necessary. |
| Print-safety, accessibility, PDF/UA, WCAG, universal design-quality, or universal-viewer claims | Visual improvement and one Phoenix journey do not establish those broader guarantees. |
| Broad planning or Windows-ledger cleanup | Cleanup is allowed only where it directly enables a committed requirement. |

## Traceability

Roadmap mapping is populated after phase approval.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CATALOG-06 | TBD | Pending |
| CATALOG-07 | TBD | Pending |
| CATALOG-08 | TBD | Pending |
| CATALOG-09 | TBD | Pending |
| SIGNAL-02 | TBD | Pending |
| SIGNAL-03 | TBD | Pending |
| SIGNAL-04 | TBD | Pending |
| SIGNAL-05 | TBD | Pending |
| JOURNEY-01 | TBD | Pending |
| JOURNEY-02 | TBD | Pending |
| JOURNEY-03 | TBD | Pending |
| JOURNEY-04 | TBD | Pending |

**Coverage:**
- v2.13 requirements: 12 total
- Mapped to phases: 0
- Unmapped: 12

---
*Requirements defined: 2026-08-19*
*Last updated: 2026-08-19 after initial definition*

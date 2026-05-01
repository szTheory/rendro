# Requirements: Rendro v1.2

**Defined:** 2026-04-30
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1.2 Requirements

### Typography

- [x] **FONT-01**: Engineer can register document fonts by logical name and select them from authored text/components without dropping into PDF-writer internals.
- [x] **FONT-02
**: Measurement, pagination, and rendering use the same resolved font metrics so custom-font documents stay deterministic.
- [x] **FONT-03**: Engineer can embed supported custom fonts into generated PDFs through the supported document contract.

### Fallback and I18n Boundaries

- [ ] **FONT-04**: Engineer can declare fallback font chains so missing glyphs resolve predictably instead of silently degrading.
- [ ] **I18N-01**: Operator receives typed diagnostics or errors when content requires unsupported glyphs, scripts, or shaping behavior.
- [ ] **I18N-02**: Maintainer publishes a truthful Unicode/i18n baseline that distinguishes supported simple text rendering from unsupported RTL or complex-shaping scenarios.

### Assets

- [ ] **ASSET-01**: Engineer can register local or in-memory image/logo assets through a first-class document API instead of ad hoc block tuples.
- [ ] **ASSET-02**: Engineer can place supported assets with deterministic bounds suitable for branded invoices, statements, and reports.
- [ ] **ASSET-03**: Unsupported asset references, formats, or sizing conditions fail through typed validation or render diagnostics rather than silent fallback.

### Recipes and Verification

- [ ] **LAY-13**: Engineer can generate at least one branded canonical document example that combines templates/regions with registered fonts and logo assets.
- [ ] **QUAL-07**: Maintainer can verify typography and asset determinism through committed regression tests, docs-contract coverage, and example proof.

## v1.3 Candidate Requirements

### First Public Release Readiness

- **REL-01**: Maintainer can publish Rendro to Hex.pm with truthful package metadata, guides, and support boundaries.
- **REL-02**: Maintainer can prove the public release surface through release-preflight, example validation, and milestone-level support review.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Remote asset fetching in core | Would introduce I/O policy and nondeterminism before the asset contract is stable |
| Broad RTL or complex-script shaping support | Requires deeper text shaping proof than this milestone is meant to provide |
| HTML/CSS-like font/layout behavior | Conflicts with Rendro's deterministic document-engine scope |
| Async artifact manifests or persistence workflows | Important later, but not a prerequisite for the first truthful branded-document milestone |
| Public Hex publication during v1.2 | Release should follow the proved support boundary, not substitute for it |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FONT-01 | Phase 25 | Complete |
| FONT-02 | Phase 26 | Complete |
| FONT-03 | Phase 26 | Complete |
| FONT-04 | Phase 27 | Pending |
| I18N-01 | Phase 27 | Pending |
| I18N-02 | Phase 27 | Pending |
| ASSET-01 | Phase 28 | Pending |
| ASSET-02 | Phase 28 | Pending |
| ASSET-03 | Phase 28 | Pending |
| LAY-13 | Phase 29 | Pending |
| QUAL-07 | Phase 29 | Pending |

**Coverage:**
- v1.2 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-30*
*Last updated: 2026-05-01 after Phase 26 Plan 02 execution and verification*

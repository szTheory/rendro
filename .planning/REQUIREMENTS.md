# Requirements: Rendro v1.9 Embedded Artifact Surfaces

**Defined:** 2026-05-05
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1.9 Requirements

### Embedded Files

- [x] **EMBED-01**: Engineers can embed one or more document-level related files into a generated PDF through explicit Rendro-authored inputs rather than external post-processing.
- [x] **EMBED-02**: Embedded file metadata is explicit and deterministic, including filename, MIME type, description, and authored timestamps when present.
- [x] **EMBED-03**: Validation rejects ambiguous, duplicate, or unsupported embedded-file state before render.

### Link Annotations

- [x] **LINK-01**: Engineers can author deterministic external-URI link annotations through a curated public API.
- [x] **LINK-02**: Engineers can author deterministic internal-destination link annotations for in-document navigation.

### Truthful Support Boundaries

- [x] **TRUST-01**: Rendro publishes one proof-backed support contract for embedded files and curated link annotations across docs and `priv/support_matrix.json`.
- [x] **TRUST-02**: Verification distinguishes structural proof from viewer behavior and does not claim support for artifact surfaces or viewers without recorded evidence.

## v2+ Requirements

### Deferred Trust Surfaces

- **ENCRYPT-01**: Rendro offers a truthful PDF protection story without overclaiming permission-based security.
- **SIGN-01**: Rendro supports signature-field and signing workflows with explicit boundaries between unsigned fields, prepared documents, and actual cryptographic signatures.
- **ANNOT-01**: Rendro may add richer annotation surfaces only if they remain authored, deterministic, and narrower than comment/review workflows.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Generic annotation dictionaries or broad comment/review APIs | Too wide for Rendro's current authored contract and likely to create workflow expectations outside core scope |
| File-attachment annotations placed on pages | More viewer-variable and more review-like than document-level embedded files |
| PDF encryption in core | Cross-cutting trust-model change that should follow artifact-surface stabilization |
| Digital signatures, PAdES, or compliance claims | Requires incremental signing mechanics and a much heavier validation/support story |
| Automatic timestamps or mutable metadata defaults | Breaks deterministic output expectations |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EMBED-01 | Phase 48 | Complete |
| EMBED-02 | Phase 48 | Complete |
| EMBED-03 | Phase 48 | Complete |
| LINK-01 | Phase 49 | Complete |
| LINK-02 | Phase 49 | Complete |
| TRUST-01 | Phase 50 | Complete |
| TRUST-02 | Phase 50 | Complete |

**Coverage:**
- v1.9 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05 after v1.9 milestone definition*

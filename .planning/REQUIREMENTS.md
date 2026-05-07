# Requirements: Rendro v2.0 Signature Fields & External Signing Preparation

**Defined:** 2026-05-06
**Status:** Active
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v2.0 Requirements

### Signature Fields

- [x] **SIGN-01**: Engineers can author unsigned signature fields through Rendro's public authored-PDF API without introducing a parallel rendering path.
- [x] **SIGN-02**: Validation rejects unsupported, ambiguous, or scope-breaking signature-field state before render.
- [ ] **SIGN-03**: Rendro serializes the required AcroForm, widget, and signature-related PDF structures deterministically for identical authored inputs.

### External Signing Preparation

- [ ] **PREP-01**: Engineers can prepare a rendered `%Rendro.Artifact{}` for external signing through an artifact-first API that does not change `Rendro.render/2` semantics.
- [ ] **PREP-02**: The signing-preparation seam operates on final artifact bytes and preserves a clear terminal handoff boundary for append or incremental signing workflows.
- [ ] **PREP-03**: Key custody, certificate management, and signer-specific trust operations remain outside Rendro core and inside optional adapters or external workflows.

### Truthful Support Boundaries

- [x] **TRUST-01**: `priv/support_matrix.json` publishes signature-field and signing-preparation support separately from unsupported `digital_signatures` and compliance claims.
- [x] **TRUST-02**: Public docs explicitly distinguish unsigned signature fields and signing preparation from cryptographic signatures, tamper evidence, and PAdES/LTV/TSA/OCSP/CRL support.
- [x] **TRUST-03**: Signature-related viewer rows default to `unverified` until recorded evidence exists, and structural proof remains distinct from viewer or cryptographic validity proof.

## Deferred Beyond v2.0

- **CRYPTO-01**: In-core cryptographic signing remains deferred.
- **COMP-01**: PAdES, LTV, TSA, OCSP, CRL, and blanket compliance claims remain deferred.
- **VIEW-01**: Broad viewer support promotion remains deferred until per-viewer recorded proof exists.

## Traceability

| Requirement | Planned Phase | Notes |
|-------------|---------------|-------|
| SIGN-01 | Phase 58 | Closed by Phase 58 via `55-VERIFICATION.md`; implementation shipped in Phase 55 |
| SIGN-02 | Phase 58 | Closed by Phase 58 via `55-VERIFICATION.md`; implementation shipped in Phase 55 |
| SIGN-03 | Phase 59 | Reopened by v2.0 audit pending `56-VERIFICATION.md` backfill |
| PREP-01 | Phase 59 | Reopened by v2.0 audit pending `56-VERIFICATION.md` backfill |
| PREP-02 | Phase 59 | Reopened by v2.0 audit pending `56-VERIFICATION.md` backfill |
| PREP-03 | Phase 59 | Reopened by v2.0 audit pending `56-VERIFICATION.md` backfill |
| TRUST-01 | Phase 57 | Support matrix updates |
| TRUST-02 | Phase 57 | Docs and support-boundary wording |
| TRUST-03 | Phase 57 | Proof and viewer-promotion discipline |

---
*Active milestone requirements as of 2026-05-06.*

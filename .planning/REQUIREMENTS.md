# Requirements: Rendro v1.10 Protected Delivery Hooks & Encryption Boundaries

**Defined:** 2026-05-06
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1.10 Requirements

### Protection API

- [x] **PROTECT-01**: Engineers can apply password-to-open protection to a rendered `%Rendro.Artifact{}` through a first-party external adapter boundary without widening the core render pipeline.
- [x] **PROTECT-02**: The public protection surface accepts only AES-256 and rejects weaker or legacy algorithms with typed errors.
- [x] **PROTECT-03**: Protection option validation rejects malformed or ambiguous authored state before any adapter invocation, and redacts password material from error details and audit metadata.

### Adapter and Validation Boundaries

- [ ] **ADAPT-01**: Rendro ships a first-party `qpdf` protection adapter that remains an optional runtime executable rather than a hard dependency.
- [ ] **ADAPT-02**: Poppler structural validation can validate protected PDFs when the caller supplies the appropriate password.
- [x] **ADAPT-03**: Existing artifact-delivery seams continue to work with already-protected artifacts without learning password material themselves.

### Truthful Support Boundaries

- [x] **TRUST-01**: `priv/support_matrix.json` publishes a dedicated `protection` family covering password-to-open, advisory permissions, unsupported native encryption, and unsupported compliance/signature narratives.
- [x] **TRUST-02**: Public docs distinguish password-to-open from advisory permissions and explicitly state that protection is not digital signing, tamper evidence, or PDF/A/compliance support.
- [ ] **TRUST-03**: New viewer rows for protection default to `unverified` until manual proof is recorded.

### Release Tail

- [ ] **RELEASE-01**: The milestone closes with release-preflight guidance and changelog/readiness updates so Rendro can be published for downstream `mailglass` consumption immediately after proof closes.

## Deferred Beyond v1.10

- **CRYPT-01**: Native in-core encryption remains deferred until a later milestone with explicit non-deterministic-output acceptance and fresh proof.
- **SIGN-01**: Signature fields and external signing preparation remain deferred to `v2.0`.
- **COMP-01**: PDF/A, PDF/UA, PAdES, LTV, TSA/OCSP/CRL, and broad compliance claims remain deferred.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Native in-core encryption | Deferred to a future milestone; this milestone keeps the render pipeline unchanged and uses external hooks first. |
| AES-128 / RC4 / legacy encryption | Not part of the truthful public security boundary for this release. |
| Password fields in persisted Oban args | Protection secrets should not be written into persisted async job payloads. |
| Digital signatures / tamper-evidence claims | Encryption is not integrity; signing remains a later milestone. |
| Blanket viewer compatibility claims | Viewer rows stay `unverified` until recorded manual proof exists. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROTECT-01 | Phase 51 | Complete |
| PROTECT-02 | Phase 51 | Complete |
| PROTECT-03 | Phase 51 | Complete |
| ADAPT-01 | Phase 52 | In Progress |
| ADAPT-02 | Phase 52 | In Progress |
| ADAPT-03 | Phase 53 | Complete |
| TRUST-01 | Phase 53 | Complete |
| TRUST-02 | Phase 53 | Complete |
| TRUST-03 | Phase 54 | Pending |
| RELEASE-01 | Phase 54 | Pending |

**Coverage:**
- v1.10 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-06 after Phase 53 execution*

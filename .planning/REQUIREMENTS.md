# Requirements: Rendro v2.1 Cryptographic Signing & Signed-Artifact Proof

**Defined:** 2026-05-07
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v2.1 Requirements

### Cryptographic Signing

- [ ] **SIGN-04**: Engineers can sign a rendered `%Rendro.Artifact{}` through a narrow public API that preserves the shipped unsigned/preparation seam instead of replacing it.
- [ ] **SIGN-05**: Signing rejects invalid field selection, malformed adapter configuration, and unsupported runtime state with typed, redacted errors before secrets leak into logs or metadata.
- [ ] **SIGN-06**: Signed artifacts expose explicit non-deterministic signing state and safe adapter metadata without persisting private key material, passphrases, or raw tool output.

### Adapter and Validation Boundaries

- [ ] **ADAPT-04**: Rendro ships a first-party optional signing adapter backed by pyHanko as a runtime executable rather than a hard dependency.
- [ ] **ADAPT-05**: Rendro ships a first-party optional signed-artifact validation adapter backed by `pdfsig` that reports signature integrity posture separately from certificate trust and tool availability.
- [ ] **ADAPT-06**: Rendro includes a live proof lane that signs a representative artifact with real toolchain inputs and verifies the resulting signed-artifact posture through the supported validator path.

### Truthful Support Boundaries

- [ ] **TRUST-04**: `priv/support_matrix.json` publishes `digital_signatures` support separately from unsigned fields, signing preparation, protection, and deferred compliance narratives.
- [ ] **TRUST-05**: Public docs explain cryptographic signing, certificate trust, viewer behavior, and compliance as distinct claims and keep unproven rows `unverified` or unsupported.
- [ ] **TRUST-06**: Verification artifacts prove the supported end-to-end signing path and the credential-redaction boundary without implying long-lived-signature or compliance support.

## Future Requirements

### Compliance and Longevity

- **COMP-02**: Rendro can produce proof-backed long-lived signatures with timestamp and revocation evidence.
- **COMP-03**: Rendro can support narrow PAdES-baseline narratives only when validator and artifact proof explicitly justify them.

### Additional Signing Ecosystem

- **ADAPT-07**: Rendro can support additional signing adapters such as PKCS#11/HSM-backed flows without widening the core API.
- **TRUST-07**: Rendro can promote viewer-specific signed-PDF support only after exact per-viewer evidence is recorded.

## Out of Scope

| Feature | Reason |
|---------|--------|
| In-core key custody or certificate-store management | Must stay outside pure core and inside optional adapters/external infrastructure |
| Timestamps, OCSP/CRL embedding, and long-lived-signature maintenance | Requires a later dedicated proof lane and would widen the milestone beyond one narrow signing path |
| PAdES/LTV/TSA/OCSP/CRL claims | Compliance narratives must follow explicit validator-backed evidence, not tool capability alone |
| Broad viewer support claims for signed PDFs | Viewer posture stays evidence-gated per viewer and surface |
| Mandatory Python or Poppler dependencies | Core Rendro must stay deployable without them |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SIGN-04 | Phase 60 | Pending |
| SIGN-05 | Phase 60 | Pending |
| SIGN-06 | Phase 60 | Pending |
| ADAPT-04 | Phase 61 | Pending |
| ADAPT-05 | Phase 61 | Pending |
| ADAPT-06 | Phase 62 | Pending |
| TRUST-04 | Phase 62 | Pending |
| TRUST-05 | Phase 62 | Pending |
| TRUST-06 | Phase 63 | Pending |

**Coverage:**
- v2.1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-07*
*Last updated: 2026-05-07 after v2.1 milestone definition*

# Feature Research

**Domain:** PDF signature fields and external signing preparation
**Researched:** 2026-05-06
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Unsigned signature widget authoring | If a PDF library claims signing preparation, users expect an actual visible or invisible signature field to exist in the PDF. | MEDIUM | Should fit the existing AcroForm widget family instead of becoming a parallel authoring API. |
| Deterministic field and catalog serialization | Signing workflows are byte-sensitive, so users expect stable object wiring before the external signer runs. | HIGH | Must preserve field references, widget annotations, and signature-related dictionary entries predictably. |
| External-signing preparation seam | Users expect a clean handoff from render output to their signer/HSM/vendor flow. | HIGH | Likely an artifact-first API parallel to `Rendro.Protect`, not a render-time option on `Rendro.render/2`. |
| Truthful support boundaries | Signing is trust-sensitive; adopters expect explicit statements about what is and is not covered. | MEDIUM | `prepared_for_signing` and `digitally_signed` cannot be conflated. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Reuse of existing `%Rendro.FormField{}` authored boundary | Keeps the public DSL small and lowers migration cost for users already authoring forms. | MEDIUM | A new `:signature` type is attractive if validation and writer logic can keep it honest. |
| Adapter-neutral signing-preparation contract | Lets adopters integrate their own signer stack without contaminating core. | HIGH | Strong fit with Rendro's optional adapter philosophy. |
| Proof-backed viewer and support-matrix posture | Gives trust-sensitive teams an auditable contract rather than vague PDF-signing marketing. | MEDIUM | High product value because this surface is easy to overclaim. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| In-core cryptographic signing | Sounds convenient and marketable | Pulls Rendro into key management, signer policy, and compliance scope immediately | Keep cryptographic signing in optional adapters or external workflows |
| Blanket "PAdES compliant" claim | Buyers look for a familiar trust label | PAdES spans more than field authoring and placeholder preparation | Ship narrow preparation claims now; defer compliance work to a later milestone |
| Reusing protection/qpdf as the signing solution | Teams want fewer tools | qpdf is not the signing engine and protection semantics do not prove authorship | Keep protection and signing as separate surfaces with separate proofs |

## Feature Dependencies

```text
Unsigned signature field authoring
    └──requires──> validate-stage signature semantics
                       └──requires──> writer support for signature widgets and dictionaries

External-signing preparation
    └──requires──> deterministic unsigned field serialization
                       └──requires──> artifact-first handoff API

Viewer proof and support-matrix promotion
    └──requires──> representative signature-field fixtures
```

### Dependency Notes

- **External-signing preparation requires deterministic unsigned field serialization:** a signer cannot safely operate on ambiguous or unstable field wiring.
- **Viewer proof depends on representative fixtures:** structural correctness alone does not prove field discoverability or visible appearance behavior.
- **Validation should precede adapter expansion:** invalid field semantics should fail before any external signer sees the PDF.

## MVP Definition

### Launch With (v2.0)

- [ ] Unsigned signature-field authoring in the existing authored-PDF model — essential to claim signature preparation truthfully
- [ ] Validate-stage enforcement for supported signature-field shapes and explicit rejection of out-of-scope signing features — keeps scope narrow
- [ ] Artifact-first external-signing preparation seam — enables real workflows without forcing core cryptographic signing
- [ ] Support-matrix and guide updates that keep `digital_signatures` unsupported unless a later proof lane changes that claim — essential honesty layer

### Add After Validation (v2.x)

- [ ] First-party adapter for one external signing path — add only after the core prep contract proves correct
- [ ] Viewer promotion for specific signature-field surfaces — add when recorded evidence exists

### Future Consideration (v3+)

- [ ] Cryptographic signing inside an optional first-party adapter family — defer until clear adopter demand exists
- [ ] PAdES / LTV / OCSP / TSA / CRL proof lanes — defer because they widen trust and compliance scope substantially

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Unsigned signature-field authoring | HIGH | MEDIUM | P1 |
| Validate-stage signing boundary checks | HIGH | MEDIUM | P1 |
| External-signing preparation seam | HIGH | HIGH | P1 |
| Support-matrix + docs-contract updates | HIGH | MEDIUM | P1 |
| First-party concrete signer adapter | MEDIUM | HIGH | P2 |
| Viewer promotion beyond `unverified` | MEDIUM | MEDIUM | P2 |
| Broad compliance surface | HIGH | VERY HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| Signature field authoring | Common in mature PDF SDKs | Common in mature PDF SDKs | Match the narrow authored-field expectation without copying broad editing suites |
| Cryptographic signing | Often bundled with enterprise/commercial toolchains | Often coupled to vendor ecosystems | Keep Rendro adapter-first and avoid pretending every adopter wants the same trust stack |
| Compliance marketing | Often broad and certification-heavy | Often broad and certification-heavy | Stay evidence-driven and explicit about unsupported claims |

## Sources

- Adobe PDF 1.7 reference (`PDF32000_2008.pdf`)
- ETSI TS 102 778-1
- ETSI TS 102 778-6
- qpdf official manual
- Adobe official signing / seal workflow documentation

---
*Feature research for: PDF signature fields and external signing preparation*
*Researched: 2026-05-06*

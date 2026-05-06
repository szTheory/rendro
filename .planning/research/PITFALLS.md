# Pitfalls Research

**Domain:** PDF signature fields and external signing preparation
**Researched:** 2026-05-06
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Treating a Signature Field as a Digital Signature

**What goes wrong:**
The project ships a visible signature box and then claims "digital signatures" are supported.

**Why it happens:**
The field is user-visible, so teams assume the trust workflow is also complete.

**How to avoid:**
Keep field authoring and external signing preparation as separate requirement categories. Leave `digital_signatures` unsupported in the support matrix unless a later proof lane changes that truth.

**Warning signs:**
Docs start saying "signed PDFs" when the implementation only emits unsigned fields or placeholder dictionaries.

**Phase to address:**
Signature field authoring phase and docs/support-boundary phase.

---

### Pitfall 2: Rewriting Bytes After Signing Preparation

**What goes wrong:**
The system re-renders, reserializes, or post-processes the PDF after the signing-prep step, invalidating byte-sensitive signing assumptions.

**Why it happens:**
Teams treat signing like any other enrichment step instead of a final-byte workflow.

**How to avoid:**
Make the signing-prep seam artifact-first and terminal. Once the prep/signer handoff starts, no later writer pass or catalog rewrite should run on those bytes.

**Warning signs:**
APIs allow "prepare for signing" before layout is finalized, or a signer receives data that can still be mutated by Rendro.

**Phase to address:**
External signing preparation phase.

---

### Pitfall 3: Coupling Core to Keys, Certificates, or HSM Policies

**What goes wrong:**
Rendro core becomes responsible for signer credential models, hardware-backed key rules, or vendor-specific trust flows.

**Why it happens:**
Signature work naturally attracts operational demands that feel adjacent to PDF authoring.

**How to avoid:**
Keep all credential, certificate, and key material concerns in optional adapters or external services.

**Warning signs:**
Core structs start carrying certificates, private-key references, or signer-service credentials.

**Phase to address:**
Architecture and adapter-boundary phase.

---

### Pitfall 4: Overclaiming PAdES or Compliance Readiness

**What goes wrong:**
The roadmap drifts from "external signing preparation" into "compliance-ready signatures" without the necessary validation surface.

**Why it happens:**
PAdES language is attractive to buyers and easy to mention prematurely.

**How to avoid:**
Keep PAdES, LTV, TSA, OCSP, and CRL explicitly out of scope for v2.0 and represent them as future milestone material.

**Warning signs:**
Requirements or guides start using compliance vocabulary without new validation lanes, trust evidence, or supporting adapters.

**Phase to address:**
Requirements definition and docs/support-boundary phase.

---

### Pitfall 5: Promoting Viewer Support Without Recorded Evidence

**What goes wrong:**
A viewer opens one fixture, and the project generalizes that to broad signature support.

**Why it happens:**
Signature fields often "look fine" in one viewer even when workflows differ across products.

**How to avoid:**
Use the existing support-matrix discipline: structural proof is separate from viewer proof, and each promoted viewer/surface pair needs recorded evidence.

**Warning signs:**
`priv/support_matrix.json` moves from `unverified` to `supported` without a corresponding fixture and checklist.

**Phase to address:**
Proof closure and milestone validation phase.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hard-code one signature widget shape with no validation taxonomy | Faster first demo | Brittle API and vague errors once users vary field setups | Only if the same milestone immediately adds explicit validation before release |
| Expose signer-specific options on core APIs | Faster first integration | Core becomes coupled to one trust vendor | Never |
| Describe prepared PDFs as "signed enough" | Easier docs copy | Permanent trust confusion and support debt | Never |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| External signer | Passing mutable document data instead of final artifact bytes | Pass the exact rendered bytes plus explicit signing instructions |
| qpdf | Assuming it can create digital signatures | Use qpdf for adjacent PDF tooling, not signing |
| Viewer validation | Treating viewer openability as signature validity | Separate structural readability, viewer behavior, and cryptographic validation |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Recomputing or rewriting the whole PDF during signing prep | Large artifacts become slow and fragile | Keep prep minimal and artifact-oriented | Noticeable on larger business documents with attachments/forms |
| Huge placeholder / appearance experiments in core writer | Writer complexity and fixture churn spike quickly | Start with one narrow supported field model | Breaks as soon as multiple signer workflows are attempted at once |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging signing inputs or signer failures verbosely | Secret leakage or trust-material disclosure | Reuse the redacted-failure posture established by protection work |
| Accepting private-key material in core structs | Scope explosion and unsafe defaults | Keep key material entirely outside core |
| Claiming tamper evidence from unsigned or merely prepared PDFs | False security posture | Publish narrow semantics and keep `digital_signatures` unsupported until true proof exists |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| One generic "signature" feature name for multiple trust levels | Users assume more support than exists | Name surfaces explicitly: signature field, signing prep, digital signing |
| Hiding unsupported signing modes behind silent no-ops | Users think a document is signable when it is not | Fail fast with typed validation errors |

## "Looks Done But Isn't" Checklist

- [ ] **Signature fields:** Often missing truthful support language — verify guide and matrix updates ship together
- [ ] **Signing prep seam:** Often missing terminal-byte guarantees — verify no later render pass mutates prepared bytes
- [ ] **Viewer support:** Often missing recorded evidence — verify promoted rows have checklists
- [ ] **Compliance posture:** Often missing explicit exclusions — verify PAdES/LTV/TSA/OCSP/CRL stay out of scope

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Support claim inflation | HIGH | Narrow docs and support matrix immediately, add regression tests to lock the corrected language |
| Wrong core/signer coupling | HIGH | Extract signer-specific concerns into an adapter seam and keep core API narrow |
| Broken prepared-byte contract | HIGH | Redesign the handoff as a terminal artifact boundary and re-baseline fixtures |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Field vs signature confusion | Requirements + docs phase | Docs-contract and support-matrix assertions remain narrow |
| Prepared-byte invalidation | External signing prep phase | Regression tests prove handoff consumes final bytes only |
| Core/signing coupling | Architecture phase | Public API review shows no key/cert material in core |
| Compliance overclaim | Docs/support phase | Explicit unsupported rows and guide wording stay present |
| Viewer overpromotion | Proof phase | Recorded checklist exists before any promotion |

## Sources

- Adobe PDF 1.7 reference (`PDF32000_2008.pdf`)
- ETSI TS 102 778-1
- ETSI TS 102 778-6
- qpdf official documentation
- Rendro support-boundary patterns from `guides/api_stability.md` and `priv/support_matrix.json`

---
*Pitfalls research for: PDF signature fields and external signing preparation*
*Researched: 2026-05-06*

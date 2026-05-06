# Project Research Summary

**Project:** Rendro
**Domain:** Deterministic PDF signature fields and external signing preparation
**Researched:** 2026-05-06
**Confidence:** HIGH

## Executive Summary

The research supports the current arc choice: Rendro can plausibly add signature-related capability next, but the milestone must stay narrow. Primary-source PDF and PAdES references treat signature fields, visible appearances, and cryptographic signing as related but distinct concerns. qpdf remains adjacent PDF infrastructure, not the signing engine. That means the right v2.0 is not "digital signatures" in the broad sense; it is authored signature fields plus a clean artifact-first handoff into external signing workflows.

Rendro's local architecture is already favorable for this. The library has one authored form-field surface, one validate-stage error envelope, one core writer that injects AcroForm structures, and one proven pattern for trust-sensitive post-processing through `%Rendro.Artifact{}` and optional adapters. The milestone should reuse those seams rather than introduce a second signature subsystem or a render-time signing path.

The main risk is truth drift. Signature work invites overclaiming faster than most PDF features. The roadmap should therefore isolate field authoring, external-signing preparation, and proof/docs closure so public language never gets ahead of implementation and evidence.

## Key Findings

### Recommended Stack

Rendro should stay on the existing Elixir/OTP core and existing writer target while extending the current AcroForm path. Signature-specific work belongs in validation rules, writer serialization, and a new artifact-first signing-preparation seam. External signers, certificates, and key custody should remain outside core and inside optional adapters or user-owned workflows.

**Core technologies:**
- Elixir / OTP: preserve the pure-core runtime and existing artifact-first APIs
- Existing PDF writer / AcroForm path: extend current field serialization instead of inventing a second authoring model
- Optional external signing adapter boundary: isolate cryptographic trust operations from deterministic rendering

### Expected Features

The table stakes for this milestone are narrow but meaningful: authored unsigned signature fields, validate-stage signing boundaries, deterministic field/catalog serialization, and a signer handoff contract that operates on final artifact bytes. The most important differentiator is not "more signing features"; it is keeping the public contract small and truthful while still enabling real-world external signer integration.

**Must have (table stakes):**
- Unsigned signature-field authoring
- Validate-stage enforcement for supported signature semantics
- Artifact-first external-signing preparation seam
- Support-matrix and guide updates that keep `digital_signatures` unsupported unless later proof changes that

**Should have (competitive):**
- Reuse of existing `%Rendro.FormField{}` boundary
- Adapter-neutral handoff contract
- Proof-backed viewer posture for any promoted signature rows

**Defer (v2+):**
- In-core cryptographic signing
- PAdES / LTV / TSA / OCSP / CRL claims
- Broad viewer support claims

### Architecture Approach

The recommended architecture is three-layered: authored signature input on the existing form boundary, validate-stage and writer extensions for unsigned field serialization, and a post-render artifact-first seam for external signing preparation. This order preserves one render core, one validation envelope, and one trustworthy distinction between deterministic authored output and environment-specific trust operations.

**Major components:**
1. `FormField` / validation rules — own authored signature semantics and explicit rejections
2. `PDF.Writer` — emit AcroForm/widget/signature-related structures deterministically
3. Signing-prep seam / optional adapters — consume final artifact bytes for external workflows

### Critical Pitfalls

1. **Treating a signature field as a digital signature** — keep field authoring and trust claims separate
2. **Rewriting bytes after signing preparation** — make the handoff terminal and artifact-first
3. **Coupling core to key/certificate workflows** — keep all such concerns in adapters or external systems
4. **Overclaiming PAdES or compliance readiness** — defer compliance surfaces explicitly
5. **Promoting viewer support without evidence** — require support-matrix proof like other Rendro surfaces

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 55: Signature Field Authoring Contract
**Rationale:** Authoring semantics must exist before any prep or proof work can be meaningful.
**Delivers:** New or extended signature-field authored surface, validation taxonomy, and unsigned field fixtures.
**Addresses:** Unsigned signature-field authoring, validate-stage signing boundaries.
**Avoids:** Field-vs-signature claim confusion.

### Phase 56: Deterministic Writer and Artifact Prep Seam
**Rationale:** Once authoring is constrained, the writer and artifact boundary can encode stable signable output.
**Delivers:** Writer support for signature-related PDF objects and an artifact-first external signing preparation API.
**Uses:** Existing AcroForm/writer seams and artifact-first trust pattern.
**Implements:** Final-byte handoff contract without in-core signing.

### Phase 57: Support Contract, Proof, and Adapter Closure
**Rationale:** This surface is trust-sensitive enough that docs, support matrix, and proof should close the milestone instead of lagging behind.
**Delivers:** Updated public support boundaries, docs-contract coverage, structural proof, and any narrowly-scoped adapter closure chosen for v2.0.
**Avoids:** Viewer/compliance overclaiming.

### Phase Ordering Rationale

- Validation and authored semantics come first because the writer should only serialize supported shapes.
- The artifact-first signing seam follows writer work because signing workflows depend on final bytes.
- Proof and support closure come last because this milestone is unusually easy to overstate.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 56:** external signer handoff details vary by signer ecosystem and may need targeted API research
- **Phase 57:** any first-party adapter choice would need signer-specific evidence and scope control

Phases with standard patterns (skip research-phase):
- **Phase 55:** extending the existing authored field and validation seams is mostly local architectural work

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Supported by official PDF, ETSI, and qpdf sources plus local architecture fit |
| Features | HIGH | Signature-prep scope is narrow and consistent across sources |
| Architecture | HIGH | Rendro already has the form, writer, validation, artifact, and support-boundary seams this milestone needs |
| Pitfalls | HIGH | The main failure modes are well understood and visible from both the PDF domain and Rendro's existing trust posture |

**Overall confidence:** HIGH

### Gaps to Address

- Choose whether v2.0 includes only the prep seam or also one first-party concrete adapter.
- Decide whether signature fields stay inside `%Rendro.FormField{}` or earn a new dedicated struct without widening authoring complexity.
- Define exactly what metadata a "prepared for external signing" artifact should expose without implying cryptographic validity.

## Sources

### Primary (HIGH confidence)
- Adobe PDF 1.7 reference (`PDF32000_2008.pdf`) — signature fields, AcroForm, signature dictionaries
- ETSI TS 102 778-1 — PAdES framing and compliance scope
- ETSI TS 102 778-6 — visible signatures and field/signature value separation
- qpdf official manual — confirms qpdf is not currently a digital-signature creation engine

### Secondary (HIGH confidence due to vendor ownership)
- Adobe official signing / electronic seal documentation — visibility and permission semantics for signing workflows

### Local architecture evidence
- `lib/rendro/form_field.ex`
- `lib/rendro/pipeline/validate.ex`
- `lib/rendro/pdf/writer.ex`
- `guides/api_stability.md`
- `priv/support_matrix.json`

---
*Research completed: 2026-05-06*
*Ready for roadmap: yes*

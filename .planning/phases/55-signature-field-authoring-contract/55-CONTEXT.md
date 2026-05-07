# Phase 55: Signature Field Authoring Contract - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend Rendro's authored form surface with a truthful unsigned signature-field contract and validate-stage scope boundaries. This phase covers public authoring semantics and early rejection of unsupported signature-related state only. It does not yet add signature-widget PDF serialization, artifact signing preparation, viewer promotion, or digital-signature/compliance claims.

</domain>

<decisions>
## Implementation Decisions

### Public API shape
- **D-01:** Expose `Rendro.signature_field/2` as the canonical public API for unsigned signature fields.
- **D-02:** Internally normalize `Rendro.signature_field/2` into the existing `%Rendro.FormField{}` path by extending the internal form model with `type: :signature`.
- **D-03:** Do not introduce a second authored field struct or a parallel render/validation subsystem for signatures in Phase 55.
- **D-04:** Do not document `Rendro.form_field(..., type: :signature)` as the primary user-facing API, even if the internal model can represent it. The canonical DX should stay explicit and least-surprise.

### Unsigned field contract
- **D-05:** Phase 55 supports one narrow authored shape: a **visible unsigned signature field** with explicit field identity and explicit layout geometry.
- **D-06:** Invisible signature fields are out of scope for Phase 55. Do not support hidden widgets, zero-rect signing hints, or author-now/place-later behavior.
- **D-07:** Unsigned signature fields should be authored as empty placeholders only. They do not carry authored signer state or a signed value.
- **D-08:** The default rendered appearance posture for Phase 55 should stay fixed and neutral: a deterministic built-in visible placeholder owned by Rendro, not viewer-generated appearance and not an appearance mini-DSL.

### Validation boundaries
- **D-09:** Signature fields must fail in `Rendro.Pipeline.Validate` with typed validate-stage errors before render when authored state exceeds the supported contract.
- **D-10:** Reject authored signature-field values/default values. An unsigned signature field is not a text field and should not accept a caller-provided `value`.
- **D-11:** Reject signer metadata on authored document state, including reason/location/contact/signing date or equivalent semantics. If such metadata ever lands in Rendro, it belongs on the later artifact-first signing-preparation seam, not on the authored field.
- **D-12:** Reject signing-policy and cryptographic dictionary state in Phase 55, including lock dictionaries, seed values, certification/DocMDP/FieldMDP policy, `/Filter`, `/SubFilter`, `/ByteRange`, `/Contents`, `/Reference`, and other raw signing keys.
- **D-13:** Reject carryover attrs whose semantics belong to other widget families, including `checked`, `group`, and `export_value`.
- **D-14:** Keep the signature-field contract explicit and non-coercive. No raw-PDF passthrough maps, no low-level escape hatch attrs, and no “future-proof” permissive bag of signature options.

### Support-boundary and appearance posture
- **D-15:** Preserve Rendro's existing authored-appearance posture: Rendro owns the initial appearance stream; Phase 55 must not rely on `NeedAppearances` or viewer-generated rendering.
- **D-16:** Do not promise that the placeholder appearance survives later external signing unchanged. Phase 55 only owns the unsigned authored state.
- **D-17:** Do not claim viewer behavior, digital-signature behavior, tamper evidence, or compliance outcomes from Phase 55. This phase only authors unsigned visible fields and rejects unsupported state early.

### Downstream GSD default
- **D-18:** Shift the maintainer preference left for downstream GSD work in this phase and similar trust-sensitive contract work: default to one cohesive recommendation set that optimizes for truthful small contracts, least-surprise DX, explicit boundary validation, and one-engine architecture rather than escalating menus of equivalent options.
- **D-19:** Escalate only if a choice materially changes public product semantics, widens the support contract, or commits Rendro to a broader signing/compliance policy the maintainer is likely to care about directly.

### the agent's Discretion
- Exact naming of the `Rendro.signature_field/2` attrs, provided the public contract stays narrow and explicit.
- Exact typed error tuple names, provided they remain compact, validate-stage, and specific enough to identify the unsupported authored shape.
- Exact placeholder appearance details, provided the Phase 55 contract remains fixed, deterministic, and neutral rather than customizable.

</decisions>

<specifics>
## Specific Ideas

- Preferred public API direction:
  - `Rendro.signature_field("customer_signature", x: 72, y: 96, width: 180, height: 48)`
  - flow-layout usage should work through the same block geometry owner as existing fields
- Preferred DX story:
  - use `Rendro.signature_field/2` for unsigned signature boxes
  - use surrounding `Rendro.text/2` blocks for labels/instructions instead of opening signature-specific appearance customization in Phase 55
  - keep examples explicit that the field is unsigned and visible only
- Preferred validation posture:
  - reject `value`
  - reject `checked`, `group`, `export_value`
  - reject signer metadata and signing dictionaries
  - reject invisible/zero-rect intent
- Ecosystem lessons to preserve:
  - iText and HexaPDF both separate field creation from signing, but their convenience paths can silently create invisible or inferred signature widgets; Rendro should not
  - PDF libraries that rely on viewer appearance regeneration create long-tail bugs and portability confusion
  - truthful narrow scope is a strength here; libraries like pdf-lib are explicit about not over-promising signature creation/signing support

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/PROJECT.md` — v2.0 milestone posture, truthful signing-preparation boundaries, and non-negotiable product constraints.
- `.planning/REQUIREMENTS.md` — `SIGN-01` and `SIGN-02` define the exact required outcomes for Phase 55.
- `.planning/STATE.md` — active milestone state and locked upstream decisions.
- `.planning/milestones/v2.0-ROADMAP.md` — Phase 55 goal, plan split, and dependency chain.
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least-surprise DX, and recommendation-first posture.

### Prior locked forms/trust decisions
- `.planning/phases/45-CONTEXT.md` — why Rendro introduced a dedicated authored form-field boundary and why authored appearances stay in-core.
- `.planning/phases/46-checkbox-and-radio-button-widgets/46-CONTEXT.md` — reuse-one-form-model decision and explicit widget semantics precedent.
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-CONTEXT.md` — explicit forms validation posture, narrow support claims, and machine-readable contract expectations.
- `.planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md` — artifact-first trust boundary precedent and narrow public-seam philosophy.

### Live contract and code seams
- `lib/rendro.ex` — current public builder helpers; Phase 55 should add `Rendro.signature_field/2` here.
- `lib/rendro/form_field.ex` — current shared authored form model that should absorb internal `type: :signature` support.
- `lib/rendro/rules/check_form_fields.ex` — validate-stage rule entry point to extend with signature-field contract checks.
- `lib/rendro/pipeline/validate.ex` — current aggregated typed validate-stage error envelope.
- `guides/api_stability.md` — public support-boundary tone and current forms/protection wording to preserve.
- `priv/support_matrix.json` — current machine-readable forms boundary where `signature` is still unsupported.

### External reference points
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` — explicit validation-at-the-boundary model and narrow accepted-shape philosophy.
- `https://hexdocs.pm/phoenix/contexts.html` — Elixir-first explicit module/function design posture.
- `https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html` — signing layer separation plus invisible-widget convenience footgun to avoid.
- `https://hexapdf.gettalong.org/documentation/interactive-forms/index.html` — field-specific form API precedent.
- `https://api.itextpdf.com/iText/java/7.1.11/com/itextpdf/forms/fields/PdfFormField.html` — dedicated signature-field creation precedent.
- `https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html` — separate signing layer precedent and implicit-field complexity to avoid.
- `https://pdf-lib.js.org/docs/api/classes/pdfsignature` — honest narrow scope precedent around digital-signature APIs.
- `https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html` — artifact-oriented signing seam precedent for later phases.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.form_field/3` and `%Rendro.FormField{}` already provide the right internal normalization seam for another field family without opening a second engine.
- `Rendro.Rules.CheckFormFields` already enforces explicit supported widget types and cross-field invariants; it is the natural place to add signature-field contract checks.
- `Rendro.Pipeline.Validate` already aggregates focused rule failures into one typed validate-stage error envelope.
- Existing forms writer infrastructure already proves Rendro prefers authored appearance streams rather than viewer-generated appearances.

### Established Patterns
- Rendro prefers explicit narrow public helpers over permissive magic when a feature widens support boundaries.
- Trust-sensitive surfaces are kept separate from core rendering semantics until they can be proven truthfully.
- Unsupported product narratives are named explicitly rather than left implied.
- Existing forms phases already reject ambiguous authored state early instead of letting writer/viewer behavior guess intent.

### Integration Points
- Phase 55 should primarily touch the public builder layer, shared form-field model, validation rules/tests, support wording, and docs/examples.
- Writer serialization for signature widgets belongs in Phase 56, but Phase 55 must lock the public authored shape so the writer only handles supported semantics later.
- Signature preparation metadata and external-signing policy belong in the later artifact-first seam, not in authored document state.

</code_context>

<deferred>
## Deferred Ideas

- Invisible signature fields or author-now/sign-later widget inference.
- Signer metadata on authored document state (`reason`, `location`, `contact`, signing date).
- Lock dictionaries, seed values, certification flags, DocMDP/FieldMDP policy, or any raw signing-dictionary passthrough.
- Signature-specific appearance customization beyond Rendro-owned fixed neutral placeholder rendering.
- Artifact signing preparation, incremental update seams, key custody, certificate management, or any actual digital-signature support.
- Viewer-promotion claims for signature fields before dedicated proof lands in Phase 57.

</deferred>

---

*Phase: 55-signature-field-authoring-contract*
*Context gathered: 2026-05-06*

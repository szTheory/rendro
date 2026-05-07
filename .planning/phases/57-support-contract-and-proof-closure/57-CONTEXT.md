# Phase 57: Support Contract and Proof Closure - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish truthful public support boundaries for Rendro's unsigned signature widgets and artifact-first signing preparation, then close the `v2.0` milestone with structural proof, docs-contract coverage, and explicit evidence discipline. This phase does not add in-core cryptographic signing, signer-owned trust workflows, compliance narratives, or broad viewer support claims.

</domain>

<decisions>
## Implementation Decisions

### Support matrix shape
- **D-01:** Keep unsigned signature authoring inside the existing `forms` family. Phase 55's `Rendro.signature_field/2` contract remains part of authored form support, not a new top-level signature taxonomy.
- **D-02:** Add a sibling top-level `signing_preparation` family in `priv/support_matrix.json` for the Phase 56 artifact-first post-render seam. Do not bury artifact preparation under `forms`.
- **D-03:** Do not introduce a broad top-level `signatures` family in Phase 57. That would create unnecessary taxonomy churn and imply a larger subsystem than Rendro truthfully supports today.
- **D-04:** Keep the support matrix family-first and explicit, following existing `forms`, `embedded_files`, `links`, and `protection` precedent rather than adding a generic `"surfaces"` wrapper.
- **D-05:** The new `signing_preparation` family should stay narrow and product-facing: express only the prepared-artifact contract and explicitly unsupported trust/compliance narratives. Do not let the family name or leaves read like full digital-signature support.

### Public wording split
- **D-06:** Split public documentation into separate support-boundary sections for:
  - unsigned signature fields/widgets
  - signing preparation
- **D-07:** Add one very short shared preamble that explains the lifecycle at a high level:
  - author unsigned placeholder
  - render artifact
  - prepare artifact for an external signer
  - external signing and verification remain outside Rendro core
- **D-08:** Keep that preamble brief and policy-oriented, not architectural. Its job is to prevent category confusion, not to explain the implementation.
- **D-09:** Do not publish one blended “signature support” section. That wording invites readers to collapse authored placeholders, prepared artifacts, viewer behavior, and cryptographic validity into a single claim.
- **D-10:** Each section must state three things in order:
  - the narrow supported surface
  - the proof lane that backs that surface
  - the unsupported narratives that remain outside contract

### Viewer-proof posture
- **D-11:** Default all signature-related viewer rows to `unverified` in Phase 57 unless a named viewer/surface pair already has recorded checklist evidence.
- **D-12:** Keep viewer claims per surface and per viewer. Do not publish a blanket signature-viewer claim.
- **D-13:** Treat structural correctness and viewer behavior as separate proof lanes. A structurally correct unsigned or prepared artifact does not imply a supported viewer experience.
- **D-14:** If the team wants momentum on future promotion, track one internal proof candidate only. Do not leak “targeted for verification” or similar soft-support language into the public contract.
- **D-15:** Do not attempt viewer promotion in Phase 57 unless the evidence already exists before the claim is written. Public support must follow proof, not planned proof.

### Proof artifact scope
- **D-16:** Keep automated structural proof and docs-contract synchronization as the merge-blocking source of truth.
- **D-17:** Add one terse Phase 57 verification note that enumerates unsupported claims by canonical name and points to the exact proof lanes that justify the public contract.
- **D-18:** That verification note must not restate long prose. It should list exact supported and unsupported claim names only, using the same vocabulary as `priv/support_matrix.json`, `guides/api_stability.md`, and docs-contract tests.
- **D-19:** Do not introduce a new structured proof-manifest system in Phase 57. The milestone should close with high-signal evidence, not tooling churn.

### Product and DX posture
- **D-20:** Rendro should continue the library-style Elixir posture used in Ecto, Plug, Phoenix, and Oban: explicit seams, explicit accepted shapes, explicit unsupported cases, and narrow product-facing contracts instead of broad capability umbrellas.
- **D-21:** The overall public story for Phase 57 is:
  - unsigned signature field authoring is supported through the existing forms contract
  - artifact-first signing preparation is supported as a separate post-render contract
  - digital signatures, signer identity/trust, tamper evidence, PAdES/LTV/TSA/OCSP/CRL, and broad viewer guarantees remain unsupported or unverified unless separately proven
- **D-22:** Downstream GSD work should shift routine policy synthesis left by default: prefer one cohesive recommendation set that optimizes for truthful small contracts, least surprise DX, and explicit boundaries. Escalate only when a choice materially changes product semantics, widens public trust claims, or commits Rendro to a substantially broader signing/compliance posture.

### the agent's Discretion
- Exact nested key names under `signing_preparation`, provided they stay small, stable, and non-cryptographic in tone.
- Exact guide heading names and ordering, provided authored unsigned widgets and artifact preparation stay clearly separate.
- Exact verification-note format, provided it remains terse, canonical, and aligned with machine-readable claim names.

</decisions>

<specifics>
## Specific Ideas

- Recommended support-matrix direction:
  - `forms.authored_helpers.signature_field`
  - `forms.widgets.signature`
  - `forms.viewers.<viewer>`
  - `signing_preparation.capabilities.external_artifact_prepare`
  - `signing_preparation.behaviors.final_byte_handoff`
  - `signing_preparation.behaviors.adapter_local_metadata`
  - `signing_preparation.boundaries.digital_signatures`
  - `signing_preparation.boundaries.tamper_evidence`
  - `signing_preparation.boundaries.pades_ltv_tsa_ocsp_crl`
- Recommended wording direction:
  - keep one short lifecycle preamble only
  - one section for authored unsigned signature widgets
  - one section for artifact-first signing preparation
  - each section states supported surface, proof lane, then unsupported claims
- Recommended viewer-proof direction:
  - keep all signature-related viewer rows `unverified` by default
  - only promote a viewer row after a recorded checklist for that exact viewer and surface
  - never use structural proof as a substitute for viewer proof
- Recommended milestone-close proof direction:
  - automated tests prove structural correctness and docs-contract lockstep
  - one narrow verification artifact lists exact unsupported claims by canonical name
- Ecosystem lessons to preserve:
  - successful PDF libraries separate field creation, preparation, and actual signing rather than collapsing them into one “signature support” claim
  - trust-sensitive docs become footguns when they imply more than tests and recorded evidence prove
  - great DX here means narrow truth, not optimistic marketing language

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/PROJECT.md` — v2.0 product posture, truthful signing-preparation boundary, and non-negotiable constraints.
- `.planning/REQUIREMENTS.md` — `TRUST-01`, `TRUST-02`, and `TRUST-03` define the exact required outcomes for Phase 57.
- `.planning/STATE.md` — active milestone state and locked upstream signature/protection decisions.
- `.planning/milestones/v2.0-ROADMAP.md` — Phase 57 boundary, plan split, and success criteria.
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least surprise DX, and recommendation-first default.

### Prior locked precedent
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-CONTEXT.md` — initial forms support-matrix, viewer-proof, and docs-contract philosophy.
- `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md` — family-first support matrix, per-surface viewer claims, and split proof-lane precedent.
- `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-CONTEXT.md` — artifact-first trust-family publication pattern and docs/matrix lockstep discipline.
- `.planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md` — independent viewer-promotion policy and explicit proof-note precedent.
- `.planning/phases/55-signature-field-authoring-contract/55-CONTEXT.md` — authored unsigned signature-field contract and unsupported-signing-state boundaries.
- `.planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md` — rendered signature-widget and `Rendro.Sign.prepare/2` contract that Phase 57 must publish truthfully.
- `.planning/phases/56-writer-and-external-signing-preparation-seam/56-PATTERNS.md` — local analogs for docs, matrix, and proof closure in this milestone.

### Live contract and proof surfaces
- `priv/support_matrix.json` — current machine-readable support contract to extend.
- `guides/api_stability.md` — canonical human-facing support-boundary wording.
- `test/docs_contract/forms_claims_test.exs` — current forms wording and matrix lockstep tests.
- `test/docs_contract/protection_claims_test.exs` — precedent for narrow family publication and explicit negative-claim guards.
- `test/rendro/sign_test.exs` — current preparation-manifest semantics and narrow post-render contract.
- `test/rendro/pdf/writer_test.exs` — rendered signature-widget structural assertions and unsigned guards.
- `scripts/verify_docs.exs` — canonical docs-contract verification entry point.

### External reference points
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` — Elixir precedent for executable documentation and docs-as-contract posture.
- `https://hexdocs.pm/ecto/Ecto.Enum.html` — explicit finite contract shapes in public API design.
- `https://hexdocs.pm/oban/Oban.Worker.html` — idiomatic Elixir explicit option surfaces and stable contract vocabulary.
- `https://pdfbox.apache.org/docs/2.0.7/javadocs/org/apache/pdfbox/examples/signature/package-summary.html` — separation between empty signature fields and signing flows.
- `https://pdf-lib.js.org/docs/api/classes/pdfsignature` — honest narrow stance: recognizes signature fields without broad digital-signature claims.
- `https://hexapdf.gettalong.org/documentation/digital-signatures/signing-pdfs-howto.html` — explicit prepare/sign separation and signing-complexity precedent.
- `https://kb.itextpdf.com/itext/pdf-and-digital-signatures` — example of how quickly signing claims widen into trust/compliance narratives if left underspecified.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `priv/support_matrix.json` already uses the right family-first shape and should be extended rather than redesigned.
- `guides/api_stability.md` already provides the right prose style: narrow support claim, explicit proof lane, explicit unsupported narratives.
- `test/docs_contract/forms_claims_test.exs` and `test/docs_contract/protection_claims_test.exs` already lock both positive and negative claims and should be copied as the Phase 57 docs-contract pattern.
- `Rendro.Sign.prepare/2` and its metadata contract already provide a clean, narrow semantic surface that can be published without widening into real signing support.

### Established Patterns
- Rendro prefers sibling capability families over broad meta-taxonomies.
- Viewer support is published per surface and per viewer, not by milestone-wide badge.
- Structural proof, viewer proof, and public docs claims move together but remain distinct.
- Trust-sensitive surfaces are described more narrowly than the underlying PDF format might permit.

### Integration Points
- Phase 57 should primarily touch `priv/support_matrix.json`, `guides/api_stability.md`, `scripts/verify_docs.exs`, docs-contract tests, and milestone verification artifacts.
- Any new `signing_preparation` support-matrix family must align with existing `Rendro.Sign.prepare/2` metadata semantics without implying signer ownership or cryptographic validity.
- Public wording must preserve the separation between forms authoring, artifact preparation, and external signing workflows.

</code_context>

<deferred>
## Deferred Ideas

- A broad top-level `signatures` taxonomy in the support matrix.
- Any wording that says or implies “digital signing is supported.”
- Viewer promotion for signature-related surfaces without recorded checklist evidence.
- A new structured proof-manifest framework or generic claim-schema system.
- In-core cryptographic signing, signer identity/trust workflows, tamper-evidence claims, compliance/archive narratives, or broad viewer guarantees.

</deferred>

---

*Phase: 57-support-contract-and-proof-closure*
*Context gathered: 2026-05-06*

# Phase 56: Writer and External Signing Preparation Seam - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Serialize deterministic unsigned signature-field PDF structures and add an artifact-first preparation seam for external signing workflows. This phase covers writer-side `/Sig` widget support for the already-locked Phase 55 authored contract plus explicit post-render preparation over final artifact bytes. It does not add in-core cryptographic signing, certificate/key custody, compliance narratives, viewer promotion, or a supported first-party signer integration.

</domain>

<decisions>
## Implementation Decisions

### Writer-side unsigned signature serialization
- **D-01:** Phase 56 writer support stays narrow: serialize a visible unsigned signature field as deterministic AcroForm + widget/field structures only.
- **D-02:** The base writer must emit `/FT /Sig` field/widget support with Rendro-owned appearance streams and explicit geometry, but it must not emit a signature value dictionary (`/V`) during normal render.
- **D-03:** The base writer must not reserve `/Contents`, `/ByteRange`, or other signing placeholders during `Rendro.render/2` or `Rendro.render_to_artifact/2`.
- **D-04:** Signing-policy dictionaries and signer-owned keys remain out of the base writer contract, including `/Lock`, `/SV`, `/Reference`, `/Filter`, `/SubFilter`, certification policy, and other signing-specific semantics.
- **D-05:** Rendro must not infer invisible or auto-placed signature widgets. Missing or invalid geometry remains a validation concern, not a writer convenience path.

### Prepared artifact public API
- **D-06:** The canonical public signing-preparation API should be `Rendro.Sign.prepare/2`.
- **D-07:** `Rendro.Sign.prepare/2` must accept a rendered `%Rendro.Artifact{}` and leave `Rendro.render/2` and `Rendro.render_to_artifact/2` semantics untouched.
- **D-08:** Do not make a root-level `Rendro.prepare_for_signing/2` the primary contract. At most, it can exist later as thin delegating sugar if discoverability pressure proves real.
- **D-09:** Keep the `Rendro` root module small and preserve the current pattern where post-render trust-sensitive transforms live in focused namespaces (`Rendro.Protect.password/2`, now `Rendro.Sign.prepare/2`).

### Prepared artifact handoff data
- **D-10:** Signing preparation must expose a narrow generic manifest rather than raw signer-specific payloads or opaque adapter blobs.
- **D-11:** The prepared output should remain artifact-first and carry a stable nested signing-preparation manifest under artifact metadata rather than widening authored document state.
- **D-12:** The manifest should stay adapter-neutral and limited to the minimum handoff facts external signers need, such as field identity, prepared status, byte-range/content-range coordinates, and reserved signature-content capacity.
- **D-13:** The core manifest must not include key material, certificates, trust policy, signer identity, compliance labels, or other data that reads like cryptographic validity ownership.
- **D-14:** If future signer integrations need extra data, they should add strictly namespaced adapter-local extensions outside the core manifest contract rather than widening the shared core shape.

### Adapter and ecosystem posture
- **D-15:** Phase 56 should stop at the core signing-preparation seam plus an adapter contract. Do not ship a supported first-party signer integration in this phase.
- **D-16:** If a concrete example becomes necessary later, it should be treated as explicitly experimental reference material rather than a promoted supported signer path.
- **D-17:** Preserve Rendro's pure-core and optional-adapter architecture: signing-preparation belongs in core only at the artifact seam, while real signer execution belongs in optional adapters or external workflows.

### Product and DX posture
- **D-18:** Optimize for one cohesive recommendation set that minimizes user decision load: narrow writer serialization, explicit artifact-first prep API, generic prep manifest, and no bundled signer path.
- **D-19:** Keep the support story brutally clear: "unsigned field support" and "prepared for external signing" are supported; "digital signatures", certificate trust, tamper-evidence guarantees, PAdES/LTV/TSA/OCSP/CRL, and viewer/compliance outcomes remain unsupported here.
- **D-20:** Shift this maintainer preference left within downstream GSD work as the default for trust-sensitive library surfaces: present one recommendation-first path unless a decision materially changes public product semantics, widens the support contract, or commits Rendro to a larger compliance/trust posture.

### the agent's Discretion
- Exact module/file placement for `Rendro.Sign` and the preparation behavior, provided the artifact-first boundary stays explicit and root render semantics remain unchanged.
- Exact manifest key names and any helper accessors, provided the manifest stays narrow, adapter-neutral, and non-cryptographic in tone.
- Exact default reserved signature-content sizing and typed error taxonomy, provided they remain deterministic, explicit, and easy to reason about.

</decisions>

<specifics>
## Specific Ideas

- Canonical happy path should read like:
  - `{:ok, artifact} = Rendro.render_to_artifact(doc, deterministic: true)`
  - `{:ok, prepared} = Rendro.Sign.prepare(artifact, field: "customer_signature", reserved_bytes: ...)`
- The prepared result should still be easy to store/deliver as an artifact, but callers must be able to inspect a stable signing-preparation manifest without parsing raw PDF objects themselves.
- Keep the DX closer to `Rendro.Protect.password/2` than to heavyweight signer frameworks. Rendro prepares final bytes; an external signer or adapter owns CMS/PKCS#7 creation and append/incremental signing.
- Avoid successful-library footguns seen elsewhere:
  - no invisible-widget fallback when a field/widget is missing
  - no empty `/V` dictionary during ordinary unsigned rendering
  - no signing-placeholder reservation inside base rendering
  - no signer-specific policy/config sprawl in core docs or APIs
- Keep docs explicit that prepared output may be structurally ready for an external signing workflow without implying that the eventual signed PDF is valid, trusted, compliant, or viewer-proven.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/PROJECT.md` — product posture: deterministic core, truthful support boundaries, optional adapters, and explicit external trust ownership.
- `.planning/REQUIREMENTS.md` — `SIGN-03`, `PREP-01`, `PREP-02`, and `PREP-03` define the required outcomes for this phase.
- `.planning/STATE.md` — active milestone state plus locked upstream signing/protection decisions.
- `.planning/milestones/v2.0-ROADMAP.md` — Phase 56 goal, plan split, dependency chain, and scope limits.
- `.planning/phases/55-signature-field-authoring-contract/55-CONTEXT.md` — locked public authored contract and rejected signature-state categories that Phase 56 must preserve.
- `.planning/METHODOLOGY.md` — truthful small contracts, explicit boundaries, and recommendation-first decision posture.

### Live code seams
- `lib/rendro.ex` — current public render/artifact builders and `render_protected/3` precedent for post-render composition.
- `lib/rendro/artifact.ex` — artifact boundary, metadata updates, and wrap semantics for transformed binaries.
- `lib/rendro/protect.ex` — closest API and metadata precedent for a trust-sensitive artifact-first transform.
- `lib/rendro/protect/adapter.ex` — optional adapter behavior pattern to mirror for signing preparation if needed.
- `lib/rendro/form_field.ex` — locked internal signature-field model and rejection-only carrier from Phase 55.
- `lib/rendro/rules/check_form_fields.ex` — validation boundary that must remain aligned with writer/prep scope.
- `lib/rendro/pdf/writer.ex` — existing AcroForm/widget allocation and appearance-stream patterns to extend for signature widgets.
- `test/rendro/pdf/writer_test.exs` — current deterministic widget serialization assertions and `NeedAppearances` guardrails.
- `guides/api_stability.md` — current public support-boundary wording that must remain truthful when Phase 56 claims expand.

### External reference points
- `https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html` — narrow external-signing seam precedent: get bytes to sign, then set CMS bytes back.
- `https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html` — signing/field separation precedent plus the non-visible-widget fallback footgun to avoid.
- `https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html` — broader signer-layer precedent and invisible-new-field default that Rendro should not inherit.
- `https://pdf-lib.js.org/docs/api/classes/pdfsignature` — honest narrow-support precedent: signature fields recognized without broad digital-signature APIs.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — idiomatic Elixir precedent for focused namespaces owning explicit operations on an existing value.
- `https://hexdocs.pm/plug/Plug.Conn.html` — idiomatic Elixir precedent for explicit transform-style APIs with clear boundary ownership.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Artifact.wrap/3` already provides the right post-render transform seam for updated bytes plus nested metadata.
- `Rendro.Protect.password/2` already proves the preferred user experience: artifact-first input, narrow option normalization, typed failures, and wrapped output.
- `Rendro.PDF.Writer` already has deterministic allocation and appearance-stream patterns for text, checkbox, and radio widgets that a signature widget should mirror without opening a new writer subsystem.
- Existing docs-contract tests around forms and protection already provide the right truthfulness gate for later support-surface wording.

### Established Patterns
- Rendro keeps public contracts narrow, explicit, and typed rather than permissive or magical.
- Trust-sensitive behavior is modeled as explicit post-render artifact work rather than hidden render flags.
- Optional ecosystem value is delivered through adapter seams, not by entangling core with third-party trust infrastructure.
- Support claims are separated from structural correctness and from viewer/cryptographic validity claims.

### Integration Points
- Phase 56-01 should extend the existing AcroForm/widget writer path for `:signature` without changing the authored field model introduced in Phase 55.
- Phase 56-02 should introduce a focused `Rendro.Sign` seam over `%Rendro.Artifact{}` and, if needed, a preparation behavior that future adapters can consume.
- Phase 57 should build directly on the manifest and docs wording chosen here; avoid any Phase 56 API shape that would force support-matrix overclaiming later.

</code_context>

<deferred>
## Deferred Ideas

- In-core cryptographic signing helpers or a public `Rendro.Sign.sign/2`.
- Supported first-party signer integrations, certificate/key custody, HSM/KMS bindings, or OpenSSL-backed productized adapters.
- Signer metadata on authored document state (`reason`, `location`, `contact`, signing time) or signing-policy passthrough in the core authoring surface.
- PAdES, LTV, TSA, OCSP, CRL, certification/DocMDP/FieldMDP narratives, or compliance-oriented product claims.
- Viewer promotion or cryptographic-validity claims before dedicated proof work lands in Phase 57 or a later milestone.

</deferred>

---

*Phase: 56-writer-and-external-signing-preparation-seam*
*Context gathered: 2026-05-06*

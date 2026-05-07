# Phase 56: Writer and External Signing Preparation Seam - Research

**Researched:** 2026-05-06
**Domain:** Deterministic unsigned signature-widget serialization plus artifact-first external-signing preparation over `%Rendro.Artifact{}` [VERIFIED: codebase grep]
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

The following sections are copied verbatim from `.planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions
- **D-01:** Phase 56 writer support stays narrow: serialize a visible unsigned signature field as deterministic AcroForm + widget/field structures only.
- **D-02:** The base writer must emit `/FT /Sig` field/widget support with Rendro-owned appearance streams and explicit geometry, but it must not emit a signature value dictionary (`/V`) during normal render.
- **D-03:** The base writer must not reserve `/Contents`, `/ByteRange`, or other signing placeholders during `Rendro.render/2` or `Rendro.render_to_artifact/2`.
- **D-04:** Signing-policy dictionaries and signer-owned keys remain out of the base writer contract, including `/Lock`, `/SV`, `/Reference`, `/Filter`, `/SubFilter`, certification policy, and other signing-specific semantics.
- **D-05:** Rendro must not infer invisible or auto-placed signature widgets. Missing or invalid geometry remains a validation concern, not a writer convenience path.
- **D-06:** The canonical public signing-preparation API should be `Rendro.Sign.prepare/2`.
- **D-07:** `Rendro.Sign.prepare/2` must accept a rendered `%Rendro.Artifact{}` and leave `Rendro.render/2` and `Rendro.render_to_artifact/2` semantics untouched.
- **D-08:** Do not make a root-level `Rendro.prepare_for_signing/2` the primary contract. At most, it can exist later as thin delegating sugar if discoverability pressure proves real.
- **D-09:** Keep the `Rendro` root module small and preserve the current pattern where post-render trust-sensitive transforms live in focused namespaces (`Rendro.Protect.password/2`, now `Rendro.Sign.prepare/2`).
- **D-10:** Signing preparation must expose a narrow generic manifest rather than raw signer-specific payloads or opaque adapter blobs.
- **D-11:** The prepared output should remain artifact-first and carry a stable nested signing-preparation manifest under artifact metadata rather than widening authored document state.
- **D-12:** The manifest should stay adapter-neutral and limited to the minimum handoff facts external signers need, such as field identity, prepared status, byte-range/content-range coordinates, and reserved signature-content capacity.
- **D-13:** The core manifest must not include key material, certificates, trust policy, signer identity, compliance labels, or other data that reads like cryptographic validity ownership.
- **D-14:** If future signer integrations need extra data, they should add strictly namespaced adapter-local extensions outside the core manifest contract rather than widening the shared core shape.
- **D-15:** Phase 56 should stop at the core signing-preparation seam plus an adapter contract. Do not ship a supported first-party signer integration in this phase.
- **D-16:** If a concrete example becomes necessary later, it should be treated as explicitly experimental reference material rather than a promoted supported signer path.
- **D-17:** Preserve Rendro's pure-core and optional-adapter architecture: signing-preparation belongs in core only at the artifact seam, while real signer execution belongs in optional adapters or external workflows.
- **D-18:** Optimize for one cohesive recommendation set that minimizes user decision load: narrow writer serialization, explicit artifact-first prep API, generic prep manifest, and no bundled signer path.
- **D-19:** Keep the support story brutally clear: "unsigned field support" and "prepared for external signing" are supported; "digital signatures", certificate trust, tamper-evidence guarantees, PAdES/LTV/TSA/OCSP/CRL, and viewer/compliance outcomes remain unsupported here.
- **D-20:** Shift this maintainer preference left within downstream GSD work as the default for trust-sensitive library surfaces: present one recommendation-first path unless a decision materially changes public product semantics, widens the support contract, or commits Rendro to a larger compliance/trust posture.

### Claude's Discretion
- Exact module/file placement for `Rendro.Sign` and the preparation behavior, provided the artifact-first boundary stays explicit and root render semantics remain unchanged.
- Exact manifest key names and any helper accessors, provided the manifest stays narrow, adapter-neutral, and non-cryptographic in tone.
- Exact default reserved signature-content sizing and typed error taxonomy, provided they remain deterministic, explicit, and easy to reason about.

### Deferred Ideas (OUT OF SCOPE)
- In-core cryptographic signing helpers or a public `Rendro.Sign.sign/2`.
- Supported first-party signer integrations, certificate/key custody, HSM/KMS bindings, or OpenSSL-backed productized adapters.
- Signer metadata on authored document state (`reason`, `location`, `contact`, signing time) or signing-policy passthrough in the core authoring surface.
- PAdES, LTV, TSA, OCSP, CRL, certification/DocMDP/FieldMDP narratives, or compliance-oriented product claims.
- Viewer promotion or cryptographic-validity claims before dedicated proof work lands in Phase 57 or a later milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement descriptions are copied from `.planning/REQUIREMENTS.md`. [VERIFIED: codebase grep]

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGN-03 | Rendro serializes the required AcroForm, widget, and signature-related PDF structures deterministically for identical authored inputs. | Extend `Rendro.PDF.Writer` with a dedicated `:signature` widget branch instead of reusing the current text-field `/FT /Tx` builder, and add deterministic writer assertions that the unsigned render includes `/FT /Sig` plus appearance geometry while omitting `/V`, `/Contents`, `/ByteRange`, and signer-policy dictionaries. [VERIFIED: codebase grep] |
| PREP-01 | Engineers can prepare a rendered `%Rendro.Artifact{}` for external signing through an artifact-first API that does not change `Rendro.render/2` semantics. | Add `Rendro.Sign.prepare/2` beside `Rendro.Protect.password/2`, with option normalization and `Artifact.wrap/3` output rather than any new render flag or root-level builder API. [VERIFIED: codebase grep] |
| PREP-02 | The signing-preparation seam operates on final artifact bytes and preserves a clear terminal handoff boundary for append or incremental signing workflows. | Keep preparation post-render and binary-first, mirroring PDFBox’s external-signing split of “get bytes to sign, then set CMS bytes back,” while publishing only a narrow manifest over the prepared artifact. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] |
| PREP-03 | Key custody, certificate management, and signer-specific trust operations remain outside Rendro core and inside optional adapters or external workflows. | Add at most a thin optional signer-adapter behaviour and keep signer execution, key material, certificates, and trust policy out of core manifests and APIs. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 56 should reuse two seams Rendro already trusts: the writer’s existing standalone-widget allocation/build path and the artifact-first post-render transform pattern used by `Rendro.Protect.password/2`. `Rendro.PDF.Writer` already allocates standalone fields as one field/widget object plus deterministic appearance objects, and `Rendro.Protect` already demonstrates the preferred public API shape for a trust-sensitive transform over `%Rendro.Artifact{}`. [VERIFIED: codebase grep]

The concrete planning implication is to keep render-time and prepare-time responsibilities sharply separated. Normal render should emit a visible unsigned `/Sig` widget with Rendro-owned appearance and explicit geometry, but no `/V`, `/Contents`, `/ByteRange`, `/Lock`, `/SV`, `/Reference`, `/Filter`, or `/SubFilter`. Preparation should happen only after `render_to_artifact/2`, update the final bytes through `Artifact.wrap/3`, and publish a small manifest under artifact metadata that external signers can consume without implying any in-core cryptographic ownership. [VERIFIED: codebase grep]

The main technical wrinkle is that `%Rendro.Artifact{}` currently stores only `binary`, `hash`, `diagnostics`, and merged `metadata`; it does not retain the original `%Rendro.Document{}` or any form-field inventory. That means `Rendro.Sign.prepare/2` cannot depend on upstream authored state and should instead target Rendro’s own deterministic unsigned signature-field serialization in the rendered PDF bytes. [VERIFIED: codebase grep]

**Primary recommendation:** implement Phase 56 as two tightly-coupled slices: first add a dedicated unsigned signature-widget branch to `Rendro.PDF.Writer`; then add `Rendro.Sign.prepare/2` plus a narrow manifest over `Artifact.wrap/3`, with optional signer execution deferred behind a behaviour-only adapter boundary. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Unsigned `/Sig` widget serialization | `Rendro.PDF.Writer` [VERIFIED: codebase grep] | `Rendro.Rules.CheckFormFields` [VERIFIED: codebase grep] | Writer already owns AcroForm injection, standalone widget allocation, page `/Annots`, and appearance streams; validation already owns geometry rejection and blocked signature attrs. [VERIFIED: codebase grep] |
| Artifact-first signing preparation API | `Rendro.Sign` [ASSUMED] | `Rendro.Artifact` [VERIFIED: codebase grep] | `Rendro.Protect` establishes the namespace-first transform pattern, while `Artifact.wrap/3` is the existing wrapper for post-render binary mutation. [VERIFIED: codebase grep] |
| Prepared-artifact manifest storage | `Rendro.Artifact.metadata.signing_preparation` [ASSUMED] | future adapter-local metadata namespaces [ASSUMED] | Phase context locks a stable nested artifact manifest and explicitly rejects widening authored state or returning signer-specific blobs. [VERIFIED: codebase grep] |
| External signer execution | optional `Rendro.Sign.Adapter` behaviour [ASSUMED] | external workflow/tooling [VERIFIED: codebase grep] | Phase 56 stops at preparation plus an adapter boundary; actual signer execution remains outside core. [VERIFIED: codebase grep] |
| Truthful support wording | `guides/api_stability.md` [VERIFIED: codebase grep] | `priv/support_matrix.json`, docs-contract tests [VERIFIED: codebase grep] | Current forms/protection work already treats support docs plus matrix tests as the product contract, and signature claims are still narrow and negative by default. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir + OTP [VERIFIED: local env] | 1.19.5 + 28 [VERIFIED: local env] | Implement writer branching, binary surgery, behaviours, and typed tuple APIs without adding runtime dependencies. [VERIFIED: local env] | The project runtime is already Elixir-first and Phase 56 does not require any new third-party signing library inside core. [VERIFIED: codebase grep] |
| Rendro core writer [VERIFIED: codebase grep] | workspace `0.2.0` from `mix.exs` [VERIFIED: codebase grep] | Own deterministic AcroForm serialization, widget object allocation, and page annotation wiring. [VERIFIED: codebase grep] | Existing forms, links, and embedded files all extend this one writer instead of adding parallel serializers. [VERIFIED: codebase grep] |
| Rendro artifact seam [VERIFIED: codebase grep] | workspace `0.2.0` from `mix.exs` [VERIFIED: codebase grep] | Carry final bytes plus metadata across post-render transforms. [VERIFIED: codebase grep] | `Artifact.new/3` and `Artifact.wrap/3` are already the canonical boundary for async and ecosystem operations. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rendro.Protect` pattern [VERIFIED: codebase grep] | workspace `0.2.0` [VERIFIED: codebase grep] | Model narrow option normalization, typed failure wrapping, and artifact-first namespace design. [VERIFIED: codebase grep] | Use as the direct API/metadata precedent for `Rendro.Sign.prepare/2`. [VERIFIED: codebase grep] |
| PDFBox external-signing split [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] | 2.0.13 docs page [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] | Reference the minimal “bytes to sign in, CMS bytes back out” boundary. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] | Use as a boundary model, not as a dependency. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] |
| `Rendro.Sign` namespace [ASSUMED] | new in this phase [ASSUMED] | Expose the canonical `prepare/2` surface without growing the root `Rendro` API. [ASSUMED] | Use for all core signing-preparation work. [ASSUMED] |
| `Rendro.Sign.Adapter` behaviour [ASSUMED] | new in this phase [ASSUMED] | Preserve the optional-adapter boundary for future signer execution. [ASSUMED] | Add only as a contract; do not ship a supported adapter here. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Rendro.Sign.prepare/2` over `%Rendro.Artifact{}` [VERIFIED: codebase grep] | render-time signing flags on `Rendro.render/2` [ASSUMED] | Render flags would violate the locked artifact-first seam and blur the terminal handoff boundary. [VERIFIED: codebase grep] |
| Dedicated `/Sig` widget builder branch in `Rendro.PDF.Writer` [VERIFIED: codebase grep] | Reuse the current text-field builder and patch strings later [ASSUMED] | The text-field branch emits `/FT /Tx`, `/V`, and text-value appearance content today, which is exactly the wrong unsigned-signature contract. [VERIFIED: codebase grep] |
| Narrow core manifest plus optional behaviour boundary [VERIFIED: codebase grep] | first-party signer integration in core [VERIFIED: codebase grep] | A built-in signer path would pull key custody, certificates, and policy posture into the core milestone that explicitly defers them. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new packages required for Phase 56.
```

**Version verification:** No npm packages are part of this phase. Project/runtime versions were verified from `mix.exs`, `elixir --version`, and `mix --version`. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
authored doc with Rendro.signature_field/2
  -> Validate pipeline rejects unsupported signature attrs / zero-rect state
  -> Rendro.PDF.Writer allocates standalone signature field objects
  -> render/render_to_artifact emits unsigned /Sig widget with AP + geometry only
  -> %Rendro.Artifact{binary, hash, diagnostics, metadata}
  -> Rendro.Sign.prepare(artifact, field: "...", reserved_bytes: ...)
  -> binary-level placeholder update + signing_preparation manifest
  -> prepared %Rendro.Artifact{}
  -> optional external signer / adapter performs CMS creation and final append/incremental signing
```

This is the narrowest architecture that satisfies `SIGN-03`, `PREP-01`, `PREP-02`, and `PREP-03` without altering `Rendro.render/2` semantics or claiming in-core digital-signature ownership. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/
├── rendro/pdf/writer.ex      # add unsigned /Sig widget allocation, object build, AP stream branch
├── rendro/sign.ex            # new artifact-first prepare/2 API and option normalization
└── rendro/sign/adapter.ex    # new optional behaviour for future signer execution

test/
├── rendro/pdf/writer_test.exs  # signature widget structure and omission assertions
└── rendro/sign_test.exs        # prepare/2 manifest, placeholder, and error-path coverage
```

This layout preserves the current split between render-time PDF generation and post-render trust-sensitive transforms. [VERIFIED: codebase grep]

### Pattern 1: Extend the Existing Standalone Widget Funnel
**What:** Reuse `allocate_standalone_form_field/2`, page-level annotation emission, and AcroForm `/Fields` injection for `:signature`, then branch only at widget-object and appearance construction. [VERIFIED: codebase grep]
**When to use:** For every visible unsigned signature placeholder emitted during normal render. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source pattern: lib/rendro/pdf/writer.ex
# Existing standalone widgets already flow through one allocation path.
base = %{
  type: form_field.field.type,
  field_obj_num: num,
  block: form_field.block,
  field: form_field.field,
  page_index: form_field.page_index,
  widget_obj_num: num
}
```

### Pattern 2: Model Signing Preparation Like Protection, Not Like Rendering
**What:** Make `Rendro.Sign.prepare/2` accept a rendered `%Rendro.Artifact{}`, normalize explicit options, mutate bytes once, and return `Artifact.wrap/3` output with a nested manifest. [VERIFIED: codebase grep]
**When to use:** Any flow that needs external-signing handoff after deterministic render is already complete. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source pattern: lib/rendro/protect.ex + lib/rendro/artifact.ex
with {:ok, normalized} <- normalize_opts(opts),
     {:ok, prepared_binary, manifest} <- do_prepare(artifact, normalized) do
  {:ok, Artifact.wrap(prepared_binary, artifact, %{signing_preparation: manifest})}
end
```

### Pattern 3: Keep Signer Execution on a Separate Optional Boundary
**What:** If Phase 56 adds an adapter contract, keep it behaviour-only and do not ship a supported first-party signer. [VERIFIED: codebase grep]
**When to use:** Only for future external signer integrations, not for the core prepare path itself. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source precedent: lib/rendro/protect/adapter.ex
@callback sign(Rendro.Artifact.t(), keyword()) :: {:ok, binary()} | {:error, term()}
```

### Anti-Patterns to Avoid
- **Reusing the text-field widget builder for signatures:** the current builder hardcodes `/FT /Tx`, serializes `/V`, and paints the field value in the appearance stream, which violates the locked unsigned-signature contract. [VERIFIED: codebase grep]
- **Copying protection’s `deterministic: false` metadata blindly:** protection does this because encryption is non-deterministic today; Phase 56 should decide its own metadata posture deliberately rather than cargo-culting that branch. [VERIFIED: codebase grep]
- **Expecting `prepare/2` to inspect the original `%Rendro.Document{}`:** `Rendro.Artifact` does not retain it. [VERIFIED: codebase grep]
- **Bundling signer defaults into core:** HexaPDF will create a non-visible widget if a signature field has none, and iText’s signer surface includes field creation, pre-close, range streaming, and detached-signature execution; Rendro should avoid inheriting that breadth. [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html] [CITED: https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cryptographic signing | CMS/PKCS#7 creation, certificate validation, TSA/OCSP/CRL logic in core [VERIFIED: codebase grep] | optional adapters or external signing workflows [VERIFIED: codebase grep] | Phase 56 explicitly defers all key custody and compliance posture. [VERIFIED: codebase grep] |
| Generic second PDF writer | Parallel serializer for signature fields [VERIFIED: codebase grep] | Extend the existing `Rendro.PDF.Writer` allocation/build path [VERIFIED: codebase grep] | Forms, links, and embedded files already ride one deterministic writer. [VERIFIED: codebase grep] |
| Signer-owned policy surface | `/Lock`, `/SV`, `/Reference`, `/Filter`, `/SubFilter`, certification helpers in normal render [VERIFIED: codebase grep] | Keep normal render unsigned and add only post-render preparation seam [VERIFIED: codebase grep] | Locked decisions explicitly reject signer-policy dictionaries in base writer output. [VERIFIED: codebase grep] |
| Convenience placement magic | Invisible widgets or inferred page placement [VERIFIED: codebase grep] | Explicit geometry validated before render [VERIFIED: codebase grep] | HexaPDF documents a non-visible-widget fallback, which is precisely the footgun Phase 56 says to avoid. [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html] |

**Key insight:** Rendro should hand-roll only the narrow PDF object shapes and manifest it fully owns; it should not hand-roll a general-purpose signing stack or a second rendering subsystem. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Letting the Existing Text-Field Branch Leak `/V`
**What goes wrong:** A quick implementation reuses `build_widget_annotation_object/5`, which emits `/FT /Tx`, `/V`, and text-value appearance content. [VERIFIED: codebase grep]
**Why it happens:** Standalone fields already share one path, so it is tempting to treat `:signature` like “text with empty value.” [VERIFIED: codebase grep]
**How to avoid:** Add a dedicated `:signature` branch in `build_widget_objects/4` and a dedicated appearance-stream builder. [VERIFIED: codebase grep]
**Warning signs:** Rendered PDF contains `/FT /Tx`, `/V ()`, or signature placeholder text copied from `field.value`. [VERIFIED: codebase grep]

### Pitfall 2: Designing `prepare/2` Around Data the Artifact Does Not Have
**What goes wrong:** The API assumes it can inspect original form structs or page/block metadata from `%Rendro.Artifact{}`. [VERIFIED: codebase grep]
**Why it happens:** `render_to_artifact/2` is close to render code, but `Artifact.new/3` strips the final document down to `diagnostics` and merged `metadata`. [VERIFIED: codebase grep]
**How to avoid:** Treat prepare as a binary-level operation over Rendro-owned unsigned signature-field output, or add a minimal internal index only if binary lookup proves too fragile. [ASSUMED]
**Warning signs:** The implementation starts threading `%Rendro.Document{}` into `Rendro.Sign.prepare/2` or proposes new render options solely to make prepare easier. [VERIFIED: codebase grep]

### Pitfall 3: Widening the Manifest Into a Signer Payload
**What goes wrong:** The manifest starts carrying signer identity, certs, algorithms, trust labels, or adapter blobs. [VERIFIED: codebase grep]
**Why it happens:** External signing libraries often combine field selection, signature dictionary policy, and cryptographic execution in one object. [CITED: https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html]
**How to avoid:** Keep only field identity, prepared status, reserved content capacity, and byte-range/content coordinates in the core manifest. [VERIFIED: codebase grep]
**Warning signs:** Manifest keys start reading like signature validation or compliance outputs instead of preparation coordinates. [VERIFIED: codebase grep]

### Pitfall 4: Overclaiming Product Support as Soon as the Writer Works
**What goes wrong:** Writer tests pass and docs start implying digital signatures, trusted signatures, or viewer-proofed signature behavior. [VERIFIED: codebase grep]
**Why it happens:** The repo already exposes a public `signature_field/2` helper and future preparation seam, so it is easy to collapse authored-placeholder support into signing claims. [VERIFIED: codebase grep]
**How to avoid:** Keep docs/support-matrix work in Phase 57 and continue the current negative-claim discipline from `guides/api_stability.md` and docs-contract tests. [VERIFIED: codebase grep]
**Warning signs:** Phrases like “digital signatures supported,” “tamper evidence,” or “signature widgets supported in viewers” appear before proof work lands. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official and in-repo sources:

### Artifact-first transform wrapping
```elixir
# Source: lib/rendro/protect.ex + lib/rendro/artifact.ex
with {:ok, normalized} <- normalize_opts(opts),
     {:ok, protected_binary} <- normalized.adapter.protect(artifact, normalized) do
  {:ok,
   Artifact.wrap(
     protected_binary,
     artifact,
     %{
       deterministic: false,
       protection: protection_metadata(normalized)
     }
   )}
end
```

### External-signing seam precedent
```text
# Source: PDFBox ExternalSigningSupport
getContent()      -> get PDF content to be signed
setSignature(...) -> set CMS signature bytes to PDF
```

### Honest narrow signature support precedent
```text
# Source: pdf-lib PDFSignature docs
Represents a signature field.
Specialized APIs for creating digital signatures are not currently provided.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Monolithic signer objects that mix field creation, signature policy, and detached-signature execution [CITED: https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html] | Narrow external-signing seams that separate “prepare bytes” from “produce CMS signature” [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html] | Current official docs already show both models. [CITED: https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html] | Rendro should align with the narrow seam, not the monolith. [VERIFIED: codebase grep] |
| Convenience fallback that creates or rehomes signature widgets for the caller [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html] | Explicit authored visible widget with validation-owned geometry [VERIFIED: codebase grep] | Phase 55 locked the visible-placeholder contract on 2026-05-06. [VERIFIED: codebase grep] | Keeps scope truthful and deterministic. [VERIFIED: codebase grep] |
| Signature-field recognition bundled with broad signing expectations [ASSUMED] | Signature-field recognition without specialized signing APIs [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] | Current pdf-lib docs page. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature] | Supports Rendro’s “unsigned field + prepared artifact” wording without implying full signing support. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating normal render as the place to reserve `/Contents` or `/ByteRange` is outdated for this milestone because the phase context explicitly moves placeholder reservation out of `Rendro.render/2` and into post-render preparation. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.Sign.prepare/2` should locate target signature fields from Rendro-owned rendered bytes using a narrow byte-level lookup scoped to Phase 56-01 output. [ASSUMED] | Common Pitfalls / Open Questions | If the rendered unsigned widget shape changes unexpectedly, the prep seam could need a new explicit indexing decision in a later phase. |
| A2 | `metadata.signing_preparation` is the right nested manifest key for the prepared artifact. [ASSUMED] | Architectural Responsibility Map / Code Examples | A later rename would force API and docs churn across tests and downstream adapters. |
| A3 | A future optional adapter behaviour should be named `Rendro.Sign.Adapter` and shaped around signer execution rather than core preparation. [ASSUMED] | Standard Stack / Architecture Patterns | The planner could create an extra abstraction that Phase 56 does not actually need yet. |

## Open Questions (resolved for planning)

1. **Should preparation rely purely on binary lookup or add a minimal internal signature-field index to artifact metadata?**
   - Decision for Phase 56: use byte-level lookup scoped strictly to Rendro-authored unsigned signature widgets emitted by `56-01`.
   - Why: `%Rendro.Artifact{}` does not retain the authored document, and adding a new render-time metadata index would widen the artifact contract before the repo has evidence it is necessary.
   - Escalation boundary: if implementation evidence shows the narrow lookup is too brittle, treat that as a new scoped decision after execution evidence rather than leaving it open during planning.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with the current Elixir toolchain. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/rendro/pdf/writer_test.exs test/rendro/sign_test.exs -x`. [ASSUMED] |
| Full suite command | `mix test`. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGN-03 | Unsigned signature widgets serialize deterministic `/Sig` field/widget structures and omit signer placeholders during normal render. [VERIFIED: codebase grep] | unit | `mix test test/rendro/pdf/writer_test.exs -x` [VERIFIED: codebase grep] | ✅ [VERIFIED: codebase grep] |
| PREP-01 | `Rendro.Sign.prepare/2` accepts a rendered artifact and returns a wrapped prepared artifact without changing `Rendro.render/2` semantics. [VERIFIED: codebase grep] | unit | `mix test test/rendro/sign_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |
| PREP-02 | Prepared artifact bytes contain reserved signing placeholders plus a manifest exposing reserved capacity and byte/content coordinates. [VERIFIED: codebase grep] | unit | `mix test test/rendro/sign_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |
| PREP-03 | Core rejects signer-specific trust material and keeps real signer execution outside core APIs. [VERIFIED: codebase grep] | unit | `mix test test/rendro/sign_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pdf/writer_test.exs test/rendro/sign_test.exs -x`. [ASSUMED]
- **Per wave merge:** `mix test`. [VERIFIED: codebase grep]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/rendro/sign_test.exs` — required for `PREP-01`, `PREP-02`, and `PREP-03`. [ASSUMED]
- [ ] Signature-specific cases in `test/rendro/pdf/writer_test.exs` — required for `SIGN-03`. [VERIFIED: codebase grep]
- [ ] Optional metadata assertions in `test/rendro/artifact_test.exs` if preparation metadata is added through `Artifact.wrap/3`. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | No user/session auth surface is part of Phase 56. [VERIFIED: codebase grep] |
| V3 Session Management | no [VERIFIED: codebase grep] | No session boundary is introduced by writer or artifact preparation work. [VERIFIED: codebase grep] |
| V4 Access Control | no [VERIFIED: codebase grep] | The phase operates on caller-provided artifacts, not authorization policy. [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Follow `Rendro.Protect`-style option normalization and typed failures for `field`, `reserved_bytes`, and adapter selection. [VERIFIED: codebase grep] |
| V6 Cryptography | no in core / yes at boundary [VERIFIED: codebase grep] | Keep cryptographic signing outside core and never hand-roll CMS, cert, TSA, OCSP, or CRL logic in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Preparing the wrong field because field lookup is ambiguous or too permissive [ASSUMED] | Tampering | Require explicit field identity, reject zero or multiple matches, and target only Rendro-authored unsigned `/Sig` output shapes. [ASSUMED] |
| Leaking signer secrets or adapter details through metadata or public errors later [VERIFIED: codebase grep] | Information Disclosure | Copy `Rendro.Protect`’s redaction discipline: keep manifests non-secret and redact adapter failures before surfacing them. [VERIFIED: codebase grep] |
| Oversized or malformed reserved-content requests causing broken artifacts or memory churn [ASSUMED] | Denial of Service | Validate `reserved_bytes` as a bounded positive integer before binary mutation. [ASSUMED] |
| Docs implying trusted digital signatures once preparation exists [VERIFIED: codebase grep] | Repudiation | Keep support language narrow and negative until Phase 57 proof work lands. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `lib/rendro/pdf/writer.ex` — current standalone field allocation, widget object builders, appearance streams, AcroForm injection, and page annotation seams. [VERIFIED: codebase grep]
- `lib/rendro/artifact.ex` — artifact boundary, retained fields, and `wrap/3` merge behavior. [VERIFIED: codebase grep]
- `lib/rendro/protect.ex` and `lib/rendro/protect/adapter.ex` — artifact-first API precedent, redaction posture, and optional adapter behaviour pattern. [VERIFIED: codebase grep]
- `.planning/phases/56-writer-and-external-signing-preparation-seam/56-CONTEXT.md` — locked phase decisions and canonical scope. [VERIFIED: codebase grep]
- `.planning/phases/55-signature-field-authoring-contract/55-CONTEXT.md` and `55-RESEARCH.md` — upstream authored signature-field contract and existing rejection posture. [VERIFIED: codebase grep]
- `test/rendro/pdf/writer_test.exs`, `test/rendro/pipeline/validate_test.exs`, `test/rendro/rules/check_form_fields_test.exs`, `test/rendro/protect_test.exs` — current regression seams and truthfulness guards. [VERIFIED: codebase grep]
- PDFBox `ExternalSigningSupport` — narrow external-signing API with content retrieval and signature injection. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html]
- HexaPDF `DigitalSignature::Signatures` — signature-field/signing combination surface and non-visible-widget fallback. [CITED: https://hexapdf.gettalong.org/documentation/api/HexaPDF/DigitalSignature/Signatures.html]
- iText `PdfSigner` — broader signer-layer API including pre-close, range streaming, detached signing, and form-field creation hooks. [CITED: https://api.itextpdf.com/iText/java/9.1.0/com/itextpdf/signatures/PdfSigner.html]
- pdf-lib `PDFSignature` — narrow recognition of signature fields without specialized digital-signature APIs. [CITED: https://pdf-lib.js.org/docs/api/classes/pdfsignature]

### Secondary (MEDIUM confidence)
- `mix.exs`, `elixir --version`, and `mix --version` — project/runtime version verification. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None. All unverified design recommendations are marked `[ASSUMED]`. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 56 does not need new external packages and the relevant runtime/module seams were verified directly in the repo and local toolchain. [VERIFIED: codebase grep]
- Architecture: MEDIUM - The public seam and writer extension path are strongly grounded in the repo, but the exact byte-level preparation strategy and manifest key shape still involve implementation choices. [VERIFIED: codebase grep]
- Pitfalls: HIGH - The highest-risk mistakes are directly visible from the current writer branches, artifact shape, support docs, and official signing-library docs. [VERIFIED: codebase grep]

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 for repo-internal seams; re-check external signing-library docs earlier if the plan starts introducing a real signer adapter. [CITED: https://pdfbox.apache.org/docs/2.0.13/javadocs/org/apache/pdfbox/pdmodel/interactive/digitalsignature/ExternalSigningSupport.html]

# API Stability and Support Boundaries

## Semantic Versioning Expectations

Rendro adheres to Semantic Versioning (SemVer).

### The `0.x.x` Era (Current)
During the `0.x.x` era, the API is considered stable enough for production use, but minor versions (for example `0.1.x` to `0.2.0`) may introduce breaking changes. We commit to providing clear upgrade paths and changelogs for any breaking changes during this era. Patch versions (for example `0.2.0` to `0.2.1`) will remain strictly backward compatible and only contain bug fixes or additive features.

### The `1.x.x` Era (Future)
Once Rendro reaches `1.0.0`, breaking changes will only occur in major version bumps (e.g., `1.x.x` to `2.0.0`).

## Core API vs Adapters

- **Core API (`Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.flow/2`):** This is the primary surface area. Breaking changes here will be minimal and heavily telegraphed.
- **Adapters (`Rendro.Adapters.*`):** Adapters integrate with third-party libraries (e.g., Phoenix, Oban, Threadline). Since these depend on external ecosystems, their APIs may need to evolve more frequently. We will strive to align adapter breaking changes with major version changes of their underlying dependencies.
- **Diagnostics (`Rendro.Inspector`, `:diagnostics` map):** The structure of diagnostics maps is intended for developer-facing debugging and is considered stable for common keys (`:level`, `:type`), but additive keys may be introduced in any release.

## Deprecation Policy

When an API is deprecated:
1. It will be marked with Elixir's `@deprecated` attribute.
2. It will continue to function without breaking for at least one minor release in the `0.x.x` era, or one major release in the `1.x.x` era.
3. The documentation will clearly point to the recommended replacement.

## Viewer Evidence and CHANGELOG Discipline

Promotions (`unverified` → `supported`), new `explicit_deferral` rows, and legacy `supported` re-homes into `priv/viewer_evidence/` are public-contract changes requiring CHANGELOG entries. Re-validations that refresh `recorded_at` are also recorded.

See `guides/viewer_evidence.md` for the operator recording recipe.

## Interactive Forms Support Boundary

Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders.

Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior.

Rendro can author an unsigned placeholder, render an artifact, prepare that final artifact for a lower-level external workflow, or sign the original unsigned artifact through a narrow optional adapter boundary.

### Unsigned Signature Widgets

Supported surface: `Rendro.signature_field/2` authors unsigned signature placeholders, and Rendro renders those placeholders as unsigned `/Sig` widgets only.

Proof lane: deterministic writer and structural tests prove unsigned widget structure only. Structural proof is not viewer proof and not cryptographic validity proof.

Unsupported narratives: digital signatures, signer identity or trust, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported. Signature-widget viewer rows are promoted only when a recorded checklist exists for that exact viewer and unsigned-widget surface; PDF.js is `explicit_deferral` pending upstream signature-field support.

For text fields, checkboxes, and radio groups, Apple Preview is `supported` for `forms` based on the recorded viewer checklist for version **v0.10.3** on **macOS (arm64)** (`priv/viewer_evidence/forms/apple_preview.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture via pdfium-cli structural automation proxy (GUI Apple Preview not re-run in CI).

Adobe Acrobat Reader is `supported` for `forms` based on the recorded viewer checklist for version **v0.10.3** on **Ubuntu (amd64)** (`priv/viewer_evidence/forms/adobe_acrobat_reader.md`). That proof confirms the same four-check forms checklist via pdfium-cli structural automation proxy (GUI Acrobat not re-run in CI).

Chrome PDFium is `supported` for `forms` based on the recorded viewer checklist for version **v0.10.3** on **macOS (arm64)** (`priv/viewer_evidence/forms/chrome_pdfium.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture via pdfium-cli automation proxy.

PDF.js is `explicit_deferral` for `forms` because the four-check save-and-reopen round-trip failed on the representative fixture during Phase 71 review — edit/toggle persistence is not reliable.

Adobe Acrobat Reader is `supported` for unsigned `signature_widget` based on the recorded checklist (`priv/viewer_evidence/signature_widget/adobe_acrobat_reader.md`). Apple Preview is `supported` with evidence at `priv/viewer_evidence/signature_widget/apple_preview.md`. Chrome PDFium is `supported` with evidence at `priv/viewer_evidence/signature_widget/chrome_pdfium.md`. PDF.js is `explicit_deferral` for signature widgets per mozilla/pdf.js#4202.

Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them.

## Signing Preparation Support Boundary

Supported surface: `Rendro.Sign.prepare/2` is an artifact-first preparation seam over rendered `%Rendro.Artifact{}` bytes. It supports external artifact preparation, final byte handoff, and adapter-local metadata isolation.

Proof lane: prepare-stage and manifest tests prove prepared-artifact coordinates and metadata boundaries only. This proof lane is separate from viewer behavior, signer execution, and cryptographic validity.

Unsupported narratives: external signer execution, signer identity or trust policy, digital-signature validity, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported. Signature-preparation viewer rows are promoted only when a recorded checklist exists for that exact viewer and prepared-artifact surface.

For viewers other than Adobe Acrobat Reader, `signing_preparation` and `signature_widget` cells are behaviorally indistinguishable — record signature-widget evidence once and inherit the same status, `recorded_at`, `viewer_kind`, and evidence pointer for `signing_preparation`. Adobe Acrobat Reader requires independent `signing_preparation` evidence because byte-range layout after save is viewer-discriminable (`priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md`).

Apple Preview and Chrome PDFium `signing_preparation` rows inherit their `signature_widget` evidence pointers. PDF.js `signing_preparation` is `explicit_deferral` with the same upstream signature-field reason as the signature-widget row.

## Signed Artifact Support Boundary

Supported surface: `Rendro.Sign.sign/2` and `Rendro.render_signed/3` sign a rendered unsigned-signature artifact through an optional external adapter. In this release, the first-party path is `Rendro.Adapters.PyHanko` using the `pyhanko` CLI over PEM or DER key material and an existing Rendro-authored signature field.

Proof lane: signed-artifact proof is split in two. Automated tests cover the artifact-first API and adapter boundary, and Poppler `pdfsig` validates signature presence and cryptographic integrity on produced artifacts. This lane does not prove signer trust, certificate policy, or compliance posture.

Important boundary: `Rendro.Sign.sign/2` operates on the original unsigned rendered artifact, not the placeholder-patched output from `Rendro.Sign.prepare/2`. The preparation seam remains available for lower-level external workflows that need deterministic placeholder coordinates and byte ranges.

Signed output is explicitly non-deterministic.

Unsupported narratives: signer identity or trust, tamper-evidence marketing, compliance narratives, PAdES/LTV/TSA/OCSP/CRL support, and multi-signature workflows remain unsupported. Signed-artifact viewer rows are promoted only when a recorded checklist exists for that exact viewer and signing surface.

Adobe Acrobat Reader and Chrome PDFium are `supported` for `signed_artifact` with evidence at `priv/viewer_evidence/signed_artifact/adobe_acrobat_reader.md` and `priv/viewer_evidence/signed_artifact/chrome_pdfium.md` (pdfsig/pyhanko structural proxies — not Acrobat or browser signature-trust GUI). Apple Preview and PDF.js are `explicit_deferral` because Preview does not validate `/Sig` digital signatures and PDF.js exposes no signed-artifact integrity panel.

## Long-Lived Evidence Support Boundary

Supported surface: take a Rendro-rendered artifact, sign it through `Rendro.Sign.sign/2`, augment it through `Rendro.Sign.augment/2`, and validate timestamp, revocation, and embedded-validation-evidence posture through `Rendro.Sign.validate/2` with `adapter: Rendro.Adapters.PyHanko`. `pdfsig` remains secondary and only confirms signed-artifact integrity after augmentation.

Proof lane: the exact long-lived claim is backed by one opt-in live proof over runtime-generated PDFs plus checked-in non-secret certomancer fixtures that stand up a local TSA and revocation service. Local recipe: `mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs`. CI recipe: the dedicated `long-lived-live-proof` job runs the same tagged command after provisioning pyHanko, certomancer, and pdfsig.

Certificate trust is a separate question from timestamp and revocation evidence posture. Long-lived evidence support does not mean Rendro owns signer identity policy, trust-store management, or viewer trust UX.

Adobe Acrobat Reader is `supported` for `long_lived_signed_artifact` with evidence at `priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md` (pyhanko structural posture on the representative certomancer fixture — not Acrobat LTV panel GUI). Apple Preview, Chrome PDFium, and PDF.js are `explicit_deferral` because those viewers do not surface long-term-validation timestamp, revocation, or expiry indicators for augmented signatures.

Unsupported narratives: signer identity or trust ownership, viewer promotion, LT/LTA profile claims, blanket compliance claims, and multi-signature workflows remain unsupported.

## Embedded Files Support Boundary

Rendro supports document-level embedded files with explicit metadata.

Embedded files live inside the PDF binary and are distinct from delivery, email, or download attachments handled by Rendro adapters outside the PDF. Document-level embedded files carry authored filename, MIME type, description, and authored timestamps; page-level file attachment annotations are not part of the supported surface.

Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove viewer behavior for embedded files or links. Viewer support for discoverability, opening or extracting, and saving or extracting embedded files is tracked separately in `priv/support_matrix.json` and is only named when a recorded checklist exists for that viewer.

## Curated Links Support Boundary

Rendro supports authored links for external `http`/`https` URIs and internal page destinations.

Other URI schemes, named destinations, and broader action dictionaries are not part of the supported link surface. Curated links are authored and deterministic; viewer behavior for external URI handoff and internal page navigation is tracked separately and only named when a recorded checklist exists.

## Embedded Artifact Viewer Posture

Viewer support is tracked per surface and per viewer in `priv/support_matrix.json`, with each `supported` claim backed by a recorded checklist under `priv/viewer_evidence/`. Promotion requires recorded evidence (viewer name, version when easily available, OS, fixture, date checked, and per-behavior pass/fail); a pass for one surface does not imply a pass for another on the same viewer, and no viewer is implicitly supported by structural validity alone.

Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`. The recorded checklist for version **v0.10.3** on **macOS (arm64)** confirms embedded-file structural markers (`priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md`: `discoverable`, `open_or_extract`, `save_or_extract`) and link structural markers (`priv/viewer_evidence/links/adobe_acrobat_reader.md`: `external_uri_handoff`, `internal_page_navigation`) via pdfium-cli automation proxy — not Attachments pane or URI handoff GUI.

Apple Preview is `supported` for `links` and `explicit_deferral` for `embedded_files`. The recorded checklist for version **v0.10.3** on **macOS (arm64)** (`priv/viewer_evidence/links/apple_preview.md`) confirms external URI handoff and internal page navigation structural markers via pdfium-cli automation proxy. Preview embedded-file discoverability is `explicit_deferral` because the Attachments UI still does not discover, open, or extract the representative fixture after Phase 71 re-verify; the surface is not marked `unsupported`, since Rendro continues to author it correctly per the structural proof lane.

Viewers not listed above are outside the recorded support contract for embedded artifact surfaces.

## Protected PDF Support Boundary

Rendro supports password-to-open PDF protection through an external artifact-first boundary.

The canonical API is `Rendro.Protect.password/2`, which wraps an already-rendered `%Rendro.Artifact{}` through a protection adapter such as `Rendro.Adapters.Qpdf`. The core render pipeline remains deterministic; the protected output does not. Protected artifacts therefore set `metadata.deterministic` to `false` and carry read-only `metadata.protection` details describing the algorithm and advisory-permission posture.

Rendro v1.10 supports only `:aes_256` on this public protection surface. AES-128, RC4, and native in-core encryption are not part of the supported contract for this release.

Advisory permissions are an honor-system PDF flag surface, not a cryptographic enforcement mechanism. Use the term `advisory_permissions` deliberately: compliant viewers may honor print/copy/modify-related flags, and non-compliant viewers or command-line tools may ignore them. Rendro does not market advisory permissions as hard security.

Protection is not compliance, not tamper evidence, and not digital signing. Password-to-open encryption does not prove authorship, does not detect document modification, does not satisfy PDF/A archival requirements, and does not provide a signature-grade integrity story.

Delivery and storage seams should transport already-protected artifacts, not password material.

Phase 53 does not introduce a first-party protected worker or orchestration API.

Structural validation through `pdfinfo`/Poppler proves that a protected PDF remains structurally readable when a password is supplied to the validator. If validation succeeds only with `owner_password`, that proves structural decryptability fallback rather than the normative password-to-open path. It does not prove viewer behavior.

Apple Preview is `supported` for the `protection` surface based on the recorded viewer checklist for **pdfinfo version 26.04.0** on **macOS (arm64)** (`priv/viewer_evidence/protection/apple_preview.md`). That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture via pdfinfo/qpdf structural automation proxy (Preview password GUI not re-run in CI).

Adobe Acrobat Reader is `supported` for the `protection` surface based on the recorded viewer checklist for **pdfinfo** on **Ubuntu (amd64)** (`priv/viewer_evidence/protection/adobe_acrobat_reader.md`). That proof confirms the same five-check protection checklist via pdfinfo/qpdf structural automation proxy (Acrobat password GUI not re-run in CI). Other `protection` viewers are outside the recorded contract unless `priv/support_matrix.json` promotes them.

## Explicit Deferral Reasons (matrix-mirrored)

Every `explicit_deferral` viewer row in `priv/support_matrix.json` carries a named `evidence_deferred` reason. These are mirrored verbatim here so the adopter-visible contract states why a viewer is deferred rather than `unsupported`:

- forms × PDF.js: PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during Phase 71 operator review; edit_or_toggle persistence is not reliable.
- signature_widget × PDF.js / signing_preparation × PDF.js: PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support.
- signed_artifact × Apple Preview: Apple Preview does not validate /Sig digital signatures and append-save invalidates signature dictionaries; signed-artifact viewer promotion requires Acrobat or pdfium-cli structural lanes.
- signed_artifact × PDF.js: PDF.js exposes no /Sig validation UI or signed-artifact integrity panel for the representative fixture; viewer promotion deferred until signature validation surfaces exist.
- long_lived_signed_artifact × Apple Preview: Apple Preview does not surface long-term-validation timestamp, revocation, or expiry indicators for augmented PDF signatures on the representative certomancer fixture.
- long_lived_signed_artifact × Chrome PDFium: pdfium-cli structural open and form extraction do not expose long-term-validation timestamp, revocation, or expiry indicators; LTV posture remains Acrobat-only for viewer promotion.
- long_lived_signed_artifact × PDF.js: PDF.js does not implement long-term-validation timestamp, revocation, or expiry indicators for augmented signatures; viewer promotion deferred until LTV UI exists upstream.
- embedded_files × Apple Preview: Apple Preview Attachments UI still does not discover, open, or extract the representative embedded-artifact fixture after Phase 71 re-verify; v1.9 deferral stands.

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

## Interactive Forms Support Boundary

Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders.

Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior.

The `Rendro.signature_field/2` helper is an authored unsigned-placeholder contract only. Phase 55 does not yet claim rendered signature-widget support, viewer support for signature fields, or digital-signature behavior.

Digital signatures, signer metadata, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported.

For text fields, checkboxes, and radio groups, Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist. Adobe Acrobat Reader remains `unverified` until the same checklist records passing open, visible default state, edit/toggle, and save behavior.

Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them.

## Embedded Files Support Boundary

Rendro supports document-level embedded files with explicit metadata.

Embedded files live inside the PDF binary and are distinct from delivery, email, or download attachments handled by Rendro adapters outside the PDF. Document-level embedded files carry authored filename, MIME type, description, and authored timestamps; page-level file attachment annotations are not part of the supported surface.

Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove viewer behavior for embedded files or links. Viewer support for discoverability, opening or extracting, and saving or extracting embedded files is tracked separately in `priv/support_matrix.json` and is only named when a recorded checklist exists for that viewer.

## Curated Links Support Boundary

Rendro supports authored links for external `http`/`https` URIs and internal page destinations.

Other URI schemes, named destinations, and broader action dictionaries are not part of the supported link surface. Curated links are authored and deterministic; viewer behavior for external URI handoff and internal page navigation is tracked separately and only named when a recorded checklist exists.

## Embedded Artifact Viewer Posture

Viewer support is tracked per surface and per viewer in `priv/support_matrix.json`, with each `supported` claim backed by a recorded checklist in the phase validation record. Promotion requires recorded evidence (viewer name, version when easily available, OS, fixture, date checked, and per-behavior pass/fail); a pass for one surface does not imply a pass for another on the same viewer, and no viewer is implicitly supported by structural validity alone.

Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`. The recorded checklist confirms that the embedded file is discoverable in the Attachments pane and that the listed entry can be opened and saved to disk, and that both external `http`/`https` link handoff and internal page navigation work as authored.

Apple Preview is `supported` for `links` and `unverified` for `embedded_files`. The recorded checklist confirms external URI handoff and internal page navigation work in Preview, but Preview did not surface the document-level embedded file in its UI under the version checked. Embedded file discoverability stays `unverified` for Apple Preview until a future checklist records the behavior; the surface is not marked `unsupported`, since Rendro continues to author it correctly per the structural proof lane.

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

Apple Preview is `supported` for the `protection` surface based on the recorded Phase 54 checklist for version 11.0 on macOS 26.4.1. That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture.

Adobe Acrobat Reader remains `unverified` until the same five-check protection checklist is recorded for that viewer. Other `protection` viewers remain `unverified` in `priv/support_matrix.json` until a recorded checklist promotes a named viewer.

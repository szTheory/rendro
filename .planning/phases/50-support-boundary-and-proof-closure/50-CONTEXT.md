# Phase 50: Support-Boundary and Proof Closure - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `v1.9` by publishing one truthful support contract for document-level embedded files and curated links, updating the machine-readable matrix and human docs together, and separating structural proof from viewer-behavior evidence. This phase does not add new PDF surface area. It closes the contract around what Phases 48 and 49 already built.

</domain>

<decisions>
## Implementation Decisions

### Support matrix shape
- **D-01:** Phase 50 should extend the existing **family-first nested support matrix** in `priv/support_matrix.json`, not replace it with a generic `"surfaces"` wrapper or a compatibility-database-style schema.
- **D-02:** The top-level family shape should remain explicit and product-facing: existing `forms`, plus new `embedded_files` and `links`.
- **D-03:** `embedded_files` should separate at least:
  - `capabilities`
  - `behaviors`
  - `viewers`
- **D-04:** `links` should separate at least:
  - `targets`
  - `behaviors`
  - `viewers`
- **D-05:** Avoid per-leaf statement objects unless a leaf genuinely needs richer metadata. Default shape should remain simple `"supported" | "unsupported" | "unverified"` values, with named viewer entries only where a proof checklist exists.

### Viewer-claim posture
- **D-06:** Viewer claims must stay **per surface**, not one blanket `v1.9` viewer status shared across embedded files and links.
- **D-07:** `supported` means a named viewer passed a recorded checklist for that specific surface and behavior set.
- **D-08:** `unverified` is the default posture for authored surfaces that Rendro serializes structurally but has not proven in a named viewer.
- **D-09:** `unsupported` should be reserved for surfaces Rendro does not author or explicitly rejects, not for merely untested viewer behavior.
- **D-10:** Structural validity through `pdfinfo`/Poppler remains valuable but must be documented as a **different proof lane** from viewer interaction, discoverability, extraction, or policy behavior.

### Proof model
- **D-11:** Phase 50 should keep one **merge-blocking automated structural proof lane** and one **separate viewer-evidence lane**, following the Phase 47 pattern rather than inventing a heavier artifact system.
- **D-12:** Structural proof should be the real product contract:
  - deterministic fixtures for embedded files and links
  - writer/validation assertions
  - support-matrix and docs-contract synchronization
- **D-13:** Viewer proof should be the smallest durable manual lane needed to justify named support claims. It should not become a screenshot archive or a broad UX-certification system.
- **D-14:** The minimum recorded manual evidence per viewer check should be:
  - viewer name
  - version if easily available
  - OS
  - fixture name or path
  - date checked
  - pass/fail/unverified per named behavior
  - one short notes field only when behavior is surprising

### Public wording and DX posture
- **D-15:** Use **`embedded files`** as the canonical public term for PDF-internal file payloads. Do not headline them as `attachments`, because Rendro already uses attachment language for delivery adapters outside the PDF binary.
- **D-16:** Use plain **`links`** in public API/docs prose because `Rendro.link/2` is already the explicit authored surface. Reserve `curated` for support-boundary prose and contract wording where scope fencing matters.
- **D-17:** Public docs should explicitly distinguish:
  - embedded files inside the PDF
  - delivery/email/download attachments outside the PDF
  - links limited to external `http`/`https` URIs and internal page destinations
- **D-18:** Docs should prefer one coherent recommendation set over presenting multiple equivalent ways to describe or consume the same feature.

### Process preference for downstream GSD work
- **D-19:** Downstream agents should default to **research-backed, cohesive recommendations** that already balance tradeoffs across Elixir ecosystem norms, adjacent-library lessons, truthful support boundaries, and least-surprise DX.
- **D-20:** Escalate to the user only when a choice materially changes product semantics, widens roadmap scope, or creates a high-impact policy tradeoff the maintainer is likely to care about directly.

### the agent's Discretion
- Exact nested key names under `embedded_files` and `links`, as long as they remain explicit, small, and stable.
- Which public docs surface becomes the canonical artifact-support guide, as long as `guides/api_stability.md`, `priv/support_matrix.json`, and docs-contract tests stay aligned.
- Which named viewers, if any, are promoted from `unverified` to `supported`, provided the checklist evidence is committed and wording matches it exactly.

</decisions>

<specifics>
## Specific Ideas

- Preferred support-matrix direction:
  - `embedded_files.capabilities.document_level`
  - `embedded_files.behaviors.explicit_metadata`
  - `embedded_files.behaviors.authored_timestamps`
  - `embedded_files.behaviors.page_attachment_annotations`
  - `embedded_files.viewers.apple_preview`
  - `embedded_files.viewers.adobe_acrobat_reader`
  - `links.targets.external_uri_http_https`
  - `links.targets.internal_page`
  - `links.behaviors.fragment_rectangles`
  - `links.behaviors.named_destinations`
  - `links.viewers.apple_preview`
  - `links.viewers.adobe_acrobat_reader`
- Preferred wording direction:
  - "Rendro supports document-level embedded files with explicit metadata."
  - "Rendro supports authored links for external `http`/`https` URIs and internal page destinations."
  - "Structural validation proves PDF structure only. Viewer behavior is tracked separately and only named as supported when recorded proof exists."
  - "Embedded files are part of the PDF binary. Delivery attachments in adapters are a separate concern."
- Preferred proof-checklist direction:
  - Embedded files: discoverable, open/extract, save/extract
  - External links: click hands off to browser/system
  - Internal links: click navigates to intended page
  - Do not treat warning-policy behavior as support unless it blocks the basic flow
- Ecosystem lessons to preserve:
  - Follow the Elixir tendency toward explicit, small, versionable contracts rather than meta-schemas.
  - Learn from adjacent PDF libraries that broader action/attachment surfaces create DX footguns and scope confusion.
  - Keep the support artifact readable by humans first; do not turn it into a mini compatibility database.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/REQUIREMENTS.md` — `TRUST-01` and `TRUST-02`.
- `.planning/milestones/v1.9-ROADMAP.md` — Phase 50 boundary and intended closure work.
- `.planning/milestones/v1.9-CONTEXT.md` — milestone-level support-boundary framing.

### Prior support-contract precedent
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-CONTEXT.md` — locked support-matrix and viewer-proof philosophy.
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md` — prior split between structural and viewer proof.
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-03-SUMMARY.md` — example of syncing recorded proof back into the public contract.

### Phase 48 and 49 implementation/proof seams
- `.planning/phases/48-embedded-file-core-surface/48-VALIDATION.md`
- `.planning/phases/48-embedded-file-core-surface/48-VERIFICATION.md`
- `.planning/phases/49-curated-link-annotation-surface/49-CONTEXT.md`
- `.planning/phases/49-curated-link-annotation-surface/49-VALIDATION.md`
- `.planning/phases/49-curated-link-annotation-surface/49-03-SUMMARY.md`

### Live contract surfaces
- `priv/support_matrix.json` — existing machine-readable contract to extend.
- `guides/api_stability.md` — current public support-boundary wording.
- `scripts/verify_docs.exs` — current docs-contract lane entry point.
- `test/docs_contract/forms_claims_test.exs` — precedent for exact wording + matrix lockstep.

### Project methodology
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least surprise DX, and default collapse-to-one-recommendation behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `priv/support_matrix.json`: already uses a family-first nested structure and should be extended rather than replaced.
- `guides/api_stability.md`: already acts as the public support-boundary guide and already distinguishes structural proof from viewer behavior for forms.
- `scripts/verify_docs.exs` plus `test/docs_contract/forms_claims_test.exs`: established pattern for locking wording and matrix shape together.

### Established Patterns
- Rendro prefers small explicit contracts over generic extensibility layers.
- Public claims are expected to be narrower than the universe of legal PDF behavior.
- Machine-readable support data and human docs should move together in the same phase so they cannot drift.

### Integration Points
- Phase 50 will primarily touch support artifacts, docs-contract tests, and proof records rather than the render core.
- Viewer-proof promotion decisions should feed back into both `priv/support_matrix.json` and public wording in the same change set.
- Documentation must preserve the naming distinction between embedded files in PDFs and adapter-delivery attachments outside PDFs.

</code_context>

<deferred>
## Deferred Ideas

- A generic top-level `"surfaces"` wrapper for the support matrix.
- BCD-style per-leaf metadata objects everywhere in the matrix.
- Blanket viewer support claims shared across all `v1.9` artifact surfaces.
- Heavy screenshot/archive workflows for viewer proof.
- Security/compliance claims about attachment safety, sandboxing, or encryption policy behavior.
- Any widening into generic annotations, richer URI schemes, named destinations, or delivery-adapter semantics.

</deferred>

---

*Phase: 50-support-boundary-and-proof-closure*
*Context gathered: 2026-05-06*

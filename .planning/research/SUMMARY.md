# Project Research Summary

**Project:** Rendro
**Domain:** PDF Generation Engine (Table of Contents, Document Outlines, Anchors, and Cross-References)
**Researched:** 2026-06-14
**Confidence:** HIGH

## Executive Summary

Rendro is a deterministic, functional Elixir PDF generation engine. Its non-negotiable architectural constraint requires pure-Elixir logic, void of external browser runtimes or stateful layout multi-pass accumulators. Building long-document navigation capabilities (Table of Contents, document outlines, anchors, cross-references) must preserve the engine's strict single-pass `build -> compose -> measure -> paginate -> validate -> render` pipeline.

The recommended approach relies heavily on stateless post-layout resolution. Anchors are emitted as primitives, accumulating their physical X/Y/Page locations down the pipeline via `doc.metadata.anchors` during `paginate`. Document Outlines (bookmarks) and cross-reference links are serialized purely natively during the `render` phase. ToC page numbers are handled via fixed-width string token substitution (`{{anchor_page:id}}`) post-layout, completely preventing infinite "pagination loops" by guaranteeing layout boundaries never change when numbers are resolved.

The major risks involve multi-pass layout oscillations where ToC size changes cascade endlessly, and doubly-linked PDF dictionary corruption in `/Outlines` which breaks standard viewer behavior. These are mitigated by bounding ToC substitution layout sizes, isolating complex doubly-linked tree serialization logic to the final `render` step, and asserting structural validation with `poppler` in CI.

## Key Findings

### Recommended Stack

Rendro will maintain strict adherence to its "zero external dependencies" constraint for this milestone. Core generation must rely entirely on native Elixir serialization, validating the output via existing CI tools.

**Core technologies:**
- **Elixir (Native):** PDF Object Generation — Outlines, anchors, and cross-references are standard PDF dictionary objects serialized purely via the existing native engine.
- **Poppler (Existing):** Structural Validation — Will validate the structural integrity of the generated `/Outlines` and `/Dests` PDF catalogs in CI.

*Explicitly avoided:* External PDF tooling (Puppeteer, Ghostscript) and stateful multi-pass accumulators are strictly forbidden.

### Expected Features

**Must have (table stakes):**
- **Internal Anchors:** Foundational primitive mapping an `id` to an explicit `[page /XYZ left top zoom]` destination.
- **Document Outlines (Bookmarks):** PDF sidebar navigation. Massive UX win for digital reports that doesn't impact visual page layout.
- **Cross-References:** Internal links pointing to explicit anchors (`/Link` annotations).

**Should have (competitive):**
- **Precise `XYZ` Destination Offsets:** Preserves user zoom and aligns view to the exact top-left of the specific heading block, rather than naively jumping to the page.
- **Declarative Outline Auth:** Harvesting hierarchical outline metadata automatically from the AST during block construction.

**Defer (v2+):**
- **Visual Table of Contents (TOC) Auto-Assembly:** Instead of magic auto-assembly blocks that risk layout oscillation, provide primitives (`{{anchor_page:id}}`) and guide users to build fixed-width TOC tables manually.

### Architecture Approach

The deterministic constraint demands isolating invisible structural navigation from printable, dynamically measured layout content.

**Major components:**
1. **Anchors (`id`):** Validated in `Build`, accumulated during `Paginate` to establish physical X/Y bounds in `doc.metadata.anchors`.
2. **Outlines (`%OutlineItem{}`):** A purely functional tree validated in `Build` and serialized as a doubly-linked dictionary during `Render`.
3. **Cross-References:** Extensions of `%Rendro.Link{}` validated against `doc.metadata.anchors` in `Validate`, emitted as `/Link` annotations during `Render`.
4. **ToC Tokens (`{{anchor_page:id}}`):** Placeholder text measured literally during layout and string-substituted at the tail end of `Paginate` to avoid "chicken-and-egg" measurement loops.

### Critical Pitfalls

1. **The "Layout Shift" Oscillation** — Substituting ToC page numbers changes dimensions, cascading into an infinite loop. Avoid by utilizing fixed-width string substitution *after* all layout is measured in `paginate`.
2. **Doubly-Linked Outline Tree Corruption** — Invalid `/Count`, `/Next`, or `/First` pointers in the Outline dictionary silently crash PDF viewers. Avoid by serializing this complex tree in a single pass purely during the final `render` phase.
3. **Destination Viewport "Drift"** — Jumping to `[page /Fit]` overrides user zoom or cuts off text. Avoid by emitting explicit `[page /XYZ left top null]` destinations mapped exactly from the block's visual bounding box.
4. **Dangling / Unresolved Cross-References** — Broken anchor links corrupt standard validators. Avoid by explicitly checking all targets against the `doc.metadata.anchors` registry during the `validate` phase, crashing deterministically (errors-as-product) before render.
5. **Invisible Bookmark Text** — Non-Latin characters in PDF sidebars fail to render. Avoid by explicitly encoding all outline `/Title` strings as UTF-16BE with a Byte Order Mark (`\xFE\xFF`).

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Location Tracking & Primitives
**Rationale:** Establishing exact X/Y physical locations is the foundational dependency for all downstream destination linking.
**Delivers:** Schema validation for `id` on blocks/sections and accumulation of `doc.metadata.anchors` during `Paginate`.
**Addresses:** Internal Anchors.
**Avoids:** Destination Viewport "Drift" (ensures exact Y-offsets are preserved).

### Phase 2: Document Outlines (PDF Bookmarks)
**Rationale:** Provides immediate, massive UX value for digital viewers without risking any changes to visual layout pipelines.
**Delivers:** `%OutlineItem{}` schema, Declarative Outline Auth, and native doubly-linked serialization in `Render`.
**Addresses:** Document Outlines.
**Avoids:** Doubly-Linked Outline Tree Corruption, Invisible Bookmark Text.

### Phase 3: Cross-References & Validation
**Rationale:** Relies on Phase 1's destination maps to safely weave links into the document body text.
**Delivers:** `{:anchor, id}` target routing in `%Rendro.Link{}`, explicit `Validate` phase structural validation, and `/Link` annotation emission.
**Addresses:** Cross-References, Precise `XYZ` Destination Offsets.
**Avoids:** Dangling / Unresolved Cross-References.

### Phase 4: Printable Table of Contents Primitive
**Rationale:** Touches the most dangerous aspect of the system (document layout loops) and is safely deferred until the structural base is proven.
**Delivers:** Post-layout `{{anchor_page:id}}` token substitution logic in `Paginate`, and documentation defining the table-based layout pattern.
**Addresses:** Bounded TOC generation primitive.
**Avoids:** The "Layout Shift" Oscillation.

### Phase Ordering Rationale

- **Dependency-Driven:** You cannot link to something until you know where it is (Phase 1).
- **Risk Mitigation:** Phase 2 introduces high business value with near-zero layout risk. Phase 4 holds the highest architectural risk and is isolated to the end of the milestone.
- **Determinism Safety:** By pushing validation to Phase 3, we ensure the pipeline guarantees error-free output before attempting complex in-document text replacements.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** The exact structure of PDF doubly-linked outlines (PDF 32000-1 specification) requires careful, precise dictionary object ID mapping logic in Elixir.
- **Phase 4:** Deep analysis on how token string length interacts with the engine's existing line-wrapping logic to completely eliminate text re-measurement risks.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Standard Elixir accumulation (via `reduce` or `map` traversals) over the AST.
- **Phase 3:** Existing link validation logic is well-understood from previous milestones.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Enforced "zero new dependency" constraint aggressively limits unknowns. |
| Features | HIGH | Clear boundary established between standard digital capabilities and complex layout problems (ToC). |
| Architecture | HIGH | Extending the single-pass pipeline deterministically fits naturally into existing patterns (e.g., v2.4 page-number substitution). |
| Pitfalls | HIGH | Historical layout engine bugs (e.g., ReportLab multiBuild loops) and PDF dictionary structure are well documented. |

**Overall confidence:** HIGH

### Gaps to Address

- **Visual TOC Auto-Assembly UX:** Since auto-assembly is deferred to protect engine performance, the exact developer ergonomics for *manually* constructing TOC tables require careful documentation and validation with end-users.

## Sources

### Primary (HIGH confidence)
- **.planning/PROJECT.md** — Architectural constraints.
- **PDF Specification (ISO 32000-1)** — Outline Dictionaries, explicit destinations, and UTF-16BE text string requirements.
- **Rendro v2.4 & v2.7** — Post-layout page-number substitution patterns.
- **Rendro v1.9** — Embedded links architecture and validation.

### Secondary (MEDIUM confidence)
- **ReportLab Documentation** — `PLATYPUS` multi-pass layout algorithm oscillations.
- **Prawn (Ruby) Issues** — State-tracking patterns for TOC generation.

---
*Research completed: 2026-06-14*
*Ready for roadmap: yes*
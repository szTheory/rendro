# ROADMAP

## Phases

- [ ] **Phase 97: Location Tracking & Primitives** - Establish exact X/Y physical locations and bounds as a foundational engine primitive.
- [ ] **Phase 98: Document Outlines (Bookmarks)** - Introduce native, declarative doubly-linked PDF outline serialization.
- [ ] **Phase 99: Cross-References & Validation** - Add validated internal document links that point to explicit physical destinations.
- [ ] **Phase 100: Printable Table of Contents Primitive** - Provide safe post-layout substitution tokens for visual Tables of Contents.

## Phase Details

### Phase 97: Location Tracking & Primitives
**Goal**: The engine reliably captures explicit physical locations of content blocks for downstream referencing without altering layout.
**Depends on**: Nothing
**Requirements**: ANC-01, ANC-02, ANC-03
**Success Criteria**:
  1. Developer can successfully build a document containing blocks with explicit `id` attributes.
  2. Developer receives a clear crash with descriptive error when providing duplicate block `id`s.
  3. The engine's post-pagination metadata correctly exposes an exact mapping of `id`s to physical page, X, and Y coordinates that are zoom-agnostic (`[page /XYZ left top null]`).
**Plans**: 2 plans
- [ ] 97-01-PLAN.md — Primitives & Validation
- [ ] 97-02-PLAN.md — Accumulation & Fragments

### Phase 98: Document Outlines (Bookmarks)
**Goal**: Viewers can navigate hierarchical document outlines using standard PDF sidebars with support for non-Latin characters.
**Depends on**: Phase 97
**Requirements**: OUT-01, OUT-02, OUT-03, OUT-04
**Success Criteria**:
  1. Developer can generate a PDF with a functional native outline sidebar simply by assigning `outline: true` to headings.
  2. Outline strings correctly display non-Latin UTF-16BE characters in standard viewers like Apple Preview or Acrobat.
  3. Poppler structural validation passes confirming the doubly-linked outline tree dictionary structure is valid.
**Plans**: 2 plans
- [ ] 97-01-PLAN.md — Primitives & Validation
- [ ] 97-02-PLAN.md — Accumulation & Fragments

### Phase 99: Cross-References & Validation
**Goal**: Users can click internal links in the document body to jump to specific sections with exact viewport alignment.
**Depends on**: Phase 97
**Requirements**: XREF-01, XREF-02, XREF-03
**Success Criteria**:
  1. User can click a rendered link in the PDF and jump to the exact top-left position of the targeted section without zooming out.
  2. Developer receives a fail-fast structured error during generation if they link to an `id` that does not exist in the document.
**Plans**: 2 plans
- [ ] 97-01-PLAN.md — Primitives & Validation
- [ ] 97-02-PLAN.md — Accumulation & Fragments

### Phase 100: Printable Table of Contents Primitive
**Goal**: Developers can render accurate visual Tables of Contents without risking infinite layout-measurement loops.
**Depends on**: Phase 97
**Requirements**: TOC-01, TOC-02, TOC-03
**Success Criteria**:
  1. Developer can use `{{anchor_page:id}}` tokens inside standard text blocks to print the exact page number of any section.
  2. Generated page numbers maintain correct alignment without causing text to re-wrap or shift lines.
  3. Multi-page document generation remains strictly single-pass and deterministic with zero performance degradation from layout loops.
**Plans**: 2 plans
- [ ] 97-01-PLAN.md — Primitives & Validation
- [ ] 97-02-PLAN.md — Accumulation & Fragments

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 97. Location Tracking & Primitives | 0/2 | Not started | - |
| 98. Document Outlines (Bookmarks) | 0/0 | Not started | - |
| 99. Cross-References & Validation | 0/0 | Not started | - |
| 100. Printable Table of Contents Primitive | 0/0 | Not started | - |

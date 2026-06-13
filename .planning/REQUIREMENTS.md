# Requirements: Rendro v2.7

**Milestone:** v2.7 Page Context & Browser Proof Hardening
**Defined:** 2026-06-13
**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Active Requirements

### Page Context Primitive

- [x] **CTX-01**: A document author can mark a body section as a section-local page-numbering boundary with `page_numbering: [restart: true]`, and rendering starts that section on a new physical page without changing existing non-numbered sections.
- [x] **CTX-02**: A document author can use `{{section_page_number}}` and `{{section_total_pages}}` in running header/footer text and get deterministic decimal section-local numbering.
- [x] **CTX-03**: Existing `{{page_number}}` / `{{total_pages}}`, `suppress_on`, and `RunningContent` `{page, total}` callback behavior remain backward-compatible.

### Duplex Running Content

- [ ] **DUP-01**: A document author can attach running header/footer sections with `only_on: :odd` or `only_on: :even`, evaluated against physical page parity.
- [ ] **DUP-02**: Duplex running content composes with section-local numbering so report/booklet-style documents can render different left/right page footers without a second render pass.
- [ ] **DUP-03**: Invalid `only_on` / `page_numbering` options fail with instructive errors before rendering produces misleading output.

### Browser Advisory Proof

- [ ] **PDFJS-01**: Maintainers can run a pinned PDF.js advisory observer that records renderer version, Node version, page count, page dimensions, warnings, and optional first-page PNG hash for committed fixtures.
- [ ] **PDFJS-02**: The PDF.js observer runs only in graph-disconnected advisory CI and cannot block required engine lanes or promote GUI-viewer claims.
- [ ] **PDFJS-03**: Support matrix and docs-contract checks keep PDF.js wording narrow and preserve existing PDF.js deferrals for forms, signatures, and long-lived signatures unless exact proof rows pass.

### Documentation and Release Hygiene

- [ ] **DOC-01**: Guides explain page context, section-local numbering, and duplex running content with code examples, rendered-proof references, and explicit unsupported TOC/outline/chart/text-shaping boundaries.
- [ ] **DOC-02**: Release/HexDocs workflow hardening prevents unreleased public docs from silently overclaiming the current Hex package and pins/minimizes CI permissions where practical.
- [ ] **DOC-03**: Public roadmap and `ADOPTION.md` language keeps global text shaping demand-gated rather than reusing the v2.7 label for a false shaping promise.

## Traceability

| Requirement | Planned Phase | Evidence Target |
|-------------|---------------|-----------------|
| CTX-01 | 89 Page Context Primitive | Pipeline tests proving section restart begins on a new physical page |
| CTX-02 | 89 Page Context Primitive | PAGE-token substitution tests for section page number and total |
| CTX-03 | 89 Page Context Primitive | Backward-compat tests for existing page tokens, `suppress_on`, and callback shape |
| DUP-01 | 90 Duplex Running Content | Header/footer tests for physical odd/even selection |
| DUP-02 | 90 Duplex Running Content | Combined duplex + section numbering fixture |
| DUP-03 | 90 Duplex Running Content | Validation tests for invalid options |
| PDFJS-01 | 91 PDF.js Advisory Proof Lane | Mix task/script output fixture with pinned version metadata |
| PDFJS-02 | 91 PDF.js Advisory Proof Lane | CI and guardrail tests showing advisory graph isolation |
| PDFJS-03 | 91 PDF.js Advisory Proof Lane | Support-matrix/docs-contract assertions for narrow wording |
| DOC-01 | 92 Docs, Claims, Release Hygiene | HexDocs guide and docs-contract coverage |
| DOC-02 | 92 Docs, Claims, Release Hygiene | Workflow and release-doc checks |
| DOC-03 | 92 Docs, Claims, Release Hygiene | `ADOPTION.md`, roadmap, and public docs contract checks |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Global text shaping and broad script support | Multi-quarter capability; remains gated by `ADOPTION.md` demand signals from v2.6. |
| Public `Rendro.PageContext` struct or callback API | Internal context is enough for tokens and duplex; public API should wait for TOC/anchor/cross-reference pressure. |
| Full visual TOC, PDF outlines, anchors, and cross-references | Needs a broader anchor registry and support story; use v2.7 page context as a prerequisite, not the whole feature. |
| Charts | Still a separate authoring and deterministic-rendering surface; no demand signal strong enough for v2.7. |
| PDF.js GUI support claims | PDF.js observations are advisory automation, not Adobe/Preview/mobile GUI evidence. |
| Release-please or full release automation | Adds credential and workflow complexity before manual/tag-gated release becomes painful. |

## Success Criteria

- All 12 active requirements have direct code, test, docs, or workflow evidence.
- Required deterministic CI lanes remain required and unchanged in responsibility.
- New PDF.js work is advisory-only and impossible to mistake for core runtime support.
- Public docs use "pinned PDF.js advisory observations" or equivalent narrow wording, never "PDF.js support" without a support-matrix row.
- The conditional global text-shaping gate remains visible and not silently converted into v2.7 scope.

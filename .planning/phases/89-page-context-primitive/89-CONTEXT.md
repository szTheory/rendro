# Phase 89: Page Context Primitive - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning
**Source:** v2.7 approved milestone plan and code inspection

<domain>
## Phase Boundary

Phase 89 extends the shipped PAGE primitive with section-local page numbering. It does not implement duplex odd/even running content, PDF.js observations, docs guide closure, TOC/outlines/anchors/cross-references, charts, or global text shaping.

</domain>

<decisions>
## Implementation Decisions

### Public API
- D-89-01: Add `page_numbering` to `%Rendro.Section{}` and accept `Rendro.section(page_numbering: [restart: true])`.
- D-89-02: Do not expose a public `Rendro.PageContext` struct in v2.7.
- D-89-03: Add `{{section_page_number}}` and `{{section_total_pages}}` to the existing `Rendro.page_number/1` token path.

### Pagination Semantics
- D-89-04: A restarting body section begins on a new physical page unless the current page is already empty.
- D-89-05: Section totals are decimal-only and derived from physical page ranges after pagination.
- D-89-06: If no restart is active for a page, section tokens fall back to whole-document numbering, so the whole document behaves like one implicit section.

### Backward Compatibility
- D-89-07: Existing `{{page_number}}`, `{{total_pages}}`, `suppress_on`, and `RunningContent` `{page, total}` behavior must not change.
- D-89-08: Do not add hidden metadata fields to `%Rendro.Block{}`. Use normalized layout entries to preserve section metadata through pagination.

### the agent's Discretion
- The exact internal page-context map shape.
- Whether validation for malformed `page_numbering` lives in Compose or a dedicated validation rule, provided failures are clear and tests cover the behavior.

</decisions>

<canonical_refs>
## Canonical References

### Planning
- `.planning/REQUIREMENTS.md` — CTX-01, CTX-02, CTX-03 definitions.
- `.planning/ROADMAP.md` — Phase 89 deliverables and exit criteria.
- `.planning/research/ARCHITECTURE.md` — internal page context and token-substitution architecture.
- `.planning/research/PITFALLS.md` — token substitution and restart pitfalls.

### Code
- `lib/rendro/section.ex` — stable section struct and type.
- `lib/rendro.ex` — `Rendro.section/1` and `Rendro.page_number/1` builders.
- `lib/rendro/pipeline/compose.ex` — normalized `layout.entries` and section metadata entry point.
- `lib/rendro/pipeline/paginate.ex` — pagination, running-content evaluation, token replacement, and page-template application.
- `test/rendro/pipeline/paginate_test.exs` — PAGE primitive regression tests.
- `test/rendro_builders_test.exs` — public builder struct tests.

</canonical_refs>

<specifics>
## Specific Ideas

- Preserve section metadata by adding `page_numbering` to normalized body entries in `Compose.normalize_section/2`.
- Paginate by body entries when `layout.entries` exists rather than only by flattened `layout.region_blocks.body`.
- Compute restart starts during pagination, then derive per-page context before `apply_page_template/4`.
- Extend `replace_page_numbers/3` into a context-aware helper that still intentionally does not re-measure measured text runs.
- Keep Phase 89 tests at the document/page block level rather than byte-level PDF assertions where possible.

</specifics>

<deferred>
## Deferred Ideas

- Duplex `only_on` physical odd/even filtering — Phase 90.
- PDF.js advisory observations — Phase 91.
- Guides/support matrix/release hygiene — Phase 92.
- Public `Rendro.PageContext` API, TOC/outlines/anchors/cross-references, charts, and global text shaping — out of scope for v2.7 Phase 89.

</deferred>

---

*Phase: 89-page-context-primitive*
*Context gathered: 2026-06-13 from approved milestone plan*

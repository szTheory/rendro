# Research Summary — v2.7 Page Context & Browser Proof Hardening

**Milestone:** v2.7 Page Context & Browser Proof Hardening
**Researched:** 2026-06-13
**Inputs:** v2.6 archived research, project prompts/brand/vision, PDF-library prior art, browser-renderer proof patterns, and Elixir/Phoenix ecosystem release norms.

## Executive Summary

Global text shaping should not consume v2.7 yet. The `ADOPTION.md` demand gate exists precisely because proper shaping is expensive, deep, and user-visible when wrong. The better near-term milestone is to harden the report/page-context layer that already has a shipped foundation in the PAGE primitive.

The coherent v2.7 path is:

1. Add internal page context and section-local page numbering.
2. Add physical odd/even running content for duplex reports/booklets.
3. Add a pinned PDF.js advisory observation lane without promoting support claims.
4. Close docs, support boundaries, and release hygiene so public wording remains exact.

This gives Phoenix teams immediately useful reporting ergonomics, preserves the deterministic single-engine architecture, and keeps proof culture intact.

## Key Recommendations

| Topic | Recommendation | Rationale |
|-------|----------------|-----------|
| Page context API | Extend `Rendro.section/1` with `page_numbering: [restart: true]`; do not expose `Rendro.PageContext` yet | Authors need stable behavior, not another public abstraction. Internal context can evolve when TOC/anchors/cross-refs are designed. |
| Tokens | Add `{{section_page_number}}` and `{{section_total_pages}}` to the existing `Rendro.page_number/1` token path | Least surprise: extends the primitive authors already use. Avoids callbacks, mutable accumulators, or arbitrary template engines. |
| Section restart | Restarting sections begin on a new physical page | Matches print/report expectations and avoids ambiguous partial-page section totals. |
| Duplex headers/footers | Add `only_on: :odd | :even` and evaluate physical page parity | Duplex means left/right physical pages. Section-local parity would surprise print workflows. |
| RunningContent callback | Keep `{page, total}` unchanged | Backward compatibility and stable public API matter more than exposing internal context in v2.7. |
| PDF.js lane | Add pinned advisory observations only | Browser-family signal is useful, but "PDF.js support" is too strong without support-matrix proof. Node/npm stays out of core. |
| TOC/charts/shaping | Explicitly defer | Each is a separate feature family with its own support and proof burden. |

## Prior-Art Lessons

- ReportLab, Prawn, fpdf2, and iText all show that page-numbering and running-content primitives are table-stakes for serious business PDFs. The successful pattern is declarative author intent plus deterministic layout resolution, not author-owned counters.
- TOCs and cross-references are where PDF engines often fall into multi-pass/fixpoint complexity. Rendro should not introduce that machinery in v2.7; page context is a prerequisite, not the whole TOC feature.
- PDF.js is useful as a renderer-family observation lane, but project history already separates raster/proxy evidence from GUI-viewer support. v2.7 should keep that distinction sharp.
- In Elixir libraries, optional integrations and graph-disconnected advisory CI are idiomatic. Core packages should not gain hard Node/browser/toolchain dependencies for proof lanes.

## Phase Structure

1. **Phase 89 — Page Context Primitive:** internal context, restart sections, section-local PAGE tokens, backwards-compatible behavior.
2. **Phase 90 — Duplex Running Content:** physical odd/even `only_on`, composition with section numbering, validation errors.
3. **Phase 91 — PDF.js Advisory Proof Lane:** pinned observation tool, fixtures, advisory CI, docs/support guardrails.
4. **Phase 92 — Docs, Claims, Release Hygiene:** guides, support rows, docs-contract checks, release wording, demand-gated shaping language.

## Coherence

Phase 89 creates the internal state needed by Phase 90. Phase 90 turns that state into real report/booklet ergonomics. Phase 91 broadens proof visibility while preserving advisory boundaries. Phase 92 makes the public contract match exactly what was built and what remains deferred.

The milestone improves user-facing value without changing Rendro's identity: pure core, deterministic pipeline, optional adapters, and claims backed by proof.

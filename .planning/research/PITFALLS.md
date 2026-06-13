# Pitfalls Research — v2.7 Page Context & Browser Proof Hardening

**Researched:** 2026-06-13
**Confidence:** HIGH

## Page Context Pitfalls

1. **Exposing public context too early.** A `Rendro.PageContext` public struct would freeze decisions before TOC/anchors/cross-references are designed. Keep context internal in v2.7.
2. **Section restarts without physical page boundaries.** Restarting numbering mid-page makes section totals ambiguous and visually surprising. Require a new physical page.
3. **Substituting tokens in arbitrary text.** The existing PAGE primitive is intentionally curated. Expanding substitution globally would create width/reflow problems and violate the no-remeasure contract.
4. **Locale formatting creep.** Section totals should be decimal-only. Locale-specific numbering and labels belong to caller-authored text or future formatting hooks.
5. **Backward-compat regression.** Existing `{{page_number}}`, `{{total_pages}}`, `suppress_on`, and callback behavior must remain unchanged.

## Duplex Pitfalls

6. **Using section-local parity.** Odd/even in print means physical page parity. Section-local parity breaks left/right booklet expectations after restarts.
7. **Single region map flattening.** Existing running-region code may flatten sections by region; duplex requires preserving section-level filters until page application.
8. **Ambiguous predicate composition.** If `only_on` and `suppress_on` both exist, behavior must be simple and test-backed: render only when the page matches `only_on` and is not suppressed.
9. **Silent invalid options.** Unknown `only_on` atoms or malformed `page_numbering` values should fail with instructive errors before rendering.

## PDF.js Pitfalls

10. **Required-lane contamination.** Node/npm download or install failures must not block required engine CI.
11. **Overclaiming support.** "PDF.js advisory observations" is acceptable. "PDF.js support" is not, unless support-matrix rows and evidence explicitly prove it.
12. **Unpinned renderer drift.** PDF.js version bumps can change warnings and raster output. Treat bumps as explicit evidence re-recording events.
13. **Fixture bloat.** Keep fixtures small and representative. The lane exists to catch broad drift, not to build a browser-rendering test suite.

## Scope Pitfalls

14. **TOC scope creep.** TOC, outlines, anchors, and cross-references are a real milestone, not a Phase 89 add-on.
15. **Chart temptation.** Charts should wait until there is demand and a deterministic Path+Text design. SVG import remains a known trap.
16. **Shaping label drift.** Do not call this milestone global text shaping. The demand gate remains binding.

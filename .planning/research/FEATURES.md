# Feature Research — v2.7 Page Context & Browser Proof Hardening

**Researched:** 2026-06-13
**Confidence:** HIGH for page context and duplex running content; MEDIUM for PDF.js lane shape until exact tool scripts land.

## In-Scope Feature Decisions

### 1. Section-Local Page Numbering

**Problem:** Long reports often need "Page 1 of N" per statement, appendix, certificate batch, or logical section while still preserving physical page numbering for the whole PDF.

**Recommended API:**

```elixir
Rendro.section(:body,
  page_numbering: [restart: true],
  blocks: [...]
)

Rendro.page_number("Page {{section_page_number}} of {{section_total_pages}}")
```

**Why this shape:**
- Reuses the existing section and PAGE primitive.
- Keeps page context internal and deterministic.
- Avoids a public callback or mutable author-owned accumulator.
- Mirrors the least-surprising "restart numbering at section" concept from document tools.

**Tradeoffs:**
- Restarting sections must begin on a new physical page. This is a constraint, but it makes section totals unambiguous and stable.
- Section totals are decimal-only in v2.7. Locale/formatting belongs to future formatting hooks, not the PAGE primitive.

### 2. Duplex Running Content

**Problem:** Printed/booklet-style documents need different left/right headers or footers: inner/outer margins, page number alignment, or section title placement.

**Recommended API:**

```elixir
Rendro.section(:footer,
  only_on: :odd,
  blocks: [Rendro.page_number("{{page_number}}")]
)

Rendro.section(:footer,
  only_on: :even,
  blocks: [Rendro.page_number("{{page_number}}")]
)
```

**Why physical parity:**
- Odd/even is a print convention over physical pages.
- Section-local parity would produce surprising left/right flips after restarts.

**Interaction with `suppress_on`:**
- Preserve existing `suppress_on` semantics.
- Apply both predicates when both are present.

### 3. PDF.js Advisory Observations

**Problem:** PDF.js is a common browser-family renderer. Maintainers benefit from observing whether fixtures still load and how many warnings the renderer emits.

**Recommended shape:**
- Tooling-only script or mix task, pinned by lockfile.
- Records renderer version, Node version, page count, dimensions, warnings, and optional first-page PNG hash.
- Runs in graph-disconnected advisory CI.
- Adds docs-contract checks for narrow wording.

**Non-goals:**
- No Node/npm dependency in core runtime or Hex deps.
- No required-CI contamination.
- No public "PDF.js support" claim unless a future support row and evidence contract explicitly say so.

## Deferred Feature Families

| Feature | Defer Reason |
|---------|--------------|
| Global text shaping | Requires shaping, bidi, cluster-aware line breaking, font proof, and script support matrix; demand gate has not triggered. |
| TOC/outlines/anchors/cross-refs | Needs an anchor registry and careful no-fixpoint design; page context is only the prerequisite. |
| Charts | Must be a deterministic authored surface lowered to Path+Text; not enough demand for this milestone. |
| Release-please/full automation | Elixir ecosystem norms favor manual/tag-gated releases; credentials and workflow risk exceed current value. |

## Developer Ergonomics

- Keep examples short and literal.
- Fail option-shape mistakes at validation time with actionable messages.
- Preserve existing working documents byte-for-byte unless authors opt into new section options.
- Keep the public API additive and in the modules users already know.

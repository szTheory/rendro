# Feature Landscape

**Domain:** PDF Generation Engine (Table of Contents, document outlines, anchors, and cross-references)
**Researched:** 2026-06-14

## Table Stakes

Features users expect. Missing = product feels incomplete for long-report generation.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Internal Anchors** | Foundational primitive for all navigation. Ability to tag a block with an ID and generate a PDF explicit destination. | Low | Rendro's `paginate` stage already calculates exact X/Y and page numbers. |
| **Document Outlines (Bookmarks)** | Required for navigating long reports in the viewer sidebar. Must support hierarchical nesting. | Medium | Requires translating an authored hierarchy into the PDF Catalog's `/Outlines` dictionary with doubly-linked tree nodes (`/Next`, `/Prev`, etc.). |
| **Cross-References** | Ability to click internal text to jump to another section (e.g., "See Figure 2"). | Low/Med | Emits `/Link` annotations pointing to explicit `/Dest` arrays. Rendro already supports URL links (v1.9), just needs internal target support. |
| **Visual Table of Contents (TOC)** | Printed/Visual page listing titles, leader dots (`......`), and page numbers. | High | Requires resolving page numbers for TOC entries. If the TOC grows, it shifts downstream page numbers, creating the classic "pagination loop" risk. |

## Differentiators

Features that set product apart in a functional/Elixir ecosystem. Not expected, but valued over traditional imperative libraries.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Precise `XYZ` Destination Offsets** | Most tools just jump to the page. Precise anchors align the viewer exactly at the top-left of the specific heading block (`[page /XYZ left top zoom]`). | Low | Massive UX improvement for document readers. |
| **Declarative Outline Auth** | Instead of mutating a global outline object imperatively (like Prawn), metadata is declared inline on content blocks and harvested automatically. | Medium | Fits Rendro's functional, declarative AST and component model. |
| **Deterministic TOC Layout** | Solving the multi-pass pagination loop predictably. Instead of infinite retry loops, using a bounded 2-pass cycle or pre-allocated TOC capacity. | High | Protects the core guarantee of deterministic, predictable performance. |

## Anti-Features

Features to explicitly NOT build to protect the engine's core philosophy.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Indeterminate Multi-Pass Layout Loops** | Re-laying out the document infinitely until page numbers settle (like ReportLab's `multiBuild`) can cause infinite oscillations. Breaks predictable performance. | Use a bounded 2-pass layout, detect oscillation and fail instructively, or require explicit TOC page capacity limits. |
| **Stateful Accumulators in Core API** | Forcing developers to pass an `outline_state` tracker through their templates breaks functional ergonomics. | Harvest Outline/Anchor metadata declaratively from the AST during the `build -> compose` pipeline. |
| **Implicit/Scraped Bookmarks** | Magically converting all bold text or `<H1>` tags into PDF Bookmarks surprises users and creates messy sidebars. | Require explicit `bookmark: "Title"` or `%Rendro.Anchor{}` opt-ins. |
| **External PDF Tooling for Metadata** | Generating the PDF and shelling out to `qpdf` or `Ghostscript` to append outlines breaks the "pure Elixir core" deployment constraint. | Generate the `/Outlines` dictionary natively during the `render` phase. |

## Feature Dependencies

```
Internal Anchors → Document Outlines (Bookmarks)
Internal Anchors → Cross-References (Internal Links)
Internal Anchors → Visual Table of Contents (TOC)
Visual Table of Contents → Multi-pass / Pagination Shift Resolution Algorithm
```

## MVP Recommendation

**Prioritize:**
1. **Internal Anchors**: The foundational primitive yielding exact `[page /XYZ left top zoom]` coordinates.
2. **Document Outlines (Bookmarks)**: Massive UX win for digital long reports. Relies only on the internal PDF catalog without requiring visual text layout changes.
3. **Cross-References**: Simple `/Link` annotations pointing to Anchors.
4. **Declarative Outline Auth (Differentiator)**: Harvest outlines directly from block metadata.

**Defer:**
- **Visual Table of Contents (TOC)**: Defer the visual TOC primitive until the multi-pass pagination problem is solved deterministically. Outlines (bookmarks) solve the immediate digital navigation need for long reports without introducing the infinite-oscillation layout complexity. If required, limit to a fixed-size TOC allocation in V1.

## Sources

- PDF Specification (ISO 32000-1): Outline Dictionaries and Explicit Destinations.
- ReportLab Documentation: `PLATYPUS` multi-pass layout algorithm (`multiBuild`) and TOC generation logic.
- Prawn (Ruby) Issues/Docs: State-tracking patterns for TOC generation.
- Typst Architecture: Declarative query systems for resolving cross-reference page numbers (`#locate`).
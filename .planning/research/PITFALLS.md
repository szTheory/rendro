# Pitfalls Research: PDF Table of Contents & Navigation

**Domain:** Deterministic PDF Generation / Document Navigation
**Researched:** 2026-06-14
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: The "Layout Shift" Oscillation (Infinite Loop)

**What goes wrong:**
Adding an inline Table of Contents (TOC) changes the page numbers. If the TOC spans multiple pages, it pushes the body content down. This changes the page numbers of the content, which might change the text size of the TOC (e.g., page 9 goes to page 10, adding a digit or an extra line), changing the layout again, ad infinitum.

**Why it happens:**
TOC generation is a classic "chicken and egg" layout problem. Page numbers aren't known until the `paginate` phase, but `paginate` needs measured block dimensions from the `measure` phase. If replacing a TOC placeholder with real page numbers changes the block dimensions, the pagination becomes invalid.

**How to avoid:**
In a deterministic, single-pass pipeline like Rendro:
1. **Strictly bounded substitution:** If TOC is substituted like `{{page_number}}`, it must not alter block heights during render.
2. **Dedicated Pages / Deferred Assembly:** Often, TOCs are generated as a completely separate document pass (since all page numbers are known *after* the body is paginated), then prepended to the final PDF.
3. **Explicit Multi-Pass:** Run `compose -> measure -> paginate` to collect accurate anchor pages. Then, regenerate the TOC tree, and run `measure -> paginate` a second time to stabilize layout, asserting convergence.

**Warning signs:**
- Test suites hanging due to infinite loops during pagination.
- Text clipping or missing lines in the TOC because the reserved block height was smaller than the final substituted height.

**Phase to address:**
Phase: TOC Primitive Definition & Layout Integration.

---

### Pitfall 2: Doubly-Linked Outline Tree Corruption

**What goes wrong:**
The PDF Outline (Bookmarks) sidebar fails to load, crashes the viewer, or hides children.

**Why it happens:**
The PDF spec does not use a simple array for outlines. It uses a complex doubly-linked list where every node must specify its `/Parent`, `/First` child, `/Last` child, `/Prev` sibling, `/Next` sibling, and a very specific `/Count` metric. 
- A **positive** `/Count` means the item is expanded and shows $n$ visible descendants.
- A **negative** `/Count` means the item is collapsed but contains $n$ descendants.
If any pointer is circular or `/Count` is wrong, viewers (especially Adobe) fail silently or violently.

**How to avoid:**
Never attempt to calculate these pointers during the `compose` or `paginate` phases. Maintain a clean, pure-Elixir Tree struct (`Rendro.Outline`). Only during the final `render` (serialization) phase should the tree be flattened, object IDs allocated in a single pass, and the `Next/Prev/First/Last/Count` relationships resolved deterministically.

**Warning signs:**
- Bookmarks work in macOS Preview (which is forgiving) but fail in Adobe Acrobat Reader or PDF.js.
- Missing expand/collapse (+/-) icons next to bookmark parents.

**Phase to address:**
Phase: PDF Outline (Bookmarks) Serialization.

---

### Pitfall 3: Destination Viewport "Drift" (The Y-Offset Bug)

**What goes wrong:**
When a user clicks a TOC link or cross-reference, the viewer navigates to the correct page, but the target header is either glued exactly to the top pixel of the screen (ignoring page margins) or cut off entirely.

**Why it happens:**
Libraries often emit naive destinations: `[page_id /Fit]` (which forces the page to fit the window, ruining the user's zoom) or `[page_id /XYZ 0 0 null]` (which points to the mathematical top-left of the page).

**How to avoid:**
Use `[page_id /XYZ left top null]`. The `top` coordinate must be extracted from the target block's actual bounding box calculated during the `measure` and `paginate` phases. It must represent the visual start of the element *including* its top margin/padding.

**Warning signs:**
- Clicking a link to "Chapter 2" makes the "Chapter 2" header invisible under the viewer's top UI bar.

**Phase to address:**
Phase: Internal Anchors & Destination Pipeline.

---

### Pitfall 4: Dangling / Unresolved Cross-References

**What goes wrong:**
A generated TOC or internal link clicks, but nothing happens. In some strict viewers or validation tools, the PDF raises a structural error.

**Why it happens:**
A component authored a link to an anchor ID (e.g., `#chapter-2`), but conditional rendering logic, pagination breaking, or an authored mistake caused the target anchor to never be emitted into the paginated output.

**How to avoid:**
The `paginate` phase must output a definitive, unified registry of all *actually emitted* anchor coordinates. The `render` phase must validate every emitted cross-reference (`/GoTo` action) against this registry. If a link points to a non-existent anchor, the engine must raise a deterministic `ArgumentError` (errors-as-product), rather than emitting a broken PDF link.

**Warning signs:**
- Silent PDF generation successes that result in broken UX.
- Validation warnings in the `poppler` CI lane.

**Phase to address:**
Phase: Internal Anchors & Destination Pipeline.

---

### Pitfall 5: Invisible Bookmark Text (Encoding)

**What goes wrong:**
Bookmark titles appear as empty strings, garbage characters (`ï»¿`), or strange glyphs in the sidebar.

**Why it happens:**
Passing raw UTF-8 strings directly into the PDF Outline `/Title` string literal. While PDF 2.0 supports UTF-8, most viewers in the wild expect `PDFDocEncoding` or UTF-16BE.

**How to avoid:**
All outline `/Title` strings must be explicitly encoded as UTF-16BE with a Byte Order Mark (`\xFE\xFF`), leveraging the same text serialization utilities Rendro already uses for metadata and form fields.

**Warning signs:**
- Emojis, accented characters, or non-Latin scripts break the outline sidebar.

**Phase to address:**
Phase: PDF Outline (Bookmarks) Serialization.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `/Fit` instead of `/XYZ` | Skips coordinate calculation | Ruins user's preferred zoom level on every click | Never acceptable in production |
| Skipping anchor validation | Faster implementation | Emits broken PDFs that silently fail in production | Never acceptable |
| 0-based page dests | Easier mapping from Elixir arrays | Broken bookmarks when pages are prepended/removed | Only if page mapping is immutable |
| Direct Object Refs for links | Avoids named destination tree (`/Names`/`/Dests`) | Harder to debug raw PDF output | Acceptable (and preferred for determinism) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Global Anchor Tracking | High memory usage during `paginate` | Only track explicit `%Rendro.Anchor{}` elements, not every text block | Reports > 500 pages |
| N-Pass Layout loops | Generation timeout / 100% CPU | Enforce a strict maximum pass limit (e.g., 3) or require separate TOC assemblies | Large dynamic TOCs |

## "Looks Done But Isn't" Checklist

- [ ] **Cross-references:** Often missing validation — verify that a broken `#id` link raises an Elixir error, not a bad PDF.
- [ ] **Bookmarks Hierarchy:** Often missing expand/collapse behavior — verify that nested bookmarks work in both Apple Preview and Acrobat Reader.
- [ ] **Zoom Retention:** Often missing `null` zoom — verify that clicking a TOC link while zoomed in at 200% keeps the document at 200%.
- [ ] **Unicode Bookmarks:** Often missing UTF-16BE BOM — verify that a bookmark titled "Café ☕" renders correctly in Acrobat.
- [ ] **Multi-page TOCs:** Often missing accurate page tracking — verify that a TOC spanning 3 pages correctly calculates page offsets for the *rest* of the document.

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Layout Oscillation | TOC Primitive & Layout Strategy | End-to-end test with a multi-page TOC |
| Viewport "Drift" | Anchors & Destinations | Bounding box offset assertions in unit tests |
| Dangling Links | Anchors & Destinations | Errors-as-product unit test for broken refs |
| Linked-List Corruption | Outline Serialization | `poppler` structural validation on generated files |
| Invisible Text | Outline Serialization | String binary snapshot tests containing `\xFE\xFF` |

---
*Pitfalls research for: Rendro v2.9 TOC & Document Navigation*
*Researched: 2026-06-14*
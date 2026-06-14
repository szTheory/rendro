# Architectural Recommendations: Navigation & Document Structure

This document details the "perfect set of recommendations" for implementing four new navigation features in Rendro: Internal Anchors, Document Outlines (Bookmarks), Cross-References, and Visual TOC.

The recommendations are grounded in Rendro's core DNA: pure-Elixir, deterministic, functional, stateless pipelines (`build -> compose -> measure -> paginate -> validate -> render`) that completely avoid multi-pass layout oscillation and browser dependencies.

---

## 1. Internal Anchors

Internal anchors serve as the foundational primitive for all document navigation. They map a logical ID to a precise physical location (page, X, Y) in the final PDF.

### Implementation Approaches & Tradeoffs
* **Implicit ID Generation (Slugification):** Automatically generating IDs from heading text (e.g., "My Section" -> `my-section`).
  * *Pros:* Zero developer effort.
  * *Cons:* Brittle. If the text changes, cross-references break. Implicit magic violates Elixir's preference for explicit data.
* **Explicit ID Assignment:** Developers manually provide an `id` attribute to blocks.
  * *Pros:* Stable, deterministic, explicit.
  * *Cons:* Slightly more boilerplate.

### Recommendation: Explicit Assignment & `paginate`-phase Accumulation
We recommend **Explicit ID Assignment**. In the Elixir tradition of "no magic", an anchor only exists if the developer explicitly declares it.

During the `paginate` phase, as the layout engine calculates the final physical coordinates of a block, it checks for an `id` attribute. If present, it records the exact `[page /XYZ left top null]` destination into `doc.metadata.anchors`. This preserves the user's zoom level (`null` zoom) and ensures exact viewport alignment without "drift", avoiding the common footgun of jumping naively to the top of a page.

### DX Example
```elixir
# Using the functional API
PDF.heading("Executive Summary", id: "exec-summary")

# Using the Phoenix Component DSL
<Heading id="exec-summary">Executive Summary</Heading>
```

---

## 2. Document Outlines (Bookmarks)

Document outlines provide the native PDF sidebar navigation tree. This is a massive UX win for digital documents and occurs entirely outside the visual layout flow.

### Implementation Approaches & Tradeoffs
* **Independent Outline Tree:** Forcing the user to build a separate outline data structure that references anchor IDs.
  * *Pros:* Complete decoupling of layout and navigation.
  * *Cons:* Violates the "principle of least surprise." Developers expect headings to automatically populate the outline.
* **AST Harvesting (Declarative):** Extracting outline metadata from blocks during the `build` or `paginate` phase based on attributes like `outline_level`.
  * *Pros:* Excellent DX, keeps data cohesive.
  * *Cons:* Requires traversing the AST to build the hierarchy.

### Recommendation: AST Harvesting with UTF-16BE Serialization
We recommend **AST Harvesting**. Blocks accept `outline: true` (defaulting to level 1) or `outline_level: N`. During `paginate`, as the AST is traversed, we build a flat list of `%OutlineItem{}` structs enriched with their physical `[page /XYZ ...]` destinations.

Crucially, the complex doubly-linked PDF dictionary serialization (`/First`, `/Last`, `/Next`, `/Prev`, `/Count`) happens strictly in the `render` phase. This isolates the complexity of PDF ISO 32000-1 trees from the functional layout engine. Furthermore, all `/Title` strings must be explicitly encoded as UTF-16BE with a Byte Order Mark (`\xFE\xFF`) to prevent the classic footgun where non-Latin characters vanish in PDF sidebars.

### DX Example
```elixir
# Using the functional API
PDF.heading("Financials", id: "financials", outline_level: 1)
PDF.heading("Q3 Revenue", id: "q3-rev", outline_level: 2)

# Using the Phoenix Component DSL
<Heading id="financials" outline_level={1}>Financials</Heading>
<Heading id="q3-rev" outline_level={2}>Q3 Revenue</Heading>
```

---

## 3. Cross-References

Cross-references allow clickable inline text to target internal anchors, translating to PDF `/Link` annotations.

### Implementation Approaches & Tradeoffs
* **String-based parsing (Markdown style):** Parsing text strings for patterns like `[Text](#anchor)`.
  * *Pros:* Familiar to markdown users.
  * *Cons:* Requires regex/parsing overhead in the layout engine; difficult to strongly type.
* **Explicit Inline Components:** Using an explicit inline data structure like `%Rendro.Link{}` inside text runs.
  * *Pros:* Strongly typed, deterministic, easily validated.
  * *Cons:* Requires splitting text strings into lists of inline elements.

### Recommendation: Explicit Inline Components & Validation Gate
We recommend **Explicit Inline Components**. The layout engine receives explicitly structured text runs.

**Lesson Learned:** Silent failures on dangling links are a major footgun in tools like Prawn. We must lean into "Errors as Product." During the `validate` phase (post-pagination, pre-render), the engine iterates through all cross-references and verifies their target `id` exists in `doc.metadata.anchors`. If a target is missing, the pipeline crashes with an instructive, beautifully formatted error detailing the missing anchor and the block that referenced it.

### DX Example
```elixir
# Using the functional API
PDF.paragraph([
  "As detailed in the ",
  PDF.inline_link("Executive Summary", to: {:anchor, "exec-summary"}),
  ", our trajectory is strong."
])

# Using the Phoenix Component DSL
<Paragraph>
  As detailed in the <Link to={:anchor, "exec-summary"}>Executive Summary</Link>, our trajectory is strong.
</Paragraph>
```

---

## 4. Visual Table of Contents (TOC)

A printed TOC requires showing the page number of a specific section. This is the most dangerous feature because it risks creating an infinite layout oscillation loop.

### Implementation Approaches & Tradeoffs
* **Multi-pass Layout (The ReportLab / Typst approach):** Layout the document -> check page numbers -> update TOC -> re-layout document.
  * *Pros:* Mathematically "perfect" if it settles.
  * *Cons:* Can result in infinite loops. If page numbers increase (e.g., "9" -> "10"), the TOC grows, pushing content to new pages, changing the numbers again. This violates Rendro's strict single-pass constraint.
* **Fixed-Width Token Substitution:** Post-layout replacement of placeholder tokens.
  * *Pros:* Guarantees a single-pass layout without oscillation. Deterministic.
  * *Cons:* The TOC page number box has a fixed maximum width.

### Recommendation: Fixed-Width Token Substitution
We strongly recommend **Fixed-Width Token Substitution**. This is the only path that protects the single-pass architectural integrity of Rendro.

Developers declare TOC entries that emit a placeholder token (e.g., `{{anchor_page:exec-summary}}`). During the `measure` phase, this token is given a fixed width equivalent to a 3-digit or 4-digit number (e.g., "999"). The layout engine wraps lines and paginates based on this fixed width.

At the very end of the `paginate` phase, after all pages are finalized and `doc.metadata.anchors` is complete, we perform a pure-string substitution, replacing the tokens with the actual resolved page numbers aligned right within their pre-allocated fixed-width box. Because the bounding box width was pre-calculated and fixed, the layout *cannot* shift, guaranteeing zero oscillation.

### DX Example
```elixir
# Using the functional API (Building a TOC row)
PDF.row([
  PDF.cell("Executive Summary"),
  PDF.cell_spacer(leader: "."), 
  PDF.cell_page_reference("exec-summary") # Under the hood: fixed-width token substitution
])

# Using the Phoenix Component DSL
<TableOfContents>
  <TocEntry label="Executive Summary" target="exec-summary" />
  <TocEntry label="Financials" target="financials" />
</TableOfContents>
```

## Summary of Architectural Flow

To ensure the "no multi-pass" constraint holds, the pipeline execution strictly follows:

1. **Build:** Validate schemas, validate explicit `id` definitions, set up `outline_level` attributes, and insert `{{anchor_page:id}}` tokens with fixed geometric widths.
2. **Compose & Measure:** Calculate layout geometries. `{{anchor_page:id}}` tokens are measured as fixed-width bounding boxes.
3. **Paginate:**
   - Flow blocks across pages.
   - Accumulate exact `[page /XYZ left top null]` destinations into `doc.metadata.anchors` for any block with an `id`.
   - Harvest `outline_level` blocks into a flat list of `%OutlineItem{}`.
   - **Post-Paginate:** Perform token substitution for `{{anchor_page:id}}` using the now-complete `doc.metadata.anchors`, aligning the text right within its fixed box.
4. **Validate:** Cross-reference every `%Rendro.Link{}` against `doc.metadata.anchors`. Fail with a clear developer error if any anchor is missing.
5. **Render:**
   - Serialize blocks.
   - Convert `%Rendro.Link{}` inline AST elements into PDF `/Link` annotations.
   - Convert the flat `%OutlineItem{}` list into a doubly-linked ISO 32000-1 dictionary tree and serialize it to the PDF `/Outlines` catalog, encoding strings as UTF-16BE.
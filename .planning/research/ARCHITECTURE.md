# Architecture Patterns

**Domain:** PDF Table of Contents, Document Outlines, Anchors, and Cross-References
**Researched:** 2026-06-14

## Recommended Architecture

Rendro's non-negotiable constraint is its deterministic, single-pass `build -> compose -> measure -> paginate -> validate -> render` pipeline. To support Table of Contents (ToC) and internal navigation without introducing multi-pass layout or stateful mutation during rendering, the architecture must separate **invisible structural navigation** (PDF Outlines, Link targets) from **printable ToC content** (which relies on late-bound token substitution).

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Anchors (`id`)** | A unique string identifier added to `%Rendro.Block{}` and `%Rendro.Section{}` to mark a named destination. | `Build` (uniqueness validation), `Paginate` (location tracking). |
| **Outlines (`%OutlineItem{}`)** | A hierarchical tree structure defined in `Document.options` representing the PDF Bookmarks sidebar. | `Build` (schema validation), `Render` (`/Outlines` catalog serialization). |
| **Cross-References** | Extension of `%Rendro.Link{target: ...}` to support `{:anchor, id}` alongside existing URI/Page targets. | `Validate` (broken link checking), `Render` (`/Link` annotation targets). |
| **ToC Tokens** | `{{anchor_page:id}}` text tokens placed inside blocks to be substituted post-layout. | `Measure` (fixed placeholder width), `Paginate` (string substitution). |

### Data Flow Changes

1. **Build Phase (Validation)**
   - Validates that all block and section `id` attributes are unique across the document.
   - Validates the `%Rendro.OutlineItem{}` tree structure.

2. **Compose / Measure Phases (Pass-through)**
   - `id` attributes are preserved on blocks.
   - `{{anchor_page:id}}` tokens are measured literally (just as `{{page_number}}` is today), reserving layout space without causing circular dependency loops.

3. **Paginate Phase (The Key Integration Point)**
   - **Accumulation:** As `Paginate` assigns blocks to physical pages, it builds a metadata map of anchor locations: `anchors: %{"my_id" => %{page: 3, y: 150.0}}`.
   - **Substitution:** At the end of the `Paginate` loop, the existing `replace_page_numbers` function is expanded to execute `replace_anchor_tokens(pages, anchors)`. This substitutes `{{anchor_page:id}}` strings with the resolved physical page number *after* all layout is locked.
   - **State Passing:** The `anchors` map is attached to the paginated `Document` (e.g., `doc.metadata.anchors`) for downstream validation and rendering.

4. **Validate Phase (Integrity)**
   - Checks that all `{:anchor, id}` cross-references point to an ID present in `doc.metadata.anchors`.
   - Checks that all OutlineItem targets resolve to valid anchors. Returns deterministic `{:error, {:invalid_anchor, id}}` if broken.

5. **Render Phase (Serialization)**
   - Resolves anchor physical pages and Y-coordinates to generate explicit PDF Destinations (e.g., `[page_obj_num, /XYZ, left, top, null]`).
   - Serializes the `/Outlines` dictionary tree.
   - Maps `/Link` annotations to the explicit Destinations.

## Patterns to Follow

### Pattern 1: Data-Driven ToC Generation
**What:** The engine provides primitives (anchors and tokens), not a magic "auto-generate ToC" layout block.
**When:** Users want a printable ToC page.
**Example:**
Instead of the engine scanning headers and injecting a ToC page, the user builds a `%Rendro.Table{}` recipe where the left column is the section title and the right column is the `{{anchor_page:sec1}}` token. The user manually inserts this table at the beginning of their `sections` list.

### Pattern 2: Post-Measurement Token Substitution
**What:** Replace `{{anchor_page:id}}` strings at the end of `Paginate`, deliberately *not* updating the text run width.
**When:** Handling page number rendering for dynamic ToCs.
**Why:** Identical to the D-10 decision for `{{page_number}}`. Re-measuring would alter layout (text wrapping), breaking determinism and requiring a multi-pass architecture.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Stateful Multi-Pass Layout
**What:** Re-running the `Measure` phase to account for the physical size of substituted page numbers, or shifting pages because a ToC grew.
**Why bad:** Creates infinite loops (ToC grows -> pushes section to next page -> number changes -> ToC shrinks/grows). Violates the deterministic engine contract.
**Instead:** Rely on post-layout string substitution and advise users to align ToC numbers rightward in table cells where exact bounding box width doesn't wrap lines.

### Anti-Pattern 2: Implicit Anchoring
**What:** Automatically generating anchor IDs based on text content (e.g., `# Introduction` -> `intro`).
**Why bad:** Implicit IDs shift when data changes, silently breaking manual cross-references.
**Instead:** Require explicit `id: "string"` declarations on Blocks/Sections.

## Recommended Build Order

To integrate safely without derailing existing CI/CD gates, build in this sequence:

1. **Phase 1: Location Tracking & Primitives**
   - Add `id` to `Block`/`Section`.
   - Accumulate `doc.metadata.anchors` in `Paginate`.
2. **Phase 2: Document Outlines (PDF Bookmarks)**
   - Add `%OutlineItem{}` schema.
   - Serialize `/Outlines` catalog pointing to explicit destinations in `Render`.
3. **Phase 3: Cross-References**
   - Add `{:anchor, id}` target to `%Rendro.Link{}`.
   - Add structural validation in `Validate` phase.
   - Wire `/Link` annotations to PDF Destinations in `Render`.
4. **Phase 4: Printable Table of Contents**
   - Add `{{anchor_page:id}}` token substitution logic in `Paginate`.
   - Author the ToC recipe/guide demonstrating table-based alignment.

## Sources
- Rendro `v2.4` and `v2.7` post-layout page-number substitution patterns (D-10 decision, `replace_page_numbers/2` in `lib/rendro/pipeline/paginate.ex`).
- Rendro `v1.9` embedded links architecture (`lib/rendro/link.ex`, `lib/rendro/pdf/writer.ex`).
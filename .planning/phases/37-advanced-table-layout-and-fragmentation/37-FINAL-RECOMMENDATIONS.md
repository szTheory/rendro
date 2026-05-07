# Phase 37 - Final Architectural Recommendations: Advanced Table Layout and Fragmentation

This document serves as the definitive architectural decision record and recommendation for Phase 37: Advanced Table Layout and Fragmentation in Rendro. Drawing on deep analysis, ecosystem idioms, and historical lessons from legacy layout engines (Prawn, ReportLab, Typst, LaTeX, wkhtmltopdf), these decisions are locked and finalized to guide the implementation.

---

## 1. DSL API for Fragmentation

### Decision: Expand Global Policy + Optional Semantic Wrappers (`%Rendro.Row{}` and `%Rendro.Cell{}`)

#### Deep Analysis of Assumptions and Footguns
*   **Assumption:** The 90% usecase for developers generating PDFs is simple lists-of-lists (strings or basic blocks).
*   **Footgun:** Forcing the creation of complex object graphs (like Prawn does) for basic tables destroys DX. Conversely, relying only on lists-of-lists leaves no room for attaching metadata (like `split_policy: :atomic`) to individual cells.

#### Pros/Cons/Tradeoffs
*   **Pros:** 
    *   Preserves the lightweight DSL `[["A", "B"], ["C", "D"]]` for the vast majority of tables.
    *   Allows progressive disclosure of complexity. If a user needs advanced behavior, they can opt-in by wrapping specific cells or rows in a struct.
    *   Idiomatic pattern matching in Elixir makes mixed data types (strings vs structs) trivial to handle in the normalization pipeline.
*   **Cons:**
    *   Internal pipeline must handle an explicit normalization step (Measure phase) to convert everything into a unified structural representation.

#### Idiomatic Elixir / Phoenix
In Phoenix and Ecto, simple maps and keyword lists are used for basic configuration, but fully cast structs (like Ecto Changesets) are used when behavior gets complex. Providing a simple entry point that can be transparently upgraded to a struct via pattern matching is a cornerstone of Elixir library design.

#### Lessons from Other Tools
*   **Prawn (Ruby):** Table rows can be split, but getting granular control means diving deep into messy object instantiation that ruins the declarative feel.
*   **Typst / HTML/CSS:** Uses CSS properties like `break-inside: avoid` that cascade from parent to child seamlessly.
*   **Our approach:** Mimics Typst's cascade by allowing the global `%Rendro.Table{}` policy to be overridden by local `%Rendro.Row{}` and `%Rendro.Cell{}` policies.

#### Developer Ergonomics (DX) & Principle of Least Surprise
By defaulting `split_policy` to `:row_atomic` but allowing `:fragment`, the user gets predictable behavior out of the box. The API grows with the user.

#### Example
```elixir
%Rendro.Table{
  split_policy: :fragment, # Breaks naturally across pages
  rows: [
    ["Simple text", "Another string"],
    %Rendro.Row{
      split_policy: :atomic, # Keeps this specific row together
      cells: [
        "Normal cell", 
        %Rendro.Cell{
          content: "I have custom rules", 
          split_policy: :row_atomic
        }
      ]
    }
  ]
}
```

---

## 2. Break Semantics Inside Cells

### Decision: Cells as Isolated Pagination Flows

#### Deep Analysis of Assumptions and Footguns
*   **Assumption:** A cell is fundamentally a container of blocks, much like a page itself.
*   **Footgun:** If a row breaks, attempting to slice different cells at different visual coordinates will result in staggered, misaligned text rows across the page break.
*   **The Invariant:** All cells in a fragmented row MUST break at the exact same relative Y-coordinate.

#### Pros/Cons/Tradeoffs
*   **Pros:**
    *   Zero new pagination logic needs to be invented. A cell literally uses the exact same `Rendro.Pipeline.Paginate.split/2` logic as top-level blocks.
    *   Highly predictable mental model for developers.
*   **Cons:**
    *   Might yield excessive empty blocks for short cells that sit next to very long cells spanning multiple pages.

#### Idiomatic Elixir / Phoenix
Elixir prefers pure data transformations. Re-using the `Paginate.split/2` pure function recursively is exactly how an Elixir developer would expect the engine to work, composing small transformations into larger ones seamlessly.

#### Lessons from Other Tools
*   **wkhtmltopdf / LaTeX:** Often clumsy when slicing visual boundaries. wkhtmltopdf is notorious for physically slicing a line of text in half visually instead of respecting text line heights.
*   **Typst:** Treats cells as standard block containers that paginate exactly like page flows. We adopt this Typst model as the gold standard.

#### Developer Ergonomics (DX) & Principle of Least Surprise
If a user understands how a top-level text block paginates (breaking at line-height boundaries), they immediately understand how a cell paginates. No surprises.

#### Example
When a row with two cells is split horizontally at `100px`:
1.  **Cell A** (Text, 300px high) is split into a 100px block and a 200px continuation.
2.  **Cell B** (Text, 50px high) finishes entirely within the 100px space. It yields a 50px block and an *empty* continuation block.
Both resume cleanly on the next page without misalignment.

---

## 3. Continuation Decorators (Headers & Borders)

### Decision: `:slice` vs `:clone` semantics via `decoration_break` and `repeat_header`

#### Deep Analysis of Assumptions and Footguns
*   **Assumption:** Users want immediate context when a table spans pages.
*   **Footgun:** Drawing a bottom border on a page break implies the table has ended. It is a visual lie to the reader. 

#### Pros/Cons/Tradeoffs
*   **Pros:**
    *   Directly mirrors the CSS3 `box-decoration-break` specification, which front-end developers already know intimately.
    *   Solves the visual ambiguity of fragmented tables gracefully.
*   **Cons:**
    *   Requires the Paginate phase to modify drawing instructions explicitly at the slice boundary, adding slight complexity to the rendering phase.

#### Idiomatic Elixir / Phoenix
Using atoms to represent discrete states (`:slice`, `:clone`) is standard practice in Elixir. Passing these configuration parameters top-down through the struct hierarchy keeps configuration localized, pure, and explicit.

#### Lessons from Other Tools
*   **ReportLab (Python):** Offers `RepeatRows`, which is excellent. However, visual cues (like omitting bottom borders to signal a break) require the user to implement complex manual drawing hooks.
*   **CSS:** Solved this problem permanently with `box-decoration-break`.

#### Developer Ergonomics (DX) & Principle of Least Surprise
A web developer transitioning to Rendro will immediately recognize `decoration_break: :slice` and `repeat_header: true`. It leverages existing mental models rather than inventing new terminology.

#### Example
```elixir
%Rendro.Table{
  repeat_header: true,
  header: ["Invoice Item", "Cost"],
  decoration_break: :slice, # Automatically omits the cut-edge border
  rows: [...]
}
```

---

## 4. Colspan/Rowspan During Fragmentation

### Decision: The Grid Projection Algorithm

#### Deep Analysis of Assumptions and Footguns
*   **Assumption:** Paginating nested recursive structures (Row -> Cell -> Span) is a fool's errand that leads to edge-case hell, especially when page breaks split a rowspan.
*   **Footgun:** Malicious or accidental input generating a table with massive spans can cause an OOM (Out Of Memory) DoS attack during matrix generation (Threat T-37-01).

#### Pros/Cons/Tradeoffs
*   **Pros:**
    *   Sidesteps the "rowspan spanning across pages" nightmare. The table is converted into a bounded 2D matrix before pagination.
    *   Future-proofs the engine for CSS-like Grid Layouts beyond just tables.
*   **Cons:**
    *   Bounding the grid requires strict maximums (mitigated by checking limits and returning `{:error, :grid_too_large}`).
    *   Requires a heavier `Measure` phase to normalize the AST and project it into memory.

#### Idiomatic Elixir / Phoenix
Elixir excels at recursive map/reduce operations to build complex data structures (like a 2D matrix). Using a separate `Measure` phase to transform the AST into an intermediate representation (`_grid_layout`) before passing it to `Paginate` aligns perfectly with the classic Plug/Pipeline architecture of Elixir. State is computed once, validated, and passed forward immutably.

#### Lessons from Other Tools
*   **wkhtmltopdf:** Frequently duplicates spanned cells or completely corrupts the layout because it tries to paginate the DOM tree directly without projecting it first.
*   **Browser Engines:** Convert table DOMs into internal layout grids before slicing. We are adopting the robust browser approach.

#### Developer Ergonomics (DX) & Principle of Least Surprise
The complexity is entirely hidden from the user. The user just declares that a cell spans 3 rows. If a page break happens on row 2, Rendro handles the geometry perfectly behind the scenes without the developer ever needing to think about "fragmentation spans."

#### Example
1.  **Input:** A user declares a table with 3 rows, where Row 1 Cell 1 has `rowspan: 2`.
2.  **Measure Phase:** Converts this into a 2D matrix. Slot `(0,0)` holds the content. Slot `(1,0)` holds `%{is_continuation: true, ref: {0,0}}`.
3.  **Paginate Phase:** If sliced horizontally at row index 1, the paginator sees the continuation marker, pulls the text flow from the primary cell, splits it correctly, and injects the remainder into the top of the next page.

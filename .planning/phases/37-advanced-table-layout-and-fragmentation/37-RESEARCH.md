# Phase 37: Advanced Table Layout & Fragmentation - Architectural Research

## Executive Summary
This document provides a comprehensive architectural recommendation for supporting explicit cell fragmentation in `Rendro.Table`. Implementing page breaks mid-row and mid-cell requires careful consideration of Elixir ecosystem idioms and drawing on the hard-learned lessons of legacy PDF/layout tools (Prawn, ReportLab, Typst, LaTeX). 

The proposal introduces a scalable DSL that stays simple for the 90% use case while offering explicit escape hatches, standardizes break semantics using the existing pagination pipeline, and proposes a grid-slicing algorithm for the notoriously difficult rowspan fragmentation problem.

---

## 1. DSL API for Fragmentation

### Current Context
`Rendro.Table` defines rows as `[Rendro.Block.t() | String.t()]` and uses a global `split_policy` (`:row_atomic` | `:atomic`).

### Lessons from other Ecosystems
* **Prawn (Ruby):** Table rows can be split or unbroken, but per-cell granularity is tough to manage via the DSL without diving into messy object instantiation.
* **Typst / HTML/CSS:** Uses CSS properties like `break-inside: avoid` which cascades. Typst supports `breakable: true` on tables and blocks.

### Recommendation: Expand Global Policy + Optional Semantic Wrappers
We should expand the global `split_policy` to include `:fragment` (or `:auto`), allowing rows to break naturally.
For granular control, we should avoid forcing users to wrap every cell in a struct. Instead, we introduce optional `%Rendro.Row{}` and `%Rendro.Cell{}` structs that implement the `Rendro.Block` behavior. 

**Pros:**
* Preserves the existing lightweight list-of-lists DSL for 90% of use cases.
* Aligns with HTML/CSS cascading principles (global table policy can be overridden by row/cell).
* Extremely idiomatic Elixir: pattern matching in the pipeline can easily handle lists vs. structs.

**Cons:**
* Increases internal complexity (needs normalization step).

### API Example
```elixir
# 1. Global policy (Simple)
%Rendro.Table{
  split_policy: :fragment, # New policy!
  rows: [
    ["Short text", "Long paragraph that will naturally split across pages"]
  ]
}

# 2. Granular Override (Advanced)
%Rendro.Table{
  split_policy: :fragment,
  rows: [
    %Rendro.Row{
      split_policy: :atomic, # Overrides table policy
      cells: ["Don't break", "me"]
    },
    [
      "Normal cell", 
      %Rendro.Cell{
        content: "I have my own rules", 
        split_policy: :row_atomic
      }
    ]
  ]
}
```

---

## 2. Break Semantics Inside Cells

### Context
When a row is split, where can the content of its cells break? 

### Lessons from other Ecosystems
* **LaTeX / wkhtmltopdf:** wkhtmltopdf often clumsily slices text in half visually if a break isn't calculated at a text-line boundary.
* **Typst:** Treats table cells as standard block containers; they paginate exactly like a page flow.

### Recommendation: Cells as Isolated Pagination Flows
A cell should be treated exactly like a top-level page region during the `Rendro.Pipeline.Paginate` phase. 
When a row fragments, it is given a `remaining_height`. The row iterates through its cells, calling the standard `Paginate.split(cell_block, remaining_height)` function.

1. **Mid-sentence splitting:** Yes, if a cell contains a `%Rendro.Text{}` block, the text block should paginate along standard line-height boundaries, pushing the remaining lines to the next page.
2. **Discrete blocks:** If a cell contains an atomic block (e.g., an Image without its own fragmentation policy), it is pushed to the next fragment.

**The Crucial Invariant:** 
All cells in a fragmented row must break at the **exact same Y-coordinate relative to the row**. If Cell A has 10 lines and Cell B has 2 lines, and the page break happens at line 5, Cell A splits at line 5, and Cell B (having finished) simply yields an empty block for the continuation fragment on page 2.

**Pros:**
* Zero new pagination logic. It reuses the exact same paginator as top-level blocks.
* Highly predictable developer mental model (a cell is just a mini-page).

---

## 3. Continuation Decorators (Headers & Borders)

### Context
When a table spans pages, users need context (repeated headers) and visual cues (open borders).

### Lessons from other Ecosystems
* **ReportLab (Python):** `RepeatRows` property is excellent. But visual cues for "table continues" (like an open bottom border) require manual drawing hooks. 
* **CSS:** `box-decoration-break: clone | slice` solves exactly this for borders and padding. 

### Recommendation: `box_decoration_break` and `repeat_header`
Introduce `repeat_header: boolean()` to `%Rendro.Table{}` (defaults to `false` for backwards compatibility, though `true` is often preferred).

For borders, introduce a `decoration_break` styling attribute mirroring CSS.
* `:slice` (default for tables): The bottom border of the page 1 fragment is omitted. The top border of the page 2 fragment is omitted. This provides a visual cue that the cell was sliced.
* `:clone`: The border is drawn fully on both fragments.

### API Example
```elixir
%Rendro.Table{
  repeat_header: true,
  header: ["Product", "Description"],
  decoration_break: :slice, # Automatically handles border omission on breaks
  rows: [...]
}
```

---

## 4. Colspan/Rowspan During Fragmentation

### Context
Splitting a table that contains rowspans is the final boss of PDF generation. If a cell spans Row 1, 2, and 3, and a page break occurs between Row 2 and 3, the spanning cell must be correctly sliced and continued.

### Lessons from other Ecosystems
* **wkhtmltopdf:** Frequently duplicates spanned cells or corrupts layouts.
* **HTML/Browser rendering:** Converts the table DOM into an internal Grid before pagination, then slices the Grid coordinates.

### Recommendation: The Grid Projection Algorithm
Instead of paginating tables recursively as a tree of `Row -> Cell`, the `Measure` phase must project the table into a 2D Grid structure.

1. **Projection Phase:** A 3x3 table with a cell spanning 2 rows is converted into a 3x3 matrix where the spanned cell occupies two slots, but with a flag `is_continuation: true` in the second slot.
2. **Fragmentation Phase:** The paginator does not split rows; it slices the **Grid horizontally at a given Y coordinate**.
3. **Reconstitution:** The sliced grid fragments are converted back into discrete drawing instructions for the `Render` phase.

If a spanned cell crosses the slice line, it is treated like a normal cell split (paginating its internal flow), and the remaining content is injected into the starting slot of the next page's grid.

**Pros:**
* Completely sidesteps the "rowspan spanning across pages" edge case, as the table is sliced as a unified geometric grid, not as nested layout nodes.
* Future-proofs the engine for complex grid layouts beyond tables.

**Cons:**
* Requires refactoring the internal layout representation for tables before they reach the `Paginate` phase.

---

## Conclusion
By treating cells as mini-pages (reusing the core pagination logic), introducing optional `%Rendro.Row{}` and `%Rendro.Cell{}` structs for overrides, leveraging `:slice` semantics for borders, and moving to a Grid-based slicing algorithm for rowspans, `Rendro` can offer a robust, Typst-tier table layout engine while maintaining the elegant, functional DSL that Elixir developers love.
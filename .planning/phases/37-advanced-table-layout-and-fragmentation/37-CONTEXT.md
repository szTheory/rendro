# Phase 37: Advanced Table Layout & Fragmentation (Context)

## Executive Summary
This document captures the locked architectural decisions for explicit table cell fragmentation, reached during the `/gsd-discuss-phase` on Monday, May 4, 2026. The full research and evaluation of alternatives can be found in `37-RESEARCH.md`.

## Locked Decisions

1. **DSL API for Fragmentation**
   - **Decision:** Expand the global table `split_policy` to support `:fragment` (alongside existing `:row_atomic` and `:atomic`). 
   - **Mechanism:** Maintain the lightweight `list-of-lists` DSL for 90% of use cases. For advanced granular overrides, introduce optional `%Rendro.Row{}` and `%Rendro.Cell{}` structs that implement the `Rendro.Block` behavior.

2. **Break Semantics Inside Cells**
   - **Decision:** Treat cells as isolated pagination flows.
   - **Mechanism:** When a row fragments, it iterates through its cells, calling the standard `Paginate.split/2` function. Text blocks inside cells paginate naturally along line-height boundaries. All cells in a fragmented row must break at the exact same Y-coordinate relative to the row.

3. **Continuation Decorators (Headers & Borders)**
   - **Decision:** Adopt CSS-style decorators for continuation visual cues.
   - **Mechanism:** Introduce `repeat_header: boolean()` (default `false`) and `decoration_break` (`:slice` | `:clone`) to `%Rendro.Table{}`. The `:slice` semantic will omit borders at the page break, signaling to the user that the cell continues.

4. **Colspan/Rowspan During Fragmentation**
   - **Decision:** Use a Grid Projection Algorithm.
   - **Mechanism:** To avoid legacy PDF layout engine bugs (e.g., wkhtmltopdf rowspan splitting), the `Measure` phase will project the table into a 2D Grid matrix. The paginator then slices this grid horizontally at a given Y coordinate, rather than paginating the table recursively as a tree of nested nodes.

## Next Steps
These decisions act as hard constraints for the execution of Phase 37. The `Paginate` pipeline will require minor modifications to support cell-level pagination streams, and the `Measure` phase must be updated to implement Grid Projection for tables.
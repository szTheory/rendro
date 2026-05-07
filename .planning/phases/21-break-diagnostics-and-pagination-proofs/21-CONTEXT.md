# Phase 21 Context: Break Diagnostics and Pagination Proofs

This document captures the architectural decisions and constraints for Phase 21, resolving requirements OBS-05 and QUAL-06. These decisions were formulated during the discuss phase, emphasizing developer ergonomics, deterministic layout math, and idiomatic Elixir patterns.

## Decisions

### 1. Surfacing Structured Layout Diagnostics (OBS-05)

**Decision:** We will adopt the "Changeset" pattern. We will add a `diagnostics: []` field to the `%Rendro.Document{}` struct and reserve `:telemetry` solely for pipeline performance metrics. 

**Rationale:**
Treat the `%Rendro.Document{}` like an `Ecto.Changeset` during the pipeline. As the document flows through `Measure` and `Paginate`, non-fatal structural decisions (like "Table split at row 4" or "Text overflowed region by 12px") will be appended as structured maps to `doc.diagnostics`.

*   **DX / Principle of Least Surprise:** When a developer calls `Rendro.render(doc)`, they can pattern match on `{:ok, final_doc}` and immediately run `IO.inspect(final_doc.diagnostics)` in their REPL or tests. This provides immediate, localized feedback, much like inspecting an Ecto changeset or using Browser DevTools, without the friction of setting up telemetry handlers just for local debugging.
*   **Separation of Concerns:** Keep `:telemetry` focused on span durations, stage tracking, and error rates (which is idiomatic for Elixir).
*   **Structured Debugging:** Define diagnostics as structured maps (e.g., `%{level: :info, type: :table_split, page: 2, block_id: "tbl-1", reason: :insufficient_height}`). This allows operators to programmatically assert on layout decisions in their own applications.

### 2. Proving Pagination Invariants (QUAL-06)

**Decision:** We will implement an ASCII Layout Tree (Snapshot Testing) approach. We will create a `Rendro.Inspector` utility that serializes a paginated `%Document{}` into a deterministic, human-readable ASCII tree, and use ExUnit snapshot testing to verify it.

**Rationale:**
We need to prove our pagination logic (breaks, keep-with-next, overflows) works correctly in CI without relying on PDF binary diffs, which are notoriously fragile, or massive Elixir struct dumps, which are unreadable in Git PRs.

Instead, `Rendro.Inspector` will walk the paginated document and print its bounding boxes and layout events as plain text:

```text
Page 1 (612x792)
├── Region: body (x: 36, y: 36, w: 540, h: 720)
│   ├── Block: Table (x: 36, y: 36, w: 540, h: 600)
│   │   ├── Break: split (row: 15)
Page 2 (612x792)
├── Region: body (x: 36, y: 36, w: 540, h: 720)
│   ├── Block: Table [Continued] (x: 36, y: 36, w: 540, h: 120)
│   ├── Block: Text (x: 36, y: 156, w: 540, h: 24)
```

*   **Bulletproof Regression Catching:** If a math bug shifts a block down by `1.0`, the snapshot diff in the GitHub PR will explicitly show `y: 156 -> y: 157`.
*   **Reviewability (DX):** Maintainers reviewing PRs don't need to decipher Elixir struct maps or download a PDF artifact. The invariant is proven in plain text right in the PR diff. This mimics the DX success of UI tree snapshot testing in React/Flutter and query inspection in Ecto.
*   **Resilience:** Because it only prints layout bounds and structural types, we can add internal fields to `%Page{}` or `%Region{}` without breaking snapshot tests, isolating layout math from pipeline state.

## Synthesis

These two decisions synergize perfectly. By appending structured diagnostics to the `%Document{}` (OBS-05), the `Rendro.Inspector` text dump (QUAL-06) can explicitly print those diagnostics alongside the layout tree. When a test runs, the developer gets an immediate, readable text snapshot that proves exactly where elements were placed and explicitly lists the internal reasons *why* they were placed there. This achieves a highly deterministic, observable, and debuggable layout engine.

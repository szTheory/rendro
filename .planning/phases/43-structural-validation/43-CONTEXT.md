# Phase 43 Context: Structural PDF Validation & Stress Test

## Goal
Implement **S04: Structural PDF Validation & Stress Test** (from the v1.5 roadmap).
A generated stress-test PDF must pass a native structural validation pass to prove layout soundness before binary serialization.

## Architectural Decision
Based on a deep analysis of Elixir ecosystem patterns, performance requirements (stress testing), and DX, we are adopting the **Hybrid Single-Pass Visitor Pattern**.

1. **Single-Pass Performance**: The validator walks the PDF AST exactly once using recursion, ensuring O(N) performance and minimizing allocation overhead compared to schema-based approaches.
2. **Pluggable Cohesion**: Instead of a monolithic walker, the traversal logic acts as an event emitter. As it visits each node, it delegates validation to a list of focused rule modules (e.g., `CheckReferences`, `CheckBounds`, `CheckRequiredKeys`).
3. **Omission of Ecto/NimbleOptions for AST**: We explicitly avoid Ecto or NimbleOptions for AST validation, as they allocate too much intermediate memory for deep, 10,000-page document stress tests.
4. **Validation Stage**: This becomes a formal stage in the `Rendro.Pipeline`: `Rendro.Pipeline.Validate`.

This architecture balances the high performance needed for pure-Elixir PDF generation with the testability and isolation of a plug-style system.
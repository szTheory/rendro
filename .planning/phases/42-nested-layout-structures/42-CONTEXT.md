# Phase 42 Context: Nested Layout Structures

## Goal
Implement **S03: Nested Layout Structures** (from the v1.5 roadmap).
A table nested inside another layout component (or complex nesting of tables, blocks, and lists) must aggregate heights correctly and fragment cleanly if it crosses a page boundary.

## Architectural Decision
Based on deep ecosystem research and Rendro's core tenets (Determinism, Pure Functions, and Developer Ergonomics), we have decided to adopt the **Universal Box Model via Protocol Polymorphism**.

1. **`Rendro.Fragmentable` Protocol**: We are extracting pagination slicing logic out of `Paginate` and formalizing it into a protocol. `Paginate` tracks page bounds; `Fragmentable` slices specific layout primitives (`Block`, `Table`, etc.).
2. **Immutable Bubbling**: The protocol's `split/2` function will return `{:fit, component} | {:split, fit, remainder} | {:overflow, component}`. Slicing happens top-down, and the sliced AST fragments bubble back up immutably.
3. **Strict Block Boundaries**: All table cells must wrap their content in `%Rendro.Block{}`. This enforces a universal layout container, making recursive slicing predictable.
4. **Decoration Break Semantics**: Splitting logic for tables and blocks will natively handle `decoration_break: :slice | :clone`, ensuring the `Render` phase requires zero contextual awareness.

This approach keeps the core pagination engine simple while enabling infinite nesting of future layout components.
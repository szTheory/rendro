# Phase 22: Authoring Ergonomics and Canonical Recipes

## Context & Decisions

The user requested a cohesive, \"batteries-included\" set of recommendations for Phase 22's authoring ergonomics that prioritize developer experience, idiomatic Elixir/Phoenix conventions, and lessons learned from other successful PDF layout engines (like Prawn, WeasyPrint, and React-PDF). Instead of manual Q&A, we conducted deep research via subagents to produce an optimal design.

### 1. API Shape for Recipes: \"Tiered Composition\"
**Decision**: `Rendro.Recipes` will not be a monolithic black box. Recipes (like `Rendro.Recipes.Invoice`) will adopt a \"Tiered Composition\" pattern:
- `document(data, opts)`: Batteries-included; returns a fully assembled `%Rendro.Document{}` ready for `Rendro.build/1`.
- `page_template(opts)`: Layout only; returns the `%Rendro.PageTemplate{}`.
- `sections(data, opts)`: Content only; returns a list of `%Rendro.Section{}` structs.
**Why**: This provides a zero-to-one \"just works\" experience for beginners, while offering \"escape hatches\" for advanced users who need to inject their own corporate templates or branded headers/footers.

### 2. Idiomatic Elixir DX: The Pipeline Builder Pattern
**Decision**: Introduce a pipeable builder API for dynamic document construction, mirroring the ergonomics of `Plug.Conn` or `Ecto.Changeset`.
- `Rendro.Document.new()`
- `|> Rendro.Document.put_metadata(...)`
- `|> Rendro.Document.add_template(...)`
- `|> Rendro.Document.add_section(...)`
**Why**: Elixir developers expect pipelines. While `Rendro.document(sections: [...])` is great for declarative definitions, a builder API supports dynamic, conditional assembly during a request cycle.

### 3. Phoenix Controller Ergonomics
**Decision**: Update `examples/phoenix_example` to serve a realistic invoice using the new APIs.
**Why**: Serving PDFs in Phoenix should feel as natural as rendering JSON. We will provide a clear, idiomatic example of loading data, building the document via the recipe API, and sending the `application/pdf` response inline.

### 4. Testing Ergonomics
**Decision**: Emphasize AST-based testing in the documentation and examples.
**Why**: Developers should not write brittle tests that assert against raw PDF binaries. Because Rendro is deterministic and data-driven, tests can simply assert on the structure of the `%Rendro.Document{}` (e.g., verifying a section contains a specific `%Rendro.Text{}` block).

### 5. The \"React-PDF\" Mental Model
**Decision**: Guide users to think in terms of functional components.
**Why**: In React-PDF, everything is a component returning UI primitives. In Rendro, users should be encouraged to write small functions that return `[%Rendro.Block{}]` or `%Rendro.Section{}`, allowing deep composability without managing stateful layout cursors (a major footgun in libraries like Prawn).

---
**Status**: The Discuss Phase is complete and alignment on the architecture has been established autonomously per the user's directive. The next step is `/gsd-plan-phase 22`.
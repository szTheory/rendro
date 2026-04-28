# Research: Features for v1.1 Layout Authoring Maturity

## Table Stakes

### Flow Layout Semantics

- Width-constrained text wrapping
- Deterministic line-breaking
- Explicit keep/break directives
- Truthful overflow/fit errors

### Page Structure

- Flow page templates with configurable geometry
- Anchored header/footer regions
- Reusable sections or bounded layout regions
- Predictable content-area calculation

### Table Behavior

- Deterministic column sizing
- Header repetition across page breaks
- Row integrity and explicit split policy
- Multi-page continuation behavior that remains stable under repeated renders

## Differentiators

### Break Explainability

- Explain why a block moved to the next page
- Explain why a block split
- Explain why authored content cannot fit a given region/page

### Truthful Authoring Surface

- Remove or close the gap between what public structs imply and what the engine actually honors
- Make recipes/examples demonstrate supported layout semantics rather than optimistic placeholders

## Anti-Features

- HTML/CSS parity
- WYSIWYG editing
- App-specific hacks hidden in core
- Premature font/image support before layout semantics harden

## Complexity Notes

- Text wrapping changes both measurement and rendering expectations, so it is foundational.
- Page-template and region work is a prerequisite for later font/image placement.
- Table maturity is an adoption-critical slice because invoices and reports are core use cases.
- Diagnostics must ship with the layout changes; otherwise future milestones become harder to debug.

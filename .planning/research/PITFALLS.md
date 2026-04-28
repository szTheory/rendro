# Research: Pitfalls for v1.1 Layout Authoring Maturity

## Primary Risks

### Premature Typography Work

Adding custom fonts or asset placement before page templates, regions, and deterministic measurement stabilize would create churn and invalidate pagination assumptions in the middle of the milestone arc.

### Public Surface Drift

Several public fields already imply behavior the engine does not fully honor (`Text.font`, `Table.width`, `Table.border`, footer semantics). v1.1 must either implement or narrow these contracts so docs and structs stay truthful.

### Ad Hoc Pagination Rules

If keep/break behavior is implemented as special cases instead of explicit data semantics, later milestones will inherit fragile pagination logic that is hard to test and explain.

### Table Work That Stops At Demo Quality

Multi-page tables are already central to Rendro's positioning. A partial refactor that preserves fixed row heights or simplistic split rules would leave the biggest adoption gap mostly open.

### Diagnostics That Don’t Preserve Cause

If break/overflow reasoning is only logged or partially surfaced, operators and future async workflows will not have enough context to debug production layout failures.

## Prevention Strategy

- Keep v1.1 focused on authoring semantics and deterministic measurement.
- Add requirement-level regression fixtures for page assignment and split behavior.
- Update recipes/docs only after the engine contracts are truthful.
- Explicitly defer fonts/assets and async artifact lifecycle work instead of leaking them into the milestone.

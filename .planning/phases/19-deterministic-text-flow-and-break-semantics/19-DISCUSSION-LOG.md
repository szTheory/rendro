# Phase 19 Discussion Log

**Date:** 2026-04-29
**Mode:** `gsd-discuss-phase`
**Style:** Recommendation-first, subagent-backed research synthesis

## Prompt

User selected all gray areas for Phase 19 and requested:
- subagent research for each area
- pros/cons/tradeoffs with examples
- idiomatic guidance for Elixir/Phoenix/Plug/Ecto ecosystems
- lessons from successful libraries in this space, including other ecosystems
- a one-shot cohesive recommendation set
- stronger recommendation-first behavior shifted left within GSD except for very impactful decisions

## Gray Areas Resolved

### 1. Text wrapping contract
- Resolved to: keep width-constrained wrapping on `Rendro.Block` geometry; do not make `Rendro.Text` self-wrapping by adding `:width`.
- Additional refinement: any text-only vertical styling belongs on `Rendro.Text`, not on `Block`.

### 2. Break directive surface
- Resolved to: put `keep_together`, `keep_with_next`, `break_before`, and `break_after` on `Rendro.Block` as the only public break-intent surface for Phase 19.
- Rejected alternatives: text-level directives, section-level directives, and standalone flow action nodes as the primary contract.

### 3. Keep-rule failure semantics
- Resolved to: treat keep rules as hard authored constraints.
- Behavior: move intact to a fresh page/region when possible; otherwise return typed paginate overflow instead of silently relaxing the rule.

### 4. Public API and docs posture
- Resolved to: keep the public story centered on the existing `flow -> block -> text` builders and page templates/regions.
- Rejected alternative: introduce a new report/authoring DSL in Phase 19.

## Research Inputs

Parallel subagent studies covered:
- wrapped text contract shape
- break directive ownership
- keep-rule failure policy
- public API/docs posture

Common external ecosystem themes surfaced across the studies:
- successful document/layout libraries separate content styling from layout geometry
- hard keep constraints are safer and more debuggable than silent best-effort relaxation
- convenience helpers are acceptable later, but only after the core contract is stable and documented truthfully

## Final Synthesis

The final recommendation set written into `19-CONTEXT.md` is:
- geometry on `Block`
- styling on `Text`
- page intent on `Block`
- deterministic multi-line measure in `Measure`
- deterministic movement/failure in `Paginate`
- no new authoring DSL in this phase
- recommendation-first posture explicitly captured for future GSD work

## Deferred

- paragraph/helper sugar if later DX warrants it
- softer future directives with different semantics than `keep_*`
- richer typography/widow-orphan/hyphenation behavior
- table-row keep policy in Phase 20

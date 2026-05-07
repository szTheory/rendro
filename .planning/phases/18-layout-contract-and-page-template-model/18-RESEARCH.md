# Phase 18: Layout Contract and Page Template Model - Research

**Researched:** 2026-04-28
**Domain:** layout contract, flow pagination, page templates, bounded regions
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-07 | Engineer can define flow documents against explicit page templates with configurable geometry and anchored header/footer regions. | Current flow pagination hard-codes `%Rendro.Page{}` and top-level `Document.header/footer`; Phase 18 needs an explicit page-template contract plus anchored regions. |
| LAY-08 | Engineer can compose reusable sections or bounded layout regions without dropping down to raw page coordinates for every document. | Current `Document.content` is just a flat block list with no section/region abstraction; Phase 18 needs first-class section and region data that normalize into the existing render core. |
| LAY-11 | Engineer receives truthful fit validation when authored fixed-position or flow-region content cannot fit the declared page/layout bounds. | Current fixed pages bypass pagination validation entirely when `pages != []`; fit checks need to become explicit for fixed pages and bounded regions. |
</phase_requirements>

## Summary

Phase 18 should introduce explicit layout data structures before changing deeper text or table behavior. The strongest seam is to keep the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline intact while making `Rendro.Document` carry a real page-template and section/region contract that both fixed and flow APIs normalize into.

Three concrete gaps in the current codebase drive the plan:

1. `lib/rendro/pipeline/paginate.ex` hard-codes `template = %Rendro.Page{}` for flow documents, so the layout contract is implicit and not authorable.
2. `lib/rendro/document.ex` models `header` and `footer` as top-level block lists and has no concept of reusable sections or bounded regions.
3. `Paginate.run/1` returns fixed pages unchanged whenever `pages != []`, so fixed-position documents are not checked against page bounds truthfully.

**Primary recommendation:** land Phase 18 in three slices:
- add explicit layout structs and builders (`PageTemplate`, `Region`, `Section`) plus `Document` shape changes;
- normalize flow documents through template-backed regions inside `Compose`, `Measure`, and `Paginate`;
- harden fixed-position and region overflow validation with deterministic tests and truthful error details.

## Current-State Findings

### 1. Flow layout is template-implicit today

`lib/rendro/pipeline/paginate.ex` currently creates flow pages with:

```elixir
template = %Rendro.Page{}
```

That means every flow document inherits one invisible page geometry. It prevents public APIs from expressing:
- alternate paper sizes or margin sets per flow document,
- anchored header/footer areas as layout regions,
- reusable body regions that reserve space deterministically.

### 2. Header and footer are not real regions yet

`lib/rendro/document.ex` exposes:
- `content`
- `header`
- `footer`

`Paginate.apply_page_template/4` prepends/appends header/footer blocks after pagination. This is useful for simple repetition, but it does not define:
- region geometry,
- reserved vertical space,
- anchoring semantics,
- region-specific overflow behavior.

Phase 18 should convert these into explicit page-template regions so later phases can reason about body width, repeated content, and break semantics without more ad hoc rules.

### 3. Fixed-position fit validation is currently incomplete

For fixed documents, `Paginate.run/1` returns `{:ok, doc}` immediately when `pages != []`. That means blocks with explicit `x/y/width/height` coordinates can exceed the declared page bounds without a committed failure path. This directly conflicts with LAY-11's truthful-fit requirement.

The fit check should happen before render, ideally in pagination or a dedicated geometry-validation pass that still returns a stage-specific `%Rendro.Error{}` with deterministic metadata.

## Recommended Data Contract

### New public structs

- `Rendro.PageTemplate`
  - owns page geometry (`width`, `height`, margins)
  - owns named regions (`header`, `body`, `footer`, optional custom regions)
- `Rendro.Region`
  - owns a bounded rectangle and an anchoring role
  - distinguishes `:fixed` from `:flow` semantics
- `Rendro.Section`
  - groups reusable content to target a named region or region sequence
  - lets flow authoring stop depending on raw page coordinates

### Document normalization target

Keep two public APIs, one engine:

- fixed API continues to accept authored pages and fixed blocks
- flow API accepts content/sections against an explicit page template

Both should normalize into one document shape before measure/paginate. That preserves the architecture boundary stated in `AGENTS.md` and avoids building a second render path for regions.

## Recommended File Targets

### Likely source files

- `lib/rendro/document.ex`
- `lib/rendro/page.ex`
- `lib/rendro.ex`
- `lib/rendro/page_template.ex`
- `lib/rendro/region.ex`
- `lib/rendro/section.ex`
- `lib/rendro/pipeline/compose.ex`
- `lib/rendro/pipeline/measure.ex`
- `lib/rendro/pipeline/paginate.ex`
- `lib/rendro/error.ex`

### Likely proof files

- `test/rendro/document_test.exs`
- `test/rendro/page_test.exs`
- `test/rendro/flow_test.exs`
- `test/rendro/pipeline/compose_test.exs`
- `test/rendro/pipeline/measure_test.exs`
- `test/rendro/pipeline/paginate_test.exs`
- `test/rendro_builders_test.exs`

## Architecture Patterns To Preserve

### Pattern 1: Pure data builders

`Rendro.document/1`, `Rendro.page/1`, and related builders currently return plain structs via `struct!`. Phase 18 should preserve:
- pure struct construction,
- unknown-key rejection,
- deterministic defaults.

That makes `PageTemplate`, `Region`, and `Section` natural additions.

### Pattern 2: Normalize first, paginate later

`Compose` already handles tree normalization and `Paginate` handles page assignment. Region/template expansion belongs in those same stages rather than being deferred to render.

### Pattern 3: Deterministic geometry over heuristic clipping

Overflow behavior should remain explicit and testable. Rendro should reject impossible layouts with stable structured errors, not silently clip or auto-shrink content.

## Common Pitfalls

### Pitfall 1: Letting new layout fields bypass the core engine

If sections or regions are handled in a separate rendering branch, later text/table work will have to duplicate pagination logic. Avoid this by normalizing sections/regions into the same internal page/block pipeline.

### Pitfall 2: Treating headers and footers as magic offsets instead of regions

The current reserved-height math in `paginate_flow/1` is a useful starting point, but it is not a durable public contract. Region rectangles and anchoring rules should become explicit data, not implicit arithmetic.

### Pitfall 3: Keeping fixed-page overflow as a render-time surprise

If fit validation remains late or absent, Phase 18 will ship a layout contract that still lies about bounds. Fixed-position and region-authored overflow both need deterministic pre-render failure semantics.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/document_test.exs test/rendro/page_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro_builders_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LAY-07 | Flow docs accept explicit page templates with anchored header/footer regions. | unit | `mix test test/rendro/document_test.exs test/rendro/page_test.exs test/rendro_builders_test.exs test/rendro/flow_test.exs` | ✅ Wave 0 |
| LAY-08 | Sections/regions normalize into the existing compose/paginate path without raw coordinate authoring. | unit | `mix test test/rendro/pipeline/compose_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |
| LAY-11 | Fixed-position and bounded-region overflow returns deterministic structured errors. | unit | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | ✅ Wave 0 |

### Sampling Rate

- Per task commit: run the smallest affected ExUnit subset.
- Per plan completion: run the full layout-focused subset listed above.
- Phase gate: full `mix test` must pass before execution is considered complete.

### Wave 0 Gaps

- None. Existing ExUnit coverage is already organized around the same modules that Phase 18 needs to change.

## Recommended Plan Boundaries

### Plan 01
Public layout data model and builders.

### Plan 02
Pipeline normalization for template-backed sections and anchored regions.

### Plan 03
Truthful fit validation and regression proofs.

## Metadata

**Confidence breakdown:**
- Current-state analysis: HIGH - verified directly from `Document`, `Page`, `Compose`, and `Paginate`.
- Proposed seams: HIGH - align with existing pure-data and single-engine architecture.
- Validation coverage: HIGH - existing test files already map to the affected modules.

**Research date:** 2026-04-28
**Valid until:** 2026-05-28

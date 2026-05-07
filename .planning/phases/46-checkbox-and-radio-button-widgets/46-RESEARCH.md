# Phase 46: Checkbox and Radio Button Widgets - Research

**Researched:** 2026-05-05
**Domain:** PDF AcroForm button widgets, Rendro layout pipeline, deterministic PDF serialization
**Confidence:** HIGH

## Summary

Phase 46 should extend the Phase 45 AcroForm text-field foundation into `/Btn` widgets: standalone checkboxes and grouped radio buttons. The local codebase already has the right seams:

- `Rendro.form_field/3` is the public authored widget boundary.
- `Rendro.FormField` is the domain carrier for widget data.
- `Rendro.Pipeline.Measure` already gives form-field blocks deterministic fallback geometry.
- `Rendro.PDF.Writer` already collects form fields, allocates widget/appearance objects, and injects `/AcroForm`, `/Annots`, and normal appearance streams.

The main delta is not a new pipeline. It is a richer form-field contract plus button-specific writer behavior. Checkboxes can remain single widget-field objects. Radio buttons should serialize as one parent button field with child widget annotations so mutual exclusion is encoded structurally rather than inferred by viewers from document order.

**Primary recommendation:** Split the phase into two plans:
1. Extend the public/domain/validation surface to model `:checkbox` and `:radio` safely.
2. Extend the writer to emit `/FT /Btn` widgets, deterministic on/off appearance dictionaries, and grouped radio parent-child objects with explicit export values.

<user_constraints>
## User Constraints (from Phase Context)

### Locked Decisions
- Reuse `Rendro.form_field` rather than inventing a second widget DSL.
- Keep radio membership explicit through authored group/value data.
- Generate deterministic appearance streams for checked and unchecked states.
- Scope only checkboxes and radio buttons in this phase.
- Keep the core pure Elixir and reuse the existing pipeline.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| DSL / Public API | `Rendro` | `Rendro.FormField` | Extend one existing authoring surface instead of creating parallel builders. |
| Domain model | `Rendro.FormField` | validation rules | Field type, checked state, group, and export semantics belong in one data carrier. |
| Validation | `Rendro.Rules.CheckFormFields` | `Rendro.Pipeline.Validate` | Type-specific invariants and contradictory radio defaults should fail before render. |
| Layout | `Rendro.Pipeline.Measure` | existing block geometry | Button widgets only need deterministic box sizing, not a new measurement engine. |
| PDF serialization | `Rendro.PDF.Writer` | page annotation helpers | Writer already owns object allocation, annotation placement, and appearance streams. |

## Recommended Modeling

### Checkbox
- `type: :checkbox`
- `checked: boolean()` default `false`
- `export_value: "Yes"` default unless explicitly overridden
- Serialized as a standalone `/FT /Btn` widget

### Radio
- `type: :radio`
- `group: String.t()` required
- `export_value: String.t()` required
- `checked: boolean()` default `false`
- Serialized as a parent `/FT /Btn` field with radio flag set and child widget annotations

## Architecture Patterns

### Pattern 1: Extend, Don’t Fork, `Rendro.FormField`
Keep one struct that can represent multiple widget kinds rather than creating separate checkbox/radio structs. The current codebase already routes author intent through `Rendro.form_field/3` and `%Rendro.FormField{}`.

### Pattern 2: Writer Allocation Expands by Logical Widget Family
Current writer allocation is one widget object + one appearance object per field. Phase 46 should preserve that deterministic allocation style while adding:
- checkbox on/off appearance objects
- radio parent field objects per group
- child widget annotations per radio option

### Pattern 3: Group Radio Semantics Before Serialization
Do not attempt to infer radio groups inside low-level dictionary assembly. Group allocations earlier so the page-builder and `/AcroForm` field tree consume explicit, deterministic data.

## Don’t Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Widget API surface | New checkbox/radio DSL unrelated to `form_field/3` | Extend `Rendro.form_field/3` | Phase 45 already established the public boundary. |
| Viewer-driven appearance | `/NeedAppearances` or missing button APs | Deterministic `/AP` dictionaries | Keeps behavior aligned with Rendro’s non-viewer-dependent rule. |
| Radio grouping by layout adjacency | “same page + same area” inference | Explicit `group` and `export_value` fields | Mutual exclusivity must be authored and testable. |
| Contradictory defaults | Let writer silently pick one checked radio | Validate document-level group state | Contradictory authored state is a structural error. |

## Common Pitfalls

### Pitfall 1: Treating Radio Buttons as Independent Checkboxes
**What goes wrong:** Viewers allow multiple “radio” widgets in the same authored group to remain selected simultaneously.
**How to avoid:** Model grouped radios explicitly and serialize parent/child field relationships or equivalent shared field identity with radio flags.

### Pitfall 2: Missing `/AS` and `/AP` State Alignment
**What goes wrong:** A widget opens visually unchecked even though its logical value is set, or vice versa.
**How to avoid:** Keep the logical value (`/V`) and appearance state (`/AS`) in the same allocation path and test both checked and unchecked outputs.

### Pitfall 3: Reusing Text-Field Appearance Helpers Verbatim
**What goes wrong:** Checkbox and radio widgets emit text-field borders/content streams that are structurally valid but visually wrong or functionally inert.
**How to avoid:** Create button-specific appearance helpers while preserving the current object/stream helper pattern.

### Pitfall 4: Validating Only Node-Local Shape
**What goes wrong:** Two radio widgets in the same group both set `checked: true` and pass validation because each node is locally valid.
**How to avoid:** Add document-level validation pass logic inside the existing rule to inspect group-wide defaults.

## Codebase Facts

- `lib/rendro/form_field.ex` currently only models `name`, `value`, `font`, and `size`.
- `lib/rendro/rules/check_form_fields.ex` currently only checks that `name` is a non-empty binary.
- `lib/rendro/pipeline/measure.ex` already assigns fallback `150.0 x 20.0` sizing for form-field blocks.
- `lib/rendro/pdf/writer.ex` already:
  - collects form-field blocks from pages and tables
  - allocates widget + appearance object numbers
  - emits `/AcroForm` and page `/Annots`
  - builds text-field widget annotations and normal appearance streams

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Text-only interactive widgets | Button widgets built on same AcroForm path | Broadens forms support without widening product boundary beyond core widgets. |

## Open Questions (RESOLVED)

1. **Radio grouping shape**
   - Recommendation: use one parent field per authored radio group with child widget annotations. This best encodes exclusivity while staying deterministic.

2. **Checkbox export value**
   - Recommendation: default to `"Yes"` for compatibility, but keep it authored/overridable so the writer never invents hidden semantic values later.

## Validation Architecture

### Test Framework
- ExUnit unit tests for rules and builder behavior
- Existing writer tests in `test/rendro/pdf/writer_test.exs`
- Small targeted integration tests rather than new external tooling

### Phase Requirements → Test Map
- Checkbox/radio authored shape -> `test/rendro/rules/check_form_fields_test.exs`, `test/rendro_builders_test.exs`
- Button field serialization -> `test/rendro/pdf/writer_test.exs`
- Page-local annotation placement -> `test/rendro/pdf/writer_test.exs`

## RESEARCH COMPLETE

### Key Findings
- The codebase already has the exact extension seams needed for button widgets.
- Validation must expand from node-local to document-aware checks for radio defaults.
- Writer work should preserve current deterministic allocation style while adding parent-group modeling for radios.

### Ready for Planning
Yes. Phase 46 is narrow, code-grounded, and naturally decomposes into two executable plans.

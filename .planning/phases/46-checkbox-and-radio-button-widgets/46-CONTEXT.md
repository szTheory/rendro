# Phase 46 Context: Checkbox and Radio Button Widgets

## Project Description
This phase extends Rendro's AcroForm foundation beyond text inputs by adding interactive checkbox and radio button widgets. It reuses the Phase 45 field/annotation infrastructure so developers can author boolean and mutually-exclusive choice fields directly in the Rendro DSL without leaving the deterministic core pipeline.

## Why This Phase
Phase 45 established the document-level AcroForm catalog, widget serialization, and deterministic appearance strategy for text fields. The next highest-value slice is button widgets because they cover common contract, approval, and survey workflows while staying within the same AcroForm infrastructure. This phase should deepen the forms surface without widening into signatures, external PDF filling, or viewer-managed rendering.

## User-Visible Outcome
Developers can author checkboxes and radio groups in Rendro templates and obtain PDFs where:
- Checkboxes can be toggled by end users in standard viewers.
- Radio buttons enforce one-of-many selection semantics within a group.
- Default checked states are visible immediately on open without relying on viewer-generated appearances.

## Completion Class
Contract / Integrated Acceptance. The engine must emit valid AcroForm button field dictionaries, widget annotations, and deterministic checked/unchecked appearances that align with authored layout geometry.

## Final Integrated Acceptance
1. A developer can generate a PDF containing one or more checkboxes and at least one radio group.
2. The generated PDF opens successfully in standard viewers and displays the default selection state immediately.
3. Checkboxes toggle correctly and radio buttons behave as a mutually exclusive group.
4. Widget placement respects authored block geometry and flow pagination.

## Architectural Decisions
### 1. Reuse the Existing `Rendro.form_field` Surface
**Decision:** Extend the existing `Rendro.form_field` DSL to support `type: :checkbox` and `type: :radio` rather than introducing a second widget API.
**Rationale:** Phase 45 already established `Rendro.form_field` as the explicit authored boundary for interactive widgets. Reusing it preserves one public abstraction for AcroForm widgets and keeps validation centralized.
**Alternatives Considered:** Separate `checkbox/2` and `radio_group/2` APIs; a dedicated `Rendro.Form.ButtonField` builder layer.

### 2. Keep Radio Membership Explicit
**Decision:** Radio widgets must carry an explicit group name and authored option value so grouping is deterministic and validation can reject incomplete definitions.
**Rationale:** Radio exclusivity is defined by field identity and export values in PDF. Making grouping explicit avoids hidden coupling based on document order or layout adjacency.
**Alternatives Considered:** Auto-group by region or adjacency; infer group identity from labels.

### 3. Deterministic Appearance Streams for Both States
**Decision:** Rendro will generate checked and unchecked normal appearances itself for checkbox and radio widgets.
**Rationale:** Phase 45 already rejected `NeedAppearances` as a viewer-dependent path. Button widgets must follow the same deterministic rule or the forms story becomes inconsistent across field types.
**Alternatives Considered:** Let viewers synthesize button appearances; only generate checked state.

### 4. Scope Only Core Button Widgets
**Decision:** Phase 46 covers checkboxes and radio buttons only.
**Rationale:** They build directly on the existing widget pipeline while keeping scope tight. Push buttons, combo boxes, list boxes, and signatures stay deferred.
**Alternatives Considered:** Include all `/Btn` subtypes and choice widgets in one phase.

## Error Handling Strategy
- Missing checkbox or radio names must raise structured validation errors before render.
- Radio widgets missing a group identifier or export value must raise structured validation errors.
- Invalid default values, such as multiple checked widgets in one radio group for the same logical field, must fail deterministically in validation rather than render a contradictory PDF.

## Risks and Unknowns
- **Viewer Appearance Differences:** The precise visual styling of check marks and radio dots can vary across viewers even when the widget remains functionally valid.
- **Field Tree Modeling:** Radio groups may require parent/child field structure or shared naming semantics in the writer; the implementation must stay deterministic and testable.
- **Pagination Edge Cases:** Widgets spanning flow layouts and nested containers must retain correct page-local annotation mapping.

## Existing Codebase / Prior Art
- `lib/rendro/form_field.ex` defines the existing widget data carrier introduced in Phase 45.
- `lib/rendro/pdf/writer.ex` already allocates form field objects, page annotations, and appearance streams for text fields.
- `test/rendro/pdf/writer_test.exs` contains the strongest existing analog for widget serialization coverage.

## Relevant Requirements
- Milestone v1.8 Interactive PDF Forms.
- Preserve pure-Elixir core and deterministic rendering guarantees.
- Treat documentation and support claims as contracts backed by tests.

## Scope
**In Scope:**
- Checkbox widgets with default checked/unchecked states.
- Radio button widgets with explicit group identity and authored option values.
- Validation rules covering missing group/value semantics and contradictory defaults.
- PDF writer updates for button field dictionaries, widget annotations, and deterministic appearances.
- Integration tests proving widgets survive the normal pipeline and land on the correct pages.

**Out of Scope:**
- Signatures, push buttons, dropdowns, list boxes, and JavaScript actions.
- Filling or modifying external PDFs.
- Broad cross-viewer styling guarantees beyond functional correctness and immediate visible default state.

## Technical Constraints
- Keep the core pure Elixir with no new hard dependency on viewer tooling.
- Reuse the existing field allocation and page annotation pipeline instead of introducing a parallel render path.
- Preserve deterministic output for identical inputs, including default widget state and object allocation order.

## Integration Points
- Extends the existing `Rendro.form_field` authored widget path from Phase 45.
- Reuses `Rendro.Pipeline.Validate`, `Rendro.Pipeline.Measure`, and `Rendro.PDF.Writer`.

## Testing Requirements
- Unit tests for validation of checkbox/radio authored data.
- Writer tests asserting `/FT /Btn`, checkbox/radio state dictionaries, export values, and grouped radio serialization.
- Integration tests verifying widget geometry and page annotation placement in rendered PDFs.

## Acceptance Criteria
- [ ] `Rendro.form_field(type: :checkbox, ...)` and `Rendro.form_field(type: :radio, ...)` compile into valid internal structures.
- [ ] Rendered PDFs emit valid button-field widgets with deterministic default appearances.
- [ ] Radio groups enforce explicit grouping and deterministic default selection semantics.
- [ ] Tests prove widget placement and serialized AcroForm structures for checkboxes and radios.

## Resolved Questions
- Radio groups serialize as one parent field with widget kids. This preserves explicit mutual-exclusion semantics in the AcroForm tree, keeps allocation deterministic, and matches the Phase 46 writer implementation and tests.

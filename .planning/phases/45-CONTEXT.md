# Phase 45 Context: Interactive Forms (AcroForm) Text Fields

## Project Description
This phase implements the foundational PDF AcroForm dictionary and interactive Text Fields within Rendro. It introduces a new `Rendro.form_field` block DSL, empowering developers to generate new PDFs with pre-filled, interactive form elements directly from Elixir data without relying on a browser renderer.

## Why This Milestone
Rendro currently supports rendering static documents (invoices, reports). Milestone 4 expands Rendro into interactive documents. Phase 45 provides the first slice of this by enabling text fields, which unlocks use cases where end-users need to edit or sign generated PDFs after downloading them.

## User-Visible Outcome
Developers can use `Rendro.form_field(type: :text, name: "first_name", value: "Jon")` in their layout DSL. The resulting PDF will contain a clickable, editable text field pre-filled with "Jon".

## Completion Class
Contract / Integrated Acceptance. This requires modifying the core PDF object writer and rendering pipelines to emit valid AcroForm catalogs and Widget annotations.

## Final Integrated Acceptance
1. A developer generates a PDF containing multiple `form_field` text inputs with pre-filled values.
2. The generated PDF opens successfully in standard viewers (Acrobat, Preview, Chrome).
3. The fields display the pre-filled values correctly without requiring the viewer to regenerate the Appearance Stream on load.
4. The user can click into the fields, edit the text, and save the PDF.

## Architectural Decisions
### 1. Form Filling Boundary
**Decision:** Rendro will only support generating *new* PDFs with fields pre-filled via our DSL at render time.
**Rationale:** Avoids building a complex PDF parser to modify external files, sticking strictly to Rendro's "generation-first" deterministic mandate.
**Alternatives Considered:** Import existing external PDFs and fill their form fields; Generate empty fillable fields for the end-user to complete manually.

### 2. DSL Representation
**Decision:** Introduce a new explicit block type `Rendro.form_field`.
**Rationale:** Form fields require distinct PDF constructs (Widget annotations and Appearance Streams) that do not neatly map to standard text blocks. A dedicated block type keeps the core text block logic pure.
**Alternatives Considered:** Add a `:form` attribute to existing blocks; Create a separate `Rendro.Form` module for overlays.

### 3. Appearance Streams (AP)
**Decision:** Rendro generates the initial Appearance Stream (AP) itself.
**Rationale:** Setting `NeedAppearances = true` delegates rendering to the PDF viewer, which violates our deterministic layout mandate and causes cross-client visual inconsistencies.
**Alternatives Considered:** Viewer generates AP; User-provided explicit visual block.

### 4. Phase 45 Scope Slicing
**Decision:** Implement the AcroForm foundation and *only* Text fields in Phase 45.
**Rationale:** Generating Appearance Streams for text is complex enough for one phase; deferring checkboxes and radio buttons limits risk and allows shipping the foundation faster.
**Alternatives Considered:** Text, Checkboxes, and Radio Buttons; All Field Types.

### 5. Editing Font (DA String)
**Decision:** Restrict the Default Appearance (DA) font to Standard 14 fonts (e.g., Helvetica).
**Rationale:** Avoids the extreme complexity and file-size bloat of embedding full custom fonts specifically for form editing, while ensuring universal compatibility when the user modifies the text.
**Alternatives Considered:** Embed full custom fonts; Use existing subsetted fonts (which breaks for characters outside the subset).

## Error Handling Strategy
- Form field definitions missing required properties (e.g., `name`) should be caught during the Validate pipeline phase and emit structured Rendro errors.
- If a provided value cannot be shaped into the generated AP stream, the layout engine should emit a clear diagnostic error rather than silently failing.

## Risks and Unknowns
- **Appearance Stream Generation:** Re-implementing text shaping inside an AP stream for form fields could duplicate logic from the main `Rendro.PDF.Writer`. We need to ensure we reuse the existing `Rendro.Text` measurements.
- **Viewer Quirks:** Different PDF viewers handle AcroForm dicts slightly differently. We must test across at least Acrobat, Apple Preview, and Chrome.

## Existing Codebase / Prior Art
- `Rendro.PDF.Writer`: Needs updates to write the `AcroForm` dictionary to the Catalog.
- `Rendro.Page`: Needs updates to attach `Annots` (Widget annotations) to the page dictionary.
- `Rendro.Block`: Will be extended to support the new `form_field` node type.

## Relevant Requirements
- Milestone 4: Core PDF Engine Expansion (Interactive Forms)
- Rendro OSS DNA: Deterministic generation, pure Elixir core.

## Scope
**In Scope:**
- AcroForm document-level dictionary generation.
- `Rendro.form_field` DSL for text inputs.
- Generation of AP streams for text fields.
- Standard 14 font fallback for the DA string.

**Out of Scope:**
- Checkboxes, Radio Buttons, Dropdowns (deferred to future phases).
- Parsing or filling existing external PDF forms.
- Full font embedding for interactive editing.
- Digital Signatures (separate Milestone 4 feature).

## Technical Constraints
- Must remain pure Elixir (no headless Chrome).
- Must emit deterministic byte output for identical inputs to support snapshot testing.

## Integration Points
- Extends the core `rendro` document model. No external adapter integration required for this foundational phase.

## Testing Requirements
- **Unit Tests:** `Rendro.PDF.Writer` unit tests asserting correct AcroForm and Annot dictionary serialization.
- **Integration Tests:** End-to-end pipeline test producing a PDF with a text field, using `poppler` (via `Rendro.Adapters.Poppler` if available) or raw string matching to verify the `/AcroForm` and `/Widget` tags are present in the output artifact.

## Acceptance Criteria
- [ ] `Rendro.form_field(type: :text, ...)` compiles and passes structural validation.
- [ ] A rendered PDF contains an AcroForm dictionary.
- [ ] The generated field has a deterministic AP stream representing its pre-filled value.
- [ ] The field is editable in Acrobat and Preview.

## Open Questions
- None.

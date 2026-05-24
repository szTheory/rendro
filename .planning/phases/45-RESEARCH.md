# Phase 45: PDF AcroForm and Interactive Text Fields - Research

**Researched:** 2024-05-18 (Current Date)
**Domain:** PDF Generation, Layout Pipeline, Elixir DSL
**Confidence:** HIGH

## Summary

This phase introduces interactive PDF Forms (AcroForms) to Rendro, specifically focusing on Text Fields. The implementation spans the user-facing DSL (`Rendro.form_field`), the internal data structures (`Rendro.FormField`, `Rendro.Block`), the layout pipeline (`Rendro.Pipeline.Measure`), and the low-level PDF serialization (`Rendro.PDF.Writer`). 

The PDF specification requires an `/AcroForm` dictionary in the Document Catalog listing all field objects. Each page containing fields must reference them in its `/Annots` array. Text Fields themselves are Widget Annotations that dictate where and how the input is displayed on the page.

**Primary recommendation:** Implement `Rendro.FormField`, update the measurement pipeline to give it a layout box, and do a two-pass collection in `Rendro.PDF.Writer` to gather form fields for the Catalog and their absolute bounding boxes for Page `Annots`. Use `/NeedAppearances true` combined with a Standard 14 font (`/Helvetica`) for the Default Appearance (`/DA`) to offload Appearance Stream (AP) generation to the PDF viewer, or manually construct the `AP` stream using PDF drawing operators.

<user_constraints>
## User Constraints (from Phase Context)

### Locked Decisions
- Implement foundational PDF AcroForm dictionary and interactive Text Fields.
- Introduce a new `Rendro.form_field` block DSL.
- `Rendro.PDF.Writer`: Needs updates to write the `AcroForm` dictionary to the Catalog.
- `Rendro.Page`: Needs updates to attach `Annots` (Widget annotations) to the page dictionary.
- `Rendro.Block`: Will be extended to support the new `form_field` node type.
- Appearance Streams (AP) for text fields, using Standard 14 fonts.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **DSL / Public API** | Client API (`Rendro`) | | Provides `Rendro.form_field/3` to construct the node. |
| **Data Structure** | Domain (`Rendro.FormField`) | `Rendro.Block` | Encapsulates form field data (`name`, `value`, `font_size`). Wraps in a `Block` for layout. |
| **Sizing & Layout** | Pipeline (`Pipeline.Measure`) | | Resolves explicit or default width/height for the `FormField` block so it participates in flow layout. |
| **PDF Serialization** | Writer (`Rendro.PDF.Writer`) | | Writes `/AcroForm` to Catalog. Resolves absolute coordinates (`Rect`) for `/Annots` on pages. Builds Appearance Stream (`AP`). |

## Architecture Patterns

### Recommended Project Structure Additions
```
lib/
├── rendro/
│   ├── form_field.ex       # New: The data structure for a text field
│   └── ...
```

### Pattern 1: Form Field Extraction & Allocation
**What:** Just like fonts and images, Form Fields must be collected from the document tree, assigned PDF object numbers, and written out.
**When to use:** In `Rendro.PDF.Writer.render/2`.
**Example:**
```elixir
defp build_objects(...) do
  # ... existing code ...
  with {:ok, fonts} <- collect_fonts(doc),
       {:ok, images} <- collect_images(doc),
       {:ok, form_fields} <- collect_form_fields(doc) do
    
    {form_field_allocations, next_num} = allocate_form_field_nums(form_fields, next_num)
    # ...
```

### Pattern 2: Absolute Coordinate Resolution for Annotations
**What:** Widget Annotations (Form Fields) require an absolute `Rect` `[llx lly urx ury]` on the PDF page.
**When to use:** While building Page objects in `build_page_objects/8`.
**Example:**
During or before `build_content_stream`, recursively walk the `page.blocks` to calculate the exact `x`, `y` based on `page.margin_left`, `page.margin_top`, and the accumulated offset of parent blocks (like tables).

```elixir
# Same logic used in `render_block` for Images:
x = block.x + ox + page.margin_left
y = page.height - (block.y + oy + block.height) - page.margin_top
w = block.width
h = block.height
rect = {:array, [x, y, x + w, y + h]}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Appearance Streams (AP) | Highly complex AP generation for every field state | Standard 14 font fallback + basic AP | If the user constraints allow, generating a basic `/N` (Normal) Appearance Stream with a Standard 14 font like `/Helvetica` is required. The `Tx` (Text) widget needs an AP containing the value string. |
| Text encoding | Custom ASCII encoding | `Rendro.PDF.Writer.escape_pdf_string/1` | AcroForm values (`/V`) and Default Appearances (`/DA`) must be properly escaped strings. |

## Common Pitfalls

### Pitfall 1: Missing Font Resources in AcroForm
**What goes wrong:** Form fields appear blank when clicked, or PDF viewers show an error.
**Why it happens:** The `/AcroForm` dictionary needs a `/DR` (Default Resources) entry defining the font used in the `/DA` (Default Appearance) string.
**How to avoid:** Ensure the Catalog injects a base Font object (e.g., `Helvetica`) and references it in the `/DR` dictionary of the `/AcroForm`.

### Pitfall 2: Coordinate System Mismatch
**What goes wrong:** Form fields are rendered upside down or at the wrong location.
**Why it happens:** Rendro uses a Top-Left origin for layout (`y = 0` is the top), but PDF uses a Bottom-Left origin (`y = 0` is the bottom).
**How to avoid:** Apply the standard Rendro coordinate transformation: `pdf_y = page.height - (layout_y + block.height) - page.margin_top`.

### Pitfall 3: Annotation Duplication or Missing Annotations
**What goes wrong:** Fields don't work on specific pages.
**Why it happens:** `Annots` must be attached to the specific `Page` dictionary where the field physically resides, not just globally.
**How to avoid:** Group collected `FormField` instances by the page they appear on during `collect_form_fields/1` or when mapping the pages in `build_page_objects/8`.

## Code Examples

### 1. `Rendro.form_field/3` DSL
```elixir
# in lib/rendro.ex
@spec form_field(String.t(), String.t(), keyword()) :: Block.t()
def form_field(name, value \\ "", attrs \\ []) do
  field = struct!(Rendro.FormField, name: name, value: value)
  struct!(Rendro.Block, Keyword.put(attrs, :content, field))
end
```

### 2. Sizing in `Rendro.Pipeline.Measure`
```elixir
# in lib/rendro/pipeline/measure.ex
defp measure_block(
       _doc,
       %Rendro.Block{content: %Rendro.FormField{}} = block,
       _container_width
     ) do
  # Fallback defaults if width/height aren't provided by user
  width = block.width || 150.0
  height = block.height || 20.0
  {:ok, %{block | width: width, height: height}}
end
```

### 3. Constructing the AcroForm Dictionary
```elixir
# in lib/rendro/pdf/writer.ex
acro_form_dict =
  {:dict,
   [
     {"Fields", {:array, field_refs}},
     {"DA", {:string, "/Helv 12 Tf 0 g"}},
     {"DR", {:dict, [{"Font", {:dict, [{"Helv", {:ref, helv_font_obj_num, 0}}]}}]}}
   ]}

catalog_dict =
  {:dict,
   [
     {"Type", {:name, "Catalog"}},
     {"Pages", {:ref, pages_num, 0}},
     {"AcroForm", acro_form_dict}
   ]}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Read-only PDFs | Interactive AcroForms | Phase 45 | Enables user data entry directly within generated PDFs. |

## Open Questions (RESOLVED)

1. **Appearance Stream Sizing:**
   - What we know: An AP stream needs to draw the text accurately inside the Rect.
   - What's unclear: How strictly we need to calculate baseline offsets inside the AP Stream.
   - Recommendation: Use a standard offset (e.g., `font_size` minus a standard descent) to draw the text string `Tj` inside the Widget's bounding box.

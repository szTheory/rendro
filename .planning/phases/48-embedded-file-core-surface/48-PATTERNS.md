---
phase: 48
slug: embedded-file-core-surface
status: ready
created: 2026-05-05
updated: 2026-05-05
---

# Phase 48: Embedded File Core Surface - Pattern Map

**Mapped:** 2026-05-05
**Scope analyzed:** document-owned registries, validation pipeline, PDF writer allocation/serialization, deterministic object ordering

## Reusable Patterns

### 1. New authored assets should live in a document-owned registry

**Primary analogs:** `lib/rendro/document.ex`, `lib/rendro/asset_registry.ex`, `lib/rendro/font_registry.ex`

- `lib/rendro/document.ex` owns registries directly on `%Rendro.Document{}` and exposes thin wrapper functions.
- `lib/rendro/asset_registry.ex` normalizes `{:path, path}` and `{:binary, bytes}` inputs into pure data immediately.
- `lib/rendro/font_registry.ex` shows the broader pattern for typed descriptors and eager normalization before render.

**Implication for Phase 48**

- Add a dedicated embedded-file registry on the document rather than hiding file descriptors inside metadata.
- Keep the public API as a thin wrapper over registry registration, matching fonts and images.

### 2. Validation should stay tuple-based and pipeline-aggregated

**Primary analogs:** `lib/rendro/pipeline/validate.ex`, `lib/rendro/rules/check_form_fields.ex`, `test/rendro/pipeline/validate_test.exs`

- `Rendro.Pipeline.Validate` already provides one traversal plus one `%Rendro.Error{details: %{errors: ...}}` envelope.
- `CheckFormFields` demonstrates document-level and node-level tuple checks without exceptions.
- Existing tests assert both raw tuples and aggregate pipeline failures.

**Implication for Phase 48**

- Add `CheckEmbeddedFiles` to the default validation rule list.
- Keep errors as small tuples that the pipeline can aggregate unchanged.
- Test both the raw rule and `Validate.run/1` aggregation path.

### 3. PDF writer object allocation should extend the existing numbered-object funnel

**Primary analog:** `lib/rendro/pdf/writer.ex`

- `build_objects/4` centrally allocates catalog, pages, fonts, images, form fields, and info objects.
- `allocate_*_nums` helpers isolate object-number planning from object serialization.
- `build_*_objects` helpers keep serialization logic grouped by surface.

**Implication for Phase 48**

- Add `allocate_embedded_file_nums/2` and `build_embedded_file_objects/2` rather than inlining file-spec allocation inside `build_objects/4`.
- Thread the resulting allocations into catalog construction the same way forms are threaded into `maybe_add_acro_form_entry/2`.

### 4. Conditional catalog injection already has a clean precedent

**Primary analog:** `maybe_add_acro_form_entry/2` in `lib/rendro/pdf/writer.ex`

- The catalog dictionary is built from a base `Type/Pages` pair and conditionally widened only when the document actually needs an extra catalog surface.

**Implication for Phase 48**

- Add a helper such as `maybe_add_embedded_files_entries/2` or a combined catalog helper that injects `/Names` and `/AF` only when embedded files exist.
- Keep empty documents free of embedded-file catalog noise.

### 5. Deterministic resource ordering is already an explicit product behavior

**Primary analogs:** `collect_fonts/1`, `collect_images/1`, `Rendro.PDF.Object.serialize/2`

- Collected resources are sorted before serialization.
- `Rendro.PDF.Object.serialize/2` sorts dictionary keys in deterministic mode.
- Writer tests already treat stable PDF content as contract.

**Implication for Phase 48**

- Registry enumeration must sort embedded files by a stable key before allocation.
- Names-tree arrays and `/AF` references must preserve that ordering.
- Any timestamps auto-generated at render time would violate this pattern and must be avoided.

### 6. Name escaping already exists for PDF names

**Primary analog:** `encode_pdf_name/1` in `lib/rendro/pdf/writer.ex`

- The writer already percent-escapes unsafe characters for PDF names using `#XX` encoding.

**Implication for Phase 48**

- Reuse this helper, or extract it narrowly, for embedded-file MIME subtype names if `/Subtype` is emitted as a PDF name.
- Do not invent a second escaping implementation.

## Candidate File Targets

| File | Role | Best analog | Notes |
|------|------|-------------|-------|
| `lib/rendro/embedded_file_registry.ex` | new registry | `lib/rendro/asset_registry.ex` | Best fit for source normalization and explicit authored metadata storage. |
| `lib/rendro/document.ex` | document surface | `register_image/3`, `register_embedded_font/3` | Add new registry field and wrapper. |
| `lib/rendro.ex` | public API wrapper | `register_image/3`, `register_embedded_font/3` | Keep one narrow public entry point. |
| `lib/rendro/rules/check_embedded_files.ex` | validation rule | `lib/rendro/rules/check_form_fields.ex` | Document-level authored invariant checks. |
| `lib/rendro/pipeline/validate.ex` | rule wiring | current `@default_rules` | Add the new rule without changing traversal. |
| `lib/rendro/pdf/writer.ex` | writer allocation and serialization | current image/form-field allocation helpers | Main implementation seam for `/Names`, `/EmbeddedFiles`, `/Filespec`, `/AF`. |
| `test/rendro/embedded_file_registry_test.exs` | registry contract | `test/rendro/asset_registry_test.exs` | New focused coverage. |
| `test/rendro/document_test.exs` | builder wrapper proof | existing document builder tests | Verify registry ownership and purity. |
| `test/rendro_builders_test.exs` | public API proof | existing font/image builder tests | Keep top-level `Rendro.*` coverage. |
| `test/rendro/rules/check_embedded_files_test.exs` | raw tuple validation | `test/rendro/rules/check_form_fields_test.exs` | Assert exact failure tuples. |
| `test/rendro/pipeline/validate_test.exs` | aggregate validation | existing validate tests | Assert `details.errors` contains embedded-file tuples. |
| `test/rendro/pdf/writer_test.exs` | structural PDF proof | existing catalog/form/image assertions | Best place for names-tree and file-spec substring checks. |

## File-Level Planning Notes

### Registry shape

Follow the small-map descriptor pattern from `AssetRegistry`:

- keep bytes and explicit metadata together
- avoid runtime file I/O during writer execution
- keep fetch/read APIs narrow

### Validation split

Embedded-file rules are document-wide, not block-local. That means the rule module should mostly inspect `%Rendro.Document{}` directly instead of adding node clauses for unrelated structs.

### Writer split

The writer already separates allocation, object-building, and catalog wiring. Phase 48 should preserve that decomposition so later Phase 49 link annotation work can extend the same writer without colliding with attachment logic.

---
phase: 49
slug: curated-link-annotation-surface
status: ready
created: 2026-05-05
updated: 2026-05-05
---

# Phase 49: Curated Link Annotation Surface - Pattern Map

**Mapped:** 2026-05-05
**Scope analyzed:** explicit link node authoring, validate-stage policy enforcement, block-owned measurement/fragmentation, and `/Annots` writer reuse

## Reusable Patterns

### 1. Interactive authored surfaces stay explicit and block-local

**Primary analogs:** `lib/rendro.ex`, `lib/rendro/form_field.ex`, `lib/rendro/block.ex`

- `Rendro.form_field/3` establishes the precedent that interactive PDF constructs should be explicit authored nodes rather than hidden attrs.
- `%Rendro.Block{}` owns geometry and remains the correct outer carrier for measured width/height and pagination flags.

**Implication for Phase 49**

- Model links as `%Rendro.Block{content: %Rendro.Link{content: inner, target: target}}`.
- Reject shapes that blur interactive semantics, including links wrapping `%Rendro.FormField{}`.

### 2. Validation belongs in the default rule pipeline, not the writer

**Primary analogs:** `lib/rendro/pipeline/validate.ex`, `lib/rendro/rules/check_form_fields.ex`, `test/rendro/pipeline/validate_test.exs`

- Existing rules return typed tuples and are aggregated by `Rendro.Pipeline.Validate`.
- Form-related validation already proves the repo prefers authored-boundary rejection over best-effort serialization.

**Implication for Phase 49**

- Add `CheckLinks` to the default rules.
- Lock exact tuple coverage for unsupported schemes, malformed URIs, out-of-range pages, and `%Rendro.FormField{}`-wrapped links.

### 3. Writer changes must extend the existing `/Annots` seam and preserve normal rendering

**Primary analogs:** `lib/rendro/pdf/writer.ex`, Phase 48 `48-PATTERNS.md`

- The writer already centralizes page object allocation and conditional `/Annots` injection.
- New annotation surfaces should thread through that seam instead of creating a parallel render path.

**Implication for Phase 49**

- Collect link annotations alongside existing page annotation data.
- Delegate `%Rendro.Link{content: inner}` back into the existing render path for `inner` so visible linked text/table content still renders unchanged while separate `/Link` annotations are emitted.
- Prove both annotation structure and content-render continuity in `test/rendro/pdf/writer_test.exs`.

## Candidate File Targets

| File | Role | Best analog | Notes |
|------|------|-------------|-------|
| `lib/rendro/link.ex` | explicit link node | `lib/rendro/form_field.ex` | New authored content wrapper with narrow target variants. |
| `lib/rendro/rules/check_links.ex` | validation rule | `lib/rendro/rules/check_form_fields.ex` | Exact tuple policy enforcement, including FormField rejection. |
| `lib/rendro/pipeline/measure.ex` | measurement seam | existing `measure_block/3` clauses | Recurse into wrapped content and keep geometry on outer block. |
| `lib/rendro/fragmentable.ex` | fragmentation seam | existing block/text/table implementations | Rewrap both fragments with the same validated target. |
| `lib/rendro/pdf/writer.ex` | annotation + render seam | existing widget `/Annots` path | Add narrow link annotation support without dropping visible content rendering. |
| `test/rendro/pdf/writer_test.exs` | structural proof | existing writer assertions | Must prove both `/Link` output and render-path delegation. |

# Phase 99: Cross-References & Validation Research

## Context
Phase 97 introduced explicit location tracking, capturing block coordinates and accumulating them into `doc.metadata.anchors` as `%{id => [page_idx, :XYZ, x, y, nil]}` during the `paginate` phase.

This phase (Phase 99) consumes those anchors to build physical PDF destinations for internal links.

## Current Architecture
- `Rendro.Link` represents an authored link. It currently supports `target: {:uri, uri}` and `target: {:page, page_number}`.
- `Rendro.link/2` builds links using `uri: "..."` or `page: N` keyword options.
- The pipeline executes: `build -> compose -> measure -> paginate -> validate -> render`.
  - `paginate` populates `doc.metadata.anchors`.
  - `validate` executes `Rendro.Rules.CheckLinks`, which validates URLs and page bounds. Since `validate` runs *after* `paginate`, `doc.metadata.anchors` is fully populated when validation occurs.
- `Rendro.PDF.Writer.render/2` serializes links into PDF annotations. It delegates to `build_link_annotation_objects`, which currently maps `{:page, N}` to `[/Fit]`.

## Implementation Strategy

### 1. Primitive & Validation (XREF-01, XREF-02)
- Add `{:anchor, String.t()}` to `Rendro.Link.target` typespec.
- Add `anchor: id` keyword support to `Rendro.link/2`.
- Update `Rendro.Rules.CheckLinks` to match `{:anchor, id}`. If `doc.metadata.anchors[id]` exists, return `:ok`. Otherwise, return `{:error, {:missing_anchor, id}}`.
- This ensures fail-fast developer feedback (Errors as Product) when linking to non-existent sections.

### 2. PDF Serialization (XREF-03)
- In `Rendro.PDF.Writer.build_page_objects`, pass `doc` down into `build_link_annotation_objects` and `build_link_annotation_object`.
- Add a clause for `build_link_annotation_object(obj_num, rect, {:anchor, id}, page_obj_nums, doc, opts)`.
- Extract `[page_idx, :XYZ, x, y, _nil]` from `doc.metadata.anchors[id]`.
- Map `page_idx` to the target page's object reference using `Enum.at(page_obj_nums, page_idx)`.
- Construct the `Dest` array: `{:array, [{:ref, target_page_obj_num, 0}, {:name, "XYZ"}, x, y, nil]}`.
- Because Elixir's `nil` serializes to `"null"` in `Rendro.PDF.Object`, this directly formats to a valid PDF `/XYZ` destination.

## Constraints & Rules
- Do not modify pagination or layout. Anchors are already accumulated correctly.
- Do not try to eagerly validate anchors before the `validate` phase (e.g. during `build`). Anchors aren't positioned until `paginate`.
- Continue adhering to deterministic generation.

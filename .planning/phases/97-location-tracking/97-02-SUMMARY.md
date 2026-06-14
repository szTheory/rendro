# Phase 97-02: Accumulation & Fragments

## Changes Made
- **Fragment ID Isolation**: Updated `Rendro.Fragmentable.split/2` for `Rendro.Block` to explicitly set `id: nil` on trailing block fragments, preventing artificial duplicate ID errors across multi-page blocks.
- **Anchor Accumulation**: Updated `run/1` in `Rendro.Pipeline.Paginate` to collect block coordinates recursively.
  - Implemented `collect_anchors/1` to aggregate `%{id => [page_idx, :XYZ, x, y, nil]}` into `paginated_doc.metadata.anchors`.
  - Added support to traverse nested elements (e.g. `Rendro.Table` headers and rows) correctly.
  - Handled `:duplicate_anchor_id` throwing and formatted it into a `Rendro.Error`.
- **Validation**: Added specific XYZ anchor accumulation mapping tests and nested flow directives logic inside `test/rendro/pipeline/paginate_test.exs`.
- **Docs Contract Update**: Updated `adoption_claims_test.exs` to reflect the progression of the `ROADMAP.md` beyond v2.7.

## Deviations
- N/A

## Status
- **Success**: XYZ anchors correctly populated in document metadata. Pagination handles duplicate IDs safely without layout oscillation.
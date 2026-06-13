# Architecture Research — v2.7 Page Context & Browser Proof Hardening

**Researched:** 2026-06-13
**Confidence:** HIGH for pipeline integration points; implementation still needs exact code mapping during Phase 89/90 execution.

## Page Context Architecture

Rendro should keep one pipeline:

`build -> compose -> measure -> paginate -> render -> validate`

Page context belongs after pagination, before running-region content is finalized, because only pagination knows physical page count and section page ranges.

Recommended internal data shape:

```elixir
%{
  physical_page: pos_integer(),
  total_pages: pos_integer(),
  section_page: pos_integer() | nil,
  section_total_pages: pos_integer() | nil
}
```

Do not expose this as a public struct in v2.7. Tokens and section options are the stable public contract.

## Section Restart

Implementation should mark the first block of a restarting body section as a hard page break boundary or use an internal pagination marker that is removed before rendering. The output contract is:

- If the section does not start on the current empty page, add a page break.
- The first rendered content of the section appears on the new physical page.
- Section total is computed from the physical range `[start_page, next_section_start - 1]`.

This preserves deterministic single-pass layout while avoiding multi-pass document reflow.

## Token Substitution

Extend the existing PAGE token replacement site. Existing tokens remain:

- `{{page_number}}`
- `{{total_pages}}`

New tokens:

- `{{section_page_number}}`
- `{{section_total_pages}}`

The replacement must happen only in curated running content / PAGE primitive paths, not arbitrary text substitution across the document.

## Duplex Filtering

`only_on: :odd | :even` is a section-level filter for running/header/footer regions. It should be evaluated against physical page number:

```elixir
odd? = rem(page_number, 2) == 1
```

`suppress_on` remains unchanged and composes with `only_on`. Invalid combinations should be surfaced through validation errors before rendering.

## PDF.js Advisory Lane

PDF.js proof should live outside core runtime:

- Script/mix task under tools/test/support territory.
- `npm` lockfile or exact package pin local to advisory tooling.
- CI job with no `needs:` link to required engine lanes.
- Guardrail metadata listed as advisory, not required.

Observation schema should be small and stable:

```json
{
  "viewer_kind": "pdfjs-dist",
  "renderer": "pdfjs-dist",
  "renderer_version": "...",
  "node_version": "...",
  "fixture": "...",
  "pages": 1,
  "page_dimensions": [{"width": 612, "height": 792}],
  "warnings": [],
  "png_sha256": null
}
```

## Architectural Boundaries

- Core remains pure Elixir.
- Optional proof tooling never becomes a runtime dependency.
- Browser-family observations never promote GUI-viewer support rows automatically.
- Page context is an internal capability used by PAGE/running content, not a general stateful templating engine.

# Phase 90: Duplex Running Content - Context

**Gathered:** 2026-06-13
**Status:** Ready for research
**Source:** Accepted v2.7 milestone plan and Phase 89 implementation outcome

<domain>

## Phase Boundary

Phase 90 adds duplex running-content filtering to Rendro's existing section/template flow. Authors can declare header/footer/running-region sections that render only on physical odd or even pages while preserving existing `suppress_on` behavior and the Phase 89 section-local page-numbering tokens.

This phase is not a public `PageContext` API, not a redesign of running content callbacks, and not a fixed-position body rendering change.

</domain>

<decisions>

## Implementation Decisions

### Additive API
- Extend `Rendro.section/1` through `%Rendro.Section{}` with `only_on: :odd | :even | nil`.
- Preserve current `suppress_on` behavior and naming.
- Preserve `RunningContent` callback shape as `{page, total}`.
- Regenerate `priv/public_api.json` when the public Section type changes.

### Duplex Semantics
- Evaluate `only_on` against physical page parity: page 1 is odd, page 2 is even, and so on.
- Do not evaluate odd/even against section-local page numbers; section restarts must not change duplex parity.
- Compose `only_on` with `suppress_on`: a running-region block appears only when both filters allow the physical page.
- Apply duplex filtering to running regions such as header and footer without changing fixed-position body rendering.

### Validation
- Invalid `only_on` values must fail before rendering misleading output.
- Invalid `page_numbering` options must fail before rendering misleading output.
- Prefer clear `ArgumentError` messages consistent with existing compose/pipeline validation style unless the codebase already exposes a narrower error surface.
- Validation should be central enough that both builder-created documents and manually built structs go through the same checks during the pipeline.

### Architecture Constraints
- Keep core pure Elixir; no Phoenix, Oban, Node, browser, or adapter dependency.
- Prefer existing `build -> compose -> measure -> paginate -> render -> validate` boundaries.
- Do not add hidden metadata fields to `%Rendro.Block{}` for section ownership.
- Preserve Phase 89's compose-entry-to-measured-block re-pairing strategy unless a simpler measured-entry representation proves safer.
- Keep token substitution deterministic and measurement-stable; replacing PAGE tokens must not reflow or remeasure text.

### the agent's Discretion
- Exact internal shape for carrying per-running-region section metadata from compose to paginate.
- Whether validation lives in compose, paginate, builder functions, or a small helper, provided both normal and manual document inputs are covered before rendering.
- Exact test decomposition across builder, compose, paginate, flow, docs-contract, and public API contract tests.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Phase Scope
- `.planning/ROADMAP.md` - Phase 90 deliverables and exit criteria.
- `.planning/REQUIREMENTS.md` - DUP-01, DUP-02, DUP-03 requirement text and milestone boundaries.
- `.planning/PROJECT.md` - v2.7 decisions, scope fences, and lessons from Phase 89.
- `.planning/phases/89-page-context-primitive/89-VERIFICATION.md` - shipped Phase 89 behavior and residual risk.
- `.planning/phases/89-page-context-primitive/89-01-SUMMARY.md` - implementation notes and affected files.

### Runtime Pipeline
- `lib/rendro/section.ex` - public Section struct and type surface.
- `lib/rendro.ex` - `Rendro.section/1` builder entry point.
- `lib/rendro/pipeline/compose.ex` - section normalization and region metadata.
- `lib/rendro/pipeline/paginate.ex` - PAGE substitution, page context, suppression, and template application.
- `lib/rendro/running_content.ex` - existing callback contract.

### Tests And Contracts
- `test/rendro_builders_test.exs` - builder and public struct regression tests.
- `test/rendro/pipeline/compose_test.exs` - normalization and metadata tests.
- `test/rendro/pipeline/paginate_test.exs` - pagination, running content, PAGE token tests.
- `test/rendro/flow_test.exs` - flow API compatibility tests.
- `test/rendro/public_api/manifest_test.exs` - public API manifest regeneration expectations.
- `test/docs_contract/public_api_contract_test.exs` - documentation/public API contract checks.

</canonical_refs>

<specifics>

## Specific Ideas

- Add focused tests for odd/even header and footer variants across a multi-page body.
- Add a regression where a body section restarts numbering on a fresh physical page and running content still follows physical page parity.
- Add validation tests for `only_on: :left`, `only_on: "odd"`, `page_numbering: [restart: false]`, and unknown page-numbering keys if those cases are not already rejected by the builder.
- Keep docs wording narrow until Phase 92; Phase 90 should prove behavior in tests and contracts, not broaden public claims prematurely.

</specifics>

<deferred>

## Deferred Ideas

- Public `%Rendro.PageContext{}` or callback API.
- Recto/verso aliases, locale-aware numbering, Roman numerals, named page styles, blank-page insertion, TOC/outlines/anchors/cross-references.
- Global text shaping and script support.
- PDF.js advisory proof lane, which is Phase 91.

</deferred>

---

*Phase: 90-duplex-running-content*
*Context gathered: 2026-06-13 via accepted milestone plan*

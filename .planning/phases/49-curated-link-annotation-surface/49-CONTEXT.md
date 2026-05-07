# Phase 49: Curated Link Annotation Surface - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the narrowest useful non-form annotation surface through deterministic external-URI and internal-destination links. Reuse the existing page `/Annots` writer seam without exposing a generic annotation escape hatch, generic PDF actions, or a broader authored identity layer.

</domain>

<decisions>
## Implementation Decisions

### Public authoring surface
- **D-01:** Phase 49 should use an explicit curated link builder, not hidden attrs on `Rendro.text/2` or `Rendro.block/2`.
- **D-02:** The recommended public shape is a dedicated `Rendro.link(...)`-style surface that wraps one authored block/content item and attaches a curated target. It should stay explicit in the same way `Rendro.form_field/3` is explicit for interactive PDF constructs.
- **D-03:** Do not expose raw annotation dictionaries, arbitrary PDF actions, or a generic metadata escape hatch for links.
- **D-04:** Do not require callers to hand-maintain overlay rectangles as the primary API. Geometry should come from the wrapped block so measurement and pagination remain authoritative.

### Internal destination contract
- **D-05:** Internal links should target pages only in Phase 49.
- **D-06:** Do not introduce named destinations, inferred anchors, block-level target IDs, or implicit destination derivation from `Section.name`, `Region.name`, text content, or layout adjacency in this phase.
- **D-07:** Page-only destinations are an intentional small-contract choice because the current codebase has no stable generic authored identity seam for rendered content.

### External URI policy
- **D-08:** External links should allow absolute `http` and `https` URIs only in Phase 49.
- **D-09:** Reject `mailto:`, `tel:`, `file:`, custom schemes, relative URLs, scheme-relative URLs, missing hosts, and any URI shape that widens into viewer- or OS-policy-dependent behavior beyond ordinary web navigation.
- **D-10:** External and internal targets should be distinct authored variants, not one overloaded `to` string that guesses intent from input shape.

### Validation and error policy
- **D-11:** Link validation should happen at the authored boundary through the existing validate-stage rule system, not later in writer code.
- **D-12:** Validation should return typed tuples for unsupported schemes, malformed URIs, and unresolved/invalid page destinations instead of silently skipping or normalizing unsupported input.
- **D-13:** Preserve authored URI bytes in output after validation; validate shape, but do not canonicalize or rewrite caller-provided URLs.

### Clickable area semantics
- **D-14:** Clickable areas should be rectangular and derived from paginated block geometry.
- **D-15:** When wrapped content fragments across pages, the renderer should emit one rectangular link annotation per paginated block fragment.
- **D-16:** Do not implement line-accurate, glyph-accurate, or inline-span hit boxes in Phase 49. Those are higher-complexity semantics that would couple the public contract to private measured-text fragmentation details.

### DX and support boundary posture
- **D-17:** Favor one coherent recommendation set over menuizing equivalent options. The phase should intentionally optimize for least-surprise DX, explicit contracts, and truthful support boundaries.
- **D-18:** It is acceptable that page-only destinations are less semantic and that block-fragment rectangles may include some whitespace. Those tradeoffs are preferable to shipping a broader, less truthful, or more fragile API in `v1.9`.

### the agent's Discretion
- Exact public names (`Rendro.link/2`, `%Rendro.Link{}`, or equivalent) as long as the API remains explicit and narrow.
- Exact typed error tuple names.
- Whether the wrapped authored value is represented as a new content struct, a block wrapper, or another explicit internal node, as long as it does not become a hidden attr or raw escape hatch.
- Precise writer object layout for `/Link`, `/A`, `/URI`, and internal destination serialization.

</decisions>

<specifics>
## Specific Ideas

- Prefer explicit builder ergonomics that feel natural in Elixir/Phoenix-style immutable pipelines: callers should compose authored data, not mutate annotations after the fact.
- Preserve the repo pattern established by form fields and embedded files: explicit authored surface, validate-stage semantics, deterministic writer reuse, truthful docs.
- Lessons from adjacent libraries:
- Prawn shows the convenience of inline link authoring, but its link/anchor attrs blur semantics into generic text formatting and rely on the caller to style/understand link behavior.
- ReportLab, HexaPDF, and iText all reinforce that link annotations are fundamentally rectangular page annotations with explicit destinations/actions; Rendro should keep that truth visible instead of pretending links are browser-style inline spans.
- Lower-level libraries like pdf-lib highlight the footgun of broad low-level surfaces where link semantics become easy to lose or hard to reason about.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/milestones/v1.9-ROADMAP.md` — Phase 49 boundary, dependency, and milestone-level annotation constraints.
- `.planning/REQUIREMENTS.md` — `LINK-01` and `LINK-02` requirements plus annotation-related out-of-scope boundaries.
- `.planning/milestones/v1.9-CONTEXT.md` — Milestone-level artifact-surface rationale and trust-boundary framing.

### Project methodology and prior precedent
- `.planning/METHODOLOGY.md` — Truthful small contracts, boundary validation, and least-surprise DX defaults.
- `.planning/phases/45-CONTEXT.md` — Prior decision to use an explicit authored node for interactive PDF constructs instead of hiding behavior inside generic block attrs.
- `.planning/phases/48-embedded-file-core-surface/48-PATTERNS.md` — Recent writer-seam precedent: extend existing allocation/build/catalog seams instead of inventing parallel abstractions.
- `.planning/phases/48-embedded-file-core-surface/48-VERIFICATION.md` — Confirms page `/Annots` remained narrow so Phase 49 can reuse that seam independently.

### Core code seams
- `lib/rendro.ex` — Public builder surface patterns.
- `lib/rendro/block.ex` — Block geometry ownership.
- `lib/rendro/page.ex` — Page structure and current lack of generic destination identity.
- `lib/rendro/pipeline/validate.ex` — Validate-stage rule aggregation contract.
- `lib/rendro/pdf/writer.ex` — Existing `/Annots` seam, widget annotation precedent, and current block-geometry-driven interactive output.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/pdf/writer.ex`: already has page annotation wiring through `/Annots` and rectangle-based widget emission that link annotations can parallel.
- `lib/rendro/pipeline/validate.ex`: existing rule walker is the right place for link boundary validation and typed tuple aggregation.
- `lib/rendro.ex` plus `lib/rendro/document.ex`: public builder APIs already favor explicit, immutable authored transformations.

### Established Patterns
- Explicit authored nodes are preferred over hidden attrs when PDF behavior introduces a distinct product contract.
- Writer extensions should reuse existing allocation/build/page-wiring seams rather than open a second rendering path.
- Validation should reject malformed authored state before render instead of allowing best-effort writer behavior.

### Integration Points
- Link authoring must normalize into the same page/block pipeline that already feeds widget annotation emission.
- Internal page destinations should resolve against final paginated pages, not pre-pagination authored layout concepts.
- Support-boundary wording for URI schemes and destination semantics must stay narrow enough for Phase 50 docs/support-matrix proof closure.

</code_context>

<deferred>
## Deferred Ideas

- Named destinations or anchor IDs for semantic in-document navigation.
- Inline span-level links inside paragraphs.
- `mailto:`, `tel:`, `file:`, and custom URI schemes.
- Generic PDF actions or generic annotation dictionaries.
- Text-accurate or glyph-accurate hit boxes.

</deferred>

---

*Phase: 49-curated-link-annotation-surface*
*Context gathered: 2026-05-05*

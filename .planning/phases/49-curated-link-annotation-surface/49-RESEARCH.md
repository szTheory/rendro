# Phase 49: Curated Link Annotation Surface - Research

**Researched:** 2026-05-05  
**Domain:** Deterministic PDF link annotations in Rendro core  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/49-curated-link-annotation-surface/49-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions
- **D-01:** Phase 49 should use an explicit curated link builder, not hidden attrs on `Rendro.text/2` or `Rendro.block/2`.
- **D-02:** The recommended public shape is a dedicated `Rendro.link(...)`-style surface that wraps one authored block/content item and attaches a curated target. It should stay explicit in the same way `Rendro.form_field/3` is explicit for interactive PDF constructs.
- **D-03:** Do not expose raw annotation dictionaries, arbitrary PDF actions, or a generic metadata escape hatch for links.
- **D-04:** Do not require callers to hand-maintain overlay rectangles as the primary API. Geometry should come from the wrapped block so measurement and pagination remain authoritative.
- **D-05:** Internal links should target pages only in Phase 49.
- **D-06:** Do not introduce named destinations, inferred anchors, block-level target IDs, or implicit destination derivation from `Section.name`, `Region.name`, text content, or layout adjacency in this phase.
- **D-07:** Page-only destinations are an intentional small-contract choice because the current codebase has no stable generic authored identity seam for rendered content.
- **D-08:** External links should allow absolute `http` and `https` URIs only in Phase 49.
- **D-09:** Reject `mailto:`, `tel:`, `file:`, custom schemes, relative URLs, scheme-relative URLs, missing hosts, and any URI shape that widens into viewer- or OS-policy-dependent behavior beyond ordinary web navigation.
- **D-10:** External and internal targets should be distinct authored variants, not one overloaded `to` string that guesses intent from input shape.
- **D-11:** Link validation should happen at the authored boundary through the existing validate-stage rule system, not later in writer code.
- **D-12:** Validation should return typed tuples for unsupported schemes, malformed URIs, and unresolved/invalid page destinations instead of silently skipping or normalizing unsupported input.
- **D-13:** Preserve authored URI bytes in output after validation; validate shape, but do not canonicalize or rewrite caller-provided URLs.
- **D-14:** Clickable areas should be rectangular and derived from paginated block geometry.
- **D-15:** When wrapped content fragments across pages, the renderer should emit one rectangular link annotation per paginated block fragment.
- **D-16:** Do not implement line-accurate, glyph-accurate, or inline-span hit boxes in Phase 49. Those are higher-complexity semantics that would couple the public contract to private measured-text fragmentation details.
- **D-17:** Favor one coherent recommendation set over menuizing equivalent options. The phase should intentionally optimize for least-surprise DX, explicit contracts, and truthful support boundaries.
- **D-18:** It is acceptable that page-only destinations are less semantic and that block-fragment rectangles may include some whitespace. Those tradeoffs are preferable to shipping a broader, less truthful, or more fragile API in `v1.9`.

### Claude's Discretion
- Exact public names (`Rendro.link/2`, `%Rendro.Link{}`, or equivalent) as long as the API remains explicit and narrow.
- Exact typed error tuple names.
- Whether the wrapped authored value is represented as a new content struct, a block wrapper, or another explicit internal node, as long as it does not become a hidden attr or raw escape hatch.
- Precise writer object layout for `/Link`, `/A`, `/URI`, and internal destination serialization.

### Deferred Ideas (OUT OF SCOPE)
- Named destinations or anchor IDs for semantic in-document navigation.
- Inline span-level links inside paragraphs.
- `mailto:`, `tel:`, `file:`, and custom URI schemes.
- Generic PDF actions or generic annotation dictionaries.
- Text-accurate or glyph-accurate hit boxes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LINK-01 | Engineers can author deterministic external-URI link annotations through a curated public API. [VERIFIED: codebase grep] | Use one explicit `Rendro.link/2` builder with a distinct `uri:` target variant, validate with `URI.new/1` plus explicit `http`/`https` and host policy, and serialize each page fragment as one `/Subtype /Link` annotation with inline `/A << /S /URI /URI (...) >>`. [CITED: https://hexdocs.pm/elixir/URI.html] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep] |
| LINK-02 | Engineers can author deterministic internal-destination link annotations for in-document navigation. [VERIFIED: codebase grep] | Use the same `Rendro.link/2` builder with a distinct `page:` target variant, resolve against final paginated pages during validate, and serialize same-document jumps with direct `/Dest [page_ref /Fit]` entries rather than widening into named destinations or generic actions. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 49 should add one explicit `Rendro.link/2` builder that accepts an already-authored `%Rendro.Block{}` and exactly one curated target variant, storing a new `%Rendro.Link{content: inner_content, target: {:uri, uri} | {:page, page_number}}` inside the existing block so block geometry, measurement, and pagination authority remain with `Rendro.Block`. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [CITED: https://hexdocs.pm/elixir/URI.html]

The validate stage is the correct ownership point for all link semantics because the current pipeline order is `build -> compose -> measure -> paginate -> validate -> render`, `Validate.run/1` already aggregates typed tuple failures, and page-only destinations cannot be resolved truthfully until final paginated pages exist. [VERIFIED: codebase grep]

The writer should stay narrow: emit `/Subtype /Link` annotations through the existing page `/Annots` seam, delegate visible content rendering through `%Rendro.Link{content: inner}` back into the existing inner render path so linked content still paints normally, use inline `/A << /S /URI /URI (...) >>` for external links, use direct `/Dest [page_ref /Fit]` for same-document page jumps, and avoid separate generic action objects, named destinations, `QuadPoints`, or raw annotation escape hatches. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

**Primary recommendation:** Add `Rendro.link/2` plus `%Rendro.Link{}` as a block-content wrapper, reject `%Rendro.FormField{}` as wrapped link content at validate time to avoid conflicting widget/link hit semantics on the shared `/Annots` seam, validate URI/page targets in a new `CheckLinks` rule after pagination, and serialize one rectangular `/Link` annotation per paginated fragment through the existing writer `/Annots` path while delegating visible content rendering through the wrapped inner node. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [CITED: https://hexdocs.pm/elixir/URI.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public authored link DSL | API / Backend | — | Rendro’s public surface is a pure Elixir builder API, and `Rendro.form_field/3` already establishes the precedent for explicit authored interactive constructs in core. [VERIFIED: codebase grep] |
| Link geometry ownership | API / Backend | — | Link hit areas must come from final block dimensions, and the current codebase stores those dimensions on `%Rendro.Block{}` and derives widget rectangles from them in the writer. [VERIFIED: codebase grep] |
| Pagination fragmentation into per-page clickable regions | API / Backend | Browser / Client | Rendro owns block splitting and page assignment before render, while viewers only consume the finished rectangles already serialized into the PDF. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| External URI resolution after click | Browser / Client | — | PDF viewers execute URI actions after activation; Rendro should only emit the narrow, validated action dictionary and not claim control over viewer or OS policy. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| Internal page destination resolution | API / Backend | Browser / Client | Rendro must resolve authored page numbers to concrete page object references before serialization, while the viewer only presents the referenced destination. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and avoid new hard dependencies on Phoenix, Oban, or admin tooling. [VERIFIED: codebase grep]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: codebase grep]
- Treat documentation claims as contracts and avoid claiming unsupported PDF capabilities. [VERIFIED: codebase grep]
- Prefer explicit dedicated builders for new PDF product semantics over hidden attrs, overloaded strings, or escape hatches. [VERIFIED: codebase grep]
- Reuse the existing pipeline and writer seams rather than inventing a second rendering path. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `URI` stdlib | 1.19.5 | Parse and validate authored URI strings at the boundary with `URI.new/1` rather than custom regexes or `URI.parse/1`. [CITED: https://hexdocs.pm/elixir/URI.html] | The official docs state `URI.new/1` parses and validates, while `URI.parse/1` parses without further validation, which matches Phase 49’s validation-first contract. [CITED: https://hexdocs.pm/elixir/URI.html] |
| `Rendro.Pipeline.Validate` | repo HEAD on 2026-05-05 | Aggregate typed link validation errors after pagination and before writer execution. [VERIFIED: codebase grep] | The default validation pipeline already collects tuple-based rule failures and runs after paginate, which is the right timing for page-destination resolution. [VERIFIED: codebase grep] |
| `Rendro.PDF.Writer` | repo HEAD on 2026-05-05 | Reuse the existing page `/Annots` seam and object-allocation funnel for `/Link` annotations. [VERIFIED: codebase grep] | The writer already centralizes page-object planning, conditional catalog widening, and page annotation emission for widgets, so Phase 49 should extend that seam instead of branching away from it. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rendro.Fragmentable` | repo HEAD on 2026-05-05 | Preserve link wrappers across text or table fragmentation so each fragment yields its own page annotation. [VERIFIED: codebase grep] | Implement for `%Rendro.Link{}` so flow pagination keeps target metadata attached to each fragment. [VERIFIED: codebase grep] |
| `Rendro.Pipeline.Measure` | repo HEAD on 2026-05-05 | Measure wrapped content while preserving the outer link wrapper. [VERIFIED: codebase grep] | Add one narrow branch for `%Rendro.Link{}` that delegates to the existing inner-content measurement path. [VERIFIED: codebase grep] |
| PDF 32000-1 link annotation rules | ISO 32000-1:2008 / Adobe-hosted copy | Define legal `/Link`, `/Dest`, and `/URI` action dictionary shapes. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] | Use for exact serialization decisions; no new Hex package is required. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct same-document `/Dest [page_ref /Fit]` | `/A << /S /GoTo /D [...] >>` | The PDF spec says the effect is the same but the direct destination is more compact and preferable for same-document jumps, so `Dest` is the tighter Phase 49 fit. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| Explicit `Rendro.link/2` wrapper | Hidden attrs on `Rendro.text/2` or `Rendro.block/2` | Hidden attrs contradict the locked phase decisions and the explicit authored-node precedent established by `Rendro.form_field/3`. [VERIFIED: codebase grep] |
| Reusing block geometry | Hand-authored overlay rectangles | Overlay rectangles split geometry ownership between caller and pagination engine, which conflicts with the phase boundary and Rendro methodology. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No additional Hex dependencies recommended for Phase 49.
```

**Version verification:** Elixir `1.19.5`, OTP `28`, and Mix `1.19.5` are installed locally, and `mix.exs` already declares the phase can rely on stdlib plus the existing Rendro core without adding a new dependency. [VERIFIED: local command] [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Caller
  |
  v
Rendro.link(block, uri: ... | page: ...)
  |
  v
%Rendro.Block{content: %Rendro.Link{content: inner, target: target}}
  |
  v
Compose -> Measure -> Paginate
  |                   |
  |                   +--> block fragments remain wrapped with same target
  v
Validate
  |
  +--> reject malformed URI / unsupported scheme / non-ASCII URI
  +--> reject invalid page number / unresolved page destination
  +--> reject zero-area final link fragments
  |
  v
Writer build_objects/4
  |
  +--> collect page link fragments in deterministic order
  +--> allocate one annotation object per fragment
  +--> build page /Annots arrays
  |
  +--> external: /A << /S /URI /URI (...) >>
  +--> internal: /Dest [page_ref /Fit]
  |
  v
PDF Viewer
  |
  +--> executes URI action or jumps to page destination
```

The important ownership boundary is that Rendro decides authored targets, geometry, fragmentation, and serialization, while the PDF viewer decides how activation is presented and whether external navigation is allowed by local policy. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

### Recommended Project Structure
```text
lib/
├── rendro/link.ex                    # New explicit authored link content node
├── rendro.ex                         # Public Rendro.link/2 builder
├── rendro/pipeline/measure.ex        # Measure wrapped inner content while preserving link wrapper
├── rendro/fragmentable.ex            # Split wrapped links into per-page fragments
├── rendro/rules/check_links.ex       # New validate-stage URI/page/link-rect checks
├── rendro/pipeline/validate.ex       # Wire CheckLinks into the default rules
└── rendro/pdf/writer.ex              # Collect/allocate/serialize /Link annotations through /Annots

test/
├── rendro_builders_test.exs          # Public builder contract
├── rendro/rules/check_links_test.exs # Raw tuple validation
├── rendro/pipeline/validate_test.exs # Aggregate validation envelope
├── rendro/pdf/writer_test.exs        # Structural /Link, /A, /Dest proof
└── rendro/deterministic_test.exs     # Byte stability and ordering proof
```

### Pattern 1: Explicit Link Wrapper Node
**What:** Represent links as block content wrappers, not document registries or hidden attrs: `%Rendro.Block{content: %Rendro.Link{content: inner_content, target: {:uri, uri} | {:page, page_number}}}`. [VERIFIED: codebase grep]  
**When to use:** For any authored block that should be clickable and should keep its geometry under the existing measure/paginate pipeline. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: codebase precedent + phase decisions
body_block = Rendro.block(Rendro.text("Read the guide"), width: 180)

doc =
  Rendro.flow([
    Rendro.link(body_block, uri: "https://example.com/guide")
  ])
```
This shape mirrors `Rendro.form_field/3` in being explicit, but it keeps geometry on the existing block instead of inventing a second rectangle-authoring API. [VERIFIED: codebase grep]

### Pattern 2: Validate After Pagination, Not in the Writer
**What:** Run link rules in `Validate.run/1` after measurement and pagination so the rule sees final block dimensions, final page count, and final page-local fragments. [VERIFIED: codebase grep]  
**When to use:** Always; internal page targets and zero-area fragment checks are not truthfully resolvable earlier. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: codebase validation pattern
def check(%Rendro.Link{target: {:uri, uri}}, _doc) do
  with {:ok, parsed} <- URI.new(uri),
       :ok <- ensure_http_scheme(parsed),
       :ok <- ensure_host(parsed),
       :ok <- ensure_ascii(uri) do
    :ok
  else
    {:error, reason} -> {:error, reason}
  end
end
```
Use `URI.new/1`, not `URI.parse/1`, because the official docs state `URI.new/1` validates while `URI.parse/1` does not. [CITED: https://hexdocs.pm/elixir/URI.html]

### Pattern 3: Serialize Same-Document Links with `Dest`, External Links with `A`
**What:** Use `/Dest [page_ref /Fit]` for internal page-only links and inline `/A << /S /URI /URI (...) >>` for external links. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]  
**When to use:** Always in Phase 49; it is the smallest truthful serialization surface that satisfies `LINK-01` and `LINK-02`. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: PDF 32000-1 semantics adapted to Rendro writer helpers
defp build_link_annotation_object(obj_num, page_num, rect, {:uri, uri}, opts) do
  dict =
    {:dict,
     [
       {"Type", {:name, "Annot"}},
       {"Subtype", {:name, "Link"}},
       {"Rect", {:array, rect}},
       {"Border", {:array, [0, 0, 0]}},
       {"A", {:dict, [{"S", {:name, "URI"}}, {"URI", {:string, uri}}]}}
     ]}

  {obj_num, Object.indirect_object(obj_num, 0, Object.serialize(dict, opts))}
end
```
The same-document equivalent should replace the `A` entry with `{"Dest", {:array, [{:ref, target_page_num, 0}, {:name, "Fit"}]}}` because `Dest` is explicitly allowed on link annotations and is preferable to a same-effect `GoTo` action in this case. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

### Anti-Patterns to Avoid
- **Hidden link attrs on text or block:** This violates the locked phase decision and makes interactive PDF behavior look like ordinary text styling. [VERIFIED: codebase grep]
- **Writer-only URI rejection:** This defers user errors to the latest possible stage and breaks the project’s boundary-validation-first posture. [VERIFIED: codebase grep]
- **Generic annotation/action escape hatches:** They widen the support contract beyond what `v1.9` requirements and proof artifacts allow. [VERIFIED: codebase grep]
- **Links wrapping `%Rendro.FormField{}`:** Widget and link annotations would compete on the same `/Annots` seam and blur click semantics, so Phase 49 should reject that authored shape instead of leaving the interaction unspecified. [VERIFIED: codebase grep]
- **Relative or scheme-relative URIs with catalog `/URI` base handling:** The PDF spec allows document-level base URIs, but Phase 49 explicitly rejects that broader behavior, so omit catalog `/URI` entries entirely. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep]
- **`QuadPoints` or inline-span hit boxes:** They are a broader semantic contract than the phase allows and would couple the public API to private text-fragment details. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep]

## Internal Ownership Recommendation

The minimal internal model is one new content struct and no new document registry: `%Rendro.Link{content: inner_content, target: {:uri, binary()} | {:page, pos_integer()}}`. [VERIFIED: codebase grep]  
Ownership should stay block-local because the current writer derives annotation rectangles from page blocks, the current pipeline stores measured geometry on blocks, and the codebase has no generic authored identity seam for arbitrary rendered content that would justify a document-level destination registry. [VERIFIED: codebase grep]

Recommended public shape:

```elixir
@spec link(Rendro.Block.t(), keyword()) :: Rendro.Block.t()

Rendro.link(block, uri: "https://example.com")
Rendro.link(block, page: 3)
```

That recommendation keeps the target variants explicit by key, keeps geometry owned by the wrapped block, and stays closer to `Rendro.form_field/3` than a hidden-attrs or overloaded-string design. [VERIFIED: codebase grep]

Recommended builder semantics:

- Accept exactly one authored `%Rendro.Block{}`. [VERIFIED: codebase grep]
- Preserve all existing outer block fields (`x`, `y`, `width`, `height`, flow directives). [VERIFIED: codebase grep]
- Replace only `block.content` with `%Rendro.Link{content: original_content, target: target}`. [VERIFIED: codebase grep]
- Do not accept raw dictionaries, action maps, or manually authored rectangles. [VERIFIED: codebase grep]

Recommended non-public helper shape:

```elixir
defmodule Rendro.Link do
  @enforce_keys [:content, :target]
  defstruct [:content, :target]
end
```

This is smaller than introducing a document-owned registry and smaller than nesting a full inner block because the outer `%Rendro.Block{}` already owns geometry and placement. [VERIFIED: codebase grep]

## Validate-Stage Responsibilities

`Rendro.Pipeline.Validate` should own link semantics by adding a `Rendro.Rules.CheckLinks` rule to `@default_rules`, following the same tuple-based aggregation pattern already used by form fields and embedded files. [VERIFIED: codebase grep]

### Exact invalid states to catch early

| Invalid state | Recommended tuple | Why it belongs in validate |
|---------------|-------------------|----------------------------|
| No target key, or more than one target key | `{:invalid_link_target_shape, attrs}` | The public API must stay explicit and non-overloaded. [VERIFIED: codebase grep] |
| URI fails `URI.new/1` validation | `{:invalid_link_uri, uri}` | `URI.new/1` is the official validating parser; malformed input should not reach the writer. [CITED: https://hexdocs.pm/elixir/URI.html] |
| Scheme is not `http` or `https` | `{:unsupported_link_scheme, scheme}` | Phase 49 explicitly limits external navigation to `http` and `https`. [VERIFIED: codebase grep] |
| URI is relative or scheme-relative | `{:relative_link_uri, uri}` | `URI.new/1` accepts relative and scheme-relative forms, so the phase must reject them with an additional policy check. [CITED: https://hexdocs.pm/elixir/URI.html] [VERIFIED: local command] |
| URI has no host | `{:missing_link_host, uri}` | `URI.new/1` also accepts shapes like `https:?query`, so host presence must be enforced separately. [CITED: https://hexdocs.pm/elixir/URI.html] [VERIFIED: local command] |
| URI contains non-ASCII bytes | `{:non_ascii_link_uri, uri}` | PDF 32000-1 specifies the `/URI` value as an ASCII string, so Phase 49 should reject non-ASCII authored bytes rather than rewrite them. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| Page target is not a positive integer | `{:invalid_link_page, page}` | Page-only destinations need a stable authored contract, and positive integers are the smallest truthful one. [VERIFIED: codebase grep] |
| Page target exceeds final page count | `{:unresolved_link_page, page}` | This cannot be resolved until after pagination, which is why validate is the correct stage. [VERIFIED: codebase grep] |
| Final fragment width or height is zero | `{:invalid_link_rect, %{width: w, height: h}}` | General blocks may allow zero-area bounds, but zero-area clickable annotations are not a useful or truthful link surface. [VERIFIED: codebase grep] |
| Nested link wrapper | `:nested_link_not_supported` | Nesting widens semantics around hit-testing and overlapping annotations without any phase requirement. [VERIFIED: codebase grep] |

Recommended rule split:

- `check(%Rendro.Link{}, _doc)` for target-shape and URI/page-type validation. [VERIFIED: codebase grep]
- `check(%Rendro.Block{content: %Rendro.Link{}} = block, _doc)` for final measured-rectangle validation. [VERIFIED: codebase grep]
- `check(%Rendro.Document{} = doc, _root_doc)` for document-wide page-count resolution if you choose to batch unresolved page checks there. [VERIFIED: codebase grep]

## Writer Allocation and Serialization Seams

### Allocation plan

The current writer already allocates page object numbers first, then feature-specific objects, then page/content objects, so links can fit naturally as one more allocation family without introducing a parallel writer path. [VERIFIED: codebase grep]

Recommended change set inside `build_objects/4`:

1. Collect page link fragments with a new `collect_links/1` helper after pagination has produced final pages. [VERIFIED: codebase grep]
2. Allocate one indirect object number per link fragment with `allocate_link_nums/2`. [VERIFIED: codebase grep]
3. Do not allocate separate action objects; inline URI actions inside the annotation dictionary and use direct `Dest` arrays for same-document page jumps. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]
4. Thread link allocations into `build_page_objects/9` so the page `/Annots` array remains the only page-annotation seam. [VERIFIED: codebase grep]

### Collection plan

Recommended collection shape:

```elixir
%{
  obj_num: 42,
  page_index: 1,
  block: %Rendro.Block{},
  target: {:uri, "https://example.com"}
}
```

Recommended traversal order:

- Page order as stored in `doc.pages`. [VERIFIED: codebase grep]
- Within each page, `page.blocks` order. [VERIFIED: codebase grep]
- Within tables, header cell order first, then row order, then cell order, matching the current form-field walker. [VERIFIED: codebase grep]

This keeps link ordering deterministic and aligned with existing traversal semantics. [VERIFIED: codebase grep]

### Page annotation assembly

Current `build_page_objects/9` gets `{annot_refs, form_objects}` from `build_form_field_objects/5` and appends `Annots` only when the list is non-empty. [VERIFIED: codebase grep]  
Recommended evolution:

```elixir
{form_refs, form_objects} = build_form_field_objects(...)
{link_refs, link_objects} = build_link_annotation_objects(...)
annot_refs = form_refs ++ link_refs
```

This is the narrowest change because it preserves the existing writer seam and keeps links out of the catalog-level form surface. [VERIFIED: codebase grep]

### Exact `/Link` shapes

External URI annotation:

```pdf
<<
  /Type /Annot
  /Subtype /Link
  /Rect [x1 y1 x2 y2]
  /Border [0 0 0]
  /A << /S /URI /URI (https://example.com) >>
>>
```

This matches the spec requirement that a link annotation may carry an `A` action dictionary and that URI actions use `/S /URI` with a required ASCII `URI` string. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

Internal page-only annotation:

```pdf
<<
  /Type /Annot
  /Subtype /Link
  /Rect [x1 y1 x2 y2]
  /Border [0 0 0]
  /Dest [7 0 R /Fit]
>>
```

This matches the spec allowance for direct `Dest` entries on link annotations and uses `/Fit` because Phase 49 only promises page-level navigation, not coordinate-level or zoom-level semantics. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep]

### Why `/Fit`

PDF explicit destinations support many forms, including `/XYZ`, `/FitH`, `/FitV`, and `/FitR`, but only `/Fit` matches the locked “page-only destination” contract without inventing new authored coordinates or viewer-zoom policy. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep]

## Deterministic Ordering and Pagination Fragment Implications

The current codebase already treats deterministic resource ordering as product behavior, with sorted embedded files and deterministic dictionary-key serialization, so link annotations should adopt the same posture. [VERIFIED: codebase grep]

Recommended deterministic rules:

- Preserve authored page traversal order when collecting links. [VERIFIED: codebase grep]
- Preserve fragment order produced by pagination; if a text or table link splits across pages, emit one annotation for each final block fragment in page order. [VERIFIED: codebase grep]
- Keep annotation object-number allocation stable from the collected order only; do not inspect hash maps or unsorted registries. [VERIFIED: codebase grep]
- Keep URI bytes exactly as authored after validation; do not lowercase hosts, normalize paths, decode escapes, or add trailing slashes. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/URI.html]

Important implication: if a linked block fragments, the final clickable areas are the fragment rectangles, not the pre-pagination authored block rectangle. [VERIFIED: codebase grep]  
That implication is consistent with the PDF model because link annotations are page-local geometric regions, not inline text spans. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

Recommended implementation detail for fragmentation:

- Add `defimpl Rendro.Fragmentable, for: Rendro.Link` that delegates split logic to the wrapped inner content and re-wraps both return values with the same target. [VERIFIED: codebase grep]
- Add a `measure_block/3` clause for `%Rendro.Block{content: %Rendro.Link{}}` that measures the wrapped inner content via the existing block-measure path, then writes the resulting width/height back onto the outer block while preserving the link target. [VERIFIED: codebase grep]

That pair of changes avoids any separate “annotation fragment registry” and lets the existing pagination engine create the exact per-page link fragments that the writer later collects. [VERIFIED: codebase grep]

## Candidate File Targets

| File | Role | Planned change |
|------|------|----------------|
| `lib/rendro/link.ex` | new authored node | Add `%Rendro.Link{content, target}` and target types. [VERIFIED: codebase grep] |
| `lib/rendro.ex` | public API | Add `Rendro.link/2` as the single explicit public builder. [VERIFIED: codebase grep] |
| `lib/rendro/pipeline/measure.ex` | measurement | Add one branch that measures wrapped inner content and preserves the outer link wrapper. [VERIFIED: codebase grep] |
| `lib/rendro/fragmentable.ex` | pagination splitting | Add `Rendro.Fragmentable` implementation for `%Rendro.Link{}` so fragments carry targets across page breaks. [VERIFIED: codebase grep] |
| `lib/rendro/rules/check_links.ex` | validation rule | Implement URI policy, page resolution, nested-link, and zero-area fragment checks as typed tuples. [VERIFIED: codebase grep] |
| `lib/rendro/pipeline/validate.ex` | validation wiring | Insert `CheckLinks` into `@default_rules`. [VERIFIED: codebase grep] |
| `lib/rendro/pdf/writer.ex` | writer seam | Add `collect_links/1`, `allocate_link_nums/2`, `build_link_annotation_objects/5`, and page `Annots` concatenation. [VERIFIED: codebase grep] |
| `test/rendro_builders_test.exs` | builder proof | Assert `Rendro.link/2` preserves outer block attrs and installs `%Rendro.Link{}`. [VERIFIED: codebase grep] |
| `test/rendro/rules/check_links_test.exs` | raw validation proof | Assert exact tuples for malformed URI, unsupported scheme, missing host, invalid page, and nested links. [VERIFIED: codebase grep] |
| `test/rendro/pipeline/validate_test.exs` | aggregate validation proof | Assert `details.errors` includes link tuples alongside unrelated failures. [VERIFIED: codebase grep] |
| `test/rendro/pdf/writer_test.exs` | structural PDF proof | Assert `/Subtype /Link`, `/A << /S /URI`, `/URI (...)`, `/Dest [.. /Fit]`, and page `/Annots` emission. [VERIFIED: codebase grep] |
| `test/rendro/deterministic_test.exs` | determinism proof | Assert identical deterministic bytes across repeated renders and stable per-page link ordering. [VERIFIED: codebase grep] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URI validation | ad hoc regexes or string splitting | `URI.new/1` plus explicit scheme/host/ASCII policy | The standard library already provides validated parsing, while Phase 49 still needs additional policy checks for relative URIs and missing hosts. [CITED: https://hexdocs.pm/elixir/URI.html] [VERIFIED: local command] |
| Fragment rectangle tracking | a custom annotation overlay registry | Existing `%Rendro.Block{}` geometry plus `Rendro.Fragmentable` | Geometry is already owned by blocks and page-local fragments, which is exactly what link annotations need. [VERIFIED: codebase grep] |
| Same-document go-to action objects | generic action builders | direct `Dest` arrays on link annotations | The PDF spec says direct `Dest` has the same effect as `GoTo` and is preferable here because it is more compact. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| Generic annotation dictionaries | raw `%{}` escape hatches | fixed `{:uri, binary}` and `{:page, pos_integer}` targets | Raw dictionaries widen scope into unsupported annotation and action semantics. [VERIFIED: codebase grep] |

**Key insight:** The narrowest truthful implementation is not “generic annotations with only one documented subtype”; it is “one explicit link wrapper, two target variants, one page-annotation writer seam.” [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Using `URI.parse/1` for validation
**What goes wrong:** Relative, malformed, or otherwise weakly-validated URIs slip through because `URI.parse/1` parses without further validation. [CITED: https://hexdocs.pm/elixir/URI.html]  
**Why it happens:** `URI.parse/1` and `URI.new/1` look similar, but the official docs give them different guarantees. [CITED: https://hexdocs.pm/elixir/URI.html]  
**How to avoid:** Use `URI.new/1`, then separately enforce `http`/`https`, non-nil host, and ASCII-only bytes. [CITED: https://hexdocs.pm/elixir/URI.html] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]  
**Warning signs:** `//example.com`, `/foo`, or `https:?query` gets accepted in tests. [VERIFIED: local command]

### Pitfall 2: Resolving page destinations before pagination finishes
**What goes wrong:** Authored page targets point at stale or non-existent pages because the final `doc.pages` list is only stable after paginate. [VERIFIED: codebase grep]  
**Why it happens:** Internal links feel like simple integers, but Rendro’s flow layout can add pages through splitting and hard-group behavior before validate runs. [VERIFIED: codebase grep]  
**How to avoid:** Resolve `page:` targets in `CheckLinks` against final paginated `doc.pages`, then build `/Dest` using allocated page object references in the writer. [VERIFIED: codebase grep]  
**Warning signs:** A document that paginates differently under small width changes produces broken internal links without any validation error. [VERIFIED: codebase grep]

### Pitfall 3: Losing target metadata when a linked block splits
**What goes wrong:** Only the first fragment gets an annotation, or later fragments render without clickable regions. [VERIFIED: codebase grep]  
**Why it happens:** The current pagination engine splits blocks by delegating to `Rendro.Fragmentable`, so a new wrapper type must participate in that protocol. [VERIFIED: codebase grep]  
**How to avoid:** Implement `Rendro.Fragmentable` for `%Rendro.Link{}` and collect links from final paginated page blocks, not from pre-pagination authored content. [VERIFIED: codebase grep]  
**Warning signs:** A long linked text block yields multiple pages of visible text but only one `/Subtype /Link` in the output PDF. [VERIFIED: codebase grep]

### Pitfall 4: Widening into coordinate-level or named-destination semantics
**What goes wrong:** The public contract silently expands into anchors, explicit zoom control, or viewer-specific navigation behaviors that the phase did not promise. [VERIFIED: codebase grep]  
**Why it happens:** PDF destinations support many richer forms, and the spec also supports named destinations and catalog URI bases. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]  
**How to avoid:** Keep the public API to `uri:` and `page:` only, and always encode internal links as `/Dest [page_ref /Fit]`. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]  
**Warning signs:** Proposed APIs include `anchor:`, `zoom:`, `x:`, `y:`, or raw PDF destination arrays. [VERIFIED: codebase grep]

## Code Examples

Verified patterns adapted to Rendro:

### Public Builder
```elixir
# Source: Rendro explicit-builder precedent + locked phase decisions
cover =
  Rendro.block(
    Rendro.text("Open project site"),
    width: 160,
    keep_together: true
  )

doc =
  Rendro.flow([
    Rendro.link(cover, uri: "https://github.com/szTheory/rendro"),
    Rendro.link(Rendro.block(Rendro.text("Jump to appendix")), page: 4)
  ])
```
This keeps link authoring explicit and narrow, and it forces geometry to come from the wrapped block rather than a separate overlay API. [VERIFIED: codebase grep]

### Fragmentable Wrapper
```elixir
# Source: existing Rendro.Fragmentable protocol shape
defimpl Rendro.Fragmentable, for: Rendro.Link do
  def split(%Rendro.Link{content: inner, target: target}, available_h) do
    case Rendro.Fragmentable.split(inner, available_h) do
      {nil, rem} -> {nil, %Rendro.Link{content: rem, target: target}}
      {this, nil} -> {%Rendro.Link{content: this, target: target}, nil}
      {this, rem} -> {%Rendro.Link{content: this, target: target}, %Rendro.Link{content: rem, target: target}}
    end
  end
end
```
This is the minimal way to preserve target metadata through the existing split pipeline. [VERIFIED: codebase grep]

### Internal Destination Serialization
```elixir
# Source: PDF 32000-1 direct Dest on /Link annotations
dest = {:array, [{:ref, target_page_num, 0}, {:name, "Fit"}]}

dict =
  {:dict,
   [
     {"Type", {:name, "Annot"}},
     {"Subtype", {:name, "Link"}},
     {"Rect", {:array, rect}},
     {"Border", {:array, [0, 0, 0]}},
     {"Dest", dest}
   ]}
```
The spec explicitly permits `Dest` on link annotations and states it has the same effect as a same-document `GoTo` action while being preferable here because it is more compact. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Same-document jumps encoded as `GoTo` actions everywhere | Direct `Dest` on `/Link` annotations is preferable when jumping within the current document. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] | Present in PDF 1.1+ and still current in PDF 32000-1. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] | Rendro can satisfy `LINK-02` with fewer objects and a smaller support surface. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| “Parse then hope” URI acceptance | `URI.new/1` validates, while `URI.parse/1` does not. [CITED: https://hexdocs.pm/elixir/URI.html] | Elixir 1.13 introduced `URI.new/1`, and it remains the documented validating API in Elixir 1.19.5. [CITED: https://hexdocs.pm/elixir/URI.html] | Phase 49 should rely on `URI.new/1` and explicit policy checks instead of custom heuristics. [CITED: https://hexdocs.pm/elixir/URI.html] |

**Deprecated/outdated:**
- `URI.parse/1` as a validation boundary for link authoring is outdated for this phase because the official docs say it performs parsing without further validation. [CITED: https://hexdocs.pm/elixir/URI.html]
- Named destinations are not outdated in PDF generally, but they are intentionally out of scope for Phase 49 because the codebase has no stable authored identity seam for them. [VERIFIED: codebase grep]

## Assumptions Log

All claims in this research were verified or cited in this session — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Should links wrapping `%Rendro.FormField{}` be explicitly rejected in Phase 49?**
   - What we know: form fields already emit widget annotations through the same page `/Annots` seam, and Phase 49 intentionally avoids widening into generic annotation layering. [VERIFIED: codebase grep]
   - Resolution: reject links whose wrapped content is `%Rendro.FormField{}` in `CheckLinks` to keep interaction semantics narrow and avoid mixed hit-testing claims in `v1.9`. This policy is now locked for Phase 49 and should be covered by raw-rule and aggregate validation tests. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: codebase grep] [VERIFIED: local command] |
| Config file | none — use the existing Mix/ExUnit defaults. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LINK-01 | Curated external `http`/`https` link authoring validates and serializes as `/A << /S /URI /URI (...) >>`. [VERIFIED: codebase grep] | unit + writer | `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pdf/writer_test.exs` | ❌ Wave 0 for `test/rendro/rules/check_links_test.exs` |
| LINK-02 | Curated internal page links validate against final page count and serialize as direct `/Dest [page_ref /Fit]`. [VERIFIED: codebase grep] | integration + writer | `mix test test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs` | ✅ existing files, but new examples/assertions required. [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs` [VERIFIED: codebase grep]
- **Per wave merge:** `mix test` [VERIFIED: codebase grep]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/rendro/rules/check_links_test.exs` — exact tuple coverage for malformed URI, unsupported scheme, missing host, invalid page, nested links, and `%Rendro.FormField{}`-wrapped links. [VERIFIED: codebase grep]
- [ ] `test/rendro_builders_test.exs` — new `Rendro.link/2` builder assertions. [VERIFIED: codebase grep]
- [ ] `test/rendro/pdf/writer_test.exs` — `/Subtype /Link`, `/A /URI`, `/Dest /Fit`, split-fragment assertions, and proof that `%Rendro.Link{content: inner}` still delegates visible rendering for linked text/table content. [VERIFIED: codebase grep]
- [ ] `test/rendro/deterministic_test.exs` — stable bytes and stable link ordering assertions. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not applicable to a pure PDF-generation link surface. [VERIFIED: codebase grep] |
| V3 Session Management | no | Not applicable to a pure PDF-generation link surface. [VERIFIED: codebase grep] |
| V4 Access Control | no | No authenticated resource access is introduced inside core; the feature only serializes links. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Use `URI.new/1` plus explicit scheme/host/ASCII/page-number validation in `CheckLinks`. [CITED: https://hexdocs.pm/elixir/URI.html] [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase 49 does not introduce encryption, signing, or secret handling. [VERIFIED: codebase grep] |

### Known Threat Patterns for Rendro link annotations

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported schemes (`mailto:`, `file:`, custom) broaden viewer/OS behavior | Elevation of Privilege | Reject any external link whose scheme is not exactly `http` or `https`. [VERIFIED: codebase grep] |
| Relative or scheme-relative URIs resolve unpredictably | Tampering | Reject relative forms and omit catalog `/URI` base support in Phase 49. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [VERIFIED: codebase grep] |
| Malformed or non-ASCII URI bytes produce ambiguous viewer behavior | Tampering | Use `URI.new/1` and reject non-ASCII values instead of rewriting authored input. [CITED: https://hexdocs.pm/elixir/URI.html] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] |
| Out-of-range page destinations silently degrade into broken navigation | Denial of Service | Reject unresolved page numbers during validate before rendering starts. [VERIFIED: codebase grep] |
| Generic annotation/action escape hatches widen the attack and support surface | Elevation of Privilege | Expose only `uri:` and `page:` and keep writer helpers private. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf` — verified link annotation entries, direct `Dest` semantics, explicit destination forms, URI action dictionary requirements, and the geometric nature of link annotations. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf]
- `https://hexdocs.pm/elixir/URI.html` — verified `URI.new/1` vs `URI.parse/1`, relative/scheme-relative parsing behavior, and validation guidance in Elixir 1.19.5. [CITED: https://hexdocs.pm/elixir/URI.html]
- `.planning/phases/49-curated-link-annotation-surface/49-CONTEXT.md` — verified locked scope, target variants, and out-of-scope boundaries. [VERIFIED: codebase grep]
- `.planning/METHODOLOGY.md` — verified truthful-small-contract and boundary-validation-first guidance. [VERIFIED: codebase grep]
- `.planning/phases/45-CONTEXT.md` — verified explicit authored-node precedent for interactive PDF constructs. [VERIFIED: codebase grep]
- `.planning/phases/48-embedded-file-core-surface/48-PATTERNS.md` — verified writer seam extension precedent. [VERIFIED: codebase grep]
- `lib/rendro.ex`, `lib/rendro/block.ex`, `lib/rendro/page.ex`, `lib/rendro/pipeline/validate.ex`, `lib/rendro/pdf/writer.ex`, `lib/rendro/pipeline/measure.ex`, `lib/rendro/fragmentable.ex` — verified current ownership, pipeline order, and writer seams. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 49 can rely on stdlib `URI` and existing Rendro pipeline/writer seams without introducing a new dependency, and both the local environment and codebase confirm that stack. [VERIFIED: local command] [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/elixir/URI.html]
- Architecture: HIGH - The public explicit-node precedent, validate-stage pattern, fragment protocol, and `/Annots` writer seam are all directly visible in the codebase. [VERIFIED: codebase grep]
- Pitfalls: HIGH - The critical pitfalls map directly to the official PDF and Elixir docs plus the current pipeline shape. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf] [CITED: https://hexdocs.pm/elixir/URI.html] [VERIFIED: codebase grep]

**Research date:** 2026-05-05  
**Valid until:** 2026-06-04

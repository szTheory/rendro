# Phase 90: Duplex Running Content - Research

**Researched:** 2026-06-13
**Domain:** Pure-Elixir document pagination, running regions, duplex page parity
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Public `%Rendro.PageContext{}` or callback API.
- Recto/verso aliases, locale-aware numbering, Roman numerals, named page styles, blank-page insertion, TOC/outlines/anchors/cross-references.
- Global text shaping and script support.
- PDF.js advisory proof lane, which is Phase 91.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUP-01 | A document author can attach running header/footer sections with `only_on: :odd` or `only_on: :even`, evaluated against physical page parity. | Use `%Rendro.Section{only_on: nil | :odd | :even}` and filter by `rem(physical_page_number, 2)` in the running-region application path. [VERIFIED: `.planning/REQUIREMENTS.md`, `lib/rendro/pipeline/paginate.ex`] |
| DUP-02 | Duplex running content composes with section-local numbering so report/booklet-style documents can render different left/right page footers without a second render pass. | Preserve Phase 89 page context and run `only_on`/`suppress_on` before `RunningContent` evaluation and PAGE-token substitution on each physical page. [VERIFIED: `.planning/phases/89-page-context-primitive/89-01-SUMMARY.md`, `lib/rendro/pipeline/paginate.ex`] |
| DUP-03 | Invalid `only_on` / `page_numbering` options fail with instructive errors before rendering produces misleading output. | Add centralized section-option validation reachable from `Compose.run/1` and direct pagination fallbacks; current post-paginate `Validate.run/1` does not walk `Document.sections`. [VERIFIED: `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/validate.ex`, `lib/rendro/pipeline.ex`] |
</phase_requirements>

## Summary

Phase 90 should implement duplex running content as a narrow extension of the Phase 89 page-context path, not as a new document-layout subsystem. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`, `.planning/phases/89-page-context-primitive/89-01-SUMMARY.md`] The central design move is to stop treating running-region behavior as only a per-region property (`region_suppress_on`) and instead preserve per-section running-region entries that include `blocks`, `suppress_on`, and `only_on`. [VERIFIED: `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/paginate.ex`]

The planner should prefer physical page parity over section-local numbering for `only_on`; this matches the locked decision and the wider paged-media model where left/right pages are a property of facing physical pages, not of local counters. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`; CITED: https://www.w3.org/TR/css-page-3/] Section-local PAGE tokens should still be substituted from the Phase 89 page context after page count and section ranges are known. [VERIFIED: `lib/rendro/pipeline/paginate.ex`]

**Primary recommendation:** Add `Section.only_on`, validate section options centrally before rendering, carry running-region section entries through `layout`, and filter each entry with `suppress_on` AND physical-parity `only_on` before evaluating `RunningContent` and substituting PAGE tokens. [VERIFIED: codebase grep + W3C CSS Paged Media + Apache FOP docs]

## Project Constraints (from AGENTS.md)

- Rendro core must remain pure Elixir with no hard dependency on Phoenix, Oban, admin tooling, Node, browser runtimes, or adapters. [VERIFIED: `AGENTS.md`]
- Existing optional integration pattern is `optional: true` dependencies plus compile/runtime checks where integrations exist. [VERIFIED: `AGENTS.md`, `mix.exs`]
- The pipeline boundary is `build -> compose -> measure -> paginate -> render -> validate`; Phase 90 should extend that path rather than introduce a second render pass. [VERIFIED: `AGENTS.md`, `lib/rendro/pipeline.ex`]
- Documentation claims are product contracts; Phase 90 should prove behavior in tests and leave broad public guide/support-matrix wording to Phase 92. [VERIFIED: `AGENTS.md`, `.planning/phases/90-duplex-running-content/90-CONTEXT.md`]
- Deterministic and advisory verification lanes must remain separated; Phase 90 has no reason to touch PDF.js or browser evidence lanes. [VERIFIED: `AGENTS.md`, `.planning/ROADMAP.md`]
- Project-local custom skills were not present under `.codex/skills/` or `.agents/skills/` during research. [VERIFIED: `find .codex/skills .agents/skills -maxdepth 2 -name SKILL.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| `only_on` public option | Core builder/struct | Public API manifest | `Rendro.section/1` is a pure data builder over `%Rendro.Section{}`; adding a field changes the stable public type and manifest. [VERIFIED: `lib/rendro.ex`, `lib/rendro/section.ex`, `test/rendro/public_api/manifest_test.exs`] |
| Section-option validation | Compose / pagination pipeline | Builder tests | Builders use `struct!` and currently accept values that match existing keys; manual structs also enter through the pipeline, so pipeline validation is the reliable boundary. [VERIFIED: `lib/rendro.ex`, `lib/rendro/pipeline.ex`] |
| Running-region filtering | Paginate | Compose metadata | Only pagination knows physical page number, total pages, and section-local page context, while Compose is the right stage to preserve authored section metadata. [VERIFIED: `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/paginate.ex`] |
| Section-local token substitution | Paginate | Measure stability guard | Tokens are replaced after pagination and measured text widths are intentionally not recomputed. [VERIFIED: `lib/rendro/pipeline/paginate.ex`, `test/rendro/deterministic_test.exs`] |
| Phoenix/Ecto/Plug concerns | Not applicable to core | Optional adapters only | Phase 90 is pure core pagination; Phoenix/Plug/Oban are optional deps and Ecto is not present in `mix.exs`. [VERIFIED: `mix.exs`, `AGENTS.md`] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.19.5, OTP 28 | Core implementation and tests | Project stack and local runtime match the declared pure-Elixir core. [VERIFIED: `AGENTS.md`, `elixir --version`] |
| ExUnit | Bundled with Elixir 1.19.5 | Unit, pipeline, and regression tests | Existing tests are ExUnit and focused Phase 89/90 seams already exist. [VERIFIED: `test/rendro/pipeline/paginate_test.exs`, `mix test --trace`] |
| Telemetry | locked 1.4.2, config `~> 1.4` | Existing pipeline spans | No new telemetry package is needed; keep existing stage behavior if errors surface through pipeline tuples. [VERIFIED: `mix.lock`, `mix hex.info telemetry`, `lib/rendro/pipeline.ex`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| StreamData | locked 1.3.0 | Optional property tests | Use only if planner wants generated parity/filter composition checks; deterministic focused ExUnit examples are enough for required coverage. [VERIFIED: `mix.lock`, `mix hex.info stream_data`] |
| ExDoc | locked 0.40.1, latest 0.40.3 | Public docs contracts and generated API docs | Regenerate `priv/public_api.json` when `Section` changes; keep broad docs to Phase 92. [VERIFIED: `mix.lock`, `mix hex.info ex_doc`, `.planning/ROADMAP.md`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-section running-region entries | Keep `region_suppress_on` map and add `region_only_on` | Per-region maps collapse multiple header/footer sections and cannot represent odd and even footer variants targeting the same region without conflict or last-writer behavior. [VERIFIED: `lib/rendro/pipeline/compose.ex`] |
| Physical `:odd` / `:even` | Recto/verso aliases | Recto/verso are deferred and can imply writing-mode semantics Rendro does not yet model. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`; CITED: https://www.princexml.com/doc/paged/] |
| Pipeline validation | Builder-only validation | Builder-only validation misses manually constructed `%Rendro.Section{}` structs, which are a supported Elixir data pattern in this codebase. [VERIFIED: `lib/rendro/section.ex`, `test/rendro_builders_test.exs`] |

**Installation:**
```bash
# No new package install is recommended for Phase 90.
```

**Version verification:** Existing runtime and test dependencies were checked with `elixir --version`, `mix --version`, `mix.lock`, and `mix hex.info telemetry stream_data ex_doc`. [VERIFIED: local command output]

## Package Legitimacy Audit

Phase 90 should not install external packages. [VERIFIED: `.planning/ROADMAP.md`, `mix.exs`]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No external package recommended. [VERIFIED: research conclusion] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no packages recommended]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no packages recommended]

## Architecture Patterns

### System Architecture Diagram

```text
Rendro.section(... only_on: :odd/:even, suppress_on: ...)
        |
        v
Build.run/1
        |
        v
Compose.run/1
  - validate section options
  - normalize body entries with page_numbering
  - normalize running-region entries with suppress_on + only_on
        |
        v
Measure.run/1
  - measure blocks once
        |
        v
Paginate.run/1
  - paginate body entries
  - compute physical page contexts and section-local counters
  - for each physical page and running region:
        suppress_on allows page?
        only_on matches physical parity?
        evaluate RunningContent {page, total}
        substitute PAGE tokens from page_context
        anchor blocks into region
        |
        v
Validate.run/1 -> Render.run/1
```

### Recommended Project Structure

```text
lib/rendro/
├── section.ex                 # public Section field/type: only_on
├── section_options.ex          # optional small private/public-hidden validator helper [ASSUMED]
├── pipeline/
│   ├── compose.ex              # section normalization + metadata preservation
│   └── paginate.ex             # physical parity filtering + token substitution
test/rendro/
├── builders_test.exs           # Section builder/public field regression
├── pipeline/compose_test.exs   # validation + normalized running entries
├── pipeline/paginate_test.exs  # odd/even, suppress_on composition, section tokens
└── flow_test.exs               # end-to-end rendered PDF compatibility
```

### Pattern 1: Preserve Authored Section Metadata As Entries
**What:** Store non-body section metadata in a layout entry/list such as `%{region: :footer, blocks: measured_or_authored_blocks, suppress_on: ..., only_on: ...}` instead of reducing filters to `%{region => filter}` maps. [VERIFIED: `lib/rendro/pipeline/compose.ex`; ASSUMED helper name]
**When to use:** Required when multiple sections target the same running region with different parity filters. [VERIFIED: DUP-01/DUP-02]
**Example:**
```elixir
# Source: existing Compose.normalize_section/2 shape extended for Phase 90.
%{
  name: section.name || :"section_#{index}",
  region: section.region || :body,
  blocks: Enum.map(section.content, &compose_block/1),
  suppress_on: section.suppress_on,
  only_on: section.only_on,
  page_numbering: section.page_numbering,
  page_template: section.page_template
}
```

### Pattern 2: Filter Before Dynamic Evaluation
**What:** Apply `suppress_on` and `only_on` before evaluating `%Rendro.RunningContent{}` and before PAGE-token replacement. [VERIFIED: `lib/rendro/pipeline/paginate.ex`]
**When to use:** All running-region application. [VERIFIED: DUP-01/DUP-02]
**Example:**
```elixir
# Source: recommended extension of existing apply_page_template/5 path.
entry.blocks
|> apply_suppression(entry.suppress_on, physical_page)
|> apply_only_on(entry.only_on, physical_page)
|> evaluate_fn_blocks(physical_page, total_pages)
|> replace_page_numbers(page_context)
```

### Pattern 3: Physical Parity Is Not Section Parity
**What:** `only_on: :odd` means physical pages `1, 3, 5...`; a section restart on page 4 does not make page 4 odd for duplex filtering. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`; CITED: https://www.w3.org/TR/css-page-3/]
**When to use:** Every `only_on` decision. [VERIFIED: DUP-01]
**Example:**
```elixir
# Source: W3C left/right page model plus locked Phase 90 decision.
defp physical_parity(page_number), do: if(rem(page_number, 2) == 1, do: :odd, else: :even)
```

### Anti-Patterns to Avoid
- **Evaluating parity from `section_page_number`:** This breaks booklet/report expectations after restarts and contradicts Phase 90. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`]
- **Adding hidden fields to `%Rendro.Block{}`:** This violates the locked architecture and spreads section ownership into authored block data. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`]
- **Per-region `only_on` map:** This cannot represent simultaneous odd/even footer sections in the same region. [VERIFIED: `lib/rendro/pipeline/compose.ex`; ASSUMED failure mode from current map shape]
- **Builder-only validation:** `Rendro.section/1` uses `struct!`; it catches unknown keys but not invalid values for known keys. [VERIFIED: `lib/rendro.ex`, `test/rendro_builders_test.exs`]
- **Remeasuring token-expanded text:** Phase 89 intentionally preserves measured geometry after token substitution; changing this can make total page count convergence unstable. [VERIFIED: `lib/rendro/pipeline/paginate.ex`; CITED: https://xmlgraphics.apache.org/fop/fo.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Duplex semantics | A local "section odd/even" interpretation | Physical page number parity | Paged-media and print/booklet semantics are based on facing physical pages. [CITED: https://www.w3.org/TR/css-page-3/] |
| Running header/footer section selection | Ad hoc callback arity changes | Existing `%Rendro.Section{}` filters + existing `RunningContent` `{page, total}` | Callback shape is locked for backward compatibility. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`, `lib/rendro/running_content.ex`] |
| Page totals | Second render pass | Existing post-pagination context and stable token substitution | FOP documents convergence risks when text changes after total page count is known; Rendro already avoids remeasure. [CITED: https://xmlgraphics.apache.org/fop/fo.html; VERIFIED: `lib/rendro/pipeline/paginate.ex`] |
| Public page context | `%Rendro.PageContext{}` | Internal page context map | Public context is explicitly deferred until future TOC/anchor pressure clarifies shape. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`] |

**Key insight:** Mature paged-media systems separate flowing body content from repeated/static page-region content, and duplex variation is a selector over generated physical pages. [CITED: https://www.w3.org/TR/css-page-3/, https://xmlgraphics.apache.org/fop/fo.html, https://docs.reportlab.com/reportlab/userguide/ch5_platypus/]

## Common Pitfalls

### Pitfall 1: Section-Local Parity Masquerades As Duplex
**What goes wrong:** A restarted section on physical page 4 renders `only_on: :odd` because its section page number is 1. [VERIFIED: Phase 90 locked decision]
**Why it happens:** Page context now contains both physical and section-local counters. [VERIFIED: `lib/rendro/pipeline/paginate.ex`]
**How to avoid:** Pass physical `idx` to parity filtering and page context only to token substitution. [VERIFIED: codebase architecture]
**Warning signs:** Tests assert on `section_page_number` for parity instead of page index. [ASSUMED]

### Pitfall 2: Per-Region Filter Collapse
**What goes wrong:** Two footer sections, one odd and one even, collapse into a single map entry or conflict. [VERIFIED: current `region_suppress_on` map shape]
**Why it happens:** The current suppression implementation stores filters by region name. [VERIFIED: `lib/rendro/pipeline/compose.ex`]
**How to avoid:** Preserve a list of running-region entries and flatten rendered blocks after per-entry filtering. [VERIFIED: architecture analysis]
**Warning signs:** A `region_only_on` map appears in the plan. [ASSUMED]

### Pitfall 3: Validation Runs Too Late Or Misses Sections
**What goes wrong:** `page_numbering: [restart: false]` silently behaves as no restart, or `only_on: "odd"` silently renders everywhere/nowhere. [VERIFIED: current `section_numbering_restart?/1` fallback behavior]
**Why it happens:** `Validate.run/1` currently walks pages/blocks/tables, not `Document.sections`, and it runs after pagination. [VERIFIED: `lib/rendro/pipeline/validate.ex`, `lib/rendro/pipeline.ex`]
**How to avoid:** Validate section options in Compose before layout metadata is trusted, and reuse the same helper in any direct pagination fallback that consumes layout entries. [VERIFIED: pipeline analysis; ASSUMED helper placement]
**Warning signs:** Tests only call `Rendro.section/1` and do not render or call `Compose.run/1` with manually built `%Section{}`. [VERIFIED: current test patterns]

### Pitfall 4: Suppressed/Filtered Regions Reclaim Body Space
**What goes wrong:** Odd pages and even pages paginate body content differently because a missing footer changes body capacity. [VERIFIED: existing suppression-capacity regression]
**Why it happens:** Treating filtering as geometry instead of rendering visibility. [VERIFIED: `test/rendro/pipeline/paginate_test.exs`]
**How to avoid:** Keep body capacity based on template geometry, not per-page filter results. [VERIFIED: Phase 89 tests]
**Warning signs:** Page count changes when toggling `only_on`. [ASSUMED]

### Pitfall 5: Overclaiming CSS/Print Parity
**What goes wrong:** Docs imply full recto/verso, named pages, blank-page insertion, or CSS paged-media support. [VERIFIED: deferred Phase 90 ideas]
**Why it happens:** External systems expose larger page-selector models than Rendro is adding now. [CITED: https://www.princexml.com/doc/paged/, https://doc.courtbouillon.org/weasyprint/stable/api_reference.html]
**How to avoid:** Document only `only_on: :odd | :even` for running regions and leave broader claims to Phase 92. [VERIFIED: `.planning/ROADMAP.md`]
**Warning signs:** Public docs mention recto/verso aliases in Phase 90. [VERIFIED: deferred ideas]

## Code Examples

### Recommended Author API
```elixir
# Source: locked Phase 90 API shape.
footer_odd =
  Rendro.section(
    region: :footer,
    only_on: :odd,
    content: [Rendro.page_number(format: "Right {{page_number}} / S{{section_page_number}}")]
  )

footer_even =
  Rendro.section(
    region: :footer,
    only_on: :even,
    suppress_on: :first,
    content: [Rendro.page_number(format: "Left {{page_number}} / S{{section_page_number}}")]
  )
```

### Validation Helper Shape
```elixir
# Source: recommended pattern from existing errors-as-product style.
def validate_section_options!(%Rendro.Section{} = section) do
  unless section.only_on in [nil, :odd, :even] do
    raise ArgumentError,
          "invalid section :only_on #{inspect(section.only_on)}; expected :odd, :even, or nil"
  end

  unless section.page_numbering in [[], [restart: true]] do
    raise ArgumentError,
          "invalid section :page_numbering #{inspect(section.page_numbering)}; expected [] or [restart: true]"
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One global running footer/header | Page-region selectors and counters | CSS Paged Media Level 3 current TR documents `:left`, `:right`, page-margin boxes, and counters. [CITED: https://www.w3.org/TR/css-page-3/] | Rendro should model the small physical selector it needs, not broad CSS. [VERIFIED: Phase 90 scope] |
| Two-pass total page substitution | Post-pagination total context or engine-supported page counters | Prince exposes predefined `page` and `pages` counters; FOP warns manual two-pass total substitution can have convergence problems. [CITED: https://www.princexml.com/doc/paged/, https://xmlgraphics.apache.org/fop/fo.html] | Rendro should keep single pipeline pagination and non-remeasured token replacement. [VERIFIED: `lib/rendro/pipeline/paginate.ex`] |
| Imperative per-page drawing callbacks | Declarative section/page-template entries | ReportLab Platypus separates document templates, page templates, frames, and flowables. [CITED: https://docs.reportlab.com/reportlab/userguide/ch5_platypus/] | Rendro should keep sections declarative and avoid changing `RunningContent` callback arity. [VERIFIED: Phase 90 locked decision] |
| Odd/even as layout-specific hacks | Physical page selectors over generated pages | Apache FOP recommends alternating page masters and distinct static-content regions for odd/even static content. [CITED: https://xmlgraphics.apache.org/fop/fo.html] | Per-section running entries map well to Rendro's existing region model. [VERIFIED: `lib/rendro/pipeline/compose.ex`] |

**Deprecated/outdated:**
- Treating browser print support as equivalent to document-engine support is outside this phase; browser-family proof is Phase 91 and advisory only. [VERIFIED: `.planning/ROADMAP.md`]
- Recto/verso aliases are not deprecated globally, but they are intentionally deferred in Rendro because writing-mode/page-progression semantics are not modeled. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`; CITED: https://www.princexml.com/doc/paged/]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A small helper such as `Rendro.SectionOptions` is an acceptable internal shape. | Recommended Project Structure / Code Examples | Planner may instead inline validation in Compose; behavior should remain the same. |
| A2 | Warning-sign heuristics reflect likely test smells. | Common Pitfalls | Low; they guide review, not implementation. |

## Open Questions

1. **Should validation raise `ArgumentError` directly from Compose or return `{:error, %Rendro.Error{}}`?**
   - What we know: The locked context prefers clear `ArgumentError` unless a narrower error surface already exists, and Compose already raises `ArgumentError` for conflicting `suppress_on`. [VERIFIED: `.planning/phases/90-duplex-running-content/90-CONTEXT.md`, `lib/rendro/pipeline/compose.ex`]
   - What's unclear: Whether maintainers want all malformed section options to be pipeline tuple errors long term. [ASSUMED]
   - Recommendation: Use `ArgumentError` for Phase 90 to match existing Compose conflict behavior, but keep messages precise and test them. [VERIFIED: existing behavior]

2. **Should direct `Paginate.run/1` with prebuilt `options.layout.entries` validate layout entries too?**
   - What we know: Tests call `Build -> Compose -> Measure -> Paginate`, but `Paginate.run/1` has fallback paths and is directly tested. [VERIFIED: `test/rendro/pipeline/paginate_test.exs`]
   - What's unclear: Whether external users rely on direct internal pipeline stages. [ASSUMED]
   - Recommendation: Validate in Compose and defensively normalize/filter unknown layout-entry values in Paginate where cheap. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | implementation/tests | yes | 1.19.5 | none needed. [VERIFIED: `elixir --version`] |
| Erlang/OTP | implementation/tests | yes | OTP 28 / erts-16.3 | none needed. [VERIFIED: `elixir --version`] |
| Mix | tests, API manifest generation | yes | 1.19.5 | none needed. [VERIFIED: `mix --version`] |
| Context7 CLI | docs lookup | no | n/a | Official docs via web search/open were used. [VERIFIED: `command -v ctx7`] |
| Project graph | graph context | no | n/a | Code grep and planning docs were used. [VERIFIED: `ls .planning/graphs/graph.json`] |

**Missing dependencies with no fallback:** none for Phase 90 implementation. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Context7 CLI unavailable; official W3C/Prince/WeasyPrint/ReportLab/Apache FOP docs were used instead. [VERIFIED: environment audit; CITED sources below]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5. [VERIFIED: `mix test --trace`] |
| Config file | `mix.exs`; no separate ExUnit config found for this phase. [VERIFIED: `mix.exs`] |
| Quick run command | `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` [VERIFIED: command passed, 94 tests] |
| Full suite command | `mix test` [VERIFIED: Phase 89 verification passed full suite] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DUP-01 | Header/footer sections with `only_on: :odd/:even` render on physical odd/even pages. | unit/integration | `mix test test/rendro/pipeline/paginate_test.exs -x` | yes, add tests. [VERIFIED: file exists] |
| DUP-02 | Duplex filters compose with section-local numbering and no second render pass. | integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs -x` | yes, add tests. [VERIFIED: files exist] |
| DUP-03 | Invalid `only_on` and `page_numbering` fail before misleading render. | unit | `mix test test/rendro/pipeline/compose_test.exs test/rendro_builders_test.exs -x` | yes, add tests. [VERIFIED: files exist] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` [VERIFIED: command passed]
- **Per wave merge:** `mix test test/docs_contract/launch_execution_claims_test.exs test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs` plus focused tests. [VERIFIED: Phase 89 verification]
- **Phase gate:** `mix test` and `mix format --check-formatted` before `$gsd-verify-work`. [VERIFIED: Phase 89 verification pattern]

### Wave 0 Gaps
- [ ] `test/rendro/pipeline/paginate_test.exs` — add odd/even header/footer and section-restart physical-parity tests for DUP-01/DUP-02. [VERIFIED: file exists]
- [ ] `test/rendro/pipeline/compose_test.exs` — add normalized running-entry metadata and invalid option validation tests for DUP-03. [VERIFIED: file exists]
- [ ] `test/rendro_builders_test.exs` — add `only_on` field regression for public builder. [VERIFIED: file exists]
- [ ] `priv/public_api.json` — regenerate after `%Rendro.Section{}` type changes. [VERIFIED: Phase 89 manifest drift]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 90 has no identity or auth surface. [VERIFIED: `.planning/ROADMAP.md`] |
| V3 Session Management | no | Phase 90 has no sessions. [VERIFIED: `.planning/ROADMAP.md`] |
| V4 Access Control | no | Phase 90 has no authorization boundary. [VERIFIED: `.planning/ROADMAP.md`] |
| V5 Input Validation | yes | Validate `Section.only_on` and `Section.page_numbering` before render output. [VERIFIED: DUP-03] |
| V6 Cryptography | no | Phase 90 does not touch signing/protection. [VERIFIED: `.planning/ROADMAP.md`] |

### Known Threat Patterns for Pure Layout Library

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading rendered output from malformed options | Tampering / Repudiation | Fail fast with instructive validation before render. [VERIFIED: DUP-03] |
| Callback exception in running content | Denial of Service | Preserve existing `running_content_error` wrapping. [VERIFIED: `lib/rendro/pipeline/paginate.ex`, `test/rendro/pipeline/paginate_test.exs`] |
| Documentation overclaim | Repudiation | Keep docs claims narrow and backed by tests/contract rows. [VERIFIED: `AGENTS.md`, `.planning/ROADMAP.md`] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - project stack, purity, architecture, and workflow constraints. [VERIFIED: local file]
- `.planning/phases/90-duplex-running-content/90-CONTEXT.md` - locked decisions and deferred scope. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - DUP-01, DUP-02, DUP-03. [VERIFIED: local file]
- `.planning/ROADMAP.md` - Phase 90 scope and exit criteria. [VERIFIED: local file]
- `.planning/phases/89-page-context-primitive/89-VERIFICATION.md` and `89-01-SUMMARY.md` - previous phase behavior and residual risk. [VERIFIED: local files]
- `lib/rendro/section.ex`, `lib/rendro.ex`, `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/paginate.ex`, `lib/rendro/pipeline/validate.ex`, `lib/rendro/pipeline.ex` - implementation seams. [VERIFIED: local files]
- W3C CSS Paged Media Module Level 3 - duplex, left/right pages, page-margin boxes, selectors. [CITED: https://www.w3.org/TR/css-page-3/]
- Apache FOP XSL-FO Input - recto/verso static content, odd/even page masters, total-page pitfalls, region overlap. [CITED: https://xmlgraphics.apache.org/fop/fo.html]

### Secondary (MEDIUM confidence)
- Prince Paged Media documentation - page-margin boxes, page counters, `:left`/`:right`, `:recto`/`:verso`, blank-page caveats. [CITED: https://www.princexml.com/doc/paged/]
- WeasyPrint stable API reference - supported paged-media selectors, running elements, named strings. [CITED: https://doc.courtbouillon.org/weasyprint/stable/api_reference.html]
- ReportLab Platypus user guide - document/page-template/frame/flowable layering. [CITED: https://docs.reportlab.com/reportlab/userguide/ch5_platypus/]
- Paged.js documentation - page pseudo-classes and named-page selector caveats. [CITED: https://pagedjs.org/en/documentation/5-web-design-for-print/, https://pagedjs.org/en/documentation/8-named-page/]
- Antenna House spread page master docs - advanced spread behavior is real but broader than Phase 90. [CITED: https://www.antenna.co.jp/AHF/help/en/ahf-spread.html]

### Tertiary (LOW confidence)
- None used as authoritative support. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing project stack and local versions were verified. [VERIFIED: `mix.exs`, `mix.lock`, local commands]
- Architecture: HIGH - Phase 89 implementation and current pipeline seams are explicit in code. [VERIFIED: local files]
- Pitfalls: HIGH for validation/filtering/token-order pitfalls, MEDIUM for external ecosystem lessons because APIs differ across CSS/XSL-FO/Python systems. [VERIFIED: local code; CITED external docs]

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 for project-local architecture; re-check external docs if broad public documentation claims are added in Phase 92. [ASSUMED]

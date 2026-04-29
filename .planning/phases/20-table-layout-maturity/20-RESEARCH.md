# Phase 20: Table Layout Maturity - Research

**Researched:** 2026-04-29 [VERIFIED: 2026-04-29 system date]
**Domain:** deterministic multi-page table measurement, pagination, and public-contract truthfulness in Rendro core [VERIFIED: .planning/ROADMAP.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: recommendations are grounded primarily in current code paths, current phase context, and completed Phase 18/19 artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/20-table-layout-maturity/20-CONTEXT.md`. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md]

### Locked Decisions
- **D-01:** Table column sizing should become an explicit authored contract, not a content-heuristic auto-layout algorithm.
- **D-02:** Phase 20 should support a narrow deterministic column-rule model based on explicit authored widths/shares rather than measured auto-sizing defaults.
- **D-03:** Table geometry resolves inside the enclosing block/body-region width; table width should not remain an independent implied layout system on `%Rendro.Table{}`.
- **D-04:** Rows are atomic by default. Phase 20 should never fragment a single row across pages as an implicit fallback.
- **D-05:** If a measured row cannot fit even on a fresh page/body region, Rendro should fail truthfully through the existing typed paginate overflow contract rather than splitting, shrinking, clipping, or silently relaxing constraints.
- **D-06:** Best-effort or hidden fallback row splitting is explicitly out of scope because it conflicts with Rendro's deterministic hard-constraint posture from Phase 19.
- **D-07:** Split tables should repeat header rows automatically on every continuation page.
- **D-08:** Header repetition must remain body-region-aware and deterministic under the Phase 18 page-template/region model.
- **D-09:** Rendro should not inject automatic "continued" labels or other continuation chrome inside the core table primitive.
- **D-10:** If callers want continuation copy or branded page chrome, that should be authored through page templates, regions, or higher-level recipes outside the core table primitive.
- **D-11:** Unsupported `%Rendro.Table{}` affordances that currently imply behavior the engine does not honor (`width`, `border`) must be removed or deprecated in Phase 20 rather than retained as misleading no-op surface area.
- **D-12:** Phase 20 should not introduce a rich table styling DSL. The focus is deterministic layout maturity, not broad styling semantics.
- **D-13:** Public docs and examples must teach the truthful table contract: explicit column rules, repeated headers, atomic rows, and typed overflow failure when authored content cannot fit.
- **D-14:** The user delegated all Phase 20 gray areas to research-backed recommendations and wants this recommendation-first posture shifted left within future GSD discuss/research/planning flows by default, except for unusually high-impact policy decisions.

### Claude's Discretion
- Exact public field names and builder syntax for the explicit column-rule contract, as long as sizing remains authored and deterministic rather than heuristic.
- Whether unsupported table fields are hard-removed immediately or first deprecated with narrow migration guidance, as long as the public contract is truthful by the end of Phase 20.
- Exact overflow detail keys for impossible single-row fits, as long as the failure stays typed and actionable through the existing paginate error surface.

### Deferred Ideas (OUT OF SCOPE)
- Measured content-based auto-sizing or hybrid auto-sizing as future sugar once diagnostics and invariants are stronger.
- True cell fragmentation / split-row layout for tall prose cells.
- Automatic continuation labels, localized continuation copy, or other built-in continuation chrome.
- Rich table styling DSL or broad border system beyond the minimal truthful layout contract.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-10 | Engineer can render multi-page tables with deterministic column sizing, repeated headers, and explicit row-split behavior suited to invoices and reports. | `Measure` already owns deterministic geometry, `Paginate` already owns page assignment plus typed overflow, `Writer` already owns table-cell emission, and Recipes/README own the truthfulness contract, so Phase 20 should extend those seams rather than invent a parallel table engine. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex, lib/rendro/recipes.ex, README.md] |
</phase_requirements>

## Summary

The current table primitive is intentionally narrow but still demo-grade: `%Rendro.Table{}` exposes `header`, `rows`, `width`, and `border`, while `Compose` only normalizes cells into blocks, `Measure` assigns a fixed `100`-unit column width and fixed `14.4`-unit row height, `Paginate` splits only by counting whole rows against that fixed height, and `Writer` emits cell text but no table width or border semantics. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex]

Phase 20 should therefore stay inside the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline and replace constants with an explicit measured table contract: authored deterministic column rules resolved against the enclosing block/body width, measured row heights derived from actual cell blocks, atomic row pagination with repeated headers, and typed impossible-row overflow through the existing paginate error family. [VERIFIED: .planning/PROJECT.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md, .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md, lib/rendro/error.ex] [ASSUMED]

Public-surface cleanup is a separate but equally necessary part of the phase because current `%Rendro.Table{width, border}` fields imply capabilities the engine does not honor, and immediate business consumers already flow through `Rendro.Recipes.invoice/1` and `Rendro.Adapters.Accrue.recipe/1`. [VERIFIED: lib/rendro/table.ex, lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]

**Primary recommendation:** implement Phase 20 as exactly two plans: first, add internal deterministic table geometry plus atomic-row pagination; second, make the public table contract truthful by narrowing builders/docs/recipes/tests around explicit column rules and immediate unsupported-field removal plus builder-level migration guidance. [VERIFIED: .planning/ROADMAP.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]

## Recommended Decomposition

Phase 20 should decompose into exactly two plans because the roadmap allocates `2 plans`, and the work naturally splits between engine semantics and public-contract truthfulness. [VERIFIED: .planning/ROADMAP.md]

1. **Plan 20-01: Deterministic table geometry and pagination core.** Add explicit column-rule data on the table surface, resolve real column widths in `Measure`, compute measured row/header heights from cell blocks, paginate atomic rows with repeated headers, and return row-specific `:content_overflow` details when a single row cannot fit on a fresh page/body region. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] [ASSUMED]
2. **Plan 20-02: Truthful public surface, recipes, and proofs.** Remove unsupported `width`/`border` affordances from `%Rendro.Table{}`, reject legacy builder attrs with a narrow migration message, update builders/README/guides/recipes/adapters to teach explicit column rules and continuation truthfulness, and add regression/docs-contract coverage that proves the supported table contract without implying styling or auto-layout features. [VERIFIED: lib/rendro/table.ex, lib/rendro.ex, README.md, guides/integrations.md, lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex, test/docs_contract/readme_doctest_test.exs] [ASSUMED]

## Project Constraints (from AGENTS.md)

- Rendro core must remain pure Elixir with Phoenix-first but Phoenix-optional integrations. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md]
- Deterministic layout and pagination are higher priority than feature breadth. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, .planning/PROJECT.md]
- Documentation claims are product contracts and must not imply unsupported capabilities. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, .planning/PROJECT.md]
- Optional adapters must stay optional and consume core APIs rather than pull layout semantics into integration modules. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, .planning/PROJECT.md, guides/integrations.md]
- The existing pipeline `build -> compose -> measure -> paginate -> render -> validate` must remain the single engine path. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, lib/rendro/pipeline.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explicit column-rule resolution | API / Backend | — | Column rules are pure Elixir authoring data that should resolve during measurement inside the core pipeline. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/measure.ex] |
| Row/header height measurement from actual cell content | API / Backend | — | Only `Measure` has access to measured text heights before pagination. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] |
| Atomic row pagination and repeated headers | API / Backend | — | Page assignment, body-region capacity, and overflow truthfulness already live in `Paginate`. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] |
| Table-cell PDF emission | API / Backend | CDN / Static | `Writer` serializes final page content streams after pagination is complete. [VERIFIED: lib/rendro/pdf/writer.ex] |
| Public docs/recipes truthfulness | API / Backend | Frontend Server (SSR) | Rendro’s external contract is Elixir builders plus docs/recipes, not a browser runtime. [VERIFIED: lib/rendro.ex, README.md, guides/integrations.md, lib/rendro/recipes.ex] |

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version`] | Runtime for measurement, pagination, and PDF serialization. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex] | Phase 20 needs no new runtime dependency to implement deterministic table semantics. [VERIFIED: mix.exs] |
| OTP | 28 [VERIFIED: `elixir --version`] | Host runtime for the pure-core pipeline. [VERIFIED: `elixir --version`] | Already locked by the project stack and sufficient for Phase 20 core work. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md] |
| `Rendro.Pipeline.Measure` | repo-local [VERIFIED: lib/rendro/pipeline/measure.ex] | Resolve column widths and measured row/header heights. [VERIFIED: lib/rendro/pipeline/measure.ex] | Replacing current table constants belongs here because this stage already owns geometry truth. [VERIFIED: lib/rendro/pipeline/measure.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| `Rendro.Pipeline.Paginate` | repo-local [VERIFIED: lib/rendro/pipeline/paginate.ex] | Assign measured rows to pages and emit typed overflow details. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] | Existing flow/table splitting already lives here; Phase 20 should deepen that seam instead of creating a second path. [VERIFIED: lib/rendro/pipeline/paginate.ex] |
| `Rendro.PDF.Writer` | repo-local [VERIFIED: lib/rendro/pdf/writer.ex] | Render measured table cells at final positions. [VERIFIED: lib/rendro/pdf/writer.ex] | Writer already renders table cells and should consume richer geometry rather than invent it. [VERIFIED: lib/rendro/pdf/writer.ex] |
| `Rendro.Error` | repo-local [VERIFIED: lib/rendro/error.ex] | Preserve typed paginate failures and actionable next steps. [VERIFIED: lib/rendro/error.ex] | Impossible row fits should extend the current `:paginate/:content_overflow` contract rather than add a new top-level error family. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, lib/rendro/error.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Telemetry | `~> 1.4` in `mix.exs` [VERIFIED: mix.exs] | Existing pipeline instrumentation. [VERIFIED: lib/rendro/pipeline.ex] | Keep unchanged in Phase 20; richer table diagnostics belong in Phase 21, not this phase. [VERIFIED: .planning/ROADMAP.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: `mix --version`, test/test_helper.exs] | Regression proof for table measurement, pagination, writer output, and public docs. [VERIFIED: test/rendro/flow_test.exs, test/rendro/pipeline/measure_test.exs, test/rendro/pipeline/paginate_test.exs, test/rendro/pdf/writer_test.exs] | Use for every deterministic table invariant in this phase. [VERIFIED: test/ tree] |
| StreamData | `~> 1.3` in `mix.exs` [VERIFIED: mix.exs] | Optional property testing for deterministic repeated runs and column-rule edge cases. [VERIFIED: mix.exs] | Use if needed for invariant-heavy geometry checks, but ordinary ExUnit fixtures may be enough for the initial two-plan scope. [VERIFIED: mix.exs] [ASSUMED] |
| `Rendro.Recipes` / `Rendro.Adapters.Accrue` | repo-local [VERIFIED: lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex] | Immediate invoice/report consumers of the table contract. [VERIFIED: lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex] | Update in Plan 20-02 so business-document examples reflect the real supported surface. [VERIFIED: .planning/ROADMAP.md, lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Authored explicit column rules | Content-driven auto-sizing | Auto-sizing conflicts with locked decisions D-01 and D-02 and would introduce heuristic layout behavior before diagnostics are mature. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| Atomic rows with truthful overflow | Implicit row fragmentation | Hidden row splitting violates D-04 through D-06 and weakens determinism. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md] |
| Truthful narrow table DSL | Rich border/styling surface | Styling breadth would widen scope without engine support, and current `border` is already misleading. [VERIFIED: lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
mix deps.compile
```
[VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Rendro.table/2 + Rendro.block/2
        |
        v
Compose
  - normalize header and rows into block cells
        |
        v
Measure
  - resolve explicit column rules against enclosing width
  - measure each cell block
  - derive per-column widths, per-row heights, header height, total table size
        |
        v
Paginate
  - place whole table if it fits
  - otherwise split by atomic measured rows
  - repeat measured header on continuation pages
  - fail with :paginate/:content_overflow when a single row cannot fit fresh-page capacity
        |
        v
Writer
  - emit measured cell blocks at resolved x/y offsets
        |
        v
Validate
  - preserve existing PDF structural checks
```
[VERIFIED: lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex] [ASSUMED]

### Recommended Project Structure
```text
lib/rendro/
├── table.ex                         # public narrow table contract
├── pipeline/measure.ex              # table geometry resolution + row/header measurement
├── pipeline/paginate.ex             # atomic-row page assignment + repeated headers
├── pdf/writer.ex                    # final table-cell emission from measured geometry
├── error.ex                         # typed impossible-row overflow guidance
├── recipes.ex                       # canonical invoice/report usage
└── adapters/accrue.ex               # billing recipe consumer

test/rendro/
├── flow_test.exs                    # public multi-page table behavior
├── pipeline/measure_test.exs        # column-rule and row-height measurement
├── pipeline/paginate_test.exs       # repeated headers and impossible-row failures
├── pdf/writer_test.exs              # rendered cell positioning and repeated-header output

test/
└── rendro_builders_test.exs         # table builder truthfulness / deprecated-field behavior
```
[VERIFIED: current module/test layout in `lib/` and `test/`] [ASSUMED]

**Recommended structural change:** keep the public surface in `lib/rendro/table.ex`, but introduce private helper structs or helper functions for resolved column geometry and measured rows instead of pushing more anonymous table metadata into raw `%Rendro.Table{}` fields. The single public sizing field should be `columns`, expressed as an ordered list of deterministic rule tuples such as `{:fixed, width}` and `{:share, weight}` so authored sizing remains explicit without adding a second DSL. [VERIFIED: current `%Rendro.Table{}` is small and public in lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]

### Pattern 1: Resolve Column Rules During Measurement
**What:** Resolve explicit authored column rules against the available table width during `Measure`, then use the resolved widths for every downstream stage. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, lib/rendro/pipeline/measure.ex]  
**When to use:** Every flow or fixed table block before pagination. [VERIFIED: lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex]  
**Example:**
```elixir
# Source: current Measure/Paginate table seam in lib/rendro/pipeline/measure.ex
available_width = block.width || layout.body_region.width
resolved_columns = resolve_columns(table.columns, available_width)
measured_header = measure_row(table.header, resolved_columns, font)
measured_rows = Enum.map(table.rows, &measure_row(&1, resolved_columns, font))
```
[ASSUMED]

### Pattern 2: Paginate Measured Rows, Not Synthetic Fixed Heights
**What:** Split a table by accumulated measured row heights plus repeated-header height, not by `floor(available_h / 14.4)`. [VERIFIED: current fixed-height split exists in lib/rendro/pipeline/paginate.ex]  
**When to use:** Any table block that does not fit wholly on the current page/body region. [VERIFIED: lib/rendro/pipeline/paginate.ex]  
**Example:**
```elixir
# Source: current Paginate split seam in lib/rendro/pipeline/paginate.ex
{fit_rows, rest_rows} =
  Enum.reduce_while(rows, {[], header_height}, fn row, {acc, used_height} ->
    next_height = used_height + row.height

    if next_height <= available_height do
      {:cont, {acc ++ [row], next_height}}
    else
      {:halt, {acc, used_height}}
    end
  end)
```
[ASSUMED]

### Pattern 3: Impossible Single-Row Fits Stay in Existing Overflow Contract
**What:** If a single measured row cannot fit on a fresh page/body region with the repeated header, throw `:paginate/:content_overflow` with row-specific details. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, lib/rendro/error.ex]  
**When to use:** Any table continuation decision where `current_page` is empty and the first remaining row still exceeds capacity. [VERIFIED: lib/rendro/pipeline/paginate.ex] [ASSUMED]  
**Example:**
```elixir
# Source: current overflow contract in lib/rendro/pipeline/paginate.ex and lib/rendro/error.ex
throw(
  {:error, :content_overflow,
   %{
     overflow_source: :bounded_region,
     region: :body,
     row_index: row_index,
     row_height: row_height,
     header_height: header_height,
     max_height: max_height
   }}
)
```
[ASSUMED]

### Pattern 4: Public Docs Teach Only Supported Table Semantics
**What:** README, guides, and recipes should show explicit column rules, repeated headers, atomic rows, and truthful overflow boundaries, and should not mention borders, auto-fit, or continuation labels as supported core features. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, README.md, guides/integrations.md]  
**When to use:** Every public-facing example changed in Plan 20-02. [VERIFIED: README.md, guides/integrations.md, lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex]  

### Anti-Patterns to Avoid
- **Keeping `width` on `%Rendro.Table{}` as a live surface while resolving width from the enclosing block anyway:** that preserves a misleading second geometry system. [VERIFIED: lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
- **Continuing fixed `100`-unit columns and fixed `14.4`-unit rows:** current constants are the core reason the primitive remains demo-grade. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex]
- **Deriving continuation fit from row count instead of measured height:** this breaks immediately once cell wrapping or differing cell heights are introduced. [VERIFIED: lib/rendro/pipeline/paginate.ex] [ASSUMED]
- **Adding continuation labels inside the table primitive:** D-09 and D-10 explicitly defer that to templates/recipes. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
- **Documenting `border` or rich styling before the writer supports it:** current writer emits text only for tables. [VERIFIED: lib/rendro/table.ex, lib/rendro/pdf/writer.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Heuristic auto-layout | Content-driven width guessing or browser-like table layout | Explicit authored width/share rules resolved in `Measure` | Locked decisions require authored deterministic sizing rather than heuristics. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| Hidden row fragmentation | Per-cell split logic or text clipping inside a row | Atomic rows plus truthful overflow | Phase 20 explicitly forbids silent row fragmentation. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| New error family | `:table_overflow` or ad hoc exceptions | Existing `%Rendro.Error{stage: :paginate, reason: :content_overflow}` with richer `details` | Phase 18 and 19 already established typed paginate overflow as the user-facing failure surface. [VERIFIED: lib/rendro/error.ex, .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md] |
| Table semantics in adapters | Phoenix/Oban/Accrue-specific table behavior | Core table behavior in Rendro, adapters as consumers only | Integration docs explicitly keep layout semantics in core. [VERIFIED: guides/integrations.md, /Users/jon/projects/rendro/AGENTS.md] |

**Key insight:** Phase 20 is not a styling phase; it is a geometry-and-truthfulness phase, so the winning strategy is to make table measurement and row pagination real without broadening the authored semantics beyond what the engine can prove. [VERIFIED: .planning/ROADMAP.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]

## Existing Code / Runtime State Inventory

### Current Code Inventory

| Surface | Items Found | Why It Matters |
|---------|-------------|----------------|
| Public table struct | `%Rendro.Table{rows, header, width: :fill, border: true}` and `Rendro.table/2` builder. [VERIFIED: lib/rendro/table.ex, lib/rendro.ex] | `width` and `border` currently over-promise compared with the engine, so public-surface cleanup is mandatory. [VERIFIED: lib/rendro/table.ex, lib/rendro/pdf/writer.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| Compose behavior | Table headers/rows are normalized so each cell becomes a `%Rendro.Block{}`. [VERIFIED: lib/rendro/pipeline/compose.ex] | This is the right seam to preserve; Phase 20 can keep cell normalization and add geometry later. [VERIFIED: lib/rendro/pipeline/compose.ex] [ASSUMED] |
| Measurement behavior | `Measure` uses `row_height = 14.4`, `col_width = 100`, computes table width from column count, and measures cell blocks without feeding those measurements back into row height or column width resolution. [VERIFIED: lib/rendro/pipeline/measure.ex] | This is the main implementation gap for `LAY-10`. [VERIFIED: lib/rendro/pipeline/measure.ex, .planning/REQUIREMENTS.md] |
| Pagination behavior | `Paginate` splits tables only when `current_h + block_h > max_h`, repeats the header by carrying `header` into the remaining table, and fits rows via `floor((available_h - header_h) / row_height)`. [VERIFIED: lib/rendro/pipeline/paginate.ex] | Continuation exists, but it is row-count-based and constant-height-based rather than measured-row-based. [VERIFIED: lib/rendro/pipeline/paginate.ex] |
| Impossible-fit behavior | `check_overflow!/4` reports block-level overflow, but current table rows can never trigger row-specific impossible-fit details because every row is treated as `14.4` units tall. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] | Phase 20 needs row-aware overflow metadata to keep D-05 truthful once row heights become real. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED] |
| Writer behavior | `Writer` renders table header/rows by rendering each cell block at offsets from the table block origin; it does not render borders, table width, or styling chrome. [VERIFIED: lib/rendro/pdf/writer.ex] | This proves `border` is currently unsupported and that geometry must be precomputed before render. [VERIFIED: lib/rendro/pdf/writer.ex, lib/rendro/table.ex] |
| Business consumers | `Rendro.Recipes.invoice/1` and `Rendro.Adapters.Accrue.recipe/1` already emit invoice tables. [VERIFIED: lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex] | These are the first downstream call sites to update once explicit column rules land. [VERIFIED: lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex] |
| Existing tests | `flow_test.exs` proves a simple 50-row split and header repetition; `measure_test.exs` has no table-specific row-height assertions; `paginate_test.exs` focuses on flow breaks more than table geometry; `writer_test.exs` has no table-layout-specific positioning assertions. [VERIFIED: test/rendro/flow_test.exs, test/rendro/pipeline/measure_test.exs, test/rendro/pipeline/paginate_test.exs, test/rendro/pdf/writer_test.exs] | Validation coverage exists but needs deeper table-specific proofs. [VERIFIED: test/ tree] |

### Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None; current table behavior is defined by code and tests, not persisted application data. [VERIFIED: requested files plus `rg -n "Rendro.table|%Rendro.Table" lib test README.md guides .planning`] | Code edit only. [VERIFIED: repo search results] |
| Live service config | None; no external service or UI-managed configuration controls table layout semantics. [VERIFIED: guides/integrations.md, requested source files] | None. [VERIFIED: guides/integrations.md] |
| OS-registered state | None; table behavior is not registered with system services. [VERIFIED: requested source files and project scope] | None. [ASSUMED] |
| Secrets/env vars | None; table behavior does not depend on env-var names or secrets. [VERIFIED: requested source files, guides/integrations.md] | None. [VERIFIED: requested source files] |
| Build artifacts | None specific to Phase 20 semantics beyond normal recompilation/test runs. [VERIFIED: table behavior is repo-local Elixir code in `lib/` and `test/`] | Recompile and rerun tests after code changes. [VERIFIED: mix.exs] |

## Common Pitfalls

### Pitfall 1: Two Width Systems
**What goes wrong:** table layout tries to honor both `%Rendro.Table.width` and enclosing block/body-region width, creating contradictory geometry rules. [VERIFIED: lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]  
**Why it happens:** the current public struct still exposes `width`, but D-03 says table geometry should resolve inside the enclosing width instead. [VERIFIED: lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]  
**How to avoid:** make `columns` the only authored sizing contract and remove misleading top-level table width from the public struct. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]  
**Warning signs:** docs or builders mention both `Rendro.block(width: ...)` and `Rendro.table(width: ...)` as active controls. [VERIFIED: lib/rendro/table.ex, lib/rendro/block.ex] [ASSUMED]

### Pitfall 2: Row Count Instead of Row Height
**What goes wrong:** pagination keeps using fixed row counts after column rules allow cells to wrap and vary in height. [VERIFIED: lib/rendro/pipeline/paginate.ex]  
**Why it happens:** current split logic divides available height by a constant `14.4` row height. [VERIFIED: lib/rendro/pipeline/paginate.ex]  
**How to avoid:** store measured row/header heights in the measured table representation and accumulate those exact heights during splits. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex] [ASSUMED]  
**Warning signs:** a row with longer text still consumes exactly one synthetic row slot in pagination tests. [VERIFIED: lib/rendro/pipeline/paginate.ex, test/rendro/flow_test.exs] [ASSUMED]

### Pitfall 3: Writer-Led Layout
**What goes wrong:** cell positions are computed ad hoc during render rather than as part of measured geometry. [VERIFIED: lib/rendro/pdf/writer.ex]  
**Why it happens:** the current writer already offsets cells from table origin, which can tempt implementers to keep more geometry logic there. [VERIFIED: lib/rendro/pdf/writer.ex]  
**How to avoid:** keep writer as a consumer of final measured table coordinates only. [VERIFIED: .planning/PROJECT.md, lib/rendro/pdf/writer.ex] [ASSUMED]  
**Warning signs:** `Writer` starts recalculating column widths or deciding page splits. [VERIFIED: current writer does not do that in lib/rendro/pdf/writer.ex] [ASSUMED]

### Pitfall 4: Docs Truthfulness Drift
**What goes wrong:** examples imply auto-fit, borders, or continuation labels before the engine supports them. [VERIFIED: .planning/PROJECT.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]  
**Why it happens:** `%Rendro.Table{}` currently exposes unsupported fields and recipes already present invoice/report use cases. [VERIFIED: lib/rendro/table.ex, lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex]  
**How to avoid:** treat README/guides/recipes as contractual deliverables in Plan 20-02. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, README.md, guides/integrations.md] [ASSUMED]  
**Warning signs:** public docs mention styling or continuation chrome with no corresponding writer or test proof. [VERIFIED: lib/rendro/pdf/writer.ex, test/docs_contract/readme_doctest_test.exs] [ASSUMED]

## Code Examples

Verified current seams from official project sources:

### Current Table Normalization
```elixir
# Source: /Users/jon/projects/rendro/lib/rendro/pipeline/compose.ex
defp compose_block(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
  normalized_header = if table.header, do: normalize_row(table.header), else: nil
  normalized_rows = Enum.map(table.rows, &normalize_row/1)
  %{block | content: %{table | header: normalized_header, rows: normalized_rows}}
end
```

### Current Table Split Contract
```elixir
# Source: /Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex
defp split_table(%Rendro.Table{rows: rows, header: header} = table, available_h) do
  row_height = 14.4
  header_h = if header, do: row_height, else: 0

  if available_h < header_h + row_height do
    {nil, table}
  else
    fit_count = floor((available_h - header_h) / row_height)
    split_table_rows(table, rows, fit_count)
  end
end
```

### Current Table Rendering Surface
```elixir
# Source: /Users/jon/projects/rendro/lib/rendro/pdf/writer.ex
defp render_block(%Rendro.Block{content: %Rendro.Table{} = table} = block, page, font) do
  header_ops =
    if table.header do
      Enum.map(table.header, &render_block(&1, page, font, block.x, block.y))
    else
      []
    end

  rows_ops =
    Enum.map(table.rows, fn row ->
      Enum.map(row, &render_block(&1, page, font, block.x, block.y))
    end)

  [header_ops | rows_ops] |> List.flatten() |> Enum.join("\n")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded table width of `500` during measurement | Table width now derives from column count times fixed `100`-unit columns. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md, lib/rendro/pipeline/measure.ex] | Phase 18 Plan 03. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md] | Fit validation now matches current renderer behavior better, but still does not provide authored or measured table geometry. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md, lib/rendro/pipeline/measure.ex] |
| Implicit flow behavior without keep semantics | Phase 19 added hard keep/break semantics and truthful impossible-layout overflow. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md, lib/rendro/pipeline/paginate.ex] | Phase 19. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md] | Phase 20 should mirror that hard-constraint posture for table rows instead of inventing best-effort fallback behavior. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |

**Deprecated/outdated:**
- `%Rendro.Table.width` as an active geometry contract is outdated relative to D-03 because geometry should resolve from enclosing width plus explicit column rules instead. [VERIFIED: lib/rendro/table.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
- `%Rendro.Table.border` as a supported capability is outdated because the writer does not render table borders. [VERIFIED: lib/rendro/table.ex, lib/rendro/pdf/writer.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 20 should split into engine semantics first and public-contract cleanup second rather than another two-plan boundary. | Recommended Decomposition | Plan granularity may need reshuffling, but the technical work still stands. |
| A2 | Private helper structs/functions for measured table geometry are the best way to keep `%Rendro.Table{}` narrow. | Recommended Project Structure | The implementation may instead stay inline in existing modules, increasing file complexity. |
| A3 | Existing ExUnit fixtures may be sufficient without mandatory StreamData coverage in Phase 20. | Standard Stack / Validation Architecture | Determinism edges could be under-tested if example-based coverage misses combinations. |
| A4 | OS-registered runtime state is irrelevant for Phase 20 because table semantics are code-only. | Runtime State Inventory | A hidden out-of-repo automation step would need separate documentation, though none appears in the requested project files. |

## Open Questions (RESOLVED)

1. **What is the narrowest truthful public syntax for explicit column rules?** [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
   **Resolved:** use a single public `columns: [...]` field on `%Rendro.Table{}` as the sole sizing contract in Phase 20. Each entry should be an explicit deterministic rule tuple, with the supported Phase 20 shapes limited to `{:fixed, width}` and `{:share, weight}`. This keeps sizing authored, ordered, and easy to validate while avoiding a broader helper DSL or heuristic auto-layout surface. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, lib/rendro/table.ex] [ASSUMED]

2. **Should unsupported table fields be removed immediately or deprecated for one phase?** [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
   **Resolved:** remove `width` and `border` from the public `%Rendro.Table{}` contract in Phase 20 and reject legacy builder attrs at `Rendro.table/2` with a narrow migration-oriented error message. Repo-local call sites are limited enough that immediate cleanup is feasible, and retaining no-op struct fields would continue to advertise unsupported behavior. [VERIFIED: lib/rendro/recipes.ex, lib/rendro/adapters/accrue.ex, test/rendro/flow_test.exs, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: `mix --version`, test/test_helper.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro/pdf/writer_test.exs test/rendro_builders_test.exs`. [VERIFIED: requested test files exist in `test/`] |
| Full suite command | `mix ci`. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAY-10 | Explicit column rules resolve deterministically against enclosing width. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] | unit | `mix test test/rendro/pipeline/measure_test.exs -x` | ✅ [VERIFIED: test/rendro/pipeline/measure_test.exs] |
| LAY-10 | Measured row/header heights drive pagination and repeated headers. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] | integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs -x` | ✅ [VERIFIED: test/rendro/pipeline/paginate_test.exs, test/rendro/flow_test.exs] |
| LAY-10 | Impossible single-row fits return typed `:paginate/:content_overflow` details. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md, lib/rendro/error.ex] | integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs -x` | ✅ [VERIFIED: test/rendro/pipeline/paginate_test.exs, test/rendro/flow_test.exs] |
| LAY-10 | Public table API/docs no longer imply unsupported width/border behavior. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/table.ex, README.md] | docs-contract + unit | `mix test test/rendro_builders_test.exs test/docs_contract/readme_doctest_test.exs -x` | ✅ [VERIFIED: test/rendro_builders_test.exs, test/docs_contract/readme_doctest_test.exs] |
| LAY-10 | Final PDF output repeats header text and places cells according to resolved geometry. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pdf/writer.ex] | integration | `mix test test/rendro/pdf/writer_test.exs test/rendro/flow_test.exs -x` | ✅ [VERIFIED: test/rendro/pdf/writer_test.exs, test/rendro/flow_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs -x`. [VERIFIED: requested test files exist]
- **Per wave merge:** `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro/pdf/writer_test.exs test/rendro_builders_test.exs`. [VERIFIED: requested test files exist]
- **Phase gate:** `mix ci` plus docs-contract coverage for any README/guides changes. [VERIFIED: mix.exs, test/docs_contract/readme_doctest_test.exs]

### Wave 0 Gaps
- [ ] Add table-specific measurement tests that assert per-column resolved widths and per-row measured heights instead of only text-block heights. [VERIFIED: test/rendro/pipeline/measure_test.exs] [ASSUMED]
- [ ] Add paginate tests for impossible single-row fits with row-specific overflow metadata. [VERIFIED: test/rendro/pipeline/paginate_test.exs, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED]
- [ ] Add writer tests that assert cell x offsets from resolved column geometry and repeated-header rendering across multiple pages. [VERIFIED: test/rendro/pdf/writer_test.exs] [ASSUMED]
- [ ] Add docs-contract coverage for the new truthful table example surface if README/guides gain table examples. [VERIFIED: README.md, test/docs_contract/readme_doctest_test.exs] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 20 is layout-engine work in core, not auth work] | — |
| V3 Session Management | no [VERIFIED: Phase 20 is layout-engine work in core, not session work] | — |
| V4 Access Control | no [VERIFIED: Phase 20 is layout-engine work in core, not access-control work] | — |
| V5 Input Validation | yes [VERIFIED: user-authored table rows, headers, and column rules are phase inputs] | Validate column-rule shapes and reject impossible or contradictory authored geometry through typed stage errors. [VERIFIED: lib/rendro/error.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED] |
| V6 Cryptography | no [VERIFIED: Phase 20 does not alter cryptographic behavior] | — |

### Known Threat Patterns for Rendro Table Layout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized cell content or impossible row geometry causes excessive pagination work or opaque failure | Denial of Service | Fail early in `Paginate` with typed overflow once a single measured row cannot fit a fresh page/body region. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] [ASSUMED] |
| Misleading no-op public fields cause operators to believe borders or width constraints are enforced when they are not | Tampering | Remove or deprecate unsupported fields and update docs/tests so unsupported semantics are not authorable. [VERIFIED: lib/rendro/table.ex, lib/rendro/pdf/writer.ex, .planning/phases/20-table-layout-maturity/20-CONTEXT.md] |
| Unbounded table growth silently bypasses authored layout constraints | Repudiation | Preserve typed overflow and existing max-pages policy checks instead of clipping or shrinking content. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/error.ex, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/20-table-layout-maturity/20-CONTEXT.md` - locked Phase 20 decisions, discretion, deferred scope, and implementation posture. [VERIFIED: .planning/phases/20-table-layout-maturity/20-CONTEXT.md]
- `.planning/ROADMAP.md` - Phase 20 goal, success criteria, and exact `2 plans` allocation. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `LAY-10` requirement text. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` - milestone constraints, architecture boundaries, and docs-truthfulness posture. [VERIFIED: .planning/PROJECT.md]
- `.planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md` - precedent for truthful overflow and renderer-aligned measurement. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md]
- `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md`, `19-RESEARCH.md`, `19-02-SUMMARY.md`, `19-03-SUMMARY.md` - hard-constraint pagination posture and docs truthfulness precedent. [VERIFIED: listed Phase 19 files]
- `lib/rendro/table.ex`, `lib/rendro.ex`, `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/measure.ex`, `lib/rendro/pipeline/paginate.ex`, `lib/rendro/pdf/writer.ex`, `lib/rendro/error.ex`, `lib/rendro/recipes.ex`, `lib/rendro/adapters/accrue.ex` - current implementation seams and business consumers. [VERIFIED: listed source files]
- `test/rendro/flow_test.exs`, `test/rendro/pipeline/measure_test.exs`, `test/rendro/pipeline/paginate_test.exs`, `test/rendro/pdf/writer_test.exs`, `test/rendro_builders_test.exs` - current proof coverage and gaps. [VERIFIED: listed test files]
- `README.md`, `guides/integrations.md` - current public contract and integration boundaries. [VERIFIED: README.md, guides/integrations.md]
- `mix.exs`, `elixir --version`, `mix --version` - current stack and validation commands. [VERIFIED: mix.exs, `elixir --version`, `mix --version`]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research relied on primary repo sources only]

### Tertiary (LOW confidence)
- None. [VERIFIED: no web-only or single-source external claims used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 20 can stay inside existing repo-local pipeline modules and current Elixir/OTP runtime. [VERIFIED: mix.exs, lib/rendro/pipeline.ex, requested source files]
- Architecture: HIGH - current code already centralizes table normalization, measurement, pagination, and rendering in the exact seams this phase needs. [VERIFIED: lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex]
- Pitfalls: HIGH - the current constants, unsupported fields, and limited tests are directly observable in the repo. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, test/rendro/flow_test.exs]

**Research date:** 2026-04-29 [VERIFIED: 2026-04-29 system date]
**Valid until:** 2026-05-29 for repo-local architecture guidance unless Phase 20 implementation lands sooner and changes the table seams materially. [VERIFIED: current repo state] [ASSUMED]

## RESEARCH COMPLETE

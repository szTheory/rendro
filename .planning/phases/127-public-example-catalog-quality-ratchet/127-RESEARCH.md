# Phase 127: Public example catalog & quality ratchet - Research

**Researched:** 2026-08-17  
**Domain:** Deterministic Elixir PDF catalog artifacts and hash-bound human-quality dispositions  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Ship exactly 32 cells: six unbranded `Theme.default/0` light baselines, twelve Phase-125 data-backed brand/preset pairs in light/dark, and Aurora Live Ticket × Brutalist in light/dark. Assert exact count and hard ceiling 32.
- **D-02:** One explicit, ordered curated registry owns public membership. Fixture discovery may validate a referenced input, never silently add a public cell; never calculate domain × brand × preset × mode.
- **D-03:** Pair matrix, each light then dark: Invoice Northline Logistics × Swiss; Cedar Mutual × Corporate-Classic. Payslip Northline Logistics × Swiss; Cedar Mutual × Corporate-Classic. Statement Signal Ledger × Minimal-Mono; Aster Research Fund × Editorial. Receipt Poppy & Grain × Humanist; Circuit Supply Co. × Minimal-Mono. Certificate Aster Institute × Swiss; Meridian Arts Fellowship × Editorial. Ticket Field Notes Conference × Minimal-Mono; The Letterpress Hall × Editorial; Aurora Live × Brutalist.
- **D-04:** Represent the complete sixth Brutalist preset through existing Aurora Live Ticket. Add missing slug/accent/preset metadata only as safe data under `priv/examples/ticket/aurora-live/`; never a brand module/genre branch; preserve historical unthemed rendering.
- **D-05:** Phase 128 can promise an exact preview only for combinations present in `catalog.json`; disclose broader code generation rather than fabricate/approximate tiles.
- **D-06:** One complete deterministic render per cell, exactly one public page-one PNG; no all-page raster catalog or PDF viewer.
- **D-07:** Record page-one PNG SHA-256, complete source-PDF SHA-256, and exact `page_count`; render/check the full PDF but do not commit source PDFs or trailing-page PNGs.
- **D-08:** Preserve native geometry: portrait families, landscape Certificate, native A6 Ticket; store page/DPI/dimensions and never crop/stretch/normalize.
- **D-09:** Keep bounded representative first/final-page advisory proof for paginating families outside `assets/rendro/catalog/`; Certificate/Ticket assert one page. Deterministic PDF, pinned-PDFium advisory raster, and human review remain separate lanes.
- **D-10:** Each cell has concrete nonempty alt and non-duplicative caption. For multi-page cells, consumer copy is `Preview: page 1 of N`.
- **D-11:** Score exactly twelve flagships, light then dark: Cedar Mutual Corporate-Classic Invoice, Northline Swiss Payslip, Signal Ledger Minimal-Mono Statement, Poppy & Grain Humanist Receipt, Meridian Editorial Certificate, and Aurora Brutalist Ticket.
- **D-12:** Every catalog ID has one `review_status: scored | unscored` disposition in `priv/quality/rubric_scores.json`. Scored records carry dimensions/gates/verdict/reviewer/date/evidence/PNG/PDF hashes; unscored records carry same identity plus dated nonempty reason. Existing launch scores remain intact.
- **D-13:** Freshness is derived from ID/evidence path/PNG hash/source-PDF hash, never reviewer-entered. Missing/new/changed/orphaned/mismatched projection fails CI; changed scored cells re-review, changed unscored cells explicitly rebind.
- **D-14:** Preserve `content_hierarchy == 5`, other core dimensions `>= 4`, and both gates true for `passed: true`; evidence applies only to named exact cell/hashes, never broad quality/accessibility/print claims.
- **D-15:** `passed: false` is valid scored evidence. False-to-true needs superseded evidence plus nonempty behavioral-fix resolution reference; generation/curation never flips it.
- **D-16:** Generation writes only artifacts/manifest, never reviewer records. A separate join/check validates hashes/thresholds with cell-specific next actions. `catalog.json` may expose a minimal derived quality projection; `rubric_scores.json` is source of truth and projection drift fails.
- **D-17:** Inspect flagships full readable size, family by family, light immediately before dark; a contact sheet is navigation only. Keep concise justifications and no-overclaim language.
- **D-18:** Add private `Rendro.Catalog` (`@moduledoc false`, absent `priv/public_api.json`) and conventional `mix rendro.catalog.gen [--pdfium PATH]` write/bless plus `mix rendro.catalog.check [--pdfium PATH]` read-only tasks.
- **D-19:** Immutable lowercase ASCII IDs are `<family>--<brand>--<preset>--<mode>`; defaults use `<family>--default--default--light`. Assets are `assets/rendro/catalog/<family>/<brand>/<preset>-<mode>.png`. Validate slugs and safe-relative paths.
- **D-20:** Fixed order: Invoice, Statement, Receipt, Certificate, Payslip, Ticket. Per family: baseline, D-03 pair order, light then dark. Never map/filesystem ordering.
- **D-21:** Versioned `catalog.json` has generator/renderer metadata and ordered cells with identity, family/brand/preset/theme/accent/mode, recipe/fixture, PNG/PDF hashes, page/page count/DPI/native dimensions, renderer, alt/caption, and minimal quality projection. Exclude raw fixtures, font mechanics, docs structs, rubric justifications, caches, and internal options.
- **D-22:** Baselines retain truthful fields: `brand: null`, `preset: null`, `theme: "default"`, `mode: "light"`; no fake brand/accent.
- **D-23:** Checker reports ID plus condition and next action for asset/path/duplicate/order/count/renderer/hash/page-count/disposition/projection failures; never recommends blanket re-bless.
- **D-24:** Catalog module, quality records, schemas, and artifacts are dev/docs assets, not Hex runtime payload; Phase 128 consumes static ExDoc assets and core stays pure/dependency-free.
- **D-25:** User-facing status is `Scored — passes current rubric`, `Scored — needs work`, or `Not yet scored`, never an approval boolean. Dark copy retains `Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim.`

### the agent's Discretion

Private helper names, additive disposition-union structure, JSON nesting, in-run caching/parallelism, and whether current multi-page proof satisfies D-09 are planner choices. Aurora’s exact accent may be selected from the existing closed palette after review, recorded only as fixture/catalog data. The 32-cell ceiling, pair matrix, flagship set, page-one policy, hash-bound dispositions, domain-first contract, and launch-gallery isolation are not discretionary. [VERIFIED: CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

- Phase 128 owns static browse/filter/configure/copy UI, URL state, palette presentation, preview disclosure, snippets, `mix rendro.gen.theme`, and Livebook.
- Phase 129 owns public guide/README/HexDocs/support-matrix closure and claim tripwires.
- No every-page browsing, PDF download/viewer, arbitrary color approximation, live render, server/database/accounts/saved themes, or automated/LLM taste score.
- No expansion beyond 32 cells or pair-matrix change without a new product decision. [VERIFIED: CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Keep core pure: no Phoenix, Oban, or admin dependency. [VERIFIED: AGENTS.md]
- Preserve deterministic versus advisory lanes in CI/docs. [VERIFIED: AGENTS.md]
- Documentation claims are contracts; do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Keep `build -> compose -> measure -> paginate -> render -> validate` and two APIs/one engine. [VERIFIED: AGENTS.md]
- Use GSD workflow for changes. [VERIFIED: AGENTS.md]

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| CATALOG-01 | Deterministic sibling catalog artifacts. | Explicit 32-spec registry, full PDF/page-one PNG/hash/page-count manifest, generation/check seams. [VERIFIED: REQUIREMENTS.md; CONTEXT.md] |
| CATALOG-02 | Machine-tested row budget. | Test exact ordered IDs, `count == 32`, and hard ceiling `count <= 32`; never derive membership. [VERIFIED: REQUIREMENTS.md; CONTEXT.md] |
| CATALOG-03 | By-domain, brand-tagged manifest keys. | Stable ID/path grammar and truthful default nulls in a consumer-focused manifest. [VERIFIED: REQUIREMENTS.md; CONTEXT.md] |
| CATALOG-04 | Additive human rubric ratchet. | One-to-one dispositions plus a fail-loud identity/hash/projection join; generator never writes human records. [VERIFIED: REQUIREMENTS.md; CONTEXT.md] |

## Summary

Implement Phase 127 as a new private sibling artifact system, not as an extension of `Rendro.LaunchArtifacts`. The existing gallery already proves the relevant mechanics: ordered in-code specs, deterministic source-PDF rendering, pinned-PDFium page-one rasterization, hashes/dimensions, a writing generator, and a non-writing checker. Reuse those mechanics for the locked 32 cells, but do not add launch-gallery README/manual behavior. [VERIFIED: `lib/rendro/launch_artifacts.ex`; `lib/mix/tasks/rendro/launch_artifacts/{gen,check}.ex`; CONTEXT.md]

Quality is a relational contract: generated catalog cells own artifact identity while `rubric_scores.json` owns human review disposition. A separate check joins them by exact ID, evidence path, PNG SHA, and complete-PDF SHA; the public manifest carries only a derived, checkable three-state projection. This retains existing threshold arithmetic and permits valid failing scores without treating unscored cells as passed. [VERIFIED: `test/docs_contract/rubric_manifest_contract_test.exs`; `priv/schemas/rubric_scores.schema.json`; CONTEXT.md]

**Primary recommendation:** One explicit ordered 32-cell registry plus shared render pipeline in `Rendro.Catalog`, followed by independent catalog-quality join validation. Never compute public membership, freshness, or approval from the filesystem or legacy launch gallery. [VERIFIED: CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Registry, fixture dispatch, deterministic PDF | API / Backend | Storage — committed files | Private Elixir composition; no server/database. [VERIFIED: CONTEXT.md; AGENTS.md] |
| Page-one PNG and renderer identity | CDN / Static | API / Backend | Offline PDFium generation produces static docs assets. [VERIFIED: `launch_artifacts.ex`] |
| `catalog.json` contract | CDN / Static | Browser / Client | Phase 127 writes it; Phase 128 reads it statically. [VERIFIED: CONTEXT.md; `mix.exs`] |
| Disposition/freshness validation | API / Backend | CDN / Static | Private checks calculate joins; public manifest exposes minimum derived state. [VERIFIED: CONTEXT.md] |
| UI browsing/configuration | Browser / Client | CDN / Static | Deferred to Phase 128. [VERIFIED: CONTEXT.md] |

## Standard Stack

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Elixir / Mix | 1.19.5 | Module, render dispatch, Mix tasks, ExUnit. | Installed runtime and existing artifact idiom. [VERIFIED: local `mix --version`; `mix.exs`] |
| Rendro renderer + `Rendro.Theme.Presets` | repository source | Full PDFs, preset construction, font registration. | One pure render engine; preset fonts are document-owned. [VERIFIED: `lib/rendro/theme/presets.ex`] |
| PDFium adapter | pinned v0.11.0 | Page-one PNG/dimensions/hash/provenance. | Existing bounded advisory evidence, not universal viewer proof. [VERIFIED: `priv/pdfium_pin.json`; `launch_artifacts.ex`] |
| JSV | existing dev/test dep | Additive quality schema validation. | Current rubric contract uses it. [VERIFIED: `mix.exs`; rubric contract test] |
| ExDoc | `~> 0.40` | Static asset copy-through. | Existing `assets` mapping makes future catalog assets available with no Node/server. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html; VERIFIED: `mix.exs`] |

**Installation:** None—no new package, Node build, service, database, or runtime dependency. [VERIFIED: ROADMAP.md; CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
explicit ordered 32-cell registry
       │ validate literal fixture path / ID / order
       ▼
Examples.load! → ExamplesData.transform_* → recipe.document(theme)
       │                                  │
       │                   preset cells: Presets.register_fonts/2
       ▼
Rendro.render(deterministic: true) → full PDF → SHA-256 + page_count
       │                                         │
       └──── pinned PDFium page 1 → PNG + dimensions + SHA ┘
                                             │
                           gen writes assets/rendro/catalog + catalog.json
                                             │
rubric_scores.json ──────── catalog-quality join/check ─── fail-loud errors
                                             │
                          derived minimal quality projection → Phase 128
```

Generator owns artifacts; reviewer records own judgment; exact identity/path/PNG/PDF hashes are their only coupling. [VERIFIED: CONTEXT.md]

### Recommended Project Structure

```text
lib/rendro/catalog.ex
lib/mix/tasks/rendro/catalog/{gen,check}.ex
assets/rendro/catalog/<family>/<brand>/<preset>-<mode>.png
assets/rendro/catalog.json
priv/quality/rubric_scores.json
priv/schemas/rubric_scores.schema.json
test/rendro/catalog_test.exs
test/docs_contract/catalog_{manifest,quality}_contract_test.exs
```

### Pattern 1: Explicit registry and one render dispatcher

Literal registry maps contain ID, family, fixture, brand/preset/theme/accent/mode, expected PNG path, alt, and caption. A lookup can dispatch known recipe transforms but must never calculate catalog membership. [VERIFIED: CONTEXT.md; `lib/rendro/examples.ex`]

```elixir
# Source: local LaunchArtifacts registry and Phase 127 locked decisions
defp render_spec(spec) do
  data = spec.fixture |> Rendro.Examples.load!() |> transform(spec.family)
  theme = theme_for(spec)

  spec.family
  |> recipe_document(data, theme)
  |> maybe_register_preset_fonts(spec)
  |> Rendro.render(deterministic: true)
end
```

Aurora Live Ticket currently has no preset/accent metadata; add any selected closed-palette value only as safe fixture/catalog data. [VERIFIED: `priv/examples/ticket/aurora-live/ticket.json`; CONTEXT.md]

### Pattern 2: Generator writes, checker recomputes and joins

Mirror `Rendro.LaunchArtifacts`: `gen` writes only catalog assets/manifest; `check` never writes. It validates manifest/file hashes, rerenders complete PDFs, rerasterizes page one with pinned PDFium, and joins rubric coverage/freshness. Accumulate all errors, each named by catalog ID and next action. [VERIFIED: `launch_artifacts.ex`; CONTEXT.md]

### Pattern 3: Additive tagged dispositions and derived projection

Keep existing launch `scores[]` untouched. Add a catalog disposition collection (or equivalent additive union) containing one `review_status: "scored" | "unscored"` record per ID. Scored records use existing score/gate/reviewer/evidence fields; unscored records use exact identity/hashes plus dated nonempty reason and no invented score. Derive/check the public three-state projection. [VERIFIED: CONTEXT.md; `rubric_scores.schema.json`]

### Anti-Patterns to Avoid

- Append catalog rows to `@gallery_specs` or mutate `artifacts.json`. [VERIFIED: CONTEXT.md]
- Use `Rendro.Examples.list/1`/filesystem discovery to produce public rows. [VERIFIED: `examples.ex`; CONTEXT.md]
- Let generation update rubric records or store reviewer-entered freshness. [VERIFIED: CONTEXT.md]
- Treat `passed: false` as invalid/unscored. [VERIFIED: CONTEXT.md; rubric contract test]
- Use a preset without `Presets.register_fonts/2`. [VERIFIED: `presets.ex`; Phase 125/126 artifacts]
- Commit source PDFs/trailing page PNGs, build a viewer, or build Phase 128 UI. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PDF layout/rendering | Catalog-specific renderer | Recipes + `Rendro.render/2` | One deterministic engine and pagination behavior. [VERIFIED: AGENTS.md] |
| Fixture loader/path safety | New permissive JSON loader | `Rendro.Examples.load!/1` | Existing safe-relative validation. [VERIFIED: `examples.ex`] |
| Preset/brand system | Per-brand modules | `Theme.default/0`, `Theme.preset/2`, font bridge | Brands stay data; presets stay code. [VERIFIED: `presets.ex`; CONTEXT.md] |
| Rasterizer/pinning | New converter | Existing PDFium adapter/pin | Preserves advisory evidence boundary. [VERIFIED: `pdfium_pin.json`] |
| Hash/PNG handling | New algorithm | Existing SHA-256/IHDR idiom | Matches sibling manifests. [VERIFIED: `launch_artifacts.ex`] |
| Review-data acceptance | Ad hoc parser | JSV schema + ExUnit joins | Separates structural validity from human judgment. [VERIFIED: rubric contract test] |

## Common Pitfalls

1. **Implicit cardinality growth:** a new fixture silently creates public assets/review work. Use literal ordered specs with both exact and maximum-32 tests; reject discovery/cross-products. [VERIFIED: CONTEXT.md]
2. **Mass re-bless conceals regressions:** `gen` must not write reviews; scored hash drift requires re-review, unscored drift explicit rebind, false-to-true resolution evidence. [VERIFIED: CONTEXT.md]
3. **Page-one overclaim:** record complete-PDF hash/page count, use `Preview: page 1 of N`, and keep bounded multi-page proof elsewhere. [VERIFIED: CONTEXT.md]
4. **Advisory raster becomes accessibility/viewer proof:** preserve pin/version and no-overclaim dark-copy boundary. [VERIFIED: CONTEXT.md; `launch_artifacts.ex`]
5. **Private surface leaks into runtime/public API:** hide module, exclude quality/schema/private PDFs from package, and add package/docs tripwires. [VERIFIED: CONTEXT.md; `mix.exs`]

## Code Examples

### Derived freshness contract

```elixir
# Source: Phase 127 D-12..D-16; retain the existing rubric passed?/2 arithmetic.
defp disposition_errors(cell, %{"review_status" => status} = disposition)
     when status in ["scored", "unscored"] do
  identity_errors(
    disposition,
    cell["id"],
    cell["png_path"],
    cell["png_sha256"],
    cell["source_pdf_sha256"]
  ) ++ status_errors(status, disposition)
end

defp disposition_errors(cell, _),
  do: ["catalog #{cell["id"]}: score it or record a dated unscored reason"]
```

The checker derives freshness from identity comparison; it never accepts a manually entered `fresh` flag. [VERIFIED: CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Fixed 11-row launch gallery | Separate catalog registry/tree/manifest | Phase 127 | Keeps launch/manual semantics isolated while enabling static catalog consumption. [VERIFIED: CONTEXT.md] |
| Optional legacy gallery seam tags | Required catalog metadata with truthful default nulls | Phase 127 | Enables exact preview matching without migrating `artifacts.json`. [VERIFIED: `launch_artifacts.ex`; CONTEXT.md] |
| Launch-gallery quality demos | Additive catalog scored/unscored coverage | Phase 127 | Makes all catalog evidence explicit without asserting every cell passes. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:** The seed wording that the catalog extends `mix rendro.launch_artifacts.gen` is superseded by the locked sibling-module boundary. [VERIFIED: `SEED-004-style-genre-presets-public-catalog.md`; CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Existing first/final-page proof can satisfy D-09 with at most a bounded extension. | Open Questions | Add one small advisory proof task. [ASSUMED] |
| A2 | `@moduledoc false` plus public API/docs exclusion hides private catalog code. | Pitfalls | Add a dedicated docs discovery guard. [ASSUMED] |

## Open Questions

1. **D-09 proof reuse:** pipeline output supplies page counts and PDFium is advisory, but current evidence for selected Invoice/Statement first/final pages was not established. Audit it first; otherwise add exactly one bounded external proof. [VERIFIED: `lib/rendro/pipeline.ex`; `launch_artifacts.ex`; ASSUMED]
2. **Aurora accent:** fixture has no accent/preset metadata. Select from existing closed palette in render review and retain it only in fixture/catalog data. [VERIFIED: Aurora fixture; CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | construction/deterministic checks | ✓ | Elixir/Mix 1.19.5; OTP 28 | — [VERIFIED: local environment] |
| Project dependencies | JSON/schema/recipes/tests | ✓ | installed project set | No new dependency. [VERIFIED: `mix.exs`] |
| `pdfium-cli` | page-one generation/check | ✗ | — | Pinned CI route or explicit `--pdfium PATH` / `RENDRO_PDFIUM_CLI`; never unpinned substitute. [VERIFIED: local environment; existing Mix tasks] |
| ExDoc assets | future static consumer | ✓ | existing `~> 0.40` | Existing `assets: %{\"assets\" => \"assets\"}`. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html; VERIFIED: `mix.exs`] |

**Missing dependencies with no fallback:** None. [VERIFIED: repository/CI pattern]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit with JSV schema validation. [VERIFIED: rubric contract test] |
| Config | `test/test_helper.exs`. [VERIFIED: repository inspection] |
| Quick | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` (Wave 0). |
| Full | `mix ci.fast`; `mix rendro.catalog.check --pdfium PATH` in advisory lane. [VERIFIED: `mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CATALOG-01 | Full PDF/page-one PNG/hash/page/dimension/metadata contract. | integration + advisory raster | `mix test test/rendro/catalog_test.exs`; `mix rendro.catalog.check --pdfium PATH` | ❌ Wave 0 |
| CATALOG-02 | Exact IDs/order and count/ceiling. | unit | `mix test test/rendro/catalog_test.exs` | ❌ Wave 0 |
| CATALOG-03 | Manifest/path/default-null/tree/gallery isolation. | docs/package contract | `mix test test/docs_contract/catalog_manifest_contract_test.exs` | ❌ Wave 0 |
| CATALOG-04 | One-to-one disposition/schema/stale-orphan-projection-threshold-false-score cases. | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `test/rendro/catalog_test.exs`
- [ ] `test/docs_contract/catalog_manifest_contract_test.exs`
- [ ] `test/docs_contract/catalog_quality_contract_test.exs`
- [ ] Add catalog disposition union to `rubric_scores.schema.json` and current rubric contract additively.
- [ ] Add catalog checker to advisory CI/guardrail in lockstep; do not put PDFium in deterministic required lane. [VERIFIED: `mix.exs`; CONTEXT.md]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication / V3 Session / V4 Access | No | No service/accounts/session. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | Yes | Safe-relative registry paths, slug/hash/manifest/schema validation before read/write/render. [VERIFIED: `examples.ex`; CONTEXT.md] |
| V6 Cryptography | Yes | Existing SHA-256 evidence identity, not an authenticity signature. [VERIFIED: `launch_artifacts.ex`; CONTEXT.md] |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Unsafe fixture/asset path | Tampering / Info disclosure | `Path.safe_relative/1` plus literal paths. [VERIFIED: `examples.ex`] |
| Artifact/review drift | Tampering | Recompute hashes/page count and exact disposition join. [VERIFIED: CONTEXT.md] |
| Unpinned rasterizer | Tampering | PDFium pin/version/executable-hash provenance. [VERIFIED: `pdfium_pin.json`] |
| Status overclaim | Repudiation | Fixed three-state and no-WCAG/PDF-UA/print/viewer microcopy. [VERIFIED: CONTEXT.md] |
| Grid/cost growth | DoS | Explicit registry and ceiling. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Phase 127 context, requirements, roadmap, state. [VERIFIED: local planning artifacts]
- `lib/rendro/launch_artifacts.ex` and existing generator/check tasks. [VERIFIED: local codebase]
- `lib/rendro/examples.ex`, `lib/rendro/examples_data.ex`, `lib/rendro/theme/presets.ex`, selected fixtures. [VERIFIED: local codebase]
- Rubric manifest/schema/contract plus Phase 125/126 artifacts. [VERIFIED: local codebase]
- `mix.exs` and `priv/pdfium_pin.json`. [VERIFIED: local codebase]

### Secondary (MEDIUM confidence)

- [Mix.Task 1.19.5](https://hexdocs.pm/mix/Mix.Task.html) — task naming, `use Mix.Task`, `run/1`. [CITED: https://hexdocs.pm/mix/Mix.Task.html]
- [ExDoc 0.40](https://ex-doc.hexdocs.pm/ExDoc.html) — assets source-to-target copy-through. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

## Metadata

- Standard stack: HIGH — existing runtime/tooling, no package decision. [VERIFIED: local codebase]
- Architecture: HIGH — directly inspected seams and locked decisions. [VERIFIED: local codebase; CONTEXT.md]
- Pitfalls: HIGH — concrete locked failure modes and evidence boundaries. [VERIFIED: CONTEXT.md]

**Research date:** 2026-08-17  
**Valid until:** 2026-09-16

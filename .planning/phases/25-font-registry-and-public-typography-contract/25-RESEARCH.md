# Phase 25: Font Registry and Public Typography Contract - Research

**Researched:** 2026-04-30
**Domain:** Pure-core typography contract, logical font registry, deterministic resolution
**Confidence:** HIGH

## Summary

Rendro currently treats `%Rendro.Text{font: ...}` as an unvalidated raw string while both `Rendro.Pipeline.Measure` and `Rendro.PDF.Writer` hard-code `Rendro.PDF.Font.helvetica/0`. That means authored font names are mostly decorative today: they can differ from `"Helvetica"` in data, but measurement and rendering still converge on the same implicit built-in font path. This is the right point to introduce a document-level font registry and a logical font-selection contract, because the layout engine already has stable pure-data seams at `%Rendro.Document{}`, `%Rendro.Text{}`, `Measure`, and `Writer`.

**Primary recommendation:** split Phase 25 into two execution plans. First, add a pure-core font registry surface on `%Rendro.Document{}` with builder APIs and truthful text-level docs/types. Second, add deterministic font resolution plumbing so `Measure` and `Writer` consume the same resolved logical font entry rather than instantiating Helvetica independently. Keep Phase 25 intentionally narrow: built-in fonts and logical names only. Do not claim custom metrics parity, arbitrary font embedding, fallback chains, or Unicode-shaping support yet; those belong to Phases 26 and 27.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Document-level font registration | API / pure data | — | Registry ownership belongs on `%Rendro.Document{}` so font selection is part of authored document state, not a writer-side side channel. |
| Logical font selection on text | API / pure data | Compose/Build validation | `%Rendro.Text{}` should carry a logical font reference that is meaningful before PDF serialization exists. |
| Font resolution for layout/render | Measure + Writer | shared pure helper | Both stages must resolve through one contract so later metrics and embedding work can reuse it deterministically. |
| Built-in font metrics and PDF names | `Rendro.PDF.Font` | Writer | The PDF layer should stay the implementation detail behind resolved logical entries, not the public authoring API. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Core runtime, tests, and docs verification | Phase 25 is pure-core contract work and needs no new runtime dependencies. |
| ExUnit | bundled | Contract and regression proof | Existing typography tests already live in ExUnit and can be extended incrementally. |

### Existing Repo Surfaces To Reuse
| Surface | Current Role | Phase 25 Reuse |
|---------|--------------|----------------|
| `lib/rendro/document.ex` | top-level authored document state | add font registry storage and builder API |
| `lib/rendro/text.ex` | text leaf styling contract | tighten logical font naming docs/types |
| `lib/rendro/pdf/font.ex` | built-in Helvetica metrics and PDF font struct | evolve into registry-backed built-in font definitions |
| `lib/rendro/pipeline/measure.ex` | deterministic measurement | resolve logical font before width/line measurement |
| `lib/rendro/pdf/writer.ex` | PDF serialization | resolve logical font before `/F* ... Tf` emission |

## Architecture Patterns

### Pattern 1: Registry Lives on the Document, Not the Writer
**What:** treat fonts like page templates and sections: authored document state first, runtime consumption second.
**When to use:** any public capability that later pipeline stages must consume deterministically.
**Example:**
```elixir
doc =
  Rendro.Document.new()
  |> Rendro.Document.register_font(:body, built_in: :helvetica)
  |> Rendro.Document.put_default_font(:body)
```

Why this fits Rendro: it preserves the project’s data-first pipeline and pure-core boundary. Callers describe intent on `%Rendro.Document{}`; downstream stages normalize and consume that intent without reaching back into Phoenix, Oban, or ad hoc writer options.

### Pattern 2: Logical Names Public, PDF Internals Private
**What:** public APIs should talk about logical font names like `:body` or `:heading`, while the registry maps those names to built-in PDF font definitions internally.
**When to use:** whenever the public contract must survive later implementation upgrades.
**Example:**
```elixir
Rendro.text("Invoice total", font: :heading)
```

Phase 25 should not require callers to know `/F1`, `/Helvetica`, or PDF object allocation rules. That keeps Phase 26 free to change embedding internals without breaking authoring code.

### Pattern 3: One Resolver For Measure And Writer
**What:** introduce one pure font-resolution path that both measurement and rendering consume.
**When to use:** whenever two stages currently duplicate a default or fallback decision.
**Example:** today `Measure` and `Writer` each call `Font.helvetica/0` directly. Phase 25 should replace that with a shared resolution helper returning the same logical-font result to both stages.

## Concrete Repo Findings

### Verified Current State
- `%Rendro.Text{}` defaults `font: "Helvetica"` and types `font` as `String.t()` only.
- `Rendro.text/2` forwards `font:` straight into `%Rendro.Text{}` with no registry involvement.
- `Rendro.Pipeline.Measure.run/1` instantiates `Font.helvetica()` once and uses it for all text width calculations.
- `Rendro.PDF.Writer.render/2` instantiates `Font.helvetica()` once and emits `/F1` for all text blocks.
- Current tests assert `"Helvetica"` as the default authoring surface in builder, text, measure, and writer tests.

### Implication
Phase 25 can land safely without broad file churn if it keeps the default behavior equivalent for documents that never register fonts. That means:
- preserve a default built-in registry entry that resolves to Helvetica;
- keep old `"Helvetica"` authoring inputs working through a compatibility path;
- add explicit tests proving authored logical names actually affect which registry entry is consumed, even if the first registry only contains built-ins.

## Anti-Patterns To Avoid

- **Do not expose PDF object names in public APIs.** `FONT-01` is about document-level logical naming, not `/F1` management.
- **Do not jump straight to arbitrary external font embedding.** That belongs to `FONT-02` and `FONT-03` in Phase 26.
- **Do not let Measure and Writer keep independent font fallbacks.** That would preserve today’s drift problem under a nicer API.
- **Do not over-claim Unicode or script support.** Phase 25 only establishes registry and resolution boundaries.
- **Do not add Phoenix/Oban-specific font configuration.** Core must remain pure and adapter-agnostic.

## Common Pitfalls

### Pitfall 1: Registry added, but text still bypasses it
**What goes wrong:** `%Rendro.Document{}` gains a font map, but `%Rendro.Text{font: ...}` still behaves like a raw PDF font string and no validation or resolution happens.
**How to avoid:** make plan tasks cover both document registration and the stage boundary where text font references are resolved.

### Pitfall 2: Writer-only resolution
**What goes wrong:** PDF output uses the registry, but measurement still widths everything with Helvetica.
**How to avoid:** keep the resolver shared and prove with tests that measure and writer consume the same built-in selection.

### Pitfall 3: Breaking current `"Helvetica"` callers prematurely
**What goes wrong:** the new logical-name contract rejects current test/data inputs before a compatibility path exists.
**How to avoid:** accept current built-in names as compatibility aliases in Phase 25 while making logical names the recommended public surface.

## Recommended Phase Split

### Plan 25-01
Scope:
- add document-level registry storage and public builder functions;
- define truthful docs/types around logical font names and defaults;
- preserve compatibility for current built-in string inputs.

### Plan 25-02
Scope:
- add pure resolution/validation path used by both `Measure` and `Writer`;
- prove registry-driven selection through focused tests;
- keep actual custom metrics and embedding explicitly deferred.

This split keeps the public contract separate from runtime plumbing, which matches the repo’s recent pattern of tightening authored contract surfaces before broadening downstream execution semantics.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` |
| Full suite command | `mix test && mix run scripts/verify_docs.exs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FONT-01 | document can register fonts by logical name | unit | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs` | ✅ |
| FONT-01 | text/components can select registered logical fonts without writer internals | unit | `mix test test/rendro/text_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs` | ✅ |
| FONT-01 | measure and writer consume the same resolved selection path | unit | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** run the smallest affected font-focused test subset.
- **Per wave merge:** run the full Phase 25 quick command.
- **Phase gate:** full test suite plus docs verification before execution closeout.

### Wave 0 Gaps
- None. Existing ExUnit coverage files already cover the public and pipeline surfaces Phase 25 will touch.

## Sources

### Primary
- `lib/rendro/document.ex`
- `lib/rendro/text.ex`
- `lib/rendro.ex`
- `lib/rendro/pdf/font.ex`
- `lib/rendro/pipeline/measure.ex`
- `lib/rendro/pdf/writer.ex`
- `test/rendro/text_test.exs`
- `test/rendro_builders_test.exs`
- `test/rendro/pipeline/measure_test.exs`
- `test/rendro/pdf/font_test.exs`
- `test/rendro/pdf/writer_test.exs`

## Metadata

**Key insight:** Phase 25 should make font choice part of the authored document contract, not just a later writer concern. If that is done with one shared resolver and a compatibility path for today’s Helvetica strings, the repo gets a truthful typography API now without pre-spending the more complex custom-font and i18n scope reserved for later phases.

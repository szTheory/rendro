# Phase 25: Font Registry and Public Typography Contract - Research

**Researched:** 2026-04-30 [VERIFIED: system date]
**Domain:** Pure-Elixir document font registration, logical font selection, and pipeline-owned typography resolution. [VERIFIED: .planning/ROADMAP.md, AGENTS.md]
**Confidence:** MEDIUM [VERIFIED: codebase inspection, official docs, Hex package metadata]

## User Constraints

No phase-specific `CONTEXT.md` exists for Phase 25, so planning constraints come from `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `AGENTS.md`, and the checked-in codebase. [VERIFIED: gsd-sdk init.phase-op output, .planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md, AGENTS.md]

- `FONT-01`: "Engineer can register document fonts by logical name and select them from authored text/components without dropping into PDF-writer internals." [VERIFIED: .planning/REQUIREMENTS.md]
- Phase 25 goal: establish the document-level font registry, logical font selection API, and pure-core contract that later font work depends on. [VERIFIED: .planning/ROADMAP.md]
- Planned work must define document-level registration and logical naming, route authored font references through the registry instead of implicit writer defaults, and keep public APIs independent from PDF object internals. [VERIFIED: .planning/ROADMAP.md]
- Core must stay pure and must not gain hard dependencies on Phoenix, Oban, or admin tooling. [VERIFIED: AGENTS.md]
- Documentation claims are contract surface and must not overstate typography support. [VERIFIED: AGENTS.md]
- The pipeline architecture remains `build -> compose -> measure -> paginate -> render -> validate`, and errors plus telemetry are part of product behavior. [VERIFIED: AGENTS.md, lib/rendro/pipeline.ex]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FONT-01 | Engineer can register document fonts by logical name and select them from authored text/components without dropping into PDF-writer internals. [VERIFIED: .planning/REQUIREMENTS.md] | Use a first-class document font registry, make `Rendro.Text.font` a logical selector, resolve references before measurement, and keep PDF resource names private to writer internals. [VERIFIED: lib/rendro/document.ex, lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED] |
</phase_requirements>

## Summary

The current codebase already exposes `Rendro.Text.font` publicly, but the engine does not honor it operationally: `Rendro.Pipeline.Measure.run/1` and `Rendro.PDF.Writer.render/2` both hard-code `Font.helvetica()`, and writer output always serializes `/F1` with `/BaseFont /Helvetica`. [VERIFIED: lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex, test/rendro/pdf/writer_test.exs] That means Phase 25 is primarily a contract-correction phase: make font choice a document-owned input to the pure pipeline instead of a writer-local hidden default. [VERIFIED: .planning/ROADMAP.md, lib/rendro/pipeline.ex] [ASSUMED]

The safest planning direction is to introduce a first-class font registry on `%Rendro.Document{}`, treat authored `text.font` values as logical keys resolved against that registry, and keep the resolved internal font descriptor separate from public text structs. [VERIFIED: lib/rendro/document.ex, lib/rendro/text.ex, lib/rendro/pipeline/measure.ex] [ASSUMED] Resolution should happen before or at `Compose` so `Measure`, `Paginate`, and later `Render` consume one canonical font choice, while `Writer` remains the only stage that knows about PDF font object names like `/F1` or `/BaseFont`. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex, https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.4.pdf] [CITED: https://hexdocs.pm/elixir/structs.html] [ASSUMED]

**Primary recommendation:** Add a dedicated `%Rendro.Document{fonts: ...}` contract plus pure builder helpers, validate logical font references before measurement, and keep PDF object/resource naming entirely internal to `Rendro.PDF.Writer`. [VERIFIED: lib/rendro/document.ex, lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Document-level font registration | API / Backend | — | Rendro is a pure Elixir library, and `%Rendro.Document{}` is the existing public builder-owned contract surface for document-wide state. [VERIFIED: AGENTS.md, lib/rendro/document.ex, lib/rendro.ex] |
| Logical font selection from authored text/components | API / Backend | — | `Rendro.Text` is the public authored leaf, so logical selection belongs to the document/tree contract rather than to PDF serialization. [VERIFIED: lib/rendro/text.ex, lib/rendro.ex] |
| Font reference resolution before layout | API / Backend | — | `Measure` owns geometry and already consumes font metrics; it cannot stay deterministic if `Writer` alone chooses the actual font. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] |
| PDF resource naming and `/BaseFont` serialization | API / Backend | — | The codebase has no separate client tier; within the backend pipeline, only `Rendro.PDF.Writer` should own PDF object/resource details. [VERIFIED: lib/rendro/pdf/writer.ex] [ASSUMED] |
| Typed failure for unknown or unsupported font references | API / Backend | — | Rendro already turns stage failures into `%Rendro.Error{}` with actionable `what/where/why/next`, so font-contract failures should join that existing error surface. [VERIFIED: lib/rendro/error.ex, lib/rendro/pipeline.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Rendro.Document` | repo-local | Own the document-wide font registry as a first-class, pure data field instead of hiding it in writer state. [VERIFIED: lib/rendro/document.ex] [ASSUMED] | The existing builder API already owns document-wide metadata, templates, sections, diagnostics, and options through pure transformations. [VERIFIED: lib/rendro/document.ex, test/rendro/document_test.exs] |
| `Rendro.Text` | repo-local | Keep authored font choice as a logical selector on the leaf text struct. [VERIFIED: lib/rendro/text.ex] [ASSUMED] | The current public text API already carries content/style fields and is the authored input surface used by builders, flow, and fixed-page APIs. [VERIFIED: lib/rendro/text.ex, lib/rendro.ex, test/rendro_builders_test.exs] |
| `Rendro.Pipeline.Compose` | repo-local | Normalize and resolve logical font references into an internal descriptor before metric work. [VERIFIED: lib/rendro/pipeline/compose.ex, lib/rendro/pipeline.ex] [ASSUMED] | Compose already owns logical-tree normalization and explicitly avoids geometry, making it the right place to canonicalize font references while preserving pipeline stage boundaries. [VERIFIED: lib/rendro/pipeline/compose.ex, .planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md] |
| `Rendro.PDF.Font` | repo-local | Remain the internal metric descriptor for built-in/base fonts and future embedded-font metadata. [VERIFIED: lib/rendro/pdf/font.ex] | Measure already uses `Font.text_width/3`, and writer already serializes fields derived from `%Rendro.PDF.Font{}`. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry` | `1.4.1` published 2026-03-09. [VERIFIED: mix.lock, https://hex.pm/api/packages/telemetry] | Preserve stage-span visibility when font resolution becomes a new measurable input to the pipeline. [VERIFIED: mix.lock, lib/rendro/pipeline.ex] | Use existing span metadata and failure surfaces; do not invent a separate typography event system in Phase 25. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/telemetry.ex] [ASSUMED] |
| `stream_data` | `1.3.0` published 2026-03-09. [VERIFIED: mix.lock, https://hex.pm/api/packages/stream_data] | Support deterministic property tests for registry resolution and repeated renders. [VERIFIED: mix.lock, test/rendro/deterministic_test.exs] | Use when asserting registry-backed font selection remains stable across repeated runs. [VERIFIED: test/rendro/deterministic_test.exs] [ASSUMED] |
| `ExUnit` + docs-contract lanes | Elixir `1.19.5` runtime and repo-local contract tasks. [VERIFIED: elixir --version, test/docs_contract/readme_doctest_test.exs, lib/mix/tasks/docs.contract.ex] | Lock the public typography contract through semantic tests plus README/docs examples. [VERIFIED: test/docs_contract/readme_doctest_test.exs, lib/mix/tasks/docs.contract.ex, README.md] | Use for builder tests, pipeline tests, and docs examples that must not claim unsupported font capabilities. [VERIFIED: AGENTS.md, README.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated document font registry | `doc.options[:fonts]` map | `options` is intentionally generic and bypasses the explicit struct-level contract discoverability that the existing builder API uses for templates, sections, and metadata. [VERIFIED: lib/rendro/document.ex] [ASSUMED] |
| Logical font keys in authored text | Public PDF font names such as `"Helvetica"` or future `/F1`-style internals | Public PDF naming leaks writer concerns, makes later embedding harder to evolve, and violates the requirement to avoid PDF-writer internals. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pdf/writer.ex, test/rendro/pdf/writer_test.exs] |
| Compose-time or pre-measure resolution | Writer-only resolution | Writer-only resolution keeps the current measure/render mismatch, where layout uses Helvetica metrics regardless of authored font values. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** [VERIFIED: mix.lock, elixir --version, https://hex.pm/api/packages/telemetry, https://hex.pm/api/packages/phoenix, https://hex.pm/api/packages/oban, https://hex.pm/api/packages/stream_data, https://hex.pm/api/packages/dialyxir, https://hex.pm/api/packages/ex_doc]

- Elixir `1.19.5` and OTP `28` are installed in the environment. [VERIFIED: elixir --version]
- `telemetry` is pinned at `1.4.1` and Hex reports `1.4.1` published on 2026-03-09. [VERIFIED: mix.lock, https://hex.pm/api/packages/telemetry]
- Optional Phoenix support is pinned at `1.8.5` and HexDocs shows Phoenix `v1.8.5`. [VERIFIED: mix.lock, https://hexdocs.pm/phoenix/Phoenix.html]
- Optional Oban support is pinned at `2.21.1`; Hex reports a newer `2.22.1`, so Phase 25 planning should not assume latest-Oban-only APIs. [VERIFIED: mix.lock, https://hex.pm/api/packages/oban]
- `stream_data` is pinned at `1.3.0`, `dialyxir` at `1.4.7`, and `ex_doc` at `0.40.1`. [VERIFIED: mix.lock, https://hex.pm/api/packages/stream_data, https://hex.pm/api/packages/dialyxir, https://hex.pm/api/packages/ex_doc]

## Architecture Patterns

### System Architecture Diagram

```text
Authored API
  Rendro.document/flow/fixed + Rendro.text(font: logical_key)
        |
        v
Document Font Registry
  %Rendro.Document{fonts: registry}
        |
        v
Build
  validate coarse document shape
        |
        v
Compose
  normalize blocks/tables
  resolve logical font keys -> internal font descriptors
        |
        v
Measure
  compute widths/heights with resolved metrics
        |
        v
Paginate
  consume measured blocks without changing font choice
        |
        v
Render / Writer
  serialize resolved fonts into PDF resource objects
  keep /F1 /BaseFont details private
        |
        v
Validate
  structural/page-count policy checks
```

The diagram above matches the existing stage order and preserves the project rule that PDF internals live behind the render/writer boundary. [VERIFIED: AGENTS.md, lib/rendro/pipeline.ex, lib/rendro/pdf/writer.ex]

### Recommended Project Structure

```text
lib/
├── rendro/document.ex          # public registry field + builder helpers
├── rendro/text.ex              # logical font selector contract
├── rendro/pipeline/compose.ex  # font reference normalization/resolution
├── rendro/pipeline/measure.ex  # metric use of resolved fonts
├── rendro/pdf/font.ex          # internal descriptor + base metrics
└── rendro/pdf/writer.ex        # PDF font resource serialization
```

This structure extends existing ownership rather than creating a typography subsystem that bypasses current stage boundaries. [VERIFIED: lib/rendro/document.ex, lib/rendro/text.ex, lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/font.ex, lib/rendro/pdf/writer.ex]

### Pattern 1: Builder-First Registry on `%Rendro.Document{}`

**What:** Add a dedicated document registry field and pipeable helpers that mirror the existing builder API style. [VERIFIED: lib/rendro/document.ex, test/rendro/document_test.exs] [ASSUMED]

**When to use:** Any time the planner needs a public font contract that is discoverable, pure, and independent from writer internals. [VERIFIED: .planning/REQUIREMENTS.md, AGENTS.md] [ASSUMED]

**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/structs.html and current builder pattern in lib/rendro/document.ex
defstruct pages: [],
          content: [],
          page_templates: [],
          page_template: nil,
          sections: [],
          diagnostics: [],
          header: [],
          footer: [],
          metadata: %Rendro.Metadata{},
          fonts: %{},
          options: %{}

@spec put_font(t(), atom() | String.t(), FontSpec.t()) :: t()
def put_font(%__MODULE__{} = doc, key, spec) do
  %{doc | fonts: Map.put(doc.fonts, key, spec)}
end
```

The important part is the pattern, not the exact helper name: pure builder mutation on the document struct, with key validation preserved through normal Elixir struct discipline. [CITED: https://hexdocs.pm/elixir/structs.html] [VERIFIED: lib/rendro/document.ex] [ASSUMED]

### Pattern 2: Resolve Logical Font Keys Before Measurement

**What:** Convert authored text font references into an internal resolved descriptor before any width measurement occurs. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/font.ex] [ASSUMED]

**When to use:** For all authored text and for any future components that emit text blocks. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/component.ex] [ASSUMED]

**Example:**
```elixir
# Source: recommended stage placement derived from lib/rendro/pipeline.ex and lib/rendro/pipeline/compose.ex
defp compose_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, fonts) do
  resolved_font = resolve_font!(text.font, fonts)
  measured_input = %{text | font: normalize_font_key(text.font)}
  %{block | content: %{measured_input | __resolved_font__: resolved_font}}
end
```

The exact carrier field may differ, but the planner should require one canonical resolved-font payload shared by later stages. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED]

### Pattern 3: Fail Unknown Font References Through Existing Error Surfaces

**What:** Unknown logical font names should become typed pipeline failures rather than silent fallback to Helvetica. [VERIFIED: .planning/REQUIREMENTS.md, AGENTS.md, lib/rendro/error.ex] [ASSUMED]

**When to use:** Whenever a text node or component references a font key absent from the document registry. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED]

**Example:**
```elixir
# Source: existing structured error contract in lib/rendro/error.ex
{:error, :unknown_font_reference}
```

Typed errors keep docs truthful and let planner tasks extend `Rendro.Error.next_step/2` instead of inventing ad hoc exceptions. [VERIFIED: lib/rendro/error.ex] [ASSUMED]

### Anti-Patterns to Avoid

- **Registry buried in `doc.options`:** It weakens the public contract and makes builder discovery inconsistent with the rest of `Rendro.Document`. [VERIFIED: lib/rendro/document.ex] [ASSUMED]
- **Writer-only font resolution:** It preserves the current mismatch where layout is measured with Helvetica even if callers author another font name. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]
- **Public exposure of `/F1` or `/BaseFont` details:** It violates `FONT-01` and makes future embedding work harder to evolve. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pdf/writer.ex]
- **Silent fallback to Helvetica for missing keys:** It creates undocumented behavior and undermines deterministic support claims. [VERIFIED: AGENTS.md, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public font registry surface | Ad hoc nested maps under `options` | A dedicated `Document` field plus builder helpers. [VERIFIED: lib/rendro/document.ex] [ASSUMED] | The current API uses explicit, typed builder entrypoints for document-wide concepts. [VERIFIED: lib/rendro/document.ex, test/rendro/document_test.exs] |
| Font metrics source in Phase 25 | Per-call fallback heuristics in `Measure` | Reuse `Rendro.PDF.Font` as the internal metric descriptor. [VERIFIED: lib/rendro/pdf/font.ex, lib/rendro/pipeline/measure.ex] | The code already has deterministic text-width math there; Phase 25 should route to it, not replace it. [VERIFIED: lib/rendro/pdf/font.ex, test/rendro/pdf/font_test.exs] |
| PDF font resource names | Public `"/F1"`-style API fields | Writer-local object/resource naming. [VERIFIED: lib/rendro/pdf/writer.ex] | PDF resource naming is a serialization concern, not a document-authoring concern. [VERIFIED: lib/rendro/pdf/writer.ex, https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.4.pdf] |
| Missing font behavior | Silent fallback logic | Typed build/compose/measure failure plus docs-contract coverage. [VERIFIED: lib/rendro/error.ex, README.md, lib/mix/tasks/docs.contract.ex] [ASSUMED] | Truthful scope boundaries are a project rule. [VERIFIED: AGENTS.md] |

**Key insight:** Phase 25 should not add “smart typography.” It should add an honest contract boundary so later phases can plug deterministic metrics and embedding into one already-stable registry surface. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Fixing Only the Writer

**What goes wrong:** Public callers can set `text.font`, but page measurement still uses Helvetica widths, so rendered font choice and measured layout diverge. [VERIFIED: lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]
**Why it happens:** Both `Measure.run/1` and `Writer.render/2` independently select `Font.helvetica()` today. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]
**How to avoid:** Require a single resolved-font payload before `Measure`, and make later stages consume that payload instead of re-choosing fonts. [VERIFIED: lib/rendro/pipeline.ex] [ASSUMED]
**Warning signs:** Tests assert different authored font names but still pass only on `/BaseFont /Helvetica` and identical widths. [VERIFIED: test/rendro/pdf/writer_test.exs, test/rendro/pipeline/measure_test.exs] [ASSUMED]

### Pitfall 2: Leaking PDF Internals Into the Public API

**What goes wrong:** The public contract starts depending on `BaseFont`, PDF object names, or writer resource identifiers. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pdf/writer.ex]
**Why it happens:** The current internal font struct already contains PDF-oriented fields such as `name` and `base_font`, so it is tempting to expose it directly. [VERIFIED: lib/rendro/pdf/font.ex]
**How to avoid:** Keep a separate public registry spec and perform any mapping to PDF names only inside writer-owned code. [VERIFIED: lib/rendro/pdf/writer.ex] [ASSUMED]
**Warning signs:** Public docs or tests mention `/F1`, `/BaseFont`, or require callers to know PDF standard-14 names. [VERIFIED: .planning/REQUIREMENTS.md, test/rendro/pdf/writer_test.exs] [ASSUMED]

### Pitfall 3: Hiding the Registry in Generic `options`

**What goes wrong:** The font contract becomes hard to discover, easy to misuse, and inconsistent with the existing builder API. [VERIFIED: lib/rendro/document.ex] [ASSUMED]
**Why it happens:** `put_options/2` already exists and looks like a shortcut for document-wide concerns. [VERIFIED: lib/rendro/document.ex]
**How to avoid:** Plan explicit builder helpers and struct fields for public font registration. [VERIFIED: lib/rendro/document.ex, test/rendro/document_test.exs] [ASSUMED]
**Warning signs:** New tests only exercise `doc.options[:fonts]` and never assert a first-class document contract. [VERIFIED: test/rendro/document_test.exs] [ASSUMED]

### Pitfall 4: Silent Fallback on Unknown Logical Names

**What goes wrong:** Unsupported font references “work” by silently falling back to Helvetica, which makes docs and rendered output untrustworthy. [VERIFIED: AGENTS.md, .planning/REQUIREMENTS.md] [ASSUMED]
**Why it happens:** Silent fallback is easy to implement and matches the current implicit defaulting behavior. [VERIFIED: lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]
**How to avoid:** Fail fast with a typed error and add docs-contract examples for both success and failure surfaces. [VERIFIED: lib/rendro/error.ex, lib/mix/tasks/docs.contract.ex, README.md] [ASSUMED]
**Warning signs:** There is no explicit test for unknown font keys and rendered PDFs still always show Helvetica. [VERIFIED: test/rendro/pdf/writer_test.exs, test/rendro/document_test.exs, test/rendro/pipeline_test.exs] [ASSUMED]

## Code Examples

Verified patterns from official and repo-local sources:

### Preserve Struct Integrity With `struct!/2`

```elixir
# Source: https://hexdocs.pm/elixir/structs.html
john = %User{name: "John", age: 27}
updates = [name: "Jane", age: 30]
struct!(john, updates)
```

`Rendro` already follows this pattern in its public builders, which is the right precedent for any new font-registry field or helper. [CITED: https://hexdocs.pm/elixir/structs.html] [VERIFIED: lib/rendro.ex, test/rendro_builders_test.exs]

### Existing Builder Pattern To Mirror

```elixir
# Source: lib/rendro/document.ex
@spec add_template(t(), Rendro.PageTemplate.t()) :: t()
def add_template(%__MODULE__{} = doc, %Rendro.PageTemplate{} = template) do
  %__MODULE__{doc | page_templates: doc.page_templates ++ [template]}
end
```

This is the established pure-builder style Phase 25 should copy for font registration helpers. [VERIFIED: lib/rendro/document.ex, test/rendro/document_test.exs]

### Existing Telemetry Span Pattern To Reuse

```elixir
# Source: https://hexdocs.pm/telemetry/index
:telemetry.span(
  [:worker, :processing],
  start_metadata,
  fn ->
    {result, %{metadata: "Information related to the processing of the message"}}
  end
)
```

Rendro already uses `:telemetry.span/3` per stage, so Phase 25 should extend current stage metadata rather than create a second instrumentation mechanism. [CITED: https://hexdocs.pm/telemetry/index] [VERIFIED: lib/rendro/pipeline.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Authored `text.font` is a raw string but measurement/render ignore it and use `Font.helvetica()` directly. [VERIFIED: lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] | Phase 25 should convert authored font values into registry-backed logical keys resolved before measurement. [VERIFIED: .planning/REQUIREMENTS.md, .planning/ROADMAP.md] [ASSUMED] | Current repo state as of 2026-04-30 versus Phase 25 target. [VERIFIED: system date, codebase inspection] | Closes the public-contract gap without yet committing to custom font embedding. [VERIFIED: .planning/ROADMAP.md] [ASSUMED] |
| Writer emits one built-in font resource (`/F1` + `/BaseFont /Helvetica`). [VERIFIED: lib/rendro/pdf/writer.ex, test/rendro/pdf/writer_test.exs] | Writer should remain the only owner of PDF font resource names even after registry support lands. [VERIFIED: lib/rendro/pdf/writer.ex] [ASSUMED] | Existing implementation. [VERIFIED: lib/rendro/pdf/writer.ex] | Keeps later embedding work additive instead of breaking the public API. [VERIFIED: .planning/ROADMAP.md] [ASSUMED] |

**Deprecated/outdated:**

- Treating `text.font` as a truthful public capability today is outdated because the pipeline does not yet honor authored font choice end-to-end. [VERIFIED: lib/rendro/text.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `%Rendro.Document{}` should gain a dedicated `fonts` field rather than storing the registry under `options`. [ASSUMED] | Summary, Standard Stack, Architecture Patterns | Medium; planner tasks would target the wrong public API surface. |
| A2 | Public logical font keys should accept `atom()` or `String.t()` for consistency with existing document/template naming patterns. [ASSUMED] | Code Examples, Open Questions | Low to medium; affects typespecs and docs wording. |
| A3 | Font resolution should happen in `Compose` or an equivalent pre-measure normalization step. [ASSUMED] | Summary, Architecture Patterns | Medium; stage ownership could shift to `Build`, but the planner still needs one pre-measure resolution task. |
| A4 | Unknown logical font references should fail fast as typed pipeline errors rather than silently falling back. [ASSUMED] | Common Pitfalls, Security Domain | Medium; if maintainers prefer fallback, docs and test strategy change materially. |
| A5 | The internal resolved-font carrier can remain private and separate from the public `%Rendro.Text{}` struct. [ASSUMED] | Architecture Patterns | Low; implementation shape may differ, but separation of concerns should remain. |

## Open Questions

1. **What should the public builder helper names be?** [ASSUMED]
   - What we know: `Rendro.Document` already uses `add_*`, `set_*`, `put_*`, and `put_options/2` patterns. [VERIFIED: lib/rendro/document.ex]
   - What's unclear: whether font registration should be singular (`put_font/3`), plural (`put_fonts/2`), or list-appending (`add_font/2`). [ASSUMED]
   - Recommendation: prefer `put_font/3` plus `put_fonts/2` so registry semantics read as keyed replacement/merge rather than list accumulation. [ASSUMED]

2. **Should `Rendro.Text.font` stay `String.t()` or widen to `atom() | String.t()`?** [ASSUMED]
   - What we know: current type is `String.t()`, while document template selectors already accept atoms or strings. [VERIFIED: lib/rendro/text.ex, lib/rendro/document.ex]
   - What's unclear: whether backward compatibility or ergonomic symmetry should dominate. [ASSUMED]
   - Recommendation: accept both publicly, canonicalize internally, and document one preferred style. [ASSUMED]

3. **Which stage should own typed unknown-font errors?** [ASSUMED]
   - What we know: `Build` validates coarse shape, `Compose` normalizes the document tree, and `Measure` consumes actual font metrics. [VERIFIED: lib/rendro/pipeline/build.ex, lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex]
   - What's unclear: whether maintainers want invalid font names rejected during logical assembly or only once metrics are required. [ASSUMED]
   - Recommendation: fail in `Compose` if the registry is fully document-owned there, otherwise fail at the start of `Measure` before any geometry work. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core implementation and test execution | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Erlang/OTP | Elixir runtime | ✓ [VERIFIED: `elixir --version`] | `28` [VERIFIED: `elixir --version`] | — |
| Mix | Build, tests, docs-contract, `mix ci` | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |

**Missing dependencies with no fallback:**

- None for Phase 25 research/planning; this phase is code-and-test work inside the existing Elixir toolchain. [VERIFIED: .planning/ROADMAP.md, elixir --version, mix --version]

**Missing dependencies with fallback:**

- None identified. [VERIFIED: .planning/ROADMAP.md, codebase inspection]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`, with StreamData property tests available. [VERIFIED: elixir --version, test/test_helper.exs, test/rendro/deterministic_test.exs, mix.lock] |
| Config file | `test/test_helper.exs`; no standalone `pytest`/JS test config applies. [VERIFIED: test/test_helper.exs, repo file list] |
| Quick run command | `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs -x` [VERIFIED: repo file list] [ASSUMED] |
| Full suite command | `mix ci` [VERIFIED: mix.exs, test/mix/tasks/ci_alias_contract_test.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FONT-01 | Register fonts by logical name and resolve authored text references without exposing writer internals. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration + docs-contract [ASSUMED] | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs -x` [VERIFIED: repo file list] [ASSUMED] | ❌ Wave 0 for specific font-registry cases; the files exist, but registry coverage does not. [VERIFIED: test/rendro/document_test.exs, test/rendro_builders_test.exs, test/rendro/pipeline/measure_test.exs, test/rendro/pdf/writer_test.exs] |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs -x` [VERIFIED: repo file list] [ASSUMED]
- **Per wave merge:** `mix ci` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json, GSD workflow rules]

### Wave 0 Gaps

- [ ] `test/rendro/document_test.exs` — add first-class registry field/helper coverage and unknown-key guard assertions for the new public API. [VERIFIED: current file lacks font-registry cases]
- [ ] `test/rendro_builders_test.exs` — add builder ergonomics coverage for logical font registration and `Rendro.text/2` logical-key selection. [VERIFIED: current file only covers raw `font` strings]
- [ ] `test/rendro/pipeline/measure_test.exs` — add proof that registry-selected fonts, not implicit Helvetica, are the source of metric choice once Phase 25 resolution lands. [VERIFIED: current file always uses Helvetica inputs]
- [ ] `test/rendro/pdf/writer_test.exs` — add proof that public callers never need writer resource names even when the registry influences output selection. [VERIFIED: current file asserts `/F1` and `/BaseFont /Helvetica` only]
- [ ] `test/docs_contract/readme_doctest_test.exs` plus README examples — add truthful examples for font registration without claiming custom embedding or fallback chains yet. [VERIFIED: current README has no font-registry examples]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [ASSUMED] | Not applicable; Phase 25 is a pure document-contract feature. [VERIFIED: .planning/ROADMAP.md, AGENTS.md] |
| V3 Session Management | no [ASSUMED] | Not applicable; no user/session state is introduced. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no [ASSUMED] | Not applicable; the phase changes library API shape, not authorization boundaries. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes [VERIFIED: phase requirement and public API scope] | Use explicit builder validation, `struct!`-guarded public contracts, and typed pipeline failures for unknown font keys. [CITED: https://hexdocs.pm/elixir/structs.html] [VERIFIED: lib/rendro.ex, lib/rendro/error.ex] [ASSUMED] |
| V6 Cryptography | no [ASSUMED] | Not applicable in Phase 25. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unknown logical font key silently falling back to Helvetica | Tampering / Integrity [ASSUMED] | Fail through a typed stage error so rendered output cannot masquerade as supported font selection. [VERIFIED: AGENTS.md, lib/rendro/error.ex] [ASSUMED] |
| Public API exposes raw PDF font resource details | Information Disclosure / Tight Coupling [ASSUMED] | Keep writer resource naming private and expose only logical registry names publicly. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pdf/writer.ex] |
| Registry resolution occurs after measurement | Tampering / Integrity [ASSUMED] | Resolve once before `Measure` so layout and output share one font choice. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- [AGENTS.md](/Users/jon/projects/rendro/AGENTS.md) - project constraints, architecture rules, and workflow expectations.
- [.planning/REQUIREMENTS.md](/Users/jon/projects/rendro/.planning/REQUIREMENTS.md) - `FONT-01` requirement and typography milestone scope.
- [.planning/ROADMAP.md](/Users/jon/projects/rendro/.planning/ROADMAP.md) - Phase 25 goal, planned work, and downstream phase boundaries.
- [lib/rendro/document.ex](/Users/jon/projects/rendro/lib/rendro/document.ex) - current document builder contract.
- [lib/rendro/text.ex](/Users/jon/projects/rendro/lib/rendro/text.ex) - current public text font field.
- [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex) - stage ordering and telemetry contract.
- [lib/rendro/pipeline/compose.ex](/Users/jon/projects/rendro/lib/rendro/pipeline/compose.ex) - logical normalization responsibilities.
- [lib/rendro/pipeline/measure.ex](/Users/jon/projects/rendro/lib/rendro/pipeline/measure.ex) - current hard-coded Helvetica metrics.
- [lib/rendro/pdf/font.ex](/Users/jon/projects/rendro/lib/rendro/pdf/font.ex) - internal metric descriptor and built-in Helvetica widths.
- [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex) - current writer-local font serialization.
- [lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex) - typed stage error contract.
- [test/rendro/document_test.exs](/Users/jon/projects/rendro/test/rendro/document_test.exs), [test/rendro_builders_test.exs](/Users/jon/projects/rendro/test/rendro_builders_test.exs), [test/rendro/pipeline/measure_test.exs](/Users/jon/projects/rendro/test/rendro/pipeline/measure_test.exs), [test/rendro/pdf/writer_test.exs](/Users/jon/projects/rendro/test/rendro/pdf/writer_test.exs) - current public/tested behavior.
- https://hexdocs.pm/elixir/structs.html - official Elixir struct update and validation guidance.
- https://hexdocs.pm/telemetry/index - official telemetry span/attach patterns.
- https://hexdocs.pm/mix/Mix.Tasks.Deps.html - official optional dependency semantics.
- https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.4.pdf - official PDF font-management rules and standard-14 font background.

### Secondary (MEDIUM confidence)

- https://hex.pm/api/packages/telemetry - current release metadata for `telemetry`.
- https://hex.pm/api/packages/phoenix - current release metadata for `phoenix`.
- https://hex.pm/api/packages/oban - current release metadata for `oban`.
- https://hex.pm/api/packages/stream_data - current release metadata for `stream_data`.
- https://hex.pm/api/packages/dialyxir - current release metadata for `dialyxir`.
- https://hex.pm/api/packages/ex_doc - current release metadata for `ex_doc`.
- https://hexdocs.pm/phoenix/Phoenix.html - Phoenix `v1.8.5` docs page used to confirm current doc version surface.

### Tertiary (LOW confidence)

- None. [VERIFIED: research notes for this session]

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM - repo ownership and package versions are verified, but the exact public registry helper names and field shape remain design recommendations for Phase 25. [VERIFIED: codebase inspection, Hex metadata] [ASSUMED]
- Architecture: MEDIUM - stage responsibilities are verified in code, but the precise resolution stage (`Compose` versus early `Measure`) is still a planning choice. [VERIFIED: lib/rendro/pipeline.ex, lib/rendro/pipeline/compose.ex, lib/rendro/pipeline/measure.ex] [ASSUMED]
- Pitfalls: HIGH - they are directly grounded in current hard-coded Helvetica behavior, explicit project constraints, and the existing writer internals. [VERIFIED: AGENTS.md, lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]

**Research date:** 2026-04-30 [VERIFIED: system date]
**Valid until:** 2026-05-30 for repo-local architecture; verify Hex package release metadata again if planning slips past 30 days. [VERIFIED: system date, Hex package metadata] [ASSUMED]

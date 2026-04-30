# Phase 26: Deterministic Font Metrics and PDF Embedding - Research

**Researched:** 2026-04-30
**Domain:** Deterministic custom-font metrics, preflight, and PDF embedding in pure Elixir
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Public font source contract
- **D-01:** Keep built-in fonts and embedded custom fonts as distinct public concepts. Built-in registration stays separate from embedded-font registration; do not collapse them into one magical API.
- **D-02:** The embedded-font contract must accept both tagged path and tagged binary sources: `{:path, path}` and `{:binary, bytes}`.
- **D-03:** Any path-based input must be eagerly read and normalized into Rendro-owned pure data before later pipeline stages run. Temp-file lifetime, release layout, or host filesystem state must not affect pagination or rendering after registration/preflight.
- **D-04:** Do not support system-font lookup, ambient OS font discovery, remote fetching, or implicit environment-dependent resolution in this phase.

### Registration and family modeling
- **D-05:** Preserve the existing logical-font authoring contract: `%Rendro.Text{font: ...}` continues to reference explicit logical font names, not PDF internals or CSS-like family strings.
- **D-06:** Add an explicit embedded-font registration path for custom fonts rather than overloading `register_font/3` with mixed semantics.
- **D-07:** Support a narrow four-variant family model for DX: `regular`, `bold`, `italic`, and `bold_italic`, but only through explicit caller-provided variant files/bytes.
- **D-08:** Missing variants must fail explicitly. No faux bold/italic synthesis, no implicit family discovery, and no silent remapping to another face.
- **D-09:** Do not broaden into arbitrary weight axes, variable-font semantics, or generalized style resolution in this phase.

### Failure and validation policy
- **D-10:** Preflight custom fonts before `measure`, `paginate`, and `render`. Unreadable data, unsupported format, missing required metrics, or non-embeddable fonts must fail through typed errors at the earliest deterministic boundary.
- **D-11:** Rendro must never silently fall back from an explicitly registered/selected embedded font to a different face. Invalid explicit font usage is a hard failure, not best effort.
- **D-12:** The existing “fail early at Build” posture from Phase 25 should extend to embedded-font readiness: later stages should consume already-validated descriptors rather than re-deciding validity ad hoc.

### Determinism and verification contract
- **D-13:** Measurement and writer must consume the same resolved font descriptor/metrics payload so line breaks, widths, heights, and final PDF font objects all derive from one shared source of truth.
- **D-14:** The public determinism contract for this phase is stable layout behavior: measured widths/heights, wrapped lines, page breaks, page counts, and resolved font selection parity.
- **D-15:** Verification should assert embedded-font structure and presence, but should not elevate full-PDF byte identity to the main public contract for this phase.
- **D-16:** If whole-file byte-stability tests exist, they should remain a narrow internal regression tool rather than the user-facing promise that defines success.

### Developer and operator experience
- **D-17:** Optimize for Phoenix, Plug, Ecto, and Oban usage without coupling core to any of them: path input should feel natural for uploads/files, binary input should feel natural for DB/blob/cached assets, and both normalize into one pure-core descriptor.
- **D-18:** Errors and diagnostics should name the logical font, source kind, and concrete failure reason so operators can fix invalid font setup without reading PDF internals.
- **D-19:** Downstream agents should default to one coherent recommendation set rather than surfacing menus of equivalent options. Escalate only choices that materially change product semantics or milestone scope. This is already consistent with `.planning/METHODOLOGY.md` and should be applied strongly in planning/execution for this phase.

### Claude's Discretion
- Exact internal module split for parsing, metrics extraction, embedding, and descriptor caching.
- Whether the four-variant family helper stores an internal variant map or expands into explicit logical names, as long as caller intent stays explicit and deterministic.
- Exact typed error atoms/details and telemetry field names, as long as they stay consistent with existing public error surfaces.
- Whether narrow whole-file deterministic fixtures exist internally, as long as the public contract stays centered on layout determinism and embedding structure rather than byte identity.

### Deferred Ideas (OUT OF SCOPE)
- Fallback chains and missing-glyph resolution policy — Phase 27.
- Unsupported glyph/script/shaping diagnostics and the Unicode support matrix — Phase 27.
- Variable fonts, arbitrary weight axes, and generalized style-resolution semantics — future work only if the roadmap explicitly asks for them.
- System-font discovery, remote font fetching, and environment-dependent font lookup — out of scope for the current milestone posture.
- Whole-file reproducible PDF bytes as a public product guarantee — future trust/release concern if explicitly required.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FONT-02 | Measurement, pagination, and rendering use the same resolved font metrics so custom-font documents stay deterministic. | One shared resolved embedded-font descriptor should be produced before `Measure`, carried on `%MeasuredText{}`, and reused by `Writer`. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] |
| FONT-03 | Engineer can embed supported custom fonts into generated PDFs through the supported document contract. | Add a separate embedded-font registration API that accepts `{:path, path}` and `{:binary, bytes}`, eagerly normalizes to bytes, preflights required tables, and writes `/FontFile2`-backed font objects for supported TrueType-outline fonts. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |
</phase_requirements>

## Summary

Rendro already has the right seam for this phase: `Build` validates authored font references, `Measure` resolves a font before wrapping text, `%MeasuredText{}` stores the resolved font, and `Writer` consumes that resolved font during PDF serialization. [VERIFIED: codebase grep] The current implementation is still built-in only, because `Rendro.FontRegistry.resolve_pdf_font/3` always returns a built-in Helvetica-backed `%Rendro.PDF.Font{}` and `Writer` only emits simple Type1 font dictionaries with `/BaseFont`. [VERIFIED: codebase grep]

The right Phase 26 contract is to keep Phase 25’s logical-font API, add a distinct embedded-font registration path, and preflight every supported custom font into one pure-data descriptor that both `Measure` and `Writer` reuse. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] That descriptor should carry normalized source bytes, scalar metrics derived from the font tables, deterministic resource naming, and the exact embedding payload needed by the writer so pagination and final PDF objects cannot drift. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html]

**Primary recommendation:** implement Phase 26 around supported TrueType-outline fonts only in core: accept `{:path, path}` and `{:binary, bytes}`, eagerly normalize to bytes, parse the required sfnt tables (`cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`), reject restricted or unsupported fonts early, and emit embedded `/FontFile2` objects from the same resolved descriptor used in measurement. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Embedded-font registration and eager byte normalization | API / pure data | Build | The document contract owns source normalization so later stages never depend on filesystem state. [VERIFIED: codebase grep] [VERIFIED: planning docs] |
| Font preflight and typed failure surface | Build | Font registry | `Build` is already the earliest deterministic failure boundary and should extend that role to embedded-font readiness. [VERIFIED: codebase grep] |
| Glyph width, ascent, descent, and line-gap measurement | Measure | shared font descriptor | Pagination depends on font metrics, so `Measure` is the primary consumer of resolved metrics. [VERIFIED: codebase grep] |
| Embedded PDF font object construction | Writer | shared font descriptor | Only `Writer` should translate the resolved descriptor into PDF font objects and resources. [VERIFIED: codebase grep] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] |
| Variant selection (`regular` / `bold` / `italic` / `bold_italic`) | Font registry | Build | Variant choice is still an authored logical-font concern, but missing variants must fail before layout work begins. [VERIFIED: planning docs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: codebase grep] | Pure-core implementation and binary parsing | The repo is already pure Elixir and Phase 26 must preserve that boundary. [VERIFIED: codebase grep] |
| Erlang/OTP | 28 [VERIFIED: `elixir --version`] | Binary pattern matching and runtime | The current runtime is sufficient for sfnt table parsing and PDF serialization without NIFs. [VERIFIED: `elixir --version`] |
| ExUnit | bundled with Elixir [VERIFIED: codebase grep] | Determinism, registry, and writer regression coverage | The existing font, measure, and writer tests already cover the seam this phase will extend. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `truetype_metrics` | 0.6.1 [VERIFIED: mix hex.info] | External reference for what a narrow pure-Elixir TTF metrics parser exposes (`load`, `parse`, `units_per_em`, `ascent`, `descent`, `metrics`, `line_gap`) | Use only as a design reference or fallback evaluation input; do not add as a core runtime dependency by default. [VERIFIED: mix hex.info] [CITED: https://hexdocs.pm/truetype_metrics/TruetypeMetrics.html] [CITED: https://raw.githubusercontent.com/boydm/truetype_metrics/master/lib/truetype_metrics.ex] |
| `opentype` | 0.5.1 [VERIFIED: mix hex.info] | External reference for OpenType parsing and shaping support | Useful only if Phase 27 later needs shaping exploration; it is not the recommended Phase 26 embedding foundation. [VERIFIED: mix hex.info] [CITED: https://hexdocs.pm/opentype/OpenType.html] [CITED: https://raw.githubusercontent.com/jbowtie/opentype-elixir/master/lib/opentype.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Narrow in-repo TrueType-outline parser and embedder [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] | `truetype_metrics` 0.6.1 [VERIFIED: mix hex.info] | `truetype_metrics` is current enough to parse TTF metrics, but it does not provide PDF embedding objects and its public docs are intentionally narrow. [VERIFIED: mix hex.info] [CITED: https://hexdocs.pm/truetype_metrics/TruetypeMetrics.html] |
| TrueType-outline-only Phase 26 scope [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] | `opentype` 0.5.1 [VERIFIED: mix hex.info] | `opentype` is older, shaping-oriented, and explicitly limited to uncompressed OpenType/TrueType input with first-font-only collection handling, which is broader than Phase 26 needs in some areas and weaker in others. [VERIFIED: mix hex.info] [CITED: https://hexdocs.pm/opentype/OpenType.html] [CITED: https://raw.githubusercontent.com/jbowtie/opentype-elixir/master/lib/opentype.ex] |
| Rendro’s current pure-core writer architecture [VERIFIED: codebase grep] | `ex_guten` 0.1.1 [VERIFIED: mix hex.info] | `ex_guten` demonstrates that pure Elixir can do TTF/OTF embedding and subsetting, but adopting it would replace Rendro’s engine rather than extend the existing pipeline. [VERIFIED: mix hex.info] [CITED: https://hexdocs.pm/ex_guten/readme.html] [CITED: https://raw.githubusercontent.com/hwatkins/ex_guten/master/README.MD] |

**Installation:**
```bash
# No new runtime packages recommended for Phase 26.
```

**Version verification:** `truetype_metrics 0.6.1`, `opentype 0.5.1`, `pdf 0.7.2`, and `ex_guten 0.1.1` were verified with `mix hex.info` in this session. [VERIFIED: mix hex.info]

## Architecture Patterns

### System Architecture Diagram

```text
Embedded font registration API
  -> normalize source (`{:path, path}` | `{:binary, bytes}`)
  -> eager byte capture + source hash
  -> sfnt preflight parser
     -> required table presence?
     -> metrics extractable?
     -> embedding allowed by OS/2 fsType?
     -> supported outline flavor?
  -> store resolved descriptor in FontRegistry
  -> Build validates logical font + variant completeness
  -> Measure resolves descriptor
     -> text widths / wrapped lines / heights
     -> %MeasuredText{resolved_font: descriptor}
  -> Paginate consumes measured block sizes
  -> Writer reuses same descriptor
     -> font file object
     -> font descriptor object
     -> font dictionary/resource entries
  -> Validate / tests assert embedded structure + layout parity
```

### Recommended Project Structure
```text
lib/rendro/
├── font_registry.ex          # extend descriptors + embedded-font registration
├── pipeline/build.ex         # preflight validation and typed failures
├── pipeline/measure.ex       # width/height from resolved embedded metrics
├── pipeline/measured_text.ex # carry shared resolved descriptor
└── pdf/
    ├── font.ex              # generalized font metrics struct
    ├── true_type.ex         # sfnt table parsing + deterministic metrics extraction
    └── writer.ex            # embedded font objects and page resources

test/
├── rendro/pdf/font_test.exs
├── rendro/pipeline/measure_test.exs
├── rendro/pdf/writer_test.exs
└── support/fixtures/fonts/   # committed deterministic sample TTF fixtures
```

### Pattern 1: Eager Source Normalization
**What:** convert every path registration into owned bytes immediately and treat binary registrations the same way. [VERIFIED: planning docs]
**When to use:** every embedded-font API path in this phase. [VERIFIED: planning docs]
**Example:**
```elixir
# Source: Phase 26 context + existing document-owned registry pattern
case source do
  {:path, path} -> {:ok, File.read!(path)}
  {:binary, bytes} when is_binary(bytes) -> {:ok, bytes}
end
```

### Pattern 2: One Resolved Descriptor Across Measure and Writer
**What:** return a generalized resolved font descriptor that contains both measurement metrics and writer embedding payload. [VERIFIED: codebase grep]
**When to use:** every font resolution call inside `Build`, `Measure`, and `Writer`. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: existing Measure -> MeasuredText -> Writer seam
with {:ok, resolved_font} <- FontRegistry.resolve_pdf_font(registry, text.font, default_font) do
  %MeasuredText{resolved_font: resolved_font, ...}
end
```

### Pattern 3: TrueType-Outline-Only Embedded Support
**What:** support fonts with required sfnt metric tables and a TrueType outline flavor; reject CFF-flavored OTF in this phase. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]
**When to use:** Phase 26 implementation and docs wording. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]
**Example:**
```elixir
# Source: OpenType required tables + PDF FontFile2 embedding path
case font_signature(bytes) do
  <<0, 1, 0, 0>> -> parse_true_type(bytes)
  <<"true">> -> parse_true_type(bytes)
  <<"OTTO">> -> {:error, {:unsupported_font_format, :cff_otf}}
end
```

### Anti-Patterns to Avoid
- **Filesystem-backed lazy registration:** storing only a path and reopening it later would violate D-03 and can make output environment-dependent. [VERIFIED: planning docs]
- **Writer-only embedding metadata:** if the writer reparses fonts independently, pagination can drift from render output. [VERIFIED: codebase grep]
- **Variant synthesis:** faux bold or faux italic would violate D-08 and produce unverified metrics. [VERIFIED: planning docs]
- **CFF/Type0 expansion in Phase 26:** that widens scope into a different PDF font model than the phase requires. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font discovery | ambient OS font scanning or fallback lookup | explicit `{:path, path}` / `{:binary, bytes}` registration only | The phase explicitly forbids environment-dependent discovery. [VERIFIED: planning docs] |
| Metrics inference | width heuristics from file names or style names | parsed `cmap` / `head` / `hhea` / `hmtx` metrics tables | PDF width arrays and deterministic wrapping depend on real font metrics, not approximations. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html] |
| Permission policy | ignoring licensing bits or documenting “best effort” | parse `OS/2.fsType` and fail or warn deterministically | Microsoft’s OpenType spec defines embedding restriction bits explicitly. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2] |
| External verification dependency | requiring `pdffonts`, `qpdf`, or `mutool` to prove embedding | ExUnit assertions against emitted PDF object structure | Those CLIs are not installed here, so planner should not make them a hard dependency. [VERIFIED: local environment audit] |
| Rich fallback or shaping | custom fallback-chain engine in this phase | defer to Phase 27 | The roadmap and context keep fallback and i18n boundary work out of Phase 26. [VERIFIED: planning docs] |

**Key insight:** the only custom parsing worth writing in Phase 26 is the narrow sfnt table subset required to make one shared deterministic descriptor. Everything else that looks “font related” is either explicitly deferred or belongs to a broader shaping/fallback engine. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [VERIFIED: planning docs]

## Common Pitfalls

### Pitfall 1: Parsing at render time instead of registration time
**What goes wrong:** temp files disappear, host release layouts differ, or one stage reparses slightly differently from another. [VERIFIED: planning docs]
**Why it happens:** it is tempting to store only a path or raw source tuple in the registry. [ASSUMED]
**How to avoid:** store normalized bytes plus extracted metrics in the registry entry and treat later stages as pure consumers. [VERIFIED: planning docs]
**Warning signs:** `Measure` and `Writer` both contain independent `File.read/1` or parser calls. [VERIFIED: codebase grep]

### Pitfall 2: Supporting CFF-flavored OTF accidentally
**What goes wrong:** the parser accepts `OTTO` headers, but the writer still emits a TrueType-style `/FontFile2` path or width model. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]
**Why it happens:** OpenType files can contain either TrueType or CFF outlines, but the PDF embedding paths differ. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]
**How to avoid:** explicitly reject CFF-flavored OTF in Phase 26 with a typed error and keep docs narrow. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]
**Warning signs:** code branches on file extension rather than sfnt signature or outline flavor. [ASSUMED]

### Pitfall 3: Ignoring `OS/2.fsType`
**What goes wrong:** Rendro embeds fonts whose licenses explicitly restrict embedding or subsetting. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2]
**Why it happens:** embedding succeeds technically, so it is easy to overlook the license metadata in the font tables. [ASSUMED]
**How to avoid:** parse `fsType` during preflight and fail restricted fonts deterministically in `Build` or registration. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2]
**Warning signs:** registration stores bytes without any `OS/2` metadata or permission state. [ASSUMED]

### Pitfall 4: Verifying only bytes, not structure
**What goes wrong:** tests become brittle around non-semantic serialization changes, or planners over-promise whole-file byte identity as the public contract. [VERIFIED: planning docs]
**Why it happens:** deterministic mode already has stable-byte tests in the repo. [VERIFIED: codebase grep]
**How to avoid:** keep byte-identity tests narrow and make primary coverage assert layout parity plus embedded font object structure. [VERIFIED: planning docs]
**Warning signs:** Phase 26 acceptance criteria mention only `pdf1 == pdf2` and not widths, page counts, or `/FontFile2` structure. [ASSUMED]

## Code Examples

Verified patterns from official or primary sources:

### Parse font bytes eagerly
```elixir
# Source: https://hexdocs.pm/truetype_metrics/TruetypeMetrics.html
{:ok, metrics} = TruetypeMetrics.parse(font_bytes, "fixture.ttf")
```

### Parse an OpenType/TrueType font file directly
```elixir
# Source: https://hexdocs.pm/opentype/OpenType.html
ttf = OpenType.parse_file("font.ttf")
```

### Embed a TrueType font in a PDF object model
```text
<< /Type /Font /Subtype /TrueType /BaseFont /ExampleFont /FirstChar 0 /LastChar 255 /Widths ... /FontDescriptor ... >>
```
Source: Adobe PDF Reference, TrueType font dictionary and embedded `FontFile2` path. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded built-in Helvetica metrics in core [VERIFIED: codebase grep] | Shared resolved descriptor carrying embedded-font metrics and writer payload [VERIFIED: planning docs] | Phase 26 plan target [VERIFIED: planning docs] | Custom-font pagination and rendering stop drifting. [VERIFIED: planning docs] |
| Path-sensitive ambient font source [VERIFIED: planning docs] | Eager byte normalization into document-owned data [VERIFIED: planning docs] | Phase 26 plan target [VERIFIED: planning docs] | Release layout and temp-file lifetime no longer affect rendering. [VERIFIED: planning docs] |
| Built-in Type1 font dictionaries only [VERIFIED: codebase grep] | Embedded `/FontFile2` + descriptor path for supported custom fonts [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf] | Phase 26 plan target [VERIFIED: planning docs] | FONT-03 becomes truthful without widening into fallback or shaping work. [VERIFIED: planning docs] |

**Deprecated/outdated:**
- Single hard-coded Helvetica measurement in `Measure`. [VERIFIED: codebase grep]
- Writer resource allocation that only knows built-in `/BaseFont` entries. [VERIFIED: codebase grep]
- Any contract that implies `.otf` automatically means “supported” without checking whether the outline flavor is CFF or TrueType. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] Storing normalized bytes and extracted metrics in the registry will be less surprising to callers than storing a path or lazy source tuple. | Common Pitfalls / Architecture Patterns | Low; if DX feedback differs, the planner may want a wrapper struct but should still keep eager normalization. |
| A2 | [ASSUMED] Warning signs framed around likely implementation mistakes are still relevant even though they are not directly present in the codebase yet. | Common Pitfalls | Low; affects review emphasis, not product semantics. |
| A3 | [ASSUMED] Structure-first verification is the right public contract wording for this phase. | Common Pitfalls / Validation Architecture | Medium; if the user wants stronger byte-identity promises, planning scope changes. |

## Open Questions

1. **Should Phase 26 accept only `.ttf`-style TrueType signatures, or also OpenType wrappers with TrueType outlines?**
   - What we know: the OpenType spec distinguishes required shared tables from outline-specific tables, and PDF’s embedded TrueType path is clearly defined through `FontFile2`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]
   - What's unclear: whether the planner wants the first supported contract expressed as “TrueType-outline fonts” or the simpler but narrower “TTF only.” [ASSUMED]
   - Recommendation: plan for TrueType-outline support keyed off sfnt signature and required tables, but keep CFF-flavored `OTTO` out of scope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]

2. **How much font-descriptor metadata should be extracted in Phase 26?**
   - What we know: PDF font descriptors can include bounding box, ascent, descent, cap height, stem values, and embedded font file references. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]
   - What's unclear: whether Rendro should compute only the minimum truthful subset now or invest in richer descriptor fidelity immediately. [ASSUMED]
   - Recommendation: extract the smallest set required for truthful embedding and deterministic measurement first: widths, bbox, ascent, descent, line gap, italic angle, weight, and embedding permissions. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2] [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | implementation and tests | ✓ [VERIFIED: local environment audit] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | build/test/verify commands | ✓ [VERIFIED: local environment audit] | 1.19.5 [VERIFIED: `mix --version`] | — |
| `pdffonts` | optional PDF inspection during development | ✗ [VERIFIED: local environment audit] | — | Assert object structure directly in ExUnit. [VERIFIED: local environment audit] |
| `qpdf` | optional PDF structure inspection | ✗ [VERIFIED: local environment audit] | — | Use deterministic writer and string/object assertions. [VERIFIED: local environment audit] |
| `mutool` | optional PDF object inspection | ✗ [VERIFIED: local environment audit] | — | Use ExUnit fixtures and writer-level assertions. [VERIFIED: local environment audit] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment audit]

**Missing dependencies with fallback:**
- `pdffonts`, `qpdf`, and `mutool` are absent, so planner should not require external PDF-inspector CLIs for Phase 26 acceptance. [VERIFIED: local environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/rendro/pdf/font_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix verify` [VERIFIED: `mix help verify`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FONT-02 | same resolved descriptor drives measured widths, wrapped lines, page breaks, and rendered font resource choice | unit + integration | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs` | ✅ existing files [VERIFIED: codebase grep] |
| FONT-02 | explicit embedded logical font does not silently fall back | unit | `mix test test/rendro/pdf/font_test.exs test/rendro/pipeline/measure_test.exs` | ✅ existing files [VERIFIED: codebase grep] |
| FONT-03 | supported custom font registration embeds font program into generated PDF | integration | `mix test test/rendro/pdf/writer_test.exs` | ✅ existing file, but new cases needed [VERIFIED: codebase grep] |
| FONT-03 | path and binary sources normalize to equivalent deterministic descriptors | unit | `mix test test/rendro/pdf/font_test.exs` | ✅ existing file, but new cases needed [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** run the smallest affected subset of `font_test`, `measure_test`, and `writer_test`. [VERIFIED: codebase grep]
- **Per wave merge:** run the quick command above plus any new fixture-specific test file added during Wave 0. [ASSUMED]
- **Phase gate:** `mix verify` must pass before `/gsd-verify-work`. [VERIFIED: `mix help verify`] [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/support/fixtures/fonts/` — no committed `.ttf` or `.otf` fixture files exist today, and Phase 26 needs stable sample fonts for deterministic regression coverage. [VERIFIED: codebase grep]
- [ ] `test/rendro/pdf/embedded_font_test.exs` or equivalent cases added to existing test files — current suite proves built-in logical-font resolution but not custom-font embedding or path-vs-binary parity. [VERIFIED: codebase grep]
- [ ] Docs-contract additions for truthful custom-font wording — current docs-contract lanes exist, but they do not yet prove Phase 26 typography claims. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [ASSUMED] | not applicable to core font handling |
| V3 Session Management | no [ASSUMED] | not applicable to core font handling |
| V4 Access Control | no [ASSUMED] | not applicable to core font handling |
| V5 Input Validation | yes [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] | eager font preflight, explicit source-shape validation, typed unsupported-format failures |
| V6 Cryptography | no [ASSUMED] | do not introduce custom crypto; any optional source hashing should use `:crypto` only |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed font binary causes parser crash or inconsistent metrics | Denial of Service | Parse only the required tables, reject missing/invalid lengths early, and keep parsing inside deterministic typed error surfaces. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |
| Restricted-license font is embedded anyway | Tampering / Repudiation | Parse `OS/2.fsType` and reject restricted embedding or subsetting modes deterministically. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2] |
| Path-based registration depends on temp-file lifetime or release layout | Tampering | Normalize paths to bytes immediately and store Rendro-owned data only. [VERIFIED: planning docs] |
| Unsupported outline flavor silently renders wrong glyph metrics | Integrity | Reject unsupported CFF-flavored OTF in this phase instead of guessing. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |

## Sources

### Primary (HIGH confidence)
- Repository source files (`lib/rendro/font_registry.ex`, `lib/rendro/pipeline/build.ex`, `lib/rendro/pipeline/measure.ex`, `lib/rendro/pipeline/measured_text.ex`, `lib/rendro/pdf/font.ex`, `lib/rendro/pdf/writer.ex`, `mix.exs`, `lib/mix/tasks/verify.ex`, `scripts/verify_docs.exs`, related tests) — current Phase 25 seams, verification commands, and missing fixture state. [VERIFIED: codebase grep]
- Adobe PDF Reference — TrueType font dictionaries, width arrays, font descriptors, and `FontFile2` embedding path. [CITED: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.2.pdf]
- Microsoft OpenType spec (`otff`, `os2`) — required sfnt tables, outline-flavor distinctions, and `fsType` embedding restrictions. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2]
- Apple TrueType Reference Manual (`head`) — `unitsPerEm` and core metric dependencies. [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html]

### Secondary (MEDIUM confidence)
- Apache PDFBox font guide — current ecosystem confirmation that embedded TrueType remains the standard portability path for PDFs. [CITED: https://svn.apache.org/repos/asf/pdfbox/site/publish/userguide/fonts.html?p=1507079]
- Adobe Distiller font-handling guide — confirms Type 1 and TrueType fonts can be embedded when not restricted from embedding. [CITED: https://helpx.adobe.com/acrobat/desktop/create-documents/explore-advanced-conversion-settings/font-handling-distiller.html]
- `truetype_metrics` Hex docs and source — current pure-Elixir reference point for narrow TTF metrics extraction. [CITED: https://hexdocs.pm/truetype_metrics/TruetypeMetrics.html] [CITED: https://raw.githubusercontent.com/boydm/truetype_metrics/master/lib/truetype_metrics.ex]
- `opentype` Hex docs and source — current Elixir reference point for OpenType parsing/shaping and collection limitations. [CITED: https://hexdocs.pm/opentype/OpenType.html] [CITED: https://raw.githubusercontent.com/jbowtie/opentype-elixir/master/lib/opentype.ex]
- `ex_guten` README and docs — proof that pure Elixir can embed TTF/OTF fonts and subset them, but on a different engine architecture. [CITED: https://hexdocs.pm/ex_guten/readme.html] [CITED: https://raw.githubusercontent.com/hwatkins/ex_guten/master/README.MD]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - repo/runtime facts are verified, but the “no new runtime dependency” recommendation is an architectural synthesis rather than a directly documented requirement. [VERIFIED: codebase grep] [VERIFIED: mix hex.info]
- Architecture: HIGH - the existing Build/Measure/MeasuredText/Writer seam is explicit in the codebase and aligns with the locked context decisions. [VERIFIED: codebase grep] [VERIFIED: planning docs]
- Pitfalls: MEDIUM - key failure modes are strongly supported by specs and current code, but some warning-sign examples are forward-looking review guidance. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/os2] [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]

**Research date:** 2026-04-30
**Valid until:** 2026-05-30

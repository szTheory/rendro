# Phase 26: Deterministic Font Metrics and PDF Embedding - Research

**Researched:** 2026-04-30
**Domain:** deterministic custom-font registration, metrics parity, PDF embedding
**Confidence:** HIGH

## Summary

Phase 25 established the document-owned logical font registry and one shared built-in resolution path, but the resolved payload is still a narrow `%Rendro.PDF.Font{}` for Helvetica-compatible built-ins only. Phase 26 needs to widen that shared contract so the same resolved logical font entry can carry deterministic metrics into `Measure` and deterministic embedding data into `Writer` without introducing ambient filesystem dependence, silent fallback, or broader fallback/i18n claims.

**Primary recommendation:** split Phase 26 into three execution plans. First, extend the registry and document boundary with explicit embedded-font registration and eager normalization of `{:path, path}` / `{:binary, bytes}` into Rendro-owned pure data plus early preflight. Second, route measurement and pagination through the same preflighted descriptor so wrapped lines, widths, heights, and page breaks derive from the resolved font metrics rather than the current single built-in width table. Third, teach the writer to emit embedded font objects and add structural regression proof around font resources, deterministic pagination parity, and typed failure cases.

Keep the phase intentionally narrow. Do not add fallback chains, unsupported-glyph recovery, system-font discovery, remote loading, arbitrary weight axes, variable fonts, or public whole-file byte-identity guarantees. Those would either violate the truthful scope boundary or pre-spend Phase 27.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Embedded-font registration API | `Rendro.Document` / `Rendro` | `Rendro.FontRegistry` | Public authoring remains document-owned pure data. |
| Path/binary normalization and preflight | `Rendro.FontRegistry` | new PDF font parsing helper | Normalize external state once before layout/render stages run. |
| Shared resolved descriptor for stages | `Rendro.FontRegistry` | `Rendro.Pipeline.MeasuredText` | Measure and Writer must consume one source of truth. |
| Font metrics extraction | new PDF font parsing/helper layer | `Rendro.PDF.Font` | Width data should be derived once from validated font data. |
| PDF embedding object construction | `Rendro.PDF.Writer` | new embedded-font helper/module | Writer owns PDF object allocation and resource emission. |
| Typed invalid-font failures | `Rendro.Pipeline.Build` | `Rendro.Error` surfaces | Build is the earliest deterministic failure boundary already established by Phase 25. |

## Architecture Patterns

### Pattern 1: Eagerly capture external state into owned pure data
Path-based custom fonts are ergonomically important for Phoenix/Plug/Oban callers, but later pipeline stages cannot depend on temp files, releases, uploads, or mutable host files. The embedded registration path should read bytes up front, validate them, and store an owned descriptor on the document registry. After registration/preflight, later phases should not re-open the filesystem.

### Pattern 2: One resolved descriptor for both metrics and embedding
Phase 25 already established one resolver for measure and writer. Phase 26 should preserve that shape but widen the resolved payload. The resolver output should carry at least:
- logical font identity
- source kind (`:built_in` or `:embedded`)
- deterministic metric data used by width calculation
- embedding payload metadata used by writer resource/object construction

If measure and writer each rebuild different interpretations of the same font source, pagination drift is almost guaranteed.

### Pattern 3: Preflight once, consume many times
Unreadable bytes, unsupported formats, missing metric tables, and non-embeddable fonts should fail once before `measure`, `paginate`, or `render`. Later stages should consume preflighted descriptors rather than reopening files, reparsing bytes, or re-deciding license/embeddability.

### Pattern 4: Structural embedding proof over whole-file byte identity
The truthful public contract for this phase is deterministic layout behavior plus successful structural embedding. Verification should inspect that the expected font resources and embedded font objects exist and that layout remains stable across runs. Full-PDF byte identity can remain a narrow internal regression tool if needed, but should not become the main user-facing promise.

## Concrete Repo Findings

### Verified current state
- `lib/rendro/font_registry.ex` stores built-in-only descriptors and resolves them into `%Rendro.PDF.Font{}` values.
- `lib/rendro/pipeline/build.ex` already rejects unknown logical fonts and invalid font references before later stages run.
- `lib/rendro/pipeline/measure.ex` uses the resolved `Rendro.PDF.Font` for `Font.text_width/3`, so metrics can be swapped behind the existing wrapping algorithm without redesigning line breaking.
- `lib/rendro/pipeline/measured_text.ex` already carries `resolved_font`, which is the correct measure-to-render parity seam.
- `lib/rendro/pdf/writer.ex` currently only emits simple Type1 built-in font objects with `BaseFont`; it has no embedded-font object graph yet.
- `lib/rendro/pdf/font.ex` is the current metrics carrier and width calculator. It is the natural place to generalize width access while keeping a narrow public/internal contract.

### Implications
- The public document and text API does not need a redesign; the main work is widening the descriptor and writer internals truthfully.
- `Build` can remain the earliest deterministic failure boundary for invalid embedded-font setup.
- `Measure` and `Paginate` can stay algorithmically stable if metrics are injected behind the existing width/height seam.
- `Writer` will need a more meaningful object model for embedded fonts than the current built-in Type1 branch, but it should still own object numbering, resource maps, and serialization.

## Anti-Patterns To Avoid

- **Do not add system-font discovery or implicit OS lookup.** It breaks deterministic layout and violates the phase context directly.
- **Do not keep path references live past registration/preflight.** Temp-file lifetime and deployment layout must not affect later stages.
- **Do not let Writer silently fall back to Helvetica when embedded setup fails.** Explicit custom-font usage must be a hard failure.
- **Do not fork measurement into a separate embedded-font wrapping algorithm.** Preserve one wrapping pipeline and change only the metrics source.
- **Do not claim general Unicode/i18n or shaping support.** Embedded fonts alone do not solve fallback, shaping, RTL, or unsupported glyph handling.
- **Do not make byte-for-byte final PDF identity the main acceptance target.** Structural embedding and layout parity are the truthful contract here.

## Common Pitfalls

### Pitfall 1: Path input remains lazy
If `{:path, path}` is stored as a path and re-read later, pagination and output can depend on external file lifetime. Avoid this by eagerly reading and validating into owned bytes or a preflighted descriptor before later stages run.

### Pitfall 2: Metrics and embedding diverge
If measurement extracts widths from one parse path and writer embeds a different parse result or subset, wrapped lines and final PDF resources can drift. One resolved descriptor should drive both.

### Pitfall 3: Build only validates names, not readiness
Phase 25 only needed logical-name validation. Phase 26 needs Build to also catch unreadable bytes, unsupported format/metrics gaps, and non-embeddable fonts so later stages stay deterministic and simple.

### Pitfall 4: Tests only assert PDF contains a font name
Writer-only assertions are insufficient. Phase 26 needs proof that the same font choice affects wrapped lines/page counts and that the PDF structurally contains the expected embedded-font resources/objects.

## Recommended Phase Split

### Plan 26-01
Scope:
- add explicit embedded-font registration helpers on document/top-level APIs;
- accept `{:path, path}` and `{:binary, bytes}`;
- normalize external input into owned pure data;
- preflight and extend registry descriptor modeling;
- add typed early failures in Build.

### Plan 26-02
Scope:
- generalize `Rendro.PDF.Font` or equivalent metrics carrier for embedded fonts;
- route `Measure` through embedded metrics using the same resolver;
- preserve `MeasuredText.resolved_font` parity;
- prove line-wrap, height, and page-break determinism with focused tests.

### Plan 26-03
Scope:
- add embedded-font PDF object/resource construction in Writer;
- keep built-in and embedded writer paths explicit but unified under one resolver;
- add structural PDF embedding assertions and deterministic regression coverage;
- update verification/docs-contract surfaces only as needed to reflect shipped support truthfully.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` |
| Full suite command | `mix test && mix run scripts/verify_docs.exs` |
| Estimated runtime | ~20-30 seconds |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FONT-02 | measure/paginate/render use the same resolved font metrics | unit + regression | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/pdf/writer_test.exs` | ✅ |
| FONT-03 | supported custom fonts embed through the document contract | unit + structural regression | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` | ✅ |
| FONT-02 / FONT-03 | invalid custom setup fails early and deterministically | unit | `mix test test/rendro/document_test.exs test/rendro/pdf/font_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** run the smallest affected typography-focused subset.
- **Per plan wave:** run the phase quick command.
- **Phase gate:** full suite plus docs verification before execution closeout.

### Wave 0 Gaps
- None required. Existing ExUnit surfaces cover the document, pipeline, paginate, and writer seams this phase needs.

## Sources

### Primary
- `AGENTS.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/26-deterministic-font-metrics-and-pdf-embedding/26-CONTEXT.md`
- `.planning/phases/26-deterministic-font-metrics-and-pdf-embedding/26-PATTERNS.md`
- `.planning/phases/25-font-registry-and-public-typography-contract/25-RESEARCH.md`
- `.planning/phases/25-font-registry-and-public-typography-contract/25-PATTERNS.md`
- `.planning/phases/25-font-registry-and-public-typography-contract/25-02-SUMMARY.md`
- `lib/rendro/font_registry.ex`
- `lib/rendro/pipeline/build.ex`
- `lib/rendro/pipeline/measure.ex`
- `lib/rendro/pipeline/measured_text.ex`
- `lib/rendro/pdf/font.ex`
- `lib/rendro/pdf/writer.ex`

## Metadata

**Key insight:** Phase 26 should not behave like “custom fonts everywhere.” It should behave like “the same preflighted logical font descriptor deterministically drives layout math and PDF embedding, or the pipeline fails early with explicit errors.” That keeps the capability real, narrow, and composable for the fallback/i18n boundary work in Phase 27.

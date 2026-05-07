<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None found.

### the agent's Discretion
None found.

### Deferred Ideas (OUT OF SCOPE)
None found.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FONT-04 | Add explicit fallback-chain resolution rules for missing glyphs. | Explored `FontRegistry` and `Measure` to support font fallback chains |
| I18N-01 | Emit typed diagnostics/errors for unsupported glyph scenarios. | Identified missing glyph tracking in `Measure.ex` and `doc.diagnostics` |
| I18N-02 | Emit typed diagnostics for RTL and complex shaping scenarios. | Developed strategy using Unicode range inspection during `Measure.ex` |
</phase_requirements>

# Phase 27: Fallback Chains and Honest I18n Diagnostics - Research

**Researched:** `date +%Y-%m-%d`
**Domain:** Typography, Text Shaping, Unicode, and PDF Generation
**Confidence:** HIGH

## Summary

This phase transitions Rendro from implicitly failing on unsupported characters to explicitly falling back or diagnosing text rendering issues. Instead of silent boxes or reversed Arabic text, Rendro will define a fallback font chain and emit structured diagnostics (`doc.diagnostics`) when it encounters RTL, complex shaping, or missing glyphs. This ensures honest behavior per the "narrow Unicode/i18n support matrix" mandate.

**Primary recommendation:** Introduce a `Rendro.I18n.Analyzer` to scan text during `Rendro.Pipeline.Measure`. Update `FontRegistry` to support fallback chains and change `MeasuredText` to represent lines as lists of font-specific text runs, outputting `/F#` switches in `Rendro.PDF.Writer`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fallback Chain Resolution | PDF Generation (`FontRegistry`) | — | Font resolution must provide fallback options to the layout system |
| Text Shaping/Measurement | PDF Generation (`Measure`) | — | Text must be split into runs depending on which font has the glyph |
| I18n/Unicode Diagnostics | Telemetry/Text Processing (`I18n.Analyzer`) | — | Identifies RTL/Complex shaping using Unicode block ranges |
| Text Rendering (Runs) | PDF Generation (`Writer`) | — | Writer must emit font change instructions (`/F1 12 Tf`) inline |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `String` / native | Core | Unicode codepoint inspection | Built-in UTF-8 handling is fully capable of range checking without C-extensions |

*No new dependencies required. Elixir's native `String.to_charlist` and `String.codepoints` are sufficient for matching Unicode blocks and building runs.*

## Architecture Patterns

### Pattern 1: Explicit Fallback Chain in Registry
**What:** The `FontRegistry` allows defining fallback fonts for a registered logical font.
**When to use:** During font registration.
**Example:**
```elixir
Rendro.FontRegistry.register_embedded(registry, :body, {:path, "NotoSans.ttf"}, fallbacks: [:noto_cjk, :noto_emoji])
```

### Pattern 2: Text Runs in `MeasuredText`
**What:** `MeasuredText.lines` changes from `[String.t()]` to lists of runs `[[%{font: Font.t(), text: String.t(), width: float()}]]` or `[[{Font.t(), String.t()}]]`.
**When to use:** When text contains characters that need fallback fonts.
**Example:**
```elixir
%MeasuredText{
  lines: [
    [
      %{font: primary_font, text: "Hello "},
      %{font: fallback_font, text: "🌍"}
    ]
  ]
}
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Checking for missing glyphs at render time in `Writer`.
  - **Why it's bad:** Writer has no ability to adjust layout widths. The font choice changes the width of the character.
  - **What to do instead:** All glyph availability checks and fallback resolution MUST happen in `Measure`, which builds `MeasuredText`.

## Runtime State Inventory

*None — verified by codebase inspection. This phase does not involve string renames or migration of external state, only internal data structures during document rendering.*

## Common Pitfalls

### Pitfall 1: Garbage Collection from Character Iteration
**What goes wrong:** High memory usage and slow layout.
**Why it happens:** Converting entire documents to `charlist` and checking each char against multiple font maps repeatedly.
**How to avoid:** Iterate efficiently. Use Elixir's binary pattern matching where possible, or convert to charlist once per segment, check `font.widths` map, and chunk consecutive characters into a single binary.

### Pitfall 2: Diagnostic Spam
**What goes wrong:** The `doc.diagnostics` list contains 5,000 entries because an Arabic document was provided.
**Why it happens:** Emitting a diagnostic for *every* unsupported character.
**How to avoid:** Maintain an accumulator in `Measure` that uses a `MapSet` for diagnostic types/reasons, or only emit one `unsupported_script` diagnostic per block.

### Pitfall 3: Notdef Width Mismatch
**What goes wrong:** Missing glyphs are rendered with overlapping text.
**Why it happens:** When a character is completely missing (not in primary or any fallback), `Measure` might use 0 width or the font's default, but the PDF reader might use a different `.notdef` width.
**How to avoid:** Ensure that if all fallbacks fail, we explicitly look up the width of glyph `0` (the `.notdef` glyph) in the primary font, and use that width.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Silent failure | Diagnostic emission | Phase 27 | Developers know when text shaping is unsupported |
| Single font per block | Multi-font runs | Phase 27 | Emojis and multi-lingual text work via fallbacks |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Missing glyphs can be reliably detected by checking `Map.has_key?(font.widths, codepoint)`. | Summary | Text might be measured incorrectly if default width is used silently. |

## Open Questions (RESOLVED)

1. **How should fallback fonts be declared?**
   - What we know: `FontRegistry` currently takes a flat list of options.
   - What's unclear: Should `fallbacks` be resolved at registration time, or lazy-evaluated at `resolve_pdf_font` time?
   - Recommendation: Lazy evaluate them during `resolve_pdf_font` so the order of registration doesn't matter.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test/test_helper.exs |
| Quick run command | `mix test test/rendro/pipeline/measure_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FONT-04 | Resolves and splits text into runs based on fallback fonts | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ Wave 0 |
| I18N-01 | Emits missing glyph diagnostics | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ Wave 0 |
| I18N-02 | Detects and emits RTL/shaping diagnostics | unit | `mix test test/rendro/i18n_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/measure_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/i18n_test.exs` — covers I18N-02 (RTL/complex shaping detection)

# Phase 19: Deterministic Text Flow and Break Semantics - Research

**Researched:** 2026-04-29
**Domain:** deterministic wrapped-text measurement, pagination keep/break semantics, flow rendering
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Width-constrained flow text remains a `Rendro.Block` containing `Rendro.Text`; Rendro does not make `Rendro.Text` self-wrapping by adding geometry such as `:width`.
- **D-02:** `Rendro.Block.width` remains the public width constraint for wrapped flow text because block geometry is already the measured and paginated unit in the existing engine.
- **D-03:** Text-specific vertical styling such as `line_height` belongs on `Rendro.Text`, not on `Rendro.Block`, so content styling stays separate from page geometry.
- **D-04:** Wrapped text semantics in Phase 19 stay narrow and truthful: preserve explicit newlines, wrap deterministically on whitespace, and document one explicit fallback for single tokens that exceed available width.
- **D-05:** Phase 19 does not introduce a new report DSL or paragraph authoring layer as the primary public contract. If a `Rendro.paragraph/2` helper is ever added later, it should compile to the same block-and-text core contract rather than replace it.
- **D-06:** `keep_together`, `keep_with_next`, `break_before`, and `break_after` live on `Rendro.Block` as the only public break-intent surface for this phase.
- **D-07:** `Rendro.Text` does not carry break directives. It remains a leaf content/style struct, not a pagination container.
- **D-08:** Phase 19 does not add section-level break semantics or flow action nodes such as standalone `page_break()` content items. Those would widen the grammar before the core contract is stable.
- **D-09:** `keep_with_next` applies to the current block plus the immediate next pagination unit in Phase 19. Chaining behavior must be deterministic and explicitly documented if multiple consecutive blocks opt in.
- **D-10:** `keep_together` and `keep_with_next` are hard authored constraints, not advisory hints. If the kept unit fits on a fresh page/body region, move it intact; if it cannot fit even there, fail truthfully.
- **D-11:** Impossible keep-rule layouts return the existing typed paginate overflow contract (`%Rendro.Error{stage: :paginate, reason: :content_overflow}`) rather than silently relaxing the keep rule, shrinking content, clipping content, or raising raw exceptions.
- **D-12:** Keep-related failures enrich `Rendro.Error.details` instead of creating a new top-level error family. Minimum keep-specific diagnostics should include the keep rule involved, the kept height, the max available height, page/region context, and the kept block indexes.
- **D-13:** Flow-only break directives used on fixed-position pages should fail with a typed boundary error rather than being silently ignored.
- **D-14:** The public story for Phase 19 is: text wraps when a flow block has constrained width, and flow blocks can carry explicit pagination intent (`keep_together`, `keep_with_next`, `break_before`, `break_after`).
- **D-15:** README and guides should teach the supported core path using `Rendro.flow/2`, `Rendro.block/2`, `Rendro.text/2`, and page templates/regions. User-facing examples should not mention internal pipeline stages.
- **D-16:** Docs must stay explicit about what Phase 19 does not promise: no widow/orphan control, no hyphenation, no typography engine claims beyond current deterministic font metrics, no browser/CSS break model, and no automatic “best effort” relaxation of keep rules.
- **D-17:** For this project, downstream GSD agents should continue the recommendation-first posture: research deeply, collapse routine tradeoffs into one coherent default, and only escalate choices that materially affect product semantics or roadmap scope.
- **D-18:** The specific preference captured from this discussion is to shift this posture left within GSD where possible. Future discuss/research/planning steps should avoid option menus by default unless the decision is unusually high-impact or policy-significant.

### Claude's Discretion
- Exact names for any new `Rendro.Text` styling field(s) added for wrapped text, as long as geometry remains on `Block` and style remains on `Text`.
- The exact long-token fallback, as long as it is deterministic, documented, and fixture-tested.
- Whether future convenience helpers are deferred entirely to Phase 22 or introduced as thin sugar only after the block-and-text core contract is documented and proven.

### Deferred Ideas (OUT OF SCOPE)
- Add a higher-level `Rendro.paragraph/2` helper or other recipe-oriented sugar only if later phases prove the boilerplate is materially harming DX.
- Introduce softer future directives such as `ensure_space` or `avoid_break` only as separate semantics; do not weaken the meaning of `keep_together` or `keep_with_next`.
- Widow/orphan control, hyphenation, richer line-breaking algorithms, and typography-sensitive paragraph semantics belong to later milestones once fonts/assets are in scope.
- Table-row integrity and row-level keep semantics belong to Phase 20, not Phase 19.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-06 | Engineer can author wrapped text inside width-constrained flow regions with deterministic line-breaking behavior. | Measure must produce stable wrapped lines and heights from `Block.width`, and Writer must serialize those measured lines explicitly instead of treating text as single-line content. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] |
| LAY-09 | Engineer can control pagination through explicit keep/break directives such as `keep_together`, `keep_with_next`, and break-before/after rules. | Paginate already owns page assignment and typed overflow behavior, so block-level keep/break semantics should be evaluated there against measured heights and body-region capacity. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] |
</phase_requirements>

## Summary

Phase 19 is a three-stage engine change, not just a `Measure` enhancement: current measurement computes one width and one height for `%Rendro.Text{}` blocks, current pagination sums those heights as indivisible units, and current PDF writing emits one `Td`/`Tj` operation per text block. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex]

The planning anchor is therefore: keep the public authoring contract narrow, but add a private measured-text representation that survives from `Measure` through `Paginate` into `Writer`. [ASSUMED] Without that, wrapped heights can become truthful in `Measure` while rendered output still remains single-line, which would break determinism and overflow truthfulness. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]

The second planning anchor is that keep/break semantics belong on already-measured pagination units. `Paginate` is already the stage that moves blocks between pages, applies body-region fit checks, and turns impossible layouts into `%Rendro.Error{stage: :paginate, reason: :content_overflow}`. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] That existing contract should be extended, not bypassed. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md]

**Primary recommendation:** keep width on `Rendro.Block`, add text-only line styling on `Rendro.Text`, perform deterministic newline-aware wrapping in `Measure`, evaluate keep/break groups in `Paginate`, and teach `Writer` to emit measured lines explicitly. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md, lib/rendro/pdf/writer.ex] [ASSUMED]

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and avoid new hard dependencies on Phoenix, Oban, or admin tooling. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md]
- Prefer optional dependency guards for integrations; Phase 19 should stay in core. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md]
- Preserve the existing data-first pipeline `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: /Users/jon/projects/rendro/AGENTS.md, lib/rendro/pipeline.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Width-constrained text wrapping | API / Backend | Database / Storage | Wrapping is computed inside pure Elixir pipeline code using font metrics and string processing; no storage tier owns the decision. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/font.ex] |
| Explicit newline preservation | API / Backend | — | Newline handling is string normalization and line construction inside `Measure`, not a render-only concern. [VERIFIED: lib/rendro/pipeline/measure.ex] [CITED: https://hexdocs.pm/elixir/1.19.3/String.html] |
| `keep_together` / `keep_with_next` / break-before / break-after | API / Backend | — | Page movement and overflow truthfulness already live in `Paginate`, so authored page intent belongs there. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] |
| Multi-line text serialization | API / Backend | CDN / Static | PDF content streams are generated inside `Rendro.PDF.Writer`; they must reflect measured lines exactly. [VERIFIED: lib/rendro/pdf/writer.ex] |
| Public API/docs exposure | API / Backend | Frontend Server (SSR) | The public contract is builder-based Elixir API plus README/guides examples, not UI runtime behavior. [VERIFIED: lib/rendro.ex, README.md, guides/integrations.md] |

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard | Source |
|------------------|---------|---------|--------------|--------|
| Elixir | 1.19.5 / OTP 28 | Runtime, `String`, `Enum`, `Regex`, and binary handling for deterministic wrapping logic. | Already the project runtime; no additional dependency is needed for Phase 19 core behavior. | [VERIFIED: `elixir --version`, `mix --version`] [CITED: https://hexdocs.pm/elixir/1.19.3/String.html] |
| `Rendro.PDF.Font` | repo-local | Deterministic glyph width measurement using built-in Helvetica metrics. | Phase 19 must preserve current deterministic font-metric behavior rather than introducing external shaping libraries early. | [VERIFIED: lib/rendro/pdf/font.ex] |
| `Rendro.Pipeline.Measure` | repo-local | Current seam for text width/height calculation. | Wrapped-line construction belongs here because this stage already turns authored text into measured geometry. | [VERIFIED: lib/rendro/pipeline/measure.ex] |
| `Rendro.Pipeline.Paginate` | repo-local | Current seam for page assignment, body fit checks, and overflow errors. | Keep/break semantics should extend existing page-fit logic instead of creating a side channel. | [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/error.ex] |
| `Rendro.PDF.Writer` | repo-local | Current seam for page content stream serialization. | Wrapped text is incomplete until the writer emits measured lines instead of one raw string per block. | [VERIFIED: lib/rendro/pdf/writer.ex] |

### Supporting
| Library | Version | Purpose | When to Use | Source |
|---------|---------|---------|-------------|--------|
| `stream_data` | 1.3.0 | Property-style determinism proofs for identical input and repeated measurement/pagination runs. | Use for LAY-06 regression properties once line breaking is implemented. | [VERIFIED: `mix deps`, `mix hex.info stream_data`] |
| `telemetry` | 1.4.1 | Existing stage instrumentation across the pipeline. | Keep unchanged in Phase 19; telemetry semantics become more useful after break diagnostics in Phase 21. | [VERIFIED: `mix deps`, `mix hex.info telemetry`, lib/rendro/pipeline.ex] |
| `ex_doc` | 0.40.1 | Docs generation for README/guides contract maintenance. | Use when updating public examples and truthfulness notes for wrapped text and keep rules. | [VERIFIED: `mix deps`, `mix hex.info ex_doc`] |
| Phoenix | 1.8.5 | Optional adapter surface only. | Not part of Phase 19 core implementation; keep untouched unless examples require integration smoke coverage later. | [VERIFIED: `mix deps`, `mix hex.info phoenix`, /Users/jon/projects/rendro/AGENTS.md] |
| Oban | 2.21.1 locked, 2.22.0 latest release listed | Optional async adapter only. | Out of scope for Phase 19 core semantics; do not expand keep/break behavior into worker adapters here. | [VERIFIED: `mix deps`, `mix hex.info oban`, /Users/jon/projects/rendro/AGENTS.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Elixir stdlib + existing `Rendro.PDF.Font` metrics | A paragraph-layout or shaping dependency | Adds scope, dependency risk, and typography claims that the project has explicitly deferred beyond this milestone. [VERIFIED: .planning/REQUIREMENTS.md, /Users/jon/projects/rendro/AGENTS.md] |
| Block-level keep/break semantics | A new flow action DSL | Conflicts with locked decisions D-05 and D-08, and would widen the public grammar before the core contract is proven. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md] |
| Typed overflow on impossible keep rules | Silent keep-rule relaxation | Violates the existing truthful overflow posture established in Phase 18. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md, lib/rendro/error.ex] |

**Installation:**
```bash
mix deps.get
mix deps.compile
```

**Version verification:** verify the runtime and supporting packages before implementation planning. [VERIFIED: `elixir --version`, `mix deps`, `mix hex.info telemetry`, `mix hex.info phoenix`, `mix hex.info oban`, `mix hex.info stream_data`, `mix hex.info credo`, `mix hex.info dialyxir`, `mix hex.info ex_doc`]
```bash
elixir --version
mix --version
mix deps
mix hex.info telemetry
mix hex.info stream_data
mix hex.info ex_doc
```

## Architecture Patterns

### System Architecture Diagram

The recommended flow keeps one public authoring surface and one private measured-text carrier. [ASSUMED]

```text
Rendro.flow/block/text builders
        |
        v
Compose
  - normalize sections/regions into block lists
        |
        v
Measure
  - preserve explicit newline boundaries
  - wrap each segment against Block.width
  - apply deterministic long-token fallback
  - compute final block height from measured lines
        |
        v
Paginate
  - apply break_before / break_after
  - form keep groups from keep_together / keep_with_next
  - move intact groups to next page when they fit
  - emit typed overflow details when they cannot fit
        |
        v
Writer
  - emit one PDF text operation per measured line
  - keep page-local x/y positions deterministic
        |
        v
Validate
  - preserve existing post-render structural checks
```

### Recommended Project Structure
```text
lib/rendro/
├── block.ex                  # public break-intent fields
├── text.ex                   # text-only line styling
├── pipeline/measure.ex       # newline-aware wrapping + multi-line height
├── pipeline/paginate.ex      # keep/break grouping + overflow diagnostics
├── pdf/writer.ex             # explicit multi-line text emission
├── error.ex                  # keep-rule diagnostics enrichment
└── rendro.ex                 # public builders/docs coherence

test/rendro/
├── flow_test.exs             # public wrapped-text and keep/break behavior
├── pipeline/measure_test.exs # deterministic line-break and height proofs
├── pipeline/paginate_test.exs# keep-group moves and impossible-layout failures
└── pdf/writer_test.exs       # multi-line content stream rendering proof
```
[VERIFIED: current module layout in `lib/` and `test/`] [ASSUMED]

### Pattern 1: Measure Wrapped Text Before Pagination
**What:** Turn width-constrained text blocks into measured line sequences and final heights before page assignment. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex]  
**When to use:** Any `%Rendro.Block{content: %Rendro.Text{}, width: number}` in a flow document. [VERIFIED: lib/rendro/block.ex, lib/rendro/text.ex]  
**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/String.html
def wrap_token(token, max_width, font, size) do
  Stream.unfold(token, fn
    "" -> nil
    rest -> String.next_grapheme(rest)
  end)
  |> Enum.reduce({"", []}, fn grapheme, {current, lines} ->
    candidate = current <> grapheme

    if Rendro.PDF.Font.text_width(font, candidate, size) <= max_width do
      {candidate, lines}
    else
      {grapheme, lines ++ [current]}
    end
  end)
end
```

### Pattern 2: Paginate Keep Groups, Not Raw Blocks
**What:** Evaluate `keep_together` and `keep_with_next` after heights are known, then move or fail the whole measured group as one unit. [VERIFIED: lib/rendro/pipeline/paginate.ex, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]  
**When to use:** Any flow pagination pass over measured blocks. [VERIFIED: lib/rendro/pipeline/paginate.ex]  
**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/Enum.html
Enum.chunk_while(blocks, [], fn block, acc ->
  if block.keep_with_next do
    {:cont, acc ++ [block]}
  else
    {:cont, acc ++ [block], []}
  end
end, fn
  [] -> {:cont, []}
  acc -> {:cont, acc, []}
end)
```
[ASSUMED]

### Pattern 3: Render Measured Lines Explicitly
**What:** Serialize wrapped text line-by-line from measured output, not from the original unsplit string. [VERIFIED: lib/rendro/pdf/writer.ex]  
**When to use:** Any text block whose measured representation contains more than one line. [ASSUMED]  
**Example:**
```elixir
# Source: /Users/jon/projects/rendro/lib/rendro/pdf/writer.ex
Enum.map_join(page.blocks, "\n", fn block ->
  render_block(block, page, font)
end)
```

### Anti-Patterns to Avoid
- **Wrapping in `Writer` only:** render-time wrapping would bypass existing fit checks and break truthful overflow behavior. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex]
- **Using `String.split/1` across the full paragraph:** `String.split/1` splits on Unicode whitespace and ignores leading/trailing whitespace, so it is the wrong primitive for preserving authored newline boundaries. [CITED: https://hexdocs.pm/elixir/1.19.3/String.html]
- **Softening impossible keep rules silently:** D-10 through D-12 explicitly reject best-effort relaxation. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]
- **Adding a new paragraph DSL in Phase 19:** locked scope forbids widening the public grammar before the block-and-text contract is proven. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rich typography | Hyphenation, widow/orphan control, locale-sensitive paragraph shaping | Explicitly defer them and ship only newline-preserving whitespace wrapping. | Those capabilities are outside the locked Phase 19 scope and would force unsupported typography claims. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md, .planning/REQUIREMENTS.md] |
| Public API expansion | A new paragraph/report DSL | Existing `Rendro.flow/2`, `Rendro.block/2`, and `Rendro.text/2` builders | The user decisions explicitly keep the public story on current builders. [VERIFIED: lib/rendro.ex, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md] |
| Overflow recovery | Auto-shrink, clip, or silently drop keep rules | Existing `%Rendro.Error{stage: :paginate, reason: :content_overflow}` path with richer `details` | Phase 18 established truthful overflow as product behavior. [VERIFIED: lib/rendro/error.ex, .planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md] |

**Key insight:** the only hard problem Phase 19 needs to solve now is deterministic line construction plus deterministic page-intent evaluation; everything else tempting around paragraphs is explicitly deferred. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Height Truth Without Render Truth
**What goes wrong:** `Measure` computes a multi-line height but `Writer` still emits one text operation, so rendered output no longer matches paginated geometry. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex]  
**Why it happens:** current writer has no concept of measured line lists; it renders one `%Rendro.Text{}` string per block. [VERIFIED: lib/rendro/pdf/writer.ex]  
**How to avoid:** carry a private measured-text representation through pagination into writer serialization. [ASSUMED]  
**Warning signs:** wrapped blocks pass fit checks yet PDF text visually overlaps or ignores authored width. [VERIFIED: lib/rendro/pdf/writer.ex] [ASSUMED]

### Pitfall 2: Evaluating Keep Rules Before Measurement
**What goes wrong:** `keep_together` or `keep_with_next` decisions are made from raw blocks before final heights are known. [VERIFIED: lib/rendro/pipeline/paginate.ex, lib/rendro/pipeline/measure.ex]  
**Why it happens:** current flow pagination sums `block.height` and assumes the value is final. [VERIFIED: lib/rendro/pipeline/paginate.ex]  
**How to avoid:** build keep groups only after wrapped text has final line counts and final heights. [ASSUMED]  
**Warning signs:** identical input produces different page moves after small text edits or after rerunning measurement. [ASSUMED]

### Pitfall 3: Losing Authored Newline Semantics
**What goes wrong:** explicit `\n` breaks disappear because implementation treats all whitespace as generic split points. [CITED: https://hexdocs.pm/elixir/1.19.3/String.html]  
**Why it happens:** `String.split/1` groups Unicode whitespace and trims edges, which is broader than the Phase 19 contract. [CITED: https://hexdocs.pm/elixir/1.19.3/String.html]  
**How to avoid:** split on explicit newline boundaries first, then wrap each segment deterministically. [ASSUMED]  
**Warning signs:** blank-line or manual line-break fixtures collapse into fewer rendered lines. [ASSUMED]

### Pitfall 4: Pairwise `keep_with_next` Rules That Don’t Chain Deterministically
**What goes wrong:** consecutive `keep_with_next` blocks produce ambiguous grouping and inconsistent failures. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]  
**Why it happens:** D-09 fixes the pairwise meaning but leaves chained behavior to implementation. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md]  
**How to avoid:** document one chain rule and fixture-test it with three-block runs. [ASSUMED]  
**Warning signs:** `A keep_with_next`, `B keep_with_next`, `C normal` behaves differently depending on starting page fill. [ASSUMED]

## Code Examples

Verified patterns from official and local sources:

### Grapheme-Safe Fallback Iteration
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/String.html
case String.next_grapheme("olá") do
  {grapheme, rest} -> {grapheme, rest}
  nil -> :done
end
```

### Stateful Chunking for Keep Groups
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/Enum.html
Enum.chunk_while(enum, acc, chunk_fun, after_fun)
```

### Current Render Constraint
```elixir
# Source: /Users/jon/projects/rendro/lib/rendro/pdf/writer.ex
[
  "BT",
  "/F1 #{format_num(text.size)} Tf",
  "#{format_num(x)} #{format_num(y)} Td",
  "(#{escape_pdf_string(text.content)}) Tj",
  "ET"
]
```
[VERIFIED: lib/rendro/pdf/writer.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-line measurement: `width = Font.text_width(...)`, `height = text.size * 1.2` | Phase 19 should treat width-constrained text as deterministic measured line boxes with total height derived from line count. | Current codebase state on 2026-04-29 vs. Phase 19 recommendation. [VERIFIED: lib/rendro/pipeline/measure.ex] [ASSUMED] | Requires coordinated changes in `Measure`, `Paginate`, and `Writer`. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, lib/rendro/pdf/writer.ex] |
| Block pagination as independent units | Block pagination with explicit break/keep grouping | Current codebase state on 2026-04-29 vs. Phase 19 requirement. [VERIFIED: lib/rendro/pipeline/paginate.ex, .planning/REQUIREMENTS.md] [ASSUMED] | Pagination tests must cover group moves, group failures, and explicit page breaks. [ASSUMED] |

**Deprecated/outdated:**
- Treating `%Rendro.Text{}` as effectively single-line in flow layout is outdated for Phase 19 planning because it cannot satisfy LAY-06. [VERIFIED: .planning/REQUIREMENTS.md, lib/rendro/pipeline/measure.ex]
- Treating break intent as undocumented caller convention is outdated for Phase 19 planning because LAY-09 requires explicit supported directives. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The deterministic long-token fallback should be grapheme-by-grapheme hard wrapping with no hyphen insertion. | Summary, Architecture Patterns, Common Pitfalls | Low-to-medium; changing the fallback mostly affects fixture expectations and docs wording. |
| A2 | Consecutive `keep_with_next` blocks should chain into one contiguous keep group that ends at the first block without `keep_with_next`. | Architecture Patterns, Common Pitfalls | Medium; this changes specific pagination behavior and test fixtures. |
| A3 | Wrapped-line data should travel through the engine in a private measured-text carrier instead of becoming a new public authoring field. | Summary, Architecture Patterns, Common Pitfalls | Medium; a different carrier choice changes implementation shape and may affect API surface cleanliness. |

## Open Questions (RESOLVED)

1. **Which private carrier should hold measured wrapped lines?**
   - Resolution: use a private internal module named `Rendro.Pipeline.MeasuredText` carried as measured block content between `Measure`, `Paginate`, and `Writer`. [RESOLVED: planner output `19-01-PLAN.md`]
   - Why this choice: it keeps `Rendro.Block` as the public geometry container, keeps `Rendro.Text` as the public style/content leaf, and avoids exposing pipeline-only wrapped-line fields on the authoring API. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-01-PLAN.md]

2. **How should chained `keep_with_next` behave?**
   - Resolution: consecutive `keep_with_next` blocks form one contiguous keep group that ends at the first block without `keep_with_next`. [RESOLVED: planner output `19-02-PLAN.md`]
   - Why this choice: it gives deterministic group boundaries for `A keep_with_next`, `B keep_with_next`, `C normal`, preserves the hard-constraint posture from D-09 through D-12, and yields fixture-testable behavior. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md, .planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core implementation and tests | ✓ | 1.19.5 / OTP 28 | — |
| Mix | Test and docs verification commands | ✓ | 1.19.5 | — |
| `mix test` subset | Fast validation loop | ✓ | ExUnit in repo | — |
| `mix docs.contract` task name | README/guides contract command | ✗ | — | Use `mix run scripts/verify_docs.exs` |

**Missing dependencies with no fallback:**
- None. [VERIFIED: `elixir --version`, `mix --version`]

**Missing dependencies with fallback:**
- `mix docs.contract` is not discoverable by `mix help docs.contract` in this workspace, but the underlying docs-contract script succeeds through `mix run scripts/verify_docs.exs`. [VERIFIED: `mix help docs.contract`, `mix run scripts/verify_docs.exs`] 

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (repo-local) [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` [VERIFIED: executed 2026-04-29; 19 tests, 0 failures] |
| Full suite command | `mix test` [VERIFIED: mix.exs, Mix conventions] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAY-06 | Same width-constrained text yields stable lines, stable heights, and stable page counts for identical input. | unit + property | `mix test test/rendro/pipeline/measure_test.exs test/rendro/flow_test.exs` | ✅ |
| LAY-09 | Block-level keep/break directives move intact groups or return typed overflow details. | unit | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | ✅ |
| LAY-06 / LAY-09 docs contract | Public README examples show wrapped text and keep/break semantics without internal pipeline details. | docs-contract | `mix run scripts/verify_docs.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` [VERIFIED: executed 2026-04-29]
- **Per wave merge:** `mix test` plus `mix run scripts/verify_docs.exs` [VERIFIED: mix.exs, lib/mix/tasks/docs.contract.ex]
- **Phase gate:** Full suite green and docs-contract green before `/gsd-verify-work`. [VERIFIED: .planning/config.json, README.md]

### Wave 0 Gaps
- [ ] Add property-style determinism coverage for repeated wrap measurement on identical input, likely in `test/rendro/pipeline/measure_test.exs` or a new focused file using `stream_data`. [VERIFIED: `stream_data` available via `mix deps`; current file has unit coverage but no property test found in `test/rendro/pipeline/measure_test.exs`]
- [ ] Add writer-level proof that wrapped multi-line text serializes into multiple text placements rather than one literal string. `test/rendro/pdf/writer_test.exs` exists, but no Phase 19 line-wrap proof was found during research. [VERIFIED: `rg --files test`, lib/rendro/pdf/writer.ex]
- [ ] Add README/docs-contract examples for wrapped flow text and keep/break directives; current README does not mention them yet. [VERIFIED: README.md, `mix run scripts/verify_docs.exs`]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not applicable to pure layout semantics. [VERIFIED: .planning/REQUIREMENTS.md, /Users/jon/projects/rendro/AGENTS.md] |
| V3 Session Management | no | Not applicable to pure layout semantics. [VERIFIED: .planning/REQUIREMENTS.md, /Users/jon/projects/rendro/AGENTS.md] |
| V4 Access Control | no | Not applicable to pure layout semantics. [VERIFIED: .planning/REQUIREMENTS.md, /Users/jon/projects/rendro/AGENTS.md] |
| V5 Input Validation | yes | Validate numeric widths, boolean break fields, and impossible keep layouts with typed failures. [VERIFIED: lib/rendro/block.ex, lib/rendro/error.ex] [ASSUMED] |
| V6 Cryptography | no | Not applicable to this phase; deterministic PDF IDs already exist outside this change. [VERIFIED: lib/rendro/pdf/writer.ex] |

### Known Threat Patterns for Elixir PDF layout semantics
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized text input causes excessive work or runaway page growth | Denial of Service | Keep existing `:max_pages`, `:max_bytes`, and `:timeout` policy guards in place while adding line-wrap tests against pathological long tokens. [VERIFIED: lib/rendro/pipeline.ex, README.md] |
| Invalid break directives or impossible keep chains crash the pipeline | Denial of Service | Return `%Rendro.Error{stage: :paginate, reason: :content_overflow}` with structured keep details instead of raising raw exceptions. [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md, lib/rendro/error.ex] |
| Mismatch between measured height and rendered lines causes content overlap | Tampering | Treat wrapped lines as measured data consumed by writer, and prove render output shape in tests. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pdf/writer.ex] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- [AGENTS.md](/Users/jon/projects/rendro/AGENTS.md) - project constraints, architectural boundaries, and stack summary.
- [.planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md](/Users/jon/projects/rendro/.planning/phases/19-deterministic-text-flow-and-break-semantics/19-CONTEXT.md) - locked user decisions and scope.
- [.planning/REQUIREMENTS.md](/Users/jon/projects/rendro/.planning/REQUIREMENTS.md) - LAY-06 and LAY-09 requirement text.
- [.planning/STATE.md](/Users/jon/projects/rendro/.planning/STATE.md) - current milestone history and Phase 18 carry-forward decisions.
- [.planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md) - truthful overflow precedent from the dependency phase.
- [lib/rendro/pipeline/measure.ex](/Users/jon/projects/rendro/lib/rendro/pipeline/measure.ex) - current single-line text measurement behavior.
- [lib/rendro/pipeline/paginate.ex](/Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex) - current flow pagination, page-fit checks, and overflow handling.
- [lib/rendro/pdf/writer.ex](/Users/jon/projects/rendro/lib/rendro/pdf/writer.ex) - current single-operation text serialization seam.
- [lib/rendro/pdf/font.ex](/Users/jon/projects/rendro/lib/rendro/pdf/font.ex) - deterministic Helvetica glyph-width metrics.
- [README.md](/Users/jon/projects/rendro/README.md) - current user-facing contract and docs posture.
- <https://hexdocs.pm/elixir/1.19.3/String.html> - grapheme handling, whitespace splitting, and string-performance caveats.
- <https://hexdocs.pm/elixir/1.19.3/Enum.html> - `Enum.chunk_while/4` and related stateful accumulation patterns.
- Verified commands run on 2026-04-29: `elixir --version`, `mix --version`, `mix deps`, `mix hex.info telemetry`, `mix hex.info phoenix`, `mix hex.info oban`, `mix hex.info stream_data`, `mix hex.info credo`, `mix hex.info dialyxir`, `mix hex.info ex_doc`, `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs`, `mix help docs.contract`, `mix run scripts/verify_docs.exs`.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - based on repo runtime, lockfile/deps output, and verified Hex package info.
- Architecture: HIGH - based on direct inspection of `Measure`, `Paginate`, `Writer`, and Phase 18 carry-forward behavior.
- Pitfalls: MEDIUM-HIGH - mostly direct codebase consequences, with a small number of explicit implementation recommendations captured in the assumptions log.

**Research date:** 2026-04-29
**Valid until:** 2026-05-29

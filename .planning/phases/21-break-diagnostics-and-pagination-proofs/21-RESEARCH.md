# Phase 21: Break Diagnostics and Pagination Proofs - Research

**Researched:** 2024-04-29
**Domain:** Elixir Layout Diagnostics and Deterministic Testing
**Confidence:** HIGH

## Summary

The Rendro pipeline currently raises fatal errors on layout overflow via `Rendro.Error`, but lacks visibility into non-fatal layout decisions (like where tables split across pages). Phase 21 resolves this by adopting a changeset-style pattern: adding a structured `diagnostics: []` list to `%Rendro.Document{}` to record layout shifts during the pipeline. Concurrently, it implements an ASCII layout tree renderer (`Rendro.Inspector`) to enable plain-text snapshot testing of the rendered layout in ExUnit, separating structural logic proofs from brittle PDF binary diffing.

**Primary recommendation:** Introduce a `diagnostics` accumulator to the pipeline stages, keeping `:telemetry` strictly for spans/performance tracking, and use ExUnit's native multiline string matchers for the new `Rendro.Inspector` ASCII tree tests to avoid external dependencies.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. Surfacing Structured Layout Diagnostics (OBS-05): Adopt the "Changeset" pattern. Add `diagnostics: []` to `%Rendro.Document{}` and keep telemetry strictly for performance.
2. Proving Pagination Invariants (QUAL-06): Implement an ASCII Layout Tree (Snapshot Testing) approach. Create `Rendro.Inspector` to serialize a paginated document into a human-readable ASCII tree, tested via ExUnit.

### the agent's Discretion
(None specifically listed)

### Deferred Ideas (OUT OF SCOPE)
(None specifically listed)
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Layout Event Tracking | API / Backend (Rendro Pipeline) | — | The pipeline makes structural layout decisions (Measure, Paginate); it should record these directly on the Document struct it transforms. |
| Diagnostic Structuring | API / Backend (Rendro Pipeline) | — | Diagnostics need to be actionable maps independent of UI/Output format. |
| Structural Verification | CI / Testing Layer (ExUnit) | — | Verifying layout invariants is a testing responsibility, verified via `Rendro.Inspector` snapshot tests rather than PDF byte comparisons. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / ExUnit | 1.19.5 | Core logic and testing | The framework native to the project. ExUnit multi-line string assertions provide sufficient snapshot-like functionality natively. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit string heredocs | Mneme | Mneme brings powerful auto-updating snapshot testing to ExUnit but requires adding a new development dependency. For simple ASCII tree snapshots, ExUnit's native multiline `assert` is robust enough without external weight. |

**Installation:**
No new packages required.

**Version verification:**
Verified Elixir 1.19.5 and Mix 1.19.5 via CLI.

## Architecture Patterns

### System Architecture Diagram
```text
  Input Document
        │
        ▼
 ┌───────────────┐
 │ Measure Stage │─────▶ [Appends Warning/Info to `doc.diagnostics`]
 └───────────────┘
        │
        ▼
 ┌───────────────┐
 │ Paginate Stage│─────▶ [Appends Split/Overflow to `doc.diagnostics`]
 └───────────────┘
        │
        ▼
  Render PDF  <or>  Rendro.Inspector (ASCII dump for tests)
```

### Pattern 1: Changeset-style Document Diagnostics
**What:** Use the document struct to accumulate layout decisions across pipeline stages.
**When to use:** Whenever a non-fatal structural decision (like splitting a table across pages) occurs.
**Example:**
```elixir
def handle_table_split(..., doc) do
  diagnostic = %{
    level: :info,
    type: :table_split,
    page: 2,
    reason: :insufficient_height
  }
  # Prepend for efficiency, Enum.reverse at end of pipeline if needed
  %{doc | diagnostics: [diagnostic | doc.diagnostics]}
end
```

### Pattern 2: ExUnit ASCII Snapshot Tests
**What:** Using `Rendro.Inspector` to serialize layout into text and assert it using ExUnit multiline strings.
**When to use:** To assert layout engine placement deterministically without relying on PDF byte generation.
**Example:**
```elixir
assert Rendro.Inspector.inspect(doc) == """
Page 1 (612x792)
├── Region: body (x: 36, y: 36, w: 540, h: 720)
│   ├── Block: Table (x: 36, y: 36, w: 540, h: 600)
"""
```

### Anti-Patterns to Avoid
- **Coupling diagnostics to telemetry:** The current `Rendro.Telemetry` module is built exclusively for span performance and generic stage failures. Pumping large layout state trees or fine-grained block split events into telemetry violates this intent and makes localized developer debugging harder.
- **Binary PDF diffing in tests:** PDF structures can change invisibly (fonts, metadata, ID hashes); testing layout logic by diffing PDFs is brittle.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tree Serialization | Custom string concatenation logic mapped randomly | A formal `Rendro.Inspector` | A dedicated module prevents polluting the core domain structs with text visualization logic. |
| Test Snapshots | Custom file writer assert macros | ExUnit multi-line string (`"""`) matchers | Keeps tests self-contained and avoids adding external libraries or file-I/O to standard unit tests. |

**Key insight:** Diagnostic metadata is pure state tracking and should remain functionally tied to the data pipeline. ExUnit natively handles large text assertions gracefully via terminal diffs.

## Runtime State Inventory

*Category: Code change and feature addition; no migrations of persistent state required.*

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Common Pitfalls

### Pitfall 1: Losing Tail-Recursive Diagnostics in Paginate
**What goes wrong:** The diagnostics list isn't carried forward properly during complex `Enum.reduce` or tail-recursive flow routines in `Rendro.Pipeline.Paginate.paginate_blocks`.
**Why it happens:** Currently, `paginate_blocks` returns only the `pages` list. If diagnostics are generated inside this recursive function, they cannot be appended to the top-level `doc` unless the accumulator signature is updated.
**How to avoid:** Refactor the return signatures of layout helpers from `pages` to `{pages, diagnostics}` and aggregate the diagnostics to the `doc` before exiting the stage.

### Pitfall 2: Test Fragility with Text Inspection Output
**What goes wrong:** Snapshot strings diff sporadically between test runs.
**Why it happens:** Inspecting maps in Elixir without sorting keys or logging randomly generated UUIDs.
**How to avoid:** Ensure `Rendro.Inspector` output enforces deterministic ordering and omits random/transient keys (like timestamps or IDs not explicitly set in the test fixture).

## Code Examples

Verified patterns for tree walking from the Elixir ecosystem:

### ASCII Tree Walker Pattern
```elixir
defmodule Rendro.Inspector do
  def inspect(%Rendro.Document{} = doc) do
    Enum.map_join(doc.pages, "\n", &inspect_page/1)
  end

  defp inspect_page(page) do
    "Page (#{page.width}x#{page.height})\n" <> walk_blocks(page.blocks, 1)
  end

  defp walk_blocks(blocks, depth) do
    indent = String.duplicate("│   ", depth - 1) <> "├── "
    Enum.map_join(blocks, "\n", fn b -> indent <> "Block: #{inspect_content(b.content)} (x: #{b.x}, y: #{b.y})" end)
  end

  defp inspect_content(%Rendro.Table{}), do: "Table"
  defp inspect_content(%Rendro.Text{}), do: "Text"
  defp inspect_content(_), do: "Unknown"
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Opaque Layout | Tracked Structs | Phase 21 | Operators can debug why content paginated unexpectedly without generating PDFs. |
| PDF Byte Tests | ASCII Tree Tests | Phase 21 | Test suite can prove pagination logic deterministically in PR reviews without binary blobs. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No snapshot library (Mneme) is required, ExUnit multi-line matches suffice. | Standard Stack | [ASSUMED] If developers strongly prefer auto-updating fixtures, they may need Mneme integrated later. |
| A2 | Pagination functions must refactor to return `{pages, diagnostics}` to thread state. | Pitfalls | [ASSUMED] If `paginate_blocks` doesn't return diagnostics, any mid-pagination split events will be lost. |

## Open Questions (RESOLVED)

1. **Diagnostic Formatting** [RESOLVED]
   - What we know: Diagnostics are structured maps appended to a list.
   - What's unclear: Should `Rendro.Inspector` also print out the `doc.diagnostics` list at the end of the text tree?
   - Recommendation: Yes, `Rendro.Inspector.inspect/1` should append a "Diagnostics" section at the bottom of the output so snapshot tests explicitly verify when warnings were triggered.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core Logic | ✓ | 1.19.5 | — |
| Mix | Tooling | ✓ | 1.19.5 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-05 | Document accumulates structural layout diagnostics | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |
| QUAL-06 | Inspector yields text tree and layout invariants are verified | unit | `mix test test/rendro/inspector_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/inspector_test.exs` — required to assert output of `Rendro.Inspector`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |

**Note:** Phase deals exclusively with isolated, deterministic, in-memory layout tracking, rendering it out-of-scope for standard ASVS boundary controls.

## Sources

### Primary (HIGH confidence)
- Rendro codebase (`lib/rendro/document.ex`, `lib/rendro/telemetry.ex`, `lib/rendro/error.ex`) - inspected struct formats and error strategies natively.
- Rendro codebase (`lib/rendro/pipeline/paginate.ex`) - confirmed `paginate_blocks` tail-recursion and need for `{pages, diagnostics}` tracking.

### Secondary (MEDIUM confidence)
- ExUnit core libraries - string literals (`"""`) native support.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ExUnit is built-in and fully capable of block string assertions.
- Architecture: HIGH - the Changeset pattern is deeply idiomatic in Elixir.
- Pitfalls: HIGH - Elixir's immutable data means recursive accumulators strictly dictate what can be tracked.

**Research date:** 2024-04-29
**Valid until:** 2024-10-29
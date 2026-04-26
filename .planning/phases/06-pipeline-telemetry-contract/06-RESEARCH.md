# Phase 6: Pipeline Telemetry Contract Fixes - Research

**Researched:** 2026-04-26
**Domain:** Elixir `:telemetry` contract + pipeline orchestration refactor
**Confidence:** HIGH

## Summary

Phase 6 closes BLOCKER-04 (missing `:validate` event), BLOCKER-05 (compose/measure inverted), and MINOR-15 (error-path metric loss). CONTEXT.md already locks twenty decisions (D-01 through D-20) drawn from four prior parallel research agents — this research therefore focuses on **implementation mechanics** (the exact `with` chain shape, helper signatures, refactor sequencing) rather than re-debating libraries or stage semantics.

The phase is unusually well-scoped because:

1. The `:telemetry.span/3` contract already accommodates everything D-11 through D-15 specify — the official telemetry source [explicitly calls out the optional `:error` key on `:stop` metadata](file:///Users/jon/projects/rendro/deps/telemetry/src/telemetry.erl#L309) as a first-class pattern. No library extension needed.
2. The existing `Rendro.Pipeline.span/4` helper is the right shape; only the stop_meta builder needs new clauses.
3. The refactor's risk is **not** in the telemetry layer — it's in the responsibility shuffle between `Compose`, `Measure`, and `Paginate`. Two of the three current stage tests pin shapes that survive the refactor unchanged; one test (`compose_test.exs`) gets thinner; one bug (page-2 y-stacking remainder) is fixed by construction.
4. No external consumers exist (no published Hex releases, Threadline adapter listens only to top-level `[:rendro, :render, :*]`), so the breaking change ships as a single-shot release per D-17.

**Primary recommendation:** Land the work in this order — (1) telemetry plumbing first (`@stage_names`, stop_meta schema, error-path metric preservation) so tests can assert against new shape; (2) `Validate` module + `with`-chain rewire; (3) Compose/Measure/Paginate responsibility shuffle last, validating each stage in isolation before combining. This sequence keeps the refactor's two independent risk surfaces (telemetry contract and layout responsibility) from compounding.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stage execution + halt-on-error | `Rendro.Pipeline.run_stages/3` (`with` chain) | — | Single orchestration point per CONTEXT D-01 |
| Telemetry span emission | `Rendro.Pipeline.span/4` helper | `:telemetry.span/3` underneath | Already wired; extend stop_meta builders only |
| Document tree assembly + cell normalization | `Rendro.Pipeline.Compose` | — | D-02: logical tree only, no metrics, no y-stacking |
| Width/height filling from font metrics | `Rendro.Pipeline.Measure` | `Rendro.PDF.Font` | D-03: pure metric pass over Compose's output |
| Y-stacking + flow split + page assignment | `Rendro.Pipeline.Paginate` | — | D-04: absorbs `current_y` cursor logic from Compose |
| `max_pages` policy guard | `Rendro.Pipeline.validate_policy(:pages, ...)` | — | D-10: non-spanned `with` step post-paginate, pre-render |
| PDF binary serialization | `Rendro.Pipeline.Render` | `Rendro.PDF.Writer` | Unchanged per D-05 |
| Post-render structural + page-count + max_bytes validation | `Rendro.Pipeline.Validate` (NEW) | — | D-06/D-07: trailing spanned stage |
| Structured error envelope | `Rendro.Error.from_stage/3` | — | Existing scaffold; D-09 adds 2 new `what`/`next` clauses |

**Tier sanity check:** All work stays inside `lib/rendro/pipeline/` and `lib/rendro/{telemetry,error}.ex`. No adapter, writer, or document-model changes. Threadline (top-level subscriber only) is verification-only territory.

## Standard Stack

### Core (already in tree)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | as resolved by `mix.exs` | Span emission, start/stop/exception lifecycle | `[VERIFIED: deps/telemetry/src/telemetry.erl in tree]` Industry-standard Elixir/Erlang telemetry; locked into Phoenix/Ecto/Oban ecosystem; no alternatives in scope per CONTEXT |

### Supporting (already in tree)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| `Rendro.PDF.Writer` | PDF binary output (unchanged) | Render stage `run/1` |
| `Rendro.Error` | Structured error envelopes | `from_stage/3` for new validate-stage reasons |
| `ExUnitProperties` (already used in `deterministic_test.exs`) | Property-based testing | Optional for stage-order invariants |

### Alternatives Considered (and locked out)
| Instead of | Could Use | Locked by |
|------------|-----------|-----------|
| Real `:validate` stage | Pure-passthrough span emitting hollow event | D-06 — would lie to operators |
| Single-shot release | Dual emission + version field + UPGRADING.md | D-17 — pre-1.0, no consumers |
| `:validate` enforces deterministic invariants | Add `/CreationDate`, `/ModDate`, `/ID` checks | D-08 — deferred to dedicated phase |
| `max_pages` in `:validate` body | Move all policies to one trailing stage | D-10 — wastes CPU; check at earliest meaningful point |

**Installation:** No new packages. CONTEXT.md confirms `:telemetry` is already wired.

## Architecture Patterns

### System Architecture Diagram

```
                Rendro.Pipeline.run/1
                        |
          (Task.async wraps; timeout policy)
                        |
                        v
        :telemetry.span([:rendro, :render], ...)
                        |
                        v
                  run_stages/3
                        |
        +---------------+---------------+
        |  with chain (halt on first {:error, _})
        |
        |  span(:build,    fn -> Build.run(doc) end)        --> {:ok, doc}
        |  span(:compose,  fn -> Compose.run(doc) end)      --> {:ok, doc}    [D-02 tree only]
        |  span(:measure,  fn -> Measure.run(doc) end)      --> {:ok, doc}    [D-03 metrics only]
        |  span(:paginate, fn -> Paginate.run(doc) end)     --> {:ok, doc}    [D-04 owns y-stacking]
        |  validate_policy(:pages, doc, policies)           --> :ok           [D-10 inline guard]
        |  span(:render,   fn -> Render.run(doc) end)       --> {:ok, pdf}
        |  span(:validate, fn -> Validate.run(pdf, doc) end)--> {:ok, pdf}    [D-06/D-07 NEW]
        |
        +-> {:ok, pdf} | {:error, %Rendro.Error{}}
                        |
                        v
         build_stop_meta/3 → top-level :stop event
```

Reader trace: A successful render fires 14 events (1 top-level start + 6 stage starts + 6 stage stops + 1 top-level stop). On error in stage N, only stages 1..N emit (start+stop with `status: :error`); top-level stop also fires with `status: :error` and best-available `page_count`/`byte_size`.

### Recommended Project Structure (additions only)

```
lib/rendro/pipeline/
├── build.ex          # unchanged
├── compose.ex        # SHRINK: remove y-stacking; gain normalize_row/1
├── measure.ex        # SHRINK: remove normalize_row; pure metric pass
├── paginate.ex       # GROW:   absorb current_y cursor from compose
├── render.ex         # unchanged
└── validate.ex       # NEW:    structural + page-count + max_bytes
test/rendro/pipeline/
├── ... (existing files)
└── validate_test.exs # NEW:    cover happy path + 3 error reasons
```

### Pattern 1: Stage Module with `run/1` returning `{:ok, doc} | {:error, atom | Error.t}`

All existing stages follow this. The new `Validate` is the **only** stage with arity 2 because it needs both the rendered binary and the doc:

```elixir
# Source: established convention in lib/rendro/pipeline/{build,compose,measure,paginate,render}.ex
defmodule Rendro.Pipeline.Validate do
  @spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, atom()}
  def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary) do
    with :ok <- check_structural(pdf_binary),
         :ok <- check_page_count(pdf_binary, doc),
         :ok <- check_max_bytes(pdf_binary, doc) do
      {:ok, pdf_binary}
    end
  end
end
```

The `with` chain returns the binary unchanged on success — the validate stage is identity-on-success, so the `with`-chain in `Pipeline.run_stages` doesn't have to thread two values forward. This is the key insight that keeps the orchestrator simple.

### Pattern 2: span/4 wrapper accepts arbitrary fun and last-known doc

Current signature in `pipeline.ex:93`:

```elixir
defp span(stage, base_meta, fun, doc)
```

`fun` is a no-arg closure returning `{:ok, result} | {:error, ...}`. `doc` is the last successful Document (for stop_meta page_count fallback). For the `:validate` stage, the closure becomes `fn -> Validate.run(pdf_binary, doc) end` — closing over `pdf_binary` is idiomatic and requires no helper-signature change. **No new helper needed.**

### Anti-Patterns to Avoid

- **Adding a `:validate` stop measurement separate from existing schema.** D-11 mandates a single stable schema across all `:stop` events; do not invent extra keys for the validate stage.
- **Moving `max_bytes` check outside the `:validate` span.** D-07.3 absorbs it; leaving the inline `validate_policy(:bytes, ...)` after `:render` would emit two ways to detect the same condition.
- **Short-circuiting the top-level `[:rendro, :render, :stop]` event when a stage fails.** Existing code already emits it correctly; preserve that with the new schema (D-16).
- **Passing the result of `Validate.run/2` (the binary) as the `doc` argument to subsequent helpers.** Validate is the terminal stage; its `:ok` value is just `pdf_binary` and flows directly to the function return.
- **Threading `error` into stop_meta when no error exists.** D-14: the `:error` key is **optional**, present only on `status: :error` stop events — matches official telemetry pattern.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lifecycle event emission | Custom `start_timestamp`/`emit_event` helpers | `:telemetry.span/3` (already used) | Span auto-handles duration, ref-based span context, exception kind/reason/stacktrace |
| Error metadata tagging on `:stop` | New event prefix like `[:rendro, :pipeline, :stage, :error]` | Optional `:error` key on existing `:stop` event per D-14 | Documented telemetry pattern (Keathley/official telemetry docs); APM tools key on `:stop` + filter on `meta.error` |
| Structural PDF parsing for page-count parity | Custom PDF object-graph walker | Regex on `/Type /Page` count or `/Count N` from existing Writer output | Writer emits well-known tokens (`test/rendro/pdf/writer_test.exs:54-128` already asserts these); full parser is out-of-scope per Out-of-Scope table |
| Tagged-tuple → exception conversion | Re-raise on `{:error, _}` to trigger `:exception` | Return `{:error, %Rendro.Error{}}` and emit `:stop` with `status: :error` per D-15 | Matches Oban convention; prevents APM double-counting; `:exception` reserved for true raises |

**Key insight:** Every problem this phase needs to solve already has an idiomatic solution in the existing scaffolding. The work is *connecting* existing pieces, not building new mechanisms.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — pipeline is stateless; no databases, no cached telemetry, no on-disk metric stores | None |
| Live service config | None — `:telemetry` handlers are attached at runtime only; tests use `Rendro.Test.TelemetryHelper` which attaches per-test and detaches in `on_exit/1` (`test/support/telemetry_helper.ex:20`) | None |
| OS-registered state | None — no OS daemons, no scheduler entries | None |
| Secrets/env vars | None — no env vars touched | None |
| Build artifacts | `_build/` carries compiled `.beam` files for `Rendro.Pipeline`, `Rendro.Telemetry`, and the five stage modules. Standard `mix compile` rebuild after source change handles this. **NO** stale `.beam` risk because no module is renamed; only added (`Rendro.Pipeline.Validate`) and refactored in place | `mix compile` after edits — no manual cleanup |

**Externally subscribed events:** Threadline adapter (`lib/rendro/adapters/threadline.ex:44-47`) subscribes to `[:rendro, :render, :stop]` and `[:rendro, :render, :exception]` — top-level only. **Adding a new stage event prefix `[:rendro, :pipeline, :validate, :*]` does not affect Threadline at all** — confirmed by reading the adapter source. D-20 lists this; verify with the adapter test suite after change.

**Test handlers attached at compile time:** `Rendro.Test.TelemetryHelper.attach/1` reads `Rendro.Telemetry.all_event_names/0` dynamically (`test/support/telemetry_helper.ex:5`). After `:validate` is added to `@stage_names`, helper picks up new event names automatically — no test-helper edits required.

## Common Pitfalls

### Pitfall 1: Refactoring all three stages (Compose/Measure/Paginate) before any test runs
**What goes wrong:** D-02/D-03/D-04 shuffle responsibilities across three modules simultaneously. If the telemetry tests are also being rewritten in the same diff, a single test failure can't tell you which refactor broke things.
**Why it happens:** Eagerness to "land it in one commit"; logical coupling between the three modules.
**How to avoid:** Sequence the work — (a) `:validate` event + stop_meta schema + error-path metric preservation first (telemetry-only), with telemetry tests rewritten and green; (b) move `normalize_row/1` from Measure to Compose, run `compose_test.exs` + `measure_test.exs` to confirm both still pass; (c) move y-stacking from Compose to Paginate, run `compose_test.exs` + `paginate_test.exs` + flow tests; (d) reorder `with` chain in `pipeline.ex` to spec order, run `telemetry_test.exs` + integration suite.
**Warning signs:** Test failures in `flow_test.exs` after step (c) — that test exercises the page-2 remainder bug fix.

### Pitfall 2: Treating `:validate` as a `Document`-returning stage
**What goes wrong:** Following the existing `{:ok, doc}` convention for the new stage forces an awkward `with` chain that has to track both the binary and the doc separately, or has to wrap them in a tuple.
**Why it happens:** Pattern-matching on existing stage signatures.
**How to avoid:** `Validate.run/2` returns `{:ok, pdf_binary}` (identity-on-success). Pipeline `with` chain stays single-threaded:
```elixir
with {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
     {:ok, pdf_binary} <- span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc) do
  {:ok, pdf_binary}
end
```
Note both `with`-clauses bind `pdf_binary` (Elixir rebinding); `doc` stays in scope from before.
**Warning signs:** Trying to invent a new tuple shape like `{:ok, {pdf_binary, doc}}`.

### Pitfall 3: Forgetting that `validate_policy(:pages, ...)` must move
**What goes wrong:** The current `with` chain at `pipeline.ex:65` runs `validate_policy(:pages, ...)` after the (incorrectly ordered) `paginate`. After reorder, paginate stays followed by `:pages` validation — but the temptation is to delete it (since `:validate` does max_bytes now). **Don't.** D-10 explicitly keeps `:pages` as a non-spanned inline guard between paginate and render.
**Why it happens:** Conflating max_pages and max_bytes — both are policies, but their meaningful checkpoints differ.
**How to avoid:** Trace each policy through CONTEXT.md:
- `:max_pages` → checked **after paginate, before render** (page count is final after paginate; no point rendering)
- `:max_bytes` → moves into `:validate` stage body (output size only knowable post-render)
- `:timeout` → existing `Task.yield` / `Task.shutdown` machinery in `Pipeline.run/1` — unchanged
**Warning signs:** `policy_test.exs` (3 tests, lines 4-31) fails with wrong error reason or wrong stage attribution.

### Pitfall 4: Stop_meta becomes inconsistent across success and error stop events
**What goes wrong:** Current `pipeline.ex:106` and `:111` build stop_meta inline as `%{render_id: ..., status: :error, page_count: 0, byte_size: 0}` — three separate places that would each need the new `:error` key (D-14) and the new fallback semantics (D-12: `length(doc.pages)` not 0).
**Why it happens:** Local optimization at each call site instead of a unified builder.
**How to avoid:** Refactor `stage_stop_meta/3` into a single function that handles both success and error paths and applies D-11 schema uniformly. Suggested signature:
```elixir
defp stage_stop_meta(stage, result, doc, base_meta)
# returns: %{render_id, document_type, deterministic, stage, status, page_count, byte_size [, error]}
```
All three current call sites collapse into one helper. Same pattern for `build_stop_meta/3` (top-level, per D-16).
**Warning signs:** Different stop events in the same render carrying different key sets.

### Pitfall 5: Page-count regex matches `/Pages` (the catalog ref) not `/Type /Page` (the page object)
**What goes wrong:** Quick implementation of `check_page_count/2` greps for `/Page` and over-counts.
**Why it happens:** PDF tokens look similar — `/Type /Catalog` references `/Pages 2 0 R`, the `/Pages` object has `/Count N` and `/Kids [...]`, and each individual page is `/Type /Page`.
**How to avoid:** Match exactly `/Type /Page\n` or `/Type /Page ` (with trailing whitespace), or — more robustly — extract `/Count N` from the `/Type /Pages` block and parse the integer. The Writer output is regular enough (`test/rendro/pdf/writer_test.exs` confirms `/Count 1`, `/Count 2` for 1- and 2-page docs) that a `Regex.run(~r{/Count (\d+)}, pdf)` works for v1.0.
**Warning signs:** `validate_test.exs` page-count test fails on a document with `/Type /Pages` but no `/Type /Page` blocks (zero-page edge case).

### Pitfall 6: Threadline test passes "by accident" because it uses `Mocks.threadline_calls()` order-sensitively
**What goes wrong:** Test `test/rendro/adapters/threadline_test.exs:50` does `[{action, metadata} | _] = Mocks.threadline_calls()` — pattern-matches the **first** call. After the stage reorder, top-level stop is still the only event Threadline subscribes to, so the call count is unchanged. **But** if the planner accidentally adds Threadline subscription to a stage event, the test starts pulling whichever call landed first.
**Why it happens:** D-20 says "no recipe edits expected" — the temptation is to skip the verification step.
**How to avoid:** Run `mix test test/rendro/adapters/threadline_test.exs` before opening the PR, even if the planner believes nothing changed. The audit calls `mix test test/rendro/adapters/threadline_test.exs` an explicit success criterion (CONTEXT D-20).
**Warning signs:** `Mocks.threadline_calls()` returns more entries than before.

## Code Examples

### `Validate.run/2` — concrete shape per D-06/D-07/D-09

```elixir
# Source: synthesizing CONTEXT D-07 with existing pipeline conventions
defmodule Rendro.Pipeline.Validate do
  @moduledoc """
  Trailing post-render checks: PDF structural sanity, page-count parity,
  and max_bytes policy enforcement.
  """

  @pdf_header "%PDF-"
  @pdf_trailer "%%EOF"

  @spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, atom()}
  def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary) do
    with :ok <- check_structural(pdf_binary),
         :ok <- check_page_count(pdf_binary, doc),
         :ok <- check_max_bytes(pdf_binary, doc) do
      {:ok, pdf_binary}
    end
  end

  defp check_structural(pdf_binary) do
    cond do
      not String.starts_with?(pdf_binary, @pdf_header) -> {:error, :structural_corruption}
      not String.contains?(pdf_binary, @pdf_trailer) -> {:error, :structural_corruption}
      true -> :ok
    end
  end

  defp check_page_count(pdf_binary, %Rendro.Document{pages: pages}) do
    expected = length(pages)
    actual = parse_page_count(pdf_binary)
    if actual == expected, do: :ok, else: {:error, :page_count_mismatch}
  end

  defp parse_page_count(pdf_binary) do
    case Regex.run(~r{/Type\s+/Pages.*?/Count\s+(\d+)}s, pdf_binary, capture: :all_but_first) do
      [n] -> String.to_integer(n)
      _ -> 0
    end
  end

  defp check_max_bytes(pdf_binary, %Rendro.Document{options: options}) do
    policies = Map.get(options, :policies, [])
    max_bytes = Keyword.get(policies, :max_bytes)
    cond do
      is_nil(max_bytes) -> :ok
      byte_size(pdf_binary) > max_bytes -> {:error, :max_bytes_exceeded}
      true -> :ok
    end
  end
end
```

### Refactored `Rendro.Pipeline.run_stages/3` — exact `with` shape

```elixir
# Source: synthesizing CONTEXT D-01, D-10 with existing pipeline.ex:61-71
defp run_stages(doc, base_meta, policies) do
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}

  with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
       {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
       {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
       {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
       :ok <- validate_policy(:pages, doc, policies, base_meta),
       {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
       {:ok, pdf_binary} <- span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc) do
    {:ok, pdf_binary}
  end
end
```

Differences from current code at `pipeline.ex:61-71`:
1. Compose moves from line 66 (after `validate_policy(:pages)`) to line 2 of the `with` (between build and measure).
2. The trailing inline `validate_policy(:bytes, ...)` (line 68) is **removed** — absorbed into Validate per D-07.3.
3. New trailing `span(:validate, ...)` step.
4. `validate_policy(:pages, ...)` keeps its position between paginate and render per D-10.

### Unified stop_meta builder — D-11 / D-12 / D-13 / D-14 schema

```elixir
# Source: synthesizing CONTEXT D-11..D-15 with current pipeline.ex:96-127
defp span(stage, base_meta, fun, last_doc) do
  start_meta = Map.put(base_meta, :stage, stage)

  :telemetry.span([:rendro, :pipeline, stage], start_meta, fn ->
    case fun.() do
      {:ok, result} ->
        {{:ok, result}, stage_stop_meta(stage, :ok, result, last_doc, base_meta)}

      {:error, %Rendro.Error{} = error} ->
        {{:error, error}, stage_stop_meta(stage, {:error, error}, nil, last_doc, base_meta)}

      {:error, reason} ->
        error = Rendro.Error.from_stage(stage, reason, base_meta)
        {{:error, error}, stage_stop_meta(stage, {:error, error}, nil, last_doc, base_meta)}
    end
  end)
end

defp stage_stop_meta(stage, status_or_error, result, last_doc, base_meta) do
  page_count = derive_page_count(result, last_doc)
  byte_size = derive_byte_size(stage, result)

  base = %{
    render_id: base_meta.render_id,
    document_type: base_meta.document_type,
    deterministic: base_meta.deterministic,
    stage: stage,
    status: if(status_or_error == :ok, do: :ok, else: :error),
    page_count: page_count,
    byte_size: byte_size
  }

  case status_or_error do
    :ok -> base
    {:error, %Rendro.Error{} = e} -> Map.put(base, :error, %{kind: e.reason, stage: e.stage})
  end
end

# D-12: prefer result.pages, fall back to last_doc.pages
defp derive_page_count(%Rendro.Document{pages: pages}, _last), do: length(pages)
defp derive_page_count(_result, %Rendro.Document{pages: pages}), do: length(pages)
defp derive_page_count(_result, _last), do: 0

# D-13: real byte_size only on render success
defp derive_byte_size(:render, pdf) when is_binary(pdf), do: byte_size(pdf)
defp derive_byte_size(:validate, pdf) when is_binary(pdf), do: byte_size(pdf)
defp derive_byte_size(_stage, _result), do: 0
```

Note: `:validate` stage stop_meta also reports real `byte_size` because the binary is in scope and useful to operators. CONTEXT D-13 is silent on `:validate` specifically; D-13 says "real only when stage == :render" but the spirit is "real when a binary is in scope." Recommendation: include byte_size for `:validate` too. **[ASSUMED]** — flag for planner to confirm or override.

### `build_stop_meta/3` — top-level event mirrors stage schema (D-16)

```elixir
# Source: synthesizing CONTEXT D-16 with current pipeline.ex:46-59
defp build_stop_meta(result, doc, base_meta) do
  case result do
    {:ok, pdf_binary} ->
      %{
        render_id: base_meta.render_id,
        document_type: base_meta.document_type,
        deterministic: base_meta.deterministic,
        stage: :render,
        status: :ok,
        page_count: length(doc.pages),
        byte_size: byte_size(pdf_binary)
      }

    {:error, %Rendro.Error{} = error} ->
      %{
        render_id: base_meta.render_id,
        document_type: base_meta.document_type,
        deterministic: base_meta.deterministic,
        stage: error.stage,
        status: :error,
        page_count: length(doc.pages),
        byte_size: 0,
        error: %{kind: error.reason, stage: error.stage}
      }
  end
end
```

Key change: error path no longer zeroes `page_count` (D-12: `length(doc.pages)` is the input doc's page count, available even on `:build` failure where it would be 0 anyway).

### `Rendro.Error` additions — D-09

```elixir
# Source: synthesizing CONTEXT D-09 with current lib/rendro/error.ex
defp what(:validate, _reason),
  do: "Post-render validation failed."

defp next_step(:validate, :structural_corruption) do
  "PDF header/trailer missing — internal renderer bug, please report with the input document and render_id."
end

defp next_step(:validate, :page_count_mismatch) do
  "Rendered page count diverged from document page count — pipeline bug, please report with the input document and render_id."
end

defp next_step(:validate, :max_bytes_exceeded) do
  "Reduce content complexity or increase the :max_bytes policy limit."
end
```

The existing `next_step(:render, :max_bytes_exceeded)` clause (`error.ex:73`) can stay as a fallback or be removed — `from_stage/3` is now called with `stage: :validate` for that reason. Recommend keeping it as defensive code; small surface area.

## State of the Art

| Old Approach (current code) | Current Approach (post-Phase-6) | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stage order `build → measure → paginate → compose → render` | `build → compose → measure → paginate → render → validate` | Phase 6 | Closes BLOCKER-04, BLOCKER-05; matches OBS-01 spec; matches CSS/WeasyPrint/TeX/Typst/ReportLab/react-pdf-Yoga industry pattern |
| Error-path `page_count: 0, byte_size: 0` regardless of doc state | Preserve `length(doc.pages)` from last known doc | Phase 6 | Closes MINOR-15; restores OBS-02 metric correlation on failed renders |
| `:validate` stage absent | Real trailing stage with structural + page-count + max_bytes checks | Phase 6 | Closes BLOCKER-04 |
| Inline `validate_policy(:bytes, ...)` after `:render` | Absorbed into `:validate` stage body | Phase 6 | One canonical max_bytes checkpoint; same telemetry as other validate failures |
| Compose performs y-stacking via reduce with `current_y` | Paginate owns y-stacking; Compose is logical-tree only | Phase 6 | Fixes latent page-2 remainder y-inheritance bug by construction |
| Measure performs row normalization (`normalize_row/1`) | Compose performs row normalization | Phase 6 | Measure becomes pure metric pass; matches "assemble tree → measure → place" idiom |

**Deprecated/outdated:** None — this is internal contract churn pre-1.0; nothing existed publicly.

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist in the repo root (verified via `ls`). No project-specific directives apply beyond what `.planning/PROJECT.md` already states:
- **Architecture:** Core stays decoupled from Phoenix/jobs/admin tooling. → All Phase 6 changes are core-only; no adapter changes; preserved.
- **Tech stack:** Pure Elixir, no browser runtime in core. → Preserved; no new deps.
- **Quality:** `mix ci` lane (format, warnings-as-errors compile, tests, docs, package build) must stay green. → All changes go through existing test infrastructure; new module gets new test file.
- **Honesty:** Compliance/signature claims need validator-backed proof. → Not relevant to Phase 6 (telemetry-only; no compliance claims).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:validate` stage stop_meta should include real `byte_size` (since the rendered binary is in scope), not just on `:render` | Code Examples → unified stop_meta builder, comment on `derive_byte_size/2` | Operators on `[:rendro, :pipeline, :validate, :stop]` see `byte_size: 0` and have to subscribe to `:render` separately. Easy planner override (one clause). CONTEXT D-13 is silent on `:validate` specifically. |
| A2 | The `error: %{kind, stage}` map in stop_meta uses `kind: error.reason` (the atom like `:no_pages`) and `stage: error.stage` | Code Examples → `stage_stop_meta/5` | Telemetry handlers might expect `kind: error.what` (the human string) or different field names. CONTEXT D-14 spec is `kind: error.kind, stage: error.stage` but `%Rendro.Error{}` has no `:kind` field — only `:reason`. Mapping `kind → reason` is the most plausible interpretation. Planner should confirm or rename. |
| A3 | Page-count parsing via `~r{/Type\s+/Pages.*?/Count\s+(\d+)}s` is sufficient for v1.0 | Code Examples → `Validate.parse_page_count/1` | Writer might emit `/Count` inside another object dict that matches first. Mitigation: scope regex to the `/Type /Pages` object specifically, and add tests for 0/1/2/N-page docs to lock the behavior. |
| A4 | `defp next_step(:render, :max_bytes_exceeded)` in `error.ex:73` should remain as defensive code even after the check moves to `:validate` | Code Examples → `Rendro.Error` additions | Could be removed; small file size impact either way. Planner's call. |

**If this table is empty:** All claims would be verified — they aren't. The four assumptions above warrant a quick planner sanity check before execution.

## Open Questions

1. **Should `:validate` propagate the rendered PDF binary into the top-level `[:rendro, :render, :stop]` event's `byte_size`, or should the top-level use the binary as-of-`:render`?**
   - What we know: D-16 says top-level mirrors stage schema. The binary is unchanged by `:validate` (identity-on-success).
   - What's unclear: If `:validate` were ever to mutate the binary (it doesn't, in v1.0), top-level should report the post-validate size.
   - Recommendation: Top-level reports `byte_size(pdf_binary)` from the final return value — same byte size whether `:validate` mutates or not. No spec change needed.

2. **What is the spec for `:validate` failure on a 0-page document?**
   - What we know: `Build.run/1` already rejects empty `pages: []` with `:no_pages` (`build.ex:16`), so `:validate` never sees a 0-page doc in practice.
   - What's unclear: If `Build` is ever relaxed (e.g., flow API with empty content), `:validate` parser must handle `expected = 0`.
   - Recommendation: Add a test for the edge case but expect it never to fire in v1.0. Defensive and free.

3. **Does the new `[:rendro, :pipeline, :validate, :exception]` event need a Threadline subscription?**
   - What we know: Threadline subscribes only to top-level `[:rendro, :render, :*]`.
   - What's unclear: D-20 says no adapter edits expected — so no.
   - Recommendation: Confirmed — no Threadline subscription for `:validate` exception. If `Validate` raises, top-level `[:rendro, :render, :exception]` still fires (via `:telemetry.span/3` propagation through `execute_with_telemetry/3`), and Threadline picks it up there.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile + test | ✓ (project standing) | as `mix.exs` declares | — |
| `:telemetry` | Span emission | ✓ (in `deps/`) | as resolved | — |
| `:ex_unit` | Tests | ✓ (built-in) | — | — |
| `:stream_data` (ExUnitProperties) | Optional property tests | ✓ (in `deps/`, used by `deterministic_test.exs`) | as resolved | Skip property tests; keep example-based tests |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

All work is inside the existing toolchain. No external services, no installations.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) + ExUnitProperties for properties |
| Config file | `mix.exs` — `test/test_helper.exs` is implicit; no separate config |
| Quick run command | `mix test test/rendro/telemetry_test.exs test/rendro/pipeline/` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-01 | Pipeline emits `[:rendro, :pipeline, :validate, :start]` and `[:rendro, :pipeline, :validate, :stop]` on every successful render | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 — new tests in existing file |
| OBS-01 | `[:rendro, :pipeline, :validate, :exception]` fires when `Validate.run/2` raises | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| OBS-01 | Stage start order is exactly `[:build, :compose, :measure, :paginate, :render, :validate]` | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:319` (rewrite) | ✅ exists, rewrite per D-19 |
| OBS-01 | `Rendro.Telemetry.stage_names/0` returns `[:build, :compose, :measure, :paginate, :render, :validate]` | unit | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| OBS-01 | `Rendro.Telemetry.all_event_names/0` includes `[:rendro, :pipeline, :validate, :start | :stop | :exception]` | unit | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| OBS-02 | Error-path stop_meta carries `page_count: length(doc.pages)`, not `0`, when doc has pages | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` (regression test for MINOR-15) | ❌ Wave 0 |
| OBS-02 | Top-level `[:rendro, :render, :stop]` on error path carries `page_count` from last known doc state | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| OBS-02 | `:render` stage stop_meta has real `byte_size > 0` on success | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:153-160` | ✅ exists, passes unchanged |
| OBS-02 | All stop events carry the unified D-11 schema (`render_id`, `document_type`, `deterministic`, `stage`, `status`, `page_count`, `byte_size`) | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:129-140` (extend) | ✅ exists, extend assertions |
| OBS-02 | Error-path stop event includes optional `:error` key with `%{kind, stage}` | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| CORE-01 | `Rendro.Pipeline.run/1` returns `{:ok, binary}` for valid document with all 6 stages executing | integration | `mix test test/rendro/pipeline_test.exs` | ✅ exists, no rewrite |
| CORE-01 | `Rendro.Pipeline.Validate.run/2` returns `{:ok, pdf}` on valid PDF + matching page count + within max_bytes | unit (stage) | `mix test test/rendro/pipeline/validate_test.exs:NEW` | ❌ Wave 0 — new file |
| CORE-01 | `Validate.run/2` returns `{:error, :structural_corruption}` when binary lacks `%PDF-` header or `%%EOF` trailer | unit (stage) | `mix test test/rendro/pipeline/validate_test.exs:NEW` | ❌ Wave 0 |
| CORE-01 | `Validate.run/2` returns `{:error, :page_count_mismatch}` when PDF page count != `length(doc.pages)` | unit (stage) | `mix test test/rendro/pipeline/validate_test.exs:NEW` | ❌ Wave 0 |
| CORE-01 | `Validate.run/2` returns `{:error, :max_bytes_exceeded}` when byte_size > policy | unit (stage) | `mix test test/rendro/pipeline/validate_test.exs:NEW` | ❌ Wave 0 |
| CORE-01 | `max_pages` policy fails between `:paginate` and `:render` (not after `:validate`) | unit (telemetry+policy) | `mix test test/rendro/policy_test.exs` + `mix test test/rendro/telemetry_test.exs:NEW` | ✅ partial; extend telemetry test for stage-emission ordering |
| CORE-01 | `max_pages_exceeded` error emits stop event from `:paginate` stage but `:render`/`:validate` don't start | unit (telemetry) | `mix test test/rendro/telemetry_test.exs:NEW` | ❌ Wave 0 |
| CORE-01 | After Compose refactor, `Compose.run/1` returns doc with row-normalized cells but `nil` widths/heights for nil-input blocks | unit (stage) | `mix test test/rendro/pipeline/compose_test.exs` (extend) | ✅ exists, extend |
| CORE-01 | After Measure refactor, `Measure.run/1` is idempotent and only fills `nil` widths/heights | unit (stage) | `mix test test/rendro/pipeline/measure_test.exs` + property test | ✅ exists, optionally add property |
| CORE-01 | After Paginate refactor, page-2 remainder rows have y-coordinates relative to page 2 (not page 1) | unit (stage) | `mix test test/rendro/pipeline/paginate_test.exs:NEW` | ❌ Wave 0 — regression test for D-04 latent bug |
| CORE-01 | Threadline adapter test passes unchanged (verification of D-20) | integration | `mix test test/rendro/adapters/threadline_test.exs` | ✅ exists, must pass unchanged |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/telemetry_test.exs test/rendro/pipeline/` — covers the telemetry contract + every stage in isolation. Runs in single-digit seconds.
- **Per wave merge:** `mix test` — full suite (~191 tests + new). Catches regressions in adapters, deterministic mode, integration tests, policy tests.
- **Phase gate:** Full suite green (`mix test` exit 0) + Threadline test specifically green (D-20 success criterion) before `/gsd-verify-work`.

**Telemetry event sampling strategy:** Tests use `Rendro.Test.TelemetryHelper.attach/1` to subscribe to **all** event names dynamically. Because `attach/1` reads `Rendro.Telemetry.all_event_names/0` at attach time, adding `:validate` to `@stage_names` automatically expands subscription with no helper edit. Each test uses `Process.send/2`-based collection with a 100ms deadline (`telemetry_helper.ex:24`). Event ordering is verified via `Enum.find_index/2` on the collected list, which preserves emission order in the test process's mailbox.

**Property-based guard against re-introduction of wrong stage order:** Add a property test that asserts, for any valid document generator, the emitted stage start order is exactly `[:build, :compose, :measure, :paginate, :render, :validate]`. This pins the OBS-01 contract regardless of which document shape regresses it. Use the existing `Rendro.Test.Generators` (referenced in `deterministic_test.exs:5`) as the document source.

```elixir
# Suggested property test (sketch — planner refines)
property "stage start order matches OBS-01 spec for any document" do
  check all(doc <- document_gen(), max_runs: 50) do
    handler_id = TelemetryHelper.attach()
    {:ok, _pdf} = Rendro.Pipeline.run(doc)
    events = TelemetryHelper.collect_events()
    TelemetryHelper.detach(handler_id)

    stage_starts =
      events
      |> Enum.filter(fn {event, _, _} -> match?([:rendro, :pipeline, _, :start], event) end)
      |> Enum.map(fn {[:rendro, :pipeline, stage, :start], _, _} -> stage end)

    assert stage_starts == [:build, :compose, :measure, :paginate, :render, :validate]
  end
end
```

### Wave 0 Gaps

- [ ] `test/rendro/pipeline/validate_test.exs` — covers CORE-01 validate-stage behaviors (4 tests minimum: happy path, `:structural_corruption`, `:page_count_mismatch`, `:max_bytes_exceeded`)
- [ ] New tests in `test/rendro/telemetry_test.exs` — D-19 specifies ~15 lines across 3 tests + 2 new tests; suggested test names:
  - `"stage start order matches OBS-01 spec [:build, :compose, :measure, :paginate, :render, :validate]"` (rewrite of line 319)
  - `":validate stop event fires after :render stop"`
  - `"max_pages_exceeded fires from :paginate stage with :validate not started"`
  - `"error-path stop_meta carries page_count from doc.pages, not 0"` (regression for MINOR-15)
  - `"error-path stop_meta includes :error map with kind and stage"` (D-14)
  - `"all stop events carry full D-11 schema (render_id, document_type, deterministic, stage, status, page_count, byte_size)"`
  - `"Rendro.Telemetry.stage_names/0 includes :validate in spec order"`
- [ ] New regression test in `test/rendro/pipeline/paginate_test.exs` — verifies page-2 remainder row y-coordinates are page-2-relative (D-04 latent bug fix)
- [ ] Optional: property test in new or existing file — pins stage order across `Rendro.Test.Generators.document_gen/0` shapes
- [ ] Test framework install: none required (ExUnit + ExUnitProperties already in tree)

### Guards Against Regression

| Guard | Mechanism | What It Catches |
|-------|-----------|------------------|
| Stage-order property test | ExUnitProperties + `Rendro.Test.Generators.document_gen/0` | Any code change that re-inverts compose/measure or drops `:validate` |
| `Rendro.Telemetry.stage_names/0` snapshot test | Direct equality assertion on the constant | Anyone who edits `@stage_names` in `telemetry.ex` without updating tests |
| `all_event_names/0` count test | Assert `length(all_event_names()) == 6 stages * 3 suffixes + 3 top-level = 21` | Accidental drop or duplicate of stage event |
| Schema completeness assertion | Extend `test/rendro/telemetry_test.exs:129-140` to assert each of the 7 D-11 keys is present on every stop event | Any future stop_meta change that drops a key |
| Threadline adapter test (unchanged) | `mix test test/rendro/adapters/threadline_test.exs` | Inadvertent change to top-level event payload structure |
| `policy_test.exs` (unchanged) | Existing 3 tests for max_pages/max_bytes/timeout | Policy-stage attribution drift (e.g., `max_bytes` accidentally attributed to `:render` instead of `:validate`) — note: this test currently asserts `reason: :max_bytes_exceeded` only; planner may want to extend to assert `stage: :validate` post-refactor |

## Sources

### Primary (HIGH confidence)
- `lib/rendro/pipeline.ex` (read in full) — current orchestrator; lines 17-37 (run/1 + Task wrap), 39-44 (top-level span), 46-59 (build_stop_meta), 61-71 (run_stages — wrong order), 73-91 (validate_policy), 93-127 (span helper + stage_stop_meta).
- `lib/rendro/telemetry.ex:26` — `@stage_names` constant.
- `lib/rendro/pipeline/{build,compose,measure,paginate,render}.ex` — all stage modules.
- `lib/rendro/error.ex` — `Rendro.Error.from_stage/3` and `what`/`why`/`next_step` clauses.
- `test/rendro/telemetry_test.exs` — 363-line test file; line 319 locks wrong order; lines 129-140 lock current schema; lines 235-277 cover error path.
- `test/rendro/pipeline/{compose,measure,paginate,render,build}_test.exs` — per-stage tests.
- `test/rendro/adapters/threadline_test.exs` — verification that adapter is unaffected.
- `test/rendro/policy_test.exs` — 3 policy tests (max_pages, max_bytes, timeout).
- `test/support/telemetry_helper.ex` — dynamic event subscription via `all_event_names/0`.
- `deps/telemetry/src/telemetry.erl:230-360` — official `:telemetry.span/3` documentation, including the `error` key on stop metadata as a documented optional pattern.
- `.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md` — locked decisions D-01 through D-20.
- `.planning/v1.0-MILESTONE-AUDIT.md` — BLOCKER-04, BLOCKER-05, MINOR-15 verbatim.
- `.planning/REQUIREMENTS.md` — OBS-01, OBS-02, CORE-01.
- `.planning/ROADMAP.md` § Phase 6 — success criteria.

### Secondary (MEDIUM confidence)
- `lib/rendro/pdf/writer.ex:12` — confirms `%PDF-1.4\n%\xE2\xE3\xCF\xD3\n` header literal.
- `lib/rendro/pdf/writer.ex:292` — confirms `%%EOF\n` trailer literal.
- `test/rendro/pdf/writer_test.exs:54-128` — confirms `/Type /Pages` + `/Count N` regex pattern is reliable for v1.0 page-count parsing.

### Tertiary (LOW confidence — none)
- All claims in this research are verified against the in-tree source or the locked CONTEXT.md.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `:telemetry` already wired; no new packages.
- Architecture: HIGH — CONTEXT D-01..D-20 lock the shape; verified against existing source.
- Pitfalls: HIGH — derived from reading current code's exact failure modes (3 inline stop_meta sites; the y-stacking responsibility tangle; the `validate_policy` placement subtlety).
- Validation Architecture: HIGH — every test file referenced exists in tree and was read.
- Assumptions: 4 explicit `[ASSUMED]` claims flagged in Assumptions Log; planner should confirm A1 (validate byte_size) and A2 (`error: %{kind: error.reason}` field mapping) before execution.

**Research date:** 2026-04-26
**Valid until:** 2026-05-26 (30 days — stable internal contract; no upstream library churn risk)

---
phase: 06-pipeline-telemetry-contract
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - CHANGELOG.md
  - lib/rendro/error.ex
  - lib/rendro/pipeline.ex
  - lib/rendro/pipeline/compose.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/pipeline/paginate.ex
  - lib/rendro/pipeline/validate.ex
  - lib/rendro/telemetry.ex
  - test/rendro/error_test.exs
  - test/rendro/pipeline/paginate_test.exs
  - test/rendro/pipeline/validate_test.exs
  - test/rendro/telemetry_test.exs
findings:
  critical: 5
  warning: 8
  info: 5
  total: 18
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The Phase 6 implementation reorders pipeline stages to match the documented architecture, introduces `Rendro.Pipeline.Validate`, and adds a unified stop-event metadata schema across success and error paths. The bulk of the implementation is sound, but several BLOCKER-class defects exist around the new orchestration:

- The `Pipeline.run/1` timeout path (added/preserved from earlier work) breaks the telemetry-span contract — on timeout, the top-level `[:rendro, :render, :start]` event has been emitted from inside the killed task, but neither `:stop` nor `:exception` will follow. Consumers (Threadline, dashboards) see an unmatched start.
- The `:max_pages` policy guard runs *between* the `:paginate` span (which already emitted `:stop` with `status: :ok`) and the `:render` span. The resulting telemetry stream is internally inconsistent — the `:paginate` stop says success, then the top-level stop says the render failed at `:paginate`.
- Top-level error-path `page_count` reads from the *original* input doc's `pages` (which is `[]` for any flow-API document) rather than the latest known doc state — directly contradicting the CHANGELOG promise that "Error-path `page_count` is now derived from the latest known doc state rather than hardcoded to `0`."
- `Pipeline.run/1` blindly destructures `Task.yield/Task.shutdown` and will raise `MatchError` on the documented `{:exit, reason}` shutdown variant.
- Header/footer block heights are never reserved in `Paginate.paginate_flow/1` — the `&(&1.height || 0)` reads always return `0` because Measure does not walk `doc.header`/`doc.footer`. The flow API will systematically over-pack pages by exactly the height of header+footer.

Several WARNING-class issues compound the picture: a regex in `Validate.parse_page_count/1` has weak object-boundary anchoring; `Measure.measure_block/2` skips inner-cell measurement for any user-sized table; `Error.next_step(:render, :max_bytes_exceeded)` is now dead code per the CHANGELOG re-attribution; `paginate_flow/1` ignores the document's first page dimensions when constructing its template.

## Critical Issues

### CR-01: Top-level render span never closes on timeout — orphaned `:start` event

**File:** `lib/rendro/pipeline.ex:35-41` (interaction with `lib/rendro/pipeline.ex:43-48`)

**Issue:** `Pipeline.run/1` wraps the pipeline in `Task.async` so it can enforce the `:timeout` policy via `Task.yield/Task.shutdown`. The `:telemetry.span/3` for the top-level `[:rendro, :render]` event lives *inside* the task closure (`execute_with_telemetry/3`). On timeout, `Task.shutdown(task)` returns `nil` and the task process is killed with `:kill` (or terminated abruptly). `:telemetry.span/3` only converts thrown errors / raises into `:exception` events via its internal `try/rescue/catch`; it cannot intercept a `Process.exit(pid, :kill)`. As a result, on timeout:

- `[:rendro, :render, :start]` was emitted (from inside the task, before the work)
- Neither `[:rendro, :render, :stop]` nor `[:rendro, :render, :exception]` is emitted
- The caller still receives `{:error, %Rendro.Error{stage: :render, reason: :timeout}}`

This breaks the documented invariant in `lib/rendro/pipeline.ex:8-11` ("All stages are instrumented with `:telemetry.span/3`. A top-level `[:rendro, :render]` span wraps the full pipeline") and the explicit CHANGELOG promise that the `:render :stop` event mirrors the new schema. Any consumer (e.g. `Threadline` adapter, dashboards) tracking start/stop pairs will report a leak on every timeout.

There is also no test exercising the timeout path — the regression cannot be caught by the current suite.

**Fix:** Move the top-level span outside the task, and emit a synthetic stop event explicitly on timeout. Alternative: emit `:exception` manually on timeout to honor the contract.

```elixir
def run(%Rendro.Document{} = doc) do
  render_id = Rendro.Telemetry.generate_render_id()
  render_opts = Map.get(doc.options, :render, [])
  deterministic = Keyword.get(render_opts, :deterministic, false) == true
  policies = Map.get(doc.options, :policies, [])
  timeout = Keyword.get(policies, :timeout, 30_000)

  base_meta = %{
    render_id: render_id,
    document_type: :pdf,
    deterministic: deterministic
  }

  :telemetry.span(Rendro.Telemetry.render_prefix(), Map.put(base_meta, :stage, :render), fn ->
    task = Task.async(fn -> run_stages(doc, base_meta, policies) end)

    result =
      case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
        {:ok, inner} -> inner
        {:exit, reason} -> {:error, Error.from_stage(:render, {:task_exit, reason}, base_meta)}
        nil -> {:error, Error.from_stage(:render, :timeout, base_meta)}
      end

    {result, build_stop_meta(result, doc, base_meta)}
  end)
end
```

Note also: the per-stage `:telemetry.span/3` calls inside `run_stages` will *also* be killed mid-flight on timeout, leaving any in-flight stage's `:start` event without a matching `:stop`. The fix above does not address that; if you want stage-level guarantees too, the timeout enforcement needs to be folded into each stage (or moved to a level where `try/after`-style guarantees hold).

---

### CR-02: `Pipeline.run/1` raises `MatchError` on `Task.shutdown` exit return

**File:** `lib/rendro/pipeline.ex:37-40`

**Issue:** The current code is

```elixir
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} -> result
  nil -> {:error, Error.from_stage(:render, :timeout, base_meta)}
end
```

Per `Task.shutdown/2` documentation, the return value is `{:ok, reply} | {:exit, reason} | nil`. The `||` handles `nil` from `Task.yield`, but if `Task.yield` returns `{:exit, reason}` (the task exited abnormally before the timeout window), or if `Task.shutdown` itself returns `{:exit, reason}` (the task crashed during the shutdown grace period), the `case` will not match either clause and Elixir raises a `CaseClauseError` (rendered as `MatchError`-class on case mismatch). The user sees a crash bubbling out of `Rendro.render/1` instead of `{:error, %Rendro.Error{}}`.

This is reachable any time a stage raises (even though `:telemetry.span` catches and re-raises, that re-raise propagates out of the task and turns into `{:exit, reason}` on yield). The `with` happy-path test suite does not cover this.

**Fix:** Add the missing clause:

```elixir
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} -> result
  {:exit, reason} -> {:error, Error.from_stage(:render, {:task_exit, reason}, base_meta)}
  nil -> {:error, Error.from_stage(:render, :timeout, base_meta)}
end
```

Add a test where a stage raises and assert `Rendro.render/1` returns `{:error, %Rendro.Error{}}` rather than crashing.

---

### CR-03: Top-level error stop reports stale `page_count` from the input doc

**File:** `lib/rendro/pipeline.ex:50-75`

**Issue:** `build_stop_meta/3` is called only at the top-level span and uses the original `doc` passed into `run/1` for `page_count: length(doc.pages)`. For the flow API, the input doc has `pages: []` and content lives in `doc.content`; the post-paginate doc is the one with real pages. So:

- A flow-API render that *fails after `:paginate`* (e.g. at `:render` or `:validate`) will have its top-level `:stop` event report `page_count: 0` even though the document was successfully paginated to N pages.
- A flow-API render that *succeeds* hits the `{:ok, _}` branch with `page_count: length(doc.pages)` = `0` — so even successful flow renders report `page_count: 0` at the top level. (Stage-level events use `derive_page_count/2` against the post-paginate doc and are correct.)

The CHANGELOG explicitly states (line 21): "Error-path `page_count` is now derived from the latest known doc state rather than hardcoded to `0`." For the success path it adds (line 22): "Top-level `[:rendro, :render, :stop]` event payload mirrors the new stage stop schema." Both promises are violated for the flow API.

The TelemetryTest suite uses only the fixed-page-API `sample_document/0`, so the bug is invisible to the current tests.

**Fix:** Thread the latest known doc through to the top-level stop, mirroring how `span/4` does it via `last_doc`:

```elixir
defp execute_with_telemetry(doc, base_meta, policies) do
  :telemetry.span(Rendro.Telemetry.render_prefix(), Map.put(base_meta, :stage, :render), fn ->
    {result, latest_doc} = run_stages_with_state(doc, base_meta, policies)
    {result, build_stop_meta(result, latest_doc, base_meta)}
  end)
end
```

Where `run_stages_with_state/3` returns `{result, latest_doc_seen}` (e.g. via a `Process.put/get` accumulator or by passing an agent). At minimum, document the limitation if you accept stale counts for the flow API.

Add a regression test rendering `Rendro.flow([Rendro.block(Rendro.text("…"))])` and asserting the top-level `:render :stop` carries `page_count: 1`.

---

### CR-04: `:max_pages` policy violation produces an internally inconsistent telemetry stream

**File:** `lib/rendro/pipeline.ex:77-98`

**Issue:** `validate_policy(:pages, …)` runs *between* the `:paginate` span and the `:render` span — *outside* any span. The `:paginate` span has already emitted `:stop` with `status: :ok` because `Paginate.run/1` itself succeeded. The policy guard then constructs `Error.from_stage(:paginate, :max_pages_exceeded, base_meta)` and the `with` short-circuits.

A consumer subscribing to telemetry will see:

1. `[:rendro, :pipeline, :paginate, :start]`
2. `[:rendro, :pipeline, :paginate, :stop]` with `status: :ok`, `page_count: N`
3. `[:rendro, :render, :stop]` with `status: :error, stage: :paginate, error.kind: :max_pages_exceeded`

Stage `:paginate` says "I succeeded" while the top-level says "I failed at `:paginate`." This contradicts the moduledoc's stated contract ("each stage emits …", "stop events now carry a unified schema across success and error paths") and is likely to break any dashboard logic that maps stage stop events to per-stage success rates.

There is no telemetry test covering `:max_pages` policy enforcement; the regression cannot be caught by the current suite.

**Fix:** Move the policy guard *into* the `:paginate` span so its outcome is captured by the same span that ran the work:

```elixir
defp run_stages(doc, base_meta, policies) do
  with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
       {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
       {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
       {:ok, doc} <- span(:paginate, base_meta, fn ->
                       with {:ok, doc} <- Paginate.run(doc),
                            :ok <- check_max_pages(doc, policies) do
                         {:ok, doc}
                       end
                     end, doc),
       {:ok, pdf} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
       {:ok, pdf} <- span(:validate, base_meta, fn -> Validate.run(pdf, doc) end, doc) do
    {:ok, pdf}
  end
end

defp check_max_pages(%Rendro.Document{pages: pages}, policies) do
  case Keyword.get(policies, :max_pages) do
    nil -> :ok
    max when length(pages) > max -> {:error, :max_pages_exceeded}
    _ -> :ok
  end
end
```

Add a TelemetryTest case asserting that on `:max_pages_exceeded`, the `:paginate :stop` event carries `status: :error, error: %{kind: :max_pages_exceeded, stage: :paginate}` — and that no `:render :start` follows.

---

### CR-05: `Paginate.paginate_flow/1` ignores header/footer block heights, over-packs every flow page

**File:** `lib/rendro/pipeline/paginate.ex:21-27`

**Issue:** `paginate_flow/1` reads:

```elixir
header_h = Enum.sum(Enum.map(h_blocks, &(&1.height || 0)))
footer_h = Enum.sum(Enum.map(f_blocks, &(&1.height || 0)))

max_h = template.height - template.margin_top - template.margin_bottom - header_h - footer_h
```

The intent is clearly "reserve space for header and footer." However, `doc.header` and `doc.footer` blocks are NEVER measured: `Measure.measure_pages/2` only walks `doc.pages`, and `Measure.measure_content/2` only walks `doc.content`. Header/footer blocks live on the document at `doc.header` / `doc.footer` (see `lib/rendro/document.ex:9-10`). They retain `height: nil` (the `Block` default) when entering Paginate, so `&(&1.height || 0)` always returns `0`. `header_h + footer_h` is therefore always `0` and `max_h` reserves no space for the rendered header/footer.

Effect: every flow-API document with non-empty `:header` or `:footer` will have content that overflows under the header / over the footer in the rendered PDF. The bug is silent — pagination still produces N pages, the binary still validates, but the layout is wrong.

This is also undetected by the test suite: `paginate_test.exs` and the broader test fixtures never construct a document with header/footer blocks.

**Fix:** Either (a) make Measure walk `doc.header` and `doc.footer`, or (b) measure them inline in `paginate_flow/1` before computing `header_h`. Option (a) is cleaner:

```elixir
# in measure.ex
def run(%Rendro.Document{} = doc) do
  font = Font.helvetica()

  doc =
    doc
    |> measure_pages(font)
    |> measure_content(font)
    |> measure_header(font)
    |> measure_footer(font)

  {:ok, doc}
end

defp measure_header(%Rendro.Document{header: h} = doc, font),
  do: %{doc | header: Enum.map(h, &measure_block(&1, font))}

defp measure_footer(%Rendro.Document{footer: f} = doc, font),
  do: %{doc | footer: Enum.map(f, &measure_block(&1, font))}
```

Then add a test: a flow doc with a header block of known height, verifying that the page-1 content blocks all sit *below* `margin_top + header_height` after pagination.

---

## Warnings

### WR-01: `Measure.measure_block/2` silently skips cells of any user-sized table

**File:** `lib/rendro/pipeline/measure.ex:41-54` (interaction with line 62)

**Issue:** The table clause matches `%Rendro.Block{content: %Rendro.Table{} = table, width: nil}`. If the user passes an explicitly-sized table block (e.g. `%Block{content: %Table{...}, width: 400}`), the pattern does NOT match. There is no second table clause, so the block falls through to the catch-all `defp measure_block(block, _font), do: block` and the entire table — header cells, every row's cells — is returned unmeasured. Downstream Paginate then tries to compute heights using nil-coalesced `block.height || 0`, and Render emits text with width=nil to the writer.

This is asymmetric with the text clause at line 56-60, which correctly merges user-supplied `block.width` / `block.height` with computed defaults rather than gating the entire measurement on them being nil.

**Fix:** Always normalize-and-measure rows; only honor user-supplied outer width/height:

```elixir
defp measure_block(%Rendro.Block{content: %Rendro.Table{} = table} = block, font) do
  row_height = 14.4
  header_h = if table.header, do: row_height, else: 0
  rows_h = length(table.rows) * row_height

  measured_header = if table.header, do: measure_row(table.header, font), else: nil
  measured_rows = Enum.map(table.rows, &measure_row(&1, font))

  table = %{table | header: measured_header, rows: measured_rows}

  %{
    block
    | content: table,
      width: block.width || 500,
      height: block.height || header_h + rows_h
  }
end
```

Also: hardcoded `width: 500` is a magic number unrelated to any page width or table-width hint (`%Table{width: :fill}` is ignored entirely). Document or extract a constant.

---

### WR-02: `Error.next_step(:render, :max_bytes_exceeded)` is dead code

**File:** `lib/rendro/error.ex:74-76`

**Issue:** Per CHANGELOG line 20, `:max_bytes_exceeded` errors are now attributed to `:validate`, not `:render`. The new `next_step(:validate, :max_bytes_exceeded)` clause at line 90-92 returns the same guidance text. The `:render` variant at line 74-76 is no longer reachable through any code path the pipeline can produce. Leaving it in place is misleading and creates two sources of truth — if the message changes, the dead clause will silently rot.

**Fix:** Remove the dead clause:

```elixir
# DELETE these three lines:
defp next_step(:render, :max_bytes_exceeded) do
  "Reduce content complexity or increase the :max_bytes policy limit."
end
```

If you want defensive belt-and-suspenders coverage, leave it but add a comment marking it deprecated/unreachable post-Phase-6.

---

### WR-03: `Validate.match_count_before_pages/1` regex anchor is too loose

**File:** `lib/rendro/pipeline/validate.ex:65-73`

**Issue:** The regex `~r{/Count\s+(\d+)[^>]*?/Type\s+/Pages}s` uses `[^>]` (single `>`) to "keep the lazy traversal bounded to one dict body." A PDF dict body is bounded by `>>` (two `>`s), and a single `>` can legitimately appear inside a dict body (it terminates a hex string `<...>`). Conversely, the pattern is too eager to terminate — a dict that contains a hex string ending in `>` somewhere between `/Count` and `/Type /Pages` will fail to match, even though the keys are in the same dict.

In practice the writer produces Pages dicts without hex strings, so the bug is currently latent. Adversarial input is not a concern (this is our own output), but the structural assumption is brittle and warrants either a comment explaining the constraint or a tighter scan.

**Fix:** Match `>>` properly using a tempered-greedy pattern, or first carve out the Pages object then look up `/Count` within it:

```elixir
defp match_count_before_pages(pdf_binary) do
  # Match a dict body containing both /Count N and /Type /Pages, in either order.
  pattern = ~r{<<(?:(?!>>).)*?/Count\s+(\d+)(?:(?!>>).)*?/Type\s+/Pages}s
  case Regex.run(pattern, pdf_binary, capture: :all_but_first) do
    [n] -> String.to_integer(n)
    _ -> nil
  end
end
```

Even better: parse the Pages object explicitly rather than regex-grovel.

Also note: `match_count_after_pages/1` has no dict bound at all (`.*?` lazy), so a `/Type /Pages` appearing in a comment or in unrelated metadata followed by a `/Count` elsewhere will cross-match. Same fix pattern applies.

---

### WR-04: `Paginate.paginate_flow/1` ignores document-level page dimensions

**File:** `lib/rendro/pipeline/paginate.ex:22`

**Issue:** `template = %Rendro.Page{}` constructs a default A4 page. There is no API to influence template dimensions from the document — `Rendro.flow(content, opts)` does not surface page width/height/margin, so users who want a US Letter flow document or custom margins have no path. While `lib/rendro.ex:51-53` accepts `opts` and forwards them to `document/1`, those keys never reach `paginate_flow/1`.

This is a design gap rather than a logic bug, but it means the flow API silently disregards any page configuration. Worth either documenting "flow API uses default A4" prominently, or threading template selection through.

**Fix:** Allow a `:page_template` (or first-page-as-template) override:

```elixir
defp paginate_flow(%Rendro.Document{content: content, header: h, footer: f, options: opts} = doc) do
  template = Map.get(opts, :page_template, %Rendro.Page{})
  ...
end
```

---

### WR-05: `paginate_flow/1` uses Enum-list-append, O(n²) — out of scope but flag-worthy

**File:** `lib/rendro/pipeline/paginate.ex:62, 82, 93, 109, 131, 139, 152`

**Issue:** Multiple hot loops use `acc ++ [element]` — list-append with a singleton, which is O(n) per call and O(n²) over the loop. For flow documents with thousands of blocks or rows, this becomes a real cliff. (Performance is out of v1 scope, but mentioning because the same files mix patterns: `Enum.reduce` returning a reversed list with a final `Enum.reverse` would fix it cleanly.)

**Fix:** Prepend then reverse:

```elixir
{stacked, _} =
  Enum.reduce(blocks, {[], starting_y}, fn block, {acc, current_y} ->
    stacked_block = stack_table_cells(%{block | y: current_y})
    next_y = current_y + (block.height || 0)
    {[stacked_block | acc], next_y}
  end)

%{page | blocks: Enum.reverse(stacked)}
```

(Flagging because of the file's scale; downgrading from Critical to Warning since v1 scope excludes performance.)

---

### WR-06: `Validate.parse_page_count/1` falls back to `0` — silently passes when both PDF and doc claim zero pages

**File:** `lib/rendro/pipeline/validate.ex:51-56`

**Issue:** When neither regex matches, `parse_page_count` returns `0`. `check_page_count/2` then compares `actual == expected` (`length(doc.pages)`). If the document somehow reaches Validate with `pages: []`, the check passes despite the rendered binary having no Pages object at all — a structural defect.

In practice, `Build.run/1` rejects empty pages with `{:error, :no_pages}` before reaching Validate, so this is unreachable today. But it's defensive-programming-broken: a future code path that bypasses Build (e.g. testing harness, recipe shortcut) could slip a degenerate doc through.

**Fix:** Distinguish "no Pages object" from "Pages object with /Count 0":

```elixir
defp check_page_count(pdf_binary, %Rendro.Document{pages: pages}) do
  expected = length(pages)
  case parse_page_count(pdf_binary) do
    nil -> {:error, :structural_corruption}
    actual when actual == expected -> :ok
    _ -> {:error, :page_count_mismatch}
  end
end

defp parse_page_count(pdf_binary) do
  cond do
    result = match_count_after_pages(pdf_binary) -> result
    result = match_count_before_pages(pdf_binary) -> result
    true -> nil
  end
end
```

---

### WR-07: `Pipeline.run/1` crashes if `doc.options.render` or `doc.options.policies` is `nil`

**File:** `lib/rendro/pipeline.ex:23-25, 33`

**Issue:** `Map.get(doc.options, :render, [])` returns the default `[]` only when the key is absent. If a caller stores `doc.options = %{render: nil, policies: nil}`, `Keyword.get(nil, :deterministic, false)` raises `FunctionClauseError`. This is reachable via `put_in(doc.options[:render], nil)` or via tests that set policies explicitly to `nil`. The Document type spec (`%{optional(atom()) => term()}`) permits any term, including `nil`.

**Fix:** Coerce `nil` to `[]`:

```elixir
render_opts = Map.get(doc.options, :render, []) || []
policies = Map.get(doc.options, :policies, []) || []
```

---

### WR-08: `Compose.run/1` and `Measure.run/1` specs claim `{:error, term()}` but never error

**File:** `lib/rendro/pipeline/compose.ex:11`, `lib/rendro/pipeline/measure.ex:14`

**Issue:** Both specs include an `{:error, term()}` arm, but neither implementation can actually return an error — they're pure transformations. This is an accurate-spec issue: callers (`Pipeline.span/4`) handle the error case, dialyzer treats the error path as live, and a maintainer reading `Compose.run/1` may waste time chasing a non-existent failure mode.

**Fix:** Either tighten the spec to `{:ok, Document.t()}`, or document explicitly which conditions could produce an error in the future and add a guard. Tightening is the safer choice today:

```elixir
@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()}
```

---

## Info

### IN-01: `:render` stage on `:max_bytes_exceeded` failure loses byte_size from the rendered binary

**File:** `lib/rendro/pipeline.ex:118-144`

**Issue:** When `Validate.run/2` returns `{:error, :max_bytes_exceeded}`, `span/4` at line 109 passes `nil` as `result` into `stage_stop_meta`, so `derive_byte_size(:validate, nil)` returns `0`. But the binary that exceeded the policy *is* available — we know its byte size — and that's the most diagnostic single piece of information for this error. Reporting `byte_size: 0` is misleading.

**Fix:** Pass the binary through on the error path so its size can be reported:

```elixir
{:error, reason} ->
  error = Error.from_stage(stage, reason, base_meta)
  meta = stage_stop_meta(stage, {:error, error}, last_input_for_size(stage, fun_input), last_doc, base_meta)
  {{:error, error}, meta}
```

Or have `Validate.run/2` return `{:error, {:max_bytes_exceeded, byte_size}}` and surface that into the stop meta's `:error` map.

---

### IN-02: `defmodule RaisingBuild` defined inside `test "exception in a stage emits exception event …"` recompiles every run

**File:** `test/rendro/telemetry_test.exs:285-309`

**Issue:** Defining a module inside a `test` block creates and recompiles it whenever the test runs (including under `mix test --stale`), emitting "redefining module" warnings and slowing down repeated runs. The test also doesn't actually invoke `Pipeline.run/1` — it directly calls `:telemetry.span` with a hand-rolled meta map, which means it doesn't validate that `Pipeline.run/1`'s span machinery handles raises correctly.

**Fix:** Either move `RaisingBuild` to `test/support/` as a top-level helper, or — better — write a test that injects a raising stage via dependency injection (or via Mox) and asserts the real `Pipeline.run/1` produces the expected `:exception` event. As-is, the test only confirms `:telemetry.span/3` works as advertised, not Rendro's wiring.

---

### IN-03: Stale comment in `validate_test.exs` references "old max_bytes path"

**File:** `test/rendro/pipeline/validate_test.exs` — wait, this file looks fine. The issue is in `telemetry_test.exs:445-449`:

**File:** `test/rendro/telemetry_test.exs:445-449`

**Issue:** The comment block reads:

```
# NOTE: until Plan 02 lands the :validate stage, this fails on the OLD
# max_bytes path which is attributed to :render. Tagged pending until
# Plan 02 ships.
```

The test is not actually `@tag :pending`-tagged — it runs live. Per the CHANGELOG, Plan 02 has shipped (`:validate` stage exists and `:max_bytes` is attributed to it). The comment is stale and may confuse a maintainer who reads it later thinking the test is gated.

**Fix:** Delete the comment, or replace with a brief note that this test is the regression that Plan 02 enabled.

---

### IN-04: `validate_test.exs:23-30` runs stages in the OLD order — explicitly wrong order in test fixture

**File:** `test/rendro/pipeline/validate_test.exs:21-30`

**Issue:** The helper `render_through_full_pipeline/1` runs `Build → Measure → Paginate → Compose → Render`. The comment acknowledges this is "the OLD order … to produce a binary independently of the orchestrator's eventual reorder in Plan 03." Phase 6 Plan 03 has now landed and the new order in `Pipeline.run_stages/3` is `Build → Compose → Measure → Paginate → Render → Validate`.

The test still runs the old order. While the rationale ("Validate operates on the binary regardless of upstream order") is technically true, exercising the wrong order in tests adds no signal and risks masking bugs that only manifest under the canonical order. (It also means these tests don't double as smoke tests for the canonical pipeline.)

**Fix:** Update the helper to match the canonical order — or, better, drop the manual stitching and call `Pipeline.run/1` directly (subscribing telemetry to capture the binary if needed).

```elixir
defp render_through_full_pipeline(doc) do
  {:ok, doc} = Build.run(doc)
  {:ok, doc} = Compose.run(doc)
  {:ok, doc} = Measure.run(doc)
  {:ok, doc} = Paginate.run(doc)
  {:ok, pdf} = Render.run(doc)
  {pdf, doc}
end
```

---

### IN-05: `Pipeline.run/1` `@spec` does not include the `:invalid_document` failure mode

**File:** `lib/rendro/pipeline.ex:20`

**Issue:** The function head pattern-matches `%Rendro.Document{}` only — passing anything else raises `FunctionClauseError`, not `{:error, %Rendro.Error{}}`. The `Build.run/1` clause for non-document at `lib/rendro/pipeline/build.ex:14` returns `{:error, :invalid_document}`, but it's never reached from `Pipeline.run/1` (the head guard already filtered). Either widen the head and rely on Build's check, or document the strict input type in the spec / moduledoc. Currently, callers might assume `{:error, _}` covers all failures and be surprised by a `FunctionClauseError`.

**Fix:** Either widen and delegate to Build:

```elixir
@spec run(term()) :: {:ok, binary()} | {:error, Rendro.Error.t()}
def run(%Rendro.Document{} = doc), do: ...
def run(other) do
  base_meta = %{render_id: Rendro.Telemetry.generate_render_id(), document_type: :pdf, deterministic: false}
  {:error, Error.from_stage(:build, :invalid_document, base_meta)}
end
```

…or keep the strict guard and add `@doc` text noting the input must be `%Rendro.Document{}`.

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

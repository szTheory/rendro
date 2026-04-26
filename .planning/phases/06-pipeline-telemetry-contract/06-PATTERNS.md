# Phase 6: Pipeline Telemetry Contract Fixes - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 11 (3 new, 8 modified)
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/pipeline/validate.ex` (NEW) | pipeline-stage module | transform (binary in, binary out, with-chain) | `lib/rendro/pipeline/build.ex` | exact (stage module + with-chain validation) |
| `test/rendro/pipeline/validate_test.exs` (NEW) | stage unit test | request-response | `test/rendro/pipeline/build_test.exs` | exact (stage test boilerplate + error-reason coverage) |
| `CHANGELOG.md` (NEW) | doc | static markdown | none in repo (first-of-kind) | no analog — use Keep-a-Changelog spec from D-18 |
| `lib/rendro/pipeline.ex` (MOD) | orchestrator | pipeline | `lib/rendro/pipeline.ex` (self-refactor) | exact (extend existing helpers) |
| `lib/rendro/telemetry.ex` (MOD) | telemetry constants | static | `lib/rendro/telemetry.ex` (self) | exact (one-line list edit) |
| `lib/rendro/pipeline/compose.ex` (MOD) | pipeline-stage | transform | `lib/rendro/pipeline/measure.ex` (source of `normalize_row/1`) | exact (move-fn refactor) |
| `lib/rendro/pipeline/measure.ex` (MOD) | pipeline-stage | transform | self (shrink-only refactor) | exact |
| `lib/rendro/pipeline/paginate.ex` (MOD) | pipeline-stage | transform | `lib/rendro/pipeline/compose.ex` (source of y-stacking) | exact (absorb cursor logic) |
| `lib/rendro/error.ex` (MOD) | error envelope | builder | self — pattern-match the `next_step/2` clause table | exact (add 2 clauses) |
| `test/rendro/telemetry_test.exs` (MOD) | telemetry contract test | request-response | self (rewrite + extend) | exact |
| `test/rendro/pipeline/{compose,measure}_test.exs` (MOD) | stage unit test | request-response | self (verify-still-passes) | exact |

---

## Pattern Assignments

### `lib/rendro/pipeline/validate.ex` (NEW pipeline-stage, transform)

**Primary analog:** `lib/rendro/pipeline/build.ex` — same shape: `run/N` returning `{:ok, _} | {:error, atom()}` via internal `with` over private check helpers.
**Secondary analog:** `lib/rendro/pipeline/render.ex` — only other stage that handles a PDF binary.

**Module boilerplate pattern** (from `lib/rendro/pipeline/build.ex:1-14`):
```elixir
defmodule Rendro.Pipeline.Build do
  @moduledoc """
  Validates and normalizes a Document struct for the render pipeline.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages} = doc) when is_list(pages) do
    case validate(doc) do
      :ok -> {:ok, normalize(doc)}
      {:error, _} = err -> err
    end
  end
```

**Validation `with`-chain pattern** (from `lib/rendro/pipeline/build.ex:7-12` + `RESEARCH.md` Code Examples §1):
```elixir
@spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, atom()}
def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary) do
  with :ok <- check_structural(pdf_binary),
       :ok <- check_page_count(pdf_binary, doc),
       :ok <- check_max_bytes(pdf_binary, doc) do
    {:ok, pdf_binary}
  end
end
```
The `:ok` short-circuit in `with` returns the first `{:error, reason}` directly — same idiom as `Build.run/1`'s `Enum.reduce_while/3` over `validate_pages/1` (`build.ex:26-32`).

**Single-clause cond/case predicate pattern** (from `lib/rendro/pipeline/build.ex:47-52`):
```elixir
defp validate_page(%Rendro.Page{width: w, height: h})
     when is_number(w) and w > 0 and is_number(h) and h > 0,
     do: :ok

defp validate_page(%Rendro.Page{}), do: {:error, :invalid_page_dimensions}
```
Use the same shape for `check_structural/1` (header + trailer present), `check_page_count/2` (regex against `length(doc.pages)`), `check_max_bytes/2` (byte_size vs policy).

**PDF token literals to import**:
- `@pdf_header "%PDF-"` — matches the prefix of `lib/rendro/pdf/writer.ex:12` (`"%PDF-1.4\n%\xE2\xE3\xCF\xD3\n"`).
- `@pdf_trailer "%%EOF"` — matches the literal at `lib/rendro/pdf/writer.ex:292` (`"\n%%EOF\n"`).

**Page-count parse pattern** (from RESEARCH.md Code Examples §1, validated against `test/rendro/pdf/writer_test.exs`):
```elixir
defp parse_page_count(pdf_binary) do
  case Regex.run(~r{/Type\s+/Pages.*?/Count\s+(\d+)}s, pdf_binary, capture: :all_but_first) do
    [n] -> String.to_integer(n)
    _ -> 0
  end
end
```

**Policy-read pattern** (from `lib/rendro/pipeline.ex:21` + `pipeline.ex:84`):
```elixir
policies = Map.get(doc.options, :policies, [])
max_bytes = Keyword.get(policies, :max_bytes)
```
Mirror this inside `check_max_bytes/2`. Returns `:ok` when `max_bytes` is nil; `{:error, :max_bytes_exceeded}` when exceeded.

---

### `test/rendro/pipeline/validate_test.exs` (NEW stage unit test)

**Primary analog:** `test/rendro/pipeline/build_test.exs` — exact match: stage with multiple error reasons + happy path; same `use ExUnit.Case, async: true` boilerplate; same `describe "run/N" do` block; same `assert {:error, :reason}` shape.
**Secondary analog:** `test/rendro/pipeline/render_test.exs` — for PDF-binary fixture construction (header assertion).

**Test module boilerplate** (from `test/rendro/pipeline/build_test.exs:1-5`):
```elixir
defmodule Rendro.Pipeline.BuildTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Build

  describe "run/1" do
```
Mirror as `Rendro.Pipeline.ValidateTest` / `alias Rendro.Pipeline.Validate` / `describe "run/2" do`.

**Happy-path test pattern** (from `test/rendro/pipeline/build_test.exs:7-14`):
```elixir
test "returns {:ok, document} for a valid document" do
  doc = %Rendro.Document{
    pages: [%Rendro.Page{blocks: []}],
    metadata: %Rendro.Metadata{}
  }

  assert {:ok, ^doc} = Build.run(doc)
end
```
For Validate, render a real PDF first via `Rendro.Pipeline.Render.run(doc)` (or call the full `Rendro.Pipeline.run/1` and capture the binary) to feed into `Validate.run(pdf, doc)`.

**Error-reason test pattern** (from `test/rendro/pipeline/build_test.exs:26-29`):
```elixir
test "returns error for empty pages" do
  doc = %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
  assert {:error, :no_pages} = Build.run(doc)
end
```
One test per new error reason: `:structural_corruption` (pass `"not a pdf"`), `:page_count_mismatch` (truncate or fabricate a 0-page PDF body), `:max_bytes_exceeded` (set `policies: [max_bytes: 1]` in `doc.options`).

**Real-PDF assertion pattern** (from `test/rendro/pipeline/render_test.exs:13-16`):
```elixir
assert {:ok, pdf} = Render.run(doc)
assert is_binary(pdf)
assert String.starts_with?(pdf, "%PDF-1.4")
```

---

### `CHANGELOG.md` (NEW root file)

**No in-repo analog** — first changelog. Use the format spec locked in CONTEXT D-18 (Keep-a-Changelog v1.1.0 https://keepachangelog.com/en/1.1.0/).

**Required sections per D-18** (verbatim):
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added
- `[:rendro, :pipeline, :validate, :start | :stop | :exception]` telemetry events for the new trailing post-render validation stage. Stage performs PDF structural sanity checks (`%PDF-` header, `%%EOF` trailer), page-count parity (PDF `/Count` vs `length(doc.pages)`), and the `:max_bytes` policy enforcement formerly inlined after `:render`.

### Changed (BREAKING)
- Pipeline stage execution order now matches the documented architecture: `build → compose → measure → paginate → render → validate`. Previously stages ran in the order `build → measure → paginate → compose → render`, which inverted compose/measure relative to the spec.
- `max_pages_exceeded` policy errors now fire from the `:paginate` stage stop event rather than mid-pipeline (the policy guard runs after `:paginate` and before `:render`, where page count is final).
- Stage `:stop` events now carry a unified schema across success and error paths: `%{render_id, document_type, deterministic, stage, status, page_count, byte_size}` with an optional `:error` map (`%{kind, stage}`) on `status: :error`. Error-path `page_count` is now derived from the latest known doc state rather than hardcoded to `0`.

### Notes
- Pre-1.0 release; previous stage order was a bug against the documented architecture (`v1.0-MILESTONE-AUDIT.md` BLOCKER-04, BLOCKER-05). Top-level `[:rendro, :render, :*]` event names are unchanged; their stop_meta schema is updated to match the new stage schema.
```

---

### `lib/rendro/pipeline.ex` (MOD orchestrator)

**Primary analog:** itself — the existing helpers are the right shape; the work is reordering and unifying.

**Pre-existing `with`-chain pattern to preserve** (from `lib/rendro/pipeline.ex:61-71`):
```elixir
defp run_stages(doc, base_meta, policies) do
  with {:ok, doc} <- span(:build, base_meta, fn -> Build.run(doc) end, doc),
       {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),
       {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
       :ok <- validate_policy(:pages, doc, policies, base_meta),
       {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
       {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),
       :ok <- validate_policy(:bytes, pdf_binary, policies, base_meta) do
    {:ok, pdf_binary}
  end
end
```

**Target shape per D-01 / D-10 / D-07.3** (from RESEARCH.md Code Examples §2):
```elixir
defp run_stages(doc, base_meta, policies) do
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

**Existing `span/4` helper signature to preserve** (from `lib/rendro/pipeline.ex:93-115`):
```elixir
defp span(stage, base_meta, fun, doc) do
  meta = Map.put(base_meta, :stage, stage)

  :telemetry.span([:rendro, :pipeline, stage], meta, fn ->
    case fun.() do
      {:ok, result} ->
        stop_meta =
          stage_stop_meta(stage, result, doc)
          |> Map.put(:render_id, base_meta.render_id)

        {{:ok, result}, stop_meta}

      {:error, %Error{} = error} ->
        stop_meta = %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
        {{:error, error}, stop_meta}

      {:error, reason} ->
        error = Error.from_stage(stage, reason, base_meta)
        stop_meta = %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
        {{:error, error}, stop_meta}
    end
  end)
end
```

**Unified `stage_stop_meta/5` builder pattern** (per D-11/D-12/D-13/D-14, from RESEARCH.md Code Examples §3):
```elixir
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
    render_id:     base_meta.render_id,
    document_type: base_meta.document_type,
    deterministic: base_meta.deterministic,
    stage:         stage,
    status:        if(status_or_error == :ok, do: :ok, else: :error),
    page_count:    page_count,
    byte_size:     byte_size
  }

  case status_or_error do
    :ok -> base
    {:error, %Rendro.Error{} = e} -> Map.put(base, :error, %{kind: e.reason, stage: e.stage})
  end
end

defp derive_page_count(%Rendro.Document{pages: pages}, _last), do: length(pages)
defp derive_page_count(_result, %Rendro.Document{pages: pages}), do: length(pages)
defp derive_page_count(_result, _last), do: 0

defp derive_byte_size(:render, pdf) when is_binary(pdf), do: byte_size(pdf)
defp derive_byte_size(:validate, pdf) when is_binary(pdf), do: byte_size(pdf)
defp derive_byte_size(_stage, _result), do: 0
```

**Existing top-level `build_stop_meta/3` pattern to update for D-16** (from `lib/rendro/pipeline.ex:46-59`):
```elixir
defp build_stop_meta(result, doc, base_meta) do
  case result do
    {:ok, pdf_binary} ->
      %{
        render_id: base_meta.render_id,
        status: :ok,
        page_count: length(doc.pages),
        byte_size: byte_size(pdf_binary)
      }

    {:error, _error} ->
      %{render_id: base_meta.render_id, status: :error, page_count: 0, byte_size: 0}
  end
end
```
Replace error-path `page_count: 0` with `length(doc.pages)` (D-12) and add `error: %{kind: error.reason, stage: error.stage}` (D-14). Add `document_type`, `deterministic`, `stage` keys to match D-11 schema.

**Module-level `@moduledoc` to update**: line 3 currently reads `build -> measure -> paginate -> compose -> render` — change to `build -> compose -> measure -> paginate -> render -> validate`.

---

### `lib/rendro/telemetry.ex` (MOD constants)

**Existing pattern** (from `lib/rendro/telemetry.ex:26`):
```elixir
@stage_names [:build, :compose, :measure, :paginate, :render]
```

**Target** (per D-01, D-19):
```elixir
@stage_names [:build, :compose, :measure, :paginate, :render, :validate]
```

Single-line edit. `event_prefixes/0` and `all_event_names/0` (lines 28, 42-47) cascade automatically — no other changes needed in this file. Test helper at `test/support/telemetry_helper.ex:5` reads `all_event_names/0` dynamically; new events auto-subscribe.

Update `@moduledoc` event-naming section (lines 7-9, 13-15, 18-19) only if it explicitly lists the old order — current text uses generic `:stage_name` placeholder, so likely no edit needed. Verify on read.

---

### `lib/rendro/pipeline/compose.ex` (MOD pipeline-stage)

**Primary analog:** `lib/rendro/pipeline/measure.ex:64-70` — the `normalize_row/1` source being moved IN.

**Source of `normalize_row/1` to MOVE FROM `measure.ex` (lines 64-70)**:
```elixir
defp normalize_row(row) do
  Enum.map(row, fn
    %Rendro.Block{} = b -> b
    content when is_binary(content) -> Rendro.block(Rendro.text(content))
    other -> Rendro.block(other)
  end)
end
```

**Y-stacking code to REMOVE from `compose.ex` (current lines 16-26, 36-44, 48-56)**:
```elixir
defp compose_page(%Rendro.Page{blocks: blocks} = page) do
  {composed_blocks, _} =
    Enum.reduce(blocks, {[], 0}, fn block, {acc, current_y} ->
      y = block.y || current_y
      composed_block = compose_block(%{block | y: y})
      next_y = y + (block.height || 0)
      {acc ++ [composed_block], next_y}
    end)

  %{page | blocks: composed_blocks}
end
```
After removal, `compose_page/1` becomes pass-through over blocks (logical tree only per D-02). Table inner cell layout (`compose_block/1` for `%Rendro.Table{}`) — y-stacking inside tables also moves to Paginate; only the row-normalization wrapper survives.

**Pattern to KEEP — `Enum.map(pages, &compose_page/1)`** (current lines 11-14): unchanged, still the entry point.

---

### `lib/rendro/pipeline/measure.ex` (MOD pipeline-stage)

**Primary analog:** itself (shrink-only refactor).

**Code to REMOVE** — `normalize_row/1` (lines 64-70), `normalized_header`/`normalized_rows` calls (lines 45-46), and any wrapping that depends on row-normalization (test that `measured_header = ... measure_row(normalized_header, ...)` chain still type-checks once normalization is upstream).

**Pattern to KEEP** — pure metric-fill (lines 56-62):
```elixir
defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, font) do
  width = block.width || Font.text_width(font, text.content, text.size)
  height = block.height || text.size * 1.2
  %{block | width: width, height: height}
end

defp measure_block(block, _font), do: block
```
This is the canonical "measure pure metric pass" idiom per D-03 — preserve, do not touch.

**Idempotence invariant** (D-03): `Measure.run/1` called twice on the same doc must produce the same doc. The `width = block.width || ...` pattern (line 57) already guarantees this — leave alone.

---

### `lib/rendro/pipeline/paginate.ex` (MOD pipeline-stage)

**Primary analog:** `lib/rendro/pipeline/compose.ex:16-26` — y-stacking source being absorbed IN.

**Y-stacking pattern to ABSORB from `compose.ex:16-26`** (move INTO Paginate, applied per page after pagination splits):
```elixir
{composed_blocks, _} =
  Enum.reduce(blocks, {[], 0}, fn block, {acc, current_y} ->
    y = block.y || current_y
    composed_block = compose_block(%{block | y: y})
    next_y = y + (block.height || 0)
    {acc ++ [composed_block], next_y}
  end)
```
**D-04 latent-bug fix:** when this logic moves to Paginate, the `current_y` accumulator MUST reset to `0` per page (or per page-template `margin_top`). The current Compose code seeds the reduce with `0` per `compose_page/1` call, which works because Compose runs before pagination in the buggy current order — once Paginate owns it, the page-2 remainder rows naturally start fresh.

**Existing flow-pagination scaffolding to extend** (from `lib/rendro/pipeline/paginate.ex:19-44`):
```elixir
defp paginate_flow(%Rendro.Document{content: content, header: h_blocks, footer: f_blocks} = doc) do
  template = %Rendro.Page{}
  # ... reduce content into pages ...
  pages =
    content
    |> Enum.reduce([%{template | blocks: []}], fn block, pages ->
      paginate_block(block, pages, template, max_h)
    end)
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {page, idx} ->
      apply_page_template(page, idx, h_blocks, f_blocks)
    end)
```
Insert a y-stacking pass over each emitted page just before `apply_page_template/4`, OR fold y-assignment into `paginate_block/4` as blocks are appended.

**Throw-and-catch error-pattern to preserve** (from `lib/rendro/pipeline/paginate.ex:27-43, 90-94`):
```elixir
try do
  pages = ... |> Enum.reduce(...) ...
  {:ok, %{doc | pages: pages, content: []}}
catch
  {:error, :content_overflow, details} ->
    {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
end
```
This is the canonical "throw inside reduce, catch at boundary, wrap in `Rendro.Error`" pattern. Preserve as-is; new y-stacking logic should not introduce new throw cases.

---

### `lib/rendro/error.ex` (MOD error envelope)

**Primary analog:** itself — pattern-match the existing `next_step/2` clause table (lines 53-87) and add new clauses.

**Existing `what/2` clause-table pattern** (from `lib/rendro/error.ex:40-45`):
```elixir
defp what(:build, _reason), do: "Input document failed pipeline validation."
defp what(:compose, _reason), do: "Document composition failed before measurement."
defp what(:measure, _reason), do: "Block measurement failed while computing dimensions."
defp what(:paginate, _reason), do: "Pagination failed while assigning content to pages."
defp what(:render, _reason), do: "PDF serialization failed during render."
defp what(stage, _reason), do: "Render pipeline failed in stage #{inspect(stage)}."
```

**Add new clause** (per D-09):
```elixir
defp what(:validate, _reason), do: "Post-render validation failed."
```

**Existing `next_step/2` clause-table pattern** (from `lib/rendro/error.ex:53-87`):
```elixir
defp next_step(:build, :no_pages) do
  "Add at least one page before rendering (Rendro.document(pages: [...]))."
end

defp next_step(:render, :max_bytes_exceeded) do
  "Reduce content complexity or increase the :max_bytes policy limit."
end

defp next_step(:render, :timeout) do
  "Optimize document complexity or increase the :timeout policy limit."
end

defp next_step(_stage, _reason) do
  "Inspect stage inputs and rerun with telemetry attached for the same render_id."
end
```

**Add new clauses** (per D-09 + RESEARCH.md Code Examples §5):
```elixir
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

**Existing `defp next_step(:render, :max_bytes_exceeded)` (line 73-75)** — keep as defensive code per RESEARCH.md A4. Small surface area; no harm.

**Existing `from_stage/3` builder is unchanged** (lines 24-38). New stages plug into the existing scaffolding via the `where:` field's automatic `Macro.camelize/1` (lines 89-93); `:validate` → `Rendro.Pipeline.Validate` automatically.

---

### `test/rendro/telemetry_test.exs` (MOD telemetry contract test)

**Primary analog:** itself.

**Existing line 319 — wrong stage order assertion**:
```elixir
assert stage_starts == [:build, :measure, :paginate, :compose, :render]
```
**Replace with** (per D-19):
```elixir
assert stage_starts == [:build, :compose, :measure, :paginate, :render, :validate]
```

**Existing event-count assertion at lines 63-74** — `5 stages + 1 top-level = 12` becomes `6 stages + 1 top-level = 14`:
```elixir
test "total event count: 5 stages + 1 top-level = 12 (6 start + 6 stop)" do
  ...
  assert length(start_events) == 6
  assert length(stop_events) == 6
  assert exception_events == []
end
```
Update count assertions (`6 → 7`) and rename test (`12 → 14`, `5 stages → 6 stages`).

**Existing for-loop iterators at lines 45, 202, 260, 356** — update `[:build, :measure, :paginate, :compose, :render]` → `[:build, :compose, :measure, :paginate, :render, :validate]`. Five sites total to grep for `[:build, :measure, :paginate, :compose, :render]`.

**Existing `:no_pages` failed-render test pattern** (lines 235-264) — preserve. After D-12, the assertion at line 243 (`assert meta.page_count == 0`) is still correct because `failing_document/0` (line 25) has `pages: []`, so `length(doc.pages) == 0`. No edit needed.

**New tests to add** (5 tests per D-19, sample shapes):
```elixir
test ":validate stop event fires after :render stop" do
  {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
  events = TelemetryHelper.collect_events()

  event_names = Enum.map(events, fn {event, _m, _meta} -> event end)
  render_stop_idx = Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :render, :stop]))
  validate_stop_idx = Enum.find_index(event_names, &(&1 == [:rendro, :pipeline, :validate, :stop]))
  assert validate_stop_idx > render_stop_idx
end

test "max_pages_exceeded fires from :paginate stage with :validate not started" do
  doc = Rendro.flow(for i <- 1..50, do: Rendro.block(Rendro.text("Line #{i}")))
  doc = put_in(doc.options[:policies], max_pages: 1)

  assert {:error, %Rendro.Error{reason: :max_pages_exceeded, stage: :paginate}} =
           Rendro.Pipeline.run(doc)
  events = TelemetryHelper.collect_events()
  assert stage_events(events, :validate, :start) == []
  assert stage_events(events, :render, :start) == []
end

test "error-path stop_meta carries page_count from doc.pages, not 0" do
  doc = sample_document()  # 1-page doc
  # Force a failure post-build by setting an impossible policy
  doc = put_in(doc.options[:policies], max_bytes: 1)

  assert {:error, %Rendro.Error{reason: :max_bytes_exceeded}} = Rendro.Pipeline.run(doc)
  events = TelemetryHelper.collect_events()

  [validate_stop] = stage_events(events, :validate, :stop)
  {_event, _measurements, meta} = validate_stop
  assert meta.status == :error
  assert meta.page_count == 1  # NOT 0 — regression test for MINOR-15
end

test "error-path stop_meta includes :error map with kind and stage" do
  assert {:error, _} = Rendro.Pipeline.run(failing_document())
  events = TelemetryHelper.collect_events()

  [build_stop] = stage_events(events, :build, :stop)
  {_event, _measurements, meta} = build_stop
  assert meta.status == :error
  assert %{kind: :no_pages, stage: :build} = meta.error
end

test "all stop events carry full D-11 schema" do
  {:ok, _pdf} = Rendro.Pipeline.run(sample_document())
  events = TelemetryHelper.collect_events()

  stop_events = events_by_suffix(events, :stop)
  expected_keys = [:render_id, :document_type, :deterministic, :stage, :status, :page_count, :byte_size]

  for {_event, _measurements, meta} <- stop_events do
    for key <- expected_keys do
      assert Map.has_key?(meta, key), "stop event missing key #{inspect(key)}: #{inspect(meta)}"
    end
  end
end

test "Rendro.Telemetry.stage_names/0 includes :validate in spec order" do
  assert Rendro.Telemetry.stage_names() == [:build, :compose, :measure, :paginate, :render, :validate]
end
```

**Test fixture pattern to reuse** (from `test/rendro/telemetry_test.exs:12-26`):
```elixir
defp sample_document do
  text = %Rendro.Text{content: "Hello!", font: "Helvetica", size: 12, color: {0, 0, 0}}
  block = %Rendro.Block{content: text, x: 10, y: 20}
  page = %Rendro.Page{blocks: [block]}
  %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Telemetry Test"}}
end

defp failing_document do
  %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
end
```

**Helper functions to reuse** (lines 28-38): `events_by_suffix/2`, `stage_events/3`, `render_events/2` — already abstract over event shape, no change needed.

---

### `test/rendro/pipeline/compose_test.exs` and `test/rendro/pipeline/measure_test.exs` (MOD verify-still-passes)

**Primary analog:** themselves.

**Compose test invariants to verify** (from `test/rendro/pipeline/compose_test.exs:7-19`): asserts explicit x/y are preserved. After y-stacking removal, this test still passes because it sets `x: 50, y: 100` explicitly (no `nil` y to fill). The y-stacking removal only affects the `block.y == nil` path, which this test does not exercise. **Predict: passes unchanged.**

**Measure test invariants to verify** (from `test/rendro/pipeline/measure_test.exs:7-48`): asserts `width`/`height` filling for `Text` blocks. After `normalize_row/1` is moved out, these tests still pass because they use raw `%Rendro.Block{content: %Rendro.Text{}}` directly (no row normalization needed). **Predict: passes unchanged.**

If either test does fail, the failure indicates the refactor went deeper than intended — investigate before patching the test.

---

## Shared Patterns

### Telemetry handler test setup
**Source:** `test/rendro/telemetry_test.exs:6-10`
**Apply to:** any new telemetry-aware test (validate_test.exs if it asserts on events; new telemetry_test.exs additions)
```elixir
setup do
  handler_id = TelemetryHelper.attach()
  on_exit(fn -> TelemetryHelper.detach(handler_id) end)
  :ok
end
```

### Stage error envelope construction
**Source:** `lib/rendro/pipeline.ex:109-112` and `lib/rendro/pipeline/paginate.ex:42`
**Apply to:** any new error path in `Validate.run/2` if it ever returns `Rendro.Error.t()` directly (currently returns bare atom; the orchestrator's `span/4` wraps it via `Error.from_stage/3`)
```elixir
{:error, Rendro.Error.from_stage(:validate, :reason, base_meta)}
```
Note: `Validate.run/2` returns `{:error, atom()}` per the established stage convention (D-09 + `build.ex` analog). The orchestrator's `span/4` calls `Error.from_stage(stage, reason, base_meta)` automatically (`pipeline.ex:110`) — no need for `Validate` to wrap manually.

### Stage module `@spec` declaration
**Source:** `lib/rendro/pipeline/{build,compose,measure,paginate,render}.ex` line 6-10 each
**Apply to:** new `Validate` module
```elixir
@spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, term()}
```
Note: arity is 2 (binary + doc), unique among stages. All other stages are `@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}`.

### Telemetry span emission
**Source:** `lib/rendro/pipeline.ex:96-114` (`span/4` helper) and `pipeline.ex:39-44` (`execute_with_telemetry/3`)
**Apply to:** orchestrator only — `Validate` module itself does NOT emit telemetry (the orchestrator's `span(:validate, ...)` wraps `Validate.run/2` from outside, identical to all other stages). **Anti-pattern:** do not call `:telemetry.span/3` from inside `Validate.run/2`.

### Policy reading from `doc.options`
**Source:** `lib/rendro/pipeline.ex:21` and `pipeline.ex:73-91`
**Apply to:** `Validate.check_max_bytes/2`
```elixir
policies = Map.get(doc.options, :policies, [])
max_bytes = Keyword.get(policies, :max_bytes)
```

### `with`-chain for halt-on-first-error
**Source:** `lib/rendro/pipeline/build.ex:7-12` (case-based) and `lib/rendro/pipeline.ex:62-71` (with-based)
**Apply to:** `Validate.run/2`
```elixir
with :ok <- check_a(),
     :ok <- check_b(),
     :ok <- check_c() do
  {:ok, result}
end
```

---

## No Analog Found

| File | Role | Data Flow | Reason | Substitute |
|------|------|-----------|--------|------------|
| `CHANGELOG.md` | doc | static markdown | First changelog in repo (no prior file) | Use Keep-a-Changelog v1.1.0 spec verbatim per D-18 |

---

## Metadata

**Analog search scope:** `lib/rendro/`, `lib/rendro/pipeline/`, `lib/rendro/adapters/`, `test/rendro/`, `test/rendro/pipeline/`, `test/support/`
**Files scanned (read in full):** 13 — `pipeline.ex`, `telemetry.ex`, `error.ex`, `document.ex` (header), `pipeline/{build,compose,measure,paginate,render}.ex`, `adapters/threadline.ex`, `test/rendro/{telemetry,error,policy}_test.exs`, `test/rendro/pipeline/{build,compose,measure,paginate,render}_test.exs`, `test/support/telemetry_helper.ex`
**Pattern extraction date:** 2026-04-26
**Confidence:** HIGH — every excerpt verified against source; no inferred APIs.

# Phase 15: Async Policy Injection + Timeout Audit Closure - Pattern Map

**Mapped:** 2026-04-28
**Scope analyzed:** Existing async adapter boundary, pipeline telemetry lifecycle, Threadline audit mapping, policy tests, docs-contract truth surface

## File Classification

| File | Role | Data Flow | Why it matters |
|---|---|---|---|
| `lib/rendro/adapters/oban/render_worker.ex` | adapter | request-response | Current async boundary; needs policy injection and typed worker-input failures. |
| `lib/rendro/pipeline.ex` | service | request-response | Owns timeout enforcement and the top-level render telemetry lifecycle. |
| `lib/rendro/adapters/threadline.ex` | adapter | event-driven | Converts top-level telemetry into audit actions; timeout closure must land here without a new action family. |
| `test/rendro/policy_test.exs` | test | request-response | Canonical proof that policies work once present on the document. |
| `test/rendro/adapters/threadline_test.exs` | test | event-driven | Canonical proof for audit action mapping and metadata allowlist. |
| `test/docs_contract/integrations_claims_test.exs` | test | request-response | Truth-contract test that currently proves the timeout audit gap. |
| `guides/integrations.md` | docs | request-response | Public adapter contract surface; currently documents the timeout gap and Threadline failure semantics. |
| `test/rendro/telemetry_test.exs` | test | event-driven | Best analog for asserting top-level `:start`/`:stop` closure and metadata shape. |
| `lib/rendro/adapters/mailglass.ex` | adapter | request-response | Best analog for narrow optional-adapter contracts and typed, non-raising boundary errors. |
| `lib/rendro/error.ex` | utility | transform | Canonical typed error constructor used by adapters and pipeline stages. |
| `lib/rendro/telemetry.ex` | config/utility | event-driven | Canonical render event names and metadata schema. |
| `test/support/telemetry_helper.ex` | test utility | event-driven | Canonical helper for collecting live telemetry events. |
| `test/support/mocks.ex` | test utility | event-driven | Canonical cross-process audit capture pattern for adapter tests. |

## Reusable Patterns

### 1. Optional adapter compile guard

**Source:** [lib/rendro/adapters/oban/render_worker.ex](/Users/jon/projects/rendro/lib/rendro/adapters/oban/render_worker.ex:1), [lib/rendro/adapters/threadline.ex](/Users/jon/projects/rendro/lib/rendro/adapters/threadline.ex:1), [lib/rendro/adapters/mailglass.ex](/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex:1)

```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Rendro.Adapters.Oban.RenderWorker do
```

```elixir
if Code.ensure_loaded?(Threadline) do
  defmodule Rendro.Adapters.Threadline do
```

```elixir
if Code.ensure_loaded?(Mailglass) do
  defmodule Rendro.Adapters.Mailglass do
```

**Pattern to preserve**
- Optional adapters stay compile-guarded.
- Phase 15 should not pull Oban or Threadline concerns into core modules.

### 2. Small explicit adapter boundary, not generic pass-through

**Source:** [lib/rendro/adapters/oban/render_worker.ex](/Users/jon/projects/rendro/lib/rendro/adapters/oban/render_worker.ex:10), [lib/rendro/adapters/mailglass.ex](/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex:56)

```elixir
def perform(%Oban.Job{args: %{"module" => module_str, "args" => args, "output_path" => path}}) do
  module = String.to_existing_atom(module_str)
  doc = module.build_document(args)
```

```elixir
@spec attach_pdf(term(), Rendro.Document.t(), String.t()) ::
        term()
        | {:error, Rendro.Error.t()}
        | {:error, {:unrecognized_message_shape, atom() | term()}}
def attach_pdf(email_or_message, document, filename \\ @default_filename)
```

**Pattern to preserve**
- Adapter APIs enumerate accepted inputs explicitly.
- The Oban worker should add a narrow policy surface, not arbitrary job-arg to `doc.options` mutation.
- Public contract should be documented via spec + tests + guide text together.

### 3. Typed, non-raising adapter misuse handling

**Source:** [lib/rendro/adapters/mailglass.ex](/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex:70), [lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:23), [test/docs_contract/integrations_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/integrations_claims_test.exs:47)

```elixir
true ->
  {:error,
   Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}
```

```elixir
defp extract_swoosh(other) when is_struct(other),
  do: {:error, {:unrecognized_message_shape, other.__struct__}}
```

```elixir
assert {:error, %Rendro.Error{reason: {:invalid_email_target, :not_an_email}}} =
         MailglassAdapter.attach_pdf(:not_an_email, document, "invoice.pdf")
```

**Pattern to preserve**
- Misuse returns typed tuples; it does not raise incidental runtime exceptions.
- Caller-facing errors should identify the offending field/value or shape.
- Phase 15 should replace `String.to_existing_atom/1` / pattern-match crash behavior in the worker with the same posture.

### 4. Document policy is the canonical enforcement surface

**Source:** [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:25), [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:88), [test/rendro/policy_test.exs](/Users/jon/projects/rendro/test/rendro/policy_test.exs:4)

```elixir
policies = Map.get(doc.options, :policies, [])
timeout = Keyword.get(policies, :timeout, 30_000)
```

```elixir
if max_pages && length(pages) > max_pages do
  {:error, Error.from_stage(:paginate, :max_pages_exceeded, base_meta)}
else
  :ok
end
```

```elixir
doc = put_in(doc.options[:policies], timeout: 0)
assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.render(doc)
```

**Pattern to preserve**
- Core enforcement already exists in `Rendro.Pipeline`; Phase 15 should inject missing async policy input into `doc.options[:policies]`, not duplicate policy logic in the worker.
- Document-authored policies are currently the only live source of truth, so any async injection must preserve least-surprise semantics.

### 5. Stable top-level telemetry schema

**Source:** [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:27), [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:50), [lib/rendro/telemetry.ex](/Users/jon/projects/rendro/lib/rendro/telemetry.ex:13), [test/rendro/telemetry_test.exs](/Users/jon/projects/rendro/test/rendro/telemetry_test.exs:176)

```elixir
base_meta = %{
  render_id: render_id,
  document_type: :pdf,
  deterministic: deterministic
}
```

```elixir
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
```

```elixir
assert meta.page_count == 1
assert meta.byte_size > 0
assert meta.status == :ok
```

**Pattern to preserve**
- Top-level render stop metadata is already normalized around `render_id`, `document_type`, `deterministic`, `stage`, `status`, `page_count`, `byte_size`, and optional nested `error`.
- Timeout closure should reuse this schema instead of inventing a timeout-only event or metadata parser.

### 6. Threadline uses top-level telemetry only and maps failures into one action family

**Source:** [lib/rendro/adapters/threadline.ex](/Users/jon/projects/rendro/lib/rendro/adapters/threadline.ex:43), [lib/rendro/adapters/threadline.ex](/Users/jon/projects/rendro/lib/rendro/adapters/threadline.ex:73), [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:53)

```elixir
@events [
  [:rendro, :render, :stop],
  [:rendro, :render, :exception]
]
```

```elixir
action =
  if Map.get(metadata, :status) == :error, do: :render_failed, else: :render_succeeded
```

```elixir
metadata
|> Map.take([
  :render_id,
  :stage,
  :status,
  :page_count,
  :byte_size,
  :document_type,
  :deterministic,
  :kind,
  :reason
])
|> Map.put(:duration, Map.get(measurements, :duration))
```

**Pattern to preserve**
- Threadline already has the desired action mapping: success -> `:render_succeeded`, all failures -> `:render_failed`.
- Timeout support should arrive by making top-level timeout produce normal failure metadata, not by adding a new audit action.

### 7. Cross-process adapter testing pattern

**Source:** [test/support/mocks.ex](/Users/jon/projects/rendro/test/support/mocks.ex:13), [test/rendro/adapters/threadline_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/threadline_test.exs:25)

```elixir
@table :rendro_threadline_calls

def threadline_calls do
  pid = test_pid()

  @table
  |> :ets.lookup(pid)
```

```elixir
case Process.get(:"$callers") do
  [pid | _] -> pid
  _ -> self()
end
```

```elixir
calls = Mocks.threadline_calls()
assert [{action, metadata} | _] = calls
```

**Pattern to preserve**
- Adapter tests assume telemetry handlers may run in another process.
- New Oban worker tests should avoid per-process state assumptions and should prefer explicit return-value assertions plus ETS-backed audit capture where needed.

### 8. Telemetry lifecycle verification pattern

**Source:** [test/support/telemetry_helper.ex](/Users/jon/projects/rendro/test/support/telemetry_helper.ex:4), [test/rendro/telemetry_test.exs](/Users/jon/projects/rendro/test/rendro/telemetry_test.exs:58), [test/rendro/telemetry_test.exs](/Users/jon/projects/rendro/test/rendro/telemetry_test.exs:338)

```elixir
handler_id = TelemetryHelper.attach()
on_exit(fn -> TelemetryHelper.detach(handler_id) end)
```

```elixir
starts = render_events(events, :start)
stops = render_events(events, :stop)
assert length(starts) == 1
assert length(stops) == 1
```

```elixir
assert render_stop_idx > last_stage_stop_idx
```

**Pattern to preserve**
- Timeout closure should be verified with the same helper and should assert balanced top-level lifecycle events.
- The most important regression to catch is an unmatched top-level `[:rendro, :render, :start]`.

## Invariants To Preserve

1. Document-authored policies remain authoritative.
Source: [test/rendro/policy_test.exs](/Users/jon/projects/rendro/test/rendro/policy_test.exs:4), [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:25)
Why: Sync and async rendering must not silently diverge for the same document.

2. Core policy enforcement stays in the pure pipeline.
Source: [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:77)
Why: The worker should normalize input into document state, not fork core render semantics.

3. Timeout is a normal failed render, not a new public event family.
Source: [lib/rendro/adapters/threadline.ex](/Users/jon/projects/rendro/lib/rendro/adapters/threadline.ex:73), [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:58)
Why: Operators already look at `:render_failed`; splitting timeout into a new action would create semantic drift.

4. Top-level telemetry metadata stays low-cardinality and shape-stable.
Source: [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:50), [lib/rendro/telemetry.ex](/Users/jon/projects/rendro/lib/rendro/telemetry.ex:17)
Why: Threadline and telemetry tests assume one stable parser.

5. Optional adapters remain truthful, narrow, and compile-guarded.
Source: [test/docs_contract/integrations_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/integrations_claims_test.exs:27)
Why: Phase 15 is a closure phase, not a product-surface expansion.

6. Adapter misuse should fail with typed tuples, not incidental crashes.
Source: [lib/rendro/adapters/mailglass.ex](/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex:27), [test/docs_contract/integrations_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/integrations_claims_test.exs:57)
Why: This is the established adapter contract posture in the repo.

## Likely File Touch Points

| File | Expected touch | Reuse from |
|---|---|---|
| `lib/rendro/adapters/oban/render_worker.ex` | Add job-arg normalization and strict validation for `module`, `args`, `output_path`, and bounded policy keys. Inject only missing policies into `doc.options[:policies]`. Return typed errors instead of crashing on bad inputs. | [lib/rendro/adapters/mailglass.ex](/Users/jon/projects/rendro/lib/rendro/adapters/mailglass.ex:56), [lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:23) |
| `lib/rendro/pipeline.ex` | Close timeout path with a top-level terminal telemetry event whose metadata matches existing `build_stop_meta/3` shape. Keep timeout reason/stage classification in nested `error`. | [lib/rendro/pipeline.ex](/Users/jon/projects/rendro/lib/rendro/pipeline.ex:50), [lib/rendro/telemetry.ex](/Users/jon/projects/rendro/lib/rendro/telemetry.ex:17) |
| `lib/rendro/adapters/threadline.ex` | Likely small or no code change if timeout stop metadata lands correctly; possibly allowlist nested `error` if tests/docs start asserting it directly. | [lib/rendro/adapters/threadline.ex](/Users/jon/projects/rendro/lib/rendro/adapters/threadline.ex:100) |
| `test/rendro/adapters/threadline_test.exs` | Add timeout case asserting `:render_failed` audit emission plus timeout classification metadata, without changing action family. | [test/rendro/adapters/threadline_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/threadline_test.exs:50) |
| `test/rendro/telemetry_test.exs` | Add timeout lifecycle assertion: one top-level `:start`, one top-level `:stop`, no orphaned render span, stable error metadata. | [test/rendro/telemetry_test.exs](/Users/jon/projects/rendro/test/rendro/telemetry_test.exs:58), [test/rendro/telemetry_test.exs](/Users/jon/projects/rendro/test/rendro/telemetry_test.exs:252) |
| `test/rendro/adapters/oban/render_worker_test.exs` | New test file is likely needed; no current analog exists. Cover fill-missing precedence, invalid policy values, unknown policy keys, and no-raise misuse behavior. | [test/rendro/adapters/threadline_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/threadline_test.exs:7), [test/rendro/policy_test.exs](/Users/jon/projects/rendro/test/rendro/policy_test.exs:4) |
| `test/docs_contract/integrations_claims_test.exs` | Flip the current timeout-gap truth test into a timeout-audit-closure proof. Keep compile-guard assertions unchanged. | [test/docs_contract/integrations_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/integrations_claims_test.exs:27) |
| `guides/integrations.md` | Remove the known-limitation section and replace it with truthful timeout-failure audit behavior under the existing Threadline section. Keep allowlist and action mapping language aligned with live code. | [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:53), [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:118) |

## Risks Of Semantic Drift

1. Silent async override of document policies.
Why risky: It would make the same document behave differently in sync vs async flows.
Hotspot: `lib/rendro/adapters/oban/render_worker.ex`

2. Generic job-arg pass-through into `doc.options` or `Rendro.render/2`.
Why risky: It widens the adapter contract beyond the documented bounded-policy surface.
Hotspot: `lib/rendro/adapters/oban/render_worker.ex`

3. Reintroducing raising boundary failures.
Why risky: Current worker crashes come from pattern matching and `String.to_existing_atom/1`; keeping that posture would violate the repo’s typed-adapter-error direction.
Hotspot: `lib/rendro/adapters/oban/render_worker.ex`

4. Emitting a timeout-specific top-level event or audit action.
Why risky: It splits failure semantics and forces Threadline consumers to handle a second family.
Hotspot: `lib/rendro/pipeline.ex`, `lib/rendro/adapters/threadline.ex`, `guides/integrations.md`

5. Publishing fake duration measurements.
Why risky: Timeout values are configuration, not native monotonic durations from `:telemetry.span`.
Hotspot: `lib/rendro/pipeline.ex`

6. Changing Threadline metadata shape incompatibly.
Why risky: Tests and guide text currently assume allowlisted, PII-safe metadata and one `:render_failed` action for all failures.
Hotspot: `lib/rendro/adapters/threadline.ex`, `test/rendro/adapters/threadline_test.exs`, `guides/integrations.md`

7. Leaving the top-level render lifecycle unbalanced on timeout.
Why risky: This is the current observability seam and would keep `OBS-04` partial even if the worker is fixed.
Hotspot: `lib/rendro/pipeline.ex`, `test/rendro/telemetry_test.exs`

8. Docs drifting ahead of code again.
Why risky: `guides/integrations.md` and `test/docs_contract/integrations_claims_test.exs` are used as truth contracts in this repo.
Hotspot: `guides/integrations.md`, `test/docs_contract/integrations_claims_test.exs`

## No Close Analog

| Target | Gap |
|---|---|
| `test/rendro/adapters/oban/render_worker_test.exs` | No existing Oban worker test file or adapter-boundary validation analog in the adapter folder. Reuse Mailglass typed-error posture plus normal ExUnit structure, but the exact worker test surface will be new. |

## Completion Note

Pattern mapping complete for Phase 15. The core guidance is: inject only missing async bounds into `doc.options[:policies]`, keep timeout on the existing top-level `[:rendro, :render, :stop]` failure path, and match Mailglass-style typed adapter failures so closure work does not widen Rendro’s public semantics.

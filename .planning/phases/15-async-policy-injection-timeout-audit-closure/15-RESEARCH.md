# Phase 15: Async Policy Injection + Timeout Audit Closure - Research

**Researched:** 2026-04-28
**Domain:** Elixir optional-adapter boundary validation, Oban worker input normalization, timeout telemetry/audit closure [VERIFIED: repo code; .planning context; hexdocs]
**Confidence:** HIGH [VERIFIED: live code inspection; live test baseline; official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Async policy precedence
- **D-01:** Document-authored policies remain the primary contract. The Oban adapter may inject `max_pages`, `max_bytes`, and `timeout` from job args only when those policies are missing from the document.
- **D-02:** Job args do not silently override document policies by default. Silent override would make the same document behave differently between sync and async paths and would weaken Rendro's least-surprise DX.
- **D-03:** Conflict-fail-fast semantics are not the default for this phase. They are more truthful than silent override, but they add operational friction and retry noise for a closure phase whose primary goal is to restore the originally claimed bounded-async behavior.
- **D-04:** If stricter precedence modes are ever needed later, they must be explicit adapter policy, not hidden default behavior. A future adapter option such as `policy_precedence: :fill_missing | :override | :error_on_conflict` is acceptable as a separate design, not part of this closure phase.

### Async worker boundary contract
- **D-05:** The Oban adapter exposes a small explicit policy surface: `max_pages`, `max_bytes`, and `timeout`. No generic pass-through from job args into `doc.options` or `Rendro.render/2`.
- **D-06:** Known policy keys are validated strictly at the worker boundary. Invalid values or shapes must fail with a typed adapter error rather than raising or being silently ignored.
- **D-07:** Unknown policy keys fail fast if they are presented as Rendro policy input. This protects operators from typo-driven loss of safety bounds.
- **D-08:** Unrelated top-level job metadata is not part of Rendro's policy contract. The worker should stay narrow about what it consumes and should not claim ownership of arbitrary producer metadata beyond the documented required keys.
- **D-09:** The worker boundary should match the stricter, typed-error posture used by other optional adapters. Raw `FunctionClauseError` and `String.to_existing_atom/1` crashes are not acceptable as the primary misuse contract after this phase.

### Timeout audit semantics
- **D-10:** A timeout is a normal failed render, not a synthetic crash class. The primary top-level timeout signal is `[:rendro, :render, :stop]` with `status: :error`, not a custom timeout event or a fake top-level `:exception`.
- **D-11:** Timeout classification lives in metadata, not in a new action or event family. The top-level stop metadata should include the same low-cardinality error shape used elsewhere, with timeout represented as `error.kind: :timeout` and stage `:render`.
- **D-12:** Threadline continues to map timeout to the existing `:render_failed` audit action. Operators should be able to query all failed renders in one place and then filter by timeout subtype when needed.
- **D-13:** Do not introduce `:render_timed_out` or `[:rendro, :render, :timeout]` as the primary public contract in this phase. That would split failure semantics, increase consumer complexity, and violate the project's preference for smaller truthful surfaces.
- **D-14:** The timeout path must close the top-level telemetry lifecycle cleanly. A render timeout should no longer leave a top-level `[:rendro, :render, :start]` without a matching terminal event.

### Telemetry and measurement discipline
- **D-15:** Synthetic timeout stop metadata must preserve the established top-level schema (`render_id`, `document_type`, `deterministic`, `stage`, `status`, `page_count`, `byte_size`, optional `error`) so downstream handlers do not need a timeout-specific parser.
- **D-16:** Any timeout measurement emitted on the synthetic top-level stop must respect telemetry conventions. Do not publish raw millisecond timeout values as if they were native monotonic duration measurements.

### Downstream agent posture
- **D-17:** For this phase, downstream agents should default to recommendation-first synthesis: collapse the researched trade space into one coherent default unless a choice would materially change public semantics beyond the locked closure target.
- **D-18:** The preferred decision lens for this phase is: smallest truthful contract, boundary validation first, deterministic behavior, and least surprise for both library users and operators.

### the agent's Discretion
- Exact typed-error tuple shapes for invalid Oban worker inputs, as long as they are explicit, non-raising, and document the offending policy key or field.
- Whether policy input lives at the top level or under a nested `"policies"` key, as long as the public docs and tests make the accepted shape explicit and the final contract remains narrow.
- Whether Threadline should additionally forward a convenience `reason: :timeout` field alongside the nested `error` map, as long as `:render_failed` remains the primary action and the top-level stop metadata stays stable.

### Deferred Ideas (OUT OF SCOPE)
- Explicit configurable precedence modes for async policy conflicts (`:override`, `:error_on_conflict`) — useful, but broader than this closure phase.
- A dedicated timeout-specific audit action or event family — only worth considering if future operators demonstrate a real need that metadata filtering cannot satisfy.
- Generalized job-arg schema or a behavior/protocol for async adapter input normalization — out of scope for this closure phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-04 | Maintainer can use an optional job-processing adapter pattern for bounded asynchronous rendering. [VERIFIED: .planning/REQUIREMENTS.md] | Inject only `max_pages`, `max_bytes`, and `timeout` from validated job args into missing document policies before `Rendro.render/2`. [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/oban/render_worker.ex; lib/rendro/pipeline.ex] |
| ADPT-05 | Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling. [VERIFIED: .planning/REQUIREMENTS.md] | Close the Threadline timeout audit gap so the integrations guide can stop carrying a timeout-limitation caveat. [VERIFIED: guides/integrations.md; test/docs_contract/integrations_claims_test.exs] |
| OBS-04 | Operator can enforce policy bounds for max pages, max output bytes, and render timeouts. [VERIFIED: .planning/REQUIREMENTS.md] | Preserve core policy enforcement in `Rendro.Pipeline` and restore the missing async handoff plus timeout terminal event/audit evidence. [VERIFIED: test/rendro/policy_test.exs; lib/rendro/pipeline.ex; .planning/v1.0-MILESTONE-AUDIT.md] |
</phase_requirements>

## Summary

Phase 15 is a narrow adapter-and-observability closure phase, not a new async API phase. The live code still shows the exact two seams called out by the roadmap and milestone audit: `Rendro.Adapters.Oban.RenderWorker` builds a document and calls `Rendro.render(doc, output: path)` without policy reinjection, and `Rendro.Pipeline.run/1` returns `{:error, %Rendro.Error{reason: :timeout}}` from the `Task.yield/2 || Task.shutdown/1` branch without emitting a terminal top-level render event. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex; lib/rendro/pipeline.ex; .planning/v1.0-MILESTONE-AUDIT.md]

The repo already has the right core primitives to close both gaps without widening scope. Core policy enforcement for `max_pages`, `max_bytes`, and `timeout` is live and passing in `Rendro.Pipeline`, Threadline already maps top-level `[:rendro, :render, :stop]` failures to `:render_failed`, and the current docs-contract test proves the remaining timeout limitation truthfully. [VERIFIED: test/rendro/policy_test.exs; lib/rendro/adapters/threadline.ex; test/docs_contract/integrations_claims_test.exs]

One additional implementation seam matters for planning: even after adding a synthetic timeout `[:rendro, :render, :stop]`, Threadline currently drops nested `:error` metadata because its allowlist only takes top-level keys such as `:render_id`, `:stage`, `:status`, `:page_count`, `:byte_size`, `:document_type`, `:deterministic`, `:kind`, and `:reason`. The planner should therefore treat Threadline metadata forwarding as part of the timeout closure, not as a postscript. [VERIFIED: lib/rendro/adapters/threadline.ex; lib/rendro/pipeline.ex]

**Primary recommendation:** Keep the contract narrow: validate a dedicated Oban policy input shape, fill only missing document policies, emit a synthetic top-level timeout `:stop` with the established schema, and forward timeout subtype metadata through Threadline under the existing `:render_failed` action. [VERIFIED: 15-CONTEXT.md; lib/rendro/pipeline.ex; lib/rendro/adapters/threadline.ex]

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and avoid introducing hard dependencies on Phoenix, Oban, or admin tooling. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Prefer optional dependency guards plus compile/runtime checks for integrations. [VERIFIED: AGENTS.md]
- Preserve the architecture contract `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: AGENTS.md]
- No project-local custom skills are present for this repo. [VERIFIED: repo scan of `.claude/skills` and `.agents/skills`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Oban job arg parsing and policy normalization | API / Backend | — | The worker boundary owns translation from `%Oban.Job{args: ...}` into Rendro’s document contract; the core pipeline should continue receiving a normal `%Rendro.Document{}`. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex; https://hexdocs.pm/oban/Oban.Worker.html] |
| Policy enforcement (`max_pages`, `max_bytes`, `timeout`) | API / Backend | — | Policy checks already live in `Rendro.Pipeline` and should not be duplicated in the adapter. [VERIFIED: lib/rendro/pipeline.ex; test/rendro/policy_test.exs] |
| Timeout terminal telemetry emission | API / Backend | — | The missing lifecycle closure happens in `Pipeline.run/1`, above all stage spans and before Threadline can observe a failure. [VERIFIED: lib/rendro/pipeline.ex; https://hexdocs.pm/telemetry/telemetry.html] |
| Audit forwarding to Threadline | API / Backend | — | Threadline subscribes only to top-level render events and converts them into `Threadline.record_action/2` calls. [VERIFIED: lib/rendro/adapters/threadline.ex; guides/integrations.md] |
| Oban persistence and scheduling | Database / Storage | API / Backend | Oban stores and executes jobs, but this phase does not need database-layer changes because the closure is purely about worker argument handling and execution-time telemetry. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][VERIFIED: 15-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime and stdlib for the adapter, pipeline, and tests. [VERIFIED: `elixir --version`; mix.exs] | The repo is pinned to `~> 1.19` and the current machine is already on `1.19.5`, so Phase 15 should plan against the installed/runtime-matched version. [VERIFIED: mix.exs; `elixir --version`] |
| Erlang/OTP | 28 | BEAM runtime beneath Elixir. [VERIFIED: `elixir --version`] | The local environment and project stack both target OTP 28, which keeps test and timeout behavior aligned with current repo evidence. [VERIFIED: AGENTS.md; `elixir --version`] |
| Oban | 2.21.1 | Optional background job worker contract for `%Oban.Job{}` and worker `perform/1`. [VERIFIED: mix.lock; `mix hex.info oban`; https://hexdocs.pm/oban/Oban.Worker.html] | The project is explicitly pinned to `2.21.1`; Hex shows `2.22.0` released on 2026-04-28, so upgrading during this closure phase would widen scope unnecessarily. [VERIFIED: AGENTS.md; `mix hex.info oban`; https://hex.pm/api/packages/oban; https://hex.pm/api/packages/oban/releases/2.21.1] |
| telemetry | 1.4.1 | Top-level and stage lifecycle instrumentation via `:telemetry.span/3`. [VERIFIED: mix.lock; `mix hex.info telemetry`; https://hexdocs.pm/telemetry/telemetry.html] | `1.4.1` is both the locked and latest Hex release, so the planner can rely on the current span semantics without version drift. [VERIFIED: `mix hex.info telemetry`; https://hex.pm/api/packages/telemetry] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | 1.8.5 | Optional integration surface only; not part of the Phase 15 implementation path. [VERIFIED: AGENTS.md; `mix hex.info phoenix`; https://hex.pm/api/packages/phoenix] | Use only to preserve optional-adapter conventions and avoid coupling Phase 15 work to Phoenix-specific concerns. [VERIFIED: AGENTS.md; 15-CONTEXT.md] |
| ExUnit | bundled with Elixir 1.19.5 | Verification harness for worker, telemetry, and docs-contract proof. [VERIFIED: repo test suite; `mix test` runs] | Use for the new worker-path, timeout-stop, and docs-contract regressions. [VERIFIED: test tree; live `mix test` runs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Project-pinned Oban `2.21.1` | Upgrade to Oban `2.22.0` | Latest exists, but Phase 15 is a closure phase and none of the required fixes depend on `2.22.0`; upgrading would mix behavior change with dependency churn. [VERIFIED: https://hex.pm/api/packages/oban; mix.lock] |
| Existing `:render_failed` Threadline action with subtype metadata | New `:render_timed_out` action | A new action would split failure semantics and contradict locked Decisions D-10 through D-13. [VERIFIED: 15-CONTEXT.md] |
| Explicit policy surface (`max_pages`, `max_bytes`, `timeout`) | Generic job-arg pass-through into `doc.options` or `Rendro.render/2` | Generic pass-through is broader, harder to validate, and directly contradicts locked Decisions D-05 through D-08. [VERIFIED: 15-CONTEXT.md] |

**Dependency verification:** `mix hex.info oban` reports locked `2.21.1` while Hex API reports latest `2.22.0` published on 2026-04-28T09:13:03Z; `mix hex.info telemetry` and Hex API both report `1.4.1` published on 2026-03-09T09:46:08Z; `mix hex.info phoenix` and Hex API both report `1.8.5` published on 2026-03-05T15:22:23Z. [VERIFIED: `mix hex.info oban`; `mix hex.info telemetry`; `mix hex.info phoenix`; https://hex.pm/api/packages/oban; https://hex.pm/api/packages/oban/releases/2.21.1; https://hex.pm/api/packages/telemetry; https://hex.pm/api/packages/phoenix]

## Architecture Patterns

### System Architecture Diagram

```text
Oban enqueue
  |
  v
%Oban.Job{args}
  |
  v
Rendro.Adapters.Oban.RenderWorker.perform/1
  |
  +--> validate required worker fields (`module`, `args`, `output_path`) [typed adapter errors]
  |
  +--> normalize explicit policy input (`max_pages`, `max_bytes`, `timeout`)
  |       |
  |       +--> reject unknown/invalid policy keys
  |       +--> fill only missing document policies
  |
  v
module.build_document(args)
  |
  v
Rendro.render(doc, output: path)
  |
  v
Rendro.Pipeline.run/1
  |
  +--> Task.async(...)
  +--> Task.yield(timeout) || Task.shutdown(task)
          |
          +--> {:ok, result} --------> normal top-level `[:rendro, :render, :stop]`
          |
          +--> nil ------------------> synthetic top-level `[:rendro, :render, :stop]`
                                        status: :error
                                        error.kind: :timeout
  |
  v
Rendro.Adapters.Threadline.handle_event/4
  |
  +--> `:render_succeeded` or `:render_failed`
  +--> preserve timeout subtype metadata in forwarded payload
  |
  v
Threadline.record_action/2
```

The diagram above matches the live code boundaries and the locked phase decisions: adapter validation at the worker edge, policy enforcement in the pipeline, and audit forwarding from top-level render telemetry only. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex; lib/rendro/pipeline.ex; lib/rendro/adapters/threadline.ex; 15-CONTEXT.md]

### Recommended Project Structure

```text
lib/
├── rendro/adapters/oban/render_worker.ex   # Validate/normalize Oban args and inject missing policies
├── rendro/pipeline.ex                      # Close timeout lifecycle at the top-level render span
└── rendro/adapters/threadline.ex           # Forward timeout subtype metadata under :render_failed

test/
├── rendro/adapters/oban/render_worker_test.exs   # New worker-path regression proof
├── rendro/adapters/threadline_test.exs           # Timeout audit forwarding assertions
├── rendro/telemetry_test.exs                     # Terminal top-level timeout stop proof
└── docs_contract/integrations_claims_test.exs    # Guide contract flips from limitation to closure

guides/
└── integrations.md                        # Remove timeout limitation section and document final contract
```

### Pattern 1: Narrow Worker Boundary Normalization
**What:** Accept one explicit worker job shape, validate it, normalize only the known policy keys, and merge them into `doc.options[:policies]` only when the document has not already set them. [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/oban/render_worker.ex; lib/rendro/pipeline.ex]
**When to use:** Any optional adapter that translates external job/process input into Rendro core contracts. [VERIFIED: AGENTS.md; 15-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html and .planning/phases/15-async-policy-injection-timeout-audit-closure/15-CONTEXT.md
def perform(%Oban.Job{args: args}) do
  with {:ok, module} <- fetch_module(args),
       {:ok, build_args} <- fetch_build_args(args),
       {:ok, output_path} <- fetch_output_path(args),
       {:ok, injected_policies} <- fetch_policies(args),
       %Rendro.Document{} = doc <- module.build_document(build_args),
       doc <- inject_missing_policies(doc, injected_policies),
       {:ok, _pdf} <- Rendro.render(doc, output: output_path) do
    :ok
  else
    {:error, {:invalid_job_args, _, _}} = error -> error
    {:error, %Rendro.Error{} = error} -> {:error, error.reason}
  end
end
```

### Pattern 2: Synthetic Top-Level Timeout Stop
**What:** When the task times out, emit a top-level `[:rendro, :render, :stop]` with the existing schema and `error.kind: :timeout` before returning the timeout error. [VERIFIED: 15-CONTEXT.md; lib/rendro/pipeline.ex][CITED: https://hexdocs.pm/telemetry/telemetry.html][CITED: https://hexdocs.pm/elixir/Task.html#yield/2]
**When to use:** Only for the top-level render span, because the timeout happens outside the span callback’s normal return path. [VERIFIED: lib/rendro/pipeline.ex]
**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/Task.html#yield/2 and https://hexdocs.pm/telemetry/telemetry.html#span-3
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} ->
    result

  nil ->
    metadata = %{
      render_id: base_meta.render_id,
      document_type: base_meta.document_type,
      deterministic: base_meta.deterministic,
      stage: :render,
      status: :error,
      page_count: length(doc.pages),
      byte_size: 0,
      error: %{kind: :timeout, stage: :render}
    }

    :telemetry.execute([:rendro, :render, :stop], %{}, metadata)
    {:error, Error.from_stage(:render, :timeout, base_meta)}
end
```

### Pattern 3: Error Metadata Forwarding Through Audit Allowlists
**What:** Keep the top-level stop schema stable and update the Threadline allowlist to preserve the nested `:error` payload, with `reason: :timeout` as optional convenience rather than the primary contract. [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/threadline.ex; lib/rendro/pipeline.ex]
**When to use:** Any telemetry-to-audit adapter that already enforces PII-safe allowlists. [VERIFIED: guides/integrations.md; lib/rendro/adapters/threadline.ex]
**Example:**
```elixir
# Source: lib/rendro/adapters/threadline.ex and .planning/phases/15-async-policy-injection-timeout-audit-closure/15-CONTEXT.md
metadata
|> Map.take([
  :render_id,
  :stage,
  :status,
  :page_count,
  :byte_size,
  :document_type,
  :deterministic,
  :error
])
|> Map.put(:duration, Map.get(measurements, :duration))
```

### Anti-Patterns to Avoid
- **Generic job-arg pass-through:** It violates the locked narrow-contract decision and makes typo-driven safety loss harder to detect. [VERIFIED: 15-CONTEXT.md]
- **Silent async override of document-authored policies:** It would make sync and async renders diverge for the same document. [VERIFIED: 15-CONTEXT.md]
- **New timeout event family or new audit action:** It would split failure semantics and add consumer complexity for no milestone gain. [VERIFIED: 15-CONTEXT.md]
- **Publishing fake duration measurements on synthetic timeout stop:** `:telemetry.span/3` durations are monotonic timing data; a raw timeout limit is not a substitute. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: 15-CONTEXT.md]
- **Leaving `String.to_existing_atom/1` and function-clause crashes as the misuse contract:** The current worker does this now, and the phase explicitly rejects it. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex; 15-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async policy transport | A generic adapter option mapper into `doc.options` | One explicit worker policy parser for `max_pages`, `max_bytes`, and `timeout` | The explicit surface is smaller, testable, and aligned with the locked contract. [VERIFIED: 15-CONTEXT.md] |
| Timeout audit classification | A new timeout-specific event family or action family | Existing top-level `[:rendro, :render, :stop]` plus `:render_failed` with subtype metadata | The existing surfaces already express failed renders; the missing piece is lifecycle closure plus metadata forwarding. [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/threadline.ex] |
| Error reporting from worker misuse | Ad hoc raises or incidental pattern-match crashes | Typed adapter errors that identify the offending field or policy key | The repo already treats structured errors and typed boundary failures as product behavior. [VERIFIED: AGENTS.md; 15-CONTEXT.md; lib/rendro/error.ex] |
| Separate async policy engine | New policy enforcement logic in the Oban adapter | Existing `Rendro.Pipeline` policy enforcement | Core policy enforcement is already passing and should remain the single enforcement point. [VERIFIED: test/rendro/policy_test.exs; lib/rendro/pipeline.ex] |

**Key insight:** Phase 15 is a wiring repair, not a capability invention; most of the implementation should route existing core policy and telemetry behavior through missing adapter/top-level seams rather than add new abstractions. [VERIFIED: 15-CONTEXT.md; .planning/v1.0-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Fixing timeout lifecycle without fixing audit payload shape
**What goes wrong:** A synthetic top-level timeout stop is emitted, but Threadline still cannot tell why the render failed because nested `:error` metadata is dropped. [VERIFIED: lib/rendro/pipeline.ex; lib/rendro/adapters/threadline.ex]
**Why it happens:** The pipeline uses nested `error: %{kind: ..., stage: ...}` while Threadline currently allowlists only flat keys and does not take `:error`. [VERIFIED: lib/rendro/pipeline.ex; lib/rendro/adapters/threadline.ex]
**How to avoid:** Treat Threadline allowlist updates as part of the timeout closure and add explicit timeout-subtype assertions in adapter tests. [VERIFIED: 15-CONTEXT.md; current test gaps]
**Warning signs:** Timeout renders create audit rows with `status: :error` but no subtype field available for filtering. [VERIFIED: inferred from current code paths]

### Pitfall 2: Reintroducing async-only semantic drift
**What goes wrong:** The async worker silently overrides document-authored `max_pages`, `max_bytes`, or `timeout`. [VERIFIED: 15-CONTEXT.md]
**Why it happens:** Job-arg normalization is implemented as a blind merge instead of a fill-missing merge. [VERIFIED: 15-CONTEXT.md]
**How to avoid:** Keep document-authored policies authoritative and inject job policies only when the document is missing them. [VERIFIED: 15-CONTEXT.md]
**Warning signs:** The same document produces different outcomes between direct `Rendro.render/2` and worker execution with identical content. [VERIFIED: 15-CONTEXT.md]

### Pitfall 3: Turning worker misuse into crash/retry noise
**What goes wrong:** Invalid job shapes trigger `String.to_existing_atom/1`, bad pattern matches, or `FunctionClauseError`, causing retries without actionable operator feedback. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex; 15-CONTEXT.md]
**Why it happens:** The current worker has a single happy-path clause and no validation layer. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex]
**How to avoid:** Validate required fields, policy shapes, and allowed keys before calling `build_document/1` or `Rendro.render/2`, and return typed adapter errors on failure. [VERIFIED: 15-CONTEXT.md]
**Warning signs:** Oban jobs fail before building a document, and the only error evidence is a stacktrace or retry count. [VERIFIED: current worker structure]

### Pitfall 4: Emitting misleading synthetic measurements
**What goes wrong:** The timeout branch publishes the timeout limit as a `:duration`, making dashboards look like they contain measured elapsed time when they do not. [VERIFIED: 15-CONTEXT.md][CITED: https://hexdocs.pm/telemetry/telemetry.html]
**Why it happens:** The normal `:telemetry.span/3` stop measurements are unavailable on the timeout branch, so it is tempting to fabricate them. [VERIFIED: lib/rendro/pipeline.ex]
**How to avoid:** Emit only metadata on the synthetic stop or clearly limited measurements; do not pretend the timeout threshold is a measured duration. [VERIFIED: 15-CONTEXT.md]
**Warning signs:** Timeout stop events always report the configured timeout value, even when the actual elapsed runtime is unknown. [VERIFIED: 15-CONTEXT.md]

### Pitfall 5: Closing the runtime seam without closing the docs seam
**What goes wrong:** The code starts auditing timeouts, but `guides/integrations.md` and `test/docs_contract/integrations_claims_test.exs` still claim the limitation exists. [VERIFIED: guides/integrations.md; test/docs_contract/integrations_claims_test.exs]
**Why it happens:** The current docs-contract suite is built specifically to keep the limitation truthful until Phase 15 lands. [VERIFIED: test/docs_contract/integrations_claims_test.exs; .planning/v1.0-MILESTONE-AUDIT.md]
**How to avoid:** Plan the guide update and docs-contract flip as first-class deliverables, not cleanup. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md]
**Warning signs:** Tests still pass only because they assert `Mocks.threadline_calls() == []` on timeout. [VERIFIED: test/docs_contract/integrations_claims_test.exs]

## Code Examples

Verified patterns from official and repo sources:

### `Task.yield/2 || Task.shutdown/1` Timeout Branch
```elixir
# Source: https://hexdocs.pm/elixir/Task.html#yield/2
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} -> result
  nil -> {:error, :timeout}
end
```

### `:telemetry.span/3` Stop Metadata Contract
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html#span-3
:telemetry.span([:rendro, :render], start_meta, fn ->
  result = run_stages(doc)
  {result, stop_meta}
end)
```

### Current Worker Gap That Phase 15 Must Close
```elixir
# Source: lib/rendro/adapters/oban/render_worker.ex
def perform(%Oban.Job{args: %{"module" => module_str, "args" => args, "output_path" => path}}) do
  module = String.to_existing_atom(module_str)
  doc = module.build_document(args)
  Rendro.render(doc, output: path)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Async worker assumes documents already contain policies. [VERIFIED: lib/rendro/adapters/oban/render_worker.ex] | Current recommended approach is explicit worker-side policy normalization that fills missing document policies only. [VERIFIED: 15-CONTEXT.md] | Locked for Phase 15 on 2026-04-28. [VERIFIED: 15-CONTEXT.md] | Restores truthful bounded-async behavior without adding a generalized async API. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md] |
| Timeout path returns an error before any top-level terminal render event is emitted. [VERIFIED: lib/rendro/pipeline.ex] | Current recommended approach is a synthetic top-level `[:rendro, :render, :stop]` with `status: :error` and `error.kind: :timeout`. [VERIFIED: 15-CONTEXT.md] | Locked for Phase 15 on 2026-04-28. [VERIFIED: 15-CONTEXT.md] | Closes the audit lifecycle and lets Threadline observe timeouts as ordinary failed renders. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md] |
| Threadline guide truthfully documents a timeout-audit limitation. [VERIFIED: guides/integrations.md; test/docs_contract/integrations_claims_test.exs] | After Phase 15, the guide should document timeout closure under the existing `:render_failed` action. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md] | Planned for Phase 15. [VERIFIED: .planning/ROADMAP.md] | `ADPT-05` can move from partial to done without relying on stale milestone summaries. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- The current “Known limitation: pipeline timeouts are not audited” guide section becomes outdated once Phase 15 lands and must be removed or rewritten in the same slice. [VERIFIED: guides/integrations.md; .planning/ROADMAP.md]

## Assumptions Log

All material claims in this research were verified from repo artifacts, live test runs, local runtime inspection, Hex package metadata, or official docs. [VERIFIED: this research session]

## Open Questions

1. **Should worker policy input live at the top level or under a nested `"policies"` key?**
   - What we know: The phase context allows either shape, and the same context explicitly prefers a narrow documented contract. [VERIFIED: 15-CONTEXT.md]
   - What's unclear: The final docs ergonomics and how much backward-compatibility is desired for existing unpublished examples. [VERIFIED: 15-CONTEXT.md]
   - Recommendation: Prefer a nested `"policies"` map because it is clearer, easier to validate, and keeps unrelated top-level job metadata out of Rendro’s policy surface. [VERIFIED: 15-CONTEXT.md]

2. **Should Threadline forward nested `:error` only, or nested `:error` plus convenience `:reason`?**
   - What we know: The locked contract requires timeout classification in metadata and leaves a convenience `reason: :timeout` field to discretion. [VERIFIED: 15-CONTEXT.md]
   - What's unclear: Whether downstream consumers need flatter keys for filtering. [VERIFIED: 15-CONTEXT.md]
   - Recommendation: Make nested `:error` the canonical contract and add flat `:reason` only if guide examples or downstream query ergonomics clearly benefit. [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/threadline.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Building and testing Phase 15 changes | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Erlang/OTP | BEAM runtime for render, task, and telemetry behavior | ✓ [VERIFIED: `elixir --version`] | 28 / erts-16.3 [VERIFIED: `elixir --version`] | — |
| Mix | Running tests and Hex metadata inspection | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |

**Missing dependencies with no fallback:**
- None identified for Phase 15 planning. Oban, Threadline, and Mailglass behavior needed by tests is exercised through local deps and test stubs rather than external services. [VERIFIED: mix.exs; test/support/mocks.ex; live `mix test` runs]

**Missing dependencies with fallback:**
- None. [VERIFIED: this research session]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: repo test suite; `mix test`; `elixir --version`] |
| Config file | none — default Mix/ExUnit setup [VERIFIED: repo scan] |
| Quick run command | `mix test test/rendro/policy_test.exs test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` [VERIFIED: live test runs] |
| Full suite command | `mix test` [VERIFIED: repo structure; Mix conventions] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADPT-04 | Worker injects validated `max_pages`, `max_bytes`, and `timeout` into missing document policies before render. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md] | unit/integration | `mix test test/rendro/adapters/oban/render_worker_test.exs` | ❌ Wave 0 [VERIFIED: repo scan] |
| ADPT-05 | Timeout failures reach Threadline as `:render_failed` audit rows under the existing action family. [VERIFIED: .planning/ROADMAP.md; 15-CONTEXT.md] | integration + docs contract | `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` | ✅ exists, but needs new assertions [VERIFIED: repo scan] |
| OBS-04 | Timeout closes the top-level telemetry lifecycle with a terminal `[:rendro, :render, :stop]` and timeout subtype metadata. [VERIFIED: 15-CONTEXT.md] | telemetry/integration | `mix test test/rendro/telemetry_test.exs test/rendro/policy_test.exs` | ✅ exists, but timeout-stop proof is missing [VERIFIED: repo scan; file inspection] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/adapters/threadline_test.exs test/rendro/telemetry_test.exs test/docs_contract/integrations_claims_test.exs` [VERIFIED: planned phase surfaces]
- **Per wave merge:** `mix test` [VERIFIED: Mix conventions]
- **Phase gate:** Full suite green plus guide/docs-contract assertions updated before `/gsd-verify-work`. [VERIFIED: AGENTS.md; .planning/ROADMAP.md]

### Wave 0 Gaps
- [ ] `test/rendro/adapters/oban/render_worker_test.exs` — missing proof for worker-path policy injection, unknown-key rejection, and typed invalid-input failures. [VERIFIED: repo scan]
- [ ] `test/rendro/telemetry_test.exs` — add a timeout-specific top-level lifecycle test asserting start + synthetic stop and no dangling render span. [VERIFIED: file inspection]
- [ ] `test/rendro/adapters/threadline_test.exs` — add timeout audit assertions that verify `:render_failed` and preserved subtype metadata. [VERIFIED: file inspection]
- [ ] `test/docs_contract/integrations_claims_test.exs` — flip the current timeout-limitation test into timeout-closure proof. [VERIFIED: file inspection]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | — |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | — |
| V5 Input Validation | yes [VERIFIED: 15-CONTEXT.md; lib/rendro/adapters/oban/render_worker.ex] | Strict worker-boundary validation of required fields, policy keys, and policy value shapes. [VERIFIED: 15-CONTEXT.md] |
| V6 Cryptography | no [VERIFIED: phase scope] | — |

### Known Threat Patterns for this Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed or typoed Oban policy input disables safety bounds | Tampering | Reject unknown policy keys and invalid shapes with typed adapter errors before render. [VERIFIED: 15-CONTEXT.md] |
| Missing timeout audit rows create repudiation gaps for failed renders | Repudiation | Emit a terminal top-level render stop on timeout and forward timeout subtype metadata through Threadline. [VERIFIED: .planning/ROADMAP.md; lib/rendro/pipeline.ex; lib/rendro/adapters/threadline.ex] |
| Unbounded async render retries amplify cost on invalid worker input | Denial of Service | Fail fast at the worker boundary instead of raising deep in the job path, and preserve core timeout/page/byte policies. [VERIFIED: 15-CONTEXT.md; lib/rendro/pipeline.ex; lib/rendro/adapters/oban/render_worker.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/15-async-policy-injection-timeout-audit-closure/15-CONTEXT.md` - locked scope, precedence rules, timeout semantics, and discretion areas. [VERIFIED: repo file]
- `.planning/REQUIREMENTS.md` - authoritative requirement descriptions and pending status for `ADPT-04`, `ADPT-05`, and `OBS-04`. [VERIFIED: repo file]
- `.planning/ROADMAP.md` - Phase 15 goal and success criteria. [VERIFIED: repo file]
- `.planning/v1.0-MILESTONE-AUDIT.md` - authoritative statement of the two open seams. [VERIFIED: repo file]
- `lib/rendro/adapters/oban/render_worker.ex` - current worker gap and current crash-prone boundary behavior. [VERIFIED: repo file]
- `lib/rendro/pipeline.ex` - current timeout branch and top-level telemetry lifecycle gap. [VERIFIED: repo file]
- `lib/rendro/adapters/threadline.ex` - current audit event mapping and metadata allowlist. [VERIFIED: repo file]
- `test/rendro/policy_test.exs`, `test/rendro/adapters/threadline_test.exs`, `test/docs_contract/integrations_claims_test.exs` - live proof of current behavior. [VERIFIED: repo files; live `mix test` runs]
- `https://hexdocs.pm/oban/Oban.Worker.html` - worker `perform/1`, `new/2`, and timeout callback semantics. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- `https://hexdocs.pm/telemetry/telemetry.html` - `:telemetry.span/3` semantics and stop metadata contract. [CITED: https://hexdocs.pm/telemetry/telemetry.html]
- `https://hexdocs.pm/elixir/Task.html#yield/2` - canonical `Task.yield/2 || Task.shutdown/1` timeout handling pattern. [CITED: https://hexdocs.pm/elixir/Task.html#yield/2]
- `https://hex.pm/api/packages/oban`, `https://hex.pm/api/packages/oban/releases/2.21.1`, `https://hex.pm/api/packages/telemetry`, `https://hex.pm/api/packages/phoenix` - current/latest package versions and publish dates. [CITED: https://hex.pm/api/packages/oban][CITED: https://hex.pm/api/packages/oban/releases/2.21.1][CITED: https://hex.pm/api/packages/telemetry][CITED: https://hex.pm/api/packages/phoenix]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: this research session]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were checked against the local runtime, lockfile, `mix hex.info`, and Hex package APIs. [VERIFIED: this research session]
- Architecture: HIGH - all recommendations map directly onto the live implementation seams and locked phase decisions. [VERIFIED: repo files; 15-CONTEXT.md]
- Pitfalls: HIGH - each pitfall is grounded in current code, current tests, or explicit locked decisions. [VERIFIED: repo files; live tests; 15-CONTEXT.md]

**Research date:** 2026-04-28 [VERIFIED: system date]
**Valid until:** 2026-05-05 for package-version currency, 2026-05-28 for repo-architecture guidance if no new roadmap changes land first. [VERIFIED: package recency; stable repo scope]

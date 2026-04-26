---
phase: 05-early-ecosystem-recipes
reviewed: 2026-04-26T17:46:05Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/rendro/audit.ex
  - lib/rendro/adapters/threadline.ex
  - lib/rendro/adapters/mailglass.ex
  - test/rendro/adapters/threadline_test.exs
  - test/rendro/adapters/mailglass_test.exs
  - test/support/mocks.ex
  - test/test_helper.exs
findings:
  critical: 2
  warning: 6
  info: 4
  total: 12
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-26T17:46:05Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The phase 05 ecosystem-adapter code is generally well-structured: optional
modules guarded by `Code.ensure_loaded?/1`, a clear `Rendro.Audit` behavior,
and PII-conscious telemetry forwarding to Threadline. The Threadline adapter
is in good shape and its tests are tight.

The Mailglass adapter, however, contains two correctness defects in the
Mailglass-message handling path that can either silently drop user data or
crash the process at runtime, and several quality issues around its
fallback/best-effort branches. Additional warnings cover gaps in audit
coverage (timeouts), a fragile struct-detection heuristic, and a latent
test-helper bug in `test_pid/0` that will misroute captured calls when more
than one process layer separates the caller from the test.

## Critical Issues

### CR-01: `extract_swoosh/1` fallback silently drops the caller's message and replaces it with an empty Swoosh email

**File:** `lib/rendro/adapters/mailglass.ex:97-100`

**Issue:** When `attach_to_mailglass/2` is given a `Mailglass.*` struct that
has neither a `:swoosh` nor an `:email` field, `extract_swoosh/1` falls
through to the `defp extract_swoosh(_), do: %Swoosh.Email{}` clause. The
adapter then attaches the rendered PDF to a brand-new empty `%Swoosh.Email{}`
and (via `put_swoosh/2`'s final `true ->` arm at line 113-114) returns that
bare email, completely discarding the caller's original message — including
any `:meta`, recipients, subject, or body the caller had set.

This is worst-case data loss: the call appears to succeed
(no `{:error, _}`), but the rendered PDF is attached to a wrong, empty
email and the user's email content is gone. Combined with the silent
type change in CR-02, this is a footgun for anyone using a non-canonical
Mailglass-style wrapper.

**Fix:** Refuse to handle unknown wrapper shapes instead of fabricating an
empty email. Return `{:error, ...}` so the caller can decide:

```elixir
defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%Swoosh.Email{} = email), do: {:ok, email}
defp extract_swoosh(other), do: {:error, {:unrecognized_message_shape, other.__struct__}}

defp attach_to_mailglass(message, attachment) do
  case extract_swoosh(message) do
    {:ok, swoosh} ->
      updated = Swoosh.Email.attachment(swoosh, attachment)
      put_swoosh(message, updated)

    {:error, _} = err ->
      err
  end
end
```

Update `attach_pdf/3`'s `@spec` and call site to propagate the new error.

---

### CR-02: `attach_binary/3` "best-effort" fallback will crash, not degrade

**File:** `lib/rendro/adapters/mailglass.ex:64-67`

**Issue:** The final `cond` branch claims:

```elixir
true ->
  # Best-effort: assume the value behaves like a Swoosh email.
  Swoosh.Email.attachment(email_or_message, attachment)
```

But `Swoosh.Email.attachment/2` (both the real implementation and the test
stub at `test/support/mocks.ex:146-148`) is defined with a head that
pattern-matches `%Swoosh.Email{} = email`. By the time control reaches the
`true ->` arm, we have already determined via `swoosh_email?/1` that the
value is NOT a `%Swoosh.Email{}` struct. Therefore this call will raise
`FunctionClauseError` at runtime, not produce a "best-effort" attachment.

The branch is dead in the success sense (cannot succeed for the inputs that
actually reach it) and live in the failure sense (will crash callers that
pass any unexpected input — e.g. `nil`, a plain map, a string filename
mistakenly passed as the first argument). This contradicts the moduledoc's
contract that rendering errors are surfaced as `{:error, Rendro.Error.t()}`:
this path raises instead.

**Fix:** Remove the misleading branch and return a typed error for unknown
inputs:

```elixir
cond do
  mailglass_message?(email_or_message) ->
    attach_to_mailglass(email_or_message, attachment)

  swoosh_email?(email_or_message) ->
    Swoosh.Email.attachment(email_or_message, attachment)

  true ->
    {:error,
     Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}
end
```

Then update the `@spec` of `attach_pdf/3` to include `{:error, Rendro.Error.t()}`
for this case (it already does, so this is purely an implementation fix).

## Warnings

### WR-01: Pipeline timeouts are never audited

**File:** `lib/rendro/adapters/threadline.ex:73-82` (in concert with `lib/rendro/pipeline.ex:31-36`)

**Issue:** `Rendro.Pipeline.run/1` wraps execution in `Task.async` and uses
`Task.yield/Task.shutdown` to enforce a timeout. On timeout the outer
`:telemetry.span` *never emits a `:stop` or `:exception` event* because the
task is shut down before its span block completes. As a result, every
timed-out render returns `{:error, %Rendro.Error{reason: :timeout}}` to the
caller but produces zero Threadline audit calls — a class of failure that
is arguably the most important to audit.

The Threadline adapter's moduledoc claims it audits "successful or failed
renders" via `[:rendro, :render, :stop]` and "crashed renders" via
`[:rendro, :render, :exception]`, neither of which fire on timeout.

**Fix:** Either (a) emit a `[:rendro, :render, :stop]` event explicitly from
the timeout branch in `Pipeline.run/1` before returning the timeout error,
or (b) add a separate `[:rendro, :render, :timeout]` event and subscribe the
adapter to it. Option (a) is less invasive:

```elixir
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} ->
    result

  nil ->
    err = Error.from_stage(:render, :timeout, base_meta)
    :telemetry.execute(
      Rendro.Telemetry.render_prefix() ++ [:stop],
      %{duration: 0},
      Map.merge(base_meta, %{status: :error, page_count: 0, byte_size: 0, reason: :timeout})
    )
    {:error, err}
end
```

---

### WR-02: `handle_event` defaults to `:render_succeeded` whenever `status` is missing or unrecognized

**File:** `lib/rendro/adapters/threadline.ex:75`

**Issue:**

```elixir
action = if Map.get(metadata, :status) == :error, do: :render_failed, else: :render_succeeded
```

If telemetry metadata ever lacks `:status` (or contains some other atom),
the adapter classifies the event as a *successful* render and emits
`:render_succeeded` to Threadline. That is a silent false-positive: a
broken render gets logged as a success in the audit trail.

Today `Pipeline.build_stop_meta/3` always sets `:status` to `:ok` or
`:error`, so the bug is dormant — but the adapter is the audit-layer last
line of defense and should not assume upstream invariants.

**Fix:** Make the mapping explicit and fail closed for unknown statuses:

```elixir
action =
  case Map.get(metadata, :status) do
    :ok -> :render_succeeded
    :error -> :render_failed
    other -> :render_failed  # or {:render_unknown, other}
  end
```

---

### WR-03: `is_mailglass_struct?/1` matches anything in the `Elixir.Mailglass.*` namespace

**File:** `lib/rendro/adapters/mailglass.ex:81-86`

**Issue:** The check `String.starts_with?(mod_str, "Elixir.Mailglass.")`
will return `true` for any struct in the `Mailglass.*` namespace —
including things like `%Mailglass.Config{}`, `%Mailglass.Whatever{}`, or a
user-defined `%Mailglass.Foo{}` that has nothing to do with messages. Those
values are then sent through `attach_to_mailglass/2`, which assumes they
are message-like and falls through to the dangerous `extract_swoosh/1`
fallback documented in CR-01.

**Fix:** Narrow the check to actual message structs (or a small whitelist),
and require the wrapper interface to be present:

```elixir
defp mailglass_message?(%Mailglass.Message{}), do: true
defp mailglass_message?(value) when is_struct(value) do
  mod = value.__struct__
  mod |> Atom.to_string() |> String.ends_with?(".Message") and
    function_exported?(mod, :update_swoosh, 2)
end
defp mailglass_message?(_), do: false
```

---

### WR-04: `test_pid/0` only inspects the head of `:"$callers"` and will mis-route across nested processes

**File:** `test/support/mocks.ex:76-81`

**Issue:**

```elixir
defp test_pid do
  case Process.get(:"$callers") do
    [pid | _] -> pid
    _ -> self()
  end
end
```

Elixir's Task sets `:"$callers"` as `[immediate_caller | inherited_callers]`,
so a Task spawned from another Task gets `[outer_task_pid, test_pid]`. The
current implementation returns the *immediate* caller (an outer Task pid),
not the test process. The captured call would then be inserted under a key
the test never queries, and `threadline_calls/0` would return `[]`.

The Rendro pipeline today only spawns one level of `Task.async` (see
`lib/rendro/pipeline.ex:31`), so the bug is latent. But anyone introducing
a second-level Task (e.g. parallel page rendering, async post-processing)
will see ghost test failures with no obvious cause.

**Fix:** Walk to the end of the chain — the last entry is the original
caller:

```elixir
defp test_pid do
  case Process.get(:"$callers") do
    [_ | _] = chain -> List.last(chain)
    _ -> self()
  end
end
```

---

### WR-05: `track_render/2` swallows arbitrary exceptions, including ones unrelated to Threadline

**File:** `lib/rendro/adapters/threadline.ex:89-98`

**Issue:** The `try/rescue e ->` is unscoped — it catches every exception
that bubbles out of `Threadline.record_action/2`, including
`ArgumentError`s caused by malformed metadata that the *adapter itself*
constructed, runtime bugs in `Threadline`, etc. The original exception is
wrapped as `{:exception, e}` and silently returned. There is no log,
telemetry event, or warning emitted to surface the underlying failure;
audit problems will be invisible until someone goes looking.

**Fix:** Either narrow the rescue to the specific exceptions Threadline
documents, or at minimum log via `Logger.warning/1` (or emit a telemetry
event) before returning the error so audit-pipeline failures aren't
hidden:

```elixir
rescue
  e ->
    require Logger
    Logger.warning("Threadline.record_action/2 raised: #{Exception.message(e)}")
    {:error, {:exception, e}}
end
```

---

### WR-06: `Rendro.render/1` is called without options, blocking deterministic-mode pass-through

**File:** `lib/rendro/adapters/mailglass.ex:48`

**Issue:** `attach_pdf/3` calls `Rendro.render(document)` (1-arity), so
callers cannot ask for deterministic output, custom timeouts, or any other
render policy when emailing a PDF. The moduledoc explicitly mentions
"existing core render policy (max pages/bytes), bounding the size of
attachments produced," but those policies live on `document.options` so
they do work — however other render-time options (deterministic, timeout)
cannot be plumbed through. A signature like
`attach_pdf(email, doc, filename \\ @default_filename, opts \\ [])` would
match the rest of the public API.

**Fix:** Add an `opts` parameter forwarded to `Rendro.render/2`:

```elixir
@spec attach_pdf(term(), Rendro.Document.t(), String.t(), keyword()) ::
        term() | {:error, Rendro.Error.t()}
def attach_pdf(email_or_message, document, filename \\ @default_filename, opts \\ [])

def attach_pdf(email_or_message, %Rendro.Document{} = document, filename, opts)
    when is_binary(filename) and is_list(opts) do
  case Rendro.render(document, opts) do
    {:ok, binary} -> attach_binary(email_or_message, binary, filename)
    {:error, _} = err -> err
  end
end
```

## Info

### IN-01: `build_audit_metadata/2` includes fields not documented in the moduledoc / audit contract

**File:** `lib/rendro/adapters/threadline.ex:101-115`

**Issue:** The moduledoc (`lib/rendro/adapters/threadline.ex:31-32`) and
`Rendro.Audit`'s PII-safety section list eight forwarded keys:
`:render_id, :stage, :status, :page_count, :byte_size, :duration,
:document_type, :deterministic`. The actual `Map.take/2` list includes two
extra keys that aren't documented anywhere: `:kind` and `:reason`. That
discrepancy is fine in practice (both come from telemetry exception
metadata and are useful), but the docs should match the implementation so
readers know what gets forwarded to Threadline.

**Fix:** Update the moduledoc (and the matching paragraph in
`lib/rendro/audit.ex:25-27`) to add `:kind` and `:reason` to the listed
keys, with a one-line note that they only appear on `:exception` events.

---

### IN-02: Test stub `Swoosh.Email` differs from real Swoosh and may shadow it depending on load order

**File:** `test/support/mocks.ex:119-153`

**Issue:** `unless Code.ensure_loaded?(Swoosh.Email) do ... end` runs at
compile-time of `mocks.ex`. If Swoosh is configured as an optional dep,
the order in which the test compiler resolves it relative to `support/`
files matters: in some configurations the stub is defined and then later
"replaced" by a real Swoosh module (warning), and in others the stub wins
and the real Swoosh.Email is shadowed for the remainder of the test run.
The stub's struct does not include several fields the real Swoosh.Email
has (e.g. `:date`), which can cause confusing assertion mismatches.

**Fix:** Either (a) add Swoosh as a real `:test`-only dep in `mix.exs` and
delete the stub, or (b) gate the stub's compilation on `Mix.env() == :test
and not Code.ensure_loaded?(Swoosh.Email)` and clearly document the
contract the stub aims to satisfy.

---

### IN-03: `AdapterReloader.recompile/0` will print "redefining module" warnings on every test boot

**File:** `test/support/mocks.ex:188-198`

**Issue:** `Code.compile_file/1` re-evaluates the adapter source files,
which re-defines the modules; the Erlang VM emits a `redefining module`
warning each time. The output noise during test runs makes real warnings
harder to spot.

**Fix:** Either (a) use `Code.put_compiler_option(:ignore_module_conflict,
true)` around the compile, scoped narrowly, or (b) only recompile when the
adapter modules are NOT already loaded (e.g. `unless
Code.ensure_loaded?(Rendro.Adapters.Threadline) do ... end`), which avoids
the warning when the real ecosystem libs are present.

---

### IN-04: `mocks.ex` `ensure_table!/0` race-prone if ever called from multiple processes

**File:** `test/support/mocks.ex:31-40`

**Issue:** The `:ets.info` → `:ets.new` sequence is non-atomic. If two
processes ever race here (today only `test_helper.exs` calls it, so this
is purely defensive), the second `:ets.new/2` raises
`ArgumentError`. Not a bug today, but `ensure_table!` reads as a generic
helper that *could* be called from anywhere.

**Fix:** Wrap the create in `try/rescue ArgumentError -> :ok end`, or
serialize creation via a `GenServer`/named process. Cheapest patch:

```elixir
def ensure_table! do
  case :ets.whereis(@table) do
    :undefined ->
      try do
        :ets.new(@table, [:named_table, :public, :bag])
        :ok
      rescue
        ArgumentError -> :ok
      end

    _ ->
      :ok
  end
end
```

---

_Reviewed: 2026-04-26T17:46:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

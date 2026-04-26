---
phase: 05-early-ecosystem-recipes
reviewed: 2026-04-26T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - guides/integrations.md
  - lib/rendro/adapters/accrue.ex
  - lib/rendro/adapters/mailglass.ex
  - lib/rendro/adapters/threadline.ex
  - lib/rendro/audit.ex
  - mix.exs
  - README.md
  - test/rendro/adapters/accrue_test.exs
  - test/rendro/adapters/mailglass_test.exs
  - test/rendro/adapters/threadline_test.exs
  - test/support/mocks.ex
  - test/test_helper.exs
findings:
  critical: 1
  warning: 6
  info: 6
  total: 13
status: issues_found
---

# Phase 05: Code Review Report (post gap-closure)

**Reviewed:** 2026-04-26T00:00:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The Phase 05 gap-closure work (commits `7ec2ea1..69085ad`) addresses the three
gaps surfaced by verification:

- **05-02 (Accrue adapter):** A new `Rendro.Adapters.Accrue` recipe is shipped,
  optional-gated, and accompanied by tests + stub modules in `mocks.ex`. The
  happy paths and the documented `{:error, {:invalid_invoice, _}}` contract are
  exercised.
- **05-03 (Mailglass contract fixes):** CR-01 (silent data loss in
  `extract_swoosh/1`) and CR-02 (`FunctionClauseError` from the
  "best-effort" cond branch) are correctly resolved; `mailglass_message?/1` is
  narrowed (WR-03) to require `.Message` suffix + `update_swoosh/2` export.
  Negative-path tests now cover all three.
- **05-04 (Integration documentation):** A new `guides/integrations.md` covers
  setup, verification, and a failure-diagnostics table for each adapter, and is
  wired into ExDoc extras. The README links to it.

The Threadline adapter, the `Rendro.Audit` behavior, and the optional-dependency
discipline are all in solid shape.

That said, the Mailglass adapter's `put_swoosh/2` retains a contract bug that
*precisely undermines the WR-03 narrowing* — it accepts custom Mailglass-style
wrappers via `mailglass_message?/1` but always dispatches the re-wrap step
through `Mailglass.Message.update_swoosh/2`, which raises `FunctionClauseError`
for any wrapper struct that is not literally `%Mailglass.Message{}`. Several
WARNING-class issues from the prior review (WR-01 timeout-not-audited, WR-02
default-to-success, WR-05 unscoped rescue, IN-04 ETS race) remain open and have
not been re-verified by the gap-closure work — they are restated here. New
findings cover the Accrue adapter and tests, plus dead code shipped in the test
fixtures.

## Critical Issues

### CR-01: `put_swoosh/2` raises `FunctionClauseError` for any non-`Mailglass.Message` wrapper that the new `mailglass_message?/1` guard admits

**File:** `lib/rendro/adapters/mailglass.ex:128-142`

**Issue:** Commit `51bc306` correctly narrows `mailglass_message?/1` to require
the struct module's atom name to end in `.Message` AND that
`update_swoosh/2` is exported by *that* struct's module
(`function_exported?(mod, :update_swoosh, 2)` at line 101). The moduledoc at
lines 21-23 explicitly advertises this: "a `Mailglass.Message` struct (it will
be unwrapped, the attachment added to its underlying Swoosh email, and
re-wrapped via `Mailglass.Message.update_swoosh/2` if available)" — and lines
36-39 promise that wrappers "must ensure one of those fields is present, or
implement `update_swoosh/2`" — i.e. the wrapper's own `update_swoosh/2`
should be honored.

`put_swoosh/2`, however, hardcodes the re-wrap to the canonical
`Mailglass.Message` module and never consults the input struct's own module:

```elixir
defp put_swoosh(message, swoosh_email) do
  cond do
    function_exported?(Mailglass.Message, :update_swoosh, 2) ->
      apply(Mailglass.Message, :update_swoosh, [message, swoosh_email])
    # ...
  end
end
```

For a custom wrapper such as `%Mailglass.Wrapper.Message{swoosh: ...}` (the
exact shape exercised by the new CR-01 test fixture at
`test/rendro/adapters/mailglass_test.exs:16-26`), the trace is:

1. `mailglass_message?/1` returns true (suffix `.Message` + `update_swoosh/2`
   exported on `Mailglass.Wrapper.Message`).
2. `extract_swoosh/1` matches `%{swoosh: %Swoosh.Email{} = email}` and returns
   `{:ok, swoosh}`.
3. `put_swoosh/2`'s first cond is true (`Mailglass.Message.update_swoosh/2`
   exists — the real lib or `mocks.ex:161`).
4. `apply(Mailglass.Message, :update_swoosh, [%Mailglass.Wrapper.Message{}, ...])`
   is called.
5. `Mailglass.Message.update_swoosh/2` (stub at `test/support/mocks.ex:161` or
   the real lib) pattern-matches `%__MODULE__{} = message`. The input is a
   `%Mailglass.Wrapper.Message{}`, NOT a `%Mailglass.Message{}`. **Raises
   `FunctionClauseError`.**

This is the same class of contract violation the CR-02 fix was supposed to
eliminate ("attach_pdf/3 never raises — all failure paths return an
`{:error, _}` tuple," moduledoc:27). It hides today only because the existing
negative-path test (`mailglass_test.exs:149-163`) uses a wrapper *without* a
`:swoosh` field, so the trace bails out at step 2 with the
`{:unrecognized_message_shape, _}` error before ever reaching `put_swoosh/2`.
Adding a `:swoosh` field to that fixture immediately reproduces the crash.

**Fix:** Dispatch the re-wrap through the *input struct's* module, mirroring
the predicate in `mailglass_message?/1`. Fall back to canonical
`Mailglass.Message`, then to direct field assignment, only if the input
struct does not export `update_swoosh/2`:

```elixir
defp put_swoosh(message, swoosh_email) when is_struct(message) do
  mod = message.__struct__

  cond do
    function_exported?(mod, :update_swoosh, 2) ->
      apply(mod, :update_swoosh, [message, swoosh_email])

    Map.has_key?(message, :swoosh) ->
      %{message | swoosh: swoosh_email}

    Map.has_key?(message, :email) ->
      %{message | email: swoosh_email}

    true ->
      {:error, {:unrecognized_message_shape, mod}}
  end
end
```

Add a regression test that exercises a wrapper struct with both a `:swoosh`
field AND its own `update_swoosh/2` to lock in the fix:

```elixir
test "Mailglass.* wrapper with :swoosh and own update_swoosh/2 is re-wrapped via the wrapper's module" do
  msg = %Mailglass.Wrapper.Message{id: 1, payload: "data"}
  # Add :swoosh to the fixture so extract_swoosh succeeds.
  msg = %{msg | swoosh: Swoosh.Email.new()}

  assert {:ok, %Mailglass.Wrapper.Message{}} =
           Adapter.attach_pdf(msg, sample_document(), "x.pdf")
end
```

Also delete the unreachable final `true -> swoosh_email` arm (it loses the
caller's wrapper entirely — the same data-loss class that CR-01 in the prior
review was meant to remove).

## Warnings

### WR-01: Pipeline timeouts are still never audited

**File:** `lib/rendro/adapters/threadline.ex:73-82`, `lib/rendro/pipeline.ex:31-36`

**Issue:** Carried over from the prior review unchanged. `Rendro.Pipeline.run/1`
wraps execution in `Task.async` and uses `Task.yield/Task.shutdown` to enforce
the timeout. On timeout the outer `:telemetry.span` *never emits a `:stop` or
`:exception` event*, so neither `[:rendro, :render, :stop]` nor
`[:rendro, :render, :exception]` fires, and the Threadline handler is never
called. Every timed-out render returns `{:error, %Rendro.Error{reason: :timeout}}`
to the caller and produces zero audit calls.

The 05-04 docs (`guides/integrations.md:120-154`) now disclose this as a known
limitation with a manual mitigation snippet. That converts the bug from "silent
audit gap" to "documented audit gap" — but it is still a defect against the
adapter moduledoc's claim that it audits all "successful or failed renders" via
`:stop` and "crashed renders" via `:exception`. Operators who rely on
Threadline as a complete audit trail will silently miss the most-important
class of failure unless they manually duplicate audit emission at every call
site.

**Fix:** Either (a) emit a `[:rendro, :render, :stop]` event explicitly from the
timeout branch in `Pipeline.run/1` before returning the timeout error, or (b)
add a `[:rendro, :render, :timeout]` event and subscribe the adapter to it.
Option (a) is least invasive:

```elixir
case Task.yield(task, timeout) || Task.shutdown(task) do
  {:ok, result} ->
    result

  nil ->
    err = Error.from_stage(:render, :timeout, base_meta)
    :telemetry.execute(
      Rendro.Telemetry.render_prefix() ++ [:stop],
      %{duration: timeout},
      Map.merge(base_meta, %{
        status: :error, page_count: 0, byte_size: 0, reason: :timeout
      })
    )
    {:error, err}
end
```

---

### WR-02: `handle_event` defaults to `:render_succeeded` whenever `:status` is missing or unrecognized

**File:** `lib/rendro/adapters/threadline.ex:75`

**Issue:** Carried over from the prior review unchanged.

```elixir
action =
  if Map.get(metadata, :status) == :error,
    do: :render_failed,
    else: :render_succeeded
```

If telemetry metadata ever lacks `:status` or carries an unrecognized atom, the
adapter classifies the event as a *successful* render and emits
`:render_succeeded` to Threadline. Today
`Rendro.Pipeline.build_stop_meta/3` always sets `:status` to `:ok` or
`:error`, so the bug is dormant — but the adapter is the audit-layer last line
of defense and should fail closed.

**Fix:** Make the mapping explicit:

```elixir
action =
  case Map.get(metadata, :status) do
    :ok    -> :render_succeeded
    :error -> :render_failed
    _      -> :render_failed
  end
```

---

### WR-03: `track_render/2` swallows arbitrary exceptions silently

**File:** `lib/rendro/adapters/threadline.ex:89-98`

**Issue:** Carried over from the prior review unchanged. The
`try/rescue e ->` is unscoped — it catches every exception that bubbles out
of `Threadline.record_action/2`, including `ArgumentError` from malformed
metadata that the adapter itself constructed, runtime bugs in `Threadline`, or
unrelated VM failures. The original exception is wrapped as
`{:error, {:exception, e}}` and silently returned. There is no log, telemetry
event, or warning emitted to surface the underlying failure; audit-pipeline
problems are invisible until someone goes looking.

**Fix:** Either (a) narrow the rescue to specific exceptions Threadline
documents, or (b) log via `Logger.warning/1` (or emit a meta-telemetry event)
before returning the error so audit failures aren't hidden:

```elixir
rescue
  e ->
    require Logger

    Logger.warning(
      "Threadline.record_action/2 raised: #{Exception.message(e)}"
    )

    {:error, {:exception, e}}
end
```

---

### WR-04: `track_render/2`'s `:action` contract is private and undocumented in the `Rendro.Audit` behavior

**File:** `lib/rendro/audit.ex:38-47`, `lib/rendro/adapters/threadline.ex:84-99`

**Issue:** The `Rendro.Audit` behavior declares
`@callback track_render(render_id, metadata) :: :ok | {:error, term()}` and
documents the *forwarded* metadata keys (`:render_id`, `:stage`, `:status`,
`:page_count`, `:byte_size`, `:duration`, `:document_type`, `:deterministic`).

The Threadline implementation, however, reads `metadata.action` (lines 86, 90)
and uses it to drive `Threadline.record_action/2`. The `:action` key is
injected by the adapter's own `handle_event/4` (lines 76, 81) — it is *not*
part of the documented metadata contract. A third-party that adopts
`Rendro.Audit` (per the example in `audit.ex:11-19`) will not learn from the
behavior or its docs that `:action` is a contract input, and the contract for
"how to call `track_render/2` directly" is different from "how to call it via
the telemetry handler."

**Fix:** Either (a) lift `:action` into the behavior's documented metadata keys
with a note that adapter callers must populate it, or (b) make `:action` an
explicit positional argument:

```elixir
@callback track_render(render_id, action :: atom(), metadata) ::
            :ok | {:error, term()}
```

Option (b) is cleanest because it removes the implicit map-shape contract.

---

### WR-05: `extract_swoosh/1`'s `%Swoosh.Email{}` clause is unreachable from `attach_to_mailglass/2`

**File:** `lib/rendro/adapters/mailglass.ex:120-122`

**Issue:** `extract_swoosh/1` declares a clause that matches a bare
`%Swoosh.Email{}`:

```elixir
defp extract_swoosh(%Swoosh.Email{} = email), do: {:ok, email}
```

But `extract_swoosh/1` is only called from `attach_to_mailglass/2` (line 110),
which is itself only entered when `mailglass_message?/1` returned true.
`mailglass_message?/1` rejects `%Swoosh.Email{}` because Swoosh's struct module
atom does not end in `.Message`. So the `%Swoosh.Email{} = email` clause is
unreachable. Dead code is a code smell and (more concretely) misleads readers
into believing the function handles Swoosh inputs as a fallback when it does
not.

**Fix:** Delete the unreachable clause:

```elixir
defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(other) when is_struct(other),
  do: {:error, {:unrecognized_message_shape, other.__struct__}}
defp extract_swoosh(other),
  do: {:error, {:unrecognized_message_shape, other}}
```

---

### WR-06: Accrue `recipe/1` validates only the outer struct; invalid `:line_items` entries crash the recipe

**File:** `lib/rendro/adapters/accrue.ex:68-77`

**Issue:** `recipe/1`'s spec is
`{:ok, Rendro.Document.t()} | {:error, {:invalid_invoice, term()}}` — i.e. the
recipe promises to return an `{:error, _}` tuple for any non-`%Accrue.Invoice{}`
input. Inside `build_content/1`, however:

```elixir
rows =
  Enum.map(line_items || [], fn %Accrue.LineItem{} = item ->
    # ...
  end)
```

The lambda pattern-matches `%Accrue.LineItem{} = item`. If `:line_items`
contains anything other than a `%Accrue.LineItem{}` struct (a plain map, a
keyword list, a string, a `nil`, or a custom Accrue struct), the call raises
`FunctionClauseError`. The moduledoc claims "Returns
`{:error, {:invalid_invoice, term()}}` for non-`%Accrue.Invoice{}` inputs" —
which is technically true at the outer level but misleading because invalid
*nested* input crashes rather than returning a typed error.

The Accrue tests at `test/rendro/adapters/accrue_test.exs:7-17` only exercise
the well-formed case, so the bug is not surfaced by CI.

**Fix:** Either (a) validate line items up front and short-circuit with
`{:error, {:invalid_invoice, ...}}`, or (b) handle non-LineItem entries
gracefully. (a) is simplest and matches the documented contract:

```elixir
def recipe(%Accrue.Invoice{line_items: items} = invoice)
    when is_list(items) do
  if Enum.all?(items, &match?(%Accrue.LineItem{}, &1)) do
    # ... build doc ...
    {:ok, doc}
  else
    {:error, {:invalid_invoice, {:invalid_line_items, items}}}
  end
end

def recipe(%Accrue.Invoice{} = invoice) do
  # line_items is not a list (or is nil)
  {:error, {:invalid_invoice, invoice}}
end

def recipe(other), do: {:error, {:invalid_invoice, other}}
```

Add a negative-path test that exercises an `Invoice` with a plain map in
`:line_items`.

## Info

### IN-01: `Mailglass.UnrecognizedFixture` is defined but never used

**File:** `test/rendro/adapters/mailglass_test.exs:7-14`

**Issue:** The fixture module `Mailglass.UnrecognizedFixture` is defined at
file-top-level "to exercise WR-03 overlap with CR-02," and the moduledoc
comment at lines 11-13 explains its purpose — but no test in the file
references it. The actual WR-03 test at lines 165-180 uses
`Mailglass.ConfigFixture` instead. `Mailglass.UnrecognizedFixture` is dead
code in the test file.

**Fix:** Either delete `Mailglass.UnrecognizedFixture` outright, or write the
test it was added to support. Note: `Mailglass.ConfigFixture` already exercises
the WR-03 scenario described in the `UnrecognizedFixture` moduledoc, so the
simplest fix is deletion.

---

### IN-02: `build_audit_metadata/2` includes `:kind` and `:reason` keys not listed in the moduledoc / behavior contract

**File:** `lib/rendro/adapters/threadline.ex:101-115`, `lib/rendro/audit.ex:25-27`,
`guides/integrations.md:62-64`

**Issue:** The Threadline moduledoc (lines 31-32), the `Rendro.Audit`
PII-safety section (`audit.ex:25-27`), and the integrations guide
(`integrations.md:62-64`) all document eight forwarded keys: `:render_id`,
`:stage`, `:status`, `:page_count`, `:byte_size`, `:duration`,
`:document_type`, `:deterministic`. The actual `Map.take/2` list at
`threadline.ex:103-113` includes two extra keys: `:kind` and `:reason`. Both
keys are useful (they come from telemetry exception metadata), but the gap
between docs and implementation means readers do not know they may be
forwarded.

**Fix:** Add `:kind` and `:reason` to all three documentation sites with a
one-liner noting they only appear on `:exception` events.

---

### IN-03: Accrue `format_amount/1` rendering is locale-naive and offers no decimal handling

**File:** `lib/rendro/adapters/accrue.ex:97-99`

**Issue:** `format_amount/1` has three clauses:

```elixir
defp format_amount(nil), do: ""
defp format_amount(value) when is_integer(value), do: "$#{value}"
defp format_amount(value), do: to_string(value)
```

The integer branch unconditionally prepends `$`, which is a hard-coded USD
assumption even though the moduledoc accepts "integer or Decimal-like value."
The fallback `to_string(value)` will work for `Decimal` (which implements
`String.Chars`), but the result will not include a currency prefix — so a
mixed-mode `Invoice` that has integer line subtotals and a Decimal `:total`
will render with `$1500` rows and a bare `123.45` total. Inconsistent.

**Fix:** Either (a) require integers in the spec and document them as
"smallest currency unit (cents)" with a separate formatter that adds the
prefix, or (b) accept `Decimal` and prefix uniformly:

```elixir
defp format_amount(nil), do: ""
defp format_amount(value) when is_integer(value), do: "$#{value}"
defp format_amount(%Decimal{} = value), do: "$#{Decimal.to_string(value)}"
defp format_amount(value), do: to_string(value)
```

---

### IN-04: Accrue header uses `inspect/1` for `:issued_at`, producing developer-facing output

**File:** `lib/rendro/adapters/accrue.ex:60-65`

**Issue:**

```elixir
Rendro.block(Rendro.text("Issued: #{inspect(issued_at)}", size: 10)),
```

`inspect/1` is for debugging output. A `~D[2026-04-26]` Date, when inspected,
produces `~D[2026-04-26]` literally — so a rendered invoice shows
`Issued: ~D[2026-04-26]` to the recipient. End users see Elixir sigil
syntax in their billing PDF.

**Fix:** Use `Date.to_string/1` (or `to_string/1` via `String.Chars` for
Date/DateTime — both implement it) and document the expected types:

```elixir
defp format_issued_at(nil), do: ""
defp format_issued_at(%Date{} = d), do: Date.to_string(d)
defp format_issued_at(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
defp format_issued_at(other), do: to_string(other)
```

---

### IN-05: `mocks.ex` `ensure_table!/0` is non-atomic (race-prone if ever called from multiple processes)

**File:** `test/support/mocks.ex:31-40`

**Issue:** Carried over from the prior review unchanged. The
`:ets.info` → `:ets.new` sequence is non-atomic. If two processes ever race
here, the second `:ets.new/2` call raises `ArgumentError`. Today only
`test_helper.exs` calls it, so the bug is purely defensive — but the function
reads as a generic helper that could be called from anywhere.

**Fix:** Wrap creation in `try/rescue ArgumentError -> :ok end`:

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

### IN-06: `AdapterReloader.recompile/0` produces "redefining module" warnings on every test boot

**File:** `test/support/mocks.ex:211-221`

**Issue:** Carried over from the prior review unchanged. `Code.compile_file/1`
re-evaluates the adapter source files, which redefines the modules; the Erlang
VM emits a `redefining module` warning each time. The output noise during test
runs makes real warnings harder to spot. With the new `accrue.ex` added to
`@adapter_files` (line 208), the noise is now three lines per `mix test`
invocation instead of two.

**Fix:** Suppress conflict warnings narrowly around the recompile, or skip
recompilation when the adapter modules are already loaded:

```elixir
def recompile do
  Code.put_compiler_option(:ignore_module_conflict, true)

  try do
    project_root = File.cwd!()

    for relative <- @adapter_files,
        path = Path.join(project_root, relative),
        File.exists?(path) do
      Code.compile_file(path)
    end

    :ok
  after
    Code.put_compiler_option(:ignore_module_conflict, false)
  end
end
```

---

_Reviewed: 2026-04-26T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: "05-early-ecosystem-recipes"
plan: "03"
subsystem: adapters
tags: [adapters, mailglass, contract-violations, gap-closure, negative-path, tdd]
dependency_graph:
  requires:
    - "05-01 (Mailglass adapter initial implementation)"
  provides:
    - "Mailglass attach_pdf/3 correct error-tuple contract on unrecognized inputs"
    - "Negative-path test coverage for CR-01, CR-02, WR-03"
  affects:
    - "lib/rendro/adapters/mailglass.ex"
    - "test/rendro/adapters/mailglass_test.exs"
tech_stack:
  added: []
  patterns:
    - "ok/error tuple propagation from extract_swoosh/1 through attach_to_mailglass/2"
    - "Narrowed struct predicate using module name suffix + function_exported?/3"
key_files:
  created: []
  modified:
    - "lib/rendro/adapters/mailglass.ex"
    - "test/rendro/adapters/mailglass_test.exs"
decisions:
  - "CR-01 fix: extract_swoosh/1 returns {:ok, email} | {:error, {:unrecognized_message_shape, mod}} instead of fabricating empty %Swoosh.Email{}"
  - "CR-02 fix: attach_binary/3 true->arm returns {:error, Rendro.Error.from_stage(:render, {:invalid_email_target, _})} instead of calling Swoosh.Email.attachment/2 (which would raise)"
  - "WR-03 fix: mailglass_message?/1 narrowed from 'any Elixir.Mailglass.* struct' to '%Mailglass.Message{} OR struct ending in .Message that exports update_swoosh/2'"
  - "WR-01/WR-02/WR-04/WR-05/WR-06/IN-01..IN-04 are intentionally out of scope per gap-closure directive"
  - "Test fixture for CR-01 uses Mailglass.Wrapper.Message (ends in .Message + exports update_swoosh/2) to exercise extract_swoosh/1 error path; Mailglass.UnrecognizedFixture and Mailglass.ConfigFixture exercise CR-02/WR-03 paths"
metrics:
  duration_minutes: 5
  completed_date: "2026-04-26T18:23:52Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 05 Plan 03: Mailglass Adapter Contract Violation Fixes (CR-01, CR-02, WR-03) Summary

Patched `Rendro.Adapters.Mailglass.attach_pdf/3` to return typed error tuples on all failure paths — eliminating a silent data-loss bug (CR-01), a crash-on-bad-input bug (CR-02), and an over-broad struct classifier (WR-03) — with negative-path test coverage using TDD.

## Tasks Completed

| Task | Name | Commit | Type | Files |
|------|------|--------|------|-------|
| 1 | Add failing negative-path RED tests (CR-01, CR-02, WR-03) | `7ec2ea1` | test | test/rendro/adapters/mailglass_test.exs |
| 2 | Apply CR-01 + CR-02 + WR-03 fixes (GREEN) | `51bc306` | fix | lib/rendro/adapters/mailglass.ex, test/rendro/adapters/mailglass_test.exs |

## What Was Fixed

### CR-02: attach_binary/3 "best-effort" arm now returns error tuple (line 80-83)

**Before (lines 64-67 original):**
```elixir
true ->
  # Best-effort: assume the value behaves like a Swoosh email.
  Swoosh.Email.attachment(email_or_message, attachment)
```

**After:**
```elixir
true ->
  {:error,
   Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}
```

### CR-01: extract_swoosh/1 now returns {:ok, _} | {:error, _} (lines 120-126)

**Before:**
```elixir
defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: email
defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: email
defp extract_swoosh(%Swoosh.Email{} = email), do: email
defp extract_swoosh(_), do: %Swoosh.Email{}   # Silent empty email fabrication — GONE
```

**After:**
```elixir
defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%Swoosh.Email{} = email), do: {:ok, email}
defp extract_swoosh(other) when is_struct(other),
  do: {:error, {:unrecognized_message_shape, other.__struct__}}
defp extract_swoosh(other),
  do: {:error, {:unrecognized_message_shape, other}}
```

`attach_to_mailglass/2` propagates the error tuple via `case extract_swoosh(message) do`.

### WR-03: mailglass_message?/1 narrowed (lines 93-104)

**Before:**
```elixir
defp mailglass_message?(value) do
  is_struct(value) and is_mailglass_struct(value)
end

defp is_mailglass_struct(%{__struct__: mod}) do
  mod_str = Atom.to_string(mod)
  String.starts_with?(mod_str, "Elixir.Mailglass.")  # Too broad — matched Config, etc.
end
```

**After:**
```elixir
defp mailglass_message?(%Mailglass.Message{}), do: true

defp mailglass_message?(value) when is_struct(value) do
  mod = value.__struct__
  mod |> Atom.to_string() |> String.ends_with?(".Message") and
    function_exported?(mod, :update_swoosh, 2)
end

defp mailglass_message?(_), do: false
```

## New Public Error Contract

`attach_pdf/3` now exposes two new error tuple shapes (documented in moduledoc `## Errors` and `@spec`):

1. `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` — non-Swoosh, non-Mailglass-message input. Returned when the first argument doesn't match any known email/message type.

2. `{:error, {:unrecognized_message_shape, module}}` — Mailglass-like struct admitted by `mailglass_message?/1` (ends in `.Message`, exports `update_swoosh/2`) but has neither `:swoosh` nor `:email` field with a `%Swoosh.Email{}`.

`attach_pdf/3` no longer raises on any of these negative paths.

## Test Coverage

10 tests, 0 failures (6 existing happy-path + 4 new negative-path):

| Test | Covers | Expected Result |
|------|--------|----------------|
| atom input `:not_an_email` | CR-02 | `{:error, %Rendro.Error{reason: {:invalid_email_target, :not_an_email}}}` |
| plain map `%{not: :swoosh}` | CR-02 | `{:error, %Rendro.Error{reason: {:invalid_email_target, %{not: :swoosh}}}}` |
| `%Mailglass.Wrapper.Message{}` (no :swoosh/:email) | CR-01 | `{:error, {:unrecognized_message_shape, Mailglass.Wrapper.Message}}` |
| `%Mailglass.ConfigFixture{}` (non-.Message struct) | WR-03 | `{:error, %Rendro.Error{reason: {:invalid_email_target, _}}}` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CR-01 test fixture needed namespace adjustment for WR-03 compatibility**

- **Found during:** Task 2 (GREEN phase)
- **Issue:** The plan's `Mailglass.UnrecognizedFixture` fixture (not ending in `.Message`) was designed to exercise CR-01 under the pre-WR-03 behavior (where `starts_with "Elixir.Mailglass."` would admit it as a message). After WR-03 fix, such a fixture never reaches `extract_swoosh/1` because `mailglass_message?/1` rejects it. The test was failing with `{:invalid_email_target, _}` instead of `{:unrecognized_message_shape, _}`.
- **Fix:** Introduced `Mailglass.Wrapper.Message` (a nested module whose atom string ends in `.Message` and exports `update_swoosh/2` but has no `:swoosh`/`:email` field) to correctly exercise the CR-01 extract_swoosh error path. `Mailglass.UnrecognizedFixture` is retained for WR-03/CR-02 overlap coverage. Added `Mailglass.ConfigFixture` for WR-03 testing as planned.
- **Files modified:** `test/rendro/adapters/mailglass_test.exs`
- **Commit:** `51bc306`

## Out of Scope (per gap-closure directive)

The following items from 05-REVIEW.md were intentionally NOT addressed in this plan. They are documented for Plan 05-04 (integration guide):

- **WR-01:** Pipeline timeouts are never audited (Threadline adapter misses timeout events)
- **WR-02:** `handle_event` defaults to `:render_succeeded` for unrecognized status values
- **WR-04:** `test_pid/0` only inspects head of `:"$callers"`, will mis-route in nested Tasks
- **WR-05:** `track_render/2` swallows arbitrary exceptions without logging
- **WR-06:** `Rendro.render/1` called without options, blocking opts pass-through
- **IN-01..IN-04:** Various info-level findings (doc discrepancy, Swoosh stub shadowing, recompile warnings, ETS race)

WR-01 is a known limitation that Plan 05-04's integration guide must document.

## Known Stubs

None.

## Threat Flags

None. All threat register items (T-05-03-01 through T-05-03-04) from the plan were mitigated as designed:

- T-05-03-01 (CR-01 Tampering): extract_swoosh/1 fallback no longer fabricates empty email
- T-05-03-02 (CR-02 DoS): attach_binary/3 true->arm returns error tuple instead of crashing
- T-05-03-03 (WR-03 Spoofing): mailglass_message?/1 narrowed to prevent non-message Mailglass.* structs from entering message handling path
- T-05-03-04 (Information Disclosure): Accepted — {:invalid_email_target, value} echo is intentional for caller debugging

## Self-Check: PASSED

- `lib/rendro/adapters/mailglass.ex`: FOUND
- `test/rendro/adapters/mailglass_test.exs`: FOUND
- Commit `7ec2ea1`: FOUND
- Commit `51bc306`: FOUND
- `mix test test/rendro/adapters/mailglass_test.exs`: 10 tests, 0 failures
- `mix test test/rendro/adapters/`: 18 tests, 0 failures
- `mix compile --warnings-as-errors`: exit 0

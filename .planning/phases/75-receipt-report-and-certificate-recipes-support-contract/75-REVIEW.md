---
phase: 75-receipt-report-and-certificate-recipes-support-contract
reviewed: 2026-05-29T21:11:21Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/rendro/recipes/pagination.ex
  - lib/rendro/page_size.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/certificate.ex
  - test/rendro/recipes/receipt_test.exs
  - test/rendro/recipes/certificate_test.exs
  - priv/support_matrix.json
  - mix.exs
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 75: Code Review Report

**Reviewed:** 2026-05-29T21:11:21Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 75 adds the Receipt and Certificate recipes on the three-rung escape hatch, extracts a shared `Rendro.Recipes.Pagination` helper out of Statement, adds the pure `Rendro.PageSize` helper, and records non-viewer-sensitive `support_matrix.json` rows. All 116 recipe tests pass; the 51-test Statement determinism gate is intact.

Verified clean:

- **Statement refactor is behavior-identical.** The diff (commit `e9c909c`) moved `chunk_into_pages/do_chunk_pages/finalize_page` into `Pagination.chunk_rows_into_pages/2` and re-qualified `formatter/label_resolver/type_name` calls. The `effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon` formula and the `rows_with_meta` zip are preserved verbatim. The shared chunker's `new_h <= cap or current == []` empty-page guard matches the original (no infinite-loop regression, and negative `effective_capacity` degrades to one-row-per-page rather than looping).
- **`support_matrix.json`** validates against `priv/schemas/support_matrix.schema.json` — the new top-level `statement` / `receipt_report` / `certificate` / `page_numbering` keys ride on root `additionalProperties: true`, and the strict `viewer_row` pattern (`evidence` must match `priv/viewer_evidence/...`) only applies inside `viewer_map`, not these capability blocks. All referenced `evidence` test paths exist.
- **Certificate geometry is genuinely derived** (CERT-02): no hardcoded A4 numerics; all x/y/width/height flow from `PageSize.resolve/2` and the margins.
- **Float-vs-Decimal** rejection is correct in Statement and Receipt (dedicated `is_float` clauses precede the generic clauses).

The defects below are all in the new recipes' input-validation surface (errors-as-product gaps) plus minor quality issues. No security vulnerabilities and no determinism breaks were found.

## Warnings

### WR-01: Certificate accepts a non-`Date` `:date` then crashes with `FunctionClauseError` instead of an errors-as-product `ArgumentError`

**File:** `lib/rendro/recipes/certificate.ex:200-238` (validation), `:190` (use site)
**Issue:** `validate_data!/1` only checks that `:title`, `:recipient`, `:date` are *present and non-nil* — it never validates their types. A caller who passes `date: "2026-01-01"` (string) passes validation, and the crash is deferred to `body_section/3 → fmt_date.(data.date) → Rendro.Format.date/1`, whose only clause is `def date(%Date{} = date)`. Confirmed empirically: `Certificate.document(%{title: "T", recipient: "R", date: "2026-01-01"})` raises `FunctionClauseError`, not the instructive `ArgumentError` the recipe's other validation branches promise. This violates the errors-as-product contract that Statement and Receipt uphold for line `:date`.
**Fix:** Add a Date guard in `validate_data!/1` mirroring `Statement.validate_line_date!/2`:
```elixir
case Map.fetch(data, :date) do
  {:ok, %Date{}} -> :ok
  {:ok, other} ->
    raise ArgumentError, """
    Rendro.Recipes.Certificate.document/2 — invalid :date type.
    What:  :date must be a %Date{} struct.
    Where: Rendro.Recipes.Certificate.validate_data!/1
    Why:   Received: #{inspect(other)} (#{Rendro.Recipes.Pagination.type_name(other)}).
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  :error -> :ok  # handled by the missing-key check above
end
```

### WR-02: Certificate body-length guard is silently skipped for non-binary `:body`

**File:** `lib/rendro/recipes/certificate.ex:223-235`
**Issue:** The 2000-byte single-page overflow guard is gated on `if is_binary(body) and byte_size(body) > 2000`. When `:body` is a non-binary (integer, list, atom), the guard is bypassed entirely AND `body_section/3` then calls `Rendro.text(body_text, size: 11)` with the non-string value. Confirmed: `Certificate.document(%{title: "T", recipient: "R", date: ~D[2026-01-01], body: 12345})` does NOT raise — it silently proceeds, defeating the T-75-03-01 overflow protection and emitting a text block from a non-string. The guard's purpose (keep certificates single-page) is only enforced for the happy-path type.
**Fix:** Reject non-binary `:body` explicitly rather than skipping the check:
```elixir
body = Map.get(data, :body, "")

cond do
  not is_binary(body) ->
    raise ArgumentError, "data.body must be a String — got #{Rendro.Recipes.Pagination.type_name(body)}"
  byte_size(body) > 2000 ->
    raise ArgumentError, """ ...existing too-long message... """
  true -> :ok
end
```
Apply the same treatment to `:seal_line` (also passed unchecked into `Rendro.text/2` at `:191`).

### WR-03: Receipt raises raw `BadMapError` / `FunctionClauseError` for malformed `:customer` and `:date` instead of an instructive `ArgumentError`

**File:** `lib/rendro/recipes/receipt.ex:380-398` (key check), `:246-248` (customer use), `:256` (date use)
**Issue:** `validate_required_keys!/1` only checks key *presence*, not shape. `:customer` is consumed via `Map.get(customer, :name, "")` and `:date` via `fmt_date.(date)`. Confirmed empirically:
- `customer: "Acme"` (non-map) → `BadMapError` from `Map.get/3`.
- `date: "2026-01-01"` (non-`Date`) → `FunctionClauseError` from `Rendro.Format.date/1`.

Both are caller-input errors that should surface as the recipe's structured `ArgumentError` (the module documents an errors-as-product validation contract), not as bare runtime exceptions leaking internal detail.
**Fix:** Add shape validation after the required-keys check:
```elixir
defp validate_customer!(%{name: _}), do: :ok
defp validate_customer!(other),
  do: raise(ArgumentError, "Rendro.Recipes.Receipt — :customer must be a map with a :name key — got #{inspect(other)}")

defp validate_date!(%Date{}), do: :ok
defp validate_date!(other),
  do: raise(ArgumentError, "Rendro.Recipes.Receipt — :date must be a %Date{} — got #{inspect(other)}")
```
Call both from `validate_data!/1`.

### WR-04: Receipt does not validate line `:description` is a string, unlike Statement

**File:** `lib/rendro/recipes/receipt.ex:428-448`
**Issue:** Statement validates each line's `:description` via `validate_line_description!/2` (rejecting non-binaries with an instructive message). Receipt's `validate_line!/2` only validates `:amount` and presence of `:description`, not its type. Confirmed: a line `%{description: :not_a_string, amount: Decimal.new("1.00")}` passes validation and renders. For two recipes sharing the same `Pagination` substrate and the same errors-as-product posture, this inconsistency means malformed input is caught in Statement but silently accepted in Receipt, masking caller bugs and risking non-deterministic text from arbitrary terms.
**Fix:** Add a description type check mirroring Statement:
```elixir
defp validate_line_description!(value, _idx) when is_binary(value), do: :ok
defp validate_line_description!(value, idx),
  do: raise(ArgumentError, "Rendro.Recipes.Receipt — lines[#{idx}].description must be a string — got #{inspect(value)}")
```
and call it from `validate_line!/2`.

### WR-05: Certificate brand validation has unreachable / order-dependent clauses for partial brand maps

**File:** `lib/rendro/recipes/certificate.ex:240-257`
**Issue:** The `validate_brand!/1` clauses are:
1. `%{font_name: f, logo_name: l} when is_atom(f) and is_atom(l)` → ok
2. `%{font_name: f} when not is_atom(f)` → font error
3. `%{logo_name: l} when not is_atom(l)` → logo error
4. `_brand` → generic error

A brand map that is `%{font_name: :ok, logo_name: "bad"}` matches clause 1's pattern but fails its guard, then matches clause 2's pattern (`%{font_name: f}`) — but its guard `not is_atom(f)` is false (font is an atom), so clause 2 is skipped — then matches clause 3 and raises the correct logo error. This happens to work, but it is fragile: clause 3 (`%{logo_name: l} when not is_atom(l)`) is only reached for maps that also lack a *non-atom* font, and a map like `%{font_name: "bad", logo_name: "bad"}` reports only the font error (clause 2), never the logo. The branching relies on subtle guard-fallthrough rather than explicit handling, making the validation hard to reason about and easy to break on edit.
**Fix:** Replace the pattern/guard chain with an explicit map-shape check that validates both keys' presence and atom-ness in one place, returning a single clear message per failure mode (or aggregating both). The current C10 tests only cover one-bad-key-at-a-time, so the multi-bad-key gaps are untested.

### WR-06: Receipt `:totals.total` is validated against a derived value even when `:subtotal` is absent, surprising callers

**File:** `lib/rendro/recipes/receipt.ex:496-522`
**Issue:** When `:totals` contains `:total` but not `:subtotal`, the recipe still computes `base = derived_subtotal` (sum of line amounts) and asserts `total == base (+tax -discount)`. Confirmed: `totals: %{total: Decimal.new("11.00")}` with a single 10.00 line raises a `:totals.total mismatch` `ArgumentError`. A caller who deliberately omits `:subtotal` (the "skip this check" escape the subtotal branch documents) cannot escape the *total* check the same way, and the derived total ignores any rounding/fees the caller intended to assert. The asymmetry — subtotal is opt-out by omission, total is not — is undocumented and likely to surprise integrators.
**Fix:** Either document that `:total` is always derived-and-validated against `subtotal (+tax -discount)`, or make `:total` validation opt-out by only running when the caller also supplies the inputs needed to derive it unambiguously. At minimum, the `:totals.total mismatch` message should state the exact derivation (`subtotal + tax - discount`) so the caller can reconcile.

## Info

### IN-01: `Pagination.type_name/1` reports `"Map"` for `%Decimal{}` and `"Unknown"` for tuples

**File:** `lib/rendro/recipes/pagination.ex:76-82`
**Issue:** `type_name/1` checks `is_map/1` before any struct awareness, so `type_name(Decimal.new("1"))` returns `"Map"` (confirmed). Since this helper feeds error messages that often concern Decimal-vs-something confusion, "Map" is mildly misleading for a Decimal that came in via the wrong path. Tuples report `"Unknown"`.
**Fix:** Add struct-aware clauses before `is_map`, e.g. `def type_name(%mod{}), do: inspect(mod)` and `def type_name(v) when is_tuple(v), do: "Tuple"`.

### IN-02: Dead binding `_ = rows` in Statement summary validation

**File:** `lib/rendro/recipes/statement.ex:676-682`
**Issue:** `maybe_validate_summary!/1` builds `{rows, derived_closing}` via `map_reduce` purely to obtain `derived_closing`, then discards `rows` with `_ = rows`. The `rows` accumulator is never used; the `Enum.reduce/3` form used in `maybe_validate_closing_balance!/1` (line 656) is the cleaner equivalent.
**Fix:** Use `derived_closing = Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)` and drop the `_ = rows` line.

### IN-03: Certificate computes and discards `_content_w`

**File:** `lib/rendro/recipes/certificate.ex:180`
**Issue:** `_content_w = template.width - template.margin_left - template.margin_right` is computed with an explanatory comment but never used (it is leading-underscore-bound to silence the warning). It is dead code that suggests an intended width-aware text-sizing path that was never wired up.
**Fix:** Remove the binding and its comment, or wire the width into the body blocks if width-aware sizing was intended.

### IN-04: Duplicated geometry constants and `body_capacity` formula across Receipt and Statement

**File:** `lib/rendro/recipes/receipt.ex:83-108`, `lib/rendro/recipes/statement.ex:86-112`
**Issue:** `@page_width 595.28`, `@page_height 841.89`, `@margin 72`, `@content_width`, `@header_height 48`, `@footer_height 24`, `@body_height`, `@footer_y`, and `@row_epsilon 2.0` are copy-pasted between the two modules, as is the `capacity = @body_height - @header_height - @footer_height` formula. Phase 75 extracted pagination *behavior* into a shared module but left these geometry magic numbers duplicated, so a future change to A4 dimensions or footer height must be made in two places and can silently drift. (Out-of-scope perf aside; this is a maintainability/consistency concern, not correctness.)
**Fix:** Consider hoisting the shared A4/letter geometry and the `body_capacity` formula into `Rendro.PageSize` or `Rendro.Recipes.Pagination` so both recipes derive from one source.

---

_Reviewed: 2026-05-29T21:11:21Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

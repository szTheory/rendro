---
phase: 93-recipes-facade-dx-closure
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/rendro/recipes.ex
  - lib/rendro/recipes/statement.ex
  - test/rendro/recipes_facade_drift_test.exs
  - README.md
  - guides/api_stability.md
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 93: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the five files comprising the Phase 93 "Recipes Facade DX Closure" deliverable.
`lib/rendro/recipes.ex` and the drift test are structurally sound. `guides/api_stability.md`
is accurate. Two blockers were found in `lib/rendro/recipes/statement.ex`: a double-subtraction
in the body capacity calculation that silently under-packs every page by ~11.5% (~5 rows at
default height), and an unguarded `Decimal.equal?` call in summary validation that crashes with a
`FunctionClauseError` on non-Decimal input instead of the documented `ArgumentError`. Two warnings
cover a double-validation on the `document/2` happy path and a misleading comment that numerically
justifies what appears to be a bug. One info item notes that the README's primary "zero-to-one"
examples still direct callers to the internal recipe module rather than the new Tier-1 stable
facade.

## Critical Issues

### CR-01: Body capacity double-subtracts header and footer heights

**File:** `lib/rendro/recipes/statement.ex:318`

**Issue:** `@body_height` is already defined as
`@page_height - 2 * @margin - @header_height - @footer_height` (line 103). Line 318 subtracts
`@header_height` and `@footer_height` from it a second time:

```elixir
capacity = @body_height - @header_height - @footer_height
```

This discards 72 additional points of usable body space (48 + 24). At default row height (14.4 pt),
that is ~5 phantom rows per page — statements break onto extra pages far sooner than necessary.
The comment at line 316 attempts to justify this as "conservative ~8% under-pack" but the actual
loss is 72 / 625.89 = **11.5%**, and the semantics are wrong: `@body_height` is already the
exclusive body region height; there is nothing further to reserve.

`effective_capacity` on line 341 then subtracts `header_h` (the measured repeated table-header
height), `2 * typical_row_h` (BF/CF reservation), and `@row_epsilon` from the already-reduced
`capacity`. These subsequent deductions are correct; the initial `- @header_height - @footer_height`
in `capacity` is not.

**Fix:**
```elixir
# @body_height already excludes header and footer regions.
# No further deduction needed here; effective_capacity below handles
# the repeated table-header row and BF/CF reservation.
capacity = @body_height
```

---

### CR-02: `maybe_validate_summary!/1` crashes on non-Decimal `summary.closing_balance`

**File:** `lib/rendro/recipes/statement.ex:716`

**Issue:** When `data.summary` contains a `:closing_balance` key that is not a `%Decimal{}`
(e.g., a float, integer, or string), the call to `Decimal.equal?(summary.closing_balance, derived_closing)`
raises a `FunctionClauseError` — not the documented `ArgumentError` with a helpful error message.
This is a correctness gap: the docstring promises instructive `ArgumentError`s for all bad-type
inputs, but this path bypasses that contract and produces an opaque crash.

`maybe_validate_closing_balance!/1` correctly handles this case for the top-level `:closing_balance`
key (lines 663–683), but the equivalent guard is missing in `maybe_validate_summary!/1`.

**Fix:**
```elixir
defp maybe_validate_summary!(%{summary: summary, opening_balance: ob, lines: lines})
     when is_map(summary) do
  derived_closing =
    Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)

  if Map.has_key?(summary, :closing_balance) do
    cb = summary.closing_balance

    unless is_struct(cb, Decimal) do
      raise ArgumentError, """
      Rendro.Recipes.Statement.document/2 — invalid :summary.closing_balance type.

      What:  :summary.closing_balance must be a Decimal.
      Where: Rendro.Recipes.Statement.validate_data!/1
      Why:   Received: #{inspect(cb)}.
      Next:  Use Decimal.new/1 — e.g. Decimal.new("100.00").
      """
    end

    unless Decimal.equal?(cb, derived_closing) do
      raise ArgumentError, """
      Rendro.Recipes.Statement.document/2 — :summary.closing_balance mismatch.

      What:  The caller-supplied :summary.closing_balance does not match the derived value.
      Where: Rendro.Recipes.Statement.validate_data!/1
      Why:   Supplied: #{inspect(cb)}, Derived: #{inspect(derived_closing)}.
      Next:  Remove :summary.closing_balance to let the recipe derive it, or correct the value.
      """
    end
  end

  :ok
end
```

---

## Warnings

### WR-01: `document/2` runs `validate_data!` twice on every call

**File:** `lib/rendro/recipes/statement.ex:253,255` (and `222`)

**Issue:** `document/2` calls `validate_data!(data)` at line 253, then immediately calls
`sections(data, opts)` at line 255. `sections/2` unconditionally calls `validate_data!(data)`
again at line 222. Every successful `document/2` invocation performs two full validation passes
over all lines, doubling the work including the per-line struct pattern-matches and
`Enum.with_index` traversal. For statements with many lines this is measurable waste.

**Fix:** Either have `document/2` skip its own `validate_data!` call and trust that `sections/2`
will validate, or extract a private `build_sections_unchecked/2` that skips validation for use
within `document/2` after it has already validated:

```elixir
def document(data, opts \\ []) do
  validate_data!(data)
  template = page_template(opts)
  # sections/2 would call validate_data! again; call a private builder instead:
  secs = build_sections(data, opts)
  ...
end

defp build_sections(data, opts) do
  [header_section(data, opts), body_section(data, opts), footer_section(data, opts)]
end

def sections(data, opts \\ []) do
  validate_data!(data)
  build_sections(data, opts)
end
```

---

### WR-02: Misleading comment misrepresents both the intent and the arithmetic of the capacity reduction

**File:** `lib/rendro/recipes/statement.ex:314-317`

**Issue:** The comment claims the double-subtraction "gives a conservative ~8% under-pack with no
overflow risk." Neither number is accurate: the actual loss is 11.5% (72 / 625.89), and the
framing of "conservative under-pack" is not a valid safety design choice — it is a calculation
error that happens not to cause `content_overflow` only because `effective_capacity` at line 341
then removes the real per-page reservation (`header_h`, BF/CF rows, epsilon). The comment
actively misleads a future maintainer into believing the double-subtraction is intentional.

**Fix:** Replace with a comment that correctly describes the computation (see also CR-01 fix):

```elixir
# @body_height is the exclusive usable body region height — it already excludes
# the header and footer region heights and both page margins. No further top-level
# deduction is needed; effective_capacity below reserves the repeated table-header
# row, BF/CF row overhead, and the sub-pixel epsilon.
capacity = @body_height
```

---

## Info

### IN-01: README primary examples bypass the new Tier-1 stable facade

**File:** `README.md:117,325`

**Issue:** The "Canonical Invoice Recipe" section (line 117) and the Phoenix integration example
(line 325) both show `Rendro.Recipes.Invoice.document(data)` as the zero-to-one pattern. Now that
`Rendro.Recipes.invoice/1` is Tier-1 stable and the canonical entry point, these examples direct
readers to the internal recipe module rather than the public facade. A new adopter reading the
README will anchor on the internal call and miss the facade.

Line 135 mentions `Rendro.Recipes.invoice/1` in prose but does not update the preceding code
block, so the code example and the explanatory text contradict each other.

**Fix:** Update line 117:
```elixir
doc = Rendro.Recipes.invoice(data)   # via Rendro.Recipes facade (Tier-1 stable)
```

Update line 325:
```elixir
doc = Rendro.Recipes.invoice(data)
```

The escape-hatch block (lines 123–133) correctly shows `Rendro.Recipes.Invoice.page_template/1`
and `.sections/2` — those are intentional direct calls to the recipe module and should remain.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

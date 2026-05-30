---
phase: 77-v2-4-closure-format-gate-nyquist-drafts-recipe-input-validat
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/certificate.ex
  - test/rendro/recipes/statement_test.exs
  - test/rendro/recipes/receipt_test.exs
  - test/rendro/recipes/certificate_test.exs
  - mix.exs
  - guides/user_flows_and_jtbd.md
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 77: Code Review Report

**Reviewed:** 2026-05-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

This phase adds structured input validation to the three recipe modules (Statement,
Receipt, Certificate), performs cosmetic cleanups (D-09: removes dead
`_content_w` in certificate.ex, replaces a `map_reduce`-with-discarded-result in
statement.ex with a plain `reduce`, extracts the `14.4` literal to
`@default_row_height`), adds negative-path tests, and wires
`guides/user_flows_and_jtbd.md` into ExDoc.

The behavior changes are correct and well-tested. All 121 tests across the three
recipe test files pass. The new `validate_account!/1`, `validate_customer!/1`,
`validate_date!/1`, and `validate_body!/1` clauses follow the established
errors-as-product pattern, dispatch via pattern matching with proper catch-all
clauses, and order correctly behind `validate_required_keys!/1` so direct
dot-access never raises a bare `KeyError`. The `type_name/1` helper they call is
a public function in `Rendro.Recipes.Pagination`, so no private-call breakage.

No Critical issues. The findings below are validation-completeness asymmetries
and quality concerns, not correctness defects in the happy path.

## Warnings

### WR-01: Certificate `:title` and `:recipient` are never type-validated, only nil-checked

**File:** `lib/rendro/recipes/certificate.ex:196-221`, used at `:182,184`
**Issue:** `validate_data!/1` only verifies `:title`, `:recipient`, and `:date`
are present and non-nil. This phase added type validation for `:date`
(`validate_date!`) and `:body` (`validate_body!`), but `:title` and `:recipient`
are passed straight into `Rendro.block(Rendro.text(data.title, size: 28))` and
`Rendro.text(data.recipient, size: 20)` without a string-type check. A caller
passing `title: 12345` or `recipient: %{}` clears validation and then fails
deeper inside the engine with a non-instructive error — defeating the
errors-as-product contract that the same module now enforces for `:body`. This is
an inconsistency the validation rewrite introduced/left: statement.ex validates
`account.name` is a string and every line `:description` is a string;
receipt.ex validates `customer.name` is a string; certificate.ex validates
`:body` is a string but leaves its two most prominent string fields unchecked.
**Fix:** Add string guards mirroring `validate_body!/1`:
```elixir
validate_string!(:title, data.title)
validate_string!(:recipient, data.recipient)

defp validate_string!(_key, v) when is_binary(v), do: :ok
defp validate_string!(key, v) do
  raise ArgumentError, """
  Rendro.Recipes.Certificate.document/2 — invalid #{inspect(key)} type.

  What:  #{inspect(key)} must be a string.
  Where: Rendro.Recipes.Certificate.validate_data!/1
  Why:   Received: #{inspect(v)} (#{Rendro.Recipes.Pagination.type_name(v)}).
  Next:  Pass a binary string.
  """
end
```

### WR-02: Certificate `:seal_line` accepts non-string without validation

**File:** `lib/rendro/recipes/certificate.ex:176,187`
**Issue:** `seal_text = Map.get(data, :seal_line, "")` is fed directly to
`Rendro.text(seal_text, size: 10)` with no type check. `:body` (an identical
optional free-text field) gained a `validate_body!/1` clause this phase that
rejects non-binary values, but `:seal_line` did not — so `seal_line: 42` passes
validation and fails later in the engine. Same errors-as-product gap as WR-01,
for a field that is structurally identical to the one that was just hardened.
**Fix:** Add `validate_seal_line!/1` mirroring `validate_body!/1` (binary check;
optionally the same 2000-byte length guard, since seal text also flows on the
single page), and call it from `validate_data!/1`.

### WR-03: Statement `validate_account!` / Receipt `validate_customer!` silently accept extra/garbage map keys but reject only on `:name` shape — combined with downstream `Map.get(account, :name, "")` the validation is partly redundant and the guarantee is narrower than the contract implies

**File:** `lib/rendro/recipes/statement.ex:517-528` (and `:261`); `lib/rendro/recipes/receipt.ex:402-413` (and `:248`)
**Issue:** Two coupled concerns. (1) After `validate_account!/1` guarantees
`account` is `%{name: binary}`, `header_section/2` still defends with
`Map.get(account, :name, "")` (statement.ex:261) and
`Map.get(customer, :name, "")` (receipt.ex:248) — the `""` fallback is now dead
since validation guarantees the key. Not a bug, but it masks the new invariant
and invites a future reader to assume `:name` may be absent. (2) The validator's
`%{name: name} when is_binary(name)` clause accepts a struct that happens to
expose a `:name` field (e.g. another struct), since Elixir map-pattern matching
on `%{name: _}` matches any struct with that key. The data-contract docstring
says `:account` is a plain map; if that distinction matters downstream, the
guard does not enforce it.
**Fix:** Either drop the now-dead `Map.get(..., "")` fallback in favor of
`account.name` to make the post-validation invariant explicit, or document that
the fallback is intentional belt-and-suspenders. If plain-map-only is required,
add `when is_map(value) and not is_struct(value)` to the catch-all dispatch.
Low severity — no current caller path is broken.

## Info

### IN-01: Receipt `:totals.total` validation comment is misleading

**File:** `lib/rendro/recipes/receipt.ex:525-527`
**Issue:** The comment says "Here we validate total == derived_subtotal for the
simple case" but the code immediately below computes
`expected_total = subtotal + tax - discount`. The comment describes a behavior
the code does not implement and contradicts the line that follows it.
**Fix:** Remove the stale "simple case" sentence; keep only the
`total == subtotal + tax - discount` explanation.

### IN-02: Receipt `maybe_validate_totals!` ignores `:tax`/`:discount` type mismatches

**File:** `lib/rendro/recipes/receipt.ex:529-537`
**Issue:** `tax`/`discount` are validated via `is_struct(_, Decimal)` only inside
the `then` folds — a non-Decimal `tax` (e.g. a Float) is silently skipped
(treated as absent) rather than rejected, unlike line `:amount` which raises a
Float-specific error. A caller passing `tax: 5.0` gets no error and a silently
wrong `expected_total`, which can then make a correct `:total` assertion fail
with a confusing mismatch message. Out of the phase's stated scope (the four new
validators), but adjacent to the validation work.
**Fix:** Add explicit Decimal/Float guards for `:tax` and `:discount` when
present, consistent with `validate_line_amount!/2`.

### IN-03: Certificate `validate_data!/1` uses an inverted-looking `Enum.reject` idiom

**File:** `lib/rendro/recipes/certificate.ex:199-205`
**Issue:** `Enum.reject(required, fn key -> case Map.fetch(...) do {:ok, val}
when not is_nil(val) -> true; _ -> false end end)` is logically correct (verified:
present-non-nil keys are rejected, leaving missing/nil keys in `missing`), but
"reject the keys that are present" reads backwards and is easy to invert during
future edits. Statement and Receipt use the clearer
`Enum.filter(required, &(not Map.has_key?(data, &1)))`.
**Fix:** Align with the sibling modules:
`Enum.filter(required, fn k -> match?(:error, Map.fetch(data, k)) or is_nil(Map.get(data, k)) end)`,
or keep the reject but invert to a `filter` for readability.

### IN-04: Certificate `validate_brand!` error messages are single-line and omit the What/Where/Why/Next structure used everywhere else

**File:** `lib/rendro/recipes/certificate.ex:265-278`
**Issue:** Every other validator in these three modules (including the four added
this phase) raises a structured multi-line What/Where/Why/Next message; the three
`validate_brand!` error clauses raise terse one-liners. Inconsistent
errors-as-product UX within the same module. Pre-existing, not changed this phase.
**Fix:** Reformat the brand error messages to match the structured template for
consistency.

---

_Reviewed: 2026-05-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

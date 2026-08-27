---
phase: 134-core-architecture-readability
reviewed: 2026-08-27T13:33:17Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/rendro/recipes/branded_invoice.ex
  - lib/rendro/recipes/certificate.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/palette.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/ticket.ex
  - priv/quality/package-members-v1.json
  - scripts/quality_governance.cjs
  - test/quality/baseline_ledger_contract_test.exs
  - test/rendro/recipes/palette_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 134: Code Review Report

**Reviewed:** 2026-08-27T13:33:17Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The recipe refactor centralizes palette resolution successfully, but the new typography seam uses a shallow merge despite the public theme contract accepting partial nested token groups. As a result, ordinary partial type-scale/font overrides crash every recipe instead of inheriting the unchanged roles. The Certificate direct `sections/2` API also bypasses its validation contract and leaks raw `KeyError`s for malformed input.

## Critical Issues

### CR-01: Partial typography overrides erase required nested roles and crash recipes

**File:** `lib/rendro/recipes/invoice.ex:720` (same implementation at `lib/rendro/recipes/branded_invoice.ex:357`, `lib/rendro/recipes/certificate.ex:556`, `lib/rendro/recipes/payslip.ex:957`, `lib/rendro/recipes/receipt.ex:679`, `lib/rendro/recipes/statement.ex:506`, and `lib/rendro/recipes/ticket.ex:735`)

**Issue:** `Map.merge/2` only merges the top-level typography map. A valid partial nested override such as `typography: %{scale: %{body: 12}}` replaces the entire `:scale` map, so accesses such as `type.scale.title` raise `KeyError`. This contradicts the project's public theme behavior, which deep-merges partial nested token groups, and makes the advertised recipe-level override unusable unless callers redundantly provide every scale and font role. Reproduction: `Rendro.Recipes.Invoice.sections(%{id: "I", date: ~D[2026-01-01], items: []}, typography: %{scale: %{body: 12}})` raises `KeyError` for `:title`.

**Fix:** Deep-merge `:scale` and `:fonts` while retaining top-level override precedence, and add coverage for a single nested scale and font override across the shared behavior. For example:

```elixir
override = Keyword.get(opts, :typography, %{})

Map.merge(base, override, fn
  :scale, base_scale, override_scale -> Map.merge(base_scale, override_scale)
  :fonts, base_fonts, override_fonts -> Map.merge(base_fonts, override_fonts)
  _key, _base_value, override_value -> override_value
end)
```

## Warnings

### WR-01: Certificate `sections/2` bypasses the documented validation boundary

**File:** `lib/rendro/recipes/certificate.ex:175-177`

**Issue:** Unlike every other reviewed recipe, public `Certificate.sections/2` does not call `validate_data!/1` before it dereferences `data.title`, `data.recipient`, and `data.date`. Calling `Certificate.sections(%{})` leaks a raw `KeyError` rather than the recipe's intended actionable `ArgumentError`. This breaks the three-rung escape-hatch API for callers who compose templates and sections directly.

**Fix:** Validate at the start of `sections/2`, matching the other recipes, and add a direct-sections invalid-data test.

```elixir
def sections(data, opts \\ []) do
  validate_data!(data)
  template = page_template(opts)
  # ...
end
```

---

_Reviewed: 2026-08-27T13:33:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

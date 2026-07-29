---
phase: 122-typography-type-scale-application-font-role-leading-wiring
reviewed: 2026-07-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/rendro/recipes/certificate.ex
  - lib/rendro/recipes/payslip.ex
  - test/rendro/recipes/certificate_typography_test.exs
  - test/rendro/recipes/payslip_opts_threading_test.exs
  - test/rendro/recipes/themed_render_smoke_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 122: Code Review Report

**Reviewed:** 2026-07-28
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the gap-closure diff (`553f748^..HEAD`) for plan 122-05: the Payslip
`typography/1` themed-font remap to `:payslip_sans` (CR-01), the Certificate
`centering_measure_font/1` guard (WR-01), and three new/edited test files (WR-02).

The two core fixes are **correct**. The Payslip theme branch now pins all three
font roles to the fallback-bearing `:payslip_sans`, and both the no-theme string
`"Helvetica"` and the themed `:payslip_sans` resolve to the same font resource, so
the fix restores the B612 unicode fallback without disturbing byte-identity. The
Certificate guard keys the centering-measurement font off the same role the run
emits and raises honestly on a non-Helvetica-metric role; the no-theme `:default`
path still measures against `helvetica/0` exactly as before. I verified all 20
tests in the three files pass and that no golden files changed in the diff.

No BLOCKER/Critical defects found in the changed code. Two WARNING-level quality
issues and one INFO item follow — the most substantive is a raw `KeyError`
(not an errors-as-product message) that surfaces on a partial `:typography`
override, which undermines the very "honest error" contract WR-01 was fixing.

## Warnings

### WR-01: Partial `:typography` override raises a raw `KeyError`, not an errors-as-product message

**File:** `lib/rendro/recipes/certificate.ex:553`, `lib/rendro/recipes/payslip.ex:904`
**Issue:** Both `typography/1` seams merge the caller override with a shallow
`Map.merge(base, Keyword.get(opts, :typography, %{}))`. Because `Map.merge` is
shallow, a caller passing only part of the nested `fonts` (or `scale`) map
**replaces the whole nested map**, dropping the other keys. The downstream reads
`type.fonts.body` / `type.fonts.heading` (and `type.scale.*`) then blow up with a
raw `KeyError` instead of the instructive raise the module otherwise prides itself
on. This directly weakens the WR-01 fix: the new `centering_measure_font/1` guard
is designed to fail loudly with an actionable message, but a partial override
never reaches the guard — it dies one layer up with an opaque error. Confirmed
empirically:

```
Rendro.Recipes.Certificate.sections(data, typography: %{fonts: %{heading: :default}})
# ** (KeyError) key :body not found in: %{heading: :default}
```

The `:typography` opt is a documented, caller-facing seam ("winning override
layer ... mirrors :palette"), so a partial `fonts`/`scale` map is a plausible
input. This is pre-existing to plan 122-05 (introduced by the 122-02/03 seams) but
is squarely in the newly-touched code path and contradicts the errors-as-product
posture the guard establishes.
**Fix:** Deep-merge the nested `fonts` and `scale` maps (so partial overrides keep
the recipe defaults), or validate the override shape and raise an instructive
error. For example:

```elixir
override = Keyword.get(opts, :typography, %{})

base
|> Map.merge(override)
|> Map.put(:fonts, Map.merge(base.fonts, Map.get(override, :fonts, %{})))
|> Map.put(:scale, Map.merge(base.scale, Map.get(override, :scale, %{})))
```

### WR-02: `certificate_typography_test` coupling test does not verify what its name claims

**File:** `test/rendro/recipes/certificate_typography_test.exs:46-53`
**Issue:** The test is named *"the themed render matches the no-theme render's
centering (both :default → Helvetica)"*, but the two assertions only check that
`Certificate.sections/2` returns a non-empty `[%Rendro.Section{} | _]` in each
case. It never compares the themed and no-theme section geometry (the `x`/`width`
centering values), so it cannot detect a real de-centering regression — it only
proves neither call raises. The name and the WR-01 coupling intent oversell the
actual coverage.
**Fix:** Either rename the test to reflect what it asserts ("themed and no-theme
section builds both succeed without raising"), or strengthen it to actually
compare the centered blocks' geometry, e.g. assert
`Certificate.sections(data) == Certificate.sections(data, theme: Rendro.Theme.default())`
(the shipped default theme should produce identical centering) or compare the
`x`/`width` of the extracted centered blocks.

## Info

### IN-01: Payslip themed fixture duplicated across two test files

**File:** `test/rendro/recipes/payslip_opts_threading_test.exs:88-111`,
`test/rendro/recipes/themed_render_smoke_test.exs:73-88`
**Issue:** The masked-middot + accented Payslip fixture (employer/employee/period/
earnings/deductions/net_pay 3480.00) is copy-pasted verbatim into both the CR-01
regression test and the cross-recipe smoke test. If the reconciliation invariant
or fixture shape ever changes, both copies must be updated in lockstep.
**Fix:** Acceptable as-is — the smoke test is intentionally self-contained (per the
plan, "do not import private test helpers"). If desired, extract a shared
`Rendro.RecipeFixtures` test-support module. Low priority.

---

_Reviewed: 2026-07-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

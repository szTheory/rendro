---
phase: 117-edge-case-stress-matrix
reviewed: 2026-07-18T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - test/support/golden.ex
  - test/support/golden_test.exs
  - test/support/edge_fixtures.ex
  - test/support/edge_fixtures_test.exs
  - test/rendro/edge_matrix_test.exs
  - test/rendro/edge_error_matrix_test.exs
  - test/rendro/adapters/pdfium_raster_snapshot_test.exs
  - test/docs_contract/branding_claims_test.exs
  - test/docs_contract/rubric_manifest_contract_test.exs
  - priv/quality/rubric_scores.json
  - priv/schemas/rubric_scores.schema.json
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 117: Code Review Report

**Reviewed:** 2026-07-18
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the edge-case stress-matrix test/infra phase. The core correctness
machinery is sound and I could not surface any BLOCKER:

- **Bless discipline (golden.ex)** is correct. `cond` ordering puts `BLESS=true`
  before the missing-ref flunk (so a bless creates the ref), a missing ref
  hard-flunks with no auto-create, `assert_deterministic!/1` renders twice and
  byte-compares before any hash is taken, and only the one-line hash is ever
  written (never PDF bytes). Verified against `golden_test.exs`.
- **Coverage ratchet (edge_matrix_test.exs)** cannot pass vacuously. `@matrix`
  drives test generation directly, and three independent meta-tests pin it:
  every pair present (`all_pairs -- Map.keys(@matrix)`), `map_size == 102`, and
  `:applies == 62`. Confirmed 17 dimensions × 6 families = 102, hand-counted 62
  `:applies`, and confirmed **62 `.sha256` refs are committed** under
  `priv/goldens/` with filenames that map exactly onto the `:applies` cells.
- **document/2 coverage** — traced every `:applies` cell to a `build/2`/`opts/2`
  clause or a dedicated `document/2` clause; all six recipes expose
  `sections/2`, `page_template/1`, `document/2` with default opts (verified in
  `lib/`), so the arity-1/0 calls in the odd/even and currency_format clauses
  resolve.
- **D-15 rubric guards** fail loud in both directions; the teeth guard
  (`stress_fixture_ids` size == 62) correctly prevents the disjointness check
  from passing vacuously on the stress side.
- **Schema/manifest** — `stress_exemption` is in root `required`, `exempt` is
  `const true`, `reason` has `minLength: 1`; manifest satisfies all of it.

Remaining findings are test-quality defects (a tautological "coverage" test, a
brittle full-prose equality that contradicts the file's own stated idiom) plus
minor maintainability notes. No security surface (no external input; the only
shell-out interpolates a Mix version string).

## Warnings

### WR-01: "Coverage discipline" meta-test is tautological — it can never fail

**File:** `test/rendro/edge_error_matrix_test.exs:95-101`
**Issue:** The test asserts `@error_cases == [:overflow, :tall_row, :rtl_default_font, :rtl_shaping_required]`, but `@error_cases` is *defined* as exactly that literal (line 27). This is `x == x` on a compile-time constant — the assertion is structurally incapable of failing. It provides zero drift protection: `@error_cases` is never wired to the four hand-written tests (unlike `@matrix` in `edge_matrix_test.exs`, which actually *generates* its tests), so adding/removing an error case or renaming a test leaves this "discipline" guard green. In a phase whose thesis is coverage honesty, a coverage guard that cannot fail is a real defect.
**Fix:** Make the constant load-bearing so drift is detectable, e.g. drive the four assertions from `@error_cases`:
```elixir
@error_fixtures %{
  overflow: {&EdgeFixtures.overflow_document/0, :paginate, :content_overflow},
  tall_row: {&EdgeFixtures.tall_row_document/0, :paginate, :content_overflow},
  rtl_default_font: {&EdgeFixtures.rtl_default_font_document/0, :measure, nil},
  rtl_shaping_required: {&EdgeFixtures.rtl_shaping_required_document/0, :measure, nil}
}

test "exactly the mapped engine-level inputs are covered" do
  assert Map.keys(@error_fixtures) |> Enum.sort() == Enum.sort(@error_cases)
end
```
so a new `@error_cases` entry without a fixture (or vice-versa) fails.

### WR-02: Full-prose `error.next ==` equality contradicts the module's own D-07 substring doctrine and is brittle

**File:** `test/rendro/edge_error_matrix_test.exs:34-36, 46-48`
**Issue:** The module docstring (lines 12-16) explicitly states the D-07 idiom: assert `next`/`why` **as SUBSTRINGS — never on full error-prose equality (wording may drift)**. Both overflow tests then do exactly that: `assert error.next == "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."` — a hardcoded full-prose literal, duplicated in two places. A benign copy-edit to that engine message flaps both assertions and reads as a regression. Note `edge_fixtures_test.exs:215` tests the *same* path with the robust substring form (`e.next =~ "does not auto-fit"`), so the codebase is internally inconsistent about it.
**Fix:** If the intent is to prove both overflow paths converge on an identical `next` (per the line-46 comment), compare the two runtime values instead of a literal, and use a substring for the content assertion:
```elixir
# in a shared setup or by capturing both errors:
assert overflow_err.next == tall_row_err.next          # proves convergence
assert overflow_err.next =~ "does not auto-fit"        # proves content, drift-tolerant
```

## Info

### IN-01: `long_text/1` depends on an unstated 55-byte invariant of its seed string

**File:** `test/support/edge_fixtures.ex:397-401`
**Issue:** `String.duplicate(base, div(n, 55) + 1) |> binary_part(0, n)` hard-codes `55` as the byte length of the Lorem seed. It happens to be exactly 55 bytes today, so provisioning is always `>= n`. But if the seed string is ever edited to fewer than 55 bytes, `(div(n,55)+1)*len < n` and `binary_part/2` raises `ArgumentError` for larger `n` (e.g. the 600-byte `tall_row` cell) — a fragile coupling with no guard.
**Fix:** Derive the length instead of hardcoding: `seed = "..."; String.duplicate(seed, div(n, byte_size(seed)) + 1) |> binary_part(0, n)`.

### IN-02: `@task1_cells`/`@task2_cells` hand-duplicate `@matrix` with no cross-check

**File:** `test/support/edge_fixtures_test.exs:9-60, 142-155`
**Issue:** `edge_matrix_test.exs` documents `@matrix` as "the single, honest source of truth" for `:applies` cells, but `edge_fixtures_test.exs` maintains a parallel hand-written list of the same cells with nothing tying the two together. A future `:applies` cell added to `@matrix` but forgotten here silently loses its render smoke-test (it would still be golden-checked, but the honesty invariant is weakened), and a typo here that isn't in `@matrix` goes unnoticed.
**Fix:** Import the truth set instead of re-typing it, e.g. iterate `Rendro.EdgeMatrixTest.stress_fixture_ids()` (or expose the `:applies` `{family, dimension}` pairs) and assert each renders, so the two files cannot drift.

### IN-03: `passed?/2` hardcodes the hierarchy dimension name rather than reading it from the manifest

**File:** `test/docs_contract/rubric_manifest_contract_test.exs:33-45`
**Issue:** `passed?/2` hardcodes `dimension_scores["content_hierarchy"] == 5` and `Map.delete("content_hierarchy")`, duplicating a value the manifest already carries at `thresholds.hierarchy_dimension`. The schema pins that to `const "content_hierarchy"`, so it can't currently diverge, but the arithmetic helper silently ignores the manifest's own declared hierarchy dimension. If the schema const is ever relaxed, the helper would test the wrong dimension without failing.
**Fix:** Read `thresholds["hierarchy_dimension"]` and use it as the key to delete/check, keeping the helper aligned with the manifest it validates.

### IN-04: `assert_deterministic!/1` surfaces a raw `MatchError` on render failure instead of a clear assertion

**File:** `test/support/golden.ex:28-29`
**Issue:** `{:ok, pdf1} = Rendro.render(...)` raises a cryptic `MatchError` if a fixture unexpectedly returns `{:error, %Rendro.Error{}}`, obscuring the actual pipeline error in the failure output for all 62 generated golden tests.
**Fix:** Pattern-match with a message, e.g. `assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)` (and same for `pdf2`), so a render regression reports the `Rendro.Error` rather than a bare `MatchError`.

---

_Reviewed: 2026-07-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

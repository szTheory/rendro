---
phase: 95-header-duplex-proof-metadata-reconcile
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - test/rendro/flow_test.exs
  - test/rendro/pipeline/paginate_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 95: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Phase 95 (PROOF-01) added four HEADER-specific `only_on: :odd | :even` tests:

- `test/rendro/flow_test.exs`: three new tests — header parity over 4 pages (L330), single-page odd-only header (L396), header+footer coexistence (L458).
- `test/rendro/pipeline/paginate_test.exs`: one new test — header parity coexisting with restart section tokens (L840).

I verified the load-bearing layout arithmetic against `lib/rendro/pipeline/measure.ex`:
`body_capacity` subtracts header/footer height only when those regions geometrically overlap the body region (L483-510). In all three new flow_test templates the header (y:24, h:16 → spans 24..40) and footer (y:190, h:16 → spans 190..206) do **not** overlap the body (y:52, h:60 → spans 52..112), so `body_capacity = 60`. With default text `12 * 1.2 = 14.4` per line (`lib/rendro/text.ex:18,20`), 60/14.4 = 4.16 → 4 lines/page. The page-count claims (16→4 pages, 1→1 page, 8→2 pages) are therefore arithmetically correct. The `{{page_number}}` substitution path (`lib/rendro/pipeline/paginate.ex:670-680`) and `apply_only_on` (L729-739) back the assertions, and the passing `(... ) Tj` asserts prove the content stream is uncompressed so the `refute "{{page_number}}"` token-leak guards are meaningful.

The defects below concern **what the tests actually prove**: two of the three new flow_test tests use only positive substring assertions and would pass even if `only_on` were a complete no-op (false-positive coverage). The paginate_test addition uses exact-list equality and does not share this weakness.

## Warnings

### WR-01: Header parity test passes even if `only_on` is completely broken (false-positive coverage)

**File:** `test/rendro/flow_test.exs:330-394`
**Issue:** The test only makes positive substring assertions:
```elixir
assert pdf =~ "(Odd 1) Tj"
assert pdf =~ "(Even 2) Tj"
assert pdf =~ "(Odd 3) Tj"
assert pdf =~ "(Even 4) Tj"
refute pdf =~ "{{page_number}}"
```
Because the odd section renders `"Odd {{page_number}}"` and the even section renders `"Even {{page_number}}"`, and the token is the *physical* page number, a broken `only_on` that renders **both** sections on **every** page produces exactly: page 1 → "Odd 1" + "Even 1", page 2 → "Odd 2" + "Even 2", page 3 → "Odd 3" + "Even 3", page 4 → "Odd 4" + "Even 4". Every asserted string (`(Odd 1)`, `(Even 2)`, `(Odd 3)`, `(Even 4)`) is still present in that broken output, so the test would pass. It does not actually prove parity — it only proves "some text containing each label exists somewhere." This is the central PROOF-01 claim (physical-page parity for headers) and it is not being proven.
**Fix:** Add negative assertions for the wrong-parity strings that should NOT appear:
```elixir
# Even header must NOT appear on odd pages; odd header must NOT appear on even pages.
refute pdf =~ "(Even 1) Tj"
refute pdf =~ "(Odd 2) Tj"
refute pdf =~ "(Even 3) Tj"
refute pdf =~ "(Odd 4) Tj"
```
Alternatively, follow the stronger paginate_test pattern and assert exact per-page block lists via `paginate_flow/1` + `page_texts/1` instead of substring matching on the rendered PDF.

### WR-02: Header+footer coexistence test passes even if `only_on` is completely broken (same false-positive)

**File:** `test/rendro/flow_test.exs:458-545`
**Issue:** Identical weakness to WR-01. With a no-op `only_on`, page 1 emits "HOdd 1"/"HEven 1"/"FOdd 1"/"FEven 1" and page 2 emits "HOdd 2"/"HEven 2"/"FOdd 2"/"FEven 2". The four positive asserts (`(HOdd 1)`, `(FOdd 1)`, `(HEven 2)`, `(FEven 2)`) all match in that broken case, so the test cannot detect a parity regression. The test comment claims it proves "Header parity and footer parity are driven by independent region_entries keys and do not interfere," but the assertions do not distinguish the correct behavior from the failure mode where the parity filter is bypassed entirely. The test also never asserts the page count (it relies on the comment "8 body lines / 4-per-page = 2 physical pages") so a regression in pagination would silently change which page each label lands on without failing.
**Fix:** Add wrong-parity refutes and pin the page count:
```elixir
assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2
refute pdf =~ "(HEven 1) Tj"
refute pdf =~ "(FEven 1) Tj"
refute pdf =~ "(HOdd 2) Tj"
refute pdf =~ "(FOdd 2) Tj"
```

## Info

### IN-01: Single-page header test uses an over-broad refute that also masks token-leak detection scope

**File:** `test/rendro/flow_test.exs:455`
**Issue:** `refute pdf =~ "(Even"` is the only new test that actually guards against the wrong-parity section appearing — good. But the matcher is broader than the rendered token form (`(Even 1) Tj`) and would also fail on any unrelated future content beginning with `(Even`. More importantly, this is the correct *pattern* the other two tests (WR-01, WR-02) are missing; consider tightening to the exact rendered form for consistency and to document intent:
```elixir
refute pdf =~ "(Even 1) Tj"
```
This keeps the negative guard precise and parallels the positive `(Odd 1) Tj` assertion.

### IN-02: Duplicated `name: :duplex_header_test` template literal across two tests

**File:** `test/rendro/flow_test.exs:330-360` and `396-426`
**Issue:** The header-parity test (L330) and the single-page test (L396) declare byte-identical `Rendro.page_template(name: :duplex_header_test, ...)` blocks (~30 lines each), and the coexistence test (L458) repeats most of the same geometry with a footer added. The file already establishes a helper-function convention in `paginate_test.exs` (`flow_keep_chain_template/0`, `section_context_template/0`). Re-using the same `name:` atom in two independent tests is harmless under `async: true` here (templates are passed per-document), but the copy-paste increases the chance a future edit updates one template and not its twin, silently desynchronizing the two tests' assumptions.
**Fix:** Extract a private helper, e.g. `defp duplex_header_template(extra_regions \\ []) do ... end`, and call it from both tests so the geometry stays single-sourced.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

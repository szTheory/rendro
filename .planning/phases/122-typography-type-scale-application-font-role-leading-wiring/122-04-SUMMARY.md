---
phase: 122-typography-type-scale-application-font-role-leading-wiring
plan: 04
subsystem: recipes
tags: [typography, type-scale, teeth-test, static-scan, phase-gate, byte-identity, TYPE-01]

# Dependency graph
requires:
  - phase: 122-01
    provides: "Invoice defp typography/1 tracer — the first seamed call sites the teeth test guards"
  - phase: 122-02
    provides: "Statement/Receipt/Payslip typography seams"
  - phase: 122-03
    provides: "BrandedInvoice/Certificate/Ticket typography seams — all 7 recipes now seamed, making the teeth test green"
  - phase: 120-s1-retrofit-theme-swap
    provides: "no_inline_color_literals_test.exs — the exact static-scan template copied here"
provides:
  - "test/rendro/recipes/no_inline_size_literals_test.exs — TYPE-01 static-scan teeth test: fails the build on any re-introduced inline numeric size: literal in a recipe section builder"
  - "Full-suite phase gate proven: all 7 byte-identity goldens, edge_matrix, the 7 opts-threading tests, the raise-path tests, and both static-scan guards green with zero re-bless"
affects: [123-from-brand-rubric-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "size-axis twin of no_inline_color_literals_test.exs: @size_literal regex keyed on a DIGIT after size: so variable reads (size: type.scale.body, size: @caption_size, size: size) never match — only a hardcoded number trips it"
    - "body-exclusion helper generalized to the typography/1 seam (typography_body_indices/1 mirrors palette_body_indices/1), where the literal role-default scale legitimately lives"
    - "narrow allowlist for the two legit literal homes: @*_size attr-definition lines and Certificate's Rendro.text(\"\", size: 1) layout spacer"

key-files:
  created:
    - test/rendro/recipes/no_inline_size_literals_test.exs
  modified: []

key-decisions:
  - "Regex keyed on a numeric literal (\\bsize:\\s*\\d+(?:\\.\\d+)?\\b) rather than any size: — this is what makes size: @caption_size / size: type.scale.<role> / size: size (all VARIABLE reads) inherently non-matching, so the teeth test needs no per-recipe allowlist for the exempt mono micro-sizes."
  - "Certificate's size: 1 spacer allowlisted by an explicit @spacer_line guard (Rendro.text(\"\", size: 1)) rather than a line-number allowlist — survives refactors that move the spacer."
  - "@*_size attr-definition lines excluded for robustness even though they carry no size: colon (so they cannot match the regex anyway) — defensive against future attrs written as size: N."
  - "The two pre-existing DxLocalReproducibilityClaimsTest failures are out-of-scope (SCOPE BOUNDARY): they fail on the HEAD~1 base independent of this change, read absent 113 planning artifacts, and are already logged in the phase deferred-items.md. Not fixed here."

patterns-established:
  - "A phase that seams N call sites closes with a static-scan teeth test guarding the seam against re-introduction, mirroring the color-axis PLUMB-02 guard from phase 120."

requirements-completed: [TYPE-01]

coverage:
  - id: D1
    description: "A source-scan teeth test guards against re-introducing inline size: literals on seamed call sites across all 7 recipes, excluding the typography/1 body, @*_size attr definitions, and the Certificate size: 1 layout spacer"
    requirement: TYPE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/no_inline_size_literals_test.exs (violations == [] across all 7 recipe files)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The full suite is green: all 7 byte-identity goldens, edge_matrix, the 7 opts-threading tests, the raise-path tests, and both static-scan guards"
    requirement: TYPE-01
    verification:
      - kind: unit
        ref: "mix test test/rendro/recipes/ test/rendro/edge_matrix_test.exs (3 doctests, 431 tests, 0 failures, zero re-bless)"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-27
status: complete
---

# Phase 122 Plan 04: TYPE-01 teeth test + full-suite phase gate Summary

**Added `no_inline_size_literals_test.exs` — the size-axis twin of the phase-120 color guard — whose numeric-literal regex trips only on a re-introduced hardcoded `size:` number (never on the `size: type.scale.<role>` / `size: @attr` variable reads), and confirmed the phase-gate suite (all 7 byte-identity goldens, edge_matrix, the 7 opts-threading tests, the raise-path tests, both static-scan guards) is green with zero re-bless.**

## Performance

- **Duration:** ~4 min
- **Tasks:** 2 (teeth test + phase gate)
- **Files created:** 1 · **Files modified:** 0

## Accomplishments
- Created `test/rendro/recipes/no_inline_size_literals_test.exs` by copying `no_inline_color_literals_test.exs` verbatim and adapting to the size axis:
  - `@size_literal ~r/\bsize:\s*\d+(?:\.\d+)?\b/` — matches a numeric literal directly after `size:`, so `size: type.scale.body`, `size: @caption_size`, and `size: size` (all variable reads) are excluded **by construction**.
  - `typography_body_indices/1` (mirroring `palette_body_indices/1`) excludes the `defp typography(opts)` body, where the literal role-default `scale: %{display: 20, ...}` legitimately lives.
  - `allowlisted?/1` narrowly exempts the two legit literal homes: Certificate's `Rendro.text("", size: 1)` layout spacer (`@spacer_line`) and any `@*_size` attr-definition line (`@size_attr_def`).
  - Reuses `comment_line?/1` and the `Enum.flat_map` violation collector as-is; asserts `violations == []` across all 7 recipe files.
- Verified the teeth test is green — the only numeric `size:` literals in the tree are Certificate's `size: 1` spacer (allowlisted) and an `# ...size: 10...` comment in invoice.ex (excluded); every seamed call site reads `size: type.scale.<role>`.
- Ran the phase gate: recipes + edge_matrix = **431 tests, 0 failures**; full `mix test` = 1676 tests with only the 2 pre-existing out-of-scope `DxLocalReproducibilityClaimsTest` failures. **Zero golden re-bless** — `priv/goldens/` is untouched.

## Task Commits

1. **Task 1: Add the no-inline-size-literals teeth test (TYPE-01 guard)** — `79d2805` (test)
2. **Task 2: Full-suite phase gate** — verification-only, no source change / no commit.

## Files Created/Modified
- `test/rendro/recipes/no_inline_size_literals_test.exs` — NEW: TYPE-01 static-scan teeth test.

## Decisions Made
- **Numeric-keyed regex is the mechanism, not an allowlist.** Keying `@size_literal` on a digit after `size:` is precisely what makes Ticket's exempt mono micro-sizes (`size: @caption_size`, `size: @present_code_size`) and every `size: type.scale.<role>` read inherently non-matching — no per-recipe carve-out needed for the variable reads.
- **Spacer allowlisted by content, not line number.** `@spacer_line` matches `Rendro.text("", size: 1)` so the guard survives edits that move the Certificate spacer.
- **Out-of-scope failures left alone.** The 2 `DxLocalReproducibilityClaimsTest` failures fail on the HEAD~1 base independent of this change (confirmed by re-running on the base), read absent Phase 113 planning artifacts, and are already logged in the phase `deferred-items.md`. Per the SCOPE BOUNDARY rule they are not fixed here.

## Deviations from Plan
None — plan executed exactly as written. Task 2's "mix test passes with zero failures" acceptance was met for every phase-gate target (all recipe/typography suites + both static-scan guards, 431 tests green, zero re-bless); the 2 residual full-suite failures are pre-existing, unrelated, and out of scope (documented above and in `deferred-items.md`).

## Issues Encountered
- Two pre-existing `Rendro.DocsContract.DxLocalReproducibilityClaimsTest` failures persist (they read `.planning/phases/113-.../113-UAT.md` + reports that are absent from this working tree). Confirmed to fail on the pre-122-04 base commit. Out of scope; logged in `deferred-items.md`.

## Known Stubs
None — the teeth test is a live static scan over the real recipe source; no placeholder/empty data paths introduced.

## User Setup Required
None.

## Next Phase Readiness
- The typography seam is now guarded on both axes (color via phase-120's `no_inline_color_literals_test.exs`, size via this plan's `no_inline_size_literals_test.exs`). All 7 recipes are typography-seamed and the invariant has teeth.
- Phase 122 is complete and ready for `/gsd-verify-work`.

## Self-Check: PASSED

`test/rendro/recipes/no_inline_size_literals_test.exs` exists on disk; commit `79d2805` is present in git history. Phase-gate suite green (431 tests, 0 failures) with zero golden re-bless.

---
*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Completed: 2026-07-27*

---
phase: 120
plan: 04
subsystem: recipes
tags: [theme-swap, color-seam, byte-identity, invoice, payslip, ticket, source-scan, plumbing]
requires:
  - lib/rendro/recipes/invoice.ex (existing palette/1 seam + Keyword.take whitelist)
  - lib/rendro/recipes/payslip.ex (existing palette/1 seam + whitelist)
  - lib/rendro/recipes/ticket.ex (existing palette/1 seam + whitelist)
  - lib/rendro/theme.ex (Rendro.Theme.resolve/1 — deep-merges + validates 9 color roles)
  - Plan 03 swap pattern (theme-branch transform mirrored here)
provides:
  - Rendro.Recipes.Invoice.palette/1 theme branch (theme.colors recolors ink/muted/accent reads)
  - Rendro.Recipes.Payslip.palette/1 theme branch (theme recolors ink/muted/surface/rule reads)
  - Rendro.Recipes.Ticket.palette/1 theme branch (theme recolors ink/muted/rule reads)
  - test/rendro/recipes/no_inline_color_literals_test.exs (phase-wide PLUMB-02 completeness guard)
affects:
  - Phase 120 close — all 7 recipes now themable, no-theme byte-identity intact, colors-only
tech-stack:
  added: []
  patterns:
    - "Shared Pattern A Commit-2 (swap): defp palette(opts) -> base = case opts[:theme] do nil -> literal-defaults; theme -> Rendro.Theme.resolve(theme).colors end; Map.merge(base, Keyword.get(opts, :palette, %{}))"
    - "phase-wide static source-scan: color-context-keyed regex (color:/fill:/stroke: + literal triple) excludes palette/1 role maps + non-color numerics by construction"
    - "typography-free static guard: no .typography read on any non-comment line (D-04 colors-only boundary)"
key-files:
  created:
    - test/rendro/recipes/payslip_opts_threading_test.exs
    - test/rendro/recipes/ticket_opts_threading_test.exs
    - test/rendro/recipes/no_inline_color_literals_test.exs
  modified:
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/payslip.ex
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/invoice_opts_threading_test.exs
decisions:
  - "The three seamed recipes had byte-identical palette/1 functions; each received the identical single case opts[:theme] branch mirroring Plan 03's statement.ex transform verbatim (all-black-ink / white-surface literals as the nil branch)."
  - "Source-scan detection is keyed on color:/fill:/stroke: assignment context rather than bare tuples, so palette/1 role-default maps (ink: {0,0,0}) and non-color numerics (width: 0.75, geometry) are excluded by construction — the explicit palette/1 body-range exclusion is a redundant second safety layer."
  - "Seam doc-comments say 'no type-scale read' (not the literal token 'typography') mirroring the Plan 03 precedent, so any phase-wide grep-based typography guard stays clean; the new scan test itself excludes comment lines anyway."
metrics:
  duration: ~10m
  completed: 2026-07-27
  tasks: 2
  files: 7
status: complete
---

# Phase 120 Plan 04: Invoice + Payslip + Ticket theme swap + PLUMB-02 source-scan Summary

Completed the theme swap on the 3 already-seamed recipes (Invoice, Payslip, Ticket) — a swap-only, single `case opts[:theme]` branch added to each existing `palette/1` (nil branch keeps the current literal defaults byte-identically, theme branch reads `Rendro.Theme.resolve(theme).colors`, `Map.merge(base, :palette-override)` keeps `:palette` the winning layer per D-01) — and added the phase-wide PLUMB-02 completeness guard proving no inline `{r,g,b}` color literal remains in any recipe section builder. Commit-set 2 (swap), committed separately from the Plan 01/02 retrofit. This closes Phase 120: all 7 recipes are themable, the no-theme path is byte-identical, and the recipe layer is colors-only (no typography).

## What was built

**Task 1 — Invoice + Payslip + Ticket swap + threading tests (commit 10778ef)**
- `invoice.ex`, `payslip.ex`, `ticket.ex` `palette/1`: each wrapped its identical `ink {0,0,0}` / white-surface literal map in `case opts[:theme]` (`nil ->` that exact map verbatim; `theme -> Rendro.Theme.resolve(theme).colors`). Their section builders (which read `colors.ink` / `colors.muted` / `colors.surface` / `colors.rule` / `colors.accent`) now recolor under a theme. The trailing `Map.merge(base, Keyword.get(opts, :palette, %{}))` is unchanged so `:palette` stays the winning override layer (D-01). Swap-only: no section-builder edits, no `Keyword.take` whitelist edits, no typography reads.
- `invoice_opts_threading_test.exs`: extended with a new `Invoice :theme threading` describe block (`:theme` threads through `page_template/1` without KeyError; themed render differs from no-theme; `:palette` override wins over `:theme`; no-theme `sections(data) == sections(data, [])`). The pre-existing `:palette`-changes-only-the-footer invariant test (D-01) is untouched and stays green.
- New `payslip_opts_threading_test.exs` + `ticket_opts_threading_test.exs`: each with the four standard assertions (theme threads without KeyError; themed differs; `:palette` wins over `:theme`; no-theme byte-identity) using the recipes' own valid fixtures (mirrored from their byte-identity tests).

**Task 2 — phase-wide source-scan guard (commit 008ac01)**
- New `no_inline_color_literals_test.exs`: a pure ExUnit static-source test (no rendering) that reads each `lib/rendro/recipes/*.ex`, excludes the `defp palette(opts)` body range and comment lines, and asserts no inline `{r,g,b}` literal is assigned to a `color:` / `fill:` / `stroke:` context. Detection is keyed on the color-context assignment so palette/1 role maps (`ink: {0,0,0}`), variable reads (`color: colors.rule`), and non-color numerics (`width: 0.75`, geometry) are excluded by construction. On failure it reports offending `file:line`. A second test asserts the recipe layer is typography-free — no `.typography` read on any non-comment line (D-04).

## Verification

- `mix test` on the 3 `*_opts_threading_test.exs` + `invoice_byte_identity_test.exs` + `edge_matrix_test.exs` — 92 tests, 0 failures; the invoice legacy `:palette`-footer invariant preserved.
- `mix test payslip_byte_identity_test.exs ticket_byte_identity_test.exs` — 5 tests, 0 failures; frozen sha256 goldens green with NO re-bless (no-theme path byte-identical, PLUMB-03).
- `mix test no_inline_color_literals_test.exs` — 2 tests, 0 failures. Guard teeth proven: injecting `color: {12, 34, 56}` into invoice's footer builder made the test fail loudly with `lib/rendro/recipes/invoice.ex:356: ...`; the file was restored via `git checkout -- lib/rendro/recipes/invoice.ex` and the test returns green.
- Full recipe suite `mix test test/rendro/recipes/ test/rendro/edge_matrix_test.exs` — 3 doctests, 401 tests, 0 failures. All Plan 01/02/03 frozen byte-identity goldens + every edge_matrix cell stayed green with NO re-bless.
- Merge-order guard: each swapped `palette/1` ends with `Map.merge(base, Keyword.get(opts, :palette, %{}))` — `:palette` is the final layer (verified in all 3 files).
- Colors-only guard (D-04): zero `.typography` reads across all recipe files (only a pre-existing layout comment in branded_invoice.ex L169, excluded as a comment line).

## Threat mitigations applied

- **T-120-08 (Tampering, medium, mitigate):** `:theme`/`:palette` color tuples reaching each `palette/1` are deep-merged and validated by `Rendro.Theme.resolve/1` (every role via `Rendro.Color.validate/1`, raising an instructive `ArgumentError` on a malformed token before any draw); `:palette` overrides pass through the same downstream validation.
- **T-120-09 (Repudiation, high, mitigate):** the swap re-ran the Plan 01/02/03 frozen `*_byte_identity_test.exs` + `edge_matrix_test.exs` (no re-bless); the new `no_inline_color_literals_test.exs` permanently guards against a section builder reacquiring an inline color literal (PLUMB-02).

## Deviations from Plan

None — plan executed exactly as written. The three seamed recipes' `palette/1` functions were byte-identical, so the swap transform applied uniformly, and no inline color literals existed in any section builder (the retrofit had already routed every color through `palette/1`), so the new guard passed on first run.

## Known Stubs

None. All 3 theme branches are fully wired to `Rendro.Theme.resolve/1` and read by real draw paths; no placeholder/empty data.

## Self-Check: PASSED

- FOUND: lib/rendro/recipes/invoice.ex (palette/1 case opts[:theme] branch, Map.merge(base, :palette) order)
- FOUND: lib/rendro/recipes/payslip.ex (palette/1 theme branch)
- FOUND: lib/rendro/recipes/ticket.ex (palette/1 theme branch)
- FOUND: test/rendro/recipes/invoice_opts_threading_test.exs (extended with :theme cases)
- FOUND: test/rendro/recipes/payslip_opts_threading_test.exs
- FOUND: test/rendro/recipes/ticket_opts_threading_test.exs
- FOUND: test/rendro/recipes/no_inline_color_literals_test.exs
- FOUND commit 10778ef (Task 1)
- FOUND commit 008ac01 (Task 2)

---
phase: 120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes
reviewed: 2026-07-27T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - lib/rendro/recipes/branded_invoice.ex
  - lib/rendro/recipes/certificate.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/ticket.ex
  - test/rendro/recipes/branded_invoice_byte_identity_test.exs
  - test/rendro/recipes/branded_invoice_opts_threading_test.exs
  - test/rendro/recipes/certificate_byte_identity_test.exs
  - test/rendro/recipes/certificate_opts_threading_test.exs
  - test/rendro/recipes/invoice_opts_threading_test.exs
  - test/rendro/recipes/no_inline_color_literals_test.exs
  - test/rendro/recipes/payslip_opts_threading_test.exs
  - test/rendro/recipes/receipt_byte_identity_test.exs
  - test/rendro/recipes/receipt_opts_threading_test.exs
  - test/rendro/recipes/statement_byte_identity_test.exs
  - test/rendro/recipes/statement_opts_threading_test.exs
  - test/rendro/recipes/ticket_opts_threading_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 120: Code Review Report

**Reviewed:** 2026-07-27
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Reviewed the S1 color-seam retrofit + full theme swap across all 7 recipes plus
the accompanying byte-identity, opts-threading, and static no-inline-color tests.

The three primary phase contracts hold up under scrutiny:

1. **`:palette` precedence** — every recipe's `palette/1` ends with
   `Map.merge(base, Keyword.get(opts, :palette, %{}))`. `Map.merge/2` gives the
   second argument (the `:palette` override) priority, so `:palette` correctly
   wins over both the `:theme` base and the literal no-theme defaults (D-01).
   Verified across all 7 files.
2. **No-theme byte identity** — the `nil` branch of each `palette/1` reproduces
   the pre-seam literals (`ink {0,0,0}`, Certificate `rule {34,34,34}`,
   Statement `surface {245,245,245}` / `rule {0,0,0}`). `Rendro.Text` defaults
   `color: {0,0,0}` (confirmed in `lib/rendro/text.ex:19`), so seaming a
   previously-uncolored run to `colors.ink = {0,0,0}` is a true no-op. All 7
   frozen sha256 goldens pass.
3. **Role-read safety** — every `colors.<role>` read (cross-checked by grep) is
   satisfied on BOTH paths: the `nil`-branch maps contain every role each recipe
   reads, and `Rendro.Theme.resolve/1` always deep-merges onto all 9 default
   roles (`lib/rendro/theme.ex:48-58`), so a themed render can never raise
   `KeyError` on a missing role.

All 70 phase tests pass (20 byte-identity/static + 50 opts-threading).

The defects found are not in the no-theme path (which is well-guarded) but in
the **themed** path, which the frozen goldens do not exercise: the swap is
applied unevenly, and one recipe recolors a fill without recoloring the text
that overlays it — producing illegible output under non-light themes.

## Warnings

### WR-01: Statement recolors the closing-balance band fill but not the text overlaying it — illegible under dark/dark-surface themes

**File:** `lib/rendro/recipes/statement.ex:304-318`
**Issue:**
`header_section/2` draws the closing-balance backdrop with a themed fill
(`fill: colors.surface`), then overlays two text blocks via the zero-height
overlay mechanic:

```elixir
closing_backdrop =
  Rendro.path([{:rect, 0, 0, @content_width, @closing_balance_band_h}],
    fill: colors.surface,           # recolors with the theme
    stroke: %{color: colors.rule, ...}, ...)

closing_label = Rendro.block(Rendro.text("#{lbl.(:closing_balance)}", size: 9))
closing_value = Rendro.block(Rendro.text(fmt_amount.(closing_balance), size: 22))
```

`closing_label` and `closing_value` pass **no** `color:`, so they render at
`Rendro.Text`'s default `{0,0,0}` (black). On the default light theme this is
fine (`surface = {247,243,234}`), but the theme swap now makes the fill
theme-dependent while the text stays hardcoded-black. A supported, public call —
`Statement.document(data, theme: Rendro.Theme.dark(Rendro.Theme.default()))` —
paints `surface = {35,32,25}` (near-black) behind a **black** closing-balance
figure, rendering the statement's single most important number invisible.

This is exposed by this phase: pre-swap the band fill was a fixed light
`{245,245,245}`, so black text was always safe. The swap introduced the
divergence. Note `Payslip.summary_section/2` (the pattern Statement's own
comments say it mirrors) does this correctly — its band label/value ARE seamed
to `colors.muted` / `colors.ink` (`payslip.ex:389,392`), so it stays legible in
dark mode. Statement is the inconsistent outlier.

Severity is WARNING because the default (light) theme and the byte-identical
no-theme path are unaffected; it escalates to BLOCKER the moment a dark or
dark-`surface` theme is offered to callers through these recipes.

**Fix:** Seam the overlaid band text the same way Payslip does, choosing a role
that contrasts the band fill:

```elixir
closing_label =
  Rendro.block(Rendro.text("#{lbl.(:closing_balance)}", size: 9, color: colors.muted))

closing_value =
  Rendro.block(Rendro.text(fmt_amount.(closing_balance), size: 22, color: colors.ink))
```

Add `ink` and `muted` to Statement's `nil`-branch map with the byte-identical
value `{0,0,0}` so the no-theme goldens stay frozen, then re-run the byte-identity
test to confirm the hash is unchanged.

### WR-02: `palette/1` duplicated verbatim across five recipes

**File:** `lib/rendro/recipes/invoice.ex:468-487` (and byte-identical copies at
`receipt.ex:474-493`, `branded_invoice.ex:229-248`, `payslip.ex:680-699`,
`ticket.ex:512-531`)
**Issue:** The same 20-line `palette/1` — identical `case opts[:theme]` branch,
identical 7-role `nil` default map, identical `Map.merge` tail — is copy-pasted
into five recipe modules (Certificate and Statement carry near-duplicates with
different `nil` defaults). Any future change to the seam contract (e.g. adding
`positive`/`negative` role defaults, changing the merge precedence, or adding
`:theme` validation) must be made in seven places and can silently drift. The
`no_inline_color_literals_test` guards against inline literals but does nothing
to keep these seven copies in sync.

**Fix:** Extract the shared merge/branch into one helper (e.g.
`Rendro.Recipes.Palette.resolve(opts, no_theme_defaults)`), passing each recipe's
`nil`-branch default map as the only per-recipe argument. The five identical
copies collapse to one call site each; Certificate/Statement pass their own
non-black defaults. Keep the frozen goldens as the regression guard.

## Info

### IN-01: Theme swap leaves primary text runs black in Statement and Certificate

**File:** `lib/rendro/recipes/statement.ex:324-326`, `lib/rendro/recipes/certificate.ex:326-334`
**Issue:** Beyond the WR-01 legibility bug, the swap is only partial in two
recipes. Statement's three header lines (`account_name`, `period_str`, `ob_str`)
and Certificate's entire body (`title`, `"This certifies that"`, `recipient`,
body paragraph, date, seal line via `centered_line/4` / `centered_paragraph/4`)
render with no `color:` and therefore stay black regardless of `:theme`. Because
these sit on the white page background (not a themed fill) they remain legible,
so this is a quality gap rather than a correctness bug: a caller passing a theme
gets a recolored frame/band but black body text — a surprising result for a
"full theme swap." Certificate reads only `colors.rule` (frame); no body text
role is ever consulted.

**Fix:** If full text theming is intended in this phase, route these runs through
`colors.ink` / `colors.muted` (adding `{0,0,0}` defaults to the `nil` branches to
preserve the goldens). If deferred, record it explicitly so the gap is not
mistaken for completed coverage.

### IN-02: `:palette` as a keyword list (instead of a map) raises `BadMapError` rather than an instructive error

**File:** `lib/rendro/recipes/invoice.ex:486` (and the `Map.merge` tail in every
recipe's `palette/1`)
**Issue:** `Map.merge(base, Keyword.get(opts, :palette, %{}))` assumes `:palette`
is a map. A caller passing the ergonomically-plausible keyword form
`palette: [ink: {1,2,3}]` triggers a raw `BadMapError` from deep in `palette/1`
instead of the errors-as-product `ArgumentError` these modules use everywhere
else. This is pre-existing (the phase only added the `case` branch above the
merge), so it is informational, but it is now the seam every theme/palette caller
funnels through.

**Fix:** Either normalize (`Keyword.get(opts, :palette, %{}) |> Map.new()`) or add
an explicit `is_map/1` guard that raises the standard instructive
`ArgumentError`.

---

_Reviewed: 2026-07-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

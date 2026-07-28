---
phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
reviewed: 2026-07-28T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/rendro/launch_artifacts.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/theme.ex
  - mix.exs
  - test/docs_contract/launch_artifacts_claims_test.exs
  - test/docs_contract/rubric_manifest_contract_test.exs
  - test/docs_contract/theming_claims_test.exs
  - test/docs_contract/theming_contract_test.exs
  - test/rendro/examples_data_test.exs
  - test/rendro/launch_artifacts_test.exs
  - test/rendro/theme_test.exs
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 123: Code Review Report

**Reviewed:** 2026-07-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the theming leading change (1.2 → 1.35 in `theme.ex`), the three
theme-gated header/footer geometry budgets it required in `statement.ex`,
`payslip.ex`, and `receipt.ex`, and the launch-artifacts gallery/manifest
expansion to 11 rows (3 dark + 1 `from_brand` variants, `readme_hero`
S7 seam) in `launch_artifacts.ex`. All 13 files' own test suites pass
(307 tests across the listed test files, plus 171 related recipe/golden
tests run for corroboration), and the arithmetic backing the new
`@themed_header_h` / `@themed_header_height` / `merchant_extra_height/1`
budgets checks out against the documented Swiss-print leading math.

However, I traced the exact function this phase modified in
`receipt.ex` (`computed_header_height/2`) through to its only caller
that does *not* thread the result correctly — the recipe's own
documented "escape hatch" usage pattern — and reproduced a live
`:content_overflow` render failure on realistic data (see CR-01). This
is not a byte-identity/PLUMB-03 regression (it reproduces with no theme
at all, so it predates 123), but it lives squarely inside the code this
phase touched, remains untested, and the theming addition makes the
gap *worse* (a themed caller using the escape hatch now needs +48pt the
template never grows by, vs. +40pt before). I'm flagging it because an
adversarial review that stops at "the diff's own new code paths pass"
without walking the call graph of the function that diff renamed
(`computed_header_height/1` → `/2`) would miss it.

I also flag a design gap in all three theme-gated geometry seams: the
new budgets are keyed only on "is `opts[:theme]` present", not on the
actual resolved scale, so a non-default theme or an explicit
`:typography` override can silently defeat the very headroom this phase
added.

## Critical Issues

### CR-01: `Rendro.Recipes.Receipt`'s documented escape hatch crashes with `:content_overflow` when `data` has a `:merchant` (independent of theme, worsened by it)

**File:** `lib/rendro/recipes/receipt.ex:137-145` (moduledoc "Escape hatch" example), `lib/rendro/recipes/receipt.ex:189-209` (`page_template/1`), `lib/rendro/recipes/receipt.ex:535-554` (`computed_header_height/2` / `merchant_extra_height/1`)

**Issue:** `page_template/1` computes `header_height` as
`Keyword.get(opts, :header_height, @default_header_height)` — it never
calls `computed_header_height/2` (the function this phase renamed from
`/1` to `/2` to add the theme branch), because `page_template/1` has no
access to `data` and therefore cannot know whether a `:merchant` block
will be rendered into the header. Only `document/2` correctly
pre-computes `header_height` from `data` + `opts` and threads it via
`Keyword.put_new/3` into `opts` *before* calling both `page_template/1`
and `sections/2`.

The moduledoc's own "Escape hatch" example (and any caller following
it) calls `page_template/1` and `sections/2` independently, exactly the
way `Rendro.Recipes.Receipt.document/2` is *not* implemented. When
`data` carries `:merchant`, `sections/2` (via `body_section/2` →
`computed_header_height/2`) correctly assumes a taller header, but
`page_template/1` still hands back a 48pt `:header` region — so the
merchant identity block itself overflows the too-short region.

Reproduced live against the reviewed code (no theme at all — the
no-theme path already breaks):

```elixir
data = %{
  title: "Payment Receipt",
  date: ~D[2026-05-29],
  customer: %{name: "Acme Corp"},
  merchant: %{name: "Harbor and Oak Cafe",
              address: "123 Dockside Ave, Suite 200, Harbor City, ST 00000"},
  lines: [%{description: "Latte", amount: Decimal.new("4.50")}]
}

template = Rendro.Recipes.Receipt.page_template()
sections = Rendro.Recipes.Receipt.sections(data)
doc = Rendro.Document.new()
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)
      |> then(fn d -> Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1)) end)

Rendro.render(doc, deterministic: true)
# => {:error, %Rendro.Error{reason: :content_overflow, details: %{region: :header, bounds: %{height: 48}, block: %{y: 38.4, height: 16.8}}}}
```

With `theme: Rendro.Theme.default()` threaded the same way (still via
the escape hatch, still no `:header_height` opt), the overflow is
larger (`bounds.height: 48` vs a needed ~96pt) — i.e. this phase's own
`merchant_extra_height/1` themed branch (`+48`) never has a chance to
apply through this path, so the themed escape-hatch case is *worse*
than the no-theme escape-hatch case, not better.

No test in the suite exercises `page_template/1` + `sections/2` called
separately with a `:merchant`-bearing `data` map — the existing
`"a receipt with :merchant ... renders without :content_overflow"` test
(`test/rendro/recipes/receipt_test.exs:169`) only calls
`Receipt.document(data)`, which works precisely because `document/2`
is the one caller that gets the threading right.

**Fix:** Make `page_template/1` and `sections/2` unable to disagree
even when called independently. Two viable options:

1. Expose the merchant-aware height computation publicly and require
   escape-hatch callers to pass it explicitly, e.g.:
   ```elixir
   header_height = Rendro.Recipes.Receipt.header_height_for(data, opts)
   template = Rendro.Recipes.Receipt.page_template(Keyword.put(opts, :header_height, header_height))
   sections = Rendro.Recipes.Receipt.sections(data, Keyword.put(opts, :header_height, header_height))
   ```
   and update the moduledoc's "Escape hatch" example to show this when
   `:merchant` is used.
2. Or, simpler and safer by default: make `page_template/1` accept
   `data` (or a `:merchant?` boolean) so it can independently derive
   the same height `sections/2` will assume, removing the possibility
   of the two disagreeing.

Either way, add a regression test that calls `page_template/1` +
`sections/2` separately (mirroring the moduledoc example) with a
`:merchant` map present, asserting the render succeeds.

## Warnings

### WR-01: Theme-gated geometry safety margins are sized for the *default* theme's scale, not the resolved one

**File:** `lib/rendro/recipes/statement.ex:424-429` (`header_height/1`), `lib/rendro/recipes/payslip.ex:311-323` (`geometry/1`), `lib/rendro/recipes/receipt.ex:546-554` (`merchant_extra_height/1`)

**Issue:** All three new geometry seams key exclusively on whether
`opts[:theme]` is `nil`:

```elixir
defp header_height(opts) do
  case opts[:theme] do
    nil -> @header_height
    _theme -> @themed_header_height
  end
end
```

The fixed themed constant (`@themed_header_height`, `@themed_header_h`,
`+48`) is hand-derived against exactly `Rendro.Theme.default()`'s scale
(`title: 16.5, body: 10.5, small: 9, display: 21`) at `leading: 1.35`
(see the arithmetic in each file's comments, e.g.
`statement.ex:103-113`). Because the gate is "theme present?" rather
than "how big is the resolved scale?", a caller supplying:

- a custom `:theme` whose `:typography.scale` is larger than the
  default (e.g. an accessibility-oriented larger type scale, or
  `Theme.resolve(typography: %{scale: %{title: 40}})`), or
- an explicit `:typography` opt override (which `typography/1` in each
  recipe already supports and lets win over the theme, by design)

gets the *same* fixed themed budget regardless of how much taller the
actual rendered text is — silently reintroducing the exact
`:content_overflow` risk this phase was written to close, just for a
scale the fixed safety margin doesn't happen to cover. No test in the
suite exercises a themed recipe with a non-default scale (the gallery
and golden tests only ever pass `Theme.default()` or `Theme.dark(Theme.default())`
or `from_brand/2`, which does not touch typography at all).

**Fix:** Either (a) derive the header/footer budget from the actually
resolved `typography(opts)` (e.g. sum the real per-line
`size * leading` the header will render, the way the table body already
uses `Rendro.measure_rows` instead of a hand-derived constant), or (b)
explicitly document/assert that `:typography` scale overrides beyond
the shipped default are unsupported for these three recipes' fixed
geometry budgets, so the limitation is discoverable rather than a
silent overflow risk.

### WR-02: Duplicated, hand-derived magic-number geometry seam across three recipes

**File:** `lib/rendro/recipes/payslip.ex:53-66`, `lib/rendro/recipes/statement.ex:103-113,424-429`, `lib/rendro/recipes/receipt.ex:525-554`

**Issue:** The same `case opts[:theme] do nil -> A; _theme -> B end`
geometry-seam shape, with its own independently-derived pt-arithmetic
safety margin (`96`, `28`, `96`, `+48`), is reimplemented three times
with no shared helper. Each margin's correctness rests entirely on
manually transcribed arithmetic living in a code comment (e.g. "6
stacked header blocks ... total ~91.1pt"), not on a computed or
asserted value. A transcription slip in any one recipe (off-by-a-line,
wrong leading figure, etc.) would compile fine and would only be caught
if the golden/raster test for that exact recipe+theme combination
happens to be regenerated and eyeballed — there is no assertion tying
the constant to the arithmetic that justifies it.

**Fix:** Not blocking given this mirrors the codebase's existing
"structural twin" convention for `palette/1`/`typography/1` per recipe,
but consider a shared `Rendro.Recipes.Pagination` helper that takes the
list of `{role, line_count}` pairs a header/footer renders and returns
the required height from the *actual* resolved typography, replacing
the three hand-maintained constants with one computed, testable
function.

## Info

### IN-01: `launch_artifacts.ex` gallery specs carry three new required-shaped tags with no compile-time check that all 11 entries set them

**File:** `lib/rendro/launch_artifacts.ex:59-217` (`@gallery_specs`)

**Issue:** `theme_tag`, `mode_tag`, and `readme_hero` are plain map keys
added ad hoc to each of the 11 `@gallery_specs` entries. Nothing
enforces at compile time (or via a fast unit test independent of a full
`mix rendro.launch_artifacts.gen` regeneration) that every entry
defines all three keys — a future 12th entry that forgets `readme_hero`
would only surface as a `KeyError` inside `build_gallery_entries/1`'s
`Enum.map(@gallery_specs, fn spec -> ... spec.readme_hero ... end)` at
generation time, not at compile time or via a fast static check.

**Fix:** Low priority; consider a small compile-time or test-time
assertion (e.g. `assert Enum.all?(@gallery_specs, &Map.has_key?(&1, :readme_hero))`)
so a missing tag on a newly added spec fails fast with a clear message
instead of a generic `KeyError` deep in `build_gallery_entries/1`.

---

_Reviewed: 2026-07-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

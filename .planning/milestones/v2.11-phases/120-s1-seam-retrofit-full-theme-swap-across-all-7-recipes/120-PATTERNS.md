# Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 16 (7 modified recipe modules + 9 new/modified test files)
**Analogs found:** 16 / 16 (all patterns already exist in-repo; this phase copies them)

> All excerpts below verified by direct read on 2026-07-27. `invoice.ex` is THE
> reference seam for every recipe change; `invoice_byte_identity_test.exs` and
> `invoice_opts_threading_test.exs` are THE reference test shapes. The planner and
> executor should copy these verbatim (adjusting per-recipe literals per D-02).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/statement.ex` (retrofit + swap) | recipe | transform (opts→draw) | `lib/rendro/recipes/invoice.ex` | exact (role + flow) |
| `lib/rendro/recipes/certificate.ex` (retrofit + swap, stress) | recipe | transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/receipt.ex` (retrofit + swap + D-03 ink + whitelist fix) | recipe | transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/branded_invoice.ex` (retrofit + swap + D-03 ink + whitelist fix) | recipe | transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/invoice.ex` (swap-only) | recipe | transform | self (already seamed) | exact |
| `lib/rendro/recipes/payslip.ex` (swap-only) | recipe | transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/ticket.ex` (swap-only) | recipe | transform | `lib/rendro/recipes/invoice.ex` | exact |
| `test/.../statement_byte_identity_test.exs` (new) | test | golden/sha256 | `test/rendro/recipes/invoice_byte_identity_test.exs` | exact |
| `test/.../certificate_byte_identity_test.exs` (new) | test | golden/sha256 | `invoice_byte_identity_test.exs` | exact |
| `test/.../receipt_byte_identity_test.exs` (new) | test | golden/sha256 | `invoice_byte_identity_test.exs` | exact |
| `test/.../branded_invoice_byte_identity_test.exs` (new, net-new golden) | test | golden/sha256 | `invoice_byte_identity_test.exs` | exact |
| `test/.../{statement,certificate,receipt,payslip,ticket}_opts_threading_test.exs` (new) | test | unit/threading | `test/rendro/recipes/invoice_opts_threading_test.exs` | exact |
| (recommended) source-scan test (no inline `{r,g,b}` in sections) | test | static/source-scan | none | no analog |

## Shared Patterns

These three patterns apply to MULTIPLE recipe files. The planner should reference
them once and point each per-file action at them.

### Shared Pattern A — The `palette/1` seam (S1)

**Source:** `lib/rendro/recipes/invoice.ex` L466–481 (verified). Identical copy also
in `payslip.ex` L677–692 and `ticket.ex` L509–524.

**Commit 1 (retrofit) shape** — copy verbatim, substituting THIS recipe's literal
defaults (see per-recipe literal map below):
```elixir
# Returns the role -> RGB map for this render. Defaults reproduce today's
# literals so sections that read colors from here stay byte-identical unless
# the caller supplies a `:palette` override. Any section that sets a color MUST
# source it from here -- never inline a literal {r, g, b} tuple (S1).
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})

  Map.merge(
    %{
      ink: {0, 0, 0},
      muted: {0, 0, 0},
      accent: {0, 0, 0},
      on_accent: {0, 0, 0},
      background: {255, 255, 255},
      surface: {255, 255, 255},
      rule: {0, 0, 0}
    },
    overrides
  )
end
```

**Commit 2 (swap) transform** — apply to ALL 7 `palette/1` functions. Add the
`case opts[:theme]` branch; keep the `Map.merge(base, overrides)` order so the
`:palette` override still wins (D-01):
```elixir
defp palette(opts) do
  base =
    case opts[:theme] do
      nil   -> %{ ...THIS recipe's literal defaults... }   # byte-identical no-theme path
      theme -> Rendro.Theme.resolve(theme).colors           # idempotent; 9 integer-{r,g,b} roles
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))          # :palette override wins (D-01)
end
```
**Apply to:** all 7 recipes. **Critical:** the `nil` branch must reproduce THIS
recipe's exact literals (per-recipe, NOT uniform all-black — see Certificate/Statement).

### Shared Pattern B — Threading `palette(opts)` into section builders

**Source:** `lib/rendro/recipes/invoice.ex` (verified L216/350/407) — each arity-2
section builder opens with `colors = palette(opts)`, then reads roles into draw structs:
```elixir
colors = palette(opts)                                            # L216, L350, L407
# ...
Rendro.block(Rendro.text("...", size: 10, color: colors.ink))    # L356/L375 ink
Rendro.block(Rendro.text(text, size: 10, color: colors.muted))   # L382/L386/L390 muted
# ... color: colors.accent  (L436)   color: colors.muted (L423)
```
**Apply to:** every section builder in the 4 retrofit recipes that draws a color.
Replace each inline `{r,g,b}` (or add an explicit `color:` for D-03) with a `colors.<role>` read.

### Shared Pattern C — `page_template/1` opts whitelist (`Keyword.take`)

**Source:** `lib/rendro/recipes/invoice.ex` L137–149 (verified). Same pattern already
in `statement.ex` L198–210 (so Statement needs NO whitelist change).
```elixir
# page_template/1 only understands PageTemplate struct keys. Recipe-level opts
# (:palette, :theme, :formatters, :labels, ...) are consumed by the section
# builders / palette/1, not by struct!/2 -- filter them out so they thread
# through to sections/2 instead of reaching struct!/2 and raising KeyError.
template_opts =
  Keyword.take(opts, [
    :name, :width, :height,
    :margin_top, :margin_right, :margin_bottom, :margin_left,
    :regions
  ])

Rendro.page_template(Keyword.merge(defaults, template_opts))
```
**Apply to:** Receipt and BrandedInvoice ONLY (they KeyError today — see per-file
gotchas). Do NOT add `:theme`/`:palette` to the whitelist — they must be DROPPED here
so they thread to `palette/1`. Invoice/Statement/Payslip/Ticket already use `Keyword.take`;
Certificate constructs the template with explicit keys (already opts-safe).

## Per-Recipe Literal → Role Map (D-02, reviewable)

`[VERIFIED by direct source read]` — the `nil`/retrofit-default branch of each
`palette/1` MUST reproduce these exact literals:

| Recipe | Inline literal (verified location) | Role binding | Retrofit default |
|--------|-----------------------------------|--------------|------------------|
| Statement | fill `{245,245,245}` (L305), stroke `{0,0,0}` (L306) — `closing_backdrop` | fill→`surface`, stroke→`rule` | `surface {245,245,245}`, `rule {0,0,0}` |
| Certificate | frame `{34,34,34}` (`resolve_frame_opts/7` L374) | frame→`rule` | `rule {34,34,34}` **(NON-BLACK — stress case)** |
| Receipt | none (D-03 implicit-black text) | primary text→`ink` | `ink {0,0,0}` |
| BrandedInvoice | none (D-03 implicit-black text) | primary text→`ink` | `ink {0,0,0}` |
| Invoice/Payslip/Ticket | none (already seamed, all `{0,0,0}`/`{255,255,255}`) | ink/muted/accent/surface/rule | unchanged |

## Pattern Assignments

### `lib/rendro/recipes/statement.ex` (retrofit + swap)

**Analog:** `invoice.ex`. **Whitelist:** already `Keyword.take` at L198–210 — no change.

- **Add** `palette/1` (Shared Pattern A) with retrofit defaults `surface {245,245,245}`, `rule {0,0,0}`.
- **Thread** `colors = palette(opts)` into the section builder that owns `closing_backdrop` (Shared Pattern B).
- **Replace** the inline literals at L305–306:
```elixir
# BEFORE (L303-311):
closing_backdrop =
  Rendro.path([{:rect, 0, 0, @content_width, @closing_balance_band_h}],
    fill: {245, 245, 245},
    stroke: %{color: {0, 0, 0}, width: 0.75},   # width 0.75 STAYS literal (non-color)
    ...)
# AFTER (retrofit): fill: colors.surface, stroke: %{color: colors.rule, width: 0.75}
```
- Keep `width: 0.75` literal (non-color numeric — do NOT seam).

### `lib/rendro/recipes/certificate.ex` (retrofit + swap — STRESS CASE)

**Analog:** `invoice.ex`. **Whitelist:** opts-safe (explicit template construction) — no change.
`@border_allowed_keys` (L62) already lists `:color` — no change.

- **Add** `palette/1` with retrofit default `rule {34,34,34}` (NON-BLACK — must NOT be `{0,0,0}` and must NOT be the theme's `rule {196,188,169}` on the no-theme path).
- **Thread** `colors` into `sections/2` / `resolve_frame_opts`.
- **Change** the frame default at L374 (verified):
```elixir
# BEFORE (L372-378):
%{
  style: Map.get(border_map, :style, :single),
  color: Map.get(border_map, :color, {34, 34, 34}),   # <-- L374
  ...
}
# AFTER: color: Map.get(border_map, :color, colors.rule)   # colors.rule default {34,34,34}
```
- Precedence becomes: explicit `border: %{color: ...}` > theme `rule` > literal `{34,34,34}`. Byte-identical with no border + no theme.
- Byte-identity test MUST include a `border: true` `{34,34,34}` frame case.

### `lib/rendro/recipes/receipt.ex` (retrofit + swap + D-03 ink + WHITELIST FIX)

**Analog:** `invoice.ex`. **GOTCHA (verified live):** `page_template/1` L178 does
`Rendro.page_template(Keyword.merge(defaults, Keyword.delete(opts, :header_height)))`
— forwards `:palette`/`:theme` to `struct!/2` → **raises KeyError today.**

- **Fix** the whitelist (Shared Pattern C) — replace L178:
```elixir
# BEFORE (L176-178):
# 118-08: :header_height is consumed locally above -- never forwarded to struct!/2
Rendro.page_template(Keyword.merge(defaults, Keyword.delete(opts, :header_height)))
# AFTER: build template_opts = Keyword.take(opts, [:name, :width, :height,
#        :margin_top, :margin_right, :margin_bottom, :margin_left, :regions])
#        then Rendro.page_template(Keyword.merge(defaults, template_opts))
#        (:header_height, :palette, :theme all naturally dropped by the take)
```
- **Add** `palette/1` with retrofit default `ink {0,0,0}` (D-03).
- **Add** explicit `color: colors.ink` to primary text runs (title, customer, date, merchant, minor total, dominant total). Byte-identical — verified `color: {0,0,0}` == no color.

### `lib/rendro/recipes/branded_invoice.ex` (retrofit + swap + D-03 ink + WHITELIST FIX)

**Analog:** `invoice.ex`. **GOTCHA (verified live):** `page_template/1` L92 does
`Rendro.page_template(Keyword.merge(defaults, opts))` — forwards EVERYTHING to
`struct!/2` → **raises KeyError today.** **Also: NO existing golden** (`priv/goldens/branded_invoice/` absent — confirmed; only 6 dirs exist) and absent from `edge_matrix`.

- **Fix** the whitelist (Shared Pattern C) — replace L92:
```elixir
# BEFORE (L92):
Rendro.page_template(Keyword.merge(defaults, opts))
# AFTER: template_opts = Keyword.take(opts, [:name, :width, :height,
#        :margin_top, :margin_right, :margin_bottom, :margin_left, :regions])
#        Rendro.page_template(Keyword.merge(defaults, template_opts))
```
- **Add** `palette/1` with retrofit default `ink {0,0,0}` (D-03).
- **Add** explicit `color: colors.ink` to header (brand, id, date) + footer text.
- Requires a **net-new byte-identity test + golden** (nothing to keep green — it's a fresh baseline).

### `lib/rendro/recipes/invoice.ex` / `payslip.ex` / `ticket.ex` (swap-only)

**Analog:** self. Each already has the full `palette/1` seam (Invoice L466, Payslip L677,
Ticket L509 — all verified identical shape) and a `Keyword.take` whitelist.

- **Only change:** apply the Shared Pattern A Commit-2 swap transform (add `case opts[:theme]` branch) and add `:theme`-aware behaviour. Existing literal defaults become the `nil` branch verbatim. No section-builder edits, no whitelist edits, no inline literals to move.
- Invoice's existing `invoice_opts_threading_test.exs` (the ONE `:palette` dependent) MUST stay green — the merge-on-top order guarantees it (D-01).

## Test Pattern Assignments

### `*_byte_identity_test.exs` (4 new: statement, certificate, receipt, branded_invoice)

**Analog:** `test/rendro/recipes/invoice_byte_identity_test.exs` (verified, 47 lines).
Copy structure exactly:
```elixir
defmodule Rendro.Recipes.StatementByteIdentityTest do
  use ExUnit.Case, async: true
  alias Rendro.Recipes.Statement

  # Frozen in the RETROFIT commit, before any theme wiring. Changing this hash
  # is a defect, not a refresh, unless a human re-authorizes a new baseline.
  @toy_golden_sha256 "<blessed in retrofit commit>"

  defp toy_data, do: %{ ...minimal required keys only... }

  test "two deterministic renders are byte-identical" do
    doc = Statement.document(toy_data())        # no :theme, no :palette
    assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end

  test "fresh render sha256 matches the frozen retrofit baseline" do
    doc = Statement.document(toy_data())
    assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
    sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
    assert sha256 == @toy_golden_sha256
  end
end
```
- Certificate variant MUST add a `border: true` case exercising the `{34,34,34}` frame.
- The `@toy_golden_sha256` is blessed via a live render in the RETROFIT commit (Commit 1), NOT the swap commit.

### `*_opts_threading_test.exs` (5 new: statement, certificate, receipt, payslip, ticket)

**Analog:** `test/rendro/recipes/invoice_opts_threading_test.exs` (verified, 105 lines).
Note `branded_invoice_opts_threading_test.exs` already exists — extend it with `:theme` cases.
Reuse these three assertion shapes (from RESEARCH Code Examples + the analog):
```elixir
# 1. :theme threads through page_template/1 without KeyError (guards the whitelist fix)
test ":theme threads through page_template/1 without KeyError" do
  assert %Rendro.PageTemplate{} = Receipt.page_template(theme: Rendro.Theme.default())
end

# 2. :palette override wins over :theme (D-01)
test ":palette override wins over :theme" do
  themed = Receipt.sections(data, theme: Rendro.Theme.default())
  ovr    = Receipt.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200,0,0}})
  refute themed == ovr
end

# 3. no-theme render is byte-identical to pre-swap (PLUMB-03)
test "no-theme sections identical to empty-opts sections" do
  assert Receipt.sections(data) == Receipt.sections(data, [])
end
```
- The analog's existing "a `:palette` override changes only the footer section's color"
  test (L83–98) is the D-01 invariant template — mirror it per recipe where a distinct
  overridable region exists.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (recommended) source-scan test | test | static/source-scan | No existing test greps `lib/rendro/recipes/*.ex` for inline `{r,g,b}`. Build fresh: scan section builders, EXCLUDE `palette/1` default maps + non-color numerics (`width: 0.75`, geometry). Optional per RESEARCH but recommended for PLUMB-02. |

## Anti-Patterns (from RESEARCH — enforce in every plan)

- **Do NOT combine retrofit + swap in one commit** (research line 48). Commit 1 = byte-identical retrofit + fresh goldens. Commit 2 = theme swap. Never merged.
- **Do NOT re-bless any existing `edge_matrix` or recipe golden on the no-theme path.** A drifted golden is a DEFECT (`golden.ex` L84), not a refresh.
- **Do NOT add `:theme`/`:palette` to a `page_template/1` whitelist** — they must be dropped there so they thread to `palette/1`.
- **Do NOT hand-roll color resolution** — use `Rendro.Theme.resolve/1` + the exact `Map.merge(base, palette_override)` order.
- **Do NOT seam non-color numerics** — `width: 0.75` (Statement stroke) and geometry constants stay literal.

## Metadata

**Analog search scope:** `lib/rendro/recipes/*.ex`, `test/rendro/recipes/*.exs`, `priv/goldens/`
**Files scanned:** invoice.ex (seam + whitelist + call sites), statement.ex, certificate.ex, receipt.ex, branded_invoice.ex, payslip.ex, ticket.ex, invoice_byte_identity_test.exs, invoice_opts_threading_test.exs
**Live confirmations this session:** invoice palette threading L216/350/407; Receipt L178 `Keyword.delete` + BrandedInvoice L92 `Keyword.merge` KeyError sources; `priv/goldens/branded_invoice/` absent (6 dirs only); `branded_invoice_opts_threading_test.exs` exists
**Pattern extraction date:** 2026-07-27

## PATTERN MAPPING COMPLETE

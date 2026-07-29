# Phase 122: Typography type-scale application + font-role/leading wiring - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 9 modified (7 recipes + `no_inline_color_literals_test.exs` guard) + up to 2 new tests
**Analogs found:** 9 / 9 (every modified file has an in-repo analog; no RESEARCH-only fallback needed)

> The single dominant analog for this phase is the **per-recipe `palette/1` seam** (added Phase 120). The new `typography/1` seam is its exact structural twin — same `case opts[:theme] do nil -> <literals>; theme -> resolve end` shape, same `Map.merge` override tail, same "section builder binds a local at the top of the function" call convention. Every excerpt below is the concrete code the planner copies from.

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/invoice.ex` | recipe/service | transform | `palette/1` in same file (`invoice.ex:491`) | exact (sibling fn) |
| `lib/rendro/recipes/branded_invoice.ex` | recipe/service | transform | `palette/1` in same file (`branded_invoice.ex:263`) | exact (sibling fn) |
| `lib/rendro/recipes/statement.ex` | recipe/service | transform | `palette/1` in same file (`statement.ex:373`) | exact (sibling fn) |
| `lib/rendro/recipes/receipt.ex` | recipe/service | transform | `palette/1` in same file (`receipt.ex:497`) | exact (sibling fn) |
| `lib/rendro/recipes/certificate.ex` | recipe/service | transform | `palette/1` in same file (`certificate.ex:403`) | exact (sibling fn) + measurement-coupled (see note) |
| `lib/rendro/recipes/payslip.ex` | recipe/service | transform | `palette/1` in same file (`payslip.ex:706`) | exact (sibling fn) |
| `lib/rendro/recipes/ticket.ex` | recipe/service | transform | `palette/1` in same file (`ticket.ex:540`) | exact (sibling fn) + 7-size blocker (see note) |
| `test/rendro/recipes/*_opts_threading_test.exs` (×7, extend) | test | request-response | `invoice_opts_threading_test.exs:106-130` (`:theme` threading block) | exact |
| `test/rendro/recipes/no_inline_color_literals_test.exs` (relax D-04 guard) | test | static-scan | same file `:81-99` (the guard to invert/remove) | exact |
| `test/rendro/recipes/no_inline_size_literals_test.exs` (NEW, optional) | test | static-scan | `no_inline_color_literals_test.exs` (whole file) | exact template |
| `test/rendro/recipes/<recipe>_typography_test.exs` (NEW) | test | request-response | `test/rendro/pdf/font_test.exs:90` raise assertion | exact |

---

## Shared Patterns

These three patterns apply to **all 7 recipes**. The planner should state them once and reference them per-recipe rather than re-deriving.

### Shared Pattern A — the `typography/1` seam (mirror `palette/1` verbatim)

**Source:** `lib/rendro/recipes/invoice.ex:491-510` (the canonical `palette/1`, identical in shape across all 7 recipes)
**Apply to:** all 7 recipe files — add ONE new `defp typography(opts)` sibling to `defp palette(opts)`.

Analog to copy from (VERIFIED, `invoice.ex:491-510`):

```elixir
defp palette(opts) do
  base =
    case opts[:theme] do
      nil ->
        %{
          ink: {0, 0, 0},
          muted: {0, 0, 0},
          accent: {0, 0, 0},
          on_accent: {0, 0, 0},
          background: {255, 255, 255},
          surface: {255, 255, 255},
          rule: {0, 0, 0}
        }

      theme ->
        Rendro.Theme.resolve(theme).colors
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

New seam to write (exact structural twin; `nil` branch carries THIS recipe's literal current sizes/fonts/leading — NEVER `Rendro.Theme.default().typography`, that would break byte-identity — see RESEARCH Pitfall 1):

```elixir
defp typography(opts) do
  base =
    case opts[:theme] do
      nil ->
        %{
          # per-recipe literal defaults — values pulled from THIS recipe's
          # current size:/font: literals (see per-recipe mapping table below)
          scale: %{display: 20, title: 18, subtitle: 12, body: 10, small: 9, caption: 8},
          fonts: %{heading: :default, body: :default, mono: :default},
          leading: 1.2,
          widows: 2,
          orphans: 2
        }

      theme ->
        Rendro.Theme.resolve(theme).typography
    end

  Map.merge(base, Keyword.get(opts, :typography, %{}))
end
```

> Naming (`typography` vs folding into `palette`) is planner discretion per CONTEXT §Discretion. RESEARCH recommends a **separate** seam (don't conflate color + type). The frozen themed values that the `theme ->` branch returns are `theme.ex:75-81`: `scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8}, fonts: all :default, leading: 1.2, widows: 2, orphans: 2`.

### Shared Pattern B — section-builder call convention (`local = seam(opts)` at top)

**Source:** `invoice.ex:239` (`colors = palette(opts)` as the first line of each arity-2 section builder), read then at every call site as `color: colors.ink`.
**Apply to:** every section builder in every recipe that emits a `%Text{}`.

Existing convention (VERIFIED, `invoice.ex:238-248`):

```elixir
defp header_section(%{id: id, date: date} = data, opts) do
  colors = palette(opts)
  fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)

  # FROZEN toy path (INV-01) — these two lines MUST stay literally
  # unchanged: no color:, no formatter. ...
  base_content = [
    Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
    Rendro.block(Rendro.text("Date: #{date}", size: 10))
  ]
```

New convention (bind a `type` local alongside `colors`, then read roles):

```elixir
defp header_section(%{id: id, date: date} = data, opts) do
  colors = palette(opts)
  type = typography(opts)
  # ...
  base_content = [
    Rendro.block(Rendro.text("INVOICE ##{id}",
      size: type.scale.title, font: type.fonts.mono,
      line_height: type.leading, widows: type.widows, orphans: type.orphans)),
    Rendro.block(Rendro.text("Date: #{date}",
      size: type.scale.body, font: type.fonts.body,
      line_height: type.leading, widows: type.widows, orphans: type.orphans))
  ]
```

> **CAUTION — `invoice.ex:245-248` is a FROZEN toy path (INV-01)** whose comment says the two lines "MUST stay literally unchanged." Seaming them changes those lines; that is *intended* this phase (byte-identity holds because `type.scale.title == 18`, `type.fonts.body == :default`), but the planner must update/retire the INV-01 freeze comment and re-confirm `invoice_byte_identity_test.exs` stays green. Same freeze-comment class exists in `branded_invoice.ex` header runs.

### Shared Pattern C — TYPE-02 raise-path assertion (never silent Helvetica)

**Source:** `test/rendro/pdf/font_test.exs:90`
**Apply to:** one new `<recipe>_typography_test.exs` per recipe (or a representative subset — planner's call).

Analog to copy (VERIFIED, `font_test.exs:82-90`):

```elixir
# doc built with a block whose text has font: :heading (an unregistered role)
Rendro.block(Rendro.text("Missing font", font: :heading))
# ...
assert {:error, {:unknown_text_font, :heading}} = Build.run(doc)
```

New shape: build a recipe `document(data, theme: t)` where `t.typography.fonts.heading` (or `.mono`/`.body`) is an unregistered atom (e.g. `:no_such_font`), assert `Build.run(doc)` returns `{:error, {:unknown_text_font, :no_such_font}}`. `resolve/1` does NOT validate font atoms (only colors), so the bad atom survives resolution and surfaces at build/validate time — exactly the shipped `font_registry.ex:393 → build.ex:110-111` path. `Rendro.render/2` returns `{:error, %Rendro.Error{}}` (does not raise) — assert on `Build.run/1` for the exact typed proof.

---

## Pattern Assignments (per recipe)

Each recipe = Shared Pattern A (add `typography/1`) + Shared Pattern B (thread at call sites) + its own literal-default table. Literal-default values and per-element role mapping are in **RESEARCH §Per-Recipe Mapping Tables** — do not duplicate; the deltas/risks are called out below.

### `lib/rendro/recipes/invoice.ex` (CLEAN — 5 sizes 20/18/12/10/9)

**Seam analog:** `invoice.ex:491-510` (Shared Pattern A).
**Anchor (`display`):** Total Due amount — `invoice.ex:456-461`, currently `@dominant_total_size` (20):

```elixir
Rendro.block(
  Rendro.text("Total Due: #{fmt_amount.(total)}",
    size: @dominant_total_size,      # → size: type.scale.display  (literal-default 20)
    color: colors.accent             # → also add font: type.fonts.mono
  )
)
```

Other call sites: header `18/10` (`invoice.ex:246-247`, Shared Pattern B excerpt above); minor totals `@minor_totals_size` 9 (`invoice.ex:444-445`); party/muted lines 12/10 (`invoice.ex:398,405,409,413`). `caption` unused. Literal-default scale: `%{display: 20, title: 18, subtitle: 12, body: 10, small: 9, caption: <pick, unused>}`.

### `lib/rendro/recipes/branded_invoice.ex` (RISK — brand font + no Total-Due run)

**Seam analog:** `branded_invoice.ex:263` (Shared Pattern A).
**Call sites (VERIFIED, `branded_invoice.ex:213-216`):**

```elixir
Rendro.block(Rendro.text("Rendro, Inc.", font: font_name, size: 18, color: colors.ink)),
Rendro.block(Rendro.text("Invoice ##{id}", font: font_name, size: 12, color: colors.ink)),
Rendro.block(Rendro.text("Date: #{date}", size: 10, color: colors.ink))
```

**Two flagged risks (RESEARCH Q1/Q2 — resolve before writing this plan):**
- **Q1:** No Total-Due `%Text` exists (totals live inside `Rendro.table/2` at `branded_invoice.ex:226-230`). RESEARCH recommends binding `display` to the brand name (18). Do NOT promote the table total to a `%Text` (byte-risk).
- **Q2:** `font: font_name` is the data-driven embedded brand font (registered `branded_invoice.ex:174-177`). Its literal-default MUST stay `font_name` (the sole exception to "all `:default`"). RESEARCH recommends brand font wins on the themed path too — do NOT seam those two runs to `type.fonts.heading`. Only `Date:`/thank-you get role seams.

### `lib/rendro/recipes/statement.ex` (CLEAN — 5 sizes 22/14/12/10/9)

**Seam analog:** `statement.ex:373`. **Anchor:** closing balance 22 (`statement.ex:341`) → `display`, font `mono`. Note the shared `cell_text/2` helper (`statement.ex:542-543`) renders both label and amount columns — keep one font role (`body`) for byte-safety (RESEARCH Pitfall 5). Mapping table: RESEARCH §3.

### `lib/rendro/recipes/receipt.ex` (EXACTLY FULL — 6 sizes 18/16/14/12/10/9, no headroom)

**Seam analog:** `receipt.ex:497`. **Anchor:** Total `@dominant_total_size` 18 (`receipt.ex:445-446`) → `display`, font `mono`. All six roles consumed exactly once — no off-scale sizes, but zero slack. Mapping table: RESEARCH §4.

### `lib/rendro/recipes/certificate.ex` (measurement-coupled — 5 sizes 34/20/12/11/10 + `size: 1` spacer)

**Seam analog:** `certificate.ex:403`. **Anchor:** recipient name `@recipient_size` 34 (`certificate.ex:303`) → `display`, font `heading` (name-anchor → heading, per RESEARCH convention).

**Distinct call-site shape — sizes are function args, not inline `%Text` literals** (VERIFIED, `certificate.ex:347-356`):

```elixir
spacer = Rendro.block(Rendro.text("", size: 1), height: top_spacer_h)   # OFF-SCALE — do NOT seam
content = [
  spacer,
  centered_line(font, data.title, @title_size, region_w, colors),
  centered_line(font, "This certifies that", @subtitle_size, region_w, colors),
  centered_line(font, data.recipient, @recipient_size, region_w, colors),
  centered_paragraph(body_text, @body_size, body_measure_w, region_w, colors),
  centered_line(font, fmt_date.(data.date), @meta_size, region_w, colors),
  ...
]
```

Attrs at `certificate.ex:301-305` (`@title_size 20`, `@subtitle_size 12`, `@recipient_size 34`, `@body_size 11`, `@meta_size 10`).

**Pitfall 2 (RESEARCH):** these `@*_size` attrs feed `line_h/1` and `text_width/3` **centering math** (`certificate.ex:338-345,366,372`), not just the text run. The seam must pass the resolved size into BOTH the `%Text{}` AND the measurement call — resolve once per element, thread to both, or centering drifts on the themed path. Brand font stays registered-but-unapplied (`certificate.ex:274-282,322-326`) — deferred per CONTEXT. Skip the `size: 1` layout spacer.

### `lib/rendro/recipes/payslip.ex` (CLEAN — 5 sizes 27/13/11/10/9)

**Seam analog:** `payslip.ex:706`. **Anchor:** net pay 27 (`payslip.ex:418`) → `display`, font `mono`. Same single-`cell_text/2`-helper caveat as Statement (`payslip.ex:573`, `@cell_size 11` collides with employee 11 — both `subtitle`, same literal, fine). Mapping table: RESEARCH §6.

### `lib/rendro/recipes/ticket.ex` (HARD BLOCKER — 7 sizes 26/16/10/9/8/7/6 vs 6 roles)

**Seam analog:** `ticket.ex:540`. **Anchor (D-01):** reference code `@reference_size` 8 (`ticket.ex:459`) → `display` via non-monotone assignment, font `mono`.

**Distinct call-site shape — `@*_size` module attrs on inline `%Text`** (VERIFIED):

```elixir
# ticket.ex:298,321
@placement_value_size 26
Rendro.block(Rendro.text(v, size: @placement_value_size, color: colors.ink))
# ticket.ex:376-378
@reference_size 8
@caption_size 7
@present_code_size 6
# ticket.ex:455,459,468
Rendro.block(Rendro.text(caption_label, size: @caption_size, color: colors.muted), ...)
Rendro.block(Rendro.text(reference_text, size: @reference_size, color: colors.ink), ...)
Rendro.block(Rendro.text(lbl.(:present_code), size: @present_code_size, color: colors.muted), ...)
```

**RESEARCH Q3 (resolve before writing this plan):** 7 distinct sizes cannot all bind to 6 scale roles without collapsing two (byte-break). RESEARCH recommends **exempting `@present_code_size` (6) — and if needed `@caption_size` (7) — from the scale seam** (keep them literal module attrs, seam only their FONT to `mono`), leaving ≤6 scale-seamed sizes. This is the phase's one genuine architecture decision — needs planner sign-off.

---

## Test Pattern Assignments

### Extend `*_opts_threading_test.exs` (×7) — `:theme` threading

**Analog:** `invoice_opts_threading_test.exs:106-130` — the "Invoice :theme threading (PLUMB-02 swap)" describe block:

```elixir
test "a themed render differs from the no-theme render" do
  data = sample_data()
  refute Invoice.sections(data) == Invoice.sections(data, theme: Rendro.Theme.default())
end

test "no-theme sections(data) equals sections(data, []) (PLUMB-03)" do
  data = sample_data()
  assert Invoice.sections(data) == Invoice.sections(data, [])
end
```

Add a `:typography` override + byte-identity companion mirroring the existing `palette(opts) seam` describe (`invoice_opts_threading_test.exs:82-104`): assert `sections(data) == sections(data, typography: %{})` (no-op) and that a `typography:` override changes the themed output.

### Relax the D-04 guard — `no_inline_color_literals_test.exs:81-99`

**This is a pre-declared red→green step.** The test "no recipe file performs a `.typography` read (colors-only boundary, D-04)" (`no_inline_color_literals_test.exs:81-99`) will fail the moment any recipe reads `theme.typography` this phase. It must be **removed or inverted**. Flag it in the plan so the red is expected, mirroring the Phase-119 manifest red→green lesson.

### NEW `no_inline_size_literals_test.exs` (optional teeth — planner's call)

**Analog:** the whole of `no_inline_color_literals_test.exs` — copy its structure verbatim:
- `@color_literal` regex (`:30`) → a `size:`-followed-by-integer/float regex.
- `palette_body_indices/1` (`:41-53`, finds `defp palette(` .. matching `  end`) → generalize to also exclude the `defp typography(` body AND the `@*_size` module-attr definition lines (Certificate/Ticket define sizes as attrs, which are the legit literal home).
- `comment_line?/1` (`:55`) and the `Enum.flat_map` violation collector (`:57-79`) reused as-is.

### NEW `<recipe>_typography_test.exs` — TYPE-02 raise-path

Shared Pattern C above (`font_test.exs:90`). One per recipe or a representative subset.

---

## No Analog Found

None. Every modified file has an exact in-repo analog (its own `palette/1` sibling, or an existing test template). The only genuinely net-new artifact is each recipe's literal-default typography map — and its values are *dictated* by the current `size:`/`font:` literals (RESEARCH mapping tables), not designed.

## Metadata

**Analog search scope:** `lib/rendro/recipes/*.ex`, `test/rendro/recipes/*.exs`, `test/rendro/pdf/font_test.exs`, `lib/rendro/{theme,text,font_registry,pipeline/build}.ex` (line refs via RESEARCH, already `file:line`-verified).
**Files scanned (this pass):** `invoice.ex` (palette + header + total-due + attrs), `branded_invoice.ex` (palette + header runs), `certificate.ex` (attrs + centered-line usage), `ticket.ex` (attrs + usage), `invoice_opts_threading_test.exs`, `no_inline_color_literals_test.exs`, `font_test.exs`.
**Pattern extraction date:** 2026-07-27

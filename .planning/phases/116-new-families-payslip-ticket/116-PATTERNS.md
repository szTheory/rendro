# Phase 116: New families — Payslip & Ticket - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 8 (2 new recipes, 2 modified core files, 2 registration artifacts, test files, fixtures)
**Analogs found:** 6 / 8 (2 genuinely new — see No Analog Found)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/recipes/payslip.ex` | recipe/adapter (controller-equivalent) | request-response (data → PDF bytes), CRUD-like table paginate | `lib/rendro/recipes/invoice.ex` (totals/Decimal/palette/Keyword.take) + `lib/rendro/recipes/branded_invoice.ex` (4-region template) + `lib/rendro/recipes/statement.ex` (label_resolver/formatter usage, running fold) | role-match (composite) |
| `lib/rendro/recipes/ticket.ex` | recipe/adapter | request-response, fixed-geometry render | `lib/rendro/recipes/certificate.ex` (geometry-from-template, byte guard, image registration) + `lib/rendro/recipes/branded_invoice.ex` (fixed logo `fit:` region) | role-match (composite) |
| `lib/rendro/recipes/pagination.ex` (MODIFY) | utility/shared internal helper | transform | itself (additive change) — `label_resolver/1` at `pagination.ex:64`, `type_name/1` at `pagination.ex:76-82` | exact (extending in place) |
| `lib/mix/tasks/rendro/api.gen.ex` (MODIFY) | config/build tooling | batch (manifest generation) | itself — `@public_modules` list at `lib/mix/tasks/rendro/api.gen.ex:25-93` (Recipes entries at lines 89-93) | exact (extending in place) |
| `priv/public_api.json` (MODIFY, generated) | config artifact | batch | generated via `mix rendro.api.gen`; no manual edits | exact (generated, not hand-authored) |
| `priv/support_matrix.json` (MODIFY) | config artifact | CRUD-like (row append) | `statement` row at `priv/support_matrix.json:440`, `receipt_report` at `:451`, `certificate` at `:462` | exact |
| `test/rendro/recipes/payslip_test.exs` (CREATE) | test | request-response | `test/rendro/recipes/statement_test.exs` (fixture_data helper, running-fold assertions) + `test/rendro/recipes/invoice_test.exs`/`invoice_byte_identity_test.exs`/`invoice_opts_threading_test.exs` (Decimal totals assertions, opts threading, byte-identity) | exact |
| `test/rendro/recipes/ticket_test.exs` (CREATE) | test | request-response | `test/rendro/recipes/certificate_test.exs` (fixture_data helper, byte-guard test, image registration test) | exact |

## Pattern Assignments

### `lib/rendro/recipes/payslip.ex` (recipe/adapter, request-response)

**Analogs:** `lib/rendro/recipes/invoice.ex` (primary — totals/Decimal/palette), `lib/rendro/recipes/branded_invoice.ex` (4-region template shape), `lib/rendro/recipes/statement.ex` (label_resolver/formatter call idiom, running fold)

**palette(opts) — copy verbatim** (`invoice.ex:363-378` approx, S1 seam):
```elixir
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

**page_template/1 `Keyword.take` whitelist pattern** (`invoice.ex:81-129`):
```elixir
def page_template(opts \\ []) do
  defaults = [
    name: :invoice,
    regions: [
      Rendro.region(name: :header, role: :header, anchor: :top, x: @margin, y: @margin, width: @content_width, height: @header_height),
      Rendro.region(name: :body, role: :body, anchor: :flow, x: @margin, y: @body_y, width: @content_width, height: @body_height),
      Rendro.region(name: :footer, role: :footer, anchor: :bottom, x: @margin, y: @footer_y, width: @content_width, height: @footer_height)
    ]
  ]

  # page_template/1 only understands PageTemplate struct keys. Recipe-level
  # opts (:formatters, :labels, :palette, ...) are consumed by the section
  # builders via opts, not here — filter them out so they thread through to
  # sections/2 / palette/1 instead of reaching struct!/2 and raising KeyError.
  template_opts =
    Keyword.take(opts, [:name, :width, :height, :margin_top, :margin_right, :margin_bottom, :margin_left, :regions])

  Rendro.page_template(Keyword.merge(defaults, template_opts))
end
```
For Payslip, adapt to the **4-region** shape (`:header`, `:summary`, `:body`, `:footer`) modeled on `branded_invoice.ex`'s region list (`page_template/1`, regions named `:logo`/`:header`/`:body`/`:footer`, each `Rendro.region(...)` with explicit `anchor:`/`role:`). Payslip's `:summary` region is `anchor: :top` per D-11 (own region, not part of `:header`), `:body` is `anchor: :flow`, `:footer` is `anchor: :bottom` (see `branded_invoice.ex:44-58` for the region-list literal shape and `invoice.ex:81` for the `page_size`/margin threading — Payslip should also derive geometry from `PageSize.resolve/2` rather than Invoice's fixed `@margin`/`@content_width` module attributes, since D-14 implies both A4 and Letter support like Certificate/Ticket).

**Kept-with-last-rows totals reservation + `Decimal.equal?/2` assert** (retarget for gross→net, `invoice.ex:244-266` capacity reservation, `invoice.ex:647`/`invoice.ex:673` assert idiom):
```elixir
# Capacity reservation (invoice.ex ~244-266, adapt @totals_line_height → payslip's
# reconciliation-block height)
effective_capacity = capacity - header_h - totals_reserved_height(data) - @row_epsilon

rows_with_meta =
  Enum.zip(formatted_rows, row_heights)
  |> Enum.map(fn {fmt_row, height} -> {fmt_row, height, nil} end)

pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)

table_blocks =
  pages
  |> Enum.with_index()
  |> Enum.map(fn {{page_rows, _meta}, idx} ->
    table = Rendro.table(page_rows, table_opts)
    Rendro.block(table, break_before: idx > 0)
  end)

# Reconciliation block appended after the LAST table block only — never wrapped
# in keep_together.
totals_blocks = build_totals_blocks(data, opts)
```

**Decimal reconciliation assertion (D-13)** — adapted directly from RESEARCH.md's Code Examples section (verbatim, ready to use):
```elixir
defp validate_totals!(%{earnings: earnings, deductions: deductions, net_pay: net_pay} = data) do
  gross = Enum.reduce(earnings, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)
  total_deductions = Enum.reduce(deductions, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)
  expected_net = Decimal.sub(gross, total_deductions)

  unless Decimal.equal?(net_pay, expected_net) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — :net_pay mismatch.

    What:  net_pay does not equal gross earnings minus total deductions.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Supplied net_pay: #{inspect(net_pay)},
           Derived (gross - deductions): #{inspect(expected_net)}.
    Next:  Correct :net_pay, or verify :earnings/:deductions line amounts.
    """
  end
end
```
Mirror the optional `:totals` caller-assertion pattern too (`invoice.ex` `maybe_validate_totals!/1`, ~lines 600-660): if caller supplies `data.totals`, assert each field against derived via `Decimal.equal?/2`, never `==` — same four-part `ArgumentError` shape, same "Remove :totals.X to skip this check" `Next:` line.

**label_resolver / formatter usage idiom (Statement precedent, generalize to arity-2 per D-18)** (`statement.ex:270-274`):
```elixir
defp header_section(%{period: period, account: account, opening_balance: ob} = _data, opts) do
  fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
  fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
  lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)  # Payslip: pass recipe @default_labels (D-18)

  ...
end
```
Payslip calls `Pagination.label_resolver(opts, @default_labels)` (new arity-2 signature) everywhere Statement currently calls `Pagination.label_resolver(opts)` (arity-1, still valid via default arg).

**Combined ledger table (D-12)** — no direct analog exists (Invoice's item table is single-column-group; Statement's table is single-money-column). Compose from primitives: `Rendro.table(rows, columns: [...], header: [...], borders: :columns, cell_align: %{1 => :right, 2 => :right, 4 => :right, 5 => :right})` — `cell_align` primitive verified at `lib/rendro.ex:475`. Feed rows through `Pagination.chunk_rows_into_pages/2` exactly as Invoice does (see above) — this is the decisive reason D-12 rejected two fixed side-by-side tables.

**Error handling pattern** — four-part `ArgumentError` (What/Where/Why/Next), copy the shape from `invoice.ex` `validate_totals_field_type!/2` and `certificate.ex` date/body validators (see Ticket section below for the certificate excerpts) — identical idiom, different field names.

---

### `lib/rendro/recipes/ticket.ex` (recipe/adapter, fixed-geometry render)

**Analog:** `lib/rendro/recipes/certificate.ex` (structural — geometry-from-template, byte guard, optional image registration) + `lib/rendro/recipes/branded_invoice.ex` (fixed region + `fit:` image placement idiom)

**Geometry-derived-from-template pattern** (`certificate.ex:75-116`, copy the shape, not the literal numbers):
```elixir
@spec page_template(keyword()) :: Rendro.PageTemplate.t()
def page_template(opts \\ []) do
  page_size = Keyword.get(opts, :page_size, @default_page_size)
  orientation = Keyword.get(opts, :orientation, @default_orientation)
  {pw, ph} = Rendro.PageSize.resolve(page_size, orientation)

  ml = Keyword.get(opts, :margin_left, @default_margin)
  mr = Keyword.get(opts, :margin_right, @default_margin)
  mt = Keyword.get(opts, :margin_top, @default_margin)
  mb = Keyword.get(opts, :margin_bottom, @default_margin)

  content_w = pw - ml - mr
  content_h = ph - mt - mb

  # Ticket-specific (D-03): band height as a RATIO of content width (~2.4:1),
  # never a fixed-point constant, so A4/Letter geometry falls out identically.
  band_w = content_w
  band_h = band_w / 2.4
  stub_x = band_w * 0.68

  body_region =
    Rendro.region(name: :main, role: :custom, anchor: :fixed, x: ml, y: mt, width: stub_x, height: band_h)

  ...
end
```
`Rendro.Region.role` is a closed 5-atom union (`:header | :body | :footer | :sidebar | :custom` — `lib/rendro/region.ex:16`); Ticket's `:main`/`:stub`/`:terms` regions must use `role: :custom` exactly as Certificate's `:frame` region does (`certificate.ex:121`, `role: :custom`).

**Frame/Path region content shape** (`certificate.ex` frame block, ~lines 175-195, adapt `{:rect}` → `{:rounded_rect}` per D-05):
```elixir
frame_block = %Rendro.Block{
  width: region_w,
  height: region_h,
  x: 0,
  y: 0,
  content: %Rendro.Path{
    ops: [{:rect, 0, 0, region_w, region_h}],
    stroke: %{color: frame_opts.color, width: frame_opts.weight}
  }
}
```
Ticket's code box (D-05): `%Rendro.Path{ops: [{:rounded_rect, box_x, box_y, box_w, box_h, 6.0}], stroke: %{color: palette.rule, width: 1.0}}` — `{:rounded_rect}` op verified at `lib/rendro/path.ex:61`; `dash:` stroke option verified at `lib/rendro/path.ex:72` (`optional(:dash) => nil | [number()]`). Perforation is a straight-line `%Rendro.Path{}` with `dash: [3, 3]` — exact line-segment op name (`{:move_to}`/`{:line_to}` or similar) is NOT re-derived in RESEARCH.md; confirm against `lib/rendro/path.ex`'s full op union before implementing (RESEARCH Assumption A2).

**Recipe-owned image registration under fixed logical name** (`certificate.ex` brand block, ~lines 250-262):
```elixir
base_doc =
  if brand = Map.get(data, :brand) do
    base_doc
    |> Rendro.Document.register_embedded_font(brand.font_name, {:path, Rendro.Branded.font_path()})
    |> Rendro.Document.register_image(brand.logo_name, {:path, Rendro.Branded.logo_path()})
  else
    base_doc
  end
```
**Critical divergence for Ticket (D-10, no prior-art copy source):** Certificate/BrandedInvoice always register a trusted, library-shipped path (`Rendro.Branded.logo_path()`) — never caller-supplied bytes. Ticket's `data.code.image` is the first caller-supplied image source in any recipe, so `register_image/3`'s raw `Rendro.AssetRegistry.InvalidAssetError` (`lib/rendro/asset_registry.ex:7-14`, `[:message, :logical_name, :reason]`) must never leak. Pre-validate in `validate_data!/1` using the pure `Rendro.ImageParser.parse/1` (verified at `lib/rendro/image_parser.ex:26/41/45`) and raise the four-part `ArgumentError` naming `data.code.image` before any `Document.register_image/3` call — this is genuinely new plumbing, not a copy-paste target.

**Byte-guarded free-text validation (D-04)** (`certificate.ex` body-length guard):
```elixir
defp validate_body!(body) when is_binary(body) and byte_size(body) > 2000 do
  raise ArgumentError, """
  Rendro.Recipes.Certificate.document/2 — data.body is too long.

  What:  data.body exceeds the single-page body-length limit.
  Where: Rendro.Recipes.Certificate.validate_data!/1
  Why:   #{byte_size(body)} bytes (limit: 2000). Certificate is a single-page recipe;
         very long body text would overflow the page and split across multiple pages.
  Next:  Shorten data.body to 2000 bytes or fewer.
  """
end
```
Ticket applies the same byte-guard idiom to any free-text fields (e.g. `:terms`, placement labels) — pick a limit appropriate to the fixed region, four-part message shape identical.

**Component.image with `fit:` (aspect-preserving contain)** — `lib/rendro/component.ex:20` `def image(logical_name, opts \\ [])`; Ticket calls `Component.image(:ticket_code, fit: {box_w, box_h})`. Deterministic contain logic lives in `lib/rendro/pipeline/measure.ex` (~103-119, the `{nil, nil, {fit_w, fit_h}}` branch of `measure_block/3`) — no recipe-level math needed, mirrors `branded_invoice.ex`'s logo `fit:` placement.

---

### `lib/rendro/recipes/pagination.ex` (MODIFY — additive)

**Current arity-1 `label_resolver/1`** (`pagination.ex:63-73`, exact current code — only callers are `statement.ex:274` and `statement.ex:294`):
```elixir
def label_resolver(opts) do
  user_labels = Keyword.get(opts, :labels, %{})

  fn key ->
    case Map.fetch(user_labels, key) do
      {:ok, val} -> val
      :error -> Rendro.Format.label(key)
    end
  end
end
```

**Target arity-2 (additive default arg — D-18, verified merge order):**
```elixir
def label_resolver(opts, default_labels \\ %{}) do
  user_labels = Keyword.get(opts, :labels, %{})

  fn key ->
    case Map.fetch(user_labels, key) do
      {:ok, val} -> val
      :error ->
        case Map.fetch(default_labels, key) do
          {:ok, val} -> val
          :error -> Rendro.Format.label(key)
        end
    end
  end
end
```
Statement's two existing call sites (`statement.ex:274`, `statement.ex:294`, both `Rendro.Recipes.Pagination.label_resolver(opts)`) keep compiling and behaving identically — `default_labels` defaults to `%{}`, empty-map lookup always falls through to `Rendro.Format.label/1`.

**New D-19 opts-shape validators — genuinely new, no prior art** (confirmed via grep: no `validate_labels!`/`validate_formatters!`/`is_function(f, 1)` anywhere in `lib/rendro/recipes/*.ex`). Compose from the existing `type_name/1` helper (`pagination.ex:76-82`, exact current code — copy verbatim, unchanged):
```elixir
def type_name(value) when is_binary(value), do: "String"
def type_name(value) when is_integer(value), do: "Integer"
def type_name(value) when is_float(value), do: "Float"
def type_name(value) when is_atom(value), do: "Atom"
def type_name(value) when is_list(value), do: "List"
def type_name(value) when is_map(value), do: "Map"
def type_name(_value), do: "Unknown"
```
New validators should follow the same four-part `ArgumentError` idiom as `invoice.ex`'s `validate_totals_field_type!/2`, using `type_name/1` in the `Why:` line: `:labels` must be a map with non-empty binary values; `:formatters` must be a keyword list with `is_function(f, 1)` values. `Rendro.Recipes.Pagination` is `@moduledoc false` (`pagination.ex:2`) — these additions never touch `priv/public_api.json`.

---

### `lib/mix/tasks/rendro/api.gen.ex` (MODIFY — `@public_modules` allowlist)

**Exact current list (verified, `lib/mix/tasks/rendro/api.gen.ex:89-93`):**
```elixir
Rendro.Recipes.BrandedInvoice,
Rendro.Recipes.Certificate,
Rendro.Recipes.Invoice,
Rendro.Recipes.Receipt,
Rendro.Recipes.Statement,
```
**Required change:** add `Rendro.Recipes.Payslip,` and `Rendro.Recipes.Ticket,` **alphabetically** into this exact list (between `Rendro.Recipes.Invoice,` and `Rendro.Recipes.Receipt,` for Payslip; after `Rendro.Recipes.Statement,` for Ticket). This is a hardcoded list (`lib/mix/tasks/rendro/api.gen.ex:41+` general area, Recipes entries at lines 89-93) — `mix rendro.api.gen` does NOT auto-discover modules by `@moduledoc tags: [:adapter]` scanning; skipping this edit means `priv/public_api.json` silently omits the new recipes and `test/docs_contract/public_api_contract_test.exs` fails with a "in code but NOT in manifest" diff (Pitfall 1, RESEARCH Finding 1). Regenerate via `mix rendro.api.gen` after the edit — do not hand-author `priv/public_api.json`.

---

## Shared Patterns

### Palette seam (S1)
**Source:** `lib/rendro/recipes/invoice.ex:363-378` (`defp palette(opts)`)
**Apply to:** Both `payslip.ex` and `ticket.ex` — copy verbatim, no inlined `{r,g,b}` literals anywhere in either recipe's section builders.

### Four-part ArgumentError (What/Where/Why/Next)
**Source:** any `validate_data!` clause in `invoice.ex` or `certificate.ex` (see excerpts above)
**Apply to:** All validation failure paths in both new recipes, plus the new `Pagination` D-19 opts validators.

### `Keyword.take` opts whitelist before `page_template/1`
**Source:** `lib/rendro/recipes/invoice.ex:119-129`
**Apply to:** Both recipes' `page_template/1` — filters caller opts to `%Rendro.PageTemplate{}` struct keys so `:palette`/`:labels`/`:formatters` never reach `struct!/2`.

### `Decimal.equal?/2` (never `==`) for money assertions
**Source:** `lib/rendro/recipes/invoice.ex:647,673` (`unless Decimal.equal?(...)`)
**Apply to:** Payslip's `gross - deductions = net_pay` assertion and any optional `:totals` caller-assertion checks.

### `Pagination.chunk_rows_into_pages/2` for multi-page tables
**Source:** `lib/rendro/recipes/pagination.ex:1-40` (`chunk_rows_into_pages/2`, `do_chunk/5`)
**Apply to:** Payslip's combined earnings/deductions ledger table — the single-table-not-two-fixed-tables decision (D-12/Pitfall 4) exists specifically so this chunker can be reused.

### `label_resolver`/`formatter` call idiom
**Source:** `lib/rendro/recipes/statement.ex:270-274` (`Pagination.formatter(opts, :amount, &Rendro.Format.money/1)`, `Pagination.label_resolver(opts, @default_labels)` for Payslip/Ticket — arity-2)
**Apply to:** All section builders in both new recipes needing money/date formatting or chrome labels.

## No Analog Found

| File/Pattern | Role | Data Flow | Reason |
|---|---|---|---|
| Ticket's caller-supplied-image pre-validation (D-10: `ImageParser.parse/1` inside `validate_data!` → instructive `ArgumentError`, never leak `InvalidAssetError`) | validation/error-mapping | request-response | No existing recipe validates *untrusted caller* image bytes — Certificate/BrandedInvoice only ever register trusted library-shipped paths (RESEARCH Finding 6). Build as new code following the four-part `ArgumentError` shape, not a copy target. |
| `Pagination`'s D-19 opts-shape validators (`:labels` map-of-binaries, `:formatters` keyword-of-arity-1-fns) | utility/validation | transform | Confirmed via grep: zero existing `validate_labels!`/`validate_formatters!`/`is_function(f, 1)` usage anywhere in `lib/rendro/recipes/*.ex` (RESEARCH Finding 7). New shared code; compose from `type_name/1` + the four-part error shape. |

## Metadata

**Analog search scope:** `lib/rendro/recipes/*.ex`, `lib/rendro.ex`, `lib/rendro/path.ex`, `lib/rendro/region.ex`, `lib/rendro/component.ex`, `lib/rendro/document.ex`, `lib/rendro/image_parser.ex`, `lib/rendro/page_size.ex`, `lib/mix/tasks/rendro/api.gen.ex`, `priv/support_matrix.json`, `test/rendro/recipes/*.exs`
**Files scanned:** ~12 (directly read/greped for exact excerpts); full list per RESEARCH.md's Verified Code Anchors table (all claims independently re-confirmed against the same commit)
**Pattern extraction date:** 2026-07-18
**Fixture placement recommendation carried from RESEARCH.md:** test-local `defp fixture_data(...)` helpers (Statement/Certificate pattern) — NOT `priv/examples/`, which is Invoice-only-shaped today (`priv/schemas/examples.schema.json` requires `issuer`/`customer`/`invoice`/`items`) and would need schema generalization out of scope for this phase (deferred to Phase 118/SHOW-01).

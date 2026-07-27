# Phase 121: Light/dark background-fill mechanism (all 7 recipes) - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 13 (2 new lib, 7 recipe edits, 1 theme-doc edit, 1 JSON edit, 2 new tests, 1 golden-ref set)
**Analogs found:** 13 / 13 (every new/modified file has a concrete in-repo analog — this phase is composition, not new capability)

> Every analog below was read this session. Line numbers are exact. RESEARCH.md
> already located the seams; this map pins each new/modified file to the exact
> analog lines to copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/background.ex` **(NEW)** | utility / shared-recipe helper | transform (geometry + predicate → struct) | `certificate.ex:181-190` (frame block) + `payslip.ex:379-387` (band call) | exact (structural twin, `stroke:`→`fill:`) |
| `lib/rendro/recipes/statement.ex` **(EDIT)** | recipe (adapter) | request-response (data→sections) | `payslip.ex` (reference recipe, all-correct seams) | exact (same 3-rung recipe) |
| `lib/rendro/recipes/certificate.ex` **(EDIT)** | recipe (adapter) | request-response | `payslip.ex` text seams + its own `:frame` region idiom | exact |
| `lib/rendro/recipes/payslip.ex` **(EDIT — bg wiring only)** | recipe (adapter) | request-response | self (`page_template/1` + `sections/2` prepend) | exact |
| `lib/rendro/recipes/invoice.ex` **(EDIT — bg wiring only)** | recipe (adapter) | request-response | `payslip.ex` wiring | role-match |
| `lib/rendro/recipes/receipt.ex` **(EDIT — bg wiring only)** | recipe (adapter) | request-response | `payslip.ex` wiring | role-match |
| `lib/rendro/recipes/branded_invoice.ex` **(EDIT — bg wiring only)** | recipe (adapter) | request-response | `payslip.ex` wiring | role-match |
| `lib/rendro/recipes/ticket.ex` **(EDIT — bg wiring only)** | recipe (adapter) | request-response | `payslip.ex` wiring | role-match |
| `lib/rendro/theme.ex` **(EDIT — dark/1 @doc)** | config (value module) | n/a (doc string) | existing `dark/1` `@doc` (`theme.ex:224-243`) | self |
| `priv/support_matrix.json` **(EDIT — `theming` row)** | config (data) | n/a (declarative JSON) | `signing_preparation` `boundaries` block (`support_matrix.json:132-138`) | exact (boundary-key idiom) |
| `test/rendro/recipes/theme_mode_background_golden_test.exs` **(NEW)** | test | golden + structural | `statement_byte_identity_test.exs` + `test/support/golden.ex` | exact (light) + role-match (dark op-order) |
| `test/docs_contract/theming_claims_test.exs` **(NEW)** | test | docs-contract | `raster_claims_test.exs` (matrix-boundary asserts) + `accessibility_overclaim_test.exs` (overclaim tripwire) | exact |
| `priv/goldens/<recipe>/dark.sha256` **(NEW blessed ref)** | test fixture | golden ref | existing `priv/goldens/**/*.sha256` (1-line hashes) | exact |

---

## Pattern Assignments

### `lib/rendro/recipes/background.ex` (NEW — utility, transform)

**Analog A (fill block):** `certificate.ex:181-190` — the `:frame` fill block. The `:background` block is its structural twin: same `%Rendro.Path{}`-in-`%Block{}`, only `stroke:` → `fill:` and inset dims → full page.

```elixir
# certificate.ex:181-190 — EXISTING frame block (stroked, inset)
frame_block = %Rendro.Block{
  width: region_w, height: region_h, x: 0, y: 0,
  content: %Rendro.Path{
    ops: [{:rect, 0, 0, region_w, region_h}],
    stroke: %{color: frame_opts.color, width: frame_opts.weight}
  }
}
```

**Analog B (band call style via `Rendro.path/2`):** `payslip.ex:379-387` — the summary backdrop uses `Rendro.path/2` with split block/path attrs, which is the exact call the helper should mirror (swap `fill: colors.surface` → `fill: colors.background`, `height: 0` → `height: page_h`).

```elixir
# payslip.ex:379-387 — EXISTING band via Rendro.path/2
backdrop =
  Rendro.path([{:rect, 0, 0, band_w, band_h}],
    fill: colors.surface,
    stroke: %{color: colors.rule, width: 0.75},
    x: 0, y: 0, width: band_w, height: 0
  )
```

**Analog C (region idiom):** `certificate.ex:119-128` — the `:frame` `%Region{}` with `role: :custom, anchor: :fixed`. The `:background` region copies this shape, sized to full page.

```elixir
# certificate.ex:119-128 — EXISTING fixed custom region
frame_region =
  Rendro.region(
    name: :frame, role: :custom, anchor: :fixed,
    x: inset, y: inset, width: pw - 2 * inset, height: ph - 2 * inset
  )
```

**Analog D (emit sentinel source):** `theme.ex:53` (`background: {255, 255, 255}` in `@default_colors`) and `theme.ex:65` (`background: {27, 23, 19}` in `@dark_colors`). The `@paper_white {255, 255, 255}` module attribute and `emit?/1` predicate derive directly from these.

**`Rendro.path/2` contract (must honor):** `lib/rendro.ex:242-263` splits `:x/:y/:width/:height` (+ break/keep attrs) into block attrs, everything else (`:fill/:stroke`) into path attrs. The helper passes `fill:` + full-page `x/y/width/height` in one call — no manual struct assembly needed.

**Anti-patterns (from RESEARCH Pitfalls 3, 4, 7):**
- Gate BOTH region (`page_template/1`) and section (`sections/2`) on `emit?/1` — never emit an empty region on the light path.
- Never hardcode A4 dims inside the helper — take `pw, ph` as args (Certificate is landscape).
- Keep the sentinel as `@paper_white` / bare `!=`; never write `fill: {255,255,255}` (would trip `no_inline_color_literals_test.exs`).

---

### `lib/rendro/recipes/statement.ex` (EDIT — recipe, request-response)

**Analog:** `payslip.ex` — the all-correct reference recipe. Copy its seam idioms verbatim.

**Text seam sites (D-02) — add swappable `color:` reading `palette(opts)`:**

| Statement site | Current | Add | Payslip analog |
|----------------|---------|-----|----------------|
| `statement.ex:324` | `Rendro.text(account_name, size: 14)` | `color: colors.ink` | `payslip.ex:319` header |
| `statement.ex:325` | `Rendro.text(period_str, size: 10)` | `color: colors.muted` | `payslip.ex:324` |
| `statement.ex:326` | `Rendro.text(ob_str, size: 10)` | `color: colors.muted` | `payslip.ex:325` |
| `statement.ex:315` | `closing_label ... size: 9` | `color: colors.muted` | `payslip.ex:389` label_block |
| `statement.ex:318` | `closing_value ... size: 22` | `color: colors.ink` | `payslip.ex:392` value_block |
| body cells `statement.ex:457,465,475` + `formatted_rows:383-386` | plain strings | wrap in `cell_text/2` @ **size 12** | `payslip.ex:546-547` `cell_text/2` |
| footer `statement.ex:495` | `Rendro.page_number(page_number_opts)` | `Keyword.put_new(opts, :color, colors.muted)` | `payslip.ex:669` `page_number(color: colors.muted, size: 9)` |

**Header seam — copy Payslip header pattern (`payslip.ex:314-327`):**
```elixir
# payslip.ex:317-326 — every text block carries a swappable color role
Rendro.block(Rendro.text("#{lbl.(:employer)}: #{employer_text}", size: 13, color: colors.ink)),
Rendro.block(Rendro.text(period_text, size: 10, color: colors.muted)),
```
Statement's header currently (`statement.ex:320-331`) passes NO `color:` — this is the primary defect. Note `header_section` already has `colors` in scope (it builds `closing_backdrop` from `colors.surface` at `statement.ex:305-307`).

**Body cell seam — copy Payslip `cell_text/2` EXACTLY but at size 12 (Pitfall 1):**
```elixir
# payslip.ex:546-547 — reference (NOTE: Payslip uses @cell_size=11 via a 118-08 re-bless)
defp cell_text(text, colors),
  do: Rendro.block(Rendro.text(text, size: @cell_size, color: colors.ink))
```
Statement's `cell_text/2` MUST use `size: 12` (the current implicit `Rendro.Text` default that plain-string cells normalize to) — an explicit `%Text{content: s, size: 12, color: {0,0,0}}` is byte-identical to the string-normalized cell. Feed identical cells into both `Rendro.measure_rows` (`statement.ex:393`) and `Rendro.table` (`statement.ex:475`). Color does not affect measurement.

**`palette/1` nil-branch completion (D-03) — analog `payslip.ex:684-692`:**
```elixir
# payslip.ex:684-692 — full neutral nil-branch (byte-identical no-theme literals)
%{
  ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
  background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}
}
```
Statement's current nil-branch (`statement.ex:351-354`) has only `surface: {245,245,245}, rule: {0,0,0}`. Add `ink: {0,0,0}, muted: {0,0,0}, background: {255,255,255}` so `color: colors.ink` resolves to `{0,0,0}` on the no-theme path (byte-identical) and to the dark pole under a theme. Keep the existing `surface: {245,245,245}` unchanged (it is Statement's band literal — NOT the Theme default's surface).

**Background wiring (D-04/D-10 — all 7 recipes):** prepend in `page_template/1` (uses module constants `@page_width/@page_height`, `statement.ex:87-88`) and `sections/2`, gated on `Background.emit?(palette(opts))`.

**Byte-identity gate:** `statement_byte_identity_test.exs:13` freezes `@toy_golden_sha256 = "87f6a2c8…"`. This must stay green with NO bless on the no-theme path (Pitfall 2).

---

### `lib/rendro/recipes/certificate.ex` (EDIT — recipe, request-response)

**Analog:** `payslip.ex` text seams + Certificate's own `:frame` region/section idiom (`certificate.ex:114-202`) for the background wiring shape.

**Text seam sites (D-02):**
```elixir
# certificate.ex:347-351 — centered_line: add color: colors.ink
defp centered_line(font, text, size, region_w) do
  width = Rendro.PDF.Font.text_width(font, text, size)
  x = max((region_w - width) / 2, 0)
  Rendro.block(Rendro.text(text, size: size), x: x, width: width)   # → add color: colors.ink
end
# certificate.ex:355-358 — centered_paragraph: add color: colors.ink
```
Thread `colors = palette(opts)` into `body_section/3` and pass to both helpers. Spacer `certificate.ex` `Rendro.text("", size: 1)` — Claude's discretion (no glyphs).

**`palette/1` nil-branch completion (D-03):** current (`certificate.ex:377-380`) has only `rule: {34, 34, 34}` (the deliberate NON-black stress literal — keep unchanged). Add `ink: {0,0,0}, background: {255,255,255}` (and `muted: {0,0,0}` for symmetry, harmless — Certificate draws no muted today).

**Background wiring — mirror the existing `:frame` conditional-region/section idiom:** Certificate already builds regions conditionally (`certificate.ex:114-133`) and sections conditionally (`certificate.ex:163-202`). Prepend the `:background` region FIRST (before `body_region`) and the `:background` section FIRST, both gated on `Background.emit?(colors)`. Certificate resolves `{pw, ph} = Rendro.PageSize.resolve(page_size, orientation)` (`certificate.ex:91`) — pass those resolved (landscape) dims to the helper (Pitfall 4).

---

### `lib/rendro/recipes/{payslip,invoice,receipt,branded_invoice,ticket}.ex` (EDIT — bg wiring ONLY)

**Text seams: VERIFY-ONLY (D-02).** These 5 already pass an explicit swappable `color:` on every `Rendro.text` — do NOT edit their text or `palette/1` (their nil-branches already carry `background: {255,255,255}`: branded_invoice:238, invoice:477, payslip:689, receipt:483, ticket:521).

**Background wiring: REQUIRED (Pitfall 6).** All 7 recipes get the region + section prepend. Each recipe owns its own resolved `pw, ph`:
- **Payslip:** via `geometry(opts)` (`payslip.ex:374`, `g.content_w`/page dims).
- **Invoice/Receipt/BrandedInvoice/Ticket:** via each recipe's own `Rendro.PageSize.resolve/2` in its `page_template/1`.

**Wiring shape (same for all 7):**
```elixir
# in page_template/1
colors = palette(opts)
regions =
  if Rendro.Recipes.Background.emit?(colors),
    do: [Rendro.Recipes.Background.region(pw, ph) | base_regions],   # FIRST → bottom of paint stack
    else: base_regions
# in sections/2 — SAME predicate, same palette(opts)
sections =
  if Rendro.Recipes.Background.emit?(colors),
    do: [Rendro.Recipes.Background.section(colors, pw, ph) | base_sections],
    else: base_sections
```

---

### `lib/rendro/theme.ex` (EDIT — dark/1 @doc, D-09)

**Analog:** the existing `dark/1` `@doc` block (`theme.ex:224-243`). Add one sentence to the doc string: the explicit "screen-oriented, not recommended for print" boundary. `theming_claims_test.exs` asserts this sentence is present in `@doc`.

```elixir
# theme.ex:224-238 — EXISTING @doc to extend (add the boundary sentence)
@doc """
Returns the dark counterpart of a theme.

Resolves the input, then swaps the pre-resolved integer role tuples to their
dark targets and sets `mode: :dark`. `accent` is unchanged and `on_accent`
stays white (R2) — no transcendental color math at draw time.
...
"""
```

---

### `priv/support_matrix.json` (EDIT — `theming` row, D-09)

**Analog:** the `signing_preparation` `boundaries` block (`support_matrix.json:132-138`) — the exact idiom of a flat map of boundary keys → `"unsupported"`.

```json
// support_matrix.json:132-138 — EXISTING boundaries idiom to mirror
"boundaries": {
  "digital_signatures": "unsupported",
  "signer_identity_trust": "unsupported",
  "cryptographic_validity": "unsupported",
  "tamper_evidence": "unsupported",
  "pades_ltv_tsa_ocsp_crl": "unsupported"
}
```

**`theming` row to add (D-09):**
- `theming.light` = `supported`; capabilities: `no_background_rect`, `byte_identical_to_v2_10`, `deterministic_output`.
- `theming.dark` = `supported_screen_oriented`; capabilities: `full_page_background_every_page`, `overflow_page_background`, `deterministic_output`; **boundaries** (all `unsupported`): `print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim`.

---

### `test/rendro/recipes/theme_mode_background_golden_test.exs` (NEW — test, golden + structural, D-08)

**Analog A (light byte-identity):** `statement_byte_identity_test.exs` (whole file) — two-render equality + frozen sha256 comparison with the DEFECT-not-refresh doctrine comment. Reuse for D-08(a): light/no-theme emits NO background rect, byte-identical to the frozen golden.

```elixir
# statement_byte_identity_test.exs:30-48 — reuse this identity guard shape
test "two deterministic renders are byte-identical" do
  doc = Statement.document(toy_data())
  assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
  assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
  assert pdf1 == pdf2
end
```

**Analog B (dark golden + bless):** `test/support/golden.ex` `assert_or_bless/3` (human-gated, missing-ref hard-flunk). Use for the blessed dark golden (`priv/goldens/<recipe>/dark.sha256`).

**Dark structural op-order (D-08b, Pitfall 5):** page content streams are uncompressed under `deterministic: true` (corroborated by `path_test.exs:89-93` asserting `pdf =~ "re\nS"` on raw bytes). Assert:
```elixir
# fill op appears BEFORE the first BT (text) token, per page content stream
assert pdf =~ Rendro.Color.rg(Rendro.Theme.dark(Rendro.Theme.default()).colors.background)
# {27,23,19} → "0.1059 0.0902 0.0745 rg\n" (color.ex:14-16, 4-decimal)
```
- (a) light no-theme: reuse identity guard → no `rg` fill op, byte-identical.
- (b) dark: fill op is FIRST content op on page 1 AND on a forced-overflow page (use Statement with enough `:lines` to spill; assert fill op count == page count).
- (c) composition: two dark renders byte-identical (band/frame ops unchanged).

**Chosen recipes (RESEARCH Open Q1):** Statement (forced-overflow, paginates natively) + Certificate (landscape, non-portrait geometry proof).

---

### `test/docs_contract/theming_claims_test.exs` (NEW — test, docs-contract, D-09)

**Analog A (matrix boundary asserts):** `raster_claims_test.exs:7-14` — reads `priv/support_matrix.json`, asserts the new section + boundary keys + `"unsupported"` are present.

```elixir
# raster_claims_test.exs:7-14 — mirror this matrix-boundary assertion
test "support matrix has raster section with boundary declarations" do
  matrix = File.read!("priv/support_matrix.json")
  assert matrix =~ ~s|"raster"|
  assert matrix =~ ~s|"gui_viewer_equivalence"|
  assert matrix =~ ~s|"unsupported"|
end
```
For `theming`: assert `"theming"`, `"supported_screen_oriented"`, and each boundary key (`print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim`) each set to `"unsupported"`. Prefer parsed JSON (`JSON.decode!/1`, as `raster_claims_test.exs:20,48` does) to assert no `theming` row carries a print/PDF-UA/WCAG **support** term.

**Analog B (overclaim tripwire + non-vacuity teeth):** `accessibility_overclaim_test.exs` (whole file) — the term-list co-occurrence predicate + the "tripwire integrity (non-vacuity / teeth)" describe block. Mirror the teeth tests so the guard can never go vacuous.

```elixir
# accessibility_overclaim_test.exs:53-60 — mirror the non-vacuity teeth
test "showcase and accessibility term lists are both non-empty" do
  refute @showcase_terms == [], "..."
  refute @accessibility_terms == [], "..."
end
```

**@doc boundary-sentence assertion (D-09):** assert `Rendro.Theme.dark/1`'s `@doc` contains the "screen-oriented, not recommended for print" sentence. Read the compiled doc via `Code.fetch_docs/1` or scan `lib/rendro/theme.ex` source for the sentence.

**Do NOT create `guides/theming.md`** (Phase 123 / CONTRACT-02).

---

### `priv/goldens/<recipe>/dark.sha256` (NEW blessed refs)

**Analog:** existing `priv/goldens/**/*.sha256` — 1-line lowercase-hex hashes (`golden.ex` writes only the hash, not PDF bytes). Bless ONCE, deliberately, via `MIX_GOLDEN_BLESS=true` for the dark Statement (overflow) + dark Certificate (landscape). Never bless the existing frozen light `*_byte_identity_test.exs` goldens (Pitfall 2).

---

## Shared Patterns

### Background emit predicate (D-06, value-driven)
**Source:** `theme.ex:53` (`{255,255,255}`) + `theme.ex:65` (`{27,23,19}`).
**Apply to:** all 7 recipes (region + section gate) + the dark test.
```elixir
@paper_white {255, 255, 255}
def emit?(%{background: bg}), do: bg != @paper_white   # exact tuple, no tolerance
```

### Full-page fill rect via `Rendro.path/2`
**Source:** `payslip.ex:379-387` band + `lib/rendro.ex:242-263` `path/2` attr-split.
**Apply to:** `Rendro.Recipes.Background.section/3`.

### Text color seam — swappable role, never a literal (D-01)
**Source:** `payslip.ex:317-326` (header), `payslip.ex:546-547` (`cell_text/2`), `payslip.ex:669` (`page_number(color:)`).
**Apply to:** Statement + Certificate draw-sites. `Rendro.page_number/1` (`lib/rendro.ex:222-227`) forwards `color:` to `text/1` — the footer seam vehicle.

### `palette/1` nil-branch = today's literals (D-03 byte-identity seam)
**Source:** `payslip.ex:680-699` (full reference), `statement.ex:347-361`, `certificate.ex:374-387`.
**Apply to:** Statement + Certificate palette completion. Golden goldens (`*_byte_identity_test.exs`) are the enforcement gate.

### Golden byte assertion + DEFECT-not-refresh doctrine
**Source:** `statement_byte_identity_test.exs:6-13` (doctrine comment) + `test/support/golden.ex` `assert_or_bless/3`.
**Apply to:** the new dark golden test; every touched recipe's existing byte-identity test must stay green with NO bless.

### Docs-contract claim boundary
**Source:** `support_matrix.json:132-138` (boundaries idiom) + `raster_claims_test.exs:7-14` (matrix asserts) + `accessibility_overclaim_test.exs` (tripwire teeth).
**Apply to:** `theming` matrix row + `theming_claims_test.exs`.

## No Analog Found

None. Every new/modified file maps to an in-repo analog. The one nuance: the
**dark structural op-order assertion** (fill op before first `BT`, per-page,
count == page count) has no exact prior test — it is assembled from the raw-binary
regex idiom in `path_test.exs:89-93` plus `Rendro.Color.rg/1` (`color.ex:14-16`).
This is a novel *assembly* of existing idioms, not a missing analog.

## Metadata

**Analog search scope:** `lib/rendro/recipes/`, `lib/rendro/{theme,color,path,region,page_template}.ex`, `lib/rendro.ex`, `lib/rendro/pipeline/{paginate,writer,compose,measure}.ex` (per RESEARCH refs), `test/rendro/recipes/`, `test/docs_contract/`, `test/support/golden.ex`, `priv/support_matrix.json`.
**Files scanned this session:** 11 read + 2 grep passes.
**Pattern extraction date:** 2026-07-27
</content>
</invoke>

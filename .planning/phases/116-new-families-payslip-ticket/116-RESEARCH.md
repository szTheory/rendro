# Phase 116: New families — Payslip & Ticket - Research

**Researched:** 2026-07-18
**Domain:** Elixir PDF-recipe authoring (internal codebase pattern verification, no new external dependencies)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All 19 decisions below are locked from a 4-agent parallel research fan-out (per-area pros/cons, Elixir/ecosystem idiom, prior art, DX/UX, design pillars). They are mutually coherent: both recipes share one anchor-dominance pattern, one palette seam, one override-map opts convention, and reuse existing primitives.

**Ticket archetype & geometry (FAM-02)**
- **D-01:** Ship **one** `Rendro.Recipes.Ticket` family. The concrete **default is an event/admission ticket** (anchor = Section/Row/Seat; demo business = the milestone's **Aurora Live** fixture). Boarding-pass (Gate/Seat/Group, origin→destination) and transit are the *same recipe* reached purely by caller **data + labels** — **no archetype branching in `lib/`**.
- **D-02:** Model the anchor as an ordered **placement grid** — `:placement => [%{label, value}]` (1–4 cells). Labels render small/caps/muted (~8pt); **values render in the largest type on the page** (~22pt, `ink`) — the single dominant element (rubric hierarchy = 5). Archetype-agnostic.
- **D-03:** **Geometry derived from template**, mirroring `Rendro.Recipes.Certificate` (zero hardcoded A4 numerics; all x/y/w/h from `PageSize.resolve/2` + margins). Default page = **A4 portrait**; `page_size: :a4 | :us_letter | {w, h}` supported. The ticket itself is a **fixed landscape band anchored at the top of the page** (`anchor: :fixed`), full content-width, height = a dimensionless ratio of content width (~2.4:1 strip). A `:main` region (left ~68%) + `:stub` region (right ~32%) split by a **vertical perforation** at `x ≈ band_w × 0.68`. Optional `:terms` region below the band (`anchor: :flow`, muted fine print).
- **D-04:** **Overflow never truncates.** `validate_data!/1` guards over-length free-text fields (byte guards à la Certificate's 2000-byte `:body` guard) with a friendly four-part `ArgumentError` *before* render; any content that still exceeds a fixed region surfaces as the pipeline's typed `:content_overflow`.

**Ticket code-area, no-PNG fallback & perforation (FAM-02)**
- **D-05:** Code area lives in the stub. **Always** draw a bordered code box — `%Rendro.Path{ops: [{:rounded_rect, ...}], stroke: %{color: palette.rule}}`, ≥ ~100×100pt, optional `fill: palette.surface`.
- **D-06:** **The human-readable reference is REQUIRED and always renders** — even when a PNG is supplied. Data shape: `data.code = %{reference: String.t() (required), label: String.t()|nil (default "Reference"), image: {:path,p}|{:binary,b}|nil}`. Reference set large + upper-cased (`palette.ink`, ~14–16pt) with a small muted caption label above.
- **D-07:** **No PNG → box contains the centered reference** + optional 1-line caption ("Present this reference at entry"). **NEVER draw a faux barcode/QR**.
- **D-08:** **PNG supplied → fit-contain (aspect-preserving), centered** via `Rendro.Component.image(:ticket_code, fit: {box_w, box_h})`. Never stretch-to-fill. Recipe registers the image internally under the fixed logical name `:ticket_code`. `image: nil` ⇒ byte-identical to the no-PNG path.
- **D-09:** **Perforation** = dashed `%Rendro.Path{}` (`dash: [3, 3]`, `width: 0.75pt`, `color: palette.rule`). Vertical at the stub's inner x-edge by default; degrade to horizontal for a bottom-tear portrait variant; omit entirely when there is no stub region. No scissors glyph. Repeat the anchor + reference in the stub.
- **D-10:** Bad/corrupt/non-PNG image → call the **pure** `Rendro.ImageParser.parse/1` inside `validate_data!` and raise an instructive `ArgumentError` naming `data.code.image` (do NOT let raw `InvalidAssetError` leak from `register_image`). Oversized image → **no error** (fit-contain scales down deterministically). Missing/blank `reference` → instructive `ArgumentError`.

**Payslip anchor & layout (FAM-01)**
- **D-11:** **Net-pay anchor = a full-width tinted band directly under the identity header** (own `:summary` region, `anchor: :top`): a `{:rect}` band (`surface`/`paper-200` fill + hairline `rule` top border) with label "NET PAY" (10pt `muted`) and the **value at 26–28pt heaviest weight, `ink`/`accent`** — the single largest element on the page (hierarchy = 5), legible in grayscale.
- **D-12:** **Earnings/deductions = ONE combined ledger table** with two column-groups: `[Earnings, Current, YTD | Deductions, Current, YTD]`, a mid vertical rule (`borders: :columns`), money right-aligned via `cell_align: %{1=>:right, 2=>:right, 4=>:right, 5=>:right}`. Rows zipped to equal length (blank-padded). A bold subtotal row ("Gross Pay | Total Deductions") closes the grid. **YTD is a per-line column inside each group**, not a separate table — decisive because a single table **paginates natively** through `Pagination.chunk_rows_into_pages/2`; two fixed side-by-side regions cannot paginate.
- **D-13:** **Gross→net reconciliation as a "kept-with-last" trailing block** (height reserved on every page à la Invoice's `@totals_line_height`): `Gross {g} − Deductions {d} = Net {n}` plus a compact YTD summary trio. In `validate_data!/1`: derive `gross`/`deductions` (Decimal fold), and **assert `Decimal.equal?(net_pay, Decimal.sub(gross, deductions))`** (never `==`). If optional `:totals` supplied, assert each against derived. Reject Float money instructively; validate row shape so no `BadMapError` leaks.
- **D-14:** **4-region template** (like `branded_invoice.ex`): `:header` (employer/employee identity + pay period/date, masked ids), `:summary` (net-pay band), `:body` (`anchor: :flow` — combined table + trailing reconciliation), `:footer` (`anchor: :bottom` — masked payment method + `Rendro.page_number/1`). Single page for realistic payslips on both A4 and Letter; genuine overflow paginates or surfaces typed `:content_overflow`. **PII masking is mandatory** in fixtures.
- **D-15:** Sketched Payslip data map: `%{employer: %{name (req), address}, employee: %{name (req), id, tax_code}, period: %{from, to} (req), pay_date (req), earnings: [%{description, amount, ytd}] (req, ≥1), deductions: [%{description, amount, ytd}] (req), net_pay: Decimal (req — anchor + assert target), totals: %{gross, deductions, net, gross_ytd, deductions_ytd, net_ytd} (optional caller assertions), payment_method (optional, masked)}`.

**Jurisdiction / label / formatting data contract (FAM-01, FAM-03) — applies to BOTH recipes**
- **D-16:** **Reuse the incumbent override-map convention — no jurisdiction profile, no named `:profile` atom, no per-country recipe.** Three orthogonal override seams thread through the open `opts` keyword: `:palette` (merged in `defp palette(opts)`, verbatim from `invoice.ex:371`), `:labels` (resolved by generalized `Pagination.label_resolver/2`), `:formatters` (resolved by `Pagination.formatter/3` with `&Rendro.Format.money/1` / `&Rendro.Format.date/1` defaults — money formatter is sole owner of currency symbol + grouping + negative style).
- **D-17:** **Statutory line content lives in each earnings/deduction line's `:description`** (data, exactly Statement's `lines[].description` pattern). Chrome labels come from `:labels`. This is the "engine never learns a jurisdiction" boundary.
- **D-18:** **Ship recipe-owned `@default_labels`** so the happy path is one line. Generalize `label_resolver` to **arity-2** — `label_resolver(opts, default_labels \\ %{})` with merge order `opts[:labels] → recipe @default_labels → Rendro.Format.label/1`. Keeps `Rendro.Format` frozen at its 5 statement keys; keeps Statement's existing arity-1 call working (additive). Payslip's `@default_labels`: earnings/deductions/description/amount/ytd_amount/gross_pay/total_deductions/**net_pay**/year_to_date/pay_period/pay_date/employer/employee. Ticket ships its own (`admit`, `seat`/`gate`/`section`/`row`/`reference`, `present_code`). **Never render a blank/humanized fallback.**
- **D-19:** **Errors-as-product opts validation (satisfies FAM-03):** shared validators in `Pagination`, wired into Payslip/Ticket. `:labels` if present must be a `map` with non-empty binary values; `:formatters` if present must be a `keyword` with arity-1-function values (`is_function(f, 1)`). Malformed → instructive four-part `ArgumentError` via `Pagination.type_name/1` — never leak `BadMapError`/`BadArityError`. Scope to Payslip/Ticket now; Invoice/Statement may retrofit additively later.

### Claude's Discretion
- Exact point sizes, band tint depth, gutter widths, caption default strings, and column-share ratios are guidance-level — refine within the locked hierarchy/pattern as long as the anchor stays dominant (rubric hierarchy = 5), money stays right-aligned, and colors stay sourced from `palette(opts)`.
- Whether a small optional accent element (ticket-type pill, emphasis bar) is included is discretionary, provided it reads via `palette.accent`/`on_accent`.

### Deferred Ideas (OUT OF SCOPE)
- **Live barcode/QR generation primitive** — explicitly out of scope (REQUIREMENTS). Ticket uses a boxed code-area + human-readable reference + optional caller-supplied PNG only.
- **Engine locale-awareness (CLDR/gettext/ex_money)** — out of scope by construction; jurisdiction stays caller data.
- **Boarding-pass / transit as distinct recipes or named jurisdiction profiles** — rejected; same Ticket/Payslip recipe reached by data + labels. If real demand ever justifies opinionated presets, that belongs to Milestone C, not here.
- **Optional Ticket tear-notch half-circles (`{:curve}` at perforation ends)** — gold-plate; defer unless it falls out cheaply.
- **Invoice/Statement retrofitting the arity-2 `label_resolver` and opts-shape validation** — additive, family-coherence nicety; out of scope for Phase 116.
- **`Rendro.Theme` palette threading (Milestone B)** — the palette seam is shaped for it; no work here beyond honoring the seam.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAM-01 | `Rendro.Recipes.Payslip` renders a production-grade payslip on the 3-rung pattern with net pay as the visual anchor, side-by-side earnings/deductions, and YTD totals; jurisdiction differences are label data, not engine logic. | Verified `palette(opts)`, `cell_align`, `Decimal.equal?/2` + `@totals_line_height` reservation, and `branded_invoice.ex`'s 4-region template all exist exactly as CONTEXT.md's D-11–D-15 assume — see Verified Code Anchors. See Common Pitfalls 4–6 for the combined-table vs two-fixed-tables trap and the Decimal-equality trap. |
| FAM-02 | `Rendro.Recipes.Ticket` renders a fixed-box ticket/boarding-pass on the 3-rung pattern with seat/gate/section as the anchor, a boxed code-area + human-readable reference + perforation line, and an optional caller-supplied PNG code image; content overflow raises a typed error. | Verified `certificate.ex`'s geometry-derived-template pattern, `{:rounded_rect}` + `dash:` Path options, `Component.image/2` fit-contain, and `:content_overflow` typed-error pipeline all exist as D-01–D-10 assume. Finding 6 / Pitfall 3 flags that caller-supplied-image pre-validation (D-10) has no prior-art copy source in this codebase — plan it as new work. |
| FAM-03 | Both new recipes validate input as errors-as-product (instructive `ArgumentError`), read colors via the `palette(opts)` seam (S1), and are registered in `priv/public_api.json` (adapter tier) and `priv/support_matrix.json`. | Verified the four-part `ArgumentError` idiom, `priv/support_matrix.json` row shape (~line 440+). Finding 1 flags that `priv/public_api.json` registration additionally requires editing `@public_modules` in `lib/mix/tasks/rendro/api.gen.ex` — not mentioned in CONTEXT.md, must be an explicit task. Finding 7 confirms D-19's opts-shape validators are net-new code with no existing `validate_labels!`/`validate_formatters!` to copy. |

</phase_requirements>

## Summary

This phase adds two new adapter-tier recipes (`Rendro.Recipes.Payslip`, `Rendro.Recipes.Ticket`) on top of an already-mature 3-rung recipe pattern. CONTEXT.md's 19 locked decisions are the design; this research's job was to verify every code anchor CONTEXT.md cites and surface anything that would trip up planning. **All cited engine primitives exist exactly as described** — `palette(opts)`, `cell_align`, Decimal totals + `Decimal.equal?/2` + `@totals_line_height`, `Keyword.take` whitelist, `Pagination.{formatter/3,label_resolver/1,chunk_rows_into_pages/2,measure_rows/4,type_name/1}`, `Path.{:rounded_rect}` + `dash:`, `measure.ex` fit-contain, `Component.image/2`, `Document.register_image/3`, `ImageParser.parse/1`, `PageSize.resolve/2`, and the Certificate/BrandedInvoice structural analogs. No new engine surface is required, confirming CONTEXT.md's central de-risking claim.

Three findings go beyond "verified, no drift" and need explicit planner attention: (1) registering a new adapter-tier module in `priv/public_api.json` requires editing an **explicit module allowlist** in `lib/mix/tasks/rendro/api.gen.ex` (`@public_modules`), not just adding `@moduledoc tags: [:adapter]` — CONTEXT.md doesn't mention this file; (2) `priv/schemas/examples.schema.json` is **hard-coded to the Invoice fixture shape** (`required: fixture_id, issuer, customer, invoice, items`) and a docs-contract test validates *every* file under `priv/examples/**/*.json` against it — dropping a Payslip/Ticket-shaped fixture into `priv/examples/` without first generalizing this schema will break `test/docs_contract/examples_schema_contract_test.exs`; (3) none of the three already-shipped families (Statement, Receipt, Certificate) actually have a `priv/examples/` fixture today — only Invoice does — so the precedent for *where new-family "fictional data only" fixtures live* is genuinely ambiguous between "test-local fixture helpers" (the Statement/Certificate pattern) and "shared `priv/examples/` library" (the Invoice/EXL pattern, whose full family rollout is SHOW-01, Phase 118). The planner must make an explicit call here.

**Primary recommendation:** Follow CONTEXT.md's decisions verbatim (they are sound and every cited anchor is real); additionally (a) update `@public_modules` in `lib/mix/tasks/rendro/api.gen.ex` as part of the FAM-03 registration task, (b) keep Payslip/Ticket "fictional data only" fixtures **test-local** (mirroring Statement/Certificate's `defp fixture_data(...)` helper pattern) rather than adding to `priv/examples/`, deferring shared-library population + schema generalization to Phase 118 (SHOW-01) unless the user overrides this in planning, and (c) implement `Pagination`'s new arity-2 `label_resolver/2` and opts-shape validators (`:labels`/`:formatters`) as genuinely new code — no prior art exists for either in this codebase.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Payslip document assembly (`document/2`) | Recipe/Adapter (`lib/rendro/recipes/payslip.ex`) | Core engine (`Rendro.Document`, pipeline) | Recipes are the adapter tier; they compose core primitives, never add new deterministic-core behavior |
| Ticket document assembly (`document/2`) | Recipe/Adapter (`lib/rendro/recipes/ticket.ex`) | Core engine | Same as above |
| Net-pay / anchor visual hierarchy | Recipe (section builder) | — | Pure layout composition using existing `Rendro.region`/`Rendro.text`/`Rendro.Path` primitives; no core change |
| Money formatting / label resolution | Adapter (`Rendro.Format`, `Pagination`) | Recipe (opts threading) | `Rendro.Format` is the frozen public adapter surface; `Pagination` is the shared `@moduledoc false` internal helper both recipes call into |
| Jurisdiction/label/locale differences | Caller data (`:labels`, `:formatters`, line `:description`) | — | Explicitly locale-free-by-construction; engine and adapter tier never branch on jurisdiction |
| Row pagination / overflow detection | Core pipeline (`lib/rendro/pipeline/paginate.ex`, `measure.ex`) | Recipe (`Pagination.chunk_rows_into_pages/2`) | Deterministic fit/overflow logic lives in the core pipeline; recipes only compute capacity and call the shared chunker |
| Image validation (caller-supplied PNG) | Recipe `validate_data!/1` (new pattern) | Core (`Rendro.ImageParser.parse/1`, `Rendro.AssetRegistry`) | Pure parse function already exists in core; pre-validating *caller-supplied* bytes before `register_image/3` is new recipe-level plumbing (see Common Pitfalls) |
| Registration/proof (public API + support matrix) | Build tooling (`mix rendro.api.gen`) + `priv/*.json` | Docs-contract test lane | Registration is a generated-artifact concern, not a runtime concern |

## Standard Stack

No new external dependency is required for this phase. All primitives are internal to the `rendro` codebase (Elixir 1.19, `decimal ~> 2.3`, already a direct dependency — no version bump needed).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `decimal` | `>= 2.3.0 and < 4.0.0` (already in `mix.exs:59`, unchanged) | Money arithmetic (`Decimal.equal?/2`, `Decimal.add/sub/mult`) | Already the project's money type; Payslip's gross/deductions/net reconciliation reuses Invoice's exact idiom |

### Supporting
None — no new libraries are introduced by this phase.

### Alternatives Considered
Not applicable — this is an internal-pattern-reuse phase, not a new-dependency phase. See `Package Legitimacy Audit` below (N/A).

**Installation:**
```bash
# No new dependencies. mix.exs is unchanged by this phase.
```

## Package Legitimacy Audit

**Not applicable.** This phase installs no new external packages. `decimal` is an existing, already-vetted direct dependency (`mix.exs:59`) reused as-is; no new `deps()` entries, no new `npm`/`pip`/`cargo` packages. The Package Legitimacy Gate protocol is skipped for this reason.

## Architecture Patterns

### System Architecture Diagram

```
Caller data (Elixir map, keyword opts)
        │
        ▼
┌───────────────────────────────┐
│ Payslip.validate_data!/1      │  ← errors-as-product: instructive ArgumentError
│ Ticket.validate_data!/1       │     (money type, required keys, opts shape D-19,
│                                │      image bytes via ImageParser.parse/1 for Ticket)
└───────────────┬───────────────┘
                │ valid data
                ▼
┌───────────────────────────────┐
│ page_template/1               │  ← geometry derived from PageSize.resolve/2 +
│  (Keyword.take whitelist)     │     margins; zero hardcoded A4/Letter numerics
└───────────────┬───────────────┘
                │ %Rendro.PageTemplate{}
                ▼
┌───────────────────────────────┐
│ sections/2                    │  ← palette(opts) (S1) + label_resolver (opts/2) +
│  (region → section builders)  │     formatter/3 read colors/labels/money formatting;
│                                │     Payslip: header/summary/body/footer (4-region,
│                                │     branded_invoice.ex analog)
│                                │     Ticket: main/stub/[terms] (fixed band, certificate.ex
│                                │     analog) + code-box Path + dashed perforation Path
└───────────────┬───────────────┘
                │ [%Rendro.Section{}]
                ▼
┌───────────────────────────────┐
│ Rendro.Document.new()         │  ← Ticket only: register_image(:ticket_code, source)
│  + register_image/3 (Ticket)  │     under a fixed logical name, mirroring
│  + add_template + add_section │     Certificate/BrandedInvoice's logo registration
└───────────────┬───────────────┘
                │ %Rendro.Document{}
                ▼
┌───────────────────────────────┐
│ Core render pipeline          │  ← measure.ex (fit-contain image sizing),
│ (measure → paginate → write)  │     paginate.ex (chunk_rows_into_pages,
│                                │     validate_region_fit!/validate_page_fit! →
│                                │     typed :content_overflow error)
└───────────────┬───────────────┘
                │ deterministic PDF bytes (or {:error, %Rendro.Error{}})
                ▼
        Caller / test / gallery
```

Registration side-channel (build-time, not runtime):
```
lib/rendro/recipes/payslip.ex, ticket.ex
  (@moduledoc tags: [:adapter])
        │
        ▼
lib/mix/tasks/rendro/api.gen.ex  @public_modules  ← MUST add both modules here
        │  mix rendro.api.gen
        ▼
priv/public_api.json  (byte-diffed by test/docs_contract/public_api_contract_test.exs)

priv/support_matrix.json  (new "payslip"/"ticket" rows, hand-authored,
                            evidence: path to the new recipe's test file)
```

### Recommended Project Structure
```
lib/rendro/recipes/
├── payslip.ex           # new — 4-region template, net-pay anchor, combined ledger table
├── ticket.ex            # new — fixed landscape band, main/stub regions, code box + perforation
└── pagination.ex        # extended — label_resolver/2 (additive), :labels/:formatters opts validators (D-19)

test/rendro/recipes/
├── payslip_test.exs      # new — mirrors statement_test.exs/certificate_test.exs fixture_data() pattern
├── ticket_test.exs       # new — same
└── ...

priv/
├── public_api.json        # regenerated via `mix rendro.api.gen` after @public_modules update
└── support_matrix.json    # + "payslip"/"ticket" rows (statement/certificate row shape)
```

### Pattern 1: `palette(opts)` color seam (S1) — copy verbatim
**What:** A private function returning a role→`{r,g,b}` map, merged with caller `:palette` overrides.
**When to use:** Every color read in both new recipes' section builders.
**Example:**
```elixir
# Source: lib/rendro/recipes/invoice.ex:371 (verbatim copy target)
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

### Pattern 2: `page_template/1` `Keyword.take` whitelist — copy verbatim
**What:** Filters caller `opts` down to `%Rendro.PageTemplate{}` struct keys before calling `Rendro.page_template/1`, so recipe-only keys (`:palette`, `:labels`, `:formatters`) never reach `struct!/2`.
**When to use:** Both recipes' `page_template/1`.
**Example:**
```elixir
# Source: lib/rendro/recipes/invoice.ex:119-129
template_opts =
  Keyword.take(opts, [
    :name, :width, :height,
    :margin_top, :margin_right, :margin_bottom, :margin_left,
    :regions
  ])

Rendro.page_template(Keyword.merge(defaults, template_opts))
```

### Pattern 3: Geometry-derived-from-template (Certificate analog) — for Ticket
**What:** Zero hardcoded A4/Letter numerics; every x/y/w/h computed from `PageSize.resolve/2` + margin opts.
**When to use:** Ticket's fixed landscape band, `:main`/`:stub` split, optional `:terms` region.
**Example:**
```elixir
# Source: lib/rendro/recipes/certificate.ex:81-135 (pattern to clone)
{pw, ph} = Rendro.PageSize.resolve(page_size, orientation)
ml = Keyword.get(opts, :margin_left, @default_margin)
mr = Keyword.get(opts, :margin_right, @default_margin)
mt = Keyword.get(opts, :margin_top, @default_margin)
mb = Keyword.get(opts, :margin_bottom, @default_margin)
content_w = pw - ml - mr

# Ticket-specific: band height as a ratio of content width (~2.4:1), NOT a
# fixed-point constant, so A4/Letter fall out identically (D-03).
band_w = content_w
band_h = band_w / 2.4
stub_x = band_w * 0.68
```

### Pattern 4: Dashed perforation + bordered code box (Path primitives)
**What:** `%Rendro.Path{}` with `{:rounded_rect, x, y, w, h, radius}` op for the code box; a straight-line dashed path for the perforation.
**When to use:** Ticket stub region.
**Example:**
```elixir
# Source: lib/rendro/path.ex — {:rounded_rect} op (line ~61) + dash stroke option (line ~72)
code_box = %Rendro.Path{
  ops: [{:rounded_rect, box_x, box_y, box_w, box_h, 6.0}],
  stroke: %{color: palette.rule, width: 1.0}
}

perforation = %Rendro.Path{
  ops: [{:move_to, stub_x, band_y}, {:line_to, stub_x, band_y + band_h}],
  stroke: %{color: palette.rule, width: 0.75, dash: [3, 3]}
}
```
(Exact op names for straight-line paths must be confirmed against `lib/rendro/path.ex`'s full op union at plan/implementation time — `{:rounded_rect}` is confirmed; the plain line-segment op name was not re-derived in this pass since D-09 only requires "a dashed line," not a specific op — see Open Questions.)

### Pattern 5: Recipe-owned fixed-name image registration (Certificate/BrandedInvoice analog)
**What:** Recipe registers a caller-supplied image under an internal fixed logical name; caller never touches the asset registry.
**When to use:** Ticket's optional PNG code image (`:ticket_code`).
**Example:**
```elixir
# Source: lib/rendro/recipes/certificate.ex:257-260 (adapt: source is CALLER-supplied
# binary/path here, not a fixed internal asset path like Rendro.Branded.logo_path())
base_doc =
  if image = get_in(data, [:code, :image]) do
    Rendro.Document.register_image(base_doc, :ticket_code, image)
  else
    base_doc
  end
```
**Important divergence from the Certificate/BrandedInvoice precedent:** Certificate/BrandedInvoice always register a *library-shipped* logo path (`Rendro.Branded.logo_path()`), so a malformed image can never come from untrusted caller input today. Ticket's `:code.image` is the **first caller-supplied image byte source** in any recipe. `Rendro.AssetRegistry.register_image/3` raises `Rendro.AssetRegistry.InvalidAssetError` (not `ArgumentError`) on bad bytes (`lib/rendro/asset_registry.ex:44-59`). D-10 requires pre-validating with the pure `Rendro.ImageParser.parse/1` inside `validate_data!/1` so the recipe can raise an instructive `ArgumentError` *before* `register_image/3` ever runs — this is new plumbing with no prior-art recipe to copy verbatim (see Common Pitfalls).

### Anti-Patterns to Avoid
- **Inlining `{r,g,b}` literals in section builders:** Breaks the S1 palette seam; every color must resolve through `palette(opts)`.
- **Two separate `anchor: :fixed` tables for Payslip earnings/deductions:** D-12 explicitly rejects this — it cannot paginate via the existing `Pagination.chunk_rows_into_pages/2` chunker. Use one combined table.
- **Drawing a faux barcode/QR pattern for Ticket's no-PNG fallback:** Explicitly forbidden by D-07 (honesty guard) — never draw stripes that could be mistaken for a scannable code.
- **Letting `Rendro.AssetRegistry.InvalidAssetError` leak from `register_image/3`:** Must be caught/pre-empted per D-10 — this is not automatic; `register_image/3` will raise its own exception type if the recipe skips pre-validation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Right-aligned money columns | Fixed-width string padding | `cell_align: %{col => :right}` (`lib/rendro.ex:475`) | Already a real alignment primitive since Phase 115; the old "fake it" caveat no longer applies |
| Multi-page table chunking | Custom row-splitting loop | `Rendro.Recipes.Pagination.chunk_rows_into_pages/2` | Shared, already handles the "always keep at least one row" edge case and empty-page guards |
| Row height measurement | Manual point-size estimates | `Rendro.measure_rows/4` (`lib/rendro.ex:357`) | Uses the engine's own font metrics; hand-rolled estimates are the documented cause of `:content_overflow` false negatives |
| Aspect-preserving image scaling | Manual width/height math | `Component.image(name, fit: {w, h})` → `measure.ex` deterministic fit-contain | Already handles both the "wide box, tall image" and "tall box, wide image" letterbox cases correctly |
| Money-equality assertions | `==` on `Decimal` structs | `Decimal.equal?/2` | `Decimal.new("1.0") == Decimal.new("1.00")` is `false` under `==` (different struct fields) but `true` under `Decimal.equal?/2` — Invoice already learned this the hard way (comment at `invoice.ex:636`) |
| PNG/JPEG dimension parsing | Custom binary pattern-matching | `Rendro.ImageParser.parse/1` (pure) | Already handles PNG + JPEG signature detection deterministically |
| Instructive error formatting | Ad-hoc error strings | Four-part What/Where/Why/Next `ArgumentError` idiom (see any `validate_data!` in Invoice/Certificate) | Established, tested, and expected by users of every other recipe |

**Key insight:** Every "hard part" of this phase (alignment, pagination, image fit, money equality, image parsing) already has a proven, tested primitive in this codebase. The actual net-new work is entirely at the *recipe composition* level — assembling existing primitives into new layouts — plus two small, genuinely new pieces of shared plumbing: `Pagination.label_resolver/2` and `Pagination`'s opts-shape validators (D-19).

## Verified Code Anchors

Per-claim verification of every code anchor CONTEXT.md cites, against the codebase as of this research session (`gsd/v2.10-realistic-business-document-examples-anatomy` branch):

| Claim (CONTEXT.md) | Status | Actual location |
|---|---|---|
| `invoice.ex:371` `defp palette(opts)` | **VERIFIED, exact line** | `lib/rendro/recipes/invoice.ex:371` |
| `lib/rendro.ex:475` `cell_align` | **VERIFIED, exact line** | `lib/rendro.ex:475` — `defp normalize_table_cell_align(attrs)`, the core `Rendro.table/2` cell-align validator (not the recipe layer) |
| Invoice Decimal totals kept-with-last-rows + `Decimal.equal?/2` assert (~640–687) + `@totals_line_height` | **VERIFIED, lines shifted slightly** | `@totals_line_height` at `invoice.ex:61`; kept-with-last-rows capacity reservation at `invoice.ex:244-266` (`totals_reserved_height/1`); `Decimal.equal?/2` asserts at `invoice.ex:647` and `invoice.ex:673` (both within cited range) |
| `page_template/1` `Keyword.take` whitelist (~line 119) | **VERIFIED, exact line** | `lib/rendro/recipes/invoice.ex:120` (the `Keyword.take(opts, [...])` call; `def page_template` opens at line 81) |
| `pagination.ex` `formatter/3`, `label_resolver/1`, `chunk_rows_into_pages/2`, `measure_rows/4`, `type_name/1` | **VERIFIED except one placement detail** | `chunk_rows_into_pages/2` at `pagination.ex:18`; `formatter/3` at `pagination.ex:57`; `label_resolver/1` at `pagination.ex:64` (**arity-1 confirmed**, see below); `type_name/1` at `pagination.ex:76-82`. `measure_rows/4` is **not** in `pagination.ex` — it lives in `lib/rendro.ex:357` (a top-level `Rendro` facade function, not `Rendro.Recipes.Pagination`). Minor mis-citation; does not affect the plan (the function exists and behaves as described). |
| `path.ex` `{:rounded_rect}` op + `dash:` stroke option | **VERIFIED** | `lib/rendro/path.ex:61` (`{:rounded_rect, x, y, w, h, radius}`), `lib/rendro/path.ex:72` (`optional(:dash) => nil \| [number()]`) |
| `measure.ex:110-119` deterministic fit-contain | **VERIFIED, region confirmed** | `lib/rendro/pipeline/measure.ex` — the `{nil, nil, {fit_w, fit_h}}` branch computing aspect-preserving contain sits in the ~103-119 range of `measure_block/3` for `%Rendro.Image{}` content |
| `component.ex` `image/2` + `fit:` | **VERIFIED** | `lib/rendro/component.ex:20` (`def image(logical_name, opts \\ [])`, requires at least one of `:width`/`:height`/`:fit`) |
| `document.ex` `register_image/3` | **VERIFIED** | `lib/rendro/document.ex:201` (delegates to `Rendro.AssetRegistry.register_image/3`) |
| `image_parser.ex` pure `parse/1` | **VERIFIED** | `lib/rendro/image_parser.ex:26` / `:41` / `:45` (multiple clauses; `@moduledoc false` — internal, not adapter-tier, still callable from within the app) |
| `page_size.ex` `resolve/2` + `{w,h}` tuple support | **VERIFIED** | `lib/rendro/page_size.ex:11-17` — `resolve({w, h}, :portrait)` and `resolve({w, h}, :landscape)` clauses exist alongside `:a4`/`:us_letter` |
| Certificate byte-guarded `validate_data!` + `%Rendro.Path{}` frame + logo image registration | **VERIFIED** | Byte guard at `certificate.ex:460` (`byte_size(body) > 2000`); frame `%Rendro.Path{}` at `certificate.ex:185`; logo registration at `certificate.ex:257-260` via `Document.register_image/3` |
| `branded_invoice.ex` 4-region template | **VERIFIED** | `lib/rendro/recipes/branded_invoice.ex` — regions `:logo` (anchor `:fixed`), `:header` (`:top`), `:body` (`:flow`), `:footer` (`:bottom`) |
| `Rendro.Format` frozen at 5 label keys | **VERIFIED, keys enumerated** | `lib/rendro/format.ex:28-33` — `@labels %{balance:, brought_forward:, carried_forward:, opening_balance:, closing_balance:}` (exactly 5) |
| `label_resolver` currently arity-1 | **VERIFIED** | `pagination.ex:64` — `def label_resolver(opts) do`; only callers are `statement.ex:274` and `statement.ex:294` (both arity-1 call sites, both would keep working unmodified if `label_resolver/2` is added additively with `default_labels \\ %{}`) |
| `priv/support_matrix.json` row shape (~line 440+) | **VERIFIED, exact line** | `statement` row starts at `priv/support_matrix.json:440`; `receipt_report` at `:451`; `certificate` at `:462`. Shape: `{"surface": <name>, "status": "supported", "evidence": <test file path>, "recorded_at": "<date>", "capabilities": {<key>: "supported", ...}}` |

**Everything CONTEXT.md cited exists and behaves as described.** The only correction is `measure_rows/4`'s module (it's `Rendro.measure_rows/4` via `lib/rendro.ex`, not `Rendro.Recipes.Pagination`) — a citation-precision issue only, not a design or plan risk.

## Additional Findings Not Explicitly Cited in CONTEXT.md

### Finding 1: `priv/public_api.json` registration requires an explicit module allowlist edit

`mix rendro.api.gen` (`lib/mix/tasks/rendro/api.gen.ex`) does **not** auto-discover adapter-tier modules by scanning `lib/`. It introspects a hardcoded `@public_modules` list (`lib/mix/tasks/rendro/api.gen.ex:41+`), which currently includes:
```elixir
Rendro.Recipes.BrandedInvoice,
Rendro.Recipes.Certificate,
Rendro.Recipes.Invoice,
Rendro.Recipes.Receipt,
Rendro.Recipes.Statement,
```
`Rendro.Recipes.Payslip` and `Rendro.Recipes.Ticket` must be **added to this list** (alphabetically, per the generator's sort-and-diff test, `test/docs_contract/public_api_contract_test.exs`) in addition to giving both new modules `@moduledoc tags: [:adapter]`. Skipping this step means `mix rendro.api.gen` will silently omit the new recipes from `priv/public_api.json` even though their `@moduledoc` tag is correct — `test/docs_contract/public_api_contract_test.exs`'s "manifest surface equality" assertion (Assertion 2) will then fail with a two-list drift diff naming the modules as "in code but NOT in manifest." **The planner should add this as an explicit task step for FAM-03**, not assume `mix rendro.api.gen` alone is sufficient.

### Finding 2: `priv/schemas/examples.schema.json` is Invoice-shaped, not family-agnostic — schema drift risk if Phase 116 populates `priv/examples/`

`priv/schemas/examples.schema.json` (`required: ["fixture_id", "issuer", "customer", "invoice", "items"]`) is the **single schema** validated against **every** file matched by `Path.wildcard("priv/examples/**/*.json")` in `test/docs_contract/examples_schema_contract_test.exs` (line 23). This schema has no `family`/`domain` discriminator — it assumes every fixture is Invoice-shaped. If a `priv/examples/payslip/.../payslip.json` or `priv/examples/ticket/.../ticket.json` fixture is added without first generalizing this schema (e.g., a `oneOf` branch keyed on a new `family` field, or per-family schema files), **`examples_schema_contract_test.exs` will fail** because the new fixture won't have `issuer`/`customer`/`invoice`/`items`. See "Runtime State Inventory" analog below (this is a schema/contract gap, not a runtime-data gap, but the same "what breaks silently downstream" discipline applies) and Open Questions for the recommended resolution.

### Finding 3: Only Invoice currently has a `priv/examples/` fixture — Statement/Receipt/Certificate do not

```
priv/examples/
└── invoice/
    ├── DOMAIN.md
    └── acme-phoenix-saas/invoice.json
```
Despite Statement, Receipt, and Certificate being fully shipped, tested families, **none of them have an entry under `priv/examples/`**. Their tests use test-local `defp fixture_data(...)` helper functions instead (verified in `test/rendro/recipes/statement_test.exs:13` and the `describe` blocks in `test/rendro/recipes/certificate_test.exs`). REQUIREMENTS.md's SHOW-01 ("family × domain demonstration matrix... rendered via recipes... citing its `DOMAIN.md`") is explicitly scoped to **Phase 118**, and covers Invoice/Statement/Receipt/Certificate/Payslip/Ticket together — i.e., the shared-fixture-library rollout for *all* families (not just the two new ones) is Phase 118's job, matching the fact that the three already-shipped families still lack `priv/examples/` fixtures today. This strongly suggests Payslip/Ticket's "fictional data only, no PII" fixtures for Phase 116 should be **test-local**, consistent with precedent — see Open Questions.

### Finding 4: `Rendro.Recipes.Pagination` is `@moduledoc false` — extending it needs no public_api.json change

`lib/rendro/recipes/pagination.ex:2` is `@moduledoc false`. Both the new `label_resolver/2` arity and the new D-19 opts-validators are purely internal additions — they do not touch `priv/public_api.json` (only the two new recipe modules do, per Finding 1).

### Finding 5: `Rendro.Region.role` type is a closed 5-atom union — Ticket's regions must pick from it

`lib/rendro/region.ex:16` — `@type role :: :header | :body | :footer | :sidebar | :custom`. Ticket's `:main`/`:stub`/`:terms` regions should use `role: :custom` (the same choice Certificate makes for its `:frame` region at `certificate.ex:121`), since none of `:header`/`:body`/`:footer`/`:sidebar` semantically fit a ticket band/stub.

### Finding 6: No prior art for validating caller-supplied image bytes before registration — D-10 is genuinely new plumbing

Confirmed via `grep -rn "ImageParser" lib/ test/`: the only caller of `Rendro.ImageParser.parse/1` today is `Rendro.AssetRegistry.register_image/3` itself (`lib/rendro/asset_registry.ex:44`), which raises `Rendro.AssetRegistry.InvalidAssetError` (a `defexception` with `[:message, :logical_name, :reason]`, `lib/rendro/asset_registry.ex:7-14`) on bad bytes. Certificate and BrandedInvoice never hit this path with untrusted input because they only ever register a fixed, library-shipped `Rendro.Branded.logo_path()`. Ticket is the first recipe to register a **caller-supplied** image, so D-10's "pre-parse in `validate_data!/1`, convert to instructive `ArgumentError`, never let `InvalidAssetError` leak" is new code with no copy-paste source — plan it as its own task, not a "mirror an existing pattern" task.

### Finding 7: No prior art for `:labels`/`:formatters` opts-shape validators (D-19) — also genuinely new

Confirmed via `grep -n "validate_labels\|validate_formatters\|is_function(f, 1)" lib/rendro/recipes/*.ex`: no matches. D-19's shared validators (`:labels` must be a map with non-empty binary values; `:formatters` must be a keyword list with `is_function(f, 1)` values) do not exist anywhere in `Pagination` or any recipe today. This is net-new shared code, not a retrofit.

## Runtime State Inventory

Not applicable — this is a greenfield feature-addition phase (new recipes, new opts-shape validators), not a rename/refactor/migration phase. No renamed strings, no stored/live-service/OS-registered state to inventory.

## Common Pitfalls

### Pitfall 1: Forgetting the `@public_modules` allowlist edit
**What goes wrong:** `@moduledoc tags: [:adapter]` is added to both new recipes, `mix rendro.api.gen` is run, but `priv/public_api.json` doesn't change because the modules were never in `@public_modules`.
**Why it happens:** The generator's introspection scope is a hardcoded list, not a `lib/` scan — easy to assume tag-based auto-discovery.
**How to avoid:** Add `Rendro.Recipes.Payslip, Rendro.Recipes.Ticket,` to `@public_modules` in `lib/mix/tasks/rendro/api.gen.ex` (alphabetically among the existing `Rendro.Recipes.*` entries) as an explicit task, before running the generator.
**Warning signs:** `mix rendro.api.gen` runs clean but `git diff priv/public_api.json` shows no new entries; `test/docs_contract/public_api_contract_test.exs` fails with "in code but NOT in manifest."

### Pitfall 2: `priv/examples/` schema drift if fixtures are added there
**What goes wrong:** A Payslip or Ticket fixture is dropped into `priv/examples/payslip/.../payslip.json` to satisfy the "fictional data only" success criterion, and `test/docs_contract/examples_schema_contract_test.exs` immediately fails because the fixture lacks Invoice's required `issuer`/`customer`/`invoice`/`items` keys.
**Why it happens:** `priv/schemas/examples.schema.json` currently has no family discriminator — it was authored (Phase 114) only against the Invoice shape.
**How to avoid:** Either (a) keep Payslip/Ticket fixtures test-local (recommended — matches Statement/Receipt/Certificate precedent, zero schema risk, see Open Questions), or (b) if the planner decides `priv/examples/` population belongs in Phase 116, budget an explicit schema-generalization task (e.g. a `family`-keyed `oneOf`) as a FAM-03 subtask, not an afterthought.
**Warning signs:** `examples_schema_contract_test.exs` red; `mix test` failing on an unrelated-looking file.

### Pitfall 3: Letting `Rendro.AssetRegistry.InvalidAssetError` leak from Ticket's PNG path
**What goes wrong:** Ticket calls `Document.register_image/3` directly with caller-supplied bytes without pre-validating via `ImageParser.parse/1` first; a malformed PNG raises `Rendro.AssetRegistry.InvalidAssetError` with a message like `"Failed to parse image for asset :ticket_code: {:error, :unsupported_image_format}"` instead of the recipe's instructive four-part `ArgumentError`.
**Why it happens:** Every existing recipe's image registration uses a trusted, fixed internal path — there's no copy-paste precedent for pre-validating untrusted bytes.
**How to avoid:** In `validate_data!/1`, before any document assembly, call `Rendro.ImageParser.parse/1` directly on the raw bytes (reading via `File.read!/1` first if `{:path, p}`) and raise the four-part `ArgumentError` naming `data.code.image` on `{:error, reason}`.
**Warning signs:** A test expecting `ArgumentError` instead raises `Rendro.AssetRegistry.InvalidAssetError`.

### Pitfall 4: Two fixed-position tables instead of one combined table for Payslip earnings/deductions
**What goes wrong:** Building `:earnings` and `:deductions` as two independently-positioned `anchor: :fixed` regions (mirroring BrandedInvoice's side-by-side pattern) instead of one wide table — this cannot paginate when a payslip has enough line items to overflow a page.
**Why it happens:** BrandedInvoice's 4-region fixed-side-by-side layout is a natural pattern to reach for, but it was designed for content that never needs multi-page continuation.
**How to avoid:** Follow D-12 exactly — one table, `[Earnings, Current, YTD | Deductions, Current, YTD]` columns, fed through `Pagination.chunk_rows_into_pages/2` like Invoice's item table.

### Pitfall 5: `Decimal.equal?/2` vs `==` for the gross−deductions=net assertion
**What goes wrong:** Using `==` to compare `net_pay` to `Decimal.sub(gross, deductions)` — this can spuriously fail even for mathematically-equal values (`Decimal.new("1.0") == Decimal.new("1.00")` is `false`).
**Why it happens:** Idiomatic Elixir reaches for `==` by default; Decimal structs need explicit numeric comparison.
**How to avoid:** Copy Invoice's exact idiom at `invoice.ex:647`/`:673` — `unless Decimal.equal?(...)`.

### Pitfall 6: `label_resolver/2` breaking Statement's existing arity-1 call sites
**What goes wrong:** Refactoring `label_resolver/1` into `label_resolver/2` non-additively (e.g., removing the 1-arg clause) breaks `statement.ex:274` and `statement.ex:294`.
**Why it happens:** Careless "generalize in place" refactor instead of an additive default-argument change.
**How to avoid:** `def label_resolver(opts, default_labels \\ %{})` — Elixir's default-argument sugar keeps the existing 1-arg call sites compiling and behaving identically (empty `default_labels` map means the merge order collapses to today's `opts[:labels] → Rendro.Format.label/1`, byte-identical to current Statement output).

## Code Examples

### Money reconciliation assertion (Payslip net-pay anchor, D-13)
```elixir
# Source: adapted from lib/rendro/recipes/invoice.ex:636-693 (verified pattern)
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

### Additive `label_resolver/2` (D-18, Pagination change)
```elixir
# Source: adapted from lib/rendro/recipes/pagination.ex:64-73 (existing arity-1)
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
Merge order confirmed matches D-18: `opts[:labels] → recipe @default_labels → Rendro.Format.label/1`. Statement's two existing calls (`label_resolver(opts)`) keep working unmodified — `default_labels` defaults to `%{}`, and an empty map lookup always falls through to `Rendro.Format.label/1`, exactly today's behavior.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed-width string padding to fake right-aligned money | Real `cell_align: %{col => :right}` | Phase 115 | Payslip's ledger table can right-align money columns natively; no workaround needed |
| Two-clause `label_resolver/1` (Statement only) | Generalized `label_resolver/2` with recipe-owned defaults (this phase) | Phase 116 (planned) | Payslip/Ticket ship correct English output with zero `:labels` opts; Statement is untouched (additive default arg) |

**Deprecated/outdated:** Nothing in this domain is deprecated by this phase; it is purely additive.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Payslip/Ticket "fictional data only" fixtures should be **test-local** (Statement/Certificate pattern) rather than added to `priv/examples/` in this phase | Additional Findings #3, Open Questions | If wrong, the planner must instead budget an `examples.schema.json` generalization task and a `priv/examples/payslip|ticket/` directory + `DOMAIN.md` as part of FAM-01/02, expanding phase scope |
| A2 | The straight-line dashed-Path op name for the perforation (D-09) is some line-drawing op in `path.ex`'s op union, distinct from `{:rounded_rect}` — exact op name not re-derived in this pass | Architecture Patterns, Pattern 4 | Low risk — `path.ex`'s full op union is small and documented; the planner/executor can confirm the exact op name (`{:move_to}`/`{:line_to}` or similar) by reading `lib/rendro/path.ex` in full during planning/execution, a one-file lookup |
| A3 | `priv/support_matrix.json`'s schema (`additionalProperties: true` for unlisted top-level keys like `payslip`/`ticket`) will accept new rows without a schema change | Additional Findings, Verified Code Anchors | Low risk — verified `support_matrix.schema.json`'s `required` list only covers `forms/signing/embedded_files/links/protection`; recipe rows (`statement`, `certificate`, etc.) are already unlisted `additionalProperties`, so `payslip`/`ticket` rows following the same shape should validate the same way — but this was inferred from schema structure, not from an executed test run against a draft `payslip`/`ticket` row |

**If this table is empty:** N/A — see above.

## Open Questions

1. **Where do Payslip/Ticket's "fictional data only" fixtures live: test-local helpers, or `priv/examples/`?**
   - What we know: CONTEXT.md's canonical_refs section cites the `priv/examples/invoice/...` pattern as the model to follow for new fixtures. But the codebase shows only Invoice has ever used `priv/examples/` — Statement, Receipt, and Certificate (already-shipped families) all use test-local `defp fixture_data(...)` helpers instead. REQUIREMENTS.md's SHOW-01 (Phase 118) explicitly owns the "family × domain demonstration matrix... across the named fictional businesses," covering all six families including Payslip/Ticket together.
   - What's unclear: Whether Phase 116's "fixtures use fictional employees only" / "Ticket fixture = Aurora Live" success criteria mean (a) test-local example data satisfies the criterion (cheapest, zero schema risk, consistent with 3/4 shipped families' precedent), or (b) the user intends genuine `priv/examples/` population now, ahead of Phase 118.
   - Recommendation: Default to test-local fixtures (option a) for Phase 116, consistent with Statement/Receipt/Certificate precedent and zero risk to `examples_schema_contract_test.exs`. If the planner or user wants `priv/examples/` population in Phase 116 instead, budget an explicit `examples.schema.json` generalization subtask (e.g., a `family` discriminator + `oneOf`) as part of FAM-01/FAM-02, and note the schema work as a distinct verification step.

2. **Exact straight-line Path op for the dashed perforation.**
   - What we know: `{:rounded_rect, x, y, w, h, radius}` is confirmed for the code box. `dash: [3, 3]` is a confirmed stroke-map option.
   - What's unclear: This research pass didn't exhaustively enumerate every op in `path.ex`'s `ops` union (e.g., whether it's `{:move_to, x, y}`/`{:line_to, x, y}`, `{:rect,...}` with zero height, or a dedicated `{:line, x1, y1, x2, y2}` op).
   - Recommendation: A one-file `Read` of `lib/rendro/path.ex`'s full `@type op` union during plan authoring (or the first Ticket task) resolves this trivially — flagged here so the planner doesn't assume `{:rounded_rect}` is the only usable op.

3. **Should a `payslip`/`ticket` `DOMAIN.md` be authored in this phase?**
   - What we know: `test/docs_contract/domain_md_contract_test.exs` only requires "at least one `priv/examples/*/DOMAIN.md`" exists (already satisfied by Invoice's) and that any DOMAIN.md that *does* exist carries all four required headings. It does not require one per family.
   - What's unclear: Whether SHOW-01's "each demo citing its `DOMAIN.md`" (Phase 118) expects Payslip/Ticket `DOMAIN.md` files to already exist by then, or whether Phase 118 authors them.
   - Recommendation: Tie this to Open Question 1 — if fixtures stay test-local in Phase 116, defer `DOMAIN.md` authoring to Phase 118 alongside the rest of SHOW-01's fixture-library rollout, for consistency.

## Environment Availability

Not applicable — no external tools/services/runtimes beyond the existing Elixir/Mix toolchain (already available and in continuous use by prior phases 114/115).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in test framework), already configured |
| Config file | `mix.exs` (`elixirc_paths(:test)` includes `test/support`); no separate ExUnit config file |
| Quick run command | `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/ticket_test.exs` |
| Full suite command | `mix test` (includes `test/docs_contract/*` contract lanes) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAM-01 | Payslip renders with net-pay anchor, combined ledger, YTD; jurisdiction differences are label data | unit | `mix test test/rendro/recipes/payslip_test.exs -x` | ❌ Wave 0 |
| FAM-01 | `net_pay == gross - deductions` caller assertion via `Decimal.equal?/2` | unit | `mix test test/rendro/recipes/payslip_test.exs -x --only totals` (or equivalent describe block) | ❌ Wave 0 |
| FAM-01 | Payslip pagination: identity+band page 1, ledger continues with repeating header on overflow | unit | `mix test test/rendro/recipes/payslip_test.exs -x --only pagination` | ❌ Wave 0 |
| FAM-02 | Ticket renders fixed-box band with seat/gate/section anchor, code box, human-readable reference, perforation | unit | `mix test test/rendro/recipes/ticket_test.exs -x` | ❌ Wave 0 |
| FAM-02 | No-PNG fallback: box contains centered reference, no faux barcode | unit | `mix test test/rendro/recipes/ticket_test.exs -x --only no_png` | ❌ Wave 0 |
| FAM-02 | PNG supplied: fit-contain, centered, `:ticket_code` logical name, bad-image raises instructive `ArgumentError` | unit | `mix test test/rendro/recipes/ticket_test.exs -x --only image_code` | ❌ Wave 0 |
| FAM-02 | Content overflow raises typed `:content_overflow` error | unit | `mix test test/rendro/recipes/ticket_test.exs -x --only overflow` | ❌ Wave 0 |
| FAM-03 | `validate_data!/1` raises instructive `ArgumentError` on malformed input for both recipes | unit | `mix test test/rendro/recipes/{payslip,ticket}_test.exs -x --only validate_data` | ❌ Wave 0 |
| FAM-03 | Both recipes read colors via `palette(opts)`, no inlined `{0,0,0}` | unit / static-review | `mix test test/rendro/recipes/{payslip,ticket}_test.exs -x --only palette` + manual grep for `{0, 0, 0}`/`{255,...}` literals in section builders | ❌ Wave 0 |
| FAM-03 | `:labels`/`:formatters` opts-shape validation (D-19) raises instructive errors, never `BadMapError`/`BadArityError` | unit | `mix test test/rendro/recipes/pagination_test.exs -x --only opts_validation` (new test file, mirrors no existing `pagination_test.exs` — confirm during planning whether one exists) | ❌ Wave 0 (confirm test file existence first) |
| FAM-03 | Both recipes registered in `priv/public_api.json` (adapter tier) | contract | `mix rendro.api.gen && mix test test/docs_contract/public_api_contract_test.exs` | ✅ (test exists; new modules absent until implemented) |
| FAM-03 | Both recipes registered in `priv/support_matrix.json` with proof-backed rows | contract | `mix test test/docs_contract/recipes_claims_test.exs` (existing describe blocks for statement/receipt_report/certificate — new `payslip`/`ticket` describe blocks likely a Phase 118 SHOW-04 reconciliation task per REQUIREMENTS traceability, but the row itself must exist and validate against `support_matrix.schema.json` in Phase 116) | ✅ (schema test exists; new describe blocks TBD) |

**Note:** No existing `test/rendro/recipes/pagination_test.exs` was confirmed to exist in this research pass — `grep -rn "label_resolver"` found only `statement.ex` and `pagination.ex` itself as matches, with no dedicated pagination unit test file surfacing in the searches performed. The planner should confirm this file's existence (or absence) directly before assuming where D-19's validator tests belong; if absent, testing D-19 through Payslip/Ticket's own `validate_data!` call sites (an integration-level test of the shared validator, via each recipe) is a reasonable Wave 0 substitute.

### Sampling Rate
- **Per task commit:** `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/ticket_test.exs`
- **Per wave merge:** `mix test` (full suite, includes all docs-contract lanes)
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus `mix rendro.api.gen` diff review (should show only the two new modules added, alphabetically sorted, no unrelated drift)

### Wave 0 Gaps
- [ ] `test/rendro/recipes/payslip_test.exs` — covers FAM-01, FAM-03 (Payslip half)
- [ ] `test/rendro/recipes/ticket_test.exs` — covers FAM-02, FAM-03 (Ticket half)
- [ ] Confirm existence/absence of a dedicated `Pagination` unit test file before deciding where D-19's shared-validator tests live
- [ ] No framework install needed — ExUnit is already configured and used by every other recipe test

## Security Domain

`security_enforcement` is absent from `.planning/config.json` → treated as enabled per policy. This phase's security surface is narrow (no network I/O, no auth, no session state) but is not zero, given Ticket's new caller-supplied-binary attack surface (Finding 6).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Rendro is a library with no auth surface |
| V3 Session Management | No | No session state anywhere in this phase |
| V4 Access Control | No | No access-control surface |
| V5 Input Validation | Yes | Errors-as-product `validate_data!/1` (four-part `ArgumentError`); D-19 opts-shape validators; D-10 pre-parse of caller-supplied image bytes via `Rendro.ImageParser.parse/1` before any registry write |
| V6 Cryptography | No | No crypto operations introduced by this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed/malicious PNG bytes supplied as Ticket's `:code.image` (first caller-supplied binary asset in any recipe) | Tampering / Denial-of-Service | Pre-validate via pure `Rendro.ImageParser.parse/1` in `validate_data!/1` (D-10) before any binary reaches `Rendro.AssetRegistry`; `ImageParser` only inspects signature bytes + declared dimensions, does not decode full pixel data, so a crafted-but-signature-valid file cannot trigger unbounded memory use through this path (confirmed no full-image decode occurs in `image_parser.ex`'s `parse/1` clauses) |
| Oversized image dimensions used as a resource-exhaustion vector | Denial-of-Service | Deterministic fit-contain in `measure.ex` only scales the *rendered box size*, not the source binary; D-10 explicitly notes oversized images are "no error" (scaled down), so this is an accepted, already-mitigated case — no additional work needed |
| PII leakage via committed Payslip fixtures/tests (SSN/NI/bank numbers) | Information Disclosure | D-14 mandates masked ids in fixtures (`··· 4321` pattern) and fictional employer/employee data only — enforced by code review, not an automated gate in this phase (no PII-detection test exists; rely on human verification per D-14's explicit callout) |
| Path traversal via a caller-supplied `{:path, p}` image source for Ticket | Tampering | `Rendro.AssetRegistry.register_image/3` calls `File.read!(path)` directly with no path sandboxing (confirmed at `asset_registry.ex:41`) — this mirrors Certificate/BrandedInvoice's existing (trusted, internal-path-only) behavior; since Ticket's path may now be caller-supplied, this is a **pre-existing pattern extended to a new trust boundary** worth flagging to the planner as a discretionary hardening item, though out of scope per CONTEXT.md's locked decisions (D-08 only discusses `{:path,p}` \| `{:binary,b}` \| `nil` as the accepted shapes, with no explicit path-sandboxing requirement) |

## Sources

### Primary (HIGH confidence — verified via direct codebase inspection this session)
- `lib/rendro/recipes/invoice.ex` — `palette/1`, `page_template/1`, totals/Decimal patterns
- `lib/rendro.ex` — `cell_align` validation, `measure_rows/4`
- `lib/rendro/recipes/pagination.ex` — `formatter/3`, `label_resolver/1`, `chunk_rows_into_pages/2`, `type_name/1`
- `lib/rendro/recipes/certificate.ex`, `lib/rendro/recipes/branded_invoice.ex` — geometry-derived template pattern, image registration pattern
- `lib/rendro/path.ex`, `lib/rendro/component.ex`, `lib/rendro/document.ex`, `lib/rendro/image_parser.ex`, `lib/rendro/asset_registry.ex`, `lib/rendro/page_size.ex`, `lib/rendro/pipeline/measure.ex`, `lib/rendro/pipeline/paginate.ex`, `lib/rendro/region.ex`, `lib/rendro/error.ex` — engine primitives
- `lib/rendro/format.ex` — `Rendro.Format` frozen 5-key label surface
- `lib/mix/tasks/rendro/api.gen.ex` — `@public_modules` registration mechanics
- `priv/public_api.json`, `priv/support_matrix.json`, `priv/schemas/examples.schema.json`, `priv/schemas/support_matrix.schema.json`, `priv/examples/invoice/` — registration/fixture artifacts
- `test/docs_contract/public_api_contract_test.exs`, `test/docs_contract/examples_schema_contract_test.exs`, `test/docs_contract/domain_md_contract_test.exs`, `test/docs_contract/recipes_claims_test.exs` — contract/gate mechanics
- `test/rendro/recipes/statement_test.exs`, `test/rendro/recipes/certificate_test.exs` — test-local fixture precedent
- `mix.exs` — dependency/version confirmation (`decimal >= 2.3.0 and < 4.0.0`, no new deps needed)

### Secondary (MEDIUM confidence)
- `.planning/phases/116-new-families-payslip-ticket/116-CONTEXT.md` — the 19 locked decisions (D-01..D-19), treated as authoritative per task instructions; not independently re-derived, only cross-checked against code anchors
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — requirement traceability and milestone history

### Tertiary (LOW confidence)
None — this phase required no external web research; all findings are direct codebase inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; reuses `decimal` already in `mix.exs`
- Architecture: HIGH — every cited pattern (palette seam, geometry-derived template, image registration, pagination chunking) verified by direct file inspection with exact line numbers
- Pitfalls: HIGH — all seven pitfalls are grounded in either a confirmed schema/test mismatch (Pitfalls 1-2), a confirmed absence of prior art (Pitfalls 3, 6-7 in Additional Findings), or a directly-quoted existing bug class already solved elsewhere in the codebase (Pitfalls 4-6)

**Research date:** 2026-07-18
**Valid until:** Stable — internal codebase patterns don't drift on their own; re-verify only if Phase 115's artifacts are further modified before Phase 116 executes, or if this branch (`gsd/v2.10-...`) is rebased/changed before planning consumes this file.

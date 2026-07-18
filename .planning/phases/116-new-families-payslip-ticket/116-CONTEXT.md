# Phase 116: New families — Payslip & Ticket - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Add two production-grade document families as `Rendro.Recipes.Payslip` and `Rendro.Recipes.Ticket`, both on the proven 3-rung escape hatch (`document/2` → `page_template/1` → `sections/2`), reusing the S1 `palette(opts)` seam, `Rendro.Format` (adapter tier), and — for Payslip — `Rendro.Recipes.Pagination`/`PageSize`. Payslip is flow-based with **net pay** as the visual anchor; Ticket is a fixed-box pass with **seat/gate/section** as the anchor. Both validate input as errors-as-product (`ArgumentError`), keep jurisdiction/locale differences as caller **data** (engine stays locale-free by construction), use fictional data only (no PII — acute for Payslip), and are registered in `priv/public_api.json` (adapter tier) + `priv/support_matrix.json` with proof-backed rows.

**Requirements:** FAM-01 (Payslip), FAM-02 (Ticket), FAM-03 (errors-as-product + palette + registration).

**Key finding that de-risks the phase:** *no new engine surface is required.* Every primitive needed already exists — `cell_align: :right` (Phase 115), dashed `%Rendro.Path{}` strokes, `{:rounded_rect}`, deterministic fit-contain image placement, `anchor: :fixed` regions, typed `:content_overflow` fit-validation, and the `Pagination` chunker.

</domain>

<decisions>
## Implementation Decisions

All four decisions below are **locked** from a 4-agent parallel research fan-out (per-area pros/cons, Elixir/ecosystem idiom, prior art, DX/UX, design pillars). They are mutually coherent: both recipes share one anchor-dominance pattern, one palette seam, one override-map opts convention, and reuse existing primitives.

### Ticket archetype & geometry (FAM-02)
- **D-01:** Ship **one** `Rendro.Recipes.Ticket` family. The concrete **default is an event/admission ticket** (anchor = Section/Row/Seat; demo business = the milestone's **Aurora Live** fixture). Boarding-pass (Gate/Seat/Group, origin→destination) and transit are the *same recipe* reached purely by caller **data + labels** — **no archetype branching in `lib/`**. Rationale: family-not-industry + locale-free-by-data; the milestone's own fixture business is a live-events company, and REQUIREMENTS names the anchor "seat/**gate**/section" (event-first, air-reachable).
- **D-02:** Model the anchor as an ordered **placement grid** — `:placement => [%{label, value}]` (1–4 cells). Labels render small/caps/muted (~8pt); **values render in the largest type on the page** (~22pt, `ink`) → this is the single dominant element (rubric hierarchy = 5). Archetype-agnostic: `[{"Section","GA"},{"Row","H"},{"Seat","24"}]` (event) or `[{"Gate","B12"},{"Seat","14C"},{"Group","2"}]` (air) — same code, different data.
- **D-03:** **Geometry derived from template**, mirroring `Rendro.Recipes.Certificate` (zero hardcoded A4 numerics; all x/y/w/h from `PageSize.resolve/2` + margins). Default page = **A4 portrait**; `page_size: :a4 | :us_letter | {w, h}` supported (bespoke ticket size via the `{w,h}` tuple `PageSize` already accepts). The ticket itself is a **fixed landscape band anchored at the top of the page** (`anchor: :fixed`), full content-width, height = a dimensionless ratio of content width (~2.4:1 strip) so A4/Letter fall out identically. A `:main` region (left ~68%) + `:stub` region (right ~32%) split by a **vertical perforation** at `x ≈ band_w × 0.68`. Optional `:terms` region below the band (`anchor: :flow`, muted fine print). The band-below-a-page layout is the family's signature that distinguishes Ticket from the flowing families.
- **D-04:** **Overflow never truncates.** `validate_data!/1` guards over-length free-text fields (byte guards à la Certificate's 2000-byte `:body` guard) with a friendly four-part `ArgumentError` *before* render; any content that still exceeds a fixed region surfaces as the pipeline's typed `:content_overflow`.

### Ticket code-area, no-PNG fallback & perforation (FAM-02)
- **D-05:** Code area lives in the stub. **Always** draw a bordered code box — `%Rendro.Path{ops: [{:rounded_rect, ...}], stroke: %{color: palette.rule}}`, ≥ ~100×100pt so a real code stays scannable, optional `fill: palette.surface`. The box *presence + placement* is ~80% of the "this is a ticket" signal.
- **D-06:** **The human-readable reference is REQUIRED and always renders** — even when a PNG is supplied (matches IATA BCBP passes and Apple Wallet `altText`; it is the accessibility/resilience affordance when a scanner fails). Data shape: `data.code = %{reference: String.t() (required), label: String.t()|nil (default "Reference"), image: {:path,p}|{:binary,b}|nil}`. Reference set large + upper-cased (`palette.ink`, ~14–16pt) with a small muted caption label above.
- **D-07:** **No PNG → box contains the centered reference** + optional 1-line caption ("Present this reference at entry"). **NEVER draw a faux barcode/QR** (drawn stripes read as scannable but fail at the gate — collides with Rendro's "never claim magic / no scannability overclaim" posture).
- **D-08:** **PNG supplied → fit-contain (aspect-preserving), centered** via `Rendro.Component.image(:ticket_code, fit: {box_w, box_h})` (deterministic contain in `measure.ex`; letterboxes wide PDF417 and square QR alike). Never stretch-to-fill (aspect distortion breaks scanning). Recipe registers the image internally under the fixed logical name `:ticket_code` — caller never touches the asset registry (same pattern as Certificate/BrandedInvoice logo). `image: nil` ⇒ byte-identical to the no-PNG path.
- **D-09:** **Perforation** = dashed `%Rendro.Path{}` (`dash: [3, 3]`, `width: 0.75pt`, `color: palette.rule`) — dashes ≥3pt survive B/W laser print. Placement derived from the stub-region boundary: **vertical** dashed line at the stub's inner x-edge for the default horizontal strip; degrade to a **horizontal** line for a bottom-tear portrait variant; **omit entirely** when there is no stub region. No scissors glyph (none in-engine). Repeat the anchor + reference in the stub (real-world tear-off convention).
- **D-10:** Bad/corrupt/non-PNG image → call the **pure** `Rendro.ImageParser.parse/1` inside `validate_data!` and raise an instructive `ArgumentError` naming `data.code.image` (do NOT let raw `InvalidAssetError` leak from `register_image`). Oversized image → **no error** (fit-contain scales down deterministically). Missing/blank `reference` → instructive `ArgumentError`.

### Payslip anchor & layout (FAM-01)
- **D-11:** **Net-pay anchor = a full-width tinted band directly under the identity header** (own `:summary` region, `anchor: :top`): a `{:rect}` band (`surface`/`paper-200` fill + hairline `rule` top border) with label "NET PAY" (10pt `muted`) and the **value at 26–28pt heaviest weight, `ink`/`accent`** — the single largest element on the page (hierarchy = 5), second in reading order (answer-first for the glance-JTBD), legible in grayscale (size + tint + rule carry it, never color alone). Chosen over a top-right box (competes with the pay-period block, weaker anchor) and a bottom summary line (forces the reader to hunt for the #1 fact).
- **D-12:** **Earnings/deductions = ONE combined ledger table** with two column-groups: `[Earnings, Current, YTD | Deductions, Current, YTD]`, a mid vertical rule (`borders: :columns`), money right-aligned via `cell_align: %{1=>:right, 2=>:right, 4=>:right, 5=>:right}`. Rows zipped to equal length (blank-padded). A bold subtotal row ("Gross Pay | Total Deductions") closes the grid. **YTD is a per-line column inside each group** (ADP/Gusto convention), not a separate table. This choice (vs two separate `anchor: :fixed` tables) is decisive because a single table **paginates natively** through the existing `Pagination.chunk_rows_into_pages/2` chunker; two fixed side-by-side regions cannot paginate.
- **D-13:** **Gross→net reconciliation as a "kept-with-last" trailing block** (height reserved on every page à la Invoice's `@totals_line_height` so it never orphans): the equation `Gross {g} − Deductions {d} = Net {n}` plus a compact YTD summary trio (`Gross YTD · Deductions YTD · Net YTD`). In `validate_data!/1`: derive `gross = Σ earnings.amount`, `deductions = Σ deductions.amount` (Decimal fold), and **assert `Decimal.equal?(net_pay, Decimal.sub(gross, deductions))`** (never `==`). If optional `:totals` supplied, assert each against derived. Reject Float money instructively; validate row shape so no `BadMapError` leaks.
- **D-14:** **4-region template** (like `branded_invoice.ex`): `:header` (employer/employee identity + pay period/date, masked ids), `:summary` (net-pay band), `:body` (`anchor: :flow` — combined table + trailing reconciliation), `:footer` (`anchor: :bottom` — masked payment method + `Rendro.page_number/1`). Single page for realistic payslips on both A4 and Letter; genuine overflow paginates (identity+band on page 1, ledger continues with repeating header) or surfaces typed `:content_overflow` for pathological un-splittable input. **PII masking is mandatory** in fixtures (SSN/NI/bank as `··· 4321`, obviously-fake ids, fictional employer/employee).
- **D-15:** Sketched Payslip data map: `%{employer: %{name (req), address}, employee: %{name (req), id, tax_code}, period: %{from, to} (req), pay_date (req), earnings: [%{description, amount, ytd}] (req, ≥1), deductions: [%{description, amount, ytd}] (req), net_pay: Decimal (req — anchor + assert target), totals: %{gross, deductions, net, gross_ytd, deductions_ytd, net_ytd} (optional caller assertions), payment_method (optional, masked)}`.

### Jurisdiction / label / formatting data contract (FAM-01, FAM-03) — applies to BOTH recipes
- **D-16:** **Reuse the incumbent override-map convention — no jurisdiction profile, no named `:profile` atom, no per-country recipe.** Three orthogonal override seams thread through the open `opts` keyword, each merged over recipe-shipped defaults (the same mental model as the S1 palette seam):
  - `:palette` — `map` role→`{r,g,b}`, merged in `defp palette(opts)` (verbatim from `invoice.ex:371`).
  - `:labels` — `map` key→String, resolved by a generalized `Pagination.label_resolver/2` (see D-18).
  - `:formatters` — `keyword` key→arity-1 fn, resolved by `Pagination.formatter/3` with `&Rendro.Format.money/1` / `&Rendro.Format.date/1` defaults. The **money formatter is the sole owner** of currency symbol + grouping + negative style (no parallel `:currency_symbol` knob).
- **D-17:** **Statutory line content lives in each earnings/deduction line's `:description`** (data, exactly Statement's `lines[].description` pattern) — "National Insurance" vs "FICA", "PAYE Income Tax" vs "Federal Income Tax" are caller-supplied line values, never a library-enumerated type. Chrome labels (section headers, "Gross/Net/YTD/Pay Date") come from `:labels`. This is the "engine never learns a jurisdiction" boundary.
- **D-18:** **Ship recipe-owned `@default_labels`** so the happy path is one line (`Payslip.document(data)` renders a correct jurisdiction-neutral English payslip with no `:labels`/`:formatters`). Generalize `label_resolver` to **arity-2** — `label_resolver(opts, default_labels \\ %{})` with merge order `opts[:labels] → recipe @default_labels → Rendro.Format.label/1`. This keeps `Rendro.Format` **frozen at its 5 statement keys** (no forced growth of the adapter-tier `label/1` spec union) and keeps Statement's existing arity-1 call working (additive). Payslip's `@default_labels`: earnings/deductions/description/amount/ytd_amount/gross_pay/total_deductions/**net_pay** (anchor — never blank)/year_to_date/pay_period/pay_date/employer/employee. Ticket ships its own (`admit`, `seat`/`gate`/`section`/`row`/`reference`, `present_code`). **Never render a blank/humanized fallback** (the Rails-I18n footgun — a blank Net Pay label destroys the anchor).
- **D-19:** **Errors-as-product opts validation (NEW, satisfies FAM-03):** shared validators in `Pagination`, wired into Payslip/Ticket. `:labels` if present must be a `map` with non-empty binary values; `:formatters` if present must be a `keyword` with arity-1-function values (`is_function(f, 1)`). Malformed → instructive four-part `ArgumentError` (What/Where/Why/Next) via `Pagination.type_name/1` — never leak `BadMapError`/`BadArityError`. Scope to Payslip/Ticket now; Invoice/Statement may retrofit additively later.

### Claude's Discretion
- Exact point sizes, band tint depth, gutter widths, caption default strings, and column-share ratios are guidance-level — the planner/executor may refine within the locked hierarchy/pattern as long as the anchor stays dominant (rubric hierarchy = 5), money stays right-aligned, and colors stay sourced from `palette(opts)`.
- Whether a small optional accent element (ticket-type pill, emphasis bar) is included is discretionary, provided it reads via `palette.accent`/`on_accent`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone-A research (vision, domain anatomy, rubric, prior art, pillars)
- `.planning/research/milestone-a/SUMMARY.md` — 5-lens research synthesis; pitfalls P1–P7 and the milestone guardrails.
- `.planning/research/milestone-a/R1-DOMAIN-ANATOMY-RUBRIC.md` — payslip/ticket domain anatomy; reader-quality rubric dimensions + non-designer anchors (hierarchy = 5, core ≥ 4, gates).
- `.planning/research/milestone-a/R2-API-DX-CONSUMER.md` — API/DX consumer research (grounds the `:labels`/`:formatters`/`:palette` opts contract).
- `.planning/research/milestone-a/R4-PRIOR-ART-PITFALLS.md` — prior-art footguns (F1/F4/F6: jurisdiction-in-layout, float money, PII).
- `.planning/research/milestone-a/R5-COHERENCE-PILLARS.md` — design pillars P2 (honesty / no accessibility overclaim), P4 (locale-free), P5 (no PII).

### Phase requirements & roadmap
- `.planning/REQUIREMENTS.md` — FAM-01, FAM-02, FAM-03 (this phase); EDGE-01/02 + SHOW-01 (downstream phases that consume these recipes); the "Making the engine locale-aware" / "live barcode/QR primitive" / "Real personal data" out-of-scope notes.
- `.planning/ROADMAP.md` §"Phase 116: New families — Payslip & Ticket" — goal, success criteria, S1 palette seam + adapter-tier registration.

### Brand (NEWER book — prefer over the older `prompts/Rendro Brand Book.txt`, which is superseded)
- `brand/README.md`, `brand/tokens/tokens.json` — color/type tokens: `ink-900 #101827` (text, AAA on paper), `ink-500 #5B6573` (muted), `blue-600 #2C6BED` (accent), `paper-200 #EFE8DA` (tint surface), `sheet-000` (surface) → map onto palette roles `ink/muted/accent/on_accent/background/surface/rule`.
- `brand/specimens/` — reference specimens for family motif/voice.

### Closest recipe analogs (idiom to clone)
- `lib/rendro/recipes/certificate.ex` — fixed-geometry-from-template, `%Rendro.Path{}` frame, optional brand/logo image registration, byte-guarded `validate_data!` — the Ticket structural analog.
- `lib/rendro/recipes/invoice.ex` — post-Phase-115: `defp palette(opts)` (~line 371), Decimal totals kept-with-last-rows + `Decimal.equal?/2` assert (~640–687), `cell_align: :right`, `page_template/1` `Keyword.take` whitelist (~line 119), four-part `ArgumentError`.
- `lib/rendro/recipes/statement.ex` — running-fold, multi-page chunking, `:labels`/`label_resolver` usage.
- `lib/rendro/recipes/receipt.ex` — `body_section/2` chunk-into-pages money-grid shape.
- `lib/rendro/recipes/branded_invoice.ex` — 4-region template + fixed side-by-side region + logo image `fit:` placement.
- `lib/rendro/recipes/pagination.ex` — `formatter/3`, `label_resolver/1` (to be generalized to arity-2), `chunk_rows_into_pages/2`, `type_name/1`.

### Engine primitives (all pre-existing — no new surface)
- `lib/rendro/path.ex` — `%Rendro.Path{}`: `{:rounded_rect,...}` op (deterministic kappa decomposition), `dash: nil | [number()]` stroke option.
- `lib/rendro/format.ex` — public adapter-tier `Rendro.Format` (`money/1`/`date/1`/`label/1`; frozen at 5 label keys; "output may evolve" caveat).
- `lib/rendro.ex` (`cell_align`, ~line 475), `lib/rendro/table.ex`, `lib/rendro/pipeline/paginate.ex` (`cell_align` + `validate_region_fit!`/`validate_page_fit!` typed `:content_overflow`), `lib/rendro/pipeline/measure.ex` (~110–119 deterministic fit-contain).
- `lib/rendro/component.ex` (`image/2` + `fit:`), `lib/rendro/document.ex` (`register_image/3`), `lib/rendro/image_parser.ex` (pure `parse/1` for pre-validation), `lib/rendro/page_size.ex` (`resolve/2`, `{w,h}` tuple support).

### Registration targets (FAM-03)
- `priv/public_api.json` (adapter tier) + `mix rendro.api.gen` — both recipes registered; docs-contract lane enforces.
- `priv/support_matrix.json` — proof-backed rows for `payslip` and `ticket` surfaces (follow the `statement`/`receipt_report`/`certificate` row shape, ~line 440+).

### Fixtures / example-data (Payslip PII is the acute risk)
- `priv/examples/invoice/DOMAIN.md` + `priv/examples/invoice/acme-phoenix-saas/invoice.json` — the established fixture pattern (Decimal-string money, optional empty brand/logo S4 slot). New Payslip/Ticket fixtures follow this (fictional only; Ticket fixture = Aurora Live).
- `lib/rendro/examples.ex` — `@moduledoc false` loader (JSON.decode!, `Path.safe_relative` guards).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`defp palette(opts)`** (`invoice.ex:371`) — copy verbatim into both recipes; defaults reproduce today's all-`{0,0,0}` ink / white surfaces so output is byte-stable until Milestone B swaps the default. Every color read sources a role from here (S1); **no inlined `{r,g,b}`**.
- **`cell_align: %{col => :right}`** (`lib/rendro.ex:475`, Phase 115) — real right-aligned money columns; obsoletes R1's "fake it with fixed-width" caveat. Used across Payslip's ledger.
- **`%Rendro.Path{}` with `{:rounded_rect}` + `dash: [3,3]`** (`path.ex`) — Ticket code box + perforation with zero new primitives.
- **`Component.image(name, fit: {w,h})`** → deterministic aspect-preserving contain (`measure.ex:110-119`) — Ticket optional PNG placement.
- **`Rendro.ImageParser.parse/1`** — pure; call in `validate_data!` to convert bad images into instructive `ArgumentError` before assembly.
- **Invoice totals-kept-with-last-rows + `@totals_line_height` reservation + `Decimal.equal?/2` assert** (`invoice.ex:246,266,640-687`) — retargeted for Payslip reconciliation (`net = gross − deductions`).
- **`Pagination.chunk_rows_into_pages/2` + `measure_rows/4` + `formatter/3` + `label_resolver/1` + `type_name/1`** (`pagination.ex`) — the flow/money/opts backbone for Payslip.
- **`PageSize.resolve/2`** — A4/Letter/`{w,h}`; derive all geometry from it (both recipes), zero hardcoded numerics.

### Established Patterns
- **3-rung escape hatch** (`document/2` → `page_template/1` → `sections/2`) — both recipes conform exactly (Invoice/Statement/Certificate precedent).
- **`page_template/1` `Keyword.take` whitelist** (`invoice.ex:119`) — filters opts to struct keys so recipe-level keys (`:palette`/`:labels`/`:formatters`/future `:theme`) never hit `struct!/2` and raise `KeyError`; top-level `opts` stays open.
- **Four-part `ArgumentError` (What/Where/Why/Next)** — the errors-as-product idiom across Invoice/Statement/Certificate; both new recipes match it, including opts-shape validation (D-19).
- **Recipe-owns-image-registration under a fixed logical name** (Certificate/BrandedInvoice) — Ticket registers the caller PNG as `:ticket_code`; caller never touches the registry.
- **`@moduledoc tags: [:adapter]`** — both recipes are adapter tier.

### Integration Points
- `priv/public_api.json` (regen via `mix rendro.api.gen`; docs-contract lane byte-compares) + `priv/support_matrix.json` (schema-validated rows) — new surfaces `payslip` + `ticket`.
- `label_resolver` arity-2 generalization is the single shared `Pagination` change; keep it additive (Statement's arity-1 call unchanged).
- Both recipes are consumed downstream by Phase 117 (edge-case stress matrix) and Phase 118 (demonstration set / rubric-gated gallery) — build the data contracts and typed errors to survive that stress grid.

</code_context>

<specifics>
## Specific Ideas

- **User explicitly requested deep parallel-subagent research producing a single coherent, one-shot locked recommendation set** across all four decision areas, viewed through software-architecture, API/DX-from-the-consumer's-perspective, graphic-design/creative-direction, user-psychology (JTBD who/what/where/when/why), and the design pillars (accessibility, performance/determinism, print-safety, coherence, DX). This CONTEXT.md is the synthesis; decisions are locked, not tentative.
- **Prefer the newer `brand/` book over `prompts/Rendro Brand Book.txt`** (per user) — brand tokens above are from `brand/tokens/tokens.json`.
- **Honesty guard is a hard line:** "production-grade" = visual/information-design craft only. **No faux barcodes**, no tagged-PDF/PDF-UA/reading-order or screen-reader claims. The human-readable reference (Ticket) and logical reading order (Payslip) are the honest affordances.
- **Ticket default business = Aurora Live** (live events), consistent with the milestone fixture corpus.

</specifics>

<deferred>
## Deferred Ideas

- **Live barcode/QR generation primitive** — explicitly out of scope (REQUIREMENTS). Ticket uses a boxed code-area + human-readable reference + optional caller-supplied PNG only.
- **Engine locale-awareness (CLDR/gettext/ex_money)** — out of scope by construction; jurisdiction stays caller data.
- **Boarding-pass / transit as distinct recipes or named jurisdiction profiles** — rejected; they are the same Ticket/Payslip recipe reached by data + labels. If real demand ever justifies opinionated presets, that belongs to Milestone C (presets + catalog), not here.
- **Optional Ticket tear-notch half-circles (`{:curve}` at perforation ends)** — gold-plate; defer unless it falls out cheaply.
- **Invoice/Statement retrofitting the arity-2 `label_resolver` and opts-shape validation** — additive, family-coherence nicety; out of scope for Phase 116 (scope the new validation to Payslip/Ticket).
- **`Rendro.Theme` palette threading (Milestone B)** — the palette seam is shaped for it (one-line default swap); no work here beyond honoring the seam.

### Reviewed Todos (not folded)
None — no matching pending todos surfaced for this phase.

</deferred>

---

*Phase: 116-New families — Payslip & Ticket*
*Context gathered: 2026-07-18*

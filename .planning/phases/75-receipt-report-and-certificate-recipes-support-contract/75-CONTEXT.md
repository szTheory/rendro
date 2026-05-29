# Phase 75: Receipt/Report and Certificate Recipes + Support Contract - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers **two new data-driven recipes on the proven three-rung escape hatch** (`document/2` / `page_template/1` / `sections/2`, consistent with `Rendro.Recipes.Invoice`), plus **terminal `priv/support_matrix.json` rows for every new public surface** (RCPT-01..03, CERT-01..03, CONTRACT-01):

- **`Rendro.Recipes.Receipt`** — accepts a data map (header summary, line items, totals) and returns a renderable `%Rendro.Document{}`. **One recipe that scales 1→N pages**: a short single-page receipt and a long multi-page tabular "report" are the same recipe — multi-page is just a receipt that overflows, handled by the table-continuation + "Page X of Y" running-footer machinery proven in Phase 74 Statement. Table column headers repeat across pages; the footer carries "Page X of Y" via the Phase 73 PAGE primitive.
- **`Rendro.Recipes.Certificate`** — accepts a data map (title, recipient, body statement, issue date, signature/seal line) and returns a renderable certificate with **all element coordinates derived from template geometry** (page size + margins), zero hardcoded A4 numerics, rendering correctly at multiple page sizes (multi-size test is an exit criterion). **Landscape default** (classic diploma/award look). Supports branded output (registered fonts/images) consistent with `Rendro.Recipes.BrandedInvoice`.
- **Support contract** — every new public surface (PAGE primitive, Statement, Receipt/Report, Certificate) gets a `priv/support_matrix.json` row in **terminal** state — `supported` with a resolvable evidence pointer, or `explicit_deferral` with a named reason; no surface ships as silent `unverified` (inherits v2.3 discipline).

**In scope:** the Receipt and Certificate recipes (recipe layer), extraction of shared recipe pagination/formatting machinery into a private `Recipes.Base`-style helper, and the support-matrix rows for all five new surfaces. **Out of scope:** the reference Phoenix app and HexDocs guide wiring (Phase 76, CONTRACT-02), any change to engine pagination *behavior* (single forward pass / no convergence loop, PAGE-04, preserved), and a separate `Report` module (folded into `Receipt` — see D-01).

</domain>

<decisions>
## Implementation Decisions

> **Carried forward from Phase 74 (locked, do NOT re-decide):** `Decimal` money type; signed-`amount` line model; **recipe owns pagination** (computes `body_capacity` from geometry, chunks rows, emits `break_before: true` on the first block of every page after page 1); `Rendro.measure_rows/4` for engine-true row heights; `Rendro.Format` deterministic defaults (`money/1`, `date/1`, `label/1`) + `:formatters`/`:labels` escape hatch; errors-as-product `validate_data!/1` raising what/where/why/next; bare atom-keyed map data contract; `Rendro.page_number/1` in a non-zero-height footer region. See `.planning/phases/74-statement-recipe/74-CONTEXT.md` D-01..D-11.

### Receipt/Report recipe topology (RCPT-01/02/03) — **user-decided**
- **D-01:** **One `Rendro.Recipes.Receipt` recipe, NOT two modules.** A single-page receipt and a multi-page tabular report are the same recipe scaling 1→N pages; "report" is a receipt whose line items overflow one page. Smallest public surface, one mental model, one guide. RCPT-03 (multi-page continuation with running footers) is proven by feeding many line items, exercising the inherited table-continuation path — not by a second module.
- **D-02:** **Receipt reuses Statement's table-continuation machinery directly** (see D-04 extraction). Body = a header-summary block + a continued line-items table; the footer carries "Page X of Y" via `Rendro.page_number/1` only on multi-page output. Single-page receipts still ship a deterministic footer region (non-zero reserved height) so the 1-page and N-page paths share geometry — the PAGE token simply reads "Page 1 of 1".
- **D-03:** **Receipt data-map contract** mirrors Statement/Invoice: bare atom-keyed map, required top-level keys for header summary + `lines` (line items) + totals, per-line `%{description, amount, ...}` with `Decimal` amounts validated at the boundary. Totals are caller assertions the recipe derives/validates when absent (same `Decimal.equal?/2` discipline as Statement's `closing_balance`). Exact required-key set is Claude's discretion within this pattern.

### Shared recipe machinery extraction (architecture — Claude-decided, locked)
- **D-04:** **Extract the shared recipe pagination/formatting machinery into a `Recipes.Base`-style helper and refactor Statement onto it.** Statement currently inlines `chunk_into_pages`, `do_chunk_pages`, `measure_rows`-driven body-capacity math, and footer/page-number assembly. With Receipt (and Certificate's geometry helpers) now sharing this, extract the row-chunking + body-capacity + break_before + page-number-footer logic into one private shared module so all recipes use identical, single-sourced pagination. The roadmap's depends-on note explicitly anticipated this (`Phase 74 for Recipes.Base extraction`). **Keep it internal/private** unless the planner finds a concrete caller need to expose it — adding a public `Rendro.Recipes.Base` is new public API and would need escalation. Refactoring Statement must preserve its existing tests byte-for-byte (determinism contract).

### Certificate geometry & layout (CERT-01/02/03) — geometry from user-decided orientation
- **D-05:** **Landscape default orientation** (user-decided). The classic diploma/award/completion-certificate look. Implemented as geometry only (swap width/height) — portrait stays reachable by passing portrait dimensions. The multi-size test (CERT-02 exit criterion) covers A4-landscape vs US-Letter-landscape.
- **D-06:** **All element coordinates derived from template geometry — zero hardcoded numerics.** Every region/element x/y/width/height is computed from `page_template.width`/`height`/margins (e.g., centered title/recipient/body via `width/2`, seal line anchored a margin off the bottom). This is the explicit CERT-02 contract and the deliberate departure from `BrandedInvoice`, which hardcodes A4 coords (`x: 152, width: 451.28, ...`) and must NOT be copied for geometry. A multi-size test renders at two page sizes and asserts correct layout at both.
- **D-07:** **Add a small named page-size helper** (e.g. `:a4` → 595.28×841.89, `:us_letter` → 612×792, with landscape = swapped) so the recipe and its multi-size test read `page_size: :a4` / `page_size: :us_letter` rather than raw point pairs. Pure, deterministic, zero-dependency — no named page-size helper exists in the codebase today (`PageTemplate` only takes raw `width`/`height`). Raw `width:/height:` passthrough remains supported for arbitrary sizes. Exact helper name/placement is Claude's discretion (likely alongside `Rendro.page_template/1` or a `Rendro.PageSize` module).
- **D-08:** **Certificate branding mirrors `BrandedInvoice`'s registration path** (CERT-03): `data.brand` with atom `font_name`/`logo_name`, registered via `Rendro.Document.register_embedded_font/3` + `register_image/3`; missing/invalid brand raises (errors-as-product), not silent fallback. Branding is optional — an unbranded certificate renders with default fonts and no seal image. Reuse `Rendro.Branded` demo asset paths for tests/examples.

### Support-contract row shape (CONTRACT-01 — architecture, Claude-decided, locked)
- **D-09:** **Recipe and PAGE-primitive surfaces are recorded as NON-viewer-sensitive surfaces** — distinct from the `forms`/`signing`/`protection` surfaces that carry a per-viewer matrix. Recipes emit ordinary text + table content the engine already proves structurally (Poppler) and deterministically; there is no novel per-viewer behavior to record. Therefore each new surface's terminal row is `supported` with an `evidence:` pointer to its **determinism + structural-validation proof** (the recipe's docs-contract / determinism test and the existing Poppler structural lane), **not** a fabricated per-viewer matrix. No surface ships as silent `unverified` (v2.3 discipline preserved).
- **D-10:** **Five new surface rows** (roadmap goal enumerates them): `running_header` + `running_footer` (the PAGE primitive — or one `page_numbering` surface if the planner finds that cleaner; keep terminology aligned with Phase 73's shipped names), `statement`, `receipt_report` (one row covering both receipt and report modes, consistent with D-01's single module), and `certificate`. The exact top-level key names/grouping under `priv/support_matrix.json` are Claude's discretion **provided** the JSON-Schema validator and the docs-contract lane accept them and each row is terminal. Backfill the Statement row (shipped Phase 74 without one) here.

### Claude's Discretion
- Exact module layout of `Rendro.Recipes.Receipt` and `Rendro.Recipes.Certificate` (private `*_section/1` builders mirroring `invoice.ex`/`statement.ex`).
- The name/placement/internal API of the extracted shared recipe helper (D-04) and the page-size helper (D-07).
- Exact Receipt required-key set, totals shape, and whether a receipt "header summary" is a fixed key set or a free block list.
- Precise `validate_data!/1` message wording for both recipes.
- The exact `priv/support_matrix.json` key names/grouping and evidence-pointer file layout for the new surfaces (D-09/D-10), subject to schema-validator + docs-contract acceptance.
- Whether the named page-size helper lives in a new `Rendro.PageSize` module or as options on `Rendro.page_template/1`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §RCPT-01..03, §CERT-01..03, §CONTRACT-01 — the locked WHAT for this phase.
- `.planning/ROADMAP.md` §"Phase 75: Receipt/Report and Certificate Recipes + Support Contract" — goal + 5 success criteria.

### Phase 74 Statement (the direct analog — Receipt inherits its machinery)
- `.planning/phases/74-statement-recipe/74-CONTEXT.md` — D-01..D-11: recipe-owns-pagination, `Decimal` money, signed-amount model, `Rendro.measure_rows/4`, `Rendro.Format`, errors-as-product, page-grouping invariant. **Read before designing Receipt and the D-04 extraction.**
- `lib/rendro/recipes/statement.ex` — the working multi-page table-continuation recipe: `chunk_into_pages/5`, `do_chunk_pages/5`, `measure_rows`-driven body-capacity math (~291), `break_before: idx > 0` (~357), non-zero footer with `Rendro.page_number/1` (~444), `validate_data!/1` + `maybe_validate_closing_balance!` (Decimal.equal? assertion). **Source of the D-04 shared-helper extraction; Receipt and Statement must end up sharing this code.**

### Phase 73 PAGE primitive (the dependency both recipes consume)
- `.planning/phases/73-page-numbering-running-region-primitive/73-CONTEXT.md` — running-region `fn {page,total}` contract, fixed-reserved-height determinism, single-pass/no-convergence PAGE-04. **Read before designing the Receipt footer.** Keep support-matrix surface names (D-10) aligned with what Phase 73 actually shipped.

### Engine & recipe code (verified during scout)
- `lib/rendro/recipes/invoice.ex` — three-rung reference skeleton (`document/2` / `page_template/1` / `sections/2`); the pattern both recipes stay consistent with (RCPT-02, certificate three-rung per success criterion 4).
- `lib/rendro/recipes/branded_invoice.ex` — branding registration path (`register_embedded_font/3`, `register_image/3`, `data.brand` atom keys, `validate_data!/1` raise-with-guidance) to mirror for Certificate (D-08, CERT-03). **NOTE:** its hardcoded A4 region coords (`x: 152`, `width: 451.28`, ...) are exactly what CERT-02 forbids — copy the branding wiring, NOT the geometry.
- `lib/rendro/page_template.ex` — `%PageTemplate{}` `width`/`height` (default A4 595.28×841.89) + four margins; the geometry Certificate derives all coords from (D-06) and the page-size helper sets (D-07).
- `lib/rendro/format.ex` — `Rendro.Format.money/1` / `date/1` / `label/1`; the pure deterministic formatters both recipes default to (carried from Phase 74).
- `lib/rendro.ex:321` — public `Rendro.measure_rows/4` (engine-true row heights for recipe chunking). `lib/rendro.ex:210` — public `Rendro.page_number/1` (footer PAGE token). `lib/rendro.ex:195/200/205/289` — `page_template/1`, `region/1`, `section/1`, `table/2`.
- `lib/rendro/pipeline/paginate.ex` — `split_table`/`stacked_header` (~106-125: table header repeats on continuation, backs RCPT-01 "headers repeat across pages"), `body_capacity` (~565), `maybe_break_before`. Engine behavior stays unchanged.
- `lib/rendro/branded.ex` — `font_path/0` / `logo_path/0` demo assets for Certificate branding tests/examples.

### Support matrix & validator (CONTRACT-01)
- `priv/support_matrix.json` — current top-level surfaces (`forms`, `signing`, `protection`, ...); **no recipe/PAGE-primitive rows exist yet**. Add five terminal rows per D-09/D-10; backfill the Statement row.
- The in-tree JSON-Schema validator + the 8th docs-contract lane (v2.3) — new rows must pass both. (Planner: locate the validator schema and the docs-contract test lane; they constrain the row shape in D-10.)
- `guides/viewer_evidence.md` — v2.3 operator recipe; the evidence-recording discipline the new (non-viewer) surfaces adapt from (D-09).

### Vision / DNA
- `prompts/rendro-oss-dna.md` — pure dependency-light core, errors-as-product, batteries-included ergonomics pushed to the recipe layer.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Recipes.Statement` (`statement.ex`) — the multi-page table-continuation recipe; Receipt inherits its chunking/measure/footer machinery (extracted per D-04).
- `Rendro.Recipes.Invoice` / `BrandedInvoice` — three-rung skeleton + branding registration path (copy branding wiring for Certificate, NOT BrandedInvoice's hardcoded geometry).
- `Rendro.Format.money/1` / `date/1` / `label/1` (`format.ex`) — pure deterministic formatters, default for both recipes; caller overrides via `:formatters`/`:labels`.
- `Rendro.measure_rows/4` (`rendro.ex:321`) + `Rendro.page_number/1` (`rendro.ex:210`) — public engine seams the recipes consume; do not re-implement.
- `Rendro.Branded.font_path/0` / `logo_path/0` (`branded.ex`) — demo brand assets for Certificate tests.

### Established Patterns
- Three-rung escape hatch (`document/2` → `page_template/1` → `sections/2`) — both recipes follow it (RCPT-02, certificate success criterion 4).
- Recipe owns pagination; engine stays single-pass (PAGE-04). Recipe pre-chunks rows ≤ `body_capacity` and emits `break_before` — engine never re-breaks or iterates.
- `deterministic: true` byte-identical contract — `Decimal` folds + `Rendro.Format` must be locale-free and reproducible. Refactoring Statement onto the shared helper (D-04) must keep its existing determinism tests passing unchanged.
- Geometry-derived coordinates (CERT-02) — a NEW discipline this phase introduces for Certificate, departing from the hardcoded-A4 approach in BrandedInvoice.

### Integration Points
- Receipt/Statement shared chunking helper (D-04) feeds the engine's existing `paginate_blocks` pass; chunks stay ≤ engine capacity so no double-pagination.
- Certificate's page-size helper (D-07) sets `%PageTemplate{}` `width`/`height`; all regions derive from those values.
- New support-matrix rows (D-09/D-10) must satisfy the existing JSON-Schema validator and the 8th docs-contract lane (v2.3) — both gate the row shape.

</code_context>

<specifics>
## Specific Ideas

- User (library author, technical, opinionated/decisive — advisor `minimal_decisive` tier) wants research-grounded, one-shot, coherent recommendations and only escalates genuinely high-impact decisions. Two were surfaced and decided directly: **one `Receipt` recipe** (smallest public surface; report = multi-page receipt) and **landscape Certificate default** (classic certificate look). Everything else (shared-helper extraction, support-matrix row shape, certificate geometry mechanics, page-size helper) was locked decisively per profile.
- Deliberate continuation of the Phase 73/74 philosophy: batteries-included ergonomics (pagination, formatting, geometry) live in the recipe layer; the engine stays pure/deterministic/single-pass. The one new engine-adjacent addition (a pure page-size helper, D-07) is read-only and zero-dependency.
- CERT-02's "no hardcoded A4" is the single most error-prone requirement — BrandedInvoice is in-repo precedent for the WRONG approach; flagged explicitly so the planner copies branding wiring without geometry.

</specifics>

<deferred>
## Deferred Ideas

- **Public `Rendro.Recipes.Base` module** — the shared helper (D-04) ships private this phase. Promote to public API only if a concrete external caller need emerges (would require escalation as new public API on a shipped lib).
- **Separate `Rendro.Recipes.Report` module** — folded into `Receipt` (D-01). Revisit only if receipt and report data contracts diverge enough that one module becomes awkward.
- **Conventional Debit/Credit display columns** and **currency/locale-aware formatting in core** — carried-over deferrals from Phase 74; the `:formatters` closure remains the supported i18n path.
- **Aligning Invoice/BrandedInvoice onto `Rendro.Format` and onto geometry-derived coords** — a future cleanup, not this phase.
- **Reference Phoenix app + HexDocs guides + CONTRACT-02 docs-contract closure** — Phase 76.

</deferred>

---

*Phase: 75-receipt-report-and-certificate-recipes-support-contract*
*Context gathered: 2026-05-29*
</content>
</invoke>

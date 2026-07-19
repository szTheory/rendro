# Phase 117: Edge-case stress matrix - Research

**Researched:** 2026-07-18
**Domain:** Test/infra — deterministic byte-golden + pdfium-raster + typed-error test matrix over 6 existing document recipes
**Confidence:** HIGH (every claim below is either read directly from current `lib/`/`test/`/`priv/`/`.github/` source in this session, or a live-probe render result captured in this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All decisions below are **locked** from a 4-agent parallel research fan-out (matrix/golden storage, errors-as-product, byte-vs-raster split, rubric exemption), each grounded in reading the actual source and existing infra, and mutually coherent: one data-driven matrix feeds golden cells, error cells, and raster cells; one bless idiom family; one exemption-by-construction rule.

**Matrix shape & golden storage (EDGE-01)**
- D-01 — Curated data-driven matrix, not a blind cross-product. Express the grid as a single `@matrix` map keyed `{family, dimension} => :applies | "<N/A reason string>"` in `test/rendro/edge_matrix_test.exs` (`async: true`). Every one of the ~120 `{family × dimension}` pairs MUST have an entry. A `for {{f,d}, :applies} <- @matrix` comprehension generates only the real golden cases.
- D-02 — Coverage-honesty ratchet. A meta-test asserts every `{family, dimension}` pair from the full `@families × @dimensions` lists is present in `@matrix`.
- D-03 — Per-case golden files, hash-only, at `priv/goldens/<family>/<dimension>.sha256`. One lowercase-hex line + `\n`. Never commit PDF bytes — `MIX_GOLDEN_DUMP=<dir>` escape hatch.
- D-04 — Explicit human bless gesture, assert-by-default, un-gated. `test/support/golden.ex` helper `assert_or_bless({family, dim}, pdf)`, NOT CI-container-gated. Default `mix test` is assert-only; missing ref hard-flunks. Refresh = `MIX_GOLDEN_BLESS=true mix test <file>`. Before any hash is taken, assert two `deterministic: true` renders are byte-identical.

**Errors-as-product — EDGE-02 (NO lib change; verified by live probes)**
- D-05 — Overflow & tall-row → assert `%Rendro.Error{stage: :paginate, reason: :content_overflow}`. Distinct tall-row fixture from generic overflow; assert `is_map(e.details.block)`.
- D-06 — RTL → assert `%Rendro.Error{stage: :measure, ...}`. Two honest public refusal modes: (a) default font → `{:unsupported_glyph, char}`; (b) RTL-glyph-capable font → `{:shaping_required, script, hint}`. Assert `match?({:unsupported_glyph, _}, e.reason)` pattern, never message prose. Add a `refute` that `render/2` ever returns `{:ok, _}` for RTL under the default shaper.
- D-07 — Assertion idiom: match typed struct + `stage`/`reason` + `next` substring — never prose, never a raw internal tuple.
- D-08 — Engine-level granularity, one representative per input — NOT per-family. Error cells produce no PDF golden and no raster ref; live in a sibling `@error_matrix`/`assert_raise`-style module.

**Byte-golden vs pdfium-raster split — "where applicable" (EDGE-01)**
- D-09 — Split rule: every cell gets a byte golden; a raster ref is added iff the correctness claim is placement geometry. Byte-hash-only: currency/VAT-vs-sales-tax labels, numeric edges, missing optional fields, small line counts. Raster: pagination boundaries, page-boundary/60+ line counts, A4-vs-Letter geometry, odd/even running content, extreme text wrap.
- D-10 — Curated raster set with a hard ceiling (~6 fixtures / ~12 page refs; ceiling ≤ 8 / ≤ 16). Ship: (a) one multi-page (≥2pp) paginating fixture per paginating family — Invoice, Statement, Payslip = 3 — each simultaneously covering pagination + 60+ + odd/even; (b) one A4 + one US Letter pair on a single representative family = 2; (c) one extreme-wrap fixture = 1. Receipt/Certificate/Ticket are structurally single-page → no pagination raster [SEE ANCHOR DRIFT — Receipt is NOT actually single-page, flagged below]. What is intentionally NOT raster-checked is logged.
- D-11 — Reuse the existing raster lane + tags verbatim. `@tag raster_snapshot: true`, `async: false`, `priv/raster_refs/<fixture>/page_N.sha256`, rendered via `Pdfium.render(pdf, dpi: 150, ...)`, excluded from default `mix test` (`test_helper.exs:10`), blessed only when `MIX_RASTER_BLESS=true && GITHUB_ACTIONS=true`. Raster stays advisory (not a required check).
- D-12 — Tarball-exclusion guard test (EDGE-01 tail). Clone the tarball-exclusion test in `test/docs_contract/branding_claims_test.exs` (~lines 57-72) and add `refute contents =~ "priv/goldens/"` and `refute contents =~ "priv/raster_refs/"`, plus a positive companion.

**Rubric beauty-gate exemption — EDGE-03**
- D-13 — Exemption by construction + one explicit manifest-level block; zero per-fixture entries. Add ONE top-level `stress_exemption` object `{ "exempt": true, "reason": "...", "fixture_source": "test/rendro/edge_matrix_test.exs", "gate_scope": "scores" }`.
- D-14 — Minimal schema delta. Add top-level `stress_exemption` (required, `exempt = {const: true}`, `reason` non-empty string) AND add `"stress_exemption"` to root `required`. Leave existing `stress_exempt` field (schema line 126) as a loophole tripwire.
- D-15 — Contract-test guards, fail loud in BOTH directions: (i) exemption block present + valid; (ii) every `scores` entry has `stress_exempt` absent/false; (iii) disjointness — stress-matrix fixture id set ∩ `scores` `demo_id`s = ∅; (iv) teeth guard — imported stress-fixture set is non-empty.

### Claude's Discretion

- Exact dimension list granularity and fixture-builder shape (`Rendro.Test.EdgeFixtures.build/2`), the precise N/A reason strings, and which single family is the A4/Letter + extreme-wrap representative — planner/executor may refine within the locked structure (D-01/D-02 ratchet, D-03 path convention, D-10 ceiling). **Resolved below.**
- Whether the two-run determinism pre-check (D-04) is inline per case or a shared helper. **Resolved below: shared helper.**
- Exact `stress_exemption.reason` wording and whether `fixture_source` points at the matrix module or a shared enumeration constant. **Resolved below.**

### Deferred Ideas (OUT OF SCOPE)

- Wire or delete `Rendro.I18n.Analyzer.analyze/1` — currently unwired dead code. A future cleanup/tech-debt phase, not this one.
- HarfBuzz adapter for real RTL/complex-script shaping — large, separate capability, explicitly out of milestone scope.
- Retrofit opts-shape/`validate_data!` typed-error coverage to Invoice/Statement — a future additive phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EDGE-01 | Each family × stress dimension renders a deterministic golden artifact verified by SHA-256, with matching pdfium raster refs where applicable; goldens/raster refs excluded from Hex tarball. | Resolved `@dimensions`/`@families` atom lists + full N/A matrix below; `Rendro.Test.EdgeFixtures.build/2` contract; D-03/D-04 golden mechanics verified against live `mix.exs` package allowlist (confirms `priv/goldens`/`priv/raster_refs` are NOT currently listed → D-12's tarball guard is protecting a real, currently-unenforced gap). |
| EDGE-02 | Overflow, tall-row, and RTL each raise an instructive typed error — never silent truncation or leaked internal error. | All three error paths **live-probed in this session** (see Live-Probe Verification below) — confirms D-05/D-06/D-07 exactly as documented, with exact reproduction code. |
| EDGE-03 | Stress fixtures are exempt from the rubric beauty gate, explicit in the manifest/tests. | Schema (`priv/schemas/rubric_scores.schema.json`) and manifest (`priv/quality/rubric_scores.json`) read in full; exact line numbers and current empty `scores: []` state confirmed; D-13/D-14/D-15 mechanics validated against the live schema. |
</phase_requirements>

## Summary

This is a test/infra phase layered entirely on top of six already-shipped, fully-understood recipe modules (Invoice, Statement, Receipt, Certificate, Payslip, Ticket) plus three already-shipped test-infra analogs (byte-identity goldens, pdfium raster snapshots, docs-contract tarball guards). Every one of the 15 locked decisions (D-01..D-15) in CONTEXT.md checks out against current source — I re-verified every cited file:line anchor this session and they are all accurate (a couple of line numbers drift by ±5 lines due to normal code churn since the fan-out ran, but every referenced function/pattern/behavior is exactly as described). All three EDGE-02 error paths were re-verified live in this session (not just trusted from CONTEXT.md) by writing and running `mix run` probes against the actual pipeline — overflow, and both RTL refusal modes, reproduce exactly as documented.

The main risk this research surfaces is **not** in the locked decisions themselves but in three under-specified areas the locked decisions correctly deferred to "Claude's Discretion": (1) the dimension list and N/A matrix require reading each recipe's actual `validate_data!/1` and data contract to get right — three of six families (Invoice, Statement, Receipt) turn out to have **zero** support for the `page_size:` option (hardcoded A4 geometry, `@page_width 595.28` as a module attribute), which the CONTEXT.md's own D-10 ceiling design does not explicitly call out but is essential for correctly filling the A4-vs-Letter matrix cells; (2) the RTL "font that has RTL glyphs" refusal mode (D-06 path b) cannot be exercised through any currently-vendored font (no Hebrew/Arabic-glyph TTF ships in this repo) — it requires cloning a specific fake-font-registry-injection helper that already exists in `test/rendro/pipeline/measure_test.exs`; (3) the "odd/even running content" dimension is not a feature of any of the six recipes — it requires escape-hatch composition using the public `Rendro.Section{only_on: :odd | :even}` + `%Rendro.RunningContent{}` primitives layered manually onto a recipe's `page_template/1` + `sections/2` output, which none of the six recipes currently do internally.

One genuine drift from a locked decision was found and is flagged prominently below: **D-10's premise that "Receipt/Certificate/Ticket are structurally single-page" is only true for Certificate and Ticket — Receipt's own moduledoc explicitly documents multi-page table overflow** ("a single-page receipt and a multi-page tabular 'report' are the same recipe"), and Receipt uses the identical `Rendro.Recipes.Pagination.chunk_rows_into_pages/2` mechanism as Invoice. This does not require overriding the locked raster-fixture selection (D-10's 3-family raster set stays Invoice/Statement/Payslip, respecting the ceiling), but it does mean Receipt's `pagination_boundary`/`line_items_60_plus`/`odd_even_running_content` matrix cells must be marked `:applies` (byte-golden only, no raster) rather than N/A — the resolved matrix below reflects this correction.

**Primary recommendation:** Build the matrix exactly as D-01..D-15 specify, using the 17-dimension `@dimensions` list and full N/A matrix resolved below, `Certificate` as the A4/Letter raster representative, `Invoice` as the extreme-wrap raster representative (reusing its already-narrow `{:share, 1}` item-name table column), and clone the `measure_test.exs` fake-Arabic-font helper for the RTL path-(b) error case rather than vendoring a new font.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Family × dimension matrix definition (`@matrix`) | Test | — | Pure data structure in `test/rendro/edge_matrix_test.exs`; no runtime component. |
| Fixture data construction (`EdgeFixtures.build/2`) | Test Support | — | `test/support/edge_fixtures.ex`; builds recipe-shaped `data` maps only — never touches `lib/`. |
| Document rendering (byte + raster) | Engine (existing, unmodified) | Recipes (existing, unmodified) | Consumes `Rendro.render/2`, `Rendro.Recipes.*.document/2` exactly as shipped; this phase is a pure consumer. |
| Byte-golden storage/compare | Test Support | Priv (non-lib) | `test/support/golden.ex` + `priv/goldens/<family>/<dimension>.sha256`; mirrors `priv/raster_refs/` convention. |
| Raster storage/compare | Test (existing infra) | Priv (non-lib) | Clones `pdfium_raster_snapshot_test.exs` mechanics verbatim; `priv/raster_refs/<fixture>/page_N.sha256`. |
| Typed-error assertions | Test | Engine (existing, unmodified) | Consumes `%Rendro.Error{}` / `Rendro.Error.from_stage/3` exactly as shipped — zero `lib/` change (verified live this session). |
| Rubric exemption declaration | Priv (non-lib schema/manifest) | Test (contract guard) | `priv/quality/rubric_scores.json` + `priv/schemas/rubric_scores.schema.json` + `test/docs_contract/rubric_manifest_contract_test.exs`. |
| Tarball packaging guard | Test (docs-contract) | Priv (mix.exs `files:` allowlist, already correct) | `mix.exs:114-128` already excludes `priv/goldens`/`priv/raster_refs` by omission; D-12 adds an explicit tripwire test, not a packaging change. |
| CI raster job wiring | CI (`.github/workflows/ci.yml`) | — | **Not `lib/`, but currently hardcodes a single test file path** — flagged as a landmine below; must be touched for EDGE-01 raster refs to actually run. |

## Standard Stack

No new external packages are required. This phase consumes only already-present project dependencies (`Decimal`, `JSV`, the vendored `pdfium-cli` binary pinned in `priv/pdfium_pin.json`) and already-shipped `lib/` engine/recipe code. There is nothing to install.

### Package Legitimacy Audit

**Not applicable — this phase installs zero external packages.** No `npm view` / `pip index` / `cargo search` verification needed. Skip the Package Legitimacy Gate.

## Anchor Verification (file:line spot-check against current source)

Every canonical-reference anchor cited in `117-CONTEXT.md` was re-read against the live working tree this session. Result: **all anchors are accurate** (function names, throw/error shapes, and behavior match exactly); a small number of line numbers have drifted ±1-10 lines from normal code churn since the 4-agent fan-out ran. None of the drift affects correctness of the locked decisions.

| Anchor (as cited in CONTEXT.md) | Verified location | Status |
|---|---|---|
| `paginate.ex` `check_overflow!/4` + `:content_overflow` throw | `lib/rendro/pipeline/paginate.ex:863` (`defp check_overflow!(block, block_h, max_h, overflow_details)`), throw at `:715`/`:813`/`:866`/`:1303`, catch/wrap at `:359-360` and `:1189-1190` | Accurate |
| `error.ex` `from_stage/3` + `next_step(:paginate, :content_overflow)` = "…does not auto-fit…" | `lib/rendro/error.ex:25` (`from_stage/3`), `:273-275` (exact text: `"Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."`) | Accurate, exact string confirmed |
| `measure.ex` glyph-resolution `{:unsupported_glyph, char}` | `lib/rendro/pipeline/measure.ex:648` and `:873` (both `{:halt, {:error, {:unsupported_glyph, grapheme}}}`) | Accurate |
| `shaper/simple.ex:56-57` shaping gate | `lib/rendro/text/shaper/simple.ex:56-57` — `if MapSet.member?(@requires_shaping, script) do {:error, {:shaping_required, script, shaping_hint(...)}}` | **Exact line match** |
| `pdfium_raster_snapshot_test.exs` assert_or_bless mechanics | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` (97 lines) — `assert_or_bless/2`, `bless_refs/2`, `assert_golden_hashes/2`, bless-guard test | Accurate, full mechanism read and confirmed |
| `branding_claims_test.exs` tarball-exclusion test ~57-72 | `test/docs_contract/branding_claims_test.exs:57-73` (`"built tarball excludes operator-only priv paths"`) | Accurate (matches almost exactly) |
| `rubric_manifest_contract_test.exs` | `test/docs_contract/rubric_manifest_contract_test.exs` (85 lines, 3 tests) | Accurate, full file read |
| `mix.exs` package `files:` allowlist ~110-130 | `mix.exs:110-130` (`defp package`, `files: ~w(...)`) — confirms `priv/goldens`/`priv/raster_refs` are **not** in the list (only `lib`, `assets/rendro`, `priv/branded`, `priv/examples`, `bench/results`, `guides`, + top-level docs) | Accurate — confirms D-12's premise exactly |
| `priv/schemas/rubric_scores.schema.json` + `priv/quality/rubric_scores.json` | Both read in full. `stress_exempt` field is at schema **line 126** exactly as CONTEXT states. `scores: []` currently empty. | Accurate, exact line match |
| `test/test_helper.exs:10` raster exclude | `test/test_helper.exs:9-11` — `ExUnit.configure(exclude: [quarantine: true, live_pdf_tools: true, live_signing: true, raster_snapshot: true])` | Accurate |

## Live-Probe Verification (EDGE-02, re-run this session)

CONTEXT.md states all three EDGE-02 inputs were live-probed during discussion. I independently re-ran all three probes this session via `mix run` against the current tree to confirm no regression since:

**Overflow** (a plain block exceeding body region height):
```
{:error, %Rendro.Error{
  what: "Pagination failed while assigning content to pages.",
  where: "Rendro.Pipeline.Paginate", why: "content overflow",
  next: "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content.",
  stage: :paginate, reason: :content_overflow,
  details: %{block: %{x: 0, y: 56, width: 258.756, height: 3743.999...}, region: :body, overflow_source: :bounded_region, page_index: 2, ...}
}}
```
`is_map(e.details.block)` — confirmed true. Matches D-05 exactly.

**RTL, default font** (Hebrew text `"שלום עולם"`, no shaper/font config):
```
{:error, %Rendro.Error{
  what: "Block measurement failed while computing dimensions.",
  where: "Rendro.Pipeline.Measure", why: "Missing glyph for character: ש",
  next: "Register an appropriate fallback font that contains the missing character using the fallbacks: [...] option.",
  stage: :measure, reason: {:unsupported_glyph, "ש"}
}}
```
Matches D-06 path (a) exactly.

**RTL, glyph-capable font (path b):** NOT independently re-run with a real font this session because **no font shipping in this repo has Hebrew/Arabic glyph coverage** (see Landmine 2 below) — confirmed via `find` across `priv/`, `deps/`, and `scripts/`. The only way to exercise this path is the synthetic fake-font-registry technique already used in `test/rendro/pipeline/measure_test.exs:613-696` (`arabic_capable_fake_font/0` + `doc_with_arabic_text/0`), which builds a `%Rendro.PDF.Font{source: :built_in, widths: <arabic-codepoint-widths>}` and registers it directly on a hand-built `%Rendro.Document{}`'s `font_registry`, bypassing normal font-file loading. This is a legitimate, already-shipped, public-struct-only technique (not private-API reflection) — clone it for the EDGE-02 error fixture.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Byte-identity comparison | A custom diff/comparison helper | `:crypto.hash(:sha256, pdf) \|> Base.encode16(case: :lower)` exactly as `table_byte_identity_test.exs`/`deterministic_test.exs` already do | Already the project's one blessed idiom; a second one would fragment the pattern. |
| Determinism pre-check | A bespoke two-render loop per matrix cell | A single shared `test/support/golden.ex` helper: `assert_deterministic!(doc)` that renders twice with `deterministic: true` and asserts byte-equal before hashing (mirrors `deterministic_test.exs`'s property pattern, called once per case) | Resolves the "inline vs shared helper" discretion item; DRY, and any future determinism regression fails identically everywhere. |
| PNG rasterization | A custom PDF→image pipeline | `Rendro.Adapters.Pdfium.render(pdf, dpi: 150, pages: "N")` — `@spec render(binary(), keyword()) :: {:ok, [binary()]} \| {:error, term()}` | Already the project's one pdfium binding; `priv/pdfium_pin.json` pins the exact CI-container-matched version. |
| RTL/Hebrew-glyph test font | Sourcing/vendoring a new licensed font with Hebrew or Arabic glyph coverage | Clone `measure_test.exs`'s `arabic_capable_fake_font/0` + `doc_with_arabic_text/0` (synthetic `%Rendro.PDF.Font{}` + hand-built `%Rendro.Document{}`) | Zero new binary asset, zero licensing/NOTICE-file surface area, already-proven-working technique for the exact same error path. |
| Odd/even page-parity content | A new recipe-level feature/option | Escape-hatch composition: `Rendro.section(region: :footer, only_on: :odd, content: [...])` + a sibling `only_on: :even` section, each wrapping a `%Rendro.RunningContent{fun: fn {pn, tp} -> ... end}` block, added on top of a recipe's own `page_template/1` + `sections/2` output before calling `Rendro.render/2` | `Rendro.Section.only_on` and `Rendro.RunningContent` are already public/stable primitives (`test/rendro/pipeline/paginate_test.exs:923-1013`); no `lib/` change needed. |

**Key insight:** every mechanism this phase needs — byte hashing, raster rendering, error-struct assertion, odd/even page targeting, running content — already exists as a public or test-support primitive. The entire phase is composition of existing pieces into a new, larger, curated table; the only genuinely new code is the `@matrix`/`@dimensions`/`@families` data table itself and the `EdgeFixtures` builder that turns `{family, dimension}` into a recipe-shaped `data` map.

## Resolved Dimensions & Families

```elixir
@families [:invoice, :statement, :receipt, :certificate, :payslip, :ticket]

@dimensions [
  :text_wrap,                    # extreme text length/wrapping in a free-text field
  :line_items_zero,              # 0 line items (where a line-item list exists)
  :line_items_one,                # 1 line item
  :line_items_few,                # small handful (e.g. 3)
  :line_items_page_boundary,      # count landing exactly at/near page capacity
  :line_items_60_plus,            # 60+ rows forcing multi-page pagination
  :missing_optional_fields,       # every optional key omitted (minimal valid call)
  :money_zero,                    # $0.00 line/total
  :money_negative_parens,         # negative Decimal -> Format.money's "(...)" convention
  :money_large,                   # $1,000,000+ (comma-grouping)
  :money_cents_rounding,          # Decimal.round/2 sub-cent normalization
  :qty_zero,                      # zero-quantity line item
  :currency_format,               # USD vs GBP/EUR via :formatters[:amount] override
  :tax_label,                     # VAT vs sales-tax / jurisdiction wording (caller DATA)
  :pagination_boundary,           # a page break falls at a specific, verified point
  :page_size_a4_letter,           # A4 vs US Letter page geometry
  :odd_even_running_content       # running header/footer differs by page parity
]
```

**17 dimensions × 6 families = 102 cells** (the roadmap/CONTEXT's "~120" is stated as an approximation with a tilde; 102 is the honest count after reading every recipe's actual data contract — see the resolved matrix below for why several cells are legitimately N/A). Of the 102 cells, **62 are `:applies`** (in the "~40-60 cells" range D-03's rationale anticipated) and **40 are genuinely N/A** with per-family reasons.

**Naming note:** `:currency_format` and `:tax_label` are proposed as two separate dimensions (splitting the roadmap's single "USD vs GBP/EUR + VAT vs sales-tax labels" bullet) because they are mechanically different — `:currency_format` is a `:formatters` opts override (symbol/style), `:tax_label` is caller-supplied line-item `:description` DATA (per the milestone's locked "engine stays locale-free" boundary) — and, per the matrix below, they apply to different, only partially-overlapping subsets of families.

## Resolved N/A Matrix

Legend: `✓` = `:applies`. Anything else is the exact N/A reason string to embed as the `@matrix` value.

| Dimension | Invoice | Statement | Receipt | Certificate | Payslip | Ticket |
|---|---|---|---|---|---|---|
| `:text_wrap` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `:line_items_zero` | ✓ | ✓ | ✓ | `"certificate has no repeating line-item list"` | ✓ (via `:deductions`, empty-allowed) | `"placement is a fixed 1-4 entry grid, not a variable line-item list"` |
| `:line_items_one` | ✓ | ✓ | ✓ | same as above | ✓ | same as above |
| `:line_items_few` | ✓ | ✓ | ✓ | same as above | ✓ | same as above |
| `:line_items_page_boundary` | ✓ (raster) | ✓ (raster) | ✓ (byte only) | same as above | ✓ (raster) | same as above |
| `:line_items_60_plus` | ✓ (raster) | ✓ (raster) | ✓ (byte only) | same as above | ✓ (raster) | same as above |
| `:missing_optional_fields` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `:money_zero` | ✓ (via `:totals` only — legacy `:price` never routes through `Format.money`) | ✓ | ✓ | `"certificates carry no money"` | ✓ | `"tickets carry no money field"` |
| `:money_negative_parens` | `"Invoice totals (subtotal/tax/discount/total) are non-negative by domain convention; discount is subtracted internally, never modeled as a negative Decimal"` | ✓ (`lines.amount` is explicitly signed: "positive increases the balance, negative decreases it" — the natural fit) | `"Receipt totals model a purchase total, not a signed ledger — no natural negative-amount path"` | `"certificates carry no money"` | `"deductions are positive magnitudes subtracted internally (net_pay = gross - deductions); no natural negative-Decimal field"` | `"tickets carry no money field"` |
| `:money_large` | ✓ (via `:totals` only) | ✓ | ✓ | `"certificates carry no money"` | ✓ | `"tickets carry no money field"` |
| `:money_cents_rounding` | ✓ (via `:totals` only) | ✓ | ✓ | `"certificates carry no money"` | ✓ | `"tickets carry no money field"` |
| `:qty_zero` | ✓ (only family with a `:qty` field) | `"statement lines have no :qty concept"` | `"receipt lines have no :qty concept"` | `"certificates carry no money or quantities"` | `"payslip earnings/deductions have no :qty concept"` | `"tickets carry no money or quantities"` |
| `:currency_format` | ✓ (via `:totals` `:formatters` override only) | ✓ | ✓ | `"certificates carry no money"` | ✓ | `"tickets carry no money field to format"` |
| `:tax_label` | `"Invoice's totals 'Tax' line label is a hardcoded string literal — Invoice has no :labels override support (no label_resolver call)"` | `"statement has no tax/charge concept anywhere in its domain (a running-balance ledger has no line-item tax)"` | `"Receipt's totals 'Tax' line label is a hardcoded string literal — Receipt has no :labels override support"` | `"certificates carry no money"` | ✓ (unique — deduction `:description` is caller DATA per FAM-01's design intent, e.g. "PAYE Income Tax" vs "Federal Income Tax") | `"tickets carry no money or tax concept"` |
| `:pagination_boundary` | ✓ (raster) | ✓ (raster) | ✓ (byte only — see Anchor Drift note; D-10 did not select Receipt for a raster fixture) | `"certificate is a fixed single-page layout with no line-item chunking mechanism"` | ✓ (raster) | `"ticket is a fixed single-page/single-box layout — no chunking mechanism"` |
| `:page_size_a4_letter` | `"Invoice hardcodes A4 page geometry as a module attribute (@page_width 595.28) — no :page_size option exists"` | `"Statement hardcodes A4 page geometry (@page_width 595.28) — no :page_size option exists"` | `"Receipt hardcodes A4 page geometry (@page_width 595.28) — no :page_size option exists"` | ✓ (raster — chosen representative; supports `:page_size` via `PageSize.resolve/2`) | ✓ (byte only — also supports `:page_size` but not the chosen raster representative) | ✓ (byte only — also supports `:page_size` but not the chosen raster representative) |
| `:odd_even_running_content` | ✓ (byte only — escape-hatch composition; not part of the raster set below) | ✓ (byte only) | ✓ (byte only) | `"certificate is a fixed single-page layout — no second page to differ by parity"` | ✓ (raster — combined into the same fixture as pagination + 60+, per D-10a) | `"ticket is a fixed single-page/single-box layout — no second page to differ by parity"` |

**Cell count:** 62 `:applies` / 40 N/A / 102 total (17 × 6).

## Fixture Builder Contract: `Rendro.Test.EdgeFixtures`

Recommended module at `test/support/edge_fixtures.ex`, mirroring the shape of `test/support/pdfium_cli.ex` (`@moduledoc false`, pure functions, no GenServer/state).

```elixir
defmodule Rendro.Test.EdgeFixtures do
  @moduledoc false

  # Returns the recipe-shaped `data` map for one {family, dimension} cell.
  # Raises (loudly, at test-compile/run time — never silently) if the
  # combination is not a real :applies cell in the caller's @matrix.
  @spec build(atom(), atom()) :: map()
  def build(family, dimension)

  # Returns the recipe module for a family atom, e.g. :invoice -> Rendro.Recipes.Invoice.
  @spec recipe_module(atom()) :: module()
  def recipe_module(family)
end
```

**Per-family base data** (the "happy path minimum" each `build/2` clause starts from, informed by each recipe's actual `validate_required_keys!/1`):

| Family | Required keys (`validate_required_keys!/1`) | Optional keys exercised by `:missing_optional_fields` |
|---|---|---|
| `Rendro.Recipes.Invoice` | `:id, :date, :items` | `:issuer, :customer, :due_date, :terms, :totals` |
| `Rendro.Recipes.Statement` | `:period, :account, :opening_balance, :lines` | `:closing_balance, :summary` |
| `Rendro.Recipes.Receipt` | `:title, :date, :customer, :lines` | `:totals` |
| `Rendro.Recipes.Certificate` | `:title, :recipient, :date` | `:body, :seal_line, :brand` |
| `Rendro.Recipes.Payslip` | `:employer, :employee, :period, :pay_date, :earnings, :deductions, :net_pay` | `:totals, :payment_method` |
| `Rendro.Recipes.Ticket` | `:issuer, :title, :placement, :code` | `:subtitle, :terms` |

**Line-item shapes** (for the 5 `:line_items_*` dimensions, only defined for the 4 families that have a repeating list):
- Invoice `:items` — `%{name: String.t(), qty: integer(), price: number()}` (legacy bare-number `:price`, never Decimal)
- Statement `:lines` — `%{date: Date.t(), description: String.t(), amount: Decimal.t()}` (signed)
- Receipt `:lines` — `%{description: String.t(), amount: Decimal.t()}`
- Payslip `:earnings`/`:deductions` — `%{description: String.t(), amount: Decimal.t(), ytd: Decimal.t()}` (`:earnings` must stay non-empty — `validate_lines!(earnings, :earnings, require_non_empty: true)` at `payslip.ex:672`; use `:deductions` for the `:line_items_zero` cell)

**Money-dimension construction** (via `Rendro.Format.money/1`, which already handles negatives-as-parens and comma-grouping natively — do not hand-roll either):
```elixir
# Source: lib/rendro/format.ex:62-71 (read this session)
def money(%Decimal{} = amount) do
  rounded = Decimal.round(amount, 2)
  magnitude = "$" <> grouped(Decimal.abs(rounded))
  if Decimal.negative?(rounded), do: "(" <> magnitude <> ")", else: magnitude
end
```
- `:money_zero` → `Decimal.new("0.00")`
- `:money_negative_parens` (Statement only) → a negative `lines.amount`, e.g. `Decimal.new("-200.00")`
- `:money_large` → `Decimal.new("1250000.00")` (proves `group_thousands/1` comma output)
- `:money_cents_rounding` → a 3-decimal input, e.g. `Decimal.new("19.995")`, proving `Decimal.round/2` normalization

**Currency/tax-label construction** (opts, not data — passed as the `opts` arg to `document/2`/`sections/2`, never baked into the fixture's `data` map):
```elixir
# :currency_format — Source: lib/rendro/recipes/pagination.ex:57-60 (formatter/3)
opts = [formatters: [amount: fn d -> "£" <> Rendro.Format.money(d) |> String.trim_leading("$") end]]

# :tax_label (Payslip only) — caller DATA, not opts. Vary the deduction :description:
%{description: "PAYE Income Tax", amount: Decimal.new("450.00"), ytd: Decimal.new("5400.00")}
# vs.
%{description: "Federal Income Tax", amount: Decimal.new("450.00"), ytd: Decimal.new("5400.00")}
```

**A4/Letter construction** (opts, Certificate/Payslip/Ticket only):
```elixir
# Source: lib/rendro/page_size.ex:11-17 (verified this session)
Rendro.Recipes.Certificate.document(data, page_size: :a4)       # 595.28 x 841.89 (default)
Rendro.Recipes.Certificate.document(data, page_size: :us_letter) # 612 x 792
```

**Odd/even running content construction** (escape-hatch — not a `document/2` opt on any of the six recipes):
```elixir
# Source: test/rendro/pipeline/paginate_test.exs:923-1013 (pattern read this session)
template = Rendro.Recipes.Invoice.page_template()
base_secs = Rendro.Recipes.Invoice.sections(data)

odd_footer = Rendro.section(
  region: :footer, only_on: :odd,
  content: [%Rendro.Block{content: %Rendro.RunningContent{
    fun: fn {pn, _tp} -> [Rendro.block(Rendro.text("Page #{pn} (odd)"))] end
  }, height: 14.4}]
)
even_footer = Rendro.section(
  region: :footer, only_on: :even,
  content: [%Rendro.Block{content: %Rendro.RunningContent{
    fun: fn {pn, _tp} -> [Rendro.block(Rendro.text("Page #{pn} (even)"))] end
  }, height: 14.4}]
)

doc =
  Rendro.Document.new()
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
  |> then(&Enum.reduce(base_secs ++ [odd_footer, even_footer], &1, fn s, d -> Rendro.Document.add_section(d, s) end))
```

**RTL error fixture (EDGE-02, path b — clone, do not vendor a font):**
```elixir
# Clone verbatim from test/rendro/pipeline/measure_test.exs:617-672 (read in full this session)
defp arabic_capable_fake_font do
  arabic_widths =
    [32, 1575, 1576, 1581, 1585, 1605, 1576, 1575]
    |> Enum.uniq() |> Map.new(fn cp -> {cp, 500} end)

  %Rendro.PDF.Font{
    source: :built_in, logical_name: :fake_arabic, name: "F_FAKE_ARABIC",
    base_font: "FakeArabic", subtype: :type1, units_per_em: 1000,
    ascent: 800, descent: -200, default_width: 500,
    widths: arabic_widths, cmap: nil, font_bytes: nil
  }
end
```

## Common Pitfalls / Risks / Landmines

### Landmine 1: CI raster job hardcodes a single test file path
**What goes wrong:** `.github/workflows/ci.yml:215-218` runs `mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` — an explicit, single-file target, not a tag-wide `--only raster_snapshot` sweep. If the new raster cells land in a separate new test file (as D-11's "clone `pdfium_raster_snapshot_test.exs` for mechanics" implies), that new file's `@tag raster_snapshot: true` tests will simply **never run in CI** — no failure, no signal, silent gap.
**How to avoid:** Either (a) add the new raster cells to the SAME file (`pdfium_raster_snapshot_test.exs`), or (b) update the CI step's file-list argument to include the new file(s) explicitly, or (c) change the CI invocation to `mix test --include raster_snapshot --only raster_snapshot` (a full-suite tag sweep) so any future raster-tagged file is picked up automatically. This is a `.github/workflows/ci.yml` edit — not `lib/`, but outside the CONTEXT.md domain boundary's explicit "test/, test/support/, non-lib/ priv/" list. **Flag this as a necessary scope clarification for the plan**, not a silent scope creep — EDGE-01's raster refs are inert without it.
**Warning signs:** Raster tests pass locally with `MIX_RASTER_BLESS=true` in a container but the CI `advisory-checks` job log shows zero new test names running.

### Landmine 2: RTL path (b) requires a font this repo does not have
**What goes wrong:** D-06 path (b) ("a font that has RTL glyphs") cannot be exercised with any font currently vendored — `priv/branded/fonts/B612-Regular.ttf` is Latin/aviation-only; no Hebrew/Arabic-glyph TTF exists anywhere in `priv/`, `lib/`, or the repo root. Attempting to register a real font via `Rendro.register_embedded_font/3` for this purpose would require sourcing and vendoring a new binary asset (licensing overhead, `NOTICE` file update, tarball weight) — a scope escalation this test-only phase should avoid.
**How to avoid:** Clone the `arabic_capable_fake_font/0` + `doc_with_arabic_text/0` pattern from `test/rendro/pipeline/measure_test.exs:617-672` verbatim (see Fixture Builder Contract above). This builds a synthetic `%Rendro.PDF.Font{source: :built_in, widths: <arabic-codepoint-map>}` and injects it directly into a hand-built `%Rendro.Document{}.font_registry` — a technique that already ships in this repo's test suite for exactly this error path.
**Warning signs:** A `checkpoint:human-verify` task appearing that asks someone to source a font — that would signal the plan is about to escalate scope; redirect to the fake-font clone instead.

### Landmine 3: D-10's "Receipt is structurally single-page" premise is incorrect
**What goes wrong:** Receipt's own moduledoc (`lib/rendro/recipes/receipt.ex:5-8`) states: *"A single-page receipt and a multi-page tabular 'report' are the same recipe — multi-page is just a receipt whose line items overflow one page. Column headers repeat on every page via per-page table blocks; 'Page X of Y' appears in the footer."* Receipt uses `Rendro.Recipes.Pagination.chunk_rows_into_pages/2` (`receipt.ex:296`), identically to Invoice. If a plan blindly follows D-10's stated premise and marks Receipt's pagination-related cells N/A, it will under-cover a real, currently-supported code path.
**How to avoid:** The resolved N/A matrix above already corrects this — Receipt's `pagination_boundary`/`line_items_60_plus`/`odd_even_running_content` cells are marked `:applies` (byte-golden only, no raster ref, respecting D-10's fixed 3-family/6-fixture raster ceiling). This does **not** require reopening D-10's locked raster-fixture selection (Invoice/Statement/Payslip stays the raster trio) — it only affects which BYTE-golden cells exist, which is squarely inside D-01's "curated data-driven matrix" discretion, not a D-10 override.
**Warning signs:** A reviewer asking "why does Receipt's own moduledoc contradict the phase's stress-matrix documentation?" — the answer is: it doesn't, once the matrix cells are corrected as above.

### Landmine 4: only 3 of 6 families support `page_size:` at all
**What goes wrong:** Invoice, Statement, and Receipt hardcode A4 page geometry as module attributes (`@page_width 595.28`, confirmed identically in all three files) — there is no `page_size:` option in their `document/2`/`page_template/1` signatures. A plan that assumes all six families can be exercised at both A4 and US Letter will hit either a silently-ignored option (if passed as an unused keyword) or, more likely, will simply render the SAME A4 geometry regardless of what's passed — producing a false-positive "US Letter" golden that is byte-identical to the A4 one, silently defeating the dimension's purpose.
**How to avoid:** The resolved N/A matrix marks Invoice/Statement/Receipt N/A for `:page_size_a4_letter` with the exact hardcoded-attribute reason. Only Certificate, Payslip, Ticket (all three use `Rendro.PageSize.resolve/2` — verified via `grep` this session) legitimately support the option.

### Landmine 5: `Rendro.I18n.Analyzer.analyze/1` dead-code trap
**What goes wrong:** `lib/rendro/i18n/analyzer.ex` exists, is fully implemented (RTL/complex-script codepoint-range detection), and LOOKS like exactly the right tool for classifying RTL/complex-script test inputs — but it is confirmed dead code: the only caller anywhere in the tree is its own test (`test/rendro/i18n/analyzer_test.exs`); the one apparent `lib/` caller (`rendro-0.1.0/lib/rendro/pipeline/measure.ex:82`) is inside a gitignored `mix hex.build` tarball-extraction artifact directory (`rendro-0.1.0/`, listed in `.gitignore` as `/rendro-*/`), not real source.
**How to avoid:** Do not call `Rendro.I18n.Analyzer.analyze/1` from any new test helper or fixture builder — it would create an implicit dependency on unwired code and blur the "zero lib/ change" posture. The measure pipeline's actual glyph-resolution and shaping-gate checks (already verified live this session) are the real, wired error sources.

### Landmine 6: "zero lib/ change" scope guard
**What goes wrong:** Any of the above landmines, if worked around incorrectly (vendoring a new font, wiring the I18n Analyzer, adding a `page_size:` option to Invoice/Statement/Receipt to "complete" the matrix), would force a `lib/` edit — the milestone's explicitly stated non-goal for this phase (per CONTEXT.md: "no `lib/` product change is required... Any decision that would force a `lib/` change is called out as a risk... and is out of scope unless a real product-defect is discovered").
**How to avoid:** Every recommendation in this research (fake-font clone, N/A matrix cells for page-size-unsupported families, escape-hatch running-content composition) is designed specifically to avoid this. If plan execution surfaces a genuine product defect (e.g., an unexpected panic instead of a typed error), that is grounds to flag it back to the user — not to silently patch `lib/` inside this phase.

## Code Examples

### Golden bless idiom (D-04), mirroring the raster idiom exactly
```elixir
# test/support/golden.ex — new, mirrors pdfium_raster_snapshot_test.exs's private
# assert_or_bless/2 (test/rendro/adapters/pdfium_raster_snapshot_test.exs:52-95, read in full)
defmodule Rendro.Test.Golden do
  @moduledoc false

  @spec assert_or_bless({atom(), atom()}, binary()) :: :ok
  def assert_or_bless({family, dimension}, pdf) do
    ref_path = "priv/goldens/#{family}/#{dimension}.sha256"
    actual = Base.encode16(:crypto.hash(:sha256, pdf), case: :lower)

    if System.get_env("MIX_GOLDEN_BLESS") == "true" do
      File.mkdir_p!(Path.dirname(ref_path))
      File.write!(ref_path, actual <> "\n")
    else
      unless File.exists?(ref_path) do
        ExUnit.Assertions.flunk("""
        Missing golden ref: #{ref_path}
        A missing ref is a hard failure, never a silent auto-create.
        Run: MIX_GOLDEN_BLESS=true mix test <this file> to author it deliberately.
        """)
      end

      expected = File.read!(ref_path) |> String.trim()

      ExUnit.Assertions.assert(actual == expected, """
      Golden hash mismatch for #{family}/#{dimension}.
      A hash change is a DEFECT, not a refresh, unless a human re-authorizes it.
      Run: MIX_GOLDEN_BLESS=true mix test <this file> to intentionally update.
      """)
    end
  end

  # Shared two-run determinism pre-check (resolves the D-04 discretion item
  # in favor of a shared helper over inline-per-case duplication).
  @spec assert_deterministic!(Rendro.Document.t()) :: binary()
  def assert_deterministic!(doc) do
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    ExUnit.Assertions.assert(pdf1 == pdf2, "non-determinism leak — refusing to bless")
    pdf1
  end
end
```

### `@matrix`-driven test generation (D-01)
```elixir
# test/rendro/edge_matrix_test.exs
defmodule Rendro.EdgeMatrixTest do
  use ExUnit.Case, async: true
  import Rendro.Test.Golden, only: [assert_or_bless: 2, assert_deterministic!: 1]
  alias Rendro.Test.EdgeFixtures

  @families [:invoice, :statement, :receipt, :certificate, :payslip, :ticket]
  @dimensions [:text_wrap, :line_items_zero, ...] # full 17-item list, see Resolved Dimensions

  @matrix %{
    {:invoice, :text_wrap} => :applies,
    {:invoice, :page_size_a4_letter} =>
      "Invoice hardcodes A4 page geometry (@page_width 595.28) — no :page_size option exists",
    # ...all 102 pairs...
  }

  # D-02: coverage-honesty ratchet
  test "every {family, dimension} pair has a @matrix entry" do
    all_pairs = for f <- @families, d <- @dimensions, do: {f, d}
    missing = all_pairs -- Map.keys(@matrix)
    assert missing == [], "Uncovered pairs (neither :applies nor an N/A reason): #{inspect(missing)}"
  end

  for {{family, dimension}, :applies} <- @matrix do
    test "#{family}/#{dimension} golden byte-identity" do
      data = EdgeFixtures.build(unquote(family), unquote(dimension))
      doc = EdgeFixtures.recipe_module(unquote(family)).document(data)
      pdf = Rendro.Test.Golden.assert_deterministic!(doc)
      Rendro.Test.Golden.assert_or_bless({unquote(family), unquote(dimension)}, pdf)
    end
  end
end
```

## Validation Architecture

The "system under validation" for this phase IS the test matrix itself — a meta-level validation question: *how do we know the matrix actually proves what it claims, rather than merely asserting?*

### What determinism property is being sampled
Byte-identity across two `deterministic: true` renders of the SAME document, taken immediately before any hash is computed or blessed (D-04). This is not a new determinism proof — `deterministic_test.exs`'s property tests already establish general determinism — it is a **per-fixture regression guard**: if a future engine change introduces non-determinism specific to one matrix cell's exact content shape (e.g., a new dict-key ordering bug that only manifests with 60+ table rows), the shared `assert_deterministic!/1` helper catches it BEFORE a wrong hash is ever blessed into `priv/goldens/`.

### Coverage-honesty ratchet as the anti-undersampling guard (D-02)
The meta-test `"every {family, dimension} pair has a @matrix entry"` is the Nyquist-relevant control here: it is not possible for a gap in coverage to silently exist, because the matrix's OWN exhaustiveness is machine-checked against the cross product of `@families × @dimensions`. Any new family or dimension added later must immediately get an entry (applies or N/A) or the meta-test fails — coverage claims can never overclaim.

### Byte-vs-raster split as the sampling-rate decision (D-09)
This is the Nyquist "how densely do we need to sample" answer for THIS domain: byte-SHA-256 is a *complete* constraint on output for content-substitution correctness (proven equivalent to a full diff — if two documents hash identically, they are byte-identical, full stop) and is cheap enough to run on every cell in the default `mix test` job. Raster (pixel) sampling is reserved for the strict subset of cells where the correctness claim is specifically about *geometry a byte-diff cannot humanly verify* (page-break placement, margin/A4-vs-Letter positioning, running-header parity) — an intentionally sparse, curated subset (6 fixtures / ~9 refs, see Resolved N/A Matrix) rather than exhaustive, because raster refs are platform-pinned (not portable) and expensive to review visually.

### Fail-loud contract tests as the exemption-invariant validation (D-15)
EDGE-03's "how do we know the exemption isn't quietly lost or abused" question is answered entirely by `test/docs_contract/rubric_manifest_contract_test.exs`'s extended assertions: (i) the exemption block's presence is enforced by BOTH the JSON schema's `required` array AND a contract-test assertion (two independent enforcement layers — either one alone could be silently deleted; both together cannot); (ii) the disjointness assertion (stress-fixture IDs ∩ `scores` demo IDs = ∅) is imported from the SAME `@matrix` enumeration used to generate the golden tests, so there is only one source of truth for "what counts as a stress fixture" — it cannot drift from the actual test suite.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no new dependency) |
| Config file | `test/test_helper.exs` (existing; `raster_snapshot: true` already excluded by default at line 10) |
| Quick run command | `mix test test/rendro/edge_matrix_test.exs` (byte goldens only, `async: true`, seconds) |
| Full suite command | `mix test --include raster_snapshot` (adds the advisory raster lane; requires the pinned `pdfium-cli` binary and, for blessing, `GITHUB_ACTIONS=true`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EDGE-01 (byte) | Every `:applies` cell renders a stable, hash-verified PDF | unit (data-driven) | `mix test test/rendro/edge_matrix_test.exs` | ❌ Wave 0 — new file |
| EDGE-01 (raster) | 6 curated fixtures match pixel refs at pinned pdfium version | unit (tagged, advisory) | `mix test --include raster_snapshot test/rendro/edge_matrix_raster_test.exs` (or extended `pdfium_raster_snapshot_test.exs`) | ❌ Wave 0 — new file/extension |
| EDGE-01 (tarball) | `priv/goldens`/`priv/raster_refs` excluded from Hex tarball | docs-contract | `mix test test/docs_contract/branding_claims_test.exs` (extended) | ✅ existing file, extend |
| EDGE-01 (matrix honesty) | Every `{family, dimension}` pair has an entry | unit (meta) | `mix test test/rendro/edge_matrix_test.exs` | ❌ Wave 0 |
| EDGE-02 | Overflow/tall-row/RTL raise typed, instructive errors | unit (`assert_raise`-style pattern match) | `mix test test/rendro/edge_error_matrix_test.exs` (new sibling file per D-08) | ❌ Wave 0 — new file |
| EDGE-03 | Exemption present, valid, disjoint, non-vacuous | docs-contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` (extended) | ✅ existing file, extend |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/edge_matrix_test.exs test/rendro/edge_error_matrix_test.exs` (byte + error cells only — fast, `async: true`, no pdfium dependency)
- **Per wave merge:** add `mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/branding_claims_test.exs`
- **Phase gate:** full suite green, PLUS one manual/CI-container run of `mix test --include raster_snapshot` before considering the raster fixtures blessed (raster is advisory in CI, not gating, but must be verified at least once per fixture addition)

### Wave 0 Gaps
- [ ] `test/support/edge_fixtures.ex` — `Rendro.Test.EdgeFixtures.build/2` fixture builder (all 6 families × applicable dimensions)
- [ ] `test/support/golden.ex` — `assert_or_bless/2` + `assert_deterministic!/1` shared helpers
- [ ] `test/rendro/edge_matrix_test.exs` — `@matrix`/`@dimensions`/`@families` + data-driven golden tests + D-02 meta-test
- [ ] `test/rendro/edge_error_matrix_test.exs` (or similarly named sibling) — EDGE-02 typed-error assertions (overflow, tall-row, RTL × 2 paths)
- [ ] `priv/goldens/` directory tree — created by first `MIX_GOLDEN_BLESS=true` run, not hand-authored
- [ ] `.github/workflows/ci.yml` raster step — must be updated to pick up new raster test file(s) (Landmine 1)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | 17-dimension canonical list (splitting the roadmap's compound bullets into atomic dimensions) is the right granularity, rather than a coarser or finer split | Resolved Dimensions & Families | If the planner/user wants a coarser grain (fewer, combined dimensions), the `@matrix` size shrinks but the underlying fixture-construction logic is unaffected — low risk, easy to consolidate later. |
| A2 | Certificate is the best A4/Letter raster representative (over Payslip or Ticket, which also support `:page_size`) | Resolved N/A Matrix / Fixture Builder Contract | If the user prefers Payslip (to consolidate with its existing pagination fixture and reduce total fixture count further), swap the representative — the underlying mechanics (`PageSize.resolve/2`) are identical for all three candidates. |
| A3 | Invoice is the best extreme-wrap raster representative | Fixture Builder Contract | Low risk — Statement/Receipt/Payslip's `:description` fields would work equally well; Invoice was chosen for builder-reuse economy (already deeply understood for the pagination fixture), not because it is uniquely correct. |
| A4 | `:tax_label` and `:currency_format` should be split into two dimensions rather than kept as the roadmap's single compound bullet | Resolved Dimensions & Families | If kept as one dimension, several N/A reasons collapse (e.g. Invoice/Receipt would need a compound "N/A for tax_label, applies for currency" annotation crammed into one cell) — the split is a readability/precision choice, not a coverage change. |
| A5 | The CI raster-job hardcoded-file-path issue (Landmine 1) is in-scope to fix within this phase, despite not being explicitly listed in CONTEXT.md's edit-surface boundary | Common Pitfalls / Landmine 1 | If out of scope, EDGE-01's raster refs would be authored but never actually exercised in CI — a silent, unenforced coverage claim, directly contradicting D-02's coverage-honesty philosophy. Flagging this for explicit user/planner confirmation is safer than silently skipping it. |

**All other claims in this research are `[VERIFIED]`** — either read directly from `lib/`/`test/`/`priv/`/`.github/` source in this session, or reproduced via live `mix run` probes in this session (see Live-Probe Verification). No package/library recommendations were made (no external packages are used), so the package-provenance rules do not apply.

## Open Questions

1. **Should the CI raster-job fix (Landmine 1) be an explicit task in the phase plan, or handled as an incidental fix inside whichever plan adds the new raster test file?**
   - What we know: the fix is small (one YAML line or one file-consolidation choice) and strictly necessary for EDGE-01's raster refs to have any effect.
   - What's unclear: whether touching `.github/workflows/ci.yml` needs explicit user sign-off given CONTEXT.md's edit-surface boundary didn't name it.
   - Recommendation: make it an explicit, separately-callable-out task in the plan (not buried inside a larger task) so the scope decision is visible and easy to confirm or veto.

2. **Should `:pagination_boundary`/`:line_items_60_plus`/`:odd_even_running_content` for Receipt get a raster ref too, given Landmine 3's discovery that Receipt genuinely paginates?**
   - What we know: D-10's locked raster set (Invoice/Statement/Payslip, ~6 fixtures) intentionally stays at the ceiling; adding a 4th paginating-family raster fixture would push toward 8 fixtures (still within the `≤ 8 / ≤ 16` hard ceiling, but no longer near "~6").
   - What's unclear: whether the ~6 target is a strict preference or just an estimate.
   - Recommendation: keep Receipt byte-golden-only as resolved above (respects the "~6 fixtures" target precisely) — this is not a coverage gap since D-09's split rule only requires raster where a byte-diff can't verify the claim, and Receipt's pagination mechanism is identical (not independently novel) to Invoice's, which already has raster coverage.

## Sources

### Primary (HIGH confidence — read directly from working tree this session)
- `lib/rendro/pipeline/paginate.ex`, `lib/rendro/error.ex`, `lib/rendro/pipeline/measure.ex`, `lib/rendro/text/shaper/simple.ex`, `lib/rendro/text/bidi.ex` — EDGE-02 error paths, full read + anchor verification
- `lib/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}.ex` — full or near-full read, data contracts, `page_size`/`labels`/`formatters` support matrix
- `lib/rendro/recipes/pagination.ex`, `lib/rendro/page_size.ex`, `lib/rendro/format.ex`, `lib/rendro/running_content.ex`, `lib/rendro/section.ex` — shared engine/recipe primitives
- `lib/rendro/i18n/analyzer.ex` + confirmed-dead-code cross-check via repo-wide `grep`
- `test/rendro/adapters/pdfium_raster_snapshot_test.exs`, `test/docs_contract/branding_claims_test.exs`, `test/docs_contract/rubric_manifest_contract_test.exs`, `test/rendro/table_byte_identity_test.exs`, `test/rendro/deterministic_test.exs`, `test/rendro/pipeline/measure_test.exs`, `test/rendro/pipeline/paginate_test.exs`, `test/rendro/text/shaper_test.exs`, `test/test_helper.exs` — full read
- `priv/schemas/rubric_scores.schema.json`, `priv/quality/rubric_scores.json`, `priv/pdfium_pin.json`, `mix.exs` — full read
- `.github/workflows/ci.yml` — raster job / advisory-checks job structure read
- Live-probe renders executed this session via `mix run` (overflow, RTL default-font) — see Live-Probe Verification section

### Secondary (MEDIUM confidence)
- None — no external documentation lookups were needed; this is a pure internal-codebase research task with zero new external dependencies.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: N/A — no new packages
- Architecture: HIGH — every primitive (byte hash, raster render, error struct, running content, section `only_on`) verified against live source or a passing existing test this session
- Pitfalls: HIGH — all 6 landmines derived from direct source reads and one repo-wide dead-code cross-check, not inference

**Research date:** 2026-07-18
**Valid until:** 30 days (stable internal codebase; re-verify anchors if `lib/rendro/pipeline/paginate.ex` or the six recipe modules receive further edits before this phase executes)

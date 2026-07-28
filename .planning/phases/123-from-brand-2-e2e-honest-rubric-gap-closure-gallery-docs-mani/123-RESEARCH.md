# Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure - Research

**Researched:** 2026-07-28
**Domain:** Elixir PDF library — theme-token application, deterministic gallery rasters, docs-contract/rubric-manifest honesty gates (pure code, zero new deps)
**Confidence:** HIGH (every ground-truth claim verified against live code at file:line; all math recomputed)

## Summary

This is a **verify-and-attest** closure phase, not a build-from-scratch phase. Five of the CONTEXT's
load-bearing assumptions were checked against the live code and **four are CONFIRMED**, one is
**NUANCED** (certificate fit-check), and **one D-03 sub-claim is CONTRADICTED** (gallery byte-impact).
The palette, the `leading` seam, the `from_brand/2` surface, the rubric `passed?/2` tripwire, the S6
gallery tags, and the docs-contract marker machinery all exist and behave as the plan needs.

**The single most important finding — headline for the planner:** threading
`theme: Rendro.Theme.default()` into the 7 "default" gallery rows (D-03 retag) is **NOT byte-neutral
except leading**. Every recipe carries its *own* native type-scale literals that differ from the
theme default scale, and every recipe reads `type.scale.*`, so **all 7 rows re-render with shifted
type sizes** — most dramatically the Certificate recipient (native `display 34` → themed `display 21`).
D-03's sub-claim that "non-prose rows (statement/receipt/payslip) stay byte-identical" is false. This
does **not** block the phase (D-02 already states "`default/0` + Phase-122 typography changed **every**
demo's pixels"), but the planner must budget a **full 7-row re-bless** and, critically, the honest
re-score (D-02) must re-measure content-hierarchy deltas against the *themed* renders — where the
Certificate's compressed hierarchy (recipient 21 vs title 16.5, was 34 vs 20) is a genuine
`content_hierarchy == 5` risk that the human sign-off must confront, not paper over.

**Primary recommendation:** Execute the D-05 three-commit split exactly. In **Commit 2** (theme
application), regenerate ALL 7 themed gallery rasters + the 4 new rows and *pre-compute every
glyph-height delta against the themed bytes* — do not reuse the 2026-07-19 native-scale deltas. Treat
the Certificate hierarchy re-measurement as the phase's highest honesty risk; if it fails `== 5` at
the themed scale, that is an honest signal to adjust emphasis (the display anchor) in Commit 2, never
to flip the score in Commit 3.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 — `default/0` palette LOCKED AS-IS; realize `leading: 1.35`.** Zero palette deltas (all 9
  roles trace to `brand/tokens/tokens.json` `semantic.light`); keep `accent = blue-600 {44,107,237}`
  (NOT blue-700); change `@default_typography` `leading: 1.2 → 1.35` (single line). Re-bless surface:
  Certificate body citation, Invoice/BrandedInvoice "Terms:", Ticket terms. Fit-check the themed
  Certificate single-page A4-landscape at 1.35. Recipe-usage guard: `accent` is a fill/large-text
  role — never small text on the warm `surface` band.
- **D-02 — Honest re-score of ALL 6 rubric demos with machine-enforced human sign-off.** Re-score all
  6 families against current themed `default/0` bytes; DO NOT touch frozen thresholds (`hierarchy==5`,
  `core≥4`, gates true). Add `signed_off_by`/`signed_off_at`/`evidence_ref` to each `scores[]` record;
  require them in the schema when `passed==true`; add test teeth (a `passed:true` without a live
  hash-checked `evidence_ref` fails the build). Author `priv/quality/SIGN-OFF.md` in the
  `brand/audit/SCORECARD.md` house style. Additive `Signed-off-by:` git trailer on the score commit.
  Evidence is pre-computed (6 pdfium rasters + per-demo glyph-height deltas + invoice before/after),
  THEN judged.
- **D-03 — Gallery: 11 curated blessed rows (hybrid, additive), flagship Invoice triptych.** Keep +
  retag 7 light rows `theme: null → "default"` (render via `theme: Rendro.Theme.default()`); append
  3 dark (`invoice_dark`, `certificate_dark`, `ticket_dark`) + 1 `from_brand` (`invoice_brand` via
  `from_brand(accent: "#0E7C76")`, accent-only). `preset: null` on all 11. Add `readme_hero: true`
  flag; README shows the 7 light + a labeled theming strip; `guides/recipes.md` + `guides/theming.md`
  show all 11 with SHA-256s. The 7 no-theme recipe byte-identity goldens stay UNTOUCHED.
- **D-04 — `from_brand/2` E2E via gallery render + executable guide example.** Build surface =
  combination; the guide's `# docs-contract:` markers make the example execute as the E2E test (NO
  separate standalone integration test). Headline one-liner:
  `Rendro.Recipes.Invoice.document(data, theme: Rendro.Theme.from_brand(accent: "#0E7C76"))`.
  Orthogonality vehicle = `BrandedInvoice` (assets via `data.brand`, accent via `theme:`); assert
  `font_registry`/`asset_registry` entries AND `Theme.resolve(theme).colors.accent == {14,124,118}`.
  Seeds: teal-700 `#0E7C76` (primary, → white on_accent) + amber-300 `#E6B450` (→ ink on_accent) to
  prove the heuristic both ways; third-party hex only in teaching prose. Mandatory honest wording:
  `on_accent` is a "readable default," never a WCAG-AA/PDF-UA claim, overridable via `on_accent:`.
- **D-05 — Split-commit ordering provable in git.** Commit 1: DATA verify/attest (likely no-op) + a
  test asserting parties/totals present; no theme, no scores. Commit 2: theme/`default/0` application
  (`leading:1.35`) + re-bless themed gallery rasters; no `rubric_scores.json` change. Commit 3: honest
  re-score (score-flip) touching ONLY `rubric_scores.json` + `SIGN-OFF.md` + schema/test; zero
  palette/token/color code in the diff.

### Claude's Discretion
Per-demo measured-delta numbers and `SIGN-OFF.md` prose; the precise `readme_hero` filter
implementation in `readme_block/1`; whether the gallery/rubric work is one slice or split by
requirement; `defp` helper naming for the themed `build_source_document/1` clauses; the exact
`# docs-contract:` marker names in `guides/theming.md`; whether the `default/0` retag threads
`theme: default()` through a shared helper or per-spec. Binding constraints: all-6-re-scored,
machine-enforced sign-off with live hash-checked `evidence_ref`, the D-05 three-commit order provable
in git, `preset:null` on every row, no engine/public-API-shape change, no new *runtime* asset, frozen
rubric thresholds untouched.

### Deferred Ideas (OUT OF SCOPE)
Genre/style presets, public example catalog, static configurator, curated preset fonts → Milestone C
(`SEED-004`); `preset` stays `null` on every row. Live Studio → Milestone D (`SEED-005`). Exhaustive
gallery matrix (~28 rows) — deliberately NOT built. Dark rows for dense (Statement/Receipt) and
asset-branded (BrandedInvoice) recipes — honestly excluded. `density: :compact` deep multipliers →
Milestone C. Tabular figures / small-caps / OpenType `mono` → demand-gated. WCAG-AA/PDF-UA conformance
claims for `on_accent`/dark — permanently out.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEFAULT-01 | Strong neutral `default/0` (`{r,g,b}` mined from tokens) that looks strong on its own; `from_brand/2` E2E | Palette VERIFIED zero-delta (`theme.ex` L48-58); `leading:1.2→1.35` is a single-line edit at L79; `from_brand(accent:"#0E7C76")` VERIFIED (hex coerced → `{14,124,118}`, on_accent→white). See §Ground-Truth 2, 4, 7. |
| DEFAULT-02 | Honest SHOW-01 closure: DATA fixed → `default/0` applied → re-score (hierarchy=5, core≥4, gates) with human sign-off; `passed:true` only on honest clear | DATA already present (verify-only, §GT-1); `passed?/2` tripwire recomputes (`rubric_manifest_contract_test.exs` L33-45); sign-off fields graft onto schema `$defs/score_entry` + a new test loop. Re-score is against **themed** renders (§GT-3, Big Finding). |
| DEFAULT-03 | Themed + dark gallery renders populate S6 `theme`/`mode` tags; each `(recipe × mode)` a distinct blessed row; `preset` stays `null` | S6 keys VERIFIED present + null-or-string (`launch_artifacts.ex` L29, L673); `expected_ids` derived from `@gallery_specs` (L571); hard-coded "seven previews" test (L12) must go to 11. See §GT-6. |
| CONTRACT-02 | Proof-backed `support_matrix.json` theming rows + `guides/theming.md` + claims test binding every claim to proof; docs-contract + Hex-tarball lanes green (no new *runtime* asset) | Marker harness VERIFIED (`test/support/docs_contract.ex`); `theming_claims_test.exs` L163 currently REFUTES `guides/theming.md` — must FLIP; tarball tripwire keeps `priv/quality`/`priv/support_matrix.json`/`priv/schemas/rubric_scores.schema.json` EXCLUDED (`branding_claims_test.exs` L72-85). See §GT-5, GT-8. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `default/0` palette + `leading` | `lib/rendro/theme.ex` (pure token value) | — | Theme is inert data; never reaches the render pipeline. |
| Type-scale/leading application to demos | Recipe layer (`lib/rendro/recipes/*`) via `type.scale.*` / `type.leading` | — | Recipes read the resolved theme; the engine is theme-agnostic. |
| Gallery raster generation + hashing | `lib/rendro/launch_artifacts.ex` + `mix rendro.launch_artifacts.gen/check` | pinned pdfium lane | Deterministic PDF → pdfium PNG → sha256 in `artifacts.json`. |
| Rubric manifest + honesty gate | `priv/quality/rubric_scores.json` + `priv/schemas/*.schema.json` + `test/docs_contract/rubric_manifest_contract_test.exs` | git `Signed-off-by:` trailer | Machine-recomputed `passed?/2`; sign-off fields are additive. |
| `from_brand/2` E2E proof | `guides/theming.md` `# docs-contract:` fences + a new `theming_contract_test.exs` | `invoice_brand` gallery row | The guide fence IS the executable test (`DocsContract.evaluate!`). |
| Support-matrix claim proof | `priv/support_matrix.json` `theming.*` + `theming_claims_test.exs` | — | Every boundary key bound to `"unsupported"`; overclaim tripwire. |
| Tarball boundary | `mix.exs` `package.files` allowlist + `branding_claims_test.exs` | — | `priv/quality`/`support_matrix`/rubric-schema excluded; `assets/rendro` + `guides` ship. |

## Ground-Truth Verification

> The core ask of this phase. Each CONTEXT claim the plan rests on, verified against live code.

### GT-1 — DATA survival (D-05 Commit 1 is a verify-only no-op): **CONFIRMED**
- `Rendro.ExamplesData.transform_invoice/1` (`lib/rendro/examples_data.ex` L36-63) `put_optional`s all
  three: `:issuer` (L58), `:customer` (L59), `:totals` (L62) via `transform_party/1`/`transform_totals/1`.
- Fixture `priv/examples/invoice/acme-phoenix-saas/invoice.json` carries `issuer` (L5), `customer`
  (L13), and `totals` (L34: subtotal 645.00 / tax 51.60 / total 696.60). Money is faithful `Decimal`.
- **Commit 1 is genuinely verify-only.** There is no residual `transform_invoice` data work. The plan
  needs a *new test* asserting `transform_invoice(load!(...))` yields a map with non-nil `:issuer`,
  `:customer`, and `:totals.total` — nothing more. `[VERIFIED: lib/rendro/examples_data.ex:58-62;
  priv/examples/invoice/acme-phoenix-saas/invoice.json:5,13,34]`

### GT-2 — `leading` seam is one-line (D-01): **CONFIRMED (with a scale caveat, see GT-3 / Big Finding)**
- `@default_typography` in `theme.ex` L75-81 is `leading: 1.2` (L79). The 1.2→1.35 change is a single
  literal edit. `[VERIFIED: lib/rendro/theme.ex:79]`
- `type.leading` is wired uniformly to `%Text{line_height}` in every recipe (e.g. Certificate
  `centered_paragraph` L441 and `centered_line` L420; each recipe reads `type.leading`). Single-line
  runs are inert (`line_height` is a no-op on one line) — only wrapped multi-line prose re-flows.
- Prose blocks that re-flow at 1.35 (themed path only): Certificate body citation
  (`certificate.ex` `centered_paragraph` ~L433/L389), Invoice/BrandedInvoice "Terms:", Ticket terms.
- **CAVEAT:** the leading edit only affects the **themed** path. But threading a theme *also* swaps the
  type scale (GT-3) — so the re-bless is broader than "leading reflow." `[VERIFIED]`

### GT-3 — Certificate fit-check (D-01 highest risk): **NUANCED — risk is LOW, but the CONTEXT's framing is imprecise**
- `validate_body!/1` (`certificate.ex` L717-731) is a **byte-length guard only**: it raises when
  `byte_size(body) > 2000`, else `:ok`. **It does not measure geometry and is completely insensitive
  to `leading`.** The CONTEXT's "verify the themed Certificate still satisfies `validate_body!/1` at
  1.35" mis-frames the lever — `validate_body!/1` cannot detect leading-induced overflow.
  `[VERIFIED: lib/rendro/recipes/certificate.ex:717-731]`
- The real vertical-fit machinery is `content_height_estimate` (L360-362), which uses the recipe's own
  module constant `@line_height 1.2` (L298, via `line_h/1` L401) to compute `top_spacer_h` for vertical
  centering — **while the actual text emits at `type.leading` (1.35 themed)**. This estimate/render
  mismatch means themed content sits ~12.5% taller than estimated → the body extends slightly *below*
  the symmetric center (mildly bottom-heavy), **not** clipped. `[VERIFIED: certificate.ex:298,360-362,401,441]`
- Fixture body is **176 bytes** (`priv/examples/certificate/summit-training-institute/certificate.json`),
  ~3–4 wrapped lines at `measure_w = region_w * 0.68`. On A4-landscape (1123×794px gallery) the body
  region is generous; total content is a small fraction of region height. **No single-page overflow.**
- **Counter-intuitive:** on the themed path the recipient uses `scale.display = 21` (vs native 34) —
  i.e. themed content is *smaller*, further reducing overflow risk. The CONTEXT's "narrow `measure_w`"
  remedy would be **counterproductive** (narrower → more wrapping → taller). If any nudge is ever
  needed, the honest lever is the vertical-centering estimate, not `measure_w`.
- **Planner action:** the fit-check is a *visual confirmation of the rendered themed raster*, not a
  `validate_body!` assertion. Confidence the Certificate fits at 1.35: **HIGH**. `[VERIFIED]`

### GT-4 — `default/0` palette is already mined, zero-delta (D-01): **CONFIRMED**
- `@default_colors` (`theme.ex` L48-58) matches D-01 exactly: `ink {16,24,39}`, `muted {91,101,115}`,
  `accent {44,107,237}` (blue-600), `on_accent {255,255,255}`, `background {255,255,255}`,
  `surface {247,243,234}`, `rule {196,188,169}`, `positive {20,122,75}`, `negative {194,65,50}`.
- Recomputed WCAG contrast of `accent {44,107,237}` on white = **4.74:1** — matches D-01's "4.74:1 AA"
  claim to two decimals. `[VERIFIED: lib/rendro/theme.ex:48-58; contrast recomputed]`
- **No palette code change this phase.** DEFAULT-01's only value edit is `leading` (GT-2).

### GT-5 — Rubric manifest current state (D-02): **CONFIRMED**
- `priv/quality/rubric_scores.json` holds exactly **6 `passed:true` records** (invoice, statement,
  receipt, certificate, payslip, ticket), all `recorded_at: "2026-07-19"`, all with `content_hierarchy=5`
  + every other core ≥4 + both gates true. `justifications` cite measured native-scale glyph heights
  (e.g. certificate "Alex Rivera 34px vs title 26px"; invoice "Total Due $696.60 24px vs title 19px").
- `priv/schemas/rubric_scores.schema.json` `$defs/score_entry.required` = `[demo_id, domain, family,
  dimension_scores, gate_results, passed, recorded_at]` — the **sign-off fields are absent**;
  `additionalProperties: true`, so adding them is non-breaking.
- `test/docs_contract/rubric_manifest_contract_test.exs` `passed?/2` (L33-45) recomputes: hierarchy==5
  AND every other core ≥4 AND all gates true. The "recorded `passed` matches recomputation" test
  (L94-114) iterates `scores[]` — **this is exactly where the new sign-off teeth graft** (a second
  `for entry <- scores` loop asserting non-empty `signed_off_by`, a `signed_off_at`, and an
  `evidence_ref` that `File.exists?` AND is present in the hash-checked `artifacts.json` gallery).
- **Sign-off enforcement — two layers (do both, per D-02):**
  1. **Schema:** JSV `~> 0.18` (dev/test, `runtime: false`) supports draft-2020-12. Add a top-level
     `if/then` on `score_entry`: `"if": {"properties": {"passed": {"const": true}}, "required":
     ["passed"]}, "then": {"required": ["signed_off_by","signed_off_at","evidence_ref"]}` plus property
     type constraints (`signed_off_at` `format: date`). The schema-validation test (L47-50) then
     enforces it. *If JSV `if/then` proves finicky, the test-loop teeth are the load-bearing guard.*
  2. **Test teeth:** the new loop (above) is the definitive fail-loud-both-directions gate.
  `[VERIFIED: priv/quality/rubric_scores.json; priv/schemas/rubric_scores.schema.json:91-140; test/docs_contract/rubric_manifest_contract_test.exs:33-114]`

### GT-6 — Gallery manifest shape (D-03): **CONFIRMED**
- S6 tags: `@gallery_optional_s6_keys = ~w(theme mode preset)` (`launch_artifacts.ex` L29), validated
  null-or-string by `s6_seam_errors/2` (L673-687); intentionally NOT in `@gallery_required_keys` (L25)
  so absence never fails. `[VERIFIED: launch_artifacts.ex:29,673-687]`
- `expected_ids = Enum.map(@gallery_specs, & &1.id)` (L571) and the manifest ids must equal it in order
  (L620) — so **adding rows = adding `@gallery_specs` entries** (regen rewrites `artifacts.json`).
- `build_source_document/1` (L313-379) currently renders **no-theme** (`document(data)` /
  `document(data, border: true)`) — see Big Finding. New clauses needed:
  `build_source_document("invoice_dark")` → `Invoice.document(data, theme: Theme.dark(Theme.default()))`;
  `"certificate_dark"`, `"ticket_dark"` analogously; `"invoice_brand"` →
  `Invoice.document(data, theme: from_brand(accent: "#0E7C76"))`. Retag the 7 existing to thread
  `theme: Theme.default()`.
- `@expected_gallery_dimensions` (L30-40) is keyed by id; add entries for the 4 new ids
  (`invoice_dark`/`invoice_brand` `{794,1123}`, `certificate_dark` `{1123,794}`, `ticket_dark`
  `{397,560}`). Absent entries skip the dimension check (L657 `is_nil` branch) but adding is cleaner.
- `readme_block/1` (L217-246) currently renders **ALL** gallery entries — it has **no** hero filter.
  D-03's `readme_hero` needs implementing: either add a `readme_hero` field to manifest entries and
  filter in `readme_block/1`, or have `readme_block/1` look up `@gallery_specs` by id (discretion).
- `recipes_block/1` (L248-287) already renders all entries with both SHA-256s → matches "all 11 with
  SHA-256s." `guides/theming.md` will need its own gallery block (new markers `@recipes_start`-style,
  or hand-authored with the `# docs-contract:` fences for the executable examples).
- Regen/check flow: `mix rendro.launch_artifacts.gen` (regen PNGs + rewrite `artifacts.json`) and
  `mix rendro.launch_artifacts.check` (in `ci.advisory`; runs `static_contract_errors/0` +
  hash verification). Dark/brand PNGs are **net-new** hashed rasters. `[VERIFIED: launch_artifacts.ex; mix.exs:93-96]`

### GT-7 — `from_brand/2` E2E surface (D-04): **CONFIRMED**
- `from_brand/2` (`theme.ex` L266-299): `@spec from_brand(keyword(), keyword())`. `coerce_color` +
  `hex_to_rgb` (L383-394) convert `"#0E7C76"` → `{14,124,118}` at the boundary; the doctest (L259)
  uses the **tuple** form (`accent: {44,107,237}`). The hex-string keyword form `from_brand(accent:
  "#0E7C76")` is supported and matches the `@spec`, but is **not** itself in the shipped doctest — the
  guide fence is the first place it executes. `[VERIFIED: lib/rendro/theme.ex:265-299,383-394]`
- **on_accent derivation recomputed** (WCAG luminance, `on_accent_for/2` L339, picks the neutral pole
  with greater contrast):

  | Seed | Luminance | contrast vs white | contrast vs ink | Derived `on_accent` | CONTEXT claim |
  |------|-----------|-------------------|-----------------|---------------------|---------------|
  | teal-700 `#0E7C76` = `{14,124,118}` | 0.158 | 5.04 | 3.52 | **white** `{255,255,255}` | ✓ "≈0.16 → white" |
  | amber-300 `#E6B450` = `{230,180,80}` | 0.500 | 1.91 | 9.31 | **ink** `{16,24,39}` | ✓ "≈0.50 → ink" |
  | blue-600 default `{44,107,237}` | 0.172 | 4.74 | 3.75 | white | ✓ (default `on_accent` white) |

  `Theme.resolve(from_brand(accent:"#0E7C76")).colors.accent == {14,124,118}` — the exact assertion
  D-04 specifies for the orthogonality fence. Both derivations prove the heuristic **both ways**.
  `[VERIFIED: on_accent_for/2, luminance/1, linearize/1; recomputed]`
- Orthogonality is in-memory assertable: `BrandedInvoice.document/2` registers assets from `data.brand`
  (`%{font_name:, logo_name:}`), while `from_brand` "emits tokens only, registers nothing" (moduledoc
  L253-255). The fence asserts `font_registry.fonts[:brand_heading]` + `asset_registry.assets[:company_logo]`
  AND `Theme.resolve(theme).colors.accent == {14,124,118}` AND that `from_brand(...)` returns a bare
  `%Theme{}` with no registry side-effect — all without rendering to disk (see GT-8 evaluator limits).

### GT-8 — Hex-tarball / docs-contract lanes (CONTRACT-02): **CONFIRMED (with a "no new asset" nuance)**
- **Marker harness** (`test/support/docs_contract.ex`): `verified_fences(path)` scans ` ```elixir `
  fences and requires each to carry `# docs-contract: <id>` (raises otherwise). `evaluate!(code, file)`
  prepends `import ExUnit.Assertions`, **blocks** `File.write*/rm*/mkdir*/cp*`, `System.cmd`, and
  `Mix.Task.run/clear`, then `Code.eval_quoted`. **So fences may use `assert`/`refute` — a raising
  assertion fails the contract test — but may NOT render a PDF to disk or shell out.** All D-04 proofs
  must be pure in-memory struct/registry assertions. `[VERIFIED: test/support/docs_contract.ex]`
- **Per-guide contract test pattern** (`branding_contract_test.exs`): asserts the exact fence-ID list
  in order, `length == N`, no `...`/`%{...}` skeletons, and `evaluate!` each. Phase 123 adds a
  **new `test/docs_contract/theming_contract_test.exs`** mirroring it for `guides/theming.md`.
- **MUST FLIP:** `theming_claims_test.exs` L163-165 currently asserts `refute File.exists?("guides/theming.md")`
  ("deferred to Phase 123"). Phase 123 removes/inverts this and adds the proof-backed support-matrix
  assertions. `[VERIFIED: test/docs_contract/theming_claims_test.exs:163-165]`
- **Support matrix** already has `theming.light` + `theming.dark` (with `status`, `capabilities`,
  boundary keys all `"unsupported"`); `theming_claims_test.exs` guards the overclaim tripwire.
  CONTRACT-02's "proof-backed" work = ensure each new *claim* the guide makes has a matching matrix
  row / test binding; do not add any `supported*` status to a print/PDF-UA/WCAG boundary key.
  `[VERIFIED: priv/support_matrix.json theming section]`
- **Tarball nuance — "no new asset ships" is precise, not literal.** `mix.exs` `package.files`
  (L114-127) ships `lib`, `assets/rendro`, `priv/branded`, `priv/examples`, `guides`, etc.
  Consequently: the 4 new gallery PNGs under `assets/rendro/gallery/` **DO ship** (normal gallery
  growth), and **`guides/theming.md` ships**. What must stay **excluded** (the tripwire in
  `branding_claims_test.exs` L72-85): `priv/quality/` (rubric_scores.json + SIGN-OFF.md),
  `priv/support_matrix.json`, `priv/schemas/rubric_scores.schema.json`, `priv/goldens/`,
  `priv/raster_refs/`. **The honest reading of "no new asset ships": no new `priv/branded` font/logo
  or runtime-consumed binary, and no operator-only artifact leak.** The theme mechanism ships as pure
  `lib/` code. Flag this to the planner so it does not mistakenly try to keep the 4 PNGs out of the
  tarball. `[VERIFIED: mix.exs:110-127; test/docs_contract/branding_claims_test.exs:41-86]`
- **Docs wiring:** adding `guides/theming.md` likely requires updating `mix.exs` `docs` `extras:`
  (L157-171), `skip_undefined_reference_warnings_on` (L139-145), and `groups_for_extras` (L172+), or
  `mix docs --warnings-as-errors` (in `ci.fast`) may warn. Verify against any test that enumerates the
  extras list.

## The Big Finding (elevated — planner MUST budget for this)

**Threading `theme: Rendro.Theme.default()` swaps each recipe's type scale, not just leading.**

Each recipe hard-codes a *native* type-scale literal map in its no-theme `typography/1` branch; every
one differs from the theme default, and every recipe reads `type.scale.*`:

| scale step | theme default | invoice | statement | receipt | payslip | ticket | certificate | branded_invoice |
|------------|--------------|---------|-----------|---------|---------|--------|-------------|-----------------|
| display | **21** | 20 | 22 | 18 | 27 | 8 | **34** | 18 |
| title | **16.5** | 18 | 14 | 16 | 13 | 26 | 20 | 12 |
| subtitle | **13** | 12 | 12 | 14 | 11 | 16 | 12 | 11 |
| body | **10.5** | 10 | 10 | 12 | 10 | 10 | 11 | 10 |
| small | **9** | 9 | 9 | 10 | 9 | 9 | 10 | 9 |

`[VERIFIED: grep of `scale: %{` across lib/rendro/recipes/*.ex + theme.ex:77]`

Consequences the planner must plan around:
1. **All 7 retagged rows re-bless** (type sizes shift), not just the 3 prose rows. D-03's "non-prose
   rows stay byte-identical" is **CONTRADICTED**. This is consistent with D-02's own statement that
   `default/0` + Phase-122 typography "changed **every** demo's pixels," so it does not break the
   decision — it corrects the byte-impact accounting inside D-03.
2. **The honest re-score deltas change substantially.** The 2026-07-19 justifications cite native-scale
   glyph heights (34px, 24px…). At the themed scale those numbers are wrong. Commit 2 must **pre-compute
   fresh glyph-height deltas from the themed rasters**; Commit 3 records them.
3. **Certificate `content_hierarchy == 5` is the #1 honesty risk.** Native recipient/title = 34/20
   (ratio 1.70); themed = 21/16.5 (ratio 1.27). The recipient is still the largest element, but far
   less dominant. The anchor "key fact dominant AND every other element recedes to one unambiguous
   focal point" is genuinely arguable at 1.27. If the themed Certificate does not honestly clear
   `== 5`, the honest response is to strengthen emphasis via the Phase-122 display anchor **in Commit 2**
   (or accept a `content_hierarchy: 4` → `passed: false` and surface it), **never** flip the score in
   Commit 3. This is exactly the trap the phase exists to avoid.
4. The 7 no-theme recipe **byte-identity goldens in `test/` remain untouched** (they render
   `document(data)` on the literal path, which never reads `default/0`) — D-03 is correct there, and
   `certificate.ex` L527-528 confirms the no-theme branch must never read `Theme.default().typography`.

**Recommendation:** proceed with D-03 as decided (render themed so the "default" tag is literally
true), but (a) plan a full 7-row re-bless in Commit 2, (b) re-measure all 6 hierarchy deltas against
themed bytes, and (c) treat the Certificate hierarchy as a checkpoint the human sign-off must honestly
confront before Commit 3.

## Standard Stack

**Zero new dependencies** (per REQUIREMENTS "New runtime/optional/dev dependencies" = out of scope).
All work uses Elixir stdlib + the existing surfaces:

| Surface | Role in this phase |
|---------|--------------------|
| `Rendro.Theme` (`lib/rendro/theme.ex`) | `leading` edit (L79); `from_brand/2` already shipped |
| `Rendro.Recipes.*` | read `type.scale.*` / `type.leading` on the themed path |
| `Rendro.LaunchArtifacts` + `mix rendro.launch_artifacts.gen/check` | gallery specs, S6 tags, regen/hash |
| pinned pdfium lane (`priv/pdfium_pin.json` v0.11.0, `test/support/pdfium_cli.ex`) | deterministic PNG rasters (sign-off evidence == gallery bytes) |
| `Rendro.Test.DocsContract` (`test/support/docs_contract.ex`) | executes `guides/theming.md` fences |
| `jsv ~> 0.18` (dev/test, `runtime: false`) | draft-2020-12 schema validation (add `if/then`) |
| `JSON` (stdlib) | manifest read/decode in tests |

**No `npm install` / package fetch. No package-legitimacy audit required** (no external packages added).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rubric pass/fail | A new `passed` field asserted independently | `passed?/2` recomputation (test L33-45) | SHOW-01's original failure mode was an independently-asserted `passed:true`; the recompute is the honesty gate. |
| Sign-off enforcement | Ad-hoc "trust the human" comment | Schema `if/then` + test-loop teeth + git trailer | D-02 mandates machine-enforced + human-legible + provenance. |
| Guide E2E test | A standalone `theme_e2e_test.exs` | `# docs-contract:` fences + `theming_contract_test.exs` | D-04: the guide fence IS the test; a duplicate drifts from the docs. |
| on_accent contrast | Re-deriving WCAG math in the guide | Assert the *derived tuple* (`== {14,124,118}` / `{16,24,39}`) | The derivation is private/deterministic; assert the output, not the algorithm. |
| Gallery raster diffing | Manual PNG compare | `mix rendro.launch_artifacts.gen/check` + sha256 in `artifacts.json` | Existing hash-checked pipeline; deterministic. |
| Vertical fit "fix" for cert | Narrowing `measure_w` | Nothing (risk is LOW) or the centering estimate | Narrowing `measure_w` increases wrapping → taller, counterproductive (GT-3). |

**Key insight:** almost everything this phase needs already exists as a proven guard; the work is
*additive graft* onto honesty machinery, not new infrastructure.

## Common Pitfalls

### Pitfall 1: Reusing the 2026-07-19 glyph-height deltas in the re-score
**What goes wrong:** the sign-off cites native-scale numbers (34px, 24px) that no longer describe the
themed rasters. **Why:** the theme scale swaps every recipe's sizes (Big Finding). **How to avoid:**
pre-compute fresh deltas from the themed pdfium rasters in Commit 2. **Warning sign:** a justification
number that matches the old record exactly.

### Pitfall 2: Flipping the Certificate score without confronting the compressed hierarchy
**What goes wrong:** themed Certificate hierarchy ratio drops 1.70→1.27; a rubber-stamp keeps
`content_hierarchy: 5`. **Why:** the display shrink (34→21) is invisible unless measured. **How to
avoid:** measure recipient-vs-title glyph height on the themed raster; if not honestly dominant,
strengthen the anchor in Commit 2 or record `4`/`passed:false`. **Warning sign:** an unchanged verdict
on a changed render.

### Pitfall 3: Trying to keep the 4 new gallery PNGs out of the tarball
**What goes wrong:** wasted effort / broken `files:` allowlist chasing a literal "no new asset." **Why:**
`assets/rendro` ships by design (GT-8). **How to avoid:** keep only `priv/quality`/`support_matrix`/
`rubric-schema` excluded; let the PNGs + `guides/theming.md` ship. **Warning sign:** editing
`package.files` to exclude `assets/rendro/gallery`.

### Pitfall 4: A docs-contract fence that renders to disk or shells out
**What goes wrong:** `evaluate!` raises "cannot perform File.write / System.cmd / Mix.Task.run". **Why:**
the evaluator blocks side effects (GT-8). **How to avoid:** keep fences in-memory (build `%Document{}`,
assert on `font_registry`/`asset_registry`/`Theme.resolve(...)`); prove the *visual* accent via the
`invoice_brand` gallery row, not a fence render. **Warning sign:** `Rendro.render(...) |> File.write`.

### Pitfall 5: Forgetting the hard-coded gallery count and the `guides/theming.md` non-existence guard
**What goes wrong:** `launch_artifacts_claims_test.exs` L12 ("exactly the seven recipe previews") and
`theming_claims_test.exs` L163 (`refute File.exists?("guides/theming.md")`) fail. **How to avoid:**
update the L12 id-list to the 11 ordered ids; remove/invert the L163 guard. **Warning sign:** a red
docs-contract lane on an otherwise-complete change.

## Code Examples

### `from_brand` E2E fence (in-memory, assertive — the pattern for `guides/theming.md`)
```elixir
# docs-contract: theming-accent-only
import ExUnit.Assertions

theme = Rendro.Theme.from_brand(accent: "#0E7C76")
resolved = Rendro.Theme.resolve(theme)

# accent seed coerced hex -> tuple
assert resolved.colors.accent == {14, 124, 118}
# on_accent derived to white (teal luminance ~0.16 -> greater contrast vs background)
assert resolved.colors.on_accent == {255, 255, 255}
```

### Both-ways contrast proof (amber -> ink)
```elixir
# docs-contract: theming-accent-contrast-both-ways
import ExUnit.Assertions

amber = Rendro.Theme.resolve(Rendro.Theme.from_brand(accent: "#E6B450"))
assert amber.colors.on_accent == {16, 24, 39}   # ink, because amber is light (lum ~0.50)
```

### Orthogonality (assets via `data.brand`, accent via `theme:`) — BrandedInvoice
```elixir
# docs-contract: theming-brand-orthogonal
import ExUnit.Assertions

data = %{ ... }  # planner: use a minimal valid branded-invoice map (no "..." in the shipped fence)
data = Map.put(data, :brand, %{font_name: :brand_heading, logo_name: :company_logo})
theme = Rendro.Theme.from_brand(accent: "#0E7C76")

doc = Rendro.Recipes.BrandedInvoice.document(data, theme: theme)
assert Map.has_key?(doc.font_registry.fonts, :brand_heading)   # assets registered by document/2
assert Map.has_key?(doc.asset_registry.assets, :company_logo)
assert Rendro.Theme.resolve(theme).colors.accent == {14, 124, 118}  # accent via theme, orthogonal
```
> Note: the shipped fence must contain a real, evaluable `data` map — `DocsContract.evaluate!` rejects
> `...`/`%{...}` skeletons and the contract test asserts their absence. Verify the exact
> `font_registry`/`asset_registry` field paths against the existing `BrandedInvoice.document/2` doctest.

### Rubric sign-off record shape (append to each `scores[]` entry, Commit 3)
```json
{
  "demo_id": "invoice-acme-phoenix-saas",
  "...": "existing fields unchanged",
  "signed_off_by": "qiksnare13",
  "signed_off_at": "2026-07-28",
  "evidence_ref": "assets/rendro/gallery/invoice.png"
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib), `async: true` throughout `test/docs_contract/` |
| Config file | `test/test_helper.exs` (+ `.formatter.exs`) |
| Quick run command | `mix test test/docs_contract/<file>.exs` |
| Full suite command | `mix test --exclude quarantine` (mirrors `ci.fast`) |
| Gallery regen/verify | `mix rendro.launch_artifacts.gen` then `mix rendro.launch_artifacts.check` |
| Tarball lane | `mix hex.build` (in `ci.fast`; `branding_claims_test` reads the build output) |
| Advisory raster lane | `mix ci.advisory` (raster snapshot + `launch_artifacts.check` + audits) |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | Exists? |
|-----|----------|-----------|-------------------|---------|
| DEFAULT-02 (data) | invoice transform yields issuer/customer/totals | unit | `mix test test/rendro/examples_data_test.exs` (add assertion) | ❌ Wave 0 (new test) |
| DEFAULT-01 (leading) | themed recipes emit `line_height: 1.35`; no-theme goldens unchanged | golden/unit | `mix test test/rendro/recipes/*` (existing byte goldens must stay green) | ✅ |
| DEFAULT-01 (from_brand) | accent coerce + on_accent both-ways | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ❌ Wave 0 (new) |
| DEFAULT-02 (re-score) | recorded `passed` == recomputation; sign-off fields present + evidence exists & is manifest-covered | docs-contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ✅ (add teeth) |
| DEFAULT-03 (gallery) | 11 ordered rows; S6 tags valid; hashes match | docs-contract + advisory | `mix test test/docs_contract/launch_artifacts_claims_test.exs` + `mix rendro.launch_artifacts.check` | ✅ (update count 7→11) |
| CONTRACT-02 (guide) | fence IDs in order + evaluable | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ❌ Wave 0 (new) |
| CONTRACT-02 (matrix) | theming rows proof-backed; no overclaim; `guides/theming.md` exists | docs-contract | `mix test test/docs_contract/theming_claims_test.exs` | ✅ (flip L163 + add) |
| CONTRACT-02 (tarball) | `priv/quality`/`support_matrix`/rubric-schema excluded; assets+guides ship | docs-contract | `mix test test/docs_contract/branding_claims_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** the touched `test/docs_contract/<file>.exs` + any affected recipe golden.
- **Per wave merge:** `mix test --exclude quarantine` + `mix rendro.launch_artifacts.check`.
- **Phase gate:** `mix ci.fast` green (includes `hex.build` tarball lane + `docs --warnings-as-errors`)
  and `mix ci.advisory` green (gallery hash + raster) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/docs_contract/theming_contract_test.exs` — NEW; mirrors `branding_contract_test.exs`,
      asserts `guides/theming.md` fence IDs in order + `evaluate!` each (covers DEFAULT-01/CONTRACT-02).
- [ ] `guides/theming.md` — NEW; `# docs-contract:` fences (accent-only, both-ways contrast, orthogonal)
      + an 11-row gallery block with SHA-256s.
- [ ] Data-survival test (invoice issuer/customer/totals) — NEW (Commit 1); may extend
      `test/rendro/examples_data_test.exs` if present, else a small new file.
- [ ] Rubric sign-off teeth — extend `rubric_manifest_contract_test.exs` (new `for entry` loop) +
      schema `if/then`.
- [ ] `priv/quality/SIGN-OFF.md` — NEW (SCORECARD house style).
- [ ] Update `launch_artifacts_claims_test.exs` L12 count 7→11; invert `theming_claims_test.exs` L163.
- [ ] `mix.exs` `docs` extras/skip-warnings for `guides/theming.md`.

## Security Domain

`security_enforcement` is absent in `.planning/config.json` (treated as enabled), but this is a
pure-code, offline PDF-document library phase with **no** auth, session, network, DB, or user-facing
input surface. ASVS applicability:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | minimal | `from_brand` hex input is coerced by `Base.decode16!` + validated by `Rendro.Color.validate/1` at `resolve/1`; malformed hex raises (errors-as-product). No new input surface added. |
| V6 Cryptography | no | sha256 here is content-addressing (gallery/manifest integrity), not a security control. |
| V2/V3/V4/others | no | no authn/session/access-control surface in a static PDF library. |

The docs-contract `evaluate!` sandbox (blocks `File.write*`/`System.cmd`/`Mix.Task.run`) is the one
security-adjacent control touched — keep guide fences side-effect-free so it stays effective.

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| Rubric verdict as a standalone `passed:true` | `passed?/2` recomputation from each entry's dims/gates | Phase 118 SHOW-01 fix | A verdict can't be asserted independently; sign-off fields extend this. |
| Gallery = 7 no-theme rows, `theme:null` | 11 rows, themed/dark/brand, S6-tagged, `preset:null` | Phase 123 (this) | First time the theme scale hits the demos → full re-bless. |
| `guides/theming.md` absent (guarded) | Executable guide + `theming_contract_test.exs` | Phase 123 | The from_brand E2E proof rides the docs. |

**Deprecated/outdated:** none removed. The certificate module comment (`certificate.ex` L527-528)
explicitly warns against the anti-pattern of reading `Theme.default().typography` on the no-theme path.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | JSV `~> 0.18` supports draft-2020-12 `if/then` for conditional `required` | GT-5 | If it doesn't, schema-level enforcement falls back to the test-loop teeth (still fully enforced) — LOW. |
| A2 | Adding `guides/theming.md` requires `mix.exs` `docs` extras/skip-warnings edits to keep `docs --warnings-as-errors` green | GT-8 | If not required, an unnecessary edit — LOW; verify by running `mix docs`. |
| A3 | `doc.font_registry.fonts` / `doc.asset_registry.assets` are the exact field paths for the orthogonality fence | Code Examples | If paths differ, the fence assertion fails loudly at plan time — confirm against the live `BrandedInvoice.document/2` doctest before authoring — LOW. |
| A4 | The Certificate honestly clears `content_hierarchy == 5` at the themed scale | Big Finding, Pitfall 2 | If it does NOT, the plan needs an emphasis adjustment in Commit 2 (or an honest `4`/`passed:false`). This is the phase's real open risk — MEDIUM. Must be measured, not assumed. |

## Open Questions

1. **Does the themed Certificate honestly earn `content_hierarchy == 5`?**
   - What we know: recipient/title ratio drops from 1.70 (native 34/20) to 1.27 (themed 21/16.5); body
     fits (176 bytes, no overflow); the display anchor is wired.
   - What's unclear: whether 1.27 dominance reads as "one unambiguous focal point" against the rubric
     anchor — only the rendered themed raster (Commit 2) resolves it.
   - Recommendation: make this an explicit checkpoint in Commit 2 (measure before scoring). If short,
     strengthen the display anchor there; do not touch the score in Commit 3 to compensate.

2. **`readme_hero` filter placement.** `readme_block/1` takes the manifest (no `readme_hero` field
   today). Add `readme_hero` to manifest entries (S6-tolerant, additive) or cross-reference
   `@gallery_specs` by id. Recommendation: add `readme_hero` to `@gallery_specs` and have `gen` emit it
   into `artifacts.json` so `readme_block/1` filters purely on the manifest (no spec lookup at doc time).

3. **One slice or split-by-requirement?** The D-05 three-commit order is a hard constraint regardless.
   Recommendation: one phase slice with three commits (data → theme+gallery → score-flip), since the
   gallery re-bless and the re-score share the same themed rasters and must not drift.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | all | ✓ (repo builds) | project mix | — |
| pdfium (pinned) | gallery rasters + sign-off evidence | ✓ | `priv/pdfium_pin.json` v0.11.0 | none — the advisory lane owns raster regen |
| jsv | rubric schema validation | ✓ | `~> 0.18` (dev/test) | test-loop teeth |
| npm/node | `ci.advisory` pdfjs observer only (not this phase's core) | n/a | — | not on the phase's critical path |

**Missing dependencies with no fallback:** none identified for the core theming/rubric/gallery work.

## Sources

### Primary (HIGH confidence — live code, verified this session)
- `lib/rendro/theme.ex` — palette L48-58, typography/leading L75-81, `from_brand/2` L266-299,
  `on_accent_for`/`luminance`/`linearize` L339-378, `coerce_color`/`hex_to_rgb` L383-394.
- `lib/rendro/examples_data.ex` — `transform_invoice/1` L36-63 (issuer/customer/totals put_optional).
- `lib/rendro/recipes/certificate.ex` — `@line_height 1.2` L298, `content_height_estimate` L360-362,
  `centered_paragraph` L433/L441, `typography/1` no-theme branch L537-554, `validate_body!/1` L717-731.
- `lib/rendro/launch_artifacts.ex` — S6 keys L29, expected dims L30-40, specs L47-125,
  `build_source_document/1` L313-379, `readme_block`/`recipes_block` L217-287, `expected_ids` L571,
  shape/s6 errors L620-687.
- `priv/quality/rubric_scores.json` (6 records, 2026-07-19); `priv/schemas/rubric_scores.schema.json`
  L91-140; `test/docs_contract/rubric_manifest_contract_test.exs` L33-114.
- `test/support/docs_contract.ex` (fence extraction + sandboxed `evaluate!`);
  `test/docs_contract/branding_contract_test.exs`; `test/docs_contract/theming_claims_test.exs` L163;
  `test/docs_contract/branding_claims_test.exs` L41-86 (tarball); `test/docs_contract/launch_artifacts_claims_test.exs` L12.
- `mix.exs` — `package.files` L110-127, `docs` extras L157-191, `aliases` L75-108.
- Recomputed WCAG luminance/contrast for teal-700, amber-300, blue-600 (Python, this session).

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` (DEFAULT-01/02/03, CONTRACT-02); `.planning/STATE.md` SHOW-01 note;
  `.planning/ROADMAP.md` §Phase 123.

### Tertiary (LOW confidence)
- JSV `if/then` draft-2020-12 support (A1) — training knowledge; verify empirically when authoring the schema.

## Metadata

**Confidence breakdown:**
- Ground truth (data, palette, leading, from_brand, rubric, gallery, docs-contract): HIGH — every claim
  checked at file:line; math recomputed.
- Certificate fit-check: HIGH that overflow risk is LOW; MEDIUM on whether hierarchy honestly clears 5.
- Big Finding (type-scale swap on retag): HIGH — verified across all 7 recipes + theme.

**Research date:** 2026-07-28
**Valid until:** ~2026-08-27 (stable in-repo code; re-verify if Phases 119-122 artifacts change).

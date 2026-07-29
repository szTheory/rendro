# Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

The **honest closure phase** for the v2.11 Document Theming milestone (Milestone B).
Land the theming contract truthfully — a strong unbranded `default/0`, `from_brand/2`
end-to-end, the Phase-118 SHOW-01 rubric gap closed **in the honest order (fix DATA →
apply theme → re-score with human sign-off)**, themed + dark gallery rows, and
`guides/theming.md` + support-matrix proof — with every theming claim proof-backed and
all lanes green. Requirements: DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02.

**The named trap this phase MUST avoid:** apply a slick accent palette, declare the
demos prettier, and flip a rubric score to `passed:true`. A better palette raises
*typographic craft* and *restraint/cohesion* — which were **NOT** the failing dimensions.
Hierarchy and information-architecture failures come from what DATA is present and what
is emphasized, so the fix is data-and-emphasis first, color second.

**In scope:**
- **`default/0` finalization** (DEFAULT-01): lock the already-mined neutral palette; realize
  the deferred `leading: 1.35` prose leading (the Phase-122 parked one-line change).
- **Honest SHOW-01 closure** (DEFAULT-02): verify/attest the DATA fix, confirm the display
  anchor makes the one key fact dominant, apply `default/0`, re-score all 6 rubric demos
  against the Milestone-A rubric with **human sign-off**, committed only on an honest clear.
- **Gallery closure** (DEFAULT-03): populate S6 `theme`/`mode` tags with themed + dark
  renders — 11 curated blessed rows, hash-checked; `preset` stays `null`.
- **`from_brand/2` E2E** (DEFAULT-01 second half): prove accent-seed theming end-to-end with
  `brand:` assets orthogonal, via a gallery render + an executable `guides/theming.md` example.
- **Docs/manifest closure** (CONTRACT-02): proof-back the `support_matrix.json` `theming.*`
  rows, add `guides/theming.md` + a claims test binding every theming claim to proof; keep
  docs-contract + Hex-tarball lanes green (theme is pure code — **no new asset ships in the tarball**).

**Out of scope (later milestones):**
- Genre/style presets, public example catalog, static configurator, curated preset fonts →
  Milestone C (`SEED-004`). `preset` stays `null` on every gallery row.
- Live Studio (LiveView playground) → Milestone D (`SEED-005`).
- Any new `%Theme{}` field, the deterministic engine core, the public-API tier shape
  (all frozen in Phases 119–122).
- Permanent theme-contract exclusions stay excluded by construction (shadow/elevation,
  z-index, motion, focus/hover, opacity/gradient, raw color scales, weight axis,
  letter-spacing, wide-gamut).

**Grounding correction (do not re-litigate):** the "fix DATA first" step is a
**verify-and-attest**, not a from-scratch rescue. `Rendro.ExamplesData.transform_invoice/1`
**already** `put_optional`s `:issuer`/`:customer`/`:totals` (restored in Phase 115), the
fixture `priv/examples/invoice/acme-phoenix-saas/invoice.json` carries all three, and the
"one key fact structurally dominant" lever is **already wired** via the Phase-122 `display`
anchor. The honest ORDER still holds and MUST be provable in git (see D-05), but the data is
present — the phase confirms it survived and locks a test asserting it.

</domain>

<decisions>
## Implementation Decisions

User directive: research-first, one-shot — all 4 selected gray areas were researched in
parallel (4 `gsd-advisor-researcher` agents, full lens stack: Elixir/ecosystem idiom,
lessons from comparable libs, DX/API-consumer perspective, brand/JTBD, design pillars,
honesty discipline) against the **living `brand/` system** (authoritative; newer than
`prompts/Rendro Brand Book.txt`) + the actual code, and locked as a coherent set. Per the
settled Rendro posture and the Phase 119–122 precedent of zero-deferral locked recommendations.

### D-01 — `default/0` palette LOCKED AS-IS; realize `leading: 1.35` (DEFAULT-01)
- **Palette: zero deltas.** All nine roles trace faithfully to a `brand/tokens/tokens.json`
  `semantic.light` alias and are AA-or-better on white for every role used as text:
  `ink {16,24,39}`=ink-900/text-primary (17.8:1, AAA), `muted {91,101,115}`=ink-500/text-muted
  (~5.3:1, AA), `accent {44,107,237}`=blue-600/action-primary-bg (as a **fill** with white
  `on_accent` = 4.74:1, AA), `on_accent {255,255,255}`, `background {255,255,255}` (forced
  white — MODE-02 gate), `surface {247,243,234}`=paper-100 (the subtlest warm band — the
  honest flat-elevation surface on a white page), `rule {196,188,169}`=line-400 (a deliberately
  quiet ~1.9:1 separator, not a graphic), `positive {20,122,75}`=green-700 (AA),
  `negative {194,65,50}`=red-700 (AA).
- **Keep `accent` = blue-600, NOT blue-700.** blue-600 IS the token's `accent`/`action-primary-bg`
  semantic; blue-700 is bound to `accent-strong`/`text-link`/hover. Swapping would unmine the
  actual `accent` alias, desync `from_brand/2` (which swaps only accent/on_accent — the default
  must be the brand's own accent), and collapse the accent/accent-strong distinction.
  **Recipe-usage guard (carry forward, NOT a token change):** `accent` is a fill/large-text
  role — recipes must not use it as *small* text on the warm `surface` band (4.28:1 there).
- **Realize `leading: 1.2 → 1.35`** in `@default_typography` (the single deferred one-line change,
  parked from 119-R1/122-D-03). Sits in the Swiss print-prose band (1.3–1.45), generous per
  Brand Book §9, not the SaaS-hero 1.5+ the book forbids. The seam is already uniform from
  Phase 122; single-line runs stay byte-identical (line_height is a no-op on single lines) —
  only wrapped multi-line **prose** re-flows.
- **The entire re-bless surface (themed path only):** Certificate body citation
  (`centered_paragraph`, `certificate.ex` ~L433), Invoice + BrandedInvoice `"Terms: …"`
  (`invoice.ex` ~L474 / `branded_invoice.ex` ~L287), Ticket terms (`ticket.ex` ~L581).
  **Verify** the themed Certificate still satisfies `validate_body!/1` single-page A4-landscape
  at 1.35 (body grows ~12.5% taller) — narrow `measure_w` or accept pagination if needed.
  — **Reversibility:** reversible — palette + leading are Evolving-tier VALUES under a frozen
  field shape; every value is proof-backed (token alias + recomputed contrast + Brand Book §9);
  any retune is a pure data change with no contract break.

### D-02 — Honest re-score of ALL 6 rubric demos with machine-enforced human sign-off (DEFAULT-02)
- **Scope: re-score all 6 families** (invoice/statement/receipt/certificate/payslip/ticket),
  NOT invoice-only. `default/0` + Phase-122 typography changed **every** demo's pixels, so the
  6 existing `passed:true` records in `priv/quality/rubric_scores.json` (recorded 2026-07-19
  against **un-themed v2.10** renders) now cite counterfactual rasters. An unchanged *verdict*
  on a changed *render* is still an unproven claim → all 6 re-validated against the current
  themed `default/0` bytes. **Do NOT touch the frozen threshold arithmetic** (`hierarchy==5,
  core≥4, gates true`) — a green demo must clear the *unchanged* bar.
- **Sign-off mechanism (machine-enforced + human-legible):**
  - Add to each `scores[]` record: `signed_off_by` (e.g. `"qiksnare13"`), `signed_off_at`
    (ISO date), `evidence_ref` (path to a hash-checked gallery PNG governed by `artifacts.json`);
    keep the existing measured-raster `justifications`.
  - Update `priv/schemas/rubric_scores.schema.json` to **require** those three fields whenever
    `passed == true`.
  - Add teeth to `test/docs_contract/rubric_manifest_contract_test.exs`: every `passed:true`
    entry must have non-empty `signed_off_by`, a `signed_off_at`, and an `evidence_ref` that
    **exists AND is covered by the hash-checked artifact manifest**. Fail loud both directions
    (a `passed:true` without a live hash-checked `evidence_ref` fails the build).
  - Author `priv/quality/SIGN-OFF.md` in the **`brand/audit/SCORECARD.md` house style**
    (dated, per-demo, "Honest not flattering"), each demo citing the measured key-fact glyph
    height vs next-largest element + the rubric anchor language it satisfies.
  - Additive `Signed-off-by: qiksnare13 <qiksnare13@gmail.com>` git trailer on the score commit.
- **Evidence the user reviews (pre-computed, THEN judged — avoids rubber-stamp fatigue):**
  (1) the 6 deterministic pdfium PNG rasters of the current themed `default/0` (light) demos —
  the *same bytes* that ship in the gallery, via the pinned pdfium lane (`priv/pdfium_pin.json`
  / `test/support/pdfium_cli.ex`); (2) per demo, a measured glyph-height delta (key-fact anchor
  vs next-largest element) substantiating `content_hierarchy == 5`; (3) for the invoice, a
  before/after confirming parties + totals present (the Phase-115 DATA fix survived).
  — **Reversibility:** reversible — `rubric_scores.json` is an appendable S5 manifest; a
  regretted pass reverts by rolling back the score-flip commit alone (D-05 split guarantees the
  data + theme commits stand independently). New fields/tests are additive; nothing touches the
  engine core or public-API tier.

### D-03 — Gallery: 11 curated blessed rows (hybrid, additive), flagship Invoice triptych (DEFAULT-03)
- **11 rows total** = keep + retag the **7 light/default** rows + **3 targeted dark** + **1
  `from_brand` accent showcase**. Right-sizes proof vs. brand-restraint showcase (the
  mechanism-level "dark works on all 7 / theming universal" proof already lives in Phase 121's
  determinism goldens + the `theming.*` support-matrix rows — the gallery's job is *showcase,
  not exhaustive re-proof*; the exhaustive 26–28-cell matrix reads as a CI test-grid and
  violates brand restraint per `brand/copy/VOICE.md`).
- **Additive, never replace.** The 7 existing light rows are the rubric-scored SHOW-01 lineup.
  Retag `theme: null → "default"` in place; append the 4 new rows. `artifacts.json` diff =
  7 tag flips + 4 appended entries (diff-auditable).
- **Row set:**
  - **7 light/default** (retag; render via `theme: Rendro.Theme.default()` so the `"default"`
    tag is literally true): `invoice`, `branded_invoice`, `statement`, `receipt_report`,
    `certificate`, `payslip`, `ticket` — each `theme:"default"`, `mode:"light"`, `preset:null`.
  - **3 dark** (net-new rasters; recipes that shine dark + span the geometry range):
    `invoice_dark` (flagship portrait+table), `certificate_dark` (landscape/ceremonial — dark
    reads premium; the 121 landscape geometry proof), `ticket_dark` (A6 screen-native — dark is
    a boarding-pass's habitat). Each `theme:"default"`, `mode:"dark"`, `preset:null`.
  - **1 `from_brand` showcase** (net-new raster): `invoice_brand` = Invoice via
    `from_brand(accent: "#0E7C76")` (teal-700) — **accent-only, no assets**, to isolate the
    pure accent effect and complete the flagship **Invoice triptych** (default / dark / brand).
    `theme:"brand"`, `mode:"light"`, `preset:null`.
- **Byte-impact of the retag (coherence with D-01):** threading `theme: default()` into the 7
  "default" rows is byte-neutral for colors (default/0 keeps colors identical) BUT `leading:1.35`
  re-flows the **prose-bearing** rows (invoice/branded_invoice/certificate, and ticket if terms
  wrap) → those PNGs re-bless. Non-prose rows (statement/receipt/payslip) stay byte-identical.
  This gallery re-bless is folded into the **same human-signed bless** as D-02 (the sign-off
  rasters ARE these gallery renders) — never a separate hidden re-bless. The 7 no-theme **recipe
  byte-identity goldens** (`test/`) stay UNTOUCHED (they render `document(data)` on the literal
  1.2 path, which never reads `default/0`).
- **README hero-subset vs full manifest:** add a `readme_hero: true` flag to `@gallery_specs`.
  README shows the 7 light lineup + a labeled "Theming: default · dark · brand" strip
  (`invoice_dark` + `invoice_brand`, ~9 thumbnails) with an honest "dark is screen-oriented, not
  print-recommended" caption; `guides/recipes.md` + `guides/theming.md` show all 11 with SHA-256s
  (`certificate_dark`/`ticket_dark` live there); `artifacts.json` is the full 11-row source of truth.
- **S6 tag shape (zero re-keying for Milestone C, by construction):** `theme` ∈ {`"default"`
  ×10, `"brand"` ×1}; `mode` ∈ {`"light"`,`"dark"`}; `preset` = `null` on **all 11** (independent
  validated key; Milestone C's genre grid populates it without touching `theme`/`mode`).
  Dark rows carry captions/alt echoing the support-matrix screen-oriented boundary.
  — **Reversibility:** reversible — every row regenerates from `@gallery_specs`; tags are
  additive strings, no schema migration; dropping a row is a spec deletion + regen.

### D-04 — `from_brand/2` E2E via gallery render + executable guide example (DEFAULT-01 / CONTRACT-02)
- **Build surface = combination (gallery render + `guides/theming.md` worked example), where the
  guide's `# docs-contract:` markers make the example execute as the E2E test** — do NOT add a
  separate standalone integration test (the docs-contract execution IS the test; a duplicate
  would drift from the docs).
- **Headline consumer one-liner (JTBD-optimal, hides `on_accent` derivation):**
  ```elixir
  Rendro.Recipes.Invoice.document(data, theme: Rendro.Theme.from_brand(accent: "#0E7C76"))
  ```
  Use the **keyword form** `from_brand(accent: "#0E7C76")` (matches the shipped
  `@spec from_brand(keyword(), keyword())` + the module doctest; idiomatic `from_*` constructor
  threaded into the `theme:` opt the user already knows from Phase 120). Guide shows accent-only
  seed first (progressive disclosure), then the fuller `from_brand(accent:, ink:, surface:)` map.
- **Orthogonality proof vehicle = `BrandedInvoice`** (the guide's executable
  `theming-brand-orthogonal` example): the two axes enter through **different doors of one call** —
  assets via `data.brand` (`%{font_name: :brand_heading, logo_name: :company_logo}`, registered by
  `document/2`), accent via `theme:` (`from_brand` emits tokens only, registers nothing). Assert
  `font_registry.fonts[:brand_heading]` + `asset_registry.assets[:company_logo]` **AND**
  `Theme.resolve(theme).colors.accent == {14,124,118}`, plus that `from_brand(...)` returns a bare
  `%Theme{}` with no registry side-effect. The neutral **Invoice** example is shown *first* to
  isolate the pure accent effect before graduating to the branded composition.
- **Accent seeds:** **teal-700 `#0E7C76`** is the primary showcase (grounded in living brand
  tokens; luminance ≈0.16 → `on_accent` derives to white; **visibly distinct from the blue-600
  default** so the recolor actually reads — a blue seed would render near-identical to default and
  prove nothing). Prove the contrast heuristic **both ways** with a second assertion on
  **amber-300 `#E6B450`** (luminance ≈0.50 → `on_accent` derives to `ink {16,24,39}`). A
  clearly-third-party hex (e.g. `#7A2E8F`) appears only in the guide's teaching prose ("your color
  here") — grounded renders/goldens stay on brand tokens so they're re-scorable.
- **Honesty wording (mandatory, next to the derivation claim):** `on_accent` is a "sensible
  readable default," **never** a WCAG-AA / PDF-UA claim, and is explicitly overridable via
  `on_accent:` — mid-tone accents may miss 4.5:1 either way (the known "theme-from-one-color"
  footgun; Phase 119 D-04 wording).
  — **Reversibility:** reversible — `from_brand/2` is already shipped/locked (Phase 119, the
  one-way door is untouched); guide, docs-contract markers, and gallery row are additive; the
  only irreversible-flavored artifact is the blessed gallery hash, and re-blessing within a
  version is the normal, expected motion.

### D-05 — Split-commit ordering that makes the honest order PROVABLE in git (spans DEFAULT-02)
Mirror the proven Phase-120 split-commit discipline. Each commit independently honest:
1. **Commit 1 — DATA verify/attest:** any residual `transform_invoice`/example-data change
   (likely a no-op confirmation) + a test asserting parties/totals present. **No theme, no scores.**
2. **Commit 2 — theme/`default/0` application** (`leading:1.35`) + re-bless the themed gallery
   rasters (D-03). **No `rubric_scores.json` change.**
3. **Commit 3 — HONEST RE-SCORE (score-flip): touches ONLY `rubric_scores.json` + `SIGN-OFF.md`
   + schema/test.** Its diff contains **zero** palette/token/color code. This is what makes the
   order provable: the `passed:true` was recorded in a commit that changed no colors, pointing at
   bytes blessed in a prior commit, signed by the human against a measured delta.
   — **Reversibility:** reversible — the split guarantees Commit 3 can be rolled back alone.

### Claude's Discretion
Planner freedom: exact per-demo measured-delta numbers and `SIGN-OFF.md` prose; the precise
`readme_hero` filter implementation in `readme_block/1`; whether the gallery/rubric work is one
slice or split by requirement; `defp` helper naming for the themed `build_source_document/1`
clauses; the exact `# docs-contract:` marker names in `guides/theming.md`; whether the `default/0`
retag threads `theme: default()` through a shared helper or per-spec. Binding constraints:
all-6-re-scored, machine-enforced sign-off with live hash-checked `evidence_ref`, the D-05
three-commit order provable in git, `preset:null` on every row, no engine/public-API-shape change,
no new asset in the Hex tarball, frozen rubric thresholds untouched.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone locks & requirements
- `.planning/REQUIREMENTS.md` — DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02 (Phase 123 rows).
- `.planning/ROADMAP.md` §"Phase 123" — goal (the named honesty trap), depends-on (Phases 121/122),
  the 4 success criteria (strong `default/0` + `from_brand` E2E; honest ordered SHOW-01 re-score
  with human sign-off; themed+dark S6 gallery rows; proof-backed support-matrix + `guides/theming.md`).
- `.planning/PROJECT.md` §"Current Milestone: v2.11" — no-overclaim, brand⊥theme, honest
  flat-elevation, family-not-industry, byte-determinism, no-tagged-PDF/PDF-UA, permanent exclusions,
  "no new asset in the tarball," mine `brand/tokens/tokens.json` for `{r,g,b}`.
- `.planning/STATE.md` — the SHOW-01 honesty note ("root cause is DATA not color; fix data → make
  key fact dominant → apply default/0 → re-score with human sign-off; never flip passed:true in a
  color-only commit").

### The LIVING brand system (authoritative — prefer over the older Brand Book prose)
- `brand/tokens/tokens.json` — raw palette + `semantic.light`/`semantic.dark` aliases
  (text-primary/secondary/muted/link, surfaces, lines, feedback) + `$contrast` block; the source of
  every `default/0` value and the `from_brand` accent seeds (teal-700 `#0E7C76`, amber-300 `#E6B450`).
- `brand/audit/SCORECARD.md` + `brand/audit/AUDIT.md` — the in-repo human-audit house style
  (dated, per-dimension, "Honest not flattering") that `priv/quality/SIGN-OFF.md` must mirror.
- `brand/copy/VOICE.md` — microcopy voice for `guides/theming.md` + the "restraint reads as
  confidence, a data-dump reads as overclaim" curation principle behind the 11-row gallery.
- `brand/README.md`, `brand/specimens/palette.svg`, `brand/specimens/typography.svg` — the brand
  motifs the gallery + default should echo.

### Vision / DNA (reference; defer to `brand/` where they conflict)
- `prompts/Rendro Brand Book.txt` §9 Typography (generous line-height, clear hierarchy, NOT
  huge SaaS-hero type) — bounds the `leading:1.35` + display-anchor ambition.
- `prompts/rendro-oss-dna.md`, `prompts/rendro-gsd-seed.md` — honesty posture, proof-backed claims.
- `prompts/rendro-integration-opportunities.md` — positioning behind the gallery/DX framing.

### Prior-phase context (the seams this phase closes)
- `.planning/phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md` — D-03 (frozen
  scale VALUES + `leading:1.35` is the Phase-123 target); D-04 (`on_accent` = readable default, not
  a WCAG claim; overridable); the brand⊥theme + `from_brand` emits-tokens-only invariant.
- `.planning/phases/120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes/120-CONTEXT.md` —
  the proven split-commit honesty discipline (D-05 mirrors it); `:theme` opt threading.
- `.planning/phases/121-light-dark-background-fill-mechanism-all-7-recipes/121-CONTEXT.md` — the
  dark mechanism + the screen-oriented/non-print honesty bound the dark gallery rows must echo.
- `.planning/phases/122-typography-type-scale-application-font-role-leading-wiring/122-CONTEXT.md`
  — the uniform `leading` seam (making 1.35 a one-line change) + the `display` anchor (the "one
  key fact dominant" lever already wired).
- `.planning/research/milestone-b/SUMMARY.md` §"Rubric-gap remediation done honestly" +
  `.planning/research/milestone-b/PITFALLS.md` — the dishonest-pass trap; manifest/contract drift.

### Code to integrate with (read before planning)
- `lib/rendro/theme.ex` — `@default_colors` L48 (LOCK), `@default_typography` L75 (the single
  `leading: 1.2 → 1.35` edit), `default/0` L180, `resolve/1` L200, `from_brand/2` L266 + on_accent
  derivation ~L339, `coerce_color` (hex→tuple at the authoring boundary).
- `lib/rendro/examples_data.ex` — `transform_invoice/1` L36 (parties/totals ALREADY put_optional'd;
  verify-and-attest, not rescue).
- `lib/rendro/launch_artifacts.ex` — `@gallery_specs` ~L47, `@expected_gallery_dimensions` ~L30,
  `build_source_document/1` ~L313 (add themed/dark/brand clauses), `readme_block/1` ~L217 +
  `recipes_block/1` (add the `readme_hero` filter), S6 tag keys ~L27, `collect_manifest_shape_errors`
  ~L620 (order-sensitive id equality), `s6_seam_errors` ~L673.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` + `check.ex` — the regen/verify entry points.
- `lib/rendro/recipes/branded_invoice.ex` (`document/2` ~L166, `data.brand` asset registration
  ~L174, terms ~L287) — the `from_brand` orthogonality vehicle.
- `lib/rendro/recipes/invoice.ex` (`document/2`, terms ~L474) — neutral vehicle + flagship triptych.
- `lib/rendro/recipes/certificate.ex` (`centered_paragraph` ~L433 + `validate_body!/1`) — the one
  prose block to **fit-check** at 1.35 (single-page A4-landscape).
- `lib/rendro/recipes/ticket.ex` (terms ~L581) — prose block re-blessed at 1.35.
- `lib/rendro/text.ex` (`%Text{}` defaults: size 12, line_height 1.2, widows/orphans 2) +
  `lib/rendro/color.ex` (`validate/1`; contrast helpers).

### Manifests, schema, tests & docs (the closure surface)
- `priv/quality/rubric_scores.json` (S5 manifest: 6 records, dimensions, gates, frozen thresholds)
  + `priv/schemas/rubric_scores.schema.json` (add required sign-off fields when `passed==true`).
- `test/docs_contract/rubric_manifest_contract_test.exs` (the `passed?/2` tripwire; add sign-off teeth).
- `priv/support_matrix.json` — `theming.light`/`theming.dark` rows already present (Phase 121);
  make proof-backed for the new claims; keep boundary keys honest.
- `assets/rendro/artifacts.json` (retag 7 + append 4; hash-checked) + `assets/rendro/gallery/*.png`.
- `priv/pdfium_pin.json` + `test/support/pdfium_cli.ex` + `test/docs_contract/raster_claims_test.exs`
  — the deterministic, pinned raster substrate the sign-off evidence + gallery share.
- `guides/branding.md` (docs-contract example style to mirror) + `guides/recipes.md` (gallery block);
  **new** `guides/theming.md` (worked examples w/ `# docs-contract:` markers = the from_brand E2E test).
- `README.md` (hero gallery block) + the Hex-tarball exclusion tripwire (theme = pure code, no new
  asset ships).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Already-mined `default/0`** (`theme.ex`): every color role traces to a `brand/tokens/tokens.json`
  semantic alias — DEFAULT-01's palette is effectively done; the only value change is `leading:1.35`.
- **Uniform `leading` seam** (Phase 122): `type.leading` is already wired to every `%Text{line_height}`
  across all 7 recipes → 1.35 is a genuine one-line data change; single-line runs are inert.
- **Appendable S5 rubric manifest + `passed?/2` tripwire** (`rubric_manifest_contract_test.exs`):
  `passed` is recomputed from each record's own dims/gates, so a bare `passed:true` can't be asserted —
  the sign-off fields + teeth graft cleanly onto this existing honesty guard.
- **Pinned pdfium raster lane** (`priv/pdfium_pin.json` / `pdfium_cli.ex` / hash-checked
  `artifacts.json`): the same deterministic bytes serve as sign-off evidence AND gallery rows.
- **`@gallery_specs` + S6 tags** (`launch_artifacts.ex`): `theme`/`mode`/`preset` keys already exist
  and validate as null-or-string; adding themed/dark/brand rows = new specs + dimension entries +
  source/PNG hashes, no schema migration; `preset` is independent → Milestone C needs zero re-keying.
- **`brand/audit/SCORECARD.md`**: the in-repo precedent for a dated, honest, human quality sign-off —
  `SIGN-OFF.md` copies its shape.
- **`BrandedInvoice.document/2` doctest**: already asserts `font_registry`/`asset_registry` entries —
  the from_brand orthogonality test extends it with a `theme:` accent assertion.

### Established Patterns
- **Split-commit honesty discipline** (Phase 120, proven real via commit-diff inspection): mirrored by
  D-05's three-commit order (data → theme → score-flip), making the honest order provable in git.
- **Measurement-backed rubric justifications** (existing invoice record: "Total Due 24px vs title
  19px"): the per-demo glyph-height delta the human signs off on reuses this exact pattern.
- **`# docs-contract:` guide-example-as-test** (`guides/branding.md`: `branding-register-assets`,
  `branding-tiered-document`): the from_brand E2E proof rides this — the guide worked example IS the test.
- **Per-recipe literal-default vs theme-read split** (Phase 120/122): the 7 no-theme byte-identity
  goldens render on the literal 1.2 path and stay untouched; only `default/0`-reaching (themed)
  renders carry 1.35.
- **Honest capability bounding** (Phase 121 `theming.dark` = `supported_screen_oriented` + overclaim
  tripwire): dark gallery captions + the theming.md dark claims inherit this wording.

### Integration Points
- **None into the deterministic engine.** All work is the recipe layer + manifests + tests + docs.
  `%Theme{}` never reaches the pipeline. The `leading:1.35` change flows only through the recipe
  `%Text{}` seam; the sign-off/gallery/support-matrix/guide work is manifest + docs-contract only.
  No new asset ships in the Hex tarball (theme is pure code — the tarball tripwire must stay green).

</code_context>

<specifics>
## Specific Ideas

- The flagship **Invoice triptych** (default / dark / brand) is the single strongest DX artifact —
  it answers the evaluator JTBD ("does theming work on the thing I'll use, light/dark/branded?") in
  one glance, far better than an exhaustive 28-cell matrix.
- The `from_brand` gallery showcase MUST use a **visibly non-blue** accent (teal-700 `#0E7C76`) — a
  blue seed would render near-identical to the blue-600 default and prove nothing to the eye.
- The `from_brand` **gallery row** isolates the accent (Invoice, no assets); the **orthogonality
  composition** (assets + accent in one call) is proven in the **guide's executable BrandedInvoice
  example**, not a muddied gallery PNG — the two proofs are complementary, not redundant.
- The human sign-off is "confirm these 6 numbers + images are honest," not "go measure things" — all
  measurement is pre-computed so judgment, not arithmetic, is the human's job (anti-rubber-stamp).
- `on_accent` honest wording ("readable default, not a WCAG/PDF-UA guarantee, overridable") must sit
  right next to every derivation claim in `guides/theming.md`.

</specifics>

<deferred>
## Deferred Ideas

- **Genre/style presets, public example catalog, static configurator, curated preset fonts** →
  Milestone C (`SEED-004`). `preset` stays `null` on every gallery row (S6 already reserves the key).
- **Live Studio (LiveView theme playground)** → Milestone D (`SEED-005`, optional).
- **Exhaustive gallery matrix (all 7 × light/dark × default/brand ≈ 28 rows)** — deliberately NOT
  built; the 11-row curated hybrid proves every claim without the CI/maintenance/brand-restraint cost.
- **Dark rows for dense recipes (Statement/Receipt) and asset-branded dark (BrandedInvoice dark)** —
  honestly excluded: dense ledgers don't shine dark and a dark brand-asset render muddies logo/font
  color. Revisit only if a concrete need surfaces.
- **`density: :compact` deep leading/spacing multipliers** — Milestone C (honored shallowly today).
- **Tabular figures / small-caps / OpenType `mono` refinements** — demand-gated on new engine
  primitives (Milestone C+).
- **WCAG-AA/PDF-UA conformance claims for `on_accent` or dark mode** — permanently out; the honesty
  posture ships "readable/sensible default" wording, never a conformance claim.

None out-of-scope surfaced during discussion — the user's directive (deep parallel research →
one-shot coherent locked recommendations) was executed within the fixed phase boundary.

</deferred>

---

*Phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-manifest-closure*
*Context gathered: 2026-07-28*

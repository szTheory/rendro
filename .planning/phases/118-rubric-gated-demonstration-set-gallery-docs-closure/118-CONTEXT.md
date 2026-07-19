# Phase 118: Rubric-gated demonstration set, gallery & docs closure - Context

**Gathered:** 2026-07-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v2.10 (Milestone A). Render a **rubric-passing family × domain demonstration set** from the realistic example library, regenerate the gallery + `artifacts.json` (with the S6 optional tags), and reconcile docs / support-matrix / README so every new family and claim is proof-backed and the milestone makes **no tagged-PDF/PDF-UA accessibility overclaim**.

Concretely, four workstreams:
- **SHOW-01** — a six-family demonstration matrix (Invoice, Statement, Receipt, Certificate, Payslip, Ticket) rendered via recipes + the escape hatch, **each demo citing its `DOMAIN.md`**, each **passing the reader-quality rubric** (hierarchy = 5, core ≥ 4, gates pass), with scores **appended** to `priv/quality/rubric_scores.json` (seam S5).
- **SHOW-02** — update `guides/recipes.md`, `guides/branding.md`, `guides/livebook/first_invoice.livemd`, and `examples/phoenix_example` to demonstrate the upgraded Invoice + new families against the realistic example library, with docs-contract claims bounded to evidence.
- **SHOW-03** — regenerate `assets/rendro/gallery/` + `assets/rendro/artifacts.json` via `mix rendro.launch_artifacts.gen` to **realistic** renders (sourced from `priv/examples/` through `Rendro.Examples`), and add optional `theme`/`mode`/`preset` tags to `artifacts.json` (seam S6).
- **SHOW-04** — reconcile `priv/support_matrix.json` + README so every new family/claim is proof-backed and "production-grade" wording is guarded against accessibility overclaim.

**Requirements:** SHOW-01, SHOW-02, SHOW-03, SHOW-04.

**Scope character:** This is the milestone's **closure/showcase** phase. It touches product code only where the gallery generator (`lib/rendro/launch_artifacts.ex`, `@moduledoc false` — out of `public_api.json`) must be repointed at the realistic example library and extended to the new families. All recipes and engine primitives already exist (Phases 114–117); the new authoring here is **data** (`priv/examples/**` fixtures + `DOMAIN.md`), **manifests** (rubric scores, artifacts.json), **docs**, and **tests**. No new public API surface, no engine change, no Hex-version bump beyond the already-planned additive `1.1.0`.

**Empirical starting state (verified during discussion):**
- Only `priv/examples/invoice/DOMAIN.md` + `priv/examples/invoice/acme-phoenix-saas/invoice.json` exist. Statement/Receipt/Certificate/Payslip/Ticket have **no** `priv/examples` fixture and **no** `DOMAIN.md`.
- `Rendro.LaunchArtifacts.@gallery_specs` renders **hardcoded toy data** for exactly 5 families (invoice, branded_invoice, statement, receipt_report, certificate) — no Payslip/Ticket, not sourced from `priv/examples/`.
- `rubric_scores.json` has `scores: []` (the S5 seam is empty; the D-15 disjointness/teeth guards from Phase 117 already gate it).
- `artifacts.json` has no `theme`/`mode`/`preset` keys yet.
- Payslip/Ticket recipe tests already use the **Aurora Live** named business; Invoice uses **acme-phoenix-saas**.

</domain>

<decisions>
## Implementation Decisions

All decisions below were locked with the user in discussion. Recommendations were research-grounded (read of `launch_artifacts.ex`, the rubric schema/contract test, the milestone SUMMARY, and the two prior CONTEXT files).

### Demonstration corpus scope (SHOW-01)
- **D-01 — Six families, one named business each, each with a co-located `DOMAIN.md`.** Author one realistic `priv/examples/<domain>/<business>/<family>.json` fixture per family and a co-located `priv/examples/<domain>/DOMAIN.md` for each new domain. Six demos total — matches SHOW-01 literally ("across the named fictional businesses"). This is **not** a families × multiple-businesses grid (that richness is Milestone C's catalog job, explicitly deferred).
- **D-02 — Reuse the already-named fictional businesses; do not invent a sprawl.** Invoice = `acme-phoenix-saas` (existing). Payslip + Ticket = **Aurora Live** (already the business in their recipe tests and the milestone fixture corpus). Statement / Receipt / Certificate get one fictional business each, chosen to fit the domain (planner's discretion on names, but keep them consistent with the existing corpus voice; fictional only, no real PII — Payslip is the acute risk per the milestone guards).
- **D-03 — Every new fixture follows the Phase-114 fixture contract:** Decimal-safe **money as strings** (never JSON floats), the optional empty `brand`/`logo` S4 slot, validates against `priv/schemas/examples.schema.json` via the existing docs-contract lane, and ships **text-only** in the Hex tarball (`.json`/`.md`/`.svg`; raster-ban holds).
- **D-04 — Each new `DOMAIN.md` carries the four required headings** enforced by `test/docs_contract/domain_md_contract_test.exs` (`## Domain Language`, `## Personas & Jobs-to-be-Done`, `## Reading Context`, `## Layout & Typographic Conventions`). The `DomainMdContractTest` currently only asserts "at least one" — planner should consider whether to strengthen it to require a `DOMAIN.md` per demonstrated domain (see Claude's Discretion).
- **D-05 — "Citing its DOMAIN.md" is satisfied by an explicit, machine-checkable link** from each demo/gallery entry (or the demo manifest) to its domain's `DOMAIN.md` path — not merely by the file existing. Planner decides the exact citation mechanism (e.g. a `domain_md` path field on the gallery/score entry, or a demonstration-index doc). It must be bounded by a docs-contract check so the citation cannot silently rot.

### Gallery source & membership (SHOW-03)
- **D-06 — Repoint the gallery generator to the realistic example library via `Rendro.Examples`.** `Rendro.LaunchArtifacts` sources its demo data from `priv/examples/**` (through the `@moduledoc false` loader) rather than the inline `invoice_data/0`, `statement_data/0`, … builders. One source of truth: the demonstration set (SHOW-01) and the gallery (SHOW-03) render from the **same** fixtures. This is the phase's one real `lib/` edit (still out of `public_api.json`).
- **D-07 — Gallery gains Payslip + Ticket, and keeps `branded_invoice`.** SHOW-01's six families all appear; `branded_invoice` stays as the Invoice family's branded demo (dropping a shipped gallery/manual asset would be a regression and would strand the manual's `recipe_page` wiring). Net gallery = **7 tiles** (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket). `@expected_gallery_dimensions`, `@gallery_required_keys`, the static/raster contract, the README/`recipes.md` generated blocks, and the manual pages all extend to cover the two new tiles.
- **D-08 — The gallery/artifacts contract stays byte-checked.** Source-PDF SHA-256 + manual SHA-256 remain in the **required** docs-contract lane; PNG rasters stay in the **advisory** pinned-pdfium lane (never a required check). Repointing to realistic data re-baselines every hash via `mix rendro.launch_artifacts.gen` — an authorized, reviewed re-bless, documented as such (not a determinism regression).

### Rubric scoring process (SHOW-01, seam S5)
- **D-09 — Claude renders → rasterizes → self-scores each demo against the anchors, with recorded justification.** For each of the six demos: render the deterministic PDF, rasterize via the pinned pdfium adapter, evaluate each of the 6 dimensions against the concrete 1/3/4/5 anchors in `rubric_scores.json`, and evaluate both pass/fail gates. This is a genuine visual assessment, not a rubber-stamp.
- **D-10 — Score-entry shape (matches `priv/schemas/rubric_scores.schema.json` `$defs.score_entry`):** each appended `scores[]` entry carries `demo_id`, `domain`, `family`, `dimension_scores` (all 6 integer 1–5), `gate_results` (`reading_order`, `print_safety` booleans), `passed` (bool), `recorded_at` (date). The schema is `additionalProperties: true`, so add a **`justifications`** object (per-dimension short rationale strings) to make the score auditable — the "why this scored what it did" trail. `stress_exempt` MUST be absent/false on every demo entry (Phase-117 D-15 guard (ii)).
- **D-11 — Passing is a hard gate, not a target to soften.** If a rendered demo does not actually reach hierarchy = 5 / core ≥ 4 / gates pass, the fix is to **improve the fixture/demo composition** (data, emphasis, layout choices within the recipe's existing knobs), not to lower the recorded score. A demo that cannot pass honestly is a finding, surfaced — never scored up to pass. The `passed` boolean must be computed from the scores by the same arithmetic as the contract test's `passed?/2` helper (hierarchy == 5, other cores ≥ 4, gates all true), never asserted independently.
- **D-12 — `demo_id`s must be disjoint from the Phase-117 stress-fixture id set** (`Rendro.EdgeMatrixTest.stress_fixture_ids/0`) — the D-15 disjointness guard enforces this. Pick demo ids from the demonstration namespace (e.g. `"invoice-acme-phoenix-saas"`), never colliding with `{family}_{dimension}` stress ids.

### S6 tags + accessibility/wording guards (SHOW-03, SHOW-04)
- **D-13 — Emit S6 tags as explicit-null seams on every gallery entry now.** Add optional `theme`, `mode`, `preset` keys to each `artifacts.json` gallery entry with a neutral placeholder value (explicit `null`, or a documented `"default"`/`"light"` where a real value is unambiguous today). Milestone C populates them without re-keying the hash manifest. The `LaunchArtifacts` `ordered_gallery_entry/1` encoder + `@gallery_required_keys` + shape contract extend to carry them. Keep them **optional** in any validation so their absence never breaks older readers.
- **D-14 — Add a docs-contract assertion guarding "production-grade" against accessibility overclaim (SHOW-04).** A test asserting that wherever "production-grade" (or equivalent showcase wording) appears in README/guides, it does **not** co-occur with a tagged-PDF / PDF-UA / screen-reader / reading-order-accessibility claim. Mirrors the existing `branding_claims_test.exs` tripwire discipline. The honest affordances remain: logical reading order (checked as a rubric gate), the human-readable Ticket reference, byte-determinism — never an accessibility-standard claim.
- **D-15 — `support_matrix.json` + README reconciliation is additive and proof-backed.** Confirm the `payslip` + `ticket` rows added in Phase 116 are present and proof-backed; add/adjust any demonstration-set or gallery claims so each maps to a resolvable test/evidence pointer. No claim ships without backing (the milestone's proof-backed-claims DNA).

### Claude's Discretion
- Exact fictional business **names** for the three legacy-family fixtures (Statement/Receipt/Certificate), and the specific realistic data content within them — subject to fictional-only + Decimal-string-money + domain-fit constraints.
- Whether the demonstration set is driven by a **new dedicated module/manifest** or folds into `LaunchArtifacts.@gallery_specs` directly (D-06 says they share the fixture source; the orchestration shape is open). Prefer the smallest change that keeps demos and gallery on one data source.
- Whether to **strengthen `DomainMdContractTest`** from "at least one DOMAIN.md" to "a DOMAIN.md per demonstrated domain" (recommended, but planner may keep it additive if it risks over-coupling).
- Exact `justifications` wording, the S6 placeholder value convention (`null` vs `"default"`), and the precise "production-grade" guard regex/word list.
- Whether the six demos render at a single page size or exercise A4/Letter variation for the geometry-derived families (Certificate/Ticket) — a showcase nicety, not required by SHOW-01.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & roadmap
- `.planning/ROADMAP.md` §"Phase 118: Rubric-gated demonstration set, gallery & docs closure" — goal + 4 success criteria (SHOW-01..04) + S5/S6 seams.
- `.planning/REQUIREMENTS.md` — SHOW-01 (demo matrix + rubric scores), SHOW-02 (guides/livebook/phoenix_example), SHOW-03 (gallery + artifacts.json + S6 tags), SHOW-04 (support_matrix + README + accessibility guard). Also the out-of-scope notes (no live barcode/QR, no locale-aware engine, no real PII, no tagged-PDF/PDF-UA).

### Milestone-A research (DNA, seams, pillars, pitfalls)
- `.planning/research/milestone-a/SUMMARY.md` — Phase-118 definition (lines 42–44), the S5 "populate in 118" + S6 "tags now" seams (lines 54–58), the accessibility-honesty guard + "production-grade" wording caution (line 105), no-PII / Payslip-acute-risk guard, catalog-is-Milestone-C boundary (line 122).
- `.planning/research/milestone-a/R1-DOMAIN-ANATOMY-RUBRIC.md` — reader-quality rubric dimensions + non-designer 1/3/4/5 anchors (the scoring reference for D-09).
- `.planning/research/milestone-a/R4-PRIOR-ART-PITFALLS.md` — float-money / jurisdiction-in-layout / PII footguns for the new fixtures.
- `.planning/research/milestone-a/R5-COHERENCE-PILLARS.md` — P2 honesty / no accessibility overclaim (source of D-14).

### Prior phase context (decisions carried forward)
- `.planning/phases/114-.../114-CONTEXT.md` — fixture contract (Decimal-string money, S4 brand slot, loader placement, text-only packaging, examples.schema.json), rubric-manifest S5 seam.
- `.planning/phases/116-new-families-payslip-ticket/116-CONTEXT.md` — Payslip/Ticket data shapes (D-11..D-19), Aurora Live default business, palette seam, adapter-tier registration, support_matrix row shape.
- `.planning/phases/117-edge-case-stress-matrix/117-CONTEXT.md` — the rubric `stress_exemption` block + D-15 disjointness/teeth guards the new `scores[]` entries must not violate.

### Gallery / artifacts infrastructure (the phase's primary edit target)
- `lib/rendro/launch_artifacts.ex` — `@gallery_specs`, `@expected_gallery_dimensions`, `@gallery_required_keys`, `build_source_document/1` (inline toy data to be repointed at `priv/examples/`), `ordered_gallery_entry/1` (S6 tag encoding), README/`recipes.md` generated blocks (`@readme_start/@recipes_start` markers), manual `recipe_page/1` wiring. `@moduledoc false` — stays out of `public_api.json`.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` + `.../check.ex` — the `mix rendro.launch_artifacts.gen|check` tasks (regen + drift check).
- `assets/rendro/artifacts.json` — current 5-entry manifest (schema_version 1); target: 7 entries + S6 tags + realistic hashes.
- `lib/rendro/examples.ex` — `@moduledoc false` loader (`load!/1`, `list/1`, `Path.safe_relative` guards, built-in `JSON.decode!`) — the gallery's new data source (D-06).

### Rubric manifest, schema & contract (SHOW-01 / S5)
- `priv/quality/rubric_scores.json` — append demo `scores[]` entries (D-10); leave `stress_exemption` intact.
- `priv/schemas/rubric_scores.schema.json` — `$defs.score_entry` (required: demo_id/domain/family/dimension_scores{6}/gate_results{2}/passed/recorded_at; `additionalProperties: true` allows a `justifications` object).
- `test/docs_contract/rubric_manifest_contract_test.exs` — the `passed?/2` arithmetic helper (D-11), the D-15 disjointness/teeth guards, `Rendro.EdgeMatrixTest.stress_fixture_ids/0` (D-12).

### Example fixtures, DOMAIN.md & their contracts (SHOW-01)
- `priv/examples/invoice/DOMAIN.md` + `priv/examples/invoice/acme-phoenix-saas/invoice.json` — the established pattern the five new domain fixtures follow.
- `priv/schemas/examples.schema.json` — the fixture schema (Decimal-string money, S4 brand slot).
- `test/docs_contract/domain_md_contract_test.exs` — the four-required-headings contract (D-04); glob `priv/examples/*/DOMAIN.md`.

### Recipes to demonstrate (all shipped; read for data shapes)
- `lib/rendro/recipes/invoice.ex` (post-115: palette, Decimal totals, cell_align, validate_data!), `statement.ex`, `receipt.ex`, `certificate.ex`, `payslip.ex`, `ticket.ex`.
- `lib/rendro/recipes/pagination.ex`, `lib/rendro/format.ex` (adapter tier), `lib/rendro/page_size.ex`.

### Docs / support surfaces to reconcile (SHOW-02 / SHOW-04)
- `guides/recipes.md` (has the generated `@recipes_start/@recipes_end` gallery block), `guides/branding.md`, `guides/livebook/first_invoice.livemd`, `examples/phoenix_example/`.
- `priv/support_matrix.json` — payslip/ticket rows (Phase 116) + any demonstration/gallery claim rows; schema-validated.
- `README.md` — the `@readme_start/@readme_end` launch-artifacts block + "production-grade" wording (D-14 guard target).
- `test/docs_contract/branding_claims_test.exs` — the tripwire-test pattern to mirror for the D-14 accessibility-overclaim guard.
- `mix.exs` (`defp package` `files:` allowlist) + the exact-allowlist tarball audit — new `priv/examples/**` domains ship text-only; goldens/raster_refs stay excluded.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Rendro.LaunchArtifacts.generate/1` + `check/1`** — the full render → rasterize → hash → write-manifest → write-docs-blocks pipeline already exists; the phase extends its spec list + data source rather than building new machinery.
- **`Rendro.Examples.load!/1` / `list/1`** — `@moduledoc false` loader with `Path.safe_relative` guards; the gallery's new realistic-data source (D-06).
- **`Rendro.Adapters.Pdfium.render/2` (dpi 96)** — the rasterizer used for both gallery PNGs and the D-09 rubric self-scoring raster.
- **`rubric_manifest_contract_test.exs` `passed?/2`** — the exact pass arithmetic to mirror when computing each entry's `passed` boolean (D-11).
- **`branding_claims_test.exs` tarball/claim tripwire** — clone-able pattern for the D-14 "production-grade" overclaim guard.
- **Each recipe's `document/2`** — all six families render deterministically today; demos are `Recipes.<Family>.document(Rendro.Examples.load!(...))` + optional launch table polish.

### Established Patterns
- **Generated-block docs discipline** (`@readme_start/@recipes_start` markers + `replace_block!` + a stale-block contract error) — extend the same markers for the 2 new tiles; never hand-edit inside the markers.
- **Ordered JSON manifest encoding** (`ordered_object` / `ordered_gallery_entry`) — S6 tags slot into this deterministic key order.
- **`priv/examples/<domain>/<business>/<family>.json` + co-located `DOMAIN.md`** — the fixture-corpus convention from Phase 114, extended to five more domains.
- **Appendable schema-backed manifest** (rubric `scores[]`) — S5: append-only, structure + arithmetic gated by contract, subjective score authored by review (D-09).
- **Proof-backed claims / no overclaim** — every gallery/demo/support claim maps to a resolvable test or evidence pointer; "production-grade" ≠ accessibility claim.

### Integration Points
- `lib/rendro/launch_artifacts.ex` (data source repoint + 2 new tiles + S6 tags) — the one real `lib/` edit (still `@moduledoc false`, out of `public_api.json`).
- `assets/rendro/gallery/*.png` + `assets/rendro/artifacts.json` (regen via `mix rendro.launch_artifacts.gen`; re-baselined hashes).
- `priv/examples/**` (5 new domains: statement/receipt/certificate/payslip/ticket) + `priv/quality/rubric_scores.json` (6 demo score entries).
- `README.md` + `guides/recipes.md` generated blocks; `guides/branding.md`, `guides/livebook/first_invoice.livemd`, `examples/phoenix_example` (hand-updated, docs-contract bounded).
- `priv/support_matrix.json` reconciliation; `mix.exs` package allowlist + tarball audit for the new example domains.
- New/extended docs-contract tests: D-14 accessibility-overclaim guard; possibly a strengthened `DomainMdContractTest` (D-04); demo-cites-DOMAIN.md check (D-05).

</code_context>

<specifics>
## Specific Ideas

- **Per user (research-first preference):** recommendations here were derived from reading the actual `launch_artifacts.ex`, rubric schema/contract, and milestone SUMMARY, then locked in one pass — only the four highest-impact decisions were surfaced for confirmation.
- **Named businesses stay consistent with the existing corpus:** Invoice = `acme-phoenix-saas`; Payslip + Ticket = **Aurora Live** (already in their recipe tests). Do not proliferate businesses — one per family (D-01/D-02).
- **Honesty is a hard line (carried from Phase 116):** "production-grade" = visual/information-design craft only. **No** tagged-PDF/PDF-UA/reading-order/screen-reader claims anywhere the demos or gallery are described. Reading-order is a rubric **gate** (a self-assessed pass/fail), not a public accessibility claim.
- **The gallery hash re-baseline is authorized, not a regression:** repointing to realistic data legitimately changes every source-PDF/PNG hash; regen via the task and document the re-bless (mirrors the Phase-117 "a hash change is a defect unless a human re-authorizes it" doctrine, here explicitly re-authorized).
- **Rubric passing is earned, not assigned (D-11):** if a demo can't honestly reach the thresholds, improve the demo, don't inflate the score.

</specifics>

<deferred>
## Deferred Ideas

- **Families × multiple-businesses catalog grid** — a true multi-business-per-family catalog is **Milestone C** (Style-Genre Presets, Public Catalog & Static Configurator), not A's closure. Phase 118 ships one business per family (D-01).
- **Populating S6 `theme`/`mode`/`preset` with real values** — Milestone B introduces theming; the tags land as explicit-null seams now (D-13) and get real values in C's catalog grid.
- **`brand`/`logo` S4 slot population** — the fixtures reserve the optional empty slot; Milestone C drops real brand data into the existing `<business>/` dirs.
- **A4/Letter geometry showcase variation** for Certificate/Ticket demos — a nice-to-have, not required by SHOW-01 (Claude's Discretion).
- **Retrofit opts-shape/`validate_data!` typed-error coverage to Invoice/Statement** — carried from Phase 116/117; a future additive phase, out of scope here.
- **Wire or delete `Rendro.I18n.Analyzer.analyze/1`** (unwired dead code) — a future cleanup/tech-debt phase (carried from Phase 117).

### Reviewed Todos (not folded)
None — no matching pending todos surfaced for this phase.

</deferred>

---

*Phase: 118-Rubric-gated demonstration set, gallery & docs closure*
*Context gathered: 2026-07-19*

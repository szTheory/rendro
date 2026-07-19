---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Realistic Business-Document Examples & Anatomy
status: executing
stopped_at: Phase 118 context gathered
last_updated: "2026-07-19T15:44:01.960Z"
last_activity: 2026-07-19
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 29
  completed_plans: 23
  percent: 79
---

# Project State

## Reference

**Project**: Rendro
**Core Value**: Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current Focus**: v2.10 Realistic Business-Document Examples & Anatomy (Milestone A / `SEED-002`) — Phases 114–116 complete (data + quality foundation, Invoice anatomy + `Format` promotion, and the Payslip/Ticket families all shipped); ready to plan Phase 117 (Edge-case stress matrix).

## Current Position

Phase: 118 (rubric-gated-demonstration-set-gallery-docs-closure) — EXECUTING
Plan: 2 of 7
Status: Ready to execute
Last activity: 2026-07-19

Progress: [████████░░] 79%

## Roadmap Snapshot (v2.10, Phases 114–118)

```text
[████████████████████████░░░░░░░░░░░░░░░░] 60% — 3/5 phases complete
Phase 114 Domain research, rubric & example-data library . ✓ Complete (2026-07-18)
Phase 115 Invoice anatomy + Format promotion + seams ..... ✓ Complete (2026-07-18)
Phase 116 New families — Payslip & Ticket ................ ✓ Complete (2026-07-19)
Phase 117 Edge-case stress matrix ........................ Ready to plan
Phase 118 Rubric-gated demos, gallery & docs closure ..... Not started
```

## Accumulated Context

### Decisions

- Milestone A (`SEED-002`) is an **additive minor** release (hex `1.1.0`), NOT v3.0 — A2 is strictly additive (toy call preserved byte-identical), `Format` goes to the adapter/Evolving tier, new families are adapter-tier modules. Unlike C1 (infra), A changes `lib/`, so it IS a versioned release.
- **The single irreversible act:** promoting `Rendro.Format` from `@moduledoc false` into the public SemVer surface (Phase 115). Held to the adapter/Evolving tier, smallest useful surface (`money/1`, `date/1`, `label/1`), with an "output may evolve" doc note. Requires editing Phase-79's `public_api_contract_test.exs` hidden set (likeliest surprise red build).
- **Fold seed's 7 phases → 5** (coarse granularity; precedent: v2.4 Phase 75 shipped 2 recipes at once). 114 foundation (data+rubric) → 115 Invoice/Format (only real `lib/` change) → 116 new families → 117 stress matrix → 118 demos+docs closure.
- **Four shape-now seams** baked into acceptance criteria so B/C/D need no breaking rework: **S1** private `palette(opts)` keyed on B's locked color roles (Phase 115, applied in 116) · **S4** fixtures reserve an optional empty `brand`/`logo` slot (Phase 114) · **S5** rubric recorded as an appendable manifest (authored 114, populated 118) · **S6** `artifacts.json` gains optional theme/mode/preset tags (Phase 118).
- **Guards:** no tagged-PDF/PDF-UA accessibility claims ("production-grade" = information design); engine stays locale-free (VAT/sales-tax + payslip jurisdiction are DATA); no real PII (fictional businesses/employees — Payslip is the acute risk); ship `priv/examples/` text-only; byte-determinism (static fixed-date fixtures; toy call byte-identical).
- Loader placement is load-bearing: `lib/rendro/examples.ex`, `@moduledoc false` — the only placement serving tests + bench(`:dev`) + Livebook + shipped consumers while staying out of `public_api.json`.
- Money in fixtures as decimal **strings** (`"79.00"`), never JSON floats. De-quarantine `invoice_data.json` verbatim first (provable no-op vs advisory bench), normalize money to strings in a separate commit.
- No text/cell right-align primitive exists today; additive `cell_align: :right` (Phase 115) is the single highest-leverage typographic upgrade — but the rubric must NOT assume it. No barcode/QR primitive; Ticket "reads as a ticket" via boxed code-area + human-readable reference + perforation + optional caller-supplied PNG.
- [Phase ?]: Plan 114-01: invoice fixture de-quarantined into priv/examples/invoice/acme-phoenix-saas/invoice.json as a provable byte-identical no-op; move kept verbatim (money/brand normalization deferred to 114-03 per Pitfall 6), consumers repointed, fresh render sha256-identical to recorded benchmark evidence.
- [Phase ?]: 114-05: Authored Invoice DOMAIN.md as locked research-first recommendation (synthesized domain-research prose), light human sanity-check reserved for phase verification.
- [Phase ?]: 114-05: DOMAIN.md structural contract test iterates priv/examples/*/DOMAIN.md so future domain families inherit the four-heading contract automatically.
- [Phase 114]: 114-03: Normalized invoice fixture money from integer cents to Decimal-safe 2-decimal strings + added S4 empty brand/logo slot in a commit separate from 114-01's verbatim move (Pitfall 6); Rendro render byte-identical. Added first schema-validation lane (examples_schema_contract_test.exs) validating every priv/examples/ fixture. EXL-01/03/06 satisfied.
- [Phase ?]: Rendro.Examples loader kept String.t() path signature with Path.safe_relative/1 defense-in-depth guard; all current callers are internal/hardcoded
- [Phase ?]: Loader uses built-in JSON.decode!/1 (never Jason) — Jason is a dev/test-only transitive dep that would crash prod Hex consumers
- [Phase ?]: Rubric threshold arithmetic (hierarchy=5, core>=4, gates pass) lives only as a test helper — no lib/ product change except the loader.
- [Phase 115]: 115-01: Used Rendro.flow/1 (not the Invoice recipe) as the minimal document/section wrapper for the INV-05 table golden, mirroring the existing table_borders_test.exs pattern. — Established lightweight pattern for exercising Rendro.table/2 through the full render pipeline without recipe-specific coupling.
- [Phase 115]: 115-01: Both sha256 goldens (@toy_golden_sha256, @table_golden_sha256) were computed by actually running renders on pristine code via mix run, not hand-typed, then embedded as module attributes. — Eliminates risk of a mistyped/stale golden silently freezing wrong bytes, per the plan's threat model T-115-01-01.
- [Phase 115]: 115-02: Promoted Rendro.Format from @moduledoc false to the public adapter/Evolving tier (money/1, date/1, label/1) in one atomic commit (INV-04, the milestone's single irreversible act); fixed a second, plan-unlisted duplicate hidden-modules assertion in test/rendro/public_api/manifest_test.exs that also expected Format hidden.
- [Phase ?]: [Phase 115]: 115-03: Resolved RESEARCH OQ2 (cell_align offset location) in favor of paginate.ex stack_cells alone — writer.ex needed zero changes since it already forwards cell.x transparently into rendered block.x.
- [Phase ?]: [Phase 115]: 115-03: Both new Cell.cell_align / Table.cell_align struct-field types are inlined into t() rather than declared as named @type, since named types are enumerated in priv/public_api.json and would have widened the frozen Stable-tier manifest.
- [Phase ?]: 115-04: body_section rewritten to per-page chunked pagination (mirrors Receipt), reserving conservative totals-block height uniformly on every page so the LAST table page always keeps room for the trailing totals block (shared chunker only accepts one capacity value, mirroring Statement's CF/BF reservation idiom).
- [Phase ?]: 115-04: Decimal.equal?/2 totals caller-assertion derives its comparison value from items (qty x price via item_line_total/1), not from a Decimal-typed source field, since Invoice's legacy line-item :price intentionally stays bare-number typed per INV-02's byte-compat split.
- [Phase 116]: 116-01: Implemented label_resolver/2 merge order (opts[:labels] -> default_labels -> Rendro.Format.label/1) exactly as prescribed in 116-RESEARCH.md's code example; default_labels defaults to %{} so Statement's arity-1 call sites (statement.ex:274,294) compile and resolve unmodified.
- [Phase 116]: 116-01: validate_labels!/2 and validate_formatters!/2 take a recipe_mfa string naming the caller's public entry point (e.g. Rendro.Recipes.Payslip.document/2), mirroring Invoice's four-part What/Where/Why/Next ArgumentError idiom, so 116-02/116-03 share one validated seam instead of each inventing their own guards.
- [Phase 116]: 116-02: Registered the vendored B612 branding font as a silent unicode fallback (built-in Helvetica -> B612) applied to both document/2 and body_section/2's own measurement document, since the built-in font's ASCII-only metrics table would otherwise crash rendering on any accented caller text (needed for D-17).
- [Phase 116]: 116-02: D-14's middot masking token stays literal in data/fixtures (test-enforced via String.contains?/2); rendering swaps it display-only for bullet (glyph_safe/1) since neither built-in Helvetica nor B612 has a middot glyph.
- [Phase ?]: 116-03: main_section/2's D-02 placement-grid anchor uses Rendro.table/2 (single data row, Block-styled header cells) not manual multi-column stacking -- sidesteps anchor_region_blocks/3's shared per-region Y cursor.
- [Phase ?]: 116-03: D-10 caller-image pre-validation mirrors asset_registry.ex's exact source-resolution logic inside validate_data!/1, pre-parses with the pure Rendro.ImageParser.parse/1, and raises an instructive ArgumentError naming data.code.image -- the first caller-supplied (not library-shipped) image asset in any Rendro recipe; Rendro.AssetRegistry.InvalidAssetError never leaks.
- [Phase ?]: 116-03: full-render PNG tests use priv/branded/images/rendro-logo.png ({:path, ...}) instead of the minimal 2x2 base64 PNG fixture -- the minimal fixture passes ImageParser.parse/1's header-only check but is not decodable by the PDF writer's stricter Rendro.PDF.PNG chunk decoder when actually embedded.
- [Phase 116]: 116-04: Registered Payslip/Ticket in @public_modules (mix rendro.api.gen) and added proof-backed payslip/ticket priv/support_matrix.json rows with matching recipes_claims_test.exs assertions. — FAM-01/02/03 all satisfied, Phase 116 complete.
- [Phase 117]: 117-01: Rendro.Test.Golden uses the Rendro.Test.* namespace (matching HexBuildCache); byte-golden bless is un-gated (MIX_GOLDEN_BLESS) because PDF-byte hashes are cross-platform stable; a missing ref hard-flunks (never silent auto-create).
- [Phase 117]: 117-04: family × stress-dimension @matrix built by zipping row-vectors against @families (transcription-resistant), independently exhaustiveness-checked by the D-02 meta-test; 62 golden refs blessed hash-only, committed as one-line SHA-256 files
- [Phase 117]: 117-06: Six D-10 curated raster fixtures added IN PLACE to the existing pdfium_raster_snapshot_test.exs (CI Landmine 1 hardcoded single-file path) so CI discovers them with zero ci.yml edit; refs blessed in the pinned CI container per D-11 (not locally: no pdfium-cli, hashes non-portable).
- [Phase ?]: [Phase 118]: 118-01: Generalized examples.schema.json to per-family allOf/if-then; invoice branch keyed on structural 'invoice' key (keeps original fixture byte-identical), 5 new families keyed on top-level 'family' const. Payslip employer deliberately 'Aurora Live' (D-02) reconciling recipe test's 'Aurora Textiles Co.' (Pitfall 5).

### Blockers / Open Questions

- None. (Phase 114 confirmed the de-quarantined `invoice_data.json` is fictional — no PII issue. Phase 115 watch item: the `Format` public promotion will edit Phase-79's `public_api_contract_test.exs` hidden set — expect a deliberate red build until the hidden-set + tier tags are updated.)

## Next Steps

1. `/gsd-plan-phase 115` — plan the additive Invoice anatomy upgrade + `Rendro.Format` public (adapter-tier) promotion + private `palette(opts)` (S1) and `cell_align: :right` seams.

## Last Session

**Last updated**: 2026-07-18
**Stopped at**: Phase 114 complete — UAT 2/2 passed (DOMAIN.md faithfulness + rubric anchor applicability), verification canonicalized `human_needed → passed`, security review closed 16 threats (0 open), transitioned to Phase 115.
**Blockers**: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| — | — | — | v2.10 not yet executed |
| Phase 114 P01 | 1min | 2 tasks | 5 files |
| Phase 114 P02 | 3min | 2 tasks | 2 files |
| Phase 114 P05 | 1min | 2 tasks | 2 files |
| Phase 114 P03 | 2min | 2 tasks | 6 files |
| Phase 114 P04 | ~2 min | 2 tasks | 3 files |
| Phase 114 P06 | 4 min | 2 tasks | 2 files |
| Phase 115 P01 | ~3min | 2 tasks | 2 files |
| Phase 115 P02 | ~4min | 2 tasks | 5 files |
| Phase 115 P03 | ~9min | - tasks | - files |
| Phase 115 P04 | ~20min | 3 tasks | 3 files |
| Phase 116 P01 | 5min | 2 tasks | 2 files |
| Phase 116 P02 | 17min | 3 tasks | 3 files |
| Phase 116 P03 | 7min | 3 tasks | 3 files |
| Phase 116 P04 | 8min | 2 tasks | 4 files |
| Phase 117 P01 | 18min | 2 tasks | 2 files |
| Phase 117 P02 | 35min | 2 tasks | 2 files |
| Phase 117 P03 | 4min | 1 tasks | 1 files |
| Phase 117 P04 | 3min | 2 tasks | 63 files |
| Phase 117 P05 | 1m | 2 tasks | 1 files |
| Phase 117 P06 | 6min | 2 tasks | 1 files |
| Phase 117 P07 | ~4min | 2 tasks | 3 files |
| Phase 118 P01 | 3min | 3 tasks | 6 files |

## Operator Next Steps

- Plan the next phase with `/gsd-plan-phase 115`.

## Session

**Last session:** 2026-07-19T15:43:35.506Z
**Stopped at:** Phase 118 context gathered
**Resume file:** None

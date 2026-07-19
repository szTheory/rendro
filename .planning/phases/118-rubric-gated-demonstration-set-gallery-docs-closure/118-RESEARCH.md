# Phase 118: Rubric-gated demonstration set, gallery & docs closure - Research

**Researched:** 2026-07-19
**Domain:** Elixir/Hex library — deterministic PDF generation; data fixtures, manifests, docs-contract tests, gallery generator (no external packages, no engine change)
**Confidence:** HIGH (every claim below is verified by direct read of the cited file at the cited line; this is a codebase-grounding research, not external-library research)

## Summary

Phase 118 is a closure/showcase phase. The decisions are fully locked (D-01..D-15 in CONTEXT.md); this research does **not** re-litigate them. It grounds the planner with the concrete, line-level facts it would otherwise rediscover: the exact shapes of `@gallery_specs`, `ordered_gallery_entry/1`, the manifest contract, the `Rendro.Examples` loader, each recipe's `document/2` data contract, the rubric schema/arithmetic, the tarball-audit and docs-contract patterns to clone, and — most importantly — **three hidden structural gaps** that the CONTEXT's tidy "`Recipes.<Family>.document(Rendro.Examples.load!(...))`" one-liner papers over.

**The three load-bearing findings the planner MUST design around:**

1. **There is NO fixture→recipe transform today, and D-06 requires one per family.** Fixtures are string-keyed JSON with money-as-strings and nested `invoice`/`items` objects (`priv/examples/invoice/acme-phoenix-saas/invoice.json`). Every recipe's `document/2` consumes **atom-keyed** maps with `Date.t()` and `Decimal.t()` values (verified across all six recipes). The only existing transform lives in `bench/comparison/fixtures/invoice_rendro.exs` (a `.exs` script, not `lib/`), and it even lossily coerces price to integer. `Rendro.LaunchArtifacts` currently renders **hardcoded atom-keyed toy data** (`invoice_data/0`, `statement_data/1`, …), NOT the fixtures. So "repoint the gallery at `Rendro.Examples`" (D-06) means **authoring a JSON→recipe-data decode/transform layer for all six families** — the single largest concealed task in the phase.

2. **`examples.schema.json` is invoice-shaped and validates EVERY fixture against that one shape.** It hard-requires top-level `["fixture_id", "issuer", "customer", "invoice", "items"]` (`priv/schemas/examples.schema.json:7`), and `examples_schema_contract_test.exs` globs `priv/examples/**/*.json` and validates each against this single schema. A payslip/ticket/statement fixture **cannot** satisfy `required: invoice+items`. The schema must be generalized (per-family branch / `oneOf` discriminated on `family`, or per-family schema files) **before** any new fixture lands, or the required `test` job goes red.

3. **The full gallery regen + PNG re-baseline + D-09 rubric rasterization all require `pdfium-cli`, which is NOT available on this dev machine and whose pin is Linux-only** (`priv/pdfium_pin.json` → `pdfium-webassembly-linux-amd64`). This exactly mirrors Phase 117's "blessed in the pinned CI container, not locally — no pdfium-cli, hashes non-portable" (STATE.md, 117-06). The planner must route SHOW-03 regen and D-09 self-scoring rasterization through the pinned pdfium environment, not local `mix`.

**Primary recommendation:** Structure the phase as: (Wave A) generalize `examples.schema.json` + author the six fixtures + five `DOMAIN.md` files + a JSON→recipe transform module; (Wave B) repoint `LaunchArtifacts` at the transform, add Payslip+Ticket tiles + S6 tags, extend `@expected_gallery_dimensions`/`@gallery_required_keys`; (Wave C) run gen in the pinned pdfium container, self-score the six demos, append `rubric_scores.json`; (Wave D) docs/support-matrix/README reconciliation + the D-14 accessibility-overclaim guard test. Regen (byte re-baseline) is the natural last step because it depends on everything upstream.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Realistic fixture data (SHOW-01) | Data (`priv/examples/**`) | Schema (`priv/schemas/examples.schema.json`) | Fixtures are content, gated by a repo-only schema; ship text-only |
| Fixture→recipe decode/transform (D-06) | Library (`lib/rendro/…`, `@moduledoc false`) | — | New code seam; must stay out of `public_api.json` like the loader |
| Gallery render/hash/manifest (SHOW-03) | Library gallery generator (`lib/rendro/launch_artifacts.ex`, `@moduledoc false`) | Rasterizer adapter (`Rendro.Adapters.Pdfium`) | Existing pipeline; extend spec list + data source only |
| Rubric scores (SHOW-01/S5) | Manifest (`priv/quality/rubric_scores.json`) | Contract test arithmetic | Append-only manifest; arithmetic gated by test, not `lib/` |
| Docs/README/guides (SHOW-02) | Docs (`guides/`, `README.md`, generated blocks) | Docs-contract tests | Prose bounded to evidence by tripwire tests |
| Support-matrix + accessibility guard (SHOW-04) | Manifest (`priv/support_matrix.json`) + test | — | Proof-backed claims; D-14 overclaim tripwire |
| Rasterization for scoring/gallery (D-09/D-08) | Adapter/CI (pinned `pdfium-cli`) | — | Non-portable, Linux-pinned; runs in CI container |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01** — Six families, one named business each, each with a co-located `DOMAIN.md`. Author one realistic `priv/examples/<domain>/<business>/<family>.json` fixture per family + a co-located `priv/examples/<domain>/DOMAIN.md` per new domain. Six demos total. NOT a families × multiple-businesses grid (that is Milestone C).
- **D-02** — Reuse already-named fictional businesses. Invoice = `acme-phoenix-saas` (existing). Payslip + Ticket = **Aurora Live**. Statement / Receipt / Certificate get one fictional business each (planner's discretion on names; consistent with corpus voice; fictional only, no real PII — Payslip is the acute risk).
- **D-03** — Every new fixture follows the Phase-114 contract: Decimal-safe money as **strings**, optional empty `brand`/`logo` S4 slot, validates against `priv/schemas/examples.schema.json` via the docs-contract lane, ships **text-only** in the Hex tarball.
- **D-04** — Each new `DOMAIN.md` carries the four required headings enforced by `domain_md_contract_test.exs` (`## Domain Language`, `## Personas & Jobs-to-be-Done`, `## Reading Context`, `## Layout & Typographic Conventions`). Contract currently asserts "at least one" — consider strengthening to per-domain (discretion).
- **D-05** — "Citing its DOMAIN.md" = an explicit, machine-checkable link from each demo/gallery/score entry to its domain's `DOMAIN.md` path — not merely the file existing. Bounded by a docs-contract check so the citation cannot silently rot.
- **D-06** — Repoint the gallery generator to the realistic example library via `Rendro.Examples`. `Rendro.LaunchArtifacts` sources demo data from `priv/examples/**` rather than the inline `invoice_data/0`, `statement_data/0`, … builders. Demonstration set (SHOW-01) and gallery (SHOW-03) render from the **same** fixtures. The phase's one real `lib/` edit (still out of `public_api.json`).
- **D-07** — Gallery gains Payslip + Ticket, keeps `branded_invoice`. Net gallery = **7 tiles** (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket). `@expected_gallery_dimensions`, `@gallery_required_keys`, static/raster contract, README/`recipes.md` blocks, and manual pages all extend for the two new tiles.
- **D-08** — Gallery/artifacts contract stays byte-checked. Source-PDF SHA-256 + manual SHA-256 remain in the **required** docs-contract lane; PNG rasters stay in the **advisory** pinned-pdfium lane (never required). Repointing re-baselines every hash via `mix rendro.launch_artifacts.gen` — an authorized, reviewed re-bless (not a determinism regression).
- **D-09** — Claude renders → rasterizes (pinned pdfium adapter) → self-scores each demo against the 1/3/4/5 anchors, with recorded justification. Genuine visual assessment, not a rubber-stamp.
- **D-10** — Score-entry shape matches `rubric_scores.schema.json` `$defs.score_entry`: `demo_id`, `domain`, `family`, `dimension_scores` (all 6, int 1–5), `gate_results` (`reading_order`, `print_safety` bools), `passed` (bool), `recorded_at` (date). Schema is `additionalProperties: true` → add a **`justifications`** object (per-dimension short rationale). `stress_exempt` MUST be absent/false on every demo entry.
- **D-11** — Passing is a hard gate. If a demo doesn't reach hierarchy = 5 / core ≥ 4 / gates pass, improve the fixture/composition, never lower the recorded score. `passed` must be computed by the same arithmetic as the contract test's `passed?/2`.
- **D-12** — `demo_id`s must be disjoint from the Phase-117 stress-fixture id set (`Rendro.EdgeMatrixTest.stress_fixture_ids/0`). Use the demonstration namespace (e.g. `"invoice-acme-phoenix-saas"`).
- **D-13** — Emit S6 tags as explicit-null seams on every gallery entry now: optional `theme`, `mode`, `preset` keys with a neutral placeholder (explicit `null`, or a documented `"default"`/`"light"` where unambiguous). Extend `ordered_gallery_entry/1` + `@gallery_required_keys` + shape contract. Keep them **optional** so absence never breaks older readers.
- **D-14** — Add a docs-contract assertion guarding "production-grade" (or equivalent) against co-occurring with a tagged-PDF / PDF-UA / screen-reader / reading-order-accessibility claim, anywhere in README/guides. Mirrors `branding_claims_test.exs`. Reading-order is a rubric **gate**, never a public accessibility claim.
- **D-15** — `support_matrix.json` + README reconciliation is additive and proof-backed. Confirm Phase-116 `payslip`+`ticket` rows present and proof-backed; every demonstration/gallery claim maps to a resolvable test/evidence pointer.

### Claude's Discretion
- Exact fictional business **names** for Statement/Receipt/Certificate fixtures + the specific realistic data (fictional-only + Decimal-string-money + domain-fit).
- Whether the demonstration set is a **new dedicated module/manifest** or folds into `LaunchArtifacts.@gallery_specs` directly (D-06 shares the fixture source; orchestration shape is open). Prefer the smallest change keeping demos and gallery on one data source.
- Whether to **strengthen `DomainMdContractTest`** from "at least one" to "per demonstrated domain" (recommended; may stay additive if over-coupling risk).
- Exact `justifications` wording, S6 placeholder convention (`null` vs `"default"`), the "production-grade" guard regex/word list.
- Whether the six demos render at one page size or exercise A4/Letter variation for geometry-derived families (Certificate/Ticket) — showcase nicety, not required.

### Deferred Ideas (OUT OF SCOPE)
- Families × multiple-businesses catalog grid → Milestone C.
- Populating S6 `theme`/`mode`/`preset` with real values → Milestone B/C.
- `brand`/`logo` S4 slot population → Milestone C.
- A4/Letter geometry showcase variation for Certificate/Ticket → nice-to-have (discretion).
- Retrofit opts-shape/`validate_data!` typed-error coverage to Invoice/Statement → future additive phase.
- Wire or delete `Rendro.I18n.Analyzer.analyze/1` → future cleanup phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHOW-01 | Six-family demo matrix, each citing its DOMAIN.md and passing the rubric, scores in the manifest | Fixture contract + transform (§Standard Stack, §Don't Hand-Roll #1); rubric schema `$defs.score_entry`, `passed?/2` arithmetic, D-15 guards (§Rubric Manifest Scoring); D-09 rasterization (§Rasterization) |
| SHOW-02 | Update `guides/recipes.md`, `guides/branding.md`, `guides/livebook/first_invoice.livemd`, `examples/phoenix_example` to the realistic library, claims bounded to evidence | Generated-block markers (§Gallery Generator Anatomy); docs-contract tripwire pattern (§Code Examples) |
| SHOW-03 | Regenerate `assets/rendro/gallery/` + `artifacts.json` via `mix rendro.launch_artifacts.gen`; add S6 `theme`/`mode`/`preset` tags | `@gallery_specs`/`ordered_gallery_entry/1`/`@expected_gallery_dimensions`/`@gallery_required_keys` (§Gallery Generator Anatomy); pinned-pdfium constraint (§Environment Availability) |
| SHOW-04 | Reconcile `support_matrix.json` + README; guard "production-grade" against accessibility overclaim | `support_matrix.json` payslip/ticket rows; `branding_claims_test.exs` tripwire to clone for D-14 (§Code Examples) |
</phase_requirements>

## Standard Stack

No external packages are installed by this phase. It is data + manifests + docs + tests + one `@moduledoc false` `lib/` edit. The in-repo "stack" the plan builds on:

### Core (existing, verified)
| Component | Location | Purpose | Notes |
|-----------|----------|---------|-------|
| `Rendro.LaunchArtifacts` | `lib/rendro/launch_artifacts.ex` (`@moduledoc false`) | Gallery render→raster→hash→manifest→docs-blocks pipeline | The one real `lib/` edit target (D-06/D-07/D-13) |
| `Rendro.Examples` | `lib/rendro/examples.ex` (`@moduledoc false`) | `load!/1`, `list/1` fixture loader with `Path.safe_relative` guards, built-in `JSON.decode!` | Gallery's new data source. Asserted absent from `public_api.json` |
| `Rendro.Adapters.Pdfium` | `lib/rendro/adapters/pdfium.ex` | `version/1`, `render/2` (`dpi:` default 150, `pages:`) → `{:ok, [png_binary]}` | Requires `pdfium-cli` on PATH. Gallery uses `dpi: 96`, `pages: "1"` |
| Six recipes | `lib/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}.ex` | Each exposes `document(data, opts \\ [])` consuming atom-keyed maps | Data shapes below |
| `mix rendro.launch_artifacts.gen` / `.check` | `lib/mix/tasks/rendro/launch_artifacts/{gen,check}.ex` | Regen (writes files) / drift-check (no writes) | Both require `pdfium-cli`; `--pdfium PATH` or `RENDRO_PDFIUM_CLI` |

### Supporting (schemas, manifests, contracts)
| Component | Location | Role |
|-----------|----------|------|
| Examples schema | `priv/schemas/examples.schema.json` | Currently invoice-shaped; MUST be generalized (finding #2) |
| Examples schema lane | `test/docs_contract/examples_schema_contract_test.exs` | Globs `priv/examples/**/*.json`, validates each; also the text-only tarball guard |
| DOMAIN.md contract | `test/docs_contract/domain_md_contract_test.exs` | Four-heading contract, globs `priv/examples/*/DOMAIN.md` |
| Rubric manifest + schema | `priv/quality/rubric_scores.json`, `priv/schemas/rubric_scores.schema.json` | Append `scores[]` (D-10) |
| Rubric contract | `test/docs_contract/rubric_manifest_contract_test.exs` | `passed?/2` arithmetic + D-15 guards |
| Branding tripwire | `test/docs_contract/branding_claims_test.exs` | Pattern to clone for D-14 |
| Support matrix | `priv/support_matrix.json` | payslip/ticket rows already present (Phase 116) |
| Package allowlist | `mix.exs` `defp package` `files:` | `priv/examples` already in allowlist (line 118) |

**Verification:** All components confirmed present by direct read on 2026-07-19. `Rendro.Examples` is asserted absent from the public API in `test/docs_contract/public_api_contract_test.exs:90` `[VERIFIED: grep]`.

## Package Legitimacy Audit

**N/A — this phase installs zero external packages.** It authors data (`priv/examples/**`), manifests (`rubric_scores.json`, `artifacts.json`), docs, and tests, plus one `@moduledoc false` edit to `lib/rendro/launch_artifacts.ex`. No `mix deps.get`, no new Hex dependency, no version bump beyond the already-planned additive `1.1.0`. No slopsquat surface.

## Architecture Patterns

### System Architecture Diagram (data flow for one demo/gallery tile)

```
priv/examples/<domain>/<business>/<family>.json   priv/examples/<domain>/DOMAIN.md
  (string-keyed JSON, money-as-strings)               (four-heading domain notes)
        |                                                     |
        | Rendro.Examples.load!("<domain>/<business>/<family>.json")   (cited by D-05 link)
        v                                                     |
  raw string-keyed map  ──►  [NEW] fixture→recipe transform ──┘
        |                     (per-family: string→atom keys,
        |                      "79.00"→Decimal, "2026-..."→Date)
        v
  atom-keyed recipe data ──► Recipes.<Family>.document(data, opts)
        |                        (+ apply_launch_table_style for table families)
        v
  %Rendro.Document{} ──► Rendro.render(doc, deterministic: true) ──► PDF binary
        |                                                              |
        |  source_pdf_sha256 (REQUIRED lane, byte-stable, portable)   |
        v                                                              v
  Pdfium.render(pdf, dpi: 96, pages: "1") ──► PNG ──► png_sha256 (ADVISORY pinned lane)
        |                                              width_px/height_px
        v
  gallery entry map (+ S6 theme/mode/preset) ──► ordered_gallery_entry/1
        v
  artifacts.json  +  README block (@readme_start..end)  +  guides/recipes.md block
                     (both regenerated via replace_block!)

  [D-09 scoring branch]  PDF ──► Pdfium raster ──► Claude visual self-score
                                                    ──► rubric_scores.json scores[] append
```

### Recommended Project Structure (new/edited files)
```
priv/
├── examples/
│   ├── statement/<business>/statement.json  + statement/DOMAIN.md   # NEW
│   ├── receipt/<business>/receipt.json      + receipt/DOMAIN.md     # NEW
│   ├── certificate/<business>/certificate.json + certificate/DOMAIN.md  # NEW
│   ├── payslip/aurora-live/payslip.json     + payslip/DOMAIN.md     # NEW (Aurora)
│   └── ticket/aurora-live/ticket.json       + ticket/DOMAIN.md      # NEW (Aurora)
├── schemas/examples.schema.json             # GENERALIZE to per-family
└── quality/rubric_scores.json               # APPEND 6 score entries
lib/rendro/
├── launch_artifacts.ex                      # repoint + 2 tiles + S6 (the one lib/ edit)
└── examples_data.ex (or similar, @moduledoc false)  # NEW transform layer (discretion)
test/docs_contract/
├── accessibility_overclaim_test.exs         # NEW (D-14)
├── domain_md_contract_test.exs              # maybe strengthen (D-04)
├── examples_schema_contract_test.exs        # follows generalized schema
└── (demo-cites-DOMAIN.md check, D-05)       # NEW or folded
assets/rendro/{gallery/*.png, artifacts.json, manual.pdf}  # REGEN in pinned container
README.md, guides/recipes.md                 # regenerated blocks
guides/branding.md, guides/livebook/first_invoice.livemd, examples/phoenix_example/  # hand-updated
```

### Pattern 1: `@gallery_specs` entry shape (the thing you extend for Payslip/Ticket)
**What:** A list of maps, one per tile, driving render + manual pages.
**Verified entry keys** (`launch_artifacts.ex:39-94`): `:id`, `:title`, `:module`, `:png_path` (`Path.join(@gallery_dir, "<id>.png")`), `:asset_name` (atom, registered for the manual PDF's embedded image), `:fit` (`{w,h}` tuple for the manual thumbnail), `:alt`, `:caption`. Order of the list == gallery order == required manifest id order (enforced at `:458`).
**When to use:** Add two entries (`payslip`, `ticket`). Portrait families use `fit: {320, 452}`; landscape (certificate) uses `{390, 276}` — pick per new tile's orientation.

### Pattern 2: The dispatch that must be repointed (D-06)
**What:** `source_document_for/1` → `build_source_document(id)` pattern-matches on the string id (`launch_artifacts.ex:255-286`) and calls the inline `*_data/*` builders. Note `render_source_pdf/1` and `source_document_for/1` accept **both** `%{id: id}` and `%{"id" => id}` (atom and string key) — the test harness calls with `%{id: "..."}` (`launch_artifacts_test.exs:9`).
**How D-06 changes it:** Replace each inline builder body with `Rendro.Examples.load!("<domain>/<business>/<family>.json") |> transform_to_<family>() |> Recipes.<Family>.document()`. Keep `apply_launch_table_style/1` for the table families (invoice/branded_invoice/statement/receipt_report); certificate/ticket/payslip decide their own polish.

### Pattern 3: `ordered_gallery_entry/1` — where S6 tags slot in (D-13)
**What:** Deterministic JSON key ordering for each gallery entry (`launch_artifacts.ex:942-959`). The 14 keys are emitted in a fixed order via `ordered_object/1` (a `Jason.OrderedObject`).
**How D-13 changes it:** Add `theme`, `mode`, `preset` to (a) the entry map built in `build_gallery_entries/1` (`:340-356`), (b) `ordered_gallery_entry/1` (choose a stable position — appending after `caption` is least disruptive), and (c) `@gallery_required_keys` (`:25`) **only if** you want them required; D-13 says keep them **optional**, so consider NOT adding to `@gallery_required_keys` and instead adding a shape check that tolerates absence. Placeholder value: explicit `null` (JSON null) is cleanest for "seam not yet populated"; `"light"` is defensible only for `mode`.

### Pattern 4: Generated docs blocks (`replace_block!` + stale-block contract)
**What:** README (`@readme_start`/`@readme_end`, `:34-35`) and `guides/recipes.md` (`@recipes_start`/`@recipes_end`, `:36-37`) each carry a machine-generated block. `write_docs_blocks/1` (`:402-406`) calls `replace_block!/4` (`:981-999`, regex `start.*?end` with `/s`). `collect_docs_block_errors/2` (`:584-598`) re-derives `readme_block/1`/`recipes_block/1` and fails the required check if the checked-in block drifts. **Never hand-edit inside the markers** — regen produces them; the two new tiles flow in automatically because both blocks iterate `manifest["gallery"]`.

### Anti-Patterns to Avoid
- **Hand-editing `artifacts.json`, README/recipes blocks, or gallery PNGs.** All are regenerated; hand edits fail the drift contract. Run the task.
- **Treating `Recipes.X.document(Examples.load!(...))` as literal.** It is not — the loader returns string-keyed JSON; every recipe wants atom keys + Decimal/Date. A transform is mandatory (finding #1).
- **Adding a new-family fixture before generalizing `examples.schema.json`.** The required `test` job validates every fixture against the invoice schema and will go red (finding #2).
- **Scoring a demo up to pass (D-11).** If a render can't honestly hit hierarchy=5/core≥4/gates, improve the composition, not the number.
- **Setting `stress_exempt: true` on a demo entry** to dodge the beauty gate — `D-15ii` tripwire (`rubric_manifest_contract_test.exs:103`) fails loudly.
- **Any accessibility/PDF-UA/tagged-reading-order wording** near "production-grade" — D-14 tripwire.

## Runtime State Inventory

> This is a data/docs/tests phase, not a rename/refactor. No stored runtime state, live-service config, OS registrations, or secrets are touched. Included for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB/datastore involved | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | `RENDRO_PDFIUM_CLI` (optional path to pdfium-cli) is **read** by the gen/check tasks and `with_pdfium/2` (`launch_artifacts.ex:1010-1034`) but is a tool locator, not a secret; unset locally | Set to a pinned pdfium binary in the CI container for regen (or pass `--pdfium`) |
| Build artifacts | `assets/rendro/gallery/*.png`, `assets/rendro/manual.pdf`, `assets/rendro/artifacts.json` are regenerated build artifacts; re-baselined this phase (D-08, authorized re-bless) | Regenerate in pinned pdfium container; commit the re-blessed hashes |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Loading a fixture path | Custom `File.read!` + decode | `Rendro.Examples.load!("<domain>/<business>/<family>.json")` | Ships `Path.safe_relative` traversal guard + `app_dir` resolution for shipped consumers (`examples.ex:13-22`) `[VERIFIED]` |
| Pass/fail arithmetic for a score entry | New threshold logic | Mirror `passed?/2` exactly (`rubric_manifest_contract_test.exs:33-45`): `content_hierarchy == 5` AND all other cores `>= 4` AND all gates `== true` (D-11) | Independent logic risks divergence from the contract test |
| Gallery PNG hashing / manifest encoding | Custom JSON writer | Existing `build_gallery_entries/1` + `encode_manifest/1` + `ordered_gallery_entry/1` | Deterministic key order + `\n` terminator already gated (`:397-399`, `:942-959`) |
| Rewriting README/recipes gallery sections | Manual markdown edit | `replace_block!/4` via `mix rendro.launch_artifacts.gen` | Drift contract (`:584-598`) fails hand edits |
| Rasterizing a PDF | Shelling to pdfium directly | `Rendro.Adapters.Pdfium.render(pdf, dpi: 96, pages: "1")` | Isolated tmp dir (0700/0600), list-form args (no shell injection), page-sorted output (`pdfium.ex:71-`) |
| Tarball text-only / exclusion assertions | New tar parsing | Clone `examples_schema_contract_test.exs` "hex tarball contents" + `branding_claims_test.exs` patterns using `Rendro.Test.HexBuildCache.get_build_output/0` | Cached tarball build already wired |

**Key insight:** Almost every mechanism this phase needs already exists and is contract-gated. The genuinely new authoring is (a) the JSON→recipe transform, (b) five fixtures + five DOMAIN.md, (c) the generalized schema, (d) six subjective score entries, (e) the D-14 guard test. Everything else is "extend a list / append to a manifest / run the task."

## Common Pitfalls

### Pitfall 1: Fixture shape ≠ recipe data shape (the silent D-06 trap)
**What goes wrong:** Planner writes `Recipes.Statement.document(Rendro.Examples.load!("statement/.../statement.json"))` and it crashes — the recipe pattern-matches atom keys (`:period`, `:opening_balance`, `:lines` with `Decimal.t()` amounts) but gets string keys with string money.
**Why it happens:** CONTEXT phrases D-06 as a one-liner; the real loader returns raw decoded JSON.
**How to avoid:** Author a per-family transform. Reference the existing pattern in `bench/comparison/fixtures/invoice_rendro.exs:8-23` (string→atom, `Decimal.new(item["price"])`, `Date.from_iso8601!(...)`) — but do NOT coerce money to integer (the bench does `Decimal.to_integer` as a lossy simplification; the demos want faithful Decimal money, INV-02).
**Warning signs:** `KeyError`/`FunctionClauseError` from a recipe when fed loader output.

### Pitfall 2: New fixtures fail the single invoice schema
**What goes wrong:** Adding `payslip.json` (with `employer`/`employee`/`earnings`) makes `examples_schema_contract_test.exs` red because the schema requires `invoice`+`items`.
**Why it happens:** `examples.schema.json:7` `required: ["fixture_id","issuer","customer","invoice","items"]` was authored for the single invoice fixture.
**How to avoid:** Generalize the schema first. Options: (a) a discriminator (`family` field) + `oneOf`/`if-then` per-family branches in one file; (b) a base schema + per-family `$defs`. Keep `money_string` (`^-?[0-9]+\.[0-9]{2}$`) and the `party`/optional-`brand` `$defs` reusable. The docs-contract lane globs `**/*.json`, so whatever shape you choose must validate all six.
**Warning signs:** `test/docs_contract/examples_schema_contract_test.exs` "every fixture … validates" failing.

### Pitfall 3: Regen/scoring cannot run locally (Linux-pinned pdfium)
**What goes wrong:** `mix rendro.launch_artifacts.gen` and D-09 rasterization error with no pdfium-cli; even if a local pdfium exists, PNG hashes won't match the pinned `pdfium-webassembly-linux-amd64` and the advisory lane drifts.
**Why it happens:** `RENDRO_PDFIUM_CLI` is unset locally; pin is Linux (`priv/pdfium_pin.json`). Phase 117 hit this exactly (STATE 117-06).
**How to avoid:** Route SHOW-03 regen + D-09 raster self-scoring through the pinned CI container. The **source-PDF SHA-256** (required lane) is byte-stable and portable, so document-shape correctness can be verified locally via `Rendro.render(doc, deterministic: true)` without pdfium; only the PNG raster + the `.gen` task need the container.
**Warning signs:** `{:error, {:executable_not_found, ...}}`; PNG hash drift only in the advisory lane.

### Pitfall 4: `demo_id` collides with a stress id (D-12)
**What goes wrong:** A demo_id like `"invoice_hierarchy"` collides with a `{family}_{dimension}` stress fixture id; `D-15iii` disjointness guard fails.
**Why it happens:** `stress_fixture_ids/0` returns a 62-element set of `{family}_{dimension}` ids (`rubric_manifest_contract_test.exs:118-122` asserts size 62).
**How to avoid:** Use the demonstration namespace with a business segment, e.g. `"invoice-acme-phoenix-saas"`, `"payslip-aurora-live"` — hyphen + business guarantees disjointness.
**Warning signs:** `MapSet.disjoint?` assertion failure listing the overlap.

### Pitfall 5: Business-name inconsistency for Payslip (D-02 vs existing test)
**What goes wrong:** D-02 says Payslip business = **Aurora Live**, but the payslip **recipe test** uses employer `"Aurora Textiles Co."` (`test/rendro/recipes/payslip_test.exs:34`), while the ticket test uses issuer `"Aurora Live"` (`ticket_test.exs:31`).
**How to avoid:** Planner should consciously pick one Aurora identity for the payslip fixture. CONTEXT D-02 locks "Aurora Live"; reconcile deliberately (the fixture is new; the recipe test's employer string is a separate artifact and need not match unless you want corpus consistency). Flag in the plan.

## Code Examples

### Fixture→recipe transform (verified existing pattern to adapt, NOT to copy verbatim)
```elixir
# Source: bench/comparison/fixtures/invoice_rendro.exs:8-23 (VERIFIED)
# NOTE: this lossily does Decimal.to_integer on price — demos must keep Decimal.
items =
  Enum.map(data["items"], fn item ->
    %{name: "#{item["name"]} - #{item["description"]}",
      qty: item["qty"],
      price: Decimal.new(item["price"])}        # keep Decimal for demos (INV-02)
  end)

invoice = %{
  id: data["invoice"]["id"],
  date: Date.from_iso8601!(data["invoice"]["date"]),
  items: items
}
Rendro.Recipes.Invoice.document(invoice)
```

### The `passed?/2` arithmetic to mirror for each score entry's `passed` (D-11)
```elixir
# Source: test/docs_contract/rubric_manifest_contract_test.exs:33-45 (VERIFIED)
defp passed?(dimension_scores, gate_results) do
  hierarchy_ok? = dimension_scores["content_hierarchy"] == 5
  other_cores_ok? =
    dimension_scores |> Map.delete("content_hierarchy") |> Map.values() |> Enum.all?(&(&1 >= 4))
  gates_ok? = gate_results |> Map.values() |> Enum.all?(&(&1 == true))
  hierarchy_ok? and other_cores_ok? and gates_ok?
end
```

### D-14 accessibility-overclaim guard — clone the tarball/claim tripwire discipline
```elixir
# Pattern source: test/docs_contract/branding_claims_test.exs (VERIFIED)
# New test asserts: wherever showcase wording appears, no accessibility claim co-occurs.
@showcase_terms ["production-grade"]           # discretion: extend word list
@accessibility_terms ["PDF/UA", "tagged PDF", "screen reader", "reading order",
                      "accessible", "accessibility conformance"]  # discretion: tune

test "no showcase wording co-occurs with an accessibility claim" do
  for path <- ["README.md" | Path.wildcard("guides/**/*.md")] do
    content = File.read!(path)
    if Enum.any?(@showcase_terms, &String.contains?(content, &1)) do
      for term <- @accessibility_terms do
        refute content =~ term,
               "#{path}: '#{term}' must not co-occur with showcase wording (D-14)"
      end
    end
  end
end
```
*(Refine to per-sentence/section proximity if a whole-file check is too coarse — "production-grade" and an accessibility disclaimer could legitimately live far apart. Planner's discretion on granularity.)*

### An appended score entry (schema-valid shape, with D-10 `justifications`)
```json
{
  "demo_id": "invoice-acme-phoenix-saas",
  "domain": "invoice",
  "family": "invoice",
  "domain_md": "priv/examples/invoice/DOMAIN.md",
  "dimension_scores": {
    "information_architecture": 4, "content_hierarchy": 5, "domain_fit": 4,
    "reader_affordances": 4, "typographic_craft": 4, "restraint_cohesion": 4
  },
  "gate_results": { "reading_order": true, "print_safety": true },
  "passed": true,
  "recorded_at": "2026-07-19",
  "justifications": { "content_hierarchy": "Total due is the single dominant number…" }
}
```
*(`domain_md` shown as one candidate D-05 citation mechanism — schema `additionalProperties: true` permits it. `dimension_scores` is `additionalProperties: false`, so justifications must be a **sibling** object, never inside `dimension_scores`.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Gallery renders hardcoded toy data (5 tiles) | Gallery renders realistic fixtures via `Rendro.Examples` (7 tiles) | This phase (D-06/D-07) | Every source-PDF/PNG hash re-baselined (authorized re-bless, D-08) |
| `rubric_scores.json` `scores: []` | Six appended demo entries with justifications | This phase (S5) | Rubric becomes a live quality ratchet Milestone C only appends to |
| `artifacts.json` no theme/mode/preset | Optional S6 tags on every entry | This phase (D-13) | Milestone C grid needs no re-keying |
| Single invoice-shaped `examples.schema.json` | Per-family generalized schema | This phase (required by finding #2) | New family fixtures validate |

**Deprecated/outdated:** The inline `invoice_data/0`, `branded_invoice_data/0`, `statement_data/1`, `receipt_data/1`, `certificate_data/0` builders (`launch_artifacts.ex:838-903`) are replaced by fixture-sourced data (D-06). `branded_invoice` is the one tile that legitimately still needs synthesized brand refs (`%{font_name: :brand_heading, logo_name: :company_logo}`, `:850-854`) — the S4 fixture slot is empty this milestone, so `branded_invoice` may keep its inline brand wiring layered over the invoice fixture data.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `branded_invoice` keeps its synthesized brand refs layered over fixture data (S4 slot empty this milestone) | State of the Art | Low — verified S4 defers brand data (REQUIRES EXL-06); planner confirms wiring |
| A2 | Whole-file regex is an acceptable first cut for the D-14 guard | Code Examples | Low — D-14 explicitly leaves the regex/word-list to discretion; may need proximity refinement |
| A3 | A new `@moduledoc false` transform module is the cleanest home for the JSON→recipe layer | Project Structure | Low — CONTEXT explicitly leaves orchestration shape to discretion (D-06 discretion note) |

*All other claims in this document are `[VERIFIED]` by direct file read at the cited line on 2026-07-19.*

## Open Questions (RESOLVED)

> All three resolved during planning; the plan set adopted every recommendation below
> (single-file schema + `family` discriminator → Plan 01; `domain_md` score-entry field +
> contract test → Plans 06/02; provisional gallery dims confirmed by container `.gen` → Plans 04/05).

1. **[RESOLVED] Schema generalization shape (one file with `oneOf` vs per-family files).**
   - What we know: The lane globs `priv/examples/**/*.json` and validates each against `examples.schema.json`; the file has reusable `money_string`/`party` `$defs`.
   - What's unclear: Whether a single discriminated schema or per-family schema files is cleaner given JSV's `oneOf` support.
   - Recommendation: Single file, add a `family` discriminator + `allOf`/`if-then` per family; reuse `money_string`. Verify JSV handles the chosen construct (it already builds draft-2020-12).

2. **[RESOLVED] D-05 citation mechanism (score-entry field vs gallery-entry field vs index doc).**
   - What we know: Must be explicit + machine-checkable + docs-contract-bounded.
   - What's unclear: Whether the link lives on the rubric score entry (`domain_md`), the gallery entry, or a standalone demonstration index.
   - Recommendation: A `domain_md` path field on each score entry (schema `additionalProperties: true` allows it) + a docs-contract test asserting each referenced path exists and each demonstrated domain has a DOMAIN.md. Lowest new surface.

3. **[RESOLVED] Payslip/Ticket manual-page `fit` + `@expected_gallery_dimensions` values.**
   - What we know: Portrait table families use `{320,452}` fit and `{794,1123}` dims; certificate (landscape) uses `{390,276}` fit and `{1123,794}` dims.
   - What's unclear: The exact rendered pixel dims of payslip (A4 portrait → likely `{794,1123}`) and ticket (fixed landscape band on A4 portrait page → page is portrait, so likely `{794,1123}`).
   - Recommendation: Let the first `.gen` run in the container report actual dims, then pin `@expected_gallery_dimensions` to observed values (that attribute is advisory-tier dimension pinning, `:26-32`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `pdfium-cli` | `mix rendro.launch_artifacts.gen` (SHOW-03), D-09 rubric rasterization, advisory PNG lane | ✗ (not on PATH; `RENDRO_PDFIUM_CLI` unset) | pin: `v0.11.0` `pdfium-webassembly-linux-amd64` (Linux only) | Run regen + raster self-scoring in the pinned CI container (Phase-117 precedent) |
| Elixir/`mix` | Everything else (render, contract tests, source-PDF hashes) | ✓ (project builds) | project toolchain | — |
| `Decimal` | Money in fixtures + transforms | ✓ (existing dep) | in `mix.lock` | — |
| `JSV` | Schema validation lanes | ✓ (existing dep) | in `mix.lock` | — |

**Missing dependencies with no fallback:** None — pdfium has a fallback (pinned container).
**Missing dependencies with fallback:** `pdfium-cli` — the **required** source-PDF/manual byte lane, all document-shape correctness, all contract tests, fixture schema validation, and the rubric arithmetic run **without** pdfium locally. Only the `.gen` task, the advisory PNG raster hashes, and D-09 image rasterization need the pinned Linux container. Plan the phase so local waves complete first and the container-gated regen/scoring is a clearly-bounded final wave.

## Validation Architecture

Nyquist validation is **enabled** (`.planning/config.json` → `nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` (standard); docs-contract lane under `test/docs_contract/` |
| Quick run command | `mix test test/docs_contract/` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SHOW-01 | Six fixtures validate against generalized schema | contract | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ (extend for new shapes) |
| SHOW-01 | Each new domain has a four-heading DOMAIN.md | contract | `mix test test/docs_contract/domain_md_contract_test.exs` | ✅ (maybe strengthen, D-04) |
| SHOW-01 | Every demo cites its DOMAIN.md (machine-checkable) | contract | new demo-cites-DOMAIN.md test | ❌ Wave 0 (D-05) |
| SHOW-01 | Score entries schema-valid; arithmetic + D-15 guards hold | contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ✅ (validates appended `scores[]`) |
| SHOW-01 | `demo_id`s disjoint from 62 stress ids | contract | (same file, `D-15iii`/`D-15iv`) | ✅ |
| SHOW-01 | Each demo actually reaches hierarchy=5/core≥4/gates (D-11) | manual-assisted (D-09 visual) + recorded | visual self-score in pinned container; recorded in manifest | N/A (human/agent judgment; arithmetic auto-checked) |
| SHOW-03 | Gallery source-PDF + manual SHA-256 byte-match (required lane) | contract | `mix rendro.launch_artifacts.check` (static lane) / `LaunchArtifacts.static_contract_errors/0` | ✅ (extend `@expected_*` for 2 tiles) |
| SHOW-03 | 7 gallery ids in fixed order; entry shape incl. S6 tags | contract | `LaunchArtifacts` shape checks (`:408-504`) + `launch_artifacts_test.exs` | ✅ (extend) |
| SHOW-03 | PNG raster hashes match pinned pdfium (advisory) | contract (advisory) | `mix rendro.launch_artifacts.check` (raster lane, container) | ✅ (container-gated) |
| SHOW-02 | Guides/livebook/phoenix_example claims bounded to evidence | contract | docs-contract lanes + generated-block drift check | ✅ (`collect_docs_block_errors/2`) |
| SHOW-04 | "production-grade" never co-occurs with accessibility claim | contract | new `accessibility_overclaim_test.exs` (D-14) | ❌ Wave 0 |
| SHOW-04 | payslip/ticket support-matrix rows proof-backed | contract | existing recipes_claims / support-matrix test | ✅ (rows present, `support_matrix.json:474,486`) |
| SHOW-03/EXL-05 | New `priv/examples/**` ship text-only in tarball | contract | `examples_schema_contract_test.exs` "hex tarball contents" | ✅ (globs `priv/examples/`) |

### Sampling Rate
- **Per task commit:** `mix test test/docs_contract/` (fast, no pdfium needed for the required lanes).
- **Per wave merge:** `mix test` (full suite; raster lane skips/soft-fails without pdfium — confirm CI behavior).
- **Phase gate:** Full suite green **in the pinned pdfium container** (only there do the advisory raster lane + `.gen` re-bless resolve) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/docs_contract/accessibility_overclaim_test.exs` — covers SHOW-04 / D-14 (new).
- [ ] Demo-cites-DOMAIN.md contract check — covers SHOW-01 / D-05 (new or folded into an existing lane).
- [ ] Generalized `priv/schemas/examples.schema.json` — precondition for SHOW-01 fixtures (schema change, not a test file, but Wave-0 blocking).
- [ ] JSON→recipe transform module (`@moduledoc false`) — precondition for SHOW-03 D-06 (new `lib/` code; needs its own unit test for the six shapes).
- [ ] (Optional, D-04) Strengthen `domain_md_contract_test.exs` from "at least one" to "per demonstrated domain."

## Security Domain

> `security_enforcement` is absent from `.planning/config.json` (treat as enabled). This phase has an unusually small security surface: data/docs/tests + one `@moduledoc false` edit; no auth, no crypto, no network, no user input at runtime.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (build-time) | Fixture paths resolved via `Path.safe_relative/1` in `Rendro.Examples.safe!/1` (`examples.ex:41-50`) — traversal guarded and tested (`examples_test.exs:13,30`) |
| V6 Cryptography | no | SHA-256 here is a content digest for determinism, not a security primitive |
| V12 Files & Resources | yes | Pdfium rasterization writes to an isolated tmp dir (0700/0600), list-form args, no shell interpolation (`pdfium.ex` render docstring, VERIFIED) |

### Known Threat Patterns for this phase's stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Real PII leaking into a fixture (Payslip acute per milestone guard) | Information disclosure | Fictional-only businesses/people; Payslip masks payment method (`···· 4321`); reviewer PII check at verification (D-02, STATE guards) |
| Path traversal via a fixture-name arg | Tampering | `Path.safe_relative/1` guard already in loader; no new fixture-name input surface |
| Accessibility overclaim (compliance/legal risk) | Repudiation/legal | D-14 tripwire test forbids PDF-UA/tagged/reading-order claims near "production-grade" |
| Shell injection via pdfium invocation | Tampering | Adapter uses list-form args + isolated tmp dir (existing, not changed here) |

## Sources

### Primary (HIGH confidence — direct file reads, 2026-07-19)
- `lib/rendro/launch_artifacts.ex` (full) — `@gallery_specs`, `build_source_document/1`, `ordered_gallery_entry/1`, `@expected_gallery_dimensions`, `@gallery_required_keys`, generated-block markers, `replace_block!`, inline `*_data` builders, `with_pdfium/2`.
- `lib/rendro/examples.ex` (full) — `load!/1`, `list/1`, `safe!/1`, `Path.safe_relative`, `JSON.decode!`.
- `lib/rendro/adapters/pdfium.ex:45-91` — `version/1`, `render/2` (dpi default 150, isolated tmp, list-form args).
- `lib/mix/tasks/rendro/launch_artifacts/{gen,check}.ex` — regen/drift-check tasks; pdfium requirement.
- `lib/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}.ex` — moduledocs + `document/2` + `validate_data!` signatures (atom-keyed, Decimal/Date data contracts).
- `bench/comparison/fixtures/invoice_rendro.exs` — the only existing JSON→recipe transform.
- `priv/examples/invoice/{DOMAIN.md, acme-phoenix-saas/invoice.json}` — established fixture + DOMAIN.md pattern.
- `priv/schemas/{examples,rubric_scores}.schema.json` — fixture + score-entry contracts.
- `priv/quality/rubric_scores.json` — dimensions/gates/thresholds/stress_exemption/`scores: []`.
- `priv/support_matrix.json:462-497` — certificate/payslip/ticket rows.
- `test/docs_contract/{domain_md,examples_schema,rubric_manifest,branding_claims}_contract_test.exs` — the four contract patterns to extend/clone.
- `test/rendro/launch_artifacts_test.exs` — source-document + table-polish assertions to extend for 2 tiles.
- `mix.exs:110-130` — package `files:` allowlist (`priv/examples` present).
- `priv/pdfium_pin.json` — Linux pin (`pdfium-webassembly-linux-amd64`, v0.11.0).
- `.planning/config.json` — `nyquist_validation: true`; `security_enforcement` absent.
- `.planning/{REQUIREMENTS.md, STATE.md}` + `118-CONTEXT.md` — requirements, prior-decision carry-forward, locked decisions.

### Secondary / Tertiary
- None. No external sources needed; this is a self-contained codebase-grounding research.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every component read directly at cited lines.
- Architecture / gallery anatomy: HIGH — full read of `launch_artifacts.ex`.
- Hidden-gap findings (transform / schema / pdfium): HIGH — verified by grep (no transform consumer of `Examples` beyond `examples_test.exs`), by schema `required` keys, and by pdfium PATH/pin check.
- Pitfalls: HIGH — each tied to a specific verified line or contract.
- Business-name discrepancy (Pitfall 5): HIGH — both test files read.

**Research date:** 2026-07-19
**Valid until:** 2026-08-18 (stable internal codebase; re-verify only if Phases 114–117 artifacts are amended before planning).

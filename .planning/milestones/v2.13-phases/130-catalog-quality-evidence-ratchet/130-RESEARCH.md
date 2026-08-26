# Phase 130: Catalog Quality & Evidence Ratchet - Research

**Researched:** 2026-08-19
**Domain:** supplied-theme recipe hierarchy, deterministic catalog artifacts, and hash-bound human evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Strict hybrid boundary:** preserve `catalog_layout: true` only for demonstrated fixture-capacity geometry, such as the existing Statement header and Ticket band accommodations. Hierarchy, typography, semantic ink, rules, labels, and color behavior belong to each recipe's normal supplied-theme path. — **Reversibility: costly** — catalog previews, public themed recipe output, deterministic hashes, quality bindings, and downstream Phase-131 evidence all consume this boundary.
- **D-02 — Catalog output must remain truthful public output:** do not create a marketing-quality rendering path that looks better than an equivalent public `Recipe.document(data, theme: ...)` call. A catalog fixture may need extra capacity, but it may not receive better visual semantics.
- **D-03 — No identity or genre branches in recipes:** visual behavior must not branch on catalog ID, brand, preset, quality status, or individual flagship cell. Recipes consume semantic theme roles; presets vary token values behind those roles.
- **D-04 — Preserve frozen and evolving contracts:** keep every no-theme byte identity intact. Supplied-theme token values and rendered bytes may evolve through the documented Evolving tier, but changes require targeted semantic contracts and refreshed evidence.
- **D-05 — No new consumer burden:** add no public option, callback, behavior, dependency, or configuration knob for this repair. The existing recipe/theme contract must become more correct without exposing catalog mechanics.
- **D-06..D-13 — Cross-genre hierarchy:** Invoice `Total Due` dominant with adjacent subordinate due date; Statement keeps its austere full-width closing-balance band and isolated mono amount; Receipt retains sole display-scale `Total` and quiet table/totals separation; Certificate recipient is largest then credential; Payslip has a sharp grid-aligned `Net Pay` band and indivisible right-aligned money; Ticket placement grid is anchor, title secondary, complete reference compact/subordinate. Preserve genre, light/dark rank/geometry, Certificate landscape, Ticket A6, pagination, and fixed family geometry.
- **D-14..D-18 — Humanist dark Receipt:** themed headers/descriptions/amounts use `ink`; page number and secondary labels use `muted`; measure/render materialize the same styles; preserve warm-neutral dark page; use one restrained `surface` + `rule` arithmetic treatment; no new theme role/token/preset/font/API; treat accessibility as an inspection lens, not a WCAG/PDF/UA/accessibility claim.
- **D-19..D-25 — Evidence closure:** pair checkpoints are deterministic and non-promotional; regenerate fixed ordered 32 cells once; explicitly rebind mechanically changed unscored identities; create one final pinned-PDFium canonical twelve-image payload; human review records observed score/justification; promotion stays threshold-derived; dark stays `needs_work` with `print_safety: false`; stop fail-closed on mismatches, missing artifacts, stale disposition, or missed threshold.

### the agent's Discretion

- Private helper names, exact numeric type/spacing/rule adjustments, focused test organization, smallest deterministic checkpoint per family, and whether existing shared semantic helpers can be reused or need a narrow extension after measurement/render-path inspection.

### Deferred Ideas (OUT OF SCOPE)

None. The discussion stayed inside the fixed twelve-cell quality repair and evidence boundary.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| CATALOG-06 | Improve all 12 scored `needs_work` cells without adding catalog surface area. | Recipe seams, focal-fact contracts, frozen no-theme tests, and explicit rebind set below. |
| CATALOG-07 | Repair Humanist dark Receipt while retaining its non-print-safe boundary. | `Receipt.body_section/2` currently uses raw table strings; use the existing structured `TableCell.content/5` pattern and themed arithmetic backdrop. |
| CATALOG-08 | Regenerate 32 cells and pass deterministic artifact/hash/schema/coverage checks. | `Rendro.Catalog.generate/1`, `check/1`, literal registry, manifest/rubric join, and CI commands below. |
| CATALOG-09 | Re-review 12 pinned page-one rasters and bind dispositions to current artifacts. | Canonical flagship list, pinned renderer staging, rubric schema, `SIGN-OFF.md`, and non-promotional checkpoint sequence below. |

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure; do not add Phoenix, Oban, Plug, Ecto, admin, or runtime dependencies for this phase. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lanes in CI and documentation. [VERIFIED: AGENTS.md]
- Treat documentation/evidence claims as contracts and do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Use optional dependency guards for integrations; no integration belongs in this phase. [VERIFIED: AGENTS.md]

## Summary

The implementation seam is already correctly shaped: `Rendro.Catalog.source_document_for/1` constructs each cell through the public `recipe_module.document(data, theme: theme, catalog_layout: true)` call, then deterministically renders the full PDF and pinned-PDFium page one. Therefore the quality ratchet belongs in recipe supplied-theme paths, not catalog overrides; only Statement’s themed header capacity and Ticket’s band height are currently allowed `catalog_layout` exceptions. [VERIFIED: dev/rendro/catalog.ex; lib/rendro/recipes/statement.ex; lib/rendro/recipes/ticket.ex]

The primary structural defect is Receipt: it measures and emits raw string cells, whereas Invoice and Statement already materialize cells through `Rendro.Recipes.TableCell.content/5` / explicit themed text. Raw table strings take default black styling, producing the recorded Humanist-dark defect and making measurement/render parity impossible to prove at the recipe seam. Convert Receipt header and rows once into themed structured cells, pass those same cells to `Rendro.measure_rows/4` and `Rendro.table/2`, register metric fonts for the measurement document, and retain a literal-string nil-theme branch for byte identity. [VERIFIED: lib/rendro/recipes/receipt.ex; lib/rendro/recipes/invoice.ex; lib/rendro/recipes/statement.ex]

**Primary recommendation:** implement six recipe-owned supplied-theme hierarchy repairs with focused no-theme/public-theme contracts; reconcile their downstream golden and launch families in a detached exact-HEAD staging worktree; obtain exact golden authorization, pinned launch generation/check, and six-light full-size reauthorization before publication; then render one dev-only catalog candidate bundle, create its separate hash-pinned 12-image payload, record the catalog review, transcribe both evidence families separately, and run canonical catalog generation exactly once. Neither generation path invents human quality authority. [RESOLVED: execution-gap revision after Wave 1]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Genre hierarchy and semantic roles | API / Backend (pure Elixir recipe) | Database / Storage (artifact evidence) | Recipes compose document ASTs from a supplied `%Rendro.Theme{}`; catalog only invokes those public recipes. [VERIFIED: dev/rendro/catalog.ex; lib/rendro/recipes/*.ex] |
| Fixture-capacity geometry | API / Backend | — | Statement/Ticket own the two existing `catalog_layout` geometry branches; it must not own visual policy. [VERIFIED: lib/rendro/recipes/statement.ex; lib/rendro/recipes/ticket.ex] |
| Deterministic 32-cell artifact build/check | API / Backend (dev-only tooling) | CDN / Static (committed PNG/JSON) | `Rendro.Catalog` renders, hashes, and validates static docs assets outside the runtime package. [VERIFIED: dev/rendro/catalog.ex; mix.exs] |
| Human disposition | Human advisory process | Database / Storage (JSON/Markdown record) | Rubric scores are human-authored, while the checker derives freshness/projection and rejects stale evidence. [VERIFIED: dev/rendro/catalog.ex; priv/quality/rubric_scores.json] |
| Pinned raster inspection | External dependency boundary (PDFium) | API / Backend test | PDFium produces advisory evidence under a pinned binary; it cannot replace deterministic merge authority. [VERIFIED: test/rendro/catalog_raster_review_test.exs; .github/workflows/ci.yml] |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|---|---:|---|---|
| Elixir/Mix | 1.19.5 / OTP 28 | recipes, tests, dev-only Mix tasks | Installed project toolchain; no new package is needed. [VERIFIED: `mix --version`; mix.exs] |
| Rendro.Theme + Presets | project source | semantic palette/type materialization | Existing public supplied-theme contract; preserve shape while evolving values/recipe use. [VERIFIED: lib/rendro/theme.ex; lib/rendro/theme/presets.ex] |
| PDFium CLI | pin in `priv/pdfium_pin.json` | advisory page-one rasterization | Existing renderer identity and SHA are already manifest-checked. [VERIFIED: dev/rendro/catalog.ex; .github/workflows/ci.yml] |
| ExUnit | bundled with Elixir | deterministic and tagged advisory tests | Tags and `mix test --include` support a separately invoked raster lane. [CITED: https://ex-unit.hexdocs.pm/ExUnit.Case.html] |

### Supporting

| Library/tool | Purpose | When to use |
|---|---|---|
| `JSON`/`Jason` already in project | read/write catalog and rubric JSON | Update the existing reviewer-owned data after final review only. [VERIFIED: dev/rendro/catalog.ex; mix.exs] |
| `Rendro.Recipes.TableCell` | create measure/render-identical themed table cells | Receipt table header and rows; do not invent receipt-only coloring. [VERIFIED: lib/rendro/recipes/invoice.ex; lib/rendro/recipes/statement.ex] |

**Installation:** none — Phase 130 must install no external package. [VERIFIED: .planning/REQUIREMENTS.md; AGENTS.md]

## Architecture Patterns

### System Architecture Diagram

```text
fixture JSON + literal 32-cell registry
              |
              v
public Recipe.document(data, theme, catalog_layout)
              |  supplied-theme semantic/type hierarchy
              |  (only capacity geometry may read catalog_layout)
              v
build -> compose -> measure -> paginate -> deterministic PDF
              |                                  |
              |                                  +--> complete-PDF SHA-256
              v
pinned PDFium page-one PNG --> PNG SHA-256 --> catalog.json
                                              |
                                              +--> deterministic check / CI authority
                                              |
                                              +--> exact 12-image advisory payload
                                                       |
                                                       v
                                             human rubric + SIGN-OFF
                                                       |
                                                       v
                                        hash join + derived quality projection
```

### Exact implementation seams

| Area | Change seam | Required contract |
|---|---|---|
| Invoice | `header_section/2`, `build_totals_blocks/2`, `table_row/4` in `lib/rendro/recipes/invoice.ex` | Strengthen compact `Total Due`/due-date relationship and retain arithmetic ladder; use theme roles, no catalog ID branch. [VERIFIED: lib/rendro/recipes/invoice.ex] |
| Statement | `header_section/2`, `header_height/1` in `lib/rendro/recipes/statement.ex` | Preserve full-width closing band; only existing `{theme, catalog_layout}` header-capacity branch may remain catalog-specific. [VERIFIED: lib/rendro/recipes/statement.ex] |
| Receipt | `body_section/2`, `build_totals_blocks/2`, `footer_section/2`, `palette/1`, `typography/1` in `lib/rendro/recipes/receipt.ex` | Replace themed raw cells with shared structured semantic cells, use identical values for measurement/render, and add restrained totals backdrop without changing nil-theme bytes. [VERIFIED: lib/rendro/recipes/receipt.ex] |
| Certificate | `body_section/3`, `centered_line/…`, centering size calculations in `lib/rendro/recipes/certificate.ex` | Resolve recipient/credential rank once and feed those values to both emitted text and centering measurement. [VERIFIED: lib/rendro/recipes/certificate.ex] |
| Payslip | `summary_section/2`, `body_section/2` in `lib/rendro/recipes/payslip.ex` | Retain the existing semantic surface/rule net-pay band, right alignment, and atomic money test; make its supplied-theme hierarchy sharper, not a new card. [VERIFIED: lib/rendro/recipes/payslip.ex] |
| Ticket | `main_section/2`, `geometry/1`, `ticket_roles/2` in `lib/rendro/recipes/ticket.ex` | Placement stays the anchor and reference subordinate; retain only the existing `catalog_layout` band-height accommodation. [VERIFIED: lib/rendro/recipes/ticket.ex] |
| Artifacts/evidence | `dev/rendro/catalog.ex`, `dev/mix/tasks/rendro/catalog/{gen,check,candidate}.ex` | Add only a dev-only fixed-target candidate writer that omits quality projection and canonical writes. Do not change literal order/count or weaken `quality_contract_errors/2`, `disposition_errors/2`, or `rubric_passed?/2`. [VERIFIED seam: dev/rendro/catalog.ex; RESOLVED policy: checker revision 1] |
| Final payload | `test/rendro/catalog_raster_review_test.exs`, `.github/workflows/ci.yml` | Split the exact 12-image final-review payload from the existing four-image multipage proof, then stage renderer version/SHA and catalog hashes together. [VERIFIED: test/rendro/catalog_raster_review_test.exs; .github/workflows/ci.yml] |
| Evidence record | `priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md`, schema + doc contracts | Update only after observing the final payload; preserve 6 legacy scores, all 32 disposition rows, and thresholds. [VERIFIED: priv/quality/rubric_scores.json; priv/schemas/rubric_scores.schema.json; test/docs_contract/rubric_manifest_contract_test.exs] |

### Pattern 1: materialize styles once for table measure/render parity

**What:** build header/row cells with the same `Rendro.Text` properties that will render, then use those cells in both `measure_rows` and `table`.

**When to use:** any Receipt supplied-theme table change; especially Humanist dark semantic `ink` correction.

```elixir
# Follow Invoice/Statement's public-theme pattern; keep a literal nil-theme branch.
cells = Enum.map(values, &Rendro.Recipes.TableCell.content(&1, theme, colors, type, :ink))
{header_h, row_heights} = Rendro.measure_rows(rows, width, measurement_doc, header: header, columns: columns)
table = Rendro.table(rows, header: header, columns: columns)
```

Source: [VERIFIED: lib/rendro/recipes/invoice.ex; lib/rendro/recipes/statement.ex]

### Pattern 2: overlay restrained semantic surface without moving flow

**What:** use the existing path block with explicit `height: 0`, then add label/value blocks to the same region flow, as Statement and Payslip already do.

**When to use:** Receipt subtotal/tax/total grouping, provided its capacity is reserved/tested and it does not become a rounded SaaS card.

```elixir
backdrop = Rendro.path([{:rect, 0, 0, width, height}],
  fill: colors.surface, stroke: %{color: colors.rule, width: 0.75},
  x: 0, y: 0, width: width, height: 0
)
```

Source: [VERIFIED: lib/rendro/recipes/statement.ex; lib/rendro/recipes/payslip.ex]

### Pattern 3: candidate isolation, one canonical writer, one checker

**What:** `mix rendro.catalog.candidate` writes one fixed-root, quality-free temp bundle for review; after review transcription, `mix rendro.catalog.gen` writes canonical assets exactly once and `mix rendro.catalog.check` validates them. Candidate generation never mutates rubric/SIGN-OFF or projects quality.

**When to use:** full catalog regeneration and final closure. [VERIFIED: dev/rendro/catalog.ex; dev/mix/tasks/rendro/catalog/*.ex]

### Safe task ordering

1. Add focused public-theme hierarchy/semantic tests beside each recipe plus untouched no-theme byte checks; do not edit `rubric_scores.json`, `SIGN-OFF.md`, or `catalog.json` yet. [VERIFIED: test/rendro/recipes/*_byte_identity_test.exs; 130-CONTEXT.md]
2. Implement and validate one family pair at a time. Run deterministic recipe/cell tests and `mix rendro.catalog.check` only as diagnostic drift detection; if catalog hashes drift, do not regenerate yet. [VERIFIED: 130-CONTEXT.md; dev/rendro/catalog.ex]
3. Before catalog candidate generation, reconcile the sibling deterministic families uncovered after Wave 1. Stage from exact `HEAD` in `tmp/phase130-launch-reconcile`; authorize only Statement dark `aca316... -> a971a8...` and Certificate dark `df9703... -> acb99d...`; run launch gen/check with PDFium v0.11.0 and executable SHA `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`; require exactly ten changed gallery PNGs and byte-stable `branded_invoice.png`; review the six changed light evidence images full-size. Keep all writes staged until final evidence transcription. [VERIFIED: post-Wave-1 failure trace; Phase 126/127 precedent]
4. Add the exact twelve-image catalog staging contract and the fixed-target dev-only candidate writer. Candidate output lives under `tmp/phase130-candidate`, contains no quality projection, and is atomically published only after all 32 identities validate; canonical assets and reviewer records remain byte-identical. [RESOLVED: checker revision 1]
5. Run one pinned catalog candidate batch and derive an ID-aligned three-way actual diff: changed scored rows are `review_required` metadata only, changed unscored rows are enumerated for later mechanical rebind, and byte-stable rows remain untouched. Never copy stale scores into candidate cells. [RESOLVED: checker revision 1]
6. Produce one pinned twelve-image catalog payload from the candidate manifest, keeping multipage proof separate. Stop and clean the exact temp roots if any ID, hash, renderer identity, cardinality, or test is wrong. [VERIFIED: 130-CONTEXT.md; RESOLVED seam: checker revision 1]
7. Perform sequential full-size catalog review. At closure, separately transcribe the six legacy launch decisions and publish their reviewed staged batch, then transcribe exactly twelve catalog scored records plus only actual changed-unscored rebinds. Run `mix rendro.catalog.gen` exactly once. Accept canonical catalog output only if all 32 PNG/PDF hashes and renderer identity reproduce the reviewed catalog candidate, then run golden, launch, catalog, docs, full-suite, and `mix ci.fast` gates. [RESOLVED: execution-gap revision]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Dark semantic coloring | Receipt/catalog-specific RGB or catalog-ID conditionals | existing `Rendro.Theme.resolve(theme).colors` and shared cell materialization | Preserves public recipe semantics and prevents catalog-only output. [VERIFIED: lib/rendro/theme.ex; lib/rendro/recipes/invoice.ex] |
| Row-height estimates | local Receipt line/height arithmetic | `Rendro.measure_rows/4` on the exact structured cells | Engine projection and renderer then share grid measurement. [VERIFIED: lib/rendro/pipeline/measure.ex; lib/rendro.ex] |
| Catalog membership/order | discovery, maps, filesystem ordering | literal `@catalog_specs` | Fixed 32-cell cardinality and canonical ordering are an enforced contract. [VERIFIED: dev/rendro/catalog.ex; test/rendro/catalog_test.exs] |
| Review verdict logic | hand-set public `passes` or a new quality score | existing rubric JSON + derived `quality_projection/1` | Hash freshness and promotion evidence are already fail-closed. [VERIFIED: dev/rendro/catalog.ex; priv/schemas/rubric_scores.schema.json] |
| Visual snapshot promotion | implicit mass rebless | explicit gen, explicit unscored rebind, one human payload | Prevents stale identities and invented quality evidence. [VERIFIED: 130-CONTEXT.md; .github/workflows/ci.yml] |

## Common Pitfalls

### 1. Accidentally creating catalog-only styling

`source_document_for/1` always supplies `catalog_layout: true`; any visual branch keyed on it would make the catalog prettier than public supplied-theme output. Restrict it to the current Statement header and Ticket band capacity seams, and add a public themed recipe assertion for each repaired behavior. [VERIFIED: dev/rendro/catalog.ex; lib/rendro/recipes/statement.ex; lib/rendro/recipes/ticket.ex]

### 2. Fixing Receipt rendering but not its measurement

Receipt currently measures raw strings with an empty document, then renders raw strings. Switching only render cells to styled text risks different font metrics, row heights, and page breaks. Build once, use twice, and register curated metric fonts in the ephemeral measurement document as Statement does. [VERIFIED: lib/rendro/recipes/receipt.ex; lib/rendro/recipes/statement.ex]

### 3. Breaking frozen nil-theme bytes

All six recipes have byte-identity suites; several palette/typography comments explicitly require nil branches to reproduce historical literal defaults. Make themed behavior conditional on `opts[:theme]`, not a global replacement. [VERIFIED: test/rendro/recipes/*_byte_identity_test.exs; lib/rendro/recipes/receipt.ex]

### 4. Conflating a successful artifact check with an aesthetic verdict

`Catalog.check/1` verifies shape, identity, artifact hashes, source PDF hashes, page counts, dispositions, and projection; it does not score visual quality. Interim checks must never mutate scores or sign-off. [VERIFIED: dev/rendro/catalog.ex; 130-CONTEXT.md]

### 5. Reviewing an impure final payload

The current raster test writes 12 flagship images plus four multipage proof images (16 files). The Phase 130 final human payload must be exactly the twelve canonical page-one images; keep multipage proof a separately named advisory artifact/test rather than allowing it into the review directory. [VERIFIED: test/rendro/catalog_raster_review_test.exs; 130-UI-SPEC.md]

### 6. Leaving changed unscored hashes stale

Recipe-wide supplied-theme repair will likely alter more than the twelve scored flagship cells. Based on the literal registry, the expected explicitly re-bound unscored candidates are Swiss Invoice (2), Editorial Statement (2), Minimal-Mono Receipt (2), Swiss Certificate (2), Corporate-Classic Payslip (2), and Minimal-Mono + Editorial Ticket (4): 14 candidates? Re-evaluate against the generated hash diff; do not assume a count. [VERIFIED: dev/rendro/catalog.ex] [ASSUMED]

**Correction for planning:** the registry actually yields 14 unscored themed candidates across those families (2 + 2 + 2 + 2 + 2 + 4), while 12 are scored. The plan must enumerate exact hash-diff IDs from the candidate bundle rather than hard-code a predicted set. [VERIFIED: dev/rendro/catalog.ex; RESOLVED policy above]

### 7. False dark-mode claims

The dark boundary disclosure is a fixed catalog string and dark `print_safety` is currently false. Improved screen readability must not change it or create WCAG/PDF/UA/print claims. [VERIFIED: dev/rendro/catalog.ex; priv/quality/rubric_scores.json; 130-UI-SPEC.md]

### 8. Publishing launch bytes before reauthorizing legacy passed evidence

Completed Plans 01/02 intentionally changed ten non-branded launch source PDFs, which changes ten pinned PNGs while `branded_invoice.png` remains byte-stable. Six changed light PNG paths are referenced by the six legacy `passed: true` records. `mix rendro.launch_artifacts.gen` proves deterministic production, not continued human approval. Follow the Phase 126 exact-SHA/full-size pattern and Phase 127 separate catalog-review pattern: stage the entire launch/golden family in a detached worktree, review the six light images, then publish artifacts and evidence atomically. Dark/brand rows are deterministic-only. [VERIFIED: post-Wave-1 launch static-contract failures; rubric manifest; Phase 126/127 artifacts]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| plain strings in table cells | structured cells when theme semantics must apply | Lets recipe-owned color/type values flow through measurement and render. [VERIFIED: lib/rendro/recipes/invoice.ex; lib/rendro/recipes/statement.ex] |
| snapshot/bless implies approval | hash-bound artifacts plus independent human rubric | Keeps a changed PNG/PDF from inheriting old visual judgment. [VERIFIED: dev/rendro/catalog.ex; priv/quality/SIGN-OFF.md] |
| generic visual regression | deterministic artifact lane + explicitly tagged PDFium advisory lane | Maintains merge authority while preserving high-fidelity human inspection. [VERIFIED: .github/workflows/ci.yml; test/rendro/catalog_raster_review_test.exs] |

## Code Examples

### Receipt semantic table contract (test shape)

```elixir
theme = Rendro.Theme.preset(:humanist, accent: "#147A4B", mode: :dark)
body = Receipt.sections(data, theme: theme) |> Enum.find(&(&1.region == :body))

# Assert header, description, and amount cells contain materialized Text with colors.ink.
# Assert footer page number uses colors.muted.
# Render through the same themed document and assert a deterministic PDF result.
```

Source: [VERIFIED: lib/rendro/recipes/receipt.ex; test/rendro/recipes/invoice_test.exs; test/rendro/recipes/statement_test.exs]

### Final evidence identity check (shell)

```bash
mix rendro.catalog.check
RENDRO_CATALOG_REVIEW_DIR="$PWD/tmp/phase130-review" \
  mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs
```

The CI payload must additionally capture `GITHUB_SHA`, run ID, PDFium version/SHA, complete `catalog.json`, the twelve review PNGs in canonical order, and their matching source-PDF/PNG identities. [VERIFIED: .github/workflows/ci.yml; test/rendro/catalog_raster_review_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | All 14 unscored themed candidates will mechanically change. | Common Pitfalls | Some may have byte-stable output; the plan must use the actual post-generation diff and rebind only changed identities. |

## Open Questions (RESOLVED)

1. **RESOLVED — Exact phase-130 CI ref grammar:** the only accepted ref is `gsd/phase-130-catalog-review-<sha>`, where `<sha>` is exactly 40 lowercase hexadecimal characters and equals `GITHUB_SHA` byte-for-byte. CI enforces both `^gsd/phase-130-catalog-review-[0-9a-f]{40}$` and exact suffix equality before candidate generation. This phase-only route reuses the pinned install, emits separately named candidate/final/multipage artifacts, and does not change normal pull-request triggers or deterministic required checks.
2. **RESOLVED — Actual-diff/rebind authority:** compare the ordered 32-cell candidate manifest to the committed canonical baseline by catalog ID and both PNG/source-PDF SHA values. Partition all IDs into changed-scored, changed-unscored, and byte-stable sets. Candidate output records changed scored rows only as `review_required` with prior/current identities and never carries their old scores as current. During final transcription, update exactly the twelve reviewed scored rows and only IDs in changed-unscored; retain unscored status with current hashes/date/concrete mechanical reason. Leave every byte-stable row unchanged. Canonical generation runs only after those records are current and must reproduce the candidate identities exactly.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix | recipe/tests/catalog tasks | ✓ | Elixir 1.19.5, OTP 28 | — [VERIFIED: `mix --version`] |
| PDFium CLI | launch reconciliation and catalog raster payload | ✗ | v0.11.0 / `b1e7f3...160a` | Blocking human action supplies the exact absolute binary or triggers an exact-full-SHA CI artifact route; no alternate renderer. [VERIFIED: local command probe; priv/pdfium_pin.json; Phase 126 precedent] |
| jq | CI identity staging | ✓ | 1.7.1 | — [VERIFIED: `jq --version`] |
| GitHub Actions | one pinned final payload | external | — | no local equivalent for CI run identity; use the designated branch workflow. [VERIFIED: .github/workflows/ci.yml] |

**Missing dependencies with no fallback:** none for deterministic implementation; local final raster inspection requires the pinned PDFium binary or the existing CI lane.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (bundled with Elixir 1.19.5) [VERIFIED: mix.exs; `mix --version`] |
| Config | `test/test_helper.exs`; recipe and docs-contract suites [VERIFIED: repository test layout] |
| Quick per-family | `mix test test/rendro/recipes/<family>_test.exs test/rendro/recipes/<family>_typography_test.exs test/rendro/recipes/<family>_byte_identity_test.exs` |
| Catalog deterministic gate | `mix rendro.catalog.check` |
| Final required suite | `mix test --exclude quarantine --slowest 10 && mix rendro.catalog.check` |
| Advisory final payload | `RENDRO_CATALOG_REVIEW_DIR=... mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type / files | Automated command | Wave 0 gap |
|---|---|---|---|---|
| CATALOG-06 | six public supplied-theme focal hierarchies, no catalog-only policy | focused recipe structural/render tests in six `*_test.exs`; existing no-theme byte suites | family quick command above | Add only missing hierarchy assertions. |
| CATALOG-07 | Humanist dark Receipt semantic ink/muted, restrained totals group, measure/render parity | `receipt_test.exs`, `receipt_typography_test.exs`, `receipt_byte_identity_test.exs` | `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/receipt_typography_test.exs test/rendro/recipes/receipt_byte_identity_test.exs` | Add themed table/footer color and identical-cell measurement coverage. |
| CATALOG-08 | literal 32 order, hashes, PNG dimensions, source PDF/page counts, quality join | `catalog_test.exs`, catalog/docs contract tests | `mix rendro.catalog.check && mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` | Add test for explicit unscored rebind reason only if schema/contract cannot distinguish it today. |
| CATALOG-09 | canonical full-size raster sequence, fail-closed pinned identity, human-only scores | `catalog_raster_review_test.exs` + CI staging; schema/doc contracts | advisory command above, then human review | Split 12-image final payload from multipage proof and assert exact order/identity manifest. |

### Sampling Rate

- **Per recipe task:** its focused three-file test command, then `mix rendro.catalog.check` as a read-only drift signal. [VERIFIED: mix.exs; dev/mix/tasks/rendro/catalog/check.ex]
- **After all six pairs:** authorize the two exact dark golden transitions; generate/check the sibling launch family once in detached staging; inspect the six changed light launch images full-size. Only then start the pinned catalog candidate path. [RESOLVED: execution-gap revision]
- **Catalog generation:** one pinned `mix rendro.catalog.candidate` batch and candidate contract gate; canonical `mix rendro.catalog.gen` runs exactly once only after the separate twelve-image catalog review transcription. Launch generation does not count toward this rule. [RESOLVED: checker revision 1]
- **Before final evidence edit:** one CI pinned-PDFium payload; inspect every image at full size, canonical light then dark. [VERIFIED: 130-UI-SPEC.md]
- **After final evidence edit:** regenerate projections and run full deterministic suite; advisory evidence remains a separate claim. [VERIFIED: dev/rendro/catalog.ex; AGENTS.md]

### Wave 0 Gaps

- [ ] Receipt test proving themed header/description/amount cells use `ink`, footer/page number uses `muted`, and no-theme strings/bytes remain unchanged.
- [ ] Receipt test proving exact themed structured table cells are shared by measurement and rendering (including curated metric-font registration).
- [ ] One structural hierarchy contract for each of Invoice, Statement, Certificate, Payslip, and Ticket that asserts public supplied-theme behavior rather than `catalog_layout` behavior.
- [ ] Final-payload test/staging split: exactly 12 page-one review images and an identity manifest; retain separate bounded multipage proof.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---|---|---|
| V2 Authentication | no | No server/user identity is introduced. [VERIFIED: phase boundary] |
| V3 Session Management | no | No session surface is introduced. [VERIFIED: phase boundary] |
| V4 Access Control | no | No endpoint/resource authorization is introduced. [VERIFIED: phase boundary] |
| V5 Input Validation | yes | Retain fixture safe-relative path validation and fixed literal registry; do not add dynamic discovery. [VERIFIED: dev/rendro/catalog.ex] |
| V6 Cryptography | yes, limited | Reuse SHA-256 identity checks; do not hand-roll a hash/evidence format. [VERIFIED: dev/rendro/catalog.ex] |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Path traversal through fixture/artifact reference | Tampering / information disclosure | `Path.safe_relative/1` rejects unsafe paths before I/O. [VERIFIED: dev/rendro/catalog.ex] |
| Stale artifact presented as current review | Tampering / repudiation | Join ID/path/PNG SHA/source-PDF SHA, pinned renderer identity, fail closed. [VERIFIED: dev/rendro/catalog.ex] |
| Human-quality approval smuggled through generation | Repudiation / integrity | Generation only derives projections; reviewer-owned records and promotion closure are validated separately. [VERIFIED: dev/rendro/catalog.ex; priv/schemas/rubric_scores.schema.json] |

## Sources

### Primary (HIGH confidence)

- [Phase 130 locked context](.planning/phases/130-catalog-quality-evidence-ratchet/130-CONTEXT.md) — scope, visual/evidence decisions, promotion and stop conditions.
- [Phase 130 UI contract](.planning/phases/130-catalog-quality-evidence-ratchet/130-UI-SPEC.md) — canonical review order, non-claim boundary, payload contract.
- [Catalog implementation](dev/rendro/catalog.ex) — public recipe invocation, registry, hashes, fail-closed rubric join.
- [Receipt recipe](lib/rendro/recipes/receipt.ex) — current raw table/measurement defect and totals seam.
- [Catalog tests](test/rendro/catalog_test.exs) and [raster review test](test/rendro/catalog_raster_review_test.exs) — deterministic/advisory coverage.
- [CI workflow](.github/workflows/ci.yml) — pinned PDFium and Phase-127 payload precedent.

### Secondary (MEDIUM confidence)

- [ExUnit tags and filters](https://ex-unit.hexdocs.pm/ExUnit.Case.html) — isolated `raster_snapshot` advisory execution.

### Tertiary (LOW confidence)

- None used for a design decision; configured web-search sources were unavailable in this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are installed/project-owned; no package choice.
- Architecture: HIGH — direct trace from catalog caller through recipe and evidence code.
- Pitfalls: HIGH — grounded in current code/comments and previous Phase-126/127 evidence artifacts.

**Research date:** 2026-08-19
**Valid until:** implementation begins or a catalog/evidence seam changes.

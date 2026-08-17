# Phase 127: Public example catalog & quality ratchet - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning
**Decision mode:** User selected every gray area and delegated a one-shot recommendation. Four typed `gsd-advisor-researcher` studies compared catalog breadth, page coverage, quality-ratchet scope, and the developer-facing catalog contract against the live codebase, current milestone research, living brand system, older `prompts/` material where still applicable, and successful ecosystem precedent.

<domain>
## Phase Boundary

Phase 127 creates a separate, deterministic public example catalog for Rendro's six document families. It curates a bounded set of unbranded and brand/preset light/dark renders, writes one hash-checked page-one preview per cell plus complete-source provenance, and turns the existing human reader-quality rubric into an explicit scored-or-unscored standing ratchet.

This phase owns `Rendro.Catalog`, `mix rendro.catalog.gen`, `mix rendro.catalog.check`, `assets/rendro/catalog.json`, `assets/rendro/catalog/`, and the additive quality-disposition contract. It does not modify the existing 11-row `Rendro.LaunchArtifacts` gallery or `assets/rendro/artifacts.json`; build the Phase-128 configurator/code generator; publish Phase-129 guide/support-matrix closure; auto-score visual quality; add a server, database, Node build, or runtime dependency; or make design-quality, accessibility, PDF/UA, WCAG, universal viewer-fidelity, or dark-mode print-safety claims.

</domain>

<decisions>
## Implementation Decisions

### Catalog breadth and pair curation

- **D-01 — Exact 32-cell catalog:** ship exactly 32 cells: six unbranded `Theme.default/0` light baselines, twelve Phase-125 data-backed brand/preset pairs in both light and dark, and one additional Aurora Live Ticket × Brutalist pair in both light and dark. Assert both the expected count and a hard ceiling of 32 so adding a fixture, preset, or mode never expands the grid implicitly. — **Reversibility: costly** — Phase 128's exact preview choices, committed artifact tree, hashes, quality dispositions, and public catalog URLs will all key off this set.
- **D-02 — Explicit curated registry, never a product:** rows come from one ordered catalog registry. Do not enumerate the filesystem into public rows and do not compute domain × brand × preset × mode. Fixture discovery may validate that a referenced input exists, but it must never silently make a new public cell.
- **D-03 — Locked pair matrix:** use these curated pairs; each pair emits light then dark.

  | Family | Curated brand/preset pairs |
  |---|---|
  | Invoice | Northline Logistics × Swiss; Cedar Mutual × Corporate-Classic |
  | Payslip | Northline Logistics × Swiss; Cedar Mutual × Corporate-Classic |
  | Statement | Signal Ledger × Minimal-Mono; Aster Research Fund × Editorial |
  | Receipt | Poppy & Grain × Humanist; Circuit Supply Co. × Minimal-Mono |
  | Certificate | Aster Institute × Swiss; Meridian Arts Fellowship × Editorial |
  | Ticket | Field Notes Conference × Minimal-Mono; The Letterpress Hall × Editorial; Aurora Live × Brutalist |

- **D-04 — Brutalist is represented honestly:** Brutalist shipped as a complete sixth preset, so omitting it from the catalog/configurator preview vocabulary would be surprising. Use the existing Aurora Live Ticket control identified by Phase 125. Any missing slug/accent/preset metadata must be added as safe data under `priv/examples/ticket/aurora-live/`, never as a brand module or genre branch; preserve the historical unthemed render path.
- **D-05 — Manifest-constrained preview choices:** Phase 128 may offer only combinations present in `catalog.json` when promising an exact pre-rendered preview. The public `Theme.preset/2` API may support more valid combinations, but the UI must disclose when code generation is broader than preview coverage rather than fabricating or approximating a tile.

### Preview and page coverage

- **D-06 — One cell, one public page-one preview:** a catalog cell represents one complete deterministic family × fixture/brand × preset × mode render, with exactly one committed page-one PNG. Do not rasterize or publish every page and do not turn the catalog/configurator into a PDF viewer.
- **D-07 — Prove the complete source without shipping it:** every cell records the page-one PNG SHA-256, the complete source-PDF SHA-256, and exact `page_count`. Generation/check renders the full PDF deterministically; source PDFs and trailing-page catalog PNGs are not committed to the public tree.
- **D-08 — Preserve native page geometry:** keep portrait families portrait, Certificate landscape, and Ticket native A6. Store physical `page: 1`, DPI, width, and height; never crop, stretch, or normalize pages into fake same-size screenshots. A future consumer may fit them visually inside a consistent sheet-style frame.
- **D-09 — Bounded multi-page evidence stays separate:** reuse or add a small advisory proof for the paginating families that checks a representative first and final physical page outside `assets/rendro/catalog/`; do not multiply it by every brand/preset/mode cell. Certificate and Ticket assert `page_count: 1` and retain their fixed-layout boundary. Deterministic complete-PDF verification remains distinct from pinned-PDFium advisory raster evidence and human review.
- **D-10 — Accessible preview semantics:** each cell carries non-empty, concrete alt text describing the visible document and a non-duplicative caption explaining its purpose/preset context. When `page_count > 1`, downstream copy says `Preview: page 1 of N`; it never implies that the thumbnail displays the complete document.

### Human-scored flagship set and quality ratchet

- **D-11 — Twelve human-scored flagships:** score exactly one curated pair per family in both light and dark. The six selected pairs cover every shipped preset exactly once:

  | Family | Human-scored flagship |
  |---|---|
  | Invoice | Cedar Mutual × Corporate-Classic, light and dark |
  | Payslip | Northline Logistics × Swiss, light and dark |
  | Statement | Signal Ledger × Minimal-Mono, light and dark |
  | Receipt | Poppy & Grain × Humanist, light and dark |
  | Certificate | Meridian Arts Fellowship × Editorial, light and dark |
  | Ticket | Aurora Live × Brutalist, light and dark |

  The other twenty cells are deliberately unscored in this phase; they are not silently treated as passing.
- **D-12 — Every cell has an explicit disposition:** `priv/quality/rubric_scores.json` has exactly one catalog disposition per catalog ID with `review_status: scored | unscored`. A scored disposition carries the existing dimensions, gates, computed verdict, reviewer/date, evidence path, PNG hash, and complete-PDF hash. An unscored disposition carries the same exact artifact identity/hashes plus a non-empty reason and recorded date. Existing launch-gallery scores remain intact and are not copied or re-pointed to new catalog artifacts.
- **D-13 — Freshness is derived and fail-closed:** freshness is computed by comparing catalog ID, evidence path, PNG SHA-256, and source-PDF SHA-256; it is not a reviewer-entered boolean. A new cell, missing disposition, changed identity/path/hash, removed cell with an orphan disposition, or mismatched quality projection fails CI. A changed scored cell requires fresh human review; a changed unscored cell requires an explicit deliberate rebind to the new artifact.
- **D-14 — Preserve the existing rubric bar:** keep `content_hierarchy == 5`, every other core dimension `>= 4`, and both existing gates true for `passed: true`. A score speaks only for the exact cell and evidence hashes it names, never for an entire preset, brand, family, mode, accessibility posture, or print behavior.
- **D-15 — Failing scores are valid evidence:** `passed: false` is a valid scored finding, not malformed data and not equivalent to unscored. A false-to-true transition must cite the superseded evidence and a non-empty resolution reference demonstrating the underlying behavioral fix; generation or catalog curation alone may never flip it.
- **D-16 — Separate generation from human approval:** catalog generation writes deterministic artifacts/manifest and never mutates reviewer records. A separate contract check joins catalog cells to rubric dispositions, verifies hashes and thresholds, and fails with a cell-specific explanation and next action. A minimal quality projection may be written into `catalog.json` for Phase 128, but `rubric_scores.json` remains the source of truth and projection drift fails.
- **D-17 — Review in meaningful pairs:** review the twelve flagships sequentially at full readable size, family by family, with light immediately followed by dark. A contact sheet may index the set but cannot be the only inspection surface. Record concise, bounded justifications and retain the project's exact-renderer and no-overclaim language.

### Catalog ordering, metadata, and Mix-task DX

- **D-18 — Internal module, conventional tasks:** add internal `Rendro.Catalog` (`@moduledoc false`, absent from `priv/public_api.json`) with narrow generation/check/validation seams. Expose `mix rendro.catalog.gen [--pdfium PATH]` as the deliberate write/bless operation and `mix rendro.catalog.check [--pdfium PATH]` as a read-only verification operation. Both mirror the existing launch-artifact task ergonomics.
- **D-19 — Stable ID and path grammar:** catalog IDs are immutable lowercase ASCII slugs shaped as `<family>--<brand>--<preset>--<mode>`; unbranded baselines use `<family>--default--default--light`. Assets live at `assets/rendro/catalog/<family>/<brand>/<preset>-<mode>.png`. Validate every slug and safe-relative path; IDs are durable keys, not labels to regenerate from display names.
- **D-20 — Domain-first deterministic order:** order families to match the current public recipe-gallery narrative with BrandedInvoice folded into Invoice: Invoice, Statement, Receipt, Certificate, Payslip, Ticket. Within each family emit the unbranded baseline first, then D-03's explicit curated brand order, with light immediately before dark. Never rely on map or filesystem ordering.
- **D-21 — Versioned consumer-focused manifest:** `assets/rendro/catalog.json` carries top-level schema/generator/renderer metadata and an ordered cell collection. Each cell includes stable identity, family, brand, preset, theme, accent, mode, recipe module, fixture reference, PNG path/hash, complete-PDF hash, page/page-count, DPI/native dimensions, renderer identity/version, alt, caption, and the minimal derived quality projection. Keep raw fixture payloads, font-registration mechanics, document structs, rubric justifications, internal cache keys, and implementation-only options out of this contract.
- **D-22 — Preserve truthful null/default semantics:** baseline cells use the explicit default ID/path sentinel while their semantic manifest fields remain truthful (`brand: null`, `preset: null`, `theme: "default"`, `mode: "light"`). Preset cells populate brand, preset, accent, theme, and mode. Do not force a fake accent or fake brand onto unbranded defaults.
- **D-23 — Errors explain what, where, why, and next:** `check` reports every failing catalog ID and the concrete condition: missing asset, unsafe path, duplicate ID, unexpected order/count, renderer mismatch, hash drift, page-count drift, missing/stale disposition, or orphan disposition. Hash drift names expected and actual values and directs the maintainer to generate, re-score, or deliberately refresh the unscored binding as appropriate; it never recommends a blanket re-bless.
- **D-24 — Dev/docs assets, not runtime payload:** keep `Rendro.Catalog`, quality records, schemas, and catalog artifacts out of the Hex runtime package. Phase 128 consumes the committed static manifest/tree through the existing ExDoc asset path; core stays pure and dependency-free.
- **D-25 — Status and boundary microcopy:** future consumers distinguish `Scored — passes current rubric`, `Scored — needs work`, and `Not yet scored`; never collapse them into an `approved` boolean. Exact preview copy may say `Exact pre-rendered <preset> · <accent> · <mode> preview.` Dark cells visibly retain `Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim.`

### the agent's Discretion

The planner may choose private helper names, the exact additive union shape used to represent scored/unscored dispositions, JSON field nesting, caching/parallelism inside one generation run, and whether existing multi-page proof already satisfies D-09 or needs a bounded extension. It may select Aurora Live's exact accent from the already-curated closed accent palette after render review, but must store the selection as fixture/catalog data and must not introduce a new arbitrary-color surface. It may not change the 32-cell ceiling, the D-03 pair matrix, the twelve D-11 flagships, the page-one public-preview policy, hash-bound disposition semantics, domain-first contract, or existing launch-gallery isolation without returning for a new product decision.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The living `brand/` system supersedes older `prompts/` brand guidance wherever they conflict; older prompts remain valuable for product, ecosystem, JTBD, and architectural context.

### Scope, requirements, and prior locked decisions

- `.planning/ROADMAP.md` — Phase 127 goal, dependencies, success criteria, and fixed sibling-catalog boundary.
- `.planning/REQUIREMENTS.md` — CATALOG-01..04, milestone-wide constraints, and explicit exclusions.
- `.planning/PROJECT.md` — pure-core, determinism, operational trust, brand-as-data, and truthful-claims posture.
- `.planning/STATE.md` — current milestone position and accumulated Phase-125/126 decisions.
- `.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-CONTEXT.md` — exact brand/preset fixture matrix, complete Brutalist decision, fonts, and explicit Aurora Live showcase preference.
- `.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-CONTEXT.md` — repaired dark/hierarchy/amount seams and evidence boundaries the catalog baseline inherits.

### Current milestone research and seed

- `.planning/research/ARCHITECTURE.md` — sibling `Rendro.Catalog`/manifest/tree architecture, additive quality integration, and Phase-128 dependency.
- `.planning/research/FEATURES.md` — catalog/preset feature hierarchy and configurator-facing metadata needs.
- `.planning/research/PITFALLS.md` — combinatorial, mass-rebless, rubric-fatigue, overclaim, and static-configurator hazards.
- `.planning/research/SUMMARY.md` — high-confidence milestone synthesis and the two decisions Phase 127 needed to lock.
- `.planning/research/JTBD-USER-FLOWS.md` — job-first documentation and example-discovery flows.
- `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md` — original public catalog, quality-ratchet, and static-configurator vision; later requirements/context supersede its in-place gallery wording.

### Living brand, voice, and UI direction

- `brand/README.md` — living source-of-truth order and the current Rendro identity system.
- `brand/index.html` — current self-contained light/dark brand book and component direction.
- `brand/tokens/tokens.json` — semantic light/dark/state/contrast tokens for later Phase-128 presentation.
- `brand/copy/VOICE.md` — maintainer voice, error pattern, status microcopy, and no-overclaim vocabulary.
- `brand/copy/marketing-copy.md` — current example CTA, artifact empty/success states, and evidence-led product copy.
- `brand/audit/AUDIT.md` — design/accessibility/maintainability pressure test; historical gaps must be interpreted through the now-current living kit.
- `brand/audit/SCORECARD.md` — visual coherence, UI readiness, accessibility, and maintainability lenses.

### Older prompt context requested during discussion

- `prompts/Rendro Brand Book.txt` — older comprehensive brand/JTBD/examples guidance; defer to `brand/` on conflict.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — ecosystem positioning, library conventions, and comparable-tool lessons.
- `prompts/rendro-gsd-seed.md` — original personas, pipeline, product boundaries, and verification posture.
- `prompts/rendro-integration-opportunities.md` — Phoenix-first optional-integration and coupling policy.
- `prompts/rendro-oss-dna.md` — Elixir package DX, API, docs-contract, CI, and operational conventions.

### Domain/JTBD sources

- `priv/examples/invoice/DOMAIN.md` — invoice reader tasks and amount/due-date hierarchy.
- `priv/examples/payslip/DOMAIN.md` — payee/payroll tasks, privacy, reconciliation, and numeric scanning.
- `priv/examples/statement/DOMAIN.md` — balance/transaction continuity and multi-page audit behavior.
- `priv/examples/receipt/DOMAIN.md` — narrow-format proof, total prominence, and photo/print reading context.
- `priv/examples/certificate/DOMAIN.md` — recipient-first ceremony and issuer authority.
- `priv/examples/ticket/DOMAIN.md` — placement/reference/time-pressure task and compact-page behavior.

### Implementation and proof seams

- `lib/rendro/launch_artifacts.ex` — existing 11-row page-one/hash manifest idiom that must remain untouched.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — Mix generation-task and `--pdfium` precedent.
- `lib/mix/tasks/rendro/launch_artifacts/check.ex` — read-only verification task precedent.
- `assets/rendro/artifacts.json` — current renderer/hash/geometry and reserved theme/mode/preset shape.
- `lib/rendro/examples.ex` — safe fixture loading/listing boundary.
- `lib/rendro/theme/presets.ex` — six canonical preset atoms, font roles, and explicit registration bridge.
- `priv/quality/rubric_scores.json` — current dimensions, gates, verdicts, sign-off provenance, and evidence records.
- `priv/schemas/rubric_scores.schema.json` — additive schema and conditional provenance contract.
- `priv/quality/SIGN-OFF.md` — exact-raster human review and bounded-claim precedent.
- `test/docs_contract/rubric_manifest_contract_test.exs` — threshold recomputation, live-evidence, and honest failing-score checks to extend.
- `test/rendro/launch_artifacts_test.exs` — fixed launch-gallery cardinality, realistic fixture, and S6 seam guards.
- `test/rendro/theme/preset_render_matrix_test.exs` — complete six-preset deterministic matrix and explicit font-registration behavior.
- `test/rendro/theme/preset_raster_snapshot_test.exs` — pinned-PDFium advisory baseline and review-output seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Rendro.LaunchArtifacts` already demonstrates deterministic full-PDF rendering, page-one PDFium rasterization at 96 DPI, PNG/source-PDF hashes, renderer pin metadata, manifest validation, and precise drift errors. The catalog should mirror this idiom in a sibling rather than generalize or mutate it.
- `Rendro.Examples` and the six `priv/examples/<domain>/` trees already provide safe data-backed fixture loading; Phase 125 supplied two explicit brand/preset records per family and retained original unbranded controls.
- `Rendro.Theme.preset/2` plus `Rendro.Theme.Presets.register_fonts/2` already provide strict preset construction and explicit document-owned font registration. Catalog generation composes them; recipes never branch on genre.
- `rubric_scores.json`, its JSON schema, `SIGN-OFF.md`, and the rubric contract test already separate human judgment from machine threshold arithmetic and accept honest failing findings.

### Established Patterns

- New artifact classes get their own module, tree, manifest, generator, and checker when their purpose/cardinality differs from an existing fixed gallery.
- Generated artifacts are checked by exact bytes/hashes under a pinned renderer; generation is explicit and check mode is non-writing.
- Required deterministic proof, pinned-raster advisory evidence, and human judgment are separate lanes with separate claims.
- Public manifests evolve additively, error messages identify what/where/why/next, and documentation claims are mechanically bounded.
- Brands remain JSON/SVG data; preset/design grammar remains code. Core has no Phoenix, Oban, server, DB, Node, or catalog runtime dependency.

### Integration Points

- New `lib/rendro/catalog.ex` owns the ordered 32-cell registry, render dispatch, manifest generation, and static validation.
- New `lib/mix/tasks/rendro/catalog/{gen,check}.ex` expose the conventional task boundary.
- New `assets/rendro/catalog.json` and `assets/rendro/catalog/<family>/<brand>/` form the committed public artifact contract consumed by Phase 128.
- `priv/quality/rubric_scores.json`, its schema, `SIGN-OFF.md`, and `rubric_manifest_contract_test.exs` gain additive catalog-disposition/hash/freshness coverage.
- The required deterministic lane verifies registry shape, exact count/order, complete PDF hashes/page counts, safe paths, and quality coverage; pinned-PDFium raster comparison and human review remain bounded advisory activities.

</code_context>

<specifics>
## Specific Ideas

- The catalog tells a domain-first comparison story: start with the strong unbranded baseline, then show each suitable synthetic brand/preset in adjacent light/dark pairs.
- A preview looks like a real sheet of paper with native proportions, not a generic rounded SaaS card or cropped screenshot.
- Phase 128 can say `Preview: page 1 of 3` and `Exact pre-rendered Editorial · #6E3CB8 · dark preview.` without exposing font registration, fixture loading, renderer internals, or scoring schema mechanics.
- Quality status is three honest user-facing states: passing scored evidence, failing scored evidence, and explicitly not-yet-scored evidence. Missing or stale is a build failure, not a fourth publishable state.

</specifics>

<deferred>
## Deferred Ideas

- Phase 128 owns the accessible static browse/filter/configure/copy UI, URL state, closed accent palette presentation, exact-preview disclosure, shared code snippet template, `mix rendro.gen.theme`, and Livebook extension.
- Phase 129 owns public guide/README/HexDocs/support-matrix closure and catalog/configurator claim-language tripwires.
- Every-page browsing, PDF download/viewer behavior, arbitrary color preview approximation, a live renderer, server persistence, accounts, and saved themes remain outside this phase and milestone.
- Automated or LLM-assigned taste scores remain excluded; only deterministic artifact checks are automated.
- Expanding beyond 32 cells or changing the curated pair matrix requires an explicit future product decision with a new cost/review budget, not fixture-driven accretion.

</deferred>

---

*Phase: 127-public-example-catalog-quality-ratchet*
*Context gathered: 2026-08-17*

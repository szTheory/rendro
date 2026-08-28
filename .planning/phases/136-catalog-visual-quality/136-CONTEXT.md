# Phase 136: Catalog Visual Quality - Context

**Gathered:** 2026-08-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair and re-review only Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light and dark, and Brutalist Ticket light and dark. The six cells must reach content hierarchy 5 and at least 4 in every other scored visual dimension through current exact-SHA pinned-PDFium evidence and named human review. The phase preserves the 32-cell catalog, twenty explicitly unscored cells, unrelated rendered bytes, public APIs, the pure-Elixir core, deterministic/advisory authority separation, and dark output's screen-oriented `print_safety: false` boundary. It adds no recipe, preset, catalog cell, runtime dependency, compliance claim, Studio surface, or new document-layout capability.

</domain>

<decisions>
## Implementation Decisions

### Target Isolation and Architecture
- **D-01:** Treat the six catalog IDs as an exact change allowlist. The implementation must prove that those six cells changed and the other 26 catalog cells stayed byte-identical.
- **D-02:** Keep catalog identity knowledge in dev-only catalog tooling. Core recipe modules must not branch on catalog IDs, phase numbers, brands, or preset names; they may consume only generic internal presentation data such as palette, typography, column, or layout profiles selected by the catalog tooling.
- **D-03:** Reuse the existing data-first recipe option/theme seams and the unchanged `build -> compose -> measure -> paginate -> render -> validate` engine. Do not add raster overlays, PDF post-processing, a second catalog renderer, or a parallel layout path.
- **D-04:** Add no public API solely for this repair. Keep Phoenix, Plug, Ecto, Oban, databases, browsers, and new runtime/package dependencies out of the phase; none belongs in the pure document-layout or evidence problem.
- **D-05:** Preserve selectable text, caller data, existing recipe semantics outside the target profiles, deterministic measurement, and exact no-theme/unrelated-theme bytes. The exact private profile names and plumbing are implementation details, but their blast radius must remain provably limited.

### Corporate Classic Invoice Dark and Minimal Mono Statement Dark
- **D-06:** Repair low-contrast labels through target-scoped semantic primary and secondary text treatments. Do not retune `Rendro.Theme.dark/1` or any preset globally; a global change would alter unscored and non-target dark cells and still would not repair raw default-black call sites reliably.
- **D-07:** Use primary ink for functional labels and table headings. Use a deliberate secondary tone for dates, addresses, terms, opening/context balances, subtotal/tax support text, footers, and other subordinate facts. No information-bearing label may remain near-background or rely on hue alone.
- **D-08:** Preserve the existing focal anchors: `Total Due` remains the sole display-size focal element in Corporate Classic Invoice dark, and boxed `Closing Balance` remains the sole display-size focal element in Minimal Mono Statement dark. Raising subordinate contrast must not flatten hierarchy.
- **D-09:** Preserve geometry, data, fonts, pagination, accent meaning, and dark `print_safety: false`. Contrast ratios may guide screen readability, especially for small text, but they do not authorize a WCAG, PDF/UA, accessibility, viewer-support, or print claim.

### Swiss Payslip Light and Dark
- **D-10:** Replace the target's paired seven-column earnings/deductions ledger with two sequential full-width three-column tables: `Earnings | Current | YTD`, followed by `Deductions | Current | YTD`.
- **D-11:** Preserve every caller-supplied description verbatim. Do not abbreviate, normalize, jurisdiction-filter, or replace realistic payroll labels to make the fixture fit; solve the geometry rather than hiding the defect in copy.
- **D-12:** Give each description column shared/flexible width and each Current/YTD amount column an explicit measured width. Amounts remain right-aligned and atomic. Do not shrink text below the established Swiss role merely to force density.
- **D-13:** Use identical structure and geometry in light and dark. Header text, surface treatment, rules, and body text must use semantic palette roles so the dark header never falls back to raw black. Dark remains screen-oriented and non-print-safe.
- **D-14:** Keep Net Pay uniquely dominant and preserve the final `Gross Pay - Total Deductions = Net Pay` reconciliation. The reconciliation stays with the final ledger rows; continued tables repeat their own headers without orphaned section headings.
- **D-15:** Use the engine's measured row heights and native pagination for both tables. Preserve Unicode fallback, unbroken money tokens, determinism, and existing failure semantics; do not introduce hand-positioned or guessed-capacity layout.

### Brutalist Ticket Light and Dark
- **D-16:** Keep all four supplied placement fields in source order: Section `GA`, Row `H`, Seat `24`, Gate `B`. Gate is present; the current image creates a visual-association defect rather than a missing-data case.
- **D-17:** Retain one left-to-right locator row and tune the target presentation so `GA` is atomic, every label sits clearly above its value, and Seat `24` cannot read as `24B` with Gate `B`. Preserve the placement group as the page's dominant hierarchy.
- **D-18:** Do not delete Gate from the shared Aurora fixture, introduce blank placeholders, reorder fields, or create a two-row/archetype-responsive locator system. Those approaches either change a non-target default ticket or add a new capability beyond this repair.
- **D-19:** Use identical light/dark geometry. In dark, strengthen muted labels, the reference/stub, perforation/rules, and terms only enough for fast screen scanning while retaining the Brutalist rectilinear motif and `print_safety: false`.

### Review, Truth, and Canonical Publication
- **D-20:** Produce one validated `review` bundle for one immutable candidate SHA through the generic `Catalog Evidence` workflow. Verify manifest, checksums, control/candidate/HEAD identity, renderer version and executable hash, run, attempt, roles, and counts before interpreting images.
- **D-21:** Review full-size images in family-paired order: unchanged Corporate Classic Invoice light control then dark target; unchanged Minimal Mono Statement light control then dark target; Swiss Payslip light then dark; Brutalist Ticket light then dark. Thumbnails and prior hashes are navigation aids, never review authority.
- **D-22:** Record scores, justifications, reviewer identity, date, source-PDF hash, PNG hash, source SHA, renderer identity, run, and provenance independently per target cell. Do not average scores across a family or infer visual approval from successful generation.
- **D-23:** Distinguish the Phase 136 visual threshold from the manifest's complete `passed` arithmetic. Every target must reach hierarchy 5 and all other scored visual dimensions at least 4 with reading order preserved. Dark records retain `print_safety: false`; they must not be forced to `passed: true`, relabeled print-safe, or given a synthetic accessibility promotion merely because their screen visual dimensions meet the phase target.
- **D-24:** If any target misses a visual threshold, keep that cell's actual scores and unpromoted disposition and rework only its bounded target profile. Do not lower thresholds, average the miss away, or update reviewer-owned fields during candidate generation.
- **D-25:** Treat per-cell review truth as granular but canonical publication as atomic for the phase. Materialize/check the canonical 32-cell catalog only after all six targets meet the Phase 136 visual thresholds and the changed-ID/unchanged-control proof passes.
- **D-26:** Keep visual review advisory and human-owned while objective completion remains reproducible: deterministic checks prove scope, structure, hashes, arithmetic, and provenance; the named review record supplies visual judgment without becoming a blocking hidden UAT state.

### the agent's Discretion
- Choose exact internal profile names, data shapes, module/function names, numeric column widths, font sizes within the selected theme roles, and secondary dark tones.
- Choose plan and commit boundaries, provided target-isolation proof lands before canonical materialization and visual changes remain separate from reviewer-owned score/provenance updates.
- Choose focused test filenames and fixture construction. Tests must cover the actual six IDs, representative failure controls, long labels, widest money tokens, dark semantic headers, ticket token atomicity, repeat headers/pagination, two-render determinism, and all 26 unchanged catalog controls.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope, Governance, and Prior Decisions
- `.planning/ROADMAP.md` — Phase 136 goal, six-cell boundary, success criteria, and dependency on the generic evidence lane.
- `.planning/REQUIREMENTS.md` — CATALOG-10 through CATALOG-13 plus milestone-wide compatibility, truthful-claim, and no-expansion constraints.
- `.planning/PROJECT.md` — Current product posture, pure-core/data-first architecture, public API and unrelated-byte contract, and milestone exclusions.
- `.planning/STATE.md` — Accumulated catalog scope, evidence-lane, completion-coverage, and Phase 132-135 decisions.
- `.planning/QUALITY.md` — Current ledger findings, owner phase, verification, disposition, and closure vocabulary.
- `.planning/quality/baselines/132-initial.json` — Source-bound initial catalog and quality evidence to compare without rewriting history.
- `.planning/phases/135-test-ci-cd-simplification/135-CONTEXT.md` — Generic workflow, one-bundle contract, candidate/reviewer authority separation, and Phase 136 handoff.
- `.planning/research/ARCHITECTURE.md` — Data-first bounded repair rule, catalog evidence flow, and prohibition on catalog-specific drawing forks or broad refactor mixing.
- `.planning/research/FEATURES.md` — Six-cell visual closure outcome and anti-features.
- `.planning/research/PITFALLS.md` — Visual overclaim, stale-image review, generated-score, and authority-loss footguns.
- `.planning/research/SUMMARY.md` — v2.14 phase sequencing and narrow catalog outcome.

### Current Catalog and Evidence Authority
- `.github/workflows/catalog-evidence.yml` — Exact-SHA read-only review/canonical workflow and bounded bundle production.
- `.github/workflows/CATALOG-EVIDENCE.md` — Supported dispatch, validation, review, failure, and canonical-materialization operator flow.
- `priv/pdfium_pin.json` — Renderer version and binary SHA-256 authority.
- `priv/quality/rubric_scores.json` — Current six target records, frozen dimensions/thresholds, exact gaps, hashes, and reviewer-owned dispositions.
- `priv/schemas/rubric_scores.schema.json` — Structural score/disposition contract and complete `passed` arithmetic.
- `priv/quality/SIGN-OFF.md` — Current and superseded review provenance, full-size family ordering, and bounded-claim language.
- `assets/rendro/catalog.json` — Current canonical 32-cell manifest and quality projection.
- `dev/rendro/catalog.ex` — Literal catalog membership, source-document construction, `catalog_layout` seam, target render generation, quality projection, and changed/unchanged classification.
- `dev/rendro/catalog_review_payload.ex` — Candidate-only identity payload, closed reviewed IDs, and prohibition on generated quality fields.
- `dev/rendro/catalog_review_reconciliation.ex` — Exact-order identity and local PNG/hash/dimension binding.
- `dev/rendro/catalog_evidence_bundle.ex` — Manifest-rooted review/canonical evidence bundle validation.
- `test/rendro/catalog_test.exs` — 32-cell membership, twenty-unscored, quality, candidate, and rendered contract coverage.
- `test/rendro/catalog_review_payload_contract_test.exs` — Fail-closed review-payload authority and exact target/control identities.
- `test/rendro/catalog_raster_review_test.exs` — Pinned PDFium full-size review artifacts and multipage proofs.
- `test/docs_contract/rubric_manifest_contract_test.exs` — Schema, threshold, gate, justification, and overclaim contracts.
- `test/docs_contract/catalog_quality_contract_test.exs` — Catalog quality projection and reviewer-authority contracts.

### Recipe, Theme, and Fixture Surfaces
- `lib/rendro/recipes/invoice.ex` — Corporate Classic target label/table/totals seams and Invoice pagination/compatibility boundaries.
- `lib/rendro/recipes/statement.ex` — Minimal Mono target raw table header, semantic cell text, closing-balance anchor, and statement pagination.
- `lib/rendro/recipes/payslip.ex` — Swiss seven-column ledger, fixed/share column widths, atomic money, Unicode fallback, reconciliation, pagination, and semantic palette/typography seams.
- `lib/rendro/recipes/ticket.ex` — Equal-share placement grid, catalog layout capacity, locator hierarchy, stub/reference/terms, geometry, and semantic seams.
- `lib/rendro/recipes/table_cell.ex` — Theme-aware table cell construction reusable for semantic headers.
- `lib/rendro/recipes/palette.ex` — Existing recipe palette resolution and override precedence.
- `lib/rendro/theme.ex` — Stable Theme field shape, dark screen-only boundary, semantic roles, and no-overclaim contract.
- `lib/rendro/theme/presets.ex` — Swiss, Corporate Classic, Minimal Mono, and Brutalist typography/color/spacing/rule tokens and font registration.
- `priv/examples/payslip/northline-logistics/payslip.json` — Exact Swiss target data whose descriptions and amounts must remain verbatim.
- `priv/examples/payslip/DOMAIN.md` — Payslip domain language and realistic anatomy.
- `priv/examples/ticket/aurora-live/ticket.json` — Shared Aurora data proving Section `GA`, Row `H`, Seat `24`, and Gate `B` are all present.
- `priv/examples/ticket/DOMAIN.md` — Ticket holder/gate-agent reading tasks and placement/reference anatomy.

### Current Brand, Voice, Personas, and Ecosystem DNA
- `brand/README.md` — Current brand source hierarchy; supersedes the old prompt-era brand book for operational visual guidance.
- `brand/tokens/tokens.json` — Current semantic light/dark tokens and warm-neutral dark system.
- `brand/copy/VOICE.md` — Senior-maintainer/typographer/SRE voice, truthful boundaries, and what/where/why/next diagnostics.
- `brand/audit/AUDIT.md` — Current brand pressure test, design principles, dark-mode lessons, and overclaim cautions.
- `prompts/rendro-gsd-seed.md` — Core value, Phoenix SaaS/back-office/SRE personas, JTBD, pure-core constraint, and deterministic/advisory posture.
- `prompts/rendro-oss-dna.md` — Elixir OSS engineering, test, package, release, and truthful-evidence lessons.
- `prompts/rendro-integration-opportunities.md` — Consumer-first optional-integration and coupling policy; informative without adding integrations to Phase 136.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Prawn/ReportLab/fpdf2/Typst and broader ecosystem lessons on explicit layout, pagination, tables, DX, visual snapshots, and truthful scope.

No external specification or ADR is authoritative for this phase. External design/payroll/PDF-layout research informed the selected decisions, but repository-local contracts above govern planning and implementation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `dev/rendro/catalog.ex` already owns literal ordered membership, an opt-in `catalog_layout` seam, source-document construction, exact changed/unchanged classification, and canonical projection; it is the natural owner of the exact six-ID treatment selection.
- Recipe `:palette` and `:typography` overrides plus theme semantic roles provide generic data seams for target treatments without public API growth or PDF post-processing.
- `Rendro.measure_rows/4`, explicit `{:fixed, width}` / `{:share, weight}` columns, shared pagination chunking, and repeatable table headers support the split Payslip layout deterministically.
- Ticket's existing equal-share placement table, generic 1-to-4 entry contract, `catalog_layout` capacity, and measured fonts permit a bounded one-row locator repair without an archetype fork.
- The generic Catalog Evidence workflow, bundle validator, review payload, reconciliation module, rubric schema, and docs contracts already separate generation identity, human judgment, and publication authority.

### Established Patterns
- Core remains pure; dev-only catalog tooling may orchestrate internal profiles while recipes remain data-first and unaware of catalog identity.
- Public APIs and unrelated rendered bytes are contracts. A target allowlist and unchanged-control hashes are stronger than an aesthetic claim that the diff is probably narrow.
- Semantic roles, not inline color literals or raster edits, express readable dark output. Light/dark structure stays identical unless the phase explicitly repairs geometry in both members of a target pair.
- Real caller content is preserved. Layout adapts through measured widths, sectioning, and pagination rather than abbreviation, clipping, or guessed capacity.
- Machine evidence proves identity and scope; named human review owns visual scores; dark print/accessibility limits remain explicit even after screen-quality improvement.

### Integration Points
- Catalog target selection and internal presentation profiles connect in `dev/rendro/catalog.ex` before each recipe `document/2` call.
- Invoice and Statement need generic opt-in semantic label/header rendering that stays inactive for every non-target call.
- Payslip needs a generic target-selected sequential-ledger profile integrated with its existing measurement, chunking, reconciliation, and Unicode font path.
- Ticket needs a generic target-selected placement-fit profile integrated with its existing one-row table, font metrics, and stub/terms geometry.
- Focused source/tests feed one exact-SHA `review` bundle; reviewer-owned rubric updates then feed `canonical` generation/checking and the existing 32-cell manifest.

</code_context>

<specifics>
## Specific Ideas

- Corporate Classic Invoice dark should read as formal and calm: primary labels become immediately scannable, secondary facts remain subordinate, and blue `Total Due` remains the unmistakable focal amount.
- Minimal Mono Statement dark should keep its operational ledger character: the four table headings become readable while the boxed closing balance remains uniquely dominant.
- Swiss Payslip should resemble a credible payroll document rather than a compressed comparison grid: full-width Earnings and Deductions regions, intact descriptions, disciplined money columns, and one gross-to-net reconciliation.
- Brutalist Ticket should retain its blunt one-row locator motif: `GA | H | 24 | B`, with each token atomic and unmistakably paired to Section, Row, Seat, and Gate.
- Review should feel like a sealed evidence packet: validate one immutable bundle, inspect full-size family pairs, record cell-specific truth, prove the six-ID diff, and materialize only after the phase threshold is satisfied.
- Design lenses applied together: legibility, scanability, content integrity, hierarchy, visual cohesion, dark/light consistency, deterministic pagination, performance, maintainability, provenance/security, zero-migration developer experience, and truthful scope.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Global dark-token retuning, recipe-wide semantic-label cleanup, generalized responsive ticket layouts, new public layout options, and broader catalog review remain outside Phase 136 rather than becoming implied follow-up work.

</deferred>

---

*Phase: 136-catalog-visual-quality*
*Context gathered: 2026-08-27*

# Phase 129: Docs & manifest closure - Context

**Gathered:** 2026-08-19
**Status:** Ready for planning
**Decision mode:** User selected all four gray areas and delegated a one-shot recommendation. Four typed `gsd-advisor-researcher` studies compared guide structure, example pedagogy, claim presentation, and discoverability against the live codebase, the current brand system, applicable `prompts/` research, Elixir/HexDocs conventions, and successful cross-ecosystem precedents.

<domain>
## Phase Boundary

Phase 129 reconciles the already-shipped preset, catalog, configurator, generator, and Livebook surfaces into Rendro's public documentation and proof manifests. It adds the canonical preset learning path, README/HexDocs routing, the proof-backed `theming.presets` support-matrix contract, the regenerated public-API manifest, and a fail-loud cross-surface docs-contract lane.

This phase documents and proves shipped behavior. It does not change preset values, expand the 32-cell catalog, redesign the configurator, add live rendering or a docs application, alter the public Theme API, introduce a server/build system/dependency, or promote any design-quality, accessibility, PDF/UA, WCAG, universal viewer-fidelity, or print-safety claim.

</domain>

<decisions>
## Implementation Decisions

### Canonical guide architecture

- **D-01 — Dedicated preset journey:** create `guides/presets.md` as the canonical task-oriented entry point for presets, the public catalog/configurator, generated theme modules, and the existing preset Livebook path. — **Reversibility: costly** — its HexDocs URL and inbound README/guide links become a published reader contract.
- **D-02 — Keep manual theming focused:** retain `guides/theming.md` as the deeper manual-token and `from_brand/2` reference. Add a compact, early "use a preset first" link to `guides/presets.md`; do not duplicate the preset tutorial or turn the theming guide into a second hub.
- **D-03 — No standalone docs portal:** do not build a new landing application, gallery page, navigation system, or interactive theme chooser. ExDoc's README main page, grouped extras, static configurator asset, and Livebook already provide the right surfaces.
- **D-04 — Current brand wins:** follow `brand/README.md`, `brand/copy/VOICE.md`, `brand/copy/marketing-copy.md`, and current tokens when guidance conflicts with `prompts/Rendro Brand Book.txt`. The applicable `prompts/` research remains useful for personas, ecosystem lessons, product boundaries, and JTBD history.

### Teaching depth and developer journey

- **D-05 — Hybrid teaching model:** teach one complete executable golden path, then expose the six shipped presets in a compact decision/reference table, followed by job-specific routes. Do not publish six near-duplicate tutorials or a screenshot-heavy exhaustive matrix.
- **D-06 — Canonical first success:** the golden path is Invoice × Swiss × `#2C6BED` × light. It shows the full working order: choose `preset`, build `Theme.preset/2` with an explicit accent and mode, pass the theme to the recipe, then call `Rendro.Theme.Presets.register_fonts/2` on the document before rendering. This must remain copy-pasteable and contract-tested.
- **D-07 — One source string, many explanations:** mark the guide's working snippet and assert byte equality with the formatter-owned canonical usage output already shared by the configurator and Livebook. Surrounding prose may differ by job, but JavaScript, Markdown, Livebook, and generated source must not independently assemble Elixir syntax.
- **D-08 — Six-row chooser, not a ranking:** include one concise row for Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono, and Brutalist. Each row explains its structural direction, font-role character, density/geometry tendency, and likely business-document fit. Use neutral "choose a direction" language; never rank a preset as universally best or visually approved.
- **D-09 — Progressive task routes:** after the golden path, route readers by job: use the configurator to browse the bounded evidence and copy a selection; use `mix rendro.gen.theme` to commit an application-owned fixed theme module and `--check` it; use the Livebook to render/inspect/download real bytes; use Theming for manual token work; use Branding for caller-owned logos/fonts; use API Stability/Support Boundaries for operational claims.
- **D-10 — Preserve distinct surface jobs:** the configurator is browse → pick → copy, the generator is adopt → commit → drift-check, the Livebook is learn by executing one real render, and the guide is the explanatory map. None should expand into a duplicate of another.
- **D-11 — User-facing language first:** explain visible outcomes before internals. Introduce `Theme.preset/2`, the explicit font bridge, exact/representative preview states, and generated modules only when the reader needs them; do not expose artifact-generation internals, hash pipelines, or registry implementation details in the quick-start flow.

### Claim language and evidence boundaries

- **D-12 — Layered truth model:** use one canonical, proof-linked `theming.presets` support-matrix row for the complete contract, plus short state-specific microcopy where readers choose a preset, view dark output, inspect a catalog/configurator preview, or see a quality disposition. Avoid both a hidden central disclaimer and repetitive warning walls.
- **D-13 — Canonical preset boundary copy:** immediately after the first preset example, state: "Each preset is a strong starting point: choose a style, supply your accent, and review the rendered document for your content. Presets are not design-quality, accessibility, PDF/UA, WCAG, or print-safety guarantees." README uses a shorter positive entry sentence and links to this complete boundary.
- **D-14 — Preserve exact local disclosures:** dark states retain `Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim.` Preview states retain the mutually exclusive exact, representative-accent, and unavailable wording already locked in Phase 128; copied code always describes the requested selection rather than the representative raster.
- **D-15 — Honest quality labels:** public quality projections are exactly equivalent to `Scored — passes current rubric`, `Scored — needs work`, or `Not yet scored`; never use "approved," "certified," or an undifferentiated quality badge. Current flagships remain honestly `needs_work` unless fresh evidence changes their stored verdict through the existing quality workflow.
- **D-16 — Support-row semantics:** `theming.presets` must distinguish proven capabilities from unsupported guarantees. Capabilities cover the six strict preset constructors, deterministic rendering, explicit caller-owned font registration, bounded catalog previews, canonical snippet/codegen paths, and the focused Livebook example, each tied to an actual test, manifest, or generated artifact. Boundaries explicitly keep design-quality, accessibility/PDF-UA, WCAG contrast, print safety, universal viewer fidelity, exhaustive catalog coverage, and live arbitrary preview unsupported. Exact JSON subkeys may follow existing support-matrix conventions, but the semantic distinctions are locked. — **Reversibility: costly** — public docs and tests will consume this row as the canonical claim contract.
- **D-17 — Evidence is layered, not conflated:** deterministic bytes, pinned raster observations, bounded human rubric dispositions, and documentation claims remain separate evidence levels. A 504-entry valid snippet vocabulary is not 504 visually reviewed outputs; a page-one catalog preview is not a complete-document viewer; a representative preview is not the caller's exact accent.
- **D-18 — Accessible documentation:** use semantic headings, descriptive links, text alternatives/captions for meaningful preview images, and visible text for warnings/statuses rather than color or tooltips alone. Keep paragraphs and tables scannable on narrow screens; no new docs UI theme controls are needed.

### README and HexDocs discoverability

- **D-19 — Layered minimal route:** add a compact README entry block after the main feature introduction and before the legacy gallery/artifact detail. It should say what the reader can accomplish, establish the starting-point boundary in one sentence, and offer direct routes to the presets guide and static configurator rather than reproducing the tutorial.
- **D-20 — One route per job:** the README/HexDocs discovery path is: discover on GitHub/Hex → open Presets → browse bounded previews/configurator → copy the canonical snippet or generate a committed module → try the Livebook → consult support boundaries. Links should name the outcome (for example, "Choose a preset" or "Try a rendered invoice"), not implementation filenames.
- **D-21 — ExDoc placement:** add `guides/presets.md` beside `guides/theming.md` in the existing `Guides` extras group. Retain README as ExDoc's main page and `guides/api_stability.md` as the ongoing support-boundary destination; do not create a competing hub group.
- **D-22 — Link integrity is product behavior:** contract-test the source-tree, Hex package, and generated ExDoc paths for the presets guide, configurator asset, and Livebook. The planner may choose the precise relative-link syntax that works in all three contexts; broken packaged/HexDocs asset links are a phase failure.

### Manifest and guardrail closure

- **D-23 — Regenerate, do not hand-edit, the API manifest:** run `mix rendro.api.gen` and let the existing public-API drift contract prove `Rendro.Theme.preset/2` is present with the correct tier/shape. Do not broaden the public API while reconciling the manifest.
- **D-24 — One cross-surface claims lane:** add one dedicated Phase-129 docs-contract lane that owns preset public-copy coherence across README, `guides/presets.md`, `guides/theming.md`, the Livebook, support matrix, and the existing catalog/configurator projections. Existing catalog, configurator, theming, accessibility-overclaim, and public-API lanes remain the behavioral owners of their narrower contracts.
- **D-25 — Fail both ways:** the new lane asserts required positive language, canonical snippet/link wiring, support-row proof/boundary keys, and allowed quality/preview labels; it also rejects forbidden guarantees and misleading terms. Tests should prove their own teeth with mutated/missing fixtures where the existing docs-contract style supports it, rather than relying only on broad substring checks.
- **D-26 — Lockstep lane accounting:** advance the registered docs-contract lane count from 26 to 27 and update `scripts/verify_docs.exs`, `test/guardrails/required_checks_contract_test.exs`, and `priv/guardrails/required_status_checks.json` together in the same commit. Reconcile stale lane-count prose in the guardrail manifest. This remains inside the existing deterministic `test`/`mix ci.fast` context; do not add a new required GitHub status check or move advisory browser/raster work into required CI.
- **D-27 — Completion bar:** `mix ci.fast` must pass end to end, including package construction, compiled/evaluated docs examples, ExDoc warnings-as-errors, public-API drift, support-matrix validation, the 27-lane docs registry, link/package checks, and all no-overclaim assertions.

### the agent's Discretion

The planner may choose section headings, compact preset-table columns, exact support-matrix subkey names consistent with the existing JSON vocabulary, the new claims-test module name, and the safest cross-context ExDoc asset-link syntax. It may refine microcopy while preserving the locked meanings and canonical phrases above. It may not collapse the two guides, duplicate snippet generation, hide the explicit font bridge, rank presets as visually approved, weaken exact/representative/no-preview disclosure, add a docs application, or create a new required CI context.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and prior decisions

- `.planning/ROADMAP.md` — Phase 129 goal, dependencies, success criteria, and final-closure boundary.
- `.planning/REQUIREMENTS.md` — DOCS-01, milestone-wide no-overclaim contract, and explicit exclusions.
- `.planning/PROJECT.md` — Phoenix-first audience, deterministic core, documentation-as-contract posture, and milestone decisions.
- `.planning/STATE.md` — current phase position and accumulated Phase 125–128 decisions.
- `.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-CONTEXT.md` — strict six-preset vocabulary, explicit font-registration ownership, and deterministic/advisory evidence separation.
- `.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-CONTEXT.md` — repaired visual baselines and bounded dark-mode claim.
- `.planning/phases/127-public-example-catalog-quality-ratchet/127-CONTEXT.md` — exact 32-cell catalog, page-one evidence, quality dispositions, and no-overclaim boundaries.
- `.planning/phases/128-static-configurator-theme-codegen-livebook/128-CONTEXT.md` — canonical snippet, exact/representative/no-preview behavior, generator/Livebook jobs, and cross-surface proof bar.
- `.planning/phases/128-static-configurator-theme-codegen-livebook/128-UI-SPEC.md` — locked configurator content, disclosure, accessibility, state, and static-product contract.

### Current brand, voice, personas, and research

- `brand/README.md` — current brand source-of-truth order; supersedes old prompt brand-book details on conflict.
- `brand/copy/VOICE.md` — evidence-first voice and what/where/why/next error/copy pattern.
- `brand/copy/marketing-copy.md` — current public feature, limitation, and CTA language.
- `.planning/research/JTBD-USER-FLOWS.md` — current developer discovery, evaluation, adoption, and handoff journeys.
- `prompts/rendro-gsd-seed.md` — foundational personas, Phoenix-first JTBD, architecture, and truthful-scope vision.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Elixir ecosystem and popular cross-language PDF-library lessons.
- `prompts/rendro-oss-dna.md` — package, API, CI, and documentation conventions learned from sibling Elixir libraries.
- `prompts/rendro-integration-opportunities.md` — optional-integration and core-coupling policy.
- `prompts/Rendro Brand Book.txt` — historical UI/copy direction only; current `brand/` sources take precedence.

### Public documentation and navigation

- `README.md` — GitHub/Hex/HexDocs main discovery surface and current guide list.
- `guides/theming.md` — existing manual theme-token, brand orthogonality, dark-boundary, and gallery guide.
- `guides/api_stability.md` — canonical public support and stability boundary destination.
- `guides/branding.md` — caller-owned font/logo registration path the presets guide cross-links.
- `guides/livebook/first_invoice.livemd` — existing executable preset learning path and exact shared snippet consumer.
- `mix.exs` — ExDoc main page, assets, extras/groups, package files, and `mix ci.fast` contract.

### Shipped preset, catalog, configurator, and generator surfaces

- `lib/rendro/theme.ex` — public `Theme.preset/2` delegation and stable Theme value surface.
- `lib/rendro/theme/presets.ex` — canonical six preset atoms, token grammar, font descriptors, and explicit registration bridge.
- `lib/rendro/theme/snippet.ex` — canonical formatter shared by configurator, generated module, and Livebook.
- `lib/mix/tasks/rendro/gen/theme.ex` — consumer-owned module generator and read-only `--check` behavior.
- `assets/rendro/catalog.json` — ordered preview identity, page-one evidence, dark disclosure, captions/alt text, and quality projection.
- `assets/rendro/configurator/index.html` — static configurator document structure and public entry asset.
- `assets/rendro/configurator/configurator.js` — exact/representative/no-preview and copy/status microcopy implementation.
- `assets/rendro/configurator/index.json` — closed 504-selection snippet vocabulary and labels.
- `priv/quality/SIGN-OFF.md` — human quality-review scope and honest current dispositions.
- `priv/quality/rubric_scores.json` — exact scored/unscored evidence relation and current verdicts.

### Manifests and enforceable contracts

- `priv/support_matrix.json` — canonical support surface; Phase 129 adds `theming.presets` beside the existing light/dark rows.
- `priv/schemas/support_matrix.schema.json` — structural validation contract for support-matrix additions.
- `priv/public_api.json` — generated public API manifest to reconcile with `Theme.preset/2`.
- `lib/mix/tasks/rendro/api.gen.ex` — canonical public-API manifest generator.
- `test/docs_contract/public_api_contract_test.exs` — generated-manifest equality and tier/hidden-surface proof.
- `test/docs_contract/theming_claims_test.exs` — existing light/dark no-overclaim pattern.
- `test/docs_contract/catalog_manifest_contract_test.exs` — preview/disclosure/quality manifest contract.
- `test/docs_contract/catalog_quality_contract_test.exs` — scored/unscored freshness and honest quality projection.
- `test/docs_contract/configurator_resolver_contract_test.exs` — exact/representative/no-preview and copied-source boundary.
- `test/docs_contract/configurator_static_contract_test.exs` — static, safe, accessible configurator source contract.
- `test/docs_contract/accessibility_overclaim_test.exs` — project-wide accessibility-claim tripwire.
- `scripts/verify_docs.exs` — registered docs-contract lane inventory.
- `test/guardrails/required_checks_contract_test.exs` — lane-count and required/advisory CI lockstep assertions.
- `priv/guardrails/required_status_checks.json` — public CI/guardrail manifest whose docs-lane description must stay truthful.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Rendro.Theme.Snippet`: already owns canonical preset/recipe/module source formatting; docs should consume or byte-compare against it instead of constructing another example.
- `guides/livebook/first_invoice.livemd`: already demonstrates one real themed render with preview/download and is the right experiential endpoint.
- `assets/rendro/catalog.json` and configurator assets: already carry safe paths, dimensions, alt/caption, quality labels, dark disclosure, and preview relationship behavior; Phase 129 needs links and contract coverage, not a replacement UI.
- Existing docs-contract tests: already model executable examples, generated-manifest equality, forbidden-claim checks, and fail-loud semantic validation.

### Established Patterns

- README is the ExDoc main page; focused Markdown/Livebook extras sit in named groups and use progressive links rather than duplicating full guides.
- Public/runtime core stays pure; dev/docs artifacts consume core APIs, never the reverse.
- Generated manifests/assets are committed and checked byte-for-byte through explicit read-only commands.
- Claims are only as strong as their evidence: deterministic, advisory raster, and human-review lanes remain visibly separate.
- The current brand system is authoritative; historical prompt research supplies context but does not override living tokens or voice.

### Integration Points

- `README.md`, `guides/theming.md`, and `mix.exs` expose the new presets guide through GitHub, Hex packaging, and ExDoc.
- `priv/support_matrix.json` and `priv/public_api.json` close the two manifest gaps.
- `scripts/verify_docs.exs`, the new claims test, `required_checks_contract_test.exs`, and `required_status_checks.json` form one lane-count/guardrail transaction.
- `mix ci.fast` is the final deterministic closure gate; no new required CI context is necessary.

</code_context>

<specifics>
## Specific Ideas

- Preferred guide promise: **choose a direction → see bounded evidence → copy working Elixir → commit it safely → verify the boundary**.
- Preferred README language: "Curated presets are strong starting points; adjust them for your document and review the result." Follow with outcome-named links rather than a second tutorial.
- Preferred reader journey: Phoenix engineer discovers Rendro on Hex/GitHub, gets one successful branded Invoice render, compares the six directions without interpreting them as rankings, browses exact or disclosed representative previews, copies or generates application-owned code, tries the real Livebook render, then checks the support boundary before making operational/compliance assumptions.
- Relevant external precedents considered by the research agents: ExDoc extras/grouping, Plug's concise README route, Ecto's task-oriented Getting Started flow, Phoenix generators and `Mix.Generator`, Livebook's executable-notebook role, shadcn's visual-choice-to-generated-code handoff, WeasyPrint's use-case documentation, and W3C guidance for headings, meaningful links, and informative image alternatives. Adopt their progressive disclosure and copy-paste strengths without importing their framework scale or implying evidence Rendro does not have.

</specifics>

<deferred>
## Deferred Ideas

- A standalone documentation hub or richer interactive documentation shell may be reconsidered with the future live Studio, if multiple additional interactive surfaces make README → guide routing insufficient. It is not justified for the bounded v2.12 surfaces.
- New preset values, catalog cells, arbitrary-color live previews, exhaustive visual review, and a server-backed theme Studio remain outside Phase 129.

</deferred>

---

*Phase: 129-docs-manifest-closure*
*Context gathered: 2026-08-19*

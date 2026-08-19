# Phase 129: Docs & manifest closure - Research

**Researched:** 2026-08-19
**Domain:** ExDoc public-documentation contracts, generated manifests, and deterministic CI closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- D-01 — Dedicated preset journey: create guides/presets.md as the canonical task-oriented entry point for presets, the public catalog/configurator, generated theme modules, and the existing preset Livebook path. Its HexDocs URL and inbound README/guide links become a published reader contract.
- D-02 — Keep manual theming focused: retain guides/theming.md as the deeper manual-token and from_brand/2 reference. Add a compact, early use-a-preset-first link to guides/presets.md; do not duplicate the preset tutorial or turn the theming guide into a second hub.
- D-03 — No standalone docs portal: do not build a new landing application, gallery page, navigation system, or interactive theme chooser. ExDoc's README main page, grouped extras, static configurator asset, and Livebook already provide the right surfaces.
- D-04 — Current brand wins: follow brand/README.md, brand/copy/VOICE.md, brand/copy/marketing-copy.md, and current tokens when guidance conflicts with prompts/Rendro Brand Book.txt. Applicable prompts research remains useful for personas, ecosystem lessons, product boundaries, and JTBD history.
- D-05 — Hybrid teaching model: teach one complete executable golden path, then expose the six shipped presets in a compact decision/reference table, followed by job-specific routes. Do not publish six near-duplicate tutorials or a screenshot-heavy exhaustive matrix.
- D-06 — Canonical first success: Invoice × Swiss × #2C6BED × light. Show choose preset, build Theme.preset/2 with explicit accent and mode, pass theme to recipe, then call Rendro.Theme.Presets.register_fonts/2 before rendering. It remains copy-pasteable and contract-tested.
- D-07 — One source string, many explanations: mark the guide working snippet and assert byte equality with the formatter-owned canonical usage output shared by configurator and Livebook. Markdown, JavaScript, Livebook, and generated source must not independently assemble Elixir syntax.
- D-08 — Six-row chooser, not a ranking: Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono, and Brutalist each get one concise structural/font-role/density/business-fit row. Use neutral choose-a-direction language; never rank a preset as universally best or visually approved.
- D-09 — Progressive task routes: configurator browse/pick/copy; generator adopts/commits/drift-checks; Livebook executes a real render; Theming covers manual token work; Branding covers caller-owned logos/fonts; API Stability/Support Boundaries covers operational claims.
- D-10 — Preserve distinct jobs: configurator is browse → pick → copy, generator is adopt → commit → drift-check, Livebook is execute/inspect/download, guide is explanatory map. Do not duplicate surfaces.
- D-11 — User-facing language first: explain outcomes before internals; do not expose artifact-generation, hashes, or registry implementation in quick start.
- D-12 — Layered truth: one canonical proof-linked theming.presets support row plus local state-specific microcopy; neither hidden disclaimer nor warning wall.
- D-13 — Canonical boundary after first example: Each preset is a strong starting point: choose a style, supply your accent, and review the rendered document for your content. Presets are not design-quality, accessibility, PDF/UA, WCAG, or print-safety guarantees. README has a shorter positive entry sentence linking here.
- D-14 — Preserve exact disclosures: dark states retain Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim. Preview state wording remains exact/representative/unavailable; copied code describes requested selection, not representative raster.
- D-15 — Quality labels only: Scored — passes current rubric, Scored — needs work, or Not yet scored. Never approved/certified/undifferentiated badge. Existing needs_work flagships remain so without fresh workflow evidence.
- D-16 — Support-row semantics: theming.presets capabilities cover six strict constructors, deterministic rendering, explicit caller font registration, bounded catalog previews, canonical snippet/codegen, focused Livebook; boundaries keep design quality, accessibility/PDF-UA, WCAG contrast, print safety, universal viewer fidelity, exhaustive catalog coverage, and live arbitrary preview unsupported.
- D-17 — Keep deterministic bytes, pinned rasters, bounded human dispositions, and docs claims separate. A 504-entry snippet vocabulary is not 504 visually reviewed outputs; page one is not complete viewer evidence; a representative preview is not requested accent.
- D-18 — Accessible documentation: semantic headings, descriptive links, text alternatives/captions, visible warning/status text, narrow-screen scanability; no docs UI controls.
- D-19 — Add compact README entry after feature introduction and before legacy gallery; establish starting-point boundary and direct routes without second tutorial.
- D-20 — Discovery route is GitHub/Hex → Presets → bounded previews/configurator → canonical copy or committed module → Livebook → support boundaries. Links name outcomes, not filenames.
- D-21 — Add guides/presets.md beside guides/theming.md in existing Guides extras group. README remains ExDoc main and guides/api_stability.md remains support-boundary destination.
- D-22 — Link integrity is product behavior: contract-test source-tree, Hex package, and generated ExDoc paths for presets guide, configurator asset, and Livebook.
- D-23 — Regenerate, never hand-edit public API: run mix rendro.api.gen and retain existing drift proof for Theme.preset/2 with correct tier/shape. Do not widen API.
- D-24 — One cross-surface claims lane covers README, presets guide, theming guide, Livebook, support matrix, catalog/configurator projections. Existing narrower lanes retain ownership.
- D-25 — Fail both ways: assert required positive language, canonical snippet/link wiring, support proof/boundary keys, allowed quality/preview labels; reject guarantees/misleading terms; prove mutation teeth.
- D-26 — Lockstep accounting: 26 → 27 docs lanes; update scripts/verify_docs.exs, required_checks_contract_test.exs, and required_status_checks.json together. No new required GitHub status and no advisory work moved into required CI.
- D-27 — mix ci.fast green end-to-end: package, evaluated examples, ExDoc warnings-as-errors, public API drift, support validation, 27 docs lanes, link/package checks, no-overclaim assertions.

### the agent's Discretion

The planner may choose headings, compact table columns, support-matrix subkey names that fit existing JSON, claims-test module name, and safest cross-context ExDoc link syntax. It may refine microcopy while preserving meanings. It may not collapse guides, duplicate snippet generation, hide font bridge, rank presets, weaken preview disclosure, add docs application, or create a required CI context.

### Deferred Ideas (OUT OF SCOPE)

- Standalone documentation hub or richer interactive shell, possibly with future Studio.
- New preset values/cells, arbitrary-color live previews, exhaustive visual review, or server-backed theme Studio.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Reconcile presets/catalog/configurator into proof-backed public documentation and manifests without design-quality or accessibility guarantees. | Existing formatter, manifests, package/ExDoc configuration, contract lanes, and CI seams are identified below. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 129 is documentation-contract closure, not product design. Rendro.Theme.Snippet.usage_snippet/4 already produces the exact Invoice/Swiss/#2C6BED/light fragment, the Livebook byte-compares against it, and the configurator’s committed 504-record index is formatter-owned. The new guide must contract-test that canonical output rather than author another equivalent snippet. [VERIFIED: codebase grep]

The public manifest change is narrow. priv/public_api.json already lists Elixir.Rendro.Theme.preset/2 in the adapter tier, but must still be regenerated using mix rendro.api.gen and proven by the existing byte-identical drift test. priv/support_matrix.json has theming.light and theming.dark but no theming.presets; its schema permits additive nested objects. [VERIFIED: codebase grep]

**Primary recommendation:** Add one presets public-claims lane first, then use it to drive guide/README/ExDoc/package/manifest edits and make the 26→27 registry-and-guardrail transaction atomic. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Preset learning path and README routing | CDN / Static | — | Markdown extras and README are static ExDoc documentation. [VERIFIED: codebase grep] |
| Canonical code example | API / Backend | CDN / Static | Theme.Snippet owns source generation; docs display and test it. [VERIFIED: codebase grep] |
| Support/API claim truth | API / Backend | CDN / Static | Committed JSON manifests are validated by Elixir tests before docs consume them. [VERIFIED: codebase grep] |
| Configurator/catalog discovery | CDN / Static | Browser / Client | ExDoc copies assets; existing no-server configurator consumes them. [VERIFIED: codebase grep] |
| Closure verification | API / Backend | CI | mix ci.fast runs package build, tests, ExDoc, Credo, and Dialyzer. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Keep core pure; do not add Phoenix, Oban, or admin dependencies. [VERIFIED: AGENTS.md]
- Preserve deterministic versus advisory lane separation. [VERIFIED: AGENTS.md]
- Treat docs claims as contracts and never claim unsupported capability. [VERIFIED: AGENTS.md]
- Use planned GSD execution for subsequent file-changing work. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir/Mix | 1.19.5 / OTP 28 | Manifests, contracts, package, CI aliases. | Installed project runtime owns all required commands. [VERIFIED: local command] |
| ExDoc | project declares ~> 0.40 | README main, Markdown/Livebook extras, Guides grouping, asset copy, warnings-as-errors. | Officially supports extras, groups_for_extras, and assets; Rendro already uses them. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html] |

### Supporting

| Library / tool | Purpose | When to Use |
|----------------|---------|-------------|
| Rendro.Theme.Snippet | Canonical preset/module source and closed vocabulary. | Assert guide/Livebook formatter equality; never build syntax in prose/JS. [VERIFIED: codebase grep] |
| mix rendro.api.gen | Deterministic public API manifest generator. | Sole way to reconcile priv/public_api.json. [VERIFIED: codebase grep] |
| scripts/verify_docs.exs | Explicit semantic docs-lane runner. | Register exactly one new lane. [VERIFIED: codebase grep] |

**Installation:** None; this phase installs no external package. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

    Theme.Snippet ──> presets guide canonical fence ──> README outcome links
          │                    │
          ├──> Livebook parity └──> configurator/generator/support routes
          │
    Theme.preset/2 ──> mix rendro.api.gen ──> public_api.json ──> drift test
          │
    proof tests/artifacts ──> theming.presets ──> cross-surface claims lane
                                                     │
    verify_docs (27) ──> test context ──> mix ci.fast ──> Hex + ExDoc

Exact, representative-accent, and no-preview are distinct browser evidence states; the guide can link to them but cannot collapse them into a visual, print, accessibility, or quality guarantee. [VERIFIED: codebase grep]

### Recommended Project Structure

    guides/presets.md                         new task-oriented hub and canonical snippet
    guides/theming.md                         existing manual guide; concise outbound pointer
    test/docs_contract/presets_claims_test.exs recommended new Phase-129 lane

### Pattern 1: Formatter-owned executable docs

Add a marked Elixir fence in guides/presets.md. Extract its body in the new contract test and compare it byte-for-byte with Snippet.usage_snippet(invoice, swiss, #2C6BED, light); parse/evaluate it with the same realistic fixture binding used by theme/snippet tests. [VERIFIED: codebase grep]

    preset = :swiss
    theme = Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)
    document =
      invoice
      |> Rendro.Recipes.Invoice.document(theme: theme)
      |> Rendro.Theme.Presets.register_fonts(preset)

Source: lib/rendro/theme/snippet.ex. [VERIFIED: codebase grep]

### Pattern 2: Proof-backed support row

Add theming.presets beside light/dark using status, capabilities, and boundaries maps with supported/unsupported values. Assert required capability/boundary keys and their test/artifact proof paths in the new lane. Schema expansion is not required because existing support-matrix schema accepts additive nested properties. [VERIFIED: codebase grep]

Recommended capability keys: strict_six_preset_constructors, deterministic_rendering, explicit_font_registration, bounded_catalog_previews, canonical_snippet_and_codegen, focused_livebook_example. Recommended unsupported boundary keys: design_quality_guarantee, accessibility_pdf_ua_claim, wcag_contrast_claim, print_safety, universal_viewer_fidelity, exhaustive_catalog_coverage, live_arbitrary_preview. [VERIFIED: CONTEXT.md]

### Pattern 3: Package plus ExDoc link closure

Test three contexts separately: repository Markdown, Hex tarball, and generated ExDoc. A measured docs build copies assets/rendro/configurator and assets/rendro/catalog into the generated output, but does not copy brand/tokens/tokens.css because mix.exs maps only assets. The static entrypoint imports that missing stylesheet. [VERIFIED: local ExDoc build]

Plan consequence: add narrowly scoped package inclusions for assets/rendro/catalog, assets/rendro/catalog.json, assets/rendro/configurator, and brand/tokens/tokens.css. Keep guides (which already covers the preset guide and Livebook) and the existing launch assets. Do not ship brand/tokens/tokens.json, brand/tokens/tailwind.tokens.js, the broader brand directory, priv/quality, support matrix, guardrails, private schemas, or test-only raster material. Reuse HexBuildCache/tarball assertions. [VERIFIED: local Hex build]

### Anti-Patterns to Avoid

- Hand-written duplicate snippet. [VERIFIED: CONTEXT.md]
- Treating page-one raster or representative accent as complete/exact evidence. [VERIFIED: codebase grep]
- Promoting advisory browser/raster/Livebook verification into required CI. [VERIFIED: CONTEXT.md]
- Quality approved/certified language. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preset source | Markdown/JS string builder | Theme.Snippet.usage_snippet/4 | Owns font bridge, vocabulary, parsing, executable coverage. [VERIFIED: codebase grep] |
| Public API inventory | Manual JSON | mix rendro.api.gen | Existing deterministic byte drift test gives actionable diagnostics. [VERIFIED: codebase grep] |
| Required CI context | New workflow/status | scripts/verify_docs inside existing test context | D-26 forbids a new context. [VERIFIED: CONTEXT.md] |
| Tarball inspection | One-off shell logic | HexBuildCache established pattern | Avoids redundant package builds and proves shipped paths. [VERIFIED: codebase grep] |

## Common Pitfalls

### Link valid in checkout but broken in HexDocs

Current package allowlist omits configurator/catalog while docs copy assets; static entrypoint also imports a brand stylesheet excluded from tarball. Test tarball and generated docs path, not just source File.exists. Keep private evidence excluded. [VERIFIED: codebase grep]

### Canonical snippet drift

A guide can look valid while omitting register_fonts/2 or changing tuple/ordering. Extract the marker-bounded fence, assert byte equality, then parse/evaluate it. [VERIFIED: codebase grep]

### Vacuous or broad claim guard

Use existing theming/accessibility idiom: assert non-empty key/term lists, introduce synthetic mutation that fails, test exact allowed quality labels, and scope scanned public paths. [VERIFIED: codebase grep]

### Registry/guardrail mismatch

scripts/verify_docs.exs has exactly 26 entries and required_checks_contract_test asserts exactly 26. Update registry, 26→27 assertion/message, and test-context notes in required_status_checks.json atomically; retain ci-success as the only required context. [VERIFIED: codebase grep]

## Code Examples

    {"Preset public-claims lane", ["test", "test/docs_contract/presets_claims_test.exs"]}

Source: scripts/verify_docs.exs lane pattern. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Manual from_brand guide and 11-row launch gallery | Six presets, 32 catalog cells, 504 formatter snippets, static configurator, preset Livebook. [VERIFIED: ROADMAP.md] | Phase 129 documents only those bounded surfaces. [VERIFIED: CONTEXT.md] |
| 26 docs-contract lanes | 27 after Phase-129 cross-surface lane. [VERIFIED: CONTEXT.md] | Registry, exact-count test, and guardrail prose change together. [VERIFIED: CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All prior link and package assumptions were resolved by local ExDoc and Hex builds. [VERIFIED: local builds] | — | — |

## Open Questions (RESOLVED)

### Exact source, tarball, and ExDoc link syntax

Measured command: mix docs --output /tmp/rendro-phase129-research.DZGcLt/docs-live. The generated tree contained assets/rendro/configurator/index.html, its CSS/JS/index JSON, assets/rendro/catalog.json, and all 32 catalog PNGs. README source links to guides/branding.md and guides/livebook/first_invoice.livemd were rendered as branding.html and first_invoice.html, respectively. A probe extra confirmed that a guide-local link to livebook/first_invoice.livemd becomes first_invoice.html. [VERIFIED: local ExDoc build]

Use these exact Markdown paths:

- README → preset guide: guides/presets.md. ExDoc rewrites it to presets.html. [VERIFIED: local ExDoc build]
- README → configurator: assets/rendro/configurator/index.html. It resolves from repository root and the generated README page; the asset is copied to that same generated location. [VERIFIED: local ExDoc build]
- presets guide → Livebook: livebook/first_invoice.livemd. It resolves from guides/ in source and ExDoc rewrites it to first_invoice.html. [VERIFIED: local ExDoc build]
- presets guide → configurator: https://hexdocs.pm/rendro/assets/rendro/configurator/index.html. A single relative asset URL cannot work in both locations: assets/rendro/... is correct from generated presets.html but resolves to guides/assets/... in source, while ../assets/rendro/... is correct in source but resolves outside the generated docs root. The absolute HexDocs asset URL is the only one-link, three-context route without an extra docs application, copied redirect, or custom ExDoc output layout. [VERIFIED: local ExDoc build]

Required plan change: add a focused docs-contract test that (1) asserts the Markdown source paths above, (2) builds docs to a temporary output directory and checks presets.html plus copied assets, and (3) checks the absolute configurator route. Do not try to make ExDoc emit extras below a guides/ directory: a probe using filename guides/link_probe failed because ExDoc does not create that output directory. [VERIFIED: local ExDoc build]

### Exact smallest public package allowlist

Measured command: MIX_DEPS_PATH=/Users/jon/projects/rendro/deps MIX_BUILD_PATH=/Users/jon/projects/rendro/_build/dev mix hex.build in a disposable source copy, followed by tar -xOf rendro-1.0.0.tar contents.tar.gz | tar -tzf -. The current tarball includes guides/livebook/first_invoice.livemd but excludes all configurator files, catalog.json, all 32 catalog PNGs, and brand/tokens/tokens.css. It also excludes priv/quality/rubric_scores.json, priv/support_matrix.json, and priv/guardrails/required_status_checks.json. [VERIFIED: local Hex build]

Add only these package-file entries:

- assets/rendro/catalog
- assets/rendro/catalog.json
- assets/rendro/configurator
- brand/tokens/tokens.css

Keep existing guides, README.md, mix.exs, assets/rendro/artifacts.json, assets/rendro/gallery, and assets/rendro/manual.pdf entries. The four additions cover every transitive static dependency: configurator/index.html imports configurator.css, configurator.js, and ../../../brand/tokens/tokens.css; configurator.js fetches index.json and ../catalog.json; catalog cells point to the 32 PNGs below assets/rendro/catalog. [VERIFIED: codebase grep]

Must not ship: brand/tokens/tokens.json, brand/tokens/tailwind.tokens.js, broader brand assets, priv/quality, priv/support_matrix.json, priv/guardrails, private schemas, or test/advisory raster evidence. Add tarball positive assertions for the four additions and negative assertions for those exclusions; retain the existing public launch-asset assertions. [VERIFIED: local Hex build]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix + OTP | manifests, tests, ExDoc, ci.fast | ✓ | Mix 1.19.5 / OTP 28 | — [VERIFIED: local command] |
| Node/npm | existing advisory browser tool only, not required closure | ✓ | Node 22.14.0 / npm 11.1.0 | Keep advisory. [VERIFIED: local command] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: codebase grep] |
| Config | test/test_helper.exs. [VERIFIED: codebase grep] |
| Quick | mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs test/docs_contract/public_api_contract_test.exs test/guardrails/required_checks_contract_test.exs. [ASSUMED: proposed] |
| Full | mix ci.fast. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | Guide/routes/snippet/support row/bounded claims/package/docs paths | semantic contract + tarball/docs integration | mix test test/docs_contract/presets_claims_test.exs | No, Wave 0. [VERIFIED: codebase grep] |
| DOCS-01 | Generated adapter API contains Theme.preset/2 | deterministic manifest drift | mix test test/docs_contract/public_api_contract_test.exs | Yes. [VERIFIED: codebase grep] |
| DOCS-01 | Registry/count/guardrail agreement | contract | mix test test/guardrails/required_checks_contract_test.exs | Yes. [VERIFIED: codebase grep] |

### Wave 0 Gaps

- presets_claims_test.exs: cross-surface language, marker snippet parity, proof row, mutation teeth, and link/package docs checks. [VERIFIED: codebase grep]
- Extend package assertions to include only the new public static payload and preserve all private exclusion assertions. [VERIFIED: codebase grep]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Static docs have no auth surface. [VERIFIED: codebase grep] |
| V3 Session Management | no | Static docs have no session surface. [VERIFIED: codebase grep] |
| V4 Access Control | no | No server control path changes. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Preserve closed query enum and safe-DOM configurator contracts; do not claim arbitrary preview. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No crypto behavior change. [VERIFIED: codebase grep] |

| Threat Pattern | STRIDE | Mitigation |
|----------------|--------|------------|
| Public copy overstates evidence | Tampering | Positive/boundary assertions, forbidden-claim mutations, proof paths. [VERIFIED: codebase grep] |
| Package omits public linked asset | Denial of service | Tarball and generated ExDoc link checks. [VERIFIED: CONTEXT.md] |
| URL state enters markup | Tampering | Retain safe DOM, closed-vocabulary, no-innerHTML guards. [VERIFIED: codebase grep] |

## Sources

### Primary

- Live codebase: mix.exs, scripts/verify_docs.exs, manifests, Theme.Snippet, configurator, and tests. [VERIFIED: codebase grep]
- Phase 129 context, requirements, roadmap, and state. [VERIFIED: CONTEXT.md]

### Secondary

- https://ex-doc.hexdocs.pm/ExDoc.html — extras, groups_for_extras, assets. [CITED: https://ex-doc.hexdocs.pm/ExDoc.html]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — current configuration inspected and ExDoc options corroborated. [VERIFIED: codebase grep]
- Architecture: HIGH — all seams are existing committed artifacts. [VERIFIED: codebase grep]
- Pitfalls: HIGH — package mismatch, exact-count guard, and claim contracts observed directly. [VERIFIED: codebase grep]

**Research date:** 2026-08-19
**Valid until:** 2026-09-18

# Phase 128: Static configurator, theme codegen & Livebook - Context

**Gathered:** 2026-08-18
**Status:** Ready for planning
**Decision mode:** User selected all gray areas and delegated one-shot, research-backed recommendations. Four typed `gsd-advisor-researcher` studies covered preview mapping/UI, canonical snippet architecture, Mix generator DX, and Livebook pedagogy; a final cross-check reconciled generated-module ownership with the existing Phase-128 architecture.

<domain>
## Phase Boundary

Phase 128 delivers three coherent tinkerer surfaces over the shipped preset and catalog contracts:

1. a zero-server static configurator that lets a developer choose a document family, preset, curated accent, and document mode, then truthfully relates that code selection to the bounded pre-rendered catalog;
2. `mix rendro.gen.theme`, which writes a safe, committed application-owned theme module and verifies it with a read-only `--check` drift gate; and
3. one focused preset path in the existing first-invoice Livebook.

All three surfaces share one Elixir-owned source formatter. The product does not add live PDF rendering, a server, database, account/persistence model, Node/npm build, arbitrary token editor, fuzzy color matching, new catalog cells, new Theme fields, automatic font substitution, or design-quality/accessibility/PDF-UA/WCAG/print-safety claims. A test-only pinned Chromium/Playwright harness is authorized in required CI; it is not a product build, runtime, or Hex dependency.

</domain>

<spec_lock>
## UI design contract (locked via UI-SPEC.md)

The approved `128-UI-SPEC.md` has no numbered `## Requirements` list; it instead locks the complete visual, interaction, copywriting, responsive, state, and registry-safety contract. Downstream agents MUST read `128-UI-SPEC.md` before planning or implementing.

**In scope:** static HTML/CSS/vanilla JS; existing Rendro tokens; native labeled controls; bounded manifest-backed raster preview; visible canonical Elixir snippet; Clipboard API feedback; strict query validation; light/dark/system-safe chrome; responsive two-column/stacked layout; loading, empty, error, overflow, and long-text states.

**Out of scope:** shadcn or another component library; React/Vite/Node product architecture; arbitrary color input; live PDF generation; form submission or persistence; server calls; hidden scope-boundary copy; unsafe URL-to-DOM interpolation; compliance or universal quality claims. Test-only Node/Playwright in the isolated CI harness is in scope.

</spec_lock>

<decisions>
## Implementation Decisions

### Requested configuration and preview relationship

- **D-01 — Code selection is canonical; preview is derived:** the canonical browser state is exactly one valid `family`, `preset`, `accent`, and document `mode`. That state always describes the copied Elixir. The selected raster is a derived catalog relationship and never rewrites the requested code values. Configurator chrome theme is independent: OS preference applies unless an explicit chrome `data-theme` override exists; choosing a dark document must not silently switch the page chrome.
- **D-02 — Three-state resolver:** resolve previews in this fixed order: (1) exact equality on family + preset + accent + mode; (2) the first manifest-ordered cell with the same family + preset + mode, differing only in accent; (3) no preview. Never cross family, preset, or mode, never calculate color distance, and never rank a broadly “similar” document. If future catalog growth creates multiple accent representatives, manifest order is the deterministic tie-breaker. — **Reversibility: costly** — shared URLs, public disclosure copy, resolver tests, and later catalog additions will rely on this relationship.
- **D-03 — First selectable fallback:** an absent, partial, duplicated, malformed, or unknown query falls back atomically to the first manifest-ordered cell that can populate all four required controls: a non-default cell with non-null preset and accent. With the current manifest this is Invoice × Swiss × `#2C6BED` × light. This is the implementable interpretation of the UI contract's “first catalog cell” rule because the literal first unbranded/default row has null preset/accent and cannot populate the locked six-preset/seven-accent controls. Do not partially retain untrusted query values.
- **D-04 — Shareable URL contract:** after initialization, write exactly one canonical value for each of `family`, `preset`, `accent`, and `mode` using `history.replaceState`. Use lowercase catalog slugs for family/preset/mode and uppercase strict `#RRGGBB` values percent-encoded by `URLSearchParams`. Reloading a valid URL restores the identical requested code selection; preview choice is re-derived and is not serialized as a fifth source of truth. — **Reversibility: costly** — published and shared configurator URLs become a public docs contract.
- **D-05 — Factual state copy:** exact matches say `Exact pre-rendered Swiss · #2C6BED · dark preview.` Accent representatives say `Preview: catalog example uses #2C6BED. Copied code uses your exact accent #1F4FB8.` No-representative states say `No catalog preview matches this selection.` followed by `Copied code is valid, but this catalog has no equivalent pre-rendered example.` Dark rows display the manifest's `boundary_disclosure` verbatim. A valid code selection remains selectable and copyable even when no raster exists; loading, malformed data, or invalid selection disables copying.
- **D-06 — One disciplined UI system:** use native semantic form controls, visible labels and labeled swatches, 44px targets, existing `--rendro-*` tokens, visible non-color focus/selection cues, natural-aspect-ratio images, manifest alt/caption text, a polite live region for preview/copy status, and alert semantics only for actionable failures. Load the manifest and current raster rather than preloading the 32-image tree. Validate all query and manifest values against closed enums and safe relative paths; build DOM nodes and use `textContent`/safe attributes, never `innerHTML`. Preserve the approved responsive hierarchy, keyboard behavior, reduced-motion behavior, light/dark/system rendering, full code overflow, and what/where/why/next error voice.

### Canonical Elixir snippet contract

- **D-07 — Elixir owns source generation:** add one pure internal formatter (the planner may name it `Rendro.Theme.Snippet`, `Rendro.Theme.Codegen`, or equivalent) in packaged `lib/` so both the public Mix task and dev/docs asset generation can call it. JavaScript never assembles Elixir tokens, atoms, tuples, module names, or recipe calls.
- **D-08 — Canonical working snippet:** the configurator and Livebook use a family-specific working fragment containing the strict preset atom, normalized RGB tuple, explicit mode, recipe call, and the locked explicit font bridge. The canonical shape is:

  ```elixir
  preset = :swiss

  theme =
    Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

  document =
    invoice
    |> Rendro.Recipes.Invoice.document(theme: theme)
    |> Rendro.Theme.Presets.register_fonts(preset)
  ```

  The family selects only the input variable and public recipe module. Do not add fixture data, rendering, Phoenix controller code, or a full runnable tutorial to the copied fragment; those belong around the fragment in Livebook/docs.
- **D-09 — Compositional formatter, not duplicated templates:** the formatter exposes composable outputs for the canonical `Theme.preset/2` call, family-specific recipe usage, and generated module source. All render paths share the same preset/mode/RGB serialization. The recipe wrapper and module wrapper are consumer-specific compositions of that canonical call, not separate formatting implementations.
- **D-10 — Committed snippet index:** generate and commit a versioned configurator index containing complete snippet strings for the bounded 6 families × 6 presets × 7 curated accents × 2 modes (504 selections), plus the closed option labels/values needed by the static UI. Browser code retrieves the selected record and copies its string verbatim. Keep preview cell identity/hashes in `assets/rendro/catalog.json`; do not duplicate or mutate catalog evidence in the snippet index. The exact generation command/file split is planner discretion, but drift must be checked inside an existing deterministic test/CI lane rather than adding a Node build.
- **D-11 — Explicit fonts remain product behavior:** `Rendro.Theme.preset/2` constructs a pure value; `Rendro.Theme.Presets.register_fonts/2` remains the explicit document transform locked in Phase 125. Every working snippet, generated module, and Livebook example preserves that order. Do not auto-register fonts inside recipes, silently substitute fonts, or hide a missing bridge behind fallback behavior.

### `mix rendro.gen.theme` module and CLI

- **D-12 — Generate a wrapper, not a struct dump:** the generated artifact is a small application-owned module with `theme/0` calling the stable public `Rendro.Theme.preset/2` constructor and `register_fonts/1` delegating the required bridge. “Materialized module” means a named committed consumer module, not serialized `%Rendro.Theme{}` internals. A literal struct dump would couple generated applications to evolving adapter-tier fields and make additive Rendro changes cause needless downstream source churn. — **Reversibility: costly** — generated files and documentation will establish this module shape for consumers.
- **D-13 — Exact CLI contract:** support:

  ```text
  mix rendro.gen.theme <preset> --accent "#RRGGBB"
    [--mode light|dark]
    [--module MyApp.RendroTheme]
    [--out lib/my_app/rendro_theme.ex]
    [--force | --check]
  ```

  Preset and accent are required; mode defaults to light but is always emitted explicitly. With no `--module`, infer `<CurrentMixAppNamespace>.RendroTheme` from the consumer project's `:app`; derive the default path from the final module. `--module` and `--out` allow multi-theme and umbrella/custom layouts. If no safe app namespace/path can be derived, fail with the exact corrected command rather than inventing a location. Validate module aliases, paths, preset/mode enums, and strict six-digit colors before generating source.
- **D-14 — Generated module shape:** emit formatter-stable source with the normalized rerun command in its generated header, `@moduledoc false`, specs, a fixed `theme/0`, and `register_fonts/1`; do not accept runtime overrides that would make the committed theme cease to represent its generating command. Example:

  ```elixir
  defmodule MyApp.RendroTheme do
    @moduledoc false

    @spec theme() :: Rendro.Theme.t()
    def theme do
      Rendro.Theme.preset(:editorial, accent: {14, 124, 118}, mode: :dark)
    end

    @spec register_fonts(Rendro.Document.t()) :: Rendro.Document.t()
    def register_fonts(document) do
      Rendro.Theme.Presets.register_fonts(document, :editorial)
    end
  end
  ```

- **D-15 — Safe write and drift behavior:** ship the Mix task and its private formatter in packaged `lib/`; add no dependency. Normal generation uses `Mix.Generator.create_file` with Elixir formatting: identical content is idempotent, differing content prompts, and `--force` is the only non-interactive overwrite. `--check` derives the exact formatted bytes, never writes or prompts, succeeds clearly on equality, and fails loudly on missing/different output with the normalized rerun command. Reject `--check --force`, unknown flags, extra positionals, unsafe paths/modules, and invalid enums with the project's what/where/why/next error pattern. Generated code becomes consumer-owned; a user who intentionally detaches/customizes it removes the generated header and stops using `--check` for that file.

### Livebook learning flow

- **D-16 — One focused additive section:** extend `guides/livebook/first_invoice.livemd`; do not add a second notebook. Immediately after the existing baseline render, add an `Apply a preset` path using Invoice × Swiss × `#2C6BED` × light—the first selectable exact catalog example—and the canonical snippet verbatim. Add exactly one themed deterministic render, `%PDF-` assertion, byte count/SHA-256 evidence, inline preview, and download for the themed bytes.
- **D-17 — Teach editing, not another UI:** explain that a developer can try another canonical preset/accent/mode by editing the three selection values. Do not add `Kino.Input`, `Kino.JS`, catalog fetches, an all-presets loop/grid, a second browser configurator, or server startup. The surrounding notebook owns setup/data/render explanation; the shared snippet remains compact and identical to the configurator record.
- **D-18 — Honest learning copy:** state that presets are working starting points, not design-quality, accessibility, PDF/UA, WCAG, or print guarantees. Beside a dark-mode suggestion, repeat the screen-oriented boundary. Preserve `Mix.install`, local-checkout execution through `RENDRO_LIVEBOOK_LOCAL=1`, and the existing `mix rendro.livebook.check` no-server path.

### Cross-surface proof bar

- **D-19 — Exhaust the bounded source vocabulary:** tests cover all 504 family × preset × curated-accent × mode usage snippets. Every string must equal the committed configurator index value, parse through `Code.string_to_quoted!/1`, and compile/evaluate in a controlled harness. Representative render tests prove the recipe/font bridge; do not multiply the 32-cell raster catalog or imply every 504 selection has visual review.
- **D-20 — Prove each consumer seam:** test generated module compilation, `theme/0 == Theme.preset/2`, explicit `register_fonts/1`, formatter-stable double generation, default and overridden module/path derivation, conflict safety, and read-only `--check` missing/different/equal behavior. Extract/mark the Livebook canonical block and assert exact formatter equality, one preset render, `%PDF-` proof, and no interactive/server additions. Static UI tests cover strict URL parsing, exact/representative/none resolution, safe DOM use, copy success/failure, theme independence, keyboard/focus/status semantics, and loading/error/empty states.
- **D-21 — Learn from successful generators/configurators without importing their scale:** follow Mix/Phoenix/Ecto conventions of generated application-owned code, derived conventional paths, explicit override controls, formatter use, and safe overwrite behavior. Follow successful theme configurators such as shadcn/create in making visual choices shareable and exportable, but keep Rendro's closed vocabulary and exact evidence boundary; do not copy their framework/build/runtime complexity or imply live preview where only curated rasters exist.

### the agent's Discretion

The planner may choose private helper names, whether the configurator index is a new JSON file or a strictly consumer-focused derived section, exact schema keys/versioning, CSS/JS file partitioning, internal AST/iodata implementation, test module layout, and the precise accessible live-region wording. It may choose a safe fallback error path for unusual umbrella projects. It may not change the exact/representative/none preview priority, cross-dimension prohibition, four-key URL contract, canonical working snippet content, explicit font bridge, wrapper-module API, safe write/check semantics, focused one-section Livebook scope, or bounded exhaustive source checks without returning for a product decision.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The living `brand/` system supersedes `prompts/Rendro Brand Book.txt` wherever they conflict; older prompts remain useful for product history, personas, ecosystem lessons, and JTBD context.

### Phase scope and locked contracts

- `.planning/ROADMAP.md` — Phase 128 goal, dependency, success criteria, and three-surface boundary.
- `.planning/REQUIREMENTS.md` — CONFIG-01..06, milestone exclusions, and truthful-claim constraints.
- `.planning/PROJECT.md` — pure core, deterministic output, Phoenix-first audience, and documentation-as-contract posture.
- `.planning/STATE.md` — current milestone position and completed Phase-125..127 decisions.
- `.planning/phases/128-static-configurator-theme-codegen-livebook/128-UI-SPEC.md` — approved visual, interaction, state, responsive, accessibility, security, and copywriting contract; MUST read before planning.
- `.planning/phases/127-public-example-catalog-quality-ratchet/127-CONTEXT.md` — fixed 32-cell catalog, manifest-constrained previews, exact page-one evidence, ordering, quality states, and Phase-128 handoff.
- `.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-CONTEXT.md` — strict preset vocabulary and the costly explicit `Theme.Presets.register_fonts/2` call shape Phase 128 must copy.
- `.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-CONTEXT.md` — repaired recipe baselines and bounded dark-mode claim language.

### Milestone research and original intent

- `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md` — original browse → pick → copy, generated-module, URL-state, and Livebook vision.
- `.planning/research/ARCHITECTURE.md` — configurator index, exact lookup, generated wrapper module, font bridge, and Livebook integration recommendation.
- `.planning/research/STACK.md` — zero-new-dependency static/ExDoc stack and Mix task conventions.
- `.planning/research/FEATURES.md` — theme configurator ecosystem comparison and expected/default feature tiers.
- `.planning/research/PITFALLS.md` — Node creep, URL XSS, duplicated snippet formatting, preview/code drift, and claim-surface hazards.
- `.planning/research/SUMMARY.md` — milestone synthesis and Phase-128 dependency/ownership summary.
- `.planning/research/JTBD-USER-FLOWS.md` — developer discovery, evaluation, adoption, and handoff jobs.

### Living brand, UI, and voice

- `brand/README.md` — current brand source-of-truth order and product identity.
- `brand/index.html` — current self-contained light/dark component and visual direction.
- `brand/tokens/tokens.json` — semantic palette, typography, spacing, state, motion, and grid source.
- `brand/tokens/tokens.css` — generated token names and OS/explicit light/dark cascade the configurator consumes.
- `brand/copy/VOICE.md` — evidence-first developer voice and what/where/why/next error pattern.
- `brand/copy/marketing-copy.md` — current feature, state, limitation, and CTA language.
- `brand/audit/AUDIT.md` — current UI/brand pressure test and source precedence.
- `brand/audit/SCORECARD.md` — coherence, accessibility, maintainability, and docs-utility lenses.

### Older prompt research, applied selectively

- `prompts/rendro-gsd-seed.md` — primary personas, pipeline, pure-core boundary, and Phoenix-first JTBD.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Elixir/Phoenix ecosystem lessons, copy-paste recipe value, codegen expectations, and popular cross-language PDF-library lessons.
- `prompts/rendro-oss-dna.md` — package/API/CI conventions learned from sibling Elixir libraries.
- `prompts/rendro-integration-opportunities.md` — optional-integration and core-coupling policy.
- `prompts/Rendro Brand Book.txt` — older developer-facing UI, code-block, copy-feedback, and docs direction; defer to `brand/` on conflict.

### Existing implementation seams

- `assets/rendro/catalog.json` — ordered 32-cell preview authority, closed accents/presets/families/modes, paths, copy, disclosure, and quality projection.
- `dev/rendro/catalog.ex` — dev-only catalog registry/render/validation patterns and Phase-128 consumer boundary.
- `lib/rendro/theme.ex` — stable public `Theme.preset/2` constructor.
- `lib/rendro/theme/presets.ex` — canonical preset atoms, strict option validation, curated font paths, and explicit registration bridge.
- `lib/mix/tasks/brand.gen.ex` — existing generated-output and `--check` precedent.
- `mix.exs` — packaged Mix task boundary, dev-only catalog compilation, ExDoc assets copy-through, Livebook dependency, docs extras, and package allowlist.
- `guides/livebook/first_invoice.livemd` — existing baseline tutorial, data, deterministic render, preview, download, and limitation language.
- `lib/mix/tasks/rendro/livebook/check.ex` — no-server Live Markdown conversion/execution path.
- `test/mix/tasks/rendro_livebook_check_test.exs` — existing Livebook task and source-boundary tests.
- `test/docs_contract/catalog_manifest_contract_test.exs` — current catalog manifest contract.
- `test/docs_contract/catalog_quality_contract_test.exs` — quality projection and no-overclaim contract.
- `test/docs_contract/theme_industry_guard_test.exs` — exact Theme delegation boundary; do not move genre logic into `theme.ex`.

### Authoritative ecosystem references

- `https://hexdocs.pm/mix/main/Mix.Generator.html` — conflict-aware generated file creation and Elixir formatting.
- `https://hexdocs.pm/elixir/Code.html` — source parsing/formatting primitives for compile-round-trip proof.
- `https://hexdocs.pm/phoenix/your_first_context.html` — generators as learning tools and application-owned starting points.
- `https://hexdocs.pm/phoenix/1.7.8/mix_phx_gen_auth.html` — generated code becomes the application's responsibility and does not silently update later.
- `https://hexdocs.pm/ecto_sql/api-reference.html` — conventional Mix generator/task shape in the Elixir data ecosystem.
- `https://hexdocs.pm/livebook/` — executable notebook model and supported Live Markdown workflows.
- `https://hexdocs.pm/kino/Kino.Download.html` — existing download-cell behavior.
- `https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams` — canonical query encoding/parsing.
- `https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState` — non-navigating share-state updates.
- `https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText` — secure-context copy behavior and failure handling.
- `https://ui.shadcn.com/docs/theming` — successful token-based visual configurator precedent.
- `https://ui.shadcn.com/docs/cli` — shareable preset and CLI handoff precedent; Rendro adopts the handoff pattern without its framework scale.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `assets/rendro/catalog.json`: already supplies ordered preview identity, safe paths, natural dimensions, alt/caption, dark disclosure, and exact quality status; Phase 128 needs a resolver and consumer index, not a new preview backend.
- `brand/tokens/tokens.css`: already provides the complete semantic light/dark/system cascade and reduced-motion tokens for a static page.
- `Rendro.Theme.preset/2` and `Rendro.Theme.Presets.register_fonts/2`: already form the proven pure-value → recipe → explicit document-registration path.
- `Mix.Tasks.Brand.Gen`: already demonstrates deterministic string generation and byte-exact `--check`; `Mix.Generator` adds idiomatic conflict/format handling for consumer-owned Elixir files.
- `first_invoice.livemd` plus `rendro.livebook.check`: already provide the data, proof, preview/download, local-checkout, and no-server tutorial shell.

### Established Patterns

- Public/runtime core stays pure; dev/docs artifact tooling may consume core but core never consumes catalog/configurator code.
- Generated assets are committed and checked byte-for-byte; generation is explicit and checks are non-writing.
- Programmer-supplied static configuration raises clear errors; unknown values are not normalized silently.
- Deterministic source/bytes, pinned raster evidence, human visual judgment, and compliance claims remain separate lanes.
- Public manifests evolve additively and safely; URLs/IDs are durable contracts, not display strings.
- Brands and selections are data, preset grammar is code, and recipes never branch on preset genre.

### Integration Points

- New `assets/rendro/configurator/index.html`, CSS, and vanilla JS consume the existing catalog manifest plus a generated consumer snippet index.
- A new private packaged source formatter supplies the configurator index, generated module, and Livebook canonical block.
- New `lib/mix/tasks/rendro/gen/theme.ex` exposes the packaged Mix task and generates into the consumer project.
- `mix.exs` already copies `assets/` into ExDoc and packages `lib/`; no new dependency, server, or build pipeline is required.
- `guides/livebook/first_invoice.livemd`, its checker, and existing docs-contract/guardrail tests gain bounded additive coverage.

</code_context>

<specifics>
## Specific Ideas

- The core mental model is deliberately visible and simple: **your requested code selection** → **exact/representative/no catalog preview** → **copy the exact requested code**. Never let the preview mutate the code behind the user's back.
- The first experience should succeed without choices the user cannot answer: Invoice × Swiss × Rendro blue × light is both a valid four-control state and an exact shipped catalog cell.
- The configurator should feel like ExDoc clarity plus a well-set technical manual: restrained native controls, one strong preview anchor, factual relationship/status copy, and a real working code block—not a generic SaaS dashboard or a miniature Studio.
- The generated module is intentionally boring application architecture: one fixed `theme/0`, one explicit `register_fonts/1`, one normalized rerun command, and no hidden state.
- Livebook demonstrates the same path with real bytes. It is the experiential proof surface, not a second selection UI.

</specifics>

<deferred>
## Deferred Ideas

- Interactive Livebook controls, an all-presets comparison grid, or a separate presets notebook: future learning work only if the focused section proves insufficient.
- Arbitrary color entry, color-distance matching, cross-family/preset/mode inspiration fallback, live PDF preview, accounts, persistence, and server-rendered Studio: Milestone D (`SEED-005`).
- Expanding or re-curating the fixed 32-cell catalog: a separate product and human-review-budget decision, not Phase-128 fixture-driven growth.
- A public general-purpose snippet/codegen API: not required; the Phase-128 formatter remains internal and the Mix task/configurator/Livebook are the supported surfaces.

</deferred>

---

*Phase: 128-static-configurator-theme-codegen-livebook*
*Context gathered: 2026-08-18*

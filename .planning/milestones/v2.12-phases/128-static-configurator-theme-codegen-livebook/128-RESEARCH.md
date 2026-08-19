# Phase 128: Static configurator, theme codegen & Livebook - Research

**Researched:** 2026-08-19
**Domain:** Deterministic Elixir source generation, static documentation UI, Mix generators, and Livebook
**Confidence:** HIGH

<user_constraints>
DATA_H8V2K4QZ_START
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Code selection is canonical; preview is derived:** the canonical browser state is exactly one valid `family`, `preset`, `accent`, and document `mode`. That state always describes the copied Elixir. The selected raster is a derived catalog relationship and never rewrites the requested code values. Configurator chrome theme is independent: OS preference applies unless an explicit chrome `data-theme` override exists; choosing a dark document must not silently switch the page chrome.
- **D-02 — Three-state resolver:** resolve previews in this fixed order: (1) exact equality on family + preset + accent + mode; (2) the first manifest-ordered cell with the same family + preset + mode, differing only in accent; (3) no preview. Never cross family, preset, or mode, never calculate color distance, and never rank a broadly “similar” document. If future catalog growth creates multiple accent representatives, manifest order is the deterministic tie-breaker.
- **D-03 — First selectable fallback:** an absent, partial, duplicated, malformed, or unknown query falls back atomically to the first manifest-ordered cell that can populate all four required controls: a non-default cell with non-null preset and accent. With the current manifest this is Invoice × Swiss × `#2C6BED` × light. Do not partially retain untrusted query values.
- **D-04 — Shareable URL contract:** after initialization, write exactly one canonical value for each of `family`, `preset`, `accent`, and `mode` using `history.replaceState`. Use lowercase catalog slugs for family/preset/mode and uppercase strict `#RRGGBB` values percent-encoded by `URLSearchParams`. Reloading a valid URL restores the identical requested code selection; preview choice is re-derived and is not serialized as a fifth source of truth.
- **D-05 — Factual state copy:** exact matches say `Exact pre-rendered Swiss · #2C6BED · dark preview.` Accent representatives say `Preview: catalog example uses #2C6BED. Copied code uses your exact accent #1F4FB8.` No-representative states say `No catalog preview matches this selection.` followed by `Copied code is valid, but this catalog has no equivalent pre-rendered example.` Dark rows display the manifest's `boundary_disclosure` verbatim. A valid code selection remains selectable and copyable even when no raster exists; loading, malformed data, or invalid selection disables copying.
- **D-06 — One disciplined UI system:** use native semantic form controls, visible labels and labeled swatches, 44px targets, existing `--rendro-*` tokens, visible non-color focus/selection cues, natural-aspect-ratio images, manifest alt/caption text, a polite live region for preview/copy status, and alert semantics only for actionable failures. Load the manifest and current raster rather than preloading the 32-image tree. Validate all query and manifest values against closed enums and safe relative paths; build DOM nodes and use `textContent`/safe attributes, never `innerHTML`. Preserve the approved responsive hierarchy, keyboard behavior, reduced-motion behavior, light/dark/system rendering, full code overflow, and what/where/why/next error voice.
- **D-07 — Elixir owns source generation:** add one pure internal formatter in packaged `lib/` so both the public Mix task and dev/docs asset generation can call it. JavaScript never assembles Elixir tokens, atoms, tuples, module names, or recipe calls.
- **D-08 — Canonical working snippet:** configurator and Livebook use a family-specific fragment containing the strict preset atom, normalized RGB tuple, explicit mode, recipe call, and explicit `Rendro.Theme.Presets.register_fonts/2` bridge. Family selects only input variable and public recipe module. Do not add fixture data, rendering, Phoenix controller code, or a full runnable tutorial to the copied fragment.
- **D-09 — Compositional formatter, not duplicated templates:** formatter outputs for the canonical `Theme.preset/2` call, family-specific recipe usage, and generated module source share preset/mode/RGB serialization. Consumer wrappers compose this call rather than duplicate formatting.
- **D-10 — Committed snippet index:** generate and commit a versioned configurator index with complete strings for 6 families × 6 presets × 7 curated accents × 2 modes (504 selections), plus closed option labels/values. Browser code retrieves and copies the selected string verbatim. Preview evidence stays only in `assets/rendro/catalog.json`; index drift is checked in an existing deterministic lane without Node.
- **D-11 — Explicit fonts remain product behavior:** `Rendro.Theme.preset/2` constructs a pure value; `Rendro.Theme.Presets.register_fonts/2` remains the explicit document transform. Every working snippet, generated module, and Livebook example preserves that order. No automatic registration, substitution, or hidden fallback.
- **D-12 — Generate a wrapper, not a struct dump:** emitted application-owned module has `theme/0` calling stable `Rendro.Theme.preset/2` and `register_fonts/1` delegating the bridge; never serialize `%Rendro.Theme{}` internals.
- **D-13 — Exact CLI contract:** `mix rendro.gen.theme <preset> --accent "#RRGGBB" [--mode light|dark] [--module MyApp.RendroTheme] [--out lib/my_app/rendro_theme.ex] [--force | --check]`. Preset/accent required; mode defaults to light but is emitted. Infer module/path from consumer `:app` when safe; validate aliases, paths, enums, and strict colors; otherwise fail with the corrected command.
- **D-14 — Generated module shape:** formatter-stable source has a normalized rerun header, `@moduledoc false`, specs, fixed `theme/0`, and `register_fonts/1`; no runtime overrides.
- **D-15 — Safe write and drift behavior:** task and private formatter are packaged `lib/` with no dependency. Normal generation uses `Mix.Generator.create_file` with Elixir formatting: same content idempotent, changed content prompts, only `--force` overwrites non-interactively. `--check` derives exact formatted bytes without writing/prompting and fails on missing/different output with rerun command. Reject `--check --force`, unknown flags, extra positionals, unsafe paths/modules, and invalid enums with what/where/why/next errors. Detached user code removes header and stops using `--check`.
- **D-16 — One focused additive section:** extend `guides/livebook/first_invoice.livemd`, immediately after baseline render, with Invoice × Swiss × `#2C6BED` × light canonical snippet. Add exactly one themed deterministic render, `%PDF-` assertion, byte count/SHA-256, inline preview, and download.
- **D-17 — Teach editing, not another UI:** explain editing the three selection values. Do not add `Kino.Input`, `Kino.JS`, catalog fetches, a grid, second configurator, or server startup.
- **D-18 — Honest learning copy:** presets are working starting points, not design-quality, accessibility, PDF/UA, WCAG, or print guarantees. Repeat screen-oriented dark boundary. Preserve `Mix.install`, `RENDRO_LIVEBOOK_LOCAL=1`, and `mix rendro.livebook.check`.
- **D-19 — Exhaust bounded source vocabulary:** cover all 504 snippets; each equals committed index, parses through `Code.string_to_quoted!/1`, and compiles/evaluates in a controlled harness. Representative renders prove recipe/font bridge; do not multiply 32 raster cells or imply visual review.
- **D-20 — Prove each consumer seam:** test generated module compilation/equivalence/font bridge/double generation/default and override derivation/conflict/read-only check; extract Livebook canonical block and prove exact equality, one render and no interactivity/server; static UI tests cover URL parsing, resolver states, safe DOM, clipboard, theme independence, keyboard/focus/status, and loading/error/empty states.
- **D-21 — Keep the scope bounded:** use conventional application-owned generated code, derived paths, override controls, formatter, and safe overwrite behavior; retain closed vocabulary and exact preview-evidence boundary without framework/build/runtime complexity or live-preview implication.

### the agent's Discretion

The planner may choose private helper names, whether the configurator index is a new JSON file or a strictly consumer-focused derived section, exact schema keys/versioning, CSS/JS file partitioning, internal AST/iodata implementation, test module layout, and the precise accessible live-region wording. It may choose a safe fallback error path for unusual umbrella projects. It may not change the exact/representative/none preview priority, cross-dimension prohibition, four-key URL contract, canonical working snippet content, explicit font bridge, wrapper-module API, safe write/check semantics, focused one-section Livebook scope, or bounded exhaustive source checks without returning for a product decision.

### Deferred Ideas (OUT OF SCOPE)

- Interactive Livebook controls, an all-presets comparison grid, or a separate presets notebook.
- Arbitrary color entry, color-distance matching, cross-family/preset/mode fallback, live PDF preview, accounts, persistence, and server-rendered Studio.
- Expanding or re-curating the fixed 32-cell catalog.
- A public general-purpose snippet/codegen API; formatter stays internal.
DATA_H8V2K4QZ_END
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| CONFIG-01 | Static zero-server configurator served through ExDoc assets | Static asset topology and browser state/resolver pattern below |
| CONFIG-02 | Exact curated preview relation with truthful representative disclosure | Ordered three-state resolver and catalog/index ownership split |
| CONFIG-03 | Copy working preset/recipe snippet with feedback | Elixir-owned 504-record index, verbatim copy, Clipboard failure state |
| CONFIG-04 | Safe, deterministic share URL | closed-enum parser, atomic fallback, `URLSearchParams` + `replaceState` |
| CONFIG-05 | Generator plus byte-exact drift gate shares canonical formatter | packaged formatter, `Mix.Generator.create_file/3`, controlled verification |
| CONFIG-06 | Existing Livebook teaches same vocabulary | one additive Invoice section and existing no-server checker |

## Summary

Build one packaged, internal `Rendro.Theme` code-generation seam first. It must own normalized preset atoms, RGB tuples, explicit modes, the six recipe mappings, the user module wrapper, and a deterministic JSON index writer. The static page is only a strict consumer of two committed JSON files: it uses the index for closed controls/snippet bytes and `catalog.json` solely for bounded raster evidence. [VERIFIED: codebase grep]

Current inputs already support the exact contract: catalog has 32 ordered cells, of which 26 are selectable preview rows; its six family slugs, six preset slugs, seven accents, and two modes yield the required 504 code selections. Its first selectable row is Invoice/Swiss/`#2C6BED`/light. `Theme.preset/2` accepts strict preset/mode/accent values and the explicit `Presets.register_fonts/2` transform is already the engine-backed bridge. [VERIFIED: codebase grep]

**Primary recommendation:** plan four ordered units: canonical formatter/index and exhaustive tests; packaged Mix task and drift tests; static UI and browser tests; then the focused Livebook edit and no-server proof.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Canonical Elixir serialization/index | API / Backend | Static build assets | Elixir determines valid source; committed JSON is a derived consumer artifact. |
| Preview selection and UI state | Browser / Client | CDN / Static | Browser resolves only committed manifest data and displays a raster. |
| Generated theme module | API / Backend | Consumer filesystem | Mix validates and writes consumer-owned code; Rendro runtime stays pure. |
| Theme construction/font bridge | API / Backend | — | Theme value plus document registration are Rendro public behavior. |
| Livebook tutorial proof | Browser / Client | API / Backend | Notebook executes a deterministic local Elixir render without a server. |

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure: no Phoenix, Oban, admin, server, or browser dependency in core. [VERIFIED: AGENTS.md]
- Keep deterministic verification distinct from advisory verification in code, CI, and claims. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts; make no unsupported quality, accessibility, PDF/UA, WCAG, or print claims. [VERIFIED: AGENTS.md]
- Use optional dependency guards for integrations; this phase installs no dependency. [VERIFIED: AGENTS.md]
- Use the established GSD workflow for any implementation edits. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / platform | Version | Purpose | Why standard |
|---|---:|---|---|
| Elixir / Mix | 1.19.5 | formatter, packaged Mix task, source parser/evaluator | Project runtime; `Mix.Generator.create_file/3` supports conflict-aware output and `:format_elixir`. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] |
| ExDoc asset copy-through | 0.40.1 | Hosts `assets/rendro/configurator/` alongside existing docs assets | Existing `mix.exs` maps `assets` to `assets`; no build/server required. [VERIFIED: codebase grep] |
| Vanilla browser APIs | browser-native | manifest fetch, URL state, copy feedback, DOM rendering | Locked zero-dependency static surface. [VERIFIED: 128-UI-SPEC.md] |
| Livebook | 0.19.8 (existing dev/test dep) | `.livemd` tutorial validation | Existing checker converts Live Markdown to a script without starting a server. [VERIFIED: codebase grep] |

### Supporting

| Library / platform | Version | Purpose | When to use |
|---|---:|---|---|
| `Code.string_to_quoted!/1` | Elixir 1.19.5 | syntax proof for all generated snippets | Verify formatter/index records only. [CITED: https://hexdocs.pm/elixir/Code.html] |
| `Code.eval_string/3` | Elixir 1.19.5 | controlled compile/evaluation harness | Use only trusted formatter output with supplied recipe-data bindings; never browser/URL input. [CITED: https://hexdocs.pm/elixir/Code.html] |
| `URLSearchParams`, `history.replaceState` | browser-native | canonical query serialization without navigation | After all four closed values are validated. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams] [CITED: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState] |
| `navigator.clipboard.writeText` | browser-native | copy exact snippet and report errors | Feature-detect/reject handling; page remains usable if unavailable. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Committed JSON index | JavaScript template generation | Violates D-07/D-09 and permits source drift. |
| Native semantic controls | React/Vite/component library | Violates locked static/no-Node scope. |
| Exact ordered resolver | Color-distance library | Violates the catalog-evidence contract. |
| `Mix.Generator.create_file/3` | direct `File.write!` | Loses normal conflict prompt/force semantics. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] |

**Installation:** none — every dependency is already present; do not add a package. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Theme selection ──> internal Elixir formatter ──> committed configurator index (504 snippets)
                         ├─────────────────────> Mix task -> consumer module / --check bytes
                         └─────────────────────> Livebook canonical block

Browser URL ──> closed-enum validation ──> requested {family,preset,accent,mode}
                                              ├─> index record -> visible/copyable exact code
                                              └─> catalog.json -> exact | representative | none
                                                                    └─> one local PNG + factual copy
```

### Recommended Project Structure

```text
lib/rendro/theme/snippet.ex                 # private pure formatter + closed vocabulary/index encoding
lib/mix/tasks/rendro/gen/theme.ex           # packaged public Mix entry point
dev/mix/tasks/rendro/configurator/gen.ex    # dev-only explicit generator for committed index (recommended)
assets/rendro/configurator/index.html        # static semantic shell
assets/rendro/configurator/configurator.css  # token-only responsive styles
assets/rendro/configurator/configurator.js   # safe manifest/index consumer and resolver
assets/rendro/configurator/index.json        # committed versioned 504 snippet records
test/rendro/theme/snippet_test.exs           # exhaustive source vocabulary proof
test/mix/tasks/rendro_gen_theme_test.exs     # filesystem/CLI behavior
test/docs_contract/configurator_*_test.exs   # asset/index/schema/no-claim contracts
guides/livebook/first_invoice.livemd         # one additive preset path
```

### Pattern 1: One canonical formatter with consumer wrappers

**What:** create private functions for normalized RGB conversion, `preset_call/3`, `usage_snippet/4`, and `module_source/4`; generator/index/Livebook compose those outputs. [VERIFIED: 128-CONTEXT.md]

**When to use:** every source-producing route in this phase. Never calculate a code string in JavaScript or duplicate indentation/source tokens in the notebook.

```elixir
# Source shape locked by 128-CONTEXT.md
preset = :swiss

theme =
  Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

document =
  invoice
  |> Rendro.Recipes.Invoice.document(theme: theme)
  |> Rendro.Theme.Presets.register_fonts(preset)
```

### Pattern 2: Atomic state parsing, then a pure ordered resolver

**What:** load JSON; derive allowed values from closed index; use `URLSearchParams.getAll` to require exactly one value per key; validate all four before state adoption. If any failure, use first selectable catalog row. Canonicalize with `URLSearchParams` and `replaceState`; resolver receives only trusted canonical state and manifest cells. [VERIFIED: 128-CONTEXT.md]

**When to use:** initialization and every select change. The resolver must return tagged data (`exact`, `representative`, `none`) rather than mutating selection.

### Pattern 3: Safe static DOM boundary

**What:** construct elements, assign `textContent`, `value`, `src`, and `alt` only after enum/path validation; reject `Path`-style traversal equivalents (`..`, absolute, protocol-relative) in manifest-relative asset paths; never use `innerHTML`. [VERIFIED: 128-UI-SPEC.md]

**When to use:** all URL, manifest, and clipboard-derived display. Treat committed JSON as validation-required input, not privileged markup.

### Anti-Patterns to Avoid

- **Preview becomes code source:** representative image accent must never overwrite copied code accent.
- **One JSON containing catalog evidence and snippets:** preserve catalog hashes/cell identity as the sole preview authority.
- **Test evaluator receives arbitrary text:** `Code.eval_string/3` executes VM-privileged code; only evaluate generated trusted strings. [CITED: https://hexdocs.pm/elixir/Code.html]
- **Hex package expansion by accident:** keep catalog/configurator documentation assets outside runtime package allowlist unless a deliberate packaging decision changes it; Phase 127 expressly excludes broad `assets/rendro`. [VERIFIED: test/docs_contract/catalog_manifest_contract_test.exs]
- **Browser test suite requires a Node build:** use static source/contract tests plus browser-capable test runner only if already available; no Node dependency or CI lane is authorized. [VERIFIED: 128-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Consumer file conflict interaction | custom overwrite prompt | `Mix.Generator.create_file/3` with `force:` / `format_elixir:` | Mix already gives equality, prompt, force, and formatter behavior. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] |
| Elixir formatting | custom whitespace formatter | `Code.format_string!/2` or `Mix.Generator` formatting | Stable source bytes make `--check` meaningful. [CITED: https://hexdocs.pm/elixir/Code.html] |
| URL encoding | string concatenation | `URLSearchParams` | Correctly percent-encodes `#RRGGBB` and centralizes four-key canonicalization. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams] |
| Clipboard fallback claims | fake “copied” state | `navigator.clipboard.writeText` promise handling | Report success only after resolution; retain retryable source on failure. [CITED: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText] |

## Common Pitfalls

### Pitfall 1: Schema/source drift

**What goes wrong:** 504 browser snippets, Mix output, and notebook snippet stop agreeing after a later whitespace or recipe change.

**How to avoid:** index generator calls the packaged formatter, index is committed, and exhaustive test compares every formatter output byte-for-byte to index, parses it, then evaluates it with each family’s controlled input binding. [VERIFIED: 128-CONTEXT.md]

### Pitfall 2: Treating a valid no-preview choice as invalid

**What goes wrong:** a valid 504-code selection that lacks a 32-cell raster disables copy.

**How to avoid:** index validity controls snippet/copy; resolver status controls only preview panel. Disable copy only during loading/malformed-index/error or invalid selection. This reconciles D-05 with UI empty-state wording. [VERIFIED: 128-CONTEXT.md]

### Pitfall 3: Unsafe generated-module path/module derivation

**What goes wrong:** unchecked aliases become atoms or output escapes project root/umbrella layout.

**How to avoid:** validate aliases syntactically without dynamic atom creation; normalize output as a safe relative path under current Mix project; reject absolute/traversal paths; derive conventional default only from safe `Mix.Project.config()[:app]`; errors show corrected invocation. [ASSUMED]

### Pitfall 4: Livebook conversion differs from interactive cells

**What goes wrong:** notebook works cell-by-cell but converted full script fails because Livebook notes whole-script macro/import limitations.

**How to avoid:** keep the additive section ordinary sequential expressions and execute `mix rendro.livebook.check`; no macros/imports between cells and no interactive controls. [CITED: https://livebook.hexdocs.pm/Livebook.html]

## Code Examples

### Explicit safe write/check split

```elixir
# normal mode: trusted formatted source, Mix handles equality/conflicts
Mix.Generator.create_file(out_path, source, format_elixir: true, force: force?)

# --check: do not call create_file/3
case File.read(out_path) do
  {:ok, ^source} -> :ok
  _ -> Mix.raise("theme is stale; run `#{rerun_command}`")
end
```

`create_file/3` prompts only for differing existing content and `:force` bypasses the prompt; format support is documented for modern Mix. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html]

### Resolver contract

```javascript
const exact = cells.find((cell) => sameSelection(cell, selection));
if (exact) return { kind: "exact", cell: exact };

const representative = cells.find((cell) =>
  cell.family === selection.family &&
  cell.preset === selection.preset &&
  cell.mode === selection.mode
);
return representative ? { kind: "representative", cell: representative } : { kind: "none" };
```

Manifest order is the tie-breaker because `find` preserves input order. Values here are already closed-enum validated. [VERIFIED: 128-CONTEXT.md]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| `Mix.Tasks.Brand.Gen` writes repo-owned derived assets directly | generator writes consumer-owned module via Mix conflict conventions | normal user customization is protected; `--check` is explicitly opt-in. [VERIFIED: lib/mix/tasks/brand.gen.ex] |
| Catalog is dev-only and excluded from package payload | configurator is static ExDoc asset consumer | documentation UI may consume catalog assets without widening runtime dependencies. [VERIFIED: mix.exs] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A safe alias/path validator can be implemented without dynamic atoms and can conservatively reject unusual umbrella layouts. | Pitfall 3 | Task may need a narrower documented override/error route. |

## Open Questions (RESOLVED)

1. **Exact index generation task name/location — RESOLVED**
   - Selected contract: dev-only `Mix.Tasks.Rendro.Configurator.Gen` at `dev/mix/tasks/rendro/configurator/gen.ex`, invoked as `mix rendro.configurator.gen`.
   - Committed output: the task deterministically writes `assets/rendro/configurator/index.json` from the packaged canonical formatter.
   - Drift contract: `mix rendro.configurator.gen --check` is read-only and compares freshly derived bytes to the committed file byte-for-byte; equality exits successfully, while a missing or different file fails without creating directories, changing bytes, or changing mtime.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir / Mix | formatter, task, tests | ✓ | 1.19.5 | — |
| Livebook dependency | no-server notebook check | ✓ | 0.19.8 | existing task reports clear missing-dep action |
| Browser | manual static UI validation | ✓ assumed | — | source/contract tests cover deterministic parser/resolver boundaries |
| Node/npm | none | ✓ | Node 22.14.0 / npm 11.1.0 | deliberately unused |

**Missing dependencies with no fallback:** none. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (project-native) |
| Config file | `.formatter.exs`; ExUnit defaults |
| Quick run command | `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs test/mix/tasks/rendro_livebook_check_test.exs --max-failures 1` |
| Full suite command | `mix ci.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CONFIG-01 | static files, no Node/server/build, ExDoc asset topology | docs contract | `mix test test/docs_contract/configurator_static_contract_test.exs` | ❌ Wave 0 |
| CONFIG-02 | exact/representative/none resolver never crosses dimensions | unit + static JS contract | `mix test test/docs_contract/configurator_resolver_contract_test.exs` | ❌ Wave 0 |
| CONFIG-03 | each index record is formatter-owned and copy uses exact visible string | exhaustive unit + source contract | `mix test test/rendro/theme/snippet_test.exs` | ❌ Wave 0 |
| CONFIG-04 | atomic strict URL parser/canonical writer/no unsafe DOM APIs | static JS contract | `mix test test/docs_contract/configurator_static_contract_test.exs` | ❌ Wave 0 |
| CONFIG-05 | 504 source proof, generator conflict/force/check, output compilation | unit + Mix task integration | `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs` | ❌ Wave 0 |
| CONFIG-06 | one canonical Livebook block, themed bytes, no server/interactive additions | notebook source + no-server integration | `mix test test/mix/tasks/rendro_livebook_check_test.exs && mix rendro.livebook.check` | partial |

### Sampling Rate

- **Per task commit:** targeted ExUnit command for files touched, then `mix format --check-formatted`.
- **Per wave merge:** `mix test`.
- **Phase gate:** `mix ci.fast`, `mix rendro.livebook.check`, and an explicit static-file smoke check that serves no API calls/build products.

### Wave 0 Gaps

- [ ] `test/rendro/theme/snippet_test.exs` — 504 formatter/index parse/evaluate and representative render bridge.
- [ ] `test/mix/tasks/rendro_gen_theme_test.exs` — strict flags, safe derivation, module compilation, create/conflict/force/check behavior.
- [ ] `test/docs_contract/configurator_static_contract_test.exs` — no framework/build/server/unsafe DOM patterns; semantic/accessibility/static asset layout.
- [ ] `test/docs_contract/configurator_resolver_contract_test.exs` — synthetic-manifest exact/representative/none/fallback cases.
- [ ] Extend `test/mix/tasks/rendro_livebook_check_test.exs` — exact formatter block, themed render evidence, explicit exclusions.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | no account/server surface |
| V3 Session Management | no | no persistence/session surface |
| V4 Access Control | no | no privileged browser operation beyond user clipboard gesture |
| V5 Input Validation | yes | closed enum validation, duplicate query rejection, strict hex/alias/path checks |
| V6 Cryptography | limited | SHA-256 evidence remains catalog provenance; use existing `:crypto`, never custom crypto |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| URL/manifest DOM injection | Tampering / information disclosure | no `innerHTML`; construct nodes; `textContent`; validate enums and relative paths |
| output path traversal | Tampering | safe relative project path validation; reject absolute/`..` paths |
| atom-table exhaustion | Denial of service | do not convert external preset/module strings with `String.to_atom/1` |
| arbitrary source execution in tests | Elevation of privilege | evaluate only internally generated trusted strings with controlled bindings |
| false clipboard success | Repudiation | await Clipboard promise and present factual failure/retry state |

## Sources

### Primary

- [Mix.Generator](https://hexdocs.pm/mix/main/Mix.Generator.html) — conflict/force/format behavior.
- [Elixir Code](https://hexdocs.pm/elixir/Code.html) — source parsing, formatting, and evaluation security boundary.
- [Livebook API](https://livebook.hexdocs.pm/Livebook.html) — Live Markdown conversion and whole-script limitation.
- [Livebook use cases](https://hexdocs.pm/livebook/use_cases.html) — versioned notebook and `Mix.install` setup.
- Current codebase: `mix.exs`, `lib/rendro/theme*.ex`, `dev/rendro/catalog.ex`, `assets/rendro/catalog.json`, and Livebook checker. [VERIFIED: codebase grep]

### Secondary

- [URLSearchParams](https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams), [History.replaceState](https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState), and [Clipboard.writeText](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText) — browser contracts.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — entirely existing project stack plus official Elixir/Livebook docs.
- Architecture: HIGH — locked context and inspected implementation seams.
- Pitfalls: MEDIUM — one conservative safe module/path implementation detail remains an assumption.

**Research date:** 2026-08-19
**Valid until:** 2026-09-18

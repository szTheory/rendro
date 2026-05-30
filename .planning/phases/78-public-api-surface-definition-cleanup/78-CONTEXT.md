# Phase 78: Public API Surface Definition & Cleanup - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Rendro's public API surface **intentional** before the irreversible 1.0 cut. Concretely (REQUIREMENTS API-01/02/03/05):
- **Hide** accidentally-public engine internals (`@moduledoc false` / `@doc false`).
- **Expose** return-type structs that are currently invisible (notably `Rendro.Metadata`).
- **Author** `priv/public_api.json` — a schema-versioned manifest that is the canonical source of truth for the public surface, every documented module/function carrying exactly one tier (`stable` | `adapter`).
- **Render** a per-module Stable/Adapter badge in ExDoc.
- **Normalize** recipe `sections/2` opts handling across all five recipes (additive).

**This phase DEFINES and CLEANS the surface; it does not ENFORCE it.** The introspection-based docs-contract test that fails CI on drift is Phase 79. (We do, however, build the shared introspection module + generator here, because authoring the manifest needs them — see D-15.)

"Public ≡ what ExDoc renders." Anything left public at 1.0 becomes frozen SemVer surface.
</domain>

<decisions>
## Implementation Decisions

All four discussed areas were taken to deep parallel research (ecosystem idioms + comparable-lib post-mortems + `prompts/` vision) and locked one-shot. Research refined the starting recommendations in 3 of 4 areas — refinements are noted.

### A. Hiding-sweep boundary (which of the 45 public modules to hide)

- **D-01:** **Hide (`@moduledoc false`):** `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter` (required), `Rendro.Text.Bidi`, `Rendro.Text.Shaper`, `Rendro.Format` (Statement-internal formatter), and **`Rendro.Audit`**. Apply `@doc false` to the `Rendro.Sign` `redact_*` helpers (`redact_opts/1`, `redact_prepare_opts/1`, `redact_sign_opts/1`, `redact_augment_opts/1`) and `Rendro.Protect.redact_opts/2`.
  - **`Rendro.Audit` → hide** was the refinement vs. the starting lean's "borderline." Rationale: it is an *internal contract behaviour* with **no user-facing extension hook** — no config option or facade lets a user register a custom audit backend; it exists only so the first-party Threadline adapter has a contract, and the real user path is telemetry. Matches the Elixir idiom of hiding internal contract behaviours (`Ecto.Adapters.SQL.Connection`) while documenting user-implemented ones (`Ecto.Adapter`, `Oban.Worker`).
- **D-02:** **Keep public (reversed from the starting lean):** `Rendro.RunningContent`, `Rendro.EmbeddedFileRegistry`, and `Rendro.FontRegistry.EmbeddedFontFamilyError`.
  - `RunningContent.t()` is referenced by `Rendro.Section`'s public `@type content` (`lib/rendro/section.ex:19`); `EmbeddedFileRegistry.t()` is referenced by `Rendro.Document`'s public `@type t` (`lib/rendro/document.ex:68`). Hiding either creates an **invisible-type gap** — the exact defect API-03 exists to fix. Same reason `Cell`/`Row` stay public (referenced by `Table`'s `@type`).
  - `EmbeddedFontFamilyError` is **raised by the public facade** `Rendro.register_embedded_font_family/3` (`lib/rendro.ex:184` → `lib/rendro/font_registry.ex`). Idiom: exceptions reachable from public functions stay documented so users can `rescue` and pattern-match them — consistent with Rendro's "errors are product" DNA.
- **D-03:** **Sweep philosophy:** hide aggressively on pure engine internals (no user story, no type leakage); keep conservatively on anything load-bearing in a published `@type` or reachable as a raised exception. Net for the 4 borderline: **1 hide (Audit), 3 keep**. Source post-mortem: Prawn's regret over auto-exposed "semi-internal bits" (prawnpdf/prawn#814); Bandit's deliberately sparse surface as the target aesthetic.

### B. Tier line (`stable` vs `adapter`), aligned to the already-shipped `guides/api_stability.md` promise

- **D-04:** **`stable` (Tier-1, strict SemVer for the life of 1.x):** `Rendro` (facade), the document model — `Document`, `Page`, `PageTemplate`, `Section`, `Region`, `Block`, `Text`, `Table`, `Image`, `Cell`, `Row`, `Component` — plus `FontRegistry`, `AssetRegistry`, `EmbeddedFileRegistry`, `RunningContent`, `Error`, `Metadata`, the `Rendro.Sign` / `Rendro.Protect` **facades**, and `Rendro.Recipes` (the delegating registry/facade).
- **D-05:** **`adapter` (Tier-2, telegraphed-evolving / additive-only):** all `Rendro.Adapters.*`, `Rendro.Sign.Adapter` + `Rendro.Protect.Adapter` (the `@callback` behaviours), `Rendro.Storage` + `Rendro.Storage.Local`, `Rendro.Inspector`, `Rendro.Telemetry`, and the **five recipe implementation modules** (`Recipes.Invoice`, `BrandedInvoice`, `Statement`, `Receipt`, `Certificate`).
- **D-06:** **Recipes → adapter** is the most important refinement (starting lean had them stable). Rationale: recipes are an opinionated convenience layer; the Prawn-templates post-mortem (feature dropped 0.13 → disabled 0.14 → extracted 0.15 into an unmaintained gem) shows the convenience layer accretes the most churn and is the layer you most regret freezing. **Split the promise:** the *way you call* a recipe is stable (`Rendro.Recipes` facade entry points), but the *emitted document structure* (region names, section ordering, default fonts) must stay free to evolve → tag the implementation modules `adapter`. Byte-output evolution is already covered by the milestone's "deterministic within a version, not frozen across versions" carve-out.
- **D-07:** **`Rendro.Metadata` → `stable`, and it MUST be exposed** (API-03 is locked). It already has `@type t` and is `@moduledoc false`; flip the moduledoc on. It is the return type of the stable facade `Rendro.metadata/1` (`@spec metadata(keyword()) :: Metadata.t()`, `lib/rendro.ex:283`). Note its `custom` field is an open map (additive by nature).
  - **Disambiguation (research finding):** there are **two** "metadata" surfaces. `Rendro.Metadata` is the *input* struct (title/author/dates) → stable module above. Separately, `%Rendro.Artifact{}.metadata` is an *output* `map()` (`:page_count`, `:deterministic`, `:protection`) — this is what `api_stability.md` already promises as "stable common keys, additive," the same contract as the `:diagnostics` map. The output map is **map content, not a module**, so it carries the diagnostics-style additive contract, not a module tier.
- **D-08:** **`Telemetry` → adapter** with the telemetry-as-API contract: **lock event names + the start/stop/exception span shape; treat metadata keys as additive.** (`:telemetry` itself versions metadata additively; Keathley's telemetry conventions.) `Telemetry`'s name-listing functions (`event_prefixes/0`, etc.) are reliable; the documented metadata maps stay additive.
- **D-09:** **Tiering philosophy (one-liner for the guide/manifest):** a module is `stable` only if it's part of the deterministic core the user *builds against* (document model + facade functions + registries + `Error` + simple data types). Everything that exists to *integrate with the outside world or encode opinions* is `adapter` (every `*.Adapter` behaviour, `Storage`, recipe implementations, `Telemetry`, `Inspector`). Diagnostic-shaped **maps** (`:diagnostics`, artifact `metadata`) get the third already-promised contract: common keys stable, all keys additive. Contradicts nothing in `api_stability.md` — it sorts modules into the three tiers that guide already names in prose.

### C. Recipe `sections/2` opts normalization

- **D-10:** **Option A — minimal additive threading. No `@behaviour`.** Flip `Rendro.Recipes.Invoice` and `Rendro.Recipes.BrandedInvoice` from `sections(data, _opts \\ [])` to `sections(data, opts \\ [])` and thread `opts` into their section helpers (which are currently arity-1 — add arity-2 heads), matching `Statement`/`Receipt`/`Certificate` via the shared `Rendro.Recipes.Pagination.formatter/3` / `label_resolver/1` helpers.
- **D-11:** **Default output must stay byte-identical.** Thread opts so the *signatures* normalize and a `formatters:`/`labels:` path becomes *available*, but keep current defaults so existing rendered bytes are unchanged (honors additive + within-version determinism). If wiring real formatter support into invoice bodies is more than a trivial thread-through, scope the deliverable to "accept and forward opts to helpers" only.
- **D-12:** **Do NOT introduce `@behaviour Rendro.Recipes.Recipe`.** It would freeze the callback set under SemVer on a permanent 1.0 (recipes may gain optional callbacks later), is inconsistent with Rendro's own convention of reserving behaviours for third-party adapter seams (`Sign.Adapter`, `Storage`, `Protect.Adapter` — which use `@optional_callbacks`), and solves a non-problem (no external recipe implementers exist; discoverability is better served by docs + a worked "write your own recipe" example).
- **D-13:** **Defer NimbleOptions / opts validation.** Out of scope for this additive cleanup — it's a feature-shaped, dependency-adding change (new core dep) with its own design surface that would itself want to be SemVer-stable. Belongs in its own intentional phase. → Deferred Ideas.

### D. Manifest shape, schema-versioning, badge mechanism

- **D-14:** **Badge = ExDoc's native `@moduledoc tags: [:stable]` / `[:adapter]`** (ExDoc 0.40 renders a `tags:` list as a native module-annotation badge) + a few lines of CSS injected via `docs/0`'s `before_closing_head_tag` to color Stable (green) vs Adapter (blue). **Reject** the custom JS-reads-metadata approach (unnecessary) and prose-only badges (not machine-checkable). The `tags:` value IS the tier; the badge falls out of ExDoc for free.
- **D-15:** **Single source of truth = the `@moduledoc tags:` attribute in source.** `priv/public_api.json` is a **generated mirror**, not a hand-authored peer. Build a shared introspection module (e.g. `Rendro.PublicApi`) that walks `Code.fetch_docs/1` → `{module → {tier, functions "name/arity", types}}`, consumed by two callers: a **`mix rendro.api.gen`** task (writes the manifest) here in Phase 78, and Phase 79's contract test (regenerates in-memory, asserts equality). Same introspection codepath → test and generator can never disagree. This generator is the single highest-leverage decision: without it, "manifest must exactly equal introspected docs" is a perpetual hand-edit drift treadmill (cf. `cargo-public-api` `tests/public-api.txt` + `UPDATE_EXPECT=1`; .NET PublicAPI analyzer code-fix).
- **D-16:** **Manifest granularity = per-function, grouped by module.** Top-level `{"modules": {...}}`; each module object carries one module-level `tier`, a `functions` list of `"name/arity"`, and a `types` list. Module-level tier satisfies "exactly one tier per module"; the function/type lists satisfy Phase 79's exact-surface-equality + Tier-1 `@spec`-coverage assertions. (Functions do not each carry a tier.) Reject per-module-only (can't express exact surface / `@doc false` exclusions).
- **D-17:** **Schema-versioning = sibling `priv/schemas/public_api.schema.json` (`$id`, no inline version field), validated with JSV** — structurally identical to the proven `support_matrix.json` + `priv/schemas/support_matrix.schema.json` + `Rendro.ViewerEvidence.Validator` (`JSV.validate/2`) stack. The requirement's words "schema-versioned like `support_matrix.json`" mean exactly this; `support_matrix.json` has **no inline version field**. Do NOT add an inline `schema_version` int (corrects the starting recommendation) — it would create a second source of version truth and diverge from the cited precedent. (The inline-`const` style in `viewer_evidence.schema.json` is per-file frontmatter, a different shape.)
- **D-18:** **Drift surfacing (errors-as-product):** the Phase 79 test should emit **two human-readable lists** — "in code but not manifested" and "manifested but not in code" (cf. Roslyn `RS0016`/`RS0017`) — not one opaque `assert ==`. Captured here so the generator/manifest shape supports it.

### Claude's Discretion
- Exact CSS for the Stable/Adapter badge colors, the precise module name for the introspection module (`Rendro.PublicApi` suggested), and the `mix` task namespace are planner/implementer discretion.
- The exact trimmed wording of `@moduledoc`s on kept-but-thin modules (`RunningContent`, `EmbeddedFileRegistry`).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (authoritative scope)
- `.planning/REQUIREMENTS.md` — v2.5 milestone; API-01/02/03/05 are this phase. The scope-lock note (tiers = `stable`|`adapter`, "public ≡ what ExDoc renders", soft-deprecation-first because `mix ci` is `--warnings-as-errors`) is binding.
- `.planning/ROADMAP.md` §"Phase 78" — goal + 5 success criteria. §"Phase 79" — the enforcement lane this phase feeds (do not duplicate its work, but build the shared introspection module so 79 can reuse it).

### Existing surface contract (do not contradict)
- `guides/api_stability.md` — the **already-shipped** stability promise. Names Core API / Adapters / Diagnostics tiers in prose. The manifest must formalize this, not invent a new contract. (Note: it leaks internal labels "Phase 53", "Phase 71", "Rendro v1.10" — that scrub is Phase 80/STAB-04, not this phase, but be aware.)

### Pattern to mirror (manifest + schema + loader + validator)
- `priv/support_matrix.json` — canonical-JSON data file to mirror in shape/spirit.
- `priv/schemas/support_matrix.schema.json` — sibling schema with `$id`, no inline version → the schema-versioning pattern for `public_api.schema.json`.
- `priv/schemas/viewer_evidence.schema.json` — inline-`schema_version` **counter-example** (different shape; do NOT copy for the manifest).
- `lib/rendro/viewer_evidence/validator.ex` — the `JSV.validate/2` usage to reuse for validating `public_api.json`.
- `lib/rendro/viewer_evidence/matrix.ex` — the `priv/`-file loader pattern.

### Code touch-points (surface, types, recipes, ExDoc)
- `mix.exs` `docs/0` (~lines 93–182) — `groups_for_modules`, `extras`, `groups_for_extras`; add `before_closing_head_tag` + badge CSS here. ExDoc pinned `~> 0.40`.
- `lib/rendro.ex:283` — `Rendro.metadata/1` `@spec` returning `Metadata.t()` (API-03 driver).
- `lib/rendro/metadata.ex` — flip `@moduledoc false` → real `@moduledoc`; `@type t` already exists (line ~14).
- `lib/rendro/section.ex:19` (`@type content` → `RunningContent.t()`) and `lib/rendro/document.ex:68` (`@type t` → `EmbeddedFileRegistry.t()`) — the invisible-type-gap references behind D-02.
- `lib/rendro/sign.ex` (`redact_*` at lines ~174–216), `lib/rendro/protect.ex` (`redact_opts/2` ~line 78) — `@doc false` targets.
- `lib/rendro/pdf/cid_font.ex`, `lib/rendro/pdf/font_subsetter.ex`, `lib/rendro/text/bidi.ex`, `lib/rendro/text/shaper.ex`, `lib/rendro/format.ex`, `lib/rendro/audit.ex` — `@moduledoc false` targets.
- `lib/rendro/recipes/invoice.ex` (sections ~line 69, arity-1 helpers ~111–149), `lib/rendro/recipes/branded_invoice.ex` (sections ~line 99, helpers ~138–179) — the two recipes to normalize; reference impls `lib/rendro/recipes/statement.ex` (~204–212) + `lib/rendro/recipes/pagination.ex` (`formatter/3`, `label_resolver/1`).

### Vision / DX research (informed the decisions)
- `prompts/rendro-oss-dna.md`, `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`, `prompts/rendro-integration-opportunities.md` — minimal-surface + "errors are product" DNA, ecosystem positioning.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`JSV` validation stack** (`lib/rendro/viewer_evidence/validator.ex` + `matrix.ex`): reuse verbatim to load + validate `priv/public_api.json` against `priv/schemas/public_api.schema.json`. No new dep, proven pattern.
- **`Rendro.Recipes.Pagination.formatter/3` + `label_resolver/1`**: the existing opts-threading helpers Statement/Receipt/Certificate already use; Invoice/BrandedInvoice should thread through these (D-10/D-11).
- **ExDoc `before_closing_head_tag`**: standard injection slot in `docs/0` for the badge CSS (D-14).
- **`Code.fetch_docs/1` + `@moduledoc tags:`**: native ExDoc/Elixir mechanism powering both the badge and the manifest generator (D-14/D-15).

### Established Patterns
- **Conditionally-compiled integration adapters** (CRITICAL): `Rendro.Adapters.Phoenix`, `Oban.RenderWorker`, `Threadline`, `Mailglass`, `Accrue` are defined **inside `if Code.ensure_loaded?(...)` guards** (indented `defmodule`; `phoenix.ex` has stub+real at lines 2 and 75). They only appear in `Code.fetch_docs/1`/ExDoc when their optional dep is compiled. The manifest, the `mix rendro.api.gen` generator, and Phase 79's "exact equality" test must run where all optional deps are present (dev/test) and/or explicitly account for conditional presence. This is the chief footgun for the whole tier-manifest enforcement chain.
- **Behaviour convention**: `@behaviour` + `@optional_callbacks` is used ONLY at adapter seams (`Sign.Adapter`, `Storage`, `Protect.Adapter`). Reinforces D-12 (no recipe behaviour).
- **`@moduledoc false` already widely used**: pipeline, rules, viewer-evidence, proof adapters are already hidden — the sweep extends an existing discipline, it doesn't introduce one.

### Integration Points
- New `Rendro.PublicApi` introspection module + `mix rendro.api.gen` task → consumed by Phase 79's `test/docs_contract/public_api_contract_test.exs`.
- New `priv/public_api.json` + `priv/schemas/public_api.schema.json` → validated in-tree; wired into Phase 79's required status checks.
- `mix.exs` `docs/0` badge CSS → ExDoc/HexDocs render.

### Drift to resolve during the sweep
- `mix.exs` `groups_for_modules` lists `Adapters.Phoenix/Oban.RenderWorker/Threadline/Mailglass/Accrue` (all real, conditionally compiled) and places `PyHanko`/`Pdfsig` under "Signing" not "Ecosystem Adapters". The full sweep must reconcile the group list with the actual compiled module set so the manifest lists real modules only.
</code_context>

<specifics>
## Specific Ideas

- User explicitly requested deep multi-agent research per area (ecosystem idioms, comparable-lib post-mortems incl. cross-language, DX / principle-of-least-surprise, `prompts/` vision) and a one-shot coherent locked recommendation set — delivered above. The decisions are mutually coherent and converge on: **minimal frozen surface, three-tier honesty (stable / adapter / additive-maps), code-as-source-of-truth with a generated test-locked manifest.**
- Concrete comparable-lib anchors the planner can cite in guide/CHANGELOG prose: Prawn templates extraction (don't freeze the convenience layer), Bandit sparse surface (target aesthetic), Ecto.Adapter (evolving adapter tier), Keathley telemetry conventions (names+span locked, metadata additive), cargo-public-api / .NET PublicAPI analyzer (generated snapshot + regenerate task + two-sided drift diff).
</specifics>

<deferred>
## Deferred Ideas

- **Formal `@behaviour Rendro.Recipes.Recipe` contract** for user-authored recipes — deferred (D-12). Revisit only when there's demand for third-party recipe implementers; pair with a "write your own recipe" guide + worked example.
- **NimbleOptions-based opts validation/documentation for recipes** — deferred (D-13). Feature-shaped, adds a core dep; its own phase if recipe opts ever become a documented stable schema.
- **Splitting `rendro` / `rendro_adapters` into separate hex packages** — out of scope per REQUIREMENTS (tier differentiation via documented tiers, not package surgery). Revisit only if adapter churn proves painful.
- **Scrub of internal milestone/phase labels** ("Phase 53", "Phase 71", "Rendro v1.10") from `guides/api_stability.md` — belongs to Phase 80 / STAB-04, noted so this phase doesn't touch it.

</deferred>

---

*Phase: 78-public-api-surface-definition-cleanup*
*Context gathered: 2026-05-30*

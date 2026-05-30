# Phase 78: Public API Surface Definition & Cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 78-public-api-surface-definition-cleanup
**Areas discussed:** Hiding-sweep boundary, Tier line (stable vs adapter), Recipe opts normalization, Manifest shape & badge mechanism

**Process:** Advisor mode (calibration `minimal_decisive`, `opinionated` profile). Codebase scouted via 2 parallel Explore agents (surface map + manifest/ExDoc/recipes); 2 high-impact areas grounded via 2 more Explore agents (hide-candidate classification + existing stability promises). User then requested deep research on ALL four areas → 4 parallel `general-purpose` research agents (ecosystem idioms + comparable-lib post-mortems + `prompts/` vision) → one-shot coherent locked set. Research refined the starting recommendation in 3 of 4 areas.

---

## A. Hiding-sweep boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Ratify as recommended | Hide engine cluster + redact_*; of 4 borderline hide Audit/RunningContent/EmbeddedFileRegistry, keep exception; keep Cell/Row | (superseded by research) |
| Hide all borderline too | Also hide EmbeddedFontFamilyError | |
| Keep borderline public | Only hide clear engine cluster + required internals | |

**User's choice:** "research using subagents... one-shot a perfect set of recommendations."
**Research outcome (locked):** Hide `CidFont`, `FontSubsetter`, `Text.Bidi`, `Text.Shaper`, `Format`, **`Audit`** (`@moduledoc false`); `@doc false` the `redact_*` helpers. **Keep `RunningContent`, `EmbeddedFileRegistry`, `EmbeddedFontFamilyError`** (refinement vs. the ratify option). `RunningContent`/`EmbeddedFileRegistry` `t()` are referenced by public `@type`s → hiding = invisible-type gap. `EmbeddedFontFamilyError` is raised by a public facade → keep rescue-able. `Audit` is an internal contract behaviour with no user extension hook → hide.
**Notes:** Anchors — Prawn #814 (regret over exposed semi-internals), Bandit sparse surface, Ecto.Adapter (keep) vs Ecto.Adapters.SQL.Connection (hide).

---

## B. Tier line (stable vs adapter)

| Option | Description | Selected |
|--------|-------------|----------|
| Ratify as recommended | Recipes stable; Storage/Metadata adapter | (refined by research) |
| Recipes → adapter tier | Treat recipes as evolving/additive | ✓ (research-adopted) |
| Storage → stable tier | Promise Storage behaviour as strict SemVer | |

**User's choice:** Deep research → one-shot recommendation.
**Research outcome (locked):** **Recipes implementation modules → adapter** (Prawn-templates extraction post-mortem: never freeze the opinionated convenience layer); `Rendro.Recipes` facade stays stable. `Storage`/`Storage.Local` → adapter (it's a `@callback` behaviour like `Ecto.Adapter`). `Metadata` (input struct) → **stable AND must be exposed** per locked API-03; distinct from the artifact `metadata` **map** which gets the diagnostics-style additive contract. `Telemetry` → adapter (names+span locked, metadata additive). `Sign`/`Protect` facades → stable; their `.Adapter` behaviours → adapter.
**Notes:** Aligns with already-shipped `guides/api_stability.md` (Core / Adapters / Diagnostics). Anchors — Ecto.Adapter, Keathley telemetry conventions, SemVer #238 / Req experimental-module tag.

---

## C. Recipe sections/2 opts normalization

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal additive threading | Flip Invoice/BrandedInvoice _opts→opts, thread to helpers | ✓ |
| Formal @behaviour contract | Introduce Rendro.Recipes.Recipe behaviour | |

**User's choice:** Deep research → one-shot recommendation.
**Research outcome (locked):** Option A (minimal additive threading), **no behaviour**, **defer NimbleOptions**. Keep default output byte-identical (thread opts but defaults unchanged). Behaviour would freeze the callback set under SemVer on a permanent 1.0 and is inconsistent with Rendro reserving behaviours for adapter seams; solves a non-problem (no external recipe implementers).
**Notes:** Anchors — Plug/Ecto/Oban behaviour-when-user-implements idiom; NimbleOptions is feature-shaped + a new core dep.

---

## D. Manifest shape, schema-versioning, badge mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Per-function + sibling schema + JS badge | per-function manifest, sibling schema + inline schema_version, JS badge | (refined by research) |
| Per-module entries only | coarser manifest | |
| Prose badge, no JS | text badge in moduledoc | |

**User's choice:** Deep research → one-shot recommendation.
**Research outcome (locked):** Badge via **native ExDoc `@moduledoc tags: [:stable|:adapter]`** + small `before_closing_head_tag` CSS (not custom JS). **Single source of truth = `@moduledoc tags:` in source**; `priv/public_api.json` is a **generated mirror** via a shared `Rendro.PublicApi` introspection module + **`mix rendro.api.gen`** task (reused by Phase 79's test). Per-function entries grouped by module, module-level tier. Schema = sibling `priv/schemas/public_api.schema.json` (`$id`, **no inline version**) validated by JSV — mirrors `support_matrix.json` exactly (corrects the starting "inline schema_version" idea). Two-sided drift diff (cf. Roslyn RS0016/RS0017).
**Notes:** Key finding — ExDoc 0.40's `tags:` is native and `Code.fetch_docs/1`-readable, collapsing the source-of-truth tension. Anchors — cargo-public-api, .NET PublicAPI analyzer.

---

## Claude's Discretion
- Badge CSS colors; introspection module name (`Rendro.PublicApi` suggested) and `mix` task namespace; trimmed `@moduledoc` wording on kept-but-thin modules.

## Deferred Ideas
- Formal `Rendro.Recipes.Recipe` behaviour (when third-party recipe demand exists).
- NimbleOptions opts validation/documentation (own phase).
- `rendro` / `rendro_adapters` package split (out of scope per REQUIREMENTS).
- Internal milestone/phase label scrub from `api_stability.md` (Phase 80 / STAB-04).

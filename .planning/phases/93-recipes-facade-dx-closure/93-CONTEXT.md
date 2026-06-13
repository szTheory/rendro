# Phase 93: Recipes Facade DX Closure - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every shipped recipe — Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate — reachable from the single `Rendro.Recipes` facade via hand-written `@spec`'d arity-1 + arity-2 wrapper pairs, with options threaded correctly, the existing `invoice/1` opts-drop footgun fixed, a drift test that prevents future facade/recipe divergence, and the generated public-API contract regenerated to reflect the additive surface.

**This phase is fully specified by ROADMAP.md Phase 93 success criteria (SC #1–#4) — they function as a SPEC.** Discussion did not surface new gray areas; instead, deep parallel research (advisor mode, `minimal_decisive`) produced a coherent locked set of implementation decisions for the micro-choices the criteria leave open. No scope was added.

**Out of scope (held v2.8 non-goals):** global text shaping, mobile GUI viewer promotion, TOC/anchors/cross-refs, charts, existing-PDF editing, release-please automation. Do NOT add validation frameworks, new opts authorities, or new recipe families.

</domain>

<decisions>
## Implementation Decisions

All four decisions were researched in parallel and are mutually coherent: thin hand-written facade → transparent opts pass-through → struct-level drift test → clean additive `:stable` contract surface.

### Facade Delegation Pattern
- **D-01:** Use **hand-written `@doc` + `@spec` wrapper pairs**, one per recipe. The arity-1 wrapper delegates to the facade's **own arity-2** wrapper; the arity-2 wrapper delegates to the recipe module's `document/2`:
  ```elixir
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data), do: invoice(data, [])

  @spec invoice(map(), keyword()) :: Rendro.Document.t()
  def invoice(data, opts), do: Rendro.Recipes.Invoice.document(data, opts)
  ```
  This makes "`name(data)` ≡ `name(data, [])`" a **structural invariant**, not an accident of the target's default arg.
- **D-02:** **Rejected `Kernel.defdelegate`** — its generated arity-1 clause calls the target `document/1` directly (bypassing the facade arity-2), so it cannot satisfy the structural arity-1→arity-2 guarantee, and it emits no `@spec` and (since Elixir v1.6) no `@doc`, so it saves almost no boilerplate. **Rejected macro/loop generation** — contradicts the "hand-written, `@spec`'d" criterion, hurts ExDoc/grep-ability, and adds a metaprogramming footgun to a contract-guarded public surface.
- **D-03:** Apply the same arity-1→arity-2 shape uniformly to all five recipes: `invoice`, `branded_invoice`, `statement`, `receipt`, `certificate` (10 functions total).

### Options Threading & Footgun Fix
- **D-04:** **Transparent pass-through.** Add `opts \\ []` at the facade arity-2 and forward verbatim to `Recipe.document(data, opts)`. The recipe modules remain the **single opts authority** (they already own/tolerate keys via `Keyword.get/3`, proven by the existing `*_opts_threading_test.exs`). No defaults live at the facade.
- **D-05:** **No validation/whitelist at the facade** (no NimbleOptions). A facade-level schema would create a second, drift-prone opts authority (each recipe accepts different keys: `:formatters` / `:labels` / `:border` / `:page_number_opts`) for negative DX. This keeps the facade a thin convenience alias (idiomatic — matches Req/Finch/Plug thin wrappers).
- **D-06:** Fix the README footgun line (`README.md:135`): change "calls `Rendro.Recipes.Invoice.document/1` for convenience" to reflect that opts now thread through `…document/2`. Facade `@doc` should point callers to the recipe module's `## Options` as the authoritative key list rather than duplicating per-key docs.

### Drift-Prevention Test
- **D-07:** Drive the test from an explicit `@recipes` **single-source-of-truth** table:
  ```elixir
  @recipes [
    {:invoice, Rendro.Recipes.Invoice},
    {:branded_invoice, Rendro.Recipes.BrandedInvoice},
    {:statement, Rendro.Recipes.Statement},
    {:receipt, Rendro.Recipes.Receipt},
    {:certificate, Rendro.Recipes.Certificate}
  ]
  ```
  Adding a recipe forces a deliberate, reviewed edit here.
- **D-08:** Three assertions off `@recipes`: (1) reachability via `function_exported?(Rendro.Recipes, name, 1)` **and** `(.., name, 2)`; (2) "no extra functions" via `MapSet.new(Rendro.Recipes.__info__(:functions))` equals the expected name×{1,2} set — raw `__info__(:functions)` is correct/strict here because the facade is a flat delegation module with no macro noise; (3) byte-identity compared on the **`%Rendro.Document{}` struct** (`Rendro.Recipes.name(data, opts) == Module.document(data, opts)`), **NOT** rendered PDF bytes — struct `==` is exact and deterministic, sidestepping every PDF timestamp / object-id / font-subset-ordering pitfall.
- **D-09:** Add one **auto-discovery sweep** assertion to catch orphan recipe modules: filter `:application.get_key(:rendro, :modules)` to `Rendro.Recipes.*` modules exporting `document/2`, subtract `Rendro.Recipes.Pagination` (no `document/2`), and assert that set equals the modules in `@recipes`. This catches a future recipe module that forgot its facade wrapper, while preserving the reviewed-edit guarantee.
- **D-10:** Reuse the existing per-recipe sample-data / fixture builders from `test/rendro/recipes/{invoice,receipt,certificate,statement,branded_invoice}_test.exs`. Also add a facade-level **opts-threading regression test** (a sentinel opt such as `:page_number_opts` or `:labels` must reach the recipe / change the result) so the silent-drop footgun cannot recur. The drift test starts RED until the facade is completed — that is correct for this phase.

### Public-API Contract Regeneration
- **D-11:** **Author the `@spec` + a real (non-`@doc false`) docstring on all 8 new defs BEFORE regenerating.** `Rendro.Recipes` is `@moduledoc tags: [:stable]`, so every new arity inherits `tier: "stable"`, and the contract test's spec-coverage assertion **requires** a `@spec`. A docstring is also required or `public_functions/1` drops the function from the surface.
- **D-12:** Regenerate mechanically via `mix rendro.api.gen` (never hand-edit `priv/public_api.json`). Verify the diff grows the `Elixir.Rendro.Recipes.functions` array from 2 entries to the 10-entry alpha-sorted set (`branded_invoice/1, branded_invoice/2, certificate/1, certificate/2, invoice/1, invoice/2, receipt/1, receipt/2, statement/1, statement/2`) with **only `+` lines, no `-` lines** (additive ⇒ no Tier-1 symbol replaced) and no other module touched. Then `public_api_contract_test.exs` byte-compare must pass.
- **D-13:** *(Optional, low-priority)* Add a one-line note to `guides/api_stability.md` that the Recipes facade now exposes statement/receipt/certificate plus arity-2 `opts` forms. Tier-1 already covers facades by module, so no per-function edits are required.

### Claude's Discretion
- Exact wording of the new `@doc` strings and the README correction (keep the README fix minimal — correct the inaccurate line and note opts now thread; a full 5-pair rewrite is optional, not required).
- Whether the facade opts-threading regression test lives in a new `test/rendro/recipes_test.exs` (facade-level) alongside the drift test, or as a dedicated file mirroring the existing `*_opts_threading_test.exs` naming. Planner/executor choose to match repo conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase spec & requirements
- `.planning/ROADMAP.md` § "Phase 93: Recipes Facade DX Closure" — the four success criteria; these are the binding spec for this phase.
- `.planning/REQUIREMENTS.md` — DX-01 (facade reaches every recipe), DX-02 (drift test).

### Facade & recipe source (the code being changed)
- `lib/rendro/recipes.ex` — current facade (only `invoice/1`, `branded_invoice/1`, both arity-1 calling `Module.document(data)` and dropping opts). This is the file to expand.
- `lib/rendro/recipes/invoice.ex` — `document/2` (line ~136), `page_template/1`, `sections/2`; shows how opts flow through a recipe.
- `lib/rendro/recipes/branded_invoice.ex`, `statement.ex`, `receipt.ex`, `certificate.ex` — each exposes `document(data, opts \\ [])` (the delegation targets). `pagination.ex` has NO `document/2` (exclude from the drift sweep).

### Test patterns to mirror
- `test/rendro/recipes/invoice_opts_threading_test.exs`, `test/rendro/recipes/branded_invoice_opts_threading_test.exs` — established opts-threading assertion pattern; mirror for the facade-level regression test.
- `test/rendro/recipes/{invoice,receipt,certificate,statement,branded_invoice}_test.exs` — sample-data / fixture builders to reuse in the drift test.
- `test/docs_contract/public_api_contract_test.exs`, `test/rendro/public_api_test.exs` — existing reflection / `MapSet.difference` two-list drift-diff / byte-compare idioms already used in this repo; match this style.

### Contract tooling & guides
- `lib/mix/tasks/rendro.api.gen.ex` — the generator (alpha-sorted, deterministic; derives tier from `@moduledoc tags`; drops `@doc false` functions; requires `@spec` for stable tier).
- `priv/public_api.json` — the committed golden contract to regenerate (the `Elixir.Rendro.Recipes.functions` array grows 2 → 10).
- `guides/api_stability.md` — tiering model; Tier-1 covers facades by module.
- `README.md` §~135 — the inaccurate "delegating alias … document/1" line to correct.

### Project vision / DX values (background)
- `prompts/rendro-oss-dna.md`, `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — DX, principle-of-least-surprise, API-stability posture that justifies the thin hand-written facade over metaprogramming.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All five recipe modules already expose `document(data, opts \\ [])` — the delegation targets exist; this phase only wires the facade.
- Existing `*_opts_threading_test.exs` and per-recipe `*_test.exs` provide sample-data builders and the exact assertion style to reuse.
- This repo already has reflection-based contract tests (`__info__`, `MapSet.difference`, byte-compare, `Code.fetch_docs/1`) — the drift test composes from established idioms, no new test infrastructure.
- `mix rendro.api.gen` already produces a deterministic, alpha-sorted golden file; the regen is mechanical.

### Established Patterns
- Thin public facade over implementation modules (current `Rendro.Recipes`), `@moduledoc tags: [:stable]` → tier inheritance.
- Curated public surface guarded by a generated `priv/public_api.json` + byte-compare contract test; stable-tier functions require `@spec`.
- Recipe modules own their opts contract via `Keyword.get/3` (tolerant of unknown keys).

### Integration Points
- `Rendro.Recipes` ↔ the five `Rendro.Recipes.*` recipe modules (`document/2`).
- New facade functions ↔ `priv/public_api.json` (additive, via `mix rendro.api.gen`).
- Drift/opts tests ↔ existing recipe test fixtures and contract-test idioms.

</code_context>

<specifics>
## Specific Ideas

- User explicitly requested deep parallel research → one coherent, decisive, locked recommendation set (per `minimal_decisive` calibration / opinionated vendor philosophy). Decisions above are that locked set; downstream agents should implement them, not re-open them.
- Coherence anchor: thin hand-written facade (D-01) → transparent opts (D-04/05) → struct-level drift test (D-08) → clean additive `:stable` contract (D-11/12). These reinforce each other; changing one (e.g. adding facade-level validation) would break the coherence and is explicitly rejected.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Full README 5-pair rewrite and the `api_stability.md` note are optional polish within this phase, not deferred capabilities.)

</deferred>

---

*Phase: 93-recipes-facade-dx-closure*
*Context gathered: 2026-06-13*

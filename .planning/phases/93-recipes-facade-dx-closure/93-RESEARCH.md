# Phase 93: Recipes Facade DX Closure - Research

**Researched:** 2026-06-13
**Domain:** Elixir module facade wiring, API contract tooling, drift-prevention testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Hand-written `@doc` + `@spec` wrapper pairs. Arity-1 wrapper delegates to the facade's own arity-2 wrapper; arity-2 delegates to the recipe module's `document/2`.
- **D-02:** `Kernel.defdelegate` rejected; macro/loop generation rejected.
- **D-03:** Same arity-1→arity-2 shape for all five recipes: `invoice`, `branded_invoice`, `statement`, `receipt`, `certificate` (10 functions total).
- **D-04:** Transparent opts pass-through. `opts \\ []` at facade arity-2, forwarded verbatim to `Recipe.document(data, opts)`. No defaults at facade.
- **D-05:** No facade-level validation/whitelist (no NimbleOptions).
- **D-06:** Fix README.md:135 line. Facade `@doc` points callers to recipe module `## Options`, does not duplicate per-key docs.
- **D-07:** Drift test driven from explicit `@recipes` single-source-of-truth table.
- **D-08:** Three assertions from `@recipes`: (1) reachability via `function_exported?`; (2) no-extra-functions via `MapSet` equality on `__info__(:functions)`; (3) byte-identity on `%Rendro.Document{}` struct (not rendered PDF bytes).
- **D-09:** Auto-discovery sweep: filter `:application.get_key(:rendro, :modules)` to `Rendro.Recipes.*` modules exporting `document/2`, subtract `Rendro.Recipes.Pagination` (confirmed: no `document/2`), assert set equals modules in `@recipes`.
- **D-10:** Reuse existing per-recipe fixture builders. Add facade-level opts-threading regression test using a sentinel opt (`:page_number_opts` or `:labels`).
- **D-11:** Author `@spec` + real docstring on all 8 new defs BEFORE regenerating. `Rendro.Recipes` is `@moduledoc tags: [:stable]` — every new arity inherits `tier: "stable"`. `@spec` and docstring required.
- **D-12:** Regenerate via `mix rendro.api.gen` (never hand-edit). Verify diff is additive-only on `Elixir.Rendro.Recipes.functions` (2 → 10), no other module touched.
- **D-13 (optional):** Add one-line note to `guides/api_stability.md`.

### Claude's Discretion
- Exact wording of new `@doc` strings and README correction.
- Whether facade opts-threading regression test lives in a new `test/rendro/recipes_test.exs` (facade-level) alongside the drift test, or as a dedicated file mirroring existing `*_opts_threading_test.exs` naming.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. Full README 5-pair rewrite and `api_stability.md` note are optional polish within this phase, not deferred capabilities.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | `Rendro.Recipes` exposes Statement, Receipt/Report, and Certificate through the same facade that already delegates Invoice and BrandedInvoice | Verified: current facade only has `invoice/1` and `branded_invoice/1`; all three missing recipes have `document/2` ready to delegate to |
| DX-02 | A test asserts each shipped recipe is reachable and renders through the `Rendro.Recipes` facade, preventing future facade/recipe drift | Verified: test idioms (`__info__/1`, `MapSet`, `:application.get_key`, struct `==`, `Code.fetch_docs/1`) all exist in this repo's test suite |
</phase_requirements>

---

## Summary

Phase 93 is a surgical wiring task: add 8 new function definitions to `lib/rendro/recipes.ex`, write one new test file (drift + opts-threading regression), fix one README line, and run `mix rendro.api.gen`. The entire implementation fits within three files of source changes and one generated file update.

All five recipe modules (`Invoice`, `BrandedInvoice`, `Statement`, `Receipt`, `Certificate`) already expose `document(data, opts \\ [])` — the delegation targets are confirmed present. The current facade at `lib/rendro/recipes.ex` contains exactly two arity-1-only functions (`invoice/1` and `branded_invoice/1`), both calling `Module.document(data)` with opts dropped. This is the opts-drop footgun D-04/D-06 address.

The repo already uses every testing idiom the drift test requires: `__info__(:functions)`, `MapSet`, `:application.get_key(:rendro, :modules)`, struct `==` byte comparison, and `Code.fetch_docs/1`. The contract generator (`lib/mix/tasks/rendro/api.gen.ex`) is confirmed deterministic and alpha-sorted, and `priv/public_api.json` currently records `Elixir.Rendro.Recipes.functions` as `["branded_invoice/1", "invoice/1"]` — the post-phase target is 10 entries.

**Primary recommendation:** Implement in one wave: (1) expand `lib/rendro/recipes.ex` with 8 new defs, (2) write `test/rendro/recipes_facade_drift_test.exs` (or `test/rendro/recipes_test.exs` per discretion), (3) fix `README.md:135`, (4) run `mix rendro.api.gen`, (5) verify `public_api_contract_test.exs` passes.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Facade delegation (opts pass-through) | `lib/rendro/recipes.ex` | — | Thin wrapper; no business logic; delegates 100% to recipe modules |
| Opts contract / key ownership | Recipe modules (`Invoice`, `Statement`, etc.) | — | Each recipe owns its own opts via `Keyword.get/3`; facade is intentionally dumb |
| Drift detection | `test/rendro/recipes_facade_drift_test.exs` (new) | `test/rendro/public_api_test.exs` (existing sweep) | Test-layer; reflection-based; no runtime cost |
| Public API contract | `priv/public_api.json` (generated) + `public_api_contract_test.exs` | — | Existing golden-file contract system; additive diff expected |
| README accuracy | `README.md:135` | — | One-line prose fix |

---

## VERIFIED CODE STATE: Current `lib/rendro/recipes.ex`

**[VERIFIED: direct file read]** Current facade is exactly 32 lines with two public functions:

```elixir
defmodule Rendro.Recipes do
  @moduledoc tags: [:stable]

  @doc "..."
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data) do
    Rendro.Recipes.Invoice.document(data)   # calls document/1 — opts dropped
  end

  @doc "..."
  @spec branded_invoice(map()) :: Rendro.Document.t()
  def branded_invoice(data) do
    Rendro.Recipes.BrandedInvoice.document(data)   # calls document/1 — opts dropped
  end
end
```

**DISCREPANCY NOTE — Opts-Drop Footgun Confirmed:** Both existing calls use `Module.document(data)` which resolves to `document/2` with `opts = []` via the default arg. This means opts ARE silently dropped — the footgun is real and actively present. The fix is replacing `Module.document(data)` with `Module.document(data, opts)` in the new arity-2 wrappers and removing the direct arity-1 delegations.

**DISCREPANCY NOTE — No Existing `document/1` on Recipe Modules:** The CONTEXT.md description of the existing facade says it "calls `Module.document(data)` and dropping opts." Technically `document(data)` dispatches to `document/2` via the default arg `opts \\ []` — there is no standalone `document/1` clause. This is consistent with D-01's design. The arity-1 facade wrapper must call the facade's own arity-2 wrapper, not the recipe's `document/2` directly.

---

## VERIFIED CODE STATE: Recipe Module `document/2` Signatures

**[VERIFIED: direct file reads]**

| Module | `document/2` signature | opts accepted |
|--------|------------------------|---------------|
| `Rendro.Recipes.Invoice` | `def document(data, opts \\ [])` line 136 | opts forwarded to `page_template/1` and `sections/2`; `sections` passes to `header_section/body_section/footer_section`; footer ignores opts (no page_number_opts); body/header ignore opts |
| `Rendro.Recipes.BrandedInvoice` | `def document(data, opts \\ [])` line 115 | opts forwarded to `page_template/1` and `sections/2` |
| `Rendro.Recipes.Statement` | `def document(data, opts \\ [])` line 236 | `:formatters`, `:labels`, `:page_number_opts` via `Rendro.Recipes.Pagination` helpers |
| `Rendro.Recipes.Receipt` | `def document(data, opts \\ [])` line 228 | `:formatters`, `:page_number_opts` via `Rendro.Recipes.Pagination` helpers |
| `Rendro.Recipes.Certificate` | `def document(data, opts \\ [])` line 225 | `:border`, `:page_size`, `:orientation`, `:margin_*`, `:page_number_opts` |

All five confirmed present. No recipe is missing `document/2`.

---

## VERIFIED CODE STATE: `Rendro.Recipes.Pagination`

**[VERIFIED: direct file read]** `lib/rendro/recipes/pagination.ex`:
- `@moduledoc false` — correctly excluded from the public surface
- Public functions: `chunk_rows_into_pages/2`, `formatter/3`, `label_resolver/1`, `type_name/1`
- **NO `document/2`** — confirmed correct; the auto-discovery sweep in D-09 subtracts `Rendro.Recipes.Pagination` and this is accurate

---

## VERIFIED CODE STATE: Current `priv/public_api.json` — `Elixir.Rendro.Recipes`

**[VERIFIED: direct file read]** Lines 319–325:
```json
"Elixir.Rendro.Recipes": {
  "functions": [
    "branded_invoice/1",
    "invoice/1"
  ],
  "tier": "stable",
  "types": []
}
```

Post-phase target (10 entries, alpha-sorted):
```json
"functions": [
  "branded_invoice/1",
  "branded_invoice/2",
  "certificate/1",
  "certificate/2",
  "invoice/1",
  "invoice/2",
  "receipt/1",
  "receipt/2",
  "statement/1",
  "statement/2"
]
```

All 8 new entries are additions (no `-` lines) — satisfies SC #4 additive constraint.

---

## VERIFIED CODE STATE: Contract Generator Behavior

**[VERIFIED: direct file read]** `lib/mix/tasks/rendro/api.gen.ex`:
- Alpha-sorts both module keys and the `functions` / `types` arrays
- Derives `tier` from `@moduledoc tags: [...]` via `Code.fetch_docs/1`
- Drops any function with `@doc false` (they are not surfaced by `Code.fetch_docs/1` docs chunk)
- Requires compiled BEAM file on disk (filters via `Code.fetch_docs/1` match)
- `Rendro.Recipes` is in `@public_modules` list (line 66) — stable tier
- Uses `Jason.OrderedObject` for deterministic key ordering
- `encode_manifest/1` is `@doc false` but accessible for test use (`public_modules/0` also `@doc false`)

**Critical constraint for D-11:** `public_functions/1` in `Rendro.PublicApi` filters out functions where `Code.fetch_docs/1` returns `:hidden` (i.e., `@doc false`). A function with no `@doc` at all has `%{}` (empty map) as its doc, which is NOT `:hidden` — it WILL appear in the manifest. However, the `@spec` requirement for stable-tier functions (contract test Assertion 5) means all 10 new facade functions MUST have `@spec`. And a real docstring (non-empty, non-`@doc false`) is also needed so they appear correctly in ExDoc.

---

## VERIFIED CODE STATE: Test Infrastructure

### `test/docs_contract/public_api_contract_test.exs`

**[VERIFIED: direct file read]** Five assertions confirmed:
1. **Schema validation** — `Validator.validate(manifest) == :ok`
2. **Byte-identity byte-compare** — `fresh_json == checked_in` (also has two-list drift diff for human UX)
3. **Hidden internals** — `Code.fetch_docs/1` returns `:hidden` for listed modules
4. **Tier-tag exactly-one** — `MapSet` filter on `tags: [...]` per module
5. **Stable-tier @spec coverage** — `Code.Typespec.fetch_specs/1` must include every manifested function

**Impact on Phase 93:** After adding 10 new functions to `Rendro.Recipes`, assertion 2 will FAIL (fresh manifest won't match stale `public_api.json`) until `mix rendro.api.gen` is run. Assertion 5 will FAIL until all 10 new functions have `@spec`. This is the expected "RED before GREEN" sequence.

### `test/rendro/public_api_test.exs`

**[VERIFIED: direct file read]** Confirmed usage of:
- `__info__(:functions)` — not directly, but the full-surface sweep uses `:application.get_key(:rendro, :modules)` (line 111)
- `MapSet.difference/2` — line 53 in contract test
- `Code.fetch_docs/1` — line 102 in contract test, line 180 in public_api_test
- `Code.Typespec.fetch_specs/1` — line 226 in contract test
- Struct `==` comparison — pattern already established; D-08 byte-identity check uses direct struct equality

### Opts-Threading Test Pattern

**[VERIFIED: direct file read]** `test/rendro/recipes/invoice_opts_threading_test.exs` and `branded_invoice_opts_threading_test.exs` establish the pattern:

```elixir
use ExUnit.Case, async: true

test "sections/2 with empty opts returns identical result as sections/1" do
  assert Module.sections(data) == Module.sections(data, [])
end

test "sections/2 with unknown opts does not crash and returns sections" do
  sections = Module.sections(data, unknown_opt: :ignored)
  assert is_list(sections)
end
```

The facade-level regression test mirrors this but operates on `Rendro.Recipes.statement/2` (or receipt/certificate) with a sentinel opt that MUST change the result (e.g., `:labels` for Statement, `:border` for Certificate, `:page_number_opts` for Receipt/Statement). The key assertion is that `Rendro.Recipes.statement(data, opts) == Rendro.Recipes.Statement.document(data, opts)` (opts actually reach the recipe).

### Existing Per-Recipe Fixture Builders

**[VERIFIED: direct file reads]** All five fixture modules confirmed:
- `invoice_test.exs` — `sample_data/0` returns `%{id:, date:, items:}`
- `branded_invoice_test.exs` — sample data includes `brand: %{font_name:, logo_name:}`
- `statement_test.exs` — `fixture_data/2` with `n` lines, Decimal opening balance
- `receipt_test.exs` — `fixture_data/2` with `n` line items, Decimal amounts
- `certificate_test.exs` — `fixture_data/1` with `title:, recipient:, body:, date:, seal_line:`

The drift test reuses these fixtures for its struct byte-identity assertion (D-08 item 3). Since these fixtures are in `*_test.exs` files (not `test/support/`), they are not directly importable. The drift test must either inline minimal fixture data or use a similar `defp fixture_data` local to the drift test file.

---

## Architecture Patterns

### The 10-Function Facade Expansion

```elixir
# Source: D-01 from CONTEXT.md + verified against current recipes.ex
@spec invoice(map()) :: Rendro.Document.t()
def invoice(data), do: invoice(data, [])

@spec invoice(map(), keyword()) :: Rendro.Document.t()
def invoice(data, opts), do: Rendro.Recipes.Invoice.document(data, opts)

# ... repeat for branded_invoice, statement, receipt, certificate
```

The arity-1 wrapper calls the facade's own arity-2 — this is a structural invariant making `name(data) ≡ name(data, [])` immune to any change in the recipe's default arg.

### The Drift Test Structure

```elixir
# Source: D-07/D-08/D-09/D-10 from CONTEXT.md
defmodule Rendro.RecipesFacadeDriftTest do
  use ExUnit.Case, async: true

  @recipes [
    {:invoice, Rendro.Recipes.Invoice},
    {:branded_invoice, Rendro.Recipes.BrandedInvoice},
    {:statement, Rendro.Recipes.Statement},
    {:receipt, Rendro.Recipes.Receipt},
    {:certificate, Rendro.Recipes.Certificate}
  ]

  # Assertion 1: reachability (both arities)
  test "each recipe is reachable as name/1 and name/2 on Rendro.Recipes" do
    for {name, _module} <- @recipes do
      assert function_exported?(Rendro.Recipes, name, 1)
      assert function_exported?(Rendro.Recipes, name, 2)
    end
  end

  # Assertion 2: no-extra-functions (MapSet equality)
  test "Rendro.Recipes exposes exactly the expected 10 functions" do
    expected =
      for {name, _} <- @recipes, arity <- [1, 2] do
        {name, arity}
      end
      |> MapSet.new()

    actual = MapSet.new(Rendro.Recipes.__info__(:functions))
    assert actual == expected
  end

  # Assertion 3: struct byte-identity per recipe
  # (fixtures must be defined inline or via defp helpers in this file)

  # Assertion 4 (auto-discovery sweep):
  test "no orphan recipe modules missing facade wrapper" do
    {:ok, all_modules} = :application.get_key(:rendro, :modules)

    recipe_modules_with_document2 =
      all_modules
      |> Enum.filter(fn mod ->
        mod_str = Atom.to_string(mod)
        String.starts_with?(mod_str, "Elixir.Rendro.Recipes.") and
          function_exported?(mod, :document, 2) and
          mod != Rendro.Recipes.Pagination
      end)
      |> MapSet.new()

    expected_modules = MapSet.new(Enum.map(@recipes, fn {_, mod} -> mod end))

    assert recipe_modules_with_document2 == expected_modules
  end
end
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Contract generation | Custom JSON writer | `mix rendro.api.gen` (already exists, deterministic) |
| Opts validation at facade | NimbleOptions schema | Nothing — recipe modules own opts; facade passes through verbatim |
| Cross-recipe module discovery | `File.ls/1` on lib/ | `:application.get_key(:rendro, :modules)` (BEAM-level, authoritative) |
| PDF byte comparison | Parse PDF, compare content | Struct `==` on `%Rendro.Document{}` — exact, deterministic, no PDF timestamp pitfalls |

---

## Common Pitfalls

### Pitfall 1: Calling `Module.document(data)` Instead of `Module.document(data, opts)`

**What goes wrong:** The arity-1 wrapper calls `Module.document(data)` — Elixir resolves this to `document/2` with `opts = []` via the default arg. Opts are silently dropped. This is the CURRENT bug in both `invoice/1` and `branded_invoice/1`.

**Why it happens:** The existing facade functions predate the opts-threading requirement. Copy-paste from them perpetuates the bug.

**How to avoid:** The arity-2 wrapper MUST call `Rendro.Recipes.Invoice.document(data, opts)` explicitly with opts. The arity-1 wrapper calls `invoice(data, [])` (the facade's own arity-2), never the recipe directly.

**Warning signs:** `Rendro.Recipes.statement(data, labels: %{balance: "Saldo"})` returns the same result as `Rendro.Recipes.statement(data)`.

### Pitfall 2: Forgetting `@spec` on New Defs Before Running `mix rendro.api.gen`

**What goes wrong:** `public_api_contract_test.exs` Assertion 5 fails: "Stable-tier functions missing @spec". The manifested function appears in `priv/public_api.json` under the stable-tier `Rendro.Recipes` module, but `Code.Typespec.fetch_specs/1` does not find a matching spec.

**Why it happens:** `Rendro.Recipes` is `@moduledoc tags: [:stable]`. Every new function in this module inherits stable tier. The contract test requires `@spec` for all stable-tier functions.

**How to avoid:** Author all 10 `@spec` annotations before running `mix rendro.api.gen`. Both arities need specs.

### Pitfall 3: Drift Test Using Rendered PDF Bytes Instead of Struct Equality

**What goes wrong:** PDF bytes contain timestamps, object IDs, font subsetting offsets that are non-deterministic across renders. A test asserting `Rendro.render(doc1) == Rendro.render(doc2)` will be flaky or require deterministic rendering mode flags.

**Why it happens:** Natural instinct to compare "the same document" means comparing outputs.

**How to avoid:** Assert `Rendro.Recipes.invoice(data, opts) == Rendro.Recipes.Invoice.document(data, opts)` — struct-level equality on `%Rendro.Document{}` is exact and deterministic. Rendro already uses this pattern in its existing test suite.

### Pitfall 4: `__info__(:functions)` Including Unexpected Functions

**What goes wrong:** The "no-extra-functions" assertion (D-08 item 2) fails because `__info__(:functions)` returns functions the developer didn't expect — e.g., if a macro or behavior injects hidden functions.

**Why it happens:** Some modules get auto-generated functions from `use` macros.

**How to avoid:** `Rendro.Recipes` uses no `use` macros; it is a plain `defmodule` with `@moduledoc`. `__info__(:functions)` is clean. Confirm by running `Rendro.Recipes.__info__(:functions)` in IEx after implementing — expect exactly `[{:branded_invoice, 1}, {:branded_invoice, 2}, {:certificate, 1}, ...]`.

### Pitfall 5: Fixture Reuse Across Test Files

**What goes wrong:** The drift test wants to reuse fixture builders from `*_test.exs` files, but `defp` helpers in test files are private to that module. Directly importing them is not possible.

**Why it happens:** Fixture builders live in `*_test.exs` modules as `defp` — they are private. `test/support/` would be the right place for shared fixtures, but these were not built there.

**How to avoid:** The drift test must inline its own minimal fixture data (maps sufficient to pass recipe validation). These need not be comprehensive — the struct byte-identity assertion only needs valid data, not edge-case data. Minimal fixtures per recipe:
- Invoice: `%{id: "INV-001", date: ~D[2026-01-01], items: []}`
- BrandedInvoice: requires `brand: %{font_name: :brand_heading, logo_name: :company_logo}` + font/logo registration (may require test support setup or skip byte-identity for this recipe — see open question below)
- Statement: requires Decimal dependency; `opening_balance: Decimal.new("100.00")`, `lines: []`, etc.
- Receipt: `title:`, `date:`, `customer: %{name: ""}`, `lines: []`
- Certificate: `title:`, `recipient:`, `date:`

---

## README Footgun Line (D-06)

**[VERIFIED: direct file read]** `README.md` line 135:

```
The delegating alias `Rendro.Recipes.invoice/1` calls `Rendro.Recipes.Invoice.document/1` for convenience.
```

**Required change:** Correct to reflect that `Rendro.Recipes.invoice/2` now accepts opts and threads them through, and that `invoice/1` is equivalent to `invoice(data, [])`. Minimal fix:

```
`Rendro.Recipes.invoice/1` (and `/2`) delegates to `Rendro.Recipes.Invoice.document/2`, threading opts through.
```

---

## Package Legitimacy Audit

No external packages are installed in this phase. All changes are:
1. New function definitions in an existing Elixir source file
2. A new test file
3. One generated JSON file update (no new deps)
4. One README line edit

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | All | Confirmed (project compiles) | ~> 1.19 | — |
| `decimal` library | Statement/Receipt fixtures in drift test | In mix.exs deps | >= 2.3.0 | — |
| `mix rendro.api.gen` | Contract regeneration (D-12) | Confirmed present at `lib/mix/tasks/rendro/api.gen.ex` | — | — |
| Jason (for `mix rendro.api.gen`) | JSON encoding | Confirmed (already used in generator) | — | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

`nyquist_validation: true` in `.planning/config.json` — this section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no separate install) |
| Config file | `test/test_helper.exs` (standard) |
| Quick run command | `mix test test/rendro/recipes/ test/docs_contract/` |
| Full suite command | `mix test` |

### RED before / GREEN after — Per Validation Signal

#### Signal A: Drift Test (new file)

**File:** `test/rendro/recipes_facade_drift_test.exs` (or `test/rendro/recipes_test.exs` — per executor discretion)

| Assertion | RED (before facade expansion) | GREEN (after facade expansion) |
|-----------|------------------------------|-------------------------------|
| reachability `function_exported?(Rendro.Recipes, :statement, 1)` | FAIL — function not defined | PASS |
| reachability `function_exported?(Rendro.Recipes, :statement, 2)` | FAIL | PASS |
| no-extra-functions MapSet equality | FAIL — actual set is `{invoice/1, invoice/2, branded_invoice/1, branded_invoice/2}` but expected set has 10 entries | PASS |
| struct byte-identity `Rendro.Recipes.statement(data, opts) == Statement.document(data, opts)` | FAIL — function undefined | PASS |
| auto-discovery orphan sweep | FAIL — Statement/Receipt/Certificate in `:rendro` modules but not in `@recipes` | PASS |

**Expected state at test creation:** ALL assertions RED. Correct — drift test must start RED.

#### Signal B: Facade-Level Opts-Threading Regression Test

**Location:** Same file as drift test, or `test/rendro/recipes/facade_opts_threading_test.exs`

| Assertion | RED (before fix) | GREEN (after fix) |
|-----------|-----------------|-------------------|
| `Rendro.Recipes.invoice(data, sentinel_opt: :val) == Invoice.document(data, sentinel_opt: :val)` | FAIL — `invoice/2` not defined | PASS |
| `Rendro.Recipes.statement(data, labels: %{balance: "Saldo"}) != Rendro.Recipes.statement(data)` | FAIL — `statement/2` not defined | PASS (opts change result) |

**Sentinel opts for each recipe:**
- Invoice/BrandedInvoice: `:formatters` key changes text output (Statement/Receipt already use it; Invoice/BrandedInvoice pass opts but `footer_section` ignores them — use `page_template` level opts like `name:` to verify pass-through, OR simply assert `invoice(data, []) == Invoice.document(data, [])` as pass-through equality)
- Statement: `:labels` — `Rendro.Recipes.Pagination.label_resolver/1` uses it; changes "Balance" column header
- Receipt: `:formatters` — `formatter/3` uses it for amount display
- Certificate: `:border` — changes template geometry (adds `:frame` region)

#### Signal C: `public_api_contract_test.exs` Byte-Compare

**File:** `test/docs_contract/public_api_contract_test.exs` (existing, no changes)

| State | Result |
|-------|--------|
| Before `mix rendro.api.gen` (facade funcs added, `@spec`'d) | FAIL — fresh manifest has 10 Recipes functions; checked-in has 2 |
| After `mix rendro.api.gen` | PASS — byte-identical |

Also: Assertion 5 (stable-tier `@spec` coverage) FAILS until all 10 new functions have `@spec`.

**Run command:** `mix test test/docs_contract/public_api_contract_test.exs`

#### Signal D: `mix rendro.api.gen` Diff (Additive-Only)

**Verification step (not automated test):** After running `mix rendro.api.gen`:

```bash
git diff priv/public_api.json
```

Expected: only `+` lines in the `Elixir.Rendro.Recipes.functions` array. No `-` lines. No other module touched. 8 new `+` lines total (`branded_invoice/2`, `certificate/1`, `certificate/2`, `invoice/2`, `receipt/1`, `receipt/2`, `statement/1`, `statement/2`).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | `Rendro.Recipes` exposes all 5 recipes via arity-1+2 wrappers | unit (reflection) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ Wave 0 |
| DX-01 | opts thread through to recipe modules | unit (regression) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ Wave 0 |
| DX-02 | drift test: reachability, no-extra-fns, struct byte-identity, orphan sweep | unit (reflection) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ Wave 0 |
| DX-01+02 | contract byte-compare passes after regen | integration | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ (existing, must pass after regen) |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/recipes/ test/docs_contract/` (targeted)
- **Per wave merge:** `mix test`
- **Phase gate:** `mix test` full suite green + `mix rendro.api.gen` diff is additive-only

### Wave 0 Gaps

- [ ] `test/rendro/recipes_facade_drift_test.exs` — covers DX-01, DX-02 (all 4 drift assertions + opts-threading regression)

*(Alternatively named `test/rendro/recipes_test.exs` at executor discretion)*

---

## Security Domain

This phase adds thin delegation functions and a test. There is no authentication, session management, access control, cryptographic material, or untrusted input handling. ASVS categories V2/V3/V4/V6 are not applicable.

| ASVS Category | Applies | Note |
|---------------|---------|------|
| V5 Input Validation | No | Opts are keyword lists passed to already-validated recipe modules; recipe modules own their own validation |
| V2/V3/V4/V6 | No | No auth, session, crypto, or access control in this phase |

---

## Open Questions

1. **BrandedInvoice struct byte-identity assertion in drift test**
   - What we know: `BrandedInvoice.document/2` calls `Rendro.Document.register_embedded_font/3` and `register_image/3` with `Rendro.Branded.font_path()` / `Rendro.Branded.logo_path()`. The struct equality assertion should still hold (the `%Rendro.Document{}` struct contains the font/image registrations).
   - What's unclear: Whether `register_embedded_font/3` involves any non-deterministic state (e.g., file handle timestamps).
   - Recommendation: Include BrandedInvoice in the struct byte-identity assertion. If it fails due to non-determinism, fall back to asserting `%Rendro.Document{} = Rendro.Recipes.branded_invoice(data)` (type check only). The existing `branded_invoice_test.exs` already calls `BrandedInvoice.document/2` and asserts struct equality (`doc.page_template == :branded_invoice`) — suggesting struct equality is reliable.

2. **File name for the new test: `recipes_facade_drift_test.exs` vs `recipes_test.exs`**
   - What we know: Existing `test/rendro/recipes/` contains per-recipe files. There is no `test/rendro/recipes_test.exs` (facade-level file). CONTEXT.md D-10 leaves this to executor discretion.
   - Recommendation: Use `test/rendro/recipes_facade_drift_test.exs` — more explicit naming, avoids confusion with existing `test/rendro/recipes/` directory contents. Or place at `test/rendro/recipes/facade_drift_test.exs` to keep all recipe tests collocated.

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| `defdelegate` for facade wrappers | Hand-written `@spec`'d arity-1+2 pairs | `defdelegate` cannot satisfy arity-1→arity-2 guarantee; rejected in D-02 |
| Inline PDF bytes comparison | `%Rendro.Document{}` struct equality | PDF bytes are non-deterministic; struct equality is exact |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.Recipes.__info__(:functions)` returns exactly the hand-defined public functions with no macro-injected extras | Architecture Patterns — drift test | Drift test "no-extra-functions" assertion would need to filter out injected functions; low risk given the module has no `use` macro |
| A2 | `BrandedInvoice.document/2` struct equality is deterministic (font/image registration does not add timestamps) | Open Questions | Drift test struct byte-identity assertion for branded_invoice might be flaky; fallback to type-check-only noted |

---

## Sources

### Primary (HIGH confidence)
- `lib/rendro/recipes.ex` — direct file read; current facade state verified
- `lib/rendro/recipes/invoice.ex`, `branded_invoice.ex`, `statement.ex`, `receipt.ex`, `certificate.ex` — direct file reads; `document/2` signatures confirmed
- `lib/rendro/recipes/pagination.ex` — direct file read; confirmed no `document/2`
- `lib/mix/tasks/rendro/api.gen.ex` — direct file read; generator behavior confirmed
- `priv/public_api.json` lines 319–325 — direct file read; current Recipes entries confirmed
- `test/docs_contract/public_api_contract_test.exs` — direct file read; all 5 assertions confirmed
- `test/rendro/public_api_test.exs` — direct file read; reflection idioms confirmed
- `test/rendro/recipes/invoice_opts_threading_test.exs` — direct file read; test pattern confirmed
- `test/rendro/recipes/branded_invoice_opts_threading_test.exs` — direct file read
- All five `test/rendro/recipes/*_test.exs` files — direct reads; fixture builder patterns confirmed
- `.planning/config.json` — direct file read; `nyquist_validation: true` confirmed

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions D-01 through D-13 — prior deep parallel research by discuss-phase; locked; this research validates them against actual code

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; pure Elixir source changes
- Architecture: HIGH — all canonical refs verified against live codebase; no discrepancies except the opts-drop footgun (expected, already documented in CONTEXT.md)
- Pitfalls: HIGH — all pitfalls derived from actual code reading, not training-data inference

**Research date:** 2026-06-13
**Valid until:** Until `lib/rendro/recipes.ex` or recipe module signatures change

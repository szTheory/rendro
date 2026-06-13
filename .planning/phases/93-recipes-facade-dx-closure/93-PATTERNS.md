# Phase 93: Recipes Facade DX Closure - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 4 (2 modified, 1 created, 1 regenerated)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes.ex` | facade / module | request-response (thin delegation) | `lib/rendro/recipes.ex` itself (existing 2-fn shape to extend) | exact — extend in-place |
| `test/rendro/recipes_facade_drift_test.exs` | test (reflection + regression) | CRUD / reflection | `test/docs_contract/public_api_contract_test.exs` + `test/rendro/recipes/invoice_opts_threading_test.exs` | role-match (reflection idioms) + role-match (opts-threading assertions) |
| `priv/public_api.json` | generated contract artifact | transform (generator output) | `priv/public_api.json` current state + `lib/mix/tasks/rendro/api.gen.ex` | exact — mechanical regeneration via `mix rendro.api.gen` |
| `README.md` | documentation | N/A | `README.md` line 135 (the inaccurate line) | exact — one-line prose fix |

---

## Pattern Assignments

### `lib/rendro/recipes.ex` (facade, request-response)

**Analog:** `lib/rendro/recipes.ex` (lines 1–32, current state — extend this file in-place)

**Current file verbatim** (lines 1–32) — the footgun shape to replace:

```elixir
defmodule Rendro.Recipes do
  @moduledoc """
  Canonical PDF recipes for standard document types.

  These recipes provide a starting point for common documents like
  invoices and reports, demonstrating best practices for layout
  and pagination.
  """
  @moduledoc tags: [:stable]

  @doc """
  Builds a standard invoice document using the canonical Tiered Composition recipe.

  Delegates to `Rendro.Recipes.Invoice.document/1` which uses explicit page template
  regions and sections instead of legacy `header:` / `footer:` kwargs.
  """
  @spec invoice(map()) :: Rendro.Document.t()
  def invoice(data) do
    Rendro.Recipes.Invoice.document(data)    # <-- FOOTGUN: drops opts silently
  end

  @doc """
  Builds a branded invoice document using the canonical branded recipe.

  Delegates to `Rendro.Recipes.BrandedInvoice.document/1`, which registers the
  shipped demo brand font and logo before composing the document.
  """
  @spec branded_invoice(map()) :: Rendro.Document.t()
  def branded_invoice(data) do
    Rendro.Recipes.BrandedInvoice.document(data)    # <-- FOOTGUN: drops opts silently
  end
end
```

**Target pattern for all 10 functions** (D-01, D-03, D-04) — copy this arity-1→arity-2 pair shape for each recipe:

```elixir
@doc """
Builds a <recipe> document.

Delegates to `Rendro.Recipes.<Module>.document/2`, threading opts through.
See `Rendro.Recipes.<Module>` for the accepted `## Options`.
"""
@spec invoice(map()) :: Rendro.Document.t()
def invoice(data), do: invoice(data, [])

@doc """
Builds a <recipe> document with options.

Delegates to `Rendro.Recipes.<Module>.document/2`, forwarding `opts` verbatim.
The recipe module is the single authority for accepted option keys.
See `Rendro.Recipes.<Module>` for the `## Options` section.
"""
@spec invoice(map(), keyword()) :: Rendro.Document.t()
def invoice(data, opts), do: Rendro.Recipes.Invoice.document(data, opts)
```

**Key rules for all 10 definitions:**
- Arity-1 wrapper calls the facade's **own** arity-2 wrapper: `invoice(data, [])`, NOT `Rendro.Recipes.Invoice.document(data)`.
- Arity-2 wrapper calls the recipe with explicit opts: `Rendro.Recipes.Invoice.document(data, opts)`, NOT `document(data)`.
- Both arities require a `@spec` (stable-tier requirement, contract test Assertion 5).
- Both arities require a non-`@doc false` docstring (required for `Code.fetch_docs/1` to surface them in the manifest).
- No `opts \\ []` default arg at facade level — arity-1 and arity-2 are separate clauses.

**All five delegation targets confirmed** (verified `document/2` signatures):

| Facade function | Delegates to | Target line |
|-----------------|-------------|-------------|
| `invoice/2` | `Rendro.Recipes.Invoice.document(data, opts)` | `lib/rendro/recipes/invoice.ex:136` |
| `branded_invoice/2` | `Rendro.Recipes.BrandedInvoice.document(data, opts)` | `lib/rendro/recipes/branded_invoice.ex:115` |
| `statement/2` | `Rendro.Recipes.Statement.document(data, opts)` | `lib/rendro/recipes/statement.ex:236` |
| `receipt/2` | `Rendro.Recipes.Receipt.document(data, opts)` | `lib/rendro/recipes/receipt.ex:228` |
| `certificate/2` | `Rendro.Recipes.Certificate.document(data, opts)` | `lib/rendro/recipes/certificate.ex:225` |

---

### `test/rendro/recipes_facade_drift_test.exs` (test: reflection + regression)

**Analogs (two combined):**
1. `test/rendro/recipes/invoice_opts_threading_test.exs` — module header, `use ExUnit.Case, async: true`, `alias`, `defp sample_data`, `describe` + `test` structure, `assert` idiom.
2. `test/docs_contract/public_api_contract_test.exs` — `:application.get_key/2`, `MapSet.new/1`, `MapSet.difference/2`, `Code.fetch_docs/1`, `function_exported?/3` idioms.

**Module header pattern** (from `invoice_opts_threading_test.exs` lines 1–9):

```elixir
defmodule Rendro.Recipes.InvoiceOptsThreadingTest do
  @moduledoc """
  TDD tests for Invoice.sections/2 opts threading (Phase 78 plan 03, D-10/D-11).
  ...
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice
```

Mirror as:

```elixir
defmodule Rendro.RecipesFacadeDriftTest do
  use ExUnit.Case, async: true
```

**Single-source-of-truth table** (D-07) — place as module attribute after `use ExUnit.Case`:

```elixir
@recipes [
  {:invoice, Rendro.Recipes.Invoice},
  {:branded_invoice, Rendro.Recipes.BrandedInvoice},
  {:statement, Rendro.Recipes.Statement},
  {:receipt, Rendro.Recipes.Receipt},
  {:certificate, Rendro.Recipes.Certificate}
]
```

**Assertion 1 — reachability** (`function_exported?/3`, D-08 item 1):

```elixir
test "each recipe is reachable as name/1 and name/2 on Rendro.Recipes" do
  for {name, _module} <- @recipes do
    assert function_exported?(Rendro.Recipes, name, 1),
           "Expected Rendro.Recipes.#{name}/1 to be exported"
    assert function_exported?(Rendro.Recipes, name, 2),
           "Expected Rendro.Recipes.#{name}/2 to be exported"
  end
end
```

**Assertion 2 — no-extra-functions** (`__info__(:functions)` + `MapSet`, D-08 item 2):

```elixir
test "Rendro.Recipes exposes exactly the expected 10 functions" do
  expected =
    for {name, _} <- @recipes, arity <- [1, 2] do
      {name, arity}
    end
    |> MapSet.new()

  actual = MapSet.new(Rendro.Recipes.__info__(:functions))
  assert actual == expected
end
```

**Assertion 3 — struct byte-identity per recipe** (`==` on `%Rendro.Document{}`, D-08 item 3):

```elixir
test "Rendro.Recipes delegates produce struct-identical result to recipe modules" do
  for {name, module} <- @recipes do
    data = fixture_for(name)
    facade_result = apply(Rendro.Recipes, name, [data])
    direct_result = module.document(data)
    assert facade_result == direct_result,
           "Rendro.Recipes.#{name}/1 struct does not match #{inspect(module)}.document/1"
  end
end
```

**Assertion 4 — auto-discovery orphan sweep** (`:application.get_key/2`, D-09):

```elixir
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

  assert recipe_modules_with_document2 == expected_modules,
         """
         Orphan recipe modules found (have document/2 but no facade wrapper):
           #{MapSet.difference(recipe_modules_with_document2, expected_modules) |> Enum.join(", ")}

         Missing from discovered set but listed in @recipes:
           #{MapSet.difference(expected_modules, recipe_modules_with_document2) |> Enum.join(", ")}
         """
end
```

**Facade-level opts-threading regression test** (D-10) — mirrors `invoice_opts_threading_test.exs` assertion style:

```elixir
describe "facade opts-threading regression" do
  test "Rendro.Recipes.statement/2 with opts produces struct-identical result to Statement.document/2" do
    data = fixture_for(:statement)
    opts = [labels: %{balance: "Saldo"}]
    assert Rendro.Recipes.statement(data, opts) == Rendro.Recipes.Statement.document(data, opts)
  end

  test "Rendro.Recipes.statement/2 with sentinel opts changes result vs no-opts" do
    data = fixture_for(:statement)
    opts = [labels: %{balance: "Saldo"}]
    assert Rendro.Recipes.statement(data, opts) != Rendro.Recipes.statement(data)
  end

  test "Rendro.Recipes.certificate/2 with opts produces struct-identical result to Certificate.document/2" do
    data = fixture_for(:certificate)
    opts = [border: true]
    assert Rendro.Recipes.certificate(data, opts) == Rendro.Recipes.Certificate.document(data, opts)
  end

  test "Rendro.Recipes.receipt/2 with empty opts returns same as receipt/1" do
    data = fixture_for(:receipt)
    assert Rendro.Recipes.receipt(data, []) == Rendro.Recipes.receipt(data)
  end
end
```

**Fixture helpers** — inline `defp` helpers in the drift test (fixtures NOT importable from other `*_test.exs` files per Pitfall 5):

```elixir
# Mirror of invoice_test.exs sample_data/0 (lines 13–21)
defp fixture_for(:invoice) do
  %{id: "INV-001", date: ~D[2026-01-01], items: []}
end

# Mirror of branded_invoice_test.exs sample_data/0 (lines 10–19)
defp fixture_for(:branded_invoice) do
  %{
    id: "INV-DRIFT-01",
    date: ~D[2026-01-01],
    items: [],
    brand: %{font_name: :brand_heading, logo_name: :company_logo}
  }
end

# Minimal form of statement_test.exs fixture_data/2 (lines 13–42)
defp fixture_for(:statement) do
  %{
    period: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
    account: %{name: "Drift Test Co"},
    opening_balance: Decimal.new("0.00"),
    lines: []
  }
end

# Minimal form of receipt_test.exs fixture_data/2 (lines 12–37)
defp fixture_for(:receipt) do
  %{
    title: "Receipt",
    date: ~D[2026-01-01],
    customer: %{name: "Drift Test Co"},
    lines: [],
    totals: %{subtotal: Decimal.new("0.00"), total: Decimal.new("0.00")}
  }
end

# Mirror of certificate_test.exs fixture_data/1 (lines 10–19)
defp fixture_for(:certificate) do
  %{
    title: "Certificate of Completion",
    recipient: "Drift Test",
    body: "Completed.",
    date: ~D[2026-01-01],
    seal_line: "Signed"
  }
end
```

**Existing per-recipe sample data shapes** (verified from test files — use these as ground truth):

| Recipe | Source file | Key fields |
|--------|-------------|------------|
| Invoice | `test/rendro/recipes/invoice_opts_threading_test.exs:13–21` | `%{id:, date:, items: [%{name:, qty:, price:}]}` |
| BrandedInvoice | `test/rendro/recipes/branded_invoice_test.exs:10–19` | same as Invoice plus `brand: %{font_name:, logo_name:}` |
| Statement | `test/rendro/recipes/statement_test.exs:13–42` | `%{period: %{from:, to:}, account: %{name:}, opening_balance: Decimal, lines: [%{date:, description:, amount: Decimal}]}` |
| Receipt | `test/rendro/recipes/receipt_test.exs:12–37` | `%{title:, date:, customer: %{name:}, lines: [%{description:, amount: Decimal}], totals: %{subtotal: Decimal, total: Decimal}}` |
| Certificate | `test/rendro/recipes/certificate_test.exs:10–19` | `%{title:, recipient:, body:, date:, seal_line:}` |

**Sentinel opts per recipe** for the opts-threading change-detection assertion:

| Recipe | Sentinel opt | Effect |
|--------|-------------|--------|
| Statement | `labels: %{balance: "Saldo"}` | Changes column header text via `Pagination.label_resolver/1` |
| Certificate | `border: true` | Adds `:frame` region, changes template geometry |
| Receipt | `formatters: %{amount: fn v -> "EUR #{v}" end}` | Changes amount display format |
| Invoice | (no user-visible opts currently consumed) | Use pass-through equality only: `invoice(data, []) == Invoice.document(data, [])` |
| BrandedInvoice | (same as Invoice) | Use pass-through equality only |

---

### `priv/public_api.json` (generated artifact)

**Analog:** `lib/mix/tasks/rendro/api.gen.ex` (the generator) + current `priv/public_api.json` lines 319–325

**Current state** (`priv/public_api.json` lines 319–326):

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

**Target state** (additive — 8 new `+` lines, 0 `-` lines, no other module touched):

```json
"Elixir.Rendro.Recipes": {
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
  ],
  "tier": "stable",
  "types": []
}
```

**Generator behavior** (`lib/mix/tasks/rendro/api.gen.ex` lines 103–127):
- Run `Mix.Task.run("compile")` then `Rendro.PublicApi.recompile_conditional_adapters()` first.
- Filters to modules with BEAM docs on disk via `Code.fetch_docs/1` match.
- Alpha-sorts both module keys and the `functions` / `types` arrays.
- Derives `tier` from `@moduledoc tags: [...]` — `Rendro.Recipes` is already `:stable`.
- Drops functions with `@doc false`; a `@doc` with a real docstring is required.
- `@spec` is required for every stable-tier function (contract test Assertion 5).
- Writes via `File.write!(@manifest_path, json <> "\n")` — the trailing `"\n"` is mandatory for the byte-compare.
- **NEVER hand-edit** `priv/public_api.json` — always regenerate with `mix rendro.api.gen`.

**Verification command after running `mix rendro.api.gen`:**

```bash
git diff priv/public_api.json
```

Expected: exactly 8 `+` lines in `Elixir.Rendro.Recipes.functions`, zero `-` lines, no other module touched.

---

### `README.md` line 135 (documentation, one-line fix)

**Analog:** `README.md` line 135 (the inaccurate line itself)

**Current line 135:**

```
The delegating alias `Rendro.Recipes.invoice/1` calls `Rendro.Recipes.Invoice.document/1` for convenience.
```

**Required replacement** (D-06):

```
`Rendro.Recipes.invoice/1` (and `/2`) delegates to `Rendro.Recipes.Invoice.document/2`, threading opts through.
```

Or a slightly fuller minimal correction:

```
`Rendro.Recipes` delegates to the recipe module's `document/2`, threading opts through. `invoice/1` is equivalent to `invoice(data, [])`.
```

**Constraint:** This is a minimal prose correction only. A full 5-pair README rewrite is optional polish (CONTEXT.md D-06, Claude's Discretion).

---

## Shared Patterns

### `@moduledoc tags: [:stable]` — Tier Inheritance
**Source:** `lib/rendro/recipes.ex` line 9
**Apply to:** `lib/rendro/recipes.ex` (the module already has this; all new functions inherit it automatically)

```elixir
@moduledoc tags: [:stable]
```

No per-function tier annotation needed — the module-level tag applies to all functions surfaced in the manifest.

### `@spec` on Both Arities — Stable-Tier Contract Requirement
**Source:** Contract test Assertion 5, `test/docs_contract/public_api_contract_test.exs` lines 209–241
**Apply to:** All 10 new/modified facade functions in `lib/rendro/recipes.ex`

```elixir
@spec invoice(map()) :: Rendro.Document.t()
def invoice(data), do: invoice(data, [])

@spec invoice(map(), keyword()) :: Rendro.Document.t()
def invoice(data, opts), do: Rendro.Recipes.Invoice.document(data, opts)
```

Both arities need `@spec` because both appear in the manifest. Forgetting either causes `public_api_contract_test.exs` Assertion 5 to fail.

### `use ExUnit.Case, async: true` — Test Module Header
**Source:** `test/rendro/recipes/invoice_opts_threading_test.exs` line 9
**Apply to:** `test/rendro/recipes_facade_drift_test.exs`

```elixir
use ExUnit.Case, async: true
```

Note: The contract test uses `async: false` (lines 3–5) because it touches global compile state. The new drift test does NOT touch compile state — it only reads BEAM-loaded module metadata — so `async: true` is correct.

### `:application.get_key(:rendro, :modules)` — BEAM-Level Module Discovery
**Source:** `test/rendro/public_api_test.exs` line 111
**Apply to:** `test/rendro/recipes_facade_drift_test.exs` (auto-discovery sweep, D-09)

```elixir
{:ok, all_modules} = :application.get_key(:rendro, :modules)
```

This is the authoritative BEAM-level list, not `File.ls/1` on `lib/`. Use it for the orphan-module sweep.

### `MapSet.new/1` + `MapSet.difference/2` — Two-Set Drift Diff
**Source:** `test/docs_contract/public_api_contract_test.exs` lines 51–69
**Apply to:** `test/rendro/recipes_facade_drift_test.exs` (no-extra-functions assertion, D-08 item 2)

```elixir
fresh_keys = Map.keys(fresh_manifest["modules"]) |> MapSet.new()
on_disk_keys = Map.keys(on_disk_manifest["modules"]) |> MapSet.new()
in_code_not_manifested = MapSet.difference(fresh_keys, on_disk_keys) |> Enum.sort()
manifested_not_in_code = MapSet.difference(on_disk_keys, fresh_keys) |> Enum.sort()
```

For the drift test, apply the same `MapSet.difference` pattern to `expected` vs `actual` sets to produce a readable failure message.

### `Code.fetch_docs/1` — BEAM Doc Metadata
**Source:** `test/docs_contract/public_api_contract_test.exs` lines 34, 84–117
**Apply to:** `test/rendro/recipes_facade_drift_test.exs` if checking for hidden modules (Assertion 3 of contract test)

```elixir
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, module_doc, _, _} -> module_doc
  {:error, reason} -> :hidden
end
```

Not strictly required for the drift test (the facade module is already confirmed not hidden), but available if needed.

---

## No Analog Found

None — all four files have strong analogs in the live codebase. The pattern map is complete with exact matches.

---

## Metadata

**Analog search scope:** `lib/rendro/`, `test/rendro/recipes/`, `test/docs_contract/`, `priv/`, `lib/mix/tasks/`
**Files read:** 15
**Pattern extraction date:** 2026-06-13

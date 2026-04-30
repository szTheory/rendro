---
phase: 22-authoring-ergonomics-and-canonical-recipes
reviewed: 2026-04-30T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/rendro/document.ex
  - test/rendro/document_test.exs
  - lib/rendro/recipes/invoice.ex
  - test/rendro/recipes/invoice_test.exs
  - lib/rendro/recipes.ex
  - lib/rendro/adapters/accrue.ex
  - test/rendro/adapters/accrue_test.exs
  - examples/phoenix_example/test/test_helper.exs
  - examples/phoenix_example/test/support/conn_case.ex
  - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
  - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
  - examples/phoenix_example/mix.exs
  - README.md
findings:
  critical: 0
  warning: 5
  info: 8
  total: 13
status: issues
---

# Phase 22: Code Review Report

**Reviewed:** 2026-04-30
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

The phase implements the Tiered Composition pattern for canonical recipes, adds the
`Rendro.Document` pipeline builder API, migrates the Accrue adapter and Phoenix example
controller to the new section-based shape, and ships an integration test for the example
app.

The core builder API and recipe surface are coherent and well-tested at the unit level.
No security issues or correctness blockers were found. However, there are several
**warning-level** quality defects, including an inconsistent currency-formatting bug in
`Rendro.Adapters.Accrue.format_amount/1`, a misleading "optional-gating proof" test that
does not actually exercise its claim, and brittle test assertions that lock onto
struct-`inspect/2` output. Several invoice-recipe pattern matches will surface as
cryptic `FunctionClauseError`s for malformed input where a focused validation error
would be friendlier.

Findings are grouped by severity below.

## Warnings

### WR-01: `Rendro.Adapters.Accrue.format_amount/1` formats integer and Decimal totals inconsistently

**File:** `lib/rendro/adapters/accrue.ex:114-116`
**Issue:** The contract docstring says `total` is "integer or Decimal-like value rendered in
the totals row" (line 28). The formatter prefixes integers with `$` but falls through to
`to_string/1` for non-integer values (e.g., `Decimal`), which yields a value like
`"3500.00"` with **no** `$` prefix. A real Accrue invoice using `Decimal` totals will render
"Total: 3500.00" while integer totals render "Total: $3500" — that is a visible
correctness defect for production output.

```elixir
defp format_amount(nil), do: ""
defp format_amount(value) when is_integer(value), do: "$#{value}"
defp format_amount(value), do: to_string(value)
```

**Fix:** Either (a) prefix `$` in the catch-all clause too, or (b) reject non-integer
non-Decimal values explicitly. Minimal patch:

```elixir
defp format_amount(nil), do: ""
defp format_amount(value) when is_integer(value), do: "$#{value}"
defp format_amount(value), do: "$#{to_string(value)}"
```

If `Decimal` is in scope, prefer an explicit clause for `%Decimal{}` that calls
`Decimal.to_string/1` with a deterministic format.

---

### WR-02: "optional-gating proof" test does not exercise `AdapterReloader.recompile/0`

**File:** `test/rendro/adapters/accrue_test.exs:75-78`
**Issue:** The test name claims "module is loaded after `AdapterReloader.recompile/0`
(`Code.ensure_loaded?` gate evaluated true)" but the body never calls
`AdapterReloader.recompile/0`. It only asserts that `Rendro.Adapters.Accrue` is loaded
and that `recipe/1` is exported in the current process — which proves nothing about the
gating mechanism. A future regression where the gate evaluates against the *wrong*
context would still pass this assertion.

```elixir
test "module is loaded after AdapterReloader.recompile/0 (Code.ensure_loaded? gate evaluated true)" do
  assert Code.ensure_loaded?(Rendro.Adapters.Accrue)
  assert function_exported?(Rendro.Adapters.Accrue, :recipe, 1)
end
```

**Fix:** Either rename the test to reflect what it actually proves (e.g., "module is
loaded when Accrue dep is present"), or invoke `AdapterReloader.recompile/0` (or whatever
mechanism the project uses to simulate the gating cycle) before the assertion. A renamed
version:

```elixir
test "module is loaded when Accrue dep is present (Code.ensure_loaded? gate satisfied)" do
  assert Code.ensure_loaded?(Rendro.Adapters.Accrue)
  assert function_exported?(Rendro.Adapters.Accrue, :recipe, 1)
end
```

---

### WR-03: Brittle assertion locks tests onto struct `inspect/2` output

**File:** `test/rendro/adapters/accrue_test.exs:55`
**Issue:** The assertion

```elixir
assert flat =~ "columns: [share: 1, fixed: 40, fixed: 60, fixed: 60]"
```

depends on the exact `Inspect` representation of `%Rendro.Table{}.columns`. Any change
to the `Inspect` protocol implementation, struct field order, or how columns are stored
internally will break this test even when the table behaviour is unchanged. This pattern
also appears in `invoice_test.exs:58-67` and `:111-114` where the test inspects the
entire document with `limit: :infinity` and pattern-matches strings — fragile and slow.

**Fix:** Reach into the structure directly instead of inspecting it:

```elixir
{:ok, doc} = Adapter.recipe(sample_invoice())
body_section = Enum.find(doc.sections, &(&1.region == :body))
[%Rendro.Block{content: %Rendro.Table{} = table} | _] = body_section.content
assert table.columns == [{:share, 1}, {:fixed, 40}, {:fixed, 60}, {:fixed, 60}]
```

The same shape applies to the `INV-042`/`Widget A` checks in
`test/rendro/recipes/invoice_test.exs` — pull the text out of the section/block tree and
assert on the text content directly.

---

### WR-04: Recipe pattern matches surface cryptic `FunctionClauseError` for malformed input

**File:** `lib/rendro/recipes/invoice.ex:111, 122`
**Issue:** `header_section/1` matches `%{id: id, date: date} = _data` and `body_section/1`
matches `%{items: items} = _data`. The public-facing `document/2` and `sections/2` advertise
a `map()` parameter type; if a caller passes a map missing `:id`, `:date`, or `:items`,
the failure surfaces as a `FunctionClauseError` from a private function with no
indication of the expected contract. This is a poor authoring-ergonomics signal for a
recipe whose entire purpose is being beginner-friendly.

```elixir
defp header_section(%{id: id, date: date} = _data) do
defp body_section(%{items: items} = _data) do
```

**Fix:** Validate the input shape once at the public entry point and raise (or return a
tagged error) with a clear message:

```elixir
@required_keys [:id, :date, :items]

def document(data, opts \\ []) when is_map(data) do
  case Enum.reject(@required_keys, &Map.has_key?(data, &1)) do
    [] -> do_document(data, opts)
    missing -> raise ArgumentError, "Rendro.Recipes.Invoice.document/2 missing keys: #{inspect(missing)}"
  end
end
```

Apply the same idea to `sections/2`. This also prevents callers from constructing a
half-populated section pipeline before failing inside a private builder.

---

### WR-05: PDF controller test source-path discovery is brittle and runs in two layers

**File:** `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs:71-99`
**Issue:** The "controller source invokes Rendro.Recipes.Invoice.document" test computes
the controller path two ways: once by walking `Application.app_dir(:phoenix_example, "priv")`
up three `..` segments, then falling back to `File.cwd!()`. Both branches are sensitive
to *how* the test is invoked (e.g., `mix test` from the example dir vs. from the parent
project, or via a script that changes cwd). A single relocated `_build` layout change in
a future Mix release silently invalidates the primary branch and the test passes via the
fallback — losing the safety net it was meant to provide.

There is also a dead-code smell: the second `if File.exists?(source_path)` branch assigns
a path computed independently of the first branch, so the *primary* derivation is
effectively unused whenever cwd is the example directory.

**Fix:** Drop the source-text scan in favour of a behavioural assertion. The "GET /download"
tests already exercise the controller end-to-end and the structural-assertion test
verifies the recipe's shape. If a source-text guard is required, anchor it at a stable
location:

```elixir
@controller_source Path.join([__DIR__, "..", "..", "..", "lib",
                              "phoenix_example_web", "controllers", "pdf_controller.ex"])
                   |> Path.expand()

test "controller uses canonical recipe (source guard)" do
  source = File.read!(@controller_source)
  assert source =~ "Rendro.Recipes.Invoice.document"
  refute source =~ ~r/Rendro\.flow\(\[/
end
```

`__DIR__` is resolved at compile time and is independent of cwd or the build layout.

## Info

### IN-01: Builder API mutates list with `++ [x]` — quadratic on long pipelines

**File:** `lib/rendro/document.ex:97, 126`
**Issue:** `add_template/2` and `add_section/2` use `doc.page_templates ++ [template]` and
`doc.sections ++ [section]`. For typical invoice documents this is fine (3 sections), but
the pattern is a known O(n²) trap if a caller programmatically appends a long list of
sections. Per project review scope, performance is out-of-scope for v1, recorded as info
only.

**Fix:** Build the list reversed and reverse once at a finalize step, or accept this as
a documented limitation given expected list sizes.

---

### IN-02: `Rendro.Recipes.invoice/1` docstring references `document/1` (recipe arity is `/2`)

**File:** `lib/rendro/recipes.ex:13`, `README.md:99`
**Issue:** The docstring says "Delegates to `Rendro.Recipes.Invoice.document/1`". The
function in question is defined as `document(data, opts \\ [])` — it has both `/1` and
`/2` callable arities, but the canonical signature documented in `invoice.ex` is
`document/2`. The same imprecision appears in README line 99: "calls
`Rendro.Recipes.Invoice.document/1`".

**Fix:** Update both references to `document/2` to match the public API signature
documented in `lib/rendro/recipes/invoice.ex`.

---

### IN-03: `set_template/2` accepts names that no template registers

**File:** `lib/rendro/document.ex:110-112`
**Issue:** `set_template(doc, :foo)` succeeds even when no template named `:foo` has been
added via `add_template/2`. The mismatch only surfaces later in the pipeline. For an
ergonomics-focused builder API this is a missed validation opportunity.

**Fix:** Validate against `doc.page_templates` and raise an `ArgumentError` listing the
known template names if the requested name is not registered. Alternatively document the
deferred-validation behavior explicitly in the docstring.

---

### IN-04: `Rendro.Recipes.Invoice.document/2` never sets metadata

**File:** `lib/rendro/recipes/invoice.ex:93-105`
**Issue:** The recipe builds an invoice document without ever calling `put_metadata/2`,
so the resulting `%Rendro.Document{}` carries `metadata: %Rendro.Metadata{}` (default
title `nil`). For a "batteries-included" invoice the obvious title is the invoice id.
This is an authoring-ergonomics gap rather than a bug.

**Fix:** Set a sensible default title:

```elixir
base_doc =
  Rendro.Document.new()
  |> Rendro.Document.put_metadata(%Rendro.Metadata{title: "Invoice #{data.id}"})
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
```

If the metadata struct exposes more fields (author, subject), allow callers to override
via `opts[:metadata]`.

---

### IN-05: Currency formatting in invoice body uses raw interpolation

**File:** `lib/rendro/recipes/invoice.ex:126`
**Issue:** `"$#{item.price}"` relies on `String.Chars` for `item.price`. For integers it
renders as `"$2500"` (no thousand-separators, no decimal places). For floats (e.g., `2.5`)
it renders as `"$2.5"`. For a canonical recipe this is misleading because real currency
formatting requires explicit precision. This matches the pre-phase legacy behavior, so
recorded as info.

**Fix:** Document the contract (e.g., "price must be integer cents"), add a
`format_price/1` helper, or accept a `:format` option in `opts` that controls precision.

---

### IN-06: Phoenix example duplicates `@demo_invoice` between controller and test

**File:** `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex:5-13`
and `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs:9-16`
**Issue:** The dummy invoice data is hand-copied. A future change to the controller's
demo data won't fail the structural assertion test — the test just asserts on its own
copy. The "matching the controller's hardcoded invoice data" comment acknowledges the
duplication explicitly.

**Fix:** Hoist the demo data into a shared module (e.g., `PhoenixExample.DemoData`) the
controller and the test both reference. Or have the test call the controller's module
attribute via a helper so divergence is impossible.

---

### IN-07: Phoenix example has no `config/test.exs`

**File:** `examples/phoenix_example/config/` (directory)
**Issue:** Only `config/config.exs` exists. The test depends on
`PhoenixExampleWeb.Endpoint` being configured. The test framework will pick up the dev
config, which works for `Phoenix.ConnTest.dispatch/5` (no HTTP listener required), but
a missing `config/test.exs` is a known footgun: any future addition like
`Logger.configure(level: :info)` for tests will require both files. This is a hygiene
gap, not a bug.

**Fix:** Add `examples/phoenix_example/config/test.exs` with:

```elixir
import Config

config :phoenix_example, PhoenixExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

config :logger, level: :warning
```

---

### IN-08: `add_template/2` and `add_section/2` silently allow duplicates

**File:** `lib/rendro/document.ex:96-98, 124-127`
**Issue:** Calling `add_template(doc, %PageTemplate{name: :invoice})` twice yields two
templates with the same `name`. `set_template(:invoice)` then resolves ambiguously
downstream. A friendly builder API would either (a) replace by name or (b) raise on
duplicate. Same concern for `add_section/2` with the same `:name`.

**Fix:** If the desired semantic is upsert-by-name:

```elixir
def add_template(%__MODULE__{} = doc, %Rendro.PageTemplate{name: name} = template) do
  templates = Enum.reject(doc.page_templates, &(&1.name == name))
  %__MODULE__{doc | page_templates: templates ++ [template]}
end
```

Otherwise document the append-only behavior in the docstring so callers know they own
de-duplication.

---

_Reviewed: 2026-04-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

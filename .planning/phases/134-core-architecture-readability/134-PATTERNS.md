# Phase 134: Core Architecture & Readability - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 12 candidate new/modified/deleted files  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/QUALITY.md` | config / governance ledger | event-driven | `.planning/QUALITY.md` `QL-001` | exact |
| `lib/rendro/i18n/analyzer.ex` (delete if accepted) | utility / model | transform | `lib/rendro/text/shaper/simple.ex` | data-flow match |
| `test/rendro/i18n/analyzer_test.exs` (delete with module) | test | transform | `test/rendro/text/shaper_test.exs` | data-flow match |
| `lib/rendro/recipes/palette.ex` (new, only if accepted) | utility / service | transform | `lib/rendro/recipes/pagination.ex` | role-match |
| `test/rendro/recipes/palette_test.exs` (new, Wave 0) | test | transform | `test/rendro/recipes/pagination_test.exs` | exact |
| `lib/rendro/recipes/invoice.ex` | component / recipe | request-response transform | `lib/rendro/recipes/receipt.ex` | exact |
| `lib/rendro/recipes/receipt.ex` | component / recipe | request-response transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/branded_invoice.ex` | component / recipe | request-response transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/payslip.ex` | component / recipe | request-response transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/ticket.ex` | component / recipe | request-response transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/statement.ex` | component / recipe | request-response transform | `lib/rendro/recipes/invoice.ex` | exact |
| `lib/rendro/recipes/certificate.ex` | component / recipe | request-response transform | `lib/rendro/recipes/statement.ex` | exact |

`lib/rendro/recipes/palette.ex`, its test, and the seven recipe migrations are conditional on a Phase 134 ledger finding being accepted after Wave 0 characterization. The analyzer pair is conditional on the same ledger-first evidence gate. No source target is warranted for shaper/error guidance, large-module/xref signals, or phase-number narration unless the ledger records a new line-specific finding.

## Pattern Assignments

### `.planning/QUALITY.md` (governance ledger, event-driven)

**Analog:** `.planning/QUALITY.md` `QL-001`.

**Finding schema** (lines 32-51): preserve permanent opaque IDs and fill every lifecycle field before a repair is scheduled.

```markdown
#### QL-001 — Compile-connected xref topology is a baseline signal, not a repair mandate

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`
- **Signal:** `SIG-ARCH-001`
- **Impact:** low
- **Confidence:** high
- **Compatibility risk:** bounded_internal
- **Evidence quality:** reproducible
- **Priority:** low — five compile-connected edges and zero cycles do not demonstrate a supported-contract or maintenance harm.
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Owner phase:** 132 (classification)
- **Scope:** baseline architecture topology only; no extraction or cleanup is authorized.
- **Verification:** rerun the registered xref statistics and cycles commands against the recorded source boundary.
- **Status:** rejected
- **Trigger:** reopen only if a concrete ownership collision, compatibility break, or measured maintenance cost is demonstrated.
- **Closure:** rejected because topology alone is insufficient evidence for repair; no unrelated green check or count change can alter that decision.
```

**Lifecycle and closure rule** (lines 186-213):

```markdown
`observed -> triaged -> accepted -> in_progress -> verified -> closed`

A repair needs an owner phase, scope boundary, focused verification, relevant full gate,
before/after statement, and resolution reference. A deferral needs an owner, concrete
event trigger, and evidence-refresh rule. A `reject_signal` records insufficient evidence
and its reopening condition.

Closure uses the predeclared focused proof and compatibility evidence. Labels, severity
changes, improved diagnostic counts, or unrelated green tests do not close a finding.
```

Apply this before creating accepted entries for the analyzer or palette drift surface. Record the simple-shaper/error two-tuple producer scan, module-size/xref topology, and phase narration audit as `reject_signal` or trigger-backed deferral when their evidence remains unchanged.

---

### `lib/rendro/i18n/analyzer.ex` and `test/rendro/i18n/analyzer_test.exs` (utility/test, transform; deletion)

**Active-behavior analog:** `lib/rendro/text/shaper/simple.ex`.

**Analyzer ownership being removed** (`lib/rendro/i18n/analyzer.ex`, lines 1-13): the module is hidden and has only a local transform API, so delete its isolated test in the same concern after current reference, xref, manifest, guide, and package checks prove it has no contract consumer.

```elixir
defmodule Rendro.I18n.Analyzer do
  @moduledoc false

  @type diagnostic :: %{type: :unsupported_script, reason: atom()}

  @spec analyze(String.t()) :: list(diagnostic)
  def analyze(text) when is_binary(text) do
    do_analyze(text, %{rtl: false, complex: false})
  end
end
```

**Current authoritative shaping gate** (`lib/rendro/text/shaper/simple.ex`, lines 50-61): retain and characterize this path instead of porting Analyzer diagnostics into another preflight.

```elixir
@spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
        {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
@impl Rendro.Text.Shaper
def shape(font, text, opts \\ []) do
  script = Keyword.get(opts, :script, :latn)

  if MapSet.member?(@requires_shaping, script) do
    {:error, {:shaping_required, script, shaping_hint(font, script, opts)}}
  else
    do_shape(font, text)
  end
end
```

**Isolated test pairing** (`test/rendro/i18n/analyzer_test.exs`, lines 1-13): delete this test, not replace it with unrelated analyzer coverage.

```elixir
defmodule Rendro.I18n.AnalyzerTest do
  use ExUnit.Case, async: true
  alias Rendro.I18n.Analyzer

  describe "analyze/1" do
    test "Ascii and basic Latin returns no diagnostics" do
      assert Analyzer.analyze("Hello, world! 123 @#$") == []
    end
  end
end
```

Use existing focused `test/rendro/text/shaper_test.exs` shaping assertions and the public manifest contracts as the post-removal behavioral/surface proof; do not modify `Rendro.Text.Shaper.Simple` or `Rendro.Error` for the rejected duplication signal.

---

### `lib/rendro/recipes/palette.ex` (new utility, transform)

**Analog:** `lib/rendro/recipes/pagination.ex`.

**Module boundary and public function style** (lines 1-20): hidden internal recipe utility, explicit spec, direct pure entry point, then private mechanics.

```elixir
defmodule Rendro.Recipes.Pagination do
  @moduledoc false

  @spec chunk_rows_into_pages([{any(), number(), any()}], number()) ::
          [{[any()], any()}]
  def chunk_rows_into_pages(rows_with_meta, effective_capacity) do
    do_chunk(rows_with_meta, effective_capacity, [], 0.0, [])
  end
end
```

**Required pure algorithm** (current `lib/rendro/recipes/invoice.ex`, lines 674-693): keep defaults recipe-owned, read only `:theme` and `:palette`, and preserve `Map.merge/2` last-wins precedence. Do not add shape validation, coercion, typography, rendering, or a new layout path.

```elixir
defp palette(opts) do
  base =
    case opts[:theme] do
      nil -> @legacy_palette
      theme -> Rendro.Theme.resolve(theme).colors
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

The new helper should be `@moduledoc false`, expose only `resolve/2` for recipe callers, and retain the exact shown branch/merge behavior. A fully qualified `Rendro.Recipes.Palette.resolve(opts, @legacy_palette)` call matches current recipe usage of fully qualified internal helpers and avoids import churn.

---

### `test/rendro/recipes/palette_test.exs` (new test, transform)

**Analog:** `test/rendro/recipes/pagination_test.exs`.

**Test module and precedence arrangement** (lines 1-25): use an async ExUnit module, alias the one helper under test, group around the policy/precedence function, and assert each layer explicitly.

```elixir
defmodule Rendro.Recipes.PaginationTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Pagination

  describe "label_resolver/2 (D-18)" do
    test "opts[:labels] wins over default_labels" do
      opts = [labels: %{net_pay: "NETTO"}]
      default_labels = %{net_pay: "Net Pay"}

      resolver = Pagination.label_resolver(opts, default_labels)

      assert resolver.(:net_pay) == "NETTO"
    end
  end
end
```

The new palette test must characterize all seven exact default maps, `[]`/nil-theme behavior, supplied-theme colors, and `:palette` last-wins override behavior before the helper is introduced. Then run all existing recipe byte-identity tests and `test/rendro/recipes/themed_render_smoke_test.exs`; do not refresh hashes.

---

### Seven recipe palette call sites (components/recipes, request-response transform)

**Analogs:** the current `palette/1` implementations in `lib/rendro/recipes/invoice.ex` and `lib/rendro/recipes/statement.ex`.

**Five identical default maps** — `invoice.ex` lines 674-693, `receipt.ex` lines 632-651, `branded_invoice.ex` lines 312-331, `payslip.ex` lines 889-908, and `ticket.ex` lines 687-706:

```elixir
defp palette(opts) do
  base =
    case opts[:theme] do
      nil ->
        %{
          ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0},
          on_accent: {0, 0, 0}, background: {255, 255, 255},
          surface: {255, 255, 255}, rule: {0, 0, 0}
        }

      theme -> Rendro.Theme.resolve(theme).colors
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

**Recipe-specific legacy defaults remain at their call sites:**

```elixir
# lib/rendro/recipes/statement.ex, lines 460-477
%{ink: {0, 0, 0}, muted: {0, 0, 0}, background: {255, 255, 255},
  surface: {245, 245, 245}, rule: {0, 0, 0}}

# lib/rendro/recipes/certificate.ex, lines 513-529
%{ink: {0, 0, 0}, muted: {0, 0, 0}, background: {255, 255, 255},
  rule: {34, 34, 34}}
```

For each of these seven files, replace only the duplicated resolution body with the narrow helper call and retain its exact no-theme map. Do not touch typography, option validation, composition, rendering calls, public docs, or public signatures.

## Shared Patterns

### Hidden internal module boundary

**Sources:** `lib/rendro/recipes/pagination.ex` lines 1-20; `lib/rendro/i18n/analyzer.ex` lines 1-13.  
**Apply to:** `Rendro.Recipes.Palette` only if accepted.

```elixir
defmodule Rendro.Recipes.Pagination do
  @moduledoc false

  @spec chunk_rows_into_pages([{any(), number(), any()}], number()) :: [{[any()], any()}]
  def chunk_rows_into_pages(rows_with_meta, effective_capacity) do
    do_chunk(rows_with_meta, effective_capacity, [], 0.0, [])
  end
end
```

Use `@moduledoc false` and an accurate public `@spec`; prove the manifest remains byte-identical rather than changing `priv/public_api.json`.

### Option precedence / error boundary

**Sources:** `lib/rendro/recipes/invoice.ex` lines 674-693; `lib/rendro/recipes/pagination.ex` lines 116-149.  
**Apply to:** palette helper and recipe migrations.

```elixir
base = case opts[:theme] do
  nil -> defaults
  theme -> Rendro.Theme.resolve(theme).colors
end

Map.merge(base, Keyword.get(opts, :palette, %{}))
```

Maintain current errors naturally emitted by `Rendro.Theme.resolve/1` and `Map.merge/2`; adding validation or rescue changes compatibility and is out of scope.

### Deterministic compatibility proof

**Sources:** `test/rendro/public_api/manifest_test.exs` lines 72-104; `test/rendro/recipes/invoice_byte_identity_test.exs` lines 27-45.  
**Apply to:** every accepted product-code repair.

```elixir
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")
assert fresh_json == checked_in

assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
assert sha256 == @toy_golden_sha256
```

Run the public-manifest contracts plus every affected recipe byte-identity test around each accepted source change. No golden or manifest update is authorized.

### Shaping candidate disposition (no code target)

**Sources:** `lib/rendro/text/shaper/simple.ex` lines 50-88; `lib/rendro/error.ex` lines 116-122 and 257-266.  
**Apply to:** ledger audit only.

`Simple.shape/3` produces the current three-tuple and its context-sensitive hint; `Rendro.Error` preserves a tested two-tuple fallback. The Phase 134 plan must record this as `reject_signal` unless an actual two-tuple producer or emitted-guidance inconsistency is found. Do not factor the hint code based on superficial duplication.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | Every concrete conditional target has a close local analogue. The bounded narration/docs audit has no accepted line-specific source target. |

## Metadata

**Analog search scope:** `lib/rendro/recipes`, `lib/rendro/i18n`, `lib/rendro/text`, `lib/rendro/error.ex`, `test/rendro/recipes`, `test/rendro/i18n`, `test/rendro/public_api`, `test/docs_contract`, `.planning/QUALITY.md`  
**Files scanned:** 22 focused implementation, test, and governance files  
**Pattern extraction date:** 2026-08-26

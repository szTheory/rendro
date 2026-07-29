# Phase 117: Edge-case stress matrix - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 9 (4 new, 5 modified)
**Analogs found:** 9 / 9

This is a test/infra-only phase. All analogs are existing test/support files. No `lib/` files are read for pattern purposes beyond consumption (types/specs), and none are modified.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/edge_fixtures.ex` (NEW) | test-support / fixture builder | transform (atom pair -> data map) | `test/support/pdfium_cli.ex` (module shape); `test/rendro/pipeline/measure_test.exs` (fake-font fixture technique) | role-match |
| `test/support/golden.ex` (NEW) | test-support / assertion helper | file-I/O (hash compare/bless) | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` private `assert_or_bless/2`/`bless_refs/2`/`assert_golden_hashes/2` | exact (un-gated sibling) |
| `test/rendro/edge_matrix_test.exs` (NEW) | test / data-driven matrix | batch (comprehension-generated tests) | `test/rendro/table_byte_identity_test.exs` (byte-golden precedent) + `test/rendro/deterministic_test.exs` (two-run determinism discipline) | role-match (compose two analogs) |
| `test/rendro/edge_error_matrix_test.exs` (NEW) | test / typed-error assertions | request-response (error struct match) | `test/rendro/pipeline/measure_test.exs` `describe "HYG-02: shaping_required error propagation"` (fake-font + error-struct assertions) | exact |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` (MODIFY, extend in place) | test / raster snapshot | file-I/O (PNG render + hash compare) | itself (existing `@tag raster_snapshot: true` test + private helpers) | exact |
| `test/docs_contract/branding_claims_test.exs` (MODIFY ~57-73) | test / docs-contract (packaging guard) | file-I/O (tarball untar + string search) | itself, `describe "hex tarball contents"` block, both the include- and exclude-assertion tests | exact |
| `test/docs_contract/rubric_manifest_contract_test.exs` (MODIFY) | test / docs-contract (schema+manifest guard) | request-response (JSV validate + assertions) | itself, existing `test "schema validation..."` and `test "structural enumeration..."` tests | exact |
| `priv/quality/rubric_scores.json` (MODIFY, add top-level key) | config / data manifest | CRUD (static JSON) | itself (existing top-level keys `dimensions`/`gates`/`thresholds`/`scores`) | exact |
| `priv/schemas/rubric_scores.schema.json` (MODIFY, add `$defs` + root `required`) | config / JSON Schema | CRUD (static schema) | itself (existing `$defs.score_entry`, root `required` array, `thresholds` object shape) | exact |

## Pattern Assignments

### `test/support/golden.ex` (test-support, file-I/O)

**Analog:** `test/rendro/adapters/pdfium_raster_snapshot_test.exs` (full file, 96 lines) — this is the direct un-gated sibling per D-04.

**Bless/assert dispatch pattern** (lines 52-65 of the analog):
```elixir
defp assert_or_bless(fixture_name, pngs) do
  if System.get_env("MIX_RASTER_BLESS") == "true" do
    if System.get_env("GITHUB_ACTIONS") != "true" do
      raise """
      MIX_RASTER_BLESS=true must only run in the pinned CI container.
      Raster hashes are not deterministic across platforms.
      """
    end
    bless_refs(fixture_name, pngs)
  else
    assert_golden_hashes(fixture_name, pngs)
  end
end
```
**Deviation for `golden.ex` (D-04):** drop the `GITHUB_ACTIONS` container gate entirely (byte hashes are cross-platform stable — that is the whole point of D-04's "un-gated" framing). Env var is `MIX_GOLDEN_BLESS` instead of `MIX_RASTER_BLESS`. Ref path is `priv/goldens/#{family}/#{dimension}.sha256` (singular file, not `page_N.sha256` per fixture dir) mirroring the `priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256` convention at lines 74/90.

**Compare/hash pattern** (lines 72-81, adapt `Base.encode16(:crypto.hash(:sha256, png), case: :lower)`):
```elixir
defp assert_golden_hashes(fixture_name, pngs) do
  Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
    ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
    expected_hash = File.read!(ref_path) |> String.trim()
    actual_hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)
    assert actual_hash == expected_hash, "..."
  end)
end
```

**Missing-ref hard-flunk (D-04's "never silent auto-create")** — NOT present in the raster analog (raster silently blesses when missing under `MIX_RASTER_BLESS`); this is new behavior. Use `ExUnit.Assertions.flunk/1` with the exact tone from `table_byte_identity_test.exs:48-52`:
```elixir
assert sha256 == @table_golden_sha256,
       "no-cell_align table render drifted from the frozen INV-05 baseline. " <>
         "If this drift is an intentional, human-approved change, " <>
         "recompute @table_golden_sha256 and update it deliberately."
```
Mirror this exact "a hash change is a DEFECT, not a refresh, unless a human re-authorizes it" phrasing verbatim (already given in RESEARCH.md's code example, cross-checked against the doctrine in `table_byte_identity_test.exs` lines 9-11 and 49-51).

**`assert_deterministic!/1` pattern** — mirror `test/rendro/deterministic_test.exs` lines 13-19:
```elixir
property "two deterministic renders of the same document produce identical binaries" do
  check all(doc <- renderable_document_gen(), max_runs: 100) do
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end
end
```
Adapt to a plain (non-property) shared helper returning the pdf bytes:
```elixir
def assert_deterministic!(doc) do
  {:ok, pdf1} = Rendro.render(doc, deterministic: true)
  {:ok, pdf2} = Rendro.render(doc, deterministic: true)
  ExUnit.Assertions.assert(pdf1 == pdf2, "non-determinism leak — refusing to bless")
  pdf1
end
```

**Module shape** (`@moduledoc false`, pure functions, no state) — mirror `test/support/pdfium_cli.ex` lines 1-2:
```elixir
defmodule Rendro.TestSupport.PdfiumCli do
  @moduledoc false
  @spec find_executable() :: String.t() | nil
  def find_executable do
```
Use `@moduledoc false` + `@spec` on every public function, same as this file's `find_executable/0`. **Naming note:** existing test-support modules use BOTH `Rendro.TestSupport.*` (this file, `FontFixture`) and `Rendro.Test.*` (RESEARCH.md's proposed `Rendro.Test.Golden`/`Rendro.Test.EdgeFixtures`, `Rendro.Test.HexBuildCache` used below). Confirm which namespace `Rendro.Test.HexBuildCache` actually uses at implementation time (`test/support/hex_build_cache.ex`) and match it — do not introduce a third namespace.

---

### `test/support/edge_fixtures.ex` (test-support, transform)

**Analog 1 (module shape):** `test/support/pdfium_cli.ex` — same `@moduledoc false`, pure-function, `@spec`-annotated shape (see excerpt above).

**Analog 2 (fake-font fixture technique for the RTL EDGE-02 case):** `test/rendro/pipeline/measure_test.exs:617-672` — clone verbatim, do not vendor a new font:
```elixir
defp arabic_capable_fake_font do
  arabic_widths =
    [32, 1575, 1576, 1581, 1585, 1605, 1576, 1575]
    |> Enum.uniq() |> Map.new(fn cp -> {cp, 500} end)

  %Rendro.PDF.Font{
    source: :built_in, logical_name: :fake_arabic, name: "F_FAKE_ARABIC",
    base_font: "FakeArabic", subtype: :type1, units_per_em: 1000,
    ascent: 800, descent: -200, default_width: 500,
    widths: arabic_widths, cmap: nil, font_bytes: nil
  }
end

defp doc_with_arabic_text do
  fake_font = arabic_capable_fake_font()
  fake_descriptor = %{
    source: :embedded, source_kind: :binary, variant: :regular,
    source_data: %{status: :ok, kind: :binary, bytes: <<>>, byte_size: 0},
    pdf_font: fake_font
  }
  base_registry = Rendro.FontRegistry.new()
  custom_registry = %Rendro.FontRegistry{
    base_registry | fonts: Map.put(base_registry.fonts, :fake_arabic, fake_descriptor),
      default_font: :fake_arabic
  }
  text = %Rendro.Text{content: "شلوم", font: :fake_arabic, size: 12, color: {0, 0, 0}}
  block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
  page = %Rendro.Page{blocks: [block]}
  %Rendro.Document{pages: [page], font_registry: custom_registry, default_font: :fake_arabic, metadata: %Rendro.Metadata{}}
end
```

**Analog 3 (money helper — do NOT hand-roll):** `lib/rendro/format.ex:62-71` (READ-ONLY consumption, `Rendro.Format.money/1` already handles negative-parens and comma grouping — build fixtures with raw `Decimal.new/1` inputs, never reimplement formatting in the fixture builder).

**Analog 4 (public escape-hatch composition for `:odd_even_running_content`):** `test/rendro/pipeline/paginate_test.exs:923-1013` pattern (also demonstrated inline in `test/rendro/deterministic_test.exs:478-524` `running_footer_doc/1`) — use `Rendro.section/1` with `only_on: :odd`/`:even` plus a `%Rendro.RunningContent{fun: fn {pn, _tp} -> ... end}` block, exactly as RESEARCH.md's Fixture Builder Contract section documents.

**Contract to implement** (per RESEARCH.md, confirmed no better in-repo analog exists — this is genuinely new code):
```elixir
@spec build(atom(), atom()) :: map()
def build(family, dimension)

@spec recipe_module(atom()) :: module()
def recipe_module(family)
```
Raise loudly (never return silently) if `{family, dimension}` isn't a real `:applies` cell — no existing analog for this guard; use a plain `raise ArgumentError` with a descriptive message, consistent with the project's "errors-as-product, never silent" DNA reflected throughout `lib/rendro/error.ex`.

---

### `test/rendro/edge_matrix_test.exs` (test, batch/data-driven)

**Analog 1 (byte-golden precedent + failure-message doctrine):** `test/rendro/table_byte_identity_test.exs` full file (55 lines) — in particular the "a hash change is a defect, not a refresh" framing at lines 9-11 and 48-52, and the two-render determinism check at lines 35-40:
```elixir
test "two deterministic renders are byte-identical" do
  doc = golden_doc()
  assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
  assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
  assert pdf1 == pdf2
end
```

**Analog 2 (`@moduletag`/`async: true` + property-test module shape):** `test/rendro/deterministic_test.exs:1-10`:
```elixir
defmodule Rendro.DeterministicTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import Rendro.Test.Generators
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}
  alias Rendro.TestSupport.FontFixture
  @moduletag :deterministic
```
`edge_matrix_test.exs` should use `use ExUnit.Case, async: true` (no `ExUnitProperties` needed — this is enumerated data, not generated) per D-01.

**Data-driven comprehension pattern** — no exact analog exists in the current suite for `for {{k1,k2}, v} <- @matrix do test ... end` at module scope generating named tests; this is genuinely new composition (confirmed via RESEARCH.md's own code example, which is the closest available reference). Follow RESEARCH.md's `Code Examples > @matrix-driven test generation (D-01)` section verbatim:
```elixir
for {{family, dimension}, :applies} <- @matrix do
  test "#{family}/#{dimension} golden byte-identity" do
    data = EdgeFixtures.build(unquote(family), unquote(dimension))
    doc = EdgeFixtures.recipe_module(unquote(family)).document(data)
    pdf = Rendro.Test.Golden.assert_deterministic!(doc)
    Rendro.Test.Golden.assert_or_bless({unquote(family), unquote(dimension)}, pdf)
  end
end
```

---

### `test/rendro/edge_error_matrix_test.exs` (test, request-response typed-error)

**Analog:** `test/rendro/pipeline/measure_test.exs` `describe "HYG-02: shaping_required error propagation"` block (lines 613-696) — exact structural match for D-05/D-06/D-07/D-08's error-assertion idiom:
```elixir
test "shaping_required error from a full render carries render_id and correlation metadata (WR-02)" do
  assert {:error, %Rendro.Error{stage: :measure} = error} =
           Rendro.render(doc_with_arabic_text())

  assert {:shaping_required, :arab, _hint} = error.reason
  assert is_binary(error.render_id)
  assert error.details.document_type == :pdf
  assert is_boolean(error.details.deterministic)
  assert error.why =~ "requires a shaping adapter"
  assert error.why =~ ":arab"
  assert error.next =~ "shaping adapter"
end
```
This is the template for ALL three EDGE-02 cases (overflow, tall-row, RTL path a/b): pattern-match `%Rendro.Error{stage: ..., reason: ...}`, then assert on `next =~ "<substring>"` — never on full prose, never on a raw internal tuple escaping to the caller (per D-07). For the RTL "refuse to silently render LTR" guard (D-06's `refute`), no existing analog asserts a negative outcome across the whole matrix — write it as a standalone `refute match?({:ok, _}, Rendro.render(doc_with_arabic_text()))`-style test, following the same file's assertion idiom.

**Overflow assertion target** (from RESEARCH.md's live-probe, verified this session against `lib/rendro/pipeline/paginate.ex` and `lib/rendro/error.ex:273-275`):
```elixir
{:error, %Rendro.Error{
  stage: :paginate, reason: :content_overflow,
  next: "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content.",
  details: %{block: %{...}, region: :body, ...}
}}
```
Assert `is_map(e.details.block)` per D-05.

---

### `test/rendro/adapters/pdfium_raster_snapshot_test.exs` (MODIFY in place)

**Analog:** itself — clone the existing `@tag raster_snapshot: true` test block (lines 28-36) verbatim per fixture, reusing the SAME private helpers (`assert_or_bless/2`, `assert_golden_hashes/2`, `bless_refs/2`, lines 52-95) already in the file — do not duplicate them into a new module. This satisfies Landmine 1 (CI hardcodes this exact file path in `ci.yml`) by construction, per the locked in-fence decision (NO new raster file):
```elixir
@tag raster_snapshot: true
test "forms support fixture renders to committed golden PNG hash" do
  pdf = File.read!(@fixture_path)
  assert {:ok, pngs} = Pdfium.render(pdf, dpi: 150, pages: "1")
  assert length(pngs) == 1
  assert_or_bless(@fixture_name, pngs)
end
```
For each of the ~6 curated edge raster fixtures, add a sibling `@tag raster_snapshot: true` test following this exact shape, with `@fixture_name`/`@fixture_path` (or an inline equivalent) per fixture, rendering via `Pdfium.render(pdf, dpi: 150, ...)` and calling the SAME `assert_or_bless/2` used by the existing fixture — extending the module's private ref set, not forking new helpers.

---

### `test/docs_contract/branding_claims_test.exs` (MODIFY ~57-73)

**Analog:** itself — `describe "hex tarball contents"` block, specifically the exclude-test at lines 57-72:
```elixir
test "built tarball excludes operator-only priv paths" do
  tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
  {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
  assert output =~ tarball
  assert File.exists?(tarball)

  list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
  {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

  refute contents =~ "priv/viewer_evidence/"
  refute contents =~ "priv/support_matrix.json"
  refute contents =~ "priv/schemas/examples.schema.json"
  refute contents =~ "priv/schemas/rubric_scores.schema.json"
  refute contents =~ "priv/quality/"
end
```
Add two more `refute` lines to this SAME test (per D-12): `refute contents =~ "priv/goldens/"` and `refute contents =~ "priv/raster_refs/"`. For the "positive companion" (D-12's second half — asserting `lib`/`priv/branded` still ship), mirror the include-test at lines 42-55 (`test "built tarball includes branded assets and NOTICE"`), which already asserts `assert contents =~ "priv/branded/fonts/B612-Regular.ttf"` etc. — either extend that test with an `assert contents =~ "lib/rendro"` (or similar) line, or add a small new test following the identical `Rendro.Test.HexBuildCache.get_build_output()` + `tar -tzf` pattern.

**Shared helper used by both:** `Rendro.Test.HexBuildCache.get_build_output/0` — read `test/support/hex_build_cache.ex` at implementation time to confirm its exact module namespace/caching behavior before use.

---

### `test/docs_contract/rubric_manifest_contract_test.exs` (MODIFY)

**Analog:** itself — existing `test "schema validation: checked-in manifest validates against rubric_scores.schema.json"` (lines 41-44) and helper functions (lines 8-19):
```elixir
defp manifest do
  @manifest_path |> File.read!() |> JSON.decode!()
end

defp rubric_schema do
  @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
end

test "schema validation: checked-in manifest validates against rubric_scores.schema.json" do
  assert {:ok, _} = JSV.validate(manifest(), rubric_schema()),
         "#{@manifest_path} failed validation against #{@schema_path}"
end
```
Add new D-15 guard tests in the same `describe`-less flat style (this file has no `describe` blocks — follow that convention), reusing `manifest()`/`rubric_schema()`:
- (i) `assert manifest()["stress_exemption"]["exempt"] == true` + non-empty `reason` string.
- (ii) `assert Enum.all?(manifest()["scores"], &(!Map.get(&1, "stress_exempt", false)))` (or `refute Enum.any?(...)`, matching this file's `Enum.all?`/`Enum.values`/`&(...)` idiom already used at lines 30-36).
- (iii) disjointness: import the `@matrix` fixture-id enumeration from `Rendro.EdgeMatrixTest` (or a shared constant module — see Claude's Discretion in CONTEXT.md re: `fixture_source`) and assert `MapSet.disjoint?(stress_ids, demo_ids)`.
- (iv) teeth guard: `assert MapSet.size(stress_ids) > 0`.

**Manifest/schema shapes to reference exactly:**
- `priv/quality/rubric_scores.json` top-level keys: `schema_version`, `dimensions`, `gates`, `thresholds`, `scores` (currently `[]`) — add sibling key `stress_exemption`.
- `priv/schemas/rubric_scores.schema.json` root `required` array (line 7): `["schema_version", "dimensions", "gates", "thresholds", "scores"]` — append `"stress_exemption"`. Existing `$defs.score_entry` optional field `"stress_exempt": { "type": "boolean" }` already at line 126 (per D-14, leave as-is, now repurposed as the loophole tripwire for guard (ii) above).

---

### `priv/quality/rubric_scores.json` (MODIFY, add top-level key)

**Analog:** itself — sibling top-level object shape, e.g. `"thresholds"` (lines 77-81):
```json
"thresholds": {
  "hierarchy_dimension": "content_hierarchy",
  "hierarchy_min": 5,
  "core_min": 4
},
```
Add, per D-13, a sibling key at the same nesting level:
```json
"stress_exemption": {
  "exempt": true,
  "reason": "<non-empty human-authored rationale>",
  "fixture_source": "test/rendro/edge_matrix_test.exs",
  "gate_scope": "scores"
},
```

---

### `priv/schemas/rubric_scores.schema.json` (MODIFY, add `$defs` + root `required`)

**Analog:** itself — `thresholds` property definition (lines 63-72) as the shape template for the new `stress_exemption` def, and root `required` array (line 7) as the edit target:
```json
"thresholds": {
  "type": "object",
  "required": ["hierarchy_dimension", "hierarchy_min", "core_min"],
  "properties": {
    "hierarchy_dimension": { "const": "content_hierarchy" },
    "hierarchy_min": { "const": 5 },
    "core_min": { "type": "integer", "minimum": 4, "maximum": 5 }
  },
  "additionalProperties": true
},
```
Add, per D-14:
```json
"stress_exemption": {
  "type": "object",
  "required": ["exempt", "reason"],
  "properties": {
    "exempt": { "const": true },
    "reason": { "type": "string", "minLength": 1 },
    "fixture_source": { "type": "string" },
    "gate_scope": { "type": "string" }
  },
  "additionalProperties": true
}
```
placed as a top-level `properties.stress_exemption` (same level as `properties.thresholds`), AND append `"stress_exemption"` to the root `required` array at line 7: `["schema_version", "dimensions", "gates", "thresholds", "scores", "stress_exemption"]`.

## Shared Patterns

### Byte-hash idiom (SHA-256, lowercase hex)
**Source:** `test/rendro/table_byte_identity_test.exs:46` and `pdfium_raster_snapshot_test.exs:76`/`92`
```elixir
:crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
```
**Apply to:** `test/support/golden.ex`, `test/rendro/edge_matrix_test.exs` (indirectly, via the helper). Never hand-roll a different hash/encoding.

### Two-run determinism pre-check before any bless
**Source:** `test/rendro/deterministic_test.exs:13-19`, `table_byte_identity_test.exs:35-40`
```elixir
assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
```
**Apply to:** `test/support/golden.ex`'s `assert_deterministic!/1`, called once per `edge_matrix_test.exs` case before any hash is taken (D-04).

### Env-var-gated bless dispatch
**Source:** `pdfium_raster_snapshot_test.exs:52-65`
```elixir
if System.get_env("MIX_RASTER_BLESS") == "true" do
  ...
else
  assert_golden_hashes(...)
end
```
**Apply to:** `test/support/golden.ex` (rename to `MIX_GOLDEN_BLESS`, drop the `GITHUB_ACTIONS` gate per D-04).

### Typed-error struct match, never prose
**Source:** `test/rendro/pipeline/measure_test.exs:685-696`
```elixir
assert {:error, %Rendro.Error{stage: :measure} = error} = Rendro.render(doc)
assert {:shaping_required, :arab, _hint} = error.reason
assert error.next =~ "shaping adapter"
```
**Apply to:** `test/rendro/edge_error_matrix_test.exs` for all three EDGE-02 assertions (D-05/D-06/D-07).

### `@moduledoc false` + `@spec`-annotated pure test-support modules
**Source:** `test/support/pdfium_cli.ex:1-4`
```elixir
defmodule Rendro.TestSupport.PdfiumCli do
  @moduledoc false
  @spec find_executable() :: String.t() | nil
  def find_executable do
```
**Apply to:** `test/support/edge_fixtures.ex`, `test/support/golden.ex`.

### Tarball untar + string search
**Source:** `test/docs_contract/branding_claims_test.exs:41-72`
```elixir
{output, 0} = Rendro.Test.HexBuildCache.get_build_output()
list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
{contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)
refute contents =~ "priv/goldens/"
```
**Apply to:** the D-12 tarball-exclusion additions in `branding_claims_test.exs`.

## No Analog Found

| File/Section | Role | Data Flow | Reason |
|---|---|---|---|
| `@matrix`/`@dimensions`/`@families` module-attribute table + `for {{f,d}, :applies} <- @matrix do test ... end` comprehension | test | batch | No existing test file in the suite generates named tests from a comprehension over a curated map at compile time. RESEARCH.md's own `Code Examples` section is the best available reference (already reproduced above) — treat it as the primary source instead of a codebase analog. |
| D-02 coverage-honesty meta-test (`all_pairs -- Map.keys(@matrix) == []`) | test | batch | Genuinely new assertion shape; no existing "exhaustiveness ratchet" test exists elsewhere in the suite. Straightforward `Kernel.--/2` + `assert ... == []`, no special pattern risk. |
| `Rendro.Test.EdgeFixtures.build/2`'s per-`{family,dimension}` construction logic (money edges, missing-optional-fields, line-item counts, currency/tax-label opts) | test-support | transform | No single existing fixture builder covers all six recipe families' data contracts in one place; RESEARCH.md's "Fixture Builder Contract" section (read from each recipe's `validate_required_keys!/1`) is the source of truth — this is new integration code, not a pattern-clone. |

## Metadata

**Analog search scope:** `test/`, `test/support/`, `priv/quality/`, `priv/schemas/` (read via targeted `Read` calls, no full-repo `Glob`/`Grep` sweep needed — CONTEXT.md/RESEARCH.md already named every analog file precisely).
**Files scanned:** 9 analog files fully read (`pdfium_raster_snapshot_test.exs`, `branding_claims_test.exs`, `rubric_manifest_contract_test.exs`, `table_byte_identity_test.exs`, `deterministic_test.exs`, `pdfium_cli.ex`, `measure_test.exs` [targeted 600-700], `rubric_scores.json`, `rubric_scores.schema.json`).
**Pattern extraction date:** 2026-07-18

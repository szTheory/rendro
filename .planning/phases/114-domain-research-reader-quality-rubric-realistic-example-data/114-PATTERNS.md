# Phase 114: Domain research, reader-quality rubric & realistic example-data library - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 11 (new/modified)
**Analogs found:** 11 / 11 (all verified to exist and read directly)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/examples.ex` | service (priv-file loader) | file-I/O | `lib/rendro/branded.ex` | exact |
| `priv/schemas/examples.schema.json` | config (JSON Schema) | transform (validation) | `priv/schemas/support_matrix.schema.json` / `public_api.schema.json` | exact |
| `priv/schemas/rubric_scores.schema.json` | config (JSON Schema) | transform (validation) | `priv/schemas/support_matrix.schema.json` | exact |
| `priv/examples/invoice/<biz>/invoice.json` | model (fixture data) | file-I/O (static) | `bench/comparison/fixtures/invoice_data.json` | exact (moved verbatim) |
| `priv/examples/invoice/DOMAIN.md` | config (docs) | — | none (new doc-only convention) | no analog |
| `priv/quality/rubric_scores.json` | model (appendable manifest) | CRUD (append-only) | `bench/results/comparison.json` | role-match |
| `test/rendro/examples_test.exs` | test | file-I/O + transform | `test/rendro/branded_test.exs` (loader) + extension-ban test (new) | role-match |
| `test/docs_contract/examples_schema_contract_test.exs` | test (docs-contract) | transform (schema validation) | `test/rendro/viewer_evidence/validator_test.exs` pattern + tarball assertions from `branding_claims_test.exs` | exact |
| `test/docs_contract/rubric_manifest_contract_test.exs` | test (docs-contract) | transform (structural validation) | `lib/rendro/comparison.ex` `static_contract_errors/1` style + `jsv` validation | role-match |
| `test/docs_contract/domain_md_contract_test.exs` | test (docs-contract) | transform (structural: required headings) | other `*_claims_test.exs` "required substring/section" style checks | role-match |
| `mix.exs` (`package/0` `:files`) | config | — | existing `priv/branded` entry (line 117) | exact |
| `lib/mix/tasks/rendro/api.gen.ex` (`@public_modules`, NO edit — verify absence) | config/generator | — | itself (verify `Rendro.Examples` is never added) | exact (negative-edit) |
| `test/docs_contract/public_api_contract_test.exs` (extend hidden-modules list) | test (docs-contract) | transform | itself, Assertion 3, lines 82-118 | exact |
| `test/docs_contract/branding_claims_test.exs` (extend or sibling exclusion test) | test (docs-contract) | file-I/O (tarball inspect) | itself, lines 57-69 | exact |
| `bench/comparison/run.exs` (`@fixture_path` repoint) | config (dev script) | file-I/O | itself, line 10 / 339 | exact |
| `bench/comparison/fixtures/invoice_rendro.exs` (repoint) | script | file-I/O | itself, line 2 | exact |
| `bench/comparison/fixtures/invoice_typst.typ` (repoint) | script | file-I/O | itself, line 2 (`sys.inputs.at("data-path", ...)`) | exact |

## Pattern Assignments

### `lib/rendro/examples.ex` (service, file-I/O)

**Analog:** `lib/rendro/branded.ex` (verbatim, 15 lines, read in full)

```elixir
defmodule Rendro.Branded do
  @moduledoc false

  @doc """
  Returns the absolute path to the shipped B612 Regular demo font.
  """
  @spec font_path() :: Path.t()
  def font_path, do: Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")

  @doc """
  Returns the absolute path to the shipped branded demo logo.
  """
  @spec logo_path() :: Path.t()
  def logo_path, do: Application.app_dir(:rendro, "priv/branded/images/rendro-logo.png")
end
```

**Core pattern to write** (per RESEARCH.md, synthesized — richer surface than `Branded` since it must read+decode, not just resolve a path):
```elixir
defmodule Rendro.Examples do
  @moduledoc false

  @base_dir "priv/examples"

  @spec load!(String.t()) :: map()
  def load!(relative_path) do
    @base_dir
    |> then(&Application.app_dir(:rendro, &1))
    |> Path.join(relative_path)
    |> File.read!()
    |> JSON.decode!()
  end

  @spec list(String.t()) :: [String.t()]
  def list(domain) do
    @base_dir
    |> then(&Application.app_dir(:rendro, &1))
    |> Path.join(domain)
    |> Path.join("**/*.json")
    |> Path.wildcard()
  end
end
```

**CRITICAL:** Decode with `JSON.decode!/1` (Elixir built-in, ships with Elixir ~> 1.19 per `mix.exs` line `elixir: "~> 1.19"`). Do NOT use `Jason.decode!/1` — `Jason` is not in `mix.exs` `deps/0`; it's only a transitive `:dev`/`:test` dep. `lib/rendro/comparison.ex` uses `Jason` only for *encoding* under `@compile {:no_warn_undefined, {Jason, :encode!, 2}}` (line 3, 529) — that guard pattern is irrelevant here since `Examples` never encodes.

---

### `priv/schemas/examples.schema.json` and `priv/schemas/rubric_scores.schema.json` (config, transform)

**Analog:** `priv/schemas/support_matrix.schema.json` (header + structure convention, lines 1-9 read):
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "support_matrix.schema.json",
  "title": "Rendro Support Matrix",
  "description": "Structural contract for priv/support_matrix.json viewer rows and family layout.",
  "type": "object",
  "required": ["forms", "signing", "embedded_files", "links", "protection"],
  "properties": { ... }
}
```
Use identical `"$schema"` draft-2020-12 URI and `$id`/`title`/`description` header shape for both new schemas. Existing sibling schemas confirmed present: `priv/schemas/public_api.schema.json`, `priv/schemas/support_matrix.schema.json`, `priv/schemas/viewer_evidence.schema.json` — all three use this same draft.

**Money-field pitfall (from RESEARCH.md Pitfall 6):** every money field must be `{"type": "string", "pattern": "^-?[0-9]+\\.[0-9]{2}$"}`, never `"type": "number"`.

---

### Validator usage pattern (docs-contract tests), analog: `lib/rendro/public_api/validator.ex` (verbatim, 22 lines, read in full)

```elixir
defmodule Rendro.PublicApi.Validator do
  @moduledoc false

  @schema_path "priv/schemas/public_api.schema.json"

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(manifest) do
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    case JSV.validate(manifest, schema) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, format_jsv_error(err)}
    end
  end

  defp format_jsv_error(err) do
    err
    |> JSV.normalize_error()
    |> inspect(limit: :infinity)
  end
end
```
Apply this exact `File.read! |> JSON.decode! |> JSV.build!()` + `JSV.validate/2` shape inline inside `test/docs_contract/examples_schema_contract_test.exs` and `rubric_manifest_contract_test.exs` (docs-contract tests typically inline the JSV calls rather than going through a dedicated Validator module — confirm by checking if a `Rendro.Examples.Validator` module is warranted, or just inline in the test per RESEARCH.md's Code Examples section, which shows it inlined).

---

### `test/docs_contract/examples_schema_contract_test.exs` (test, docs-contract)

**Analog for schema-validation loop:** RESEARCH.md Code Examples section (synthesized from `Rendro.PublicApi.Validator` + `test/rendro/viewer_evidence/validator_test.exs`):
```elixir
schema =
  "priv/schemas/examples.schema.json"
  |> File.read!()
  |> JSON.decode!()
  |> JSV.build!()

for path <- Path.wildcard("priv/examples/**/*.json") do
  fixture = path |> File.read!() |> JSON.decode!()
  assert {:ok, _} = JSV.validate(fixture, schema), "#{path} failed schema validation"
end
```

**Analog for tarball text-only assertion:** `test/docs_contract/branding_claims_test.exs` lines 41-69 (read in full):
```elixir
describe "hex tarball contents" do
  test "built tarball includes branded assets and NOTICE" do
    tarball = "rendro-#{Mix.Project.config()[:version]}.tar"

    {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
    assert output =~ tarball
    assert File.exists?(tarball)

    list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
    {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

    assert contents =~ "priv/branded/fonts/B612-Regular.ttf"
    assert contents =~ "priv/branded/images/rendro-logo.png"
    assert contents =~ "NOTICE"
  end

  test "built tarball excludes operator-only priv paths" do
    tarball = "rendro-#{Mix.Project.config()[:version]}.tar"

    {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
    assert output =~ tarball
    assert File.exists?(tarball)

    list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
    {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

    refute contents =~ "priv/viewer_evidence/"
    refute contents =~ "priv/support_matrix.json"
  end
end
```
For EXL-05, write the analogous positive+negative pair:
```elixir
example_paths =
  contents
  |> String.split("\n", trim: true)
  |> Enum.filter(&String.starts_with?(&1, "priv/examples/"))

assert example_paths != []

for path <- example_paths do
  assert Path.extname(path) in [".json", ".md", ".svg"],
         "#{path} must be text-only (.json/.md/.svg)"
end
```
Note: `Rendro.Test.HexBuildCache.get_build_output()` is the existing helper both tests use to avoid rebuilding the tarball repeatedly — reuse it, do not re-invoke `mix hex.build` directly.

---

### `test/docs_contract/rubric_manifest_contract_test.exs` (test, docs-contract)

**Analog for "structural not subjective" validation style:** `lib/rendro/comparison.ex`'s `static_contract_errors/1` accumulator pattern (function names confirmed at lines 46-96: `read_manifest!/0`, `static_contract_errors/1`) — mirror the "collect_*_errors" accumulator shape: validate schema via `jsv`, then separately assert threshold arithmetic (hierarchy == 5, core dims >= 4, both gates pass) as plain Elixir predicate checks over the decoded map, not part of the JSON Schema itself.

---

### `mix.exs` `package/0` `:files` allowlist (config)

**Exact current list** (`mix.exs` lines 114-127, read in full):
```elixir
files: ~w(
  lib
  assets/rendro
  priv/branded
  bench/results
  guides
  .formatter.exs
  mix.exs
  README.md
  ADOPTION.md
  LICENSE
  NOTICE
  CHANGELOG.md
)
```
**Edit:** add `priv/examples` as a new entry (recommend right after `priv/branded`, following existing grouping). Do **NOT** add `priv/schemas`, `priv/quality`, or `bench/comparison` — those must stay repo-only (see Pitfall 4 in RESEARCH.md; confirmed today's list has neither `priv/schemas` nor `bench/comparison`, only `bench/results`).

---

### `lib/mix/tasks/rendro/api.gen.ex` `@public_modules` (verify-absence, no edit)

**Exact list location:** lines 44-84+ (partial read, list starts at 44, contains `Rendro`, `Rendro.Artifact`, ... through adapter tier). **Action:** confirm `Rendro.Examples` is never added to this list (it must stay absent — internal-only). This is a negative/verification task, not an edit.

---

### `test/docs_contract/public_api_contract_test.exs` — extend hidden-modules list (Assertion 3)

**Exact current list** (lines 85-91, read in full):
```elixir
hidden_modules = [
  Rendro.PDF.CidFont,
  Rendro.PDF.FontSubsetter,
  Rendro.Text.Bidi,
  Rendro.Format,
  Rendro.Audit
]
```
**Edit:** add `Rendro.Examples` to this list. The surrounding test (lines 82-118, read in full) already does everything needed: `Code.ensure_loaded?/1` guard + `Code.fetch_docs/1` + assert `module_doc == :hidden`. No other change needed to this test file.

---

### Bench harness repoint (EXL-04) — three hardcoded path references

**1. `bench/comparison/run.exs`** — `@fixture_path` module attribute, line 10:
```elixir
@fixture_path "bench/comparison/fixtures/invoice_data.json"
```
also referenced at line 83 (`fixture = @fixture_path |> File.read!() |> JSON.decode!()`) and line 339 (`"fixture" => @fixture_path` — the manifest's documentation string). **Edit:** repoint `@fixture_path` to the new `priv/examples/invoice/<slug>/invoice.json` location (resolved via `Rendro.Examples` loader or a literal path — RESEARCH.md doesn't mandate which; using `Rendro.Examples.load!/1`'s underlying path via `Application.app_dir/2` keeps single-source-of-truth).

**2. `bench/comparison/fixtures/invoice_rendro.exs`** — line 2:
```elixir
data = "bench/comparison/fixtures/invoice_data.json" |> File.read!() |> JSON.decode!()
```
**Edit:** repoint this literal path string to the new location.

**3. `bench/comparison/fixtures/invoice_typst.typ`** — line 2:
```typst
#let data_path = sys.inputs.at("data-path", default: "invoice_data.json")
```
This resolves the `--input data-path=` CLI flag (or defaults to a relative `invoice_data.json`). Typst resolves relative paths against the compiling `.typ` file's own directory — since this file itself is NOT moving, the `default:` fallback string may need updating, but more importantly wherever `run.exs` invokes `typst compile` with `--input data-path=...` (search `run.exs` for the Typst `System.cmd` invocation — RESEARCH.md line ~159 references `"bench/comparison/fixtures/invoice_typst.typ"` as the compiled target) must pass the new absolute/relative path to the moved fixture.

**Verification approach (Pitfall 2):** `mix rendro.comparison.check` does NOT re-read the fixture — it only validates `bench/results/comparison.json`'s already-recorded structure. Proving the de-quarantine is a no-op requires: (a) `git mv` the file verbatim and diff for zero content drift, (b) update all three consumers above, (c) optionally update `bench/results/comparison.json`'s `scenario.fixture` string (line 339's value) for documentation accuracy.

## Shared Patterns

### `@moduledoc false` priv-reading loader
**Source:** `lib/rendro/branded.ex` (full file, 15 lines)
**Apply to:** `lib/rendro/examples.ex`
**Key idiom:** `Application.app_dir(:rendro, "priv/<subpath>")` — never `Path.join(__DIR__, ...)` or `:code.priv_dir/1` directly.

### JSON Schema validation via `jsv`
**Source:** `lib/rendro/public_api/validator.ex` (full file, 22 lines)
**Apply to:** `test/docs_contract/examples_schema_contract_test.exs`, `test/docs_contract/rubric_manifest_contract_test.exs`
```elixir
schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
case JSV.validate(manifest, schema) do
  {:ok, _} -> :ok
  {:error, err} -> {:error, err |> JSV.normalize_error() |> inspect(limit: :infinity)}
end
```

### Tarball inclusion/exclusion assertions
**Source:** `test/docs_contract/branding_claims_test.exs` lines 41-69 (full `describe` block read)
**Apply to:** `test/docs_contract/examples_schema_contract_test.exs` (new inclusion+text-only-extension assertions for `priv/examples/`), and extend/sibling to the existing "excludes operator-only priv paths" test to add `refute contents =~ "priv/schemas/examples.schema.json"` and `refute contents =~ "priv/quality/"`.
```elixir
list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
{contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)
```
Reuse `Rendro.Test.HexBuildCache.get_build_output()` to avoid rebuilding the tarball per test.

### Built-in `JSON` module for all reads (never `Jason` for decoding in `lib/`)
**Source:** `lib/rendro/comparison.ex` (uses `Jason` only for encoding, guarded with `@compile {:no_warn_undefined, {Jason, :encode!, 2}}` at line 3; uses `JSON.decode!` implicitly via `read_manifest!/0` at lines 46-47)
**Apply to:** `lib/rendro/examples.ex` (decode-only, use `JSON.decode!/1`), any test files reading fixtures/schemas.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `priv/examples/invoice/DOMAIN.md` | config (docs) | — | No existing `DOMAIN.md`-style doc convention in repo; this is new domain-research content (RUB-01), not a packaging pattern — author fresh per RESEARCH.md's Assumptions Log A1 |
| `test/docs_contract/domain_md_contract_test.exs` | test | transform (structural headings check) | No existing "required markdown headings present" test to copy verbatim; nearest style is the substring-assertion pattern used throughout `*_claims_test.exs` files (e.g. `assert File.read!(...) =~ "..."`), reusable but not a structural/headings-specific analog |

## Metadata

**Analog search scope:** `lib/rendro/`, `lib/mix/tasks/rendro/`, `priv/schemas/`, `test/docs_contract/`, `bench/comparison/`, `mix.exs`
**Files scanned:** 11 read directly (branded.ex, validator.ex, comparison.ex, api.gen.ex, mix.exs, support_matrix.schema.json, branding_claims_test.exs, public_api_contract_test.exs, run.exs, invoice_rendro.exs, invoice_typst.typ) + directory listings of `priv/schemas/` and `test/docs_contract/`
**Pattern extraction date:** 2026-07-10

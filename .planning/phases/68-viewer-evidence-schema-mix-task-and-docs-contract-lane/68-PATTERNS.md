# Phase 68 Pattern Map: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane

**Mapped:** 2026-05-28  
**Sources:** `68-CONTEXT.md`, `68-RESEARCH.md`, existing codebase analogs  
**Phase boundary:** Infrastructure only — `priv/support_matrix.json` unchanged; validator passes production matrix at phase end.

---

## 1. File role map

### Create

| Path | Role | Closest analog |
|------|------|----------------|
| `priv/schemas/support_matrix.schema.json` | Draft 2020-12 contract for full matrix + `$defs/viewer_row` | `priv/support_matrix.json` (data being constrained) |
| `priv/schemas/viewer_evidence.schema.json` | Frontmatter contract (schema_version 1, D-07–D-09) | `.planning/research/ARCHITECTURE.md` Pattern 2 example shape |
| `priv/viewer_evidence/.gitkeep` | Keep empty evidence directory in git | `priv/support/` (existing `priv/` contract tree) |
| `priv/viewer_evidence/_template.md` | Canonical scaffold with valid frontmatter | Phase verification markdown with YAML fences (`.planning/phases/*-UAT.md`) |
| `lib/rendro/viewer_evidence/matrix.ex` | Walker: decode matrix, enumerate 26 viewer cells, surface-key mapping | No direct analog — new cross-artifact walker |
| `lib/rendro/viewer_evidence/frontmatter.ex` | Split `---` fences, YAML parse, path alignment | No direct analog — new; parse style mirrors UAT frontmatter |
| `lib/rendro/viewer_evidence/lint.ex` | Body lint (D-15), deferral lint (D-16), byte budget (D-14) | `lib/rendro/rules/check_*.ex` (rule-style validation, `@moduledoc false`) |
| `lib/rendro/viewer_evidence/validator.ex` | JSV roots + cross-artifact rules; shared by Mix task + tests | `lib/rendro/pipeline/validate.ex` (orchestrated validation pass) |
| `lib/mix/tasks/rendro/viewer_evidence.ex` | `Mix.Tasks.Rendro.ViewerEvidence` — `list` / `validate` / `missing` | `lib/mix/tasks/rendro.visual_uat.ex` |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Eighth docs-contract lane (cross-family only) | `test/docs_contract/protection_claims_test.exs` (lane registration); `embedded_artifact_claims_test.exs` (cross-surface invariants) |
| `test/rendro/viewer_evidence/validator_test.exs` | Unit tests for tier-B violation fixtures | `test/mix/tasks/verify_test.exs` (lane/status assertions) |
| `test/mix/tasks/viewer_evidence_task_test.exs` | Exit codes, `--json`, subcommand dispatch | `test/mix/tasks/docs_contract_task_test.exs` |
| `test/support/viewer_evidence/fixtures/` | Minimal invalid matrix/evidence snippets | `test/support/docs_contract.ex` + family fixtures pattern |

### Modify

| Path | Role | Closest analog |
|------|------|----------------|
| `mix.exs` | Add `jsv`, `yaml_elixir` (dev/test only) | Existing `{:req, ... only: [:dev, :test], runtime: false}` entries |
| `scripts/verify_docs.exs` | Eighth lane tuple | Existing seven lane tuples |
| `.planning/research/ARCHITECTURE.md` | Reconcile Pattern 1 deferral flow with `explicit_deferral` status (D-05) | Self — Pattern 1 section |

### Explicitly out of scope (do not create/modify)

- `priv/support_matrix.json`, `guides/viewer_evidence.md`, family `*_claims_test.exs`, `.github/workflows/ci.yml`, `mix.exs` `:ci` alias, `Rendro.Support.ViewerEvidence`

---

## 2. Pattern excerpts

### 2.1 Docs-contract lane aggregator (`scripts/verify_docs.exs`)

**Pattern:** Tuple list `{label, ["test", path]}` → `Enum.map` → `System.cmd("mix", args)` → `System.halt(1)` on any failure.

```7:15:scripts/verify_docs.exs
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}
]
```

**Phase 68 addition (new tuple, same shape):**

```elixir
{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}
```

**Lane runner and halt:**

```19:39:scripts/verify_docs.exs
results =
  Enum.map(lanes, fn {label, args} ->
    Mix.shell().info("  - #{label}")

    {output, status} = System.cmd("mix", args, stderr_to_stdout: true)

    if status == 0 do
      Mix.shell().info("    PASS")
    else
      Mix.shell().error(output)
      Mix.shell().error("    FAIL")
    end

    {label, status}
  end)

if Enum.all?(results, fn {_label, status} -> status == 0 end) do
  Mix.shell().info("Docs contract VERIFIED!")
else
  System.halt(1)
end
```

**Analog for lane self-registration test:**

```89:94:test/docs_contract/protection_claims_test.exs
  test "docs verification script includes the protection claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}|
  end
```

**Embedded-artifact variant (assert new lane + prior lanes still present):**

```122:140:test/docs_contract/embedded_artifact_claims_test.exs
  test "the canonical docs verification script includes the embedded artifact claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]}|

    # Existing lanes must remain present.
    assert script =~
             ~s|{"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]}|

    assert script =~
             ~s|{"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]}|

    assert script =~
             ~s|{"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]}|

    assert script =~
             ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|
  end
```

---

### 2.2 Docs-contract entrypoint chain

**Pattern:** `mix docs.contract` delegates to `scripts/verify_docs.exs`; non-zero → `exit({:shutdown, 1})`.

```10:19:lib/mix/tasks/docs.contract.ex
  def run(_args) do
    runner = Application.get_env(:rendro, :docs_contract_command_runner, &System.cmd/3)
    {output, status} = runner.("mix", ["run", "scripts/verify_docs.exs"], stderr_to_stdout: true)
    print_output(output)

    if status == 0 do
      :ok
    else
      exit({:shutdown, 1})
    end
  end
```

**Test seam for injectable runner:**

```6:21:test/mix/tasks/docs_contract_task_test.exs
  test "runs the canonical docs verifier command" do
    runner = fn "mix", ["run", "scripts/verify_docs.exs"], _opts ->
      {"Docs contract VERIFIED!\n", 0}
    end

    Application.put_env(:rendro, :docs_contract_command_runner, runner)

    on_exit(fn ->
      Application.delete_env(:rendro, :docs_contract_command_runner)
    end)

    {messages, result} = capture_shell_messages(fn -> Contract.run([]) end)

    assert result == :ok
    assert Enum.join(messages, "\n") =~ "Docs contract VERIFIED!"
  end
```

Phase 68 eighth lane flows through this chain unchanged — no new CI job.

---

### 2.3 Family claims tests vs cross-family viewer-evidence test

**Pattern (family-narrow):** Read raw JSON string; assert family-specific regex facts; do **not** merge cross-family schema rules here.

```4:38:test/docs_contract/protection_claims_test.exs
  test "support matrix publishes the narrow protection family and promotes only the proven protection viewer" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"protection"|
    assert matrix =~ ~s|"password_to_open": "supported"|
    ...
    assert matrix =~
             ~r/"protection".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    refute matrix =~ ~s|"native_encryption": "supported"|
    refute matrix =~ ~s|"digital_signatures": "supported"|
  end
```

**Pattern (forms nested viewers):**

```21:30:test/docs_contract/forms_claims_test.exs
    assert matrix =~ ~r/"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
    ...
    assert matrix =~
             ~r/"signature_widget_viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
```

**Phase 68 `viewer_evidence_claims_test.exs` must:**
- Call `Rendro.ViewerEvidence.Validator` — never duplicate lint/schema inline
- Cover all 8 viewer maps (26 cells), orphan scan, deferral vocabulary, tier-B fixtures
- **Not** assert family-specific promotion regexes (those stay in family tests)

**Optional self-guard pattern (from forms):**

```76:86:test/docs_contract/forms_claims_test.exs
  test "signature docs-contract lane keeps explicit negative claim guards" do
    source = File.read!(__ENV__.file)

    [wording_test] =
      Regex.run(~r/test "public forms wording stays narrow.*?\n  end/s, source)

    assert wording_test =~ ~s|refute guide =~ "digital signatures are supported"|
    ...
  end
```

---

### 2.4 Dev/test-only deps (`mix.exs`)

**Pattern:** `only: [:dev, :test], runtime: false` — no `application/0` change.

```50:55:mix.exs
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]}
```

**Phase 68 additions:**

```elixir
{:jsv, "~> 0.18", only: [:dev, :test], runtime: false},
{:yaml_elixir, "~> 2.12", only: [:dev, :test], runtime: false}
```

**Note:** Use `yaml_elixir` for frontmatter **decode** — `ymlr` is encode-only (RESEARCH §5).

**JSV usage sketch (from RESEARCH — no existing repo usage):**

```elixir
schema_path = "priv/schemas/support_matrix.schema.json"
schema = schema_path |> File.read!() |> JSON.decode!()
root = JSV.build!(schema, base_uri: "file://" <> Path.absname("priv/schemas/"))

case JSV.validate(matrix_map, root) do
  {:ok, _} -> :ok
  {:error, err} -> {:error, JSV.normalize_error(err)}
end
```

---

### 2.5 Internal validation modules (`lib/rendro/viewer_evidence/*`)

**Pattern:** `@moduledoc false`, no public runtime API — same as pipeline/rules modules.

```1:4:lib/rendro/pipeline/validate.ex
defmodule Rendro.Pipeline.Validate do
  @moduledoc false

  alias Rendro.Document
```

**Orchestration pattern (collect errors, return tagged result):**

```28:35:lib/rendro/pipeline/validate.ex
    case walk(doc, doc, rules) do
      [] ->
        {:ok, doc}

      errors ->
        {:error,
         Rendro.Error.from_stage(:validate, :structural_corruption, %{details: %{errors: errors}})}
    end
```

**Phase 68 module split:**

| Module | Responsibility |
|--------|----------------|
| `Matrix` | `load!/0`, `enumerate_viewer_cells/1`, `surface/2` path mapping table |
| `Frontmatter` | Split `---`, `YamlElixir.read_from_string/1`, path ↔ frontmatter alignment |
| `Lint` | `evidence_body/1`, `deferral_reason/1`, byte budget check |
| `Validator` | JSV tier-A + Elixir tier-B (`promotion_complete?/1`), staleness warnings |

**Frontmatter parse flow (RESEARCH):**

```elixir
["" | yaml_and_body] = String.split(content, "---", parts: 3)
{:ok, frontmatter} = YamlElixir.read_from_string(yaml)
body = yaml_and_body |> List.last()
```

**Surface key mapping (Elixir, not JSON Schema):**

| Matrix path | Evidence `<surface>` segment |
|-------------|------------------------------|
| `forms.viewers.*` | `forms` |
| `forms.signature_widget_viewers.*` | `signature_widget` |
| `signing_preparation.viewers.*` | `signing_preparation` |
| `signing.viewers.*` | `signed_artifact` |
| `signing.long_lived.viewers.*` | `long_lived_signed_artifact` |
| `embedded_files.viewers.*` | `embedded_files` |
| `links.viewers.*` | `links` |
| `protection.viewers.*` | `protection` |

**Current matrix viewer shapes (must remain tier-A valid):**

```28:52:priv/support_matrix.json
    "viewers": {
      "adobe_acrobat_reader": {
        "status": "unverified",
        "proof": [
          "open",
          "default_state_visible",
          "edit_or_toggle",
          "save"
        ]
      },
      "apple_preview": {
        "status": "supported",
        "proof": [
          "open",
          "default_state_visible",
          "edit_or_toggle",
          "save"
        ]
      },
      "chrome_pdfium": {
        "status": "unverified"
      },
```

**Tier A/B split (critical):**
- **Tier A (blocking on production matrix):** JSV structural schema; legacy `supported` without `evidence` allowed
- **Tier B (fixture subtests only in Phase 68):** `supported` requires resolvable `evidence` + `recorded_at` + `viewer_kind`; enforced in Elixir, not JSON Schema `then` until Phase 70

---

### 2.6 JSON Schema `$defs/viewer_row` (new files)

**Pattern:** Draft 2020-12, `additionalProperties: false` on viewer rows, `if/then` for status conditionals.

Core enum and deferral branch (from RESEARCH §6):

```json
"status": { "enum": ["supported", "unverified", "explicit_deferral"] },
"allOf": [
  {
    "if": { "properties": { "status": { "const": "explicit_deferral" } }, "required": ["status"] },
    "then": {
      "required": ["evidence_deferred"],
      "not": { "required": ["evidence", "recorded_at", "viewer_kind"] }
    }
  },
  {
    "if": { "properties": { "status": { "const": "unverified" } }, "required": ["status"] },
    "then": {
      "not": { "anyRequired": ["evidence", "recorded_at", "viewer_kind", "evidence_deferred"] }
    }
  }
]
```

**Do not** add tier-B `required: ["evidence", ...]` on `supported` in Phase 68 schema — flip in Phase 70 when legacy rows promoted.

---

### 2.7 Mix task (`Mix.Tasks.Rendro.ViewerEvidence`)

**Analog:** `Mix.Tasks.Rendro.VisualUat` — rich `@moduledoc`, `Mix.Task.run("app.start")`, `Mix.shell()`, `exit({:shutdown, 1})`.

```1:24:lib/mix/tasks/rendro.visual_uat.ex
defmodule Mix.Tasks.Rendro.VisualUat do
  use Mix.Task
  @compile {:no_warn_undefined, Req}

  @shortdoc "Verify a branded PDF preview by Claude vision and update phase UAT"

  @moduledoc """
  Renders the branded invoice fixture, rasterises page 1 to PNG via `pdftoppm`,
  ...
      mix rendro.visual_uat            # phase 29 (default)
      mix rendro.visual_uat 29
  ...
  """
```

**Exit code pattern:**

```57:67:lib/mix/tasks/rendro.visual_uat.ex
      if verdict.overall_pass do
        :ok
      else
        Mix.shell().error("Visual UAT failed (overall_pass: false). See notes above.")
        exit({:shutdown, 1})
      end
    else
      {:error, msg} ->
        Mix.shell().error(msg)
        exit({:shutdown, 1})
    end
```

**Phase 68 task contract:**

| Subcommand | Exit | stdout |
|------------|------|--------|
| `list` | 0 if matrix parses | Summary + fixed-width table; `--json` → JSON only |
| `missing` | 1 iff any `status == "unverified"` (expect 21 today) | Filtered table / JSON |
| `validate` | 1 on structural violation; 0 with staleness warnings only | Violations + stderr warnings |

**Implementation sketch:**

```elixir
def run(args) do
  {cmd, opts} = parse_argv(args)
  Mix.Task.run("app.start")
  matrix = Matrix.load!()
  cells = Matrix.enumerate_viewer_cells(matrix)

  case cmd do
    :list -> List.run(cells, opts)
    :missing -> Missing.run(cells, opts)
    :validate -> Validator.run_full(matrix, cells, opts)
  end
end
```

**Path note:** CONTEXT specifies `lib/mix/tasks/rendro/viewer_evidence.ex` (subdirectory); existing tasks use dot notation (`rendro.visual_uat.ex`). Both compile to `Mix.Tasks.Rendro.ViewerEvidence`.

**Mix task test analog (exit capture):**

```23:41:test/mix/tasks/docs_contract_task_test.exs
  test "exits non-zero when the canonical docs verifier fails" do
    ...
    {messages, exit_reason} =
      capture_shell_messages(fn ->
        catch_exit(Contract.run([]))
      end)

    assert exit_reason == {:shutdown, 1}
    assert Enum.join(messages, "\n") =~ "docs failed"
  end
```

---

### 2.8 Scaffolding files (`priv/viewer_evidence/`)

**Pattern:** Machine-readable contract in `priv/` — human mirror deferred to Phase 69 (`guides/viewer_evidence.md`).

**Ship in Phase 68:**
- `.gitkeep` — empty directory in git
- `_template.md` — valid schema_version 1 frontmatter + example `behaviors[]`

**Canonical path rule (D-06):** `priv/viewer_evidence/<surface>/<viewer>.md`

**Orphan scan:** Exclude `_template.md` (and `.gitkeep`); every other `.md` must be referenced by exactly one matrix row.

---

### 2.9 Docs-contract test support (`test/support/`)

**Pattern:** Shared test helpers with `@moduledoc false` in `test/support` (compiled in test env).

```1:18:test/support/docs_contract.ex
defmodule Rendro.Test.DocsContract do
  @moduledoc false

  @fence_regex ~r/```(?<lang>[[:alnum:]_-]+)\n(?<code>.*?)```/ms
  @id_regex ~r/^\s*#\s*docs-contract:\s*(?<id>[[:alnum:]_-]+)\s*$/m

  def verified_fences(path) do
    path
    |> File.read!()
    ...
  end
```

**Phase 68 fixtures:** `test/support/viewer_evidence/fixtures/` — minimal matrix/evidence snippets for tier-B negative cases (RECIPE-04, GUARDRAIL-01/04).

---

## 3. Integration points

```
mix ci
  └── mix test  (unchanged — no viewer task in :ci alias)
        └── test/docs_contract/viewer_evidence_claims_test.exs  (via normal test run)

mix docs.contract
  └── scripts/verify_docs.exs
        └── lane 8: mix test test/docs_contract/viewer_evidence_claims_test.exs

mix rendro.viewer_evidence {list|validate|missing} [--json]
  └── Rendro.ViewerEvidence.{Matrix,Validator,Lint,Frontmatter}
        ├── priv/support_matrix.json
        ├── priv/schemas/*.schema.json  (JSV)
        └── priv/viewer_evidence/**/*.md

mix verify (advisory lane)
  └── mix docs.contract  (already wired — eighth lane picked up automatically)
```

| Integration | Phase 68 touch | Must remain stable |
|-------------|----------------|-------------------|
| `scripts/verify_docs.exs` | +1 lane tuple | Existing 7 lanes |
| `mix.exs` deps | +jsv, +yaml_elixir | No runtime deps |
| `priv/support_matrix.json` | **No edits** | Family claims regex tests |
| Family `*_claims_test.exs` | **No edits** | Lane registration assertions |
| `.github/workflows/ci.yml` | **No edits** | Single `test` job |
| `mix.exs` `:ci` alias | **No viewer task** | D-24 |

**Production matrix sanity (unchanged at phase end):**

| Metric | Expected |
|--------|----------|
| Total viewer cells | 26 |
| `supported` (legacy, no `evidence:`) | 5 |
| `unverified` | 21 |
| `explicit_deferral` | 0 |
| `missing` exit code | 1 |

**Verify wiring (docs lane already canonical):**

```82:86:test/mix/tasks/verify_test.exs
  test "default docs lane uses the canonical docs.contract task" do
    source = File.read!("lib/mix/tasks/verify.ex")

    assert source =~ "run_system_step(\"mix\", [\"docs.contract\"])"
    refute source =~ "Mix.Task.run(\"run\", [\"scripts/verify_docs.exs\"])"
  end
```

---

## 4. Anti-patterns to avoid

| Anti-pattern | Why it fails | Correct pattern |
|--------------|--------------|-----------------|
| Require `evidence` on all `supported` rows in JSON Schema Phase 68 | Breaks unchanged production matrix (5 legacy rows) | Tier A/B split: schema allows legacy; tier B in Elixir + fixtures only |
| Use `ymlr` for frontmatter parse | Encode-only library | `yaml_elixir` for decode |
| Duplicate validation in Mix task and docs-contract test | Drift (PITFALLS #2) | Single `Rendro.ViewerEvidence.Validator` |
| Add `Rendro.Support.ViewerEvidence` runtime loader | Violates pure-core / D-25 | Build-time modules + Mix task only |
| Merge viewer-evidence rules into `protection_claims_test.exs` etc. | Cross-family coupling | New cross-family file only |
| Overload `unverified` with `evidence_deferred` | Breaks `missing` semantics (D-01–D-03) | Third status `explicit_deferral` |
| Put `status`, `viewer_kind`, `checks` in evidence frontmatter | Promotion state on matrix only (D-10) | Frontmatter schema forbids those keys |
| Put `viewer_version` on matrix row | Silent invalidation on viewer auto-update (D-11) | `viewer_version` in evidence file only |
| Block CI on staleness (180 days) in Phase 68 | Violates D-17 | Warning in `validate` only; blocking Phase 72 |
| Fail docs-contract on tier-B legacy supported rows | Violates phase boundary | Production pass tier A; tier B in isolated fixtures |
| New GitHub required check / CI job | D-18, GUARDRAIL-02 spirit | Eighth lane inside existing `test` job |
| Add `mix rendro.viewer_evidence` to `:ci` alias | D-24 | Operator tooling; CI runs test file directly |
| Change `priv/support_matrix.json` in Phase 68 | ROADMAP pitfall | Schema accepts current file byte-for-byte semantics |
| Staleness / `--strict` blocking in ExUnit | D-17 | Mix task advisory warnings only |
| Embed secrets in evidence body | GUARDRAIL-04 | Body lint rejects `-----BEGIN`, home paths, `passphrase:` assignments |
| Vague deferral reasons (`TBD`, `< 40` chars) | GUARDRAIL-01 | `Lint.deferral_reason/1` with allowlist phrases |
| Trust `signature_widget_viewers` omission in walker | Wrong `missing` count | Walk all 8 viewer maps including nested (D-23) |
| Use matrix family name as evidence `<surface>` for signing | Wrong canonical paths | `signed_artifact` / `long_lived_signed_artifact` mapping table |
| Create `guides/viewer_evidence.md` in Phase 68 | Deferred to Phase 69 | `@moduledoc` forward link only |

---

## PATTERN MAPPING COMPLETE

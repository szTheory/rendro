# Phase 85: Deterministic Raster Lane - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/adapters/pdfium.ex` | adapter (extend) | file-I/O + request-response | `lib/rendro/adapters/qpdf.ex` (tmp dir + write_private_file pattern); self (find_executable/run_command) | exact |
| `priv/pdfium_pin.json` | config | — | no analog (first pin file) | none |
| `priv/schemas/support_matrix.schema.json` | config (edit) | — | self (line 113-116: viewer_kind enum) | exact — one-line edit |
| `lib/rendro/viewer_evidence/validator.ex` | utility (edit) | — | self (line 15: @viewer_kinds) | exact — one-line edit |
| `priv/support_matrix.json` | config (edit) | — | self (existing top-level sections) | role-match |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | test | file-I/O + event-driven (tag-excluded) | `test/rendro/adapters/pdfium_test.exs` (injectable finder pattern); `test/test_helper.exs` (tag exclusion) | role-match |
| `test/docs_contract/raster_claims_test.exs` | test (docs contract) | request-response | `test/docs_contract/path_claims_test.exs` (matrix JSON assertion style); `test/docs_contract/viewer_evidence_claims_test.exs` (guardrails + verify_docs assertion) | exact |
| `.github/workflows/ci.yml` | config (edit) | — | self (lines 31-48: `example-phoenix` advisory job; lines 64-68: pdfium-cli install step) | exact |
| `priv/guardrails/required_status_checks.json` | config (edit) | — | self (lines 40-54: `advisory_contexts` array) | exact |

---

## Pattern Assignments

### `lib/rendro/adapters/pdfium.ex` (adapter extension, file-I/O)

**Primary analog for tmp-dir + write pattern:** `lib/rendro/adapters/qpdf.ex`
**Primary analog for find_executable / run_command:** `lib/rendro/adapters/pdfium.ex` (existing functions)

**Existing find_executable pattern** (`lib/rendro/adapters/pdfium.ex` lines 55-65):
```elixir
defp find_executable do
  finder =
    Application.get_env(:rendro, :pdfium_cli_executable_finder, &default_finder/1)

  case finder.("pdfium-cli") || finder.("pdfium") do
    nil -> {:error, {:missing_executable, "pdfium-cli"}}
    executable -> {:ok, executable}
  end
end

defp default_finder(name), do: System.find_executable(name)
```

**Existing run_command pattern** (`lib/rendro/adapters/pdfium.ex` lines 82-94):
```elixir
defp run_command(executable, args, opts \\ []) do
  runner = Application.get_env(:rendro, :pdfium_cli_command_runner, &System.cmd/3)
  cmd_opts = Keyword.get(opts, :cmd_opts, stderr_to_stdout: true)

  try do
    case runner.(executable, args, cmd_opts) do
      {output, 0} -> {:ok, output}
      {output, exit_code} -> {:error, {:pdfium_cli_failed, exit_code, output}}
    end
  rescue
    error -> {:error, {:command_failed, error.__struct__}}
  end
end
```

**Existing with-try-after pattern** (`lib/rendro/adapters/qpdf.ex` lines 21-30):
```elixir
def protect(%Rendro.Artifact{} = artifact, opts) when is_map(opts) do
  with {:ok, executable} <- find_executable(),
       {:ok, tmp_dir} <- make_tmp_dir() do
    try do
      protect_with_tmp_dir(executable, tmp_dir, artifact.binary, opts)
    after
      File.rm_rf(tmp_dir)
    end
  end
end
```

**make_tmp_dir pattern** (`lib/rendro/adapters/qpdf.ex` lines 75-89):
```elixir
defp make_tmp_dir do
  path =
    Path.join(
      System.tmp_dir!(),
      "rendro-protect-#{System.unique_integer([:positive, :monotonic])}"
    )

  with :ok <- File.mkdir_p(path),
       :ok <- File.chmod(path, 0o700) do
    {:ok, path}
  else
    {:error, reason} -> {:error, reason}
  end
end
```

**write_private_file pattern (chmod 0o600)** (`lib/rendro/adapters/qpdf.ex` lines 124-132):
```elixir
defp write_private_file(path, contents) do
  File.rm(path)

  with :ok <- File.write(path, contents, [:write, :exclusive, :binary]),
       :ok <- File.chmod(path, 0o600) do
    :ok
  end
end
```

**render/2 function to add** — copy the `with {:ok, executable} <- find_executable(), {:ok, tmp_dir} <- make_tmp_dir()` shell from `qpdf.ex` lines 22-29, adapt tmp dir name to `"rendro-raster-..."`, use `write_private_file/2` for the PDF input, invoke `run_command/2` with `["render", input_path, output_pattern, "--dpi", dpi_str, "--file-type", "png"]`, collect output PNGs with `Path.wildcard/1 |> Enum.sort()`.

---

### `priv/pdfium_pin.json` (new config file)

**No direct analog exists** — first pin file in the project. Shape defined by RESEARCH.md:
```json
{
  "version": "v0.11.0",
  "binary": "pdfium-webassembly-linux-amd64",
  "sha256": "<executor must compute: curl ... | sha256sum for v0.11.0>"
}
```

**Note:** The SHA256 for v0.11.0 webassembly-linux-amd64 is `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` per RESEARCH.md (VERIFIED). The existing CI lane (`viewer-evidence-live-proof`) uses v0.10.3 without a sha256 check (see `ci.yml` lines 66-68). The pin file records the version used by the new raster advisory lane only.

---

### `priv/schemas/support_matrix.schema.json` (one-line enum edit)

**Analog:** self, lines 113-116 (the `viewer_kind` enum inside `$defs.viewer_row.properties.viewer_kind`):
```json
"viewer_kind": {
  "type": "string",
  "enum": ["manual", "pdfium-cli", "pdfjs-dist"]
},
```

**Change:** append `"pdfium-render"` to the enum array:
```json
"viewer_kind": {
  "type": "string",
  "enum": ["manual", "pdfium-cli", "pdfjs-dist", "pdfium-render"]
},
```

**Critical constraint:** `"additionalProperties": false` on `viewer_row` (line 96) means only the listed properties are valid — the enum update unlocks `viewer_kind: "pdfium-render"` for any `viewer_row`, but the raster section in `support_matrix.json` must NOT be placed inside a viewer_map (see Pitfall 4 in RESEARCH.md). The schema's root `"additionalProperties": true` (line 88) allows the new top-level `"raster"` key.

---

### `lib/rendro/viewer_evidence/validator.ex` (one-line constant edit)

**Analog:** self, line 15:
```elixir
@viewer_kinds ~w(manual pdfium-cli pdfjs-dist)
```

**Change:**
```elixir
@viewer_kinds ~w(manual pdfium-cli pdfjs-dist pdfium-render)
```

**Must be in sync with the schema enum.** Both the schema (JSON) and this sigil list are checked independently — the schema gates `validate_matrix_structure/1`, the sigil gates `promotion_complete_row?/1` (line 275). Both must be updated atomically.

---

### `priv/support_matrix.json` (add top-level `"raster"` key)

**Analog:** self — any existing top-level non-viewer section. Look at the `"validators"` key (lines 2-9) as the shape reference for a flat non-viewer-map top-level section with nested objects.

**New section shape** (from RESEARCH.md Pattern 4):
```json
"raster": {
  "renderer": "pdfium-render",
  "capabilities": {
    "pdf_to_png": "supported",
    "dpi_configurable": "supported",
    "page_range": "supported",
    "byte_deterministic_on_pinned_container": "supported"
  },
  "boundaries": {
    "gui_viewer_equivalence": "unsupported",
    "adobe_acrobat_visual_fidelity_claim": "unsupported",
    "apple_preview_visual_fidelity_claim": "unsupported"
  },
  "evidence": {
    "renderer_version": "v0.11.0",
    "viewer_kind": "pdfium-render",
    "platform": "Linux (x86_64) — CI container only",
    "dpi": 150,
    "notes": "pdfium-render evidence records what the pdfium engine renders. It does not claim GUI-viewer visual fidelity for Adobe Acrobat, Apple Preview, or Chrome PDF viewer."
  }
}
```

**Critical constraint:** Add this as a NEW top-level key, NOT under `forms.viewers`, `signing.viewers`, or any other viewer map. The root schema has `"additionalProperties": true` (line 88 of schema) which allows this. Placing it inside a viewer_map would trigger `promote_complete` validation failures (Pitfall 4 in RESEARCH.md).

---

### `test/rendro/adapters/pdfium_raster_snapshot_test.exs` (new test, tag-excluded)

**Analog 1:** `test/rendro/adapters/pdfium_test.exs` — injectable finder pattern (lines 1-16):
```elixir
defmodule Rendro.Adapters.PdfiumTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Pdfium

  test "returns missing executable when pdfium-cli is absent" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> nil end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert {:error, {:missing_executable, "pdfium-cli"}} =
             Pdfium.info("test/fixtures/forms_support_fixture.pdf")
  end
end
```

**Analog 2:** `test/test_helper.exs` — tag exclusion pattern (line 2):
```elixir
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true])
```

**New tag to add to `test/test_helper.exs`:**
```elixir
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true, raster_snapshot: true])
```

**Key patterns for the new test file:**
- `use ExUnit.Case, async: false` (writes to priv/raster_refs/, cannot be async)
- `@tag raster_snapshot: true` on each live-render test (excluded from default `mix test`)
- unit-mode tests (no tag) for: missing executable error, bless-outside-CI guard, hash-mismatch message — these run in normal `mix test`
- Injectable executable override via `Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)` + `on_exit` cleanup (same as `pdfium_test.exs` lines 7-11)
- Hash comparison: `Base.encode16(:crypto.hash(:sha256, png), case: :lower)`
- Bless guard: `if System.get_env("GITHUB_ACTIONS") != "true", do: raise "..."` when `MIX_RASTER_BLESS=true`
- Ref file paths: `"priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"`

---

### `test/docs_contract/raster_claims_test.exs` (new docs-contract test)

**Primary analog:** `test/docs_contract/path_claims_test.exs` — minimal claims test reading `priv/support_matrix.json` as raw text and asserting key/value presence (lines 1-42):
```elixir
defmodule Rendro.DocsContract.PathClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix has path_primitive section with ..." do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"path_primitive"|
    assert matrix =~ ~r/"transforms_cm"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/
    # ...
  end

  test "docs verification script includes the path claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]}|
  end
end
```

**Secondary analog:** `test/docs_contract/viewer_evidence_claims_test.exs` — `required_contexts` / guardrails assertion pattern. The guardrail file path is `"priv/guardrails/required_status_checks.json"`. Required contexts are checked by reading the JSON and using `assert` / `refute` on the parsed structure.

**Key assertions for the new test:**

1. `support_matrix.json` has a `"raster"` top-level section — `assert matrix =~ ~s|"raster"|`
2. Raster section has boundary declarations — `assert matrix =~ ~s|"gui_viewer_equivalence"|`, `assert matrix =~ ~s|"unsupported"|`
3. `pdfium_pin.json` exists and has required keys — `assert File.exists?("priv/pdfium_pin.json")`, decode and assert `Map.has_key?(pin, "version")`, `Map.has_key?(pin, "sha256")`
4. Advisory lane NOT in `required_contexts` — `refute "raster-advisory" in guardrails["required_contexts"]`
5. Advisory lane IS in `advisory_contexts` — `assert Enum.any?(guardrails["advisory_contexts"], &(&1["name"] == "raster-advisory"))`
6. GUI-viewer rows do not carry `viewer_kind: "pdfium-render"` — `refute matrix =~ ~r/"forms".*?"viewer_kind"\s*:\s*"pdfium-render"/s`
7. `verify_docs.exs` lane registration — `assert script =~ ~s|{"Raster claims lane", ...|`

**Module name convention:** `Rendro.DocsContract.RasterClaimsTest` (matches `Rendro.DocsContract.PathClaimsTest` naming).

---

### `.github/workflows/ci.yml` (add `raster-advisory` job)

**Primary analog:** `example-phoenix` job (lines 31-48) — graph-disconnected advisory job with no `needs:`:
```yaml
example-phoenix:
  runs-on: ubuntu-latest
  # no `needs:` -> graph-disconnected (D-09); no continue-on-error (D-10)
  steps:
    - name: Checkout
      uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

    - name: Setup Beam
      uses: erlef/setup-beam@v1
      with:
        otp-version: '28'
        elixir-version: '1.19.5'

    - name: Run example app tests
      working-directory: examples/phoenix_example
      run: |
        mix deps.get
        mix test
```

**pdfium-cli install step analog:** `viewer-evidence-live-proof` job (lines 64-68) — existing pdfium-cli install (v0.10.3, no sha256 currently):
```yaml
- name: Install pdfium-cli
  run: |
    curl -fsSL -o pdfium-cli "https://github.com/klippa-app/pdfium-cli/releases/download/v0.10.3/pdfium-webassembly-linux-amd64"
    chmod +x pdfium-cli
    sudo mv pdfium-cli /usr/local/bin/pdfium-cli
    pdfium-cli --version
```

**New job shape for `raster-advisory`:** Use `example-phoenix` as structural template (no `needs:`), add `continue-on-error: true` (per RESEARCH.md Pattern 3 rationale), and upgrade the pdfium-cli install step to v0.11.0 with `sha256sum --check`. The new job uses v0.11.0 (different from the existing lane's v0.10.3 — this is intentional; they are separate jobs).

---

### `priv/guardrails/required_status_checks.json` (add to `advisory_contexts`)

**Analog:** self, lines 40-54 — existing `advisory_contexts` array entries:
```json
"advisory_contexts": [
  {
    "name": "viewer-evidence-live-proof",
    "semantic_class": "behavioral_live_proof",
    "ci_job": "viewer-evidence-live-proof",
    "command": "mix test --include live_pdf_tools ...",
    "notes": "Phase 71 structural-proxy evidence regen; not required on main per D-18/D-32."
  },
  {
    "name": "example-phoenix",
    "semantic_class": "example_app",
    "ci_job": "example-phoenix",
    "command": "mix deps.get && mix test",
    "notes": "Phase 76 reference Phoenix app smoke; not required on main per REF-03/D-09."
  }
]
```

**New entry shape:**
```json
{
  "name": "raster-advisory",
  "semantic_class": "raster_snapshot",
  "ci_job": "raster-advisory",
  "command": "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs",
  "notes": "Phase 85 deterministic raster lane; not required on main. Download failure must never block engine merges."
}
```

**Critical constraint:** `"raster-advisory"` must NOT appear in `required_contexts` (lines 7-12). The four required contexts are `["long-lived-live-proof", "release-proof", "signing-live-proof", "test"]` — do not touch them.

---

## Shared Patterns

### Injectable executable finder (all adapter tests)
**Source:** `test/rendro/adapters/pdfium_test.exs` lines 7-15 + `lib/rendro/adapters/pdfium.ex` lines 55-65
**Apply to:** `test/rendro/adapters/pdfium_raster_snapshot_test.exs`
```elixir
Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)
on_exit(fn -> Application.delete_env(:rendro, :pdfium_cli_executable_finder) end)
```

### ExUnit tag exclusion (live/advisory test gating)
**Source:** `test/test_helper.exs` line 2
**Apply to:** `test/test_helper.exs` (edit), `test/rendro/adapters/pdfium_raster_snapshot_test.exs`
```elixir
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true])
# Extended to:
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true, raster_snapshot: true])
```

### `with` + `try/after` + tmp dir cleanup (binary-input adapter ops)
**Source:** `lib/rendro/adapters/qpdf.ex` lines 21-30, 75-89
**Apply to:** `lib/rendro/adapters/pdfium.ex` (render/2 implementation)
- Tmp dir named `"rendro-raster-#{System.unique_integer([:positive, :monotonic])}"`
- `File.chmod(dir, 0o700)` on dir, `File.chmod(file, 0o600)` on input PDF file
- `File.rm_rf(tmp_dir)` in `after` block unconditionally

### docs-contract test: matrix JSON assertion + verify_docs lane registration
**Source:** `test/docs_contract/path_claims_test.exs` lines 5-41
**Apply to:** `test/docs_contract/raster_claims_test.exs`
```elixir
matrix = File.read!("priv/support_matrix.json")
assert matrix =~ ~s|"section_key"|
# ...
test "docs verification script includes the raster claims lane" do
  script = File.read!("scripts/verify_docs.exs")
  assert script =~ ~s|{"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]}|
end
```

### advisory_contexts entry shape (guardrails)
**Source:** `priv/guardrails/required_status_checks.json` lines 41-54
**Apply to:** `priv/guardrails/required_status_checks.json` (edit)
Required fields: `name`, `semantic_class`, `ci_job`, `command`, `notes`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/pdfium_pin.json` | config | — | First binary pin file in the project; no existing `.json` pin files under `priv/` |
| `priv/raster_refs/` (directory + `.gitkeep`) | data store | — | First hash-ref store; no existing `priv/raster_refs/` or similar directory |

---

## Metadata

**Analog search scope:** `lib/rendro/adapters/`, `test/rendro/adapters/`, `test/docs_contract/`, `.github/workflows/`, `priv/guardrails/`, `priv/schemas/`, `priv/support_matrix.json`, `test/test_helper.exs`, `scripts/verify_docs.exs`
**Files scanned:** 12
**Pattern extraction date:** 2026-06-10

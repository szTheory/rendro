# Phase 91: pdf-js-advisory-proof-lane - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 12 likely new/modified files
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/pdfjs_observer/package.json` | config | request-response/tooling | `mix.exs` package/dependency boundary | partial-match |
| `scripts/pdfjs_observer/package-lock.json` | config | request-response/tooling | `priv/pdfium_pin.json` + CI pinned install | partial-match |
| `scripts/pdfjs_observer/observe.mjs` | utility | file-I/O transform | `scripts/signing_viewer_proof_fixtures.exs` | role-match |
| `priv/pdfjs_observations/schema.json` | config | validation | `priv/schemas/viewer_evidence.schema.json` | role-match |
| `priv/pdfjs_observations/*.json` | evidence | file-I/O transform | `priv/raster_refs/forms_support_fixture/page_1.sha256` and `priv/support_matrix.json` raster evidence | role-match |
| `test/docs_contract/pdfjs_advisory_claims_test.exs` | test | validation/request-response | `test/docs_contract/raster_claims_test.exs` | exact |
| `test/docs_contract/forms_claims_test.exs` | test | validation | existing PDF.js deferral checks in same file | exact |
| `test/docs_contract/signing_claims_test.exs` | test | validation | existing PDF.js deferral checks in same file | exact |
| `scripts/verify_docs.exs` | utility/config | batch | existing lane list in `scripts/verify_docs.exs` | exact |
| `.github/workflows/ci.yml` | config | batch/CI | `raster-advisory`, `comparison-advisory`, `livebook-advisory` jobs | exact |
| `priv/guardrails/required_status_checks.json` | config | validation | existing advisory contexts in same file | exact |
| `test/guardrails/required_checks_contract_test.exs` | test | validation | advisory separation tests in same file | exact |

## Pattern Assignments

### `scripts/pdfjs_observer/observe.mjs` (utility, file-I/O transform)

**Analog:** `scripts/signing_viewer_proof_fixtures.exs`

**Maintainer script boundary and usage pattern** (lines 4-22):

```elixir
@usage """
Usage:
  mix run scripts/signing_viewer_proof_fixtures.exs
  mix run scripts/signing_viewer_proof_fixtures.exs --help

Regenerates all Phase 71 signing-surface viewer proof fixtures:
...
"""
```

**Argument parsing and error exits** (lines 29-49):

```elixir
{opts, args, invalid} =
  OptionParser.parse(argv, strict: [help: :boolean], aliases: [h: :help])

cond do
  invalid != [] ->
    IO.puts(:stderr, "Invalid options")
    print_usage()
    exit({:shutdown, 1})

  args != [] ->
    IO.puts(:stderr, "Unexpected positional arguments: #{Enum.join(args, " ")}")
    print_usage()
    exit({:shutdown, 1})

  opts[:help] ->
    print_usage()

  true ->
    regenerate_all!()
end
```

**Subprocess status handling** (lines 101-110):

```elixir
{output_text, status} =
  System.cmd("mix", ["run", script, "--output", output], stderr_to_stdout: true)

if status != 0 do
  IO.puts(:stderr, output_text)
  exit({:shutdown, status})
end

IO.puts(output_text)
```

**Apply to Phase 91:** keep the observer under `scripts/pdfjs_observer/`, expose `--help`, use explicit non-zero exits on invalid flags or failed observation generation, and print generated/checked observation paths. The script can be Node ESM per research, but should copy the repository's maintainer-only script ergonomics and explicit failure behavior.

### `scripts/pdfjs_observer/package.json` and `package-lock.json` (config, tooling boundary)

**Analog:** `mix.exs`

**Core dependency boundary** (lines 42-60):

```elixir
defp deps do
  [
    {:telemetry, "~> 1.4"},
    {:harfbuzz_ex, "~> 1.2", optional: true},
    {:unicode, "~> 1.22"},
    {:decimal, ">= 2.3.0 and < 4.0.0"},
    {:phoenix, "~> 1.7", optional: true},
    {:plug, "~> 1.14", optional: true},
    {:oban, "~> 2.17", optional: true},
    {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
    ...
  ]
end
```

**Hex package file allowlist** (lines 77-94):

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(
      lib
      assets/rendro
      priv/branded
      bench/results
      guides
      .formatter.exs
      mix.exs
      README.md
      LICENSE
      NOTICE
      CHANGELOG.md
    )
  ]
end
```

**Apply to Phase 91:** do not add `pdfjs-dist`, Node, npm, or canvas dependencies to `mix.exs`; keep npm files inside `scripts/pdfjs_observer/`, which is not in the Hex package allowlist.

### `priv/pdfjs_observations/*.json` and `schema.json` (evidence/config, file-I/O validation)

**Analog A:** `priv/raster_refs/forms_support_fixture/page_1.sha256`

**Compact committed evidence** (line 1):

```text
73e33ed6c6d68e461b4317f0551f9ae8f8225b28cf7e0eebcf88fa45d09b8deb
```

**Analog B:** `priv/support_matrix.json` raster evidence object

**Boundary-rich committed observation metadata** (lines 499-520):

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
    "fixture": "test/fixtures/forms_support_fixture.pdf",
    "ref": "priv/raster_refs/forms_support_fixture/page_1.sha256",
    "png_sha256": "73e33ed6c6d68e461b4317f0551f9ae8f8225b28cf7e0eebcf88fa45d09b8deb",
    "notes": "pdfium-render evidence records what the pdfium engine renders. It does not claim GUI-viewer visual fidelity for Adobe Acrobat, Apple Preview, or Chrome PDF viewer."
  }
}
```

**Apply to Phase 91:** store compact JSON observations under `priv/pdfjs_observations/`; include renderer/tool versions, platform/invocation, fixture path, per-page dimensions, warnings, and errors. Keep observations outside support-matrix promotion rows unless a later phase deliberately adds a narrow support-matrix section.

### `test/docs_contract/pdfjs_advisory_claims_test.exs` (test, validation)

**Analog A:** `test/docs_contract/raster_claims_test.exs`

**Support-boundary and committed evidence tests** (lines 7-14, 91-102):

```elixir
test "support matrix has raster section with boundary declarations" do
  matrix = File.read!("priv/support_matrix.json")

  assert matrix =~ ~s|"raster"|
  assert matrix =~ ~s|"gui_viewer_equivalence"|
  assert matrix =~ ~s|"unsupported"|
  assert matrix =~ ~s|"pdfium-render"|
end
```

```elixir
expected_hash =
  File.read!("priv/raster_refs/forms_support_fixture/page_1.sha256") |> String.trim()

evidence = matrix["raster"]["evidence"]

assert evidence["fixture"] == "test/fixtures/forms_support_fixture.pdf"
assert evidence["ref"] == "priv/raster_refs/forms_support_fixture/page_1.sha256"
assert evidence["png_sha256"] == expected_hash
assert evidence["png_sha256"] =~ ~r/\A[0-9a-f]{64}\z/
```

**Lane registration assertion** (lines 105-110):

```elixir
test "docs verification script includes the raster claims lane" do
  script = File.read!("scripts/verify_docs.exs")

  assert script =~
           ~r/\{"Raster claims lane",\s*\["test",\s*"test\/docs_contract\/raster_claims_test\.exs"\]\}/s
end
```

**Analog B:** `test/docs_contract/comparison_claims_test.exs`

**Banned/qualified phrase scan** (lines 116-134):

```elixir
guide
|> String.split("\n")
|> Enum.with_index(1)
|> Enum.each(fn {line, number} ->
  for phrase <- @comparative_phrases do
    if contains_phrase?(line, phrase) do
      assert line =~ ~r/\[bench:CMP-[A-Z0-9-]+\]/,
             "line #{number} has uncited comparative phrase #{inspect(phrase)}"
    end
  end

  for phrase <- @banned_phrases do
    refute contains_phrase?(line, phrase),
           "line #{number} contains banned comparison phrase #{inspect(phrase)}"
  end
end)
```

**Apply to Phase 91:** make `pdfjs_advisory_claims_test.exs` assert observation files parse, required keys exist, warnings/errors are arrays, page dimensions exist for each page, optional PNG hashes are 64 lowercase hex when present, unqualified "PDF.js support" is absent from public docs, and the lane is registered exactly once in `scripts/verify_docs.exs`.

### Existing PDF.js deferral tests in docs contracts (test, validation)

**Analog:** `test/docs_contract/viewer_evidence_claims_test.exs`

**Explicit deferral row shape** (lines 49-71):

```elixir
rows = [
  get_in(matrix, ["forms", "viewers", "ios_files_preview"]),
  get_in(matrix, ["forms", "viewers", "android_drive_viewer"]),
  get_in(matrix, ["signing", "viewers", "ios_files_preview"]),
  get_in(matrix, ["signing", "viewers", "android_drive_viewer"])
]

assert Enum.all?(rows, &(&1["status"] == "explicit_deferral"))

for row <- rows do
  assert is_binary(row["evidence_deferred"])
  refute Map.has_key?(row, "evidence")
  refute Map.has_key?(row, "recorded_at")
  refute Map.has_key?(row, "viewer_kind")
end
```

**PDF.js support-matrix deferrals already present** (`priv/support_matrix.json` lines 65-68, 118-120, 176-178, 232-234, 275-277):

```json
"pdfjs": {
  "status": "explicit_deferral",
  "evidence_deferred": "PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support."
}
```

**Apply to Phase 91:** add or extend docs-contract tests to assert existing `pdfjs` rows remain `explicit_deferral` for forms/signature/signing/LTV surfaces and do not gain `evidence`, `recorded_at`, or `viewer_kind` from advisory observations.

### `scripts/verify_docs.exs` (utility/config, batch)

**Analog:** existing lane list and runner in same file

**Lane registration pattern** (lines 8-34):

```elixir
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  ...
  {"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]},
  {"Launch artifacts claims lane",
   ["test", "test/docs_contract/launch_artifacts_claims_test.exs"]},
  {"Comparison claims lane", ["test", "test/docs_contract/comparison_claims_test.exs"]},
  ...
]
```

**Batch execution and fail-fast status aggregation** (lines 40-60):

```elixir
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

**Apply to Phase 91:** append one lane, likely `{"PDF.js advisory claims lane", ["test", "test/docs_contract/pdfjs_advisory_claims_test.exs"]}`, and update the guardrail lane-count test from 20 to 21.

### `.github/workflows/ci.yml` (config, CI batch)

**Analog:** advisory jobs

**Raster advisory job** (lines 50-82):

```yaml
raster-advisory:
  runs-on: ubuntu-latest
  continue-on-error: true
  # no 'needs:' -> graph-disconnected; continue-on-error: true -> download failure cannot block engine merges (RAST-02)
  steps:
    - name: Checkout
      uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
    ...
    - name: Run Raster Snapshot Tests
      env:
        MIX_RASTER_BLESS: "false"
      run: mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs
    - name: Check Launch Artifacts
      run: mix rendro.launch_artifacts.check
```

**Other lightweight advisory jobs** (lines 84-122):

```yaml
comparison-advisory:
  runs-on: ubuntu-latest
  continue-on-error: true
  # no 'needs:' -> graph-disconnected; committed benchmark truth only, no external benchmark rerun
  steps:
    - name: Checkout
      uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
    ...
    - name: Check Comparison Evidence
      run: mix rendro.comparison.check
```

```yaml
livebook-advisory:
  runs-on: ubuntu-latest
  continue-on-error: true
  # no 'needs:' -> graph-disconnected; notebook check does not start a Livebook server
  steps:
    ...
    - name: Check Livebook Tutorial
      run: mix rendro.livebook.check
```

**Apply to Phase 91:** add `pdfjs-advisory` with no `needs:`, `continue-on-error: true`, pinned checkout, setup-node, `npm ci` in `scripts/pdfjs_observer`, and `node scripts/pdfjs_observer/observe.mjs --check`. Do not add Node/npm steps to the required `test` job.

### `priv/guardrails/required_status_checks.json` (config, validation)

**Analog:** existing advisory contexts

**Required context boundary** (lines 7-12):

```json
"required_contexts": [
  "long-lived-live-proof",
  "release-proof",
  "signing-live-proof",
  "test"
]
```

**Advisory context pattern** (lines 55-75):

```json
{
  "name": "raster-advisory",
  "semantic_class": "raster_snapshot",
  "ci_job": "raster-advisory",
  "command": "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs && mix rendro.launch_artifacts.check",
  "notes": "Phase 85 deterministic raster snapshots and Phase 86 launch artifact PNG/hash checks; not required on main. Pdfium download or check failures must never block engine merges."
},
{
  "name": "comparison-advisory",
  "semantic_class": "comparison_static_advisory",
  "ci_job": "comparison-advisory",
  "command": "mix rendro.comparison.check",
  "notes": "Phase 87 comparison evidence static check; not required on main and must not rerun external benchmarks."
}
```

**Apply to Phase 91:** add only an `advisory_contexts` entry for `pdfjs-advisory`; do not edit `required_contexts`. Use a semantic class such as `pdfjs_advisory_observation`, command text matching CI, and notes that npm/PDF.js failures are not required-lane failures.

### `test/guardrails/required_checks_contract_test.exs` (test, validation)

**Analog:** required/advisory CI separation tests in same file

**Baseline advisory assertions** (lines 61-79):

```elixir
expected_advisory_contexts = [
  {"comparison-advisory", "comparison_static_advisory", "mix rendro.comparison.check"},
  {"livebook-advisory", "livebook_execution", "mix rendro.livebook.check"}
]

for {name, semantic_class, command} <- expected_advisory_contexts do
  context = advisory_context!(baseline, name)

  assert context["semantic_class"] == semantic_class
  assert context["ci_job"] == name
  assert context["command"] == command
  assert context["notes"] =~ "Phase 87"
  assert context["notes"] =~ "not required"
  refute name in baseline["required_contexts"]
end
```

**Docs lane count contract** (lines 147-164):

```elixir
test "verify_docs.exs registers exactly twenty lanes including launch and GitHub intake lanes" do
  script = File.read!(@verify_docs_path)

  lane_entries =
    Regex.scan(
      ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
      script
    )

  assert length(lane_entries) == 20
  ...
end
```

**Required job forbidden fragments** (lines 186-209):

```elixir
test_block = ci_job_block!(ci, "test")

assert test_block =~ "run: mix ci"

for fragment <- forbidden_required_fragments do
  refute test_block =~ fragment
end
```

**Advisory CI shape** (lines 225-240):

```elixir
for {job, command} <- expected_advisory_jobs do
  block = ci_job_block!(ci, job)

  assert block =~ "continue-on-error: true"
  assert block =~ "run: mix deps.get"
  assert block =~ "run: #{command}"
  refute block =~ ~r/^\s+needs:/m
end
```

**Apply to Phase 91:** add `pdfjs-advisory` to advisory job key assertions, baseline alignment, and non-blocking/no-`needs:` tests. Add `node`, `npm`, `pdfjs`, and `pdfjs-dist` to forbidden required-job fragments. Update docs-contract lane count to 21 after registering the PDF.js lane.

## Shared Patterns

### Advisory Lane Separation

**Source:** `.github/workflows/ci.yml` lines 50-53 and `test/guardrails/required_checks_contract_test.exs` lines 212-222.

Apply to `pdfjs-advisory`: `continue-on-error: true`, no `needs:`, no Node/npm/pdfjs in the required `test` job, and guardrail JSON entry in `advisory_contexts` only.

### Claim Boundary Tests

**Source:** `test/docs_contract/comparison_claims_test.exs` lines 116-134 and `test/docs_contract/viewer_evidence_claims_test.exs` lines 49-71.

Apply to public docs and support matrix: ban unqualified "PDF.js support"; require wording like "pinned PDF.js advisory observations"; assert PDF.js GUI-viewer rows remain `explicit_deferral` without evidence promotion fields.

### Compact Evidence Under `priv/`

**Source:** `priv/raster_refs/forms_support_fixture/page_1.sha256` line 1 and `priv/support_matrix.json` lines 512-520.

Apply to `priv/pdfjs_observations/`: commit compact JSON observations rather than large binary artifacts; keep paths repo-relative and include exact tool versions and boundaries.

### Maintainer-Only Script Ergonomics

**Source:** `scripts/signing_viewer_proof_fixtures.exs` lines 4-22, 29-49, and 101-110.

Apply to `observe.mjs`: include `--help`, explicit check/write modes, predictable stderr on failures, and non-zero exit status when observations cannot be produced or checked.

## Likely Phase 91 File Changes

| File | Rationale |
|---|---|
| `scripts/pdfjs_observer/package.json` | New maintainer-only npm boundary for exact `pdfjs-dist` pin. |
| `scripts/pdfjs_observer/package-lock.json` | New lockfile so CI uses `npm ci` and avoids PDF.js version drift. |
| `scripts/pdfjs_observer/observe.mjs` | New Node observer that records pinned PDF.js metadata, page dimensions, warnings, errors, and optional PNG hash. |
| `priv/pdfjs_observations/schema.json` | New compact schema for committed observation shape. |
| `priv/pdfjs_observations/*.json` | New committed advisory evidence for representative PDF fixtures. |
| `test/docs_contract/pdfjs_advisory_claims_test.exs` | New docs-contract lane for observation schema, wording, and support-boundary assertions. |
| `test/docs_contract/forms_claims_test.exs` | Likely extension to preserve existing PDF.js forms/signature widget deferrals. |
| `test/docs_contract/signing_claims_test.exs` | Likely extension to preserve existing PDF.js signing and long-lived-signing deferrals. |
| `scripts/verify_docs.exs` | Register the new PDF.js advisory docs-contract lane. |
| `.github/workflows/ci.yml` | Add graph-disconnected, non-blocking `pdfjs-advisory` job if CI wiring is included. |
| `priv/guardrails/required_status_checks.json` | Add `pdfjs-advisory` under `advisory_contexts` only. |
| `test/guardrails/required_checks_contract_test.exs` | Assert PDF.js advisory CI is non-required, graph-disconnected, and absent from required job dependencies. |

## Mismatches And Footguns

| Area | Research Recommendation | Existing Codebase Pattern | Footgun / Planner Guidance |
|---|---|---|---|
| Node tooling | Direct Node ESM script with npm lockfile. | Existing scripts are Elixir `.exs` or shell; no npm subtree exists. | Keep Node in `scripts/pdfjs_observer/` and out of `mix.exs`, `mix ci`, and Hex package files. |
| CI action pinning | Research example used `actions/setup-node@v6` with note to pin. | Existing third-party actions are SHA-pinned for checkout/setup-python; `erlef/setup-beam@v1` is not SHA-pinned. | Verify current setup-node version and SHA-pin if following the stricter existing action style used for checkout/setup-python. |
| Evidence location | `priv/pdfjs_observations/` recommended. | Hex package allowlist includes only `priv/branded`, not arbitrary `priv` evidence. | This is okay for repo evidence, but do not assume observations ship in Hex unless `mix.exs` package files are intentionally changed. |
| Support matrix | Research recommends observations outside support matrix. | Raster evidence currently has a `support_matrix.json` top-level `raster` section. | Do not copy raster's support-matrix section unless planning explicitly handles claim vocabulary; PDF.js already has trust-sensitive `explicit_deferral` rows. |
| PNG hash | Optional first-page PNG hash. | Raster hash has CI-only bless guard because hashes are platform-sensitive. | If PNG hash is included, add a CI-pinned determinism guard; metadata-only observations are safer for first pass. |
| Docs lane count | Add one lane. | Guardrail test asserts exactly 20 lanes. | Update both `scripts/verify_docs.exs` and `test/guardrails/required_checks_contract_test.exs` together. |
| Required/advisory wording | "PDF.js advisory observations". | Existing support-matrix rows use `pdfjs` under GUI-viewer surfaces. | Avoid phrase "PDF.js support"; assert advisory observations do not promote `pdfjs` viewer rows. |

## No Analog Found

None. The Node/npm implementation language is new, but every repository boundary it touches has a local analog: maintainer scripts under `scripts/`, compact proof evidence under `priv/`, docs-contract claim policing, and advisory CI guardrails.

## Metadata

**Analog search scope:** `scripts/`, `priv/`, `test/docs_contract/`, `test/guardrails/`, `.github/workflows/`, `mix.exs`
**Files scanned:** 52 candidate files via `rg --files`/`find`; 13 files read for concrete excerpts
**Pattern extraction date:** 2026-06-13

---
phase: 52
slug: qpdf-adapter-and-structural-validation
status: ready
created: 2026-05-06
updated: 2026-05-06
---

# Phase 52: qpdf Adapter and Structural Validation - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 11
**Analogs found:** 10 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/adapters/qpdf.ex` | adapter | file-I/O | `lib/rendro/adapters/qpdf.ex` | exact |
| `lib/rendro/adapters/poppler.ex` | adapter | request-response | `lib/rendro/adapters/poppler.ex` | exact |
| `lib/rendro/protect.ex` | service | transform | `lib/rendro/protect.ex` | exact |
| `lib/rendro/error.ex` | model | transform | `lib/rendro/error.ex` | exact |
| `test/rendro/adapters/qpdf_test.exs` | test | file-I/O | `test/rendro/adapters/qpdf_test.exs` | exact |
| `test/rendro/adapters/poppler_test.exs` | test | request-response | `test/rendro/adapters/poppler_test.exs` | exact |
| `test/rendro/protect_test.exs` | test | transform | `test/rendro/protect_test.exs` | exact |
| `test/docs_contract/protection_claims_test.exs` | test | transform | `test/docs_contract/protection_claims_test.exs` | exact |
| `guides/api_stability.md` | docs | transform | `guides/api_stability.md` | exact |
| `priv/support_matrix.json` | config | static | `priv/support_matrix.json` | exact |
| `test/rendro/adapters/qpdf_live_test.exs` or equivalent live proof file | test | file-I/O | none in repo | no-analog |

## Pattern Assignments

### `lib/rendro/adapters/qpdf.ex` (adapter, file-I/O)

**Analog:** `lib/rendro/adapters/qpdf.ex`

**Optional executable seam** ([lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:23)):
```elixir
defp find_executable do
  finder = Application.get_env(:rendro, :qpdf_executable_finder, &System.find_executable/1)

  case finder.("qpdf") do
    nil -> {:error, {:missing_executable, "qpdf"}}
    executable -> {:ok, executable}
  end
end
```

**Injected command runner + typed crash shaping** ([lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:32)):
```elixir
defp run_command(executable, args) do
  runner = Application.get_env(:rendro, :qpdf_command_runner, &System.cmd/3)

  try do
    runner.(executable, args, stderr_to_stdout: true)
  rescue
    error -> {:error, {:command_failed, error.__struct__}}
  end
end
```

**Hermetic temp-dir + argfile boundary** ([lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:12), [lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:63), [lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:88)):
```elixir
with {:ok, executable} <- find_executable(),
     {:ok, tmp_dir} <- make_tmp_dir() do
  try do
    protect_with_tmp_dir(executable, tmp_dir, artifact.binary, opts)
  after
    File.rm_rf(tmp_dir)
  end
end
```
```elixir
with :ok <- File.mkdir_p(path),
     :ok <- File.chmod(path, 0o700) do
  {:ok, path}
end
```
```elixir
args =
  [
    "--encrypt",
    opts.open_password,
    opts.owner_password,
    "256"
  ] ++ permission_args(opts.advisory_permissions) ++ ["--", input_path, output_path]
```

**Permission mapping pattern** ([lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:114)):
```elixir
[
  print_arg(permissions),
  modify_arg(permissions),
  yes_no_arg("--extract", :copy in permissions),
  yes_no_arg("--annotate", :annotate in permissions),
  yes_no_arg("--form", :fill_forms in permissions),
  yes_no_arg("--assemble", :assemble in permissions),
  yes_no_arg("--accessibility", :extract_for_accessibility in permissions)
]
```

**Use in Phase 52**
- Keep the adapter optional and runtime-discovered.
- Preserve argfile-based password isolation and `after` cleanup.
- Remove or deprecate `--accessibility` by changing the curated mapping at this layer, not by widening the public API.
- Continue returning tiny stable reasons like `{:missing_executable, "qpdf"}`, `{:command_failed, RuntimeError}`, `{:qpdf_failed, exit_code}`.

### `lib/rendro/adapters/poppler.ex` (adapter, request-response)

**Analog:** `lib/rendro/adapters/poppler.ex`

**Current executable boundary** ([lib/rendro/adapters/poppler.ex](/Users/jon/projects/rendro/lib/rendro/adapters/poppler.ex:14)):
```elixir
case System.find_executable("pdfinfo") do
  nil ->
    {:error, {:missing_executable, "pdfinfo"}}

  executable ->
    case System.cmd(executable, pdfinfo_args(file_path, opts), stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, parse_output(output)}

      {output, _exit_code} ->
        {:error, {:invalid_pdf, String.trim(output)}}
    end
end
```

**Password-flag builder** ([lib/rendro/adapters/poppler.ex](/Users/jon/projects/rendro/lib/rendro/adapters/poppler.ex:30)):
```elixir
[]
|> maybe_put_password_flag("-upw", Keyword.get(opts, :open_password))
|> maybe_put_password_flag("-opw", Keyword.get(opts, :owner_password))
|> Kernel.++([file_path])
```

**Use in Phase 52**
- Keep this module as the structural validation seam.
- Tighten password precedence here: `open_password` first, otherwise `owner_password`, never both.
- Replace raw `{:invalid_pdf, String.trim(output)}` with a small classified reason set; Phase 52 should not publish vendor text.
- Follow qpdf’s injectable seam pattern if hermetic unit tests need controlled executable/runner behavior.

### `lib/rendro/protect.ex` (service, transform)

**Analog:** `lib/rendro/protect.ex`

**Public normalization boundary** ([lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:41), [lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:106)):
```elixir
with {:ok, normalized} <- normalize_opts(opts),
     {:ok, protected_binary} <- normalized.adapter.protect(artifact, normalized) do
  {:ok,
   Artifact.wrap(
     protected_binary,
     artifact,
     %{
       deterministic: false,
       protection: protection_metadata(normalized)
     }
   )}
```
```elixir
%{
  adapter: Map.get(opts, :adapter, @default_adapter),
  algorithm: Map.get(opts, :algorithm, :aes_256),
  advisory_permissions: permissions,
  has_open_password: present_password?(Map.get(opts, :open_password)),
  has_owner_password: present_password?(Map.get(opts, :owner_password))
}
```

**Stable permission whitelist** ([lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:12)):
```elixir
@supported_permissions [
  :annotate,
  :assemble,
  :copy,
  :extract_for_accessibility,
  :fill_forms,
  :modify,
  :print
]
```

**Use in Phase 52**
- If `:extract_for_accessibility` is removed from the public contract, update the whitelist here first.
- Keep password safety at the public boundary: all downstream validation/proof changes should continue using boolean presence flags, never secrets.
- Reuse this module’s normalization vocabulary in Poppler docs and tests: `open_password` is the normative name.

### `lib/rendro/error.ex` (model, transform)

**Analog:** `lib/rendro/error.ex`

**Typed error envelope** ([lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:23)):
```elixir
%__MODULE__{
  what: what(stage, reason),
  where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
  why: why(reason),
  next: next_step(stage, reason),
  stage: stage,
  reason: reason,
  render_id: Map.get(context, :render_id),
  details: Map.merge(%{document_type: ..., deterministic: ...}, Map.get(context, :details, %{}))
}
```

**Current protect-stage wording** ([lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:67), [lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:144)):
```elixir
defp why({:missing_executable, executable}), do: "Missing executable: #{executable}"
defp why({:adapter_failure, adapter, {:qpdf_failed, exit_code}}),
  do: "Protection adapter #{inspect(adapter)} failed: qpdf exited with status #{exit_code}"
```
```elixir
defp next_step(:protect, {:missing_executable, "qpdf"}) do
  "Install qpdf on the host or select a different protection adapter before calling Rendro.Protect.password/2."
end
```

**Use in Phase 52**
- Extend the same style for validation-stage failures instead of inventing a second public error philosophy.
- Keep `why` and `next` operator-useful but redacted; stable status classes and exit codes are acceptable, raw stderr is not.
- If Poppler failures are wrapped into `Rendro.Error`, keep the reason tuples narrow enough to support exact assertions.

### `test/rendro/adapters/qpdf_test.exs` (test, file-I/O)

**Analog:** `test/rendro/adapters/qpdf_test.exs`

**Injected seam cleanup pattern** ([test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:9)):
```elixir
setup do
  on_exit(fn ->
    Application.delete_env(:rendro, :qpdf_executable_finder)
    Application.delete_env(:rendro, :qpdf_command_runner)
  end)

  :ok
end
```

**Hermetic argfile assertions** ([test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:43)):
```elixir
Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf", ["@" <> path], _opts ->
  input_path = Path.join(Path.dirname(path), "input.pdf")
  assert file_mode(Path.dirname(path)) == 0o700
  assert file_mode(path) == 0o600
  assert file_mode(input_path) == 0o600
  [first | rest] = File.read!(path) |> String.split("\n", trim: true)
  assert first == "--encrypt"
```

**Redaction-by-assertion pattern** ([test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:72)):
```elixir
Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf", ["@" <> path], _opts ->
  send(self(), {:tmp_dir, Path.dirname(path)})
  {"qpdf failed for open-secret", 2}
end)

assert {:error, {:qpdf_failed, 2}} = Qpdf.protect(sample_artifact(), sample_opts())
assert_receive {:tmp_dir, tmp_dir}
refute File.exists?(tmp_dir)
```

**Use in Phase 52**
- Copy this style for Poppler hermetic tests: inject seams, assert exact args, and prove cleanup/redaction from the outside.
- Test password-precedence decisions by asserting the command args, not by depending on host tools.

### `test/rendro/adapters/poppler_test.exs` (test, request-response)

**Analog:** `test/rendro/adapters/poppler_test.exs`

**Current host-tool-light pattern** ([test/rendro/adapters/poppler_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/poppler_test.exs:8)):
```elixir
case System.find_executable("pdfinfo") do
  nil ->
    IO.puts("Skipping ...: pdfinfo not installed")
    :ok

  _executable ->
    ...
end
```

**Scope-boundary commentary** ([test/rendro/adapters/poppler_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/poppler_test.exs:98)):
```elixir
# Poppler proves PDF structure only. This lane does NOT prove ...
# Those claims require the manual viewer proof lane ...
```

**Use in Phase 52**
- Preserve the split between structural proof and viewer claims.
- Replace ad-hoc host-tool tests with two lanes:
- Hermetic unit tests using injected seams.
- Narrow live-tool proof tests that skip cleanly when tools are absent.

### `test/rendro/protect_test.exs` (test, transform)

**Analog:** `test/rendro/protect_test.exs`

**Public error redaction assertions** ([test/rendro/protect_test.exs](/Users/jon/projects/rendro/test/rendro/protect_test.exs:184)):
```elixir
assert error.reason == {:adapter_failure, FailingAdapter, :adapter_down}
assert error.details.has_open_password == true
assert error.details.has_owner_password == true
refute Map.has_key?(error.details, :open_password)
refute Map.has_key?(error.details, :owner_password)
```

**Non-leak regression style** ([test/rendro/protect_test.exs](/Users/jon/projects/rendro/test/rendro/protect_test.exs:200)):
```elixir
assert error.reason == {:adapter_failure, Qpdf, {:qpdf_failed, 2}}
refute error.why =~ "open-secret"
refute error.why =~ "owner-secret"
refute inspect(error.reason) =~ "open-secret"
refute inspect(error.details) =~ "owner-secret"
```

**Use in Phase 52**
- Mirror these assertions for Poppler validation failures.
- Public failure tests should pin the redacted reason tuple and check that `why`, `reason`, and `details` do not leak password material or vendor output.

### `test/docs_contract/protection_claims_test.exs` + `guides/api_stability.md` + `priv/support_matrix.json` (docs contract, transform/static)

**Analogs:** `test/docs_contract/protection_claims_test.exs`, `guides/api_stability.md`, `priv/support_matrix.json`

**Matrix and docs must lock together** ([test/docs_contract/protection_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/protection_claims_test.exs:4)):
```elixir
assert matrix =~ ~s|"password_to_open": "supported"|
assert matrix =~ ~s|"external_hook_qpdf": "supported"|
assert matrix =~ ~s|"native_encryption": "unsupported"|
...
assert matrix =~
         ~r/"protection".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
```

**Truthful wording pattern** ([guides/api_stability.md](/Users/jon/projects/rendro/guides/api_stability.md:60)):
```markdown
Rendro supports password-to-open PDF protection through an external artifact-first boundary.
...
Structural validation through `pdfinfo`/Poppler proves that a protected PDF remains structurally readable when a password is supplied to the validator. It does not prove viewer behavior.
```

**Explicit docs lane registration** ([scripts/verify_docs.exs](/Users/jon/projects/rendro/scripts/verify_docs.exs:7)):
```elixir
{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}
```

**Use in Phase 52**
- Update support claims only where proof exists.
- Keep protection viewers `unverified` until manual proof exists.
- If the public permission whitelist changes, adjust both `priv/support_matrix.json` and the claims test in the same slice.
- Use exact-string docs assertions to prevent wording drift.

## Shared Patterns

### Optional executable adapters
**Sources:** [lib/rendro/adapters/qpdf.ex](/Users/jon/projects/rendro/lib/rendro/adapters/qpdf.ex:23), [test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:36)

- Runtime discovery via `Application.get_env(..., &System.find_executable/1)` is the repo’s strongest existing analog.
- Command execution should be injectable and return typed tuples on missing tool, non-zero exit, or runner crash.

### Typed error shaping and redaction
**Sources:** [lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:58), [lib/rendro/protect.ex](/Users/jon/projects/rendro/lib/rendro/protect.ex:79), [lib/rendro/error.ex](/Users/jon/projects/rendro/lib/rendro/error.ex:67), [test/rendro/protect_test.exs](/Users/jon/projects/rendro/test/rendro/protect_test.exs:200)

- Public APIs wrap adapter failures into `Rendro.Error.from_stage/3`.
- Redaction happens through small boolean/detail maps, never raw command data.
- Tests prove non-leakage by asserting against `why`, `reason`, and `details`.

### Hermetic external-boundary tests with injected seams
**Sources:** [test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:43), [test/rendro/adapters/qpdf_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/qpdf_test.exs:72)

- Inject seams through application env.
- Assert command args and file permissions directly.
- Use fake runners to drive failure branches and cleanup checks without host-tool dependence.

### Tagged/live integration proof lanes
**Closest existing sources:** [test/rendro/adapters/poppler_test.exs](/Users/jon/projects/rendro/test/rendro/adapters/poppler_test.exs:8), [scripts/verify_docs.exs](/Users/jon/projects/rendro/scripts/verify_docs.exs:7), [mix.exs](/Users/jon/projects/rendro/mix.exs:48)

- The repo already tolerates optional-tool proof by skipping cleanly when the executable is absent.
- There is no existing `@tag :integration` or separate Mix alias for live tool tests.
- Planner should treat the tagged live lane as a new file/pattern introduction built on the existing “optional proof lane” posture, not as a direct copy-paste from an existing tagged suite.

### Docs/support-matrix contract updates
**Sources:** [test/docs_contract/protection_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/protection_claims_test.exs:4), [test/docs_contract/embedded_artifact_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/embedded_artifact_claims_test.exs:8), [guides/api_stability.md](/Users/jon/projects/rendro/guides/api_stability.md:60), [priv/support_matrix.json](/Users/jon/projects/rendro/priv/support_matrix.json:1)

- Support claims live in two places only: `guides/api_stability.md` and `priv/support_matrix.json`.
- Claims tests pin both surfaces together and refute broader wording.
- `scripts/verify_docs.exs` is the canonical lane registry; add proof-lane coverage there if new docs-claims tests are introduced.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/rendro/adapters/qpdf_live_test.exs` or equivalent tagged live-tool proof file | test | file-I/O | Repo has optional-tool skips and explicit docs lanes, but no established `@tag :integration` or dedicated live executable proof suite yet. |

## Implementation Guidance

- Prefer modifying `Poppler.validate/2` to mirror qpdf’s seam design before adding new proof files; that gives fast hermetic coverage and a narrow public contract.
- Treat `test/rendro/adapters/qpdf_test.exs` as the primary analog for seam injection and redaction, and `test/rendro/protect_test.exs` as the primary analog for public error assertions.
- Treat `test/docs_contract/protection_claims_test.exs` as the gate for any support-matrix or wording change.
- If Phase 52 introduces a new live proof file, keep it separate from default `mix test` expectations and make tool absence a clean skip, not a failure.

## Metadata

**Analog search scope:** `lib/rendro`, `test/rendro`, `test/docs_contract`, `guides`, `priv`, `.planning/phases/51-*`, `.planning/phases/50-*`
**Pattern extraction date:** 2026-05-06

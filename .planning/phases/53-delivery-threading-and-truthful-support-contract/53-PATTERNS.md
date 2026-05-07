---
phase: 53
slug: delivery-threading-and-truthful-support-contract
status: ready
created: 2026-05-06
updated: 2026-05-06
---

# Phase 53: Delivery Threading and Truthful Support Contract - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 13
**Analogs found:** 12 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/storage.ex` | service | request-response | `lib/rendro/storage.ex` | exact |
| `lib/rendro/storage/local.ex` | service | file-I/O | `lib/rendro/storage/local.ex` | exact |
| `lib/rendro/adapters/mailglass.ex` | adapter | request-response | `lib/rendro/adapters/mailglass.ex` | exact |
| `lib/rendro/adapters/oban/render_worker.ex` | adapter | request-response | `lib/rendro/adapters/oban/render_worker.ex` | exact |
| `guides/integrations.md` | docs | request-response | `guides/integrations.md` | exact |
| `guides/api_stability.md` | docs | transform | `guides/api_stability.md` | exact |
| `priv/support_matrix.json` | config | static | `priv/support_matrix.json` | exact |
| `test/docs_contract/protection_claims_test.exs` | test | transform | `test/docs_contract/protection_claims_test.exs` | exact |
| `test/docs_contract/integrations_claims_test.exs` | test | request-response | `test/docs_contract/integrations_claims_test.exs` | exact |
| `test/rendro/adapters/mailglass_test.exs` | test | request-response | `test/rendro/adapters/mailglass_test.exs` | exact |
| `test/rendro/adapters/oban/render_worker_test.exs` | test | request-response | `test/rendro/adapters/oban/render_worker_test.exs` | exact |
| `test/rendro/storage/local_test.exs` or equivalent protected-storage regression file | test | file-I/O | `test/rendro/end_to_end_pipeline_test.exs` plus `test/rendro/artifact_test.exs` | partial |
| `test/rendro/end_to_end_pipeline_test.exs` | test | request-response | `test/rendro/end_to_end_pipeline_test.exs` | exact |

## Pattern Assignments

### `lib/rendro/storage.ex` (service, request-response)

**Analog:** `lib/rendro/storage.ex`

**Keep the behavior narrow** (`lib/rendro/storage.ex:10-30`):
```elixir
@doc """
Persists an artifact.

Implementations must return `{:ok, identifier}` where `identifier` is a stable
string/URI referencing the stored document. They may also return `{:error, reason}`.
"""
@callback put(Rendro.Artifact.t(), keyword()) :: {:ok, String.t()} | {:error, term()}

@doc """
Retrieves a stored artifact by its identifier.

Returns `{:ok, Artifact.t()}` if found, or `{:error, :not_found}` / `{:error, reason}`.
"""
@callback get(String.t(), keyword()) :: {:ok, Rendro.Artifact.t()} | {:error, term()}
```

**Use in Phase 53**
- Preserve the small `put/2`, `get/2`, `delete/2` contract.
- Do not add password-bearing options or a richer mandatory metadata round-trip contract at the behavior layer.
- If moduledoc/docs change, mirror the existing “external system seam” wording rather than turning `Rendro.Storage` into a framework contract.

### `lib/rendro/storage/local.ex` (service, file-I/O)

**Analog:** `lib/rendro/storage/local.ex`

**Current file-write and minimal reload seam** (`lib/rendro/storage/local.ex:7-20`, `lib/rendro/storage/local.ex:23-39`):
```elixir
def put(artifact, opts) do
  case Keyword.fetch(opts, :path) do
    {:ok, path} ->
      path |> Path.dirname() |> File.mkdir_p!()

      case File.write(path, artifact.binary) do
        :ok -> {:ok, path}
        {:error, reason} -> {:error, reason}
      end
```
```elixir
def get(identifier, _opts) do
  case File.read(identifier) do
    {:ok, binary} ->
      # Here we only have the binary, so we reconstruct a minimal artifact.
      # Real implementations might also fetch a sidecar metadata JSON.
      {:ok,
       %Rendro.Artifact{
         binary: binary,
         hash: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower),
         diagnostics: [],
         metadata: %{}
       }}
```

**Nearest metadata-shape analog for reconstruction:** `Rendro.Artifact.wrap/3` assertions in `test/rendro/artifact_test.exs:19-50` and protected metadata assertions in `test/rendro/protect_test.exs:44-71`.

**Use in Phase 53**
- The sidecar/manifest addition belongs here, not in `Rendro.Storage`.
- Preserve the current `{:ok, path}` storage identifier and `{:error, reason}` style.
- Rebuild only the small truthful metadata envelope on reload: at minimum `deterministic` and `protection` when a first-party manifest exists.
- Copy the “minimal, password-safe metadata only” constraint from protection tests; never persist open/owner password values.

### `lib/rendro/adapters/mailglass.ex` (adapter, request-response)

**Analog:** `lib/rendro/adapters/mailglass.ex`

**Optional adapter guard + transport-only attachment seam** (`lib/rendro/adapters/mailglass.ex:1-10`, `lib/rendro/adapters/mailglass.ex:50-67`, `lib/rendro/adapters/mailglass.ex:79-103`):
```elixir
if Code.ensure_loaded?(Mailglass) do
  defmodule Rendro.Adapters.Mailglass do
```
```elixir
@doc """
Attaches a rendered `Rendro.Artifact` as a PDF to `email_or_message`.
"""
@spec attach_artifact(term(), Rendro.Artifact.t(), String.t()) ::
        term()
        | {:error, Rendro.Error.t()}
        | {:error, {:unrecognized_message_shape, atom() | term()}}
def attach_artifact(
      email_or_message,
      %Rendro.Artifact{binary: binary},
      filename \\ @default_filename
    )
    when is_binary(filename) do
  attach_binary(email_or_message, binary, filename)
end
```
```elixir
def attach_pdf(email_or_message, %Rendro.Document{} = document, filename)
    when is_binary(filename) do
  case Rendro.render(document) do
    {:ok, binary} -> attach_binary(email_or_message, binary, filename)
    {:error, _} = err -> err
  end
end
```

**Message-shape validation and typed errors** (`lib/rendro/adapters/mailglass.ex:112-163`):
```elixir
defp mailglass_message?(%Mailglass.Message{}), do: true

defp mailglass_message?(value) when is_struct(value) do
  mod = value.__struct__

  mod
  |> Atom.to_string()
  |> String.ends_with?(".Message") and
    function_exported?(mod, :update_swoosh, 2)
end
```

**Use in Phase 53**
- Keep `attach_pdf/3` as the plain render-and-attach convenience path.
- Put all protected-delivery clarification into moduledoc/docs/tests, not into a new `attach_protected_pdf/4` API.
- Reuse `attach_artifact/3` as the canonical protected seam and keep passwords out of the adapter surface completely.

### `lib/rendro/adapters/oban/render_worker.ex` (adapter, request-response)

**Analog:** `lib/rendro/adapters/oban/render_worker.ex`

**Optional worker boundary and narrow `perform/1` pipeline** (`lib/rendro/adapters/oban/render_worker.ex:1-25`):
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Rendro.Adapters.Oban.RenderWorker do
    use Oban.Worker, queue: :render, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) when is_map(args) do
      with {:ok, module} <- fetch_module(args),
           {:ok, builder_args} <- fetch_builder_args(args),
           {:ok, storage_mod, storage_opts} <- fetch_storage(args),
           {:ok, policies} <- fetch_policies(args),
           {:ok, doc} <- build_document(module, builder_args) do
        doc
        |> inject_missing_policies(policies)
        |> render_and_store(storage_mod, storage_opts)
      end
    end
```

**Storage-module resolution and typed worker boundary errors** (`lib/rendro/adapters/oban/render_worker.ex:40-56`, `58-93`):
```elixir
defp fetch_storage(%{"storage_module" => mod_val} = args) do
  opts_val = Map.get(args, "storage_opts", %{})

  with {:ok, mod} <- resolve_storage_module(mod_val),
       {:ok, opts} <- resolve_storage_opts(opts_val) do
    {:ok, mod, opts}
  end
end
```
```elixir
defp validate_storage_module(module, module_input) do
  cond do
    not Code.ensure_loaded?(module) -> {:error, {:unknown_worker_storage, module_input}}
    not function_exported?(module, :put, 2) -> {:error, {:invalid_worker_storage, module}}
    true -> {:ok, module}
  end
end
```

**Render-to-artifact then store** (`lib/rendro/adapters/oban/render_worker.ex:191-201`):
```elixir
defp render_and_store(doc, storage_mod, storage_opts) do
  case Rendro.render_to_artifact(doc) do
    {:ok, artifact} ->
      case storage_mod.put(artifact, storage_opts) do
        {:ok, _identifier} -> :ok
        {:error, error} -> {:error, {:storage_error, error}}
      end

    {:error, error} ->
      {:error, error.reason}
  end
end
```

**Use in Phase 53**
- Keep this worker render-only.
- If docs or tests add a protected async recipe, keep it application-owned and outside `perform/1`.
- Reuse the current typed worker error style and the identifiers-only job-arg posture already documented in the guide.

### `guides/integrations.md` (docs, request-response)

**Analog:** `guides/integrations.md`

**Boundary-first adapter overview** (`guides/integrations.md:5-13`, `15-27`):
```markdown
Rendro ships three optional adapters for common ecosystem workflows...
Each adapter module is compiled only when its target library is present...
```
```markdown
Adapters such as Oban workers, audit logging hooks, and mail-delivery helpers
only transport or observe the document you already built.
```

**Oban protected-delivery wording to extend, not replace** (`guides/integrations.md:67-70`):
```markdown
The worker also does **not** accept password or protection fields in job args.
Protection secrets do not belong in persisted Oban args. If you need protected
delivery, render the artifact in your worker and apply `Rendro.Protect.password/2`
 in an application-owned credential boundary before storage or delivery.
```

**Mailglass protected-artifact recipe** (`guides/integrations.md:252-260` and continuation already referenced by `test/docs_contract/protection_claims_test.exs`):
- The existing guide already teaches `render_to_artifact -> Protect.password -> attach_artifact/3`.
- Phase 53 should strengthen that section with one canonical async/storage variant, not introduce multiple competing recipes.

**Use in Phase 53**
- Keep the guide schematic and application-owned.
- Add one strong protected async recipe: identifiers in args, late secret fetch, protect, then store/deliver.
- Distinguish clearly between `attach_pdf/3` for unprotected renders and `attach_artifact/3` for already-protected artifacts.

### `guides/api_stability.md` (docs, transform)

**Analog:** `guides/api_stability.md`

**Current support-boundary style** (`guides/api_stability.md:60-72`):
```markdown
## Protected PDF Support Boundary

Rendro supports password-to-open PDF protection through an external artifact-first boundary.

The canonical API is `Rendro.Protect.password/2`, which wraps an already-rendered `%Rendro.Artifact{}` through a protection adapter such as `Rendro.Adapters.Qpdf`.
...
Protection is not compliance, not tamper evidence, and not digital signing.
```

**Use in Phase 53**
- Extend this section with small explicit boundary sentences, matching the existing blunt style.
- Keep the wording product-facing and conservative.
- Add the storage/delivery boundary story here only if it is a stable support contract, and keep it aligned with the machine-readable matrix.

### `priv/support_matrix.json` (config, static)

**Analog:** `priv/support_matrix.json`

**Current family-first protection contract** (`priv/support_matrix.json:106-143`):
```json
"protection": {
  "capabilities": {
    "password_to_open": "supported",
    "external_hook_qpdf": "supported",
    "native_encryption": "unsupported"
  },
  "algorithms": {
    "aes_256": "supported",
    "aes_128": "unsupported",
    "rc4": "unsupported"
  },
  "behaviors": {
    "advisory_permissions": "supported",
    "deterministic_output": "unsupported",
    "digital_signatures": "unsupported",
    "pdf_a_compliance": "unsupported",
    "tamper_evidence": "unsupported"
  }
}
```

**Closest shape analog for nested support families:** `embedded_files` / `links` in `priv/support_matrix.json:52-105`.

**Use in Phase 53**
- Keep the current compact family-first structure.
- Add a small `protection.boundaries` subsection rather than widening `behaviors`.
- Follow the existing scalar-leaf style used elsewhere in the matrix for support/unsupported, with only the smallest extra leaves needed for boundary truths.

### `test/docs_contract/protection_claims_test.exs` (test, transform)

**Analog:** `test/docs_contract/protection_claims_test.exs`

**Literal matrix and guide wording lock** (`test/docs_contract/protection_claims_test.exs:4-25`, `27-56`):
```elixir
test "support matrix publishes the narrow protection family and leaves viewers unverified" do
  matrix = File.read!("priv/support_matrix.json")

  assert matrix =~ ~s|"protection"|
  assert matrix =~ ~s|"password_to_open": "supported"|
  assert matrix =~ ~s|"external_hook_qpdf": "supported"|
  ...
end
```
```elixir
test "api stability guide uses narrow, truthful protection wording" do
  guide = File.read!("guides/api_stability.md")

  assert guide =~
           "Rendro supports password-to-open PDF protection through an external artifact-first boundary."
  ...
  refute guide =~ "secure PDF"
end
```

**Cross-guide seam already present** (`test/docs_contract/protection_claims_test.exs:45-55`):
```elixir
assert guide =~ "The worker also does **not** accept password or protection fields in job args."
assert guide =~ "Protection secrets do not belong in persisted Oban args."
assert guide =~ "Mailglass does not need to know the passwords"
```

**Use in Phase 53**
- Extend this exact test rather than creating a second overlapping protection claims file.
- Add assertions for `protection.boundaries.*`, for the narrow storage/delivery transport story, and for anti-overclaim refutes.
- Keep literal string assertions and targeted regexes instead of abstract helpers.

### `test/docs_contract/integrations_claims_test.exs` (test, request-response)

**Analog:** `test/docs_contract/integrations_claims_test.exs`

**Compile-time guard assertions** (`test/docs_contract/integrations_claims_test.exs:35-45`):
```elixir
for {path, dependency} <- [
      {"lib/rendro/adapters/threadline.ex", "Threadline"},
      {"lib/rendro/adapters/oban/render_worker.ex", "Oban"},
      {"lib/rendro/adapters/mailglass.ex", "Mailglass"},
      {"lib/rendro/adapters/accrue.ex", "Accrue"}
    ] do
  source = File.read!(path)
  assert source =~ "if Code.ensure_loaded?(#{dependency}) do"
end
```

**Protected transport claim test** (`test/docs_contract/integrations_claims_test.exs:91-109`):
```elixir
test "mailglass can transport a protected artifact without receiving passwords" do
  email = Swoosh.Email.new() |> Swoosh.Email.to("customer@example.test")
  {:ok, artifact} = Rendro.render_to_artifact(sample_document(), deterministic: true)

  {:ok, protected} =
    Protect.password(artifact,
      adapter: FakeProtectAdapter,
      open_password: "open-secret",
      owner_password: "owner-secret",
      advisory_permissions: [:print]
    )

  result = MailglassAdapter.attach_artifact(email, protected, "invoice.pdf")
```

**Use in Phase 53**
- Keep docs-contract assertions executable and concrete.
- Add the async protected-delivery recipe checks here if they are guide-level claims, especially “identifiers only” and “late secret resolution”.
- Reuse the fake adapter pattern when proving transport-only semantics without binding tests to qpdf.

### `test/rendro/adapters/mailglass_test.exs` (test, request-response)

**Analog:** `test/rendro/adapters/mailglass_test.exs`

**Direct attachment seam** (`test/rendro/adapters/mailglass_test.exs:101-121`):
```elixir
describe "attach_artifact/3" do
  test "attaches an artifact binary directly to the email" do
    email = Swoosh.Email.new()

    artifact = %Rendro.Artifact{
      binary: <<"%PDF-1.4\n">>,
      hash: "dummyhash",
      diagnostics: [],
      metadata: %{}
    }

    result = Adapter.attach_artifact(email, artifact, "receipt.pdf")
```

**Negative-path contract style** (`test/rendro/adapters/mailglass_test.exs:148-203`):
- Use explicit small fixture structs at top level.
- Catch regressions by asserting exact `{:error, ...}` tuple shapes.

**Use in Phase 53**
- Add a protected-artifact metadata-preservation or “transport bytes only” regression here if the adapter code or moduledoc changes.
- Do not test password handling in this file beyond proving it is absent from the API and irrelevant to attachment behavior.

### `test/rendro/adapters/oban/render_worker_test.exs` (test, request-response)

**Analog:** `test/rendro/adapters/oban/render_worker_test.exs`

**Narrow builder fixture and typed boundary tests** (`test/rendro/adapters/oban/render_worker_test.exs:6-29`, `68-118`):
```elixir
defmodule SampleBuilder do
  def build_document(%{"content" => content} = args) do
    ...
  end
end
```
```elixir
test "malformed required worker fields do not crash" do
  assert {:error, {:missing_worker_field, :module}} =
           RenderWorker.perform(%Oban.Job{args: %{}})
  ...
end
```

**Current policy-precedence style** (`test/rendro/adapters/oban/render_worker_test.exs:31-66`):
```elixir
test "document-authored policies win over worker policies when already present" do
  ...
  assert :ok = perform_worker(...)
end
```

**Use in Phase 53**
- Extend this file only if `RenderWorker` itself changes or its boundary needs new typed rejection tests.
- If Phase 53 stays docs-only for async protected delivery, prefer docs-contract coverage over widening this unit test unnecessarily.

### `test/rendro/storage/local_test.exs` or equivalent protected-storage regression file (test, file-I/O)

**Analog:** no exact analog; compose from:
- `test/rendro/end_to_end_pipeline_test.exs:32-66` for `put -> get -> downstream use`
- `test/rendro/artifact_test.exs:19-50` for exact metadata reconstruction assertions
- `test/rendro/protect_test.exs:44-71` for the allowed `metadata.protection` shape

**Use in Phase 53**
- This is the main new seam.
- Prefer a focused storage test over hiding the behavior only in end-to-end coverage.
- Test cases should likely be:
  - `put/2` writes PDF bytes and sidecar/manifest metadata together.
  - `get/2` reconstructs `%Rendro.Artifact{}` with `metadata.deterministic` and `metadata.protection`.
  - retrieved metadata excludes password strings and any adapter-private detail.
  - missing manifest stays truthful, either returning minimal metadata or a clearly documented fallback, without pretending protection metadata was preserved.

### `test/rendro/end_to_end_pipeline_test.exs` (test, request-response)

**Analog:** `test/rendro/end_to_end_pipeline_test.exs`

**Current pipeline composition seam** (`test/rendro/end_to_end_pipeline_test.exs:32-60`):
```elixir
assert :ok = RenderWorker.perform(job)

assert {:ok, %Artifact{} = artifact} = Local.get(storage_path, [])
assert is_binary(artifact.binary)
assert String.starts_with?(artifact.binary, "%PDF-")

email = Swoosh.Email.new()
email_with_pdf = Mailglass.attach_artifact(email, artifact, "invoice-e2e.pdf")
```

**Use in Phase 53**
- Strong analog if the planner wants one higher-level protected-delivery integration test.
- Keep any new end-to-end variant application-owned and explicit: render artifact, protect artifact, store or attach artifact.
- Avoid turning this test into a first-party async protected orchestrator proof.

## Shared Patterns

### Optional adapter compile guards

**Sources:** `lib/rendro/adapters/mailglass.ex:1-10`, `lib/rendro/adapters/oban/render_worker.ex:1-8`, `test/docs_contract/integrations_claims_test.exs:35-45`

Apply to all adapter docs/tests touched in Phase 53:
```elixir
if Code.ensure_loaded?(Mailglass) do
  defmodule Rendro.Adapters.Mailglass do
```
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Rendro.Adapters.Oban.RenderWorker do
```

Planning implication:
- Keep transport/orchestration seams optional.
- Prefer docs-contract and source-shape assertions over introducing runtime dependencies into core tests.

### Protected artifact metadata stays minimal and password-safe

**Sources:** `test/rendro/protect_test.exs:44-71`, `test/rendro/artifact_test.exs:19-50`

Apply to storage reconstruction, docs wording, and any new storage tests:
```elixir
assert protected.metadata.protection == %{
         algorithm: :aes_256,
         advisory_permissions: [:copy, :print],
         has_open_password: true,
         has_owner_password: true
       }

refute inspect(protected.metadata.protection) =~ "open-secret"
refute inspect(protected.metadata.protection) =~ "owner-secret"
```

Planning implication:
- Any manifest/sidecar stored by first-party examples should capture only this small contract.
- No password material, qpdf stderr, or adapter identifiers should be added.

### Docs-contract tests stay literal, narrow, and anti-overclaim

**Sources:** `test/docs_contract/protection_claims_test.exs:4-63`, `test/docs_contract/embedded_artifact_claims_test.exs:8-133`, `test/docs_contract/forms_claims_test.exs:4-48`

Apply to `protection` matrix/docs updates and integration-guide wording:
```elixir
assert matrix =~ ~s|"password_to_open": "supported"|
assert guide =~ "Rendro supports password-to-open PDF protection through an external artifact-first boundary."
refute guide =~ "secure PDF"
```

Planning implication:
- Use literal string assertions and a small number of regexes.
- Add explicit refutes for the new high-risk misreads: password-bearing job args, adapter-owned password management, and over-broad storage guarantees.

### Application-owned async orchestration

**Sources:** `guides/integrations.md:63-70`, `lib/rendro/adapters/oban/render_worker.ex:16-25`, `test/docs_contract/integrations_claims_test.exs:47-58`

Apply to Oban docs and any plan touching async protected delivery:
```markdown
The worker also does **not** accept password or protection fields in job args.
Protection secrets do not belong in persisted Oban args.
```

Planning implication:
- Keep Oban render-only.
- Teach a recipe around identifiers, late secret fetch, `render_to_artifact`, `Protect.password/2`, and then store/deliver.

### Protected delivery uses `attach_artifact/3`, not a new policy-bearing helper

**Sources:** `lib/rendro/adapters/mailglass.ex:50-87`, `test/docs_contract/integrations_claims_test.exs:91-109`, `test/rendro/adapters/mailglass_test.exs:101-121`

Apply to Mailglass docs and tests:
```elixir
{:ok, protected} = Protect.password(artifact, ...)
result = MailglassAdapter.attach_artifact(email, protected, "invoice.pdf")
```

Planning implication:
- Phase 53 should reinforce this exact sequence.
- Do not add `protect:` options or password-taking Mailglass APIs.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/rendro/storage/local_test.exs` or equivalent manifest/sidecar regression file | test | file-I/O | Repo has no existing first-party storage test that round-trips artifact metadata through `put/2` and `get/2`; compose from end-to-end storage usage plus artifact/protection metadata assertions. |

## Plan-Oriented Mapping

### Plan A: Protected artifact transport and storage semantics

Primary files:
- `lib/rendro/storage/local.ex`
- `lib/rendro/storage.ex`
- `lib/rendro/adapters/mailglass.ex`
- `lib/rendro/adapters/oban/render_worker.ex`
- `test/rendro/storage/local_test.exs` or equivalent
- `test/rendro/adapters/mailglass_test.exs`
- optionally `test/rendro/end_to_end_pipeline_test.exs`

Best patterns to copy:
- `test/rendro/protect_test.exs:44-71` for the only acceptable `metadata.protection` shape
- `lib/rendro/storage/local.ex:23-39` as the precise place to add first-party manifest reconstruction
- `lib/rendro/adapters/mailglass.ex:56-87` and `test/docs_contract/integrations_claims_test.exs:91-109` for transport-only protected delivery
- `guides/integrations.md:67-70` and `lib/rendro/adapters/oban/render_worker.ex:191-201` for render-only async composition

### Plan B: Support matrix, docs, and docs-contract closure

Primary files:
- `guides/integrations.md`
- `guides/api_stability.md`
- `priv/support_matrix.json`
- `test/docs_contract/protection_claims_test.exs`
- `test/docs_contract/integrations_claims_test.exs`

Best patterns to copy:
- `priv/support_matrix.json:106-143` for compact protection-family shape
- `test/docs_contract/protection_claims_test.exs:4-63` for literal support-boundary locking
- `test/docs_contract/embedded_artifact_claims_test.exs:8-133` for matrix-plus-guide-plus-lane synchronization style
- `guides/api_stability.md:60-72` for concise product-boundary prose

## Metadata

**Analog search scope:** `lib/rendro`, `guides`, `priv`, `test/rendro`, `test/docs_contract`, adjacent phase artifacts in `.planning/phases/50-*`, `.planning/phases/51-*`, `.planning/phases/52-*`
**Files scanned:** 20
**Pattern extraction date:** 2026-05-06

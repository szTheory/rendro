# Phase 133: Repository & Evidence Hygiene - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 61 file targets (including 17 retained journey records and 7 historical planning moves)  
**Analogs found:** 42 / 61

## File Classification

| New/Modified File(s) | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `evidence/releases/v1.3.4/manifest.json` | config / manifest | file-I/O | `priv/public_api.json` | role-match |
| `evidence/releases/v1.3.4/{public_prerequisite,release_identity,validation}.json` | immutable evidence record | file-I/O | `priv/quality/rubric_scores.json` | partial |
| `evidence/releases/v1.3.4/journey/index.json` | immutable evidence index | file-I/O | `priv/public_api.json` | role-match |
| `evidence/releases/v1.3.4/journey/*.json` (9 records) | immutable evidence record | file-I/O | `priv/journey_evidence/*.json` | exact data-role, relocated |
| `evidence/releases/v1.3.4/journey/*.md` (8 sidecars) | immutable evidence narrative | file-I/O | `priv/journey_evidence/*.md` | exact data-role, relocated |
| `priv/schemas/release_evidence_*.schema.json` (manifest, prerequisite, identity, validation, journey index, attempt) | schema / config | transform | `priv/schemas/public_api.schema.json` | exact |
| `dev/rendro/repository_evidence.ex` | service / loader | file-I/O | `lib/rendro/public_api/{loader,validator}.ex` | role-match |
| `dev/rendro/repository_hygiene.ex` | service / policy validator | batch | `dev/rendro/catalog.ex` | partial |
| `dev/mix/tasks/quality/hygiene.ex` (or `mix.exs` function alias) | Mix task / command | batch | `dev/mix/tasks/rendro/catalog/check.ex` | role-match |
| `priv/quality/package-members-v1.json` | expected-artifact manifest | file-I/O | `priv/public_api.json` | role-match |
| `test/scripts/repository_evidence_test.exs` | contract test | file-I/O | `test/quality/baseline_ledger_contract_test.exs` | role-match |
| `test/quality/repository_hygiene_test.exs` | contract test | batch | `test/guardrails/required_checks_contract_test.exs` | role-match |
| `scripts/README.md` | maintainer inventory / documentation | transform | no close tracked inventory | none |
| `mix.exs` | build / command config | batch | current alias and dev-only compilation arrangement | exact modification site |
| `scripts/phoenix_clean_room_proof.exs` | proof script | request-response / file-I/O | its current `with` pipeline | exact modification site |
| `scripts/verify_public_release.exs` | release verifier | request-response / file-I/O | its current strict parser/validator | exact modification site |
| `.github/workflows/release.yml` | CI workflow | event-driven | current advisory job | exact modification site |
| `test/scripts/{phoenix_clean_room_proof,public_release_verifier}_test.exs` | script contract tests | file-I/O | current tests | exact modification site |
| `test/docs_contract/phoenix_newcomer_contract_test.exs` | docs/evidence contract test | file-I/O | current test | exact modification site |
| `test/guardrails/required_checks_contract_test.exs` | CI topology contract test | event-driven | current test | exact modification site |
| `priv/journey_evidence/*` (17 moved/deleted source records) | historical evidence | file-I/O | destination capsule records | exact move |
| `.planning/phases/05-CONTEXT.md` | archived planning artifact | file-I/O | milestone phase directories | exact move (destination `v1.0` archive per history) |
| `.planning/phases/45-{CONTEXT,PATTERNS,RESEARCH,01-PLAN,01-SUMMARY,02-PLAN,02-SUMMARY}.md` | archived planning artifacts | file-I/O | milestone phase directories | exact move (destination `v1.8` archive per history) |
| `scripts/repo_hygiene_check.sh` | deprecated helper | batch | `mix quality.hygiene` replacement | no retained analog; remove unless a documented caller needs a thin wrapper |

## Pattern Assignments

### `dev/rendro/repository_evidence.ex` (service/loader, file-I/O)

**Analogs:** `lib/rendro/public_api/validator.ex`, `lib/rendro/public_api/loader.ex`

Keep this module under `dev/`, not `lib/`: `mix.exs` compiles `dev` only in `:dev` and `:test` (lines 53-57), matching the maintainer-only scope.

**Schema import/load pattern** — `lib/rendro/public_api/validator.ex:1-20`:

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
end
```

**Narrow loader shape** — `lib/rendro/public_api/loader.ex:1-9`:

```elixir
@manifest_path "priv/public_api.json"

@spec load!() :: map()
def load! do
  @manifest_path |> File.read!() |> JSON.decode!()
end
```

**Required adaptation:** return `{:ok, facts}` / `{:error, diagnostic}` rather than blindly raising. Resolve only the capsule `manifest.json`; validate role, schema version, confined relative path, regular-file status, SHA-256, media type, and release/candidate/tag bindings before exposing `public_prerequisite`. Do not let scripts assemble record paths or decode the JSON themselves.

**Path guard to copy** — `dev/rendro/catalog.ex:435-443`:

```elixir
defp validate_safe_path!(path, label) when is_binary(path) do
  case Path.safe_relative(path) do
    {:ok, _safe} -> :ok
    :error -> raise ArgumentError, "unsafe catalog #{label} path rejected: #{inspect(path)}"
  end
end
```

Use the same early validation principle, strengthened by expanding from a fixed capsule root and checking the expanded result remains under that root; reject absolute paths, `..`, symlinks/non-regular files, unknown roles, unsupported versions, and digest mismatch before `JSON.decode`.

### `priv/schemas/release_evidence_*.schema.json` and evidence JSON records (schema/config, file-I/O)

**Analog:** `priv/schemas/public_api.schema.json`

**Schema convention** — `priv/schemas/public_api.schema.json:1-36`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "public_api.schema.json",
  "type": "object",
  "required": ["modules"],
  "properties": {
    "modules": {"type": "object"}
  },
  "additionalProperties": false
}
```

Use draft 2020-12, an explicit `$id`, `required`, enum-bounded role/authority/lane/status values, `additionalProperties: false`, `schema_version: 1`, bounded strings/arrays, and separate `$defs` for the manifest record and provenance object. The capsule manifest is the sole entry point; payload JSON must not duplicate all manifest facts.

**Data formatting convention** — `priv/public_api.json:1-12`:

```json
{
  "modules": {
    "Elixir.Rendro": {
      "functions": ["block/2", "document/1"],
      "tier": "stable",
      "types": ["render_option/0"]
    }
  }
}
```

Use stable, pretty JSON with deterministic order. Preserve source payload facts separately from import metadata (`source_path`, original digest/commit where available, import timestamp/reason, sanitization classification). Treat each imported JSON byte payload, record ID, and meaning as immutable; later interpretation is an appended record with `supersedes`.

The 17 `priv/journey_evidence/*` files are content-preserving source inputs, not templates to keep package-visible. Put the 9 JSON attempt records and 8 Markdown narratives under `evidence/releases/v1.3.4/journey/`, then have `journey/index.json` order them and `manifest.json` index their identity/digest/authority. No existing file provides a full authority-separated capsule analogue.

### `dev/rendro/repository_hygiene.ex`, `dev/mix/tasks/quality/hygiene.ex`, `priv/quality/package-members-v1.json`, and `mix.exs` (service/task/config, batch)

**Analogs:** `dev/rendro/catalog.ex`, `dev/mix/tasks/rendro/catalog/check.ex`, `mix.exs`

**Deterministic aggregation pattern** — `dev/rendro/catalog.ex:860-871`:

```elixir
defp concrete?(value), do: is_binary(value) and byte_size(String.trim(value)) > 0
defp read_rubric_scores, do: "priv/quality/rubric_scores.json" |> File.read!() |> JSON.decode!()

defp encode_manifest(manifest), do: Jason.encode!(manifest, pretty: true)
defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
```

Use pure helpers that return a stable, sorted list of violations. The hygiene service must inspect only: the unpacked Hex artifact, NUL-delimited `git ls-files -z` tracked paths, the reviewed script inventory, and declared operational consumer surfaces. It must never fail on arbitrary untracked/ignored worktree files.

**Mix command success/failure UX** — `dev/mix/tasks/rendro/catalog/check.ex:1-18`:

```elixir
case Rendro.Catalog.check(parse_opts(args)) do
  :ok ->
    Mix.shell().info("Catalog VERIFIED")

  {:error, errors} ->
    shell = Mix.shell()
    Enum.each(errors, &shell.error/1)
    exit({:shutdown, 1})
end
```

Make `mix quality.hygiene` follow this one-command shape with concise deterministic success text and stably ordered diagnostics. Every failure must state offending path, rule, why the boundary matters, and exact next action; do not use color/emoji as the only signal.

**Alias and dev-only placement** — `mix.exs:53-57,79-104`:

```elixir
defp elixirc_paths(:test), do: ["lib", "dev", "test/support"]
defp elixirc_paths(:dev), do: ["lib", "dev"]
defp elixirc_paths(_), do: ["lib"]

"ci.fast": [
  "format --check-formatted",
  "hex.build",
  "compile --warnings-as-errors"
]
```

Add the preferred test environment and the single hygiene command to `ci.fast` using the same implementation local maintainers invoke. `mix hex.build --unpack` (rather than only `package: files`) must produce the inspected member list; compare normalized exact members to `priv/quality/package-members-v1.json`, then separately reject package paths/classes such as `.planning`, `evidence`, internal schemas, tests, scripts, workflow metadata, caches, editor debris, and raw proof artifacts. Keep the intentional `priv/adoption_evidence` package exception narrow and explicit.

### Active release/proof consumers (scripts and workflow, request-response/event-driven)

**Analogs:** `scripts/phoenix_clean_room_proof.exs`, `scripts/verify_public_release.exs`, `.github/workflows/release.yml`

**Fail-closed `with` pipeline and bounded exception conversion** — `scripts/phoenix_clean_room_proof.exs:14-31`:

```elixir
result =
  try do
    with {:ok, options} <- parse_args(args),
         {:ok, prerequisite} <- read_prerequisite(options.prerequisite),
         :ok <- validate_prerequisite(prerequisite) do
      executor.(options, prerequisite)
    else
      {:error, reason} -> failure(reason)
    end
  rescue
    error -> failure({:exception, error.__struct__})
  end
```

Replace `read_prerequisite/1` and the archive-bound default at `scripts/phoenix_clean_room_proof.exs:331-342` with the shared loader. Keep the existing explicit prerequisite override only if it is passed through the same validation contract; the default must be the capsule, not a planning path.

**Strict release verifier pipeline** — `scripts/verify_public_release.exs:32-43`:

```elixir
with {:ok, options} <- parse_args(argv),
     {:ok, candidate} <- candidate_from_record(options.candidate_record),
     :ok <- validate_candidate(candidate),
     :ok <- validate_tag(options.tag),
     {:ok, facts} <- context.collect.(options, candidate),
     :ok <- validate(facts) do
  :ok
else
  {:error, message} -> {:error, message}
end
```

Use the loader's release-identity record instead of an archive Markdown candidate record for operational identity. Retain the bounded parser/validation behavior; release evidence facts must agree on candidate, tag, and version before use.

**Workflow advisory lane contract** — `.github/workflows/release.yml:80-115`:

```yaml
continue-on-error: true
run: |
  set -euo pipefail
  mix run scripts/phoenix_clean_room_proof.exs -- \
    --prerequisite <current-authoritative-path> \
    --root "$PROOF_ROOT" \
    --output "$PROOF_OUTPUT"
```

Retain `continue-on-error`, fresh workflow artifact upload, and the outcome/cleanup assertion. Change the prerequisite to the capsule operational record and scope this job explicitly to `v1.3.4`; it must not run fixed 1.3.4 facts for future semver tags. Workflow output remains expiring advisory transport, not capsule authority.

### Test migrations (test, file-I/O/event-driven)

**Analogs:** `test/quality/baseline_ledger_contract_test.exs`, existing script/docs/guardrail contracts

**Schema plus semantic invariant style** — `test/quality/baseline_ledger_contract_test.exs:21-28,79-94,155-186`:

```elixir
defp valid_snapshot?(snapshot, schema) do
  evidence_items = snapshot["evidence_items"]

  match?({:ok, _}, JSV.validate(snapshot, schema)) and
    Enum.uniq_by(evidence_items, & &1["id"]) == evidence_items
end

schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
assert valid_snapshot?(snapshot, schema)
refute match?({:ok, _}, JSV.validate(mutated, schema))
```

`test/scripts/repository_evidence_test.exs` should use this pattern for good data and fixture mutations: traversal, unknown/malformed role, schema version, digest, digest binding, candidate/tag/release mismatch, duplicate ID, and immutable source facts. Tests should be offline and deterministic.

**Current docs evidence assertions to migrate** — `test/docs_contract/phoenix_newcomer_contract_test.exs:30-65,107-118`:

```elixir
evidence = File.read!("priv/journey_evidence/phoenix_clean_room_1.3.4.json")
transcript = File.read!("priv/journey_evidence/phoenix_clean_room_1.3.4.md")

refute evidence =~ ~r/HEX_API_KEY|HOME|\/Users\/|\"pid\"|\"port\"|%PDF-/
```

Replace direct package-visible journey/archive reads with loader-provided facts and the capsule record/sidecar paths. Preserve the redaction, exact journey identity, success/failed-attempt retention, and advisory-language assertions without exposing internal classifications in newcomer-facing prose.

**Current CI alias/topology contract to update** — `test/guardrails/required_checks_contract_test.exs:152-189`:

```elixir
ci_fast_steps = Keyword.fetch!(aliases, :"ci.fast")
assert advisory_block =~ "scripts/phoenix_clean_room_proof.exs"
assert advisory_block =~ "131-PUBLIC-PREREQUISITE.json"
assert advisory_block =~ "continue-on-error: true"
```

Update exact expected `ci.fast` steps to include `quality.hygiene`; assert the new capsule path, `v1.3.4` guard, and continued advisory separation. `test/quality/repository_hygiene_test.exs` should cover package member diffs, prohibited classes, tracked planning placement (NUL-safe inputs), archive-consumer prohibition, explicit `gsd_tooling` exceptions, and script-inventory coverage.

### Archive moves and `scripts/README.md` (documentation/config, file-I/O)

**Analog:** canonical existing milestone phase directories under `.planning/milestones/*-phases/<NN>-<slug>/`.

There is no current tracked helper inventory to copy. Create the inventory as reviewed table data (executable path, purpose, stable role owner, supported invocation, inputs/outputs, evidence authority lane, current callers, and review/removal trigger). Do not retain an entry merely because it once supported a phase.

Move the loose Phase 5 and 45 artifacts with Git-recognizable renames into the owner locations established by archive/history research (`v1.0` for Phase 5 and `v1.8` for Phase 45). Do not leave redirect stubs or duplicate authority. If an exact v1.0/v1.8 destination hierarchy is not provable during implementation, use one clearly labeled legacy archive and record the uncertainty rather than fabricating provenance.

## Shared Patterns

### Dev/test-only control-plane code

**Sources:** `mix.exs:53-57`, `mix.exs:59-76`  
**Apply to:** repository evidence loader, hygiene service, task, and their tests

Place maintainer-only modules in `dev/`; JSV is already `only: [:dev, :test], runtime: false`. Do not add a runtime `lib/` API, Phoenix, Ecto, hosted service, or new quality stack.

### Fail-closed validation and diagnostics

**Sources:** `lib/rendro/public_api/validator.ex:6-20`, `scripts/phoenix_clean_room_proof.exs:14-31`  
**Apply to:** every capsule consumer and hygiene gate

Validate before returning facts. Normalize schema errors, preserve bounded failures, and identify what/where/why/next action. Do not fall back to archive paths or silently accept malformed evidence.

### Integrity and stable data ordering

**Sources:** `dev/rendro/catalog.ex:867-871`, `test/quality/baseline_ledger_contract_test.exs:21-28`  
**Apply to:** manifest records, journey index, package member list, and hygiene diagnostics

Use lower-case SHA-256 hex, stable IDs, `Enum.sort`-equivalent deterministic ordering, and explicit uniqueness checks. A digest detects tampering but does not substitute for Git history/protected branches/release tags as the retention authority.

### Deterministic versus advisory evidence lanes

**Source:** `.github/workflows/release.yml:80-115`  
**Apply to:** workflow, documentation, tests, and release consumer migration

Path/schema/digest/package/placement checks are deterministic. Retained clean-room success is historical advisory evidence. Fresh workflow artifacts are expiring transport. No deterministic test should require GitHub/Hex access or re-run a retained failed attempt.

## No Analog Found

| File(s) | Role | Data Flow | Reason |
|---|---|---|---|
| `evidence/releases/v1.3.4/manifest.json` and authority-separated capsule records | internal evidence capsule | file-I/O | Existing manifests are not authority-separated release dossiers with provenance/digest/path confinement. |
| `scripts/README.md` | helper inventory | transform | No tracked scripts inventory exists. |
| `priv/quality/package-members-v1.json` | built-artifact membership contract | batch/file-I/O | Existing `mix.exs` allowlist describes intended inputs but no current exact unpacked artifact manifest exists. |
| `dev/rendro/repository_hygiene.ex` | repository hygiene policy | batch | The former shell script is intentionally the wrong broad-worktree model; new code should follow the narrow deterministic contract in RESEARCH.md. |

## Metadata

**Analog search scope:** `lib/rendro/public_api`, `dev/rendro`, `dev/mix/tasks`, `priv/schemas`, `priv/quality`, `priv/journey_evidence`, `scripts`, `test/{quality,scripts,docs_contract,guardrails}`, `.github/workflows`, `mix.exs`, `.planning` archive paths  
**Files scanned:** 31 focused source/config/test files plus capsule/journey and planning-path inventories  
**Pattern extraction date:** 2026-08-26

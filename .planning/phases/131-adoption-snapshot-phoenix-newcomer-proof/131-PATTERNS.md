# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof - Pattern Map

**Mapped:** 2026-08-21  
**Files analyzed:** 13 planned create/modify targets (plus ephemeral generated-app templates)  
**Analogs found:** 12 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `ADOPTION.md` | documentation / decision index | transform | `ADOPTION.md` + `test/docs_contract/adoption_claims_test.exs` | exact-extension |
| `priv/adoption_evidence/2026-08-21.json` | evidence model | transform | `priv/viewer_evidence/_template.md` / `priv/support_matrix.json` | partial |
| `scripts/adoption_snapshot.exs` | utility / one-shot observer | request-response | `scripts/release_preflight_proof.exs` | role-match |
| `test/docs_contract/adoption_evidence_contract_test.exs` | test / contract | transform | `test/docs_contract/adoption_claims_test.exs` | exact |
| `README.md` | documentation / discovery route | transform | `guides/presets.md` | role-match |
| `guides/presets.md` | documentation / canonical snippet host | transform | `lib/rendro/theme/snippet.ex` + configurator contract | exact seam |
| `mix.exs` | package/release config | batch | `test/docs_contract/preset_fonts_package_contract_test.exs` | exact-extension |
| `CHANGELOG.md` | release documentation | transform | existing release version/tag parity in `mix.exs` and `.github/workflows/release.yml` | partial |
| `scripts/phoenix_clean_room_proof.exs` | utility / isolated harness | batch + request-response | `scripts/release_preflight_proof.exs` | role-match |
| `test/scripts/phoenix_clean_room_proof_test.exs` | test / harness unit | batch | `test/scripts/release_preflight_proof_test.exs` | exact |
| `test/docs_contract/phoenix_newcomer_contract_test.exs` | test / docs contract | transform | `test/docs_contract/configurator_phase_gate_test.exs` | exact |
| `priv/journey_evidence/phoenix_clean_room_1.3.0.json` | advisory evidence model | transform | viewer evidence records / JSON contract tests | partial |
| `priv/journey_evidence/phoenix_clean_room_1.3.0.md` | advisory transcript | transform | `priv/viewer_evidence/_template.md` | role-match |
| Generated `lib/<app>/invoice_document.ex`, controller, router, ConnCase and controller test | consumer module/controller/route/test | request-response | `examples/phoenix_example` | exact-template |

`examples/phoenix_example` remains only the source template: its `{:rendro, path: "../.."}` dependency at `examples/phoenix_example/mix.exs:31` disqualifies it as JOURNEY-01 evidence.

## Pattern Assignments

### `ADOPTION.md`, `priv/adoption_evidence/2026-08-21.json`, and `test/docs_contract/adoption_evidence_contract_test.exs`

**Analogs:** `ADOPTION.md`; `test/docs_contract/adoption_claims_test.exs`.

**Existing public threshold source** (`ADOPTION.md:20-31`):

```markdown
The gate is currently **blocked** until all three threshold families are met in the same review window: demand, downloads, and contributor signal.

| Demand | Blocked | 6 qualifying text-shaping signals ... |
| Downloads | Blocked | Since discovery baseline, Hex downloads.all increases by at least 1,500 ... |
| Contributor | Blocked | At least 1 merged, non-maintainer PR ... |
```

**Offline contract style** (`test/docs_contract/adoption_claims_test.exs:46-63,66-72`):

```elixir
adoption = File.read!(@adoption_path)
assert adoption =~ "# Adoption Signals"

for sentence <- @threshold_sentences do
  assert adoption =~ sentence
end
```

Copy this direct-parse, explicit-assertion style. The new contract should `JSON.decode!/1` the dated sidecar and assert retrieval (`AVAILABLE | UNAVAILABLE`) separately from decision (`HOLD | ACCUMULATING | TRIGGER`), reject `raw` numeric values for unavailable sources, and compute the composite as the minimum of the three family decisions. Do not fetch Hex or GitHub in this test.

**Existing bounded-observation precedent** (`test/docs_contract/viewer_evidence_claims_test.exs:1-20,112-119`): parse committed evidence, reject incomplete/legacy states, and keep public-guide references synchronized. Apply that same approach to a typed sidecar linked by `ADOPTION.md`, not prose-derived arithmetic.

### `scripts/adoption_snapshot.exs`

**Analog:** `scripts/release_preflight_proof.exs`.

**Argument and fail-closed pattern** (`scripts/release_preflight_proof.exs:29-80`):

```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: [...])

cond do
  invalid != [] -> {:error, "invalid options: ..."}
  ... -> {:ok, %{...}}
end
```

**Injectable command boundary** (`scripts/release_preflight_proof.exs:132-139,176-181`):

```elixir
defp run_command(context, command, args, opts \\ []) do
  print_command(command, args, opts)
  context.runner.(command, args, Keyword.put(opts, :stderr_to_stdout, true))
end
```

Make parsing, source-result normalization, qualification, redaction, and JSON construction public/pure enough for the script unit test. Put live `curl`/`gh` calls behind a runner; preserve only allowlisted metadata/digests. A failed source must render `UNAVAILABLE`, not synthesize zero or pass as a trigger.

### `README.md` and `guides/presets.md`

**Analogs:** `guides/presets.md`; `lib/rendro/theme/snippet.ex`; `test/docs_contract/configurator_phase_gate_test.exs`.

**Canonical formatter-owned source** (`lib/rendro/theme/snippet.ex:54-73`):

```elixir
preset = :swiss

theme =
  Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

document =
  invoice
  |> Rendro.Recipes.Invoice.document(theme: theme)
  |> Rendro.Theme.Presets.register_fonts(preset)
```

**Existing docs seam** (`guides/presets.md:6-24`): it encloses exactly that selection in `# rendro-theme-snippet:start/end` markers and states that it is formatter-owned.

**Generated-index invariant** (`test/docs_contract/configurator_phase_gate_test.exs:33-68`):

```elixir
assert File.read!(@index_path) == Snippet.index_json()
...
assert record["snippet"] ==
         Snippet.usage_snippet(record["family"], record["preset"],
           record["accent"], record["mode"])
```

README should add only the short `install -> select -> customize -> serve -> verify` route, use `{:rendro, "~> 1.3"}`, and link to the authoritative preset/configurator seam. The generated-app template may consume `Snippet.module_source/4` or the exact generated formatter output; do not maintain another handwritten theme variant.

### `mix.exs`, `CHANGELOG.md`, and release checkpoint

**Analogs:** `mix.exs`; `.github/workflows/release.yml`; `scripts/release_preflight_proof.exs`.

**Version/package/docs coupling** (`mix.exs:4,140-166,193-224`):

```elixir
@version "1.0.0"
...
files: ~w(
  ...
  ADOPTION.md
  ...
)
...
source_ref: "v#{@version}"
extras: ["README.md", "ADOPTION.md", "CHANGELOG.md", ...]
```

Add the adoption sidecar directory to the Hex allowlist because the already-shipped `ADOPTION.md` links it. Add documentation extras only where the new journey transcript must be public on HexDocs; do not add Phoenix as a root dependency.

**Existing tag/publish boundary** (`.github/workflows/release.yml:31-47,50-70`):

```yaml
- name: Verify Version Match
  run: |
    MIX_VERSION=$(grep '@version' mix.exs ...)
    TAG_VERSION=${GITHUB_REF_NAME#v}
...
- name: Run Release Preflight
  run: mix release.preflight
- name: Publish to Hex (Dry Run)
  run: mix hex.publish --dry-run
```

Plan a human checkpoint after a passing preflight/dry run and immediately before the externally visible `v1.3.0` tag invokes this workflow. Do not introduce a new publishing command or a second path in the newcomer harness.

### `scripts/phoenix_clean_room_proof.exs` and `test/scripts/phoenix_clean_room_proof_test.exs`

**Analogs:** `scripts/release_preflight_proof.exs`; `test/scripts/release_preflight_proof_test.exs`; `test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs`.

**Isolated state and cleanup** (`scripts/release_preflight_proof.exs:84-126,207-230`): create an isolated target, execute explicit commands, then clean it on both success and failure. Its test injects a command runner rather than invoking tools (`test/scripts/release_preflight_proof_test.exs:35-73,103-193`).

**Fresh-consumer root pattern** (`test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs:7-24`):

```elixir
tmp = Path.join(System.tmp_dir!(), "rendro-fresh-consumer-" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false))
File.mkdir_p!(tmp)

try do
  ...
after
  File.rm_rf!(tmp)
end
```

Use a similarly unique system-temporary run root, but never repurpose `HOME`. The harness must unset `PHX_NEW_CACHE_DIR`, `MIX_DEPS_PATH`, `MIX_BUILD_PATH`, and `MIX_ARCHIVES`, provide fresh run-scoped Mix/Hex/Rebar paths, and audit source declarations before and after `deps.get`. Keep process startup/readiness/loopback logic bounded by timeout and `after` cleanup. Emit only a redacted advisory manifest and transcript; never retain app/cache/PID/port/PDF body.

### `test/docs_contract/phoenix_newcomer_contract_test.exs`, journey manifest, and transcript

**Analogs:** `test/docs_contract/configurator_phase_gate_test.exs`; `test/docs_contract/preset_fonts_package_contract_test.exs`.

**Static/public seam checks** (`test/docs_contract/configurator_phase_gate_test.exs:10-30,70-85`): read committed paths, assert concrete allowed references, and `refute` disallowed technologies/strings. Apply this to README, guide markers, harness command template, exact `1.3.0` evidence pin, no `path:`/`git:` sources, and manifest redaction rules.

**Hex package contents check** (`test/docs_contract/preset_fonts_package_contract_test.exs:12-24`):

```elixir
tarball = Rendro.Test.HexBuildCache.tarball_path!()
{contents, 0} = System.cmd("sh", ["-c", "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"])
assert "NOTICE" in String.split(contents, "\\n", trim: true)
```

Follow it to assert the `priv/adoption_evidence/` sidecar ships. The journey files need structure-only checks: advisory lane label, declared/resolved identities, lock hash, source-leakage audit, ConnCase and loopback response facts, repair list, and no forbidden raw payload/path/PID/token fields.

### Ephemeral generated Phoenix application templates

**Analogs:** `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex`, `router.ex`, `test/support/conn_case.ex`, and controller test.

**Thin controller** (`pdf_controller.ex:47-52`):

```elixir
def download(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)
  RendroPhoenix.render_pdf(conn, doc, "example.pdf")
end
```

For this phase improve the template boundary: `CleanRoom.InvoiceDocument.build/0` owns in-memory invoice mapping, selected formatter-derived theme, recipe, and `register_fonts`; controller only calls `Rendro.Adapters.Phoenix.render_pdf(conn, CleanRoom.InvoiceDocument.build(), "invoice.pdf")`.

**Route and ConnCase patterns** (`router.ex:17-31`; `test/support/conn_case.ex:9-23`): use a generated app’s `:api` pipeline, a single `get "/invoice.pdf", PDFController, :download`, `Phoenix.ConnTest`, `Plug.Conn`, and `Phoenix.ConnTest.build_conn/0`.

**Response assertions** (`pdf_controller_test.exs:49-66`):

```elixir
conn = get(conn, "/download")
assert conn.status == 200
assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
assert is_binary(conn.resp_body)
assert byte_size(conn.resp_body) > 0
assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
```

Add the exact attachment header assertion from `test/rendro/adapters/phoenix_test.exs:21-35`. The actual loopback check must assert the same contract, but its result is advisory external/local evidence rather than deterministic CI authority.

## Shared Patterns

### Advisory versus deterministic evidence

**Sources:** `ADOPTION.md:7-13,88-108`; `scripts/verify_docs.exs:1-64`.

Existing docs contracts run explicit offline lanes with `System.cmd("mix", args, stderr_to_stdout: true)`. Phase 131 must preserve that boundary: deterministic tests validate committed schema/templates/claims; one-shot Hex/GitHub/public-package/server observations are explicitly labeled `advisory_external_evidence` and are never run by default CI.

### Optional Phoenix boundary

**Source:** `lib/rendro/adapters/phoenix.ex:1-14,16-39,66-92`.

The core adapter is protected with `Code.ensure_loaded?(Plug.Conn) and Code.ensure_loaded?(Phoenix)`, calls `Rendro.render/1`, sends the response, and translates `Rendro.Error`. Consumer templates call its public API; do not recreate headers, `send_resp`, or error serialization in controllers, docs, or scripts.

### Release and package integrity

**Sources:** `.github/workflows/release.yml:12-70`; `mix.exs:140-224`; `scripts/release_preflight_proof.exs:84-126`.

Version, tag, package allowlist, docs `source_ref`, dry run, protected publish environment, and post-publication inspection are one system. The pre-publish checkpoint is a plan/execution gate—not an automated script branch—and must precede the irreversible release action.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `priv/adoption_evidence/2026-08-21.json` | evidence model | transform | No existing dedicated adoption sidecar schema; use the bounded viewer-evidence discipline plus Phase 131’s locked retrieval/decision enums. |

## Metadata

**Analog search scope:** `mix.exs`, `.github/workflows`, `scripts`, `test/docs_contract`, `test/scripts`, `lib/rendro`, `guides`, `README.md`, and `examples/phoenix_example`  
**Files scanned:** 20 focused source/test/configuration files  
**Pattern extraction date:** 2026-08-21

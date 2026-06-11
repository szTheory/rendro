# Phase 87 Pattern Mapping: Comparison Page & Livebook

**Role:** gsd-pattern-mapper (inline Codex execution)  
**Phase:** 87 - Comparison Page & Livebook  
**Output:** `.planning/phases/87-comparison-page-livebook/87-PATTERNS.md`  
**Inputs:** `87-CONTEXT.md`, `87-RESEARCH.md`, `87-UI-SPEC.md`, current codebase

## Executive Summary

Phase 87 should mirror Phase 86's proof pipeline:

- one module owns structured manifest loading, generated Markdown blocks, static
  contract errors, and advisory checks;
- required docs-contract tests validate static truth, generated block freshness,
  citation binding, package inclusion, and overclaim guards;
- noisy external work stays advisory and graph-disconnected;
- public docs are buyer-guide surfaces with proof citations, not marketing hero
  pages or winner charts.

The most important analog is `lib/rendro/launch_artifacts.ex`. Build
`Rendro.Comparison` with the same split between required/static validation and
advisory external-tool execution.

## Likely File Map

| File | Role | Data flow | Closest analog | Pattern to follow |
|---|---|---|---|---|
| `lib/rendro/comparison.ex` | Comparison manifest/generator/checker core | `bench/results/comparison.json` + raw files -> generated guide blocks -> static contract errors | `lib/rendro/launch_artifacts.ex` | Keep one explicit workflow. Separate static contract from advisory benchmark reruns. Use actionable drift messages. |
| `lib/mix/tasks/rendro/comparison/gen.ex` | Write task | pins/results/raw artifacts -> manifest -> generated guide blocks | `lib/mix/tasks/rendro/launch_artifacts/gen.ex` | Thin `Mix.Task` wrapper, parse args, start app, non-zero exit on failure. |
| `lib/mix/tasks/rendro/comparison/check.ex` | Check task | manifest/raw/docs -> static/advisory checks | `lib/mix/tasks/rendro/launch_artifacts/check.ex` | No repo writes unless explicit generation task; print every drift error. |
| `bench/comparison/**` | Benchmark harness and fixtures | normalized invoice data -> per-comparator render commands -> raw artifacts | `scripts/release_preflight_proof.exs`, `Rendro.Adapters.Pdfium` command-runner pattern | Use list-form commands where in Elixir. Record exact commands, environment, repetitions, median, p95. |
| `bench/results/comparison.json` | Public benchmark truth manifest | run metadata + comparators + results + claims -> docs/tests | `assets/rendro/artifacts.json` | Stable JSON, schema version, generated_by, raw SHA-256s, public claims. |
| `bench/results/raw/*.json` | Auditable raw benchmark evidence | runner output -> manifest raw refs | `priv/raster_refs/**`, `assets/rendro/artifacts.json` hashes | Every raw artifact referenced by path and SHA-256 in manifest. |
| `guides/comparison.md` | HexDocs buyer guide | generated fit/results/evidence blocks + human interpretation | `guides/recipes.md` generated gallery block | Use generated block markers for measured content; hand-author intro/interpretation. |
| `guides/livebook/first_invoice.livemd` | First-success tutorial | fixed invoice data -> `Rendro.Recipes.Invoice.document/1` -> deterministic PDF -> Kino preview/download | README recipe examples, `Rendro.Recipes.Invoice` | Keep notebook simple for `Livebook.live_markdown_to_elixir/1`; no benchmark cells. |
| `lib/mix/tasks/rendro/livebook/check.ex` | Advisory notebook executor | `.livemd` -> `Livebook.live_markdown_to_elixir/1` -> script execution | `lib/mix/tasks/docs.contract.ex`, `lib/mix/tasks/verify.ex` | Thin task, clear errors, no Livebook server, local checkout mode via env. |
| `test/docs_contract/comparison_claims_test.exs` | Required docs contract | manifest/docs/package/CI -> assertions | `test/docs_contract/launch_artifacts_claims_test.exs` | Manifest shape, generated blocks, citations, raw hashes, package inclusion, overclaim guards, lane registration. |
| `test/rendro/comparison_test.exs` | Pure module/unit tests | mutated manifests -> contract error assertions | `test/rendro/launch_artifacts_test.exs` | Test static helpers and generated block helpers without external runtimes. |
| `test/mix/tasks/rendro_livebook_check_test.exs` | Task seam tests | fake runner/converter -> task success/failure | `test/mix/tasks/docs_contract_task_test.exs`, `test/mix/tasks/verify_test.exs` | Inject command runner/converter via app env where possible. |
| `scripts/verify_docs.exs` | Required docs-contract lane registry | lane list -> `mix test ...` | existing docs-contract lanes | Add "Comparison claims lane"; update lane count tests. |
| `mix.exs` | ExDoc and package contract | extras/groups/package files/deps | current `docs/0`, Phase 86 package tests | Add comparison guide and Livebook extra; add dev/test-only Livebook/Kino only if needed. |
| `README.md` | Public entry point | guide links and compact Livebook affordance | current Guides section | Add comparison/Livebook links without hero layout. |
| `.github/workflows/ci.yml` | Advisory execution | benchmark/livebook advisory jobs | `raster-advisory`, `example-phoenix` | New advisory jobs have no `needs:` and remain absent from required contexts. |
| `priv/guardrails/required_status_checks.json` | Required/advisory registry | advisory context metadata -> guardrail tests | existing `raster-advisory` entry | Register benchmark/livebook advisory contexts only under `advisory_contexts`. |
| `test/guardrails/required_checks_contract_test.exs` | CI isolation tests | CI job blocks + guardrail JSON -> negative proof | current raster-advisory assertions | Scope scans to job blocks; prove required `test` job stays external-tool free. |

## Manifest Pattern

Follow `assets/rendro/artifacts.json` style:

- `schema_version`
- `generated_by`
- `run`
- `scenario`
- `comparators`
- `results`
- `claims`

Required comparator IDs:

- `rendro`
- `chromic_pdf`
- `chromic_pdf_warm_pool`
- `pdf_generator`
- `typst_cli`

Required metric IDs:

- `cold_start_ms`
- `rss_mb`
- `container_image_mb`
- `dependency_count`

Recommended claim shape:

```json
{
  "id": "CMP-COLD-START-001",
  "public": true,
  "text": "In the pinned invoice harness, Rendro had the lowest median cold-start time among the measured options.",
  "scope": "Pinned Linux container, invoice_v1 fixture; not a general performance promise.",
  "evidence": [{"metric": "cold_start_ms", "operator": "min"}]
}
```

Pattern rules:

- Every raw artifact path has `raw_sha256`.
- Every public claim has a stable `CMP-*` ID.
- Every claim cited in docs must exist in the manifest.
- Every public manifest claim must appear in the guide.
- Manifest text is allowed to be public only if docs-contract tests bind it to
  the guide.

## Generated Guide Block Pattern

Use marker-pair extraction like `Rendro.LaunchArtifacts.readme_markers/0` and
`recipes_markers/0`.

Expected helper shape:

```elixir
@comparison_path "guides/comparison.md"
@manifest_path "bench/results/comparison.json"
@results_start "<!-- rendro-comparison-results-start -->"
@results_end "<!-- rendro-comparison-results-end -->"

def results_markers, do: {@results_start, @results_end}
def read_manifest!, do: @manifest_path |> File.read!() |> JSON.decode!()
def results_block(manifest), do: ...
def static_contract_errors(), do: ...
```

Generated block checks should mirror Phase 86:

- extract block with regex from `guides/comparison.md`;
- compare to generator output;
- fail with `guides/comparison.md comparison block is stale; run mix rendro.comparison.gen`.

## Docs-Contract Pattern

Use `test/docs_contract/launch_artifacts_claims_test.exs` as the direct analog.

Required assertions:

- `Rendro.Comparison.static_contract_errors() == []`.
- Manifest comparator IDs include `rendro`, `chromic_pdf`, `pdf_generator`,
  and `typst_cli`.
- Manifest includes both cold and warm ChromicPDF posture.
- Raw artifact SHA-256 values match committed files.
- Required metadata fields exist: tool/library versions, Docker image digest,
  OS, arch, CPU, memory limit, fonts/assets, input fixture, commands,
  repetitions, median, p95.
- Generated guide blocks equal `Rendro.Comparison` helper output.
- Every `[bench:CMP-*]` citation resolves.
- Every public claim appears in guide copy.
- Forbidden uncited comparative phrases fail.
- Required caveats appear: arbitrary HTML/CSS, complex scripts/RTL bounded by
  support matrix, no universal winner.
- ExDoc extras and Hex package include the guide and notebook.
- `scripts/verify_docs.exs` includes the comparison claims lane.

## Benchmark Harness Pattern

Use Elixir scripts/tasks for orchestration, with external tools treated as
advisory.

Recommended runner responsibilities:

- build or invoke one normalized invoice fixture for each comparator;
- record child-process tree RSS, not only parent process memory;
- record cold-start time separately from warm/pool behavior;
- capture command stdout/stderr in raw artifacts;
- compute median and p95 from repeated samples;
- write raw artifacts first, then write summary manifest with SHA-256 refs.

Implementation cautions:

- Do not include dependency download/build time in render metrics.
- Do record runtime container image size and dependency/runtime count.
- Pin versions in `bench/comparison/pins.json` or manifest metadata.
- Avoid shell interpolation for generated commands in Elixir code.
- If a shell wrapper is required, keep inputs fixed and documented.

## Livebook Execution Pattern

Use a task with an injectable seam, following `Docs.Contract` and `Verify` task
tests:

```elixir
converter = Application.get_env(:rendro, :livebook_converter, &Livebook.live_markdown_to_elixir/1)
runner = Application.get_env(:rendro, :livebook_command_runner, &System.cmd/3)
```

Expected task behavior:

- read `guides/livebook/first_invoice.livemd`;
- convert via `Livebook.live_markdown_to_elixir/1`;
- write generated script to a temp file;
- run `elixir`/`mix run` with `RENDRO_LIVEBOOK_LOCAL=1`;
- fail with an explicit message if conversion or execution fails.

Notebook constraints:

- no cross-cell macros;
- no branching sections required for success path;
- no benchmark cells;
- no Phoenix runtime startup;
- Kino dependencies live in notebook `Mix.install`, not library runtime deps.

## CI Guardrail Pattern

Extend `test/guardrails/required_checks_contract_test.exs`.

Add assertions that:

- `comparison-advisory` and/or `livebook-advisory` exist in
  `advisory_contexts`;
- neither appears in `required_contexts`;
- advisory job blocks have no `needs:` key;
- required `test:` job continues to run only `mix ci`;
- required `test:` job does not install Chrome, wkhtmltopdf, Typst, Livebook,
  Kino, or run benchmark/notebook tasks.

Use the existing `ci_job_block!/2` helper pattern to avoid false positives from
legitimate advisory jobs.

## Package/ExDoc Pattern

Current `mix.exs` package allowlist includes `guides` and `assets/rendro`. If
`bench/results/**` must ship with HexDocs/package, add either:

- a specific package path such as `bench/results`, or
- generated blocks in docs that contain all public evidence while raw artifacts
  stay repo-only.

The docs contract must match the choice. If the guide cites raw artifact paths,
package tests should prove those cited artifacts are included or the guide
should explicitly describe them as repository-only.

ExDoc extras:

- add `guides/comparison.md`;
- add `guides/livebook/first_invoice.livemd`;
- group under `Evaluation` or similar.

## Anti-Patterns

- Adding `livebook` or `kino` as runtime deps.
- Putting benchmark reruns into `mix ci`.
- Publishing placeholder benchmark numbers in final guide copy.
- Generating the entire comparison guide from JSON.
- Using a single "winner" badge or total score.
- Measuring only parent RSS.
- Letting Livebook cells rot without advisory execution.
- Hand-editing generated result blocks.


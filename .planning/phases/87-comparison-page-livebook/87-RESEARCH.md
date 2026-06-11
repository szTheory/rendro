# Phase 87 Research: Comparison Page & Livebook

**Date:** 2026-06-11
**Role:** gsd-phase-researcher (inline Codex execution)
**Question:** What do I need to know to PLAN this phase well?
**Requirements:** CMP-01, CMP-02, CMP-03
**Confidence:** HIGH

## Executive Summary

Phase 87 should be planned as a proof-and-adoption phase, not as a rendering
feature phase. The core design is already locked in `87-CONTEXT.md`: a
dual-track benchmark, a JSON benchmark-results manifest with raw artifact
hashes, a HexDocs comparison guide whose public claims cite manifest claims,
and one CI-executed Livebook tutorial.

The highest-risk planning mistakes are:

- publishing a blended winner chart instead of a job-fit guide;
- measuring only parent processes while ignoring Chrome, Ghostscript,
  wkhtmltopdf, Typst, and other child processes;
- letting comparative guide copy escape the checked-in manifest;
- adding benchmark reruns or Livebook execution to required `mix ci`;
- adding Livebook, Kino, Chrome, wkhtmltopdf, Typst, or benchmark tooling as
  runtime dependencies of the `rendro` library.

The strongest local pattern is Phase 86's `Rendro.LaunchArtifacts`: structured
JSON manifest, generated Markdown blocks, static docs-contract checks,
advisory external-tool checks, and explicit package inclusion tests. Phase 87
should mirror that shape with a new comparison/benchmark module and docs
contract rather than introducing a second proof idiom.

## Inputs Read

- `AGENTS.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/87-comparison-page-livebook/87-CONTEXT.md`
- `.planning/phases/87-comparison-page-livebook/87-DISCUSSION-LOG.md`
- `.planning/phases/83-claim-accuracy-shaping-hygiene/83-CONTEXT.md`
- `.planning/phases/86-self-proving-launch-artifacts/86-CONTEXT.md`
- `.planning/phases/86-self-proving-launch-artifacts/86-VERIFICATION.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `.planning/research/STACK.md`
- `mix.exs`
- `.github/workflows/ci.yml`
- `priv/guardrails/required_status_checks.json`
- `scripts/verify_docs.exs`
- `lib/rendro/launch_artifacts.ex`
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex`
- `lib/mix/tasks/rendro/launch_artifacts/check.ex`
- `test/docs_contract/launch_artifacts_claims_test.exs`
- `test/docs_contract/raster_claims_test.exs`
- `test/guardrails/required_checks_contract_test.exs`
- `README.md`
- `guides/recipes.md`
- `lib/rendro/recipes/*.ex`
- Current upstream docs for ChromicPDF, pdf_generator, Livebook, Kino, ExDoc,
  and Typst.

## Upstream Facts To Preserve

- ChromicPDF v1.17.1 is Chrome/Ghostscript-based, runs as a supervised
  process, supports session pools, exposes warm/session behavior, and documents
  browser security/deployment considerations. Plan both a cold-start row and a
  warm pooled row.
  Source: https://chromic-pdf.hexdocs.pm/ChromicPDF.html
- pdf_generator v0.6.2 wraps wkhtmltopdf or chrome-headless, with pdftk as an
  optional encryption helper. Treat it as the legacy HTML-to-PDF comparison
  point, not as a modern supervised Elixir-native engine.
  Source: https://pdf-generator.hexdocs.pm/PdfGenerator.html
- Livebook v0.19.8 exposes `Livebook.live_markdown_to_elixir/1`, which converts
  Live Markdown to Elixir source and has limitations around cross-cell macro
  definitions and branching sections. Keep the tutorial simple enough for this
  conversion path.
  Source: https://livebook.hexdocs.pm/Livebook.html
- Kino v0.19.0 has `Kino.HTML.new/1` for rendering HTML and
  `Kino.Download.new/2` for download buttons. This supports a base64 PDF iframe
  preview and lazy PDF download without starting a Livebook server in CI.
  Sources: https://kino.hexdocs.pm/Kino.HTML.html and
  https://kino.hexdocs.pm/Kino.Download.html
- ExDoc has supported "Run in Livebook" badges for `.livemd` files in `:extras`
  since v0.25.4. The current project already depends on ExDoc `~> 0.40` in
  dev/test, so registering the notebook as an extra is the right path.
  Source: https://ex-doc.hexdocs.pm/changelog.html
- Typst's own automated-generation guidance uses `typst compile` with
  `--input` values surfaced via `sys.inputs`; `sys.inputs` values are strings.
  Use a native `.typ` template in the idiomatic track and keep Typst quantitative
  comparisons pinned to the same invoice/statement fixture.
  Sources: https://typst.app/docs/reference/foundations/sys/ and
  https://typst.app/blog/2025/automated-generation/

## Requirement Interpretation

### CMP-01

The benchmark harness must be checked in and reproducible. It must measure:

- cold start;
- memory/RSS of whole process trees;
- runtime container image size;
- dependency/runtime count;
- pinned versions and environment metadata.

The benchmark should use two tracks:

- Normalized track: one realistic invoice/statement workload implemented for
  Rendro, ChromicPDF, pdf_generator, and Typst-CLI. This is the only source for
  headline quantitative claims.
- Idiomatic track: per-tool setup, template shape, operational model, failure
  modes, and "when this tool wins" guidance. This track is non-ranking.

The likely file set:

- `bench/comparison/fixtures/invoice_data.json`
- `bench/comparison/fixtures/invoice_rendro.exs`
- `bench/comparison/fixtures/invoice_chromic_pdf.html.eex`
- `bench/comparison/fixtures/invoice_pdf_generator.html.eex`
- `bench/comparison/fixtures/invoice_typst.typ`
- `bench/comparison/pins.json`
- `bench/comparison/run.exs` or a Mix task
- `bench/results/comparison.json`
- `bench/results/raw/*.json`

### CMP-02

The guide should be `guides/comparison.md`, titled "Generating PDFs in Elixir
without Chrome". It should be a decision guide, not a takedown page.

Required guide sections from context:

- `The Short Version`
- `Choose By Job`
- `Measured Operational Tradeoffs`
- `Where HTML/CSS Renderers Still Win`
- `Text, Fonts, and Complex Scripts`
- `Reproduce These Numbers`
- `Try Rendro In Livebook`

The comparison proof should live in code analogous to `Rendro.LaunchArtifacts`:

- load `bench/results/comparison.json`;
- validate manifest shape;
- validate raw artifact SHA-256s;
- generate measured result blocks for the guide;
- expose static contract errors safe for required CI;
- expose advisory checks for optional benchmark reruns, if any.

The docs-contract test should fail if:

- a `[bench:CMP-*]` citation in `guides/comparison.md` does not resolve to the
  manifest;
- a public manifest claim marked for docs is absent from the guide;
- a measured/generated block has drifted;
- raw artifact hashes do not match committed raw files;
- pins or environment metadata are missing;
- comparative phrases such as `faster`, `smaller`, `lower RSS`, `fewer
  dependencies`, `lighter`, or `no Chrome runtime` appear in uncited
  comparative contexts;
- guide copy implies Rendro renders arbitrary HTML/CSS, works everywhere,
  supports full complex scripts/RTL, or is a universal replacement.

### CMP-03

The notebook should be one canonical tutorial, likely
`guides/livebook/first_invoice.livemd`.

The notebook flow:

1. `Mix.install` published dependencies by default.
2. Use `RENDRO_LIVEBOOK_LOCAL=1` to run against the checkout in advisory CI.
3. Define fixed invoice data.
4. Build `Rendro.Recipes.Invoice.document/1`.
5. Render with deterministic options.
6. Assert `%PDF-`, byte size, and SHA-256.
7. Preview via `Kino.HTML.new/1` and a base64 `data:application/pdf` iframe or
   embed.
8. Provide `Kino.Download.new(fn -> pdf end, filename: "rendro-invoice.pdf")`.
9. End with a schematic Phoenix controller handoff and links to
   `guides/recipes.md`, `guides/comparison.md`, and `assets/rendro/manual.pdf`.

The advisory execution path should avoid launching a Livebook server. Use a
script or Mix task that:

- reads the `.livemd`;
- calls `Livebook.live_markdown_to_elixir/1`;
- writes or evaluates the generated script in a temp dir;
- runs with `RENDRO_LIVEBOOK_LOCAL=1`;
- asserts the script exits 0 and produces the expected PDF proof output.

## Local Architecture Map

### Reuse Directly

- `Rendro.LaunchArtifacts` demonstrates manifest-backed generation, static
  contract checks, generated docs blocks, and advisory external-tool checks.
- `scripts/verify_docs.exs` is the canonical registry for required docs-contract
  lanes.
- `test/docs_contract/launch_artifacts_claims_test.exs` is the best template for
  manifest shape, generated-block equality, package inclusion, and overclaim
  guard tests.
- `test/guardrails/required_checks_contract_test.exs` already scopes CI job
  block checks and should be extended for benchmark/livebook advisory contexts.
- `.github/workflows/ci.yml` already has graph-disconnected advisory jobs
  (`example-phoenix`, `raster-advisory`); add Phase 87 advisory jobs in that
  style.
- `mix.exs` already includes `guides` and `assets/rendro` in the Hex package
  files and configures ExDoc extras/groups.
- `Rendro.Recipes.Invoice.document/1` is the Livebook first-success recipe and
  normalized benchmark Rendro fixture.

### Add New

Recommended modules/tasks:

- `lib/rendro/comparison.ex`
- `lib/mix/tasks/rendro/comparison/gen.ex`
- `lib/mix/tasks/rendro/comparison/check.ex`
- `lib/mix/tasks/rendro/livebook/check.ex`
- `test/docs_contract/comparison_claims_test.exs`
- `test/rendro/comparison_test.exs`
- `test/mix/tasks/rendro_livebook_check_test.exs`

Recommended generated markers:

- `<!-- rendro-comparison-results-start -->`
- `<!-- rendro-comparison-results-end -->`
- `<!-- rendro-comparison-fit-start -->`
- `<!-- rendro-comparison-fit-end -->`

## Planning Recommendation

Use six plans:

1. Static benchmark manifest contract and guardrails scaffolding.
2. Benchmark harness fixtures, pins, raw artifacts, and committed summary
   results.
3. Comparison guide generator plus docs-contract claim binding.
4. Livebook tutorial and local/advisory execution helper.
5. ExDoc/README/package/CI wiring for comparison guide and Livebook, including
   advisory context registration and required/advisory separation tests.
6. Final regeneration, guide copy pass, and verification closure.

The execution order should put static contracts before guide copy so claims
cannot be added faster than the tests can police them.

## Validation Architecture

Nyquist validation is applicable because this phase has multiple independent
truth channels: benchmark data, generated guide blocks, docs claim lint,
Livebook execution, Hex package contents, and CI guardrails.

Validation should require:

- after each task: targeted ExUnit/docs-contract tests for the touched surface;
- after each plan: at least one command that proves both source assertions and
  behavior for the plan's requirement IDs;
- before verification: `mix docs.contract`, `mix test` for all new comparison
  and guardrail tests, `mix hex.build` package inspection, and advisory command
  dry runs where local external tools are available.

Suggested required/static commands:

- `mix test test/docs_contract/comparison_claims_test.exs`
- `mix test test/rendro/comparison_test.exs`
- `mix test test/guardrails/required_checks_contract_test.exs`
- `mix test test/mix/tasks/rendro_livebook_check_test.exs`
- `mix run scripts/verify_docs.exs`
- `mix ci`

Suggested advisory commands:

- `mix rendro.comparison.check`
- `mix rendro.livebook.check`
- any full benchmark rerun command, only when external runtimes are installed
  or CI images are available.

## Threats And Mitigations

- Benchmark fairness attack: mitigate with dual-track model, pinned versions,
  environment metadata, raw artifacts, whole-process measurements, and explicit
  "where HTML/CSS wins" guide sections.
- Manifest tampering or stale raw files: mitigate with raw SHA-256 validation
  and generated-block equality tests.
- Public overclaim: mitigate with citation resolution and forbidden comparative
  phrase tests.
- Required CI contamination: mitigate with guardrail tests proving benchmark and
  Livebook jobs are advisory and graph-disconnected.
- Supply-chain/tool drift: mitigate with pinned comparator versions, Docker
  image digests, tool version capture, and no runtime deps in `rendro` core.
- Livebook rot: mitigate with `Livebook.live_markdown_to_elixir/1` execution in
  a graph-disconnected advisory job.

## Open Implementation Choices

- Whether the benchmark runner is plain `elixir bench/comparison/run.exs` or a
  Mix task. A Mix task gives better discoverability and test seams.
- Whether committed results are seeded by a lightweight deterministic placeholder
  run first, then replaced by real external-tool runs in a final advisory pass.
  The final public guide must only cite real, pinned benchmark results.
- Exact manifest schema field names. Preserve the concepts: run metadata,
  scenario metadata, comparator metadata, raw artifact references, result rows,
  and public claim records.
- Exact CI split: one `comparison-advisory` job plus one `livebook-advisory`
  job, or a single `comparison-livebook-advisory` job. Separate jobs are clearer
  because benchmarks and notebook execution fail for different reasons.

## RESEARCH COMPLETE


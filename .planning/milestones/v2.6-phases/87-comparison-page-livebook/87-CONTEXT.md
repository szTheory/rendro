# Phase 87: Comparison Page & Livebook - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the Phase 87 `CMP-01..03` launch-evaluation artifacts:

1. A reproducible checked-in benchmark harness versus ChromicPDF, pdf_generator, and Typst-CLI that measures cold start, memory, container image size, and dependency count with pinned versions and published environment metadata.
2. A HexDocs comparison guide titled around "Generating PDFs in Elixir without Chrome" whose metric and fit claims are bounded to committed benchmark results by docs-contract tests.
3. A `.livemd` Livebook tutorial that gives evaluating Phoenix engineers a zero-friction first invoice workflow with inline preview and download, and that is executed in an advisory CI lane so it cannot rot.

This phase does not add new rendering capabilities. It packages existing v2.6 truth fixes, visual proof, raster tooling, gallery/manual artifacts, and launch positioning into an honest evaluation path. The output should help a Phoenix SaaS engineer decide whether Rendro, ChromicPDF, pdf_generator, or Typst-CLI is the right fit for a particular PDF job.

</domain>

<decisions>
## Implementation Decisions

### Benchmark Fairness Model
- **D-01:** Use a **dual-track benchmark model**. Track 1 is a normalized business-document workload and is the only source for headline quantitative claims. Track 2 is idiomatic-per-tool fixtures used for DX, setup, operational fit, and "when this tool wins" guidance.
- **D-02:** The normalized workload should be a realistic invoice or statement-style business document: A4 or US Letter, logo, 50-150 rows, repeated table headers, footer page numbers, simple borders, fixed fonts, and Latin text. Do not include complex scripts, CSS grid/flex showcase behavior, math typesetting, or web-template migration scenarios in the quantitative baseline.
- **D-03:** The idiomatic track should use each tool the way its ecosystem expects: Rendro recipe/data DSL; ChromicPDF with Phoenix/HEEx-style HTML and print CSS; pdf_generator as a legacy wkhtmltopdf or chrome-headless HTML wrapper; Typst-CLI with a native `.typ` template and Typst table/page features.
- **D-04:** The idiomatic track is explicitly **non-ranking**. It can compare code shape, setup steps, supervision/runtime story, telemetry posture, template maintenance, and failure modes. It must not feed a blended "winner" chart.
- **D-05:** Measure **whole process trees**, not parent processes only. Chrome, Ghostscript, wkhtmltopdf, Typst, BEAM children, helper tools, and subprocesses all count toward RSS and cold-start posture.
- **D-06:** Publish pins and environment metadata with every committed result: tool/library versions, Docker image digest, OS, architecture, CPU, memory limit, fonts/assets, input fixture, commands, repetitions, median, and p95.
- **D-07:** Exclude dependency download/build time from runtime metrics, but publish runtime container image size and dependency/runtime count separately. The runtime/deployment burden is part of the comparison, but dependency installation time is not a render-time metric.
- **D-08:** Include both a ChromicPDF cold-start row and a warm pooled render row. ChromicPDF's supervision/pooling model is a real Elixir strength; omitting it would make the comparison look unfair.
- **D-09:** Do not publish a single overall winner. Publish a decision guide: Rendro wins for deterministic Elixir-native documents without a browser runtime; ChromicPDF wins when source-of-truth is existing HTML/CSS or browser fidelity; Typst wins when Typst templates and its layout language are already a good fit; pdf_generator is primarily a legacy/wkhtmltopdf comparison point.

### Results & Claim Binding
- **D-10:** Store benchmark truth in **JSON**, not Markdown. Use `bench/results/comparison.json` as the summary manifest plus raw artifacts under `bench/results/raw/` referenced by SHA-256.
- **D-11:** The manifest should include `schema_version`, `generated_by`, run metadata, scenario metadata, comparator metadata, result rows, and public claim records. Each raw artifact path must carry a SHA-256 so reviewers can audit the source data.
- **D-12:** Generate only the public result tables, fit/caveat table, and evidence summary blocks inside `guides/comparison.md`. Keep the guide's intro and interpretation human-authored so the page reads like a useful HexDocs guide, not a generated report.
- **D-13:** Use visible claim citations such as `[bench:CMP-COLD-START-001]`. Docs-contract tests must require every `[bench:*]` citation to resolve to the manifest, and every public manifest claim intended for docs to appear in the guide.
- **D-14:** Docs-contract tests must fail uncited comparative language in the comparison guide. Words/phrases such as "faster", "smaller", "lower RSS", "fewer dependencies", "lighter", and "no Chrome runtime" need valid `[bench:CMP-*]` citations or must be in a clearly non-metric scope such as the static project tagline already supported elsewhere.
- **D-15:** Required docs-contract checks validate static truth only: manifest shape, raw-artifact hashes, generated-block freshness, citation resolution, forbidden overclaims, pinned versions, published hardware/container metadata, required caveats, ExDoc registration, package inclusion, and required/advisory CI separation.
- **D-16:** Benchmark reruns and Livebook execution stay **advisory**. Do not put noisy benchmark reruns, Chrome/wkhtmltopdf/Typst downloads, Livebook execution, Kino, or pdfium-style external tooling into the required `mix ci` path.

### Comparison Guide Framing
- **D-17:** Title the guide **"Generating PDFs in Elixir without Chrome"** because it matches the v2.6 launch hook, search intent, and existing forum demand. The subtitle/first paragraph must frame it as a decision guide for Phoenix teams choosing between native document layout, HTML-to-PDF, wkhtmltopdf, and Typst-backed rendering.
- **D-18:** Use this guide structure:
  - `The Short Version`
  - `Choose By Job`
  - `Measured Operational Tradeoffs`
  - `Where HTML/CSS Renderers Still Win`
  - `Text, Fonts, and Complex Scripts`
  - `Reproduce These Numbers`
  - `Try Rendro In Livebook`
- **D-19:** Lead with a compact fit matrix before measured results. Use labels like `Best fit`, `Good fit`, and `Use another tool`; do not use winner badges, trophies, or attack-language labels.
- **D-20:** Public guide copy must explicitly praise alternatives where true:
  - "Choose ChromicPDF when your source of truth is already HTML/CSS or browser CSS fidelity is the requirement."
  - "Choose Typst when your team wants Typst templates and its layout language is already part of your workflow."
  - "Choose Rendro when your PDF is authored from Elixir data and you want deterministic layout, pagination, telemetry, and no browser runtime."
- **D-21:** The limitation block must be impossible to miss: Rendro does not render arbitrary HTML/CSS; complex-script and RTL support are bounded by `priv/support_matrix.json`; unsupported shaping cases fail explicitly instead of producing silent broken output.
- **D-22:** Avoid attack or hype words: no "bloated", "kills Chrome", "replaces every PDF tool", "pixel-perfect HTML-to-PDF", or "works everywhere". Use "tradeoff", "fit", "runtime dependency", "evidence", and "measured in this harness".
- **D-23:** Place "Try the invoice workflow in Livebook" and "Reproduce the benchmark results" as the primary CTAs. Put "Run in Livebook" affordances near the first decision summary and again near the end.

### Livebook Tutorial Shape
- **D-24:** Ship one canonical notebook, likely `guides/livebook/first_invoice.livemd`. Do not build a multi-recipe gallery notebook and do not include benchmark cells.
- **D-25:** Notebook flow:
  1. Setup via `Mix.install` for published-use mode, with a local-checkout path mode gated by `RENDRO_LIVEBOOK_LOCAL=1`.
  2. Define fixed invoice data.
  3. Build `Rendro.Recipes.Invoice.document/1`.
  4. Render with deterministic options.
  5. Assert `%PDF-` and display byte size plus SHA-256.
  6. Show inline PDF preview via `Kino.HTML` with a base64 `data:application/pdf` iframe or embed.
  7. Provide `Kino.Download.new(fn -> pdf end, filename: "rendro-invoice.pdf")`.
  8. End with a short Phoenix controller handoff snippet and links to gallery/manual/comparison.
- **D-26:** Keep Phoenix code schematic in the notebook. A real Phoenix `conn` flow should not be executed in Livebook because that would pull Phoenix into the tutorial runtime and fight the "core pure, adapters optional" boundary.
- **D-27:** Use Kino only for notebook UX. Kino belongs inside the notebook `Mix.install`, not in Rendro runtime deps. `:livebook` may be added only as `only: [:dev, :test], runtime: false` if planning chooses the official conversion API for advisory execution.
- **D-28:** Execute notebook code cells in CI without starting a Livebook server. The preferred advisory path is: convert the `.livemd` using `Livebook.live_markdown_to_elixir/1`, then run the resulting script with `RENDRO_LIVEBOOK_LOCAL=1` against the checkout. Keep the notebook simple enough to avoid the documented conversion limitations around macros spanning cells or branching sections.
- **D-29:** ExDoc should own the main Livebook affordance: add the `.livemd` to `extras`, because ExDoc supports `.livemd` extras and adds "Run in Livebook" affordances. README should contain a small guide/badge link near Getting Started or Guides, not a large marketing hero.
- **D-30:** Required static docs-contract tests should verify that the notebook is listed in ExDoc extras, packaged in Hex files, linked from README/comparison guide, registered in advisory guardrails, and absent from required status checks. Advisory CI verifies actual execution.

### the agent's Discretion
- Exact benchmark harness implementation is left to planning. Acceptable choices include plain Mix tasks, shell wrappers, Dockerfiles, and Benchee for BEAM-local timing where appropriate, provided whole-process metrics and external runtimes are captured truthfully.
- Exact manifest schema field names may vary, but the schema must preserve the core distinction between scenario, comparator, raw artifact, metric result, and public claim.
- Exact guide block markers may follow the Phase 86 launch-artifact generator style. Prefer generated blocks for tables and evidence summaries, not full generated prose.
- Exact Livebook filename and section titles may change if ExDoc path grouping suggests a better name, but keep one canonical first-invoice notebook.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative Scope
- `.planning/ROADMAP.md` — Phase 87 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — `CMP-01..03` requirement text and traceability.
- `.planning/STATE.md` — active milestone state and current Phase 87 readiness.

### Prior Phase Decisions
- `.planning/phases/83-claim-accuracy-shaping-hygiene/83-CONTEXT.md` — claim-accuracy decisions, explicit shaper configuration, complex-script boundary, and support-matrix posture. Phase 87 guide must reflect these truth boundaries.
- `.planning/phases/84-drawn-path-primitive-visible-polish/84-CONTEXT.md` — Path primitive, table-border polish, and visible output constraints that make Phase 87 screenshots/comparison examples credible.
- `.planning/phases/85-deterministic-raster-lane/85-VERIFICATION.md` — verified raster lane closure and `pdfium-render`/GUI-viewer boundary.
- `.planning/phases/85-deterministic-raster-lane/85-05-SUMMARY.md` — render-backed golden PNG snapshot harness pattern.
- `.planning/phases/85-deterministic-raster-lane/85-06-SUMMARY.md` — advisory raster/GUI-row separation and adapter hardening.
- `.planning/phases/86-self-proving-launch-artifacts/86-CONTEXT.md` — gallery/manual proof posture, generated docs blocks, brand presentation, and required/advisory verification split.
- `.planning/phases/86-self-proving-launch-artifacts/86-VERIFICATION.md` — Phase 86 artifact verification closure.

### v2.6 Research
- `.planning/research/FEATURES.md` — Phase 87 benchmark/comparison and Livebook lane recommendations.
- `.planning/research/PITFALLS.md` — Phase 87 pitfalls: benchmark fairness attacks and Livebook rot.
- `.planning/research/ARCHITECTURE.md` — Phase 87 benchmark/Livebook architecture: committed results, docs-contract guide, advisory CI.
- `.planning/research/STACK.md` — benchmark tooling expectations, no runtime deps, Livebook/Kino/ExDoc constraints.
- `.planning/research/JTBD-USER-FLOWS.md` — Phoenix SaaS engineer persona and competitor-fit context.
- `.planning/research/SUMMARY.md` — launch/adoption strategy and proof-culture positioning.

### Brand / Product Direction
- `prompts/Rendro Brand Book.txt` — voice, microcopy, visual table/guide design, honest limitations, "without Chrome" positioning, and Livebook/guide presentation constraints.
- `prompts/rendro-oss-dna.md` — docs-contract discipline, deterministic/advisory lane separation, optional dependency boundaries, and proof-backed claims.
- `prompts/rendro-gsd-seed.md` — core thesis, personas, and non-negotiable pure-core/Phoenix-first constraints.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Elixir PDF ecosystem lessons and comparator strengths/weaknesses across ChromicPDF, pdf_generator, Typst, Prawn, ReportLab, fpdf2, PDFKit, pdf-lib, WeasyPrint, Prince, iText, and PDFBox.
- `prompts/rendro-integration-opportunities.md` — Phoenix SaaS/user-flow adjacency and optional-integration posture.

### Current Code Touchpoints
- `mix.exs` — ExDoc extras/groups, Hex package allowlist, optional dependencies, `mix ci` alias, and dev/test dependency placement.
- `.github/workflows/ci.yml` — required `test`, advisory `example-phoenix`, advisory `raster-advisory`, and live proof lane patterns.
- `scripts/verify_docs.exs` — explicit docs-contract lane registration pattern.
- `test/docs_contract/launch_artifacts_claims_test.exs` — Phase 86 manifest-backed generated block/static contract pattern.
- `test/docs_contract/raster_claims_test.exs` — structured support-matrix checks and `pdfium-render` boundary pattern.
- `test/guardrails/required_checks_contract_test.exs` — required/advisory CI separation contract to extend for Phase 87.
- `lib/rendro/launch_artifacts.ex` — generated README/guide block pattern, manifest helpers, artifact hash checks, and advisory-tool separation.
- `README.md` — launch-artifact block, first-screen positioning, guide-link placement, and generated/manual proof copy.
- `guides/recipes.md` — rendered gallery block style and HexDocs guide tone.
- `priv/guardrails/required_status_checks.json` — required vs advisory CI context contract.
- `priv/support_matrix.json` — source of truth for complex-script, raster, viewer, and support-boundary claims.
- `priv/pdfium_pin.json` — pinned external-tool metadata pattern.
- `assets/rendro/artifacts.json` — Phase 86 manifest pattern to mirror for benchmark results.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.LaunchArtifacts` already demonstrates the right shape for Phase 87: structured JSON manifest, generated Markdown blocks, static contract checks, asset hash verification, and advisory external-tool checks.
- `scripts/verify_docs.exs` is the established place to add a "Comparison claims lane" or similarly named docs-contract lane.
- `test/docs_contract/launch_artifacts_claims_test.exs` provides a direct template for generated-block drift, manifest-shape drift, package inclusion, and public-copy overclaim tests.
- `test/docs_contract/raster_claims_test.exs` and `test/guardrails/required_checks_contract_test.exs` provide patterns for proving advisory lanes stay outside required CI.
- ExDoc configuration in `mix.exs` already groups guides and recipe/primitives extras. Phase 87 should add `guides/comparison.md` and the `.livemd` notebook as extras and group them intentionally.
- `.github/workflows/ci.yml` already has graph-disconnected advisory jobs. Phase 87 should add benchmark and Livebook advisory execution in that style, not under the required `test` job.

### Established Patterns
- Deterministic/static proof belongs in required docs-contract lanes; external-tool, noisy benchmark, raster, and Livebook execution proof belongs in advisory lanes.
- Documentation claims are product contracts. Public guide copy should be generated or mechanically linted wherever numeric/comparative claims appear.
- Package contents are explicit in `mix.exs`; any benchmark manifest, comparison guide, Livebook notebook, and public assets must be intentionally included or intentionally excluded.
- Optional dependencies must stay optional and dev/test/tool-scoped when they support docs/tutorial workflows. Core must not gain hard Phoenix, Livebook, Kino, Chrome, wkhtmltopdf, Typst, or benchmark-tool runtime deps.
- Errors and drift messages should be errors-as-product: state what drifted, where, why it matters, and which command regenerates or verifies the artifact.

### Integration Points
- New benchmark functionality likely connects through a private module such as `Rendro.Benchmarks` plus Mix tasks such as `mix rendro.bench.gen` and `mix rendro.bench.check`. Names are discretionary; manifest/proof semantics are not.
- `guides/comparison.md` should use generated block markers similar to `<!-- rendro-launch-artifacts-start -->` / `<!-- rendro-launch-artifacts-end -->`.
- A new docs-contract test file, likely `test/docs_contract/comparison_claims_test.exs`, should register in `scripts/verify_docs.exs`.
- A new advisory CI job should execute benchmark checks and/or Livebook checks without adding `needs: test` unless intentionally separate from required status. It must not appear in `required_contexts`.
- The Livebook execution helper may be a script or Mix task that reads `guides/livebook/first_invoice.livemd`, calls `Livebook.live_markdown_to_elixir/1`, and runs the generated script with `RENDRO_LIVEBOOK_LOCAL=1`.

</code_context>

<specifics>
## Specific Ideas

### Recommended Manifest Sketch

The exact schema is discretionary, but planning should preserve this conceptual shape:

```json
{
  "schema_version": 1,
  "generated_by": "mix rendro.bench.gen",
  "run": {
    "id": "2026-06-11-linux-amd64",
    "recorded_at": "2026-06-11T16:00:00Z",
    "git_sha": "...",
    "host": {"os": "ubuntu-24.04", "arch": "x86_64", "cpu": "...", "ram_mb": 8192},
    "container": {"image": "ghcr.io/...@sha256:...", "elixir": "1.19.5", "otp": "28"}
  },
  "scenario": {"id": "invoice_v1", "fixture": "bench/fixtures/invoice.exs"},
  "comparators": [
    {"id": "rendro", "version": "1.0.0", "external_runtime": "none"},
    {"id": "chromic_pdf", "version": "...", "external_runtime": "chrome"},
    {"id": "pdf_generator", "version": "...", "external_runtime": "wkhtmltopdf"},
    {"id": "typst_cli", "version": "...", "external_runtime": "typst"}
  ],
  "results": [
    {
      "comparator": "rendro",
      "metric": "cold_start_ms",
      "median": 180,
      "p95": 220,
      "samples": 10,
      "unit": "ms",
      "raw_artifact": "bench/results/raw/rendro-cold-start.json",
      "raw_sha256": "..."
    }
  ],
  "claims": [
    {
      "id": "CMP-COLD-START-001",
      "text": "In the pinned invoice harness, Rendro had the lowest median cold-start time among the measured options.",
      "scope": "Pinned Linux container, invoice_v1 fixture; not a general performance promise.",
      "evidence": [{"metric": "cold_start_ms", "operator": "min"}]
    }
  ]
}
```

### Guide Microcopy

Useful copy that downstream agents can adapt:

- "Rendro is an open-source, Elixir-native PDF layout library. This guide helps Phoenix teams choose between native document layout, HTML-to-PDF, wkhtmltopdf, and Typst-backed rendering."
- "Choose Rendro when your PDF is authored from Elixir data and you want deterministic layout, pagination, telemetry, and no browser runtime."
- "Choose ChromicPDF when your source of truth is already HTML/CSS or browser CSS fidelity is the requirement."
- "Choose Typst when your team wants Typst templates and its layout language is already part of your workflow."
- "Measured in this harness" should appear near any numeric comparison.
- "Rendro does not render arbitrary HTML/CSS. Complex-script and RTL support is bounded by the support matrix; unsupported cases fail explicitly instead of producing silent broken output."

### External References Consulted During Discussion

- `https://chromic-pdf.hexdocs.pm/ChromicPDF.html` — ChromicPDF is Chrome/Ghostscript-based, supervision-tree oriented, supports PDF/A via Ghostscript, documents browser security/deployment considerations, and exposes warm-up/pooling concepts.
- `https://pdf-generator.hexdocs.pm/PdfGenerator.html` — pdf_generator wraps wkhtmltopdf/pdftk and can use chrome-headless; documents system executable requirements and startup checks.
- `https://typst.app/docs/reference/pdf/` — Typst CLI defaults to PDF export and exposes PDF standards/tagging options.
- `https://typst.app/blog/2025/automated-generation/` — Typst's own automated-generation posture uses `typst compile`, `--input`, `sys.inputs`, and template-native data handling.
- `https://benchee.hexdocs.pm/readme.html` — Benchee supports time, memory, reductions, warmup, samples, statistics, and formatters, but BEAM-local memory measurements do not cover whole external process trees.
- `https://livebook.hexdocs.pm/Livebook.html` — `Livebook.live_markdown_to_elixir/1` converts Live Markdown to Elixir source code and documents conversion limitations.
- `https://kino.hexdocs.pm/Kino.HTML.html` — `Kino.HTML.new/1` renders HTML content for notebook preview.
- `https://kino.hexdocs.pm/Kino.Download.html` — `Kino.Download.new/2` creates a file download button with lazy content generation.
- `https://ex-doc.hexdocs.pm/changelog.html` — ExDoc supports `.livemd` extras and adds "Run in Livebook" badges for them.
- `https://livebook.dev/badge/` — official Livebook badge generator for additional README badge/link usage.
- `https://github.com/prawnpdf/prawn` — Prawn's generated manual and explicit "not HTML-to-PDF" scope are useful precedent for Rendro's honest docs.

</specifics>

<deferred>
## Deferred Ideas

- Benchmark cells inside the Livebook tutorial — rejected for Phase 87 notebook because toy benchmarks invite fairness criticism, slow the first-success path, and duplicate the comparison guide.
- Full gallery/manual recreation inside Livebook — rejected because it duplicates Phase 86 assets and risks blurring curated launch fixtures with default recipe output.
- A single overall winner badge — rejected because it would collapse distinct jobs and poison the guide's fair-decision posture.
- Required CI reruns of noisy benchmark or Livebook execution lanes — rejected because it violates deterministic/advisory lane separation.
- Full hosted playground — remains out of v2.6; Livebook gives the lower-cost try path.
- New rendering capabilities, charts, TOC, PDF.js lane, broader text shaping, and mobile viewer evidence remain in their already deferred future phases/items.

</deferred>

---

*Phase: 87-Comparison Page & Livebook*
*Context gathered: 2026-06-11*

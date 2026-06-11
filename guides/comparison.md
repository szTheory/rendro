# Generating PDFs in Elixir without Chrome

Rendro is an Elixir-native PDF layout library for Phoenix teams that build documents from application data. This guide compares Rendro with ChromicPDF, pdf_generator, and Typst CLI as a decision guide, not as a single winner chart.

## The Short Version

Choose Rendro when your PDF is authored from Elixir data and you want deterministic layout, pagination, telemetry, and no browser runtime. [bench:CMP-RUNTIME-BURDEN]

Choose ChromicPDF when your source of truth is already HTML/CSS or browser CSS fidelity is the requirement.

Choose Typst when your team wants Typst templates and its layout language is already part of your workflow.

Primary actions:

- Try the invoice workflow in Livebook: [`guides/livebook/first_invoice.livemd`](livebook/first_invoice.livemd)
- Reproduce the benchmark results: `elixir bench/comparison/run.exs --track normalized --all`

## Choose By Job

<!-- rendro-comparison-fit-start -->
| Job | Rendro | ChromicPDF | pdf_generator | Typst CLI | Reason |
|---|---|---|---|---|---|
| Documents authored from Elixir data | Best fit | Good fit | Use another tool | Good fit | Native data-driven layout, deterministic pagination, and telemetry-oriented operation [bench:CMP-COLD-START], [bench:CMP-RSS], [bench:CMP-RUNTIME-BURDEN] |
| Existing HTML/CSS source of truth | Use another tool | Best fit | Good fit | Use another tool | Browser or wkhtmltopdf renderers preserve HTML/CSS workflows |
| Typst-native template workflow | Use another tool | Use another tool | Use another tool | Best fit | Typst is strongest when its template language is already the document source |

- [bench:CMP-COLD-START] The normalized invoice harness records timing for each comparator posture. Scope: Phase 87 pinned invoice_v1 harness on the recorded host/container only; cold rows include process startup, and the warm-pool row times a render after an untimed warm-up render.
- [bench:CMP-RSS] The normalized invoice harness records process memory for each comparator. Scope: RSS values are measured by platform time tools and should be read as harness evidence, not a universal memory promise.
- [bench:CMP-RUNTIME-BURDEN] The normalized invoice harness records runtime image size and external runtime count as separate operational metrics. Scope: Runtime burden is separate from render timing and excludes dependency download/build time.
<!-- rendro-comparison-fit-end -->

## Measured Operational Tradeoffs

The table below is generated from `bench/results/comparison.json`. Measured in this harness means the numbers apply to the pinned `invoice_v1` workload, host, container, versions, and commands recorded in the evidence block.

<!-- rendro-comparison-results-start -->
Measured in this harness.

| Metric | Rendro | ChromicPDF cold | ChromicPDF warm pool | pdf_generator | Typst CLI | Evidence |
|---|---:|---:|---:|---:|---:|---|
| Render time | 459 ms median / 477 ms p95 | 733 ms median / 742 ms p95 | 31 ms median / 32 ms p95 | 727 ms median / 762 ms p95 | 55 ms median / 130 ms p95 | [bench:CMP-COLD-START] |
| RSS | 114.00 MB median / 115.80 MB p95 | 110.40 MB median / 112.10 MB p95 | 108.20 MB median / 110.50 MB p95 | 108.40 MB median / 110.00 MB p95 | 35.20 MB median / 35.20 MB p95 | [bench:CMP-RSS] |
| Runtime image | 0 MB median / 0 MB p95 | 917.80 MB median / 917.80 MB p95 | 917.80 MB median / 917.80 MB p95 | 917.80 MB median / 917.80 MB p95 | 0 MB median / 0 MB p95 | [bench:CMP-RUNTIME-BURDEN] |
| Runtime dependencies | 0 count median / 0 count p95 | 2 count median / 2 count p95 | 2 count median / 2 count p95 | 2 count median / 2 count p95 | 1 count median / 1 count p95 | [bench:CMP-RUNTIME-BURDEN] |
<!-- rendro-comparison-results-end -->

## Where HTML/CSS Renderers Still Win

ChromicPDF is the right fit when browser CSS fidelity, existing HTML templates, or Phoenix-rendered markup are already the document source. That is a real strength, and this guide keeps it separate from Rendro's Elixir-data authoring path.

pdf_generator remains useful for teams maintaining a wkhtmltopdf workflow. It is included here as legacy operational context rather than a broad recommendation for new native-Elixir document systems.

Typst is a strong fit when the team wants Typst templates, Typst review workflows, and Typst's layout language.

## Text, Fonts, and Complex Scripts

> Limitation: Rendro does not render arbitrary HTML/CSS.
>
> Complex-script and RTL support are bounded by priv/support_matrix.json.
>
> Unsupported shaping cases fail explicitly instead of producing silent broken output.

Rendro's comparison posture is intentionally narrow: deterministic business documents authored from Elixir data, with explicit support boundaries. If a job depends on arbitrary browser layout, use a browser-backed renderer. If a job depends on Typst-native templates, use Typst.

## Reproduce These Numbers

Run the normalized benchmark from the repository root:

```bash
elixir bench/comparison/run.exs --track normalized --all
mix rendro.comparison.check
```

The runner builds the pinned Docker image for ChromicPDF and pdf_generator rows, uses the host Typst CLI for Typst, and records raw artifacts under `bench/results/raw/`.

<!-- rendro-comparison-evidence-start -->
| Field | Value |
|---|---|
| Run id | `phase-87-normalized-2026-06-11` |
| Recorded at | `2026-06-11T21:23:51.834141Z` |
| Git SHA | `ab6bf9c` |
| Scenario | `invoice_v1` from `bench/comparison/fixtures/invoice_data.json` |
| Host | Darwin, arm64, Apple M5 Pro, 65536 MB |
| Container | rendro-comparison-bookworm:local sha256:066f1956bd58ce148a99019fea2f83b645aa013f396fa67baa8ba2dffa8dbae6 917.8 MB |
| Comparator versions | `rendro` 1.0.0 (none); `chromic_pdf` 1.17.1 (Chromium 149.0.7827.102 built on Debian GNU/Linux 12 (bookworm)); `chromic_pdf_warm_pool` 1.17.1 (Chromium 149.0.7827.102 built on Debian GNU/Linux 12 (bookworm)); `pdf_generator` 0.6.2 (wkhtmltopdf 0.12.6); `typst_cli` typst 0.14.2 (unknown hash) (typst) |
| Repetitions | 3 |

Result summaries:
- `rendro/cold_start_ms`: median 459 ms, p95 477 ms, samples 3, raw `bench/results/raw/rendro.json`
- `rendro/rss_mb`: median 114.00 MB, p95 115.80 MB, samples 3, raw `bench/results/raw/rendro.json`
- `rendro/container_image_mb`: median 0 MB, p95 0 MB, samples 1, raw `bench/results/raw/rendro.json`
- `rendro/dependency_count`: median 0 count, p95 0 count, samples 1, raw `bench/results/raw/rendro.json`
- `chromic_pdf/cold_start_ms`: median 733 ms, p95 742 ms, samples 3, raw `bench/results/raw/chromic_pdf.json`
- `chromic_pdf/rss_mb`: median 110.40 MB, p95 112.10 MB, samples 3, raw `bench/results/raw/chromic_pdf.json`
- `chromic_pdf/container_image_mb`: median 917.80 MB, p95 917.80 MB, samples 1, raw `bench/results/raw/chromic_pdf.json`
- `chromic_pdf/dependency_count`: median 2 count, p95 2 count, samples 1, raw `bench/results/raw/chromic_pdf.json`
- `chromic_pdf_warm_pool/cold_start_ms`: median 31 ms, p95 32 ms, samples 3, raw `bench/results/raw/chromic_pdf_warm_pool.json`
- `chromic_pdf_warm_pool/rss_mb`: median 108.20 MB, p95 110.50 MB, samples 3, raw `bench/results/raw/chromic_pdf_warm_pool.json`
- `chromic_pdf_warm_pool/container_image_mb`: median 917.80 MB, p95 917.80 MB, samples 1, raw `bench/results/raw/chromic_pdf_warm_pool.json`
- `chromic_pdf_warm_pool/dependency_count`: median 2 count, p95 2 count, samples 1, raw `bench/results/raw/chromic_pdf_warm_pool.json`
- `pdf_generator/cold_start_ms`: median 727 ms, p95 762 ms, samples 3, raw `bench/results/raw/pdf_generator.json`
- `pdf_generator/rss_mb`: median 108.40 MB, p95 110.00 MB, samples 3, raw `bench/results/raw/pdf_generator.json`
- `pdf_generator/container_image_mb`: median 917.80 MB, p95 917.80 MB, samples 1, raw `bench/results/raw/pdf_generator.json`
- `pdf_generator/dependency_count`: median 2 count, p95 2 count, samples 1, raw `bench/results/raw/pdf_generator.json`
- `typst_cli/cold_start_ms`: median 55 ms, p95 130 ms, samples 3, raw `bench/results/raw/typst_cli.json`
- `typst_cli/rss_mb`: median 35.20 MB, p95 35.20 MB, samples 3, raw `bench/results/raw/typst_cli.json`
- `typst_cli/container_image_mb`: median 0 MB, p95 0 MB, samples 1, raw `bench/results/raw/typst_cli.json`
- `typst_cli/dependency_count`: median 1 count, p95 1 count, samples 1, raw `bench/results/raw/typst_cli.json`

Raw artifacts:
- `bench/results/raw/rendro.json`
- `bench/results/raw/chromic_pdf.json`
- `bench/results/raw/chromic_pdf_warm_pool.json`
- `bench/results/raw/pdf_generator.json`
- `bench/results/raw/typst_cli.json`

- [bench:CMP-COLD-START] The normalized invoice harness records timing for each comparator posture. Scope: Phase 87 pinned invoice_v1 harness on the recorded host/container only; cold rows include process startup, and the warm-pool row times a render after an untimed warm-up render.
- [bench:CMP-RSS] The normalized invoice harness records process memory for each comparator. Scope: RSS values are measured by platform time tools and should be read as harness evidence, not a universal memory promise.
- [bench:CMP-RUNTIME-BURDEN] The normalized invoice harness records runtime image size and external runtime count as separate operational metrics. Scope: Runtime burden is separate from render timing and excludes dependency download/build time.
<!-- rendro-comparison-evidence-end -->

## Try Rendro In Livebook

Try the invoice workflow in Livebook with [`guides/livebook/first_invoice.livemd`](livebook/first_invoice.livemd). The notebook renders an invoice, checks the `%PDF-` header, displays byte size and SHA-256, shows an inline preview, and provides a download button for the same rendered PDF.

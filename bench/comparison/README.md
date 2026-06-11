# Rendro Comparison Benchmark

This directory contains the reproducible Phase 87 comparison harness for the
normalized invoice workload.

## Tracks

The normalized track is the only source for headline quantitative claims. It
uses the same `invoice_v1` business-document data for Rendro, ChromicPDF,
pdf_generator, and Typst CLI.

The idiomatic track is non-ranking. It can describe setup, maintenance,
supervision, template ownership, and failure modes, but it must not feed a
blended score or a winner chart.

## Measurement Rules

- Dependency download and build time are excluded from render-time metrics.
- Runtime container image size and dependency/runtime count are published as
  separate operational metrics.
- RSS/memory measurements count whole process trees, including browser,
  wkhtmltopdf, Typst, BEAM children, helper tools, and subprocesses.
- ChromicPDF is measured twice: `chromic_pdf` for cold start and
  `chromic_pdf_warm_pool` for supervised warm-pool rendering.
- Raw artifacts are committed under `bench/results/raw/` and referenced from
  `bench/results/comparison.json` by lowercase SHA-256.

## Normalized Workload

The workload is `invoice_v1`: a fixed Latin-text invoice with one issuer, one
customer, 60 line items, repeated table headers in paginated renderers, simple
borders, fixed fonts, and footer page numbers where the renderer supports them.
It intentionally avoids complex scripts, CSS grid/flex showcases, math
typesetting, and web-template migration scenarios.

## Comparator IDs

- `rendro`
- `chromic_pdf`
- `chromic_pdf_warm_pool`
- `pdf_generator`
- `typst_cli`

## Reproduction

Required host tools for the pinned local runner:

- Docker
- Chrome or Chromium
- wkhtmltopdf
- Typst CLI

Print the runner help:

```bash
elixir bench/comparison/run.exs --help
```

Run all normalized-track comparators after the required tools are installed:

```bash
elixir bench/comparison/run.exs --track normalized --all
```

Run one comparator:

```bash
elixir bench/comparison/run.exs --track normalized --comparator rendro
```

Development-only static scaffold re-encoding:

```bash
mix rendro.comparison.gen --skip-external
```

`--skip-external` must never be used to publish public benchmark claims.

## Static Check

The required CI-safe check never reruns benchmarks and never launches Docker,
Chrome, wkhtmltopdf, or Typst:

```bash
mix rendro.comparison.check
```

---
phase: 87
slug: comparison-page-livebook
status: draft
shadcn_initialized: false
preset: none
surface_type: comparison-guide-and-livebook
created: 2026-06-11
---

# Phase 87 - UI Design Contract

Visual and interaction contract for `guides/comparison.md`, generated benchmark
blocks, README/HexDocs Livebook affordances, and
`guides/livebook/first_invoice.livemd`.

This is not a web application UI phase. No client framework, shadcn, component
registry, custom JavaScript, or marketing landing page is in scope.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Markdown / ExDoc / GitHub README / Livebook |
| Component library | none |
| Icon library | none |
| Primary surfaces | HexDocs comparison guide, README guide links/badge, Livebook tutorial, generated benchmark tables |
| Source of truth for generated blocks | `Rendro.Comparison` helpers |
| Source of truth for measured claims | `bench/results/comparison.json` |

Contract:

- Generated comparison result blocks must be edited through the comparison
  generator; hand edits are drift.
- The guide must read as a buyer's guide for Phoenix engineers, not as a
  winner-takes-all benchmark page.
- README and HexDocs should use simple Markdown/HTML compatible with both
  GitHub and ExDoc.
- ExDoc should own the main "Run in Livebook" affordance by registering the
  `.livemd` file in `extras`.

---

## Comparison Guide

Guide title:

`Generating PDFs in Elixir without Chrome`

Required section order:

1. `The Short Version`
2. `Choose By Job`
3. `Measured Operational Tradeoffs`
4. `Where HTML/CSS Renderers Still Win`
5. `Text, Fonts, and Complex Scripts`
6. `Reproduce These Numbers`
7. `Try Rendro In Livebook`

Visual hierarchy:

- Start with a compact fit matrix before measured results.
- Use `Best fit`, `Good fit`, and `Use another tool` labels; do not use winner
  badges, trophies, attack labels, or a global score.
- Every measured row must carry visible evidence/citation text such as
  `[bench:CMP-COLD-START-001]`.
- Put `Measured in this harness` near every numeric comparison table.
- Put limitation copy in a visible section, not buried in footnotes.

Guide copy requirements:

- Praise alternatives where true:
  - `Choose ChromicPDF when your source of truth is already HTML/CSS or browser CSS fidelity is the requirement.`
  - `Choose Typst when your team wants Typst templates and its layout language is already part of your workflow.`
  - `Choose Rendro when your PDF is authored from Elixir data and you want deterministic layout, pagination, telemetry, and no browser runtime.`
- State the boundaries:
  - Rendro does not render arbitrary HTML/CSS.
  - Complex-script and RTL support are bounded by `priv/support_matrix.json`.
  - Unsupported shaping cases fail explicitly rather than silently producing
    broken output.
- Avoid attack/hype words: `bloated`, `kills Chrome`, `replaces every PDF tool`,
  `pixel-perfect HTML-to-PDF`, `works everywhere`.

---

## Tables

Fit matrix columns:

- Job
- Rendro
- ChromicPDF
- pdf_generator
- Typst CLI
- Reason

Measured operational table columns:

- Metric
- Rendro
- ChromicPDF cold
- ChromicPDF warm pool
- pdf_generator
- Typst CLI
- Evidence

Benchmark metadata table columns:

- Field
- Value

Table rules:

- Keep text dense but readable.
- Do not create wide prose paragraphs inside table cells.
- Metric labels must include units.
- Evidence cells must use compact `[bench:CMP-*]` citations.
- Do not color-code winners unless the semantic label is also written in text.

---

## Generated Blocks

Recommended markers:

- `<!-- rendro-comparison-fit-start -->`
- `<!-- rendro-comparison-fit-end -->`
- `<!-- rendro-comparison-results-start -->`
- `<!-- rendro-comparison-results-end -->`
- `<!-- rendro-comparison-evidence-start -->`
- `<!-- rendro-comparison-evidence-end -->`

Generated block contents:

- Fit matrix.
- Measured operational tradeoff table.
- Evidence summary listing benchmark run id, fixture id, pinned comparator
  versions, container image digest, hardware/OS, sample count, median, and p95.

Generated block anti-patterns:

- Full generated guide prose.
- A single overall winner chart.
- Raw JSON dumps in public docs.
- Huge tables that require horizontal scrolling for normal HexDocs widths.

---

## Livebook Tutorial

Notebook path:

`guides/livebook/first_invoice.livemd`

Notebook flow:

1. Setup via `Mix.install`.
2. Published-use mode by default.
3. Local-checkout mode when `RENDRO_LIVEBOOK_LOCAL=1`.
4. Fixed invoice data.
5. `Rendro.Recipes.Invoice.document/1`.
6. Deterministic render.
7. `%PDF-` assertion, byte size, and SHA-256 display.
8. Inline PDF preview using `Kino.HTML.new/1` and a base64
   `data:application/pdf` iframe or embed.
9. Download using `Kino.Download.new(fn -> pdf end, filename: "rendro-invoice.pdf")`.
10. Short Phoenix controller handoff snippet.
11. Links to recipes, comparison guide, and manual.

Notebook UX requirements:

- The first successful render should happen before any Phoenix handoff snippet.
- Avoid benchmark cells.
- Avoid multi-recipe gallery cells.
- Avoid macros split across cells or branching sections that break
  `Livebook.live_markdown_to_elixir/1`.
- Keep Phoenix code schematic so Phoenix remains optional and outside core.
- Use Kino only inside the notebook `Mix.install`, never as a runtime dependency.

---

## README / HexDocs Links

README placement:

- Add a small Livebook/guide link near `Guides`, not a large marketing hero.
- The README should link to `guides/comparison.md` and the notebook.
- If adding an official Livebook badge/link, keep it compact and adjacent to the
  getting-started or guide list.

ExDoc placement:

- Add `guides/comparison.md` and `guides/livebook/first_invoice.livemd` to
  `extras`.
- Group them under a launch/evaluation-oriented guide group, for example
  `Evaluation`.
- Keep existing recipe/gallery grouping intact.

Package surface:

- `guides/comparison.md`, `guides/livebook/first_invoice.livemd`,
  `bench/results/comparison.json`, and any public raw/evidence files required
  by docs-contract tests must be intentionally included or explicitly excluded
  with tests matching that choice.

---

## Color And Tone

Use the existing Rendro brand palette and host Markdown styles.

| Role | Value | Usage |
|------|-------|-------|
| Dominant | white / paper warm neutrals | Markdown surface, docs tables, generated guide blocks |
| Text | ink-900 / ink-700 | Prose, captions, caveats |
| Lines | line-300 | Table separators and document preview boundaries |
| Accent | blue-600 | Links, proof references, CTAs |
| Warning | amber-600 with text label | Limitations and caveats |
| Success | green-700 with text label | Verified/pinned evidence labels |

Tone:

- Calm, factual, proof-backed.
- Use `fit`, `tradeoff`, `measured in this harness`, `runtime dependency`, and
  `evidence`.
- Do not use shame, attack language, or universal promises.

---

## Accessibility

- Every guide table must have a header row.
- Any status marker must include text, not color alone.
- Every notebook preview/download section needs a clear preceding heading.
- Image/iframe preview copy must mention that the download button provides the
  same rendered PDF.
- README badge/link text must remain meaningful when images fail.

---

## UI Verification

Required source assertions:

- `guides/comparison.md` contains the required section headings.
- `guides/comparison.md` contains visible `[bench:CMP-*]` evidence citations.
- `guides/comparison.md` contains the HTML/CSS and complex-script limitation
  sections.
- README links to `guides/comparison.md`.
- README or HexDocs extras link to `guides/livebook/first_invoice.livemd`.
- `mix.exs` lists both the comparison guide and Livebook under ExDoc extras.
- The notebook contains `Kino.HTML.new`, `Kino.Download.new`, `%PDF-`, and
  `RENDRO_LIVEBOOK_LOCAL`.

Manual review before launch:

- Read the comparison guide in rendered HexDocs or local docs output and confirm
  tables fit without awkward wrapping.
- Open the notebook in Livebook once and confirm the preview/download cells are
  visible and understandable.


# Phase 87: Comparison Page & Livebook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 87-Comparison Page & Livebook
**Areas discussed:** Benchmark Fairness Model, Results & Claim Binding, Comparison Guide Framing, Livebook Tutorial Shape

---

## Benchmark Fairness Model

| Option | Description | Selected |
|--------|-------------|----------|
| One normalized workload | Same JSON invoice/statement across Rendro, ChromicPDF/pdf_generator HTML+print CSS, and Typst `.typ`; useful for cold start, RSS, image size, dependency count, PDF size, and render duration. | |
| Idiomatic per tool | Rendro recipe DSL, ChromicPDF Phoenix/HEEx-style HTML, pdf_generator legacy HTML, and Typst native template; useful for DX and fit. | |
| Dual-track normalized + idiomatic | Normalized track supplies quantitative claims; idiomatic track explains fit, ergonomics, setup, and when each tool wins. | ✓ |
| Scenario decision matrix | Job-based guide around existing Phoenix HTML, deterministic Elixir data documents, Typst-native templates, and legacy migration. | |

**User's choice:** Discuss/consider all areas with subagent research and produce a cohesive recommendation set.

**Notes:** Research recommended the dual-track model. The normalized workload is the only source for headline numeric claims. The idiomatic track is explicitly non-ranking and should be used for fit/DX guidance. ChromicPDF must get both cold-start and warm pooled rows because its supervision/pooling model is an actual ecosystem strength.

---

## Results & Claim Binding

| Option | Description | Selected |
|--------|-------------|----------|
| JSON manifest + generated Markdown tables | `bench/results/comparison.json` drives generated blocks in `guides/comparison.md`; easy to validate with ExUnit and consistent with Phase 86. | ✓ |
| Raw artifacts + summary manifest | Raw command outputs and image inspect data are preserved under `bench/results/raw/` with SHA-256s referenced from the summary manifest. | ✓ |
| ExUnit regex/citation checks only | Guide text carries `[bench:CMP-*]` citations and docs-contract lint checks unresolved or missing citations. | |
| Fully generated guide | Entire guide generated from the manifest. | |
| YAML manifest | Human-editable results in YAML. | |
| Required CI benchmark rerun | Benchmark reruns inside `mix ci`. | |

**User's choice:** Discuss/consider all areas with subagent research and produce a cohesive recommendation set.

**Notes:** Research recommended a hybrid: JSON summary manifest plus raw artifact hashes plus generated guide blocks plus citation lint. Regex/citation checks are secondary lint, not the primary source of truth. Required CI validates static truth; advisory CI may rerun tool-heavy or noisy checks.

---

## Comparison Guide Framing

| Option | Description | Selected |
|--------|-------------|----------|
| Neutral buyer's guide | Calm "Choosing a PDF generator for Elixir" guide. | |
| Sharp "without Chrome" guide | "Generating PDFs in Elixir without Chrome" search/launch hook. | ✓ |
| Competitor comparison | "Rendro vs ChromicPDF vs pdf_generator vs Typst" as a direct comparison. | |
| JTBD decision matrix | "If you need X, choose Y" matrix for Phoenix SaaS engineers. | ✓ |
| Proof-first benchmark page | Metrics-first page around cold start, RSS, image size, dependency count, and pinned versions. | ✓ |
| Livebook-first guide | Lead from the try path rather than the comparison. | |

**User's choice:** Discuss/consider all areas with subagent research and produce a cohesive recommendation set.

**Notes:** Research recommended the hybrid: use "Generating PDFs in Elixir without Chrome" as the title/hook, but structure the guide as an honest decision guide with fit matrix, measured results, explicit alternative strengths, limitations, reproduction steps, and Livebook CTA. No attack language or winner badges.

---

## Livebook Tutorial Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal invoice render path | `Mix.install` → fixed invoice data → `Rendro.Recipes.Invoice.document/1` → `Rendro.render/2` → Kino preview/download. | |
| Rich gallery/manual tie-in | Multi-recipe gallery or manual-aware notebook. | |
| Phoenix-ish workflow | Executable render plus schematic Phoenix controller handoff. | |
| Benchmark-adjacent tutorial | Notebook reads results or runs mini benchmarks. | |
| Recommended hybrid | First invoice, proof, preview/download, Phoenix handoff, and links to gallery/manual/comparison. | ✓ |

**User's choice:** Discuss/consider all areas with subagent research and produce a cohesive recommendation set.

**Notes:** Research recommended one canonical `guides/livebook/first_invoice.livemd`. It should render a deterministic invoice, show PDF magic/byte size/SHA, preview via `Kino.HTML`, download via `Kino.Download`, include a schematic Phoenix handoff, and link to Phase 86/87 proof artifacts. No benchmark cells. CI should execute code cells in a graph-disconnected advisory lane by converting `.livemd` with `Livebook.live_markdown_to_elixir/1` and running the generated script against the checkout.

---

## the agent's Discretion

- Exact benchmark harness implementation details: Mix tasks, shell wrappers, Dockerfiles, raw artifact formats, and whole-process measurement tool choices.
- Exact JSON schema names, as long as scenario, comparator, raw artifact, result, and claim concepts remain distinct.
- Exact guide generated-block marker names and module/task names.
- Exact Livebook filename and section titles, provided the notebook stays one canonical first-invoice try path.

## Deferred Ideas

- Benchmark cells inside the Livebook tutorial.
- Full gallery/manual recreation inside Livebook.
- Single overall winner badge for the guide.
- Required CI reruns of noisy benchmark or notebook execution lanes.
- Hosted playground, broader text shaping, charts, TOC, PDF.js render lane, and mobile viewer evidence remain future/deferred work.

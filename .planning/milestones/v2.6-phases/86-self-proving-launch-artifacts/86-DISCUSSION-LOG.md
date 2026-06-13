# Phase 86: Self-Proving Launch Artifacts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 86-Self-Proving Launch Artifacts
**Areas discussed:** Showcase Fixture Posture, Manual Depth, Verification Split, README Prominence

---

## User Direction

The user selected all four gray areas and requested subagent-backed research. Explicit decision style requested:

- compare pros/cons/tradeoffs for each approach;
- consider Elixir/Plug/Ecto/Phoenix idioms and ecosystem expectations;
- learn from successful libraries and apps in other ecosystems;
- emphasize developer ergonomics, least surprise, user friendliness, architecture quality, and cohesive recommendations;
- consider the local `prompts/` corpus, especially brand/design guidance;
- where applicable, consider UI/UX/graphic design, accessibility, dark/light behavior, microcopy, user persona, user flows, and JTBD;
- synthesize one coherent recommendation set so the user does not need to manually choose from broad menus.

Four research subagents were spawned, one per area. They returned convergent recommendations, synthesized into `86-CONTEXT.md`.

---

## Showcase Fixture Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical recipe defaults exactly | Gallery output matches `Invoice.document/2`, `Statement.document/2`, etc. Lowest surprise, but visually weak and underuses Phase-84 polish. | |
| Launch-tuned fixtures | Gallery fixtures visibly exercise table rules/header bands/certificate frame. Strong adoption signal, but risky if copy implies defaults changed. | |
| Hybrid | Canonical examples remain default; launch artifacts use deterministic, clearly labeled curated fixtures with optional polish. | ✓ |

**User's choice:** Research all and synthesize one recommendation.
**Notes:** The selected recommendation is hybrid. Do not change default recipe behavior for screenshots. Launch fixtures may use subtle opt-in table polish and `border: true` certificate frame, with explicit copy that they are curated deterministic fixtures.

---

## Manual Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Compact proof artifact | Low-maintenance self-rendered PDF proving recipes, path primitive, page numbering, manifest/hash checks. | |
| Full Prawn-style manual | Broad self-generated example catalog. Strong precedent, but high hash churn, high maintenance, and risk of implying unsupported breadth. | |
| Layered compact PDF + HexDocs depth | Compact proof PDF plus searchable HexDocs/Livebook for teaching and reference depth. | ✓ |

**User's choice:** Research all and synthesize one recommendation.
**Notes:** Keep `manual.pdf` roughly 8-12 pages. It should prove positioning, fit boundaries, all five recipes, determinism, Path/page-numbering, and manifest checks. Do not duplicate HexDocs as a PDF reference manual.

---

## Verification Split

| Option | Description | Selected |
|--------|-------------|----------|
| Required static/docs/source-PDF/manual checks + advisory PNG regeneration | Required docs contract proves deterministic artifacts; pdfium PNG regeneration stays advisory. | ✓ |
| Required PNG raster regeneration | Strong literal drift prevention, but violates Phase-85 advisory boundary and can block engine merges on external tooling. | |
| Fully advisory launch artifacts | Keeps required CI light, but undercuts self-proving launch claims. | |

**User's choice:** Research all and synthesize one recommendation.
**Notes:** Required `mix ci` must not require pdfium. Required docs-contract checks should cover manifest shape, exact five IDs, asset hashes, regenerated source-PDF hashes, regenerated manual hash, generated docs blocks, package inclusion, alt text, and overclaim guards. Advisory `raster-advisory` should run PNG regeneration and renderer drift checks.

---

## README Prominence

| Option | Description | Selected |
|--------|-------------|----------|
| Gallery immediately under README intro | Maximum visual proof above the fold, but too marketing-heavy before positioning is established. | |
| Gallery after feature bullets | Balanced: first explain what Rendro is and why it matters, then prove it with real rendered output. | ✓ |
| Rich hero-like README/HexDocs presentation | More visual impact, but fragile in GitHub Markdown, mobile, dark mode, and HexDocs. Better for a future website. | |

**User's choice:** Research all and synthesize one recommendation.
**Notes:** Tighten README opening copy around the brand-book language; keep feature bullets before the gallery. Use README as quick proof and `guides/recipes.md` as the richer gallery with larger images, captions, source-PDF hashes, PNG hashes, and manual SHA.

---

## the agent's Discretion

- Exact implementation technique for applying gallery fixture table polish.
- Exact fixture data, image sizes, and manual page count.
- Exact generated-copy wording, provided it preserves the proof/advisory split and brand-book voice.
- Exact task/module names, provided generation/checking stay explicit and deterministic.

## Deferred Ideas

- Full generated reference manual.
- README/HexDocs hero composite.
- Hosted playground.
- Charts, TOC, PDF.js render lane, broader text shaping, mobile viewer evidence, and launch execution work outside Phase 86.

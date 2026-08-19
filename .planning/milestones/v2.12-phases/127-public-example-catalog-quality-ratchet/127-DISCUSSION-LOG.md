# Phase 127: Public example catalog & quality ratchet - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-17
**Phase:** 127-public-example-catalog-quality-ratchet
**Areas discussed:** Catalog breadth and pairings, Preview and page coverage, Human-scored flagship set, Catalog ordering and metadata
**Method:** The user selected all areas and delegated a one-shot recommendation. Four typed `gsd-advisor-researcher` studies compared the live Rendro code/research/brand system with official ecosystem precedent, then the orchestrator reconciled their recommendations into one contract.

---

## Catalog breadth and pairings

| Option | Description | Selected |
|--------|-------------|----------|
| 30-cell two-pair grid | Six families × one unbranded light baseline plus two curated pairs in light/dark. Lowest cost, but either omits shipped Brutalist or drops one Phase-125 authored pair. | |
| 42-cell three-pair grid | Three light/dark pairs per family plus baselines. Uniform arithmetic and more variety, but creates contrived pairings and expands hash/review blast radius. | |
| 32-cell curated hybrid | Keep every Phase-125 recommended pair, add only Aurora Live Ticket × Brutalist light/dark, and enforce an exact ceiling. | ✓ |

**User's choice:** The user delegated the decision and asked for the single most coherent recommendation.

**Notes:** The 32-cell result is `6 baselines + 12 authored pairs × 2 modes + 1 Aurora/Brutalist pair × 2 modes`. It keeps all six shipped presets previewable without turning the catalog into a cross product. An explicit registry matches PhoenixStorybook/Storybook's “interesting states” approach better than automatically publishing every fixture combination: [PhoenixStorybook variations](https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html), [Storybook visual testing](https://storybook.js.org/docs/8/writing-tests/visual-testing).

---

## Preview and page coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Page-one raster only | Matches the existing launch gallery and keeps Phase 128 simple, but proves nothing about the complete rendered PDF unless paired with separate evidence. | |
| Every-page raster catalog | Gives a complete visual record, but artifact count, review fatigue, and future UI complexity scale with pagination. | |
| Page-one public preview plus complete-PDF and bounded multi-page proof | Commit one page-one PNG per cell, record the complete PDF hash/page count, and keep representative trailing-page proof outside the public tree. | ✓ |

**User's choice:** Delegated to the research-backed recommendation.

**Notes:** The selected hybrid keeps the catalog a browse surface rather than a PDF viewer. It follows the existing page-one gallery/pinned-renderer precedent and mature snapshot guidance that baselines require a stable environment and explicit acceptance: [Playwright snapshots](https://playwright.dev/docs/test-snapshots), [Chromatic baselines](https://docs.chromatic.com/docs/branching-and-baselines/). Alt text describes the visible page while captions carry purpose/context: [MDN text labels and names](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Understanding_WCAG/Text_labels_and_names).

---

## Human-scored flagship set

| Option | Description | Selected |
|--------|-------------|----------|
| Six light-only anchors | One score per family; cheapest, but dark catalog cells receive no human ratchet coverage. | |
| Twelve paired flagships | One curated pair per family reviewed in both light/dark, selected to cover all six shipped presets exactly once. | ✓ |
| Eighteen baseline-plus-pair triplets | Adds each unbranded baseline to the paired review; stronger comparison story but duplicates existing default evidence at 50% more review work. | |
| Full-grid human scoring | Every cell scored; conflicts with the locked flagship-subset policy and invites mechanical rubber-stamping. | |

**User's choice:** Delegated to the recommendation that best preserves honest human judgment.

**Notes:** The selected set is Cedar/Corporate Invoice, Northline/Swiss Payslip, Signal/Minimal Statement, Poppy/Humanist Receipt, Meridian/Editorial Certificate, and Aurora/Brutalist Ticket, each light/dark. All twenty remaining cells still need explicit hash-bound unscored dispositions. Stable reference artifacts and explicit baseline approval informed the freshness model: [Playwright snapshots](https://playwright.dev/docs/test-snapshots), [Chromatic baselines](https://docs.chromatic.com/docs/branching-and-baselines/), [Storybook snapshot-testing guidance](https://storybook.js.org/docs/writing-tests/snapshot-testing).

---

## Catalog ordering and metadata

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical domain-first cell contract | Stable explicit IDs/paths, baseline-first family groups, adjacent light/dark pairs, versioned manifest, and separate gen/check tasks. | ✓ |
| Variant-first catalog | Preset/brand before family; useful for a style showcase but weaker for the developer's “show me an invoice” job. | |
| Filesystem-derived manifest | Less declared data, but accidental fixture additions become public rows and order/identity drift silently. | |

**User's choice:** Delegated to the consumer/JTBD-first recommendation.

**Notes:** `Rendro.Catalog` stays internal; `mix rendro.catalog.gen` writes and `mix rendro.catalog.check` verifies without writing. Dot-namespaced tasks and help text follow standard Mix discoverability: [Mix.Task](https://hexdocs.pm/mix/Mix.Task.html). Stable explicit story metadata rather than inferred filesystem labels is also the successful Storybook pattern: [Component Story Format](https://storybook.js.org/docs/api/csf/index).

---

## the agent's Discretion

- Private helper names, JSON nesting, and the additive union representation for scored/unscored dispositions.
- Cache/parallelization details inside a generation run.
- Whether existing bounded pagination/raster proof already satisfies the final-page evidence requirement.
- Aurora Live's exact accent from the existing closed curated palette, stored as data and reviewed in the chosen Brutalist render.

## Deferred Ideas

- Phase 128: static configurator UI, URL state, exact-preview disclosure, shared copy/codegen template, theme generator, and Livebook.
- Phase 129: public docs, support matrix, README/HexDocs wiring, and claim-language tripwires.
- Every-page viewer/download UX, arbitrary-color preview approximation, live rendering, persistence/accounts, automated taste scoring, and any catalog expansion beyond the explicit 32-cell budget.

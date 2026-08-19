# Phase 129: Docs & manifest closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-19
**Phase:** 129-docs-manifest-closure
**Areas discussed:** Guide structure, Example depth, Claim presentation, Discoverability
**Method:** The user selected every area and delegated a one-shot recommendation. Four typed `gsd-advisor-researcher` studies examined the live project, current `brand/` source of truth, applicable `prompts/` research, Elixir/HexDocs/Phoenix/Ecto conventions, accessible documentation practice, and successful cross-ecosystem precedents.

---

## Guide Structure

| Option | Description | Selected |
|--------|-------------|----------|
| New `guides/presets.md` only | Focused and searchable, but risks becoming an orphan or duplicating theming boundaries. | |
| Extend `guides/theming.md` only | Lowest navigation cost, but mixes manual-token reference with the new browse/copy/adopt journey. | |
| Hybrid presets hub plus theming deep-link | Canonical task guide for presets with the existing theming guide retained as the manual-token reference. | ✓ |

**User's choice:** Delegated; selected the coherent research recommendation.
**Notes:** `guides/presets.md` becomes the stable task path. README and ExDoc expose it; `guides/theming.md` links to it early and remains focused. Current `brand/` sources override the historical prompt brand book on conflict.

---

## Example Depth

| Option | Description | Selected |
|--------|-------------|----------|
| One golden-path quick start | Maximizes initial copy-paste success but hides the broader preset vocabulary. | |
| Exhaustive all-six-preset reference | Complete inventory, but duplicates code, increases drift, and can imply unsupported visual ranking. | |
| Task-oriented progressive disclosure | Strong job alignment, but needs a compact comparison reference and disciplined links. | |
| Hybrid golden path, compact reference, and task routes | One executable path plus a six-row chooser and distinct routes to configurator, generator, Livebook, and manual theming. | ✓ |

**User's choice:** Delegated; selected the coherent research recommendation.
**Notes:** Use Invoice × Swiss × `#2C6BED` × light and the exact formatter-owned snippet. Preserve explicit font registration. Do not create six tutorials or claim 504 visual reviews from 504 syntactically valid snippets.

---

## Claim Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Central disclaimer only | Easy to maintain, but too far from dark/preview/quality decisions and likely to be missed. | |
| Contextual repeated disclosure | Places truth at decision time, but can create warning fatigue and wording drift. | |
| Layered canonical boundary plus local microcopy | One complete support contract plus concise state-specific disclosure beside each relevant decision. | ✓ |
| Proof-artifact-first status page | Maximally auditable, but poor onboarding and too operational for the primary reader. | |

**User's choice:** Delegated; selected the coherent research recommendation.
**Notes:** The `theming.presets` support row is canonical. Guide copy establishes the strong-starting-point boundary; dark, preview, and quality states retain their precise local wording. Documentation uses semantic structure, descriptive links, text alternatives, and visible non-color status text.

---

## Discoverability

| Option | Description | Selected |
|--------|-------------|----------|
| Guide-list-only wiring | Smallest change, but leaves the milestone's main public surfaces effectively hidden. | |
| README feature block plus guide links | Good discovery, but can turn README into a duplicate guide without strict scope. | |
| Dedicated documentation hub | Scalable but disproportionate, duplicative, and costly for the bounded v2.12 surface. | |
| Layered minimal routes | Compact README entry → canonical presets guide → job-specific configurator/generator/Livebook/support links. | ✓ |

**User's choice:** Delegated; selected the coherent research recommendation.
**Notes:** README remains ExDoc's main page. Presets joins Theming in the existing Guides group. API Stability remains the support-boundary destination. Source, Hex package, and generated ExDoc links must all be proven.

---

## the agent's Discretion

- Section titles and exact compact-table columns.
- Exact support-matrix subkeys, provided they preserve the locked capability/evidence/boundary semantics.
- The new cross-surface claims test's module/file name.
- Cross-context link syntax that resolves correctly in the source tree, Hex package, and generated ExDoc output.
- Minor copy edits that preserve the locked meaning and canonical phrases.

## Deferred Ideas

- Reconsider a standalone documentation hub only if the future live Studio introduces enough interactive surfaces to outgrow README → guide routing.
- Preset expansion, catalog expansion, arbitrary live preview, exhaustive visual review, and server-backed Studio work remain outside Phase 129.

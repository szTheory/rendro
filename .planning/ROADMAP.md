# Roadmap: Rendro

## Overview

Rendro has shipped two verified milestones. `v1.0` proved the pure-core rendering and trust contract; `v1.1` shipped the layout-authoring maturity needed for serious document composition. The active milestone is now `v1.2`, which turns that authoring base into a truthful branded-document surface through deterministic typography, assets, and honest Unicode/i18n boundaries. If `v1.2` closes cleanly, the next milestone should promote first public Hex release readiness ahead of async artifact expansion.

## Active Milestone

### Milestone v1.3: First Public Hex Release Readiness

**Status:** Active
**Planned Phases:** 31-33

`v1.3` prepares Rendro for its first public Hex release. It ensures licensing, metadata, documentation organization, and explicit API support boundaries are established before the package is published.

#### Phase 31: Licensing and Hex Metadata
**Goal:** Finalize the project's open-source license and ensure Hex package metadata accurately reflects the project.
**Requirements:** [REL-01, REL-02]

**Plans:** 1/1 plans

Plans:
- [x] 31-01-PLAN.md — Finalize open-source license and Hex metadata

#### Phase 32: Documentation and Support Boundaries
**Goal:** Polish the public-facing documentation surfaces and explicitly declare the project's API stability policy.
**Requirements:** [REL-03, REL-04, REL-05]

Planned work:
- Update `mix.exs` to configure `groups_for_extras` for ExDoc, rationally organizing guides and references.
- Add status badges (CI, Hex.pm version, HexDocs) to the top of `README.md`.
- Draft a `usage_rules.md` (or equivalent API policy document) to define the first public release support boundaries and API stability expectations.
- Scan public modules for stability and document the deprecation policy.

#### Phase 33: Release Preflight and Proof
**Goal:** Verify the release artifacts and dry-run the Hex publication process.
**Requirements:** [REL-06]

Planned work:
- Extend the `mix release.preflight` task (or CI equivalent) to include `mix hex.publish --dry-run`.
- Verify that the generated Hex package includes the necessary files (e.g., `LICENSE`, `README.md`, `usage_rules.md`) via `mix hex.build --unpack`.
- Ensure all CI workflows and visual UAT checks pass cleanly on the finalized release surface.

## Milestones

- <details><summary><b>Milestone v1.2</b> (Shipped 2026-05-03)</summary>
  Deterministic typography, assets, and honest Unicode/i18n boundaries for branded business documents. Planned phases: 25-30.
  </details>

- <details><summary><b>Milestone v1.0</b> (Shipped 2026-04-28)</summary>
  MVP delivered. Core pure rendering, layout primitives, Phoenix adapters, rigorous CI verification.
  See [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.0-ROADMAP.md) for full phase details.
  </details>
- <details><summary><b>Milestone v1.1</b> (Shipped 2026-04-30)</summary>
  Layout authoring maturity delivered: explicit page templates and regions, deterministic wrapped text and keep/break semantics, stronger table continuation, public diagnostics/proof surfaces, and canonical recipes.
  See [.planning/milestones/v1.1-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.1-ROADMAP.md) for full phase details.
  </details>

## Next Milestones

- **Milestone v1.3: First Public Hex Release Readiness** — Promote `Phase 999.1` into active milestone scope after `v1.2` proves the branded-document support boundary.
- **Milestone v1.4: Async Delivery and Artifact Operations** — Add queued render lifecycle, artifact metadata, and persistence/sink contracts after the public release boundary is defined.
- **Milestone v1.5: Validation and Trust Surfaces** — Add validator-backed support evidence and stronger machine-readable trust/reporting surfaces.

## Backlog

*(No backlog items currently planned)*

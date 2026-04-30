# Roadmap: Rendro

## Overview

Rendro has shipped two verified milestones. `v1.0` proved the pure-core rendering and trust contract; `v1.1` shipped the layout-authoring maturity needed for serious document composition. There is no active milestone yet. The next planning pass should decide how much of typography/assets to take on next and whether public Hex release readiness belongs in that same milestone or later.

## Milestones

- <details><summary><b>Milestone v1.0</b> (Shipped 2026-04-28)</summary>
  MVP delivered. Core pure rendering, layout primitives, Phoenix adapters, rigorous CI verification.
  See [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.0-ROADMAP.md) for full phase details.
  </details>
- <details><summary><b>Milestone v1.1</b> (Shipped 2026-04-30)</summary>
  Layout authoring maturity delivered: explicit page templates and regions, deterministic wrapped text and keep/break semantics, stronger table continuation, public diagnostics/proof surfaces, and canonical recipes.
  See [.planning/milestones/v1.1-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.1-ROADMAP.md) for full phase details.
  </details>

## Backlog

### Phase 999.1: First Hex Release Readiness (BACKLOG)
**Goal**: Decide whether Rendro is ready for a truthful first public Hex.pm release and close the remaining packaging, proof, and support-boundary work required to publish.
**Source**: `SEED-001`
**Deferred at**: 2026-04-30 during `v1.1` milestone-close preflight
**Notes**:
- Existing release preflight coverage already exercises `mix hex.build --unpack` and `mix hex.publish --dry-run --yes`.
- This remains backlog until the next milestone explicitly chooses public release readiness as scope.

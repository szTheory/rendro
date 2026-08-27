# Phase 135: Test & CI/CD Simplification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-27
**Phase:** 135-test-ci-cd-simplification
**Areas discussed:** Test consolidation targets and stopping rule, Replacement tests with teeth, Catalog artifact packaging, Parity and legacy-route retirement

---

## Test Consolidation Targets and Stopping Rule

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded candidate-only cleanup | Act only on candidates with the same observable behavior/failure contract and a demonstrated maintenance benefit; allow an evidence-backed no-op. | ✓ |
| Evidence-gated suite-wide inventory | Review the full suite for overlap before choosing targets. | |
| Broad structural consolidation | Introduce shared fixtures/macros and reorganize test families broadly. | |

**User's choice:** Discuss all options, research them with expert subagents, and select the best coherent recommendation without requiring further user decisions.
**Notes:** The selected recommendation applies bounded cleanup to the phase-number workflow contracts, the one duplicated Payslip end-to-end render, and the overstated Certificate test name. Elixir/Phoenix/Ecto/Plug conventions were considered from the consumer and maintainer perspective; their shared-case patterns do not justify importing framework/database abstractions into Rendro's pure suite.

---

## Replacement Tests With Teeth

| Option | Description | Selected |
|--------|-------------|----------|
| In-memory contract negative controls | Pair every retained positive contract with one minimal broken fixture/state/manifest that fails at the intended assertion. | ✓ |
| Temporary isolated source mutation | Patch production code temporarily to show the retained test fails. | Diagnostic fallback only |
| Selective StreamData properties | Use property tests for general pure invariants with strong oracles. | Complement only |
| Automated mutation-testing tooling | Add a tool/service and mutation score. | |

**User's choice:** Asked for a one-shot expert recommendation emphasizing sound architecture, DX, least surprise, and ecosystem lessons.
**Notes:** The selected policy retains exact error/byte/hash oracles, forbids golden re-blessing as closure, and avoids speculative tooling. Temporary source mutation is not durable evidence and is allowed only when no in-memory seam can represent the original defect.

---

## Catalog Artifact Packaging

| Option | Description | Selected |
|--------|-------------|----------|
| One manifest-rooted bundle per operation/run | One download and authority boundary containing README, schema-valid manifest, checksum inventory, and closed payload subpaths. | ✓ |
| Separate candidate/final/multipage/canonical artifacts | Preserve multiple independently uploaded payload classes. | |
| Authoritative bundle plus convenience artifacts | Upload a canonical bundle and duplicate selected payloads for convenience. | |

**User's choice:** Asked for a cohesive, user-friendly recommendation across maintainer, reviewer, SRE, security, and developer-experience lenses.
**Notes:** The selected design uses exact operation/full-SHA/run/attempt naming, 30-day bounded retention, one textual job summary, `contents: read`, no secrets/caches, and no attestations. GitHub Actions is the only UI surface; text never relies on color or screenshots for authority.

---

## Parity and Legacy-Route Retirement

| Option | Description | Selected |
|--------|-------------|----------|
| One old/new comparison per generic operation | Compare one review and one canonical run without enumerating every legacy route. | |
| Repeated generic runs at one SHA | Establish generic reproducibility but not legacy equivalence. | Corroboration only |
| Route-by-route old/new parity matrix | Compare each Phase 126/127/130 operation once against the generic workflow at the same full SHA. | ✓ |

**User's choice:** Asked for the expert recommendation that best preserves reliability, security, evidence authority, and operator ergonomics.
**Notes:** Four matrix rows are required. Local tests own workflow/manifest/comparator/security shape; remote Ubuntu/PDFium owns raster payload identity; human review remains Phase 136. Legacy and generic routes coexist until parity passes, then one dedicated deletion commit becomes the rollback unit.

## the agent's Discretion

- Exact helper/module/schema names and implementation language for parity normalization.
- Exact safe subdirectory names within the single artifact bundle.
- Exact adjacent repository-native runbook path and internal plan boundaries before the dedicated cutover commit.

## Deferred Ideas

- Whole-suite shared-fixture/test-macro architecture and global mutation scoring, pending a concrete recurring cost or false-negative finding.
- Artifact attestations, pending a real verifier and explicit authorization for the additional write permissions.
- Visual changes, rubric scores, and human catalog approval remain Phase 136 work.

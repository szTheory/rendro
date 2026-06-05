# Phase 82: 1.0.0 Consolidation & Publish — Context

This phase handles the final, irreversible 1.0.0 publish to Hex.

## Carryover from Phase 81 (Blockers)

An audit of Phase 81 (`.planning/phases/81-release-hardening/81-01-SUMMARY.md`) revealed that while CI was SHA-pinned and repo hygiene scripts were added, two critical release-hardening requirements were missed and must be handled here before the CHANGELOG is consolidated:

- **REL-02 (Tarball Audit Gap)**: `lib/mix/tasks/release/preflight.ex` currently checks that required files are present in the hex build, but it does NOT verify the **absence** of operator/evidence artifacts (`priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, `test/`). It also missing `mix hex.audit`, `mix deps.audit`, and a `source_ref` parity check. This must be added to `preflight.ex`.
- **REL-03 (CHANGELOG Self-Block Gap)**: `lib/mix/tasks/release/preflight.ex` (`check_changelog_release_tail/1`) currently hardcodes a check for `## [#{version}] - Unreleased` and a brittle pointer string. If not generalized to accept a dated `## [1.0.0] - YYYY-MM-DD` header, the preflight will fail and block the 1.0.0 cut.

## Native Phase 82 Scope

- **REL-04 (Consolidation)**: Consolidate `CHANGELOG.md`. The currently-stubbed `## [0.3.1] - Unreleased` (v2.3 viewer-evidence) + the uncatalogued v2.4 features + the Phase 78-80 stability/cleanup work must all be rolled into a single `## [1.0.0] - <date>` entry. It needs a "Stability" subsection linking the upgrade guide.
- **REL-06 (Publish Sequence)**: 
  - Update `mix.exs` to `1.0.0`.
  - The actual Hex publish is tag-triggered in CI (`.github/workflows/release.yml` triggers on `v*.*.*`).
  - The operator or CI cuts the tag `v1.0.0`, pushes it, and the GitHub Action publishes to Hex. 
  - Post-publish verification (tarball spot-check, HexDocs render check, version shield).

## Execution Directives

1. **Pre-requisite Plan**: Create a plan to fix REL-02 and REL-03 in `preflight.ex` first.
2. **Consolidation Plan**: Create a plan to update `CHANGELOG.md` and `mix.exs` to `1.0.0`.
3. **Publish Plan**: Document the exact manual operator commands required to cut the tag, wait for CI, and verify the publish. Since Hex publish is irreversible, the agent must NOT run the `git tag` or `git push` commands autonomously; it must provide them for the operator to run manually at the end of the phase.

*Context synthesized 2026-06-05 by gsd-discuss-phase.*
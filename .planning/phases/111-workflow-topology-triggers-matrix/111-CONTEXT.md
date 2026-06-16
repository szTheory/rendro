# Phase 111: Workflow Topology, Triggers & Matrix - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Reshape the GitHub Actions CI/CD workflow graph into a coherent fast-PR / main / nightly / release model. The goal is to minimize the critical path, merge duplicated setup steps across advisory and live-proof jobs, cancel superseded PR runs, define a clear version-matrix policy, and expose exactly one stable required-check name for branch protection.

</domain>

<decisions>
## Implementation Decisions

### Live-proof and Advisory Topology
- **D-01:** Merge the 4 `live-proof` jobs (`viewer-evidence`, `signing`, `long-lived`, `release-proof`) into a single `integration-proofs` job that runs sequentially and depends on the `test` job. 
- **D-02:** Merge the 4 `advisory` jobs (`raster`, `comparison`, `livebook`, `pdfjs`) into a single `advisory-checks` job that runs sequentially, has no `needs:` (graph-disconnected), and sets `continue-on-error: true`.
- **D-03:** *Rationale:* Grouping these jobs eliminates redundant checkout and VM setup overhead (1-2 minutes per job), saving significant runner minutes while retaining full test coverage. This is idiomatic for Elixir/Phoenix OSS projects where tests are grouped into fewer jobs unless massive parallelization is needed.

### Summary Gate Job
- **D-04:** Implement a final dependent job (e.g., `ci-success`) using `if: always()` that depends on all required jobs. It must evaluate `needs.*.result` to ensure all prerequisites are either `success` or explicitly `skipped` (due to matrix).
- **D-05:** *Rationale:* Provides a single, stable required-check name for GitHub branch protection (satisfies FLOW-05) without the brittleness of path/branch/skip-directive pending-check traps or Status API calls.

### Concurrency Cancellation
- **D-06:** Apply concurrency using `group: ${{ github.workflow }}-${{ github.ref }}` and set `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.
- **D-07:** *Rationale:* Cancels superseded PR runs immediately (FLOW-02) but ensures that `main` branch pushes and release tags are never canceled, preserving vital caching and release workflows.

### Triggers & Matrix Scope
- **D-08:** The `pull_request` trigger runs the test suite on the primary target only (latest OTP/Elixir) to serve as a fast gate.
- **D-09:** A scheduled nightly trigger (`schedule:`) runs the broad version matrix (minimum and latest supported versions) to protect compatibility without slowing down PRs (FLOW-04). Lint and static analysis checks run strictly once on the primary version.

### Claude's Discretion
- The user delegated deep-dive architectural decisions entirely to Claude. All decisions above reflect a cohesive, one-shot "perfect" recommendation optimized for developer ergonomics, CI efficiency, and Elixir ecosystem best practices.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CI Configuration
- `.github/workflows/ci.yml` — Current CI definition to be refactored.
- `.github/workflows/release.yml` — Release workflow that relies on the main CI outcomes.

### Requirements & Context
- `.planning/REQUIREMENTS.md` § FLOW-01 to FLOW-05 — Core requirements for this phase.
- `.planning/phases/108-baseline-audit-report/C1-AUDIT.md` — The original CI audit providing baseline timings and pipeline architecture goals.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `setup-beam` step: Pinned to `erlef/setup-beam@v1` with explicit SHA. Can be factored into a local composite action if setup logic needs DRYing further across workflows, though merging jobs reduces the need.

### Established Patterns
- The `test` job currently exports a `CI Baseline Summary` to `$GITHUB_STEP_SUMMARY`. The new `ci-success` or combined jobs should ensure they do not overwrite but append or cleanly present their own summaries.

### Integration Points
- `.github/workflows/ci.yml` is the primary integration point. Branch protection rules (implied) will need to target the new `ci-success` job name.

</code_context>

<specifics>
## Specific Ideas

- Emphasize developer ergonomics: The CI must be fast on PRs (single target version) and robust on main. 
- Use standard, proven GitHub Actions patterns (like the `always()` gate job) rather than custom scripts.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 111-Workflow Topology, Triggers & Matrix*
*Context gathered: 2026-06-16*
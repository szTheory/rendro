# Phase 113: DX, Local Reproducibility & Validation - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

DX, Local Reproducibility & Validation. 
This phase delivers 1:1 local reproducibility of the CI gates, actionable CI failure reporting, accurate README badging, and metric-backed validation of the pipeline's before/after performance improvements.
</domain>

<decisions>
## Implementation Decisions

### `mix ci` Parity Approach
- **D-01:** **Decompose `mix ci` into scoped aliases.** Introduce `mix ci.fast` (format, compile, credo, fast tests), `mix ci.proofs` (integration and live proofs), and `mix ci.advisory` (advisory checks).
- **D-02:** **The root `mix ci` alias runs `ci.fast` followed by `ci.proofs`.** It should represent the *required* merge gate, omitting advisory checks. 
- **Rationale:** Developer ergonomics and the principle of least surprise. If a developer needs to reproduce a failure in the integration proofs, they shouldn't have to run the entire monolith. This perfectly mirrors the new GitHub Actions topology (Phase 111).

### Exposing CI Warnings
- **D-03:** **Utilize both GitHub Problem Matchers AND Step Summaries.** 
- **D-04:** Use Problem Matchers for warnings (e.g., compiler warnings, Credo, Dialyzer) so they appear inline on the PR diff.
- **D-05:** Use Step Summaries (`$GITHUB_STEP_SUMMARY`) to consolidate test timings, cache hits, and overall pipeline health.
- **Rationale:** Actionability. A developer reviewing a PR needs to see warnings exactly where the code changed (Problem Matchers), but an operator investigating a build failure needs a high-level overview of what failed and why (Step Summary).

### README Badge Reflection
- **D-06:** **The README status badge MUST target the `ci-success` job, not the overall workflow.**
- **Rationale:** The `ci.yml` workflow contains advisory jobs that are allowed to fail (`continue-on-error: true`). If the badge targets the workflow, it will appear failing/yellow when the core library is actually healthy. Targeting `ci-success` guarantees the badge is 100% truthful to the required merge gate.

### Metric Validation
- **D-07:** **Record final before/after metrics in `113-METRICS.md` and append a summary to `C1-AUDIT.md`.**
- **Rationale:** Provides an immutable snapshot of the improvements delivered by the C1 milestone without polluting the repository root.

### Claude's Discretion
- The user delegated deep-dive architectural decisions entirely to Claude. All decisions above reflect a cohesive, one-shot "perfect" recommendation optimized for developer ergonomics, CI efficiency, and Elixir ecosystem best practices, directly leveraging the Rendro OSS DNA and brand constraints.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — DX-01 to DX-04, VAL-01 to VAL-02
- `prompts/rendro-oss-dna.md` — Canonical OSS DNA for CI and DX expectations
- `.planning/phases/108-baseline-audit-report/C1-AUDIT.md` — Baseline metrics
- `.github/workflows/ci.yml` — The target GitHub actions file to annotate and summarize.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` aliases currently hold the monolithic `mix ci` command.

### Established Patterns
- Step summaries are currently manually echoed in Phase 108 baseline.
- `ci-success` job established in Phase 111.

### Integration Points
- `mix.exs`: Updating the `aliases/0` function.
- `README.md`: Updating the CI badge markdown.
- `CONTRIBUTING.md`: Documenting the new `mix ci.*` aliases and local reproduction steps.
</code_context>

<specifics>
## Specific Ideas

- Focus on the "threadline" OSS pattern: explicit entrypoints (`mix verify.phase_nn`) over magic.
</specifics>

<deferred>
## Deferred Ideas

None
</deferred>

---

*Phase: 113-DX, Local Reproducibility & Validation*
*Context gathered: 2026-06-16*
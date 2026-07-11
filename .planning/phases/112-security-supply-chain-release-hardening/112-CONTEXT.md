# Phase 112: Security, Supply-chain & Release Hardening - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

CI/CD security constraints, dependency audits, and release workflow hardening.
This phase delivers pinned third-party actions, least-privilege action permissions,
strict automated version validation before Hex publish, and reliable network-resilient
security audits, ensuring the pipeline remains deterministic and secure.

</domain>

<decisions>
## Implementation Decisions

### Dependabot configuration
- **D-01:** Scope: Monitor both `mix` (Hex) and `github-actions`.
- **D-02:** Frequency: `weekly` (e.g., Monday mornings). *Note: Dependabot Security Updates will still open PRs immediately for critical CVEs regardless of this schedule.*
- **D-03:** Grouping Strategy: Utilize Dependabot's grouping feature to minimize PR fatigue:
    - Group 1: `elixir-dev-tools` (Group `ex_doc`, `credo`, `dialyxir`, `mix_audit`, `bypass`). These rarely break runtime behavior and can be batch-merged safely.
    - Group 2: `github-actions` (Group `actions/checkout`, `erlef/setup-beam`, etc.).
    - Group 3: `runtime-minor-patch` (Group minor/patch updates for any core runtime dependencies).

### Audit lane placement
- **D-04:** PR Lane (Advisory/Informational): Run `mix deps.audit` and `mix hex.audit` as a discrete job in the main CI workflow, but set `continue-on-error: true`. It provides immediate context to reviewers without blocking community PRs on upstream CVEs.
- **D-05:** Nightly Lane (Actionable): Implement a scheduled nightly workflow (e.g., `audit.yml`) that strictly runs the audits. If it fails, use the `peter-evans/create-issue-from-file` action to automatically create (or update) a rolling "Security Audit Failure" issue assigned to the maintainers.

### Release tag validation
- **D-06:** Automated Validation (The Lock): The release workflow MUST contain a step that extracts the version from `mix.exs` and asserts it exactly matches the triggered `github.ref_name` (e.g., asserting `1.0.0` == `v1.0.0` sans 'v'). If this fails, the workflow hard-stops.
- **D-07:** Environment Approval Gate (The Key): Configure a GitHub Environment named `Hex Publish`.
    - Scope the `HEX_API_KEY` secret *only* to this environment.
    - Require manual approval from specific maintainers on the environment.
    - The workflow does a `mix hex.publish --dry-run` and prints the output. It then pauses. A maintainer reviews the dry-run output in the GitHub UI and clicks "Approve and Deploy" to trigger the actual publish.

### Claude's Discretion
None

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Security & Release Architecture
- `milestones/C1-AUDIT-BRIEF.md` — The canonical infra milestone brief defining SEC-01 through SEC-04.
- `prompts/rendro-oss-dna.md` — OSS library constraints: "Production is a feature" and explicit requirement for "Release safety checks before publish".

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix release.preflight`: Existing alias in `mix.exs` providing baseline release checks before Hex publish.

### Established Patterns
- `ci.yml`: The existing CI setup provides separate advisory and required lanes. Our new PR audit jobs (`hex.audit`/`deps.audit`) should join the advisory lane.
- `erlef/setup-beam@8251c486...`: Current SHA-pinned action in `ci.yml` – all new workflows must maintain exact SHA pinning.

### Integration Points
- `.github/workflows/ci.yml`: Expand to include advisory audit checks.
- `.github/workflows/release.yml`: Refactor to add GitHub Environment gates and `mix.exs` version extraction logic.
- `.github/dependabot.yml`: Create/update for Dependabot configuration.
- `.github/workflows/audit.yml`: Create for Nightly strict auditing.

</code_context>

<specifics>
## Specific Ideas

- Strict separation of code-correctness failures from ecosystem-environment failures. Breaking a PR for code the contributor didn't write violates the principle of least surprise.
- Use `peter-evans/create-issue-from-file` in the Nightly audit for tracking.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 112-Security, Supply-chain & Release Hardening*
*Context gathered: 2026-06-16*

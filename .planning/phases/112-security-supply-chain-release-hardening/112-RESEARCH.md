# Phase 112: Security, Supply-chain & Release Hardening - Research

**Researched:** 2026-06-16
**Domain:** CI/CD security constraints, dependency audits, and release workflow hardening
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Dependabot configuration
- **D-01:** Scope: Monitor both `mix` (Hex) and `github-actions`.
- **D-02:** Frequency: `weekly` (e.g., Monday mornings). *Note: Dependabot Security Updates will still open PRs immediately for critical CVEs regardless of this schedule.*
- **D-03:** Grouping Strategy: Utilize Dependabot's grouping feature to minimize PR fatigue:
    - Group 1: `elixir-dev-tools` (Group `ex_doc`, `credo`, `dialyxir`, `mix_audit`, `bypass`). These rarely break runtime behavior and can be batch-merged safely.
    - Group 2: `github-actions` (Group `actions/checkout`, `erlef/setup-beam`, etc.).
    - Group 3: `runtime-minor-patch` (Group minor/patch updates for any core runtime dependencies).

#### Audit lane placement
- **D-04:** PR Lane (Advisory/Informational): Run `mix deps.audit` and `mix hex.audit` as a discrete job in the main CI workflow, but set `continue-on-error: true`. It provides immediate context to reviewers without blocking community PRs on upstream CVEs.
- **D-05:** Nightly Lane (Actionable): Implement a scheduled nightly workflow (e.g., `audit.yml`) that strictly runs the audits. If it fails, use the `peter-evans/create-issue-from-file` action to automatically create (or update) a rolling "Security Audit Failure" issue assigned to the maintainers.

#### Release tag validation
- **D-06:** Automated Validation (The Lock): The release workflow MUST contain a step that extracts the version from `mix.exs` and asserts it exactly matches the triggered `github.ref_name` (e.g., asserting `1.0.0` == `v1.0.0` sans 'v'). If this fails, the workflow hard-stops.
- **D-07:** Environment Approval Gate (The Key): Configure a GitHub Environment named `Hex Publish`.
    - Scope the `HEX_API_KEY` secret *only* to this environment.
    - Require manual approval from specific maintainers on the environment.
    - The workflow does a `mix hex.publish --dry-run` and prints the output. It then pauses. A maintainer reviews the dry-run output in the GitHub UI and clicks "Approve and Deploy" to trigger the actual publish.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| D-01/02/03 | Dependabot Configuration | Explored exact syntax for `dependabot.yml` grouping and scheduling |
| D-04 | PR Lane Audit Checks | Adding discrete job with `continue-on-error: true` in `ci.yml` |
| D-05 | Nightly Audit Lane | Creating `audit.yml` schedule workflow using `peter-evans/create-issue-from-file` |
| D-06 | Automated Release Version Validation | Extract version using `Mix.Project.config()[:version]` or regex to assert match |
| D-07 | GitHub Environment Gate | Architecting `release.yml` with separate `dry-run` and `publish` (w/ environment) jobs |
</phase_requirements>

## Summary

This phase hardens the repository's supply-chain and release architecture by bringing automated dependency management, split-lane security auditing, and strict human-in-the-loop release gates. The core outcomes are reducing PR fatigue via Dependabot grouping, maintaining ecosystem safety without blocking forks via an advisory PR audit lane and an actionable nightly strict lane, and preventing accidental tag publishing by enforcing an exact version string match accompanied by a manual GitHub Environment approval step.

**Primary recommendation:** Implement the Dependabot configuration with clear group blocks, split `release.yml` into a two-job topology (`dry-run` then `publish` via environment), and use pinned third-party actions for the nightly audit issue generation to maintain a deterministic pipeline.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency Monitoring | CI / Dependabot | — | `.github/dependabot.yml` owns ecosystem scans. |
| PR Audit Checks | CI / PR Gate | — | `ci.yml` `advisory-audits` job provides non-blocking PR-time alerts. |
| Nightly Audit Tracking | CI / Scheduled | GitHub Issues | `audit.yml` guarantees actionable tracker issues on regression. |
| Release Verification | CI / Release Gate | — | `release.yml` guarantees tag and project config sync before publish. |

## Standard Stack

### Core
| Library / Action | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `actions/checkout` | `v6.0.3` | Code retrieval | Native, used everywhere |
| `erlef/setup-beam` | `v1` (pinned SHA) | Erlang/Elixir environment | Proven and standard in Elixir ecosystem |
| `peter-evans/create-issue-from-file` | `v6.0.0` (pinned SHA) | Nightly issue generation | Reliable, stateless way to integrate CI failures with repo issues |

*Note: All third-party GitHub Actions MUST use exact SHA pinning.*
*`peter-evans/create-issue-from-file@fca9117c27cdc29c6c4db3b86c48e4115a786710` resolves to `v6.0.0`.*

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `peter-evans/create-issue-from-file` | `gh issue create` (GitHub CLI) | `gh` CLI requires manual boilerplate for formatting, updating existing issues, and idempotent checks; the third-party action handles tracking updates out-of-the-box. |

## Architecture Patterns

### System Architecture Diagram
(Conceptual logic for Release Gate)
`Tag Push` → `checkout` → `assert v<mix_version> == tag` (fails if mismatched) → `mix hex.publish --dry-run` → **[Pause] GitHub Environment Request** → `Maintainer clicks Approve` → `mix hex.publish --yes`

### Recommended Project Structure
```
.github/
├── dependabot.yml       # New file for Dependabot configuration
└── workflows/
    ├── ci.yml           # Modified to include advisory audit job
    ├── release.yml      # Refactored for two-job Environment approval
    └── audit.yml        # New file for Nightly strict auditing
```

### Pattern 1: Split-Job Release Approval Gate
**What:** Decoupling the "dry run" feedback from the "actionable" deployment.
**When to use:** When human review of pipeline stdout is required before releasing packages to a registry.
**Example:**
```yaml
jobs:
  dry_run:
    runs-on: ubuntu-latest
    steps:
      - run: mix release.preflight
      - run: mix hex.publish --dry-run

  publish:
    runs-on: ubuntu-latest
    needs: dry_run
    environment: "Hex Publish" # Configured in GitHub Settings with required reviewers
    steps:
      - run: mix hex.publish --yes
```

### Pattern 2: Elixir Version Extraction
**What:** Programmatically fetching the version from `mix.exs` without complex regex matching.
**When to use:** Validating GitHub tag parity.
**Example:**
```bash
MIX_VERSION=$(elixir -e "IO.puts Mix.Project.config()[:version]")
if [ "v${MIX_VERSION}" != "${{ github.ref_name }}" ]; then
  echo "Tag mismatch!" && exit 1
fi
```

### Pattern 3: Dependabot Grouping
**What:** Batching related low-risk dependencies into single PRs to prevent noise.
**Example:**
```yaml
groups:
  elixir-dev-tools:
    patterns:
      - "ex_doc"
      - "credo"
      - "dialyxir"
      - "mix_audit"
      - "bypass"
```

### Anti-Patterns to Avoid
- **Implicit Approvals:** Placing `environment: Hex Publish` on the same job that generates the `dry-run` output. The environment gate blocks the job from even starting, preventing maintainers from reading the dry-run output before making their decision.
- **Loose Action Tags:** Using `@v2` instead of full SHA pinning in the workflow files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Issue idempotency | Bash script with `gh issue list` | `peter-evans/create-issue-from-file` | Handles issue updates (vs endless duplicates) natively |
| Version mismatch parsing | Bash `grep` or `awk` | `elixir -e "..."` | `Mix.Project` parses the exact internal version safely |

## Common Pitfalls

### Pitfall 1: Dependabot Schedule Overwrite PRs
**What goes wrong:** Fast-moving dev tools (like `ex_doc`) get a PR on Monday, but an author pushes to main on Tuesday. Dependabot force-pushes a rebase, discarding any manual CI fixes.
**Why it happens:** Dependabot handles its grouping PRs as a continuous moving target.
**How to avoid:** Accept that Dependabot PRs are disposable until approved. Ensure the `ci.yml` advisory checks provide clear diagnostic output.

### Pitfall 2: CI Lane Over-strictness
**What goes wrong:** A PR by a community contributor fails because an external package got a CVE.
**Why it happens:** The `deps.audit` job runs as a required check.
**How to avoid:** Explicitly define `continue-on-error: true` on the `advisory-audits` job in `ci.yml` (as mandated by D-04).

## Code Examples

### Dependabot Grouping Syntax
```yaml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      elixir-dev-tools:
        patterns:
          - "ex_doc"
          - "credo"
          - "dialyxir"
          - "mix_audit"
          - "bypass"
      runtime-minor-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
```

## Assumptions Log

If this table is empty: All claims in this research were verified or cited — no user confirmation needed.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

*(Empty)*

## Open Questions (RESOLVED)

None. The exact requirements from CONTEXT.md map cleanly to standard GitHub Actions and Mix behaviors.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond standard runner environments).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + GitHub Actions |
| Config file | `.github/workflows/*.yml` |
| Quick run command | `mix test` |
| Full suite command | `mix ci` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-01 | Dependabot | syntax | `gh workflow check` / YAML parse | ❌ Need to create |
| D-04 | Advisory Audit | smoke | `mix deps.audit` | ✅ `ci.yml` |
| D-06 | Version Lock | unit | `elixir -e "..."` check | ❌ Add to `release.yml` |
| D-07 | Env Gate | manual | GitHub UI "Approve" button | ❌ Configure in repo settings |

### Sampling Rate
- **Per task commit:** Workflow logic verification locally.
- **Per wave merge:** Execute GitHub Actions pipeline.
- **Phase gate:** Full suite green before `/gsd:verify-work`.

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V14 Configuration | yes | Dependabot, SHA-pinned Actions |
| V10 Malicious Code | yes | Split-lane `mix deps.audit` / `hex.audit` |

### Known Threat Patterns for GitHub Actions / CI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious Dependency Subversion | Tampering | `mix deps.audit` + Dependabot |
| Improper Release Tagging | Repudiation | Enforce script-level `mix.exs` exact match before publish |
| Unauthorized Hex Publish | Elevation of Privilege | Require GitHub Environment manual gate with scoped `HEX_API_KEY` |

## Sources

### Primary (HIGH confidence)
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `mix.exs`
- `milestones/C1-AUDIT-BRIEF.md`

### Secondary (MEDIUM confidence)
- Official GitHub Actions Documentation (Grouping Syntax, Environment Protection Rules).
- Official Mix/Hex Documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Extracted from current repository state and official specs.
- Architecture: HIGH - Matches the explicitly designed topology constraints in `CONTEXT.md`.
- Pitfalls: HIGH - Addressed through precise D-04 and D-07 directives.

**Research date:** 2026-06-16
**Valid until:** 2026-07-16

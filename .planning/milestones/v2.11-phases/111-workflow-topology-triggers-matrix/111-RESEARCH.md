# Phase 111: Workflow Topology, Triggers & Matrix - Research

**Researched:** 2026-06-16
**Domain:** GitHub Actions CI/CD Pipeline Architecture
**Confidence:** HIGH

## Summary

This phase restructures the GitHub Actions workflow graph for Rendro to dramatically reduce PR wall-clock time and duplicated runner usage. By merging 4 live-proof jobs into a single sequential job, merging 4 advisory jobs into another, and applying a consistent concurrency cancellation policy, the pipeline efficiency increases. A final `ci-success` gate job provides a stable branch-protection target, eliminating the brittleness of path/skip triggers. A clear trigger matrix separates fast PR gates (single version) from nightly compatibility sweeps.

**Primary recommendation:** Apply the `if: always()` summary gate pattern and group jobs by outcome criticality (integration vs advisory) rather than arbitrary domains, using standard GitHub Actions concurrency directives.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Merge the 4 `live-proof` jobs (`viewer-evidence`, `signing`, `long-lived`, `release-proof`) into a single `integration-proofs` job that runs sequentially and depends on the `test` job. 
- **D-02:** Merge the 4 `advisory` jobs (`raster`, `comparison`, `livebook`, `pdfjs`) into a single `advisory-checks` job that runs sequentially, has no `needs:` (graph-disconnected), and sets `continue-on-error: true`.
- **D-03:** *Rationale:* Grouping these jobs eliminates redundant checkout and VM setup overhead (1-2 minutes per job), saving significant runner minutes while retaining full test coverage. This is idiomatic for Elixir/Phoenix OSS projects where tests are grouped into fewer jobs unless massive parallelization is needed.
- **D-04:** Implement a final dependent job (e.g., `ci-success`) using `if: always()` that depends on all required jobs. It must evaluate `needs.*.result` to ensure all prerequisites are either `success` or explicitly `skipped` (due to matrix).
- **D-05:** *Rationale:* Provides a single, stable required-check name for GitHub branch protection (satisfies FLOW-05) without the brittleness of path/branch/skip-directive pending-check traps or Status API calls.
- **D-06:** Apply concurrency using `group: ${{ github.workflow }}-${{ github.ref }}` and set `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.
- **D-07:** *Rationale:* Cancels superseded PR runs immediately (FLOW-02) but ensures that `main` branch pushes and release tags are never canceled, preserving vital caching and release workflows.
- **D-08:** The `pull_request` trigger runs the test suite on the primary target only (latest OTP/Elixir) to serve as a fast gate.
- **D-09:** A scheduled nightly trigger (`schedule:`) runs the broad version matrix (minimum and latest supported versions) to protect compatibility without slowing down PRs (FLOW-04). Lint and static analysis checks run strictly once on the primary version.

### the agent's Discretion
- The user delegated deep-dive architectural decisions entirely to Claude. All decisions above reflect a cohesive, one-shot "perfect" recommendation optimized for developer ergonomics, CI efficiency, and Elixir ecosystem best practices.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOW-01 | Critical path minimized, duplicated setups reduced, advisory/live-proof jobs rationalized | Merging jobs into `integration-proofs` and `advisory-checks` removes 6x VM provisioning overhead. |
| FLOW-02 | Concurrency cancels superseded PR runs while never canceling in-flight main | GitHub Actions `concurrency` property with conditional `cancel-in-progress` correctly isolates refs. |
| FLOW-03 | Triggers follow clear PR fast gate vs nightly matrix | Matrix strategy partitioned via scheduled vs PR events. |
| FLOW-04 | Matrix policy covers latest + min on nightly, lint runs once | Supported Elixir matrix defined. Linting isolated to primary test run. |
| FLOW-05 | Stable required-check summary job gates merge | `ci-success` job using `if: always()` provides single branch-protection target. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CI Graph Execution | GitHub Actions Runner | — | Centralized orchestration of continuous integration. |
| Dependency Resolution | Mix | npm | Elixir's build tool fetches and compiles all required packages. |
| Proof Validation | External Binaries | Python | Validates PDF outputs using actual real-world parsers (pdfium, poppler). |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions | v4/v6 | CI workflow orchestration | Defacto for OSS Elixir projects, native repo integration |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `if: always()` gate | Branch protection paths | Path filters are brittle and can lead to unmergable "pending" PR states if a path is skipped. |
| Job merging | Matrix / parallel | 6 individual jobs takes 6-12m of VM setup; sequential saves runner minutes for lightweight tasks. |

## Architecture Patterns

### System Architecture Diagram
```
Push / PR Trigger
│
├─► test (fast gate)
│   └─► integration-proofs (runs sequential test commands)
│       └─► ci-success (evaluates needs.*.result) ◄── Branch Protection Target
│
├─► example-phoenix
│   └─► ci-success
│
└─► advisory-checks (continue-on-error: true, graph-disconnected)
```

### Pattern 1: Summary Gate Job (`ci-success`)
**What:** A final job that aggregates the result of all parallel and sequential gate jobs.
**When to use:** In any non-trivial repository where required checks might be skipped due to path filtering or matrices.
**Example:**
```yaml
ci-success:
  needs: [test, example-phoenix, integration-proofs]
  if: always()
  runs-on: ubuntu-latest
  steps:
    - name: Evaluate outcomes
      run: |
        if [[ "${{ contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled') }}" == "true" ]]; then
          echo "Prerequisite jobs failed or were cancelled."
          exit 1
        fi
```

### Anti-Patterns to Avoid
- **Status Checks API:** Using a custom script to ping the GitHub API to set a check. Too brittle.
- **Over-Matrixing:** Running lint/format checks on every Elixir/OTP matrix combination. Waste of runner minutes.
- **Unbounded Concurrency:** Leaving PR pushes without `cancel-in-progress`, leading to duplicate queued jobs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Required check stability | Custom bash pinging GitHub API | `ci-success` gate job | Native workflow dependency resolution is reliable. |
| Canceling old runs | Third-party GH actions | `concurrency:` directive | Natively supported by GitHub Actions. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | GitHub Branch Protection Rules | Update branch protection to require only `ci-success` once merged |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Common Pitfalls

### Pitfall 1: Skipped Jobs Breaking the Gate
**What goes wrong:** A required job is skipped (e.g., due to matrix or path filter), so GitHub branch protection waits forever.
**Why it happens:** GitHub considers a skipped required check as "pending".
**How to avoid:** The `ci-success` gate evaluates skipped jobs as acceptable prerequisites using `if: always()`.

### Pitfall 2: Accidental Main Cancellation
**What goes wrong:** Fast pushes to `main` cancel previously running `main` deployments/cache-warmers.
**Why it happens:** `concurrency` group defined without branch exclusion.
**How to avoid:** Set `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.

### Pitfall 3: Template injection via `${{ }}` in shell block
**What goes wrong:** Malicious PR injects shell commands through variable outputs.
**Why it happens:** `${{ }}` is parsed before the bash script runs.
**How to avoid:** Map outputs to step `env:` variables and reference the env variable natively in bash `$VAR`.

## Code Examples

### Concurrency Grouping
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GitHub Actions | CI execution | ✓ | Cloud | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix ci` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOW-05 | `mix ci` runs required checks | integration | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** Ensure `ci.yml` parses with actionlint (if available) or yaml checker.
- **Per wave merge:** Inspect modified yaml structure locally.
- **Phase gate:** Push to branch and observe PR checks green.

### Wave 0 Gaps
- None — test infrastructure exists, but `test/guardrails/required_checks_contract_test.exs` will need adjustment if it strictly matches specific job names inside the workflow.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | `permissions: contents: read` block |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |

### Known Threat Patterns for GitHub Actions

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Pwned Action | Tampering | Pin third-party actions to SHA |
| Token Exfiltration | Info Disclosure | Restrict `permissions:` to `contents: read` |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/111-workflow-topology-triggers-matrix/111-CONTEXT.md` - Locked Decisions
- `.planning/REQUIREMENTS.md` - FLOW requirements
- `.github/workflows/ci.yml` - Current workflow topology

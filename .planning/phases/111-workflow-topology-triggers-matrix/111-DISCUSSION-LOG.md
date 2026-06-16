# Phase 111: Workflow Topology, Triggers & Matrix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 111-Workflow Topology, Triggers & Matrix
**Areas discussed:** Live-proof & Advisory topology, Summary gate job, Concurrency cancellation, Matrix scope

---

## Live-proof & Advisory topology

| Option | Description | Selected |
|--------|-------------|----------|
| Merge into single job | Combine them into a single 'Integration & Proofs' job to save checkout/setup overhead and runner minutes, running them sequentially. | ✓ |
| Keep separate, refactor setup | Keep them as separate jobs but perhaps use a reusable workflow or composite action for setup. Keeps parallel execution but higher overhead. | |

**User's choice:** The user requested an autonomous, deep-dive recommendation based on best practices.
**Notes:** Claude selected "Merge into single job" to drastically reduce duplicate setup time and runner minutes, which is idiomatic for Elixir CI pipelines where tests run quickly and setup is the primary bottleneck.

---

## Summary Gate Job

| Option | Description | Selected |
|--------|-------------|----------|
| Final dependent job | Check `needs.*.result == 'success'` in a final job that depends on all required path jobs. Handles skipped jobs well. | ✓ |
| Status API check | Use a GitHub Action or API call to verify the commit status. Less declarative. | |

**User's choice:** The user requested an autonomous, deep-dive recommendation.
**Notes:** Claude selected "Final dependent job" because it is the standard, declarative GitHub Actions pattern for consolidating matrix and required checks into a single status name for branch protection.

---

## Concurrency Cancellation

| Option | Description | Selected |
|--------|-------------|----------|
| group: workflow-ref with cancel-in-progress conditionally | Use `group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}` to cancel PRs but protect main. | ✓ |
| head_ref || run_id | Older pattern that can be less reliable depending on trigger events. | |
| PR specific only | Restrict concurrency entirely to pull_request triggers. | |

**User's choice:** The user requested an autonomous, deep-dive recommendation.
**Notes:** Claude selected the conditional `cancel-in-progress` on the `workflow-ref` group as the most modern and robust way to achieve FLOW-02.

---

## Claude's Discretion

- The user explicitly requested: "one-shot a perfect set of recommendations so i dont have to think... using great software architecture/engineering, principle of least surprise and great UI/UX wheere applicable great dev experience".
- Claude utilized discretion to shape the matrix (PRs fast, nightly broad) and combine the jobs effectively.

## Deferred Ideas

- None.
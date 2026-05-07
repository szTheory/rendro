---
type: quick-task
id: 260428-hsl-fix-pr-1-ci-format-failures-and-rerun-ve
title: Fix PR #1 CI format failures and rerun verification
branch: phase-13-docs-release-closure
repo: /Users/jon/projects/rendro
created: 2026-04-28
autonomous: true
scope:
  - Fix only formatting failures reported by CI
  - Preserve existing behavior and scope boundaries
verification:
  - mix format --check-formatted
  - mix ci
  - git push origin phase-13-docs-release-closure
files:
  - test/scripts/release_preflight_proof_test.exs
  - lib/rendro/recipes.ex
  - test/rendro/adapters/phoenix_test.exs
  - lib/rendro/adapters/mailglass.ex
  - lib/rendro/adapters/threadline.ex
  - test/rendro/policy_test.exs
---

# Quick Task Plan

## Objective
Resolve the PR #1 CI failure on `phase-13-docs-release-closure` by formatting only the files named in the 2026-04-28 CI log, then rerun local verification and push the branch so GitHub checks rerun.

## Constraints
- Use the GSD quick-task workflow; do not make ad hoc repo edits outside it.
- Keep changes limited to formatting in the six listed files.
- Do not expand scope into functional, docs, or refactor work unless formatting reveals a blocking syntax issue.

## Execution

### Task 1: Apply minimal formatting fixes
Run the formatter only against the CI-listed files, review the diff, and confirm the changes are formatting-only.

### Task 2: Re-run local verification
Run:

```bash
mix format --check-formatted
mix ci
```

If `mix ci` fails for a reason unrelated to formatting, stop and record the failure instead of broadening the fix.

### Task 3: Commit and push
Create a focused commit for the formatting fix and push `phase-13-docs-release-closure` to origin so PR #1 checks rerun.

## Done When
- `mix format --check-formatted` passes locally.
- `mix ci` passes locally.
- Only the six CI-listed files changed, unless a directly dependent generated formatting change is unavoidable.
- The branch is pushed and PR #1 has a new CI run triggered.

---
phase: 132
fixed_at: 2026-08-26T20:30:00Z
review_path: .planning/phases/132-quality-baseline-triage/132-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 132: Code Review Fix Report

**Fixed at:** 2026-08-26T20:30:00Z
**Source review:** `.planning/phases/132-quality-baseline-triage/132-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: Recursive consumer inventory reads generated symlink directories as text files

**Files modified:** `scripts/quality_governance.cjs`
**Commit:** c4595f1
**Applied fix:** Consumer traversal now prunes closed generated/dependency/cache/VCS directory names, ignores symbolic links, and returns regular files only. The regression test proves a generated directory symlink is skipped without crashing while a regular example consumer remains fail-closed.

### CR-01: A regular source-file symlink can hide an unapproved ledger consumer

**Files modified:** `scripts/quality_governance.cjs`
**Commits:** 84b2fd5, 85500e0
**Applied fix:** In-scope symlinks now resolve only to regular files within the repository and are scanned under the symlink path. Directory symlinks remain untraversed through generated-directory pruning; dangling, external, cyclic, unreadable, and non-regular targets fail closed with an actionable error.

## Earlier Iteration Fixes

### CR-01: PROH fixtures are tautologies and never detect a real consumer leak

**Files modified:** `scripts/quality_governance.cjs`, `test/quality/fixtures/governance-violation.json`, `test/quality/fixtures/governance-clean.json`
**Commit:** a120632
**Applied fix:** Replaced kind labels with closed repository-relative artifacts carrying authority, consumer, and decision states. The active scan now checks defined consumer surfaces with an exact maintenance allowlist; CLI mutations prove inserted prohibited states fail while snapshot inputs remain rejected.

### CR-02: Active governance fails open for human-state fields

**Files modified:** `scripts/quality_governance.cjs`
**Commit:** 2b8037f
**Applied fix:** Centralized blocking human-state matching and applied it to PLAN, UAT, SUMMARY, VALIDATION, and VERIFICATION roles. CLI mutation coverage verifies all required true-valued states while advisory prose and explicit false fields remain allowed.

---

_Fixed: 2026-08-26T20:30:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_

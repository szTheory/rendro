---
phase: 94-docs-warning-hygiene
plan: "02"
subsystem: viewer-evidence
tags: [hygiene, docs, wording, staleness, warning]
dependency_graph:
  requires: []
  provides: [HYG-02]
  affects: [lib/rendro/viewer_evidence/validator.ex, guides/viewer_evidence.md]
tech_stack:
  added: []
  patterns: [errors-as-product, inline-compact-remediation-message]
key_files:
  created: []
  modified:
    - lib/rendro/viewer_evidence/validator.ex
    - guides/viewer_evidence.md
decisions:
  - "Augmented staleness warning string via Elixir string concatenation (<>) to keep the list literal structure intact; multi-line concat is idiomatic and reviewable"
  - "Placed staleness lifecycle section between worked example and Appendix A — a maintainer reading the guide sequentially reaches lifecycle context after understanding the recording workflow"
  - "Used 'designed cadence signal' and 'intentional' language per D-07 to make the first-fire event legible as planned, not a regression"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-13"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 94 Plan 02: Staleness Signal Self-Explanation Summary

**One-liner:** Made the 180-day viewer-evidence staleness warning self-explaining with inline remediation command, advisory-severity note, and guide pointer; documented the staleness lifecycle in the guide so the ~late November 2026 first firing is legible as a designed cadence event.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Augment staleness_warnings/1 message in validator.ex | 8b3a4db | lib/rendro/viewer_evidence/validator.ex |
| 2 | Add staleness lifecycle section to guides/viewer_evidence.md | 0196136 | guides/viewer_evidence.md |

## What Was Done

### Task 1 — staleness_warnings/1 message augmentation

The original message string in `staleness_warnings/1` (line 105 of `validator.ex`) was:

```
"#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days"
```

It was augmented via `<>` string concatenation to append three pieces of information per D-05:

```elixir
"#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days" <>
  " (advisory — non-fatal unless --strict; run mix rendro.viewer_evidence record to re-record;" <>
  " see guides/viewer_evidence.md)"
```

- (a) Advisory note: `advisory — non-fatal unless --strict`
- (b) Remediation command: `run mix rendro.viewer_evidence record` (house style: inline, lowercase "run", no shell prompt, no trailing period)
- (c) Guide pointer: `see guides/viewer_evidence.md`

`@staleness_days 180` at line 11 was preserved without change. The call chain (`run_full/3`, `warnings/2` aggregator) was not touched.

### Task 2 — Staleness lifecycle section in guide

Added a new "Staleness Lifecycle" section to `guides/viewer_evidence.md` positioned between the "Worked example" section and Appendix A. The section covers:

1. The 180-day staleness signal is a designed cadence signal, not a defect
2. Expected first-fire date: approximately late November 2026 (180 days after mid-June 2026 recordings)
3. Correct response: re-record evidence using `mix rendro.viewer_evidence record <surface> <viewer>`
4. Advisory severity by default (non-fatal); fatal only with `--strict`
5. Explicit instruction not to suppress or raise the threshold

## Verification Results

| Check | Result |
|-------|--------|
| `grep "@staleness_days 180" validator.ex` | PASS — threshold preserved |
| `grep "mix rendro.viewer_evidence record" validator.ex` | PASS — remediation command present |
| `grep "viewer_evidence.md" validator.ex` | PASS — guide pointer present |
| `grep -c "staleness" guides/viewer_evidence.md` | 3 matches — content added |
| `grep "180" guides/viewer_evidence.md` | PASS — threshold mentioned in new section |
| `grep -i "cadence\|designed\|lifecycle\|intentional" guides/viewer_evidence.md` | PASS — section explains designed nature |
| `mix test test/docs_contract/public_api_contract_test.exs` | PASS — 6 tests, 0 failures |
| `@staleness_days` occurrences in validator.ex | 3 (1 definition + 2 usage sites — no duplicate added) |

## Deviations from Plan

None — plan executed exactly as written. The message wording follows the suggested shape from the plan's `<interfaces>` block with minor phrasing adjustments (added "to re-record" after the command for natural English flow while keeping the house-style pattern intact).

## Known Stubs

None. Both changes are complete: the warning message is fully augmented and the guide section is fully written.

## Threat Flags

No new attack surface introduced. Changes are limited to a warning message string and a markdown guide section. No network endpoints, auth paths, file access patterns, or schema changes.

T-94-02-02 (Tampering — @staleness_days threshold): Mitigated. The `@staleness_days 180` value at line 11 is unchanged; grep gate confirmed 1 definition, 2 usage sites only.

## Self-Check: PASSED

- `lib/rendro/viewer_evidence/validator.ex` — modified and committed at 8b3a4db
- `guides/viewer_evidence.md` — modified and committed at 0196136
- Both commits verified present in `git log --oneline`
- Contract test: 6 tests, 0 failures

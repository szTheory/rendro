---
phase: 95
slug: header-duplex-proof-metadata-reconcile
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir / Mix) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/rendro/flow_test.exs test/rendro/pipeline/paginate_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–60 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (the two touched test files)
- **After every plan wave:** Run the full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 95-01-* | 01 | 1 | PROOF-01 | — / — | N/A (no I/O, no API surface change) | unit/E2E | `mix test test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 95-02-* | 02 | 1 | META-01 | — / — | N/A (docs reconcile only) | manual | re-read reconciled VALIDATION.md files for intra-file consistency | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Plan/task IDs above are provisional — the planner owns final numbering.*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Both new PROOF-01 tests slot into existing test files (`test/rendro/flow_test.exs`, `test/rendro/pipeline/paginate_test.exs`); ExUnit is already configured. No new framework, fixtures, or files required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reconciled v2.6/v2.7 VALIDATION.md files are internally consistent (no `approved`/`nyquist_compliant: true` file still showing `pending` task cells or `Status: Planned`) | META-01 | Markdown metadata reconcile — no automated assertion harness for archived planning docs | Re-read `90-VALIDATION.md`, `91-VALIDATION.md`, `92-VALIDATION.md` after edits; confirm no false-pending/false-incomplete markers remain and each file's recorded status matches the passed milestone audit. Confirm `88-VALIDATION.md` left untouched (genuinely-consistent draft artifact per research). |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

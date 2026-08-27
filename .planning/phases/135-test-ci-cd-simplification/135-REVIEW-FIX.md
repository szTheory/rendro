---
phase: 135-test-ci-cd-simplification
fixed_at: 2026-08-27T20:50:00Z
review_path: .planning/phases/135-test-ci-cd-simplification/135-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 4
skipped: 1
status: partial
---

# Phase 135: Code Review Fix Report

## Fixed Issues

### CR-01: Isolate candidate control plane

**Commit:** `6843e03`

Candidate generation now occurs in a dedicated job and hands only a bounded artifact to a fresh trusted control-plane job.

### CR-02: Derive bundle record counts

**Commit:** `a39ff7e`

Closed payload counts are exact and derived from JSON/checksum records during both build and validation.

### CR-03: Enforce route parity schemas

**Commit:** `2d67ab7`

Each route now selects an explicit semantic role/count schema and has a negative schema/count test.

### WR-01: Quote catalog evidence SHA

**Commit:** `e473936`

Runbook dispatch commands now expand the validated full SHA.

## Skipped Issues

### CR-04: Durable parity-ledger comparator evidence

**Reason:** retained remote artifact payloads and a durable prior comparator output are not available locally. The committed matrix contains transport facts, but its `matched` state cannot truthfully be independently recomputed from those facts alone. It must be changed only after the retained legacy and generic artifacts are restored or the four routes are rerun and their normalized comparator records are durably retained.

---

_Fixer: gsd-code-fixer_

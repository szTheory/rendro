---
phase: 135
fixed_at: 2026-08-27T22:15:00Z
review_path: .planning/phases/135-test-ci-cd-simplification/135-REVIEW-2.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 135: Code Review Fix Report

## CR-03: Route-specific extraction and normalization

`Rendro.CatalogEvidenceParity` now accepts unpacked artifact roots or the sealed durable record rather than caller-normalized payload maps. It extracts the Phase 126 selected-six preset IDs, generic review/canonical payloads, checksum records, and historical underscore-to-hyphen file identities.

## CR-04: Reproducible durable parity evidence

The version-2 sealed record retains typed transport facts and normalized `{id, sha256}` records for both sides of every route. Its stored status is mechanically recomputed; inventory status is contract-tested against the record.

Focused tests were prepared and formatting/JSON/diff checks passed. `mix test` could not run in this isolated worktree because the dependency cache is absent; Mix reported missing dependencies before compiling project code.

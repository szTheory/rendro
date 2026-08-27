---
phase: 135
fixed_at: 2026-08-27T21:19:51Z
review_path: .planning/phases/135-test-ci-cd-simplification/135-REVIEW-3.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 135: Code Review Fix Report

## CR-03: Route-specific extraction and normalization

`Rendro.CatalogEvidenceParity` now accepts unpacked artifact roots or the sealed durable record rather than caller-normalized payload maps. It extracts the Phase 126 selected-six preset IDs, generic review/canonical payloads, checksum records, and historical underscore-to-hyphen file identities.

## CR-04: Reproducible durable parity evidence

The version-2 sealed record retains typed transport facts and normalized `{id, sha256}` records for both sides of every route. Its stored status is mechanically recomputed; inventory status is contract-tested against the record.

Focused tests were prepared and formatting/JSON/diff checks passed. `mix test` could not run in this isolated worktree because the dependency cache is absent; Mix reported missing dependencies before compiling project code.

## CR-01 (Iteration 3): Sealed provenance and inventory binding

`Rendro.CatalogEvidenceParity.verify_record/2` binds each route side to the root candidate identity. The Markdown inventory contract now parses the exact named schema and requires all 16 cells of each ordered route row to equal the canonical `inventory_row/2` projection from the sealed record.

The sealed transport schema uses a nonempty, unique, ordered `artifacts` array and explicit `reviewer_required: false` fact. This preserves all three Phase 130 legacy artifact identities and archive digests while keeping every other transport uniform with one artifact entry.

The committed inventory uses that canonical serialization for transport, renderer, normalized role/count/hash, authority, and status facts. Table-driven negative coverage changes every column independently and rejects header changes, reordered routes, extra routes, and missing routes.

---
phase: 50
plan: 01
subsystem: support-boundary-and-proof-closure
tags:
  - docs-contract
  - support-matrix
  - embedded-files
  - curated-links
  - trust-boundary
dependency_graph:
  requires:
    - 48-* (embedded files core surface)
    - 49-* (curated link annotation surface)
  provides:
    - Family-first nested support matrix entries for embedded_files and links
    - Canonical public wording for embedded files and curated links boundaries
    - Embedded artifact semantic-claims docs-contract lane
  affects:
    - priv/support_matrix.json
    - guides/api_stability.md
    - scripts/verify_docs.exs
    - test/docs_contract/embedded_artifact_claims_test.exs
tech_stack:
  added: []
  patterns:
    - Family-first nested support matrix (sibling families, simple scalar statuses)
    - Per-surface viewer entries with proof checklist arrays
    - Atomic docs-contract change set (matrix + guide + claims test + verify_docs lane)
    - Conservative `unverified` posture pending recorded manual evidence
key_files:
  created:
    - test/docs_contract/embedded_artifact_claims_test.exs
    - .planning/phases/50-support-boundary-and-proof-closure/50-01-SUMMARY.md
  modified:
    - priv/support_matrix.json
    - guides/api_stability.md
    - scripts/verify_docs.exs
decisions:
  - Extended priv/support_matrix.json with embedded_files and links as siblings of forms — no generic "surfaces" wrapper, no BCD-style per-leaf statement objects.
  - Held all embedded_files and links viewer statuses at "unverified"; promotion deferred to Plan 03 with recorded manual evidence per D-06..D-14.
  - Used "embedded files" (not "attachments") in public wording, with one explicit sentence distinguishing PDF-internal embedded files from delivery adapter attachments per D-15..D-17.
  - Added a single new Embedded artifact semantic-claims lane to verify_docs.exs rather than extending forms_claims_test.exs, keeping per-surface claims isolated and stable.
metrics:
  completed_at: 2026-05-06T00:00:00Z
  duration: approx. 15m
  task_commits: 4
  files_changed: 4
---

# Phase 50 Plan 01: Embedded Files and Curated Links Support Boundary Summary

The support matrix and the canonical public guide now publish a proof-backed contract for embedded files and curated link annotations as siblings of the existing forms family, with conservative `unverified` viewer posture for both new families and a dedicated docs-contract lane that fails together when any of those four surfaces drift.

## Completed Work

- Extended `priv/support_matrix.json` with two top-level family entries:
  - `embedded_files` with `capabilities.document_level: "supported"`, behaviors `explicit_metadata`/`authored_timestamps` `"supported"`, `page_attachment_annotations` `"unsupported"`, and viewer entries for `adobe_acrobat_reader` and `apple_preview` at `"unverified"` with proof checklist `["discoverable", "open_or_extract", "save_or_extract"]`.
  - `links` with `targets.external_uri_http_https`/`internal_page` `"supported"`, `named_destinations` `"unsupported"`, `behaviors.fragment_rectangles` `"supported"`, and viewer entries for `adobe_acrobat_reader` and `apple_preview` at `"unverified"` with proof checklist `["external_uri_handoff", "internal_page_navigation"]`.
- Preserved the existing `forms` family and `validators` block byte-for-byte equivalent at the public claim level (no removed keys, no demoted statuses).
- Added `test/docs_contract/embedded_artifact_claims_test.exs` with four assertions: matrix shape for `embedded_files`, matrix shape for `links`, public guide wording, and verify_docs lane registration. Test refutes the generic `"surfaces"` wrapper, premature `"supported"` viewer claims for the new families, and broad viewer language ("standard PDF viewers", `v1.9 viewer`, "all PDF viewers").
- Extended `guides/api_stability.md` with three new sections: Embedded Files Support Boundary, Curated Links Support Boundary, and Embedded Artifact Viewer Posture. Wording explicitly distinguishes PDF-internal embedded files from delivery/email/download attachments handled outside the PDF, and restates the structural-vs-viewer split for the new families.
- Registered `Embedded artifact semantic-claims lane` in `scripts/verify_docs.exs` alongside the existing four lanes so `mix docs.contract` blocks drift atomically across matrix, guide, and claims test.

## Task Commits

- `7fca1be` `test(50-01): add failing embedded artifact support claims` (Task 1 RED)
- `8f817bd` `feat(50-01): extend support matrix with embedded_files and links families` (Task 1 GREEN)
- `6243c22` `test(50-01): add failing canonical wording and docs gate coverage` (Task 2 RED)
- `a04a191` `docs(50-01): publish embedded files and curated links support boundaries` (Task 2 GREEN)

## Deviations from Plan

None — plan executed exactly as written. Both tasks followed the prescribed RED → GREEN cycle with a single test file extended in place rather than split, matching the precedent of `forms_claims_test.exs`.

## TDD Gate Compliance

- Task 1: RED commit `7fca1be` (test) precedes GREEN commit `8f817bd` (feat). RED was confirmed failing on both schema assertions before the matrix change.
- Task 2: RED commit `6243c22` (test) precedes GREEN commit `a04a191` (docs). RED was confirmed failing on both the new guide wording and the verify_docs lane registration before either change.
- No REFACTOR commits were needed; the GREEN edits were minimal additions and did not require cleanup.

## Locked Decisions Honored

- D-01..D-05: Extended the existing family-first nested matrix; added `embedded_files` and `links` as siblings of `forms`; kept simple scalar statuses for capability/behavior/target leaves; viewer objects only where a proof checklist exists. No generic `"surfaces"` wrapper, no BCD-style per-leaf metadata.
- D-06..D-14: Per-surface viewer claims, with `unverified` as the default posture for both new families. No promotion to `supported` for any embedded_files or links viewer in this plan; the matrix and guide together advertise the gating posture so Plan 03 owns the manual proof closure.
- D-15..D-18: Public wording uses "embedded files" (never "attachments" as a headline), plain "links" with `http`/`https` and internal page destinations, and one explicit sentence distinguishing PDF-internal embedded files from delivery adapter attachments.

## Known Stubs

None. The new sections in `guides/api_stability.md` are concrete claim wording, not placeholders. Viewer rows in `priv/support_matrix.json` carry real proof checklists; their `unverified` status is the truthful current state, not a TODO.

## Threat Flags

None. The change publishes narrower-than-implementation claims and does not introduce any new authored surface, URI scheme, destination semantics, or runtime behavior. It strictly tightens the public contract around already-shipped Phase 48 and Phase 49 functionality.

## Verification

- `mix test test/docs_contract/embedded_artifact_claims_test.exs` (4 tests, 0 failures)
- `mix test test/docs_contract/embedded_artifact_claims_test.exs test/docs_contract/forms_claims_test.exs` (7 tests, 0 failures — confirms the existing forms claims still pass)
- `mix docs.contract` (5 lanes pass: README doctest, Integration contract, Integration semantic-claims, Forms semantic-claims, Embedded artifact semantic-claims)

## Self-Check: PASSED

- File `test/docs_contract/embedded_artifact_claims_test.exs` exists.
- File `priv/support_matrix.json` modified with `embedded_files` and `links` family blocks.
- File `guides/api_stability.md` modified with three new boundary sections.
- File `scripts/verify_docs.exs` modified with the Embedded artifact semantic-claims lane.
- Commit `7fca1be` exists in git history.
- Commit `8f817bd` exists in git history.
- Commit `6243c22` exists in git history.
- Commit `a04a191` exists in git history.

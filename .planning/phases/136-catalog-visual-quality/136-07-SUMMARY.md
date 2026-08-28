---
phase: 136-catalog-visual-quality
plan: "07"
subsystem: catalog-evidence
tags: [catalog, review, github-actions, provenance, exact-sha, unavailable]
requires:
  - phase: 136-catalog-visual-quality
    provides: immutable candidate and explicit publication authorization
provides:
  - A dedicated non-force remote ref for the exact Phase 136 candidate.
  - One dynamically identified review workflow outcome with a precise unavailable-evidence record.
affects: [136-08, catalog-review, catalog-canonicalization]
tech-stack:
  added: []
  patterns: [exact remote ref binding, dynamic run identity, detached trusted control, fail-closed evidence intake]
key-files:
  created:
    - .planning/phases/136-catalog-visual-quality/136-07-SUMMARY.md
  modified: []
key-decisions:
  - "Publish only d547bbfa60760d43f19a15372d88a2d159bfa327 to its dedicated non-force remote ref after explicit authorization."
  - "Treat run 33177154682's candidate-generation failure and zero artifacts as unavailable review evidence; do not infer validation, eligibility, scores, or canonical authority."
metrics:
  duration: 6m 41s
  completed: 2026-08-28
  tasks_completed: 2
  files_modified: 1
status: complete
---

# Phase 136 Plan 07: Exact Candidate Review Dispatch Summary

**The authorized immutable candidate is remotely reachable, but its one newly dispatched review run failed before artifact production, leaving review evidence explicitly unavailable and unpromoted.**

## Immutable Publication

- Candidate SHA: `d547bbfa60760d43f19a15372d88a2d159bfa327`
- Candidate ref: `refs/heads/gsd/phase-136-candidate-d547bbfa6076`
- Remote ref resolution: `d547bbfa60760d43f19a15372d88a2d159bfa327` (one exact ref result)
- Publication method: `git push origin d547bbfa60760d43f19a15372d88a2d159bfa327:refs/heads/gsd/phase-136-candidate-d547bbfa6076`
- Force update: not used
- Pre-publication workflow diff: none relative to the candidate parent for `.github/workflows/catalog-evidence.yml`

## Dynamically Identified Review Run

- Operation: `review`
- Dispatch timestamp (UTC): `2026-08-28T13:49:12Z`
- Run ID: `33177154682`
- Run attempt: `1`
- Run URL: `https://github.com/szTheory/rendro/actions/runs/33177154682`
- Selection method: the sole post-dispatch `workflow_dispatch` run not present in the pre-dispatch Catalog Evidence run set and created after the dispatch timestamp.
- Run control SHA: `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`
- Run conclusion: `failure`

## Independent Trusted Control

- Default branch: `main`
- Remote control ref: `refs/heads/main`
- Independently resolved control SHA: `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`
- Detached control checkout: `/tmp/rendro-control-136-07.3drapZ/control`
- Asserted detached HEAD: `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`
- Control identity result: pass — remote default-branch SHA, run control SHA, and detached checkout HEAD were all exact lowercase 40-character matches.

## Evidence Outcome

- Expected artifact name: `rendro-catalog-evidence--review--d547bbfa60760d43f19a15372d88a2d159bfa327--run-33177154682--attempt-1`
- Artifact API result: `total_count: 0`
- Artifact URL: unavailable — no final evidence artifact was uploaded.
- Archive digest: unavailable — no final evidence artifact was uploaded.
- Download and bundle root: unavailable — no artifact existed to download.
- Validator execution directory: `/tmp/rendro-control-136-07.3drapZ/control`
- Validator result: not run — the candidate-generation job failed before its isolated handoff upload, the trusted control packaging job was skipped, and no bundle root existed.
- Exact unavailable reason: candidate-generation step `Bind candidate and generate closed handoff` exited 1 with `Candidate catalog generation failed: :invalid_candidate_scope` at `2026-08-28T13:52:46Z`; the control job was skipped and no review bundle was produced.

## Closed-Bundle Facts

No closed bundle exists, so none of these facts was validated from Plan 07 evidence: pinned PDFium executable digest, manifest candidate/checked-out HEAD binding, payload role/count closure, safe paths, checksums, full-size reconciled review images, or review-image hashes.

- Candidate classification required for any future review: exactly six changed target IDs and 26 byte-identical controls.
- Six target identities left unreviewed: `invoice--cedar-mutual--corporate-classic--dark`, `statement--signal-ledger--minimal-mono--dark`, `payslip--northline-logistics--swiss--light`, `payslip--northline-logistics--swiss--dark`, `ticket--aurora-live--brutalist--light`, `ticket--aurora-live--brutalist--dark`.
- 26-control identity result: unavailable from this run; no control bytes were reclassified or promoted.
- Locked review ordering result: unavailable; no image was opened, interpreted, scored, or used for eligibility.

## Verification

- PASS — exact candidate object existed locally before publication and the remote dedicated ref resolved to the same complete SHA after a non-force push.
- PASS — `gh auth status` succeeded before dispatch.
- PASS — one newly dispatched run was selected dynamically and its actual ID/attempt/control SHA were captured.
- PASS — independent `main` remote resolution, run control SHA, and fresh detached control checkout HEAD all matched exactly.
- PASS — in the detached trusted control checkout: `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` (93 tests, 0 failures).
- UNAVAILABLE — `Rendro.CatalogEvidenceBundle.validate/3`; no artifact or `BUNDLE_ROOT` existed after the failed candidate-generation job.

## Decisions Made

- The user-selected authorization was applied only to the dedicated exact-SHA ref and one `review` dispatch; no force push, canonical operation, or unrelated remote mutation occurred.
- A successful workflow is not inferred from a published ref. The failed run creates no review, score, eligibility, canonical, or image-interpretation claim.

## Deviations from Plan

None - the plan's prescribed fail-closed unavailable-evidence path was followed after the external candidate-generation failure.

## Issues Encountered

- GitHub Actions run `33177154682` failed in candidate generation with `:invalid_candidate_scope`; no bounded final artifact was uploaded and trusted control packaging did not run.

## Next Action

Investigate `mix rendro.catalog.candidate` against the published immutable candidate to determine why its scope is invalid. If a source correction is required, create a new immutable candidate, obtain a new one-way publication decision for that SHA, then dispatch one new `review` operation and validate its sole artifact from a freshly asserted detached control checkout. Do not reuse this failed run, any stale artifact, Phase 130 scores, or inferred approval.

## Known Stubs

None.

## Self-Check: PASSED

- The summary exists at the required phase path.
- The candidate remote ref, dynamic run ID/attempt, default branch/control SHA, detached control assertion, and zero-artifact API outcome were recorded from this execution.
- No bundle validation or visual claim was asserted without the missing evidence.

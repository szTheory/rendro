---
phase: 130-catalog-quality-evidence-ratchet
plan: "08"
subsystem: launch-artifact-reconciliation
tags: [pdfium, deterministic-pdf, launch-assets, staging, provenance]
requires:
  - phase: 130-07
    provides: exact-source detached staging worktree with two authorized dark golden transitions
provides:
  - provenance-bound, staged launch family with ten changed gallery images
  - machine-readable diff, stable-control, and rollback fence for later review/publication
affects: [130-09, 130-06, launch-review, launch-publication]
tech-stack:
  added: []
  patterns:
    - consume only a provenance-verified exact-SHA renderer artifact into detached staging
    - preserve review authority by separating generation identities from human quality decisions
key-files:
  created:
    - tmp/phase130-launch-reconcile/.phase130-launch-diff.json
  modified:
    - tmp/phase130-launch-reconcile/assets/rendro/gallery
    - tmp/phase130-launch-reconcile/assets/rendro/artifacts.json
    - tmp/phase130-launch-reconcile/assets/rendro/manual.pdf
    - tmp/phase130-launch-reconcile/README.md
    - tmp/phase130-launch-reconcile/guides/recipes.md
    - tmp/phase130-launch-reconcile/guides/theming.md
key-decisions:
  - "Accepted only artifact phase130-launch-artifact-32385410822-1 after manifest, output, source, route, run/job, and PDFium-pin provenance all matched."
  - "Staged exactly ten gallery transitions; branded_invoice.png remains the byte-stable negative control."
  - "No launch bytes, golden refs, catalog, rubric, SIGN-OFF, or review decision were published to main."
requirements-completed: [CATALOG-06, CATALOG-07, CATALOG-08]
coverage:
  - id: D1
    description: "Pinned, provenance-bound staged launch family and exact diff inventory"
    requirement: "CATALOG-06"
    verification:
      - kind: integration
        ref: "verified artifact output-hashes.sha256 plus detached staging fence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Six changed light launch images await separate full-size human review"
    requirement: "CATALOG-07"
    verification: []
    human_judgment: true
    rationale: "Generation and identity proof cannot authorize visual quality or legacy score reuse."
metrics:
  duration: 17m
  completed: 2026-08-20
  tasks: 2
  files: 17
status: complete
---

# Phase 130 Plan 08: Provenance-Bound Launch Staging Summary

**A verified PDFium v0.11.0 launch batch is staged behind an exact 10-image inventory, stable control, and rollback fence—without publishing binaries or authorizing quality evidence.**

## Performance

- **Duration:** 17m
- **Completed:** 2026-08-20
- **Tasks:** 2/2
- **Tracked staging files:** 17

## Accomplishments

- Revalidated artifact manifest SHA-256 `806dbcc4c9473f835d0c0415734b3b46e00214aefaa49e12ba906be12751fe0a` and all 55 listed content-file hashes before import.
- Bound the artifact to source `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd`, route `gsd/diagnostic-launch-route-246374` at `c2a6ce1411388b3be1aa8fd86308105e644ee194`, run `32385410822`, job `96478573018`, artifact ID `9412909590`, and PDFium v0.11.0 executable SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.
- Imported only the plan-owned launch family into the detached worktree and synchronized the theming guide's 11 hash entries from the verified staged manifest.
- Recorded `.phase130-launch-diff.json` with exact PNG/PDF identities, the 10-path gallery partition, stable `branded_invoice.png`, provenance, preflight policy, and the constrained rollback command.
- Proved main contains no launch, golden, catalog, rubric, SIGN-OFF, source, API, dependency, recipe, preset, or membership mutation.

## Task Commits

No task commit was created by design: both tasks' outputs are ephemeral and remain only in the detached staging worktree until the separately gated Plan 130-06 publication boundary.

## Verification

- Artifact provenance manifest SHA and all `output-hashes.sha256` entries — pass.
- Staging source SHA and exact two authorized pre-import golden transitions — pass.
- Exact tracked staging diff equals 17 authorized paths; gallery subset equals the named 10 paths — pass.
- `branded_invoice.png` is byte-stable — pass.
- Imported artifact hashes match staging for `artifacts.json`, `manual.pdf`, `README.md`, and `guides/recipes.md`; all 11 manifest PNG/PDF hashes appear in `guides/theming.md` — pass.
- Protected catalog/evidence/API/dependency/source fences — pass.
- Local focused Mix test command — not run: the detached worktree has no installed dependencies. The accepted purpose-built CI artifact is the provenance-bound green generator/check result; no package installation or renderer substitution was attempted.

## Provenance Record

| Field | Value |
| --- | --- |
| Rendered source | `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd` |
| Route branch / commit | `gsd/diagnostic-launch-route-246374` / `c2a6ce1411388b3be1aa8fd86308105e644ee194` |
| GitHub run / job / artifact | `32385410822` / `96478573018` / `9412909590` |
| Renderer | PDFium v0.11.0, `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` |
| Stable control | `assets/rendro/gallery/branded_invoice.png`, `2b075ca9a95b63726863a388057895e7edcadbd09bb68f62a1d4fd184b1de804` |

## Decisions Made

- The independently verified purpose-built artifact is accepted solely as renderer/generation provenance; it does not approve six launch images, quality scores, SIGN-OFF, catalog evidence, or publication.
- Plan 130-09 must perform the next separate, full-size human review of only the six changed light images.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking environment] Detached-worktree dependency cache unavailable**
- **Found during:** Task 1
- **Issue:** Local focused Mix verification could not start because optional/development dependencies are absent from the detached worktree.
- **Fix:** Did not install or substitute packages. Used only the independently verified exact-SHA CI artifact for the green generator/check provenance and completed all local file/hash/path fences.
- **Files modified:** None
- **Verification:** Artifact hash manifest and staging boundary checks passed.

---

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** No scope expansion or publication; the missing local dependency cache leaves only the focused local Mix test unrun.

## Issues Encountered

The staging worktree has no `deps/` cache, so Mix reports unavailable dependencies before compiling the focused test files. This does not alter the accepted CI artifact or permit a renderer/package substitution.

## Known Stubs

None.

## Next Phase Readiness

Plan 130-09 can review exactly the six changed light images using the staged manifest and `.phase130-launch-diff.json`. Its human approval remains a blocking, separate authority gate. Plan 130-06 remains prohibited from publication until that gate produces six complete approved records.

## Self-Check: PASSED

- The staging diff record and all 17 authorized tracked staging changes exist.
- Main checkout remains free of launch/golden/evidence artifact changes.

---

*Phase: 130-catalog-quality-evidence-ratchet*
*Completed: 2026-08-20*

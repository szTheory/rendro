---
phase: 133-repository-evidence-hygiene
plan: "12"
subsystem: infra
tags: [hex-package, repository-hygiene, pdfjs, ci]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: "Versioned package-member manifest and deterministic hygiene command"
provides:
  - "Exact Hex package membership for public comparison evidence"
  - "Test-owned PDF.js advisory fixture"
  - "One hygiene command in local, ci.fast, and release validation paths"
affects: [release, package, comparison-evidence, ci]
tech-stack:
  added: []
  patterns: ["Run external Hex Mix tasks through cmd when a prior alias starts the application"]
key-files:
  created: [test/fixtures/pdfjs-rendro.pdf]
  modified: [mix.exs, .github/workflows/release.yml, dev/rendro/repository_hygiene.ex]
key-decisions:
  - "Package only comparison.json and the five manifest-referenced raw JSON records; keep D-07 adoption evidence separately owner-bearing."
  - "Use a test-only PDF.js fixture so advisory observation does not require package-visible PDF proof."
  - "Keep quality.hygiene deterministic and shared across local, ci.fast, and release clean checkout paths."
patterns-established:
  - "Package boundary tests assert both required public evidence and forbidden raw proof paths."
requirements-completed: [HYGIENE-04]
coverage:
  - id: D1
    description: "The actual Hex artifact contains only the resolved comparison assets and adoption evidence."
    requirement: HYGIENE-04
    verification:
      - kind: integration
        ref: "mix quality.hygiene"
        status: pass
    human_judgment: false
  - id: D2
    description: "PDF.js advisory observation uses a test-only fixture without package-visible raw PDF proof."
    requirement: HYGIENE-04
    verification:
      - kind: unit
        ref: "test/docs_contract/pdfjs_advisory_claims_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The hygiene gate runs through ci.fast and release validation while advisory checks remain separate."
    requirement: HYGIENE-04
    verification:
      - kind: integration
        ref: "mix ci.fast"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 12: Package Boundary and Hygiene Wiring Summary

**The Hex package now ships only reviewed comparison JSON evidence, while PDF.js proof is test-owned and one deterministic hygiene gate protects local, CI, and release paths.**

## Performance

- **Duration:** 18min
- **Started:** 2026-08-26T22:40:00Z
- **Completed:** 2026-08-26T22:58:00Z
- **Tasks:** 1/1
- **Files modified:** 18

## Accomplishments

- Removed five raw comparison PDFs, the obsolete static fixture, and `.gitkeep`; retained only the manifest-referenced JSON evidence and `comparison.json` in the package.
- Moved the Rendro PDF.js observer input to `test/fixtures/pdfjs-rendro.pdf` and updated the observation schema, data, and contracts.
- Wired `mix quality.hygiene` as the exact local, `ci.fast`, and release validation command; it validates the real unpacked Hex artifact and ignores unrelated local debris.

## Task Commits

1. **Task 1 RED: add failing hygiene boundary contracts** - `0c8f2f8` (test)
2. **Task 1 GREEN: enforce exact package hygiene boundary** - `ef98618` (feat)
3. **Task 1 verification fix: keep ci.fast Hex build runnable** - `13ca6df` (fix)

## Files Created/Modified

- `mix.exs` - Declares the hygiene alias and narrowed package membership.
- `.github/workflows/release.yml` - Runs the hygiene command in release validation.
- `test/fixtures/pdfjs-rendro.pdf` - Test-only PDF.js observer fixture.
- `dev/rendro/repository_hygiene.ex` - Treats its own planning-policy check as narrow maintainer tooling.
- `scripts/pdfjs_observer/observe.mjs` - Resolves the relocated fixture.
- `test/docs_contract/*` and `test/guardrails/required_checks_contract_test.exs` - Enforce fixture, package, and command contracts.

## Decisions Made

- Kept the deterministic hygiene lane separate from the advisory PDF.js observer lane.
- Used explicit individual package paths rather than a broad `bench/results` package directory.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Exempted the hygiene policy module from its own archive-consumer scan**
- **Found during:** Task 1 verification
- **Issue:** `mix quality.hygiene` classified the module's planning-placement policy regex as an operational archive consumer.
- **Fix:** Added the narrow maintainer-tooling exception with a regression contract.
- **Files modified:** `dev/rendro/repository_hygiene.ex`, `test/quality/repository_hygiene_test.exs`
- **Verification:** `mix quality.hygiene` passes.
- **Committed in:** `ef98618`

**2. [Rule 1 - Bug] Made ci.fast invoke the external Hex task in a child Mix command**
- **Found during:** Task 1 verification
- **Issue:** Starting the application in `quality.hygiene` prevented the subsequent alias entry `hex.build` from resolving.
- **Fix:** Replaced the alias entry with `cmd mix hex.build` and updated its exact guardrail contract.
- **Files modified:** `mix.exs`, `test/guardrails/required_checks_contract_test.exs`
- **Verification:** `mix ci.fast` passes.
- **Committed in:** `13ca6df`

**Total deviations:** 2 auto-fixed Rule 1 bugs.

## Issues Encountered

- The plan's focused-test command included unsupported `-x`; the same focused tests were run successfully without that invalid option.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The artifact boundary is deterministic and release-wired; Phase 133 can continue without package-visible raw PDF proof.

## Self-Check: PASSED

- `test/fixtures/pdfjs-rendro.pdf` exists.
- Task commits `0c8f2f8`, `ef98618`, and `13ca6df` exist.
- `mix quality.hygiene`, focused contracts, PDF.js observer check, and `mix ci.fast` passed.

---
*Phase: 133-repository-evidence-hygiene*
*Completed: 2026-08-26*

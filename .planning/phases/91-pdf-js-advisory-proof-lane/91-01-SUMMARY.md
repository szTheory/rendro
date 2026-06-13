---
phase: 91-pdf-js-advisory-proof-lane
plan: 01
subsystem: evidence
tags: [pdfjs, node, advisory-ci, docs-contract, guardrails]

requires:
  - phase: v2.6 evidence vocabulary
    provides: support-matrix deferrals, viewer-evidence claim boundaries, advisory CI patterns
provides:
  - Pinned PDF.js advisory observer under scripts/pdfjs_observer
  - Compact committed PDF.js observations under priv/pdfjs_observations
  - Docs-contract protections against PDF.js support overclaims
  - Graph-disconnected pdfjs-advisory CI lane
affects: [phase-92-docs-claims-release-hygiene, support-matrix, ci-guardrails]

tech-stack:
  added: [pdfjs-dist@6.0.227, Node 22.14.0 advisory tooling]
  patterns: [maintainer-only npm subtree, compact advisory observations, advisory-only CI registration]

key-files:
  created:
    - scripts/pdfjs_observer/package.json
    - scripts/pdfjs_observer/package-lock.json
    - scripts/pdfjs_observer/observe.mjs
    - priv/pdfjs_observations/schema.json
    - priv/pdfjs_observations/embedded_artifact_support_fixture.json
    - priv/pdfjs_observations/bench_rendro_invoice.json
    - test/docs_contract/pdfjs_advisory_claims_test.exs
  modified:
    - scripts/verify_docs.exs
    - .github/workflows/ci.yml
    - priv/guardrails/required_status_checks.json
    - test/guardrails/required_checks_contract_test.exs
    - test/docs_contract/forms_claims_test.exs
    - test/docs_contract/signing_claims_test.exs

key-decisions:
  - "Keep PDF.js as pinned advisory observations, not support-matrix promotion or GUI-viewer evidence."
  - "Use a direct Node ESM script instead of a Mix wrapper so Node/npm stays outside required BEAM lanes."
  - "Defer first-page PNG hashes until a future deterministic proof path exists."

patterns-established:
  - "Node advisory tooling is isolated under scripts/<tool>/ with package-lock and no mix.exs dependency."
  - "Observation checks compare stable PDF facts while recording runtime/platform metadata."
  - "Advisory CI jobs must be in advisory_contexts only, continue-on-error, and have no needs edge."

requirements-completed: [PDFJS-01, PDFJS-02, PDFJS-03]

duration: 34min
completed: 2026-06-13
---

# Phase 91: PDF.js Advisory Proof Lane Summary

**Pinned PDF.js advisory observations for representative Rendro PDFs, isolated from core runtime and required CI.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-06-13T02:46:00Z
- **Completed:** 2026-06-13T03:20:16Z
- **Tasks:** 4
- **Files modified:** 15

## Accomplishments

- Added `scripts/pdfjs_observer/observe.mjs` with `--write`, `--check`, and `--help`, using exact-pinned `pdfjs-dist@6.0.227`.
- Committed compact observations for `test/fixtures/embedded_artifact_support_fixture.pdf` and `bench/results/raw/rendro.pdf`, including PDF.js version, Node version, page counts, page dimensions, warnings, and errors.
- Added docs-contract tests that validate the observer package boundary, observation JSON shape, absence of unqualified PDF.js support wording, and preservation of existing PDF.js `explicit_deferral` rows.
- Added `pdfjs-advisory` to CI as a graph-disconnected `continue-on-error` job and registered it only under `advisory_contexts`.

## Task Commits

1. **Planning:** `0d3fa20` docs(91): plan pdfjs advisory proof lane
2. **Task 1:** `9b63f1a` feat(91-01): add pinned pdfjs observer
3. **Task 2:** `996f502` test(91-01): add pdfjs advisory claim guards
4. **Task 3:** `999a0e2` ci(91-01): add pdfjs advisory lane

## Files Created/Modified

- `scripts/pdfjs_observer/package.json` - Maintainer-only npm boundary with exact `pdfjs-dist` pin.
- `scripts/pdfjs_observer/package-lock.json` - Exact npm lockfile for advisory CI `npm ci`.
- `scripts/pdfjs_observer/observe.mjs` - PDF.js observer and stable-fact checker.
- `priv/pdfjs_observations/schema.json` - Project-owned observation JSON schema.
- `priv/pdfjs_observations/*.json` - Committed observations for two representative fixture PDFs.
- `test/docs_contract/pdfjs_advisory_claims_test.exs` - Observation, package-boundary, wording, and deferral guardrails.
- `.github/workflows/ci.yml` - Graph-disconnected `pdfjs-advisory` job.
- `priv/guardrails/required_status_checks.json` - Advisory-only context registration.
- `test/guardrails/required_checks_contract_test.exs` - Required/advisory separation checks, including 21 docs lanes.

## Decisions Made

- **Direct Node script:** Chosen over a Mix wrapper to avoid implying Node is part of Rendro's core runtime or required toolchain.
- **Metadata-only observations:** First-page PNG hashes were deferred because PDFJS-01 makes them optional and native canvas output can be platform-sensitive.
- **No support-matrix row:** Observations stay under `priv/pdfjs_observations/`; existing trust-sensitive `pdfjs` rows remain explicit deferrals.
- **Stable check surface:** `--check` compares stable PDF facts and verifies metadata shape; it records runtime/platform data without making OS strings part of the drift contract.

## Deviations from Plan

None. The planned optional PNG hash remained deferred by design.

## Issues Encountered

- The initial prose plan lacked GSD task frontmatter and was blocked by the plan checker. It was converted into executable GSD plan format and re-checked successfully before implementation.
- `mix format --check-formatted` flagged the new docs-contract file and `scripts/verify_docs.exs`; running `mix format` resolved it before commits.

## Verification

- `npm ci --prefix scripts/pdfjs_observer` — passed, 0 vulnerabilities.
- `node scripts/pdfjs_observer/observe.mjs --check` — passed for both committed observations.
- `mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/guardrails/required_checks_contract_test.exs` — 25 tests, 0 failures.
- `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs` — 34 tests, 0 failures.
- `mix run scripts/verify_docs.exs` — all 21 docs-contract lanes passed.
- `mix ci` — passed; 12 doctests, 4 properties, 1180 tests, 0 failures, 11 excluded; credo found no issues; dialyzer total errors 0.

Known existing verification noise: adapter redefinition warnings, telemetry local handler notices, docs-reference warnings, and the stale Apple Preview viewer-evidence warning still appear but do not fail the gate.

## User Setup Required

None for Rendro users. Maintainers who want to rerun the advisory lane need Node satisfying `>=22.13.0 || >=24`, then:

```bash
npm ci --prefix scripts/pdfjs_observer
node scripts/pdfjs_observer/observe.mjs --check
```

## Next Phase Readiness

Phase 92 can safely document the page-context and PDF.js advisory posture using the new observation files and docs-contract lane. It should keep public wording narrow: "pinned PDF.js advisory observations", not "PDF.js support".

---
*Phase: 91-pdf-js-advisory-proof-lane*
*Completed: 2026-06-13*


---
phase: 91-pdf-js-advisory-proof-lane
reviewed: 2026-06-13T03:27:10Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - scripts/pdfjs_observer/package.json
  - scripts/pdfjs_observer/package-lock.json
  - scripts/pdfjs_observer/observe.mjs
  - priv/pdfjs_observations/bench_rendro_invoice.json
  - priv/pdfjs_observations/embedded_artifact_support_fixture.json
  - priv/pdfjs_observations/schema.json
  - test/docs_contract/pdfjs_advisory_claims_test.exs
  - scripts/verify_docs.exs
  - .github/workflows/ci.yml
  - priv/guardrails/required_status_checks.json
  - test/guardrails/required_checks_contract_test.exs
  - test/docs_contract/forms_claims_test.exs
  - test/docs_contract/signing_claims_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 91: Code Review Report

**Reviewed:** 2026-06-13T03:27:10Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** clean

## Summary

Re-reviewed Phase 91 after follow-up fix commit `4bf139f fix(91-01): enforce pdfjs observation keys`. The previous WR-01 is resolved: `scripts/pdfjs_observer/observe.mjs --check` now rejects unexpected top-level observation keys and unexpected nested page keys, and `test/docs_contract/pdfjs_advisory_claims_test.exs` mirrors that contract in the required Mix docs lane.

The quick follow-up scan found no remaining HIGH/WARNING issues in the requested risk areas:

- Node/npm dependency boundary leaks: `pdfjs-dist` remains confined to `scripts/pdfjs_observer`, exact-pinned, and absent from `mix.exs` and the deterministic CI test job.
- PDF.js support overclaim/promotion risk: public docs and support-matrix rows keep PDF.js as advisory or explicit deferral, without `evidence`, `proof`, `recorded_at`, or `viewer_kind` promotion fields on deferred PDF.js rows.
- Advisory CI required-lane contamination: `pdfjs-advisory` remains graph-disconnected, `continue-on-error: true`, and listed only as an advisory context, not a required status check.
- Observation checker false negatives: forbidden extra keys are now rejected before stable-fact comparison can drop them.

All reviewed files meet quality standards. No issues found.

## Verification Commands Observed

- `npm run check` from `scripts/pdfjs_observer` -> checked both committed observations successfully.
- Temp-worktree negative check with top-level `viewer_kind` added to an observation -> `node observe.mjs --check` failed with `unexpected key viewer_kind`.
- Temp-worktree negative check with page-level `proof` added to an observation page -> `node observe.mjs --check` failed with `unexpected key proof`.
- `mix test test/docs_contract/pdfjs_advisory_claims_test.exs` -> 6 tests, 0 failures.
- `mix test test/guardrails/required_checks_contract_test.exs` -> 19 tests, 0 failures.

## Narrative Findings (AI reviewer)

No Critical, Warning, or Info findings.

### Resolved Previous Finding

**WR-01:** `observe.mjs --check` did not enforce the observation schema. Resolved by `4bf139f`, which added explicit allowed-key checks for observation objects and page objects in `observe.mjs`, plus required/optional key assertions in `pdfjs_advisory_claims_test.exs`.

---

_Reviewed: 2026-06-13T03:27:10Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

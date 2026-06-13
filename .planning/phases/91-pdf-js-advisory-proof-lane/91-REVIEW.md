---
phase: 91-pdf-js-advisory-proof-lane
reviewed: 2026-06-13T03:22:55Z
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
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-06-13T03:22:55Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the pinned PDF.js observer, committed observations, docs-contract guards, CI wiring, and required-status guardrails for Phase 91. The Node/npm dependency stays scoped to `scripts/pdfjs_observer` and the `pdfjs-advisory` job is graph-disconnected with `continue-on-error: true`; focused verification also passed. One guardrail gap remains: the committed observation schema is stricter than the actual checker/tests, so support-promoting or otherwise non-contract fields can be added without tripping `--check`.

## Verification Commands Observed

- `mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/guardrails/required_checks_contract_test.exs` -> 25 tests, 0 failures
- `npm ci` from `scripts/pdfjs_observer` -> installed/audited successfully, 0 vulnerabilities
- `npm run check` from `scripts/pdfjs_observer` -> checked both committed observations successfully

## Warnings

### WR-01: `observe.mjs --check` Does Not Enforce The Observation Schema

**File:** `scripts/pdfjs_observer/observe.mjs:63`

**Issue:** `priv/pdfjs_observations/schema.json` declares `additionalProperties: false` and narrows fields like `observer`, `pdfjs_dist_version`, fixture paths, and page objects. The runtime checker never loads that schema. Instead, `assertObservationShape/2` only checks a small set of types, and the drift comparison serializes `stableObservation/1`, which drops every unknown property before comparing expected and actual observations. The docs-contract test has the same blind spot: it accepts all extra keys except for a narrow optional hash check.

That means a committed observation could add fields such as `viewer_kind`, `evidence`, `proof`, or `gui_viewer_proof` and `node observe.mjs --check` would still pass as long as the stable subset is unchanged. This creates a false negative in the advisory proof lane and weakens the support-promotion boundary the phase is trying to protect.

**Fix:** Validate committed observations against the JSON schema during `--check` and fail on unknown keys. A minimal local fix is to add an exact-key assertion matching the schema and apply it to both top-level observations and page objects:

```js
const OBSERVATION_KEYS = new Set([
  "schema_version",
  "observer",
  "advisory_boundary",
  "pdfjs_dist_version",
  "node_version",
  "recorded_at",
  "platform",
  "fixture",
  "page_count",
  "pages",
  "warnings",
  "errors",
  "first_page_png_sha256"
]);

const PAGE_KEYS = new Set(["page_number", "width", "height"]);

function assertAllowedKeys(object, allowedKeys, output) {
  for (const key of Object.keys(object)) {
    if (!allowedKeys.has(key)) {
      throw new Error(`${output}: unexpected observation key ${key}`);
    }
  }
}
```

Call `assertAllowedKeys(observation, OBSERVATION_KEYS, output)` in `assertObservationShape/2`, and call the page variant inside the page loop. Also add a docs-contract assertion that `Map.keys(observation) -- allowed_keys == []` so the required Mix lane catches the same contract gap without requiring Node.

---

_Reviewed: 2026-06-13T03:22:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

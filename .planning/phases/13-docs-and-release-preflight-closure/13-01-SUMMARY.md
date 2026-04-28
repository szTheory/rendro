---
phase: 13-docs-and-release-preflight-closure
plan: "01"
subsystem: testing
tags: [docs-contract, readme, exunit, guides]
requires:
  - phase: 12-verification-chain-closure
    provides: canonical verification lanes and hosted-proof expectations
provides:
  - explicit README doctest and compile/eval docs lanes
  - curated integrations guide executable surface
  - semantic-claim regression coverage for public adapter guidance
affects: [QUAL-02, mix-verify, release-preflight]
tech-stack:
  added: []
  patterns: [explicit docs-contract fence ids, named docs lanes]
key-files:
  created: [test/support/docs_contract.ex, test/docs_contract/readme_doctest_test.exs, test/docs_contract/integrations_contract_test.exs, test/docs_contract/integrations_claims_test.exs]
  modified: [README.md, guides/integrations.md, scripts/verify_docs.exs]
key-decisions:
  - "Verified `elixir` fences now require explicit docs-contract ids while schematic examples move to `elixir-schematic`."
  - "README output-sensitive behavior is covered through markdown doctests; guide semantics are pinned by ExUnit instead of compile-only checks."
patterns-established:
  - "Public docs examples must declare whether they are doctest, compile/eval, or schematic."
requirements_completed: [QUAL-02]
duration: 35 min
completed: 2026-04-28
---

# Phase 13 Plan 01: Docs Contract Summary

**Explicit README and integration-guide docs lanes backed by doctests, compile/eval checks, and semantic-claim regressions**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-28T14:27:00Z
- **Completed:** 2026-04-28T15:01:40Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Reclassified schematic README and guide snippets out of the verified `elixir` lane and labeled the executable contract surface explicitly.
- Added markdown doctest and compile/eval contract coverage for README and the curated integrations guide.
- Replaced the heuristic README-only verifier with an explicit lane runner that fails through ExUnit-backed docs checks.

## Files Created/Modified
- `README.md` - Explicit README doctest and compile/eval contract lanes.
- `guides/integrations.md` - Curated executable guide fences plus truthful schematic examples.
- `scripts/verify_docs.exs` - Canonical docs lane runner.
- `test/support/docs_contract.ex` - Shared markdown-fence helper for docs contract tests.
- `test/docs_contract/*.exs` - README doctest, guide happy-path, and semantic-claim regressions.

## Decisions Made
- Use explicit `# docs-contract:` ids inside verified fences so the contract surface is reviewable in the docs themselves.
- Keep guide semantic behavior under direct tests instead of pretending compile success proves runtime claims.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The guide exposed stale Mailglass success-tuple examples while wiring the executable lane; those snippets were narrowed to the actual return shape before the docs contract was accepted.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Release metadata and strict preflight work can now build on a canonical docs contract.
- `mix docs.contract` promotion and release-proof helper work can reuse this lane structure directly.

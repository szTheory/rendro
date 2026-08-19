---
phase: 129-docs-manifest-closure
plan: "02"
subsystem: documentation-package-contract
tags: [exdoc, hex, markdown, static-assets, presets]
requires:
  - phase: 129-01
    provides: canonical formatter-owned preset guide and support-boundary claim lane
provides:
  - Outcome-named README, presets, theming, Livebook, branding, and support-boundary reader route
  - Six neutral preset chooser rows with explicit evidence and quality disclosures
  - ExDoc and Hex package closure for the public configurator, catalog, and token stylesheet graph
affects: [129-03 manifest and guardrail closure, HexDocs consumers, Hex package consumers]
tech-stack:
  added: []
  patterns: [source-tarball-generated-docs path proof, narrow static asset allowlist]
key-files:
  created: [.planning/phases/129-docs-manifest-closure/129-02-SUMMARY.md]
  modified: [README.md, guides/presets.md, guides/theming.md, mix.exs, test/docs_contract/presets_claims_test.exs]
key-decisions:
  - "Keep presets as the canonical chooser while theming remains a compact manual-token/from_brand reference."
  - "Use the absolute HexDocs configurator URL from the guide because one relative asset link cannot resolve from source Markdown and root-level ExDoc extras."
  - "Ship only the catalog, configurator, and tokens.css static dependencies; retain private evidence exclusions."
metrics:
  duration: 19min
  completed: 2026-08-19
  tasks: 2
  files: 5
status: complete
---

# Phase 129 Plan 02: Reader Route and Package Closure Summary

**Canonical preset discovery now resolves from checkout, the Hex archive, and generated ExDoc without widening Rendro's public evidence claims.**

## Accomplishments

- Expanded the canonical Presets guide with exactly six neutral directions and job-specific routes for the static configurator, generator, Livebook, manual Theming, Branding, and API Stability boundaries.
- Added a compact README discovery section before legacy gallery artifacts, plus outcome-named guide routes, while keeping Theming focused on manual tokens and `from_brand/2`.
- Preserved visible exact/representative-accent/unavailable preview, screen-oriented dark, and three-label quality disclosures without claiming approval, certification, accessibility, or print guarantees.
- Registered `guides/presets.md` in the existing ExDoc Guides group and copied only the required configurator/catalog asset graph plus `brand/tokens/tokens.css`.
- Added a synchronous cross-context contract that checks source Markdown routes, a unique generated ExDoc output including all 32 catalog images, Hex package contents, and private-path exclusions.

## Task Commits

1. **Task 1: Expand the canonical guide and outcome-named discovery route** — `0f9d639` (RED), `31c153c` (GREEN)
2. **Task 2: Close ExDoc and Hex package paths for the public static asset graph** — `454859e` (RED), `f21938b` (GREEN)

## Files Created/Modified

- `guides/presets.md` — six-direction chooser, distinct adoption jobs, and factual preview/dark/quality disclosures.
- `README.md` — early preset/configurator/Livebook discovery with outcome-named guide routes.
- `guides/theming.md` — compact early handoff to the canonical Presets guide.
- `mix.exs` — ExDoc extra/group registration and narrow public package/asset mappings.
- `test/docs_contract/presets_claims_test.exs` — red/green discovery, package, Hex tarball, and generated ExDoc contracts.

## Decisions Made

- Kept the canonical guide and manual-theming guide separate to avoid duplicate tutorials.
- Used the absolute HexDocs configurator route in the guide, which is the single route that resolves from source Markdown and root-level generated ExDoc output.
- Kept the package addition to four explicit public paths and one in-memory ExDoc stylesheet asset, excluding broad brand and private evidence trees.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Verification

- `mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/configurator_static_contract_test.exs test/docs_contract/configurator_resolver_contract_test.exs --max-failures 1` — passed: 35 tests, 0 failures.
- `mix docs --warnings-as-errors` — passed; generated `presets.html`, `first_invoice.html`, static configurator/catalog assets, and `brand/tokens/tokens.css`.
- `mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs test/docs_contract/public_api_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` — passed: 48 tests, 0 failures.

## Self-Check: PASSED

- Confirmed all five modified delivery files and this summary exist.
- Confirmed task commits `0f9d639`, `31c153c`, `454859e`, and `f21938b` exist in git history.

---
*Phase: 129-docs-manifest-closure*
*Completed: 2026-08-19*

---
phase: 128-static-configurator-theme-codegen-livebook
plan: "03"
subsystem: static configurator
tags: [static-html, css, vanilla-javascript, exdoc, theme, clipboard]
requires:
  - phase: 128-01
    provides: formatter-owned 504-record configurator snippet index
provides:
  - Static semantic configurator shell under the existing ExDoc asset tree
  - Strict four-key canonical URL state with atomic fallback
  - Exact, representative, or absent catalog preview provenance with formatter-owned copy
affects: [128-04, 128-05, documentation, theme discovery]
tech-stack:
  added: []
  patterns: [closed manifest validation, safe DOM projection, atomic URL state, truthful asynchronous clipboard feedback]
key-files:
  created:
    - assets/rendro/configurator/index.html
    - assets/rendro/configurator/configurator.css
    - assets/rendro/configurator/configurator.js
    - test/docs_contract/configurator_static_contract_test.exs
    - test/docs_contract/configurator_resolver_contract_test.exs
  modified: []
key-decisions:
  - "Keep requested code identity separate from derived catalog preview identity; representative previews never rewrite selected source values."
  - "Reject malformed, duplicate, partial, and unknown query state atomically, then serialize only the four canonical keys."
  - "Copy exactly the visible committed formatter string and report Clipboard success only after its promise resolves."
metrics:
  duration: 15min
  completed: 2026-08-19
  tasks: 2
  files: 5
status: complete
---

# Phase 128 Plan 03: Static Configurator Summary

Accessible static configurator with strict share URLs, bounded catalog preview provenance, and exact formatter-owned Elixir copying.

## Accomplishments

- Added a semantic static HTML shell with native labeled selectors, polite status and alert regions, selectable source, and no form submission or persistence surface.
- Added token-native responsive styling with a 320px control column at desktop, stacked mobile layout, 44px controls, focus/selection affordances, natural raster sizing, overflow-safe source, and reduced-motion handling.
- Validated both local JSON inputs before enabling interaction, including closed enum values and safe relative catalog paths; manifest or image failures disable actions and do not fabricate a preview.
- Implemented atomic four-key URL parsing and canonical serialization, ordered exact/representative/none preview resolution, and Clipboard feedback that remains factual on success and failure.

## Verification

- `mix test test/docs_contract/configurator_static_contract_test.exs test/docs_contract/configurator_resolver_contract_test.exs test/rendro/theme/snippet_test.exs --max-failures 1` — 14 tests, 0 failures.
- `mix format --check-formatted` — passed.

## Task Commits

1. **Task 1: Build the static semantic shell, token layout, and safe loading states** — `9beccf5` (feat)
2. **Task 2: Implement atomic URL state, three-state preview resolution, and truthful clipboard feedback** — `cd308db` (feat)

## Decisions Made

- Preserve the selected family/preset/accent/mode as the canonical copied-source identity, with preview evidence resolved independently.
- Use the first selectable validated catalog cell for atomic fallback, which currently resolves to Invoice/Swiss/#2C6BED/light.
- Keep the static surface browser-native and local-only: no live render, build pipeline, framework, server, storage, or fuzzy preview matching.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All five planned static and contract-test files exist.
- Task commits `9beccf5` and `cd308db` exist in git history.
- No task commit deleted tracked files.
- The focused static/resolver/source verification and formatter check passed after the final changes.

## Next Phase Readiness

The livebook and documentation plans can link to the committed static configurator while relying on the same formatter-owned source vocabulary.

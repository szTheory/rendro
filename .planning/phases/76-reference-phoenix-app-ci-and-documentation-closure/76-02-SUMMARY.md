---
phase: 76-reference-phoenix-app-ci-and-documentation-closure
plan: "02"
subsystem: phoenix-example
tags: [phoenix, recipes, statement, receipt, certificate, controller, tests, conncase]
dependency_graph:
  requires: ["76-01"]
  provides:
    - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
    - examples/phoenix_example/lib/phoenix_example_web/router.ex
    - examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex
    - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
  affects: [examples/phoenix_example]
tech_stack:
  added: [decimal (transitive via mix.lock)]
  patterns: [inline @demo_* module attrs, RendroPhoenix.render_pdf/3 + preview_pdf/2, ConnCase HTTP + structural assertions]
key_files:
  created: []
  modified:
    - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
    - examples/phoenix_example/lib/phoenix_example_web/router.ex
    - examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex
    - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
decisions:
  - "D-05: Cloned Invoice/BrandedInvoice dead-controller pattern for Statement, Receipt, Certificate — no LiveView, no shared SampleData module"
  - "D-06: Inline @demo_* module attrs with Decimal.new values — Float raises ArgumentError in validate_data!/1"
  - "D-07: 6 new routes in :api scope (/statement/*, /receipt/*, /certificate/*) plus 6 chooser links in page_controller.ex"
  - "D-08: Per-recipe ConnCase tests: HTTP+magic-bytes+structural; Certificate asserts region_names == [:body] (single-body only), NOT 3-region set"
metrics:
  duration: "5m"
  completed: "2026-05-29"
  tasks: 2
  files: 4
---

# Phase 76 Plan 02: Reference Phoenix App — Statement/Receipt/Certificate via Adapter Summary

Statement, Receipt, and Certificate recipes demonstrated through Rendro.Adapters.Phoenix with attachment + inline routes, chooser links, and passing ConnCase + structural tests including the Certificate single-:body-region assertion.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add 3 fixtures + 6 actions, 6 routes, 6 chooser links (D-05, D-06, D-07) | e3e7855 | pdf_controller.ex, router.ex, page_controller.ex, mix.lock |
| 2 | Per-recipe ConnCase + structural tests (D-08) | 748bf43 | pdf_controller_test.exs |

## Verification Results

- `cd examples/phoenix_example && mix compile --warnings-as-errors` exits 0 (rendro library warnings are pre-existing, library-owned, not example-app source)
- `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` exits 0 — 12 tests, 0 failures
- `cd examples/phoenix_example && mix test` exits 0 — full example-app suite green
- All 6 new action names present in pdf_controller.ex: statement_download, statement_preview, receipt_download, receipt_preview, certificate_download, certificate_preview
- All 6 new routes present in router.ex: /statement/download, /statement/preview, /receipt/download, /receipt/preview, /certificate/download, /certificate/preview
- All Decimal amounts use Decimal.new("...") — no bare floats; @demo_statement lines have no :balance key
- Certificate structural test asserts region_names == [:body] — not the 3-region Statement/Receipt assertion

## Decisions Made

- Cloned Invoice/BrandedInvoice action pair pattern 1:1 for all three new recipes (statement_download/2 + statement_preview/2, etc.)
- Used Decimal.new("...") for all amount/balance values as required by validate_data!/1 (Float raises ArgumentError)
- Certificate structural test uses `assert region_names == [:body]` (exactly one body-only region) per certificate.ex:89-100 — critical deviation from the 3-region Statement/Receipt assertion pattern
- Extended source-level check test to assert all 5 recipe document/1 calls are present in the controller
- mix.lock updated to include the `decimal` dependency (transitive, required by Decimal.new in fixtures)

## Deviations from Plan

None — plan executed exactly as written. The mix.lock decimal entry addition is an expected consequence of using Decimal.new in the controller module attributes (compile-time evaluation adds the dep).

## Known Stubs

None — all six controller actions are fully wired to real recipe document/1 calls and the Phoenix adapter. All routes are active. All tests exercise real HTTP paths.

## Threat Flags

None — actions bind `_params` and serve only fixed inline `@demo_*` fixtures; all fixture data is fictitious (Acme Corp, Jane Smith). No user input reaches `document/2`.

## Self-Check: PASSED

- examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex — FOUND (modified, 6 new actions + 3 @demo_* attrs)
- examples/phoenix_example/lib/phoenix_example_web/router.ex — FOUND (modified, 6 new routes)
- examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex — FOUND (modified, 6 new chooser links)
- examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs — FOUND (modified, 3 new describe blocks)
- Commit e3e7855 — verified in git log
- Commit 748bf43 — verified in git log

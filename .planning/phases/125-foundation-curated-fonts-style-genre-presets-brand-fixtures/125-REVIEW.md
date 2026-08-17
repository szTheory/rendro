---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
reviewed: 2026-08-17T02:16:34Z
depth: standard
files_reviewed: 73
files_reviewed_list:
  - NOTICE
  - README.md
  - assets/rendro/artifacts.json
  - guides/recipes.md
  - guides/theming.md
  - lib/rendro/adapters/pdfium.ex
  - lib/rendro/font_registry.ex
  - lib/rendro/pdf/cid_font.ex
  - lib/rendro/pdf/font.ex
  - lib/rendro/pdf/font_parser.ex
  - lib/rendro/pdf/font_subsetter.ex
  - lib/rendro/recipes/certificate.ex
  - lib/rendro/recipes/receipt.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/theme.ex
  - lib/rendro/theme/presets.ex
  - mix.exs
  - priv/examples/certificate/aster-institute/certificate.json
  - priv/examples/certificate/aster-institute/logo.svg
  - priv/examples/certificate/meridian-arts-fellowship/certificate.json
  - priv/examples/certificate/meridian-arts-fellowship/logo.svg
  - priv/examples/invoice/cedar-mutual/invoice.json
  - priv/examples/invoice/cedar-mutual/logo.svg
  - priv/examples/invoice/northline-logistics/invoice.json
  - priv/examples/invoice/northline-logistics/logo.svg
  - priv/examples/payslip/cedar-mutual/logo.svg
  - priv/examples/payslip/cedar-mutual/payslip.json
  - priv/examples/payslip/northline-logistics/logo.svg
  - priv/examples/payslip/northline-logistics/payslip.json
  - priv/examples/receipt/circuit-supply-co/logo.svg
  - priv/examples/receipt/circuit-supply-co/receipt.json
  - priv/examples/receipt/poppy-and-grain/logo.svg
  - priv/examples/receipt/poppy-and-grain/receipt.json
  - priv/examples/statement/aster-research-fund/logo.svg
  - priv/examples/statement/aster-research-fund/statement.json
  - priv/examples/statement/signal-ledger/logo.svg
  - priv/examples/statement/signal-ledger/statement.json
  - priv/examples/ticket/field-notes-conference/logo.svg
  - priv/examples/ticket/field-notes-conference/ticket.json
  - priv/examples/ticket/the-letterpress-hall/logo.svg
  - priv/examples/ticket/the-letterpress-hall/ticket.json
  - priv/goldens/certificate/dark.sha256
  - priv/public_api.json
  - priv/raster_refs/presets/brutalist/dark.sha256
  - priv/raster_refs/presets/brutalist/light.sha256
  - priv/raster_refs/presets/corporate_classic/dark.sha256
  - priv/raster_refs/presets/corporate_classic/light.sha256
  - priv/raster_refs/presets/editorial/dark.sha256
  - priv/raster_refs/presets/editorial/light.sha256
  - priv/raster_refs/presets/humanist/dark.sha256
  - priv/raster_refs/presets/humanist/light.sha256
  - priv/raster_refs/presets/minimal_mono/dark.sha256
  - priv/raster_refs/presets/minimal_mono/light.sha256
  - priv/raster_refs/presets/swiss/dark.sha256
  - priv/raster_refs/presets/swiss/light.sha256
  - priv/schemas/examples.schema.json
  - test/docs_contract/examples_schema_contract_test.exs
  - test/docs_contract/preset_fonts_package_contract_test.exs
  - test/docs_contract/theme_industry_guard_test.exs
  - test/mix/tasks/release_preflight_test.exs
  - test/rendro/adapters/pdfium_test.exs
  - test/rendro/pdf/cid_font_test.exs
  - test/rendro/pdf/font_subsetter_test.exs
  - test/rendro/recipes/branded_invoice_byte_identity_test.exs
  - test/rendro/recipes/certificate_typography_test.exs
  - test/rendro/recipes/payslip_byte_identity_test.exs
  - test/rendro/recipes/statement_typography_test.exs
  - test/rendro/theme/preset_fonts_test.exs
  - test/rendro/theme/preset_raster_snapshot_test.exs
  - test/rendro/theme/preset_render_matrix_test.exs
  - test/rendro/theme/presets_test.exs
  - test/support/hex_build_cache_test.exs
  - test/support/preset_render_matrix.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 125: Code Review Report

**Reviewed:** 2026-08-17T02:16:34Z
**Depth:** standard
**Files Reviewed:** 73
**Status:** issues_found

## Summary

All prior blockers and warnings are resolved in the current implementation: Certificate uses the resolved leading and curated font metrics for centering; Statement registers the selected curated roles for measurement; both proof lanes use the same 12-row matrix; invalid preset IDs and out-of-range glyph IDs fail explicitly; the PDFium wrapper is separated from the SHA-pinned provenance artifact; and the Certificate launch/raster evidence now verifies.

The standard full suite passes (1,732 tests, 0 failures; 27 excluded), `mix rendro.launch_artifacts.check` passes, formatting passes, and the isolated pinned-PDFium raster matrix passes. One test-isolation warning remains: the adapter unit module mutates VM-global application configuration and process-global environment variables while declaring itself async, causing the combined raster test invocation to fail depending on scheduling.

Verification performed:

- `mix test`: 1,732 tests, 0 failures (27 excluded).
- `mix rendro.launch_artifacts.check`: passed.
- `mix format --check-formatted`: passed.
- Pinned runner: mounted binary SHA-256 matches `priv/pdfium_pin.json`; `--version` returns `v0.11.0`.
- Isolated matrix: `PATH=/private/tmp/rendro-pdfium-Riomtw/bin:$PATH RENDRO_PDFIUM_PROVENANCE_CLI=/private/tmp/rendro-pdfium-Riomtw/pdfium-cli mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs`: passed.
- Combined focused command containing both the adapter and raster modules fails at the pinned-digest assertion because the async adapter test deletes `RENDRO_PDFIUM_PROVENANCE_CLI` during the raster module's run.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: [WARNING] PDFium tests race the pinned raster contract through global state

**File:** `test/rendro/adapters/pdfium_test.exs:2, 7-10, 16-22, 29-34`
**Issue:** This module is marked `async: true` while its tests modify the VM-global `Application` PDFium settings and the process-global `RENDRO_PDFIUM_PROVENANCE_CLI` environment variable. The raster contract concurrently reads those same settings at `test/rendro/theme/preset_raster_snapshot_test.exs:55-67`. In the combined focused invocation, the adapter test's `on_exit` deletes the caller-provided provenance path before the raster test hashes it, producing `raster snapshots require the project-pinned PDFium binary digest`. The pinned raster lane is consequently schedule-dependent rather than a reliable verification gate.

**Fix:** Make `Rendro.Adapters.PdfiumTest` synchronous (`use ExUnit.Case, async: false`) or serialize and restore the exact prior application/env values around every mutation. Keep the raster module synchronous and add a regression command/test that runs both modules together under the pinned wrapper/provenance environment.

---

_Reviewed: 2026-08-17T02:16:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

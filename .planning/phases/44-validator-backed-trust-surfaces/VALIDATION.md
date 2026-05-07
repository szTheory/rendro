# Phase 44 Validation

This document outlines the Nyquist-compliant test criteria and success conditions for Phase 44 (Validator-backed Trust Surfaces).

## Goal
Strengthen the evidence and support surface around produced PDFs by providing structural validation against an external tool (`pdfinfo`), alongside a machine-readable support matrix for claims.

## Verification Scenarios

### Scenario 1: Adapter Missing Executable Graceful Degradation
* **Given** the environment does not have `pdfinfo` installed (e.g., using `System.put_env` or stubbing `System.find_executable` in the tests)
* **When** `Rendro.Adapters.Poppler.validate/1` is called
* **Then** it must return `{:error, {:missing_executable, "pdfinfo"}}` and avoid any `:enoent` crashes.
* **Nyquist Automation**: `mix test test/rendro/adapters/poppler_test.exs`

### Scenario 2: Valid PDF Successfully Parsed
* **Given** `pdfinfo` is available in the environment
* **When** `Rendro.Adapters.Poppler.validate/1` is called with a valid PDF file path
* **Then** it must return `{:ok, metadata_map}`.
* **Nyquist Automation**: `mix test test/rendro/adapters/poppler_test.exs`

### Scenario 3: Corrupt/Invalid PDF Handled Correctly
* **Given** `pdfinfo` is available in the environment
* **When** `Rendro.Adapters.Poppler.validate/1` is called with an invalid/dummy text file
* **Then** it must return `{:error, {:invalid_pdf, reason}}`.
* **Nyquist Automation**: `mix test test/rendro/adapters/poppler_test.exs`

### Scenario 4: Machine-readable Support Matrix Exists
* **Given** the repository state
* **When** `priv/support_matrix.json` is read
* **Then** it must successfully parse as JSON and contain the top-level keys (`validators`, `surfaces`, `unsupported`).
* **Nyquist Automation**: `jq . priv/support_matrix.json > /dev/null`

## Success Conditions
1. All ExUnit tests in `test/rendro/adapters/poppler_test.exs` pass reliably.
2. `priv/support_matrix.json` exists and matches the required schema.
3. Code changes use analog patterns successfully and defensively guard against missing OS dependencies.

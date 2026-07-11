---
phase: 110
slug: test-concurrency-determinism-cleanup
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-10
updated: 2026-07-10
---

# Phase 110 Validation

## Goal-Backward Validation

What must be true for this phase to be complete:

1. **Test Concurrency (`async: true`) Maximized:**
   - [x] All safely-isolatable tests are `async: true` (TEST-01).
   - [x] `DocsContract.evaluate!/2` statically enforces read-only execution by validating the AST, allowing contract tests to run asynchronously.
   - [x] Shared `hex.build` test setup costs are mitigated via a singleton `HexBuildCache`, allowing claims tests to run concurrently.

2. **Flake Quarantine and Test Layering:**
   - [x] The `mix verify.flake` nightly quarantine lane exists in mix aliases and correctly scopes to the `:quarantine` tag.
   - [x] `RecipesFacadeDriftTest` is correctly tagged with `@moduletag :quarantine` and does not fail the primary PR pipeline.
   - [x] ExUnit default exclusions explicitly exclude `:quarantine`, `:live_pdf_tools`, `:live_signing`, and `:raster_snapshot` tags.

3. **Performance Visibility:**
   - [x] Mix test aliases (`ci`, `verify.flake`, `test.all`) include `--slowest 10` to continuously surface slow tests (TEST-05).

4. **Strategic Documentation:**
   - [x] The test helper file clearly documents the rejection of `mix test --partitions N` in favor of maximizing `async: true` (D-01).
   - [x] Valid reasons for remaining `async: false` tests (like global state mutation) are documented in the test helper.

## Verification Procedures

Run the following commands to verify the structural integrity of the test suite adjustments:

1. **Verify Default Test Execution (Exclusions & Async)**
   ```bash
   mix test
   ```
   **Expected Result:** The suite runs without executing quarantined or live tests, and tests run with high concurrency. Slowest tests are reported at the end.

2. **Verify CI Pipeline Alias**
   ```bash
   mix ci
   ```
   **Expected Result:** The `ci` task excludes `:quarantine` tests and runs successfully, with `--slowest` reporting.

3. **Verify the Quarantine Lane**
   ```bash
   mix verify.flake
   ```
   **Expected Result:** The test command executes specifically the tests tagged with `:quarantine`, such as `RecipesFacadeDriftTest`.

4. **Verify AST Read-Only Protection**
   Run the specific docs contract test to ensure it blocks malicious or mutating code:
   ```bash
   mix test test/support/docs_contract_test.exs
   ```
   **Expected Result:** Tests should assert that `DocsContract.evaluate!/2` raises exceptions when `File.write`, `System.cmd`, or `Mix.Task` are executed.

5. **Verify Claims Tests Concurrency**
   ```bash
   mix test test/docs_contract/
   ```
   **Expected Result:** The claims tests run successfully, utilizing the `HexBuildCache` to run `mix hex.build` only once, demonstrating safe `async: true` behavior.

## Validation Sign-Off

- [x] All TEST requirements have automated or verifier-backed evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] No watch-mode flags.
- [x] Feedback latency within the phase's expected local test bounds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-10 from `110-VERIFICATION.md`.

## Validation Audit 2026-07-10

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated/manual-only | 0 |

The validation file existed in a non-standard shape without Nyquist frontmatter. This audit adds frontmatter and reconciles the checklist with `110-VERIFICATION.md`.

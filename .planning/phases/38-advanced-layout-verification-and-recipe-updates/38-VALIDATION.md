# Phase 38: VALIDATION.md

## Validation Strategy
1. **Goal:** Verify multi-page tables and Arabic text shaping render deterministically.
2. **Artifact:** `test/rendro/recipes/invoice_test.exs` will contain the deterministic rendering test.
3. **Artifact:** `README.md` and `test/docs_contract/readme_doctest_test.exs` will prove the docs-contract.
4. **Acceptance Criteria:**
   - The generated PDF binary explicitly contains the Arabic font name (e.g. `NotoSansArabic`) indicating successful shaping.
   - The test must assert exact byte-for-byte matches across multiple test executions.
   - The documentation code fence compiles successfully.

# Phase 38-01 Summary: Advanced Layout Verification & Recipe Updates

## Context
This plan serves as the execution guide for Slice S05 of the v1.4 Advanced Layout & Typography milestone. It verifies the integration of table fragmentation (Phase 37) and text shaping (Phase 35) using the canonical `Invoice` recipe.

## Execution Strategy
The execution will add a new test to the `Invoice` recipe that provides a 60-item list containing Arabic names to trigger multi-page rendering and HarfBuzz text shaping/fallbacks. It will use deterministic rendering to verify the output is stable byte-for-byte.

Additionally, a docs-contract test snippet will be added to the `README.md` to demonstrate the Advanced Layout and i18n capabilities to end-users, ensuring that the documentation compiles and executes correctly without placeholders.

## Tasks Addressed
1. **Add Advanced Layout Deterministic Test**: Modify `test/rendro/recipes/invoice_test.exs` to verify deterministic layout and shaping for multi-page Arabic content.
2. **Docs-Contract Test Update**: Add an evaluable block to `README.md` and verify it via `test/docs_contract/readme_doctest_test.exs`.

## Artifacts to Create/Modify
- `test/rendro/recipes/invoice_test.exs`
- `README.md`
- `test/docs_contract/readme_doctest_test.exs`
# Deferred Items — Phase 114

## Out-of-scope failure discovered during Plan 114-07 Task 4

**Lane:** `Comparison claims lane` (`test/docs_contract/comparison_claims_test.exs:56`)

**Symptom:** `mix run scripts/verify_docs.exs` fails one pre-existing lane. The checked-in
comparison guide block still references the old benchmark scenario path
`bench/comparison/fixtures/invoice_data.json`, while `Rendro.Comparison.evidence_block/1`
now generates `priv/examples/invoice/acme-phoenix-saas/invoice.json`.

**Root cause:** Plans 114-01 / 114-03 repointed the comparison benchmark fixture to the
new `priv/examples/...` location but did not regenerate the checked-in comparison guide
markdown block. Not caused by Plan 114-07 (which only touches `mix.exs`, `.gitignore`,
`examples_schema_contract_test.exs`, `branding_claims_test.exs`, `verify_docs.exs`,
`required_checks_contract_test.exs`).

**Status:** RESOLVED (post-merge fix, commit `c4e122e`). The stale `Scenario` line in
`guides/comparison.md` was resynced to `priv/examples/invoice/acme-phoenix-saas/invoice.json`
to match `Rendro.Comparison.evidence_block/1` (the sole one-line diff, 45/45 block lines
otherwise identical). `mix test test/docs_contract/comparison_claims_test.exs` → 10 tests,
0 failures; `mix run scripts/verify_docs.exs` → "Docs contract VERIFIED!"; full suite
`mix test --exclude quarantine` → 1232 tests, 0 failures.

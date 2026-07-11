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

**Status:** Out of scope for Plan 114-07 per the executor scope boundary. Plan 114-07's own
three new lanes (Examples schema, Rubric manifest, Domain content) all PASS. Needs the
comparison guide regenerated (whatever generator backs `Rendro.Comparison.evidence_block/1`)
before the phase-gate `mix ci.fast` / `verify_docs.exs` goes fully green.

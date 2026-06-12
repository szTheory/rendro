---
type: quick-task-summary
id: 260612-iqj-automate-hexdocs-publish-and-public-url-
title: Automate HexDocs publish and public URL verification on main
status: complete
branch: main
completed: 2026-06-12
verification:
  - bash -n scripts/verify_public_launch_urls.sh
  - mix test test/docs_contract/launch_execution_claims_test.exs test/guardrails/required_checks_contract_test.exs
  - mix docs.contract
  - mix rendro.livebook.check
  - mix rendro.comparison.check
  - mix hex.build
---

# Quick Task Summary

Automated the main-branch HexDocs refresh path so launch proof docs no longer depend on local Hex auth.

## Outcome

- Added `.github/workflows/hexdocs.yml` with PR/push readiness checks and docs-only publishing on `main` pushes.
- Added `scripts/verify_public_launch_urls.sh` for GitHub raw and HexDocs public proof checks, with HexDocs propagation retries.
- Extended launch docs-contract coverage so the workflow stays docs-only, secret-backed, no-approval, and wired to public URL verification.

## Commit

- `db2f7d3` - `ci: automate HexDocs publish on main`

## Verification

- `bash -n scripts/verify_public_launch_urls.sh` passed.
- `mix test test/docs_contract/launch_execution_claims_test.exs test/guardrails/required_checks_contract_test.exs` passed: 24 tests, 0 failures.
- `mix docs.contract` passed all 20 lanes.
- `mix rendro.livebook.check` passed.
- `mix rendro.comparison.check` passed.
- `mix hex.build` passed.

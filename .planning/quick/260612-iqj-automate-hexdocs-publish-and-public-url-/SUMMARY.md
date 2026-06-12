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
  - actionlint .github/workflows/ci.yml .github/workflows/hexdocs.yml .github/workflows/release.yml
  - mix test test/scripts/release_preflight_proof_test.exs test/mix/tasks/release_preflight_test.exs test/guardrails/required_checks_contract_test.exs
  - GitHub Actions HexDocs run 27432226735
  - GitHub Actions HexDocs run 27433121994
  - GitHub Actions HexDocs run 27433698454
---

# Quick Task Summary

Automated the main-branch HexDocs refresh path so launch proof docs no longer depend on local Hex auth.

## Outcome

- Added `.github/workflows/hexdocs.yml` with PR/push readiness checks and docs-only publishing on `main` pushes.
- Added `scripts/verify_public_launch_urls.sh` for GitHub raw and HexDocs public proof checks, with HexDocs propagation retries.
- Extended launch docs-contract coverage so the workflow stays docs-only, secret-backed, no-approval, and wired to public URL verification.
- Pinned `actions/checkout` to the `v6.0.3` commit SHA across HexDocs, CI, and release workflows after GitHub Actions warned that the previous `v4.2.2` pin used the deprecated Node 20 runtime.
- Pinned `actions/setup-python` to the `v6.2.0` commit SHA in CI live-proof jobs after GitHub Actions warned that `v5` is on the Node 20 deprecation path.
- Removed a nested `mix run` subprocess from the release-preflight proof test after CI exposed it as timeout-prone inside the main `mix ci` test job.
- Made release preflight proof output stream through CI logs and bounded the `release-proof` job with a 45-minute timeout.
- Fixed the anonymous CI release-proof path so `mix hex.publish --dry-run --yes` reaches Hex's local-check/authentication boundary noninteractively instead of waiting for credentials forever. The release-tag workflow still uses the authenticated dry-run path when `HEX_API_KEY` is present.

## Commits

- `db2f7d3` - `ci: automate HexDocs publish on main`
- Additional main-branch commits update the checkout action pin to `v6.0.3`.
- Additional main-branch commit stabilizes the release-preflight proof test under CI.
- Additional main-branch commits make release-proof observable and noninteractive under anonymous CI.

## Verification

- `bash -n scripts/verify_public_launch_urls.sh` passed.
- `mix test test/docs_contract/launch_execution_claims_test.exs test/guardrails/required_checks_contract_test.exs` passed: 24 tests, 0 failures.
- `mix docs.contract` passed all 20 lanes.
- `mix rendro.livebook.check` passed.
- `mix rendro.comparison.check` passed.
- `mix hex.build` passed.
- `actionlint .github/workflows/ci.yml .github/workflows/hexdocs.yml .github/workflows/release.yml` passed.
- `mix test test/scripts/release_preflight_proof_test.exs test/mix/tasks/release_preflight_test.exs test/guardrails/required_checks_contract_test.exs` passed: 29 tests, 0 failures.
- GitHub Actions HexDocs run `27432226735` passed end to end: readiness checks, `mix hex.publish docs --yes`, and public launch URL verification.
- GitHub Actions HexDocs run `27433121994` passed end to end after all workflow checkout pins moved to `v6.0.3`.
- GitHub Actions HexDocs run `27433698454` passed end to end after the release-preflight CI test timeout fix.

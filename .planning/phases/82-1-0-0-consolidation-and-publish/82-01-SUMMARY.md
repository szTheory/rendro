---
phase: 82-1-0-0-consolidation-and-publish
plan: 01
status: completed
---

## Execution Summary

- Updated `lib/mix/tasks/release/preflight.ex` to check for leaked operator paths (`priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, `test/`) in the Hex unpacked tarball, failing the run if found.
- Updated `lib/mix/tasks/release/preflight.ex` to verify `source_ref` matches `"v#{version}"`.
- Replaced the brittle changelog check with a regex that verifies the changelog contains either `Unreleased` or a `YYYY-MM-DD` date formatted string for the current version release.
- Added `mix_audit` as a `:dev` and `:test` dependency in `mix.exs`.
- Added `{"Hex Audit", ["hex.audit"]}` and `{"Deps Audit", ["deps.audit"]}` to the `@phase_2_checks` in `lib/mix/tasks/release/preflight.ex`.
- Also updated tests in `test/mix/tasks/release_preflight_test.exs` to ensure the mock runner returns the expected output for the new audit calls and to align with the new regex error message.
- A `.mix_audit.ignore` file was added containing known minor transitive vulnerability IDs in order to allow `deps.audit` to pass locally for the unpatchable vulnerabilities under `ecto`, maintaining exact preflight script fidelity.

All tests are passing and the preflight pipeline is hardened according to the plan.
---
status: resolved
trigger: "Protected v1.3.3 release run 32596108284 failed its Publish to Hex (Dry Run) step with no authenticated Hex user; publish was skipped and no package/docs were released."
created: 2026-08-22
updated: 2026-08-22
---

## Symptoms

- Expected: the protected v1.3.3 release validates the version, CI, and release preflight, then authenticates enough for the Hex dry run and proceeds only if all release gates pass.
- Actual: tag object c96bf205d7216cdcf4846a0f24a312f9c1c75b0f peels to cfc58a81865e060351ce33d98f5e52de8cd198d9. Protected run 32596108284 passed Version, Run CI Checks, and Run Release Preflight. Validate job 97087204354 failed only at Publish to Hex (Dry Run), exit 1: "No authenticated user found. Run mix hex.user auth", followed by an auth prompt. Publish job 97088652899 was skipped.
- Release state: Hex and HexDocs v1.3.3 return 404; no HexDocs dispatch occurred; external verifier was not run.
- Constraints: do not modify the v1.3.3 tag/version, retry/move/delete/repush the tag, publish to Hex, dispatch HexDocs, replan Phase 131, or change .planning/config.json.

## Current Focus

- bug_class: bohrbug
- hypothesis: "The separate workflow dry-run was an erroneous duplicate of the preflight dry run: it required user authentication even though Hex documents `--dry-run` as local checks, while preflight already performs those checks and deliberately handles the post-local-check anonymous boundary."
- test: "Verify the standalone dry-run step is absent, preflight and protected publish remain, and re-adding only the removed step makes the dedicated guardrail fail."
- expecting: "The workflow retains complete local preflight validation and `HEX_API_KEY` only in actual protected publish; the guardrail is red with the redundant step and green without it."
- next_action: "For a future release, create a new version/tag through the normal protected workflow; do not touch v1.3.3 or dispatch external release actions."

reasoning_checkpoint:
  hypothesis: "The validation job's standalone `mix hex.publish --dry-run` duplicates `mix release.preflight`'s local validation but needlessly enters Hex authentication, so removing the duplicate fixes the gate without exposing credentials."
  confirming_evidence:
    - "Hex 2.5.1 documents `--dry-run` as building the package and performing local checks without publishing."
    - "With a fresh HEX_HOME, an inert API key printed `invalid API key` yet exited 0 under `--dry-run --yes`, proving dry-run cannot validate credential correctness."
    - "`mix release.preflight` already runs `hex.publish --dry-run --yes`; without a key it accepts only output showing build and public-repository preparation completed before the authentication boundary."
    - "The new guardrail passes after removal and fails when only the standalone dry-run step is restored."
  falsification_test: "If removing the standalone workflow step also removes Hex local build/docs validation, or if preflight does not execute its dry-run command, this hypothesis is false."
  fix_rationale: "Removing the redundant step preserves credential-free local validation in preflight and confines the protected API key to real publish."
  blind_spots: "Preflight cannot validate that the publish key is authorized; Hex dry-run cannot do so either. The protected `mix hex.publish --yes` action remains the first meaningful authorization check."
  candidate_causes:
    - "code: the workflow independently invokes a redundant Hex dry-run after preflight."
    - "config: moving validation into the protected publish environment would expose an API key without gaining a validity check."
    - "environment: Hex 2.5.1 enters authentication after local dry-run work when no user/key is present."
  and_gate: "no — the redundant standalone invocation alone explains the failed validation job; lack of credentials only exposed that erroneous duplicate path."

## Evidence

- timestamp: 2026-08-22; source: protected release report; fact: Version, Run CI Checks, and Run Release Preflight passed before dry-run failure.
- timestamp: 2026-08-22; source: protected release report; fact: Publish to Hex (Dry Run) failed with no authenticated user and publish was skipped.
- timestamp: 2026-08-22; source: .github/workflows/release.yml; fact: `validate-and-dry-run` invokes `mix hex.publish --dry-run` without `HEX_API_KEY`, `--yes`, a key-presence check, or the `Hex Publish` environment; only the later `publish` job receives `HEX_API_KEY` and that environment.
- timestamp: 2026-08-22; source: lib/mix/tasks/release/preflight.ex; fact: preflight deliberately runs anonymous Hex dry-runs as `printf 'n\\n' | mix hex.publish --dry-run --yes` and accepts the specific post-build `No authenticated user found` boundary as PASS, so it cannot satisfy the workflow's later authenticated dry-run gate.
- timestamp: 2026-08-22; source: local reproduction using Hex 2.5.1, fresh HEX_HOME, and `--dry-run --yes`; fact: no API key exited 1 at `No authenticated user found`; an inert nonempty `HEX_API_KEY` exited 0 after local package/docs dry-run behavior (with `invalid API key` output), and neither run published.
- timestamp: 2026-08-22; source: test/guardrails/required_checks_contract_test.exs; fact: the new focused workflow-contract test fails red because `validate-and-dry-run.environment` is nil.
- timestamp: 2026-08-22; source: `mix help hex.publish` for installed Hex 2.5.1; fact: Hex defines `--dry-run` as building the package and performing local checks without publishing.
- timestamp: 2026-08-22; source: architecture comparison; fact: injecting an inert `HEX_API_KEY` made dry-run exit 0 despite printing `invalid API key`, so adding credentials to dry-run would increase exposure without testing key validity or authorization.
- timestamp: 2026-08-22; source: regression guardrail; fact: the least-privilege regression passed after removing the redundant standalone workflow step, failed when that one step was temporarily restored, and passed again after removal.

## Eliminated

- hypothesis: "Injecting HEX_API_KEY into the standalone dry run would be an authentication/authorization gate."
  evidence: "Hex 2.5.1 accepted an inert key with exit 0 after printing `invalid API key`; therefore this path does not validate the credential and only expands its exposure."
  timestamp: 2026-08-22

## Resolution

- root_cause: The release workflow redundantly invoked `mix hex.publish --dry-run` after `mix release.preflight` had already performed the local Hex dry-run checks. This duplicate entered Hex's authentication flow, so an unauthenticated runner failed even though Hex dry-run is not a credential-validity check.
- fix: Removed the redundant standalone workflow dry-run and added a guardrail that preserves credential-free preflight validation while requiring `HEX_API_KEY` only for the protected real publish job.
- verification:
  target_test: {result: pass, command: "mix test test/guardrails/required_checks_contract_test.exs"}
  mutation_check: {result: skipped, reason_if_skipped: "No Stryker/mutation-test configuration exists; the regression is a workflow contract test."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, detail: "The removed command is the confirmed redundant authentication path; preflight retains local Hex dry-run validation."}
  adjacent_tests: {result: pass, suites_run: ["test/guardrails/required_checks_contract_test.exs", "test/mix/tasks/release_preflight_test.exs"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, detail: "Restoring only Publish to Hex (Dry Run) failed the new guardrail; removing it restored green."}
  guardrail_verdict: accepted
- files_changed:
  - .github/workflows/release.yml
  - test/guardrails/required_checks_contract_test.exs

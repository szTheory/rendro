---
phase: 92
slug: docs-claims-release-hygiene
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 92 - Validation Strategy

Per-phase validation contract for docs, claims, and release hygiene.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5 |
| Config file | `mix.exs` |
| Quick run command | `mix test test/docs_contract/page_primitive_claims_test.exs test/docs_contract/adoption_claims_test.exs test/docs_contract/script_support_claims_test.exs test/docs_contract/pdfjs_advisory_claims_test.exs test/docs_contract/launch_artifacts_claims_test.exs test/guardrails/required_checks_contract_test.exs` |
| Docs contract command | `mix run scripts/verify_docs.exs` |
| Package/docs command | `mix hex.build --unpack /tmp/rendro_hex_phase92 && mix docs` |
| Full gate command | `mix ci` |

## Sampling Rate

- After docs/support-matrix edits: run page primitive, adoption, script support, and PDF.js docs-contract tests.
- After package/workflow edits: run launch artifact and required-check guardrail tests.
- Before phase close: run `mix run scripts/verify_docs.exs`, `mix hex.build --unpack`, `mix docs`, and `mix ci`.
- Max feedback latency: one task.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 92-01-01 | 01 | 1 | DOC-01, DOC-03 | Claim drift | Public PAGE/context docs and support matrix name only shipped capabilities and explicit deferrals | contract | `mix test test/docs_contract/page_primitive_claims_test.exs test/docs_contract/script_support_claims_test.exs test/docs_contract/pdfjs_advisory_claims_test.exs` | yes | pending |
| 92-01-02 | 01 | 1 | DOC-03 | False shaping milestone | `ADOPTION.md`, README, comparison, API stability, support matrix, and `.planning/ROADMAP.md` keep global text shaping demand-gated rather than v2.7-promised | contract | `mix test test/docs_contract/adoption_claims_test.exs test/docs_contract/script_support_claims_test.exs` | yes | pending |
| 92-02-01 | 02 | 1 | DOC-02 | Broken HexDocs/package links and overbroad token permissions | Public linked docs are packaged/docs extras where appropriate, CI/release use read-only token permissions, and changelog records the posture change | contract/package | `mix test test/docs_contract/launch_artifacts_claims_test.exs test/guardrails/required_checks_contract_test.exs && mix hex.build --unpack /tmp/rendro_hex_phase92 && mix docs` | yes | pending |
| 92-03-01 | 03 | 1 | DOC-01, DOC-02, DOC-03 | Integration drift | Full docs-contract lane and project CI pass after all public claims and release hygiene changes | regression | `mix run scripts/verify_docs.exs && mix ci` | yes | pending |

## Wave 0 Requirements

Existing docs-contract, support-matrix, Hex package, and workflow guardrail infrastructure covers all Phase 92 requirements.

## Manual-Only Verifications

All Phase 92 deliverables have automated verification. Manual review should focus on copy clarity and avoiding unsupported public claims.

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-13

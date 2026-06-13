---
phase: 90
slug: duplex-running-content
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 90 - Validation Strategy

Per-phase validation contract for duplex running content.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5 |
| Config file | `mix.exs` |
| Quick run command | `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` |
| Full suite command | `mix test` |
| Estimated runtime | Focused: under 30 seconds; full suite: project baseline |

## Sampling Rate

- After every task commit: run the focused command for changed seams.
- After the plan wave: run focused tests plus public API contract tests.
- Before phase close: full `mix test` and `mix format --check-formatted` must pass.
- Max feedback latency: one task.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 90-01-01 | 01 | 1 | DUP-03 | Invalid options | Malformed `only_on` and `page_numbering` raise before render | unit | `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs` | yes | passed |
| 90-01-02 | 01 | 1 | DUP-01, DUP-02 | Wrong parity | Running regions filter on physical odd/even pages and compose with section tokens | integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | yes | passed |
| 90-01-03 | 01 | 1 | DUP-01, DUP-02, DUP-03 | Contract drift | Public API manifest, focused tests, full suite, and formatting are green | contract/regression | `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs && mix test && mix format --check-formatted` | yes | passed |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All Phase 90 behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-13

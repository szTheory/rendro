---
phase: 53
slug: delivery-threading-and-truthful-support-contract
status: passed
nyquist_compliant: true
wave_0_complete: true
source: planning
created: 2026-05-06
updated: 2026-05-06
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for protected-artifact transport/storage truthfulness and synchronized `protection` support-boundary claims.

Phase 53 has two closure lanes and keeps them separate:

1. The **runtime seam lane** proves protected artifacts remain truthful across first-party storage reload and existing delivery composition.
2. The **support-contract lane** proves `priv/support_matrix.json`, guides, and Mailglass docs publish the same narrow `protection` story.

Per `53-CONTEXT.md`, these lanes close Phase 53 without widening Oban, Mailglass, or `Rendro.Storage` contracts.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract script |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/storage/local_test.exs test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs` |
| **Full suite command** | `mix test test/rendro/storage/local_test.exs test/rendro/end_to_end_pipeline_test.exs test/rendro/adapters/oban/render_worker_test.exs test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs && mix docs.contract` |
| **Estimated runtime** | ~15-45 seconds |

## Sampling Rate

- After each `53-01` task: run the narrowest affected storage/runtime command.
- After each `53-02` task: run the narrowest affected docs-contract command.
- Before phase handoff: run the full suite command once end-to-end.
- Max automated feedback latency: 45 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | ADAPT-03 | T-53-01, T-53-02 | First-party local storage preserves `metadata.deterministic` and `metadata.protection` without storing passwords. | unit | `mix test test/rendro/storage/local_test.exs` | ✅ | ✅ green |
| 53-01-02 | 01 | 1 | ADAPT-03 | T-53-03, T-53-04 | Protected artifacts still compose through render-only async flow and Mailglass transport-only delivery. | integration | `mix test test/rendro/storage/local_test.exs test/rendro/end_to_end_pipeline_test.exs test/rendro/adapters/oban/render_worker_test.exs` | ✅ | ✅ green |
| 53-02-01 | 02 | 2 | TRUST-01 | T-53-05, T-53-06 | `priv/support_matrix.json` exposes a compact `protection.boundaries` subsection without widening the family-first matrix. | docs-contract | `mix test test/docs_contract/protection_claims_test.exs` | ✅ | ✅ green |
| 53-02-02 | 02 | 2 | TRUST-01, TRUST-02 | T-53-06, T-53-07, T-53-08 | Guides and Mailglass docs mirror the matrix and keep async/password boundaries explicit. | docs-contract | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs && mix docs.contract` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] Every planned task has an explicit automated verification command.
- [x] The runtime seam lane and the support-contract lane are separated.
- [x] The canonical docs gate remains `mix docs.contract`.
- [x] Validation commands cover both the new storage seam and the existing docs-contract seams.
- [x] `test/rendro/storage/local_test.exs` was created to lock first-party manifest/sidecar behavior.
- [x] `53-01` runtime slice proved delete-path cleanup for the first-party sidecar.
- [x] `53-02` docs slice added `protection.boundaries` assertions and wording locks.

## Automated Proof Lanes

### 1. Runtime seam lane

Purpose:
- Prove that protected artifacts survive first-party storage reload truthfully and still compose with existing transport seams.

Automation:
- `mix test test/rendro/storage/local_test.exs`
- `mix test test/rendro/storage/local_test.exs test/rendro/end_to_end_pipeline_test.exs test/rendro/adapters/oban/render_worker_test.exs`

Important boundary:
- `Rendro.Adapters.Oban.RenderWorker` remains render-only.
- Passwords must not appear in worker args, sidecar files, or delivery adapter APIs.
- `Rendro.Storage` remains unchanged; only Rendro-owned example semantics are tightened.

Expected result:
- Protected-artifact metadata round-trips through `Rendro.Storage.Local`.
- First-party delete removes the adjacent sidecar together with the PDF.
- Protected artifacts can still be delivered through `attach_artifact/3` after application-owned protection.

### 2. Support-contract lane

Purpose:
- Prove the matrix, guides, and Mailglass docs all publish the same narrow `protection` contract.

Automation:
- `mix test test/docs_contract/protection_claims_test.exs`
- `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs`
- `mix docs.contract`

Important boundary:
- The contract must distinguish password-to-open support from advisory permissions.
- The contract must explicitly keep password material out of persisted async args and delivery/storage seams.
- No viewer-promotion or release-tail claims belong in this phase.

Expected result:
- `protection.boundaries` is present and locked.
- Guides and Mailglass docs use the same artifact-first protected-delivery story.
- Docs-contract tests fail on wording drift or scope widening.

## Validation Sign-Off

- [x] All planned tasks have automated verification coverage
- [x] Sampling continuity is preserved across Plans 01 and 02
- [x] Runtime and docs-contract proof lanes are explicitly separated
- [x] No watch-mode flags
- [x] `mix docs.contract` remains the canonical docs gate
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 53 validation contract prepared on 2026-05-06 during plan-phase revision.

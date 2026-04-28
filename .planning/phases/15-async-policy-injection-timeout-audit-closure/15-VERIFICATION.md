---
phase: 15-async-policy-injection-timeout-audit-closure
verified: 2026-04-28T20:10:03Z
status: passed
requirements:
  - ADPT-04
  - ADPT-05
  - OBS-04
---

# Phase 15: Async Policy Injection + Timeout Audit Closure Verification

**Phase Goal:** Restore truthful bounded async rendering and timeout audit visibility by hardening the Oban worker boundary, closing the top-level timeout lifecycle, and syncing the public integration contract to the live behavior.

## Goal Achievement

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The Oban worker now accepts only the documented async policy surface and injects only missing `max_pages`, `max_bytes`, and `timeout` bounds into the document. | ✓ VERIFIED | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/policy_test.exs` |
| 2 | Timeout renders now emit a terminal top-level `[:rendro, :render, :stop]` event with stable failed-render metadata instead of leaving the render lifecycle unbalanced. | ✓ VERIFIED | `mix test test/rendro/telemetry_test.exs` |
| 3 | Threadline records timeout failures under the existing `:render_failed` action and preserves timeout subtype metadata in the nested `:error` payload. | ✓ VERIFIED | `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` |
| 4 | The integrations guide now documents the narrow Oban worker contract and the timeout audit closure truthfully. | ✓ VERIFIED | `guides/integrations.md`; `mix test test/docs_contract/integrations_claims_test.exs` |

## Requirement: ADPT-04

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/policy_test.exs`
**Supporting evidence:** `lib/rendro/adapters/oban/render_worker.ex`, `guides/integrations.md`

The worker boundary validates required job args and the nested `"policies"` map, rejects unknown policy keys and invalid values with typed tuples, and injects only missing `max_pages`, `max_bytes`, and `timeout` bounds into `doc.options[:policies]` before render. Worker-path tests cover all three supported bounds plus fill-missing precedence, closing the async bounded-render seam that Phase 08 and Phase 14 left partial.

## Requirement: ADPT-05

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs`
**Supporting evidence:** `guides/integrations.md`, `lib/rendro/adapters/threadline.ex`

Phase 15 closes the remaining timeout truth gap inside the `threadline` recipe surface. The guide and docs-contract suite now prove timeout failures are visible through the existing `:render_failed` audit family with nested timeout subtype metadata, instead of documenting timeout audit absence as a known limitation.

## Requirement: OBS-04

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/telemetry_test.exs test/rendro/adapters/threadline_test.exs`
**Supporting evidence:** `test/docs_contract/integrations_claims_test.exs`, `lib/rendro/pipeline.ex`

Operators can now enforce max pages, max output bytes, and render timeouts across both the synchronous render path and the documented async worker path. Timeout failures also leave an auditable top-level render stop and Threadline `:render_failed` record, so the observability half of the requirement is no longer partial.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Worker-path policy injection and typed worker-boundary failures | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/policy_test.exs` | Exit `0`; all worker boundary and policy enforcement assertions pass | ✓ PASS |
| Timeout render lifecycle closure | `mix test test/rendro/telemetry_test.exs` | Exit `0`; timeout renders emit a top-level `:start` and terminal `:stop` with timeout metadata | ✓ PASS |
| Timeout audit forwarding and docs-contract truth | `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` | Exit `0`; timeout failures record `:render_failed` with nested timeout metadata and the guide contract stays aligned | ✓ PASS |

## Requirements Coverage

| Requirement | Status | Primary proof |
|-------------|--------|---------------|
| ADPT-04 | Done | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/policy_test.exs` |
| ADPT-05 | Done | `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` |
| OBS-04 | Done | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/telemetry_test.exs test/rendro/adapters/threadline_test.exs` |

## Required Artifacts

| Artifact | Role |
|----------|------|
| `15-VERIFICATION.md` | Canonical Phase 15 requirement verdicts and proof mapping |
| `15-VALIDATION.md` | Nyquist validation contract and executed command record |
| `test/rendro/adapters/oban/render_worker_test.exs` | Worker-path bounded-async proof |
| `test/rendro/telemetry_test.exs` | Timeout top-level lifecycle proof |
| `test/rendro/adapters/threadline_test.exs` | Timeout audit forwarding proof |
| `test/docs_contract/integrations_claims_test.exs` | Public-contract truth enforcement for Oban and Threadline integration claims |
| `guides/integrations.md` | Operator-facing async and audit contract |

---

_Verified: 2026-04-28T20:10:03Z_
_Verifier: Codex_

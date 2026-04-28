---
phase: 08-bounded-async-timeout-telemetry
verified: 2026-04-28T00:00:00Z
status: reconstructed
requirements:
  - ADPT-04
  - ADPT-05
  - OBS-02
  - OBS-04
---

# Phase 08: Bounded Async Timeout Telemetry Verification

**Phase Goal:** Re-verify the bounded-async and timeout-telemetry slice against current executable proof, using current policy, Threadline, and docs-contract suites to distinguish what still works from what the codebase no longer proves at the Oban worker and timeout-exception boundaries.

## Goal Achievement

- Current executable proof still closes correlated render metadata for successful and failed renders and closes policy enforcement in the core render path.
- The original Phase 08 promise that the Oban worker injects policy bounds and that timeout exceptions reach Threadline is not fully supported by the current codebase: the dedicated worker test file is gone, `Rendro.Adapters.Oban.RenderWorker` no longer merges job-arg policies, and the docs-contract suite now explicitly proves Threadline does not observe timeout failures.
- This backfill therefore records a mixed result rather than replaying the original summary as if the later state still matched it.

## Requirement: ADPT-04

**Status:** Partial
**Primary proof:** `mix test test/rendro/policy_test.exs`
**Supporting evidence:** `lib/rendro/adapters/oban/render_worker.ex`
**Why this does not fully close the requirement:** The current policy suite proves bounded rendering remains available in the core render path, but the live Oban worker no longer injects `max_pages`, `max_bytes`, or `timeout` from job args and there is no current committed worker-path test proving bounded async behavior end to end.

## Requirement: ADPT-05

**Status:** Partial
**Primary proof:** `mix test test/docs_contract/integrations_claims_test.exs`
**Supporting evidence:** `test/rendro/adapters/threadline_test.exs`, `lib/rendro/adapters/threadline.ex`
**Why this does not fully close the requirement:** The current docs-contract suite proves the adapter recipe docs stay truthful about optional guards and the present Threadline timeout limitation, but this phase alone does not close the broader `threadline`/`mailglass`/`accrue` recipe requirement and should not claim that later recipe-traceability work was already complete here.

## Requirement: OBS-02

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/threadline_test.exs`
**Supporting evidence:** `lib/rendro/adapters/threadline.ex`
**Why this closes the requirement:** The current Threadline integration suite proves render lifecycle calls still carry correlated `render_id`, `status`, `page_count`, `byte_size`, and `duration` metadata for both successful and failed renders, which is the required metrics-correlation surface.

## Requirement: OBS-04

**Status:** Partial
**Primary proof:** `mix test test/rendro/policy_test.exs`
**Supporting evidence:** `test/docs_contract/integrations_claims_test.exs`, `lib/rendro/pipeline.ex`, `lib/rendro/adapters/oban/render_worker.ex`
**Why this does not fully close the requirement:** The current policy suite proves `max_pages`, `max_bytes`, and `timeout` are enforced when policies are present on the document, but the timeout-exception audit path is not currently observed by Threadline and the Oban worker no longer proves bound injection from async job args.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Render policies still reject oversize page counts, byte sizes, and zero-timeout renders at the core render boundary. | ✓ VERIFIED | `test/rendro/policy_test.exs` asserts `:max_pages_exceeded`, `:max_bytes_exceeded`, and `:timeout` from current `Rendro.render/1` calls. |
| 2 | Threadline still receives correlated metadata for successful and non-timeout failed renders. | ✓ VERIFIED | `test/rendro/adapters/threadline_test.exs` asserts `render_id`, `status`, `page_count`, `byte_size`, and `duration` on `:render_succeeded` and `:render_failed`. |
| 3 | The current docs contract explicitly says timeout failures are not yet forwarded into Threadline audit calls. | ✓ VERIFIED | `test/docs_contract/integrations_claims_test.exs` asserts a timeout render returns `{:error, %Rendro.Error{reason: :timeout}}` and leaves `Mocks.threadline_calls()` empty. |
| 4 | The live Oban worker does not currently merge `max_pages`, `max_bytes`, or `timeout` from job args into the document policy. | ✓ VERIFIED | `lib/rendro/adapters/oban/render_worker.ex` builds the document and calls `Rendro.render(doc, output: path)` directly, with no policy-injection step. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `08-VERIFICATION.md` | `test/rendro/adapters/threadline_test.exs` | metrics-correlation proof for `OBS-02` | WIRED | The current suite verifies the correlated metadata surface for success and failure. |
| `08-VERIFICATION.md` | `test/docs_contract/integrations_claims_test.exs` | truthful timeout-limitation proof | WIRED | The docs-contract test prevents us from claiming timeout audit coverage that no longer exists. |
| `08-VERIFICATION.md` | `lib/rendro/adapters/oban/render_worker.ex` | async bound-injection inspection | WIRED | The worker implementation itself now shows the missing policy-merge step that keeps `ADPT-04` and `OBS-04` partial. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core policy guards still fail oversize/time-bound renders | `mix test test/rendro/policy_test.exs` | Exit `0`; all three policy guards pass | ✓ PASS |
| Correlated Threadline metadata still flows on non-timeout paths | `mix test test/rendro/adapters/threadline_test.exs` | Exit `0`; metadata assertions pass | ✓ PASS |
| Timeout audit gap remains truthfully documented | `mix test test/docs_contract/integrations_claims_test.exs` | Exit `0`; timeout renders produce no Threadline audit call | ✓ PASS |

## Requirements Coverage

| Requirement | Status | Primary proof |
|-------------|--------|---------------|
| ADPT-04 | Partial | `mix test test/rendro/policy_test.exs` |
| ADPT-05 | Partial | `mix test test/docs_contract/integrations_claims_test.exs` |
| OBS-02 | Done | `mix test test/rendro/adapters/threadline_test.exs` |
| OBS-04 | Partial | `mix test test/rendro/policy_test.exs` |

## Required Artifacts

| Artifact | Role |
|----------|------|
| `08-VERIFICATION.md` | Canonical Phase 08 requirement verdicts and proof mapping |
| `08-VALIDATION.md` | Nyquist validation contract for this artifact backfill |
| `08-01-SUMMARY.md` | Machine-readable execution summary aligned to the verification verdicts |
| `test/rendro/policy_test.exs` | Current policy-bound enforcement proof |
| `test/rendro/adapters/threadline_test.exs` | Current correlated-metadata proof |
| `test/docs_contract/integrations_claims_test.exs` | Truthful timeout-limitation and optional-adapter contract proof |
| `lib/rendro/adapters/oban/render_worker.ex` | Current optional async worker implementation under review |


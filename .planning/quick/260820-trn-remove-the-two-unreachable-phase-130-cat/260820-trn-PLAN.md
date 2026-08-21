---
type: quick-task
quick_id: 260820-trn
slug: remove-the-two-unreachable-phase-130-cat
title: Remove the unreachable Phase 130 catalog review payload and reconciliation fallback clauses
repo: /Users/jon/projects/rendro
created: 2026-08-20
autonomous: true
scope:
  - Preserve the committed removal of the two unreachable bind_local_path/3 fallbacks
  - Remove only the newly exposed unreachable catch-all from CatalogReviewPayload.classify/2
  - Remove only the newly exposed unreachable false and catch-all clauses from CatalogReviewReconciliation.reconcile/4
  - Retain typed error propagation and both public invalid-input function heads
  - Preserve catalog review payload and reconciliation behavior and focused contract coverage
files:
  - dev/rendro/catalog_review_payload.ex
  - dev/rendro/catalog_review_reconciliation.ex
verification:
  - mix format --check-formatted dev/rendro/catalog_review_payload.ex dev/rendro/catalog_review_reconciliation.ex test/rendro/catalog_review_payload_contract_test.exs
  - mix test test/rendro/catalog_review_payload_contract_test.exs
  - mix dialyzer
  - mix ci.fast
---

# Quick Task Plan

## Objective

Remove the proven unreachable fallback clauses in the Phase 130 catalog review payload and reconciliation paths so `mix dialyzer` and `mix ci.fast` pass without changing reachable validation, error propagation, or public invalid-input behavior.

## Recorded Deviation

The first execution pass correctly removed the two unreachable `bind_local_path/3` fallbacks and committed that narrow change as `149b483`. After that warning was cleared, Dialyzer exposed the same class of adjacent findings: the catch-all at `dev/rendro/catalog_review_payload.ex:44`, plus the `false` and catch-all clauses at `dev/rendro/catalog_review_reconciliation.ex:30-31`. This revision expands the existing quick task only to those newly visible clauses; it does not replace or reinterpret the completed first pass.

## Constraints

- Preserve the committed `bind_local_path/3` result: its `else` block contains only `false -> {:error, :local_binding_mismatch}`.
- In `CatalogReviewPayload.classify/2`, remove only the unreachable catch-all after the reachable `true` quality-bearing result and `{:error, reason}` propagation.
- In `CatalogReviewReconciliation.reconcile/4`, remove only the unreachable `false` and catch-all clauses after the reachable `{:error, _reason} = error` propagation.
- Retain both modules' public fallback function heads that return their documented invalid-input errors for arguments outside the guarded primary heads.
- Do not change payload or reconciliation inputs, outputs, typed error propagation, PNG parsing, hashes, identity checks, or any other Phase 130 behavior.
- Preserve the focused contract test unchanged; any test failure is a blocker to diagnose and report, not permission to add behavior or broaden scope.
- Do not absorb or revert concurrent work. Inspect and stage only the scoped source change; the quick workflow may manage its own plan, summary, and state artifacts separately.

## Execution

### Task 1: Remove the adjacent unreachable fallbacks and prove the catalog contracts remain intact

Edit `dev/rendro/catalog_review_payload.ex` so the primary `classify/2` `with` expression retains only its reachable `true -> {:error, :quality_bearing_input}` and `{:error, reason} -> {:error, reason}` branches. Delete only its final catch-all; preserve the separate public `classify/2` fallback head that returns `{:error, :invalid_candidate_payload}` for invalid top-level inputs.

Edit the primary `CatalogReviewReconciliation.reconcile/4` `with` expression so its `else` block retains only `{:error, _reason} = error -> error`. Delete only the now-proven unreachable `false` and catch-all branches at the reported lines. Preserve the separate public `reconcile/4` fallback head and the already-corrected `bind_local_path/3` branch exactly as committed.

Inspect `git diff -- dev/rendro/catalog_review_payload.ex dev/rendro/catalog_review_reconciliation.ex test/rendro/catalog_review_payload_contract_test.exs` and confirm the new source diff deletes exactly these three adjacent clauses. The focused three-test contract suite must remain unchanged; the removals are type-reachability cleanup and add no new behavior. Then run:

```bash
mix format --check-formatted dev/rendro/catalog_review_payload.ex dev/rendro/catalog_review_reconciliation.ex test/rendro/catalog_review_payload_contract_test.exs
mix test test/rendro/catalog_review_payload_contract_test.exs
mix dialyzer
mix ci.fast
```

After all four commands pass, stage only the two scoped source modules that changed, inspect the staged diff again, and create one atomic follow-up code commit such as `fix(130): remove adjacent unreachable catalog fallbacks`. Leave the focused tests and all unrelated tracked and untracked work untouched. If a `mix ci.fast` step fails for an unrelated environmental reason after formatting, focused tests, and Dialyzer pass, record that exact blocker rather than broadening this task.

## Done When

- The original `bind_local_path/3` cleanup remains intact, including `false -> {:error, :local_binding_mismatch}`.
- The new diff removes exactly the payload catch-all and the reconciliation `false` plus catch-all reported by Dialyzer.
- Typed error propagation and both public invalid-input function heads remain intact.
- Both scoped source modules and the focused contract test pass `mix format --check-formatted`.
- The three tests in `test/rendro/catalog_review_payload_contract_test.exs` pass unchanged.
- `mix dialyzer` passes without the reported unreachable-clause warnings.
- `mix ci.fast` passes, or any unrelated environmental failure is recorded precisely after the focused gates succeed.
- The follow-up source cleanup is recorded in one atomic commit without staging unrelated work.

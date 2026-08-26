---
phase: 132-quality-baseline-triage
reviewed: 2026-08-26T18:38:55Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - mix.exs
  - test/quality/baseline_ledger_contract_test.exs
  - test/test_helper.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 132: Code Review Report

**Reviewed:** 2026-08-26T18:38:55Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The focused `mix quality.baseline` command passes (9 tests), and formatting and Credo pass. However, the new ledger contract can be satisfied by Markdown outside a classification record, does not prove that findings actually resolve to evidence, and is excluded from every normal CI alias. Those gaps make the intended durable baseline guard ineffective against several realistic regressions.

## Warnings

### WR-01: The baseline contract is not part of any normal CI gate

**File:** `mix.exs:87-89`, `test/test_helper.exs:9-17`
**Classification:** WARNING
**Issue:** The only invocation of the ledger contract is the opt-in `mix quality.baseline` alias, while `:quality_ledger_contract` is excluded from the default suite and neither `ci.fast` nor `ci.proofs` invokes that alias. A broken or incomplete baseline/ledger/schema can therefore merge and ship while all normal CI checks remain green.
**Fix:** Add `quality.baseline` to the appropriate deterministic CI alias (for example, `ci.fast`) or invoke the focused tagged test in the CI workflow that owns baseline integrity. Keep the tag exclusion if the separate lane is desired, but make that lane mandatory in CI.

### WR-02: Any stray `**Signal:**` Markdown can satisfy signal-classification coverage

**File:** `test/quality/baseline_ledger_contract_test.exs:49-52`, `219-237`
**Classification:** WARNING
**Issue:** `classified_signal_ids/1` scans the entire ledger for a bullet-shaped `**Signal:**` string without associating it with a `QL-*` finding or `NS-*` non-action record. If a real record loses its signal classification, adding the same bullet in a heading, prose, or unrelated section still makes the exact-set and uniqueness assertions pass. The test consequently does not establish that every signal has a durable classification and disposition.
**Fix:** Parse record blocks first (for example, `#### QL-...` and `### NS-...` through the next peer heading), collect signals only from those blocks, and assert each referenced signal is in exactly one block with the required disposition fields.

### WR-03: Findings may name no resolvable evidence and still pass the contract

**File:** `test/quality/baseline_ledger_contract_test.exs:239-270`
**Classification:** WARNING
**Issue:** The `for evidence_id <- Regex.scan(...)` loop only checks IDs when one happens to be present. A `QL-*` block whose `**Evidence:**` field is empty, says arbitrary prose, or references no `EV-*` token passes all assertions; `NS-*` classification records are not checked at all. This contradicts the test's stated guarantee that findings resolve evidence and allows untraceable triage decisions.
**Fix:** For every `QL-*` and `NS-*` record, require at least one parsed `EV-*` reference, assert it is contained in the snapshot evidence set, and require every record signal's `source_evidence_id` to be one of that record's evidence IDs.

---

_Reviewed: 2026-08-26T18:38:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

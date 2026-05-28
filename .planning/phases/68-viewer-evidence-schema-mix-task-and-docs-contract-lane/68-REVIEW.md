---
phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane
reviewed: 2026-05-28T20:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/rendro/viewer_evidence/validator.ex
  - lib/rendro/viewer_evidence/lint.ex
  - lib/rendro/viewer_evidence/frontmatter.ex
  - lib/rendro/viewer_evidence/matrix.ex
  - lib/mix/tasks/rendro/viewer_evidence.ex
  - priv/schemas/support_matrix.schema.json
  - priv/schemas/viewer_evidence.schema.json
  - test/rendro/viewer_evidence/validator_test.exs
  - test/docs_contract/viewer_evidence_claims_test.exs
  - test/mix/tasks/viewer_evidence_task_test.exs
  - scripts/verify_docs.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues
---

# Phase 68: Code Review Report

**Reviewed:** 2026-05-28T20:00:00Z  
**Depth:** standard  
**Files Reviewed:** 14  
**Status:** issues

## Summary

Phase 68 delivers a coherent viewer-evidence validation stack: Draft 2020-12 schemas, a shared `Validator` entry point, operator Mix task, and eighth docs-contract lane. The Tier A/B split is implemented correctly for the phase boundary — production matrix passes Tier-A JSV and `run_full/3` emits five legacy-supported warnings without failing; Tier-B rules are enforced in isolated fixtures and direct `validate_promotion_complete/2` calls.

Exit-code contracts match the documented D-22 refinement: `list` → 0, `missing` → 1 (21 unverified cells), `validate` → 0 with advisory legacy/staleness warnings only. All 49 phase tests pass; `mix docs.contract` runs 8/8 lanes green.

Two warnings remain: orphan/referenced-evidence scans ignore the matrix loaded by `run_full/3`, and GUARDRAIL-04 body lint does not cover frontmatter fields (notably `behaviors[].note`). No critical defects block merge for the default production-matrix path.

## Narrative Findings (AI reviewer)

### Focus-area assessment

| Area | Verdict |
|------|---------|
| Tier A/B split | Correct — schema legacy carve-out, Elixir promotion-complete in fixtures, `run_full` warnings-only for legacy supported |
| Exit codes | Correct on production matrix; advisory/fatal partition in Mix task matches moduledoc |
| GUARDRAIL-04 body lint | Partial — body patterns and negation lookbehinds work; frontmatter YAML not scanned |
| Docs-contract lane | Correct — delegates to shared `Validator`/`Lint`, no duplicated rules; `verify_docs.exs` tuple matches prior lanes |

## Warnings

### WR-01: Orphan and referenced-evidence scans ignore `run_full/3` matrix parameter

**File:** `lib/rendro/viewer_evidence/validator.ex:73-86,188-207`  
**Issue:** `list_orphan_evidence/1`, `list_orphan_evidence_from_root/1`, and the `_matrix` argument to `orphan_violations/3` always call `Matrix.load!()` (hardcoded `priv/support_matrix.json`) when building the referenced-path set. A caller passing a custom `matrix_path` to `run_full/3` gets structural validation and legacy warnings against that matrix, but orphan detection and the public orphan API still compare against the on-disk production matrix.  
**Fix:** Thread the loaded `matrix` through `orphan_violations/3`, `list_orphan_evidence_from_root/1`, and `list_orphan_evidence/1` (add optional `matrix` keyword) instead of calling `Matrix.load!()` internally.

### WR-02: GUARDRAIL-04 lint scope is markdown body only

**File:** `lib/rendro/viewer_evidence/validator.ex:55-65`, `lib/rendro/viewer_evidence/lint.ex:28-37`  
**Issue:** `validate_evidence_file/3` runs `Lint.evidence_body/1` on the markdown body after frontmatter parse but never lints frontmatter strings. Operational secrets, PEM blocks, or home paths placed in `behaviors[].note`, `platform`, or `fixture` bypass GUARDRAIL-04 while still passing schema and body lint. Docs-contract tier-B tests only exercise body violations.  
**Fix:** After frontmatter decode, run `evidence_body/1` (or a shared `lint_text/1`) over concatenated frontmatter string fields (`platform`, `fixture`, all `behaviors[].note` values) before or alongside body lint.

## Info

### IN-01: `validate` subcommand accepts `--json` but ignores it

**File:** `lib/mix/tasks/rendro/viewer_evidence.ex:72-94,129`  
**Issue:** `parse_args!/1` allows `--json` with `validate`, but `run_validate/1` discards the flag. Operators scripting `mix rendro.viewer_evidence validate --json` get human stderr/stdout only. Moduledoc correctly omits JSON for validate, but argv parsing implies support.  
**Fix:** Either reject `--json` on `validate` with a usage error, or document and implement JSON output for validate results.

### IN-02: Duplicate `fetch_row/2` in Mix task and Validator

**File:** `lib/mix/tasks/rendro/viewer_evidence.ex:278-307`, `lib/rendro/viewer_evidence/validator.ex:331-357`  
**Issue:** Identical matrix-path dispatch logic is copy-pasted. Future map additions require two edits and can drift.  
**Fix:** Extract a shared helper (e.g. on `Matrix`) for row lookup by `matrix_path`.

### IN-03: Mix validate tests cover exit 0 only

**File:** `test/mix/tasks/viewer_evidence_task_test.exs:68-76`  
**Issue:** No regression test asserts `validate` exits 1 on Tier-A schema failure, evidence-file lint failure, or orphan detection. Exit-1 path is implemented but unverified in the task test module (covered indirectly via docs-contract tier-B fixtures calling `Validator` directly).  
**Fix:** Add a focused test that stubs or uses a temp matrix/evidence fixture to assert `exit({:shutdown, 1})` when `partition_warnings/1` would classify a violation as fatal.

---

_Reviewed: 2026-05-28T20:00:00Z_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_

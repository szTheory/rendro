---
phase: 76-reference-phoenix-app-ci-and-documentation-closure
plan: "04"
subsystem: docs-contract
tags: [docs, guides, exdoc, docs-contract, support-matrix, CONTRACT-02]
dependency_graph:
  requires:
    - 76-03 (lane-count assertion already set to 10)
    - priv/support_matrix.json (page_numbering, statement, receipt_report, certificate rows)
  provides:
    - guides/page_primitive.md (PAGE primitive guide bounded to page_numbering matrix row)
    - guides/recipes.md (consolidated recipes guide with statement/receipt/certificate + branding pointer)
    - test/docs_contract/page_primitive_claims_test.exs
    - test/docs_contract/recipes_claims_test.exs
    - test/docs_contract/recipes_contract_test.exs
  affects:
    - scripts/verify_docs.exs (10 lanes total, up from 8)
    - mix.exs (extras + groups_for_extras)
tech_stack:
  added: []
  patterns:
    - ExDoc guides with elixir/elixir-schematic fence discipline
    - semantic-claims test pattern (File.read! + assert/refute + matrix lookup + File.exists?)
    - fence-contract test pattern (verified_fences/1 + evaluate!/2)
key_files:
  created:
    - guides/page_primitive.md
    - guides/recipes.md
    - test/docs_contract/page_primitive_claims_test.exs
    - test/docs_contract/recipes_claims_test.exs
    - test/docs_contract/recipes_contract_test.exs
  modified:
    - mix.exs (extras, groups_for_extras, skip_undefined_reference_warnings_on)
    - scripts/verify_docs.exs (+2 lanes, total 10)
decisions:
  - "D-13: Two consolidated guides (page_primitive + recipes) rather than per-recipe guides; Invoice/BrandedInvoice is a pointer to branding.md"
  - "D-14: Both guides wired into root mix.exs docs/0 extras + groups_for_extras under Recipes & Primitives; both added to skip_undefined_reference_warnings_on"
  - "D-15: Reuse existing two harnesses (verified_fences/evaluate! + *_claims_test pattern); no new framework invented"
  - "D-16: Two new claims lanes in verify_docs.exs; fence-contract test in normal suite only"
  - "fence-api-fix: page_primitive.md basic fence revised to use Rendro.Recipes.Statement.document/1 rather than non-existent Rendro.PageTemplate.new/1; suppress_on fence corrected to show Section-level suppress_on (not Block)"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-29T22:15:19Z"
  tasks_completed: 2
  files_created_or_modified: 7
---

# Phase 76 Plan 04: Guides + Docs-Contract Tests Summary

PAGE primitive + canonical recipes documented in HexDocs guides bounded to support matrix rows, with three docs-contract tests and two new verify_docs lanes completing the 8→10 lane count required by CONTRACT-02.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Author page_primitive.md + recipes.md; wire into ExDoc | e73889e | guides/page_primitive.md, guides/recipes.md, mix.exs |
| 2 | Three docs-contract tests + two verify_docs lanes | 8b7a606 | test/docs_contract/{page_primitive_claims,recipes_claims,recipes_contract}_test.exs, scripts/verify_docs.exs |

## Verification Results

- `mix test test/docs_contract/recipes_claims_test.exs test/docs_contract/page_primitive_claims_test.exs test/docs_contract/recipes_contract_test.exs` — **38 tests, 0 failures**
- `mix run scripts/verify_docs.exs` — **all 10 lanes green**
- `mix test test/guardrails/required_checks_contract_test.exs` — **11 tests, 0 failures**
- `mix docs` — **builds clean** (no undefined-reference warnings from new guides)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed non-existent PageTemplate.new/1 in page_primitive fence**
- **Found during:** Task 2 RED phase — fence evaluation in recipes_contract_test.exs
- **Issue:** The initial `page_primitive.md` basic fence called `Rendro.PageTemplate.new/1` which is not a public API (no `new/1` constructor exists; the struct has no constructor)
- **Fix:** Replaced the basic fence with a `Rendro.Recipes.Statement.document/1` call that correctly demonstrates the PAGE primitive via the primary consumer recipe
- **Files modified:** guides/page_primitive.md
- **Commit:** part of task 2 iteration (not committed separately; guides revised before task 2 commit)

**2. [Rule 1 - Bug] Fixed suppress_on fence to use Section (not Block)**
- **Found during:** Task 2 RED phase
- **Issue:** Initial fence showed `block.suppress_on` but `suppress_on` lives on `Rendro.Section`, not `Rendro.Block`
- **Fix:** Revised the suppress fence to show `Rendro.section/1` with `suppress_on: :first` field
- **Files modified:** guides/page_primitive.md

**3. [Rule 1 - Bug] Removed full_pdf_compliance from guide prose**
- **Found during:** Task 2 test run — `refute guide =~ "full_pdf_compliance"` failed
- **Issue:** Guide intro mentioned `full_pdf_compliance` in the "unsupported array" explanation
- **Fix:** Replaced prose with neutral "Claims that exceed the support matrix are not made here"; rewrote scope boundaries section to avoid mentioning the exact `unsupported` array term
- **Files modified:** guides/recipes.md

**4. [Style] Removed unused @guides module attribute**
- **Found during:** Task 2 compile warning
- **Issue:** `@guides` attribute declared but only used in `for` comprehension binding
- **Fix:** Removed `@guides` attribute; the comprehension uses the list literal directly
- **Files modified:** test/docs_contract/recipes_contract_test.exs

## Success Criteria Verification

- [x] guides/page_primitive.md exists and contains "Page X of Y"
- [x] guides/recipes.md exists with statement/receipt/certificate sections and branding.md pointer; contains "Page X of Y"
- [x] Neither guide contains "digital signatures" or full_pdf_compliance claims
- [x] mix.exs extras includes both guides; groups_for_extras has "Recipes & Primitives" group
- [x] mix docs builds clean
- [x] page_primitive_claims_test cross-checks ONLY page_numbering row; refutes digital_signatures
- [x] recipes_claims_test cross-checks statement + receipt_report + certificate; asserts File.exists? on all 3 evidence paths; refutes digital_signatures
- [x] recipes_contract_test calls verified_fences/1 + evaluate!/2 over BOTH guides; refutes "..." / "%{...}"
- [x] verify_docs.exs has exactly 10 lanes; fence-contract test NOT registered as a lane
- [x] mix run scripts/verify_docs.exs runs all 10 lanes green (CONTRACT-02)

## Known Stubs

None. All guides are fully wired with evaluated elixir fences and semantic-claims cross-checks.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries were introduced by this plan. The semantic-claims tests (T-76-07) and fence-contract test (T-76-08) are in place as specified in the threat model.

## Self-Check: PASSED

- [x] guides/page_primitive.md exists
- [x] guides/recipes.md exists
- [x] test/docs_contract/page_primitive_claims_test.exs exists
- [x] test/docs_contract/recipes_claims_test.exs exists
- [x] test/docs_contract/recipes_contract_test.exs exists
- [x] scripts/verify_docs.exs has 10 lanes
- [x] Commits e73889e and 8b7a606 exist in git log

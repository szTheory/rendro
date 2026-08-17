---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
verified: 2026-08-17T06:30:32Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 126: Carryover Polish Verification Report

**Phase Goal:** Resolve or honestly exempt every deferred v2.11 dark-mode/hierarchy defect, and deepen golden/typography coverage—including a preset × accent golden now that `Theme.preset/2` exists—so the first catalog generation isn't the first real stress test of these paths.

**Verified:** 2026-08-17T06:30:32Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `invoice_dark` table-body cells use legible ink at a shared color-role boundary. | ✓ VERIFIED | `Rendro.Recipes.TableCell.content/5` returns semantic-color `Text` blocks only for supplied themes, while preserving literal strings for `nil`; Invoice routes headers and rows through it. `invoice_test.exs` asserts resolved dark `:ink` on every cell and palette precedence. |
| 2 | Ticket themed hierarchy is fixed or explicitly exempted. | ✓ VERIFIED | It is fixed, not exempted: `ticket_roles/2` maps supplied themes to display/title/caption; `ticket_test.exs` asserts placement > title > complete reference across default plus all six genres. WINDOWS id 2 is fixed with bounded raster and approval evidence. |
| 3 | Payslip themed numeric cells do not wrap mid-number, including Minimal-Mono. | ✓ VERIFIED | Themed-only 61pt Current / 68pt YTD widths flow into both `measure_rows/4` and rendered table columns. Tests cover all six genres, right alignment, and a Humanist one-point-narrower failing control; WINDOWS id 3 is fixed. |
| 4 | A dedicated byte-identity golden covers `from_brand`/preset × accent combinations. | ✓ VERIFIED | `preset_accent_golden_test.exs` defines exactly three ordered variants (`from_brand`, Swiss, Minimal-Mono), asserts two-render byte equality and named SHA-256 values, and proves preset font registration is required. |
| 5 | All seven recipes have dedicated materialized type-scale coverage. | ✓ VERIFIED | Seven `*_typography_test.exs` modules cover Invoice, BrandedInvoice, Statement, Receipt, Payslip, Certificate, and Ticket, asserting semantic text scale/font/leading and explicit typography override precedence. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/rendro/recipes/table_cell.ex` | Internal semantic cell boundary | ✓ VERIFIED | 19 substantive lines; `nil` compatibility and role lookup are real implementation, imported by Invoice. |
| `lib/rendro/recipes/invoice.ex` | Themed semantic table cells and correct measurement context | ✓ VERIFIED | `table_row/4` uses `TableCell`; same transformed cells feed `measure_rows/4`; review fixes limit metric roles to the body/mono roles actually emitted. |
| `lib/rendro/recipes/ticket.ex` | Themed monotonic role mapping and compact reference | ✓ VERIFIED | `main_section/2` and `reference_blocks/7` consume `ticket_roles/2`; supplied-theme mapping is display/title/caption, nil path remains historical. |
| `lib/rendro/recipes/payslip.ex` | Measured atomic money cells | ✓ VERIFIED | Themed widths are selected only with a supplied theme and used in rendered/measurement table options; nil widths remain frozen. |
| `test/rendro/theme/preset_accent_golden_test.exs` | Bounded deterministic accent golden | ✓ VERIFIED | 81-line substantive, executable SHA-256 and two-render test. |
| Seven recipe typography test modules | Semantic type-scale contracts | ✓ VERIFIED | All exist, are substantive, and ran in focused/current full-suite verification. |
| `.github/workflows/ci.yml` + `test/guardrails/required_checks_contract_test.exs` | Pinned advisory raster blessing guard | ✓ VERIFIED | Only legacy adapter comparison is step-level non-blocking; preset blessing, staging, and upload are fail-closed and tested. |
| `.planning/WINDOWS.md`, `priv/quality/SIGN-OFF.md`, `priv/quality/rubric_scores.json` | Honest closure records for ids 1–3 | ✓ VERIFIED | IDs 1–3 are fixed with deterministic, pinned-PDFium, and bounded-review citations; JSON validates and closure contract tests pass. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Invoice | TableCell | `table_row/4` | ✓ WIRED | Same transformed header/body cells are used to measure and render. |
| Ticket roles | Ticket main/reference content | `ticket_roles/2` | ✓ WIRED | Placement, title, and reference sizes are consumed at their respective render sites. |
| Payslip widths | Measurement and rendered table | `money_column_widths/1` + `table_opts` | ✓ WIRED | One `table_opts` value supplies `measure_rows/4` and `Rendro.table/2`. |
| Accent golden | `Theme.from_brand/2`, `Theme.preset/2`, font bridge | test helper and `Presets.register_fonts/2` | ✓ WIRED | Preset rows render only after explicit bridge; from-brand row remains default-font path. |
| CI advisory job | Preset raster snapshot + pinned PDFium manifest | guarded ref env | ✓ WIRED | Workflow contract test verifies branch guard, exact six hash/review paths, pin provenance, and absence of blessing in required test job. |
| WINDOWS / sign-off / rubric | approved review record | exact stable row IDs | ✓ WIRED | Records cite the same bounded Invoice, Ticket, and Payslip rows and retain non-compliance wording. |

### Data-Flow Trace (Level 4)

Not applicable: Phase 126 changes pure rendering/test/evidence paths, not a dynamic UI or API data source. The relevant render inputs were traced through the actual recipe construction, engine measurement, and deterministic render tests above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase recipe/golden/typography/guardrail behavior | focused `mix test` across changed recipe, typography, golden, guardrail, and preset-matrix tests | 166 tests, 0 failures | ✓ PASS |
| Quality ledger schema and workflow guard | `mix test test/docs_contract/rubric_manifest_contract_test.exs test/guardrails/required_checks_contract_test.exs` | 91 tests, 0 failures | ✓ PASS |
| Full deterministic suite | `mix test` | 12 doctests, 8 properties, 1,764 tests, 0 failures (27 excluded) | ✓ PASS |
| Required CI-quality lane | `mix ci.fast` | passed: tests, docs, Credo, Dialyzer | ✓ PASS |
| Temporary evidence-ref deletion | `git ls-remote --exit-code --heads origin <each retained ref>` | both refs absent (exit 2 expected) | ✓ PASS |

### Advisory Raster / Human Evidence

The deterministic and advisory lanes remain intentionally separate. The accepted artifact is recorded as GitHub Actions run `31997957937`, exact SHA `a00f1b0540602b8ba8937ce1b7e55ba0cba48b13`, pinned PDFium `v0.11.0`, executable SHA `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`. The workflow/artifact contract is fail-closed except for the disclosed legacy adapter comparison.

Only six intended preset raster hashes changed: Swiss Invoice light, Corporate-Classic Invoice dark, Editorial/Minimal-Mono Ticket dark, and Humanist/Brutalist Payslip dark. Four additional Invoice pagination goldens are the documented post-review reconciliation from the capacity correction; the unblessed edge matrix and focused Invoice suites passed. No other raster-reference path changed.

The already-completed blocking human checkpoint is recorded as `visual_review: approved` and `cleanup_authorized: true`: all six stable row images were reviewed one at a time at readable native size, not as a contact sheet alone. Its claims are explicitly bounded to those fixtures and reject WCAG, PDF/UA, print-safety, accessibility, and universal-quality interpretations; therefore no further human verification is outstanding.

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| POLISH-01 | ✓ SATISFIED | Shared `TableCell` semantic `:ink` path, Invoice all-cell/palette/nil-byte tests, approved Swiss/Corporate raster rows, WINDOWS id 1 fixed. |
| POLISH-02 | ✓ SATISFIED | Themed display/title/caption mapping and all-genre hierarchy/reference tests; approved Editorial/Minimal-Mono rows; WINDOWS id 2 fixed. |
| POLISH-03 | ✓ SATISFIED | Measured themed money widths with all-genre and one-point-boundary tests; approved Humanist/Brutalist rows; WINDOWS id 3 fixed. |
| POLISH-04 | ✓ SATISFIED | Exact bounded three-row `from_brand`/preset accent SHA-256 golden with two-run equality. |
| POLISH-05 | ✓ SATISFIED | Dedicated semantic typography modules for all seven recipes, exercised in focused and full runs. |

No Phase-126 requirement is orphaned: all five `POLISH-*` IDs are declared in the plans and mapped to implementation and executable evidence.

### Anti-Patterns and Scope Audit

No blocker anti-patterns found in Phase-126 implementation/test files: no TODO/FIXME/XXX debt marker, placeholder implementation, new dependency, public table/no-wrap API, preset-specific recipe branch, or unsupported public claim.

No later-phase leakage found. `lib/rendro/catalog.ex`, `assets/rendro/catalog.json`, `assets/rendro/configurator/`, configurator codegen, and `guides/presets.md` are absent; the phase made no `mix.exs`, public API manifest, support-matrix, or `theme.ex` change. Existing launch-artifact regeneration is confined to the repaired pre-existing gallery surface.

**Disconfirmation pass:** review-fix commits corrected an Invoice capacity calculation and font-role validation after the initial implementation; the four authorized Invoice pagination goldens prove the correction was reconciled rather than hidden. The current focused selection now contains 166 tests (the review report’s earlier scope recorded 164), with all passing. Error paths for missing curated/font roles are actively tested, not inferred from successful render paths.

### Probe Execution

SKIPPED — no `scripts/**/tests/probe-*.sh` exists and Phase 126 declares no runnable shell probe. Its ten planning “specless probes” are explicitly represented by executable recipe/golden/guardrail tests or flagged assumptions in the completed validation map.

### Human Verification Required

None. The phase’s only human-dependent item—the six-row full-size pinned-PDFium review—was completed and recorded with a bounded approval before WINDOWS closure and remote-ref cleanup.

---

_Verified: 2026-08-17T06:30:32Z_  
_Verifier: the agent (gsd-verifier)_

---
phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
plan: 05
subsystem: testing
tags: [rubric, sign-off, jsv, schema, honesty-gate, docs-contract]

# Dependency graph
requires:
  - phase: 123-03
    provides: 11-row themed gallery + fresh themed glyph-height deltas + 3 discovered honesty findings recorded in WINDOWS.md
provides:
  - Honest re-score of all 6 rubric demos against the themed default/0 gallery bytes (not the stale 2026-07-19 native-scale numbers)
  - Machine-enforced human sign-off (signed_off_by/signed_off_at/evidence_ref) via schema if/then + test-loop teeth
  - priv/quality/SIGN-OFF.md (SCORECARD house style, dated, per-demo, honest-not-flattering)
  - A git-provable, colour-free score-flip commit (D-05 Commit 3 isolation)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schema if/then (draft-2020-12) + test-loop teeth as a two-layer sign-off enforcement: passed==true requires signed_off_by/signed_off_at/evidence_ref, and the test loop additionally verifies evidence_ref exists on disk AND is present in the hash-checked gallery manifest."
    - "passed?/2 recomputation as the sole source of truth for the passed field — never asserted independently, so an honest passed:false (Ticket) is structurally indistinguishable in the test harness from a passed:true (both are recomputed, not trusted)."

key-files:
  created:
    - priv/quality/SIGN-OFF.md
    - .planning/phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/deferred-items.md
  modified:
    - priv/quality/rubric_scores.json
    - priv/schemas/rubric_scores.schema.json
    - test/docs_contract/rubric_manifest_contract_test.exs
    - .planning/WINDOWS.md

key-decisions:
  - "Ticket is recorded passed:false (content_hierarchy: 3, typographic_craft: 3) per the human's honest verdict — the themed uniform type scale inverted the reference-code/placement-grid hierarchy the 2026-07-19 rubric scored, and the reference code now wraps mid-token across 3 lines. This was NOT flattened to true; it is the honesty culmination of the phase (D-05's named anti-trap)."
  - "Certificate is recorded passed:true (content_hierarchy: 5) despite the themed recipient/title ratio compressing from 1.70 to 1.27 — human visual sign-off 2026-07-28 confirmed the recipient still reads as the single unambiguous focal point on the actual raster, and the compression is disclosed (not hidden) in both rubric_scores.json's justification and SIGN-OFF.md."
  - "Payslip's typographic_craft stays at 4 (not raised to 5) because the themed render introduced a real numeric-cell wrap defect ($4,200.0/0); this is recorded honestly and left open as WINDOWS.md id 3, cited in SIGN-OFF.md, rather than silently patched or silently ignored to justify a 5."
  - "mix ci.fast/ci.advisory could not be run fully green in this execution environment due to pre-existing, out-of-scope blockers (format debt in 7 unrelated files, 2 unrelated pre-existing test failures referencing missing phase-113 artifacts, pre-existing dialyzer errors in ticket.ex, and a missing pdfium-cli binary) — verified individually that compile/docs/credo/hex.build/test (net of the 2 unrelated failures) are all clean, and logged the 4 blockers as WINDOWS.md ids 4-7 + this plan's deferred-items.md rather than fixing out-of-scope files."

patterns-established:
  - "Sign-off provenance fields (signed_off_by/signed_off_at/evidence_ref) as additive, non-breaking manifest fields under a schema with additionalProperties: true, enforced by a conditional if/then rather than a blanket required list — allows passed:false entries to omit sign-off fields without failing schema validation."

requirements-completed: [DEFAULT-02]

coverage:
  - id: D1
    description: "All 6 rubric demos are re-scored against the themed default/0 gallery bytes; passed is recomputed via passed?/2 for every entry, never independently asserted; Ticket's honest passed:false is preserved (not flattened to true)."
    requirement: "DEFAULT-02"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#recorded `passed` matches recomputation from each entry's own dimensions/gates"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every passed==true record carries signed_off_by/signed_off_at/evidence_ref; evidence_ref File.exists? AND is present in the hash-checked artifacts.json gallery, enforced by schema if/then AND test-loop teeth, fail-loud both directions."
    requirement: "DEFAULT-02"
    verification:
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#every passed:true entry carries a live, hash-checked human sign-off (DEFAULT-02 honesty gate)"
        status: pass
      - kind: unit
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#schema validation: checked-in manifest validates against rubric_scores.schema.json"
        status: pass
    human_judgment: false
  - id: D3
    description: "The score-flip commit's diff touches ONLY priv/quality/, priv/schemas/, and test/docs_contract/ — zero lib/*.ex, zero assets/, zero palette/token/colour code."
    requirement: "DEFAULT-02"
    verification:
      - kind: other
        ref: "git show --stat --name-only 5eda766 (grep for lib/ or assets/ returns nothing)"
        status: pass
    human_judgment: false
  - id: D4
    description: "priv/quality/SIGN-OFF.md exists in the brand/audit/SCORECARD.md house style (dated, per-demo, 'Honest not flattering'), citing each demo's measured themed key-fact glyph delta and explicitly naming Certificate's 1.27 compression, Payslip's wrap (WINDOWS id 3), and Ticket's honest passed:false (WINDOWS id 2)."
    requirement: "DEFAULT-02"
    verification:
      - kind: manual_procedural
        ref: "priv/quality/SIGN-OFF.md (reviewed for house style, per-demo citations, and the 3 named findings)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Human sign-off verdict applied verbatim from the Task 1 checkpoint: Invoice/Statement/Receipt-Report/Certificate/Payslip passed:true, Ticket passed:false, with the exact dimension scores the human specified."
    verification: []
    human_judgment: true
    rationale: "The verdict itself (which scores each demo honestly earns) is inherently a human visual judgment call over the pre-computed evidence — this plan applies it verbatim, but confirming the applied JSON matches the human's stated verdict is a judgment call best re-confirmed by a human reviewer, not purely mechanical."

duration: 6min (Task 2-3 only; Task 1's human-verify checkpoint from the prior executor session is not included)
completed: 2026-07-28
status: complete
---

# Phase 123 Plan 05: Honest rubric re-score + machine-enforced sign-off Summary

**All 6 rubric demos re-scored against the themed default/0 gallery bytes with machine-enforced human sign-off — 5 honestly pass (Invoice, Statement, Receipt/Report, Certificate, Payslip), Ticket honestly fails (content_hierarchy inversion + mid-token wrap), and the score-flip commit is provably colour-free.**

## Performance

- **Duration:** 6 min (Task 2 + Task 3, from human verdict receipt to phase-gate documentation; this is a continuation agent — Task 1's human-verify checkpoint occurred in a prior session and is not included in this duration)
- **Started:** 2026-07-28T20:45:00Z (approx., continuation agent start)
- **Completed:** 2026-07-28T20:54:13Z
- **Tasks:** 2 of 3 (Task 1 — human checkpoint — was completed by a prior executor session; this agent resumed at Task 2)
- **Files modified:** 6 (4 in Task 2's score-flip commit + 2 in Task 3's documentation commit)

## Accomplishments

- All 6 records in `priv/quality/rubric_scores.json` re-scored against the themed `default/0` gallery rasters blessed in 123-03, replacing the stale 2026-07-19 native-scale justifications with fresh measured glyph-height deltas (25.9px display vs. 20.4px title, 1.27 ratio).
- Human verdict applied verbatim, with no flattening: Invoice, Statement, Receipt/Report, Certificate, and Payslip honestly clear `passed:true`; Ticket is honestly recorded `passed:false` (content_hierarchy 3, typographic_craft 3) — the reference-code display anchor now dominates the placement-grid title role the original rubric scored, and wraps mid-token across 3 lines.
- Every record gains `signed_off_by`/`signed_off_at`/`evidence_ref`; the `passed` field is recomputed by `passed?/2` from each entry's own `dimension_scores`/`gate_results` for every entry — never independently asserted (SHOW-01 honesty gate).
- Added a schema `if/then` (`priv/schemas/rubric_scores.schema.json`) requiring the 3 sign-off fields when `passed==true`, plus test-loop teeth (`rubric_manifest_contract_test.exs`) asserting every `passed:true` entry's `evidence_ref` exists on disk AND is present in the hash-checked `assets/rendro/artifacts.json` gallery — fails loud in both directions; Ticket's honest `passed:false` is never blocked by this loop.
- Authored `priv/quality/SIGN-OFF.md` in the `brand/audit/SCORECARD.md` house style, dated, per-demo, citing each demo's measured themed glyph delta and explicitly naming Certificate's 1.27 compression, Payslip's numeric-cell wrap (WINDOWS id 3, open), and Ticket's honest `passed:false` (WINDOWS id 2, open).
- Verified the score-flip commit (`5eda766`) is provably colour-free: `git show --stat --name-only` lists only `priv/quality/`, `priv/schemas/`, and `test/docs_contract/` paths.
- Committed with an additive `Signed-off-by: qiksnare13 <qiksnare13@gmail.com>` git trailer.

## Task Commits

1. **Task 1: Human sign-off — judge the 6 themed rubric demos** — completed in a prior executor session (checkpoint, no separate commit; verdict supplied to this continuation agent)
2. **Task 2: Record the honest re-score — sign-off fields + schema if/then + test teeth + SIGN-OFF.md** - `5eda766` (feat)
3. **Task 3: Prove the score-flip commit isolation + run the phase gate** - `23f821e` (docs) — verification-only per the plan's `reversibility` note; committed the isolation-proof documentation + WINDOWS.md entries for pre-existing blockers, no product code touched

**Plan metadata:** _pending — recorded after this SUMMARY is committed_

## Files Created/Modified

- `priv/quality/rubric_scores.json` - all 6 records re-scored (fresh themed justifications, sign-off fields, recomputed `passed`)
- `priv/quality/SIGN-OFF.md` - new, SCORECARD house-style human sign-off record
- `priv/schemas/rubric_scores.schema.json` - `signed_off_by`/`signed_off_at`/`evidence_ref` properties + `if/then` requiring them when `passed==true`
- `test/docs_contract/rubric_manifest_contract_test.exs` - new `gallery_png_paths/0` helper + sign-off teeth test loop
- `.planning/WINDOWS.md` - 4 new entries (ids 4-7) for pre-existing phase-gate blockers discovered during Task 3
- `.planning/phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/deferred-items.md` - new, documents the 4 out-of-scope blockers in detail

## Decisions Made

- Kept all non-flagged dimension scores unchanged from the 2026-07-19 baseline for the 5 passing demos (the human verdict confirmed content_hierarchy==5 and the pre-existing core dimensions, without directing new values for the untouched dimensions) — only content_hierarchy justifications were rewritten with fresh themed measurements, plus Payslip's typographic_craft justification (to honestly cite the new wrap defect while keeping its existing score of 4).
- For Ticket, only `content_hierarchy` (5→3) and `typographic_craft` (4→3) were changed per the human's explicit verdict; the other 4 dimensions and both gates were left at their prior values since the human did not direct changes to them.
- Sign-off fields (`signed_off_by`/`signed_off_at`/`evidence_ref`) were added to ALL 6 records (including the failing Ticket entry), per the plan's Task 2 action text ("add ... to every record"), even though the schema `if/then` only requires them when `passed==true` — this preserves full provenance across the whole re-score, not just the passing entries.
- `mix ci.fast`/`mix ci.advisory` phase gates could not be run fully green in this environment; rather than force a false green (or silently skip verification), each sub-step was run individually to prove this plan's own changes are clean (compile, docs, credo, hex.build, and the full test suite net of 2 unrelated pre-existing failures all pass), and the 4 pre-existing, out-of-scope blockers were logged to `WINDOWS.md` (ids 4-7) and this plan's `deferred-items.md` per the executor's scope-boundary rule.

## Deviations from Plan

### Auto-fixed Issues

None — Task 2 was executed exactly as specified; no bugs, missing functionality, or blocking issues were encountered while writing the score-flip commit.

### Scope-Boundary Findings (documented, NOT fixed — out of scope)

**1. [Scope boundary] `mix ci.fast` fails at its first step (`format --check-formatted`) on 7 pre-existing files**
- **Found during:** Task 3 (running the phase gate)
- **Issue:** `lib/rendro/launch_artifacts.ex`, `test/docs_contract/theme_industry_guard_test.exs`, `test/docs_contract/theming_claims_test.exs`, `test/rendro/recipes/payslip_opts_threading_test.exs`, `test/rendro/recipes/themed_render_smoke_test.exs`, `test/rendro/recipes/certificate_typography_test.exs`, `test/rendro/recipes/theme_mode_background_golden_test.exs` fail `mix format --check-formatted` — none were touched by this plan's commit (last touched by phases 119/121/122/123-03/123-04). Because `ci.fast`'s alias chain runs this step first, the whole chain halts here.
- **Not fixed** (pre-existing, unrelated files — out of this plan's scope per the SCOPE BOUNDARY rule). Logged as `.planning/WINDOWS.md` id 4.
- **Verified in isolation instead:** `mix compile --warnings-as-errors`, `mix docs --warnings-as-errors`, `mix credo --strict`, and `mix hex.build` were each run standalone and are all clean.

**2. [Scope boundary] 2 pre-existing test failures unrelated to phase 123**
- **Found during:** Task 3 (`mix test --exclude quarantine`)
- **Issue:** `test/docs_contract/dx_local_reproducibility_claims_test.exs` has 2 failures — `File.Error` reading `.planning/phases/113-dx-local-reproducibility-validation/113-UAT.md` and `113-METRICS.md`, which do not exist in this working tree's partial phase-113 planning directory.
- **Not fixed** (unrelated to phase 123's rubric/gallery/theming work). Logged as `.planning/WINDOWS.md` id 5.
- **Verified:** all other 1699 tests + 12 doctests + 8 properties pass; the new rubric contract test loop is green (74/74 in its own file, including the honest `passed:false` case).

**3. [Scope boundary] `mix dialyzer` fails on pre-existing `lib/rendro/recipes/ticket.ex` contract errors**
- **Found during:** Task 3 (running `mix dialyzer`)
- **Issue:** `no_return` errors on `Ticket.document/1,2` and `Ticket.sections/1,2`, plus a `Rendro.Recipes.Background.emit?/1` contract mismatch — not touched by this plan's commit.
- **Not fixed** (a `lib/`-touching fix would violate this plan's D-05 Commit 3 isolation scope; plausibly related to the same Ticket regression already recorded honestly as `passed:false`). Logged as `.planning/WINDOWS.md` id 6.

**4. [Scope boundary] `mix rendro.launch_artifacts.check` fails: `pdfium-cli` not installed**
- **Found during:** Task 3 (running `ci.advisory`'s gallery-hash check)
- **Issue:** `{:missing_executable, "pdfium-cli"}` — the pinned v0.11.0 binary is not present on `PATH` in this execution environment.
- **Not fixed** (environment/tooling gap; external binaries are not auto-installed without human verification, per the executor's package-legitimacy caution). Logged as `.planning/WINDOWS.md` id 7.

---

**Total deviations:** 0 auto-fixed; 4 scope-boundary findings documented (not fixed, all pre-existing and unrelated to this plan's changes)
**Impact on plan:** This plan's own commit (`5eda766`) is fully verified clean in isolation (compile, docs, credo, hex.build, the full test suite net of 2 unrelated failures, and the new rubric contract test loop all pass). The phase-gate blockers are pre-existing environment/formatting/tooling debt from earlier phases/plans, now tracked in `WINDOWS.md` (ids 4-7) so they surface at ship time rather than being silently absorbed into this plan's honest re-score work.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan's changes.

## Issues Encountered

See "Scope-Boundary Findings" above — all four issues were pre-existing, unrelated to this plan's file scope, and are documented rather than fixed per the SCOPE BOUNDARY rule.

## User Setup Required

None — no external service configuration required. (Installing `pdfium-cli` locally would resolve WINDOWS.md id 7, but that is an environment-setup action for a future session/plan, not a runtime service dependency of this plan's own deliverables.)

## Next Phase Readiness

- DEFAULT-02 (the honest rubric-gap closure) is satisfied: the invoice (SHOW-01's subject) honestly clears `passed:true` against the themed bytes, and honest `passed:false` findings (Ticket) are recorded where warranted rather than rubber-stamped.
- `priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md`, `priv/schemas/rubric_scores.schema.json`, and `test/docs_contract/rubric_manifest_contract_test.exs` are all in their final, honest state for this milestone.
- `.planning/WINDOWS.md` now has 7 open items (ids 1-7): the 3 discovered-during-123-03 findings (Invoice dark illegibility, Ticket hierarchy inversion, Payslip numeric wrap) plus the 4 phase-gate blockers found in this plan's Task 3 (format debt, 2 unrelated test failures, dialyzer errors, missing pdfium-cli). All 7 remain OPEN and will block `/gsd-ship` until triaged (fixed or explicitly waived) in a future plan.
- Phase 123 is now complete (5 of 5 plans) pending STATE.md/ROADMAP.md/REQUIREMENTS.md bookkeeping below.

## Self-Check: PASSED

Verified on disk: `priv/quality/rubric_scores.json` (6 records, all with `signed_off_by`/`signed_off_at`/`evidence_ref`), `priv/quality/SIGN-OFF.md`, `priv/schemas/rubric_scores.schema.json` (if/then present), `test/docs_contract/rubric_manifest_contract_test.exs` (sign-off teeth loop present), `.planning/WINDOWS.md` (7 entries), `.planning/phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/deferred-items.md`. Verified in `git log`: `5eda766` and `23f821e` both present, both carrying `Signed-off-by: qiksnare13 <qiksnare13@gmail.com>` trailers.

---
*Phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani*
*Completed: 2026-07-28*

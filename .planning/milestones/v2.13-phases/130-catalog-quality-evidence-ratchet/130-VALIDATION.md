---
phase: 130
slug: catalog-quality-evidence-ratchet
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-19
revised: 2026-08-26
---

# Phase 130 — Validation Strategy

> Deterministic checks are merge authority. Golden authorization, pinned launch generation, six-light launch review, catalog candidate generation, pinned catalog payload, and twelve-cell catalog review remain distinct evidence stages.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Elixir 1.19.5 / OTP 28 |
| Quick recipe command | Modified family's structural, typography, and byte-identity suites |
| Golden command | Staged explicit bless followed by identical assert-only test |
| Launch command | Detached staging gen/check with one PDFium v0.11.0 binary, SHA `b1e7f3...160a` |
| Launch contracts | launch artifacts + launch claims + theming claims + rubric manifest contracts |
| Catalog candidate | `mix rendro.catalog.candidate`; fixed temp root, quality-free actual diff |
| Pure payload | untagged catalog review payload contract |
| Catalog advisory payload | tagged raster snapshot against exact candidate identities |
| Canonical catalog | exactly one `mix rendro.catalog.gen` after twelve-record transcription |
| Full closure | golden + launch + recipes + catalog/schema/docs + full tests + ci.fast + package/API boundaries |

## Sampling and Ordering

1. Completed 130-01/02 retain their focused green checks; 130-03 establishes the pure payload and full-SHA CI contract.
2. 130-07 stages exact HEAD and obtains the first human gate: exact two-golden authorization.
3. 130-08 obtains the second gate for exact pinned launch generation, then fences the generator-owned diff without review.
4. 130-09 obtains the third gate: six changed light launch decisions, with no binary ownership.
5. 130-04 obtains the fourth gate and creates the pinned 32-cell candidate; 130-05 obtains the fifth gate through the distinct twelve-image catalog review.
6. 130-06 publishes one isolated 19-path launch/golden/evidence commit; 130-10 transcribes catalog evidence and runs the sole canonical generation; 130-11 validates and cleans exact temporary provenance.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Evidence / secure behavior | Automated command or checkpoint evidence | Status |
|---|---:|---:|---|---|---|---|---|
| 130-01-01 | 01 | 1 | CATALOG-06,07 | T-130-01A/B/C | Receipt measure/render semantic identity and frozen nil-theme bytes | Receipt focused suites | ✅ complete |
| 130-01-02 | 01 | 1 | CATALOG-06 | T-130-01A/C | Invoice public-theme Total Due/due-date hierarchy | Invoice focused suites | ✅ complete |
| 130-01-03 | 01 | 1 | CATALOG-06 | T-130-01A/C | Statement public-theme closing balance | Statement focused suites | ✅ complete |
| 130-02-01 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Certificate rank and coupled centering | Certificate focused suites | ✅ complete |
| 130-02-02 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Payslip Net Pay and atomic money | Payslip focused suites | ✅ complete |
| 130-02-03 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Ticket placement-first hierarchy | Ticket focused suites | ✅ complete |
| 130-03-01 | 03 | 2 | CATALOG-09 | T-130-03A/C | Exact 12-image payload, separate 4-image multipage proof, complete identity | Pure payload contract; 130-03-SUMMARY | ✅ complete |
| 130-03-02 | 03 | 2 | CATALOG-09 | T-130-03B/C | Full-40-SHA advisory route remains non-required | Required-checks contract; 130-03-SUMMARY | ✅ complete |
| 130-07-01 | 07 | 3 | CATALOG-06,07,08 | T-130-07B/C | Exact-HEAD detached worktree and baseline fence | SHA equality + baseline + main diff fence; 130-07-SUMMARY | ✅ complete |
| 130-07-02 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/C | Blocking exact two-golden authorization | Authorized exact old/new SHA pairs; 130-07-SUMMARY | ✅ complete |
| 130-07-03 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/B | Only authorized goldens blessed in staging | Assert-only 7-test golden check + exact two-file diff; 130-07-SUMMARY | ✅ complete |
| 130-08-01 | 08 | 4 | CATALOG-06,07,08 | T-130-08A/C | Blocking pinned PDFium path or exact-SHA CI action | Pin/provenance and CI renderer/generation evidence; 130-08-SUMMARY | ✅ complete |
| 130-08-02 | 08 | 4 | CATALOG-06,07,08 | T-130-08B/C | Exact ten-change/stable-control staged diff and rollback | Exact diff JSON, stable control, canonical fences; 130-08-SUMMARY | ✅ complete |
| 130-09-01 | 09 | 5 | CATALOG-06,07,09 | T-130-09A/B/C | Blocking six-light full-size launch review, no binary ownership | Six complete dated/hash-bound decisions; 130-09-SUMMARY | ✅ complete |
| 130-04-01 | 04 | 6 | CATALOG-08,09 | T-130-04A/B/C/D | Compile-first fixed-target quality-free candidate seam, strict options, and atomic cleanup | Catalog/quality contracts + invalid-option proof; 130-04-SUMMARY | ✅ complete |
| 130-04-02 | 04 | 6 | CATALOG-08,09 | T-130-04A/D | Blocking exact-SHA pinned 32-cell candidate batch | Full-SHA route/run/pin; 32 candidate + 12 final + 4 multipage; 130-04/05 summaries | ✅ complete |
| 130-04-03 | 04 | 6 | CATALOG-08,09 | T-130-04A/B/C/D | Exact actual-diff partition and canonical unchanged | 12 scored/review-required, 20 unscored, zero stable; 130-04-SUMMARY | ✅ complete |
| 130-05-01 | 05 | 7 | CATALOG-09 | T-130-05A/B/C | Blocking distinct twelve-cell full-size catalog review | Twelve complete reconciliation-SHA-bound records; 130-05-SUMMARY | ✅ complete |
| 130-06-01 | 06 | 8 | CATALOG-06,07,08 | T-130-06A/B/C | One 19-path reviewed launch publication commit and whole-commit rollback | Exact 19-path `07e3fc8` publication + contracts; 130-06-SUMMARY | ✅ complete |
| 130-10-01 | 10 | 9 | CATALOG-08,09 | T-130-10A/B | Exact catalog transcription and threshold/dark closure | 12 scored projections, dark `print_safety: false`; 130-10-SUMMARY | ✅ complete |
| 130-10-02 | 10 | 9 | CATALOG-08,09 | T-130-10B/C | Sole canonical generation and 32-cell candidate reproduction | Exact-SHA CI run `32434769523`, 33 checksums, 32-cell equality; 130-10-SUMMARY | ✅ complete |
| 130-11-01 | 11 | 10 | CATALOG-06,07,08,09 | T-130-11A/C | Complete source/decision/UI/edge/prohibition and deterministic closure | Focused 119, family 300, catalog 95, full suite pass; final `mix ci.fast` pass (1,839 tests, 0 failures; Dialyzer 0 errors) | ✅ complete |
| 130-11-02 | 11 | 10 | CATALOG-06,07,08,09 | T-130-11A/B | Exact ref/worktree/candidate cleanup after durable closure | Exact remote SHA/manifest/worktree checks passed; two refs, detached launch worktree, and review root absent afterward | ✅ complete |

## Wave 0 Ownership

| Gap | Owning task | Proof created before behavior/publication |
|---|---|---|
| Candidate-driven twelve-image/multipage split | 130-03-01 | Untagged pure classifier contract |
| Full-SHA route and authority separation | 130-03-02 | Guardrail assertions precede workflow edit |
| Golden authorization and exact staging | 130-07-01/02/03 | Baseline and diff gates precede publication |
| Launch fail-closed staging | 130-08-02 | Exact inventory/stable control/rollback record |
| Six legacy current-image evidence | 130-09-01, 130-06-01 | Human summary precedes atomic transcription/publication |
| Candidate generation, task discovery, and actual diff | 130-04-01 | Catalog/quality tests plus `mix rendro.catalog.candidate --invalid-option` prove the `mix.exs` compile wrapper and strict parser before any publication |
| Catalog threshold and reproduction closure | 130-10-01/02 | Mutation tests precede evidence projection and sole generation |

`wave_0_complete` becomes true only after all listed automated contracts are green. Human checkpoints remain evidence prerequisites, never substitutes. It is `true` at revision 2026-08-21: the separately authorized GSD quick fixes formatted the Phase 130-10 rubric contract and removed Phase-130 review-reconciliation Dialyzer warnings; final `mix ci.fast` passed with 1,839 tests, 0 failures, and Dialyzer 0 errors.

## Manual / External Evidence — Five Gates

| Order | Task | Why non-automated | Required evidence |
|---:|---|---|---|
| 1 | 130-07-02 | Golden baseline movement needs explicit authority | Exact two old/new SHA pairs and authorization |
| 2 | 130-08-01 | Exact pinned PDFium is externally supplied/triggered | Absolute binary or full-SHA CI ref/run/job/artifact provenance |
| 3 | 130-09-01 | Six changed light legacy images need current reauthorization | Six full-size decisions; no dark/brand inference |
| 4 | 130-04-02 | Pinned catalog candidate needs exact external identity | Full SHA/ref/run/pin and complete candidate/review artifacts |
| 5 | 130-05-01 | Catalog hierarchy/craft are bounded human judgments | Twelve full-size catalog records; every miss/dark stays needs_work |

## Closure Observation — 2026-08-21

### Current deterministic evidence

- Focused golden/launch/docs/theming/rubric contracts: pass, 119 tests.
- All six family structural, typography, and byte-identity suites: pass, 300 tests.
- `mix rendro.catalog.check`: `Catalog VERIFIED`; catalog/quality/rubric contracts: pass, 95 tests.
- Full deterministic suite: `mix test --exclude quarantine --slowest 10`: pass.
- Live identities: 32 catalog cells and 12 `review_status == "scored"` catalog dispositions; literal catalog order and current projection joins are covered by the catalog contracts.
- Current rubric contract preserves every dark row as `needs_work` with `print_safety: false`; no-theme bytes, safe paths, public API/dependency/package/catalog-membership boundaries remain under the passing suite/contract coverage.

### Advisory and human evidence remains separate

- Pinned launch raster execution is not runnable on this macOS host: `mix rendro.launch_artifacts.check --pdfium "$RENDRO_PHASE130_PDFIUM"` reports `{:missing_executable, "pdfium-cli"}`. No renderer was substituted. The accepted exact-SHA Linux PDFium advisory evidence is CI run `32434769523`, job `advisory-checks`, on `002d42adfec74a1f2fd2ba824d1623fb33c92891`; its pin install, canonical generation/check, launch check, and catalog check all passed.
- The exact two-golden authorization, pinned launch provenance, six-light launch review, pinned 32-cell candidate, and twelve-cell catalog review are retained in Plans 07/08/09/04/05 respectively. They are prerequisite evidence, not deterministic authority.

### Source, decision, UI, edge, and prohibition audit

Every Source Coverage Audit row in 130-11-PLAN.md maps to the completed task rows and the cited summaries above. CATALOG-06..09, D-01..D-26, all ten UI considerations (E1: overflow/long-text; E2: empty/loading/error/populated/overflow/long-text; E3: overflow/long-text), and all eleven spec-less probes are covered. The three plan prohibitions are proven: deterministic, advisory, and human lanes remain separate; no scope was widened; and every former red gate is now green.

### Closure transition

The prior formatting and Dialyzer gates were resolved through separately authorized, narrow GSD quick tasks, not by expanding Plan 130-11. Final `mix ci.fast` completed with 1,839 tests, 0 failures, and Dialyzer 0 errors. All mapped automated and human prerequisites are green; `nyquist_compliant` and `wave_0_complete` are therefore true. Exact provenance cleanup remains the final Task 2 operation and is recorded below after each literal target is removed.

### Exact cleanup record

- Verified then deleted remote candidate ref `gsd/phase-130-catalog-review-411cdcafa5d3090f3d0ec144c0cba59d991ba99f` only after `git ls-remote` returned the literal recorded SHA `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`.
- Verified then deleted remote canonical ref `gsd/phase-130-catalog-canonical-002d42adfec74a1f2fd2ba824d1623fb33c92891` only after `git ls-remote` returned the literal recorded SHA `002d42adfec74a1f2fd2ba824d1623fb33c92891`.
- Verified `tmp/phase130-launch-reconcile` at `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd` and proved each tracked difference belonged to the published `07e3fc8` launch batch; removed it with `git worktree remove --force tmp/phase130-launch-reconcile`.
- Verified both review inventories with `shasum -a 256 -c` before removing their literal manifest-enumerated files and empty directories. `tmp/phase130-candidate` was already absent and was not targeted for deletion.
- Final absence checks passed for the two refs and `tmp/phase130-launch-reconcile`, `tmp/phase130-candidate`, and `tmp/phase130-review`.

## Final Contract Checklist

- [x] Five blocking-human gates occurred in the exact order above.
- [x] Two authorized goldens pass assert-only.
- [x] Pinned launch gen/check is green in the accepted exact-SHA Linux CI lane; exactly ten PNGs changed and branded_invoice is stable.
- [x] Six launch records are current and distinct from the twelve catalog records.
- [x] The 130-06 patch is exactly 19 paths, one task, one commit, with whole-commit rollback.
- [x] Exactly one final canonical catalog generation occurred after catalog transcription.
- [x] Canonical 32-cell identities reproduce the candidate and all catalog checks pass.
- [x] All D-01..D-26, requirements, research constraints, ten UI states, and eleven edge probes are evidenced.
- [x] `mix ci.fast` is green (1,839 tests, 0 failures; Dialyzer 0 errors).
- [x] Temporary refs/paths are removed only after durable closure and literal identity checks.
- [x] `nyquist_compliant: true` and `wave_0_complete: true` are withheld until every 130-11 gate is green.

**Approval:** complete — final deterministic, advisory, human-evidence, and exact-cleanup closure recorded.

## Validation Audit — 2026-08-26

| Metric | Count |
|---|---:|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

- State A audit: the existing validation strategy, all eleven plans, and all eleven summaries were cross-referenced.
- CATALOG-06 through CATALOG-09 each retain behavior-targeted automated coverage; the bounded full-size human judgments and pinned-PDFium evidence remain explicitly separate from deterministic authority.
- Fresh deterministic closure: `mix ci.fast` passed with 12 doctests, 8 properties, 1,917 tests, 0 failures, and 28 excluded live/advisory tests; documentation, Credo, and Dialyzer also passed.
- Fresh catalog closure: `mix rendro.catalog.check` returned `Catalog VERIFIED`; live cardinality remains 32 catalog cells and 12 scored dispositions.
- No test files were generated because no requirement was classified PARTIAL or MISSING. Lifecycle metadata is now authoritative with `status: validated`.

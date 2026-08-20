---
phase: 130
slug: catalog-quality-evidence-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-19
revised: 2026-08-20
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
| 130-03-01 | 03 | 2 | CATALOG-09 | T-130-03A/C | Exact 12-image payload, separate 4-image multipage proof, complete identity | Pure payload contract | ⬜ pending |
| 130-03-02 | 03 | 2 | CATALOG-09 | T-130-03B/C | Full-40-SHA advisory route remains non-required | Required-checks contract | ⬜ pending |
| 130-07-01 | 07 | 3 | CATALOG-06,07,08 | T-130-07B/C | Exact-HEAD detached worktree and baseline fence | SHA equality + baseline + main diff fence | ⬜ pending |
| 130-07-02 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/C | Blocking exact two-golden authorization | Human authorize/reject exact four hashes | ⬜ pending |
| 130-07-03 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/B | Only authorized goldens blessed in staging | Focused golden + exact two-file diff | ⬜ pending |
| 130-08-01 | 08 | 4 | CATALOG-06,07,08 | T-130-08A/C | Blocking pinned PDFium path or exact-SHA CI action | Pin provenance + gen/check + focused contracts | ⬜ pending |
| 130-08-02 | 08 | 4 | CATALOG-06,07,08 | T-130-08B/C | Exact ten-change/stable-control staged diff and rollback | Diff JSON + launch checks + canonical fences | ⬜ pending |
| 130-09-01 | 09 | 5 | CATALOG-06,07,09 | T-130-09A/B/C | Blocking six-light full-size launch review, no binary ownership | Six complete current decisions or blocked marker | ⬜ pending |
| 130-04-01 | 04 | 6 | CATALOG-08,09 | T-130-04A/B/C/D | Fixed-target quality-free candidate seam and atomic cleanup | Catalog/quality contracts | ⬜ pending |
| 130-04-02 | 04 | 6 | CATALOG-08,09 | T-130-04A/D | Blocking exact-SHA pinned 32-cell candidate batch | Ref/run/pin + 32 candidate + 12 final + 4 multipage | ⬜ pending |
| 130-04-03 | 04 | 6 | CATALOG-08,09 | T-130-04A/B/C/D | Exact actual-diff partition and canonical unchanged | Family/catalog tests + jq partition | ⬜ pending |
| 130-05-01 | 05 | 7 | CATALOG-09 | T-130-05A/B/C | Blocking distinct twelve-cell full-size catalog review | Twelve complete records or blocked marker | ⬜ pending |
| 130-06-01 | 06 | 8 | CATALOG-06,07,08 | T-130-06A/B/C | One 19-path reviewed launch publication commit and whole-commit rollback | Exact inventory + focused contracts + clean fences | ⬜ pending |
| 130-10-01 | 10 | 9 | CATALOG-08,09 | T-130-10A/B | Exact catalog transcription and threshold/dark closure | 12 scored + mutation contracts | ⬜ pending |
| 130-10-02 | 10 | 9 | CATALOG-08,09 | T-130-10B/C | Sole canonical generation and 32-cell candidate reproduction | generation_count 1 + catalog check/contracts | ⬜ pending |
| 130-11-01 | 11 | 10 | CATALOG-06,07,08,09 | T-130-11A/C | Complete source/decision/UI/edge/prohibition and deterministic closure | Focused/full/ci.fast + live cardinalities | ⬜ pending |
| 130-11-02 | 11 | 10 | CATALOG-06,07,08,09 | T-130-11A/B | Exact ref/worktree/candidate cleanup after durable closure | Absence gates + Nyquist flags | ⬜ pending |

## Wave 0 Ownership

| Gap | Owning task | Proof created before behavior/publication |
|---|---|---|
| Candidate-driven twelve-image/multipage split | 130-03-01 | Untagged pure classifier contract |
| Full-SHA route and authority separation | 130-03-02 | Guardrail assertions precede workflow edit |
| Golden authorization and exact staging | 130-07-01/02/03 | Baseline and diff gates precede publication |
| Launch fail-closed staging | 130-08-02 | Exact inventory/stable control/rollback record |
| Six legacy current-image evidence | 130-09-01, 130-06-01 | Human summary precedes atomic transcription/publication |
| Candidate generation and actual diff | 130-04-01 | Catalog/quality tests precede dev-only seam |
| Catalog threshold and reproduction closure | 130-10-01/02 | Mutation tests precede evidence projection and sole generation |

`wave_0_complete` becomes true only after all listed automated contracts are green. Human checkpoints remain evidence prerequisites, never substitutes.

## Manual / External Evidence — Five Gates

| Order | Task | Why non-automated | Required evidence |
|---:|---|---|---|
| 1 | 130-07-02 | Golden baseline movement needs explicit authority | Exact two old/new SHA pairs and authorization |
| 2 | 130-08-01 | Exact pinned PDFium is externally supplied/triggered | Absolute binary or full-SHA CI ref/run/job/artifact provenance |
| 3 | 130-09-01 | Six changed light legacy images need current reauthorization | Six full-size decisions; no dark/brand inference |
| 4 | 130-04-02 | Pinned catalog candidate needs exact external identity | Full SHA/ref/run/pin and complete candidate/review artifacts |
| 5 | 130-05-01 | Catalog hierarchy/craft are bounded human judgments | Twelve full-size catalog records; every miss/dark stays needs_work |

## Final Contract Checklist

- [ ] Five blocking-human gates occurred in the exact order above.
- [ ] Two authorized goldens pass assert-only.
- [ ] Pinned launch gen/check is green; exactly ten PNGs changed and branded_invoice is stable.
- [ ] Six launch records are current and distinct from the twelve catalog records.
- [ ] The 130-06 patch is exactly 19 paths, one task, one commit, with whole-commit rollback.
- [ ] Exactly one final canonical catalog generation occurred after catalog transcription.
- [ ] Canonical 32-cell identities reproduce the candidate and all checks pass.
- [ ] All D-01..D-26, requirements, research constraints, ten UI states, eleven edge probes, and prohibitions are evidenced.
- [ ] Temporary refs/paths are removed only after durable closure.
- [ ] `nyquist_compliant: true` and `wave_0_complete: true` are set only after 130-11 evidence exists.

**Approval:** pending execution evidence

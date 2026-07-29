---
phase: 124-address-v2-11-tech-debt-stale-113-docs-contract-test-formatt
verified: 2026-07-29T02:10:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 124: Address v2.11 Tech Debt Verification Report

**Phase Goal:** Clear the three non-blocking v2.11 tech-debt items so `mix ci.fast` runs green end-to-end
WITHOUT changing any rendered output: (1) fix the stale `dx_local_reproducibility_claims_test.exs`, (2)
resolve formatter drift on ~7 files, (3) correct `Background.emit?/1`'s type contract so `mix dialyzer`
passes — preserving the byte-identity golden guard and leaving the locked Ticket visual-hierarchy
regression (WINDOWS id 2) untouched.

**Verified:** 2026-07-29T02:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

All evidence below was produced by commands run live in this verification session (not copied from
SUMMARY.md).

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix dialyzer` reports 0 errors (was 133 across 10 files), fixed via a single-file open-map `@spec` widening on `Background.emit?/1` (D-03) | VERIFIED | Live run: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` (`done in 0m3.08s`). `git show d16ebdf --stat`: 1 file changed (`lib/rendro/recipes/background.ex`, 4 insertions/2 deletions). `git show d16ebdf -- lib/rendro/recipes/background.ex` shows only the `@spec` hunk changed; `def emit?(%{background: bg}), do: bg != @paper_white` is byte-identical before/after. |
| 2 | `mix format --check-formatted` exits 0; the reformat touched exactly the 7 known WINDOWS-id-4 files and is formatting-only (D-02) | VERIFIED | Live run: `mix format --check-formatted` → exit 0. `git show f7beecb --stat`: exactly 7 files changed (`lib/rendro/launch_artifacts.ex`, `test/docs_contract/theme_industry_guard_test.exs`, `test/docs_contract/theming_claims_test.exs`, `test/rendro/recipes/{payslip_opts_threading,themed_render_smoke,certificate_typography,theme_mode_background_golden}_test.exs`), 47 insertions/17 deletions — matches RESEARCH.md's live-verified bounded-check exactly. Commit message documents whitespace/paren/wrap-only hunks; matches RESEARCH.md's line-by-line inspection. |
| 3 | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` reports 3 tests, 0 failures (was 5 tests, 2 failures); the 2 removed cases guarded only archived, deleted Phase-113 evidence (D-01) | VERIFIED | Live run: `3 tests, 0 failures`, no compiler warnings. `git show 98310da --stat`: 1 file changed, 7 insertions/46 deletions (the 2 test blocks + 3 module attributes removed). `.planning/phases/113-dx-local-reproducibility-validation/113-UAT.md` and `113-METRICS.md` confirmed absent (not resurrected). |
| 4 | The byte-identity/golden regression suite (9 files: 7 recipe `*_byte_identity_test.exs` + `table_byte_identity_test.exs` + `theme_mode_background_golden_test.exs`) shows 0 failures after the background.ex spec fix — the milestone's central regression guard (D-03/D-06) | VERIFIED | Live run of the full 9-file suite: `27 tests, 0 failures`. Matches RESEARCH.md's documented pre/post-fix baseline exactly (27 tests, 0 failures both before and after). |
| 5 | `mix ci.fast` runs green end-to-end across all 7 steps (format, hex.build, compile, test, docs, credo, dialyzer) (D-06) | VERIFIED | Live full run of `mix ci.fast`: format-check passed silently (step 1), compile clean, `12 doctests, 8 properties, 1697 tests, 0 failures (26 excluded)` (step 4), docs generated cleanly (step 5), `3159 mods/funs, found no issues` (credo, step 6), `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` (dialyzer, step 7). No shell error surfaced at any step; `git status --short` after the run is clean (no stray artifacts committed). |

**Score:** 5/5 truths verified (0 present-behavior-unverified)

### Prohibitions (must-NOT checks)

| # | Prohibition | Status | Evidence |
|---|-------------|--------|----------|
| 1 | MUST NOT change rendered output/PDF bytes for any recipe — byte-identity/golden suite MUST report identical failure count (0) before/after | VERIFIED (judgment, corroborated by live re-run) | `def emit?/1` body byte-identical (diff shows only the `@spec` type annotation changed, which has zero runtime effect — Dialyzer specs are compile-time-only static hints). Golden suite re-run live this session: 27 tests, 0 failures, matching RESEARCH.md's documented pre-fix baseline of 27/0. |
| 2 | MUST NOT touch `lib/rendro/recipes/ticket.ex` — WINDOWS id 2 is a LOCKED Phase-122 design outcome | VERIFIED | `git show d16ebdf --stat`, `git show f7beecb --stat`, `git show 98310da --stat` — none list `ticket.ex`. `git log --oneline -- lib/rendro/recipes/ticket.ex` shows its last touch was `d3908ed` (Phase 122-03), pre-dating this phase entirely. |
| 3 | MUST NOT create, restore, or write to any file under `.planning/phases/113-dx-local-reproducibility-validation/` | VERIFIED | `test ! -e .../113-UAT.md` and `test ! -e .../113-METRICS.md` both confirmed absent live. `git show 98310da --stat` touches only the docs-contract test file, nothing under `.planning/phases/113-*`. |
| 4 | MUST NOT let bare `mix format` touch any file outside the known bounded 7-file set (WINDOWS id 4) | VERIFIED | `git show f7beecb --stat` lists exactly 7 files, matching the plan's declared set verbatim (cross-checked path-for-path). |
| 5 | MUST NOT expand the dialyzer fix beyond `lib/rendro/recipes/background.ex` | VERIFIED | `git show d16ebdf --stat` shows exactly 1 file changed. `recipes.ex`, `launch_artifacts.ex` (logic), `ticket.ex`, `rendro.visual_uat.ex` are absent from that commit's diff. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/recipes/background.ex` | `@spec emit?/1` widened to open map type | VERIFIED | Diff confirmed spec-only change; substantive and correct per Dialyzer's own 0-error report. |
| `test/docs_contract/dx_local_reproducibility_claims_test.exs` | Reduced to 3 live cases | VERIFIED | 3 tests, 0 failures confirmed live; commit diff shows only deletions (+ comment) as claimed. |
| `lib/rendro/launch_artifacts.ex` | mix format whitespace-only | VERIFIED | In the bounded 7-file commit; part of `mix ci.fast`'s green docs/compile/test steps. |
| `test/docs_contract/theme_industry_guard_test.exs`, `theming_claims_test.exs`, `payslip_opts_threading_test.exs`, `themed_render_smoke_test.exs`, `certificate_typography_test.exs`, `theme_mode_background_golden_test.exs` | mix format whitespace-only | VERIFIED | All present in `f7beecb`'s 7-file diff; all pass under full `mix ci.fast` test run (1697 tests, 0 failures includes these). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `Background.emit?/1`'s `@spec` | All 14 call sites across 7 recipes' `palette(opts)`-derived colors maps | Widened open-map spec accepted by Dialyzer for every real caller shape | VERIFIED | `mix dialyzer` 0 errors confirms every one of the 133 original errors (spanning `statement.ex`, `ticket.ex`, `certificate.ex`, `branded_invoice.ex`, `invoice.ex`, `payslip.ex`, `receipt.ex`, `recipes.ex`, `launch_artifacts.ex`, `rendro.visual_uat.ex`) is now resolved by this single-file edit — the cascade is cleared end-to-end. |
| `dx_local_reproducibility_claims_test.exs`'s 3 surviving tests | `scripts/verify_docs.exs` / `.github/workflows/ci.yml` / README.md+CONTRIBUTING.md | Live docs-contract guarantees left untouched | VERIFIED | 3 tests pass; commit diff shows zero edits inside the 3 surviving test bodies (only the 2 stale blocks + 3 attributes removed). |

### Behavioral Spot-Checks / Commands Run Live This Session

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Dialyzer 0 errors | `mix dialyzer` | `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` | PASS |
| Formatter clean | `mix format --check-formatted` | exit 0 | PASS |
| Stale test fixed | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | `3 tests, 0 failures` | PASS |
| Byte-identity guard | 9-file golden suite | `27 tests, 0 failures` | PASS |
| Full CI gate | `mix ci.fast` | `12 doctests, 8 properties, 1697 tests, 0 failures`; credo `3159 mods/funs, found no issues`; dialyzer `Total errors: 0` | PASS |
| Scope fence — ticket.ex untouched | `git show <3 commits> --stat` + `git log -- lib/rendro/recipes/ticket.ex` | ticket.ex absent from all 3 commits; last touched by pre-124 commit `d3908ed` | PASS |
| Scope fence — no stray artifacts committed | `git status --short` post-`ci.fast` | clean (stray `rendro-*.tar` from `hex.build` present but untracked/gitignored, not committed) | PASS |
| WINDOWS ledger updated | `.planning/WINDOWS.md` frontmatter + rows 4/5/6 | `fixed_count: 3`; ids 4, 5, 6 status `fixed`; ids 1, 2, 3, 7 remain `open` (1/2/3 are separate pre-existing 123 gallery deviations out of this phase's scope; 2 is the locked Ticket regression; 7 is pdfium tooling) | PASS |

### Deferred Items (D-05 scope fence — confirmed not touched)

| Item | Status |
|------|--------|
| Ticket visual-hierarchy re-mapping (WINDOWS id 2) | Confirmed untouched — `ticket.ex` absent from all 3 commits |
| `pdfium-cli` install/PATH provisioning (WINDOWS id 7) | Confirmed still `open` in WINDOWS.md, no code change |
| Nyquist validation of 121/122/123 | Not touched by this phase's commits |
| `from_brand/2` byte-level E2E golden | No new golden file added; not in the 9-file changed-file set |
| SUMMARY frontmatter `requirements_completed` backfill | Not touched; explicitly noted as deferred in 124-01-SUMMARY.md |

All 3 commits (`d16ebdf`, `f7beecb`, `98310da`) plus the plan-completion commit (`f2e19a9`, which updates
`.planning/WINDOWS.md` and other tracking docs) together touch exactly: `background.ex`, the 7 formatter
files, the stale docs-contract test, and `.planning` tracking files — no deferred-scope files appear in any
of these diffs.

### Requirements Coverage

Phase 124 has no formal REQUIREMENTS.md REQ-IDs (maintenance phase per phase brief); D-01/D-02/D-03 are
CONTEXT.md decision IDs, cross-referenced against the plan's `must_haves` and this phase's success criteria
instead. All 3 decisions are SATISFIED per the Observable Truths table above.

| Decision | Description | Status | Evidence |
|----------|-------------|--------|----------|
| D-01 | Stale 113 docs-contract test fixed (delete, don't resurrect) | SATISFIED | Truth #3 |
| D-02 | Formatter drift resolved, bounded to 7 files, formatting-only | SATISFIED | Truth #2 |
| D-03 | Dialyzer type contract corrected, zero rendered-output change | SATISFIED | Truths #1, #4 |
| D-04 | Ticket visual hierarchy stays untouched | SATISFIED | Prohibition #2 |
| D-05 | Scope fence — only the 3 titled targets | SATISFIED | Deferred Items table |
| D-06 | `mix ci.fast` green end-to-end + byte-identity preserved | SATISFIED | Truth #5, Truth #4 |

### Anti-Patterns Found

None. Scanned all 9 modified files' commit diffs (via `git show --stat` per commit) — no `TBD`/`FIXME`/`XXX`
markers, no placeholder returns, no stub patterns introduced. The changes are a type-spec widening, a
`mix format` pass, and test-body deletions — none of which introduce new code bodies to scan for
anti-patterns.

### Human Verification Required

None. All 5 must-have truths and all 5 prohibitions were verified with direct, live command evidence
(re-run in this session, not copied from SUMMARY.md) plus `git show`/`git log` commit-diff inspection. The
byte-identity/golden guard — the one item most at risk of being a "trust the SUMMARY" claim — was
independently re-run live and matches RESEARCH.md's documented baseline exactly (27/27 both before and
after the fix, per RESEARCH.md; 27/27 confirmed again live in this verification session).

### Gaps Summary

None. All three tech-debt targets (D-01/D-02/D-03) are confirmeded closed with live evidence; the byte-identity
golden guard holds; the locked Ticket hierarchy regression (WINDOWS id 2) is confirmed untouched; the D-05
scope fence held (no deferred item was touched); `mix ci.fast` runs green end-to-end.

---

_Verified: 2026-07-29T02:10:00Z_
_Verifier: Claude (gsd-verifier)_

---
phase: 120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes
verified: 2026-07-27T22:45:00Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
---

# Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes — Verification Report

**Phase Goal:** Make every recipe fully themable by threading a resolved `theme:` through the 3-rung pattern — retrofitting the 4 un-seamed recipes (Statement/Certificate/Receipt/BrandedInvoice) byte-identically FIRST, then swapping all 7 to read `theme.colors.*` — while an un-themed call reproduces v2.10 bytes exactly.
**Verified:** 2026-07-27T22:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The 4 un-seamed recipes gain a byte-identical `palette/1` seam whose no-theme defaults equal today's exact literals (SC1, PLUMB-01) | ✓ VERIFIED | `statement.ex:347` nil-branch `surface {245,245,245}/rule {0,0,0}`; `certificate.ex:374` nil-branch `rule {34,34,34}` (non-black stress case); `receipt.ex:474` + `branded_invoice.ex:229` nil-branch `ink {0,0,0}`. 7 byte-identity tests + edge_matrix green (83 tests, 0 failures). |
| 2 | Certificate's retrofit default is the exact non-black `{34,34,34}` frame literal — NOT `{0,0,0}`, NOT the theme's rule (PLUMB-01, D-02) | ✓ VERIFIED | `certificate.ex:379` nil-branch `rule: {34,34,34}`; `resolve_frame_opts/8` reads `colors.rule`; `certificate_byte_identity_test.exs` includes a `border: true` case exercising the frame. |
| 3 | Retrofit committed SEPARATELY from theme swap (split-commit discipline) | ✓ VERIFIED | Retrofit commits 559ccb8, 9e1804c, cb4f342, d8907be contain 0 `Theme.resolve` reads; swap commits e064d67, adfae62, 10778ef add them. `git show 559ccb8:...statement.ex \| grep -c Theme.resolve` = 0; `e064d67` = 2. Retrofit commits chronologically precede swap. |
| 4 | Receipt + BrandedInvoice `page_template/1` whitelists fixed — `:palette`/`:theme` thread without KeyError (PLUMB-02 prep) | ✓ VERIFIED | Both use `Keyword.take([:name,:width,:height,:margin_*,:regions])` (`receipt.ex:184`, `branded_invoice.ex:98`), dropping `:theme`/`:palette`. Threading tests assert `%PageTemplate{} = <Recipe>.page_template(theme: ...)` — green. |
| 5 | All 7 recipes read `Rendro.Theme.resolve(theme).colors` via a `case opts[:theme]` branch; `Map.merge(base, :palette-override)` order keeps `:palette` winning (SC2, PLUMB-02, D-01) | ✓ VERIFIED | All 7 `palette/1` bodies show the identical `case opts[:theme] do nil -> literals; theme -> Rendro.Theme.resolve(theme).colors end` then `Map.merge(base, Keyword.get(opts,:palette,%{}))`. Threading tests assert `:palette` override wins over `:theme` — green. |
| 6 | A supplied `:theme` recolors output and threads all 3 rungs (`document/2`→`page_template/1`→`sections/2`) without KeyError (SC2, PLUMB-02) | ✓ VERIFIED | 7 `*_opts_threading_test.exs` (52 tests, 0 failures) assert themed `sections` differ from no-theme. End-to-end spot-check: `Receipt.document(data,theme:)` ≠ `Receipt.document(data)`; `BrandedInvoice.document(valid_data,theme:)` threads with no KeyError and recolors. |
| 7 | No inline `{r,g,b}` color literal remains in any recipe section builder; recipe layer is typography-free (SC2, PLUMB-02, D-04) | ✓ VERIFIED | `no_inline_color_literals_test.exs` (2 tests, 0 failures) — real color-context regex scan excluding `palette/1` bodies + comments, with documented teeth (Plan 04 injection test). Independent grep `(color\|fill\|stroke):\s*\{[0-9]` across all 7 = 0 matches. |
| 8 | `document(data)` with no `:theme` is a byte-identity no-op for all 7 recipes, reproducing v2.10 bytes with no re-bless (SC3, PLUMB-03 — central regression guard) | ✓ VERIFIED | 7 frozen sha256 byte-identity tests + `edge_matrix_test.exs` green (83 tests, 0 failures), no golden re-blessed. BrandedInvoice net-new golden `6b20ecc8…` closes the prior blind spot. |

**Score:** 8/8 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/rendro/recipes/statement.ex :: palette/1` | seam + theme branch, surface/rule defaults | ✓ VERIFIED | L347, nil-branch literals + theme branch |
| `lib/rendro/recipes/certificate.ex :: palette/1` | seam + theme branch, `{34,34,34}` default | ✓ VERIFIED | L374, `resolve_frame_opts/8` reads `colors.rule` |
| `lib/rendro/recipes/receipt.ex :: palette/1` + whitelist | ink seam + `Keyword.take` fix | ✓ VERIFIED | palette L474; take list L184 (no `:theme`/`:palette`) |
| `lib/rendro/recipes/branded_invoice.ex :: palette/1` + whitelist | ink seam + `Keyword.take` fix | ✓ VERIFIED | palette L229; take list L98 |
| `lib/rendro/recipes/{invoice,payslip,ticket}.ex :: palette/1` | existing seam + theme branch | ✓ VERIFIED | L468 / L680 / L512, swap-only theme branch |
| 7× `*_byte_identity_test.exs` | frozen sha256 goldens | ✓ VERIFIED | all present; 83 tests green, no re-bless |
| 7× `*_opts_threading_test.exs` | theme threads/recolors/override-wins/byte-id | ✓ VERIFIED | all present; 52 tests green |
| `no_inline_color_literals_test.exs` | phase-wide source-scan + typography-free guard | ✓ VERIFIED | present; 2 tests green, teeth proven |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| each `palette/1` | `Rendro.Theme.resolve(theme).colors` | `case opts[:theme]` theme branch | ✓ WIRED | present in all 7 recipes |
| `palette/1` base | `:palette` override | `Map.merge(base, Keyword.get(opts,:palette,%{}))` final layer | ✓ WIRED | override-wins tests green |
| `page_template/1` | `sections/2` → `palette/1` | `Keyword.take` drops `:theme`/`:palette` so they thread | ✓ WIRED | no-KeyError threading tests green |
| no-theme render | frozen `@toy_golden_sha256` + edge_matrix | deterministic render equality | ✓ WIRED | 83 byte-identity/matrix tests green |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| 7 byte-identity + edge_matrix (PLUMB-03) | `mix test *_byte_identity_test.exs edge_matrix_test.exs` | 83 tests, 0 failures | ✓ PASS |
| 7 opts-threading + source-scan (PLUMB-02) | `mix test *_opts_threading_test.exs no_inline_color_literals_test.exs` | 52 tests, 0 failures | ✓ PASS |
| `Receipt.document(data,theme:)` recolors vs no-theme (3-rung) | `mix run` e2e | `no_theme == themed? false` | ✓ PASS |
| `BrandedInvoice.document(valid,theme:)` threads without KeyError | `mix run` e2e | OK, recolors (`false`) | ✓ PASS |
| Retrofit commits contain no theme reads | `git show <retrofit>:… \| grep -c Theme.resolve` | 0 (retrofit) / 2 (swap) | ✓ PASS |
| Full suite | `mix test` | 1636 tests, 2 failures (both pre-existing, unrelated) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PLUMB-01 | 120-01, 120-02 | 4 un-seamed recipes retrofitted byte-identically, separate commits | ✓ SATISFIED | Truths 1–3; split-commit git evidence |
| PLUMB-02 | 120-01/02/03/04 | All 7 thread resolved `theme:` through 3 rungs, read `theme.colors.*` by role, whitelist admits `:theme` | ✓ SATISFIED | Truths 4–7; typography deferred to Phase 122 (D-04) — REQUIREMENTS marks complete |
| PLUMB-03 | all | No-theme call byte-identity no-op for all 7 | ✓ SATISFIED | Truth 8; 83 byte-identity/matrix tests green, no re-bless |

All 3 requirement IDs from PLAN frontmatter are declared in REQUIREMENTS.md and marked `[x] Complete`. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No inline color literals, stubs, debt markers, or empty impls in phase-modified files | ℹ️ Info | None. Source-scan test permanently guards. |

### Notes on Scope / Nuance

- **SC2 wording "whitelist admits `:theme`":** The intentional design (and an explicit plan prohibition) DROPS `:theme`/`:palette` from each `page_template/1` `Keyword.take` list so they thread to `palette/1` instead of reaching `struct!/2`. The ROADMAP's "admits `:theme`" is satisfied in intent — the recipe accepts `:theme` without crashing, proven by the no-KeyError threading tests. Not a gap.
- **Typography (PLUMB-02 mentions `theme.typography.*`):** Deliberately out of Phase-120 scope (D-04 colors-only; Phase 122 owns type-scale). Enforced by the typography-free assertion in `no_inline_color_literals_test.exs`. REQUIREMENTS.md marks PLUMB-02 complete for Phase 120.
- **WR-01 (code review):** Statement closing-balance band text may be invisible under a *future* dark theme. Per phase scope, dark/themed-path legibility is Phase 121/122 work (background-fill mechanism). Recorded as forward-looking debt, NOT a Phase 120 gap — Phase 120 proves threading + byte-identity only.
- **2 full-suite failures** in `test/docs_contract/dx_local_reproducibility_claims_test.exs:77,103` are pre-existing (missing Phase 113 archived artifacts), fail on the base commit, and are unrelated to Phase 120.

### Human Verification Required

None. All success criteria are machine-verifiable (byte-identity goldens, threading tests, split-commit git history) and were verified green. No visual/runtime-legibility item is in Phase-120 scope.

### Gaps Summary

No gaps. All 3 ROADMAP success criteria, all 8 must-have truths, all artifacts, and all key links are verified against the codebase. The retrofit→swap split-commit discipline holds (retrofit commits contain zero theme reads), the no-theme path is byte-identical across all 7 recipes with no golden re-bless (PLUMB-03), all 7 recipes thread `theme.colors.*` through the 3-rung pattern with `:palette` override precedence intact (PLUMB-02), and the 4 un-seamed recipes carry byte-identical `palette/1` seams with per-recipe literal defaults including Certificate's non-black `{34,34,34}` stress case (PLUMB-01). Phase goal achieved.

---

_Verified: 2026-07-27T22:45:00Z_
_Verifier: Claude (gsd-verifier)_

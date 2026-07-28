---
phase: 121-light-dark-background-fill-mechanism-all-7-recipes
plan: 01
subsystem: recipes
tags: [elixir, pdf, theme, dark-mode, statement, background-fill, tdd-golden]

# Dependency graph
requires:
  - phase: 120-s1-retrofit-theme-swap-7-recipes
    provides: "palette/1 seam retrofitted (byte-identical) + theme: swap wired in all 7 recipes"
  - phase: 119-rendro-theme-core-module
    provides: "Rendro.Theme.resolve/1, Rendro.Theme.dark/1, integer {r,g,b} color roles"
provides:
  - "Rendro.Recipes.Background (emit?/1, region/2, section/3) — single source of truth for the :background full-page fill"
  - "Statement fully text-seamed (D-01/D-02): header, closing summary, body/CF/BF table cells, footer page number all read colors.* roles"
  - "Statement palette/1 nil-branch completed (ink/muted/background) — byte-identical no-theme path"
  - "Statement dark-mode background wiring: :background region + section prepended first, gated on Background.emit?(palette(opts))"
  - "test/rendro/recipes/theme_mode_background_golden_test.exs — the phase's shared dark-mechanism golden/structural test, to be extended by 121-02/03"
  - "priv/goldens/statement/dark.sha256 — blessed Statement dark golden"
affects: [121-02-certificate, 121-03-remaining-5-recipes, 121-04-docs-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Background helper pattern: emit?/1 exact-tuple sentinel (no tolerance) + region/2 (fixed, full-page, dims as args) + section/3 (Rendro.path/2 full-page fill) — the D-10 shape every remaining recipe wires against"
    - "Dual-gate invariant: page_template/1 and sections/2 both call Background.emit?(palette(opts)) on the SAME palette(opts) so region and section can never disagree (Pitfall 3)"
    - "cell_text/2 helper wraps table cells in a sized+colored Rendro.Text, fed identically into both Rendro.measure_rows and Rendro.table so color never perturbs measurement (Pitfall 1)"

key-files:
  created:
    - lib/rendro/recipes/background.ex
    - test/rendro/recipes/theme_mode_background_golden_test.exs
    - priv/goldens/statement/dark.sha256
  modified:
    - lib/rendro/recipes/statement.ex

key-decisions:
  - "emit?/1 uses exact integer-tuple inequality against paper-white {255,255,255} — no near-white tolerance (D-06), matching theme.ex's default/dark color poles directly"
  - "Statement cell_text/2 uses size: 12 (not Payslip's size: 11) — the implicit Rendro.Text default a plain-string cell already normalized to, preserving byte-identical measurement/chunking on the light path"
  - "Dark-mode golden test asserts fill-op precedence via raw byte offset (:binary.match on the whole PDF) rather than per-page stream splitting — page-1 content always serializes before later pages (object-number sort), so first-occurrence-offset comparison against the first BT is equivalent and far simpler"
  - "Forced-overflow fill-op count assertion also runs on the whole-binary occurrence count (mirrors flow_test.exs's established /Type /Page + repeated-Tj-per-page idiom) rather than isolating streams"

patterns-established:
  - "Tracer feedback gate: after Task 1 (tracer), re-ran the tracer's <verify> before starting Task 2's expansion (dark golden authoring) — passed, so expansion proceeded without a checkpoint"

requirements-completed: [MODE-01, MODE-02]

coverage:
  - id: D1
    description: "Rendro.Recipes.Background helper (emit?/1, region/2, section/3) is the single source of truth for the :background region"
    requirement: MODE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs — no recipe section builder inlines a literal {r,g,b} color tuple (PLUMB-02)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Statement dark render paints the full-page :background fill as the FIRST content op on page 1 and on every page of a forced-overflow render"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(b) dark page 1: background fill is the first content op"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(c) forced-overflow: fill op present on EVERY page"
        status: pass
    human_judgment: false
  - id: D3
    description: "Statement no-theme render emits zero background ops and stays byte-identical to v2.10"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/statement_byte_identity_test.exs — fresh render sha256 matches the frozen pre-seam retrofit baseline"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(a) light/no-theme: zero background ops, byte-identical"
        status: pass
    human_judgment: false
  - id: D4
    description: "Statement text seams read swappable colors.* roles at every draw-site (header, closing summary, body/CF/BF cells, footer)"
    requirement: MODE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs"
        status: pass
      - kind: other
        ref: "grep -c 'size: 11' lib/rendro/recipes/statement.ex == 0 (acceptance criterion, verified manually during execution)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-27
status: complete
---

# Phase 121 Plan 01: Background Helper + Statement Dark Wiring Summary

**Rendro.Recipes.Background (emit?/region/section) created and wired end-to-end into Statement — full-page dark-mode fill paints first on every page, blessed by a new structural golden test, with the no-theme path staying byte-identical to v2.10.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-28T00:00:00Z (approx)
- **Completed:** 2026-07-28T00:25:04Z
- **Tasks:** 2
- **Files modified:** 4 (1 created helper, 1 created test, 1 blessed golden ref, 1 edited recipe)

## Accomplishments
- Created `Rendro.Recipes.Background` — `emit?/1` (exact paper-white sentinel, D-06), `region/2` (fixed full-page region, dims always caller-supplied), `section/3` (full-page fill block via `Rendro.path/2`) — the single source of truth every remaining recipe (121-02, 121-03) will wire against (D-10)
- Completed Statement's `palette/1` nil-branch with `ink`/`muted`/`background` neutral literals (D-03), keeping the existing `surface`/`rule` band literals untouched
- Text-seamed every Statement draw-site (D-01/D-02): account name, period, opening balance, closing-balance label/value, and the footer page number now read `colors.ink`/`colors.muted`
- Introduced `cell_text/2` (size 12) and rewired body rows + brought-forward/carried-forward rows through it, so table cells are colored without perturbing measurement/chunking (Pitfall 1)
- Wired `page_template/1` + `sections/2` to prepend the `:background` region/section first, both gated on the identical `Background.emit?(palette(opts))` predicate (Pitfall 3)
- Authored `theme_mode_background_golden_test.exs` (RED → GREEN TDD cycle) proving: (a) light path emits zero background ops and stays deterministic, (b) dark page-1 fill precedes the first `BT` text token, (c) forced-overflow fill-op count equals page count, (d) dark renders are deterministic and match the newly blessed `priv/goldens/statement/dark.sha256`
- Confirmed the tracer feedback gate: re-ran Task 1's `<verify>` before starting Task 2's golden-test expansion — passed, so execution proceeded without a checkpoint

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Rendro.Recipes.Background helper + wire Statement end-to-end** - `61aebee` (feat)
2. **Task 2 (RED): Author the failing dark-mode background golden test** - `28a2d4d` (test)
3. **Task 2 (GREEN): Bless the Statement dark background golden** - `a6accb8` (feat)

**Pre-task fix (unrelated blocker):** `0ee0c00` (chore) — resolved stale unresolved git index conflict entries left from a prior, unrelated session that were blocking ALL commits in the repo (see Deviations below).

_Note: Task 2 followed the plan-mandated `tdd="true"` RED/GREEN cycle (test commit, then a separate bless commit) rather than a single combined commit._

## Files Created/Modified
- `lib/rendro/recipes/background.ex` - New shared helper: `emit?/1`, `region/2`, `section/3`
- `lib/rendro/recipes/statement.ex` - `palette/1` nil-branch completed, all text draw-sites seamed, `cell_text/2` added, `page_template/1`/`sections/2` wired to prepend the background region/section
- `test/rendro/recipes/theme_mode_background_golden_test.exs` - New dark-mechanism golden + structural op-order test (4 cases a-d)
- `priv/goldens/statement/dark.sha256` - Newly blessed Statement dark golden (1-line hash)

## Decisions Made
- Compared fill-op precedence and per-page occurrence count against the WHOLE raw PDF binary (not isolated per-page content streams) — page objects serialize in ascending object-number order which matches page order, so a whole-binary first-occurrence-offset / occurrence-count comparison is equivalent to a per-page check and matches the established `flow_test.exs` idiom (`/Type /Page` count + repeated-text-per-page occurrence counting)
- Kept Statement's existing `surface`/`rule` band literals in `palette/1`'s nil-branch unchanged (they are Statement's own band literals, not `Rendro.Theme`'s default `surface`/`rule` — changing them would have broken byte-identity)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved stale unresolved git index conflict entries**
- **Found during:** attempting the Task 1 commit
- **Issue:** Three files (`110-01-PLAN.md`, `111-01-PLAN.md`, `111-02-PLAN.md`) were left in an unresolved-conflict index state from an earlier, unrelated session (no active merge/rebase in progress — `MERGE_HEAD` absent). This blocked ALL commits in the repository, including this plan's task commits.
- **Fix:** Verified the working-tree content for all three files already exactly matched the conflict's "theirs" (stage 3) side — a zero-content-change resolution — then `git add`'d them to clear the stale index stages.
- **Files modified:** `.planning/phases/110-test-concurrency-determinism-cleanup/110-01-PLAN.md`, `.planning/phases/111-workflow-topology-triggers-matrix/111-01-PLAN.md`, `.planning/phases/111-workflow-topology-triggers-matrix/111-02-PLAN.md`
- **Verification:** `diff` confirmed byte-identical to stage 3 before staging; `git status` showed a clean index after.
- **Committed in:** `0ee0c00` (separate commit, kept out of the Task 1 feature commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to unblock any commit in the repo; zero content risk (working tree already matched the correct side). No scope creep into this plan's actual deliverables.

## Issues Encountered
- `mix test` (full suite) surfaced 2 pre-existing, unrelated failures in `test/docs_contract/dx_local_reproducibility_claims_test.exs` (missing `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md` and `113-UAT.md`). Confirmed via `git stash -u` against the pre-plan HEAD that these files are absent independent of any change in this plan — out of scope (SCOPE BOUNDARY) and logged to `.planning/phases/121-light-dark-background-fill-mechanism-all-7-recipes/deferred-items.md`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Rendro.Recipes.Background` is ready for 121-02 (Certificate) and 121-03 (remaining 5 recipes) to wire against, following the exact `page_template/1`/`sections/2` prepend shape established here.
- `theme_mode_background_golden_test.exs` is the shared file 121-02 will extend with Certificate's dark-mechanism cases.
- No blockers.

---
*Phase: 121-light-dark-background-fill-mechanism-all-7-recipes*
*Completed: 2026-07-27*

## Self-Check: PASSED

All created files found on disk; all 4 commits (`61aebee`, `28a2d4d`, `a6accb8`, `0ee0c00`) found in git log.

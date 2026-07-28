---
phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
plan: 04
subsystem: docs
tags: [elixir, exdoc, docs-contract, theme, from_brand, support-matrix, hex-package]

requires:
  - phase: 119-rendro-theme-core-module-the-one-way-door
    provides: "Rendro.Theme.from_brand/2 + on_accent WCAG-contrast derivation (public adapter tier)"
  - phase: 123-03 (gallery closure)
    provides: "11-row assets/rendro/artifacts.json gallery manifest with blessed png_sha256/source_pdf_sha256"
provides:
  - "guides/theming.md: 3 executable # docs-contract: fences proving from_brand/2 end-to-end (accent coercion, on_accent both-ways, brand/theme orthogonality)"
  - "test/docs_contract/theming_contract_test.exs: the from_brand/2 E2E gate"
  - "Flipped guides/theming.md existence guard + proof-backed theming.light capability keys in priv/support_matrix.json"
  - "SHA drift guard binding guides/theming.md's gallery block to assets/rendro/artifacts.json"
affects: [123-05, future-theming-docs-phases]

tech-stack:
  added: []
  patterns:
    - "Guide fence IS the E2E test (D-04): no standalone integration test for from_brand/2, only the executable # docs-contract: fences in guides/theming.md"
    - "skip_code_autolink_to accepts MFA strings (Module.function/arity), not just module names, to suppress ExDoc 'references hidden function' warnings"

key-files:
  created:
    - guides/theming.md
    - test/docs_contract/theming_contract_test.exs
  modified:
    - mix.exs
    - test/docs_contract/theming_claims_test.exs
    - priv/support_matrix.json
    - test/rendro/launch_artifacts_test.exs

key-decisions:
  - "guides/theming.md ships via the existing `guides` package.files glob -- no package.files edit needed or made"
  - "New theming.light capability keys (from_brand_accent_seed, on_accent_readable_default, brand_theme_orthogonal) added rather than reusing a boundary key, keeping the overclaim tripwire's boundary-key set untouched"

requirements-completed: [CONTRACT-02, DEFAULT-01]

coverage:
  - id: D1
    description: "guides/theming.md ships 3 in-memory executable # docs-contract: fences (theming-accent-only, theming-accent-contrast-both-ways, theming-brand-orthogonal) proving from_brand/2 end-to-end"
    requirement: "DEFAULT-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_contract_test.exs#guides/theming.md ships exactly the three expected verified fence IDs in order"
        status: pass
      - kind: unit
        ref: "test/docs_contract/theming_contract_test.exs#every guides/theming.md fence body is evaluable and free of skeleton placeholders"
        status: pass
    human_judgment: false
  - id: D2
    description: "Honest on_accent wording (readable default, not WCAG-AA/PDF-UA, overridable) sits next to every derivation claim; every new theming claim binds to a proof-backed support_matrix.json capability with no overclaim"
    requirement: "CONTRACT-02"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#every new from_brand/theming claim the guide makes has a proof-backed theming.light capability"
        status: pass
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#the guide's honest on_accent wording is present next to the derivation claims"
        status: pass
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#no theming row carries a print/PDF-UA/WCAG support term (overclaim tripwire)"
        status: pass
    human_judgment: false
  - id: D3
    description: "guides/theming.md guard flipped (file must now exist), SHA drift guard added, and the Hex-tarball lane stays green with the 4 gallery PNGs + guide shipping while priv/quality, support_matrix.json, and the rubric schema stay excluded"
    requirement: "CONTRACT-02"
    verification:
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#guides/theming.md exists (CONTRACT-02)"
        status: pass
      - kind: unit
        ref: "test/docs_contract/theming_claims_test.exs#every gallery png_sha256 appears in guides/theming.md"
        status: pass
      - kind: unit
        ref: "test/docs_contract/branding_claims_test.exs#hex tarball contents"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-28
status: complete
---

# Phase 123 Plan 04: from_brand/2 E2E via executable guide fences Summary

**`guides/theming.md` ships 3 in-memory `# docs-contract:` fences that ARE the from_brand/2 end-to-end test (accent coercion, on_accent both-ways derivation, brand/theme orthogonality), every new theming claim binds to a proof-backed `support_matrix.json` capability with no overclaim, and the docs + Hex-tarball lanes stay green.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-07-28T19:42:48Z
- **Completed:** 2026-07-28T19:56:14Z
- **Tasks:** 3 completed
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments

- Authored `guides/theming.md`: 3 verified `elixir` fences in exact order (`theming-accent-only`, `theming-accent-contrast-both-ways`, `theming-brand-orthogonal`), each pure in-memory (no `File.write`/`System.cmd`/`Mix.Task.run`), proving `from_brand(accent: "#0E7C76")` → `colors.accent == {14,124,118}` / `on_accent == {255,255,255}` (white), `from_brand(accent: "#E6B450")` → `on_accent == {16,24,39}` (ink), and `BrandedInvoice.document/2` registering `data.brand` assets while `theme:` supplies the accent orthogonally
- Honest wording ("readable default", explicitly NOT a WCAG-AA/PDF-UA guarantee, overridable via `on_accent:`) sits next to every derivation claim; a third-party hex (`#7A2E8F`) appears only in teaching prose, never a grounded fence
- 11-row gallery table with every `source_pdf_sha256` + `png_sha256` copied verbatim from `assets/rendro/artifacts.json`
- Wired `guides/theming.md` into `mix.exs` docs `extras`/`groups_for_extras`/`skip_undefined_reference_warnings_on` without touching `package.files` (it ships via the existing `guides` glob)
- Added `test/docs_contract/theming_contract_test.exs` mirroring `branding_contract_test.exs` — asserts the 3 fence ids in order, `length == 3`, no skeleton placeholders, and executes each fence (the from_brand/2 E2E gate, D-04: no separate standalone integration test)
- Flipped `theming_claims_test.exs`'s `guides/theming.md` non-existence guard to an existence assertion, dropping the "deferred to Phase 123" wording
- Added 3 proof-backed `theming.light` capability keys to `priv/support_matrix.json` (`from_brand_accent_seed`, `on_accent_readable_default`, `brand_theme_orthogonal`, all `"supported"`, none an overclaim term) plus tests binding each to the guide's claims and asserting the honest wording is present
- Added a SHA drift guard: every `assets/rendro/artifacts.json` gallery `png_sha256` must appear in `guides/theming.md`, so the guide's SHA block can never silently drift from the manifest
- Verified the overclaim tripwire stays green and the Hex-tarball lane (`branding_claims_test.exs`) still ships the 4 gallery PNGs + `guides/theming.md` while excluding `priv/quality/`, `priv/support_matrix.json`, and `priv/schemas/rubric_scores.schema.json`

## Task Commits

Each task was committed atomically:

1. **Task 1: Author guides/theming.md + wire mix.exs docs** - `ae6eb2a` (feat)
2. **Task 2: Add theming_contract_test.exs (from_brand E2E gate)** - `b161772` (test)
3. **Task 3: Flip theming.md guard, bind claims to proof, verify tarball lane** - `814e1df` (feat)

_Note: Task 3's commit also includes a Rule 1 fix to a pre-existing, out-of-plan test file — see Deviations below._

## Files Created/Modified

- `guides/theming.md` - New guide: from_brand/2 accent-only + both-ways contrast fences, brand/theme orthogonality fence, honest on_accent wording, 11-row SHA gallery block
- `mix.exs` - Wired `guides/theming.md` into docs `extras`/`groups_for_extras`/`skip_undefined_reference_warnings_on`; added `Rendro.Color.validate/1` to `skip_code_autolink_to` (pre-existing bug fix, see Deviations); `package.files` untouched
- `test/docs_contract/theming_contract_test.exs` - New: fence-id-order + evaluate! test, the from_brand/2 E2E gate
- `test/docs_contract/theming_claims_test.exs` - Flipped the `guides/theming.md` guard; added proof-backed capability-binding tests + SHA drift guard
- `priv/support_matrix.json` - Added `from_brand_accent_seed`/`on_accent_readable_default`/`brand_theme_orthogonal` capability keys under `theming.light`
- `test/rendro/launch_artifacts_test.exs` - Updated a stale "exactly seven" gallery-id assertion to the 11 blessed ids (Rule 1 fix, see Deviations)

## Decisions Made

- Ship `guides/theming.md` through the already-allowlisted `guides` package.files glob rather than editing `package.files` — matches Pitfall 3's guidance that the tarball nuance is "no new runtime asset," not "no new file at all"
- Add new `theming.light` capability keys rather than repurposing an existing boundary key, so the overclaim tripwire's boundary-key set (`print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim`) stays exactly as Phase 121 defined it
- The orthogonality fence asserts `from_brand(...)` alone returns a bare `%Rendro.Theme{}` with no `font_registry`/`asset_registry` field (rather than re-deriving the WCAG math), matching the "assert the derived tuple, not the algorithm" guidance from RESEARCH.md's Don't-Hand-Roll table

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix docs --warnings-as-errors` was already broken on HEAD before this plan started**
- **Found during:** Task 1 (running the plan's own `<verify>` command)
- **Issue:** `lib/rendro/theme.ex`'s `resolve/1` `@doc` references `` `Rendro.Color.validate/1` ``, and `Rendro.Color` carries `@moduledoc false` (hidden). ExDoc flags this as "documentation references function ... but it is hidden," failing `--warnings-as-errors`. Confirmed via a clean worktree + `mix deps.get` rebuild that this predates Plan 04 entirely (traces to the Phase-119 commit that introduced `theme.ex`) — `main` was already red on this required `ci.fast` step.
- **Fix:** Added `"Rendro.Color.validate/1"` to `mix.exs`'s `skip_code_autolink_to` list — the exact established pattern already used for `Rendro.Format`/`Rendro.PDF.CidFont`/`Rendro.PDF.FontSubsetter` (all hidden modules referenced from public docs).
- **Files modified:** `mix.exs`
- **Verification:** `rm -rf doc && MIX_ENV=dev mix docs --warnings-as-errors` exits 0 with a clean rebuild
- **Committed in:** `ae6eb2a` (Task 1 commit)

**2. [Rule 1 - Bug] Stale "exactly seven" gallery-tile assertion in `test/rendro/launch_artifacts_test.exs`**
- **Found during:** Task 3 (running the full test suite to confirm the tarball/gallery lane stays green)
- **Issue:** Plan 123-03 updated the sibling `test/docs_contract/launch_artifacts_claims_test.exs` assertion from 7 to the 11 blessed gallery ids, but missed this second, non-docs_contract test (`Rendro.LaunchArtifacts.gallery_specs()` directly), which still asserted exactly the original 7 ids — a false claim about the shipped 11-row gallery.
- **Fix:** Updated the expected id list to the 11 blessed ids (same order as the docs_contract sibling) and renamed the test description from "seven" to "eleven."
- **Files modified:** `test/rendro/launch_artifacts_test.exs`
- **Verification:** `mix test test/rendro/launch_artifacts_test.exs` — 12 tests, 0 failures; full suite `mix test --exclude quarantine` now shows only the 2 known pre-existing Phase-113 archived-artifact failures (unrelated, fail on the base commit too)
- **Committed in:** `814e1df` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were necessary to make this plan's own `<verify>` commands (and the phase's "docs + Hex-tarball lanes stay green" success criterion) honestly pass. Neither touched engine/pipeline code or widened scope beyond docs/test/manifest closure.

## Issues Encountered

None beyond the two auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CONTRACT-02 and DEFAULT-01 are both closed: `from_brand/2` is proven end-to-end by executable guide fences, and every public theming claim binds to `priv/support_matrix.json` proof with no overclaim
- `mix docs --warnings-as-errors`, `mix test test/docs_contract/theming_contract_test.exs`, `mix test test/docs_contract/theming_claims_test.exs`, and `mix test test/docs_contract/branding_claims_test.exs` all green
- Full suite (`mix test --exclude quarantine`): 1698 tests, 2 failures (both pre-existing, unrelated Phase-113 `dx_local_reproducibility_claims_test.exs` archived-artifact failures)
- Ready for Plan 05 (the phase's final closure plan) — no blockers surfaced

---
*Phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani*
*Completed: 2026-07-28*

## Self-Check: PASSED

All created/modified files verified present on disk; all 3 task commit hashes (`ae6eb2a`, `b161772`, `814e1df`) verified present in git log.

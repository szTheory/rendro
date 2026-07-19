---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
plan: 02
subsystem: api
tags: [public-api, semver, docs-contract, moduledoc, adapter-tier]

requires:
  - phase: 115-01
    provides: "Byte-identity goldens (INV-01, INV-05) confirming pristine pre-Phase-115 render output"
provides:
  - "Rendro.Format promoted from @moduledoc false to the public adapter/Evolving tier (money/1, date/1, label/1)"
  - "priv/public_api.json regenerated with an Elixir.Rendro.Format adapter entry"
  - "Both hidden-module contract checks (public_api_contract_test.exs and manifest_test.exs) updated to reflect the promotion"
affects: [115-04]

tech-stack:
  added: []
  patterns:
    - "Adapter-tier moduledoc shape: @moduledoc \"\"\"...\"\"\" followed by @moduledoc tags: [:adapter], with a migration note + explicit stability caveat for previously-internal modules being promoted"

key-files:
  created: []
  modified:
    - lib/rendro/format.ex
    - lib/mix/tasks/rendro/api.gen.ex
    - test/docs_contract/public_api_contract_test.exs
    - priv/public_api.json
    - test/rendro/public_api/manifest_test.exs

key-decisions:
  - "Tasks 1 and 2 were staged separately but committed together as one atomic commit (per the plan's explicit ATOMICITY instruction) so the contract lane never observes a red intermediate state."
  - "Discovered and fixed a second, plan-unlisted hidden-modules assertion in test/rendro/public_api/manifest_test.exs (Rule 3 — blocking issue caused directly by this task's change) in a separate follow-up commit."

requirements-completed: [INV-04]

coverage:
  - id: D1
    description: "Rendro.Format reports the adapter tier (not :hidden) via @moduledoc tags: [:adapter], with unchanged money/1, date/1, label/1 bodies and @specs"
    requirement: "INV-04"
    verification:
      - kind: unit
        ref: "test/rendro/format_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rendro.Format appears in priv/public_api.json with functions date/1, label/1, money/1 at tier adapter, and the public-API contract lane (including the Phase-79 hidden set) passes green"
    requirement: "INV-04"
    verification:
      - kind: unit
        ref: "test/docs_contract/public_api_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/rendro/public_api/manifest_test.exs"
        status: pass
      - kind: other
        ref: "mix rendro.api.gen && git diff --exit-code priv/public_api.json"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rendro.Format docs carry a migration note and an explicit \"output may evolve\" caveat"
    requirement: "INV-04"
    verification:
      - kind: unit
        ref: "lib/rendro/format.ex moduledoc (manual review)"
        status: pass
    human_judgment: false

duration: ~4min
completed: 2026-07-18
status: complete
---

# Phase 115 Plan 02: Rendro.Format Public Promotion Summary

**Flipped `Rendro.Format` from `@moduledoc false` to the public adapter/Evolving tier in one atomic commit — the milestone's single irreversible act (INV-04) — regenerating `priv/public_api.json` and fixing two independent hidden-module contract checks so the lane stays green.**

## Performance

- **Duration:** ~4 min
- **Completed:** 2026-07-18T18:11:47Z
- **Tasks:** 2 completed
- **Files modified:** 5 (4 planned + 1 discovered)

## Accomplishments
- Replaced `@moduledoc false` in `lib/rendro/format.ex` with a real moduledoc (pure/locale-free/deterministic description, migration note, "output may evolve" stability caveat) plus `@moduledoc tags: [:adapter]`, mirroring the two-attribute pattern in `receipt.ex`. `money/1`, `date/1`, `label/1` bodies and `@spec`s untouched.
- Registered `Rendro.Format` in `api.gen.ex`'s Adapter-tier `@public_modules` block (alphabetical neighbor of `Rendro.Inspector`).
- Removed `Rendro.Format` from `public_api_contract_test.exs`'s `hidden_modules` list.
- Regenerated `priv/public_api.json` via `mix rendro.api.gen`; the new `Elixir.Rendro.Format` entry has `functions: ["date/1", "label/1", "money/1"]`, `tier: "adapter"`, `types: []`. `git diff --exit-code priv/public_api.json` is clean after regeneration (committed manifest matches generator output byte-for-byte).
- All four planned artifacts landed in a single atomic commit (`83d356c`) per the plan's explicit atomicity requirement — the contract lane never observed a red intermediate state.
- Discovered a second, plan-unlisted duplicate hidden-modules assertion in `test/rendro/public_api/manifest_test.exs` (independent of the Phase-79 lane) that also expected `Elixir.Rendro.Format` absent from the manifest; fixed in a follow-up commit (`d24b37c`).
- Full `mix test` suite: 1236 tests, 0 failures (was 1 failure before the manifest_test.exs fix).

## Task Commits

Each task was committed atomically per the plan's ATOMICITY instruction (Tasks 1+2 as one commit unit):

1. **Task 1 + Task 2: Flip Rendro.Format to public adapter tier + register/deregister/regenerate manifest (atomic)** - `83d356c` (feat)
2. **Deviation fix: second hidden-modules check** - `d24b37c` (fix)

_Note: Task 1 was staged (`git add`) without a standalone commit as instructed, then committed together with Task 2's changes in `83d356c`._

## Files Created/Modified
- `lib/rendro/format.ex` - `@moduledoc false` → real moduledoc + `@moduledoc tags: [:adapter]`; migration note + "output may evolve" caveat added; functions unchanged.
- `lib/mix/tasks/rendro/api.gen.ex` - Added `Rendro.Format,` to the Adapter-tier `@public_modules` block.
- `test/docs_contract/public_api_contract_test.exs` - Removed `Rendro.Format,` from `hidden_modules`.
- `priv/public_api.json` - Regenerated; new `Elixir.Rendro.Format` adapter entry.
- `test/rendro/public_api/manifest_test.exs` - Removed `"Elixir.Rendro.Format"` from a second, independent `hidden_modules` list (deviation fix).

## Decisions Made
- Followed the plan's explicit atomicity instruction literally: staged Task 1's file without committing, then made one commit covering all four Task 1 + Task 2 artifacts together.
- Fixed the second hidden-modules assertion inline (Rule 3 — blocking issue directly caused by this task's change) rather than treating it as out-of-scope, since it duplicates the exact same contract concern the plan targeted and blocked `mix test` from passing green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Second hidden-modules check not covered by the plan**
- **Found during:** Post-task full `mix test` run (after Task 2's targeted verification passed)
- **Issue:** `test/rendro/public_api/manifest_test.exs` (a Phase-79-era contract test not referenced in this plan's `<read_first>`/`<action>`) independently asserts `Elixir.Rendro.Format` is absent from `priv/public_api.json`'s manifest. After the promotion, this test failed: "Elixir.Rendro.Format should be hidden from the manifest but was found."
- **Fix:** Removed `"Elixir.Rendro.Format"` from the `hidden_modules` list in that test, mirroring the fix already applied to `public_api_contract_test.exs`.
- **Files modified:** `test/rendro/public_api/manifest_test.exs`
- **Verification:** `mix test test/rendro/public_api/manifest_test.exs` (8 tests, 0 failures) and full `mix test` (1236 tests, 0 failures).
- **Committed in:** `d24b37c`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Necessary for correctness — the plan's stated success criterion ("the contract lane passes green") requires all hidden-module contract checks to agree, not just the one file explicitly named in the plan. No scope creep beyond the plan's own INV-04 objective.

## Issues Encountered
None beyond the deviation documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
`Rendro.Format` is now public at the adapter/Evolving tier with a capped, documented, byte-verified surface (`money/1`, `date/1`, `label/1`). Plan 04 (Invoice anatomy upgrade / INV-02 recipe money-routing) can now depend on the public `Rendro.Format` surface. No blockers.

---
*Phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/rendro/format.ex
- FOUND: lib/mix/tasks/rendro/api.gen.ex
- FOUND: test/docs_contract/public_api_contract_test.exs
- FOUND: priv/public_api.json
- FOUND: test/rendro/public_api/manifest_test.exs
- FOUND: 83d356c
- FOUND: d24b37c

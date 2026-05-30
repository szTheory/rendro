---
phase: 78-public-api-surface-definition-cleanup
plan: 01
subsystem: api
tags: [elixir, moduledoc, hexdocs, public-api, semver, exdoc]

# Dependency graph
requires: []
provides:
  - "@moduledoc false applied to six engine internals: CidFont, FontSubsetter, Bidi, Shaper, Audit, Format"
  - "@doc false applied to five redact_* helpers in Rendro.Sign (4) and Rendro.Protect (1)"
  - "Rendro.Metadata exposed with real @moduledoc prose and tags: [:stable] — invisible-type gap for Rendro.metadata/1 closed"
affects:
  - 78-02
  - 78-03
  - 78-04
  - 78-05
  - 79-public-api-contract-enforcement-lane

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@moduledoc false for pure engine internals with no user story and no type leakage into public @type declarations"
    - "@doc false for public helper functions that are internal-only (redact_* pattern in signing/protection facades)"
    - "@moduledoc with tags: [:stable] keyword syntax for ExDoc 0.40 tier badges on documented structs"

key-files:
  created: []
  modified:
    - lib/rendro/pdf/cid_font.ex
    - lib/rendro/pdf/font_subsetter.ex
    - lib/rendro/text/bidi.ex
    - lib/rendro/text/shaper.ex
    - lib/rendro/audit.ex
    - lib/rendro/format.ex
    - lib/rendro/sign.ex
    - lib/rendro/protect.ex
    - lib/rendro/metadata.ex

key-decisions:
  - "D-01/D-03: hide six engine internals aggressively — CidFont, FontSubsetter, Bidi, Shaper, Audit, Format have no load-bearing type references in still-public modules"
  - "D-07: flip Rendro.Metadata from @moduledoc false to documented with tags: [:stable] — it is the return type of the stable facade Rendro.metadata/1"
  - "Confirmed zero invisible-type gaps introduced: no public @type or @spec references any of the six hidden module types"

patterns-established:
  - "ExDoc 0.40 @moduledoc keyword syntax: @moduledoc \"\"\"...\"\"\", tags: [:stable] — comma before tags keyword option"
  - "Sweep philosophy: compile-check each hidden target for type references in public modules before hiding (D-03 cross-reference check)"

requirements-completed:
  - API-02
  - API-03

# Metrics
duration: 15min
completed: 2026-05-30
---

# Phase 78 Plan 01: API Surface Hiding Sweep & Metadata Exposure Summary

**Six accidentally-public engine internals hidden with @moduledoc false, five redact_* helpers silenced with @doc false, and Rendro.Metadata promoted from hidden to documented with tags: [:stable] — closing the invisible-type gap for Rendro.metadata/1**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-30T10:18:00Z
- **Completed:** 2026-05-30T10:33:00Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Applied `@moduledoc false` to six pure engine internals (CidFont, FontSubsetter, Bidi, Shaper, Audit, Format) that were accidentally public; verified no invisible-type gaps introduced by checking all public @type references
- Applied `@doc false` to all four `redact_*` helpers in `Rendro.Sign` (redact_opts/1, redact_prepare_opts/1, redact_sign_opts/1, redact_augment_opts/1) and `Rendro.Protect.redact_opts/2`
- Flipped `Rendro.Metadata` from `@moduledoc false` to a real documented module with `tags: [:stable]`, closing the invisible-type gap where `Rendro.metadata/1` returned `Metadata.t()` but the struct was hidden from HexDocs

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply @moduledoc false to six engine internals** - `39be607` (chore)
2. **Task 2: Apply @doc false to redact_* helpers in Sign and Protect** - `d06762a` (chore)
3. **Task 3: Expose Rendro.Metadata with real @moduledoc, tags: [:stable]** - `0e66215` (feat)

## Files Created/Modified

- `lib/rendro/pdf/cid_font.ex` - @moduledoc false (was real moduledoc string)
- `lib/rendro/pdf/font_subsetter.ex` - @moduledoc false (was real moduledoc string)
- `lib/rendro/text/bidi.ex` - @moduledoc false (was real moduledoc string)
- `lib/rendro/text/shaper.ex` - @moduledoc false (was real moduledoc string)
- `lib/rendro/audit.ex` - @moduledoc false (was real moduledoc — internal behaviour contract)
- `lib/rendro/format.ex` - @moduledoc false (was real moduledoc — Statement-internal formatter)
- `lib/rendro/sign.ex` - @doc false on redact_opts/1, redact_prepare_opts/1, redact_sign_opts/1, redact_augment_opts/1
- `lib/rendro/protect.ex` - @doc false on redact_opts/2
- `lib/rendro/metadata.ex` - real @moduledoc with prose + tags: [:stable] replacing @moduledoc false

## Decisions Made

- Confirmed D-03 sweep philosophy by cross-referencing each of the six hidden modules: `grep -rn "FontSubsetter\.t()\|CidFont\.t()\|Format\.t()\|Bidi\.t()\|Shaper\.t()\|Audit\.t()" lib/` returned empty — no invisible-type gaps introduced
- Used `@moduledoc "...", tags: [:stable]` keyword list syntax (ExDoc 0.40 reads tags from the @moduledoc attribute options); `@type t` and `defstruct` in metadata.ex kept completely unchanged per task spec

## Deviations from Plan

None — plan executed exactly as written. All six files confirmed @moduledoc false; Metadata confirmed @moduledoc false removed; Sign has exactly 4 @doc false annotations; Protect has exactly 1; `mix compile --warnings-as-errors` exits 0; 925 tests pass, 0 failures.

## Issues Encountered

None. Compilation clean on first attempt after each task. The worktree does not have its own deps directory — compilation was performed via `mix compile` in the main project directory (`/Users/jon/projects/rendro/`), which shares `_build` and `deps` with the worktree (standard git worktree behavior for Elixir projects).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 78-02 (tags sweep) can proceed immediately — the hiding sweep is complete; all modules that remain public are candidates for `tags: [:stable]` or `tags: [:adapter]` annotation
- Phase 79 (contract enforcement lane) feed: six modules now hidden (ExDoc-invisible), five helpers hidden, Metadata documented — the public surface is intentional and ready for manifest generation and contract testing
- No blockers

---
*Phase: 78-public-api-surface-definition-cleanup*
*Completed: 2026-05-30*

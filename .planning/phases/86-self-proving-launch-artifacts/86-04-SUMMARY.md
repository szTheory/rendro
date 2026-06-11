---
phase: 86-self-proving-launch-artifacts
plan: 04
subsystem: docs
tags: [readme, hexdex, manual, launch-artifacts, copy-guards]
requires:
  - phase: 86-self-proving-launch-artifacts
    provides: 86-03 curated launch fixture source documents
provides:
  - Brand-aligned README opening and recipes guide copy
  - Generator-owned proof copy for README and HexDocs blocks
  - Compact manual source copy aligned to proof boundaries
affects: [phase-86, readme, guides, manual]
tech-stack:
  added: []
  patterns:
    - Generator-owned public proof copy is asserted by docs-contract tests before regeneration
key-files:
  created: []
  modified:
    - README.md
    - guides/recipes.md
    - lib/rendro/launch_artifacts.ex
    - test/docs_contract/launch_artifacts_claims_test.exs
key-decisions:
  - "Use Native PDF layout for Elixir as the README tagline and keep gallery proof after concise feature bullets."
  - "Generated proof copy distinguishes required source/manual byte checks from advisory pdfium-render PNG regeneration."
patterns-established:
  - "README remains Markdown-native with linked thumbnails; no hero composite, remote images, JavaScript, or viewer/prepress cues."
  - "manual.pdf source stays an 8-page proof artifact and points readers to HexDocs for reference depth."
requirements-completed: [GAL-01, GAL-02, GAL-03]
duration: 3min
completed: 2026-06-11
---

# Phase 86 Plan 04: Brand and Manual Presentation Summary

**README, recipe guide, generated proof copy, and manual source now express the launch artifact proof contract without overclaiming.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-11T18:12:00Z
- **Completed:** 2026-06-11T18:15:22Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Replaced the README opening with `Native PDF layout for Elixir.` and the locked open-source, Elixir-native first mention.
- Fixed `guides/recipes.md` so it names five rendered gallery entries and no longer claims only four canonical recipes.
- Updated `readme_block/1` and `recipes_block/1` with curated fixture language, required/advisory proof split, `not GUI-viewer proof`, and canonical-defaults boundary copy.
- Tightened manual source pages around the fit boundary, HTML/CSS boundary, PDF/A/PDF/UA boundary, complex-script boundary, manifest hashes, manual hash, Path proof, and advisory raster lane.

## Task Commits

1. **Task 1: Align README and guide hand-authored copy with the brand contract** - `37470d1` (docs)
2. **Task 2: Update generated README and recipes-guide block copy** - `3a0504d` (docs)
3. **Task 3: Tighten compact manual source copy and structure** - `94ba53c` (docs)

## Files Created/Modified

- `README.md` - Updates launch-facing tagline, first mention, and feature bullets.
- `guides/recipes.md` - Fixes the stale recipe count and names five rendered gallery entries.
- `lib/rendro/launch_artifacts.ex` - Updates generated block and manual source copy.
- `test/docs_contract/launch_artifacts_claims_test.exs` - Adds positive assertions for generated proof copy.

## Decisions Made

- Kept generated blocks generator-owned; committed Markdown blocks are intentionally refreshed in Plan 86-05.
- Kept manual source compact and proof-focused rather than expanding into an API reference.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `grep -n "Native PDF layout for Elixir." README.md` - passed
- `grep -n "five rendered gallery entries" guides/recipes.md` - passed
- `mix run -e 'm = Rendro.LaunchArtifacts.read_manifest!(); IO.puts(Rendro.LaunchArtifacts.readme_block(m))'` - printed curated fixture, required/advisory, and `not GUI-viewer proof` copy
- `mix run -e 'm = Rendro.LaunchArtifacts.read_manifest!(); IO.puts(Rendro.LaunchArtifacts.recipes_block(m))'` - printed `Source PDF SHA-256` entries and proof split copy
- `mix run -e 'case Rendro.LaunchArtifacts.render_manual_pdf() do {:ok, <<"%PDF-", _::binary>>} -> IO.puts("manual ok"); other -> raise inspect(other) end'` - passed

## Issues Encountered

Full docs-contract remains expected to fail until Plan 86-05 regenerates README/guide blocks, manifest hashes, PNGs, and `manual.pdf` from the final source.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 86-05. All source/copy changes are settled; final generation can now refresh assets, docs blocks, hashes, and visual evidence.

---
*Phase: 86-self-proving-launch-artifacts*
*Completed: 2026-06-11*

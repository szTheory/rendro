# Phase 33: Release Preflight and Proof

## Objective
Verify the release artifacts and dry-run the Hex publication process.

## Work Completed
1. Updated `mix release.preflight` to move `hex.build --unpack` to phase 1 checks.
2. Implemented `check_hex_artifacts/2` to assert that the unpacked Hex artifact contains the strictly required documentation (`LICENSE`, `README.md`, `CHANGELOG.md`, and `guides/*.md`).
3. Tested the newly updated `mix release.preflight` and ensured that `mix rendro.visual_uat` continues to pass, validating the final release surface.

## Status
Complete.
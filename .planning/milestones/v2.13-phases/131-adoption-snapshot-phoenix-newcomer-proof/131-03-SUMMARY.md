---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "03"
subsystem: release-candidate-validation
tags: [hex, hexdocs, github-actions, release-preflight, tdd]
requires:
  - phase: 131-02
    provides: exact-one protected workflow version extraction
provides:
  - Private exact v1.3.1 release candidate bound to source SHA and package checksum
  - Fail-closed v1.3.1 public-release verifier and protected HexDocs dispatch contract
  - Immutable v1.3.0 failed-release incident evidence with explicit no-mutation facts
affects: [131-04, protected-release, hexdocs, phoenix-newcomer-proof]
tech-stack:
  added: []
  patterns:
    - Candidate records bind a code-bearing commit and package checksum before one-way approval
    - Private release preflight uses the existing isolated synthetic-tag proof runner and cleans its local artifacts
key-files:
  created:
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-03-SUMMARY.md
  modified:
    - mix.exs
    - CHANGELOG.md
    - README.md
    - .github/workflows/hexdocs.yml
    - scripts/verify_public_release.exs
    - test/scripts/public_release_verifier_test.exs
    - test/mix/tasks/release_preflight_test.exs
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md
key-decisions:
  - "The exact candidate is v1.3.1 at 7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1; public installation documentation remains ~> 1.3."
  - "The failed v1.3.0 tag/run remains evidence only: it was not moved, retried, or published."
requirements-completed: [JOURNEY-01, JOURNEY-02]
coverage:
  - id: D1
    description: Private v1.3.1 candidate agrees across project, dispatch, verifier, package, and evidence surfaces.
    requirement: JOURNEY-01
    verification:
      - kind: integration
        ref: mix ci.fast; isolated release_preflight_proof; mix hex.build
        status: pass
    human_judgment: false
  - id: D2
    description: Candidate preserves the failed v1.3.0 incident while proving no v1.3.1 public mutation.
    requirement: JOURNEY-02
    verification:
      - kind: integration
        ref: test/scripts/public_release_verifier_test.exs; git ls-remote tag checks
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 1
  files_modified: 9
  tests: 1858
status: complete
---

# Phase 131 Plan 03: Private v1.3.1 Candidate Summary

The private v1.3.1 release candidate is bound to its exact source commit and package checksum, with protected release contracts repaired and failed v1.3.0 history retained without public mutation.

## Tasks Completed

1. Prepared and fully validated the private exact v1.3.1 candidate.
   - Retargeted the project version, ExDoc source ref, changelog, protected HexDocs dispatch, and public verifier to `1.3.1` / `v1.3.1`.
   - Recorded candidate source SHA `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1` and package checksum `85856694ee5e4192cdd189186f353a0698235e6479ba2f86c2cc1aa48a9307d7`.
   - Kept README installation copy at `{:rendro, "~> 1.3"}` and retained the Swiss/light, formatter-owned discovery route.
   - Preserved annotated v1.3.0 peeled commit `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`, failed run `32513353551`, failure-before-publish state, and absent Hex/HexDocs 1.3.0 facts as immutable incident evidence.

## Verification

- Focused release, workflow, docs, candidate, and preflight suites — passed (46 tests, 0 failures).
- `mix ci.fast` — passed (12 doctests, 8 properties, 1858 tests, 0 failures; Credo and Dialyzer clean).
- Existing isolated `scripts/release_preflight_proof.exs --current-version-tag --skip-ci --skip-security-audits` — passed all required private preflight gates, Hex dry-run, and docs contract; its temporary local v1.3.1 tag/worktree were removed.
- `mix hex.build` — passed; checksum matches the candidate record.
- Package inventory checksum — `00b4fa76537781c159ab5d0490f28bbfea861176a59bf32a9fc1306c6900765b`.
- Docs build — passed in `mix ci.fast` and isolated preflight.
- Read-only tag checks — remote v1.3.0 still peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`; local and remote v1.3.1 are absent.

## TDD Gate Compliance

- RED: `ae93d12` introduced v1.3.1 candidate and protected-dispatch contracts; they failed against the prior v1.3.0 state.
- GREEN: `3d22ce8` retargeted the release surfaces; candidate evidence and supporting regression repairs were then committed before final validation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored README docs-contract fence classification**
- **Found during:** Task 1 private preflight.
- **Issue:** The public dependency declaration was marked as executable Elixir without a required docs-contract ID, blocking `mix docs.contract`.
- **Fix:** Classified that declaration as the intended `elixir-schematic` snippet while retaining `{:rendro, "~> 1.3"}`.
- **Files modified:** `README.md`.
- **Verification:** `test/docs_contract/readme_doctest_test.exs`, `mix ci.fast`, and isolated release preflight passed.
- **Committed in:** `41c7113`.

**2. [Rule 3 - Blocking] Made release-preflight test fixture archives follow injected versions**
- **Found during:** Task 1 full CI.
- **Issue:** Fixtures used the live project version while testing injected historical versions, so the v1.3.1 retarget caused false package-inventory failures.
- **Fix:** Parameterized fixture archive versioning and updated default protected-target assertions to v1.3.1.
- **Files modified:** `test/mix/tasks/release_preflight_test.exs`.
- **Verification:** focused preflight tests and `mix ci.fast` passed.
- **Committed in:** `7afb1dd`.

**Total deviations:** 2 auto-fixed (2 Rule 3 blocking corrections).

## Security and Release Boundary

No public mutation occurred. No v1.3.1 tag was retained locally or exists remotely; no workflow was dispatched; Hex, HexDocs, and every registry remain unmodified. The temporary local tag/worktree used by the existing isolated preflight proof were removed before completion. v1.3.0 was only read and remains untouched.

## Known Stubs

None.

## Next Phase Readiness

Plan 131-04 can present only the recorded SHA `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1` for fresh blocking-human approval. No prior v1.3.0 approval transfers, and no tag, publication, or dispatch is authorized by this plan.

## Self-Check: PASSED

- Candidate record and all task commits exist.
- Candidate SHA resolves to the recorded source commit.
- The working tree has no task changes pending; the only unrelated modification is `.planning/config.json`.

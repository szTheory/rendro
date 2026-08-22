---
candidate_commit_sha: 47af6448d2989ffe69c4b80c77935c896b1ddb07
version: 1.3.2
release_ref: v1.3.2
package_checksum: a3e1517b175510c868cb8fd883290fe90dcd6fa02e045b9c6d7dec4fa6eececb
candidate_status: private_verified_no_tag
proof_mode: exact-sha-no-tag
tag_refs_unchanged: true
fifo_regression: passed
tag_object_sha: b386d1e39b6c9e63af58aa1fa5890d93909d278f
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
release_run_id: "32539594278"
release_conclusion: cancelled
release_stage: repeated-ci-inside-release-preflight
publish_job_skipped: true
hex_1_3_1_present: false
hexdocs_1_3_1_present: false
recovery_fix_commit: 9dee9c8b837510191a1036a642e43e0b5dba2018
superseded_by_planned_version: 1.3.2
supersedes_failed_version: 1.3.0
failed_release_tag: v1.3.0
failed_release_peeled_commit: 3d014b8194782fc29bc685c0d5e84e4adc64b2c3
failed_release_run_id: "32513353551"
failed_release_conclusion: failure
failed_release_stage: version-parity-before-hex
hex_1_3_0_present: false
hexdocs_1_3_0_present: false
---

# Rendro v1.3.2 Private Candidate Record

This historical record binds the committed v1.3.1 release surface at
`7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`. Its package checksum is
`85856694ee5e4192cdd189186f353a0698235e6479ba2f86c2cc1aa48a9307d7`.
Annotated tag `v1.3.1` now exists as public immutable history. Protected run
`32539594278` was automatically cancelled after release preflight's repeated CI
blocked; its publish job was skipped, Hex `1.3.1` remains absent, and HexDocs was
not dispatched.

Public consumer documentation remains `{:rendro, "~> 1.3"}`. Per D-33, exact
`1.3.2` is the next release/verifier/clean-room target; no 1.3.2 candidate SHA
is recorded until all candidate-bound source and evidence fixes are committed.

## Immutable failed v1.3.1 incident evidence

- Annotated public tag object `b386d1e39b6c9e63af58aa1fa5890d93909d278f`
  peels to `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`.
- Protected release run `32539594278` passed version parity and first CI, then
  hung in repeated preflight CI at `Mix.Tasks.RendroGenThemeTest`; GitHub
  cancelled it at the six-hour limit and skipped publication.
- Hex `1.3.1` is absent and HexDocs was not dispatched.
- Commit `9dee9c8b837510191a1036a642e43e0b5dba2018` fixes the shell mismatch and
  adds 45/15-minute protected release job timeout caps, with 26 focused tests
  and a full `mix ci.fast` recorded in the debug session.
- Push-tag-only `release.yml` means this tag is never moved or retried. Exact
  `v1.3.2` requires a new private candidate and fresh exact-SHA approval.

## Immutable failed v1.3.0 incident evidence

- Annotated public tag `v1.3.0` exists and peels to approved commit
  `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`.
- Protected release workflow run `32513353551` concluded **failure** before Hex
  publication. The version extraction matched both the top-level
  `@version "1.3.0"` declaration and the interpolated `source_ref` consumer,
  producing a multiline `MIX_VERSION` that could not equal the tag version.
- Hex package `1.3.0` is absent.
- HexDocs `1.3.0` was not dispatched and is absent.
- The tag and failed run are historical evidence, not a successful release.
  They must not be deleted, moved, overwritten, recreated, retried, or routed
  through an alternate publication mechanism.

## Historical private validation

- Deterministic exactly-one `@version` parser with zero/multiple-match failure,
  including the v1.3.0 multiline regression fixture.
- Exact `1.3.1` agreement across project version, ExDoc source ref, changelog,
  HexDocs dispatch gates, public verifier, package/docs contracts, and this record.
- Focused contracts, `mix ci.fast`, release preflight, Hex dry-run, package
  inventory/checksum, docs build, local/remote `v1.3.1` absence, and read-only
  v1.3.0 incident checks.

## Superseding approval boundary

No approval transfers from v1.3.0 or v1.3.1. A future blocking-human approval
must name the final exact v1.3.2 candidate SHA and authorize annotated tag,
protected Hex, and candidate-bound HexDocs together immediately before mutation.

---
candidate_commit_sha: PENDING_RECOVERY_TASK
version: 1.3.1
release_ref: v1.3.1
package_checksum: PENDING_RECOVERY_TASK
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
supersedes_failed_version: 1.3.0
---

# Rendro v1.3.1 Recovery Candidate

This record is intentionally not approval-ready yet. Plan 131-02 Task 1 must
replace both `PENDING_RECOVERY_TASK` values with the exact committed v1.3.1
candidate SHA and validated package checksum after the parser repair, regression
contract, version/source-ref/changelog/verifier/HexDocs updates, CI, preflight,
dry-run, package, docs, and public no-mutation checks all pass.

Public consumer documentation remains `{:rendro, "~> 1.3"}`; exact `1.3.1` is
the superseding evidence pin and clean-room target per D-32.

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

## Recovery gates still required

- Deterministic exactly-one `@version` parser with zero/multiple-match failure.
- Regression contract reproducing the v1.3.0 multiline extraction failure.
- Exact `1.3.1` agreement across project version, source ref, changelog,
  HexDocs dispatch gates, verifier, package contracts, and this record.
- Successful `mix ci.fast`, release preflight, Hex dry-run, package inventory,
  docs build, and local/remote `v1.3.1` absence checks.
- Fresh blocking-human approval naming the final exact candidate SHA before any
  v1.3.1 tag, Hex, or HexDocs mutation.

No prior v1.3.0 approval transfers to v1.3.1.

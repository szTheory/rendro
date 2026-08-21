---
candidate_commit_sha: 3d22ce89df8e6cd7ad8440950e2d668e7661625d
version: 1.3.1
release_ref: v1.3.1
package_checksum: 3dd6f70733111e2de2ceb4607da91403f592854b130802c495b6952dad05d0ef
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
supersedes_failed_version: 1.3.0
failed_release_tag: v1.3.0
failed_release_peeled_commit: 3d014b8194782fc29bc685c0d5e84e4adc64b2c3
failed_release_run_id: "32513353551"
failed_release_conclusion: failure
failed_release_stage: version-parity-before-hex
hex_1_3_0_present: false
hexdocs_1_3_0_present: false
---

# Rendro v1.3.1 Recovery Candidate

This private candidate binds the committed v1.3.1 release surface at
`3d22ce89df8e6cd7ad8440950e2d668e7661625d`. Its package checksum is
`3dd6f70733111e2de2ceb4607da91403f592854b130802c495b6952dad05d0ef`.
It remains approval-gated: no tag, workflow dispatch, Hex/HexDocs publication,
or registry mutation has occurred.

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

## Completed private validation

- Deterministic exactly-one `@version` parser with zero/multiple-match failure,
  including the v1.3.0 multiline regression fixture.
- Exact `1.3.1` agreement across project version, ExDoc source ref, changelog,
  HexDocs dispatch gates, public verifier, package/docs contracts, and this record.
- Focused contracts, `mix ci.fast`, release preflight, Hex dry-run, package
  inventory/checksum, docs build, local/remote `v1.3.1` absence, and read-only
  v1.3.0 incident checks.

## Approval boundary still required

A fresh blocking-human approval must name the exact candidate SHA above before
any v1.3.1 tag, Hex, or HexDocs mutation. No prior v1.3.0 approval transfers to
v1.3.1.

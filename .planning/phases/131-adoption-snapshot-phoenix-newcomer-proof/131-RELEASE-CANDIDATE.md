---
candidate_commit_sha: cfc58a81865e060351ce33d98f5e52de8cd198d9
version: 1.3.3
release_ref: v1.3.3
candidate_status: consumed_failed_immutable_incident
required_fix_ancestor: 9dabf90
proof_mode: exact-sha-no-tag-complete-audits
tag_pushed: true
hexdocs_dispatched: false
registry_mutated: false
supersedes_failed_version: 1.3.2
recovery_target: 1.3.4
recovery_decision: D-35
---

# Rendro v1.3.3 Candidate Control Record

**Sealed private candidate:** `cfc58a81865e060351ce33d98f5e52de8cd198d9`.
Detached HEAD matched this SHA; it contains `9dabf90`. Focused contracts (67
tests), FIFO, isolated Livebook, package/docs, `mix ci.fast` (Dialyzer 0),
both audits, and complete no-skip candidate preflight passed. Archive SHA-256:
`41b1766c8010dbd401da610ef32e12cdcf13e5062da5c17960beaba466a872c8`.

This candidate was approved and consumed by the single immutable v1.3.3
release attempt. It is historical evidence only and is not eligible for a
retry, new tag, package publication, or HexDocs dispatch.

Before the consumed Plan 131-06 approval, no local or remote `v1.3.3` tag
existed and complete tag-ref snapshots remained unchanged throughout private
proof. After approval, the single immutable tag was created exactly once.

Public consumer documentation remains `{:rendro, "~> 1.3"}`. Exact `1.3.3`
is historical failed evidence; exact `1.3.4` is the current verifier and
clean-room target per D-35.

## Immutable failed v1.3.2 incident

- Annotated public tag object `9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd`
  peels to approved candidate `47af6448d2989ffe69c4b80c77935c896b1ddb07`.
- Protected release run `32586098785`, validate job `97062582546`, publish job
  `97064173653`.
- Exact version match and `Run CI Checks` succeeded. `Run Release Preflight`
  failed with exit 1 from `2026-08-22T17:04:19Z` through `17:06:49Z`.
- The separate Hex dry run and publish job were skipped. Hex `1.3.2` is absent;
  HexDocs `1.3.2` was not dispatched and is absent.
- Exact detached reproduction passed preflight phase 1, repeated CI, docs,
  package unpack, and Hex dry run, then failed both audits because root
  Livebook 0.19.x pinned vulnerable Req 0.5.8, Protobuf 0.13.0, and related
  tooling transitives. The previous private wrapper had omitted the audits.
- Commit `9dabf90` removes root Livebook/config coupling while retaining the
  packaged ExDoc/Hex guide and isolated ephemeral `Mix.install` execution.
  Tutorial verification, package inventory, both audits, and `mix ci.fast`
  with 1,862 tests pass; no ignore was added.

## Earlier immutable failed incidents

- `v1.3.0` peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`;
  run `32513353551` failed before publication; Hex/HexDocs 1.3.0 are absent.
- `v1.3.1` tag object `b386d1e39b6c9e63af58aa1fa5890d93909d278f`
  peels to `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`; run
  `32539594278` was cancelled during repeated CI; publish was skipped and
  Hex/HexDocs 1.3.1 are absent.

None of these three tags or runs may be retried, moved, deleted, overwritten,
recreated, repushed, dispatched, or routed through an alternate publisher.

## Immutable failed v1.3.3 incident

- Annotated tag object `c96bf205d7216cdcf4846a0f24a312f9c1c75b0f`
  peels to this candidate.
- Protected run `32596108284`, validate job `97087204354`, publish job
  `97088652899`.
- Version, CI, and complete release preflight passed. A redundant standalone
  unauthenticated Hex dry run then failed; protected publish skipped.
- Hex and HexDocs 1.3.3 are absent, no HexDocs dispatch occurred, and the
  public verifier did not run.

## D-35 recovery boundary

Exact `1.3.4` is the only current recovery target. Commit
`bbe75d2bf3f53e5235626974c539500395d2032e` removes the redundant standalone
dry run and preserves complete credential-free preflight; `HEX_API_KEY` remains
exclusive to actual protected publish. No approval transfers from this record.
Plans 131-07 and 131-08 must commit every exact-version/verifier/incident
surface before capturing a new candidate, require `bbe75d2` ancestry, and
replace this file only after complete detached exact-SHA/no-tag proof passes.

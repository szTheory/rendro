---
candidate_commit_sha: 108c312f0746fdec97db934eba98ed692b395c7d
version: 1.3.3
release_ref: v1.3.3
candidate_status: sealed_private_pending_blocking_human
required_fix_ancestor: 9dabf90
proof_mode: exact-sha-no-tag-complete-audits
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
supersedes_failed_version: 1.3.2
---

# Rendro v1.3.3 Candidate Control Record

**Sealed private candidate:** `108c312f0746fdec97db934eba98ed692b395c7d`.
Detached HEAD matched this SHA; it contains `9dabf90`. Focused contracts (67
tests), FIFO, isolated Livebook, package/docs, `mix ci.fast` (Dialyzer 0),
both audits, and complete no-skip candidate preflight passed. Archive SHA-256:
`41b1766c8010dbd401da610ef32e12cdcf13e5062da5c17960beaba466a872c8`.

This candidate is sealed for private review and requires fresh blocking-human
approval before any tag, Hex publication, or HexDocs dispatch. The complete
proof included focused regressions, FIFO, `mix ci.fast`, isolated tutorial,
package/docs checks, and no-skip candidate preflight with both security audits.

No local or remote `v1.3.3` tag may exist, even temporarily, before the fresh
Plan 131-06 approval. Complete local and remote tag-ref snapshots must remain
unchanged throughout private proof. After the candidate is captured,
`candidate..HEAD` may contain only Phase 131 planning/control records.

Public consumer documentation remains `{:rendro, "~> 1.3"}`; exact `1.3.3` is
the release verifier and clean-room evidence target per D-34.

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

None of the three tags or runs may be retried, moved, deleted, overwritten,
recreated, repushed, dispatched, or routed through an alternate publisher.

## Superseding approval boundary

No approval transfers from a prior candidate. Plan 131-06 must repeat the
complete no-tag proof immediately before a blocking-human decision. Approval
must name the final exact 40-character v1.3.3 SHA and authorize annotated tag,
protected Hex, and candidate-bound protected HexDocs together.

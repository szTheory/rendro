---
prepared_at: 2026-08-22T19:02:51Z
version: 1.3.3
candidate_commit_sha: cfc58a81865e060351ce33d98f5e52de8cd198d9
required_fix_ancestor: 9dabf90
proof_mode: exact-sha-no-tag-complete-audits
head_equals_candidate: true
focused_regressions: pass
fifo_regression: pass
mix_ci_fast: pass
tutorial_verification: pass
docs_contract: pass
package_checksum: 41b1766c8010dbd401da610ef32e12cdcf13e5062da5c17960beaba466a872c8
complete_release_preflight: pass
security_audits_included: required
tag_refs_unchanged: true
v1_3_3_local_tag_absent: true
v1_3_3_remote_tag_absent: true
v1_3_3_hex_absent: true
v1_3_3_hexdocs_absent: true
approval_status: approved_exact_blocking_human
release_status: failed_immutable_incident
release_run_id: "32596108284"
release_validate_job_id: "97087204354"
release_publish_job_id: "97088652899"
tag_object_sha: c96bf205d7216cdcf4846a0f24a312f9c1c75b0f
tag_peeled_sha: cfc58a81865e060351ce33d98f5e52de8cd198d9
---

# Rendro v1.3.3 Release Approval Packet

This is a fresh pre-approval control record, not approval. It binds only the
exact candidate `cfc58a81865e060351ce33d98f5e52de8cd198d9`; detached HEAD
equaled that SHA and its ancestry contains resolved commit `9dabf90`.

## Fresh no-tag proof — 2026-08-22T19:02:51Z

- Local and remote full tag-ref snapshots were taken before proof and compared
  byte-for-byte after each detached proof and again at completion. The final
  local snapshot has 25 entries and SHA-256
  `0161828e07d55fe922aaf62f6989d2e6e5428e6bbcd9eeaf22c528eba21a940a`; the
  final remote snapshot has 33 entries and SHA-256
  `8960bc4b24f5b028b99c13d550a0e210d1d8030dba1cf2c2c53c2cccf5a14eab`.
  Both equal their before snapshots. `v1.3.3` is absent locally and at
  `origin`; no tag command was run.
- Read-only public checks found no Hex or HexDocs 1.3.3 surface: `GET
  https://hex.pm/api/packages/rendro/releases/1.3.3` returned `404`, and
  `GET https://hexdocs.pm/rendro/1.3.3/` returned `404`.
- The exact no-tag wrapper ran `mix run scripts/release_preflight_proof.exs
  --candidate-sha cfc58a81865e060351ce33d98f5e52de8cd198d9 --worktree
  <isolated-temp-dir>`. It created a detached worktree at the candidate,
  asserted its HEAD, ran `mix deps.get`, and completed `mix release.preflight
  --candidate-sha cfc58a81865e060351ce33d98f5e52de8cd198d9`. The complete
  preflight passed clean-worktree/candidate/package/source-ref/changelog and
  package-artifact gates, repeated `mix ci.fast`, docs contract, unpack,
  anonymous Hex publish dry run, `mix hex.audit`, and `mix deps.audit`; the
  worktree was removed afterwards.
- A second detached candidate check ran the focused release-preflight,
  workflow, public-verifier, and isolated-Livebook regression set: 57 tests,
  0 failures. It also passed `mix rendro.livebook.check`, `mix docs.contract`,
  `mix deps.audit`, and `mix hex.audit`; `mix hex.build` produced archive
  SHA-256 `41b1766c8010dbd401da610ef32e12cdcf13e5062da5c17960beaba466a872c8`.
  The inventory exposed the expected Hex archive envelope
  (`CHECKSUM`, `VERSION`, `contents.tar.gz`, `metadata.config`), while the
  complete preflight separately unpacked and verified required/forbidden
  package contents.
- `candidate..HEAD` was inspected before this packet update and contains only
  control record `06254306fc3fd4b90caa610a0b476e02d3f70466`
  (`docs(131-05): rebind sealed candidate proof`).

## Immutable failed incidents

- `v1.3.0` peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`; protected
  run `32513353551` failed before publication. Hex and HexDocs 1.3.0 remain
  absent.
- `v1.3.1` tag object `b386d1e39b6c9e63af58aa1fa5890d93909d278f` peels to
  `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`; protected run `32539594278`
  was cancelled during repeated CI, and publishing was skipped. Hex and
  HexDocs 1.3.1 remain absent.
- `v1.3.2` tag object `9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd` peels to
  `47af6448d2989ffe69c4b80c77935c896b1ddb07`; protected run `32586098785`
  had validate job `97062582546` fail its release preflight and publish job
  `97064173653` skip. Hex and HexDocs 1.3.2 remain absent.

None of those tags, runs, or absence facts may be retried, moved, deleted,
overwritten, recreated, repushed, dispatched, or routed through another
publisher.

## Required blocking-human decision

Only a new literal approval that names
`cfc58a81865e060351ce33d98f5e52de8cd198d9` and jointly authorizes the
annotated `v1.3.3` tag, protected tag-driven Hex publication, and
candidate-bound protected HexDocs publication may advance this packet. Prior
approval, generic assent, silence, partial approval, and automatic advancement
do not authorize mutation.

## Literal blocking-human approval

**Recorded at:** 2026-08-22T20:14:00Z

> approve exact v1.3.3 candidate cfc58a81865e060351ce33d98f5e52de8cd198d9 for annotated tag, protected Hex, and candidate-bound HexDocs

The approval names the exact candidate in this packet and jointly authorizes
only one annotated `v1.3.3` tag, its existing protected tag-driven Hex path,
and the existing candidate-bound protected HexDocs dispatch. It authorizes no
retry, ref movement, deletion, alternate publisher, or action on a mismatch.

## Immutable v1.3.3 failed-release incident

The single approved annotated tag was created and pushed exactly once:
`v1.3.3` object `c96bf205d7216cdcf4846a0f24a312f9c1c75b0f` peels to approved
candidate `cfc58a81865e060351ce33d98f5e52de8cd198d9`.

Protected `Release to Hex` run `32596108284` was a `push` event at the exact
candidate and concluded `failure`. Its validation job `97087204354` passed
Verify Version Match, Run CI Checks, and Run Release Preflight, then failed
the separate **Publish to Hex (Dry Run)** at `2026-08-22T20:26:14Z` with exit
1: `No authenticated user found. Run mix hex.user auth`; its interactive
authentication prompt was not answered. The protected `publish` job
`97088652899` was skipped.

Read-only checks immediately afterwards confirm Hex 1.3.3 and HexDocs 1.3.3
both return `404`; no candidate-bound `workflow_dispatch` HexDocs run exists.
This is immutable failure evidence. Do not retry, move, delete, recreate, or
repush the tag; do not use another publisher; and do not dispatch HexDocs for
this failed release.

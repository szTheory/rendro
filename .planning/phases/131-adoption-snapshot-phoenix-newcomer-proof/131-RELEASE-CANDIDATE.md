---
candidate_commit_sha: ed68ff83a3211cc8318d0cab88acbd4c01859474
version: 1.3.4
release_ref: v1.3.4
candidate_status: proof_complete_control_pending
required_fix_ancestor: bbe75d2bf3f53e5235626974c539500395d2032e
proof_mode: exact-sha-no-tag-complete-audits
tag_pushed: false
hexdocs_dispatched: false
registry_mutated: false
recovery_target: 1.3.4
recovery_decision: D-35
---

# Rendro v1.3.4 Candidate Control Record

**Sealed private candidate:** `ed68ff83a3211cc8318d0cab88acbd4c01859474`.
This exact committed SHA contains required fix
`bbe75d2bf3f53e5235626974c539500395d2032e`. It is private deterministic
control evidence only: no `v1.3.4` tag was created, no package was published,
no HexDocs dispatch occurred, and no public verifier was run.

## Exact no-tag proof — 2026-08-22

- Fresh local and `origin` tag-ref snapshots were captured before the detached
  proof and compared byte-for-byte afterwards. The local snapshot has 26
  entries and SHA-256
  `8ac725d50e6afa6af5a8f69fea7997eecdbaee9abe2842361d27e3a2da9b7996`; the
  remote snapshot has 35 entries and SHA-256
  `646bbb2f2df8156e482d695a57a4bb8ea5ec9cab9f472f5aa3e9df0e3538fdf9`.
  Both are unchanged. `v1.3.4` is absent locally and at `origin`.
- Read-only public checks returned `404` for
  `https://hex.pm/api/packages/rendro/releases/1.3.4` and
  `https://hexdocs.pm/rendro/1.3.4/`.
- An isolated detached worktree was created at this SHA and its `HEAD` was
  asserted equal to the candidate. The focused release-preflight, workflow,
  public-verifier, isolated-Livebook, and open-silent FIFO regression suite
  passed: 61 tests, 0 failures.
- The detached SHA passed `mix ci.fast` (including Dialyzer: 0 errors),
  `mix docs.contract`, `mix rendro.livebook.check`, `mix hex.build`, package
  unpack allowlist/forbidden-path checks, `mix hex.audit`, and `mix deps.audit`.
  Archive SHA-256 is
  `7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a`.
  Archive inventory is exactly `CHECKSUM`, `VERSION`, `contents.tar.gz`, and
  `metadata.config`; unpacked contents include the required license, README,
  changelog, and API-stability, branding, and integrations guides, with the
  forbidden support-matrix/viewer-evidence/guardrails/test paths absent.
- `mix run scripts/release_preflight_proof.exs --candidate-sha
  ed68ff83a3211cc8318d0cab88acbd4c01859474 --worktree <isolated-temp-dir>`
  created its own detached worktree, asserted exact `HEAD`, ran `mix deps.get`,
  and completed `mix release.preflight --candidate-sha` with no skips. It passed
  clean-worktree, candidate parity, package/source-ref/changelog/artifact gates,
  repeated CI, docs, unpack, credential-free internal Hex dry run, and both
  audits. Its cleanup completed before the after snapshots.

## Immutable failed-release incidents

- `v1.3.0` peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`; protected run
  `32513353551` failed before publication. Hex and HexDocs 1.3.0 are absent.
- `v1.3.1` object `b386d1e39b6c9e63af58aa1fa5890d93909d278f` peels to
  `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`; run `32539594278` was cancelled
  during repeated CI and publishing was skipped. Hex and HexDocs 1.3.1 are absent.
- `v1.3.2` object `9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd` peels to
  `47af6448d2989ffe69c4b80c77935c896b1ddb07`; validate job `97062582546`
  failed complete preflight in protected run `32586098785` and publish job
  `97064173653` skipped. Hex and HexDocs 1.3.2 are absent.
- `v1.3.3` object `c96bf205d7216cdcf4846a0f24a312f9c1c75b0f` peels to
  `cfc58a81865e060351ce33d98f5e52de8cd198d9`; protected run `32596108284`
  reached validate job `97087204354`, which passed version, CI, and preflight
  before its redundant standalone dry run failed, and publish job `97088652899`
  skipped. Hex and HexDocs 1.3.3 are absent; no HexDocs dispatch or public
  verifier occurred.

All four incidents are immutable historical evidence and may not be retried,
moved, deleted, overwritten, recreated, repushed, dispatched, or published
through another route. The D-35 fix removes only the duplicate dry run and
confines `HEX_API_KEY` to later protected actual publication.

## Approval boundary

This record is not approval. `candidate..HEAD` was empty at capture. Only
Phase-131 control records may follow this SHA. A fresh blocking-human decision
must name this exact SHA and jointly authorize one annotated `v1.3.4` tag, its
protected tag-driven Hex publish, and exact-candidate HexDocs dispatch. No
v1.3.3 approval transfers.

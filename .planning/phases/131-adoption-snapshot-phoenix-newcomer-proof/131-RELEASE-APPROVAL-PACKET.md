---
prepared_at: 2026-08-22T21:20:00Z
version: 1.3.4
candidate_commit_sha: f03c78bab54efe1cd1596d51cf3f28193232e2a3
required_fix_ancestor: bbe75d2bf3f53e5235626974c539500395d2032e
proof_mode: exact-sha-no-tag-complete-audits
head_equals_candidate: true
focused_regressions: pass
fifo_regression: pass
mix_ci_fast: pass
tutorial_verification: pass
docs_contract: pass
package_checksum: 7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a
complete_release_preflight: pass
security_audits_included: required
tag_refs_unchanged: true
v1_3_4_local_tag_absent: true
v1_3_4_remote_tag_absent: true
v1_3_4_hex_absent: true
v1_3_4_hexdocs_absent: true
approval_status: pending_blocking_human
release_status: private_candidate_only
recovery_target: 1.3.4
recovery_decision: D-35
---

# Rendro v1.3.4 Release Approval Packet

This pending packet binds only private candidate
`f03c78bab54efe1cd1596d51cf3f28193232e2a3`, whose ancestry includes
`bbe75d2bf3f53e5235626974c539500395d2032e`. It authorizes nothing.

## Fresh no-tag evidence

- Detached `HEAD` equaled the candidate. Focused release/workflow/verifier,
  isolated-Livebook, and open-silent FIFO contracts passed (61 tests, 0 failures).
- `mix ci.fast`, docs contract, tutorial check, package build/checksum/inventory
  and unpack inspection, Hex audit, and deps audit passed. Archive SHA-256:
  `7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a`.
- Complete `mix release.preflight --candidate-sha` passed in an internally
  detached worktree, including its credential-free internal Hex dry run and
  both required security audits; no separate dry-run command or credential was
  used.
- Local tag snapshot (26 entries)
  `8ac725d50e6afa6af5a8f69fea7997eecdbaee9abe2842361d27e3a2da9b7996` and
  remote tag snapshot (35 entries)
  `646bbb2f2df8156e482d695a57a4bb8ea5ec9cab9f472f5aa3e9df0e3538fdf9` are
  unchanged. `v1.3.4` remains absent locally/remotely and both public endpoints
  returned 404.

## Immutable history and non-transfer

The packet retains the four immutable failed-release incidents: v1.3.0/run
`32513353551`; v1.3.1 object `b386d1e...`/run `32539594278`; v1.3.2 object
`9b7ff50...`/jobs `97062582546` and `97064173653`; and v1.3.3 object
`c96bf205...`/jobs `97087204354` and `97088652899`. Their Hex and HexDocs
versions are absent. They cannot be retried or mutated. The v1.3.3 approval was
consumed by its failed immutable attempt and does not transfer to v1.3.4.

## Required fresh human decision

Only an explicit blocking-human approval that names
`f03c78bab54efe1cd1596d51cf3f28193232e2a3` and jointly authorizes the single
annotated `v1.3.4` tag, protected tag-driven Hex publication, and
candidate-bound protected HexDocs dispatch may advance this packet. Generic
assent, prior approval, silence, partial approval, and automatic advancement do
not authorize mutation. No tag, publish, dispatch, or public verifier has been
run for this candidate.

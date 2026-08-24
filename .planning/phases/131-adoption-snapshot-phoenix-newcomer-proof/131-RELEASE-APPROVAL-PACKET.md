---
prepared_at: 2026-08-22T21:40:56Z
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
sealed_manifest_sha256: d2ba1a33339d501291736c67df74cbed3ef46f5063409043ac7d6f4f38012f9e
sealed_metadata_sha256: 52d92fd928453dcf23c1dd0ef1fc0daf699c1de97b68ce3cadb6c5cb0c8564b3
complete_release_preflight: pass
security_audits_included: required
tag_refs_unchanged: true
v1_3_4_local_tag_absent: true
v1_3_4_remote_tag_absent: true
v1_3_4_hex_absent: true
v1_3_4_hexdocs_absent: true
approval_status: approved_exact_publication_sequence
approved_at: 2026-08-24T18:32:19Z
release_status: protected_release_complete_pending_atomic_verification
recovery_target: 1.3.4
recovery_decision: D-35
---

# Rendro v1.3.4 Release Approval Packet

This pending packet binds only private candidate
`f03c78bab54efe1cd1596d51cf3f28193232e2a3`, whose ancestry includes
`bbe75d2bf3f53e5235626974c539500395d2032e`. It authorizes nothing.

## Fresh no-tag evidence — 2026-08-22T21:40:56Z

- Before the detached run, candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3`
  was re-asserted to contain required ancestor
  `bbe75d2bf3f53e5235626974c539500395d2032e`; its detached release-bearing
  worktree was clean. Focused release/workflow/verifier, isolated-Livebook, and
  open-silent FIFO contracts passed (58 tests, 0 failures).
- `mix ci.fast` passed (1,867 tests, 0 failures; Credo 0 issues; Dialyzer 0
  errors). `mix docs.contract`, `mix rendro.livebook.check`, `mix hex.build`,
  package checksum/inventory/unpack inspection, `mix hex.audit`, and
  `mix deps.audit` all passed. Archive SHA-256:
  `7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a`.
  The outer archive inventory is exactly `CHECKSUM`, `VERSION`,
  `contents.tar.gz`, and `metadata.config`; its 257 unpacked entries include
  required license, README, changelog, API-stability, branding, and
  integrations guides, with support-matrix/viewer-evidence/guardrails/test
  paths absent.
- Complete `mix release.preflight --candidate-sha` passed in its own internally
  detached worktree with every Phase 1 and 2 gate green, including the
  credential-free internal Hex dry run and both required security audits. No
  standalone workflow dry run or credential was used.
- Local tag snapshot (26 entries)
  `8ac725d50e6afa6af5a8f69fea7997eecdbaee9abe2842361d27e3a2da9b7996` and
  remote tag snapshot (35 entries)
  `646bbb2f2df8156e482d695a57a4bb8ea5ec9cab9f472f5aa3e9df0e3538fdf9` are
  byte-identical before and after cleanup. `v1.3.4` remains absent
  locally/remotely and fresh Hex/HexDocs probes both returned 404.
- The detached proof and nested preflight worktrees were removed. The
  `candidate..HEAD` delta remains control-only (Phase-131 state/roadmap/summary
  and candidate/approval records); no release-bearing source change follows the
  candidate. The workflow still runs credential-free preflight and exposes
  `HEX_API_KEY` only to protected actual `mix hex.publish --yes`.

## Immutable history and non-transfer

The packet retains the four immutable failed-release incidents: v1.3.0/run
`32513353551`; v1.3.1 object `b386d1e...`/run `32539594278`; v1.3.2 object
`9b7ff50...`/jobs `97062582546` and `97064173653`; and v1.3.3 object
`c96bf205...`/jobs `97087204354` and `97088652899`. Their Hex and HexDocs
versions are absent. They cannot be retried or mutated. The v1.3.3 approval was
consumed by its failed immutable attempt and does not transfer to v1.3.4.

## Recorded fresh human decision

The blocking-human response was recorded verbatim at 2026-08-24T18:32:19Z:

`approve exact v1.3.4 candidate f03c78bab54efe1cd1596d51cf3f28193232e2a3 for annotated tag, protected release and Hex, and candidate-bound HexDocs`

It names this packet's candidate and jointly authorizes only the single
annotated `v1.3.4` tag, protected tag-driven Hex publication, and
candidate-bound protected HexDocs dispatch. Generic assent, prior approval,
silence, partial approval, and automatic advancement do not authorize mutation.
No tag, publish, dispatch, or public verifier had run when this decision was
recorded.

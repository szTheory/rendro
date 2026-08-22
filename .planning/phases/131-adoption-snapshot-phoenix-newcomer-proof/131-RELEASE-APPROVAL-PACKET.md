---
prepared_at: 2026-08-22T16:48:04Z
version: 1.3.2
candidate_commit_sha: 47af6448d2989ffe69c4b80c77935c896b1ddb07
package_checksum: a3e1517b175510c868cb8fd883290fe90dcd6fa02e045b9c6d7dec4fa6eececb
proof_mode: exact-sha-no-tag
head_equals_candidate: true
fifo_regression: passed
overwrite_prompt_seen: false
release_timeout_contract: passed
tag_refs_unchanged: true
v1_3_2_local_tag_absent: true
v1_3_2_remote_tag_absent: true
v1_3_2_hex_absent: true
v1_3_2_hexdocs_absent: true
approval_status: pending_blocking_human
---

# Rendro v1.3.2 Release Approval Packet

This is a fresh, read-only approval packet for the final private candidate
`47af6448d2989ffe69c4b80c77935c896b1ddb07`. It is evidence, not approval, and
does not create, move, push, or dispatch any tag, Hex package, or HexDocs release.

## Candidate identity

| Field | Value |
| --- | --- |
| Version | `1.3.2` |
| Candidate SHA | `47af6448d2989ffe69c4b80c77935c896b1ddb07` |
| Detached HEAD | `47af6448d2989ffe69c4b80c77935c896b1ddb07` |
| Package checksum | `a3e1517b175510c868cb8fd883290fe90dcd6fa02e045b9c6d7dec4fa6eececb` |
| Required recovery ancestor | `9dee9c8b837510191a1036a642e43e0b5dba2018` (present) |

## Deterministic private proof

- **Open-silent FIFO regression:** passed under a separate 10-minute bound. The
  detached candidate test completed its internal `Skipped lib/generated_theme.ex`
  assertion; captured output contained no `overwrite? [Yn]` prompt.
- **Release timeout contract:** passed. `release.yml` retains independent
  45-minute `validate-and-dry-run` and 15-minute `publish` limits.
- **Focused contracts:** passed — 46 tests across exact-SHA preflight, release
  preflight, public verifier, and protected-workflow contracts.
- **Exact-SHA no-tag preflight:** passed through
  `mix run scripts/release_preflight_proof.exs --candidate-sha
  47af6448d2989ffe69c4b80c77935c896b1ddb07 --worktree <unique-path>`.
  The wrapper created a new detached worktree at the candidate, asserted HEAD
  equality, repeated CI/security checks, package build/inventory, Hex dry run,
  and docs build, then removed the worktree.
- **No-tag boundary:** the proof used candidate-SHA mode only. It did not invoke
  the legacy synthetic-tag mode or any tag mutation command. Complete tag-ref
  snapshots before and after were byte-for-byte unchanged.

## Read-only public state

All HTTP facts below are advisory external evidence; deterministic contracts above
remain the release authority.

- Local and remote `refs/tags/v1.3.2` are absent.
- Hex `rendro` release `1.3.2` is absent (final HTTP `404`).
- HexDocs `rendro/1.3.2` is absent (bounded redirect-following final HTTP `404`).
- Candidate-to-HEAD control-plane delta contains only
  `131-RELEASE-CANDIDATE.md` and `131-04-SUMMARY.md` before this packet.

## Immutable failed-release incidents

| Version | Tag identity | Protected run | Verified state |
| --- | --- | --- | --- |
| v1.3.0 | peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3` | `32513353551` | `failure`; publish skipped; Hex and HexDocs absent (final `404`) |
| v1.3.1 | object `b386d1e39b6c9e63af58aa1fa5890d93909d278f`, peels to `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1` | `32539594278` | `cancelled`; publish skipped; Hex and HexDocs absent (final `404`) |

Neither historical tag, run, package, nor docs state was changed during this
proof.

## Required decision

Approval must be freshly stated against the exact 40-character candidate above
and must authorize all three permanent actions together: annotated `v1.3.2` tag,
protected tag-driven Hex publication, and candidate-bound protected HexDocs
publication. Previous approvals, generic approval, silence, or partial approval
do not authorize mutation.

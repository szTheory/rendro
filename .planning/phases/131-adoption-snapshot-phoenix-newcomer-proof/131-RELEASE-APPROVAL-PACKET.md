---
prepared_at: 2026-08-22
version: 1.3.3
candidate_commit_sha: cfc58a81865e060351ce33d98f5e52de8cd198d9
proof_mode: exact-sha-no-tag-complete-audits
head_equals_candidate: true
fifo_regression: pass
complete_release_preflight: pass
security_audits_included: required
tag_refs_unchanged: true
v1_3_3_local_tag_absent: required
v1_3_3_remote_tag_absent: required
v1_3_3_hex_absent: required
v1_3_3_hexdocs_absent: required
approval_status: pending_blocking_human
---

# Rendro v1.3.3 Release Approval Packet

This packet is a planning control record, not approval. It becomes eligible for
human review only after Plan 131-05 seals an exact v1.3.3 candidate and Plan
131-06 immediately repeats the complete exact-SHA no-tag preflight.

The refreshed packet must record:

- the exact 40-character candidate SHA and proof that detached HEAD equals it;
- ancestry containing resolved commit `9dabf90`;
- focused preflight/verifier/workflow/tutorial regressions;
- the open-silent FIFO result with no interactive overwrite prompt;
- `mix ci.fast`, tutorial verification, package checksum/inventory, and docs;
- complete candidate-SHA release preflight with repeated CI and both
  `mix hex.audit` and `mix deps.audit` included;
- full local and remote tag-ref snapshots unchanged;
- no local/remote `v1.3.3` tag and no Hex/HexDocs 1.3.3 surface;
- a `candidate..HEAD` delta containing only Phase 131 control-plane records;
- the exact v1.3.0, v1.3.1, and v1.3.2 failed tag/run/job and public-absence
  facts recorded in `131-RELEASE-CANDIDATE.md`.

Any audit/CI bypass, stale candidate, mismatched checksum/inventory, tag-ref
change, public v1.3.3 presence, or non-control delta leaves
`approval_status: not_ready`.

## Required decision

Fresh approval must name the exact candidate and jointly authorize all three
permanent actions: annotated `v1.3.3`, protected tag-driven Hex publication,
and exact-candidate protected HexDocs publication. Previous approvals, generic
approval, silence, partial approval, and automatic advancement do not authorize
mutation.

---
decision: rejected_or_revise
packet_created_at_utc: 2026-08-25T18:20:00Z
control_sha: 7e28826cf9f0832063ea9fd922d6bb065a920fc4
remote_baseline_sha: 881b97ffc10551f77e7c6f416bc91df2e1289025
candidate_sha: f03c78bab54efe1cd1596d51cf3f28193232e2a3
release_ref: v1.3.4
workflow_name: HexDocs
---

# Phase 131 HexDocs Retry Approval Packet

## Decision Required

This packet requests one fresh, literal decision for the corrected control. It does not reuse the consumed Plan 131-14/15 authority or authorize a retry of its terminal run.

**Exact proposed action:** integrate reviewed local control commit `7e28826cf9f0832063ea9fd922d6bb065a920fc4` into protected `origin/main`, then dispatch `HexDocs` from `main` exactly once with `candidate_commit_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3` and `release_ref=v1.3.4`.

The corrected `verify-docs-ready` job fetches the exact tag, rejects a missing or lightweight tag, and requires `v1.3.4^{}` to equal the sealed candidate before Beam setup, dependency installation, or every docs-contract action. It has no secret-bearing environment. The protected `publish-hexdocs` job, detached candidate validation, `HEX_API_KEY` boundary, publication command, and durable `hexdocs-candidate-binding` upload are unchanged.

## Control Identities and Preconditions

| Fact | Observed value | Result |
|---|---|---|
| Corrected local control commit | `7e28826cf9f0832063ea9fd922d6bb065a920fc4` | distinct from failed baseline |
| Failed-run baseline / remote `origin/main` | `881b97ffc10551f77e7c6f416bc91df2e1289025` | read-only `git ls-remote` observation |
| Fast-forward relation | baseline is an ancestor of corrected control | pass |
| Workflow SHA-256 | `44bfed3efc2a7ae8c53694112478104b45bfd63c98bdf4c9101659698927ef3a` | `.github/workflows/hexdocs.yml` |
| Contract test SHA-256 | `fcabf48d135e763c2ebafa4588b5678dd606dc56d1171071f4c72b6d5fab2da4` | `test/docs_contract/launch_execution_claims_test.exs` |
| Annotated tag object | `v1.3.4` is `tag` | pass |
| Sealed tag target | `v1.3.4^{}` = `f03c78bab54efe1cd1596d51cf3f28193232e2a3` | pass |

The protected-main delta is limited to the explicit pre-contract fetch, annotated-tag-type assertion, and peeled-candidate equality check, plus the structural regression contract. It adds no publisher, dependency, registry mutation, token, secret use, or alternate workflow.

## Immutable Terminal Incident

| Fact | Observed value |
|---|---|
| Terminal run | [`32877290266`](https://github.com/szTheory/rendro/actions/runs/32877290266), `HexDocs`, `workflow_dispatch`, completed/failure |
| Failed control identity | `main` at `881b97ffc10551f77e7c6f416bc91df2e1289025` |
| Requested artifact | `f03c78bab54efe1cd1596d51cf3f28193232e2a3`, `v1.3.4` |
| Failed job | `verify-docs-ready` [`97899588380`](https://github.com/szTheory/rendro/actions/runs/32877290266/job/97899588380), `Verify Docs Contract` |
| Exact cause | checkout lacked annotated `v1.3.4`; the docs contract's `git rev-parse v1.3.4^{}` exited 128 |
| Publish job | [`97900969705`](https://github.com/szTheory/rendro/actions/runs/32877290266/job/97900969705) skipped |
| Binding artifact | artifacts endpoint reported `total_count: 0`; no `hexdocs-candidate-binding` exists |

Run `32877290266`, its jobs, and the prior approval are immutable terminal-failure evidence. This packet cannot authorize their retry, rerun, reuse, replacement, or transfer.

## Local Verification

Executed successfully on 2026-08-25:

```text
MIX_ENV=test mix test test/docs_contract/launch_execution_claims_test.exs test/scripts/public_release_verifier_test.exs --max-failures 1

30 tests, 0 failures

mix ci.fast

pass
```

The structural contract proves checkout precedes the credential-free tag gate; the tag gate precedes Beam setup, dependency installation, and the docs contract; and the gate fetches, requires an annotated tag object, and compares its peeled target to the sealed candidate.

## Authority Required and Stop Conditions

Only an unqualified literal response that names this exact control SHA, the sealed candidate, `v1.3.4`, protected-main integration, and **exactly one new HexDocs dispatch** may authorize the following ordered scope:

1. Integrate `7e28826cf9f0832063ea9fd922d6bb065a920fc4` through the repository's non-force protected-main route.
2. Dispatch `HexDocs` from protected `main` once with candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` and tag `v1.3.4`.
3. Retrieve the resulting `hexdocs-candidate-binding` only if the new run succeeds and use the current verifier as the sole canonical prerequisite writer.

Stop before external mutation on a rejected, silent, qualified, mismatched, or recycled approval; a changed remote baseline or non-fast-forward relation; changed workflow/test hashes; an invalid tag type or peeled target; failed focused/full checks; unavailable protected-main integration or environment approval; any need for force-push, tag/package mutation, alternate publisher, extra dispatch, retry, or manufactured prerequisite.

## Literal Decision Record

decision: rejected_or_revise
literal_response: reject-or-revise
reviewer_identity: not supplied
recorded_at_utc: 2026-08-25T18:24:32Z

The requested protected-main integration and new `HexDocs` workflow dispatch are rejected.
No protected-main integration, workflow dispatch, rerun, publication, tag/package mutation,
artifact retrieval, or canonical prerequisite regeneration was performed. The corrected control
and Task 1 verification evidence remain available only for a future revised packet and fresh
blocking-human decision.

To authorize the exact scope, reply with an unqualified statement that names all bound facts, for example:

```text
approve-corrected-control-and-one-dispatch: control_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
```

To leave all external state unchanged, reply:

```text
reject-or-revise
```

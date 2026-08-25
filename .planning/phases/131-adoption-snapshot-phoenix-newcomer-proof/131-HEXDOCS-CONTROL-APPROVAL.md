---
decision: pending
packet_created_at_utc: 2026-08-25T17:06:33Z
local_control_sha: 881b97ffc10551f77e7c6f416bc91df2e1289025
origin_main_sha: 6c56d390c1765e8724d6caabc1fa088a87266533
candidate_sha: f03c78bab54efe1cd1596d51cf3f28193232e2a3
release_ref: v1.3.4
workflow_name: HexDocs
---

# Phase 131 HexDocs Control Approval Packet

## Decision Required

This packet requests one fresh, literal decision. The earlier v1.3.4 package-release approval does not authorize this action.

**Exact proposed action:** fast-forward protected `origin/main` from `6c56d390c1765e8724d6caabc1fa088a87266533` to reviewed local control commit `881b97ffc10551f77e7c6f416bc91df2e1289025`, then dispatch the `HexDocs` workflow from `main` exactly once with `candidate_commit_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3` and `release_ref=v1.3.4`.

The dispatch runs the trusted control workflow from protected `main`, validates the immutable candidate and peeled tag before secret validation, checks out the candidate for documentation publication, and uploads the `hexdocs-candidate-binding` provenance artifact.

## Control Identities and Local Preconditions

| Fact | Observed value | Result |
|---|---|---|
| Local reviewed control commit | `881b97ffc10551f77e7c6f416bc91df2e1289025` | exact local `HEAD` |
| Protected remote tip | `6c56d390c1765e8724d6caabc1fa088a87266533` | exact `origin/main` |
| Fast-forward relation | `origin/main` is an ancestor of local `HEAD` | pass (`git merge-base --is-ancestor origin/main HEAD`) |
| Local workflow state | no uncommitted `.github/workflows/hexdocs.yml` change | clean |
| Local worktree state before packet creation | clean | no unrelated change observed |
| Workflow SHA-256 | `cea1392c37eb541034ed642914b3ae3795660744921e993aea23c8f8f643ae24` | `.github/workflows/hexdocs.yml` |
| Inline-contract test SHA-256 | `a106e09b74844411f66693afb775aea363c16ce0f70ce730beaa314a7754ca44` | `test/docs_contract/launch_execution_claims_test.exs` |

## Sealed Artifact and Read-Only Remote Facts

| Fact | Observed value |
|---|---|
| Candidate record | `f03c78bab54efe1cd1596d51cf3f28193232e2a3`, version `1.3.4`, ref `v1.3.4` |
| Annotated tag identity | `v1.3.4^{}` peels to `f03c78bab54efe1cd1596d51cf3f28193232e2a3` |
| Release run | `32763039854` (`Release to Hex`) is completed/successful, event `push`, head SHA `f03c78bab54efe1cd1596d51cf3f28193232e2a3` |
| Remote workflow delta | `origin/main` lacks hardened candidate inputs, immutable identity gate, and `hexdocs-candidate-binding` upload markers; the local reviewed workflow contains them |
| Current prerequisite | `131-PUBLIC-PREREQUISITE.json` records legacy `protected_release_publish` / `push` provenance and has no candidate-binding field |

These are read-only observations. They establish why protected-main control publication and one candidate-bound `workflow_dispatch` are required; they do not authorize a remote write.

## Local Verification

Executed successfully on 2026-08-25:

```text
MIX_ENV=test mix test test/docs_contract/launch_execution_claims_test.exs test/scripts/public_release_verifier_test.exs --max-failures 1

29 tests, 0 failures
```

The command covers the inline trusted-workflow identity predicate, immutable candidate/tag assertions, and public-release verifier controls. The fast-forward and tag commands above also passed.

## Authorized Scope If Approved

Only an unqualified `approve-exact-control-and-docs` response authorizes all of the following, together and in order:

1. Fast-forward `origin/main` to local control SHA `881b97ffc10551f77e7c6f416bc91df2e1289025`.
2. Dispatch `HexDocs` from protected `main` once with candidate SHA `f03c78bab54efe1cd1596d51cf3f28193232e2a3` and tag `v1.3.4`.
3. Retain the emitted `hexdocs-candidate-binding` artifact for subsequent verifier/prerequisite work.

## Explicitly Excluded

This packet does **not** authorize force-pushes, tag creation/deletion/mutation, package publication, an alternate publisher or workflow, credential use outside the existing protected `Hex Publish` environment, or any retry/mutation of `v1.3.0`, `v1.3.1`, `v1.3.2`, or `v1.3.3`.

## Fail-Closed Stop Conditions

Stop with no external mutation if local workflow changes are uncommitted; `origin/main` is no longer an ancestor of `881b97ffc10551f77e7c6f416bc91df2e1289025`; `v1.3.4^{}` no longer peels to `f03c78bab54efe1cd1596d51cf3f28193232e2a3`; focused contracts fail; the requested dispatch ref is not protected `main`; or any requested identity/scope differs from this packet.

## Literal Decision Record

decision: pending

To authorize the exact scope, reply literally:

```text
approve-exact-control-and-docs
```

To leave all external state unchanged, reply literally:

```text
reject-or-revise
```

An approval may include reviewer identity, but it must not alter the bound control SHA, candidate SHA, tag, workflow name, or authorized scope.

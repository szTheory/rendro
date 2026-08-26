---
decision: terminal_binding_artifact_invalid_no_retry
packet_created_at_utc: 2026-08-25T18:20:00Z
packet_revised_at_utc: 2026-08-25T20:04:51Z
control_sha: 9f67a222b6e0a846656024035694ee27350e08f8
local_correction_control_sha: 283d753973fa5669b26c7249c10aa656ef86a0fd
dispatch_authority: spent
remote_baseline_sha: 7e28826cf9f0832063ea9fd922d6bb065a920fc4
candidate_sha: f03c78bab54efe1cd1596d51cf3f28193232e2a3
release_ref: v1.3.4
workflow_name: HexDocs
---

# Phase 131 HexDocs Retry Approval Packet

## Decision Required

This packet requests one fresh, literal decision for the corrected control. It does not reuse the consumed Plan 131-14/15 authority or authorize a retry of its terminal run.

**Exact proposed action:** integrate reviewed local correction control commit `9f67a222b6e0a846656024035694ee27350e08f8` into protected `origin/main`, then dispatch `HexDocs` from `main` exactly once with `candidate_commit_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3` and `release_ref=v1.3.4`.

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

The executable correction introduced by commits `fe491000822fe2490f848189b5dbd2ea86f6bead`
and `7e28826cf9f0832063ea9fd922d6bb065a920fc4` is limited to the structural
regression contract plus the explicit pre-contract fetch, annotated-tag-type assertion,
and peeled-candidate equality check. It adds no publisher, dependency, registry mutation,
token, secret use, or alternate workflow.

The protected-main fast-forward itself is broader because the approved control SHA includes
ten earlier local-only Phase 131 commits after remote baseline
`881b97ffc10551f77e7c6f416bc91df2e1289025`. The complete ordered range contains eleven
commits and the following path delta:

| Status | Path |
|---|---|
| M | `.github/workflows/hexdocs.yml` |
| M | `.planning/ROADMAP.md` |
| M | `.planning/STATE.md` |
| A | `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-14-SUMMARY.md` |
| R100 | `131-15-PLAN.md` → `131-15-TERMINAL-INCIDENT.md` |
| M | `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-16-PLAN.md` |
| M | `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-17-PLAN.md` |
| A | `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-18-PLAN.md` |
| A | `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-HEXDOCS-CONTROL-APPROVAL.md` |
| M | `test/docs_contract/launch_execution_claims_test.exs` |

The canonical ordered commit listing has SHA-256
`abec0f6fe1b74808d0c04e408f53e0a0b10a5944d45e40f17e98386cf449ca36`; the canonical
`git diff --name-status` listing has SHA-256
`a9c11367bb265b6c47db1a73a7c3d515add55344f0b64cc464e097e04402460c`.

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

## Local Binding-Writer Correction — No Dispatch Authority

status: local_correction_ready_external_authority_spent
recorded_at_utc: 2026-08-25T20:04:51Z

The successful dispatch `32891807712` remains immutable terminal evidence, not a valid
prerequisite source. Its `hexdocs-candidate-binding.json` is exactly 398 bytes with
SHA-256 `35ac6e892b50ede746ad7bd9bc096333aec5dad21cce90c37730504c6ef00b3a` and ends
`7d 5c 6e`: the writer appended JavaScript string `"\\n"`, producing literal
backslash-plus-`n` after the JSON object. `jq -e .` exits 5. The verifier remains strict;
this malformed advisory artifact is not normalized, reused, or used to write the canonical
prerequisite.

Local correction control `283d753973fa5669b26c7249c10aa656ef86a0fd`
(`fix(131-18): write parseable HexDocs binding`) replaces the unsafe construction with
`fs.writeFileSync("hexdocs-candidate-binding.json", JSON.stringify(evidence));`.
Its deterministic regression executes the exact embedded Node writer in an isolated fixture,
requires exactly one decoded binding map with the expected control/candidate/tag/workflow/run
identities, and keeps the exact `7d 5c 6e` malformed fixture as a decoder rejection.

| Local-control fact | Exact value |
|---|---|
| Correction control SHA | `283d753973fa5669b26c7249c10aa656ef86a0fd` |
| Baseline ancestor | `9f67a222b6e0a846656024035694ee27350e08f8` |
| Ordered local range | eight commits, `9f67a222b6e0a846656024035694ee27350e08f8..283d753973fa5669b26c7249c10aa656ef86a0fd` |
| Ordered-history SHA-256 | `3f9c330230a5c3fcb16a684613b6b5e2cddaf337a64fac04ee97b62ffbbfdb4b` |
| Name-status SHA-256 | `a21f4c9100615014480d77186f2eb4c7918c5547e379ce2b52237d3e58c279bb` |
| Workflow SHA-256 | `949402bf66f7412be323509b22c9bbb553a8fb2999b8c13781733f30ad6beb4b` |
| Launch-contract SHA-256 | `b08a63a038795295e424865efa40a8ce3f6d5ff63eddcc0ecbb3ccf9fc99342d` |
| Local verification | focused workflow/verifier contracts: 32 tests, 0 failures; `mix ci.fast`: pass |

### Machine-Gated Next-Attempt Policy

No action is authorized by this local correction: do not push, integrate protected main,
dispatch, rerun, approve an environment, retrieve another artifact, publish, mutate tags or
packages, or create the canonical prerequisite. A future attempt needs newly granted external
authority that explicitly binds a reviewed control, then the existing machine gates must pass in
order: protected-main non-force integration, exact-SHA push CI, one newly authorized dispatch,
successful `verify-docs-ready` and `publish-hexdocs`, and strict binding JSON/schema/identity
validation by the current verifier. Any failure consumes no implicit retry authority and stops.

For unattended retries, consider a separately designed idempotent release-intent record with a
durable consumed-dispatch state; it is intentionally out of scope for this repository-local fix.

## One-Time Recovery Authorization

decision: retry-once
literal_response: retry-once
reviewer_identity: user (interactive GSD blocking-human checkpoint)
recorded_at_utc: 2026-08-25T20:10:00Z

The user authorizes exactly one fresh recovery control: create a clean branch rooted at the
current `origin/main`, carry only local binding-writer correction
`283d753973fa5669b26c7249c10aa656ef86a0fd`, and integrate it through the repository's
normal protected PR and required-CI path. The recovery control's eventual merge SHA—not this
local planning SHA—must be revalidated by exact-SHA push CI and HexDocs verification before a
single newly created `HexDocs` `workflow_dispatch` may occur.

The sole prospective dispatch remains bound to
`candidate_commit_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3` and
`release_ref=v1.3.4`. No direct push to `main`, branch-protection bypass, force-push, tag or
package mutation, rerun, alternate publisher, verifier weakening, artifact fabrication, or
second dispatch is authorized. Any failed machine gate ends this recovery attempt automatically.

## Recovery Outcome

status: completed_verified
control_sha: f9b63246029396f76c443c5750aad42a3004081b
ci_push_run_id: 32896233006
hexdocs_push_run_id: 32896232999
hexdocs_dispatch_run_id: 32898926521
recorded_at_utc: 2026-08-25T21:13:00Z

Clean PR #47 merged normally at the control SHA above. Its exact-SHA push CI (including
`ci-success`) and credential-free HexDocs push verification both succeeded before the sole new
dispatch. Run `32898926521` is the only new `workflow_dispatch`; its `verify-docs-ready`
job `97967916084` and `publish-hexdocs` job `97969916166` succeeded. The sole bounded
`hexdocs-candidate-binding` artifact was valid JSON (SHA-256
`74fd616bfcd4b691b37cffdb5ef6ccd7e9e121b581dbea25feeb5be61cff4ccf`) and exactly bound
`refs/heads/main`, this control SHA, sealed candidate, `v1.3.4`, `HexDocs`,
`workflow_dispatch`, and this run. The prior canonical record was retained as legacy
package provenance (SHA-256 `505394af4ab54393ac06ac35592e8b2bfd935b3365983775191a2a7cca7278bf`);
the current verifier then solely wrote the replacement VERIFIED prerequisite.

## Conditional Post-Bypass Approval

decision: approved_conditionally_after_exact_sha_push_validation
literal_response: yes
reviewer_identity: user (interactive GSD checkpoint)
recorded_at_utc: 2026-08-25T19:44:00Z

The user answered **yes** to the exact checkpoint question: continue automatically if and
only if both current exact-SHA push runs succeed, consuming the one authorized HexDocs
dispatch. This accepts the already-landed approved control despite GitHub reporting the
required-CI protection bypass, but only if all of the following bounded facts hold before
any dispatch:

- CI run `32890265624` is a `push` run for `main` at
  `9f67a222b6e0a846656024035694ee27350e08f8`, completes successfully, and its required
  `ci-success` job succeeds.
- HexDocs verification run `32890265565` is a `push` run for `main` at the same SHA and
  completes successfully. It is not a `workflow_dispatch`, creates no binding, and does
  not consume dispatch authority.
- No other `HexDocs` `workflow_dispatch` has been created after the spent terminal run
  `32877290266`.

If any identity check or conclusion fails, is cancelled, or times out, execution stops with
no dispatch and no retry. If all checks pass, this decision authorizes exactly one new
`HexDocs` `workflow_dispatch` from `main` with
`candidate_commit_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3` and `release_ref=v1.3.4`.
It does not authorize an environment-policy bypass, a rerun, any additional dispatch, tag or
package mutation, artifact fabrication, or an alternative publisher.

## Dispatch Outcome — Binding Contract Failure

status: terminal_binding_artifact_invalid_no_retry
recorded_at_utc: 2026-08-25T19:58:00Z

The one authorized new dispatch was created exactly once as run `32891807712` on `main`.
It is `HexDocs` / `workflow_dispatch` at control SHA
`9f67a222b6e0a846656024035694ee27350e08f8`; both `verify-docs-ready` (job
`97945235644`) and `publish-hexdocs` (job `97947208198`) concluded `success`.

The downloaded sole `hexdocs-candidate-binding.json` artifact was 398 bytes with SHA-256
`35ac6e892b50ede746ad7bd9bc096333aec5dad21cce90c37730504c6ef00b3a`. Its otherwise expected
identity fields name the approved control, sealed candidate, `v1.3.4`, `HexDocs`, and run
`32891807712`; however, its final bytes are literal backslash-plus-`n` (`5c 6e`) after the JSON
object (`7d 5c 6e`). `jq -e .` therefore exits 5 with `Invalid numeric literal at EOF`.

This artifact is not a JSON map, so it fails the bounded binding prerequisite required by this
plan and by `Rendro.PublicReleaseVerifier`. The old canonical prerequisite remains untouched;
no legacy copy was made and no replacement VERIFIED record was written. The dispatched run is
retained as immutable advisory incident evidence. The sole dispatch authority is consumed:
there was no rerun, second dispatch, binding repair, policy bypass, tag/package mutation, or
manufactured prerequisite.

## Reconciled Literal Approval Received

decision: approved
packet_revision: range-reconciled-2026-08-25T19:36:00Z
literal_response: approve-reconciled-control-and-one-dispatch: packet_revision=range-reconciled-2026-08-25T19:36:00Z control_sha=9f67a222b6e0a846656024035694ee27350e08f8 remote_baseline_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 complete_nine_commit_history_sha256=fa3fa9d814b28456fd262e3313fceb872ebff782234917879893c324773fe669 complete_eight_path_delta_sha256=e1e125e3dda9a1818d46373507f99e61647f290ff101bca07d8200d941696d5b candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
reviewer_identity: user (interactive GSD blocking-human reconciliation checkpoint)
recorded_at_utc: 2026-08-25T19:31:21Z

This is the user's unqualified literal approval of the final reconciled packet revision.
It authorizes only its exact nine-commit/eight-path non-force protected-main integration
and one newly dispatched `HexDocs` workflow after every stated pre-mutation validation
passes. It does not transfer or broaden earlier approvals, dispatches, or incidents.

## Protected-Main Safety Stop After Integration

status: blocked_branch_protection_bypass
recorded_at_utc: 2026-08-25T19:31:21Z
remote_main_after_integration: 9f67a222b6e0a846656024035694ee27350e08f8

Every approval-bound local and remote identity check passed immediately before the
authorized non-force integration. The exact control was then sent to
`refs/heads/main`; GitHub accepted the fast-forward but returned the following
branch-protection notice:

```text
Bypassed rule violations for refs/heads/main:
- Required status check "ci-success" is expected.
```

The packet and reconciled approval prohibit bypassing branch protection and require
required CI conditions before the one new `HexDocs` dispatch. Therefore this is a
safety stop, not dispatch authority: no `workflow_dispatch` was created, no prior
run was rerun, no tag/package/environment was mutated, no binding artifact was
retrieved, and the canonical prerequisite was not regenerated or replaced.

Further work requires a new explicit human decision that addresses the already-landed
protected-main integration and its required-CI/protection state. The existing one-dispatch
authority is deliberately unconsumed and must not be assumed to transfer.

## Fresh Approval After Revision Review

decision: approved
literal_response: approve-corrected-control-and-one-dispatch: control_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
reviewer_identity: user (interactive GSD checkpoint)
recorded_at_utc: 2026-08-25T18:49:59Z

This fresh decision supersedes only the packet's earlier rejection. It authorizes the exact
corrected control, sealed candidate, release ref, protected-main integration, and one new
HexDocs dispatch stated above. It does not authorize rerunning terminal run `32877290266`,
changing a tag or package, force-pushing, using an alternate publisher, or dispatching more
than once.

## Preflight Scope Reconciliation

status: pending_blocking_human
recorded_at_utc: 2026-08-25T18:52:44Z

The pre-mutation fast-forward check found that the earlier approval described only the two-file
executable correction, while pushing the exact approved control SHA also integrates the complete
eleven-commit Phase 131 history enumerated above. The earlier approval is therefore insufficient
for external mutation and has been invalidated without any push or dispatch.

A new decision must explicitly acknowledge the complete
`881b97ffc10551f77e7c6f416bc91df2e1289025..7e28826cf9f0832063ea9fd922d6bb065a920fc4`
fast-forward history, including the listed planning artifacts, while retaining every existing
candidate, release, protected-main, one-dispatch, and stop-condition binding.

## Reconciled Literal Decision Record

decision: approved
literal_response: approve-reconciled-control-and-one-dispatch: packet_revision_sha=2367609794405381017e640b59a598977bd0a8eb control_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 remote_baseline_sha=881b97ffc10551f77e7c6f416bc91df2e1289025 complete_fast_forward_history=acknowledged planning_artifacts=acknowledged candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
reviewer_identity: user (interactive GSD checkpoint)
recorded_at_utc: 2026-08-25T19:00:04Z

This fresh decision binds packet revision `2367609794405381017e640b59a598977bd0a8eb`,
the complete eleven-commit fast-forward and listed planning artifacts, exact control SHA,
remote baseline, sealed candidate, release ref, protected-main integration, and exactly one
new HexDocs dispatch. Every previously stated stop condition remains in force.

## Protected-Main Integration Outcome and Safety Stop

status: blocked_remote_ci_failure
recorded_at_utc: 2026-08-25T19:08:15Z
protected_main_sha: 7e28826cf9f0832063ea9fd922d6bb065a920fc4
ci_run_id: 32887354057
ci_success_job_id: 97931741585
hexdocs_dispatch_consumed: false

The exact approved non-force fast-forward updated `origin/main` from
`881b97ffc10551f77e7c6f416bc91df2e1289025` to
`7e28826cf9f0832063ea9fd922d6bb065a920fc4`. GitHub accepted the update but reported that
the expected `ci-success` rule was bypassed. The push-triggered exact-SHA CI run
[`32887354057`](https://github.com/szTheory/rendro/actions/runs/32887354057) then produced a
terminal failure in required job `ci-success` (`97931741585`).

The primary OTP 28 / Elixir 1.19.5 test job `97930815451` failed because
`Rendro.DocsContract.LaunchExecutionClaimsTest` tried to resolve local `v1.3.4^{}` in the
generic Actions checkout, where that tag was absent. This is the same shallow-checkout class
that the HexDocs correction was meant to close, now exposed in the structural test itself.
The OTP 25 / Elixir 1.19.0 setup job `97930815435` also failed because that toolchain pair is
unavailable, and configurator-browser job `97930815410` reported four screenshot-height
mismatches. Local focused tests and `mix ci.fast` had passed before integration, so these
remote-only failures are retained as bounded CI evidence rather than normalized away.

No `HexDocs` workflow was dispatched. A read-only run inventory after the failure still
contained only terminal failed run `32877290266`; exactly-one new-dispatch authority remains
unconsumed but may not be used with this failed control. Any correction requires a new control
SHA, focused and remote validation, a revised packet, and fresh blocking-human approval.

## Superseding Correction Control and Fresh Decision Request

status: pending_blocking_human
packet_revision: post-`7e28826`-CI-repair
recorded_at_utc: 2026-08-25T19:36:00Z

This section supersedes every prior approval and rejection record in this packet for execution
purposes. The older terminal incident, failed control, earlier approvals, and CI runs remain
immutable historical evidence; none transfers authority to this correction.

| Fact | Exact value | Result |
|---|---|---|
| New correction control SHA | `9f67a222b6e0a846656024035694ee27350e08f8` | distinct from failed control `7e28826cf9f0832063ea9fd922d6bb065a920fc4` |
| Current remote baseline | `7e28826cf9f0832063ea9fd922d6bb065a920fc4` | `origin/main`, read-only observation |
| Required fast-forward | `7e28826cf9f0832063ea9fd922d6bb065a920fc4..9f67a222b6e0a846656024035694ee27350e08f8` | two correction commits; no force-push |
| Ordered range SHA-256 | `3648d68330e1ecc42494243192a316e72cedbba839dba6ab37815e733ac8600b` | `c2912e8`, then `9f67a22` |
| Range name-status SHA-256 | `e1e125e3dda9a1818d46373507f99e61647f290ff101bca07d8200d941696d5b` | bounded to CI workflow, launch contract, and four Chromium snapshots |
| HexDocs workflow SHA-256 | `44bfed3efc2a7ae8c53694112478104b45bfd63c98bdf4c9101659698927ef3a` | unchanged sealed-tag correction remains present |
| Launch-contract SHA-256 | `078b5807e41f117e5ebe6ec1460284a1f41cacc020f3b151bbb6c7fa2459d7cc` | no generic-checkout local-tag assumption |
| CI workflow SHA-256 | `623ba555485bb87268d2bf085cf2e244416d1e2e8a741e32e88f7d6dacf1ee55` | secondary matrix is OTP 26 / Elixir 1.19.0 |
| Candidate/tag | `f03c78bab54efe1cd1596d51cf3f28193232e2a3` / `v1.3.4` | annotated tag, peeled target matches candidate |

The correction closes every in-scope remote required-CI failure from run
`32887354057`: its launch-contract test no longer assumes the tag exists in a generic Actions
checkout; its unavailable OTP 25 / Elixir 1.19.0 secondary setup is replaced by OTP 26; and its
four pinned Chromium snapshots are refreshed from the reviewed Phase 130 catalog assets. The
current pinned-container browser suite and local deterministic lanes remain strict rather than
masked or made advisory.

### Immutable Run Inventory

- `32877290266` / job `97899588380` remains the failed, spent `workflow_dispatch` incident;
  job `97900969705` stayed skipped and no binding artifact exists.
- `32887354057` / `97931741585` remains the failed required-CI incident that required this
  correction. It was not rerun.
- `32887354106` is a separate push-triggered `HexDocs` verification run at the failed control
  SHA `7e28826…`; `verify-docs-ready` succeeded and `publish-hexdocs` was skipped. It is not a
  workflow dispatch, did not publish, did not create a binding artifact, and does not consume
  the one-dispatch authority.

### Local Verification for This Control

```text
MIX_ENV=test mix test test/docs_contract/launch_execution_claims_test.exs \
  test/scripts/public_release_verifier_test.exs --max-failures 1

31 tests, 0 failures

npm run test:container --prefix scripts/configurator_e2e

13 passed

mix ci.fast

pass
```

### Exact Fresh Approval Required

No external action is authorized by this packet until the user supplies the following
unqualified literal response through the blocking-human checkpoint:

```text
approve-corrected-control-and-one-dispatch: control_sha=9f67a222b6e0a846656024035694ee27350e08f8 remote_baseline_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
```

That literal approval authorizes only the exact non-force fast-forward of the two correction
commits and one later `HexDocs` `workflow_dispatch` from `main`. It does not authorize a rerun
of `32877290266` or `32887354057`, use of `32887354106` as a dispatch, force-push, tag/package
mutation, alternate publisher, environment bypass, publication before the job's own protected
environment approval, an extra dispatch, artifact fabrication, or canonical prerequisite
regeneration absent a successful newly dispatched run and its binding.

To leave external state unchanged, reply:

```text
reject-or-revise
```

## Literal Approval Received

decision: approved
literal_response: approve-corrected-control-and-one-dispatch: control_sha=9f67a222b6e0a846656024035694ee27350e08f8 remote_baseline_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
reviewer_identity: user (interactive GSD checkpoint)
recorded_at_utc: 2026-08-25T19:20:59Z

This is the user's unqualified literal approval for the exact named control,
baseline, candidate, release ref, protected-main integration, and one new
HexDocs workflow dispatch. It remains subject to the packet's required
pre-mutation fact validation; it does not broaden the stated scope.

## Pre-Mutation Validation Stop

status: blocked_range_mismatch
recorded_at_utc: 2026-08-25T19:20:59Z

No remote mutation was performed. The required remote baseline remains
`7e28826cf9f0832063ea9fd922d6bb065a920fc4`; the sealed candidate and annotated
`v1.3.4` tag validate; local workflow, contract, and CI hashes validate; and
authenticated GitHub access plus the required `ci-success` protected-main control
are available. However, the approval-bound fast-forward range is not the packet's
declared two commits. The actual ordered range is nine commits:

```text
48b5429405dbbd94d1bcc6adac75cd66bce6cb22
de69fe51183cc9873c969c7c5462c72e5ec430ce
54964804dd9e5b0af4d23edada11ad2772ddaec7
b5da699688762361762d4713e46c7cd113ae5f69
2367609794405381017e640b59a598977bd0a8eb
d71d81a1adff72b590793cacf7444d83329ca53d
f5a582af330ccb19d2725450a54b151ab392c473
c2912e87eeb46bab07e036d29948cffaa9f1add9
9f67a222b6e0a846656024035694ee27350e08f8
```

Its SHA-256 is
`a97ff9e001378603d38edbd1678f68d85c14747b04bfdb757edf19d4ddcad95a`, not the
packet's two-commit range hash
`3648d68330e1ecc42494243192a316e72cedbba839dba6ab37815e733ac8600b`.
The current exact name-status hash is still
`e1e125e3dda9a1818d46373507f99e61647f290ff101bca07d8200d941696d5b`.

Because that mismatch changes the approval-bound integration scope, execution
stops before protected-main integration or any workflow dispatch. A reconciled
packet and fresh blocking-human approval must name the actual nine-commit range
and its complete path delta before this plan may resume.

## Final Reconciliation and Fresh Decision Request

status: pending_blocking_human
packet_revision: range-reconciled-2026-08-25T19:36:00Z
recorded_at_utc: 2026-08-25T19:36:00Z

This final section supersedes every earlier approval and rejection record in this packet for
execution purposes. Earlier controls, approvals, terminal incidents, and CI runs remain immutable
evidence; none transfers authority to the corrected control below.

### Read-only Reconciliation Facts

`git ls-remote --heads origin refs/heads/main` returned
`7e28826cf9f0832063ea9fd922d6bb065a920fc4`. That baseline is still an ancestor of control
`9f67a222b6e0a846656024035694ee27350e08f8`.

| Fact | Exact value | Result |
|---|---|---|
| Reconciled packet revision | `range-reconciled-2026-08-25T19:36:00Z` | this decision request |
| New correction control SHA | `9f67a222b6e0a846656024035694ee27350e08f8` | distinct from failed control `7e28826cf9f0832063ea9fd922d6bb065a920fc4` |
| Current remote baseline | `7e28826cf9f0832063ea9fd922d6bb065a920fc4` | `origin/main`, read-only observation |
| Required non-force fast-forward | `7e28826cf9f0832063ea9fd922d6bb065a920fc4..9f67a222b6e0a846656024035694ee27350e08f8` | nine commits |
| Ordered-history SHA-256 | `fa3fa9d814b28456fd262e3313fceb872ebff782234917879893c324773fe669` | canonical `git log --format='%H%x09%s' --reverse` output |
| Name-status SHA-256 | `e1e125e3dda9a1818d46373507f99e61647f290ff101bca07d8200d941696d5b` | canonical `git diff --name-status` output |
| HexDocs workflow SHA-256 | `44bfed3efc2a7ae8c53694112478104b45bfd63c98bdf4c9101659698927ef3a` | sealed-tag correction remains present |
| Launch-contract SHA-256 | `078b5807e41f117e5ebe6ec1460284a1f41cacc020f3b151bbb6c7fa2459d7cc` | generic checkout has no local-tag assumption |
| CI workflow SHA-256 | `623ba555485bb87268d2bf085cf2e244416d1e2e8a741e32e88f7d6dacf1ee55` | secondary matrix is OTP 26 / Elixir 1.19.0 |
| Candidate/tag | `f03c78bab54efe1cd1596d51cf3f28193232e2a3` / `v1.3.4` | annotated tag object `84b0a632af6f6fa96af5fb515cecbbe18dcf6d37` peels to candidate |

### Complete Approval-Bound History

The complete ordered range is exactly:

```text
48b5429405dbbd94d1bcc6adac75cd66bce6cb22  docs(131-18): record corrected HexDocs approval packet
de69fe51183cc9873c969c7c5462c72e5ec430ce  docs(131-18): record rejected HexDocs control decision
54964804dd9e5b0af4d23edada11ad2772ddaec7  docs(131-18): record rejection checkpoint state
b5da699688762361762d4713e46c7cd113ae5f69  docs(131-18): record fresh HexDocs retry approval
2367609794405381017e640b59a598977bd0a8eb  docs(131-18): reconcile protected-main fast-forward scope
d71d81a1adff72b590793cacf7444d83329ca53d  docs(131-18): record reconciled HexDocs approval
f5a582af330ccb19d2725450a54b151ab392c473  docs(131-18): record protected-main CI safety stop
c2912e87eeb46bab07e036d29948cffaa9f1add9  fix(131-18): repair required CI gates
9f67a222b6e0a846656024035694ee27350e08f8  test(131-18): guard generic checkout tag independence
```

The complete name-status/path delta is exactly:

```text
M  .github/workflows/ci.yml
M  .planning/STATE.md
A  .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-HEXDOCS-RETRY-APPROVAL.md
M  scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/breakpoint-899-representative-linux.png
M  scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/desktop-dark-exact-linux.png
M  scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/desktop-light-exact-linux.png
M  scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/mobile-dark-representative-linux.png
M  test/docs_contract/launch_execution_claims_test.exs
```

The correction closes every in-scope remote required-CI failure from run `32887354057`: the
launch-contract test no longer assumes a generic checkout has the tag, the unavailable OTP 25
secondary setup is replaced by OTP 26, and the four reviewed Chromium snapshots are refreshed.
The pinned-container browser suite and deterministic lanes remain strict.

### Prior Approval Is Invalid

The literal approval recorded at `2026-08-25T19:20:59Z` is invalid and cannot authorize external
mutation. It named this control and baseline but asserted a two-commit fast-forward with history
hash `3648d68330e1ecc42494243192a316e72cedbba839dba6ab37815e733ac8600b`; the actual approved
scope is the nine commits and eight paths above, with history hash
`fa3fa9d814b28456fd262e3313fceb872ebff782234917879893c324773fe669`. The scope discrepancy is
material, so no prior approval, rejection, or spent authority transfers to this packet revision.

### Immutable Run Inventory

- `32877290266` / job `97899588380` remains the failed, spent `workflow_dispatch` incident;
  job `97900969705` stayed skipped and no binding artifact exists.
- `32887354057` / `97931741585` remains the failed required-CI incident that required this
  correction. It was not rerun.
- `32887354106` is a separate push-triggered `HexDocs` verification run at failed control
  `7e28826…`; `verify-docs-ready` succeeded and `publish-hexdocs` was skipped. It is not a
  workflow dispatch, did not publish, did not create a binding artifact, and does not consume
  the one-dispatch authority.

### Exact Fresh Approval Required

No external action is authorized until an unqualified literal response states:

```text
approve-reconciled-control-and-one-dispatch: packet_revision=range-reconciled-2026-08-25T19:36:00Z control_sha=9f67a222b6e0a846656024035694ee27350e08f8 remote_baseline_sha=7e28826cf9f0832063ea9fd922d6bb065a920fc4 complete_nine_commit_history_sha256=fa3fa9d814b28456fd262e3313fceb872ebff782234917879893c324773fe669 complete_eight_path_delta_sha256=e1e125e3dda9a1818d46373507f99e61647f290ff101bca07d8200d941696d5b candidate_sha=f03c78bab54efe1cd1596d51cf3f28193232e2a3 release_ref=v1.3.4 integrate protected-main and dispatch exactly one new HexDocs workflow
```

This authorizes only the exact non-force nine-commit fast-forward and one later `HexDocs`
`workflow_dispatch` from `main`. Stop before external mutation for a rejected, silent,
qualified, mismatched, or recycled approval; changed baseline/control/history/delta/hashes;
invalid tag type or peeled target; failed checks; unavailable protected-main or environment
approval; force-push; tag/package mutation; alternate publisher; extra dispatch; rerun; artifact
fabrication; prerequisite regeneration without a successful new dispatch and binding; or any
other external mutation not named above. In particular it does not authorize a rerun of
`32877290266` or `32887354057`, use of `32887354106` as a dispatch, environment bypass,
publication before the workflow's own protected environment approval, or artifact retrieval.

To leave all external state unchanged, reply:

```text
reject-or-revise
```

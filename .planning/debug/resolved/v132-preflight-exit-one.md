---
status: resolved
trigger: "Protected v1.3.2 release run 32586098785 passed exact version match and Run CI Checks, then Run Release Preflight exited 1 after about 2.5 minutes; Hex dry-run and publish were skipped."
created: 2026-08-22
updated: 2026-08-22
---

# Debug Session: v1.3.2 Release Preflight Exit One

## Symptoms

### Expected behavior

The protected tag-triggered release workflow for approved exact candidate `47af6448d2989ffe69c4b80c77935c896b1ddb07` should complete release preflight, complete its separate Hex dry run, publish Hex 1.3.2, and only then permit candidate-bound HexDocs dispatch.

### Actual behavior

Run `32586098785` passed setup, exact version matching, and `Run CI Checks`. `Run Release Preflight` started at `2026-08-22T17:04:19Z` and failed with exit code 1 at `17:06:49Z`. The separate Hex dry-run step and publish job were skipped. Hex 1.3.2 remains absent and HexDocs was not dispatched.

### Error messages

The public job annotation reports only `Process completed with exit code 1.` GitHub's authenticated API is rate-limited and the public/anonymous log endpoints do not expose the step body. The failing sub-check is not yet known.

### Timeline

The approved tag was pushed at candidate `47af6448d2989ffe69c4b80c77935c896b1ddb07`; protected run `32586098785` completed with failure in 12m48s. The release-preflight step itself ran for roughly 2m30s. Earlier exact-SHA private proof ran `mix ci.fast` separately and invoked the ref-free preflight wrapper with CI and security audits skipped; those gates passed in their documented lanes.

### Reproduction

In a clean detached worktree at candidate SHA `47af6448d2989ffe69c4b80c77935c896b1ddb07`, run the same complete `mix release.preflight` command and environment-sensitive checks used by `.github/workflows/release.yml`, capturing each sub-check. Compare with the remote timing and determine whether CI duplication, Hex/dependency audits, docs, package, or another environment-sensitive gate returns 1.

## Scope Constraints

- v1.3.0, v1.3.1, and v1.3.2 are immutable failed public tags; never move, delete, recreate, retry, or repush them.
- Do not publish via a local/alternate Hex command and do not dispatch HexDocs.
- Hex publish may be exercised only in dry-run mode as part of exact diagnostic reproduction.
- Preserve candidate/run/tag identities and the unrelated `.planning/config.json` modification.
- Diagnose and fix the smallest root cause, then require a newly versioned private candidate and fresh approval before any further public release.

## Current Focus

confirmed_root_cause: the root `:livebook` development dependency pulled an advisory-pinned, incompatible transitive graph into the release lockfile; it was used only to convert a non-runtime tutorial, so normal dependency refresh could not resolve it while that root constraint existed.
next_action: archived after supervisory confirmation; commit only the bounded remediation files and this resolved debug record, without release actions.
bug_class: bohrbug
remediation_scope: broadened per supervisory direction; evaluate removal/isolation before any audit-policy exception.
reasoning_checkpoint:
  hypothesis: "The protected preflight fails because root Livebook forces vulnerable transitive packages into mix.lock; isolating guide conversion removes that release-audited graph without removing package/docs/tutorial behavior."
  confirming_evidence:
    - "With only root Livebook/config removed and unused lock entries pruned, ci.fast completed and Hex build retained guides/livebook/first_invoice.livemd."
    - "The Livebook, KubeReq, Protobuf, Bandit, and Phoenix LiveView entries vanished from the probe lockfile; after normal permitted dependency refresh, both audits returned zero."
  falsification_test: "If the root-Livebook-free implementation cannot run the guide validation externally, cannot keep the guide in ExDoc/package output, or either audit still fails with the refreshed root lockfile, this remediation is wrong."
  fix_rationale: "Removing an unneeded root development dependency eliminates the advisory-pinned release graph; a separate short-lived Mix.install process preserves executable Livebook conversion without adding it to root mix.lock or the packaged runtime."
  blind_spots: "The external authoring process will independently resolve Livebook and therefore requires network/Hex availability when the advisory validation job runs; it is intentionally outside the root release audit graph."
  candidate_causes:
    - "code: the root project couples an authoring-only converter to its release dependency graph."
    - "data: current advisory feeds identify the versions transitively pinned by Livebook."
    - "environment: upstream Livebook releases available to the resolver do not yet allow patched transitive versions."
  and_gate: "yes — failure requires both the root coupling and the current advisory dataset marking Livebook's pinned graph; the remediation removes the coupling while retaining audit enforcement."
  hypothesis: "The v1.3.2 candidate’s locked dependencies are now vulnerable, so the complete preflight returns 1 because it runs both security audits; the prior proof skipped those audits."
  confirming_evidence:
    - "The exact detached candidate passed phase 1, CI, Docs Contract, Hex Build Unpack, and the unauthenticated Hex dry-run."
    - "The same run’s final summary reported Hex Audit: FAIL and Deps Audit: FAIL, then Overall: FAIL."
    - "The earlier private proof explicitly used --skip-security-audits."
  falsification_test: "With the same candidate and advisory database, if both security audits exit zero without changing the lockfile or ignore configuration, this diagnosis is wrong."
  fix_rationale: "Advance only affected dependency constraints and lock entries to non-vulnerable versions; retain the complete preflight and its audit checks so future releases remain protected."
  blind_spots: "The protected GitHub runner’s unavailable raw logs prevent a byte-for-byte audit finding comparison; package compatibility and the smallest safe upgrade set remain untested."
  candidate_causes:
    - "code: complete release preflight correctly executes audits not covered by mix ci."
    - "data: candidate mix.lock resolves versions now matched by security advisories."
    - "environment: the external advisory database changed after the candidate’s earlier private proof."
  and_gate: "yes — the exit requires both the complete preflight’s audit branch and advisory data matching vulnerable locked versions; the fix must preserve the branch while remediating its dependency inputs."
bug_class: bohrbug (the protected job consistently failed at one aggregate step; deterministic reproduction is the first route)
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-22
  checked: public workflow run 32586098785 and job 97062582546
  found: exact version and first CI succeeded; Run Release Preflight failed from 17:04:19Z to 17:06:49Z; later dry-run/publish were skipped.
  implication: failure is inside the aggregate preflight and before all registry mutation.

- timestamp: 2026-08-22
  checked: public tag and registry/docs state
  found: annotated v1.3.2 tag object `9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd` peels to approved candidate; Hex 1.3.2 is 404; HexDocs was never dispatched.
  implication: diagnosis can remain fail-closed and no partial package/docs publication requires repair.

- timestamp: 2026-08-22
  checked: workspace and candidate metadata
  found: the working tree has only the explicitly protected unrelated `.planning/config.json` modification plus this untracked debug session; the exact candidate is `47af6448d2989ffe69c4b80c77935c896b1ddb07` and declares version `1.3.2`.
  implication: a detached worktree can reproduce the candidate without touching protected tags or user changes.

- timestamp: 2026-08-22
  checked: project and configured debugger skills
  found: no `.codex/skills` or `.agents/skills` directories were present and the debugger-skill query returned no configured skills.
  implication: no project-specific skill rules constrain this investigation.

- timestamp: 2026-08-22
  checked: exact candidate release-preflight code and its tests
  found: the complete preflight executes CI, Docs Contract, Hex Build Unpack, Hex Publish Dry Run, Hex Audit, and Deps Audit; the prior private proof passed with both CI and security audits explicitly skipped.
  implication: the protected failure is expected to reside in a branch the private proof did not exercise, with security-audit behavior the highest-timing candidate.

- timestamp: 2026-08-22
  checked: knowledge-base recall
  found: MemPalace is unavailable; keyword fallback found no two-token match among the two resolved sessions.
  implication: no prior resolution is a candidate diagnosis.

- timestamp: 2026-08-22
  checked: complete command composition and security-audit configuration
  found: unauthenticated Hex dry-run is explicitly accepted only after reaching Hex’s authentication boundary; security audits invoke `mix hex.audit` and `mix deps.audit --ignore-file .mix_audit.ignore`, which contains three GHSA ignore IDs.
  implication: the reproduction must retain the full command and an unset API key, while each audit result is independently observable from the preflight summary.

- timestamp: 2026-08-22
  checked: clean detached candidate worktree setup
  found: `/tmp/rendro-v132-preflight-debug` is detached at exactly `47af6448d2989ffe69c4b80c77935c896b1ddb07` with a clean worktree and no tag changes. Local `mix deps.get` reported multiple current advisories and exited nonzero before the aggregate command could run.
  implication: the intended reproduction path was interrupted locally before preflight; direct aggregate execution is required to distinguish an environment/tool-version difference from the protected job’s later preflight exit.

- timestamp: 2026-08-22
  checked: direct aggregate preflight output in the detached candidate worktree
  found: the original run passed clean-worktree, candidate-SHA, package metadata, source-ref, changelog, and Hex artifact checks, then started `mix ci.fast`; an accidental second local invocation was blocked on the same build-directory lock.
  implication: no phase-1 boundary check explains the protected failure; the duplicate must be removed before phase-2 evidence can be trusted.

- timestamp: 2026-08-22
  checked: exact candidate’s complete preflight in `/tmp/rendro-v132-preflight-debug`
  found: the run passed phase 1, CI, Docs Contract, Hex Build Unpack, and unauthenticated Hex Publish Dry Run, then reported `Hex Audit: FAIL`, `Deps Audit: FAIL`, and `Overall: FAIL`. The visible audit output flags vulnerable locked packages including mint 1.7.1, protobuf 0.13.0, and req 0.5.8.
  implication: the root cause is confirmed: newly reported vulnerability data matches dependencies locked by v1.3.2, in the release-only audit branch skipped by the prior private proof. No publication step was reached.

- timestamp: 2026-08-22
  checked: full audit output and `mix deps.tree` for the exact candidate
  found: both audits report mint 1.7.1 (patched at 1.9.0), protobuf 0.13.0 (patched at 0.16.1), and req 0.5.8 (patched at 0.6.1/0.6.0). The direct `req ~> 0.5` constraint reaches mint, while the direct `livebook ~> 0.19.8` path reaches kubereq, req, mint, and protobuf.
  implication: a lockfile-only update cannot remediate all findings; the minimal candidate fix must advance the direct `req` and `livebook` constraints to versions that permit the patched transitive releases.

- timestamp: 2026-08-22
  checked: current Hex package metadata
  found: patch-compatible Livebook 0.19.9 and KubeReq 0.4.5 are available; Req 0.6.1+, Mint 1.9.0+, and Protobuf 0.16.1+ satisfy the advisory minimums.
  implication: start by updating only Livebook inside the existing constraint to measure its transitive remediation before changing the direct Req requirement.

- timestamp: 2026-08-22
  checked: isolated `mix deps.update livebook` from the exact candidate with `mix.exs` unchanged
  found: resolving Livebook 0.19.9 upgraded Mint to 1.9.3 (and compatible Finch/HPAX), but retained KubeReq 0.4.2, Req 0.5.8, and Protobuf 0.13.0; both audit commands still report failures.
  implication: a patch-level Livebook update alone remediates Mint but cannot lift the vulnerable Req or Protobuf paths; changing the direct Req constraint and a broader Livebook constraint are separately necessary candidates.

- timestamp: 2026-08-22
  checked: Hex release metadata for Livebook 0.19.9 and KubeReq 0.4.2/0.4.5
  found: the newest available Livebook 0.19.9 pins KubeReq 0.4.2, Req 0.5.8, and Protobuf 0.13.0 exactly; KubeReq 0.4.2 requires Req `~> 0.5.0`, whereas KubeReq 0.4.5 requires Req `~> 0.7.0`.
  implication: neither the existing Livebook constraint nor a direct Req 0.6.x constraint can satisfy the resolver without an unavailable newer Livebook release or an explicit override; direct Req update must be tested as a falsification experiment before deciding scope.

- timestamp: 2026-08-22
  checked: fresh detached probe with only direct Req changed from `~> 0.5` to `~> 0.6.1`
  found: Mix resolution failed: Livebook `~> 0.19.8` requires exact Req 0.5.8, which conflicts with Req `~> 0.6.1`.
  implication: the direct-Req-only remediation hypothesis is eliminated; the candidate cannot satisfy the required Req advisory floor while retaining the available Livebook release line.

- timestamp: 2026-08-22
  checked: current audit output after isolated Livebook 0.19.9 resolution
  found: beyond the Req and Protobuf findings, the audit feed now flags Bandit 1.11.1, Phoenix 1.8.7, Phoenix LiveView 1.1.24, and Plug 1.19.2; all are exact dependencies pinned by Livebook 0.19.9.
  implication: even an unproven override for Req/Protobuf would not make either security gate pass without additional dependency-policy changes that the scope expressly disallows.

- timestamp: 2026-08-22
  checked: root dependency declaration, package manifest, ExDoc configuration, CI/release wiring, and all source/test references to Livebook/Kino
  found: Livebook is a `dev/test`, `runtime: false` root dependency; it appears in Dialyzer's extra applications and is used at runtime only by `Mix.Tasks.Rendro.Livebook.Check`. The `.livemd` is included independently in the Hex package's `guides` directory and ExDoc `extras`; release preflight does not invoke the guide task. Root `config/config.exs` contains only Livebook tooling configuration.
  implication: there is a concrete, testable removal path: remove Livebook and its config from the root graph, preserve the guide/package/docs declarations, and move converter execution to an external ephemeral tool.

- timestamp: 2026-08-22
  checked: detached removal probe with Livebook removed from `mix.exs`, Dialyzer applications, and root config
  found: `mix ci.fast` completed in the probe and `mix hex.build` listed `guides/livebook/first_invoice.livemd` in the package. Its first audit still failed because the copied lockfile retained Livebook and all now-unused transitives.
  implication: root declaration removal is compatible with core CI/docs/package behavior; a stale-lockfile audit is not evidence against the approach and must be pruned before evaluating the release graph.

- timestamp: 2026-08-22
  checked: pruned root-Livebook-free probe lockfile and repeated security audits
  found: Livebook, KubeReq, Protobuf, Bandit, and Phoenix LiveView no longer appear in `mix.lock`, proving their release-audit presence was exclusively from Livebook. Both audits still flag direct Req 0.5.8 and its Mint 1.7.1 transitive, plus existing direct Phoenix/Plug and development tooling advisories.
  implication: removing Livebook eliminates its incompatible transitive set but a passing release audit also requires normal safe updates of the remaining root dependencies; audit policy is not a valid remediation.

- timestamp: 2026-08-22
  checked: implemented external tutorial conversion
  found: the root task now invokes `scripts/verify_livebook.exs`, whose short-lived process supplies only the two Livebook compile settings required by standalone `Mix.install`; `mix rendro.livebook.check` completes with `Livebook tutorial VERIFIED` while root `mix.lock` contains no Livebook.
  implication: executable guide validation is retained without restoring authoring tooling to the root release graph.

- timestamp: 2026-08-22
  checked: final verification of the implemented removal/isolation change
  found: `mix test test/mix/tasks/rendro_livebook_check_test.exs` passed (8 tests); `mix rendro.livebook.check` reported `Livebook tutorial VERIFIED`; `mix ci.fast` passed with 1,862 tests, docs, Credo, and Dialyzer; the package contained both the `.livemd` guide and converter script; `mix deps.audit` and `mix hex.audit` both returned zero with no root Livebook lock entry.
  implication: option A satisfies the required source, executable-guide, docs/package, CI, and security-audit boundaries without advisory ignores.

## Eliminated

- hypothesis: a direct Req constraint update to `~> 0.6.1` is compatible with the candidate's existing Livebook `~> 0.19.8` constraint
  evidence: fresh resolver probe failed because available Livebook requires Req 0.5.8 exactly
  timestamp: 2026-08-22

## Resolution

root_cause: the release preflight's security audits correctly reject advisory-matched locked dependencies; the latest available Livebook 0.19.9 pins Req 0.5.8, Protobuf 0.13.0, and other currently advised packages, preventing a compatible direct Req/Livebook-only upgrade.
fix: removed root Livebook tooling/configuration, refreshed the allowed root dependency lockfile, and moved `.livemd` conversion to an external ephemeral `Mix.install` script with a regression contract against root-graph reintroduction.
files_changed: [mix.exs, mix.lock, config/config.exs, lib/mix/tasks/rendro/livebook/check.ex, scripts/verify_livebook.exs, test/mix/tasks/rendro_livebook_check_test.exs]
verification:
  target_test: {result: pass, suites_run: ["mix test test/mix/tasks/rendro_livebook_check_test.exs", "mix rendro.livebook.check"]}
  mutation_check: {result: skipped, reason_if_skipped: "Stryker is not configured for this Elixir project"}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true}
  adjacent_tests: {result: pass, suites_run: ["mix ci.fast", "mix hex.build package-content inspection", "mix deps.audit --ignore-file .mix_audit.ignore", "mix hex.audit"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: "The exact unmodified candidate's complete preflight reproduced both audit failures; detached removal/update probe made both audits pass before the implementation was applied to the main worktree."}
  guardrail_verdict: accepted

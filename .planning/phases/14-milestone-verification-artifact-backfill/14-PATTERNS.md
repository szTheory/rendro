# Phase 14: Milestone Verification Artifact Backfill - Pattern Map

**Mapped:** 2026-04-28
**Scope targets:** 5 new milestone-grade `VERIFICATION.md` artifacts for Phases `07`-`11`, summary metadata normalization, and `REQUIREMENTS.md` traceability sync
**Primary analog set:** Phases `03`, `04`, `05`, `06`, `10`, `11`, `12`, `13`

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md` | verification-artifact | traceability sync | `.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md` | exact |
| `.planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md` | verification-artifact | traceability sync | `.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md` | exact |
| `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` | verification-artifact | traceability sync | `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` | exact |
| `.planning/phases/10-recipe-correctness-and-traceability/10-VERIFICATION.md` | verification-artifact | re-verification | `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` | exact |
| `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VERIFICATION.md` | verification-artifact | reconstruction audit | `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md` | role-match |
| `.planning/phases/07-phoenix-adapter-hardening/07-01-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/12-verification-chain-closure/12-01-SUMMARY.md` | role-match |
| `.planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/12-verification-chain-closure/12-02-SUMMARY.md` | role-match |
| `.planning/phases/09-ci-and-release-hardening/09-01-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/13-docs-and-release-preflight-closure/13-02-SUMMARY.md` | role-match |
| `.planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/13-docs-and-release-preflight-closure/13-03-SUMMARY.md` | role-match |
| `.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md` | summary-artifact | metadata + traceability sync | `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md` | role-match |
| `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md` | exact |
| `.planning/phases/12-verification-chain-closure/*-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/12-verification-chain-closure/12-01-SUMMARY.md` | exact |
| `.planning/phases/13-docs-and-release-preflight-closure/*-SUMMARY.md` | summary-artifact | metadata sync | `.planning/phases/13-docs-and-release-preflight-closure/13-01-SUMMARY.md` | exact |
| `.planning/REQUIREMENTS.md` | traceability-doc | status sync | `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md` | role-match |
| `Phase 14 plan set (if decomposed into multiple plans)` | plan-artifact | phased decomposition | `.planning/phases/12-verification-chain-closure/12-01-PLAN.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-01-PLAN.md` | exact |
| `Phase 14 VALIDATION.md` or any backfilled `07`-`09` `VALIDATION.md` if scope expands | validation-artifact | verification contract | `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VALIDATION.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-VALIDATION.md` | exact |

## Pattern Assignments

### `.planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md`

**Primary analog:** `.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md`

Use the reconstructed requirement-first shell from [03-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md:1):

```md
---
phase: 03-adapter-and-ops-integration
verified: 2026-04-28T00:00:00Z
status: reconstructed
requirements:
  - ADPT-01
  - ADPT-02
  - ADPT-03
  - ADPT-04
  - OBS-02
  - OBS-04
---
```

Copy the per-requirement block shape from [03-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md:24):

```md
## Requirement: ADPT-01

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/phoenix_test.exs`
**Supporting evidence:** `lib/rendro/adapters/phoenix.ex`, `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex`
**Why this closes the requirement:** ...
```

Close with the compact coverage and artifact appendices from [03-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md:66).

**Secondary analog for mixed outcomes:** if any Phase 7 requirement is still not fully closed, copy the `Partial` / `Blocked` wording discipline from [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:23).

### `.planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md`

**Primary analog:** `.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md`
**Secondary analog:** `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md`

Use the same parseable per-requirement shell as [03-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md:24) so the final Phase 14 traceability sync can read one consistent schema across `07`-`11`:

```md
## Requirement: OBS-02

**Status:** Done
**Primary proof:** `mix test test/rendro/pipeline_test.exs`
**Supporting evidence:** `test/rendro/adapters/oban/render_worker_test.exs`, `lib/rendro/adapters/oban/render_worker.ex`
**Why this closes the requirement:** ...
```

Phase 08 must include explicit blocks for `ADPT-04`, `ADPT-05`, `OBS-02`, and `OBS-04`. This parseable requirement-first structure is authoritative. After those blocks, append the richer milestone sections from [06-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md:34) if they add clarity:

- `Observable Truths`
- `Key Link Verification`
- `Behavioral Spot-Checks`
- `Anti-Patterns Found`
- `Gaps Summary`

This keeps the telemetry-oriented narrative from Phase 06 while removing the schema contradiction that would otherwise break the final parser.

### `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md`

**Primary analog:** `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md`

Use the quality/release truthfulness pattern from [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:15):

```md
**Phase Goal:** Reconstruct Phase 4 against the live quality and release surfaces, using `11-VALIDATION.md` as the execution contract and a temporary clean worktree at current `HEAD` for the decisive command proofs.
```

The critical pattern to copy is the requirement block that allows honest non-`Done` verdicts, from [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:23):

```md
**Status:** Partial
**Primary proof:** temporary clean worktree run of `mix ci`
**Supporting evidence:** `mix.exs`, `.github/workflows/ci.yml`
**Why this does not fully close the requirement:** ...
```

For Phase 9, prefer clean-worktree or named proof-surface evidence over active-workspace state, exactly as [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:19-21) does.

### `.planning/phases/10-recipe-correctness-and-traceability/10-VERIFICATION.md`

**Primary analog:** `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md`

Phase 10 is the clearest re-verification analog. Copy these frontmatter/report conventions from [05-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md:1):

```md
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
```

Also copy these sections:

- `Observable Truths` and `Roadmap Success Criteria Coverage` from lines `29-52`
- `Key Link Verification` from lines `69-78`
- `Requirements Coverage` from lines `104-110`
- `Anti-Patterns Found` from lines `112-122`
- `Human Verification Required` from lines `124-167`

This is the right shape for Phase 10 because the phase is explicitly about closing earlier verification debt and recording what changed since the prior artifact.

### `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VERIFICATION.md`

**Primary analog:** `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md`

Phase 11 needs milestone-grade verification for a meta-phase. Use the richer milestone report style from [06-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md:32) rather than the simpler reconstructed `03`/`04` shell.

Add a meta-level requirements/proof section that mirrors the execution claims in [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:15):

```md
provides:
  - "Reconstructed PLAN/SUMMARY/VERIFICATION triads for phases 01 through 04"
  - "Phoenix conn-boundary proof test for ADPT-01 and ADPT-02"
  - "Truth-synced .planning/REQUIREMENTS.md ..."
```

And preserve the central rule from [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:49):

```md
patterns-established:
  - "Reconstructed artifacts explicitly cross-reference their own PLAN/SUMMARY/VERIFICATION filenames to keep traceability self-contained."
  - "Central requirements rows update immediately from phase verification verdicts, while coverage totals are recomputed only at final closeout."
```

### Summary Metadata Repair

**Primary analog:** `.planning/phases/12-verification-chain-closure/12-01-SUMMARY.md`
**Also use:** `.planning/phases/12-verification-chain-closure/12-02-SUMMARY.md`, `.planning/phases/12-verification-chain-closure/12-03-SUMMARY.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-01-SUMMARY.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-02-SUMMARY.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-03-SUMMARY.md`

Copy the summary frontmatter field set from [12-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/12-verification-chain-closure/12-01-SUMMARY.md:1):

```md
---
phase: 12-verification-chain-closure
plan: 01
subsystem: infra
tags: [github-actions, ci, phoenix, verification]
requires:
  - phase: 11-reconstruct-phase-1-4-artifacts
    provides: ...
provides:
  - ...
affects: [...]
tech-stack:
  added: []
  patterns:
    - ...
key-files:
  created:
    - ...
  modified: []
key-decisions:
  - ...
patterns-established:
  - ...
requirements-completed: [QUAL-01, QUAL-03]
duration: 2min
completed: 2026-04-28
---
```

**Normalization rule:** keep this shape, but rename `requirements-completed` to `requirements_completed`. There is no positive in-repo analog for the correct key; the audit is the authority. See [v1.0-v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/rendro/.planning/v1.0-v1.0-MILESTONE-AUDIT.md:84).

**Files that most clearly need this repair:**

- Missing frontmatter entirely: [07-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/07-phoenix-adapter-hardening/07-01-SUMMARY.md:1), [08-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md:1), [09-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/09-ci-and-release-hardening/09-01-SUMMARY.md:1), [09-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md:1)
- Have structured frontmatter but wrong key: [10-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md:1), [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:1), all `12-*` and `13-*` summaries

### `.planning/REQUIREMENTS.md`

**Primary analog:** Phase 11 traceability sync pattern

Use the immediate-sync rule explicitly stated in [11-VALIDATION.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VALIDATION.md:41):

```md
Phase ... verdicts cite executable proof only and immediately sync owned traceability rows
```

Also follow the summary-level rule from [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:72):

```md
- Synced `.planning/REQUIREMENTS.md` incrementally after each reconstructed phase and finished with exact coverage totals ...
```

For Phase 14, that means:

- Update rows only after the new `07`-`11` `VERIFICATION.md` verdicts exist.
- Recompute coverage totals only after the final affected phase closes.
- Keep statuses aligned with the requirement table vocabulary visible in [REQUIREMENTS.md](/Users/jon/projects/rendro/.planning/REQUIREMENTS.md:95): `Pending`, `Done`, `Partial`, `Blocked`.

### Validation Pattern for Any Backfilled `VALIDATION.md`

**Primary analog:** `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VALIDATION.md`
**Secondary analog:** `.planning/phases/13-docs-and-release-preflight-closure/13-VALIDATION.md`

Use the reconstructed validation contract shape from [11-VALIDATION.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VALIDATION.md:1):

```md
phase: 11
slug: reconstruct-phase-1-4-artifacts
status: ready
nyquist_compliant: true
wave_0_complete: false
created: ...
```

Copy these sections in order:

- `Test Infrastructure`
- `Sampling Rate`
- `Per-Task Verification Map`
- `Wave 0 Requirements`
- `Manual-Only Verifications`
- `Validation Sign-Off`

For manual-proof edges, copy the explicit human-needed wording from [13-VALIDATION.md](/Users/jon/projects/rendro/.planning/phases/13-docs-and-release-preflight-closure/13-VALIDATION.md:63):

```md
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strict tagged-release happy path ... | QUAL-04 | ... | ... |
```

### Plan Decomposition Pattern for Phase 14

**Primary analogs:** `.planning/phases/12-verification-chain-closure/12-01-PLAN.md`, `.planning/phases/12-verification-chain-closure/12-02-PLAN.md`, `.planning/phases/12-verification-chain-closure/12-03-PLAN.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-01-PLAN.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-02-PLAN.md`, `.planning/phases/13-docs-and-release-preflight-closure/13-03-PLAN.md`

Copy this frontmatter decomposition contract from [12-01-PLAN.md](/Users/jon/projects/rendro/.planning/phases/12-verification-chain-closure/12-01-PLAN.md:1):

```md
phase: "12"
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - ...
requirements:
  - ...
must_haves:
  truths:
    - ...
  artifacts:
    - path: ...
      provides: ...
  key_links:
    - from: ...
      to: ...
      via: ...
      pattern: ...
```

And keep the plan body narrow like [12-02-PLAN.md](/Users/jon/projects/rendro/.planning/phases/12-verification-chain-closure/12-02-PLAN.md:59) and [13-03-PLAN.md](/Users/jon/projects/rendro/.planning/phases/13-docs-and-release-preflight-closure/13-03-PLAN.md:107):

- one requirement slice or proof-surface repair per plan
- explicit `<task>` blocks with `files`, `read_first`, `action`, `acceptance_criteria`, `verify`, `done`
- threat model and verification sections kept close to the changed proof surface

Recommended Phase 14 decomposition:

1. Plan 01: backfill `07-VERIFICATION.md` and normalize `07-01-SUMMARY.md`
2. Plan 02: backfill `08-VERIFICATION.md` and normalize `08-01-SUMMARY.md`
3. Plan 03: backfill `09-VERIFICATION.md` plus `09-01/09-02-SUMMARY.md`
4. Plan 04: backfill `10-VERIFICATION.md`, fix `10-02-SUMMARY.md`, and align `ADPT-05`
5. Plan 05: backfill `11-VERIFICATION.md`, normalize `11-01-SUMMARY.md`, then resync `.planning/REQUIREMENTS.md` and later summary metadata

## Shared Patterns

### Requirement-First Verification Is the Source of Truth

**Sources:** [03-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md:24), [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:23)

Use this exact requirement block schema everywhere:

```md
## Requirement: REQ-ID

**Status:** Done|Partial|Blocked
**Primary proof:** `command or test`
**Supporting evidence:** `files`
**Why this closes the requirement:** ...
```

### Milestone Reports Need More Than Requirement Blocks

**Sources:** [05-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md:29), [06-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md:54)

For milestone-grade artifacts, add:

- `Observable Truths`
- `Key Link Verification`
- `Behavioral Spot-Checks`
- `Requirements Coverage`
- `Anti-Patterns Found`
- `Human Verification Required` when needed

### Summary Frontmatter Must Be Machine-Readable

**Sources:** [12-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/12-verification-chain-closure/12-01-SUMMARY.md:1), [13-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/13-docs-and-release-preflight-closure/13-01-SUMMARY.md:1), [v1.0-v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/rendro/.planning/v1.0-v1.0-MILESTONE-AUDIT.md:84)

Keep:

- `phase`
- `plan`
- `subsystem`
- `tags`
- `requires`
- `provides`
- `affects`
- `tech-stack`
- `key-files`
- `key-decisions`
- `patterns-established`
- `requirements_completed`
- `duration`
- `completed`

### Traceability Sync Happens After Verification, Not Before

**Sources:** [11-VALIDATION.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-VALIDATION.md:41), [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:97)

Do not infer requirement closure from plans or summaries. Only the final `VERIFICATION.md` verdicts should drive `REQUIREMENTS.md` updates.

## Anti-Patterns To Avoid

| File/Pattern | Source | Why to avoid |
|--------------|--------|--------------|
| Summary with no frontmatter | [07-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/07-phoenix-adapter-hardening/07-01-SUMMARY.md:1), [08-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md:1), [09-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/09-ci-and-release-hardening/09-01-SUMMARY.md:1), [09-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md:1) | Workflow extraction cannot discover evidence or requirement closure from plain prose summaries. |
| `requirements-completed` key | [v1.0-v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/rendro/.planning/v1.0-v1.0-MILESTONE-AUDIT.md:87) | Automation expects `requirements_completed`; the hyphenated key is explicitly called out as workflow debt. |
| Frontmatter/body contradiction | [10-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md:9), [10-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md:24), [10-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md:48) | The frontmatter says `requirements-completed: [QUAL-04]` while the body says `QUAL-04` remains pending. Phase 14 must make metadata match the prose verdict. |
| Updating requirements from intention instead of proof | [10-02-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md:24), [11-01-SUMMARY.md](/Users/jon/projects/rendro/.planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md:97) | Phase 10 already shows how easy it is to drift. Phase 14 should only resync after backfilled verification exists. |
| Dirty-workspace quality proof | [04-VERIFICATION.md](/Users/jon/projects/rendro/.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md:19) | Quality/release claims must be based on clean worktrees or explicit proof helpers, not whatever happens to be lying around locally. |
| Leaving milestone artifact debt open after state says complete | [v1.0-v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/rendro/.planning/v1.0-v1.0-MILESTONE-AUDIT.md:130) | The audit explicitly marks Phases `07`-`11` as completed in state but not milestone-verified. Phase 14 exists to eliminate exactly this inconsistency. |

## No Positive Analog Found

| Need | Result |
|------|--------|
| Correct `requirements_completed` key in summary frontmatter | No existing positive in-repo example. Use the current `12`/`13` summary frontmatter shape, but rename the key per the audit. |
| Milestone-grade `VERIFICATION.md` for Phase 11 itself | No exact existing meta-phase analog. Use the rich milestone report structure from `06-VERIFICATION.md`, then tailor the evidence tables to artifact reconstruction and requirements-sync behavior. |

## Metadata

**Analog search scope:** `.planning/phases/03`, `04`, `05`, `06`, `10`, `11`, `12`, `13`, plus `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`
**Key findings:**
- `03` and `04` are the canonical requirement-first verification shells for reconstructed phase artifacts.
- `05` and `06` are the canonical milestone-grade verification reports with truth tables, spot-checks, and anti-pattern sections.
- `12` and `13` provide the current summary frontmatter contract and narrow plan decomposition pattern.
- Summary metadata is currently inconsistent in two ways: older summaries lack frontmatter entirely, and newer ones still use the wrong `requirements-completed` key.

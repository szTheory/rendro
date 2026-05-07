# Phase 14: milestone-verification-artifact-backfill - Research

**Researched:** 2026-04-28 [VERIFIED: system date]
**Domain:** GSD verification artifact backfill, milestone traceability repair, and Nyquist validation normalization for Phases 07 through 11. [VERIFIED: .planning/ROADMAP.md; user prompt]
**Confidence:** HIGH [VERIFIED: codebase-only scope with direct artifact inspection]

## User Constraints

- Phase 14 must produce `.planning/phases/14-milestone-verification-artifact-backfill/14-RESEARCH.md` and focus on milestone-grade verification artifact backfill for Phases 07 through 11. [VERIFIED: user prompt]
- No runtime code edits are allowed in this phase. [VERIFIED: user prompt]
- Documentation claims must be treated as contracts. [VERIFIED: AGENTS.md; user prompt]
- The work must focus on truthful artifact backfill and executable evidence, not rewriting history. [VERIFIED: user prompt]
- Phase 14 has no `CONTEXT.md`; research scope must come from roadmap, requirements, audit, and prior artifacts only. [VERIFIED: user prompt; .planning/phases/14-milestone-verification-artifact-backfill directory listing]

## Summary

Phase 14 is a documentation-and-evidence phase, not a runtime implementation phase. The repo already has the proof surfaces needed to verify the later gap-closure work, but Phases 07, 08, 09, 10, and 11 are structurally incomplete as milestone artifacts because they either lack `VERIFICATION.md`, lack a Nyquist-grade `VALIDATION.md`, or carry summary metadata that automation cannot reliably extract. [VERIFIED: .planning/v1.0-v1.0-MILESTONE-AUDIT.md; phase directory listings; 10-VALIDATION.md; 11-VALIDATION.md]

The strongest in-repo verification pattern is already established by `03-VERIFICATION.md`, `04-VERIFICATION.md`, `05-VERIFICATION.md`, `06-VERIFICATION.md`, and `12-VERIFICATION.md`: frontmatter first, `## Goal Achievement`, requirement-first coverage, executable proof commands, explicit artifact appendix, and honest mixed verdicts where applicable. Phase 14 should reuse that pattern exactly rather than inventing a new artifact shape. [VERIFIED: .planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md; .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md; .planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md; .planning/phases/12-verification-chain-closure/12-VERIFICATION.md; .planning/phases/11-reconstruct-phase-1-4-artifacts/11-PATTERNS.md]

The highest-risk drift is not missing prose; it is mismatched truth between summaries, validation artifacts, and the central traceability table. The audit already proves three concrete failures: `10-02-SUMMARY.md` claims `requirements-completed: [QUAL-04]` while its body says `QUAL-04` remains pending, `11-01-SUMMARY.md` marks all 23 owned requirements as completed although its own body reports mixed outcomes, and automation expects `requirements_completed` while the repo’s summaries currently use `requirements-completed`. [VERIFIED: .planning/v1.0-v1.0-MILESTONE-AUDIT.md; .planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md; .planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md]

**Primary recommendation:** Split Phase 14 into four plans: `07+08 verification creation`, `09 quality-chain re-verification`, `10 traceability/stale-evidence repair`, and `11 artifact/meta reconciliation + final requirements sync`. [VERIFIED: current artifact gap matrix below]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Create `07/08/09/10/11-VERIFICATION.md` artifacts | CDN / Static | API / Backend | The outputs are Markdown planning artifacts, but their truth comes from existing code, tests, and prior verification reports. [VERIFIED: phase directory listings; 03/04/05/06/12 verification reports] |
| Normalize summary frontmatter for automation | CDN / Static | — | The drift is in summary YAML keys and values, not in runtime code. [VERIFIED: 07-01-SUMMARY.md; 08-01-SUMMARY.md; 09-01-SUMMARY.md; 09-02-SUMMARY.md; 10-01-SUMMARY.md; 10-02-SUMMARY.md; 11-01-SUMMARY.md; audit] |
| Resync affected `REQUIREMENTS.md` rows | CDN / Static | API / Backend | The table is documentation, but updates must be derived from executable evidence and finished verification artifacts only. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-PLAN.md] |
| Repair Nyquist validation drift for Phases 07-11 | CDN / Static | — | The missing/partial state is in `VALIDATION.md` files and their frontmatter/sign-off, not in runtime modules. [VERIFIED: phase directory listings; 09 VALIDATION.md; 10-VALIDATION.md; 11-VALIDATION.md; audit] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-01 | Phoenix engineer can serve rendered PDFs through download-friendly adapter helpers. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 07 verification should cite `test/rendro/adapters/phoenix_test.exs` and Phase 11/03 proof surfaces. [VERIFIED: 03-VERIFICATION.md; 11-01-SUMMARY.md] |
| ADPT-02 | Phoenix engineer can preview rendered output through Phoenix-friendly integration helpers. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 07 verification should use the same conn-boundary proof surface as ADPT-01. [VERIFIED: 03-VERIFICATION.md] |
| ADPT-03 | Maintainer can enable optional adapters without introducing hard compile/runtime dependencies in core. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 07 verification should reuse `mix compile --no-optional-deps --warnings-as-errors` evidence already established for Phase 3 reconstruction. [VERIFIED: 03-VERIFICATION.md] |
| ADPT-04 | Maintainer can use an optional job-processing adapter pattern for bounded asynchronous rendering. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 08 verification should cite Oban worker and policy proof from current tests. [VERIFIED: 08-01-PLAN.md; 03-VERIFICATION.md] |
| ADPT-05 | Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 10 verification must close the remaining row drift using current recipe tests plus repaired Phase 5 evidence. [VERIFIED: 10-01-SUMMARY.md; 10-02-SUMMARY.md; 05-VERIFICATION.md] |
| OBS-03 | Operator receives structured errors that explain what happened, where it failed, why, and suggested next actions. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 07 verification should cite structured Phoenix adapter error rendering plus existing Phase 1 closure. [VERIFIED: 07-01-PLAN.md; 11-01-SUMMARY.md] |
| QUAL-01 | Maintainer can run a canonical merge-blocking verification lane (`mix ci`) including format, compile, tests, docs, and package build. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 09 verification should treat `12-VERIFICATION.md` as the decisive closure surface, not the original 09 summary claims. [VERIFIED: 12-VERIFICATION.md; 09-01-SUMMARY.md] |
| QUAL-02 | Maintainer can validate public docs/quickstart claims with docs-contract checks in CI. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 09 verification should point at Phase 13 docs-contract proof; Phase 10 should only repair stale recipe evidence. [VERIFIED: 13-01-SUMMARY.md; 12-VERIFICATION.md; 10-02-SUMMARY.md] |
| QUAL-03 | Maintainer can run a CI-verified Phoenix example app as executable adoption proof. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 07 and Phase 09 verification should reuse the committed workflow + example compile evidence from Phase 12. [VERIFIED: 12-VERIFICATION.md] |
| QUAL-04 | Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 09 and Phase 10 verification should cite Phase 13 release-preflight closure and keep 10’s traceability-only role truthful. [VERIFIED: 13-02-SUMMARY.md; 10-02-SUMMARY.md] |
| QUAL-05 | Maintainer can separate deterministic required lanes from advisory/provider-dependent lanes in verification output. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 09 verification should cite Phase 12 verification-lane proof as the authoritative closure. [VERIFIED: 12-VERIFICATION.md] |
</phase_requirements>

## Current Artifact State

### Milestone-Grade `VERIFICATION.md` Contract

The repo’s milestone-grade verification contract is already visible in Phases 03, 04, 05, 06, and 12. The common shape is: YAML frontmatter, `## Goal Achievement`, requirement-first sections or tables, executable proof commands, `### Required Artifacts`, and honest gap reporting. [VERIFIED: 03-VERIFICATION.md; 04-VERIFICATION.md; 05-VERIFICATION.md; 06-VERIFICATION.md; 12-VERIFICATION.md; 11-PATTERNS.md]

Use the following required structure for Phase 14 backfill artifacts. [VERIFIED: 11-PATTERNS.md]

1. Frontmatter with `phase`, `verified`, `status`, and requirement or must-have metadata. [VERIFIED: 03-VERIFICATION.md; 06-VERIFICATION.md; 12-VERIFICATION.md]
2. `## Goal Achievement` as the first body section. [VERIFIED: 03-VERIFICATION.md; 04-VERIFICATION.md; 06-VERIFICATION.md]
3. Requirement-first proof mapping with explicit `Primary proof` or requirements coverage tables. [VERIFIED: 03-VERIFICATION.md; 04-VERIFICATION.md; 06-VERIFICATION.md]
4. `### Required Artifacts` and, when useful, `### Key Link Verification`, `### Behavioral Spot-Checks`, `### Anti-Patterns Found`, and `### Gaps Summary`. [VERIFIED: 05-VERIFICATION.md; 06-VERIFICATION.md; 12-VERIFICATION.md]
5. Re-verification framing where later phases closed the original gap after the initial plan ran. [VERIFIED: 05-VERIFICATION.md; 12-VERIFICATION.md]

### Phase 07-11 Gap Matrix

| Phase | Present Now | Missing / Partial | Exact Repair Needed |
|------|-------------|-------------------|---------------------|
| 07 | `07-01-PLAN.md`, `07-01-SUMMARY.md`, `07-PATTERNS.md`, `RESEARCH.md`. [VERIFIED: phase directory listing] | No `07-VERIFICATION.md`; no `07-VALIDATION.md`; summary has no automation frontmatter. [VERIFIED: phase directory listing; 07-01-SUMMARY.md] | Create `07-VERIFICATION.md`; create `07-VALIDATION.md`; add summary frontmatter with `requirements_completed` and values consistent with the summary body and later verification evidence. [VERIFIED: 07-01-SUMMARY.md; 11-PATTERNS.md] |
| 08 | `08-01-PLAN.md`, `08-01-SUMMARY.md`. [VERIFIED: phase directory listing] | No `08-VERIFICATION.md`; no `08-VALIDATION.md`; no research/patterns artifact; summary has no automation frontmatter. [VERIFIED: phase directory listing; 08-01-SUMMARY.md] | Create `08-VERIFICATION.md`; create `08-VALIDATION.md`; add summary frontmatter; use plan file plus current tests as the authoritative source. [VERIFIED: 08-01-PLAN.md; 08-01-SUMMARY.md] |
| 09 | `09-01/02-PLAN.md`, `09-01/02-SUMMARY.md`, `PATTERNS.md`, `RESEARCH.md`, plain `VALIDATION.md`. [VERIFIED: phase directory listing] | No `09-VERIFICATION.md`; validation file is not Nyquist-shaped and lacks phase-prefixed filename/frontmatter; summaries have no automation frontmatter and overstate closure relative to later evidence. [VERIFIED: phase directory listing; 09 VALIDATION.md; 09-01-SUMMARY.md; 09-02-SUMMARY.md; 12-VERIFICATION.md; 13-01-SUMMARY.md; 13-02-SUMMARY.md] | Create `09-VERIFICATION.md`; convert `VALIDATION.md` into `09-VALIDATION.md` with Nyquist frontmatter and task map; add summary frontmatter; verify against current post-12/13 quality surfaces, not original 09 claims. [VERIFIED: 09 VALIDATION.md; 12-VERIFICATION.md; 13 summaries] |
| 10 | `10-01/02-PLAN.md`, `10-01/02-SUMMARY.md`, `10-CONTEXT.md`, `10-PATTERNS.md`, `10-RESEARCH.md`, `10-VALIDATION.md`. [VERIFIED: phase directory listing] | No `10-VERIFICATION.md`; `10-VALIDATION.md` remains `status: draft`, `nyquist_compliant: false`, `wave_0_complete: false`; `10-02-SUMMARY.md` metadata contradicts its body; summary key uses `requirements-completed`. [VERIFIED: 10-VALIDATION.md; 10-02-SUMMARY.md; audit] | Create `10-VERIFICATION.md`; update `10-VALIDATION.md` to a truthful final state; rename metadata key to `requirements_completed`; fix the completed-requirements value to match the body and verification. [VERIFIED: 10-VALIDATION.md; 10-02-SUMMARY.md] |
| 11 | `11-01-PLAN.md`, `11-01-SUMMARY.md`, `11-CONTEXT.md`, `11-PATTERNS.md`, `11-RESEARCH.md`, `11-VALIDATION.md`. [VERIFIED: phase directory listing] | No `11-VERIFICATION.md`; summary key uses `requirements-completed` and lists all 23 owned requirements as completed even though the body reports 18 Done, 4 Partial, 1 Blocked; `11-VALIDATION.md` says `wave_0_complete: false` despite `Approval: approved`. [VERIFIED: 11-01-SUMMARY.md; 11-VALIDATION.md] | Create `11-VERIFICATION.md`; rename summary key to `requirements_completed`; reduce the value to only the actually completed requirements; reconcile `11-VALIDATION.md` frontmatter/body so the approval state is internally consistent. [VERIFIED: 11-01-SUMMARY.md; 11-VALIDATION.md] |

### Traceability / Process Drift Requiring Repair

- `10-02-SUMMARY.md` frontmatter claims `requirements-completed: [QUAL-04]`, but its body explicitly says `QUAL-04` remains pending while `ADPT-05` was marked done. [VERIFIED: 10-02-SUMMARY.md; audit]
- `11-01-SUMMARY.md` frontmatter lists all 23 Phase 11 requirements as completed, but its body reports `19 Done, 4 Partial, 1 Blocked` for all 24 v1 requirements and explicitly calls out mixed Phase 4 outcomes. [VERIFIED: 11-01-SUMMARY.md]
- `05-VERIFICATION.md` still carries stale Mailglass custom-wrapper anti-pattern and human-verification notes even though `10-01-SUMMARY.md` claims the wrapper dispatch was fixed and automated. [VERIFIED: 05-VERIFICATION.md; 10-01-SUMMARY.md; audit]
- The metadata-key drift is broader than Phase 14’s narrow target: `04-SUMMARY.md`, `10-01-SUMMARY.md`, `10-02-SUMMARY.md`, `11-01-SUMMARY.md`, `12-03-SUMMARY.md`, `13-01-SUMMARY.md`, and `13-02-SUMMARY.md` all use `requirements-completed` rather than `requirements_completed`. [VERIFIED: codebase grep]

## Standard Stack

Phase 14 should add no new libraries. The standard stack is the repo’s existing planning artifacts, Mix/ExUnit proof commands, and shell-based artifact integrity checks. [VERIFIED: codebase grep; mix.exs]

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Mix | 1.19.5 | Executes repo proof commands and test suites. [VERIFIED: `mix --version`] | All later-phase evidence is already expressed as Mix commands. [VERIFIED: 07-11 plans; 12-VERIFICATION.md] |
| Elixir | 1.19.5 | Runtime for verification commands and ExUnit suites. [VERIFIED: `mix --version`; AGENTS.md] | Matches the repo’s declared stack and hosted CI contract. [VERIFIED: AGENTS.md; 12-VERIFICATION.md] |
| Git | 2.41.0 | Proves workflow tracking and supports clean-evidence checks. [VERIFIED: `git --version`] | Phase 09/12/13 quality claims rely on tracked workflow and release-state evidence. [VERIFIED: 12-VERIFICATION.md; 13-02-SUMMARY.md] |
| ripgrep | 15.1.0 | Fast artifact integrity and metadata consistency checks. [VERIFIED: `rg --version`] | Existing plans already use `rg` as an acceptance/verification tool. [VERIFIED: 10-02-PLAN.md; 11-01-PLAN.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 | Requirement-boundary proof for adapter, telemetry, Mix task, and docs-contract behavior. [VERIFIED: mix.exs; test tree] | Use whenever a phase verification can cite a narrow current test suite instead of narrative claims. [VERIFIED: 03-VERIFICATION.md; 12-VERIFICATION.md] |
| Existing verification reports | repo-local | Re-verification anchors for current truth. [VERIFIED: 03/04/05/06/12 verification files] | Use as supporting evidence when the later fixing phase already has a milestone-grade proof surface. [VERIFIED: 12-VERIFICATION.md; 13 summaries] |
| Nyquist validation template | repo-local | Frontmatter and task-map shape for `VALIDATION.md`. [VERIFIED: 11-VALIDATION.md; 06-VALIDATION.md] | Use to create `07/08-VALIDATION.md`, replace `09/VALIDATION.md`, and repair `10/11`. [VERIFIED: phase directory listings; 10-VALIDATION.md; 11-VALIDATION.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing the 05/06/12 verification pattern | Invent a new Phase 14-only verification schema | This would increase planner complexity and break artifact consistency for no benefit. [VERIFIED: 11-PATTERNS.md; existing verification files] |
| Narrow artifact-only repair plans | A single monolithic Phase 14 plan | One plan would mix missing-file creation, summary metadata normalization, stale evidence repair, and requirements sync across five phases, which makes truthful verification harder and regression diagnosis slower. [VERIFIED: gap matrix above] |
| Verification based on current post-fix evidence | Restating original execution summaries as proof | The summaries for 09 and 10 already diverge from later verified truth, so summary-only backfill would repeat the same process drift the audit flagged. [VERIFIED: 09 summaries; 10-02-SUMMARY.md; 12-VERIFICATION.md; 13 summaries; audit] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** No new packages are recommended for Phase 14. The required local tools are already available as `Mix 1.19.5`, `Elixir 1.19.5`, `Git 2.41.0`, and `ripgrep 15.1.0`. [VERIFIED: `mix --version`; `git --version`; `rg --version`]

## Architecture Patterns

### System Architecture Diagram

```text
Existing runtime proof surfaces
  |
  +--> phase plans/summaries (07-11)
  |       |
  |       +--> identify missing VERIFICATION / VALIDATION / metadata drift
  |
  +--> existing verified phases (03/04/05/06/12)
  |       |
  |       +--> extract canonical verification structure
  |
  +--> current requirement table + milestone audit
          |
          +--> detect row/status contradictions
          |
          +--> Phase 14 plans create/repair:
                - 07/08/09/10/11-VERIFICATION.md
                - 07/08/09/10/11-VALIDATION.md as needed
                - 07-11 summary frontmatter normalization
                - REQUIREMENTS.md final row sync
```

This is the correct conceptual flow because Phase 14 produces truth from existing evidence; it does not create new product behavior. [VERIFIED: user prompt; audit; phase directory listings]

### Recommended Project Structure

```text
.planning/phases/
├── 07-phoenix-adapter-hardening/
│   ├── 07-VERIFICATION.md
│   └── 07-VALIDATION.md
├── 08-bounded-async-timeout-telemetry/
│   ├── 08-VERIFICATION.md
│   └── 08-VALIDATION.md
├── 09-ci-and-release-hardening/
│   ├── 09-VERIFICATION.md
│   └── 09-VALIDATION.md
├── 10-recipe-correctness-and-traceability/
│   ├── 10-VERIFICATION.md
│   └── 10-VALIDATION.md
└── 11-reconstruct-phase-1-4-artifacts/
    ├── 11-VERIFICATION.md
    └── 11-VALIDATION.md
```

Keep every artifact in the existing phase directories and preserve the zero-padded naming pattern used by Phases 01 through 06 and 12 through 13. [VERIFIED: codebase grep]

### Pattern 1: Verification-First Backfill

**What:** Write `VERIFICATION.md` first, then derive summary metadata and `REQUIREMENTS.md` row changes from that verification, not the other way around. [VERIFIED: 11-01-PLAN.md; 11-PATTERNS.md]
**When to use:** For every Phase 14 sub-plan. [VERIFIED: gap matrix]
**Example:**
```markdown
## Requirement: ADPT-01

**Status:** Done
**Primary proof:** `mix test test/rendro/adapters/phoenix_test.exs`
**Supporting evidence:** `03-VERIFICATION.md`, `07-01-SUMMARY.md`
**Why this closes the requirement:** Current conn-boundary proof plus Phase 7 adapter hardening evidence cover the download helper truthfully.
```

### Pattern 2: Summary Frontmatter Is an Extraction Surface, Not Narrative Decoration

**What:** Every summary in scope should carry machine-readable frontmatter using `requirements_completed`, and that list must contain only requirements the summary actually closes as `Done`. [VERIFIED: audit; 10-02-SUMMARY.md; 11-01-SUMMARY.md]
**When to use:** On all 07-11 summaries, including retrofit frontmatter for 07/08/09 and key/value repair for 10/11. [VERIFIED: 07-11 summary files]
**Example:**
```yaml
---
phase: 10-recipe-correctness-and-traceability
plan: "02"
requirements_completed: [ADPT-05]
---
```

### Pattern 3: Re-Verification Is Valid When Later Phases Closed the Original Gap

**What:** A late verification artifact can truthfully say a phase is now closed if it cites the later proof surfaces that actually fixed the gap and makes the re-verification explicit. [VERIFIED: 05-VERIFICATION.md; 12-VERIFICATION.md]
**When to use:** Especially for Phase 09, whose quality requirements are now closed through Phases 12 and 13 rather than by the original 09 execution summaries alone. [VERIFIED: 09 summaries; 12-VERIFICATION.md; 13 summaries]
**Example:**
```markdown
**Re-verification:** Yes - after Phases 12 and 13 closed the hosted CI, docs-contract, and release-preflight gaps.
```

### Anti-Patterns to Avoid

- **Summary-led traceability flips:** Do not update `REQUIREMENTS.md` from a summary body or summary frontmatter before the phase’s `VERIFICATION.md` exists. [VERIFIED: 11-01-PLAN.md; audit]
- **“All requirements completed” metadata on mixed phases:** This is already wrong in `11-01-SUMMARY.md` and should not be repeated. [VERIFIED: 11-01-SUMMARY.md]
- **Carrying forward stale anti-pattern notes after the underlying behavior is fixed:** This is the current `05-VERIFICATION.md` problem relative to Phase 10. [VERIFIED: 05-VERIFICATION.md; 10-01-SUMMARY.md; audit]
- **Plain-text `VALIDATION.md` without Nyquist frontmatter and verification map:** This is the current Phase 09 problem. [VERIFIED: 09 VALIDATION.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification document schema | A new Phase 14-specific layout | The existing 05/06/12 verification format | The repo already has a working milestone-grade pattern and the planner expects it. [VERIFIED: 05-VERIFICATION.md; 06-VERIFICATION.md; 12-VERIFICATION.md; 11-PATTERNS.md] |
| Validation contract shape | A prose-only signoff note | Existing Nyquist-style `*-VALIDATION.md` frontmatter plus per-task map | The config has `workflow.nyquist_validation: true`, and later phases already use this structure. [VERIFIED: .planning/config.json; 10-VALIDATION.md; 11-VALIDATION.md] |
| Requirement status derivation | Manual intuition about what a phase “basically achieved” | Direct synchronization from completed `VERIFICATION.md` verdicts | This is the explicit Phase 11 pattern and the only reliable way to avoid drift. [VERIFIED: 11-01-PLAN.md; 11-PATTERNS.md] |
| Release/docs quality truth for Phase 09 | Replaying 09 summaries as if they were decisive | Phase 12/13 proof surfaces plus current targeted commands | The later phases contain the actual committed CI, docs-contract, and release-preflight closures. [VERIFIED: 12-VERIFICATION.md; 13-01-SUMMARY.md; 13-02-SUMMARY.md] |

**Key insight:** Phase 14 should backfill missing evidence containers and normalize extraction metadata; it should not attempt to “improve” the product again. [VERIFIED: user prompt; audit; roadmap]

## Common Pitfalls

### Pitfall 1: Treating Plan/Summary Presence as Verification Presence
**What goes wrong:** A phase looks “complete” because it has a plan and summary, but milestone scoring still marks it missing. [VERIFIED: audit; phase directory listings]
**Why it happens:** The milestone audit counts `VERIFICATION.md` as the proof artifact, not `PLAN.md` or `SUMMARY.md`. [VERIFIED: audit; 11-PATTERNS.md]
**How to avoid:** Backfill `VERIFICATION.md` first for 07-11 and only then sync metadata and requirements rows. [VERIFIED: 11-01-PLAN.md]
**Warning signs:** `STATE.md` says Phase 14 is next while audit still lists `INT-PHASE-ARTIFACTS`. [VERIFIED: .planning/STATE.md; audit]

### Pitfall 2: Fixing the Metadata Key but Leaving the Value False
**What goes wrong:** `requirements-completed` becomes `requirements_completed`, but the list still claims the wrong requirements. [VERIFIED: 10-02-SUMMARY.md; 11-01-SUMMARY.md]
**Why it happens:** The repo currently has both naming drift and semantic drift. [VERIFIED: audit; summary files]
**How to avoid:** Normalize key and value in the same edit, using the matching `VERIFICATION.md` verdicts as the source of truth. [VERIFIED: 11-01-PLAN.md]
**Warning signs:** The summary body says “pending”, “partial”, or “blocked” while metadata lists that requirement as completed. [VERIFIED: 10-02-SUMMARY.md; 11-01-SUMMARY.md]

### Pitfall 3: Verifying Phase 09 Against Obsolete Evidence
**What goes wrong:** The Phase 09 artifact repeats claims like “all established quality gates are passing” even though later verification proved that 09 alone was insufficient. [VERIFIED: 09-01-SUMMARY.md; 09-02-SUMMARY.md; 12-VERIFICATION.md; 13 summaries]
**Why it happens:** The later closure work in Phases 12 and 13 changed the decisive proof surfaces for `QUAL-01` through `QUAL-05`. [VERIFIED: 12-VERIFICATION.md; 13-01-SUMMARY.md; 13-02-SUMMARY.md]
**How to avoid:** Make Phase 09 a re-verification artifact that explicitly cites later closures. [VERIFIED: 12-VERIFICATION.md; 13 summaries]
**Warning signs:** A new `09-VERIFICATION.md` cites only `09-01/02-SUMMARY.md` and no current quality-chain proof. [ASSUMED]

### Pitfall 4: Leaving Stale Phase 5 Evidence After Phase 10 Backfill
**What goes wrong:** `10-VERIFICATION.md` says recipe drift is closed, but `05-VERIFICATION.md` still tells readers the custom Mailglass wrapper path needs manual confirmation. [VERIFIED: 05-VERIFICATION.md; 10-01-SUMMARY.md; audit]
**Why it happens:** Phase 10 updated central traceability but did not complete a phase-level verification repair. [VERIFIED: 10-02-SUMMARY.md; audit]
**How to avoid:** Couple `10-VERIFICATION.md` with targeted edits to stale Phase 5 notes and UAT references. [VERIFIED: 10-02-PLAN.md; audit]
**Warning signs:** `05-VERIFICATION.md` still contains `REVIEW CR-01` human-verification text after Phase 10 verification is added. [VERIFIED: 05-VERIFICATION.md]

## Code Examples

Verified patterns from current repo artifacts:

### Verification Frontmatter
```yaml
# Source: .planning/phases/12-verification-chain-closure/12-VERIFICATION.md
---
phase: 12-verification-chain-closure
verified: 2026-04-28T13:58:38Z
status: passed
score: 7/7 must-haves verified
---
```

### Summary Metadata Repair
```yaml
# Source: audit + corrected Phase 10 semantics
---
phase: 10-recipe-correctness-and-traceability
plan: "02"
requirements_completed: [ADPT-05]
---
```

### Requirements Coverage Table
```markdown
# Source: .planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md
### Requirements Coverage

| Requirement | Status | Primary proof |
|-------------|--------|---------------|
| ADPT-01 | Done | `mix test test/rendro/adapters/phoenix_test.exs` |
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plan + summary without milestone verification | Requirement-first `VERIFICATION.md` with executable proof | Phase 05 onward, reinforced by Phase 11 reconstruction and Phase 12 closure. [VERIFIED: 05-VERIFICATION.md; 11-PATTERNS.md; 12-VERIFICATION.md] | Milestone audits can score phases from evidence instead of execution intent. [VERIFIED: audit] |
| Heuristic quality claims in summaries | Decisive quality proof in `12-VERIFICATION.md` and Phase 13 artifact set | 2026-04-28. [VERIFIED: 12-VERIFICATION.md; 13 summaries] | Phase 09 backfill must cite current truth rather than original overclaims. [VERIFIED: 09 summaries; 12-VERIFICATION.md; 13 summaries] |
| Free-form or missing validation docs | Nyquist frontmatter + per-task verification map | Active by Phases 10 and 11. [VERIFIED: 10-VALIDATION.md; 11-VALIDATION.md] | 07/08/09 need alignment before Phase 14 can be considered process-complete. [VERIFIED: gap matrix] |
| `requirements-completed` summary key | `requirements_completed` expected by automation | Audit identified on 2026-04-28. [VERIFIED: audit] | Summary extraction is unreliable until normalized. [VERIFIED: audit] |

**Deprecated/outdated:**
- `requirements-completed` as a summary extraction field is outdated for automation use in this repo. [VERIFIED: audit]
- Plain `VALIDATION.md` without Nyquist frontmatter is outdated relative to the repo’s current phase-validation pattern. [VERIFIED: 09 VALIDATION.md; 10-VALIDATION.md; 11-VALIDATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A future `09-VERIFICATION.md` should be written as an explicit re-verification artifact rather than as a “failed initial verification” artifact. [ASSUMED] | Architecture Patterns / decomposition | Low - either framing can work if the evidence and requirement statuses stay truthful. |

## Open Questions

1. **Should Phase 14 normalize `requirements_completed` only for 07-11, or also for 04, 12, and 13 where the same key drift exists?**
   - What we know: The audit flags the key mismatch as workflow drift, and codebase grep shows the hyphenated key in summaries outside 07-11 as well. [VERIFIED: audit; codebase grep]
   - What's unclear: Whether the current planner/extractor consumes only active later phases or all summaries globally. [ASSUMED]
   - Recommendation: Keep Phase 14’s required scope at 07-11, but add a final low-risk metadata sweep if automation is confirmed to read all summaries globally. [VERIFIED: user prompt; codebase grep]

2. **Should Phase 10’s completed-requirements metadata list `ADPT-05` or be empty?**
   - What we know: `10-02-SUMMARY.md` body says ADPT-05 is now done and QUAL-04 remains pending, while metadata currently says `[QUAL-04]`. [VERIFIED: 10-02-SUMMARY.md]
   - What's unclear: Whether the field means “requirements touched by this plan” or “requirements moved to Done by this plan”. [ASSUMED]
   - Recommendation: Use the stricter interpretation: list only requirements moved to `Done`, which makes `ADPT-05` the likely correct value for `10-02-SUMMARY.md`. [VERIFIED: 10-02-SUMMARY.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | proof commands, tests, docs, release task verification | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| `git` | workflow tracking proof, release-state checks, worktree-style evidence references | ✓ [VERIFIED: `git --version`] | 2.41.0 [VERIFIED: `git --version`] | — |
| `rg` | artifact integrity and metadata grep checks | ✓ [VERIFIED: `rg --version`] | 15.1.0 [VERIFIED: `rg --version`] | `grep` if needed, but slower. [ASSUMED] |

**Missing dependencies with no fallback:**
- None identified for this docs-and-evidence phase. [VERIFIED: local tool checks]

**Missing dependencies with fallback:**
- None identified. [VERIFIED: local tool checks]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus repo-local shell/grep verification. [VERIFIED: mix.exs; existing plans] |
| Config file | `mix.exs`, `test/test_helper.exs`, and per-phase `*-VALIDATION.md`. [VERIFIED: mix.exs; 10-VALIDATION.md; 11-VALIDATION.md] |
| Quick run command | `mix test` for the smallest requirement-specific suite plus `rg` on affected artifacts. [VERIFIED: 10-02-PLAN.md; 11-01-PLAN.md] |
| Full suite command | `mix test` plus targeted proof commands for the phase slice being documented. [VERIFIED: 11-VALIDATION.md; 12-VERIFICATION.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADPT-01 / ADPT-02 / OBS-03 | Phoenix adapter download/preview/error-envelope proof stays discoverable in Phase 07 artifacts. [VERIFIED: 07-01-PLAN.md; 03-VERIFICATION.md] | unit + artifact integrity | `mix test test/rendro/adapters/phoenix_test.exs test/rendro/error_test.exs && rg -n "ADPT-01|ADPT-02|OBS-03|Primary proof" .planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md` | ❌ Wave 0 |
| ADPT-03 | Optional adapter boundary remains tied to explicit compile proof in Phase 07 artifact. [VERIFIED: 03-VERIFICATION.md] | compile + artifact integrity | `mix compile --no-optional-deps --warnings-as-errors && rg -n "ADPT-03|no-optional-deps" .planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md` | ❌ Wave 0 |
| ADPT-04 / OBS-02 / OBS-04 | Phase 08 artifact cites bounded async and timeout telemetry proof accurately. [VERIFIED: 08-01-PLAN.md; 03-VERIFICATION.md] | unit + artifact integrity | `mix test test/rendro/pipeline_test.exs test/rendro/adapters/threadline_test.exs test/rendro/adapters/oban/render_worker_test.exs && rg -n "ADPT-04|OBS-02|OBS-04" .planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md` | ❌ Wave 0 |
| QUAL-01 / QUAL-03 / QUAL-05 | Phase 09 artifact reflects Phase 12’s committed CI and verification-lane closure truthfully. [VERIFIED: 12-VERIFICATION.md] | regression + artifact integrity | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs && git ls-files --error-unmatch .github/workflows/ci.yml && rg -n "QUAL-01|QUAL-03|QUAL-05" .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` | ❌ Wave 0 |
| QUAL-02 / QUAL-04 | Phase 09 artifact reflects Phase 13 docs-contract and release-preflight closure truthfully. [VERIFIED: 13 summaries] | regression + artifact integrity | `mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/release_preflight_test.exs && rg -n "QUAL-02|QUAL-04" .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` | ❌ Wave 0 |
| ADPT-05 | Phase 10 artifact closes recipe-traceability drift and removes stale Phase 5 caveats. [VERIFIED: 05-VERIFICATION.md; 10-01/02 summaries] | unit + doc consistency | `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs && rg -n "ADPT-05|CR-01|WR-06|IN-04" .planning/phases/10-recipe-correctness-and-traceability/10-VERIFICATION.md .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` | ❌ Wave 0 |
| Phase 11 owned rows | `11-VERIFICATION.md` matches existing 01-04 reconstructed verdicts and summary metadata only lists completed requirements. [VERIFIED: 11-01-SUMMARY.md; 01-04 verification files] | artifact parity | `rg -n "^## Requirement:|^\\*\\*Status:\\*\\*" .planning/phases/{01-core-deterministic-foundation,02-layout-and-pagination-engine,03-adapter-and-ops-integration,04-quality-and-release-hardening}/*-VERIFICATION.md && rg -n "requirements_completed" .planning/phases/11-reconstruct-phase-1-4-artifacts/11-01-SUMMARY.md` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the smallest targeted proof suite plus artifact `rg` checks for the phase slice just edited. [VERIFIED: existing 10/11 validation patterns]
- **Per wave merge:** Re-run all targeted proof commands for the plans touched in that wave. [VERIFIED: 11-VALIDATION.md]
- **Phase gate:** All new `07-11-VERIFICATION.md` files exist, all `07-11` summary metadata keys are normalized, and affected `REQUIREMENTS.md` rows match the final Phase 14 verification verdicts. [VERIFIED: roadmap Phase 14 success criteria; audit]

### Wave 0 Gaps

- [ ] `07-VERIFICATION.md` and `07-VALIDATION.md` do not exist yet. [VERIFIED: phase directory listing]
- [ ] `08-VERIFICATION.md` and `08-VALIDATION.md` do not exist yet. [VERIFIED: phase directory listing]
- [ ] `09-VERIFICATION.md` does not exist, and `VALIDATION.md` must be replaced or renamed into a Nyquist-compatible `09-VALIDATION.md`. [VERIFIED: phase directory listing; 09 VALIDATION.md]
- [ ] `10-VERIFICATION.md` does not exist, and `10-VALIDATION.md` is still draft/non-compliant. [VERIFIED: phase directory listing; 10-VALIDATION.md]
- [ ] `11-VERIFICATION.md` does not exist, and `11-VALIDATION.md` frontmatter/body need reconciliation. [VERIFIED: phase directory listing; 11-VALIDATION.md]
- [ ] Summary frontmatter is missing for 07/08/09 and semantically wrong for 10/11. [VERIFIED: summary files; audit]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: docs-only scope] | — |
| V3 Session Management | no [VERIFIED: docs-only scope] | — |
| V4 Access Control | no [VERIFIED: docs-only scope] | — |
| V5 Input Validation | yes [VERIFIED: phase scope includes status/metadata/traceability normalization] | Validate requirement IDs, status vocabulary, and metadata keys against existing artifact conventions before changing `REQUIREMENTS.md`. [VERIFIED: 11-01-PLAN.md; audit] |
| V6 Cryptography | no [VERIFIED: docs-only scope] | — |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Summary metadata contradicts verification body | Repudiation | Derive `requirements_completed` only from finished `VERIFICATION.md` verdicts. [VERIFIED: audit; 11-01-PLAN.md] |
| Requirements table is updated before proof artifacts exist | Tampering | Require each row flip to be traceable to a concrete `07-11-VERIFICATION.md` section and proof command. [VERIFIED: 11-01-PLAN.md; roadmap] |
| Stale verification notes survive after later fixes | Repudiation | Repair upstream stale artifacts such as `05-VERIFICATION.md` when a later phase verification closes the gap. [VERIFIED: 05-VERIFICATION.md; 10-01-SUMMARY.md; audit] |

## Recommended Decomposition

### Plan 14-01: Backfill Phase 07 and 08 Verification + Validation Foundations

**Scope:** Create `07-VERIFICATION.md`, `08-VERIFICATION.md`, `07-VALIDATION.md`, `08-VALIDATION.md`, and add automation frontmatter to `07-01-SUMMARY.md` and `08-01-SUMMARY.md`. [VERIFIED: gap matrix]

**Why first:** These two phases are missing the most basic artifact scaffolding and do not depend on the more contentious quality-chain metadata repairs. [VERIFIED: gap matrix]

**Primary proof commands:**  
`mix compile --no-optional-deps --warnings-as-errors`  
`mix test test/rendro/adapters/phoenix_test.exs test/rendro/error_test.exs`  
`mix test test/rendro/pipeline_test.exs test/rendro/adapters/threadline_test.exs test/rendro/adapters/oban/render_worker_test.exs` [VERIFIED: 03-VERIFICATION.md; 08-01-PLAN.md]

### Plan 14-02: Re-Verify Phase 09 Against the Post-12/13 Quality Chain

**Scope:** Create `09-VERIFICATION.md`; replace plain `VALIDATION.md` with Nyquist-compatible `09-VALIDATION.md`; add frontmatter to `09-01-SUMMARY.md` and `09-02-SUMMARY.md`; explicitly cite Phase 12 and Phase 13 as the decisive closure surfaces. [VERIFIED: gap matrix; 12-VERIFICATION.md; 13 summaries]

**Why isolated:** Phase 09 is the only later phase whose original summaries materially overclaim compared to later verified truth, so it deserves its own evidence pass. [VERIFIED: 09 summaries; 12-VERIFICATION.md; 13 summaries]

**Primary proof commands:**  
`mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs`  
`mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/release_preflight_test.exs`  
`git ls-files --error-unmatch .github/workflows/ci.yml` [VERIFIED: 12-VERIFICATION.md; 13 summaries]

### Plan 14-03: Verify Phase 10 and Remove Recipe-Traceability Drift

**Scope:** Create `10-VERIFICATION.md`; finalize `10-VALIDATION.md`; rename summary metadata key to `requirements_completed`; repair the wrong completed-requirements value in `10-02-SUMMARY.md`; update stale Phase 5 notes that still contradict Phase 10’s claimed closure. [VERIFIED: gap matrix; audit]

**Why separate:** Phase 10 is the only target phase that requires both its own verification artifact and upstream stale-evidence repair in Phase 5 artifacts. [VERIFIED: 05-VERIFICATION.md; 10 summaries; audit]

**Primary proof commands:**  
`mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs`  
`rg -n "CR-01|WR-06|IN-04|ADPT-05|requirements_completed" .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md .planning/phases/10-recipe-correctness-and-traceability/*` [VERIFIED: 10-02-PLAN.md; audit]

### Plan 14-04: Verify Phase 11 and Finish Cross-Phase Metadata / Requirements Sync

**Scope:** Create `11-VERIFICATION.md`; repair `11-01-SUMMARY.md` metadata key and completed-requirements value; reconcile `11-VALIDATION.md` frontmatter/body; perform the final `REQUIREMENTS.md` sync for Phase 14-owned rows. [VERIFIED: gap matrix; roadmap Phase 14 success criteria]

**Why last:** Phase 11 is the phase that already defines the repo’s own reconstruction and traceability rules, so its verification and metadata repair should be the final consistency gate. [VERIFIED: 11-01-PLAN.md; 11-PATTERNS.md]

**Primary proof commands:**  
Reuse the artifact parity checks from `11-01-PLAN.md` for cross-checking reconstructed verification sections and row sync. [VERIFIED: 11-01-PLAN.md]

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 14 goal, dependencies, requirements, and success criteria. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - Current traceability rows and affected requirement states. [VERIFIED: codebase grep]
- `.planning/v1.0-v1.0-MILESTONE-AUDIT.md` - Explicit artifact, metadata, and process-drift findings. [VERIFIED: codebase grep]
- `.planning/phases/03-adapter-and-ops-integration/03-VERIFICATION.md` - Milestone-grade verification exemplar for adapter boundaries. [VERIFIED: codebase grep]
- `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` - Mixed-verdict verification exemplar. [VERIFIED: codebase grep]
- `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` - Re-verification and stale-evidence repair target. [VERIFIED: codebase grep]
- `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md` - Evidence-forward verification exemplar. [VERIFIED: codebase grep]
- `.planning/phases/12-verification-chain-closure/12-VERIFICATION.md` - Current authoritative quality-chain closure for `QUAL-01`, `QUAL-03`, and `QUAL-05`. [VERIFIED: codebase grep]
- `.planning/phases/13-docs-and-release-preflight-closure/13-01-SUMMARY.md` and `13-02-SUMMARY.md` - Current authoritative docs-contract and release-preflight closure surfaces. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- `07-11` plan, summary, research, patterns, and validation artifacts - internal execution intent and current process state. [VERIFIED: codebase grep]
- Local tool availability checks: `mix --version`, `git --version`, `rg --version`. [VERIFIED: local commands]

### Tertiary (LOW confidence)
- None. All substantive findings were verified directly from repo artifacts or local tool output. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new ecosystem choices are needed; all tools and patterns are repo-local and directly inspected. [VERIFIED: local tool checks; codebase grep]
- Architecture: HIGH - the artifact shape and truth-sync workflow are explicitly documented by current verification exemplars and Phase 11 patterns. [VERIFIED: 03/04/05/06/12 verification files; 11-PATTERNS.md]
- Pitfalls: HIGH - each pitfall is already visible in the current audit or artifact set, not inferred from memory. [VERIFIED: audit; summary files; 05-VERIFICATION.md]

**Research date:** 2026-04-28 [VERIFIED: system date]
**Valid until:** 2026-05-28 for artifact-structure guidance, or until any new phase edits `07-11` artifacts before planning. [ASSUMED]

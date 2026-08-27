# Architecture Research

**Domain:** Evidence-led quality architecture for Rendro
**Researched:** 2026-08-26
**Confidence:** HIGH

## System Overview

```text
                         PUBLIC CONTRACTS
        Rendro facade / data structs / recipes / optional adapters
                                  |
                                  v
                  build -> compose -> measure -> paginate
                                  |
                                  v
                         render -> validate
                                  |
                    deterministic artifacts

  ------------------------------------------------------------------
                         QUALITY CONTROL PLANE

  official research + repository baseline
                    -> .planning/QUALITY.md
                    -> accepted finding owners
                       |        |        |
                       v        v        v
                  core code   tests    CI/evidence
                       \        |        /
                        verified closure
                               |
                               v
                     catalog human review
```

The product pipeline remains unchanged. v2.14 adds no runtime layer; it improves the maintainer control plane around the existing code and evidence.

## Component Responsibilities

| Component | Current signal | v2.14 responsibility |
|-----------|----------------|-----------------------|
| Public API manifest and docs contracts | Mature, fail-loud contract | Prove no public removal or unsupported claim change |
| Core pipeline and PDF writer | Large/high-dependency change points | Accept extraction only for cohesive responsibilities with regression proof |
| Recipes/themes/fixtures | Multiple >1k-line recipes; known catalog gaps | Preserve three-rung APIs and unaffected bytes while repairing six exact visual targets |
| Test suite | 1,917 tests with large contract/fixture tests | Reduce brittleness/duplication while preserving observable failure modes |
| Main CI workflow | Required/proof/advisory separation plus historical catalog routes | Keep committed-state validation; remove milestone-specific generation authority |
| Catalog evidence workflow | Currently embedded in Phase 126/127/130 branches | Become a standalone exact-SHA artifact producer with read-only permissions |
| Release evidence | Current facts split across archived Phase 131 files | Move current machine-consumed facts to stable versioned repository evidence |
| Quality ledger | Does not exist | Own current findings, disposition, status, evidence, and next trigger |

## Durable Quality Ledger

Create `.planning/QUALITY.md` in Phase 132 with these sections:

1. **Baseline:** dated commands and values (CI, xref, source/test shape, package, catalog).
2. **Disposition rules:** high, medium, low/style definitions and compatibility policy.
3. **Active findings table:** `ID | area | evidence | impact | confidence | compatibility risk | disposition | owner phase | verification | status`.
4. **Resolved/rejected findings:** retain concise evidence and resolution reference.
5. **Deferred triggers:** precise conditions for the next review/milestone.
6. **Before/after:** populated in Phase 137 without erasing the baseline.

Detailed analysis belongs in Phase 132 artifacts; the ledger stays concise and current.

## Architecture Patterns

### 1. Evidence before extraction

An internal module is extracted only when the audit identifies a coherent responsibility and a measurable benefit such as reduced change fan-out, duplicate logic, misleading ownership, or a proven testability problem. A line count or runtime cycle alone is insufficient.

Verification order:

1. Freeze public manifest and affected goldens.
2. Add/confirm characterization tests for the responsibility.
3. Extract behind the existing public/internal call boundary.
4. Re-run focused and full deterministic gates.
5. Record the before/after dependency/change surface in the ledger.

### 2. Planning is history, not executable state

Machine-consumed release facts move under `priv/release_evidence/v1.3.4/`:

- Preserve the public prerequisite JSON semantics used by the clean-room harness.
- Add a schema-validated manifest carrying every release identity and journey hash currently asserted from Phase 131 candidate/validation prose.
- Update scripts, release workflow, and product/docs-contract tests to consume the durable files.
- Explicitly exclude internal release evidence from the Hex package unless a public contract later requires it.
- Archived planning files remain immutable historical narrative only.

GSD-specific tools may read current `.planning` state when that is their explicit purpose; product behavior, release automation, and durable regression tests may not.

### 3. Validate committed state; generate evidence separately

Ordinary `ci.yml` validates repository state. A new `catalog-evidence.yml` performs pinned generation through manual exact-SHA inputs:

```text
workflow_dispatch(candidate_sha, operation)
    -> validate input and read-only permissions
    -> checkout exact candidate_sha
    -> literal HEAD equality
    -> install + hash-check pinned PDFium
    -> operation=review: candidate/final/multipage payload
    -> operation=canonical: exact 32-cell catalog payload
    -> checksum inventory + immutable run artifact
```

The workflow never edits or commits the repository. A later human-authorized local step verifies and materializes an artifact. Artifact names include candidate SHA, run ID, and attempt.

### 4. Comments and specs are boundary tools

- Public docs describe behavior, failure shapes, stability tier, and truthful limits.
- Comments explain invariants, provenance/authority boundaries, surprising ordering, and security constraints.
- Names and small functions express mechanics; remove line-by-line narration and stale phase references.
- Public/stable functions keep specs. Private specs remain when they clarify a non-obvious contract or improve Dialyzer; redundant/misleading private specs may be removed with Dialyzer proof.

### 5. Catalog repair remains data-first and evidence-bound

Target exactly:

- `invoice--cedar-mutual--corporate-classic--dark`
- `statement--signal-ledger--minimal-mono--dark`
- `payslip--northline-logistics--swiss--light`
- `payslip--northline-logistics--swiss--dark`
- `ticket--aurora-live--brutalist--light`
- `ticket--aurora-live--brutalist--dark`

Fix recipe/theme/fixture behavior, not catalog-specific drawing forks. Regenerate through the generic workflow, bind current hashes, and require human review. Hierarchy remains 5; every other visual dimension reaches at least 4. Dark `print_safety` remains false, so visual closure does not become a print/accessibility claim.

## Data Flows

### Finding flow

```text
repository evidence -> audit finding -> disposition rule -> owner phase
       -> implementation diff -> focused proof -> full gate -> ledger closure
```

### Release-evidence flow

```text
protected release / HexDocs / journey facts
       -> versioned durable manifest + prerequisite
       -> verifier, clean-room harness, release workflow, contract tests
       -> archived planning narrative (reference only)
```

### Catalog flow

```text
recipe/theme/fixture change -> deterministic source PDF
       -> exact-SHA pinned workflow -> PNG + checksum artifact
       -> human full-size review -> rubric/hash update
       -> canonical exact-SHA artifact -> verified materialization
```

## Repository Structure Changes

```text
.planning/
├── QUALITY.md                         # durable current ledger
├── research/                          # v2.14 research
└── milestones/v2.13-research/         # preserved prior research

priv/release_evidence/v1.3.4/
├── public_prerequisite.json           # clean-room input
├── manifest.json                      # sealed machine facts
└── manifest.schema.json               # validation contract

.github/workflows/
├── ci.yml                             # committed-state validation
└── catalog-evidence.yml               # exact-SHA generation only
```

Names may be adjusted only to match an existing stronger repository convention; responsibilities and authority boundaries are locked.

## Anti-Patterns

- Splitting `Rendro.PDF.Writer` or recipes into generic “utils” modules without an owned responsibility.
- Treating runtime xref cycles as defects when compile-connected health is already acyclic.
- Moving planning prose verbatim into runtime evidence rather than extracting stable machine facts.
- Letting a workflow input select an unchecked ref, branch, path, command, or artifact name.
- Making a catalog generator both produce and publish/commit output.
- Updating rubric scores before exact regenerated bytes exist.
- Combining architecture refactors and visual changes in one unbounded diff.

## Sources

- Rendro source/test size and xref baseline captured 2026-08-26
- `.github/workflows/ci.yml`, `release.yml`, and `priv/guardrails/required_status_checks.json`
- Phase 130 and 131 archived plans, summaries, verification, and evidence artifacts
- Official sources listed in `STACK.md`

---
*Architecture research for: v2.14 Quality & Maintainability*
*Researched: 2026-08-26*

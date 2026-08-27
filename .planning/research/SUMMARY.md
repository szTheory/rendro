# Project Research Summary

**Project:** Rendro
**Domain:** Quality and maintainability ratchet for a mature deterministic Elixir library
**Researched:** 2026-08-26
**Confidence:** HIGH

## Executive Summary

Rendro does not need a new quality stack. It already has a strong deterministic baseline—compiler warnings as errors, 1,917 tests, strict Credo, Dialyzer, ExDoc warnings, package checks, vulnerability audits, and deliberately separate proof/advisory lanes. The next gain comes from applying these mechanisms to maintainability questions they do not answer automatically: cohesive module ownership, durable evidence boundaries, test brittleness, workflow authority, current comments/specs, and decision-ready debt tracking.

The milestone should audit before changing and treat metrics as investigation signals. Current evidence identifies useful starting points: several high-churn multi-responsibility modules, three runtime (not compile-connected) dependency cycles, current tests/release paths coupled to archived Phase 131 files, loose historical planning files, and phase-number-specific catalog generation routes in the main CI workflow. None should be “fixed” solely because it exists; Phase 132 must establish impact, confidence, compatibility risk, and verification first.

The catalog track remains narrow. Repair six exact scored cells with actual visual gaps, retain the fixed 32-cell membership and twenty explicitly unscored entries, and keep dark output screen-oriented with `print_safety: false`. A generic exact-SHA catalog evidence workflow must exist before the new review so future quality windows do not add more milestone-specific CI branches.

## Key Findings

### Stack

- Keep Elixir 1.19.5, OTP 28, ExUnit, Credo 1.7.17, Dialyxir 1.4.7, ExDoc, mix_audit, and existing schema tooling.
- Use `mix xref`, coverage, slow-test output, package manifests, and workflow contracts diagnostically.
- Add no runtime dependency and no quality dependency unless a trial proves a current false-negative that existing tools cannot express.
- Treat GitHub caches as untrusted and catalog generation as read-only artifact production.

### Table Stakes

- A durable current quality ledger with evidence and dispositions.
- Public API and unrelated PDF-byte stability.
- Product/release paths independent of archived planning.
- Evidence-backed architecture/readability/spec/comment cleanup.
- Tests that protect behavior rather than planning prose or implementation trivia.
- One purpose-named exact-SHA catalog evidence workflow.
- Six-cell visual closure with truthful dark boundaries.
- Before/after reporting and next-review triggers.

### Architecture

The product pipeline remains untouched. v2.14 adds a maintainer control plane: official research and repository evidence feed the milestone quality ledger; accepted findings route to bounded phases; each change closes through focused and full verification. Durable release facts move to a versioned release-evidence directory. Ordinary CI validates committed state, while the generic catalog-evidence workflow produces checksum-bound review/canonical artifacts for an exact input SHA without repository write authority.

### Critical Pitfalls

1. **Cleanup churn:** require evidence and verification before extraction, renaming, or deletion.
2. **Metric gaming:** never substitute coverage, line count, or dependency count for behavioral proof and cohesion judgment.
3. **Executable planning history:** machine-consumed facts must live in stable versioned evidence, not archived phase prose.
4. **Authority loss during CI cleanup:** generic workflow inputs, permissions, renderer pin, HEAD equality, and artifact scope must be at least as strict as existing routes.
5. **Weaker tests after consolidation:** inventory distinct behaviors/failures and prove replacement tests have teeth.
6. **Visual overclaim:** improve screen scores without changing print/accessibility/viewer claims.

## Implications for Roadmap

### Phase 132: Quality Baseline & Triage

**Why first:** Later phases need a frozen, evidence-backed finding set and compatibility contract.

**Delivers:** the durable quality ledger, current metrics, finding dispositions, owner phases, and verification methods.

### Phase 133: Repository & Evidence Hygiene

**Why second:** Stable evidence inputs and correct historical archives remove known brittle foundations before code/test/CI restructuring.

**Delivers:** versioned release evidence, no product/release dependency on archived planning, archived loose phase files, justified tracked helpers, and package/hygiene guards.

### Phase 134: Core Architecture & Readability

**Why third:** The accepted finding set and stable evidence boundary permit conservative internal cleanup with public/golden proof.

**Delivers:** closed high-impact architecture/readability/spec/comment/dead-code findings and bounded medium fixes.

### Phase 135: Test & CI/CD Simplification

**Why fourth:** Tests can be consolidated after internal boundaries stabilize; generic catalog authority must land before visual review.

**Delivers:** behavior-preserving test cleanup, smaller ordinary CI, and one secure exact-SHA catalog evidence workflow with historical routes retired after parity.

### Phase 136: Catalog Visual Quality

**Why fifth:** Uses stable core/tests and the generic evidence workflow to repair and re-review six exact cells.

**Delivers:** hierarchy 5 and other visual dimensions at least 4 for all six targets, with exact hashes/provenance and unchanged dark print boundary.

### Phase 137: Closure & Handoff

**Why last:** Measures committed results, closes/rejects every high finding, and makes deferred work actionable.

**Delivers:** full verification, before/after ledger, ranked triggers, and next-milestone options in current project state.

### Ordering Rationale

- Audit before remediation prevents subjective scope drift.
- Evidence hygiene before architecture/CI avoids rebuilding on archived planning paths.
- Architecture before test consolidation keeps characterization coverage trustworthy.
- Generic evidence CI before catalog repair prevents another phase-number route.
- Catalog after engineering cleanup separates output changes from refactors.
- Closure last preserves a truthful baseline/final comparison.

### Research Flags

- **Phase 132:** Medium—confirm the final finding rubric against actual source/test/workflow evidence; avoid turning initial signals into conclusions.
- **Phase 133:** Medium—inventory every fact consumed from Phase 131 before defining the durable manifest schema.
- **Phase 134:** High—each extraction target requires local pattern mapping and characterization tests; do not preselect splits from file size.
- **Phase 135:** High—map all current catalog route authority checks and obtain remote artifact parity before deletion.
- **Phase 136:** High—visual changes require exact current image review and human judgment.
- **Phase 137:** Low—standard verification and lifecycle closure once preceding artifacts are complete.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Current versions and commands are repository-verified; official docs support diagnostic boundaries |
| Scope | HIGH | User approved exact compatibility, catalog, research, CI, comment, and completion decisions |
| Architecture | HIGH | Current planning coupling, workflow topology, xref shape, and catalog evidence paths were inspected directly |
| Pitfalls | HIGH | Risks follow from prior archive regressions and current authority boundaries |

**Overall confidence:** HIGH

### Gaps to Resolve During Planning

- The exact core extractions are intentionally not preordained; Phase 132 evidence decides whether each hotspot is fixed, deferred, or rejected.
- The durable v1.3.4 manifest fields must be derived exhaustively from current verifier/newcomer assertions before migration.
- Generic catalog workflow parity requires a live remote run; local YAML/contracts alone cannot prove the Linux PDFium path.
- Human review remains necessary for the six visual targets.

## Sources

### Primary

- [Mix xref](https://hexdocs.pm/elixir/1.19.5/Mix.Tasks.Xref.html)
- [Mix test coverage](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Test.Coverage.html)
- [Credo configuration](https://credo.hexdocs.pm/config_file.html)
- [Dialyxir 1.4.7](https://dialyxir.hexdocs.pm/)
- [GitHub reusable workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)
- [GitHub dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)
- Rendro source, tests, workflows, catalog/rubric manifests, and archived v2.10-v2.13 artifacts

---
*Research completed: 2026-08-26*
*Ready for roadmap: yes*

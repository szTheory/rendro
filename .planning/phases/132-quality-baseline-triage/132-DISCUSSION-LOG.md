# Phase 132: Quality Baseline & Triage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 132-quality-baseline-triage
**Areas discussed:** Ledger form and audience, finding identity and history, baseline evidence depth, risk and disposition rubric

---

## Ledger Form and Audience

| Option | Description | Selected |
|--------|-------------|----------|
| Human-first `.planning/QUALITY.md` | One concise, repository-native, Git-reviewable current ledger for maintainers and reviewers, with structured companions only for machine facts. | ✓ |
| Schema-first JSON/YAML | Canonical structured records with a generated or synchronized Markdown reviewer view. | |
| GitHub Issues/Projects | Hosted issues, labels, assignees, and project fields as canonical quality state with a repository summary. | |

**User's choice:** Approved the recommended human-first repository ledger.
**Notes:** Research emphasized archive independence, small-project proportionality, reviewer DX, and avoiding a second hosted or runtime state system. Ecto and Phoenix persistence patterns were considered inappropriate for this maintainer control plane.

---

## Finding Identity and History

| Option | Description | Selected |
|--------|-------------|----------|
| Permanent opaque IDs | Sequential `QL-*` IDs, cause-and-boundary deduplication, concise lifecycle metadata, and Git line history. | ✓ |
| Semantic IDs | Encode area, phase, severity, or ownership in identifiers. | |
| External issue identities | Use issue numbers and issue threads as the durable identity and history. | |

**User's choice:** Approved permanent opaque IDs and the recommended lifecycle/deduplication rules.
**Notes:** IDs never change when priority or ownership changes. Corroborating observations become evidence; distinct compatibility or owner boundaries remain separate findings. Resolved, rejected, deferred, reopened, related, and superseded records remain visible.

---

## Baseline Evidence Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Normalized snapshots plus bounded raw artifacts | Commit schema-valid, redacted facts and provenance; retain large raw evidence as hash-bound CI artifacts. | ✓ |
| Commit raw evidence | Store complete logs, reports, PDFs, PNGs, and diagnostic output in Git. | |
| CI links only | Keep only run IDs, URLs, hashes, and artifact references in the ledger. | |

**User's choice:** Approved normalized committed baselines with bounded raw artifacts.
**Notes:** Existing Mix contracts remain the command registry. Snapshots record source/tool/environment identity, authority lane, result, raw hash/location/expiry, and explicit unavailability. The starting baseline is immutable and Phase 137 adds a final comparison.

---

## Risk and Disposition Rubric

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-gated qualitative rubric | Keep impact, confidence, compatibility risk, evidence quality, optional likelihood, and justified priority separate. | ✓ |
| Numeric risk matrix | Calculate priority from likelihood-by-impact scores and modifiers. | |
| Enterprise treatment register | Model inherent/residual risk, controls, approvers, exceptions, and formal review cadence. | |

**User's choice:** Approved the qualitative evidence-gated rubric and full closure governance package.
**Notes:** No composite score or diagnostic quota. High findings require repair or evidence-backed rejection; medium findings require bounded repair or trigger-backed deferral; low/style signals do not create standalone churn. Closure requires the predeclared proof and compatibility evidence.

---

## Research Direction Requested

The user requested one-shot, cohesive recommendations grounded in:

- Typed GSD advisor subagent research across all four areas.
- Idiomatic Elixir, Mix, Plug, Ecto, and Phoenix conventions where applicable.
- Successful ecosystem and cross-language precedents plus their footguns.
- Developer ergonomics, least surprise, maintainability, auditability, DevOps/SRE, and software-architecture lenses.
- Relevant project prompt research and the current brand/voice sources instead of stale brand material.
- Persona/JTBD analysis and UI/UX principles only where applicable.

Three typed `gsd-advisor-researcher` agents compared ledger architecture/history, baseline evidence, and risk governance. Their recommendations converged with the existing v2.14 research and were synthesized into one package. The user approved that package without changes.

## the agent's Discretion

- Exact normalized snapshot directory and schema filenames.
- Exact repository-owned validation/test mechanism.
- Markdown table layout and compact evidence-link presentation.
- Focused contract-test implementation, provided it does not turn the human ledger into a pseudo-database or add runtime dependencies.

## Deferred Ideas

None — discussion stayed within Phase 132 scope.

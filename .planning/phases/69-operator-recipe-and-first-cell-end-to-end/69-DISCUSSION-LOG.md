# Phase 69: Operator Recipe + First Cell End-to-End - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 69-operator-recipe-and-first-cell-end-to-end
**Areas discussed:** Operator guide shape & tone; Phase 47 consolidation; Guide ↔ canonical file; api_stability + CHANGELOG scope
**Mode:** All areas, research-backed one-shot recommendations (user requested subagent research, no interactive Q&A)

---

## Area 1: Operator Guide Shape & Tone

| Option | Description | Selected |
|--------|-------------|----------|
| A — Linear runbook only | Numbered steps, copy-paste commands | |
| B — Reference manual + quick-start | Lookup-first, stub quick-start | |
| C — Hybrid runbook + appendices | Quick-start spine + deferral/schema/checklist appendices | ✓ |

**User's choice:** C (recommended after research synthesis)
**Notes:** Modeled on MDN BCD contributing + data-guidelines, Oban getting-started + troubleshooting, Playwright intro + detailed guide. Matches Rendro `integrations.md` recipe style and Phase 69 UAT (“second operator, zero questions”). Policies-group placement signals contract/process beside `api_stability.md`.

---

## Area 2: Phase 47 Consolidation Strategy

| Axis | Options considered | Selected |
|------|-------------------|----------|
| recorded_at | Original 2026-05-05 vs re-validation date vs split dates | Re-validation date (equal in matrix + frontmatter); Phase 47 date in body only |
| Fixture | Checked-in path vs render command vs sha256-only | `fixture: test/fixtures/forms_support_fixture.pdf` + regen from FormSupportFixture |
| Notes | Template stubs vs substantive observations | Substantive, widget-specific (email, terms, contact radio group) |
| Body | Migration-first vs fresh-only vs hybrid | Hybrid provenance + boundary notes |

**User's choice:** Re-attestation consolidation (research recommendation)
**Notes:** Avoid backdating without contemporaneous evidence file (PITFALLS #2). Mirror EmbeddedArtifactSupportFixture committed-PDF pattern. Poppler ≠ viewer proof called out in body.

---

## Area 3: Guide ↔ Canonical File Relationship

| Option | Description | Selected |
|--------|-------------|----------|
| A — Pointer-only | Link to canonical file | |
| B — Inline full frontmatter + body | Duplicate entire evidence file in guide | |
| C — Skeleton + link | Annotated YAML skeleton + GitHub link to canonical file | ✓ |
| D — Deferral example timing | Phase 69 vs Phase 71 | Synthetic deferral mini-example in Phase 69 guide |

**User's choice:** C + synthetic deferral in guide (not production matrix row)
**Notes:** ExDoc lacks Django-style includes; Kubernetes hybrid (inline concepts, canonical files in repo) is closest fit. Hex package omits `priv/` — prerequisites must state repo checkout. Duplicating frontmatter would drift without enforcement lane.

---

## Area 4: api_stability.md + CHANGELOG Scope

| Option | Description | Selected |
|--------|-------------|----------|
| A — CHANGELOG rule only | Discipline section, no row prose | |
| B — Rule + forms prose | Partial VIEWER-01 | |
| C — Rule + prose + CHANGELOG entry | Full public-contract closure for worked cell | ✓ |
| D — Defer all prose to Phase 70 | Matrix/evidence only in 69 | |

**User's choice:** C
**Notes:** Phase 69 success criterion #3 requires full cycle including public-contract artifacts. RECIPE-05 needs demonstrated practice, not dead letter. Other four legacy rows deferred to Phase 70. CHANGELOG uses **Changed** for re-home (status unchanged since v1.8).

---

## Claude's Discretion

- Appendix formatting and optional `forms_viewer_proof_fixture.exs` vs module-only regen docs
- Exact hypothetical deferral cell in synthetic example
- Lightweight docs-contract guide pointer assertion

## Deferred Ideas

- `mix rendro.viewer_evidence init` — Phase 72
- Hex `files:` expansion for priv tooling — release packaging
- Four remaining legacy row prose updates — Phase 70
- Production deferral matrix rows — Phase 71

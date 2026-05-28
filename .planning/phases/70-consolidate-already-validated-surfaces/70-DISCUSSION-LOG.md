# Phase 70: Consolidate Already-Validated Surfaces - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 70-consolidate-already-validated-surfaces
**Areas discussed:** Re-attestation rigor, Fixture strategy, forms × Apple Preview vs chrome_pdfium, api_stability + CHANGELOG batching, Tier-B JSON Schema flip

---

## Re-attestation rigor

| Option | Description | Selected |
|--------|-------------|----------|
| Full fresh checklist (all proof[] behaviors) | Strongest audit trail; highest operator cost | |
| Re-attestation consolidation (Phase 69 D-07) | Schema migration + mandatory re-run of every proof[] behavior; fresh recorded_at | ✓ |
| Migrate-from-milestone-docs only | Fastest; backdates or transcribes without re-opening fixture | |
| Hybrid tiered rigor | Same policy, differentiated intensity per row risk | ✓ (execution detail under re-attestation) |

**User's choice:** Research-backed one-shot recommendation package (delegated decision-making across all areas).
**Notes:** Reject ARCHITECTURE.md “no manual checking.” protection×Preview = full 5-check. Acrobat batches embedded_files + links. links×Preview independent of embedded_files×Preview outcome.

---

## Fixture strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Commit PDF per surface under test/fixtures/ | Matches Phase 69 forms precedent; operator can double-click fixture | ✓ |
| fixture_sha256 only | Schema-valid but poor operator DX; wrong for protection non-determinism | |
| Shared mega-fixture | One PDF for embedded + links (Phase 50 design) | ✓ |
| Regen-on-demand only | Fine for CI temp paths; insufficient for manual consolidation | |

**User's choice:** Three committed PDFs (forms, embedded_artifact, protection); five evidence files; shared embedded PDF for three matrix cells.
**Notes:** Commit embedded_artifact_support_fixture.pdf and protection_support_fixture.pdf before recording.

---

## forms × Apple Preview vs chrome_pdfium

| Option | Description | Selected |
|--------|-------------|----------|
| Same fixture, orthogonal evidence files | forms_support_fixture.pdf for both; distinguish via viewer_kind + note vocabulary | ✓ |
| Separate fixtures per viewer | Violates D-09; doubles maintenance | |
| Defer Preview; rely on pdfium only | Breaks VIEWER-01 (forms×Preview is one of five rows) | |
| Single combined evidence file | Violates path rule priv/viewer_evidence/<surface>/<viewer>.md | |

**User's choice:** A1 pattern — manual Preview GUI notes; pdfium-cli proxy stays separate; cross-boundary negation in both bodies.

---

## api_stability + CHANGELOG batching

| Option | Description | Selected |
|--------|-------------|----------|
| Single atomic commit wave | Evidence + matrix + api_stability + CHANGELOG + Tier-B flip together | ✓ |
| Per-surface commits | Git history per surface; risks prolonged mixed public-contract state | |
| Matrix-first, prose second | CI green between waves; violates ROADMAP #4 and D-19 closure | |

**User's choice:** One PR; five Changed bullets under [0.3.0] Viewer Evidence (v2.3); Embedded Artifact section edited as one unit.

---

## Tier-B JSON Schema flip

| Option | Description | Selected |
|--------|-------------|----------|
| Schema flip at Phase 70 closure (after all 5 pointers) | Aligns JSV with Elixir tier-B; matches 68-PATTERNS intent | ✓ |
| Schema flip at Phase 70 start | CI red until all five done | |
| Elixir-only tier-B forever | JSV accepts invalid supported rows; D-04 drift | |
| Schema flip + immediate strict staleness | Overlaps Phase 72 GUARDRAIL-02 | |

**User's choice:** B1 — add supported if/then at closure; production validate_promotion_complete in tier-A; staleness stays advisory until Phase 72.

---

## Claude's Discretion

- Evidence body prose wording, optional fixture script wrappers, exact docs-contract assert shapes, internal plan split — as long as merge remains one atomic public-contract wave.

## Deferred Ideas

- Phase 71 net-new promotions and deferrals
- Phase 72 staleness strict mode and init subcommand
- pdfium-cli proxies for Preview/Acrobat GUI behaviors

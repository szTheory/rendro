---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Realistic Business-Document Examples & Anatomy
status: executing
last_updated: "2026-07-11T05:31:30.481Z"
last_activity: 2026-07-11
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 7
  completed_plans: 5
  percent: 0
---

# Project State

## Reference

**Project**: Rendro
**Core Value**: Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current Focus**: v2.10 Realistic Business-Document Examples & Anatomy (Milestone A / `SEED-002`) — roadmap created; ready to plan Phase 114.

## Current Position

Phase: 114 (Domain research, reader-quality rubric & realistic example-data library) — EXECUTING
Plan: 6 of 7
Status: Ready to execute
Last activity: 2026-07-11

Progress: [███████░░░] 71%

## Roadmap Snapshot (v2.10, Phases 114–118)

```text
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0% — 0/5 phases complete
Phase 114 Domain research, rubric & example-data library . Ready to plan
Phase 115 Invoice anatomy + Format promotion + seams ..... Not started
Phase 116 New families — Payslip & Ticket ................ Not started
Phase 117 Edge-case stress matrix ........................ Not started
Phase 118 Rubric-gated demos, gallery & docs closure ..... Not started
```

## Accumulated Context

### Decisions

- Milestone A (`SEED-002`) is an **additive minor** release (hex `1.1.0`), NOT v3.0 — A2 is strictly additive (toy call preserved byte-identical), `Format` goes to the adapter/Evolving tier, new families are adapter-tier modules. Unlike C1 (infra), A changes `lib/`, so it IS a versioned release.
- **The single irreversible act:** promoting `Rendro.Format` from `@moduledoc false` into the public SemVer surface (Phase 115). Held to the adapter/Evolving tier, smallest useful surface (`money/1`, `date/1`, `label/1`), with an "output may evolve" doc note. Requires editing Phase-79's `public_api_contract_test.exs` hidden set (likeliest surprise red build).
- **Fold seed's 7 phases → 5** (coarse granularity; precedent: v2.4 Phase 75 shipped 2 recipes at once). 114 foundation (data+rubric) → 115 Invoice/Format (only real `lib/` change) → 116 new families → 117 stress matrix → 118 demos+docs closure.
- **Four shape-now seams** baked into acceptance criteria so B/C/D need no breaking rework: **S1** private `palette(opts)` keyed on B's locked color roles (Phase 115, applied in 116) · **S4** fixtures reserve an optional empty `brand`/`logo` slot (Phase 114) · **S5** rubric recorded as an appendable manifest (authored 114, populated 118) · **S6** `artifacts.json` gains optional theme/mode/preset tags (Phase 118).
- **Guards:** no tagged-PDF/PDF-UA accessibility claims ("production-grade" = information design); engine stays locale-free (VAT/sales-tax + payslip jurisdiction are DATA); no real PII (fictional businesses/employees — Payslip is the acute risk); ship `priv/examples/` text-only; byte-determinism (static fixed-date fixtures; toy call byte-identical).
- Loader placement is load-bearing: `lib/rendro/examples.ex`, `@moduledoc false` — the only placement serving tests + bench(`:dev`) + Livebook + shipped consumers while staying out of `public_api.json`.
- Money in fixtures as decimal **strings** (`"79.00"`), never JSON floats. De-quarantine `invoice_data.json` verbatim first (provable no-op vs advisory bench), normalize money to strings in a separate commit.
- No text/cell right-align primitive exists today; additive `cell_align: :right` (Phase 115) is the single highest-leverage typographic upgrade — but the rubric must NOT assume it. No barcode/QR primitive; Ticket "reads as a ticket" via boxed code-area + human-readable reference + perforation + optional caller-supplied PNG.
- [Phase ?]: Plan 114-01: invoice fixture de-quarantined into priv/examples/invoice/acme-phoenix-saas/invoice.json as a provable byte-identical no-op; move kept verbatim (money/brand normalization deferred to 114-03 per Pitfall 6), consumers repointed, fresh render sha256-identical to recorded benchmark evidence.
- [Phase ?]: 114-05: Authored Invoice DOMAIN.md as locked research-first recommendation (synthesized domain-research prose), light human sanity-check reserved for phase verification.
- [Phase ?]: 114-05: DOMAIN.md structural contract test iterates priv/examples/*/DOMAIN.md so future domain families inherit the four-heading contract automatically.
- [Phase 114]: 114-03: Normalized invoice fixture money from integer cents to Decimal-safe 2-decimal strings + added S4 empty brand/logo slot in a commit separate from 114-01's verbatim move (Pitfall 6); Rendro render byte-identical. Added first schema-validation lane (examples_schema_contract_test.exs) validating every priv/examples/ fixture. EXL-01/03/06 satisfied.
- [Phase ?]: Rendro.Examples loader kept String.t() path signature with Path.safe_relative/1 defense-in-depth guard; all current callers are internal/hardcoded
- [Phase ?]: Loader uses built-in JSON.decode!/1 (never Jason) — Jason is a dev/test-only transitive dep that would crash prod Hex consumers

### Blockers / Open Questions

- None. (Verify during Phase 114: the quarantined `invoice_data.json` is already fictional — a seed-wording correction, not a PII issue.)

## Next Steps

1. `/gsd-plan-phase 114` — plan the domain research, rubric & example-data library foundation.

## Last Session

**Last updated**: 2026-07-11
**Stopped at**: Completed 114-03-PLAN.md — invoice fixture money normalized to Decimal-safe strings + S4 brand/logo slot (byte-identical render); examples_schema_contract_test.exs validates every priv/examples/ fixture; EXL-01/03/06 satisfied.
**Blockers**: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| — | — | — | v2.10 not yet executed |
| Phase 114 P01 | 1min | 2 tasks | 5 files |
| Phase 114 P02 | 3min | 2 tasks | 2 files |
| Phase 114 P05 | 1min | 2 tasks | 2 files |
| Phase 114 P03 | 2min | 2 tasks | 6 files |
| Phase 114 P04 | ~2 min | 2 tasks | 3 files |

## Operator Next Steps

- Plan the first phase with `/gsd-plan-phase 114`.

---
phase: 118
slug: rubric-gated-demonstration-set-gallery-docs-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-19
---

# Phase 118 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/` |
| **Full suite command** | `mix ci.fast` (or `mix test`) |
| **Estimated runtime** | ~60–120 seconds |

Note: gallery regen / PNG re-baseline / D-09 rubric self-scoring raster require the
Linux-pinned `pdfium-cli` container (absent locally) — those are container-gated, not
part of the local quick loop. Source-PDF SHA-256 (required docs-contract lane) stays portable.

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract/` (fixture schema, DOMAIN.md, rubric manifest, branding/overclaim guards)
- **After every plan wave:** Run `mix ci.fast`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

*Filled during planning/execution. Each SHOW-0x task maps to an observable docs-contract or
rubric-contract test — see the RESEARCH.md `## Validation Architecture` section for the
criterion→test mapping the planner lifts into `must_haves.truths`.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 118-01-01 | 01 | 1 | SHOW-01 | — | fixtures validate against generalized examples.schema.json | docs-contract | `mix test test/docs_contract/` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Generalize `priv/schemas/examples.schema.json` beyond the invoice-only shape BEFORE any new fixture lands (RESEARCH gap #2) — else the required `test` job goes red.

*Existing ExUnit/docs-contract infrastructure otherwise covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rubric self-score (visual assessment of rendered/rasterized demo against 1/3/4/5 anchors) | SHOW-01 | D-09 requires a genuine human/Claude visual assessment, not an automated score | Render deterministic PDF → rasterize via pinned pdfium (container) → score 6 dimensions + 2 gates against anchors → append to `rubric_scores.json` with justifications |

*The rubric manifest's structure, arithmetic (`passed?/2`), and D-15 disjointness/teeth guards ARE automated (`rubric_manifest_contract_test.exs`); only the subjective score authorship is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

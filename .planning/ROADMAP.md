# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.7 closed at phase 92; v2.8 starts at phase 93.

## Milestones

- ✅ **v1.0 MVP** — deterministic core rendering (shipped)
- ✅ **v1.1 Layout Authoring** — templates/regions, pagination semantics (shipped)
- ✅ **v1.2 Typography & Assets** — deterministic typography, honest Unicode boundaries (shipped)
- ✅ **v1.3 Hex Release Readiness** — first public package boundary (shipped 2026-05-03)
- ✅ **v1.4 Async Delivery & Artifact Ops** — queued lifecycle, artifact metadata, integrations (shipped 2026-05-05)
- ✅ **v1.5 Validation & Trust Surfaces** — Poppler structural validation, support matrix (shipped 2026-05-05)
- ✅ **v1.8 Interactive PDF Forms** — Phases 45-47 (shipped 2026-05-05)
- ✅ **v1.9 Embedded Artifact Surfaces** — Phases 48-50 (shipped 2026-05-06)
- ✅ **v1.10 Protected Delivery Hooks** — Phases 51-54 (shipped 2026-05-06)
- ✅ **v2.0 Signature Fields & Signing Prep** — Phases 55-59 (shipped 2026-05-07)
- ✅ **v2.1 Cryptographic Signing** — Phases 60-63 (shipped 2026-05-07)
- ✅ **v2.2 Long-Lived Signatures** — Phases 64-67 (shipped 2026-05-08)
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29, tag v0.3.1)
- ✅ **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-77 (shipped 2026-05-30)
- ✅ **v2.5 1.0 Release Capstone** — Phases 78-82 (shipped 2026-06-05, hex tag 1.0.0)
- ✅ **v2.6 Public Launch & Adoption Bootstrap** — Phases 83-88 (shipped 2026-06-13)
- ✅ **v2.7 Page Context & Browser Proof Hardening** — Phases 89-92 (shipped 2026-06-13)
- 🚧 **v2.8 Done-Enough Stewardship & Adoption Signal Loop** — Phases 93-96 (in progress)
- 💤 **Global Text Shaping & Script Support** — conditional; only if the v2.6 `ADOPTION.md` demand gate triggers

## Phases

<details>
<summary>✅ v1.0 - v2.7 (Phases 1-92) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and, where present, `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

v2.6 archives:

- `.planning/milestones/v2.6-ROADMAP.md`
- `.planning/milestones/v2.6-REQUIREMENTS.md`
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md`
- `.planning/milestones/v2.6-phases/`

v2.7 archives:

- `.planning/milestones/v2.7-ROADMAP.md`
- `.planning/milestones/v2.7-REQUIREMENTS.md`
- `.planning/milestones/v2.7-MILESTONE-AUDIT.md`
- `.planning/milestones/v2.7-phases/`

</details>

### 🚧 v2.8 Done-Enough Stewardship & Adoption Signal Loop (In Progress)

**Milestone Goal:** Reduce maintainer/adopter friction and keep Rendro's public posture truthful while demand accumulates — without widening product scope. This is a tight stewardship cycle: close the `Rendro.Recipes` facade DX gap (drift-proofed), clean up or deliberately document the docs/warning posture, bring header odd/even proof depth to footer parity while reconciling stale phase-validation metadata, and record a dated adoption-signal review plus the "done-enough" stewardship posture.

**Named non-goals (held):** global text shaping, mobile GUI viewer promotion, TOC/outlines/anchors/cross-references, charts, existing-PDF editing, release-please automation, proactive outreach, and any new feature family — unless concrete adopter demand changes the tradeoff.

#### Phase 93: Recipes Facade DX Closure

**Goal**: A caller can reach every shipped recipe — Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate — from the single `Rendro.Recipes` module, with options threaded correctly and a test that prevents future facade/recipe drift.
**Depends on**: Phase 92 (v2.7 close); builds on shipped v2.4 recipe modules and the v2.5 API contract
**Requirements**: DX-01, DX-02
**Success Criteria** (what must be TRUE):

  1. `Rendro.Recipes` exposes hand-written, `@spec`'d arity-1 + arity-2 wrapper pairs (`invoice/1,2`, `branded_invoice/1,2`, `statement/1,2`, `receipt/1,2`, `certificate/1,2`), each delegating to the recipe module's `document/2`.
  2. The existing `invoice/1` opts-drop footgun is fixed — `:formatters` / `:labels` / `:border` / `:page_number_opts` thread through instead of being silently dropped — and the README line documenting the drop is corrected.
  3. A drift test asserts each recipe is reachable as `name/1` and `name/2`, that the facade exposes no extra functions (MapSet equality), and that `Rendro.Recipes.name(data, opts)` is byte-identical to `Module.document(data, opts)`.
  4. `mix rendro.api.gen` is re-run so `priv/public_api.json` reflects the 10-function facade surface, and `public_api_contract_test.exs` passes the byte-compare (additive arity pair, no Tier-1 symbol replaced).

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 93-01-PLAN.md — Author RED drift test (test/rendro/recipes_facade_drift_test.exs) + fix README opts-drop line
- [x] 93-02-PLAN.md — Expand lib/rendro/recipes.ex with 10 @spec'd facade functions (fixes opts-drop footgun)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 93-03-PLAN.md — Run mix rendro.api.gen, verify additive-only diff, confirm contract test passes

#### Phase 94: Docs & Warning Hygiene

**Goal**: A maintainer building the docs sees a clean, deliberate warning posture — `mix docs` emits zero unexplained ExDoc warnings, and the latent viewer-evidence staleness signal is self-explaining rather than mysterious.
**Depends on**: Phase 93 (sequencing only; clean working tree)
**Requirements**: HYG-01, HYG-02
**Success Criteria** (what must be TRUE):

  1. Prose `@doc` references to hidden internals are resolved via a `skip_code_autolink_to:` list in `mix.exs docs/0`, and the `Rendro.PDF.Font` typespec autolinks stop warning. **(Deviation, user-approved 2026-06-13):** the original plan to give `Font` an *internal-marking* `@moduledoc` while keeping it out of `priv/public_api.json` proved impossible — the full-surface public-API sweep (`test/rendro/public_api_test.exs`) forbids a visible-untagged module, and `skip_code_autolink_to` cannot suppress hidden-type typespec warnings. Since `Font.t()` is already exposed in the public `Rendro.Text.Shaper.shape/3` callback, `Font` was instead promoted to public `[:stable]` and added to the regenerated `priv/public_api.json`. See `94-01-SUMMARY.md` post-merge correction.
  2. `mix docs` emits zero warnings, and `docs --warnings-as-errors` is added to the `ci` alias so the zero-unexplained-warnings policy is mechanically enforced.
  3. The viewer-evidence staleness line in the validator is made self-explaining (appends remediation command, advisory-outside-`--strict` note, and a `guides/viewer_evidence.md` pointer) — the 180-day threshold is preserved and nothing is silenced, raised, or pre-emptively re-recorded (HYG-02 is a wording/docs change, not a silencing).
  4. `guides/viewer_evidence.md` documents the staleness lifecycle so a maintainer who sees the signal after it first fires (~late Nov 2026) knows it is a designed cadence signal, not a defect.

**Plans**: 2 plans

**Wave 1** *(both plans are independent and can run in parallel)*

- [x] 94-01-PLAN.md — Resolve all ExDoc warnings (skip_code_autolink_to: + Font @moduledoc + ci --warnings-as-errors)
- [x] 94-02-PLAN.md — Augment staleness message + add lifecycle section to guides/viewer_evidence.md

#### Phase 95: Header Duplex Proof & Metadata Reconcile

**Goal**: Header-specific `only_on: :odd | :even` running content has direct end-to-end proof at parity with the footer coverage shipped in v2.7, and recorded phase-validation metadata matches the already-passed milestone audit status.
**Depends on**: Phase 94 (sequencing only; PROOF-01 builds on shipped v2.7 duplex code paths)
**Requirements**: PROOF-01, META-01
**Success Criteria** (what must be TRUE):

  1. A render-layer E2E test in `test/rendro/flow_test.exs` renders header `only_on:` content across a ≥4-physical-page document and asserts on the byte-stable content stream (`Odd 1` / `Even 2` / `Odd 3` / `Even 4` present, `{{page_number}}` token not leaked).
  2. A paginate-layer test in `test/rendro/pipeline/paginate_test.exs` proves header physical odd/even parity coexists with section-local header tokens under `page_numbering: [restart: true]`.
  3. Edge cases are covered: first-page parity (page 1 = odd), single-page doc (only `:odd` appears), and header + footer `only_on` coexisting via independent `region_entries`.
  4. Stale v2.6/v2.7 phase validation-history / Nyquist metadata is reconciled so no false-incomplete or false-pending markers remain and recorded status matches each passed milestone audit.

**Plans**: 2 plans

**Wave 1** *(both plans are independent — no shared files — and can run in parallel)*

- [x] 95-01-PLAN.md — PROOF-01: header only_on render-layer 4-page proof + edge cases + paginate-layer restart coexistence
- [x] 95-02-PLAN.md — META-01: reconcile v2.7 VALIDATION.md false-pending markers (90, 92, 91; 88 left untouched per research)

#### Phase 96: Adoption Signal Review & Stewardship Posture

**Goal**: The project carries a dated, decision-rule-based adoption-signal review and an explicit "done-enough" stewardship posture, so future planning cycles inherit a truthful read of demand and the named non-goals.
**Depends on**: Phase 95 (sequencing only; pure-docs work)
**Requirements**: SIGNAL-01, STEW-01
**Success Criteria** (what must be TRUE):

  1. A single dated review row plus a short prose block is appended to the existing `## Review Log` in `ADOPTION.md`, recording the current download/version/contributor signal against the gate thresholds and an explicit verdict (current evidence supports a HOLD) with a concrete next trigger — no new `mix` task or public surface is added.
  2. The review applies the four-verdict decision rule (TRIGGER / ACCUMULATING / HOLD / HOLD-noise) and resists both hype (stars/+1/generic i18n do not count) and neglect (the HOLD records the next earliest re-check date).
  3. `.planning/MILESTONE-ARC.md` gains a dated `## Stewardship Posture (Done-Enough)` section recording the ~90-93% done-enough estimate, the standing rule to prefer stewardship over deepening proof/viewer machinery, and the named non-goals as demand-gated deferrals tied to `ADOPTION.md` — not abandonment.
  4. `guides/api_stability.md` gains a top `## Project Status & Stewardship` section signalling "stable and actively stewarded · feature-complete for its stated scope" with a *Last reviewed* date, explicit bug/security commitments, and "new capabilities are demand-gated, not abandoned" pointing to `ADOPTION.md`.

**Plans**: 1 plans

Plans:
- [ ] 96-01-PLAN.md — Apply a dated adoption-signal review with a HOLD verdict and establish the explicit "done-enough" stewardship posture

## Progress

**Execution Order:**
v2.8 phases execute in numeric order: 93 → 94 → 95 → 96

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 93. Recipes Facade DX Closure | v2.8 | 3/3 | Complete    | 2026-06-13 |
| 94. Docs & Warning Hygiene | v2.8 | 2/2 | Complete    | 2026-06-13 |
| 95. Header Duplex Proof & Metadata Reconcile | v2.8 | 2/2 | Complete    | 2026-06-13 |
| 96. Adoption Signal Review & Stewardship Posture | v2.8 | 0/TBD | Not started | - |

---
*v2.8 Done-Enough Stewardship & Adoption Signal Loop started 2026-06-13 (Phases 93-96, 8 requirements). Global text shaping remains demand-gated by ADOPTION.md.*

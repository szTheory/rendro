---
thread: v24-adoption-scoping
status: resolved
opened: 2026-05-29
resolved: 2026-05-30
resolution: All findings shipped — page primitive (Phase 73), Statement/Receipt/Certificate recipes (Phases 74–75), reference Phoenix app + CI + docs (Phase 76). Open questions answered (primitive folded into v2.4; statement+receipt/report+certificate shipped; reference-app CI lane shipped in-milestone as an isolated non-required job). Closed at v2.4 milestone completion.
context: Milestone next-step assessment after v2.3 (Hex v0.3.1) shipped
related: .planning/STATE.md, .planning/PROJECT.md, .planning/ROADMAP.md
---

# v2.4 Adoption Scoping — RESOLVED (closed 2026-05-30 at v2.4 close)

Scoping inputs for **v2.4 Batteries-Included Workflow & Adoption Closure**, surfaced by the
2026-05-29 milestone next-step assessment (direct inspection of `lib/`, `test/`, `examples/`,
`priv/`, `guides/`). Rendro is ~88–90% done for its stated scope; the remaining leverage is
**adoption ergonomics**, not more proof.

## Findings to feed v2.4

1. **Page numbering / running headers-footers is a missing table-stakes primitive.**
   "Page X of Y", repeated header/footer region content, and carried-forward totals are **not
   first-class** — adopters hand-roll them with text blocks (confirmed: no built-in primitive in
   `lib/`). For invoices/statements/reports this is table-stakes and a real adoption bounce risk.
   Treat as a **foundational primitive the new recipes need anyway**, not polish. Idiomatic analogs:
   ReportLab `onPage` hooks, fpdf2 header/footer overrides. Must stay deterministic + tested.

2. **Recipe breadth gap.** Only `Rendro.Recipes.Invoice` + `BrandedInvoice` exist. Common SaaS
   documents (statement, receipt/report, certificate) are unserved. Add 2–3 following the proven
   three-rung escape-hatch pattern (document / page_template / sections), each runnable from data,
   doc-contract tested, and documented in a guide.

3. **Reference app is thin.** `examples/phoenix_example` exists but is minimal, undocumented, and
   not described as CI-run. OSS-DNA lesson: a reference app should be **executable adoption proof**
   — `mix`-runnable, README'd, exercised in CI. Upgrade it.

4. **1.0 release is the natural capstone AFTER v2.4.** Engine is 1.0-grade (per source review) and
   `guides/api_stability.md` already exists. Sequence: v2.4 adoption closure → cut 1.0 (SemVer
   commitment + migration note) → maintenance/community.

5. **Diminishing-returns guidance — stop deepening the proof axis.** The per-viewer evidence /
   trust machinery (26 cells terminal, 4 required CI lanes, docs-contract lanes) is already
   best-in-class and arguably over-invested. Resist more viewers / mobile proof / signing adapters /
   stricter staleness cadence unless pulled by real adopter demand. Resist adjacent scope
   (multi-signature, HSM, global text shaping) — that is overbuilding for the stated scope.

## Graduation candidates (promote into v2.4 first-phase LEARNINGS)

- `evidence-discipline-is-inheritable` — the v2.3 viewer-evidence recording discipline (recorded
  proof or named `explicit_deferral`, never silent `unverified`) is a reusable pattern any new
  surface must inherit; it graduated from a phase tactic to a project-wide contract.
- `proof-axis-at-diminishing-returns` — proof/trust investment has crossed into diminishing returns;
  leverage has shifted to adoption ergonomics. Record so future milestones don't re-deepen proof by
  default.

## Open questions for `/gsd-new-milestone`

- Fold the page-numbering/running-footer primitive INTO v2.4 (recommended — recipes depend on it) or
  split it into its own phase?
- Which 2–3 recipes ship in v2.4 (statement + receipt/report + certificate is the proposed set)?
- Is the reference-app CI lane in v2.4 scope or deferred to the 1.0 milestone?

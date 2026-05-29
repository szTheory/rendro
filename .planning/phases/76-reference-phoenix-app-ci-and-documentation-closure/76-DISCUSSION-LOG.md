# Phase 76: Reference Phoenix App, CI, and Documentation Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 76-Reference Phoenix App, CI, and Documentation Closure
**Mode:** `--auto` (advisor, calibration tier `minimal_decisive`) — all gray areas auto-selected; recommended option locked per area after parallel codebase research. No interactive prompts.
**Areas discussed:** Phoenix reference-app modernization, Recipe demonstration surface, CI isolation mechanism, Guides + docs-contract enforcement

---

## Phoenix Reference-App Modernization Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| A. Upgrade existing scaffold in place | Bump constraints, fix missing `ErrorJSON`, keep hand-rolled minimal structure (lock already on 1.8 line) | ✓ |
| B. Regenerate with `mix phx.new --no-*` and port controllers | Matches stock 1.8 generator output | |

**Auto-selected:** Option A (recommended default). `[auto] → Selected: "Upgrade in place"`
**Notes:** Research found `mix.lock` already resolves Phoenix 1.8.5 / jason 1.4.4 / plug 1.19.1 with zero generator boilerplate. Regeneration would re-add omitted boilerplate and force re-porting all recipe controllers. Surfaced a load-bearing bug: `config.exs` references a missing `PhoenixExampleWeb.ErrorJSON` module.

---

## Recipe Demonstration Surface

| Option | Description | Selected |
|--------|-------------|----------|
| A. Extend existing dead-controller pattern | One download/preview action pair per new recipe, inline fixtures, mirror existing tests | ✓ |
| B. Shared SampleData module + LiveView gallery | Central fixtures, LiveView index | |

**Auto-selected:** Option A (recommended default). `[auto] → Selected: "Extend dead-controller pattern"`
**Notes:** LiveView is not a dependency and contradicts the minimal/PDF-only mandate. Option A mirrors the shipped Invoice/BrandedInvoice surface (`render_pdf/3` / `preview_pdf/2`) that arriving engineers will copy.

---

## CI Isolation Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| A. `needs: []` (fully independent) + `advisory_contexts` entry | Graph-disconnected; earliest independent signal; cannot gate/be-gated by engine lanes | ✓ |
| B. `needs: test` (mirror `viewer-evidence-live-proof`) | Consistent with existing advisory job; skips when engine `test` red | |

**Auto-selected:** Option A (recommended default). `[auto] → Selected: "needs: [] independent advisory job"`
**Notes:** REF-03's hard constraint (Phoenix-dep failure must never block engine lanes + signal must be independently visible) is satisfied structurally by `needs: []`. `needs: test` would suppress the example signal whenever engine `test` is red. No `continue-on-error` (would mask red as green). Required/advisory status is recorded in `priv/guardrails/required_status_checks.json`; the guardrail test's single-element advisory destructure must be refactored.

---

## Guides + Docs-Contract Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| A. Consolidated `recipes.md` + `page_primitive.md`, reuse both existing harnesses | 2 guides mapping to the 4 real matrix rows; Invoice/Branded point to branding guide | ✓ |
| B. Six separate guides, one claims test each | Maximal granularity | |

**Auto-selected:** Option A (recommended default). `[auto] → Selected: "Two consolidated guides"`
**Notes:** Support matrix has exactly 4 new surface rows and no separate invoice/branded rows. Option B would create guides whose claims have no matrix row to cross-check and duplicate existing branding coverage. Reuse the fence harness (`Rendro.Test.DocsContract`) + the semantic-claims `*_claims_test.exs` pattern verbatim.

---

## Claude's Discretion

- README prose/structure, exact guide wording and example selection, fixture sample values, and `# docs-contract:` fence ids — left to planning/execution within the locked decisions.

## Deferred Ideas

None — discussion stayed within phase scope. The missing `PhoenixExampleWeb.ErrorJSON` module was folded into scope (D-03) as it blocks REF-01's `mix`-runnable requirement, not deferred.

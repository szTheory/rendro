# Roadmap: Rendro

## Overview

Rendro will be delivered through five coarse phases that move from non-negotiable core guarantees (pure deterministic rendering) to production viability (pagination, observability, Phoenix integration, release quality) and finally to early ecosystem recipes. This ordering prioritizes reliability and truthful scope before breadth.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Core Deterministic Foundation** - Establish pure core boundaries, deterministic rendering contract, and lifecycle event/error schema.
- [x] **Phase 2: Layout and Pagination Engine** - Deliver practical document primitives, robust pagination, and table/header behavior for real invoice/report workloads.
- [x] **Phase 3: Adapter and Ops Integration** - Add optional Phoenix/job adapter patterns with bounded execution and operational metrics.
- [x] **Phase 4: Quality and Release Hardening** - Implement CI verification contracts, docs truthfulness checks, and release safety gates.
- [ ] **Phase 5: Early Ecosystem Recipes** - Ship do-now integration recipes without violating core boundary constraints.
- [ ] **Phase 6: Pipeline Telemetry Contract Fixes** - Restore the spec-stated pipeline stage order and emit the missing `:validate` telemetry event so observability matches OBS-01.
- [ ] **Phase 7: Phoenix Adapter Hardening + Example Skeleton** - Guard the optional Phoenix adapter, complete the example app, and surface structured error envelopes through HTTP responses.
- [x] **Phase 8: Bounded Async + Timeout Telemetry** - Inject policy bounds into the Oban worker and emit `:exception` telemetry on render timeouts so audit handlers see them.
- [ ] **Phase 9: CI Scheduler + Release Hardening** - Land the CI YAML, expand the `mix ci` lane, fix `mix verify` advisory crash semantics, and harden release preflight tag/dry-run parity.
- [ ] **Phase 10: Recipe Correctness + Traceability Sync** - Fix Mailglass custom-wrapper dispatch, return typed errors from Accrue, and resync REQUIREMENTS.md ADPT-05 status.
- [x] **Phase 11: Reconstruct Phase 1-4 GSD Artifacts** - Map existing tests to requirements and produce evidence-based PLAN/SUMMARY/VERIFICATION for phases 1-4 against the fixed code.
- [x] **Phase 12: Verification Chain Closure** - Commit hosted CI proof, make `mix verify` complete deterministic and advisory lanes end-to-end, and close the remaining verification-lane gaps.
- [x] **Phase 13: Docs and Release Preflight Closure** - Remove docs-contract blind spots and make release preflight fail on dirty/tag-parity issues while exercising publish dry-run parity.
- [ ] **Phase 14: Milestone Verification Artifact Backfill** - Add milestone-grade `VERIFICATION.md` artifacts for Phases 7-11 and resync traceability/process evidence with the audit.

## Phase Details

### Phase 1: Core Deterministic Foundation
**Goal**: Deliver a pure Elixir core document/render pipeline with deterministic mode and actionable observability/error foundations.
**Depends on**: Nothing (first phase)
**Requirements**: [CORE-01, CORE-02, CORE-05, OBS-01, OBS-03]
**Success Criteria** (what must be TRUE):
  1. Engineer can render a valid PDF from Elixir data using core APIs only.
  2. The same deterministic input produces repeatable artifacts in CI fixtures.
  3. Lifecycle telemetry events are emitted for core pipeline stages.
  4. Render failures return structured diagnostics with what/where/why/next guidance.
**Plans**: 2 plans

Plans:
- [x] 01-01: Build pure core document model and rendering skeleton
- [x] 01-02: Implement deterministic mode plus telemetry and structured error schema

### Phase 2: Layout and Pagination Engine
**Goal**: Make invoice/report generation viable with robust flow layout, multi-page tables, and predictable page-level composition.
**Depends on**: Phase 1
**Requirements**: [CORE-03, CORE-04, LAY-01, LAY-02, LAY-03, LAY-04, LAY-05]
**Success Criteria** (what must be TRUE):
  1. Engineer can choose fixed-position or flow API over the same rendering engine.
  2. Multi-page content paginates automatically with stable break behavior.
  3. Tables repeat headers correctly across page breaks.
  4. Headers/footers and page numbers render in predictable positions.
  5. Overflow diagnostics identify failing block path and remediation options.
**Plans**: 3 plans

Plans:
- [x] 02-01: Implement dual API surface and shared document primitives
- [x] 02-02: Build pagination/table engine with repeat-header and overflow handling
- [x] 02-03: Add header/footer placement and metadata behavior with deterministic fixtures

### Phase 3: Adapter and Ops Integration
**Goal**: Enable production adoption through optional adapters, operational metrics, and bounded rendering policies.
**Depends on**: Phase 2
**Requirements**: [ADPT-01, ADPT-02, ADPT-03, ADPT-04, OBS-02, OBS-04]
**Success Criteria** (what must be TRUE):
  1. Phoenix teams can download and preview rendered PDFs through optional adapters.
  2. Optional adapters can be enabled/disabled without breaking core compilation.
  3. Background render pattern is available via optional job adapter integration.
  4. Operators can enforce max pages/bytes/timeouts on render execution.
  5. Render artifact metrics are correlated and observable for operations workflows.
**Plans**: 2 plans

Plans:
- [x] 03-01: Implement optional Phoenix adapter helpers for download/preview workflows
- [x] 03-02: Add optional job adapter pattern, policy bounds, and artifact metric correlation

### Phase 4: Quality and Release Hardening
**Goal**: Guarantee truthful, reproducible delivery through canonical verification and release safety automation.
**Depends on**: Phase 3
**Requirements**: [QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05]
**Success Criteria** (what must be TRUE):
  1. `mix ci` enforces merge-blocking format/compile/test/docs/package checks.
  2. Docs-contract checks fail on unsupported or drifting public claims.
  3. Phoenix example host app executes in CI as adoption proof.
  4. Release preflight catches version/tag mismatch and publish issues before release.
  5. Verification output clearly separates deterministic required lanes from advisory lanes.
**Plans**: 2 plans

Plans:
- [x] 04-01: Build canonical verify lanes and deterministic/advisory verification contract
- [x] 04-02: Add docs-contract checks, example app CI, and release preflight parity automation

### Phase 5: Early Ecosystem Recipes
**Goal**: Provide validated do-now integration recipes for high-value ecosystem workflows while preserving architecture boundaries.
**Depends on**: Phase 4
**Requirements**: [ADPT-05]
**Success Criteria** (what must be TRUE):
  1. Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue`.
  2. Recipes remain optional and do not introduce hard dependencies into core.
  3. Integration documentation includes verification guidance and failure diagnostics.
**Plans**: 4 plans (05-01 executed; 05-02..05-04 added by gap closure 2026-04-26)

Plans:
- [x] 05-01: Implement and validate threadline/mailglass/accrue recipe integrations (verification: 4/7 must-haves; gaps closed below)
- [x] 05-02-PLAN.md — Implement optional Accrue billing-document recipe with contract mock (closes Gap 1)
- [x] 05-03-PLAN.md — Fix Mailglass attach_pdf/3 contract violations CR-01, CR-02, WR-03 with negative-path tests (closes Gap 3)
- [x] 05-04-PLAN.md — Author integration guide and wire into ExDoc + README (closes Gap 2)

### Phase 6: Pipeline Telemetry Contract Fixes
**Goal**: Bring the rendering pipeline back into agreement with REQUIREMENTS.md OBS-01 — emit the missing `:validate` telemetry event, restore spec-stated stage order (build → compose → measure → paginate → render → validate), and stop dropping page/byte metrics on the error path.
**Depends on**: None (independent of other gap-closure phases)
**Requirements**: [OBS-01, OBS-02, CORE-01]
**Gap Closure**: Closes BLOCKER-04, BLOCKER-05, MINOR-15 from `.planning/v1.0-MILESTONE-AUDIT.md`
**Success Criteria** (what must be TRUE):
  1. Pipeline emits `[:rendro, :stage, :start|:stop|:exception]` for `:validate` in addition to existing five stages.
  2. Stage execution order matches REQUIREMENTS.md spec (compose precedes measure).
  3. Stage stop metadata preserves `page_count` and `byte_size` from `doc.pages` even on the error path.
**Plans**: 3 plans

Plans:
- [x] 06-01-PLAN.md — Telemetry plumbing: add :validate to stage_names, unify stage_stop_meta (D-11..D-14), update build_stop_meta (D-16), add Rendro.Error :validate clauses (D-09); closes MINOR-15
- [x] 06-02-PLAN.md — Create Rendro.Pipeline.Validate stage module + wire into with-chain after :render; absorb max_bytes; CHANGELOG.md (D-18); closes BLOCKER-04
- [x] 06-03-PLAN.md — Restore canonical stage order (compose before measure); move normalize_row → Compose, y-stacking → Paginate (D-02..D-04); D-04 page-2 regression; D-20 Threadline verification; closes BLOCKER-05

### Phase 7: Phoenix Adapter Hardening + Example Skeleton
**Goal**: Make the optional Phoenix adapter actually optional and the example app actually compilable, while surfacing structured `%Rendro.Error{}` envelopes through HTTP responses instead of leaking raw atoms.
**Depends on**: None (independent of other gap-closure phases)
**Requirements**: [ADPT-01, ADPT-02, ADPT-03, OBS-03, QUAL-03]
**Gap Closure**: Closes BLOCKER-01, BLOCKER-02, MAJOR-11; restores Phoenix download/preview flows
**Success Criteria** (what must be TRUE):
  1. `lib/rendro/adapters/phoenix.ex` compiles and behaves correctly when `:plug` is absent (guarded by `Code.ensure_loaded?`).
  2. `examples/phoenix_example/` boots end-to-end (Application, Endpoint, Router, Web, config) and renders a download response.
  3. Error responses from the Phoenix adapter render the structured `%Rendro.Error{}` envelope (what/where/why/next), not `inspect(reason)`.
**Plans**: 1 plan

Plans:
- [x] 07-01-PLAN.md — Harden Phoenix adapter and Example Skeleton

### Phase 8: Bounded Async + Timeout Telemetry
**Goal**: Make `Rendro.Adapters.Oban.RenderWorker` enforce render policy bounds and make the pipeline timeout path emit `:exception` telemetry so Threadline-style audit handlers can observe timeouts.
**Depends on**: Phase 6 (uses telemetry contract)
**Requirements**: [ADPT-04, ADPT-05, OBS-02, OBS-04]
**Gap Closure**: Closes MAJOR-07, MAJOR-10; restores Threadline timeout audit flow
**Success Criteria** (what must be TRUE):
  1. Oban RenderWorker injects `max_pages`/`max_bytes`/`timeout` from job args into the document policy and has dedicated test coverage.
  2. `Pipeline.run/1` timeout path emits `[:rendro, :stage, :exception]` (or equivalent) before returning `{:error, :timeout}`.
  3. Threadline integration test (or equivalent) observes the timeout exception and records the audit entry.
**Plans**: 1 plan

Plans:
- [ ] 08-01-PLAN.md — Inject render policy bounds into Oban RenderWorker and emit telemetry exception on timeout

### Phase 9: CI Scheduler + Release Hardening
**Goal**: Land an actual CI scheduler that runs `mix ci`, expand `mix ci` to match the QUAL-01 contract (format, compile, tests, docs, hex.build), fix `mix verify`'s advisory MatchError crash, fix `verify_docs.exs` `...` skip, and tighten `release.preflight` to enforce git-tag parity and a publish dry-run.
**Depends on**: Phase 7 (Phoenix example app required for `mix verify` to pass)
**Requirements**: [QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05]
**Gap Closure**: Closes BLOCKER-03, MAJOR-09, MAJOR-12, MAJOR-13, MINOR-14
**Success Criteria** (what must be TRUE):
  1. `.github/workflows/` (or equivalent) runs `mix ci` on every PR and merge to main.
  2. `mix ci` includes `format --check-formatted`, `docs`, and `hex.build` in addition to compile/test/credo/dialyzer.
  3. `mix verify` advisory lane returns a non-zero exit but does not crash with `MatchError`; example dir gets `mix deps.get` first.
  4. `release.preflight` fails on tag/version mismatch and runs `mix hex.publish --dry-run`.
  5. `verify_docs.exs` exercises code blocks containing `...` (or warns rather than silently skipping).
**Plans**: 2 plans

Plans:
- [ ] 09-01-PLAN.md — Setup GitHub CI and expand mix ci pipeline
- [ ] 09-02-PLAN.md — Hardened verification lanes and release preflight

### Phase 10: Recipe Correctness + Traceability Sync
**Goal**: Fix the remaining Phase 5 recipe defects (Mailglass custom-wrapper dispatch, Accrue line-item discipline, Accrue date sigil leak) and resync REQUIREMENTS.md ADPT-05 status with 05-VERIFICATION.md so the traceability table tells the truth.
**Depends on**: None (independent of other gap-closure phases)
**Requirements**: [ADPT-05, QUAL-04]
**Gap Closure**: Closes BLOCKER-06, REVIEW CR-01, REVIEW WR-06, REVIEW IN-04; resolves Mailglass custom-wrapper human-test path
**Success Criteria** (what must be TRUE):
  1. `Rendro.Adapters.Mailglass.put_swoosh/2` dispatches custom wrapper structs (any module ending in `.Message` exporting `update_swoosh/2`) without `FunctionClauseError`.
  2. `Rendro.Adapters.Accrue.recipe/1` returns `{:error, {:invalid_invoice, _}}` on non-`%LineItem{}` entries instead of raising.
  3. Accrue invoice does not render `~D[...]` sigil syntax for `issued_at` (uses `Date.to_iso8601/1` or equivalent).
  4. REQUIREMENTS.md ADPT-05 row reads `[x]` / Done, matching `05-VERIFICATION.md`.
**Plans**: 2 plans

Plans:
- [ ] 10-01-PLAN.md — Fix Mailglass and Accrue recipe contracts with regression tests and guide updates
- [ ] 10-02-PLAN.md — Sync Phase 5 verification artifacts and REQUIREMENTS traceability with Phase 10 evidence

### Phase 11: Reconstruct Phase 1-4 GSD Artifacts
**Goal**: Produce evidence-based PLAN.md, SUMMARY.md, and VERIFICATION.md for Phases 1, 2, 3, and 4 by mapping the existing source tree and test suite to each requirement, so all 23 currently-orphaned requirements have formal verification trails.
**Depends on**: Phases 6, 7, 8, 9, 10 (verifies against the fixed code)
**Requirements**: [CORE-01, CORE-02, CORE-03, CORE-04, CORE-05, LAY-01, LAY-02, LAY-03, LAY-04, LAY-05, ADPT-01, ADPT-02, ADPT-03, ADPT-04, OBS-01, OBS-02, OBS-03, OBS-04, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05]
**Gap Closure**: Closes the formal-orphan status of all 23 requirements claimed Done by Phases 1-4 in REQUIREMENTS.md but unbacked by GSD artifacts
**Success Criteria** (what must be TRUE):
  1. `.planning/phases/01-core-deterministic-foundation/` has a reconstructed PLAN.md, SUMMARY.md, and VERIFICATION.md that map each Phase 1 requirement to specific source files and tests.
  2. New `.planning/phases/02-layout-and-pagination-engine/`, `.planning/phases/03-adapter-and-ops-integration/`, `.planning/phases/04-quality-and-release-hardening/` directories exist with the same triad of artifacts.
  3. Each VERIFICATION.md scores must-haves against the live test suite (not against intent statements).
  4. REQUIREMENTS.md traceability statuses for Phases 1-4 reflect verified evidence, not documentation drift.
**Plans**: 1 plan (to be planned via `/gsd-plan-phase 11`)

### Phase 12: Verification Chain Closure
**Goal**: Restore trustworthy quality verification by committing the hosted CI workflow, making `mix verify` complete both deterministic and advisory lanes without aborting early, and re-proving the Phoenix example path under CI-backed evidence.
**Depends on**: Phase 11
**Requirements**: [QUAL-01, QUAL-03, QUAL-05]
**Gap Closure**: Closes `INT-VERIFY-LANES`, `INT-CI-TRACKING`, and the audit flow break in verification lane separation from `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`
**Success Criteria** (what must be TRUE):
  1. `.github/workflows/ci.yml` is tracked in git and runs the canonical verification lane on PRs and merges.
  2. `mix verify` executes deterministic and advisory segments end-to-end and reports failures without crashing or aborting the advisory segment prematurely.
  3. Phoenix example adoption proof is exercised by committed CI evidence rather than only by local compilation state.
**Plans**: 3/3 plans complete

Plans:
- [x] 12-01-PLAN.md — Commit hosted CI workflow and explicit Phoenix example proof
- [x] 12-02-PLAN.md — Complete `mix verify` deterministic and advisory lanes end-to-end
- [x] 12-03-PLAN.md — Expand `mix ci` to the full QUAL-01 contract and pin the public `mix verify` shutdown boundary

### Phase 13: Docs and Release Preflight Closure
**Goal**: Close the remaining docs-contract and release-safety gaps so public claims and release automation are both enforced by executable checks.
**Depends on**: Phase 12
**Requirements**: [QUAL-02, QUAL-04]
**Gap Closure**: Closes `INT-RELEASE-PREFLIGHT` and the audit flow breaks in docs-contract verification and release preflight from `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`
**Success Criteria** (what must be TRUE):
  1. `scripts/verify_docs.exs` no longer silently skips partial snippets that matter to public contract verification, or explicitly fails/warns in a way CI surfaces.
  2. `mix release.preflight` fails dirty worktrees, enforces tag/version parity, and reaches publish dry-run parity checks.
  3. Docs-contract and release-preflight checks can be rerun as evidence-backed milestone gates.
**Plans**: 3 plans

Plans:
- [x] 13-01-PLAN.md — Close the curated docs contract with explicit lanes, guide curation, and semantic-claim regression tests
- [x] 13-02-PLAN.md — Rebuild `mix release.preflight` as a strict two-phase release gate with package-build parity and blocker coverage
- [x] 13-03-PLAN.md — Add canonical docs/release proof surfaces so milestone evidence can be rerun from named commands and isolated release-like state

### Phase 14: Milestone Verification Artifact Backfill
**Goal**: Produce milestone-grade verification artifacts for Phases 7 through 11 and repair traceability/process drift so audit status, summaries, and requirement rows tell the same story.
**Depends on**: Phases 12, 13
**Requirements**: [ADPT-01, ADPT-02, ADPT-03, ADPT-04, ADPT-05, OBS-03, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05]
**Gap Closure**: Closes `INT-PHASE-ARTIFACTS` and the audit-noted traceability drift for later gap-closure phases from `.planning/v1.0-v1.0-MILESTONE-AUDIT.md`
**Success Criteria** (what must be TRUE):
  1. Phases `07`, `08`, `09`, `10`, and `11` each have milestone-grade `VERIFICATION.md` artifacts.
  2. Summary metadata and workflow extraction fields use the naming expected by automation so evidence is discoverable.
  3. REQUIREMENTS.md traceability for affected adapter/quality requirements matches the new artifact-backed verification state.
**Plans**: 3/4 plans executed

Plans:
- [x] 14-01-PLAN.md — Backfill Phase 07 and 08 verification/validation artifacts and normalize summary metadata
- [x] 14-02-PLAN.md — Re-verify the Phase 09 quality chain, replace legacy validation, and reconcile summary drift
- [x] 14-03-PLAN.md — Backfill Phase 10 verification and retire stale recipe evidence that Phase 10 already closed
- [ ] 14-04-PLAN.md — Backfill Phase 11 verification, normalize later summary metadata, and sync final requirements truth

## Progress

**Execution Order:**
Phases execute in numeric order: 2 -> 2.1 -> 2.2 -> 3 -> 3.1 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Deterministic Foundation | 0/2 | Not started | - |
| 2. Layout and Pagination Engine | 0/3 | Not started | - |
| 3. Adapter and Ops Integration | 0/2 | Not started | - |
| 4. Quality and Release Hardening | 0/2 | Not started | - |
| 5. Early Ecosystem Recipes | 0/1 | Not started | - |

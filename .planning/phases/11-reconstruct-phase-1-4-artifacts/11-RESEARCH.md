# Phase 11: Reconstruct Phase 1-4 Artifacts - Research

**Researched:** 2026-04-28 [VERIFIED: codebase grep]  
**Domain:** GSD artifact reconstruction, requirement-boundary verification mapping, and traceability repair for Phases 1-4 [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Confidence:** MEDIUM [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md` [VERIFIED: codebase grep]

### Locked Decisions

> - **D-01:** A requirement may be marked verified only when it has one primary executable proof at the requirement's public boundary in the live fixed codebase.
> - **D-02:** Supporting evidence may include source links, docs links, and prior phase artifacts, but supporting evidence never substitutes for the primary proof.
> - **D-03:** Source inspection, file presence, historical intent, or narrative confidence alone are never sufficient to flip a requirement to verified.
> - **D-04:** Default primary-proof types by requirement class are locked:
>   - Core/layout/determinism/telemetry/error requirements: ExUnit, property, or integration tests at the public API boundary.
>   - Phoenix/Plug adapter requirements: connection- or endpoint-level proof where practical, not helper-only proof by default.
>   - Optional dependency discipline requirements: guarded compilation/runtime proof such as `mix compile --no-optional-deps --warnings-as-errors` or equivalent.
>   - Docs-contract claims: executable doctests, markdown doctests, or docs-contract verification.
>   - CI/release claims: runnable command or workflow proof, not config-file presence alone.
> - **D-05:** If a requirement cannot be tied to executable proof or a clearly named manual check, it stays non-verified and the gap is stated explicitly.
> - **D-06:** Phase 11 is a read-mostly reconstruction phase against the fixed codebase.
> - **D-07:** Targeted test, docs, and traceability edits are allowed only when they prove an already-existing contract and do not change public behavior, accepted input shapes, telemetry semantics, optional-dependency boundaries, or release semantics.
> - **D-08:** Runtime code changes are out of scope for Phase 11 unless the phase is explicitly re-scoped by the user.
> - **D-09:** If reconstruction discovers a real behavior gap rather than a proof gap, the requirement is recorded as partial/blocked in the phase verification artifact and routed to a separate remediation plan or gap-closure phase.
> - **D-10:** When in doubt, prefer a narrower truthful status over a broader verified claim.
> - **D-11:** Each reconstructed `VERIFICATION.md` uses a hybrid structure: short success-criteria summary first, requirement-first body second, artifact appendix last.
> - **D-12:** Requirement-level sections are the traceability backbone. Success criteria are a reader aid, not the proof model. Artifact inventory is supporting evidence, not the primary verification structure.
> - **D-13:** Verification documents must describe the live fixed codebase and current executable proof, not historical implementation intent from the original Phase 1-4 execution window.
> - **D-14:** Repeated evidence should be cited once and cross-referenced, not duplicated across summary, requirement matrix, and artifact appendix.
> - **D-15:** `.planning/REQUIREMENTS.md` traceability rows update only from a completed reconstructed `VERIFICATION.md`, never from source mapping, planning, or summary writing alone.
> - **D-16:** Rows remain `Pending` until the relevant reconstructed phase verification closes, then update immediately row-by-row from that finished verdict.
> - **D-17:** Mixed outcomes must remain mixed. The default status vocabulary for the traceability table is `Pending`, `Done`, `Partial`, and `Blocked`.
> - **D-18:** If a requirement was fixed by a later gap-closure phase but Phase 11 is the formal verification point, do not mark it `Done` until Phase 11 closes it with explicit evidence.
> - **D-19:** Downstream agents should default to research-backed recommendations and make routine implementation-discipline choices without escalating them to the user.
> - **D-20:** Escalate only when a decision changes product semantics, revises a documented public contract, or presents a genuinely high-impact user-visible tradeoff.
> - **D-21:** For this phase, the least-surprise default is evidence-first, requirement-first, and recommendation-first. Avoid menus of equivalent options when one clearly better default fits Rendro's methodology.

### Claude's Discretion

> - Exact subsection names and table layouts inside reconstructed `PLAN.md`, `SUMMARY.md`, and `VERIFICATION.md`, as long as D-11 through D-14 stay intact.
> - Whether a proof is best expressed as an existing test mapping, a targeted new proving test, or a runnable command, as long as D-01 through D-05 remain satisfied.
> - Whether to keep nuanced mixed outcomes only in `VERIFICATION.md` or also mirror them in additional summary text, as long as `.planning/REQUIREMENTS.md` remains truthful and aligned.

### Deferred Ideas (OUT OF SCOPE)

> - If Phase 11 uncovers real runtime defects rather than missing proof, queue those as separate remediation work instead of broadening this reconstruction phase.
> - If the new `Pending`/`Done`/`Partial`/`Blocked` status vocabulary proves too heavy for the central table, simplify later only after Phase 11 lands and the tradeoff is visible in real repo usage.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-01 | Engineer can define a PDF document from Elixir data/components using a pure core API. [VERIFIED: .planning/REQUIREMENTS.md] | Map to `test/rendro_builders_test.exs`, `test/rendro/integration_test.exs`, `test/rendro/pipeline_test.exs`, and Phase 06 proof for the fixed six-stage pipeline. [VERIFIED: codebase grep] |
| CORE-02 | Engineer can render PDFs without requiring Chrome/Chromium runtime in core. [VERIFIED: .planning/REQUIREMENTS.md] | Use live `mix test` proof plus grep showing no browser-runtime invocation in core `lib/` render path. [VERIFIED: mix test] [VERIFIED: codebase grep] |
| CORE-03 | Engineer can use a fixed-position API for exact-placement document use cases. [VERIFIED: .planning/REQUIREMENTS.md] | Map to `Rendro.fixed/2` in `lib/rendro.ex` and fixed-path tests in `test/rendro/flow_test.exs` and `test/rendro/integration_test.exs`. [VERIFIED: codebase grep] |
| CORE-04 | Engineer can use a flow API for report/document use cases. [VERIFIED: .planning/REQUIREMENTS.md] | Map to `Rendro.flow/2` and flow tests in `test/rendro/flow_test.exs`, plus invoice-style README/examples only as supporting evidence. [VERIFIED: codebase grep] |
| CORE-05 | Engineer can run deterministic mode that produces repeatable artifacts for identical inputs. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro_test.exs` and `test/rendro/deterministic_test.exs` as primary proof. [VERIFIED: codebase grep] |
| LAY-01 | Engineer can compose document primitives including pages, blocks, tables, headers/footers, and metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Map to builder tests, `test/rendro/metadata_test.exs`, `test/rendro/flow_test.exs`, and public builders in `lib/rendro.ex`. [VERIFIED: codebase grep] |
| LAY-02 | Engineer can render flowing content with automatic page breaks. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/flow_test.exs` page-count assertions and `test/rendro/pipeline/paginate_test.exs`. [VERIFIED: codebase grep] |
| LAY-03 | Engineer can render large tables across pages with repeating table headers. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/flow_test.exs` table-splitting and repeated-header assertions. [VERIFIED: codebase grep] |
| LAY-04 | Engineer can configure headers/footers with page numbers and predictable placement. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/flow_test.exs` header/footer/page-number test as primary proof. [VERIFIED: codebase grep] |
| LAY-05 | Engineer receives overflow diagnostics that identify where layout failed and what to try next. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/flow_test.exs` overflow error plus `test/rendro/error_test.exs` structured envelope assertions. [VERIFIED: codebase grep] |
| ADPT-01 | Phoenix engineer can serve rendered PDFs through download-friendly adapter helpers. [VERIFIED: .planning/REQUIREMENTS.md] | Existing evidence is compile-level only; add a targeted connection- or endpoint-level proving test unless a current executable endpoint proof already exists outside the repo. [VERIFIED: codebase grep] |
| ADPT-02 | Phoenix engineer can preview rendered output through Phoenix-friendly integration helpers. [VERIFIED: .planning/REQUIREMENTS.md] | Same as ADPT-01; `preview_pdf/2` has route/example evidence but no current conn-level test. [VERIFIED: codebase grep] |
| ADPT-03 | Maintainer can enable optional adapters without introducing hard compile/runtime dependencies in core. [VERIFIED: .planning/REQUIREMENTS.md] | Use `optional: true` deps, adapter `Code.ensure_loaded?` guards, and passing `mix compile --no-optional-deps --warnings-as-errors`. [VERIFIED: codebase grep] [VERIFIED: mix compile --no-optional-deps --warnings-as-errors] |
| ADPT-04 | Maintainer can use an optional job-processing adapter pattern for bounded asynchronous rendering. [VERIFIED: .planning/REQUIREMENTS.md] | Use `lib/rendro/adapters/oban/render_worker.ex` plus `test/rendro/adapters/oban/render_worker_test.exs`. [VERIFIED: codebase grep] |
| OBS-01 | Operator can observe telemetry events for build, compose, measure, paginate, render, and validate lifecycle steps. [VERIFIED: .planning/REQUIREMENTS.md] | Cross-reference Phase 06 verification and current `test/rendro/telemetry_test.exs`. [VERIFIED: .planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md] [VERIFIED: codebase grep] |
| OBS-02 | Operator can correlate render operations with artifact metrics (duration, page count, byte size, status). [VERIFIED: .planning/REQUIREMENTS.md] | Use current telemetry tests, timeout exception test, Threadline adapter tests, and Phase 08 behavior already present in the live code. [VERIFIED: mix test] [VERIFIED: codebase grep] |
| OBS-03 | Operator receives structured errors that explain what happened, where it failed, why, and suggested next actions. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/error_test.exs`, `test/rendro/pipeline_test.exs`, and Phoenix stringification only as supporting evidence. [VERIFIED: codebase grep] |
| OBS-04 | Operator can enforce policy bounds for max pages, max output bytes, and render timeouts. [VERIFIED: .planning/REQUIREMENTS.md] | Use `test/rendro/policy_test.exs`, `test/rendro/adapters/oban/render_worker_test.exs`, and `test/rendro/pipeline_test.exs`. [VERIFIED: codebase grep] |
| QUAL-01 | Maintainer can run a canonical merge-blocking verification lane (`mix ci`) including format, compile, tests, docs, and package build. [VERIFIED: .planning/REQUIREMENTS.md] | Primary proof should be `mix ci` on a clean tree; current workspace-level `mix verify` failed because format-check caught an already-modified file, so Phase 11 should treat a clean-tree rerun as mandatory. [VERIFIED: mix verify] [VERIFIED: codebase grep] |
| QUAL-02 | Maintainer can validate public docs/quickstart claims with docs-contract checks in CI. [VERIFIED: .planning/REQUIREMENTS.md] | Use `scripts/verify_docs.exs`, `mix run scripts/verify_docs.exs`, and CI wiring as supporting evidence. [VERIFIED: mix run scripts/verify_docs.exs] [VERIFIED: codebase grep] |
| QUAL-03 | Maintainer can run a CI-verified Phoenix example app as executable adoption proof. [VERIFIED: .planning/REQUIREMENTS.md] | Local example compile succeeds, but current workflow file only runs `mix ci`; Phase 11 should be prepared for `Partial` or `Blocked` unless separate CI proof exists. [VERIFIED: cd examples/phoenix_example && mix compile] [VERIFIED: codebase grep] |
| QUAL-04 | Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows. [VERIFIED: .planning/REQUIREMENTS.md] | `mix release.preflight` exists and currently fails on missing exact tag, which proves the parity gate is live; dry-run behavior is source-proven but may need a tagged manual check for full closure. [VERIFIED: mix release.preflight] [VERIFIED: codebase grep] |
| QUAL-05 | Maintainer can separate deterministic required lanes from advisory/provider-dependent lanes in verification output. [VERIFIED: .planning/REQUIREMENTS.md] | Use `lib/mix/tasks/verify.ex` and the observed `mix verify` output headings as the primary public-boundary proof. [VERIFIED: mix verify] [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 11 should be planned as a requirement-first reconstruction pass, not as a retrospective narrative rewrite. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] The repo already has enough live proof to close most of Phases 1, 2, and the non-Phoenix parts of Phase 3 and Phase 4 using read-only mapping from existing tests, mix tasks, and the fixed pipeline behavior landed in later gap-closure phases. [VERIFIED: mix test] [VERIFIED: .planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md] [VERIFIED: codebase grep]

The safest decomposition is phase-by-phase in original order, with `VERIFICATION.md` written first conceptually, then `SUMMARY.md`, then `PLAN.md` reconstructed from the evidence and known implementation surfaces. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] Do not bulk-update `.planning/REQUIREMENTS.md`; update only the rows owned by a reconstructed phase after that phase's `VERIFICATION.md` reaches a final truthful verdict. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

Two areas are likely to need narrower handling. [VERIFIED: codebase grep] Phase 3 adapter verification probably needs a targeted Phoenix conn/endpoint proving test because the current repo has compile-level example proof but no explicit connection-level test for `render_pdf/3` or `preview_pdf/2`. [VERIFIED: codebase grep] Phase 4 may need mixed outcomes because the current GitHub Actions workflow does not execute the example app proof path, and `mix release.preflight` cannot complete its happy path without an exact git tag. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: mix release.preflight]

**Primary recommendation:** Plan Phase 11 as four sequential reconstruction slices, allow targeted proving tests only for ADPT-01 and ADPT-02 by default, and expect QUAL-03 and QUAL-04 to remain mixed unless current executable proof closes them without changing CI/release semantics. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure: no hard dependency on Phoenix, Oban, or admin tooling. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts; do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Prefer optional dependency guards (`optional: true` + compile/runtime checks) for integrations. [VERIFIED: AGENTS.md]
- Preserve the data-first pipeline `build -> compose -> measure -> paginate -> render -> validate` when referencing proof surfaces. [VERIFIED: AGENTS.md]
- Core never depends on adapter packages; adapters consume core APIs. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Requirement-boundary executable proof | API / Backend [VERIFIED: codebase grep] | CI / Tooling [VERIFIED: codebase grep] | The proof lives in ExUnit, Mix tasks, and example-app compilation against Elixir code, not in planning prose. [VERIFIED: mix test] |
| Reconstructed phase artifacts (`PLAN.md`, `SUMMARY.md`, `VERIFICATION.md`) | Repository Docs [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | The documents are persisted in `.planning/phases/*`, but their truth comes from backend code and tests. [VERIFIED: codebase grep] |
| Traceability status updates in `.planning/REQUIREMENTS.md` | Repository Docs [VERIFIED: codebase grep] | CI / Tooling [VERIFIED: codebase grep] | The table is the durable source of status, but rows must be driven by completed executable verification. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Optional-dependency proof | CI / Tooling [VERIFIED: mix help compile] | API / Backend [VERIFIED: codebase grep] | The decisive boundary is `mix compile --no-optional-deps --warnings-as-errors`, backed by adapter guards in code. [VERIFIED: mix compile --no-optional-deps --warnings-as-errors] |
| Example-app adoption proof | CI / Tooling [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | QUAL-03 is about executable adoption proof; the example source alone is insufficient without command or workflow evidence. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir + Mix | `1.19.5` / built-in [VERIFIED: elixir --version] | Execute tests, compile paths, docs-contract checks, and mix-task proofs | The repo's proof surfaces are already expressed as Mix commands and ExUnit tests. [VERIFIED: codebase grep] |
| ExUnit | bundled with Elixir `1.19.5` [VERIFIED: elixir --version] | Primary executable proof at public boundaries | D-01 and D-04 prefer executable boundary proof over narrative mapping. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| StreamData | `~> 1.3` in `mix.exs` [VERIFIED: mix.exs] | Determinism/property proofs for CORE-05 | Existing deterministic property tests already use it and pass. [VERIFIED: codebase grep] [VERIFIED: mix test] |
| Markdown GSD artifacts | repo-local [VERIFIED: codebase grep] | Persist reconstructed PLAN/SUMMARY/VERIFICATION documents | The planner consumes these exact artifact shapes. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix example app | Phoenix `~> 1.7` in example `mix.exs` [VERIFIED: examples/phoenix_example/mix.exs] | Compile- and route-surface adoption proof for adapter requirements | Use as supporting evidence for ADPT-01/02 and QUAL-03; promote to primary proof only when executed through a conn/endpoint or CI path. [VERIFIED: codebase grep] |
| `mix verify` | repo-local task [VERIFIED: mix help verify] | Demonstrates deterministic vs advisory lane separation | Use for QUAL-05 and as supporting evidence for QUAL-03 on a clean tree. [VERIFIED: mix verify] |
| `mix release.preflight` | repo-local task [VERIFIED: mix help release.preflight] | Public release-boundary proof for QUAL-04 | Use for tag-parity and dry-run checks; expect a manual tagged-release step for happy-path proof. [VERIFIED: mix release.preflight] |
| Existing Phase 05/06 verification reports | repo-local [VERIFIED: codebase grep] | Style anchors for requirement-first evidence writing | Use to keep reconstructed artifacts consistent with newer verified phases. [VERIFIED: .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md] [VERIFIED: .planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual requirement-first reconstruction from current proof surfaces [VERIFIED: codebase grep] | Automated requirement-to-file generator [ASSUMED] | Automation would over-reward file presence and under-enforce D-01/D-03 truthfulness. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Targeted Phoenix conn/endpoint proving test [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Helper-only adapter proof from direct function calls [ASSUMED] | D-04 explicitly prefers connection- or endpoint-level proof where practical. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Row-by-row requirements updates after each phase closes [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Single bulk status flip at the end [ASSUMED] | Bulk flipping increases drift risk and violates D-15/D-16. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |

**Setup / verification commands:** [VERIFIED: codebase grep]
```bash
mix deps.get
mix test
mix compile --no-optional-deps --warnings-as-errors
mix run scripts/verify_docs.exs
mix verify
cd examples/phoenix_example && mix compile
```

**Version verification:** Use `elixir --version`, `mix --version`, and the repo `mix.exs` constraints instead of `npm view`, because this phase is BEAM-only. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
ROADMAP.md + REQUIREMENTS.md + 11-CONTEXT.md + v1.0-MILESTONE-AUDIT.md
        |
        v
Phase Scope + Locked Evidence Rules
        |
        +--> Source/Test Inventory (`lib/`, `test/`, `examples/`, mix tasks)
        |          |
        |          v
        |    Executable Proof Runs
        |    (`mix test`, `mix compile --no-optional-deps`, docs check, example compile)
        |          |
        |          v
        +--> Requirement Evidence Matrix (one primary proof per requirement)
                   |
                   +--> Reconstructed Phase 01 VERIFICATION -> SUMMARY -> PLAN
                   +--> Reconstructed Phase 02 VERIFICATION -> SUMMARY -> PLAN
                   +--> Reconstructed Phase 03 VERIFICATION -> SUMMARY -> PLAN
                   +--> Reconstructed Phase 04 VERIFICATION -> SUMMARY -> PLAN
                   |
                   v
            Row-by-row `.planning/REQUIREMENTS.md` status updates
            only after each phase verification closes
```

### Recommended Project Structure

```text
.planning/
├── REQUIREMENTS.md                 # central traceability table
├── ROADMAP.md                      # original phase ownership + success criteria
├── v1.0-MILESTONE-AUDIT.md         # orphaned-requirement starting point
└── phases/
    ├── 01-core-deterministic-foundation/
    │   ├── 01-PLAN.md
    │   ├── 01-SUMMARY.md
    │   └── 01-VERIFICATION.md
    ├── 02-layout-and-pagination-engine/
    ├── 03-adapter-and-ops-integration/
    └── 04-quality-and-release-hardening/
```

### Pattern 1: Verification-First Reconstruction

**What:** Write each missing phase as a proof document first, then derive the summary and reconstructed plan from the verified evidence surface. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**When to use:** Use for all four reconstructed phases because `VERIFICATION.md` is the only artifact allowed to drive traceability updates. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Example:**
```markdown
## Requirement: CORE-05

**Status:** VERIFIED [VERIFIED: mix test]
**Primary proof:** `mix test test/rendro_test.exs test/rendro/deterministic_test.exs` [VERIFIED: codebase grep]
**Supporting evidence:** `lib/rendro.ex`, `lib/rendro/pdf/writer.ex` [VERIFIED: codebase grep]
**Notes:** Deterministic mode yields identical binaries and fixed timestamps. [VERIFIED: codebase grep]
```

### Pattern 2: Read-Only Mapping First, Proving Edit Only on Explicit Proof Gaps

**What:** Attempt to satisfy each requirement from existing tests/commands before planning any new test or doc edit. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**When to use:** Use for all 23 requirements; only escalate to a proving edit when no current public-boundary executable proof exists. [VERIFIED: codebase grep]  
**Example:**
```bash
# Existing proof
mix compile --no-optional-deps --warnings-as-errors

# Likely proving edit target
# add a Phoenix conn/endpoint test only if ADPT-01/ADPT-02 still lack boundary proof
```

### Anti-Patterns to Avoid

- **Artifact-first reconstruction:** Writing PLAN/SUMMARY from remembered phase intent before locking requirement evidence creates drift against the live fixed codebase. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]
- **Status flips from source presence:** A module, route, or workflow file is not proof under D-01/D-03. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]
- **Sneaking CI or release behavior changes into Phase 11:** Changing workflow semantics or release logic is out of scope for a read-mostly reconstruction phase. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Requirement traceability closure [VERIFIED: codebase grep] | A custom evidence-scoring script [ASSUMED] | Manual requirement-first matrices in `VERIFICATION.md` [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Truthfulness depends on human judgment around mixed `Done` / `Partial` / `Blocked` outcomes. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Optional-dependency proof [VERIFIED: codebase grep] | Grep-only “no hard dependency” claims [ASSUMED] | `mix compile --no-optional-deps --warnings-as-errors` plus guard mapping [VERIFIED: mix compile --no-optional-deps --warnings-as-errors] | The command proves compile behavior; grep only proves intention. [VERIFIED: mix help compile] |
| Phoenix adapter proof [VERIFIED: codebase grep] | Helper-only assertions on returned conn shape [ASSUMED] | Conn- or endpoint-level proof path [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | D-04 prefers boundary proof for adapter requirements. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| QUAL-03 closure [VERIFIED: codebase grep] | CI claim from workflow-file presence alone [ASSUMED] | Executed workflow evidence or truthful `Partial`/`Blocked` status [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | CI/release claims need runnable proof. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |

**Key insight:** This phase is about proving contracts, not re-explaining them. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Later Gap-Closure Work as Automatic Verification

**What goes wrong:** A later fix phase repaired behavior, so the planner assumes the original requirement is now `Done`. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** The traceability table already names later gap-closure phases, which invites shortcut reasoning. [VERIFIED: .planning/REQUIREMENTS.md]  
**How to avoid:** Re-verify each original Phase 1-4 requirement against the live codebase and update rows only from reconstructed verification verdicts. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Warning signs:** Requirements are marked complete before the matching reconstructed `VERIFICATION.md` exists. [VERIFIED: codebase grep]

### Pitfall 2: Over-claiming Phoenix Adapter Verification

**What goes wrong:** The planner treats example-app compilation or helper-level source mapping as sufficient for ADPT-01 and ADPT-02. [VERIFIED: codebase grep]  
**Why it happens:** The repo contains routes and a compiling example app, but no explicit Phoenix conn/endpoint test in `test/`. [VERIFIED: codebase grep]  
**How to avoid:** Plan a small proving test if no current boundary proof exists, and keep the phase read-only otherwise. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Warning signs:** Verification language says “download/preview works” without a command or test hitting the adapter boundary. [VERIFIED: codebase grep]

### Pitfall 3: Letting Dirty-Tree State Falsely Fail QUAL Proofs

**What goes wrong:** `mix ci` or `mix verify` fails on incidental formatting drift in the current workspace, and the requirement is marked blocked. [VERIFIED: mix verify]  
**Why it happens:** These commands validate current working-tree state, not just committed source. [VERIFIED: mix verify]  
**How to avoid:** Treat clean-tree reruns as the decisive proof for QUAL-01 and QUAL-05, and document when a local dirty tree polluted the signal. [VERIFIED: codebase grep]  
**Warning signs:** Failure output points at formatting or unrelated modified files instead of missing command behavior. [VERIFIED: mix verify]

### Pitfall 4: Updating `.planning/REQUIREMENTS.md` in Bulk

**What goes wrong:** Multiple rows are flipped together after a broad evidence sweep, and later mixed outcomes are lost. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Why it happens:** It feels efficient to reconcile the whole table after all four reconstructed phases are written. [ASSUMED]  
**How to avoid:** Update rows immediately after each phase `VERIFICATION.md` closes, preserving mixed outcomes row-by-row. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]  
**Warning signs:** The traceability table changes before the corresponding verification file exists or says `passed`. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from the current repo:

### Optional Dependency Discipline Proof
```bash
# Source: `mix help compile` + live command output
mix compile --no-optional-deps --warnings-as-errors
```

### Deterministic Public-Boundary Proof
```elixir
# Source: test/rendro_test.exs
doc = sample_doc()
{:ok, pdf1} = Rendro.render(doc, deterministic: true)
{:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
```

### Flow Pagination Proof
```elixir
# Source: test/rendro/flow_test.exs
content = for i <- 1..50, do: Rendro.block(Rendro.text("Line #{i}"))
doc = Rendro.flow(content)
{:ok, pdf} = Rendro.render(doc)
assert length(Regex.scan(~r"/Type\\s*/Page\\b", pdf)) == 2
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase completion without reconstructed GSD artifacts [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | Requirement-first reconstructed PLAN/SUMMARY/VERIFICATION artifacts [VERIFIED: .planning/ROADMAP.md] | Audit on `2026-04-26` established the orphaned-state problem. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | Phase 11 must close formal proof debt, not implementation debt. [VERIFIED: .planning/ROADMAP.md] |
| Helper- or source-level confidence for adapter/docs/CI claims [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | Executable boundary proof or explicit mixed status [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Locked in Phase 11 context on `2026-04-28`. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Prevents drift and over-claiming in reconstructed artifacts. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |

**Deprecated/outdated:**

- “File exists, therefore requirement is done” is explicitly outdated for this repo after the `2026-04-26` milestone audit. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | An automated requirement-to-file generator would increase false-positive verification risk more than it would save planning time. [ASSUMED] | Standard Stack / Don't Hand-Roll | Low; the planner can still choose a light helper script if it preserves D-01/D-03 discipline. |
| A2 | Helper-only Phoenix adapter assertions are materially weaker than conn-level proof for this repo. [ASSUMED] | Standard Stack / Don't Hand-Roll | Medium; if the user accepts helper-level proof, Phase 11 could stay more read-only. |
| A3 | Bulk traceability updates would be more drift-prone than row-by-row updates. [ASSUMED] | Alternatives / Common Pitfalls | Low; D-15 and D-16 still force completed verification before status flips. |

## Open Questions

1. **Do ADPT-01 and ADPT-02 already have acceptable public-boundary proof outside `test/`?**
   - What we know: The Phoenix adapter compiles conditionally, the example app compiles, and example routes call `render_pdf/3` and `preview_pdf/2`. [VERIFIED: cd examples/phoenix_example && mix compile] [VERIFIED: codebase grep]
   - What's unclear: There is no explicit conn- or endpoint-level test in the root test suite. [VERIFIED: codebase grep]
   - Recommendation: Default the plan to one small proving test slice for the Phoenix adapter unless the user points to existing CI or endpoint proof. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

2. **Can QUAL-03 truthfully reach `Done` in Phase 11?**
   - What we know: The example app compiles locally, but `.github/workflows/ci.yml` only runs `mix ci`. [VERIFIED: cd examples/phoenix_example && mix compile] [VERIFIED: .github/workflows/ci.yml]
   - What's unclear: Whether any current CI path executes the example app proof outside the checked-in workflow file. [ASSUMED]
   - Recommendation: Plan for `Partial` or `Blocked` unless executable CI evidence is available without changing workflow semantics. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

3. **How should QUAL-04 be closed without a release tag in the current workspace?**
   - What we know: `mix release.preflight` exists and fails immediately when no exact tag is present. [VERIFIED: mix release.preflight]
   - What's unclear: Whether a tagged clean release commit is available during Phase 11 execution. [ASSUMED]
   - Recommendation: Treat happy-path release-preflight closure as a clearly named manual/tagged check if a suitable tag is not present during reconstruction. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All executable proof commands | ✓ [VERIFIED: elixir --version] | `1.19.5` [VERIFIED: elixir --version] | — |
| Erlang / OTP | All executable proof commands | ✓ [VERIFIED: elixir --version] | `28` [VERIFIED: elixir --version] | — |
| Mix | `mix test`, compile, verify, docs, release tasks | ✓ [VERIFIED: mix --version] | `1.19.5` [VERIFIED: mix --version] | — |
| Git | `mix release.preflight` tag/parity checks | ✓ [VERIFIED: git --version] | `2.41.0` [VERIFIED: git --version] | None for exact-tag proof |
| Hex archive | `mix hex.build` / `mix hex.publish --dry-run` path | ✓ [VERIFIED: mix help hex.build] | `hex-2.4.1-otp-28` in help path [VERIFIED: mix help hex.build] | — |
| Phoenix example app deps | ADPT-01, ADPT-02, QUAL-03 supporting proof | ✓ [VERIFIED: cd examples/phoenix_example && mix compile] | project-local deps in `examples/phoenix_example` [VERIFIED: examples/phoenix_example/mix.exs] | — |

**Missing dependencies with no fallback:**

- Exact git tag for QUAL-04 happy-path proof is absent in the current workspace. [VERIFIED: mix release.preflight]

**Missing dependencies with fallback:**

- None; the repo already has the local BEAM toolchain needed for read-mostly reconstruction. [VERIFIED: elixir --version]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData properties [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test` [VERIFIED: mix test] |
| Full suite command | `mix test` plus targeted mix tasks (`mix compile --no-optional-deps --warnings-as-errors`, `mix run scripts/verify_docs.exs`, `mix verify`) [VERIFIED: mix test] [VERIFIED: mix compile --no-optional-deps --warnings-as-errors] [VERIFIED: mix run scripts/verify_docs.exs] [VERIFIED: mix verify] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-01 | public builders + render pipeline produce PDFs from Elixir data | integration | `mix test test/rendro_builders_test.exs test/rendro/integration_test.exs test/rendro/pipeline_test.exs` | ✅ [VERIFIED: codebase grep] |
| CORE-02 | render path works without browser runtime in core | integration + negative grep | `mix test test/rendro/integration_test.exs` | ✅ [VERIFIED: mix test] |
| CORE-03 | fixed-position API renders correctly | integration | `mix test test/rendro/flow_test.exs test/rendro/integration_test.exs` | ✅ [VERIFIED: codebase grep] |
| CORE-04 | flow API renders correctly | integration | `mix test test/rendro/flow_test.exs` | ✅ [VERIFIED: codebase grep] |
| CORE-05 | deterministic mode is repeatable | property + unit | `mix test test/rendro_test.exs test/rendro/deterministic_test.exs` | ✅ [VERIFIED: codebase grep] |
| LAY-01 | primitives compose into documents | unit + integration | `mix test test/rendro_builders_test.exs test/rendro/flow_test.exs test/rendro/metadata_test.exs` | ✅ [VERIFIED: codebase grep] |
| LAY-02 | flow paginates automatically | integration | `mix test test/rendro/flow_test.exs test/rendro/pipeline/paginate_test.exs` | ✅ [VERIFIED: codebase grep] |
| LAY-03 | tables split across pages with repeated headers | integration | `mix test test/rendro/flow_test.exs` | ✅ [VERIFIED: codebase grep] |
| LAY-04 | headers/footers/page numbers render predictably | integration | `mix test test/rendro/flow_test.exs` | ✅ [VERIFIED: codebase grep] |
| LAY-05 | overflow diagnostics are actionable | integration + error | `mix test test/rendro/flow_test.exs test/rendro/error_test.exs` | ✅ [VERIFIED: codebase grep] |
| ADPT-01 | Phoenix download helper serves PDF response | endpoint/conn | `mix test <new phoenix adapter proof file>` | ❌ Wave 0 likely needed [VERIFIED: codebase grep] |
| ADPT-02 | Phoenix preview helper serves inline PDF response | endpoint/conn | `mix test <new phoenix adapter proof file>` | ❌ Wave 0 likely needed [VERIFIED: codebase grep] |
| ADPT-03 | optional adapters do not hard-couple core | compile/runtime | `mix compile --no-optional-deps --warnings-as-errors` | ✅ [VERIFIED: mix compile --no-optional-deps --warnings-as-errors] |
| ADPT-04 | Oban worker injects bounded async policies | unit | `mix test test/rendro/adapters/oban/render_worker_test.exs` | ✅ [VERIFIED: codebase grep] |
| OBS-01 | full lifecycle telemetry emits | unit/integration | `mix test test/rendro/telemetry_test.exs` | ✅ [VERIFIED: codebase grep] |
| OBS-02 | telemetry correlates metrics | unit/integration | `mix test test/rendro/telemetry_test.exs test/rendro/pipeline_test.exs test/rendro/adapters/threadline_test.exs` | ✅ [VERIFIED: codebase grep] |
| OBS-03 | structured errors explain what/where/why/next | unit/integration | `mix test test/rendro/error_test.exs test/rendro/pipeline_test.exs` | ✅ [VERIFIED: codebase grep] |
| OBS-04 | max pages/bytes/timeouts are enforced | unit/integration | `mix test test/rendro/policy_test.exs test/rendro/adapters/oban/render_worker_test.exs test/rendro/pipeline_test.exs` | ✅ [VERIFIED: codebase grep] |
| QUAL-01 | canonical merge-blocking lane exists | mix task | `mix ci` on a clean tree [VERIFIED: codebase grep] | ✅ command exists [VERIFIED: codebase grep] |
| QUAL-02 | docs-contract checks execute | mix task | `mix run scripts/verify_docs.exs` | ✅ [VERIFIED: mix run scripts/verify_docs.exs] |
| QUAL-03 | Phoenix example app is CI-backed adoption proof | workflow + command | `cd examples/phoenix_example && mix compile` plus CI evidence [VERIFIED: cd examples/phoenix_example && mix compile] | ⚠️ local proof yes; CI proof unclear [VERIFIED: .github/workflows/ci.yml] |
| QUAL-04 | release preflight enforces tag parity and dry-run path | mix task + manual tagged run | `mix release.preflight` | ✅ command exists [VERIFIED: mix release.preflight] |
| QUAL-05 | deterministic vs advisory lanes are separated in verification output | mix task | `mix verify` | ✅ [VERIFIED: mix verify] |

### Sampling Rate

- **Per task commit:** `mix test` plus the smallest requirement-specific command set for the slice under reconstruction. [VERIFIED: mix test]
- **Per wave merge:** rerun the affected proof commands and the relevant phase verification artifact checks. [ASSUMED]
- **Phase gate:** all reconstructed `VERIFICATION.md` files complete, and `.planning/REQUIREMENTS.md` rows updated only from those final verdicts. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]

### Wave 0 Gaps

- [ ] Phoenix adapter conn/endpoint proof file for ADPT-01 and ADPT-02 if no existing executable boundary proof is accepted. [VERIFIED: codebase grep]
- [ ] Clean-tree `mix ci` rerun for QUAL-01 because the current workspace has formatting drift unrelated to Phase 11 reconstruction. [VERIFIED: mix verify]
- [ ] Decision on whether QUAL-03 can be closed without new CI execution evidence. [VERIFIED: .github/workflows/ci.yml]
- [ ] Tagged-release manual proof path for QUAL-04 if no exact git tag exists during execution. [VERIFIED: mix release.preflight]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | none; this phase does not add auth surfaces [VERIFIED: codebase grep] |
| V3 Session Management | no [VERIFIED: codebase grep] | none; this phase is planning/docs/test mapping only [VERIFIED: codebase grep] |
| V4 Access Control | no [VERIFIED: codebase grep] | none; no new access-control code is in scope [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Use requirement-boundary executable proof instead of narrative claims so bad inputs stay observable and truthful. [VERIFIED: codebase grep] |
| V6 Cryptography | no [VERIFIED: codebase grep] | none in this phase; release proof and document truthfulness only [VERIFIED: codebase grep] |

### Known Threat Patterns for this Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False verification from file presence [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] | Tampering | Require one primary executable proof per requirement. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Traceability drift between per-phase docs and central table [VERIFIED: .planning/REQUIREMENTS.md] | Repudiation | Update `.planning/REQUIREMENTS.md` only from completed reconstructed `VERIFICATION.md` verdicts. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md] |
| Dirty-worktree command failures misreported as product gaps [VERIFIED: mix verify] | Denial of Service | Distinguish command-surface issues caused by local modifications from missing capability proof in the committed code. [VERIFIED: mix verify] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints and architecture boundary. [VERIFIED: AGENTS.md]
- `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md` - locked decisions, proof rules, and scope boundaries. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - requirement definitions and current traceability rows. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - original phase ownership and success criteria. [VERIFIED: codebase grep]
- `.planning/v1.0-MILESTONE-AUDIT.md` - orphaned-requirement baseline. [VERIFIED: codebase grep]
- `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` - verification style exemplar. [VERIFIED: codebase grep]
- `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md` - verification style exemplar and Phase 6 evidence cross-reference. [VERIFIED: codebase grep]
- `mix test` - live test-suite proof (`3 properties, 224 tests, 0 failures`). [VERIFIED: mix test]
- `mix compile --no-optional-deps --warnings-as-errors` - optional-dependency proof. [VERIFIED: mix compile --no-optional-deps --warnings-as-errors]
- `mix run scripts/verify_docs.exs` - docs-contract proof surface. [VERIFIED: mix run scripts/verify_docs.exs]
- `mix verify` - public verification-lane surface and current dirty-tree failure signal. [VERIFIED: mix verify]
- `mix release.preflight` - release-preflight boundary and current tag-parity failure signal. [VERIFIED: mix release.preflight]
- `cd examples/phoenix_example && mix compile` - local example-app adoption proof surface. [VERIFIED: cd examples/phoenix_example && mix compile]

### Secondary (MEDIUM confidence)

- `.planning/phases/07-phoenix-adapter-hardening/07-01-SUMMARY.md` - prior phase claims about Phoenix adapter hardening and example app completion. [VERIFIED: codebase grep]
- `.planning/phases/09-ci-and-release-hardening/09-01-SUMMARY.md` - prior phase claims about CI/docs-contract improvements. [VERIFIED: codebase grep]
- `.planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md` - prior phase claims about verify/preflight hardening. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None; low-confidence items are listed explicitly in the Assumptions Log. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase uses repo-local Mix, ExUnit, StreamData, and planning artifacts already verified in this workspace. [VERIFIED: codebase grep] [VERIFIED: mix test]
- Architecture: HIGH - the reconstruction flow is locked tightly by Phase 11 context decisions and existing repo structure. [VERIFIED: .planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md]
- Pitfalls: MEDIUM - the main remaining uncertainty is whether Phoenix adapter and CI-backed example proof are already satisfiable without targeted proving edits or manual checks. [VERIFIED: codebase grep] [VERIFIED: .github/workflows/ci.yml]

**Research date:** 2026-04-28 [VERIFIED: codebase grep]  
**Valid until:** 2026-05-05 because Phase 11 depends on live repo state and currently-running milestone changes. [ASSUMED]

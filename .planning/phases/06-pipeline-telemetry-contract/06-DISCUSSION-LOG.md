# Phase 6: Pipeline Telemetry Contract Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 06-pipeline-telemetry-contract
**Areas discussed:** validate stage shape, compose-vs-measure ordering, error-path telemetry metadata, SemVer + breaking-change communication
**Discussion style:** Research-first, one-shot. User opted out of interactive option-picking and asked for synthesized research-backed recommendations across all four areas. Four parallel research subagents produced evidence; this log records the alternatives they considered and the locked synthesis.

---

## Area 1 — `:validate` stage shape

| Option | Description | Selected |
|--------|-------------|----------|
| A. Pure passthrough | `:validate` emits `start/stop` with no body work; satisfies OBS-01 contract literally; existing `validate_policy` calls stay where they are | |
| B. Consolidate both policy checks into trailing `:validate` | Both `max_pages` AND `max_bytes` move to a final `:validate` stage; uniform shape; `max_pages_exceeded` would fire post-render | |
| C. Real structural-integrity stage (scoped) | `:validate` does PDF header/EOF check + page-count parity + absorbs `max_bytes`; keeps `max_pages` as fail-fast guard before render | ✓ |
| C+ (researcher's expansion). Add deterministic invariants | C plus `/CreationDate`/`/ModDate`/`/ID` checks when `deterministic: true` | |
| D. Hybrid | Keep `max_pages` mid-pipeline, move only `max_bytes` into trailing `:validate` | |

**Locked decision:** C (scoped tight to audit).
**Why not C+:** Deterministic-mode invariant enforcement is new scope beyond the audit's success criteria. High-leverage idea but belongs in its own focused phase with a dedicated test corpus. Promoted to `<deferred>` for a follow-up "deterministic mode hardening" phase.
**Why not A (passthrough):** Hollow span pollutes dashboards and lies about coverage; violates `:telemetry.span/3` convention (Oban only spans real work; Keathley conventions warn against guard-only spans).
**Why not B (max_pages in tail):** Would force compose+measure+paginate+render work on a document the policy exists to refuse — CPU/DoS regression dressed as uniformity.

## Area 2 — Compose-vs-measure ordering

| Option | Description | Selected |
|--------|-------------|----------|
| A. Relabel only | Keep code semantics unchanged, just rename stages so telemetry events fire in spec order | |
| B. Real semantic split | `Compose` = logical/tree assembly (no pixels), `Measure` = metrics, `Paginate` absorbs y-stacking | ✓ |
| C. Two-pass approach | `Compose` runs logical pass, `Measure` measures, second internal "finalize compose" inside `Paginate` | |
| D. Rename + concede | Update REQUIREMENTS.md to match current implementation order | |

**Locked decision:** B (real semantic split with y-stacking moved to Paginate).
**Why not A (relabel only):** Violates OBS-01 by lying in telemetry — operators reading event order would see compose firing after measurement. Doesn't fix the latent flow bug (page-2 remainder rows inheriting page-1 y values).
**Why not C (two-pass):** Invites "which pass owns this field" ambiguity that haunts CSS engines (Chromium relayout-on-style-change). Avoid pre-1.0.
**Why not D (concede):** Burns the OBS-01 spec; PROJECT.md explicitly locks `build → compose → measure → paginate → render → validate` as the canonical architecture.
**Evidence pattern:** CSS/WeasyPrint, TeX, Typst, ReportLab Flowables, react-pdf/Yoga all agree: assemble tree → measure → place.

## Area 3 — Error-path telemetry metadata

| Option | Description | Selected |
|--------|-------------|----------|
| A. Always read from doc passed in | `page_count: length(doc.pages)`; `byte_size: 0` until render succeeds | partial ✓ |
| B. Last-known-good carried across stages | Pipeline tracks last successful doc state | |
| C. Best-available from result first, fallback to doc | Prefer stage result if it produced anything | partial ✓ |
| D. Status-aware schema with `:error` key | Stop event for error path adds `error: %{kind, stage}` so consumers can branch | partial ✓ |

**Locked decision:** A + C + D combined — single stable schema for `:start` and `:stop` (success and error), `page_count` derived from `result.pages` if available else `doc.pages`, `byte_size` real only when `stage == :render` and `result` is binary, optional `:error` key on failure.
**Why not B (last-known-good tracking):** Adds plumbing for marginal benefit; the doc passed into each span already carries the latest state.
**Schema stability evidence:** Finch, Broadway, and Telemetry Conventions (Keathley) all agree on a single stable stop schema with optional `:error` key for tagged-tuple failures; Oban distinguishes `:stop` from `:exception` (only true raises hit `:exception`).

## Area 4 — SemVer + breaking-change communication

| Option | Description | Selected |
|--------|-------------|----------|
| A. Pre-1.0 free hand | Single-shot release, CHANGELOG entry, no shim, no UPGRADING.md | ✓ |
| B. Bridge period | Emit both old and new events for one minor version with deprecation warning | |
| C. Telemetry contract version field | Add `telemetry_contract_version: 1` to event metadata | |
| D. Single-shot with explicit migration doc + UPGRADING.md | Heavier ceremony than A | |

**Locked decision:** A.
**Why not B/C (bridge or version field):** Encodes the buggy ordering as a "v1 contract" Rendro then carries forward — exactly what BLOCKER-05 says we should not do.
**Why not D (UPGRADING.md):** Pre-publish lib, no external consumers, the CHANGELOG "Changed (BREAKING)" section already contains the full migration. Oban only added UPGRADING-style guides at v2.0 after years of 1.x.
**Direct precedent:** Oban v2.0 renamed every telemetry event with one conversion table, no dual-emission bridge. Phoenix endpoint telemetry standardization (PR #3698) shipped as breaking change with CHANGELOG callouts only.
**Threadline impact:** None — `Rendro.Adapters.Threadline` only subscribes to top-level `[:rendro, :render, :*]`, not stage events.

---

## Claude's Discretion

User explicitly delegated:
- Module naming for new pipeline helpers (`Rendro.Pipeline.Validate` etc.).
- Internal organization of `Compose` after y-stacking removal.
- Test file layout for `:validate` stage tests.
- Exact wording of `Rendro.Error` `what`/`next` strings for new error reasons.

User also delegated the meta-decision (per saved feedback memory): research-backed recommendations should be locked without per-decision user approval unless a decision is **VERY impactful** (irreversible public-API break post-1.0, product positioning shift, license/values call). None of Phase 6's decisions met that bar — pre-1.0 internal pipeline bug-fix per audit.

## Deferred Ideas

- **Deterministic-mode runtime invariant enforcement** in `:validate` (no `/CreationDate`/`/ModDate`/non-deterministic `/ID` when `deterministic: true`). High-leverage but new scope; promote to roadmap backlog as candidate post-Phase 11 phase.
- **PDF/A and PDF/UA conformance checks** in `:validate` — already tracked as v2 requirements (COMP-01, COMP-02).
- **`telemetry_contract_version` metadata field** — overengineered pre-1.0; reconsider if a downstream consumer requests explicit contract pinning.
- **Dedicated post-render policy stage separate from `:validate`** for finer-grained telemetry on `max_bytes` — defer until usage data shows it matters.

## Research provenance

Four parallel research subagents (general-purpose) produced evidence-based recommendations on 2026-04-26:

1. **Validate stage shape** — surveyed Oban/Ecto/Phoenix telemetry patterns, Typst/WeasyPrint/ReportLab post-render validation analogues, reproducible-builds determinism literature.
2. **Compose-vs-measure ordering** — surveyed CSS/WeasyPrint formatting structure, TeX boxes/page-builder split, Typst content/style/layout phases, ReportLab Flowables (`wrap → split → drawOn`), react-pdf/Yoga.
3. **Error-path telemetry metadata** — surveyed Finch/Broadway/Oban error-event conventions and `:telemetry.span/3` documented patterns.
4. **SemVer / breaking-change norms** — surveyed Oban v2.0 telemetry rename, Phoenix endpoint telemetry PR #3698, Finch deprecations, Elixir Library Guidelines, SemVer 2.0 §4.

Synthesis happened in the main thread (this discussion). Cross-area conflicts were resolved in favor of: Research 2's pipeline ordering (compose first), Research 1's validate body scope (minus deterministic invariants which were promoted to deferred), Research 3's stable schema, Research 4's lock-and-ship recommendation.

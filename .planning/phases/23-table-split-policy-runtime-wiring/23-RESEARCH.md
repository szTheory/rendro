# Phase 23: Table Split Policy Runtime Wiring - Research

**Researched:** 2026-04-30 [VERIFIED: 2026-04-30 system date]
**Domain:** runtime consumption of authored table split policy plus truthful requirement re-verification for `LAY-10` [VERIFIED: .planning/ROADMAP.md, .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md, .planning/v1.1-MILESTONE-AUDIT.md]
**Confidence:** HIGH [VERIFIED: recommendations are grounded in the current codebase, current phase context, and existing phase artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `Rendro.Table.split_policy` should describe internal table continuation semantics only, not whole-block keep behavior.
- **D-02:** The truthful Phase 23 table policy is row-atomic continuation: tables may continue across pages, but rows never fragment.
- **D-03:** The public name should move toward an explicit `:row_atomic` meaning. `:atomic` may remain as a temporary deprecated compatibility alias for one cycle if needed, but Phase 23 should not leave the contract ambiguous.
- **D-04:** Phase 23 should not add speculative enum branches that are not fully implemented. Do not widen `split_policy` into a menu of future ideas.
- **D-05:** Runtime pagination should branch on the authored split policy in `Paginate`, but the actual supported behavior in this phase remains: fit full rows on the current page when possible, otherwise continue on a fresh page with repeated headers.
- **D-06:** If a single row plus repeated header cannot fit on an empty page/body region, Rendro should fail through the existing typed paginate overflow contract rather than fragmenting cells, shrinking content, clipping, or silently relaxing constraints.
- **D-07:** Phase 23 should not add advisory policies such as "avoid split if possible."
- **D-08:** Whole-table cohesion belongs to block-level keep semantics, not table split semantics.
- **D-09:** Phase 23 should not introduce a table-local `:whole_table` or similar mode that duplicates `keep_together` semantics.
- **D-10:** Requirement closure should follow a hybrid traceability model: backfill `20-VERIFICATION.md` as explicit re-verification/history repair, but keep authoritative final closure of `LAY-10` anchored to Phase 23 because Phase 23 fixes a real runtime product gap.
- **D-11:** Roadmap/requirements status must not mark `LAY-10` complete until Phase 23 verification exists.
- **D-12:** For this project, GSD should prefer recommendation-first research synthesis for routine gray areas instead of broad option menus.
- **D-13:** When discuss-phase supports it, research should happen before questions so the user is asked to confirm/correct a cohesive recommendation set instead of performing codebase archaeology interactively.

### the agent's Discretion
- Exact deprecation mechanics and wording for `:atomic` as a compatibility alias, as long as the public contract becomes more explicit and docs stay truthful.
- Exact overflow detail payload additions, as long as impossible row fits remain typed and actionable.
- Exact wording/frontmatter strategy for linking `20-VERIFICATION.md` and Phase 23 verification artifacts, as long as the historical record stays truthful and machine-discoverable.

### Deferred Ideas (OUT OF SCOPE)
- True cell fragmentation / split-row layout.
- Advisory "avoid split if possible" behavior.
- Table-local whole-table keep mode that duplicates block-level `keep_together`.
- Automatic continuation labels or other continuation chrome inside the core table primitive.
- Broader multi-mode table policy surface before there is a proven need beyond row-atomic continuation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-10 | Engineer can render multi-page tables with deterministic column sizing, repeated headers, and explicit row-split behavior suited to invoices and reports. | Phase 20 already shipped deterministic columns, repeated headers, and row-atomic splitting mechanics, but `split_policy` is still a dead public field because pagination never branches on it. Phase 23 should therefore be a runtime-wiring and proof-closure phase, not a second table-layout redesign. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/paginate.ex, test/rendro/pipeline/paginate_test.exs, .planning/v1.1-MILESTONE-AUDIT.md] |
</phase_requirements>

## Summary

The core Phase 20 geometry work already landed: `%Rendro.Table{}` carries `columns`, `column_widths`, `row_heights`, and `header_height`; `Measure` resolves real widths and heights; `Paginate` repeats headers and keeps rows atomic; and flow tests already prove multi-page tables. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, test/rendro/pipeline/paginate_test.exs, test/rendro/flow_test.exs]

The remaining gap is narrower and more specific: `split_policy` still defaults to `:atomic`, the builder test only proves `:atomic`, and the paginator never consumes the authored field when deciding how to handle table continuation. That leaves a public contract surface that callers can set without any runtime effect, which is exactly the audit finding `INT-TABLE-SPLIT-POLICY`. [VERIFIED: lib/rendro/table.ex, test/rendro_builders_test.exs, .planning/v1.1-MILESTONE-AUDIT.md]

The right Phase 23 move is therefore not to invent new table modes. It is to make the existing runtime branch on the authored policy, tighten the public contract around the explicit `:row_atomic` meaning, preserve a temporary `:atomic` alias only if needed for compatibility, and prove the branch with tests that would fail if the field went dead again. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md, lib/rendro/pipeline/paginate.ex] [ASSUMED]

The second half of the phase is historical and traceability repair. Because Phase 20 shipped materially incomplete, the repo needs a backfilled `20-VERIFICATION.md` that explains what was originally present versus what Phase 23 later closed, and a `23-VERIFICATION.md` that becomes the authoritative proof for `LAY-10`. Requirements and roadmap status should only flip after those artifacts exist. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md, .planning/v1.1-MILESTONE-AUDIT.md, .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md]

**Primary recommendation:** implement Phase 23 as exactly two plans. Plan 23-01 should normalize the split-policy contract and wire it into runtime pagination with targeted regression proof. Plan 23-02 should create the truthful re-verification artifacts and update roadmap/requirements traceability only after the runtime fix is proven. [VERIFIED: .planning/ROADMAP.md, .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md] [ASSUMED]

## Recommended Decomposition

Phase 23 should decompose into exactly two plans because the roadmap allocates one cohesive gap-closure phase, and the work naturally splits between product behavior and artifact closure. [VERIFIED: .planning/ROADMAP.md]

1. **Plan 23-01: Runtime split-policy wiring and public contract tightening.** Consume `split_policy` in `Paginate`, move the public meaning toward `:row_atomic`, keep `:atomic` only as an explicit compatibility alias if needed, and add regression tests proving authored policy is no longer dead. [VERIFIED: lib/rendro/table.ex, lib/rendro/pipeline/paginate.ex, test/rendro_builders_test.exs, test/rendro/pipeline/paginate_test.exs] [ASSUMED]
2. **Plan 23-02: Re-verification and traceability closure for `LAY-10`.** Backfill `20-VERIFICATION.md` as historical repair, create `23-VERIFICATION.md` as authoritative closure, and then update `REQUIREMENTS.md` and `ROADMAP.md` so they stop implying completion before proof exists. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md, .planning/v1.1-MILESTONE-AUDIT.md, .planning/REQUIREMENTS.md, .planning/ROADMAP.md] [ASSUMED]

## Project Constraints (from AGENTS.md)

- Rendro core must remain pure Elixir and keep integrations optional. [VERIFIED: AGENTS.md]
- Deterministic pagination semantics matter more than broad feature menus. [VERIFIED: AGENTS.md, .planning/PROJECT.md]
- Documentation and planning artifacts are treated as product contracts. [VERIFIED: AGENTS.md, .planning/PROJECT.md]
- The core engine path remains `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: AGENTS.md, .planning/PROJECT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Split-policy public contract | API / Backend | Docs | `%Rendro.Table{}` and `Rendro.table/2` are the only truthful place to define the supported authored semantics. [VERIFIED: lib/rendro/table.ex, test/rendro_builders_test.exs] |
| Runtime policy consumption | API / Backend | — | `Paginate` already owns table continuation and overflow; Phase 23 should extend that seam instead of introducing a second policy engine. [VERIFIED: lib/rendro/pipeline/paginate.ex] |
| Whole-table cohesion | Existing block semantics | — | `keep_together` already exists on `%Rendro.Block{}` and should remain the place for whole-element cohesion. [VERIFIED: lib/rendro/block.ex, lib/rendro/pipeline/paginate.ex, .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md] |
| Requirement closure | Planning artifacts | Tests | `20-VERIFICATION.md`, `23-VERIFICATION.md`, `REQUIREMENTS.md`, and `ROADMAP.md` are the machine-discoverable truth surfaces for milestone status. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md, .planning/REQUIREMENTS.md, .planning/ROADMAP.md] |

## Existing Code / Runtime State Inventory

| Surface | Items Found | Why It Matters |
|---------|-------------|----------------|
| Public table contract | `%Rendro.Table{split_policy: :atomic}` and `@type split_policy: :atomic` only. [VERIFIED: lib/rendro/table.ex] | The current name is ambiguous and the type does not yet express the intended explicit `:row_atomic` direction. |
| Builder coverage | `Rendro.table/2` test only asserts `split_policy: :atomic`. [VERIFIED: test/rendro_builders_test.exs] | Compatibility and public-contract changes need direct regression proof. |
| Pagination seam | `paginate_block/5` branches to `handle_table_split/10`, but never consults `table.split_policy`. [VERIFIED: lib/rendro/pipeline/paginate.ex] | This is the live runtime gap called out by the milestone audit. |
| Existing table behavior | `split_table/2` already does row-atomic continuation with repeated headers and impossible-row overflow. [VERIFIED: lib/rendro/pipeline/paginate.ex, test/rendro/pipeline/paginate_test.exs] | The runtime algorithm is already the desired supported behavior; the gap is contract wiring, not missing layout capability. |
| Phase 20 closure artifacts | `20-VALIDATION.md` exists, `20-VERIFICATION.md` does not. [VERIFIED: .planning/phases/20-table-layout-maturity/20-VALIDATION.md, .planning/v1.1-MILESTONE-AUDIT.md] | Traceability is incomplete even though much of the product work exists. |
| Historical re-verification precedent | Phase 09 uses frontmatter and explicit "later proof closed the original gaps" language. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md] | Phase 23 should follow this shape for the Phase 20 backfill. |

## Recommended Patterns

### Pattern 1: Normalize public contract at the boundary, not in the middle of pagination
Use `%Rendro.Table{}` and `Rendro.table/2` to declare the supported authored values, then let `Paginate` consume the normalized value. Do not bury alias handling in multiple downstream helpers. [VERIFIED: lib/rendro/table.ex, lib/rendro.ex] [ASSUMED]

### Pattern 2: Branch on authored policy even when only one behavior is currently implemented
The runtime does not need multiple fully implemented behaviors to justify branching. It needs one explicit supported path plus typed failure or boundary rejection for unsupported values so the public field stops being dead. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md, lib/rendro/pipeline/paginate.ex] [ASSUMED]

### Pattern 3: Re-verification artifacts must distinguish historical execution from later closure
Phase 09 proves the repo already accepts "the original phase was incomplete, later proof closed it" as a first-class verification pattern. Phase 20 should use the same language, then Phase 23 should own final authoritative closure. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md] [ASSUMED]

## Anti-Patterns to Avoid

- Adding `:whole_table`, `:avoid_split_if_possible`, or any other speculative policy branch in Phase 23. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md]
- Keeping `split_policy` typed as one value but documented with another. The struct/type/docs/tests must move together. [VERIFIED: lib/rendro/table.ex, test/rendro_builders_test.exs]
- Closing `LAY-10` in `REQUIREMENTS.md` before `23-VERIFICATION.md` exists. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md, .planning/REQUIREMENTS.md]
- Treating Phase 23 as permission to redesign the table engine. Phase 20 already delivered the geometry core; this phase is about contract wiring and truthful closure. [VERIFIED: lib/rendro/pipeline/measure.ex, lib/rendro/pipeline/paginate.ex, .planning/v1.1-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Alias support without proof
If `:atomic` remains temporarily accepted, tests must prove both the normalized canonical value and the runtime behavior. Otherwise the alias will silently regress. [ASSUMED]

### Pitfall 2: Unsupported policy values falling through to row-atomic behavior
If an unsupported value is accepted and silently treated as row-atomic, the product contract is still ambiguous. Reject at the boundary or fail with a typed, actionable error. [ASSUMED]

### Pitfall 3: Marking Phase 20 complete without explaining why it was previously open
The backfilled verification artifact needs explicit re-verification framing so future audits can distinguish original execution from later closure. [VERIFIED: .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md] [ASSUMED]

## Validation Architecture

### Test Framework
- ExUnit remains sufficient for this phase. The needed proof surface is focused: builder validation, paginate branch behavior, overflow metadata, end-to-end flow rendering, and planning-artifact presence/content checks where appropriate. [VERIFIED: test/ tree]

### Phase Requirements -> Test Map

| Requirement | Proof Surface |
|-------------|---------------|
| LAY-10 runtime contract | `test/rendro_builders_test.exs`, `test/rendro/pipeline/paginate_test.exs`, `test/rendro/flow_test.exs` |
| LAY-10 traceability closure | `.planning/phases/20-table-layout-maturity/20-VERIFICATION.md`, `.planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` |

### Sampling Rate
- After Task 23-01-01: run the focused builder and paginate tests.
- After Task 23-01-02: run `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs`.
- After Plan 23-01: run the Phase 23 quick suite plus any docs or traceability assertions added by Plan 23-02.
- Before final verification: read both verification artifacts and confirm `REQUIREMENTS.md` / `ROADMAP.md` reflect the new authoritative state.

### Wave 0 Gaps
- No new infrastructure is needed.
- The main proof gap is historical: there is no `20-VERIFICATION.md`.
- The other proof gap is semantic: no test currently proves `split_policy` is consumed at runtime.

## Sources

### Primary (HIGH confidence)
- `AGENTS.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/v1.1-MILESTONE-AUDIT.md`
- `.planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md`
- `.planning/phases/20-table-layout-maturity/20-VALIDATION.md`
- `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md`
- `lib/rendro/table.ex`
- `lib/rendro/pipeline/paginate.ex`
- `lib/rendro/block.ex`
- `test/rendro_builders_test.exs`
- `test/rendro/pipeline/paginate_test.exs`
- `test/rendro/flow_test.exs`

### Secondary (MEDIUM confidence)
- `.planning/phases/20-table-layout-maturity/20-RESEARCH.md`
- `.planning/phases/20-table-layout-maturity/20-CONTEXT.md`

## Metadata

- Research mode: recommendation-first
- New dependencies required: none
- Optional adapter impact: none beyond continued consumption of the core table contract
- Historical artifact backfill required: yes (`20-VERIFICATION.md`)

## RESEARCH COMPLETE

# Phase 23: Table Split Policy Runtime Wiring - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining table-layout contract gap by making authored table split policy affect runtime pagination, then close the missing `LAY-10` verification/traceability chain truthfully. This phase finishes the authored split-policy flow for serious multi-page business tables; it does not broaden into cell fragmentation, advisory pagination heuristics, continuation chrome, or a richer table styling DSL.

</domain>

<decisions>
## Implementation Decisions

### Split Policy Contract
- **D-01:** `Rendro.Table.split_policy` should describe internal table continuation semantics only, not whole-block keep behavior.
- **D-02:** The truthful Phase 23 table policy is row-atomic continuation: tables may continue across pages, but rows never fragment.
- **D-03:** The public name should move toward an explicit `:row_atomic` meaning. `:atomic` may remain as a temporary deprecated compatibility alias for one cycle if needed, but Phase 23 should not leave the contract ambiguous.
- **D-04:** Phase 23 should not add speculative enum branches that are not fully implemented. Do not widen `split_policy` into a menu of future ideas.

### Runtime Pagination Behavior
- **D-05:** Runtime pagination should branch on the authored split policy in `Paginate`, but the actual supported behavior in this phase remains: fit full rows on the current page when possible, otherwise continue on a fresh page with repeated headers.
- **D-06:** If a single row plus repeated header cannot fit on an empty page/body region, Rendro should fail through the existing typed paginate overflow contract rather than fragmenting cells, shrinking content, clipping, or silently relaxing constraints.
- **D-07:** Phase 23 should not add advisory policies such as “avoid split if possible.” Advisory break behavior weakens Rendro’s deterministic hard-constraint posture and creates surprise.

### Whole-Table Cohesion
- **D-08:** Whole-table cohesion belongs to block-level keep semantics, not table split semantics. If a caller wants “move this entire table to the next page if possible,” that should be expressed through the containing `%Rendro.Block{keep_together: true}` contract rather than a table-local split mode.
- **D-09:** Phase 23 should not introduce a table-local `:whole_table` or similar mode that duplicates `keep_together` semantics.

### Verification and Traceability
- **D-10:** Requirement closure should follow a hybrid traceability model: backfill `20-VERIFICATION.md` as explicit re-verification/history repair, but keep authoritative final closure of `LAY-10` anchored to Phase 23 because Phase 23 fixes a real runtime product gap.
- **D-11:** Roadmap/requirements status must not mark `LAY-10` complete until Phase 23 verification exists. The backfilled Phase 20 artifact should clarify that Phase 20 execution was materially incomplete at milestone-close time.

### Workflow Posture
- **D-12:** For this project, GSD should prefer recommendation-first research synthesis for routine gray areas instead of broad option menus. Escalate only when choices materially change product semantics, scope, or other high-impact policy the user is likely to care about directly.
- **D-13:** When discuss-phase supports it, research should happen before questions so the user is asked to confirm/correct a cohesive recommendation set instead of performing codebase archaeology interactively.

### the agent's Discretion
- Exact deprecation mechanics and wording for `:atomic` as a compatibility alias, as long as the public contract becomes more explicit and docs stay truthful.
- Exact overflow detail payload additions, as long as impossible row fits remain typed and actionable.
- Exact wording/frontmatter strategy for linking `20-VERIFICATION.md` and Phase 23 verification artifacts, as long as the historical record stays truthful and machine-discoverable.

</decisions>

<specifics>
## Specific Ideas

- Invoice, statement, and ledger tables should keep row integrity while continuing normally across pages; they should not start failing just because the document grows from one page to two.
- Short summary/KPI tables that must stay visually together should rely on block-level `keep_together`, not a second overlapping table policy surface.
- Recommended public direction:
  - `split_policy: :row_atomic`
  - temporary support for `split_policy: :atomic` as a deprecated alias
  - no `:whole_table`
  - no `:avoid_split_if_possible`
- Recommendation-first user preference:
  - synthesize one cohesive recommendation set by default
  - surface tradeoffs briefly
  - ask only on genuinely high-impact semantic decisions

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirement State
- `.planning/ROADMAP.md` — Phase 23 goal, gap-closure scope, and success criteria.
- `.planning/REQUIREMENTS.md` — `LAY-10` remains pending and is currently mapped to Phase 23.
- `.planning/PROJECT.md` — milestone constraints, deterministic posture, and truthful-docs contract.
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation, deterministic formatting, and least-surprise DX lenses.

### Gap Discovery and Historical Context
- `.planning/v1.1-MILESTONE-AUDIT.md` — identifies the `INT-TABLE-SPLIT-POLICY` runtime gap and missing verification-chain closure.
- `.planning/phases/20-table-layout-maturity/20-CONTEXT.md` — locked table-layout decisions from the original phase.
- `.planning/phases/20-table-layout-maturity/20-RESEARCH.md` — research framing for explicit column rules, row integrity, and truthful boundaries.
- `.planning/phases/20-table-layout-maturity/20-VALIDATION.md` — intended proof surface for `LAY-10`, currently still pending closure.
- `.planning/phases/14-milestone-verification-artifact-backfill/14-RESEARCH.md` — precedent for verification-artifact backfill work.
- `.planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` — example of a verification artifact shape used by this repo.

### Existing Runtime and Public Contract
- `lib/rendro/table.ex` — current public `%Rendro.Table{}` contract, including `split_policy`.
- `lib/rendro/pipeline/paginate.ex` — existing table continuation seam, repeated-header behavior, block keep semantics, and typed overflow path.
- `lib/rendro/block.ex` — block-level keep/break surface that should remain the place for whole-block cohesion.
- `README.md` — current truthful public table guidance that must stay aligned with the real runtime contract.
- `test/rendro/pipeline/paginate_test.exs` — current pagination proof surface.
- `test/rendro/flow_test.exs` — end-to-end flow/table render coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/pipeline/paginate.ex`: already owns table continuation, repeated headers, typed overflow, and block-level `keep_together`/`keep_with_next` semantics; Phase 23 should extend this seam instead of inventing a second pagination path.
- `lib/rendro/table.ex`: already carries `split_policy`, `column_widths`, `row_heights`, and `header_height`, so the public contract and measured geometry are already in place for runtime wiring.
- `test/rendro/pipeline/paginate_test.exs` and `test/rendro/flow_test.exs`: existing proof surfaces for deterministic continuation, repeated headers, and row-specific overflow behavior.

### Established Patterns
- Rendro prefers small truthful contracts over broad speculative enums or advisory heuristics.
- Hard layout constraints fail through typed errors instead of silently degrading behavior.
- Orthogonal concerns stay separate: public API validation at boundaries, geometry in Measure, page assignment in Paginate, output in Writer.
- Block-level keep semantics already exist and should remain the home for whole-block cohesion.

### Integration Points
- `Rendro.table/2` and `%Rendro.Table{}` need the public split-policy contract tightened and documented truthfully.
- `Rendro.Pipeline.Paginate` must consume the authored split policy at runtime and align diagnostics/error details with the chosen contract.
- Phase 20 and Phase 23 verification/traceability artifacts must be linked so audits can answer both “what was originally shipped?” and “what actually closed the requirement?”

</code_context>

<deferred>
## Deferred Ideas

- True cell fragmentation / split-row layout.
- Advisory “avoid split if possible” behavior.
- Table-local whole-table keep mode that duplicates block-level `keep_together`.
- Automatic continuation labels or other continuation chrome inside the core table primitive.
- Broader multi-mode table policy surface before there is a proven need beyond row-atomic continuation.

</deferred>

---

*Phase: 23-table-split-policy-runtime-wiring*
*Context gathered: 2026-04-30*

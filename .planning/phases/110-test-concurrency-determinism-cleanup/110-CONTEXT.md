# Phase 110: Test Concurrency, Determinism & Cleanup - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Optimize the test suite to maximize concurrency (`async: true`), establish a structural mechanism to quarantine and prove flake absence (nightly lane), and enforce docs-contract reading without filesystem overlap races. This delivers the TEST-01..05 requirements defined in the C1-AUDIT.md baseline.

</domain>

<decisions>
## Implementation Decisions

### Test Partitioning Strategy (TEST-02)
- **D-01:** **Rely entirely on maximizing `async: true` modules.** Do NOT adopt `mix test --partitions N`. For a pure-Elixir library without heavy Ecto sandboxing, partitioning across multiple CI runners adds overhead (booting BEAM/downloading deps) without sufficient wall-clock benefit.

### Flake Quarantine vs Fixing (TEST-03)
- **D-02:** **Establish the `mix verify.flake` nightly quarantine lane first**, adhering strictly to the `threadline` OSS DNA pattern.
- **D-03:** Once the nightly lane is in place, move the known `RecipesFacadeDriftTest` seed failure into it to quarantine it safely. The flake is seed-dependent and ordering-artifact related, not a random failure. It will be fixed within the structure of that lane, rather than holding up the main PR gate or relying on blind retries.

### Docs Contract Concurrency (TEST-01)
- **D-04:** **Refactor `DocsContract.evaluate!/2` to guarantee it only reads, then flip all 10+ contract tests to `async: true`.** Reading `priv/` json and markdown files is inherently parallelizable. Enforce a structural guarantee that the contract evaluator never writes to disk during test execution to prevent race conditions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope & Source of Truth
- `.planning/milestones/C1-AUDIT-BRIEF.md` — The canonical milestone brief, specifically §4 (test value A–E classification) and §5.1–§5.2 (ExUnit async/partitioning).
- `.planning/milestones/C1-AUDIT.md#base-03-a-e-classification` — The A–E classification of tests.
- `.planning/REQUIREMENTS.md` — TEST-01 through TEST-05 definitions.
- `.planning/ROADMAP.md` — Phase 110 success criteria.

### Engineering DNA
- `prompts/rendro-oss-dna.md` — szTheory CI/test DNA; specifically §2.2 test strategy and the `threadline` pattern for nightly flake lanes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/docs_contract/` files (e.g., `public_api_contract_test.exs`, `branding_contract_test.exs`) will be the targets for `async: true` flips after refactoring `DocsContract.evaluate!/2`.

### Established Patterns
- Flake management will follow the `threadline` pattern: a separate nightly lane (`mix verify.flake`) rather than blind retries in the main PR gate.

### Integration Points
- `test/test_helper.exs`: Will be updated with documented reasoning for the remaining `async: false` tests.
- `.github/workflows/ci.yml` or a new workflow file for the nightly `verify.flake` lane.
- `lib/docs_contract.ex` or equivalent module containing `evaluate!/2` logic.

</code_context>

<specifics>
## Specific Ideas

- Ensure `RecipesFacadeDriftTest` documents its seed dependency when quarantined.
- The `DocsContract.evaluate!/2` refactor MUST be structurally verified to have no write-side-effects.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 110-Test Concurrency, Determinism & Cleanup*
*Context gathered: 2026-06-15*
# Phase 109: caching-setup-beam - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase establishes the foundational caching layer (`deps`, `_build`, PLT) and unified, pinned `setup-beam` action for the CI pipeline to eliminate cold-cache costs. It guarantees explicit isolation of Dialyzer PLT lifecycles and ensures caches never mask compilation warnings or restore across incompatible toolchains.

</domain>

<decisions>
## Implementation Decisions

### Caching Strategy
- **D-01:** **`CACHE_BUSTER` Strategy**: Use a hardcoded environment variable in the workflow YAML files (`env: CACHE_BUSTER: v1`). This provides visibility in PRs, reproducibility across historical commits, and simplicity for OSS contributors.
- **D-02:** **Dialyzer PLT Isolation and Save/Restore Split (CACHE-03)**: Configure `mix.exs` to place the PLT in `priv/plts/`. Use `actions/cache/restore@v4` and `actions/cache/save@v4` specifically targeting `priv/plts` in the workflow. The `actions/cache/save` step for the PLT will use `if: always()` after `mix ci`, successfully capturing the PLT even if Dialyzer finds type errors.

### Workflow Topology & Actions
- **D-03:** **Workflow Topology & `mix ci`**: Defer `mix ci` decomposition to Phase 111. Phase 109 focuses solely on establishing the caching primitives. `run: mix ci` remains intact to avoid entangling cache logic with `test/guardrails/required_checks_contract_test.exs` rewrites.
- **D-04:** **`erlef/setup-beam` SHA Pinning (CACHE-04)**: Unify all occurrences of `erlef/setup-beam` to the pinned SHA currently found in `release.yml` (`8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Scope
- `.planning/REQUIREMENTS.md` — CACHE-01 through CACHE-05 definitions.
- `.planning/ROADMAP.md` — Phase 109 success criteria.

### Guardrails
- `priv/guardrails/required_status_checks.json` — For `mix ci` verification constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `actions/cache/restore@v4` and `actions/cache/save@v4` will be added to `.github/workflows/ci.yml`.

### Established Patterns
- Workflow step conventions and bash brace-groups for GitHub step summaries (from Phase 108).

### Integration Points
- `mix.exs`: Will be updated to point `dialyzer` core path to `priv/plts`.
- `.github/workflows/ci.yml` (and potentially others): Will be updated with `CACHE_BUSTER` env var, caching steps, and `setup-beam` SHA unification.

</code_context>

<specifics>
## Specific Ideas

- The `actions/cache/save` step for the PLT will use `if: always()` placed after `mix ci`, which runs `dialyzer` last, successfully capturing the PLT even if Dialyzer errors.

</specifics>

<deferred>
## Deferred Ideas

- Decomposing the `mix ci` monolith (Deferred to Phase 111).

</deferred>

---

*Phase: 109-caching-setup-beam*
*Context gathered: 2026-06-15*
# Phase 17: deterministic-ci-gate-recovery-traceability-resync - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Reopen and close the current quality-gate regression by fixing the committed formatting failure in `test/scripts/release_preflight_proof_test.exs` and aligning requirement traceability in `REQUIREMENTS.md` with the actual milestone gate state.
</domain>

<decisions>
## Implementation Decisions

### Formatting Approach
- **D-01:** Apply standard `mix format` to `test/scripts/release_preflight_proof_test.exs` to resolve the format regression. Do not use manual workarounds.

### Traceability Documentation
- **D-02:** Update `REQUIREMENTS.md` to accurately reflect the `QUAL-01` requirement as fully resolved and verified by the CI gate. Ensure the milestone gate state matches the documented traceability.

### CI Gate Verification
- **D-03:** Rely on `mix ci` passing locally as the definitive proof that the format fix is complete and the deterministic CI gate is recovered.

### Claude's Discretion
- All routine implementation decisions regarding the exact lines changed by `mix format` and the specific wording of the traceability update are left to the implementation agent's discretion, following the project methodology (Truthful Small Contracts and Deterministic Standard Formatting).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md` — Overall project goals and constraints.
- `.planning/REQUIREMENTS.md` — Core requirements and traceability matrix to update.
- `.planning/ROADMAP.md` — Phase boundary and goals.
- `.planning/METHODOLOGY.md` — Engineering posture and lenses.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix format` — The standard formatting tool to apply.
- `mix ci` — The canonical verification lane to run.

### Integration Points
- `test/scripts/release_preflight_proof_test.exs` — The file with the formatting regression.
- `.planning/REQUIREMENTS.md` — The documentation to resync.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches (use standard Elixir formatting).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 17-deterministic-ci-gate-recovery-traceability-resync*
*Context gathered: 2026-04-28*
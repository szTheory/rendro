# Phase 52: qpdf Adapter and Structural Validation - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the first-party `qpdf` executable boundary and make Rendro's structural-validation lane prove that a qpdf-protected PDF remains structurally readable when the caller supplies the intended password. This phase is about truthful adapter behavior and proof shape, not about widening the protection product surface, not about viewer claims, and not about native in-core encryption.

</domain>

<decisions>
## Implementation Decisions

### Validation password contract
- **D-01:** `Rendro.Adapters.Poppler.validate/2` should be `open_password`-first. If `open_password` is present and non-empty, use only Poppler's `-upw` path.
- **D-02:** `owner_password` is accepted only as a fallback when `open_password` is not provided. Do not silently retry owner-password validation after an `open_password` failure.
- **D-03:** Do not add a generic `password:` validation option in Phase 52. Keep validation terminology aligned with the public protection contract from Phase 51.
- **D-04:** Docs and tests must state plainly that owner-only validation proves structural decryptability, not the normative password-to-open recipient path.

### qpdf permission mapping posture
- **D-05:** Do not widen Phase 52 toward lower-level qpdf parity. Keep the public advisory-permissions contract intentionally small and Phoenix-friendly.
- **D-06:** Tighten the curated whitelist once by removing or deprecating `:extract_for_accessibility`, since modern readers are expected to ignore that restriction and keeping it would create misleading expectations.
- **D-07:** Keep the rest of the public advisory-permission atoms narrow and high-signal: `:print`, `:copy`, `:modify`, `:annotate`, `:fill_forms`, and `:assemble`.
- **D-08:** Do not expose raw qpdf args, print-tier variants, modify sub-modes, metadata-encryption toggles, insecure flags, or other expert escape hatches in this milestone.

### Proof strategy for the protected-PDF lane
- **D-09:** Phase 52 should use a hybrid proof pyramid: hermetic fast tests for option mapping/redaction/temp-dir behavior, plus a narrow live-tool lane using real `qpdf` and `pdfinfo`.
- **D-10:** Default `mix test` should remain host-tool-light and contributor-friendly. Live qpdf/Poppler checks belong in an explicit tagged integration/proof lane that skips cleanly when tools are unavailable.
- **D-11:** The live lane should generate or build unprotected fixtures, protect them with real qpdf, confirm the protected artifact actually requires a password, and then validate structural readability with `pdfinfo` using the intended password path.
- **D-12:** Commit unprotected seed builders or representative authored fixtures, not protected binaries. Protected output is intentionally non-deterministic and should be generated during proof execution.

### Failure and diagnostics shape
- **D-13:** Keep public failures typed and sanitized. Do not make raw qpdf or Poppler stderr/stdout part of the stable tuple contract.
- **D-14:** Align Poppler with the existing `:protect` posture by normalizing raw `pdfinfo` failures into a small stable reason set rather than returning arbitrary tool text.
- **D-15:** Accept a small, operator-useful classification surface for validation failures such as structural invalidity, password required, incorrect password, missing executable, and generic tool failure. Keep the set intentionally small to avoid binding Rendro to vendor wording.
- **D-16:** Password values, raw command lines, temp paths, argfile contents, and rich vendor output must stay out of public errors, metadata, proof artifacts, and routine logs. Public error details may carry only narrow safe signals such as password-presence booleans or stable exit-status classes where explicitly intended.

### Downstream GSD default
- **D-17:** For this phase and similar adapter/proof/documentation work, downstream GSD agents should synthesize one cohesive recommendation set by default instead of surfacing broad menus of equivalent options.
- **D-18:** Escalate to the user only when a decision materially changes public semantics, security/trust posture, milestone scope, or release positioning. Routine tradeoff resolution should be shifted left into GSD.

### the agent's Discretion
- Exact Poppler normalized reason atom names, as long as the public classification surface stays small, stable, and redacted.
- Exact tagged-test naming and CI-lane placement, as long as the fast local lane stays low-friction and the live-tool proof lane remains explicit.
- Whether `:extract_for_accessibility` is removed immediately or deprecated with a narrow migration note, as long as the end state removes it from the truthful long-term contract.
- Exact qpdf-side proof commands used in the live lane, as long as they confirm both actual protection and structural readability.

</decisions>

<specifics>
## Specific Ideas

- Recommended Poppler behavior:
  - if `open_password` exists, pass only `-upw`
  - otherwise, if `owner_password` exists, pass only `-opw`
  - never pass both and treat any success as equivalent proof
- Recommended live proof path:
  - render or build an unprotected PDF fixture
  - protect it with real qpdf using AES-256
  - prove the file is actually protected with a qpdf-side check
  - validate the protected PDF with `pdfinfo` using the intended password path
- Recommended public DX posture:
  - keep permissions as a short whitelist of atoms, not a bitmask or raw qpdf DSL
  - keep validation failures typed and actionable without exposing vendor text
  - prefer "open password" terminology, with "user password" mentioned only as a parenthetical alias in docs
- Ecosystem lessons to preserve:
  - qpdf/Poppler distinguish user/open and owner passwords for a reason; Rendro should preserve that distinction instead of flattening it
  - libraries like `pypdf` and lower-level wrappers expose more parity but also more ambiguity and footguns; Rendro should not copy that posture
  - Elixir users expect stable tagged tuples and explicit boundary APIs more than raw CLI parity

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/PROJECT.md` — v1.10 product posture, truthful-boundary rules, and deterministic-core constraints.
- `.planning/REQUIREMENTS.md` — `ADAPT-01` and `ADAPT-02` define the required Phase 52 outcomes.
- `.planning/STATE.md` — current milestone positioning and accepted constraints from completed Phase 51 work.
- `.planning/milestones/v1.10-ROADMAP.md` — Phase 52 goal, dependency chain, and plan split.
- `.planning/milestones/v1.10-CONTEXT.md` — milestone-level locked scope and non-goals for the protection family.

### Prior locked decisions
- `.planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md` — public protection seam, AES-256-only contract, advisory-permissions posture, and password-redaction rules that Phase 52 must preserve.

### Research inputs
- `.planning/research/SUMMARY.md` — milestone recommendation to stay external-hook-first and proof-backed.
- `.planning/research/ARCHITECTURE.md` — artifact-first protection rationale, deterministic-core posture, and adapter boundary guidance.

### Core code seams
- `lib/rendro/protect.ex` — public protection API, option normalization, and redaction behavior that validation must stay aligned with.
- `lib/rendro/adapters/qpdf.ex` — qpdf executable seam, argfile behavior, temp-dir cleanup, and permission-flag mapping.
- `lib/rendro/adapters/poppler.ex` — structural validation seam and password-flag handling to refine in this phase.
- `lib/rendro/error.ex` — typed error contract and `why`/`next` guidance that diagnostics must remain consistent with.
- `test/rendro/adapters/qpdf_test.exs` — existing hermetic adapter proof style to extend.
- `test/rendro/adapters/poppler_test.exs` — existing Poppler test seam to evolve into the Phase 52 proof shape.
- `guides/api_stability.md` — truthful wording for protection and structural validation boundaries.
- `priv/support_matrix.json` — machine-readable support contract that Phase 52 proof must remain consistent with.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/adapters/qpdf.ex`: already has the key executable-finder, command-runner, argfile, and temp-dir-cleanup seam needed for a strong hermetic test layer.
- `lib/rendro/adapters/poppler.ex`: already supports `open_password` and `owner_password` flags, so the main work is contract tightening and failure normalization rather than inventing a new interface.
- `lib/rendro/protect.ex`: already defines the explicit dual-password and narrow advisory-permissions posture that Phase 52 should inherit instead of reinterpreting.
- `test/rendro/adapters/qpdf_test.exs`: already demonstrates the repo's preferred style for external-boundary unit tests via injected runtime seams.

### Established Patterns
- Rendro prefers explicit narrow public contracts over raw low-level parity surfaces.
- Optional runtime integrations should stay optional in normal development and fail with typed results instead of hidden behavior or hard dependency assumptions.
- Proof-backed support language matters more than feature breadth; structural validation and viewer proof remain separate lanes.
- Password-safe redaction is part of product behavior, not an afterthought.

### Integration Points
- Phase 52 is the missing `protect -> validate` link called out by the v1.10 audit.
- The new proof lane must reinforce, not weaken, the current artifact-first public story and the `metadata.deterministic = false` protected-artifact contract.
- Any Poppler diagnostics changes must compose cleanly with `Rendro.Error` and not introduce a different error philosophy for validation than protection already uses.

</code_context>

<deferred>
## Deferred Ideas

- Low-level qpdf parity controls such as print tiers, modify sub-modes, metadata-encryption toggles, insecure/test-only flags, or raw CLI passthrough.
- A generic one-password validation API that collapses `open_password` and `owner_password`.
- Rich public exposure of vendor stderr/stdout or deep CLI diagnostics.
- Any viewer-behavior promotion, manual viewer proof, or release-tail work assigned to Phases 53 and 54.

</deferred>

---

*Phase: 52-qpdf-adapter-and-structural-validation*
*Context gathered: 2026-05-06*

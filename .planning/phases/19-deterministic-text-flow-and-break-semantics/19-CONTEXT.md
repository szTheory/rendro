# Phase 19: Deterministic Text Flow and Break Semantics - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Make flow layout expressive enough for real reports by adding deterministic wrapped-text measurement and explicit keep/break intent to the existing flow engine. This phase clarifies how authored flow text wraps and how flow blocks express page intent; it does not introduce fonts/assets, rich paragraph typography, browser-style fragmentation, or table-row split policy.

</domain>

<decisions>
## Implementation Decisions

### Wrapped text contract
- **D-01:** Width-constrained flow text remains a `Rendro.Block` containing `Rendro.Text`; Rendro does not make `Rendro.Text` self-wrapping by adding geometry such as `:width`.
- **D-02:** `Rendro.Block.width` remains the public width constraint for wrapped flow text because block geometry is already the measured and paginated unit in the existing engine.
- **D-03:** Text-specific vertical styling such as `line_height` belongs on `Rendro.Text`, not on `Rendro.Block`, so content styling stays separate from page geometry.
- **D-04:** Wrapped text semantics in Phase 19 stay narrow and truthful: preserve explicit newlines, wrap deterministically on whitespace, and document one explicit fallback for single tokens that exceed available width.
- **D-05:** Phase 19 does not introduce a new report DSL or paragraph authoring layer as the primary public contract. If a `Rendro.paragraph/2` helper is ever added later, it should compile to the same block-and-text core contract rather than replace it.

### Break directive surface
- **D-06:** `keep_together`, `keep_with_next`, `break_before`, and `break_after` live on `Rendro.Block` as the only public break-intent surface for this phase.
- **D-07:** `Rendro.Text` does not carry break directives. It remains a leaf content/style struct, not a pagination container.
- **D-08:** Phase 19 does not add section-level break semantics or flow action nodes such as standalone `page_break()` content items. Those would widen the grammar before the core contract is stable.
- **D-09:** `keep_with_next` applies to the current block plus the immediate next pagination unit in Phase 19. Chaining behavior must be deterministic and explicitly documented if multiple consecutive blocks opt in.

### Keep-rule failure semantics
- **D-10:** `keep_together` and `keep_with_next` are hard authored constraints, not advisory hints. If the kept unit fits on a fresh page/body region, move it intact; if it cannot fit even there, fail truthfully.
- **D-11:** Impossible keep-rule layouts return the existing typed paginate overflow contract (`%Rendro.Error{stage: :paginate, reason: :content_overflow}`) rather than silently relaxing the keep rule, shrinking content, clipping content, or raising raw exceptions.
- **D-12:** Keep-related failures enrich `Rendro.Error.details` instead of creating a new top-level error family. Minimum keep-specific diagnostics should include the keep rule involved, the kept height, the max available height, page/region context, and the kept block indexes.
- **D-13:** Flow-only break directives used on fixed-position pages should fail with a typed boundary error rather than being silently ignored.

### Public API and docs posture
- **D-14:** The public story for Phase 19 is: text wraps when a flow block has constrained width, and flow blocks can carry explicit pagination intent (`keep_together`, `keep_with_next`, `break_before`, `break_after`).
- **D-15:** README and guides should teach the supported core path using `Rendro.flow/2`, `Rendro.block/2`, `Rendro.text/2`, and page templates/regions. User-facing examples should not mention internal pipeline stages.
- **D-16:** Docs must stay explicit about what Phase 19 does not promise: no widow/orphan control, no hyphenation, no typography engine claims beyond current deterministic font metrics, no browser/CSS break model, and no automatic “best effort” relaxation of keep rules.

### Recommendation-first workflow posture
- **D-17:** For this project, downstream GSD agents should continue the recommendation-first posture: research deeply, collapse routine tradeoffs into one coherent default, and only escalate choices that materially affect product semantics or roadmap scope.
- **D-18:** The specific preference captured from this discussion is to shift this posture left within GSD where possible. Future discuss/research/planning steps should avoid option menus by default unless the decision is unusually high-impact or policy-significant.

### the agent's Discretion
- Exact names for any new `Rendro.Text` styling field(s) added for wrapped text, as long as geometry remains on `Block` and style remains on `Text`.
- The exact long-token fallback, as long as it is deterministic, documented, and fixture-tested.
- Whether future convenience helpers are deferred entirely to Phase 22 or introduced as thin sugar only after the block-and-text core contract is documented and proven.

</decisions>

<specifics>
## Specific Ideas

- Primary recommendation synthesis for Phase 19:
  - keep width on `Block`
  - keep style on `Text`
  - keep break intent on `Block`
  - keep impossible keep rules as typed overflow failures
  - keep the docs centered on the existing builders instead of a new DSL
- Important UX rule: callers should be able to look at authored flow code and predict what owns geometry, what owns text styling, and what owns page intent without reading engine internals.
- Future helper opportunity is acknowledged but deferred: if repeated wrapped-text boilerplate becomes noisy, a `paragraph` helper can arrive later as thin sugar over the same core contract.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and roadmap contract
- `.planning/PROJECT.md` — product boundary, current milestone intent, and truthfulness constraints.
- `.planning/REQUIREMENTS.md` — locked requirements `LAY-06` and `LAY-09` for wrapped text and explicit keep/break directives.
- `.planning/ROADMAP.md` — Phase 19 goal and success criteria within milestone `v1.1`.
- `.planning/METHODOLOGY.md` — active lenses: truthful small contracts, boundary validation first, deterministic standard formatting, least surprise DX.

### Prior phase foundation
- `.planning/phases/18-layout-contract-and-page-template-model/18-RESEARCH.md` — explicit page-template/region rationale and Phase 19 dependency context.
- `.planning/phases/18-layout-contract-and-page-template-model/18-03-SUMMARY.md` — truthful overflow contract and renderer-aligned fit-validation behavior that Phase 19 should extend, not replace.

### Current public surface and pipeline seams
- `lib/rendro.ex` — public builders and the current authoring surface that Phase 19 should extend coherently.
- `lib/rendro/text.ex` — current leaf text contract; style belongs here, not geometry.
- `lib/rendro/block.ex` — current geometry container and recommended home for break directives.
- `lib/rendro/document.ex` — flow document contract and block-based content surface.
- `lib/rendro/pipeline/compose.ex` — current normalization seam; sections already flatten into block lists here.
- `lib/rendro/pipeline/measure.ex` — current text and table measurement seam; Phase 19 wrapping logic must land here coherently.
- `lib/rendro/pipeline/paginate.ex` — current pagination seam; keep/break logic and overflow diagnostics must remain deterministic here.
- `lib/rendro/error.ex` — current structured error surface to enrich for keep-rule failures.

### Existing proofs and docs to extend
- `test/rendro/flow_test.exs` — current public flow behavior proofs; Phase 19 should add wrapped-text and keep/break regressions here.
- `test/rendro/pipeline/paginate_test.exs` — current pagination and overflow proof surface for deterministic block movement and failure details.
- `test/rendro/pipeline/measure_test.exs` — current measurement proof surface to extend for multi-line text height/line-break determinism.
- `README.md` — primary user-facing docs surface that must explain wrapped text and break semantics truthfully.
- `guides/integrations.md` — supporting docs surface that must remain aligned with the core authoring contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Block` already owns `x`, `y`, `width`, and `height`, making it the natural width and break-intent boundary.
- `Rendro.Text` is currently a pure content/style leaf with `content`, `font`, `size`, and `color`; it is the right place for text styling extensions, not geometry.
- `Rendro.Pipeline.Measure` already computes text width/height and is the natural place to add deterministic multi-line measurement.
- `Rendro.Pipeline.Paginate` already owns page movement and typed overflow details, so keep-rule evaluation should stay there rather than leaking into render.

### Established Patterns
- Public builders are plain `struct!` wrappers with small explicit contracts; Phase 19 should preserve that style.
- Compose normalizes authored structures into block lists, Measure sizes them, and Paginate applies movement and fit rules. New semantics should follow those stage boundaries.
- Overflow is already treated as product behavior with structured `details`; keep-rule failures should extend that posture instead of inventing a second error path.

### Integration Points
- `Measure` must turn width-constrained text blocks into deterministic line boxes and multi-line heights.
- `Paginate` must evaluate `keep_together`, `keep_with_next`, and explicit break-before/after on measured blocks using the existing body-region/page-fit model.
- Docs and tests must move in the same phase so the public contract stays truthful once wrapped text and keep rules ship.

</code_context>

<deferred>
## Deferred Ideas

- Add a higher-level `Rendro.paragraph/2` helper or other recipe-oriented sugar only if later phases prove the boilerplate is materially harming DX.
- Introduce softer future directives such as `ensure_space` or `avoid_break` only as separate semantics; do not weaken the meaning of `keep_together` or `keep_with_next`.
- Widow/orphan control, hyphenation, richer line-breaking algorithms, and typography-sensitive paragraph semantics belong to later milestones once fonts/assets are in scope.
- Table-row integrity and row-level keep semantics belong to Phase 20, not Phase 19.

</deferred>

---

*Phase: 19-deterministic-text-flow-and-break-semantics*
*Context gathered: 2026-04-29*

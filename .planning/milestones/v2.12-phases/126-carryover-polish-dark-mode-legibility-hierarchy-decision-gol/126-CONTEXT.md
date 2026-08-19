# Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning
**Decision mode:** Fully autonomous (`--auto`); all phase-specific gray areas were selected and resolved to the recommended conservative option in one pass.

<domain>
## Phase Boundary

Phase 126 closes the three known v2.11 visual regressions before catalog generation: dark Invoice table text, themed Ticket hierarchy/reference wrapping, and themed Payslip amount wrapping. It also adds the missing preset/accent byte golden and dedicated typography coverage needed to make all seven recipes explicit rather than smoke-only.

This phase repairs and proves existing recipe/theming behavior. It does not generate the public catalog, add new presets or Theme fields, build configurator/codegen surfaces, or publish final milestone claims.

</domain>

<decisions>
## Implementation Decisions

### Dark table color semantics

- **D-01:** A themed table body must receive semantic theme ink rather than inheriting the fixed black default used by bare String cells. Repair the shared themed table-cell construction/style boundary so the same rule can be reused by every recipe; do not make the dark surface artificially light and do not hide the problem with an Invoice-only background or palette patch.
- **D-02:** Preserve the legacy unthemed String-cell path and all frozen no-theme bytes. The shared repair may add or reuse a private helper or table styling seam, but must not globally change unrelated unthemed caller tables.
- **D-03:** The fix covers table headers and body cells wherever a themed recipe uses the shared path, with explicit role choices (`ink` for primary values and `muted` only where the existing semantic hierarchy calls for it). Color contrast remains a bounded legibility improvement, not a WCAG/PDF-UA claim.

### Ticket hierarchy disposition

- **D-04:** Fix WINDOWS id 2; do not ship an exemption as the preferred outcome. Under every supplied theme, including all six Phase 125 presets, placement-grid values remain the dominant ticket fact, the event title stays secondary, and the human-readable reference code remains compact, legible, and visually subordinate.
- **D-05:** Preserve the no-theme Ticket bytes and the public `theme:`/`:typography` override order. Resolve the conflict through theme-aware semantic role mapping or an equally narrow recipe seam, not per-preset branches or a flattened one-size hierarchy. — **Reversibility: costly** — the resulting semantic role mapping becomes the baseline for Phase 127 rubric scoring and generated catalog rows.
- **D-06:** Keep the required reference visible and copyable; do not truncate it, hide it behind an image, or permit ordinary fixture references to split into the known three-line mid-token failure.

### Payslip numeric integrity

- **D-07:** Formatted money cells are visually atomic. Current/YTD values such as `$4,200.00` and `$25,200.00` must not break mid-number under the default theme or any curated preset, including Minimal-Mono.
- **D-08:** Prefer a bounded numeric-cell solution—measured column retuning, amount-specific fitting, or an existing non-breaking layout primitive—before shrinking the entire Payslip type scale. Preserve right alignment, Decimal formatting, description readability, reconciliation, and pagination.
- **D-09:** Preserve the no-theme bytes and the existing `:payslip_sans` fallback behavior. Do not introduce a public no-wrap API or a new font dependency unless research proves the existing private/layout seams cannot satisfy the requirement.

### Golden and typography depth

- **D-10:** Add a dedicated, table-driven byte golden over one stable realistic recipe/input that proves more than the historical single `from_brand/2` call: include `from_brand` and representative `Theme.preset/2` paths across at least two distinct accents, assert two-run equality, and bind the expected hashes. Keep the matrix deliberately bounded rather than multiplying every genre × accent × mode combination already covered elsewhere.
- **D-11:** Bring all seven recipes to dedicated typography-contract coverage. Four test modules currently exist (Invoice, Statement, Certificate, Ticket); planning must inspect their actual assertions and add or deepen the missing BrandedInvoice, Payslip, and Receipt coverage so every recipe proves its materialized scale, font roles, leading, and winning explicit override behavior.
- **D-12:** Existing smoke, byte-identity, deterministic preset-matrix, and raster tests remain useful but do not substitute for recipe-specific semantic typography assertions. Avoid duplicating the full twelve-row Phase 125 matrix in the new golden lane.

### Evidence closure and review ergonomics

- **D-13:** Close `.planning/WINDOWS.md` ids 1–3 only after focused regression tests, the relevant full deterministic suites, and fresh pinned-PDFium output for affected rows all pass. Update `priv/quality/SIGN-OFF.md` and `priv/quality/rubric_scores.json` from the new evidence; do not merely flip `passed` fields.
- **D-14:** Re-render only the affected launch/preset evidence unless a shared-byte change mechanically requires broader regeneration. Keep deterministic and advisory verification lanes separate and keep `priv/goldens` changes explicit.
- **D-15:** If human visual judgment is requested, present affected images at readable size in a sequential slideshow/lightbox-style review rather than only as a dense contact sheet. This is review ergonomics, not a new shipped UI feature.
- **D-16:** Phase completion means the three known defects are fixed and evidenced, all seven recipes have explicit typography coverage, the bounded accent golden is stable, and `mix test` plus `mix ci.fast` pass. Previously accepted Phase 125 preset imagery must not regress.

### the agent's Discretion

The planner may choose private helper names, exact affected raster rows, the stable golden fixture and two-or-more accent values, and whether amount integrity is achieved by measured widths or an existing private fitting seam. Research should determine the narrowest shared table-cell mechanism and the exact Ticket themed-role remapping. No public API, new dependency, per-preset recipe branch, blanket contrast claim, or premature catalog artifact may be introduced.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and locked requirements

- `.planning/ROADMAP.md` — Phase 126 goal, ordering, success criteria, and catalog-before-polish prohibition.
- `.planning/REQUIREMENTS.md` — POLISH-01..05 and milestone-wide determinism/no-overclaim boundaries.
- `.planning/PROJECT.md` — pure-core, deterministic, optional-adapter, and truthful-claims constraints.
- `.planning/STATE.md` — current milestone position and carryover ownership.
- `.planning/WINDOWS.md` — exact root-cause records for open ids 1–3.

### Prior decisions and evidence

- `.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-CONTEXT.md` — preset grammar, font bridge, deterministic/advisory lane separation, and Phase 126 deferred scope.
- `.planning/milestones/v2.11-phases/122-typography-type-scale-application-font-role-leading-wiring/122-CONTEXT.md` — original recipe role assignments and byte-preservation decisions.
- `.planning/milestones/v2.11-phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/123-CONTEXT.md` — honest rubric closure and explicit deferral of the three defects.
- `priv/quality/SIGN-OFF.md` — human findings and current honest dispositions for Invoice, Payslip, and Ticket.
- `priv/quality/rubric_scores.json` — machine-checked score records whose rationale must be updated from fresh evidence.

### Implementation and test seams

- `lib/rendro/theme.ex` — light/dark role values, `from_brand/2`, and stable Theme field shape.
- `lib/rendro/theme/presets.ex` — six curated preset values and font roles; recipes must not branch on genre.
- `lib/rendro/recipes/invoice.ex` — bare String table rows causing dark ink failure.
- `lib/rendro/recipes/ticket.ex` — non-monotone native role mapping and themed reference/placement conflict.
- `lib/rendro/recipes/payslip.ex` — fixed numeric columns, shared cell helper, and `:payslip_sans` fallback constraints.
- `test/rendro/recipes/themed_render_smoke_test.exs` — current seven-recipe render smoke baseline.
- `test/rendro/theme/preset_render_matrix_test.exs` — deterministic six-genre light/dark matrix.
- `test/rendro/theme/preset_raster_snapshot_test.exs` — pinned-PDFium advisory comparator and review-output seam.
- `test/rendro/recipes/invoice_typography_test.exs` — existing dedicated recipe typography pattern.
- `test/rendro/recipes/statement_typography_test.exs` — existing dedicated recipe typography pattern.
- `test/rendro/recipes/certificate_typography_test.exs` — existing dedicated recipe typography and curated-font pattern.
- `test/rendro/recipes/ticket_typography_test.exs` — existing Ticket-specific role contract that Phase 126 must intentionally revise.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `palette/1` and `typography/1` in every recipe already preserve a literal no-theme branch and resolve a supplied theme separately; fixes can remain additive to themed behavior while protecting frozen bytes.
- `Rendro.measure_rows/4` and the current fixed/share column model provide real font measurements for Payslip width decisions.
- `Rendro.Theme.resolve/1`, `from_brand/2`, and `preset/2` already produce fully materialized values; the phase needs proof and recipe mapping, not another theme engine.
- The shared preset render/raster matrices already provide stable row IDs and a pinned advisory evidence path.

### Established Patterns

- No-theme branches reproduce exact historical literals; theme branches may evolve on the adapter tier but require explicit evidence and updated hashes.
- Recipe semantics bind visible elements to named type/color roles; presets vary values behind those roles and never cause genre branches in recipes.
- Quality records stay honest: an issue is closed only by changed behavior plus evidence, not by prose or score edits alone.
- Deterministic bytes, raster hashes, and human visual judgment are separate verification layers.

### Integration Points

- Invoice table row construction is the concrete reproducer for shared semantic cell ink.
- Ticket `main_section/2`, `reference_blocks/7`, and `typography/1` jointly control the inverted hierarchy.
- Payslip `body_section/2`, `cell_text/3`, fixed amount widths, and `measure_rows/4` jointly control numeric wrapping.
- The missing dedicated typography surfaces are BrandedInvoice, Payslip, and Receipt after Phase 125's Certificate coverage.
- WINDOWS, rubric scores, sign-off prose, launch artifacts, and raster hashes are downstream evidence consumers of the fixes.

</code_context>

<specifics>
## Specific Ideas

- Treat numbers like `$4,200.00` as indivisible visual tokens; the line-item description columns may wrap, but money columns should not.
- Ticket should read placement first, event title second, reference code as a compact utility fact—not as the largest object on the page.
- Human review artifacts should be readable one at a time. A zoomed-out contact sheet can remain an index, but not the only inspection surface.

</specifics>

<deferred>
## Deferred Ideas

- Phase 127 owns public catalog generation, row-budget policy, and catalog-wide quality scoring.
- Phase 128 owns the shipped static configurator; a reusable browser-based slideshow/lightbox may be considered there if it naturally supports catalog browsing.
- Phase 129 owns final public guide/support-matrix/claim-language closure.
- A general public table-cell styling or no-wrap API is deferred unless Phase 126 research proves a private/shared existing seam cannot solve the bounded defects.

</deferred>

---

*Phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-golden-typography-depth*
*Context gathered: 2026-08-16*

# Phase 73: Page-Numbering / Running-Region Primitive - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers **running header/footer regions with deterministic "Page X of Y" substitution as a proven, tested engine capability**, and closes the prerequisite `body_capacity` overlap bug. Concretely (PAGE-01..04):

- Single-pass `{{page_number}}` **and** `{{total_pages}}` substitution where the total is the real page count (no second render).
- Running-region content authorable as a per-page function, a named helper, or token strings; suppressible on specific pages (e.g. first page).
- `body_capacity` subtracts header/footer region heights so body content never overlaps a non-zero footer.
- Byte-identical output for identical inputs; no layout-convergence loop.

**In scope:** the engine-level PAGE primitive only. **Out of scope:** the Statement/Receipt/Certificate recipes (phases 74–76) that *consume* this primitive — though the API shipped here must stay consistent with the three-rung escape hatch (`document/2`, `page_template/1`, `sections/2`) those recipes use.

</domain>

<decisions>
## Implementation Decisions

### Running-region content API
- **D-01:** **The per-page function is the primitive.** Running-region content blocks may carry a `fn {page_number, total_pages} -> content end`, evaluated once per page. `Rendro.page_number/1` (named helper) and the `{{page_number}}` / `{{total_pages}}` token strings are **sugar that lowers to that function** — one uniform evaluation path, not parallel mechanisms.
- **D-02:** Evaluation happens at the existing per-page site (`Rendro.Pipeline.Paginate.replace_page_numbers/2`, paginate.ex:414), called from the `Enum.with_index(1)` map (paginate.ex:36) where the real `total = length(pages)` is already in hand. This keeps it single-pass (PAGE-01) and rides infrastructure that already works for `{{page_number}}`.
- **D-03:** The function signature is `fn {page_number, total_pages} -> content end` (a 2-tuple of integers → content blocks), matching the requirement's stated `fn {page, total} -> ... end` shape. This is the public surface recipes 74–76 inherit; it must compose with `Rendro.section(region: :footer, content: [...])` authoring.
- **Rejected:** token-string-as-primitive (coercing `fn` output back into tokens is leaky and cannot host the mandated raw `fn`; inverts the ReportLab/fpdf2/Prawn-proven model).

### Reserved-height model (PAGE-03 fix)
- **D-04:** **Authored region `height:`; the engine subtracts it.** Fix `body_capacity` to `body_region.height − header_region.height − footer_region.height`, reading the heights already present on `Rendro.Region` (default 0 → no-op for today's default template; correct reservation whenever a caller sets a non-zero footer/header).
- **D-05:** **No engine auto-measure of region content** in this phase. Auto-measure is the one model (CSS @page margin boxes) that requires multi-pass and would reintroduce the convergence loop PAGE-04 forbids. Batteries-included ergonomics live at the recipe layer (recipes supply correct heights), not the engine primitive.
- **D-06:** A future opt-in `height: :auto` (measure-once-then-freeze) is a **deferred** possibility, not in this phase's scope.
- **Fix locations:** `body_capacity/1` at `lib/rendro/pipeline/measure.ex:442` and the mirror at `lib/rendro/pipeline/paginate.ex:494`.

### Per-page suppression (PAGE-02)
- **D-07:** **Declarative selector as common-case sugar over a functional fallthrough.** Provide `skip_first: true` / `pages: :except_first` (and an explicit-page selector form) at the region/section surface for the dominant "suppress on first page" case (cover pages, letterheads); the content function returning `nil`/`[]` is the always-available escape hatch for arbitrary per-page logic.
- **D-08:** **Suppression hides rendering but NEVER reclaims reserved height.** A suppressed page keeps the region's reserved height, so `body_capacity` stays uniform across all pages. This matches LaTeX `\thispagestyle{empty}`, ReportLab `onFirstPage`, and CSS `@page :first`, and is what keeps the determinism invariant (D-09) intact.
- **Precedence:** the declarative selector resolves first; the content function is still consulted for non-suppressed pages. Planner to specify exact precedence when selector and function disagree.

### Determinism contract (PAGE-04)
- **D-09:** **Fixed reserved height; `total_pages` is pure post-pagination text substitution (Option A).** Invariant to encode: reserved region height — and therefore `body_capacity` — is a pure function of **declared layout geometry only**, independent of (a) per-page region content, (b) page index, and (c) the digit-width of `{{page_number}}`/`{{total_pages}}`.
- **D-10:** `{{total_pages}}` MUST follow the existing `{{page_number}}` path in `replace_page_numbers/2`: rewrite `MeasuredText.source.content` and the `lines`/runs `text` only — never re-run measurement or re-derive `body_capacity`. (This is the ReportLab single-build `NumberedCanvas` deferred-stamp model, not `multiBuild` two-pass.)
- **D-11:** **Determinism test MUST assert** all four: (a) same doc rendered twice with `deterministic: true` → byte-identical bytes; (b) `body_capacity` identical for a 9-page vs 100+-page document (digit-width does not feed back into capacity); (c) page count + per-page body-block assignment identical whether the region contains `{{total_pages}}` or a static wide placeholder string; (d) `replace_page_numbers/2` (extended for `{{total_pages}}`) leaves `MeasuredText.lines` geometry and block `height` unchanged before vs. after substitution (regression guard against a future re-measure-on-substitute).

### Claude's Discretion
- Exact module/typespec placement of the `page_number/1` helper (`lib/rendro.ex` near `region/1`/`section/1`, lines ~199–207) and the `Rendro.Section` content typespec widening.
- Internal representation of a "lowered" function vs token string, and the selector field name/shape (`suppress_on:` vs `pages:`) — pick the most idiomatic; keep it consistent for recipe reuse.
- Error/validation behavior for an under-sized region or a malformed function arity (reuse existing `maybe_validate_region_fit`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §PAGE-01..PAGE-04 — the locked WHAT for this phase.
- `.planning/ROADMAP.md` §"Phase 73" — goal + 4 success criteria.

### Engine code to modify (verified during scout)
- `lib/rendro/pipeline/paginate.ex:414` — `replace_page_numbers/2`; per-page substitution site. Extend for `{{total_pages}}` and host function evaluation here.
- `lib/rendro/pipeline/paginate.ex:36` — `Enum.with_index(1)` map where `total = length(pages)` is available single-pass; paginate.ex:494 sets `body_capacity`.
- `lib/rendro/pipeline/measure.ex:442` — `body_capacity/1`; the PAGE-03 bug (returns `body_region.height`, ignores header/footer). measure.ex:420 `measure_region_blocks` already measures header/footer block heights.
- `lib/rendro/region.ex` — `Rendro.Region` struct; existing `height` field (the field D-04 subtracts).
- `lib/rendro/page_template.ex` — default `Rendro.PageTemplate` regions (header/footer default height 0).
- `lib/rendro.ex:199-207` — public `region/1` / `section/1`; likely home for the `page_number/1` helper.
- `lib/rendro/recipes/invoice.ex:141` — `footer_section/1`; the section-authoring pattern recipes use that this API must stay consistent with.

### Idiomatic analogs (cited by PROJECT.md / research)
- ReportLab `onPage` / `NumberedCanvas` deferred-stamp (per-page callback primitive; single-build total-pages).
- fpdf2 `header`/`footer` + `page_no()`/`{nb}`; LaTeX `\textheight` derived from fixed `\headheight`/`\footskip`; CSS `@page :first`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `replace_page_numbers/2` (paginate.ex:414) — already does post-pagination `{{page_number}}` substitution into both `Rendro.Text` and `Rendro.Pipeline.MeasuredText` (source + per-run `lines`). Extend it (don't replace) for `{{total_pages}}` and for function evaluation; the `total` is already computable at the call site.
- `measure_region_blocks/2` (measure.ex:420) — already measures header/footer block heights, so measured data is available if a future `height: :auto` is pursued.
- `apply_page_template/3` (paginate.ex:397) + `anchor_region_blocks/3` — anchors non-body regions per page; the seam where suppressed-but-reserved regions render nothing while keeping geometry.
- `maybe_validate_region_fit` — existing region-fit validation; reuse for under-sized-region errors rather than inventing new error paths.

### Established Patterns
- Three-rung escape hatch (`document/2` → `page_template/1` → `sections/2`) — `lib/rendro/recipes/invoice.ex` is the reference; the PAGE API must be authorable from `sections/2` and consistent across recipes 74–76.
- Single forward pass over body blocks against `max_h = layout.body_capacity` (paginate.ex:20) — no convergence loop today; D-09 preserves this.
- `deterministic: true` contract already exists from prior milestones.

### Integration Points
- `body_capacity` is consumed in exactly two places (measure.ex:442, paginate.ex:494) — both must change together.
- Recipes (phase 74+) author footers via `Rendro.section(region: :footer, content: [...])`; the new content-function/helper/selector surface plugs in there.

</code_context>

<specifics>
## Specific Ideas

- User is the library author (technical, opinionated/decisive). Preference confirmed: deep parallel research → locked recommendations, asked only on very impactful decisions. All four areas were researched in parallel and locked in one pass.
- The design is deliberately the *engine primitive only*; "batteries-included" ergonomics are intentionally pushed to the recipe layer so the engine stays deterministic and single-pass.

</specifics>

<deferred>
## Deferred Ideas

- **`height: :auto` (auto-measured region height, measure-once-then-freeze)** — a future opt-in ergonomic. Explicitly out of scope for Phase 73 to protect the no-convergence-loop guarantee (PAGE-04). Candidate for a later phase if real demand appears.

None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 73-page-numbering-running-region-primitive*
*Context gathered: 2026-05-29*

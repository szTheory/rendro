# Phase 73: Page-Numbering / Running-Region Primitive - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 73-page-numbering-running-region-primitive
**Areas discussed:** Running-region content API, Reserved-height model, Per-page suppression, Determinism contract

**Mode:** Advisor (research-backed comparison tables), calibration tier `minimal_decisive` (vendor_philosophy: opinionated). Four parallel research agents spawned, one per selected area; recommendations locked in one pass per user's research-first / one-shot preference.

---

## Running-region content API

| Option | Description | Selected |
|--------|-------------|----------|
| Per-page function is the primitive | `fn {page, total} -> content end` is the underlying form; `Rendro.page_number/1` helper and `{{page_number}}`/`{{total_pages}}` tokens lower to it. Maps onto existing `replace_page_numbers/2` per-page site. | ✓ |
| Token-string is the primitive | `{{...}}` tokens underlie; helper emits tokens; raw `fn` output coerced back into token substitution. | |

**User's choice:** Per-page function is the primitive (locked recommendation).
**Notes:** Research found ReportLab `onPage`, fpdf2 `header`/`footer`+`page_no()`, and Prawn `repeat dynamic:` all converge on the per-page callback as primitive. Token-as-primitive cannot cleanly host PAGE-02's mandated raw `fn` and would force an awkward dual model.

---

## Reserved-height model (PAGE-03 fix)

| Option | Description | Selected |
|--------|-------------|----------|
| Authored region `height:` subtracted | `body_capacity = body_region.height − header.height − footer.height` from existing `Region.height` field. Deterministic, ~2 lines, default no-op. | ✓ |
| Engine auto-measure | Sum measured header/footer block heights and subtract. Batteries-included but risks PAGE-04 convergence loop. | |

**User's choice:** Authored region height (locked recommendation).
**Notes:** Every mature deterministic engine (LaTeX `\textheight`, fpdf2 `bMargin`, ReportLab fixed Frames) uses authored reserved dimensions. Auto-measure (CSS @page) is the one model needing multi-pass. `height: :auto` deferred as a future opt-in.

---

## Per-page suppression (PAGE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Declarative selector + functional fallthrough; height kept | `skip_first:`/`pages: :except_first` sugar; content fn returning `nil`/`[]` as escape hatch; reserved height never reclaimed → uniform `body_capacity`. | ✓ |
| Pure functional only | Content fn returns `nil`/`[]`; no declarative option surface. | |

**User's choice:** Declarative sugar over functional fallthrough, reserved height always kept (locked recommendation).
**Notes:** Dominant case is "skip footer on cover page" — deserves a readable declarative form consistent across recipes 74–76. Suppression must hide rendering but not reclaim height (matches LaTeX `\thispagestyle{empty}`, ReportLab `onFirstPage`, CSS `@page :first`) to avoid per-page `body_capacity` and the PAGE-04 convergence loop.

---

## Determinism contract (PAGE-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Fixed reserved height; total_pages pure text substitution | `body_capacity` is a pure function of declared geometry; `{{total_pages}}` rewrites text only, never re-measures/re-paginates. ReportLab single-build `NumberedCanvas` model. | ✓ |
| B — Variable reserved height with measure-max-once bounded rule | Allows content-dependent region heights; pre-pass computes max; still single-pass but reintroduces a page-count→height edge to prove non-circular. | |

**User's choice:** Option A — fixed reserved height (locked recommendation).
**Notes:** Option A is already Rendro's architecture. Option B buys variable region height no v2.4 requirement asks for, at the cost of reintroducing the exact cycle PAGE-04 forbids. Four-part determinism test specified in CONTEXT.md D-11.

---

## Claude's Discretion

- Module/typespec placement of `page_number/1` helper and `Rendro.Section` content typespec widening.
- Selector field name/shape (`suppress_on:` vs `pages:`) and internal representation of lowered functions vs token strings.
- Error/validation for under-sized regions or malformed function arity (reuse `maybe_validate_region_fit`).

## Deferred Ideas

- **`height: :auto`** (auto-measured region height, measure-once-then-freeze) — future opt-in ergonomic, out of scope for Phase 73 to protect the no-convergence-loop guarantee.

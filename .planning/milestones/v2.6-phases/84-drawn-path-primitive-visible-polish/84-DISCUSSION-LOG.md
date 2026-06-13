# Phase 84: Drawn-Path Primitive & Visible Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 84-drawn-path-primitive-visible-polish
**Areas discussed:** Color representation, Path coordinate + struct model, Table borders API, Certificate frame design

**Mode:** advisor (calibration tier `minimal_decisive`, profile `opinionated`). Two-pass parallel research: a first scout-grounded sweep, then a deeper pass mining `prompts/` (OSS DNA, Brand Book) + `.planning/research/` (PITFALLS, JTBD) and pressure-testing each first-pass recommendation. The user requested the deep pass explicitly ("research deeply, one-shot a perfect coherent set so I don't have to think") and did not override any recommendation — all four locked as researched.

---

## Color representation (cross-cutting)

| Option | Description | Selected |
|--------|-------------|----------|
| `{r,g,b}` 0–255 tuples only | Reuse the shipped Text convention on all new surfaces; one internal `Rendro.Color` helper; reject hex; correct the ROADMAP example. Hex = future widening. | ✓ |
| Accept hex strings + tuples | Canonical `Rendro.Color` parses `"#000"`/`"#000000"` AND tuples; matches the roadmap example verbatim. | |
| Hex-only | Single web-familiar form. | |

**User's choice:** `{r,g,b}` tuples only (researched recommendation, accepted).
**Notes:** Decisive across-the-board win — no serious lib accepts a bare hex string in a struct field (all use an explicit constructor); Scenic/mudbrick use tuples; tuples are byte-deterministic via the existing `format_num(x/255)` with zero new parser surface to freeze. Brand Book hex palette is web chrome, not an engine format. ROADMAP `"#000"` example corrected to `{0,0,0}` (D-05). Errors must name the hex footgun explicitly.

---

## Path coordinate + struct model (PATH-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Block, top-left, declared size | Flow block; block-relative top-left Y-down (reuses writer Y-flip); caller declares width/height (like Image); raw tagged-tuple op list + declarative stroke/fill maps; no DSL. | ✓ |
| Infer bounding box from ops | Caller writes only ops; block size computed from ops' extent. | (adopted only as the *fallback* when dims omitted) |

**User's choice:** Block, top-left, declared size (researched recommendation, accepted).
**Notes:** Deep pass added load-bearing refinements: (1) bbox = caller-declared primary **with** a deterministic ops-extent fallback so bare paths still measure; (2) `:rounded_rect` is a first-class op decomposed via the `0.5523` kappa already in `circle_path`; (3) `stroke`/`fill` accept a bare color OR a map; (4) deterministic paint-op selection `n/S/f/B` with default-valued state ops omitted for byte-cleanliness; (5) `@enforce_keys [:ops]`. Page-absolute bottom-left rejected (inverts the API's Y convention; can't paginate). Builder DSL rejected (Scenic idiom + Rendro inert-struct culture favor the tuple list; mudbrick's pipe-builder is a culture mismatch).

---

## Table borders / rules / shading (PATH-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Three flat fields | `borders:` (atom\|set-list), `border_style:` (`{color,width,dash}`), `header_fill:` (`{r,g,b}`); inert defaults = byte-identical; collapse/draw-once render. | ✓ |
| Single nested command-map DSL | One `borders:` map, ReportLab/pdfmake-style per-edge command list + callbacks. | |

**User's choice:** Three flat fields (researched recommendation, accepted).
**Notes:** Deep pass reinforced with two binding rules: (1) `border_style` is the inert subset of the Path stroke (`cap`/`join` omitted — axis-aligned edges render identically; forward-compatible); (2) the load-bearing render contract is the **collapse model — each interior edge drawn once** from `_grid_layout` (kills Prawn's double-stroke; rowspan/colspan-aware). `header_fill` kept a distinct field (shading is fill, not stroke — Typst split). Vocabulary = ReportLab BOX/INNERGRID/GRID granularity as composable atoms (`:none/:outer/:rows/:columns/:grid/:all`), list = de-duplicated set. Nested command-map DSL rejected (ReportLab `TableStyle` is the named DX anti-model); per-cell edge fields rejected (Prawn double-draw footgun).

---

## Certificate decorative frame (PATH-03)

| Option | Description | Selected |
|--------|-------------|----------|
| `true\|false\|map`, double-rule default | `border: true` => default frame, map overrides; first-pass default was classic double-rule. | ✓ (shape) / overturned (default design) |
| Boolean `true\|false` only | Smallest surface, no configuration. | |

**User's choice:** `true | false | map` shape (researched recommendation, accepted) — but the **default visual design was overturned** by the deep brand-grounded pass.
**Notes:** Brand Book is explicitly anti-ornamental ("not flashy", "not print-shop nostalgic", monoline, no skeuomorphism) → default changed from a classic double-rule to a **single crisp near-ink keyline** (`{34,34,34}`, square corners, `inset = 0.5·min(margins)`, `weight = max(1.0, short/400)` ≈1.5pt); `:double` kept as a tunable, not the default. Critical layering correction: the frame is NOT drawn first in the `:body` flow region (would consume the flow budget and push text off-page) — instead it's a `%Rendro.Path{}` in a dedicated `anchor: :fixed` `:frame` region whose anchored blocks are prepended (`paginate.ex:422`) → painted underneath content automatically. Color validation delegates to the Path validator. Boolean-only rejected (real additive-later risk); map-only rejected (reintroduces the hardcoded-numerics footgun PATH-03 forbids).

---

## Claude's Discretion

- Module/function names, file layout, internal helper signatures, golden-fixture contents, test organization, and exact `priv/support_matrix.json` row keys — all left to planner/executor, provided the locked public shapes (D-01..D-23) hold.

## Deferred Ideas

- Transforms (`cm`), clipping (`W`), gradients, blend modes, even-odd fill (`f*`) — explicit support-matrix deferrals (PATH-04 / PITFALLS #5).
- Hex / named / 0–1-float color input — future backward-compatible widening via `Rendro.Color.rgb("#..")`, only on demand.
- Per-edge / per-range table border styling — out of scope for v1.
- Certificate corner flourishes / ornamental motifs — out of scope (brand is anti-ornamental).

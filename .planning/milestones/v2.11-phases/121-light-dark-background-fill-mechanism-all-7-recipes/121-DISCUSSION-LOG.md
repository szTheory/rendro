# Phase 121: Light/dark background-fill mechanism (all 7 recipes) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 121-Light/dark background-fill mechanism (all 7 recipes)
**Areas discussed:** Dark legibility scope, Emit trigger, Existing bands/frames & z-order, Dark demo posture

**Method:** User directed a deep-research pass on all four gray areas (pros/cons/tradeoffs, Elixir/OSS idioms, lessons from other design-token/theming/PDF systems, DX, design pillars, the brand book) and asked for one coherent locked recommendation set. Four parallel `gsd-advisor-researcher` agents (one per area) read the brand book + OSS research corpus + the actual theme/recipe/pipeline code and returned grep-grounded recommendations; the orchestrator synthesized them into the mutually-coherent D-01…D-10 in CONTEXT.md.

---

## Dark legibility scope

| Option | Description | Selected |
|--------|-------------|----------|
| A — Page background only (MODE-02 literal) | Paint the dark page rect; accept some overlay text may be illegible | |
| B — Legibility-complete | Paint background AND close remaining foreground-contrast seams so dark reads | ✓ |

**Choice:** B (bounded). Research found Statement passes NO `color:` on any text block → under `dark/1` the whole document is near-black-on-near-black (not "some overlay text" — the entire doc is invisible); Certificate body text has the same hole. A shipped-but-unreadable dark mode violates the brand honesty law (§5/§15). Fix is small and precedent-backed: seam 2 recipes (Statement fully, Certificate body) using Payslip's already-proven pattern; verify the other 5. Byte-identity held by nil-branch literals (`ink/muted {0,0,0}`).
**Notes:** Adopted a lint-able foreground role contract (text reads `ink`/`muted`/`on_accent`/`rule` by what it sits on) rather than per-recipe fixes. Statement table cells (plain strings) are the one real byte-risk → preserve effective cell size, goldens gate.

## Emit trigger

| Option | Description | Selected |
|--------|-------------|----------|
| A — Mode-based | Emit rect iff `mode == :dark` | |
| B — Value-driven | Emit rect iff resolved `background != {255,255,255}` (exact sentinel) | ✓ |

**Choice:** B. Strictly subsumes A (every dark bg is non-white), preserves white-default byte-identity exactly, and is forward-coherent: `from_brand/2` already threads `:background` and Phase 123 does branded/tinted backgrounds — value-driven ships that in light mode for free without reopening `paginate.ex` later. Same-cost predicate, no determinism penalty.
**Notes:** Exact tuple equality is the guard — no tolerance band (a fuzzy near-white cutoff would be an arbitrary, surprising boundary). White `{255,255,255}` documented as the reserved no-paint value. Flag for 123: keep `default/0` background exactly white unless a deliberate, human-signed cream re-bless is intended.

## Existing bands/frames & z-order

| Option | Description | Selected |
|--------|-------------|----------|
| Everything rides the role swap; first-in-`regions` background; no engine change | Single full-page rect behind content; existing bands/frames swap automatically | ✓ |
| Per-recipe bespoke dark handling | Recipe-specific dark branches | |

**Choice:** First option. Z-order grep-proven: `anchored_blocks ++ page.blocks` + list-order paint (painter's algorithm) → first-in-`regions` `:background` = bottom of stack, behind everything, every page incl. overflow. No engine change. Per-recipe audit confirmed all 7 ride the swap (Material "surface tint = elevation without shadow"); only Certificate needs the `:background` region prepended to its `regions`.
**Notes:** No recipe does `fill: colors.background` (grep-confirmed), so the un-guarded `background` literal in `palette/1` is not a clash. Centralize the background-region construction in one shared helper (pays down WR-02 duplication).

## Dark demo posture

| Option | Description | Selected |
|--------|-------------|----------|
| Ship one dark screen demo now | A dark gallery/README image as evidence | |
| Zero shipped dark demos; deterministic test + support stub; defer visual to 123 | Prove mechanism by test; human visual in Phase 123 | ✓ |

**Choice:** Second option. Gallery PNGs ship in the Hex tarball (asserted by `launch_artifacts_claims_test.exs`) → a dark gallery PNG *is* a shipped dark demo → violates MODE-03. Phase 123 already owns the dark visual (DEFAULT-03 + CONTRACT-02), correctly after legibility/typography/DATA fixes. Prove the mechanism with a deterministic dark test (first-op background on page 1 + forced-overflow page; light byte-identical) + a `theming` support-matrix stub row with explicit non-print/PDF-UA/WCAG boundaries + a small `theming_claims_test.exs`.
**Notes:** Do NOT create `guides/theming.md` (Phase 123). A dark visual would also have to wait for the WR-01 legibility fix anyway.

## Claude's Discretion

- Exact mechanism-test file name/placement (new file vs folded into the determinism-golden suite), provided all D-08 assertions are covered.
- Shape of the shared `:background` helper (private fn vs small shared module), provided D-10's single-source intent holds.
- Whether to seam Certificate's empty spacer `Rendro.text("", size: 1)` (no visible glyphs — harmless either way).

## Deferred Ideas

- Human-facing dark gallery visual + `guides/theming.md` → Phase 123.
- `accent`-fill bands reading `on_accent` → latent contract, no live draw-site today.
- Tinted/cream light `default/0` → Phase 123 rubric/`default` tuning (net-new blessed goldens + human sign-off).
- Any WCAG/PDF-UA/print-safety dark claim → permanently out (boundary keys assert `unsupported`).

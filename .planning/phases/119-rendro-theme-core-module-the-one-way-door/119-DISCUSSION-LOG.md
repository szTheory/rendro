# Phase 119: `Rendro.Theme` core module (the one-way door) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 119-rendro-theme-core-module-the-one-way-door
**Areas discussed:** Full frozen field shape, Type-scale ramp numbers, on_accent derivation, default/0 neutral calibration

**Method:** User selected all four presented gray areas and directed deep multi-lens research
(4 parallel subagents) for a one-shot coherent locked recommendation set. Each agent covered:
Elixir/Phoenix/Ecto idiom, cross-language design-token/theming prior art (W3C DTCG, Material 3,
Tailwind, Radix, Bootstrap), DX / principle-of-least-surprise from the consumer's viewpoint,
footguns from other libs, and domain-specific lenses (typographic scale theory, WCAG luminance,
Swiss/International document design). Final synthesis + cross-decision coherence done in main thread.

---

## Full frozen field shape (the one-way door)

| Option | Description | Selected |
|--------|-------------|----------|
| Bare typed maps for token groups under one adapter-tier struct | Matches S1 seam, one manifest module, non-breaking widening | ✓ |
| Nested public structs per group (Theme.Colors, Theme.Typography, …) | Compile-time key safety, but N+1 Hyrum surfaces + rewrites `colors.ink` sites | |
| `positive`/`negative` always present with real values | vs absent-until-set (would make absence an observable contract) | ✓ (always present) |
| `density` as bare `:comfortable \| :compact` atom | vs richer map (premature structure freeze) | ✓ (atom) |

**Choice:** Single `Rendro.Theme` adapter-tier struct; groups are bare typed maps; `@enforce_keys []`;
construct only via `resolve`/`default`/`dark`/`from_brand`; idempotent `resolve/1` deep-merges +
validates every `{r,g,b}` via `Color.validate/1`. Complete frozen field set: colors (9 roles),
typography (fonts/scale/leading/widows/orphans), spacing (unit/tight/normal/loose/section),
rules (hairline/thin/thick), radius (none/sm/md), density atom, mode atom.
**Notes:** Semantic named steps (not Tailwind numbered scales) so values evolve without renaming
fields. Excluded-by-construction web concepts appear as NO field at all. Footguns explicitly avoided:
Tailwind numbered-scale unit leak + extend-vs-replace wipe (answered by semantic names + deep-merge);
Material 3 role explosion (ship only 9 roles real recipes read); Radix raw scales (excluded);
shipping unrenderable tokens like shadow/opacity (excluded); `@enforce_keys` breaking future widening.

---

## Type-scale ramp numbers

| Option | Description | Selected |
|--------|-------------|----------|
| Proposal A (REQUIREMENTS draft) 8/9/10.5/12.5/16/22 | Restrained, but subtitle 1.19× body + title→display 1.375 editorial spike | |
| Proposal B (STACK) 8/9/11/15/20/28 | Taller; display 28 = SaaS-hero + editorial 1.33–1.36 mid-ratios | |
| **Tuned ramp 8/9/10.5/13/16.5/21** | Monotonic 1.125→1.273 (no editorial step); display:body = clean 2.0× | ✓ |

**Choice:** `%{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8}`,
`leading: 1.2` for `default/0` (generous 1.35 = Phase-123 target). Scored 24/25 vs A 22/25, B 21/25.
**Notes:** Body 10.5 = center of business-doc convention (LaTeX 10/11/12; recipes' own 10–11).
caption 8 = print legibility floor. Fixes A's two defects (subtitle-too-close, editorial display spike).
`leading: 1.2` chosen for `default/0` to make TYPE-03 metric-no-op trivially true (engine default is 1.2).
Footguns: display too big (SaaS-hero); caption below 8pt (illegible in print); any step ≥1.333 (editorial
creep); leading >1.2 routed into a frozen-golden block (byte change).

---

## on_accent derivation

| Option | Description | Selected |
|--------|-------------|----------|
| WCAG max-contrast vs theme's two poles (≡ luminance > 0.179 flip), return a token tuple | Bootstrap `color-contrast()` / Material 3 pattern; token-coherent; free dark swap | ✓ |
| Return pure white/black instead of theme tokens | Squeezes ~0.3–0.5 extra ratio but foreign to a warm-paper doc | |
| Require explicit `on_accent:` always | No zero-config path from a single accent seed | |

**Choice:** Auto-derive via WCAG relative-luminance (0.179 threshold, derived not guessed), return
whichever of `background`/`ink` has greater contrast against accent; explicitly overridable. Helpers
private/`@doc false`. Output is always an integer tuple (floats pick a branch only → byte-safe).
**Notes:** Hand-verified across all brand accents (white text on blue/teal/plum/red/green; ink text on
ambers) — matches human expectation. Claims wording = "sensible readable default," NEVER WCAG-AA/PDF-UA
conformance (consistent with MODE-03 posture). Footgun handled honestly: mid-tone accents (blue-600 is
borderline ~4.28) may miss 4.5:1 either way — documented, override offered, never claimed away.

---

## default/0 neutral calibration

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Pure black `{0,0,0}` on pure white | Matches today's recipe literals; flat/generic; ignores brand | |
| (b) Mined-Swiss warm-paper/cool-ink from tokens.json | ink-900 + blue-600 accent + paper surface; "owns ink/paper/blue"; crafted | ✓ |

**Choice:** (b). ink `{16,24,39}` / muted `{91,101,115}` / accent blue-600 `{44,107,237}` / on_accent
white / **background pure white** / surface paper-100 `{247,243,234}` / rule line-400 `{196,188,169}` /
positive green-700 / negative red-700; dark swaps to night-*/paper-d-* tuples.
**Notes:** `background` = pure white is essentially FORCED — MODE-02 gates the dark fill-rect on
`background != {255,255,255}` and demands the light default emit no rect (byte-identical to v2.10); a
tinted page also prints as a full ink wash. Warm character lives in `surface`, not the page. rule =
line-400 (line-300 vanishes on white). Keep surface+rule warm and ink+accent cool — never mix per-role.
Both (a) and (b) are equally safe on the hard constraints; (b) wins decisively on DEFAULT-01's "look
strong on its own." Values are Evolving (tunable at Phase-123 rubric closure); `default/0` is unwired
this phase so zero golden impact now.

## Claude's Discretion

User explicitly asked for a one-shot locked set ("so i dont have to think") — no area deferred back to
the user. Planner retains freedom on: exact `defp` helper names, `@type` phrasing, `density :compact`
shallow-honoring mechanics, moduledoc prose (must carry the stability note + flat-elevation guidance),
and the exact newer-brandbook (`prompts/Rendro Brand Book.txt` / `tokens.json`) values if they supersede
older references.

## Deferred Ideas

- Generous `leading: 1.35` on prose blocks → Phase-123 rubric closure (re-bless).
- `density: :compact` deep wiring (real multipliers) → Milestone C; B honors shallowly.
- Accent-as-text-on-dark (blue-300) → Milestone-C refinement.
- Genre presets / curated fonts / catalog / configurator → Milestone C; Studio → Milestone D;
  tabular figures / small-caps / OpenType → demand-gated (need new primitives).
- `default/0` value tuning, themed/dark gallery renders, support-matrix theming rows, `guides/theming.md`
  → Phase 123 (DEFAULT-02/03, CONTRACT-02).

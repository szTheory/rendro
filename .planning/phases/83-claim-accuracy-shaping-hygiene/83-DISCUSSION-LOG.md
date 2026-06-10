# Phase 83: Claim-Accuracy & Shaping Hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 83-claim-accuracy-shaping-hygiene
**Areas discussed:** Shaper selection mechanism, Public surface shape & tier, Complex-script gate policy, Golden-test posture
**Mode:** Advisor (minimal_decisive calibration) under yolo/autonomous config — all four gray areas auto-selected, researched by parallel `gsd-advisor-researcher` agents, recommended options locked per the user's research-first decision-handling profile (USER-PROFILE.md). No areas met the escalation bar (the public-behaviour decision itself was locked at the requirements level by HYG-01).

---

## Shaper selection mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit config + per-render opt | `config :rendro, shaper:` (default `Shaper.Simple`) + `shaper:` render opt; HarfBuzz module compile-gated but never auto-activated; loaded-but-unconfigured dep detected in the error message | ✓ |
| Auto-detect default | `Code.ensure_loaded?(HarfbuzzEx)` silently wins when present, config/opt override | |

**Locked choice:** Explicit selection, no auto-detect.
**Notes:** Auto-detection makes PDF bytes a function of the dependency lockfile (a transitive dep pulling `harfbuzz_ex` silently flips output) — directly contradicts the byte-determinism brand and the "explicit seams, never silent magic" adapter philosophy. Matches dominant Elixir idiom (Tesla adapters, Phoenix `:json_library`, Swoosh/Oban adapter config). Friction neutralized by errors-as-product: the `{:shaping_required, script}` error prints the exact config line when `harfbuzz_ex` is loaded but inactive.

---

## Public surface shape & stability tier

| Option | Description | Selected |
|--------|-------------|----------|
| Split layout | `Rendro.Text.Shaper` behaviour (`:stable`) + `Shaper.Simple` (`:stable`) + `Rendro.Adapters.HarfBuzz` (`:adapter`) | ✓ |
| Unified layout | Everything under `Rendro.Text.Shaper.*`, HarfBuzz impl tagged `:adapter` outside the `Rendro.Adapters.*` namespace | |

**Locked choice:** Split layout.
**Notes:** Only option requiring zero amendments to the namespace-defined Tier-2 contract in `guides/api_stability.md` (Tier-2 = `Rendro.Adapters.*`); reuses the existing `@adapter_files` conditional-compile machinery as-is; `:adapter` tier lets the HarfBuzz impl track `harfbuzz_ex` majors without a Rendro 2.0; the behaviour gets strict SemVer, which third-party shaping engines and the v2.7 demand gate need. Researcher verified the minimal-churn mechanical path (hidden-list line removal, tier tags + specs, manifest regen, `optional: true` flip).

---

## Complex-script gate policy

| Option | Description | Selected |
|--------|-------------|----------|
| Principled requires-shaping set | Curated script list derived from HarfBuzz complex-shaper dispatch families, gated inside `Shaper.Simple` keyed on the Bidi run's script tag | ✓ |
| Exact-four gate | Only `:arab`, `:hebr`, `:deva`, `:thai` error, checked in measure stage | |

**Locked choice:** Principled set, gate in `Shaper.Simple`, error through measure's existing tuple-halt path.
**Notes:** Exact-four would re-create Prawn-style silent garbage for Bengali (~270M speakers), Tamil, Khmer, Myanmar, Syriac, etc. — failing the errors-as-product and matrix-honesty rules the phase exists to enforce. Bidi already produces the script tag per run, so the broader gate costs little. The two `{:ok, glyphs} =` hard-matches in `measure.ex` must become `case`/`with`. HYG-05 matrix rows stay scoped to the four named families; runtime gate being broader is the honest direction of mismatch.

---

## Golden-test posture for the cluster-boundary fix

| Option | Description | Selected |
|--------|-------------|----------|
| Byte-freeze fork | Cluster-aware breaking only when HarfBuzz active; keep per-grapheme path for `Shaper.Simple` | |
| Uniform fix + deliberate re-bless | Shape runs everywhere; property test proves Simple-path byte-identity; consolidate HarfBuzz + ex_unicode shifts into one changelogged re-bless event | ✓ |

**Locked choice:** Uniform fix.
**Notes:** The freeze buys nothing — `Shaper.Simple` has no cross-grapheme effects (pure cmap+advance), so run-shaping is byte-identical on the pure path by construction; a permanent two-path fork in `measure.ex` would keep dead bug-compatible code alive and contradict the "refactor + fence" exit criterion. Only HarfBuzz-path goldens can shift, and only where old widths were objectively wrong; roadmap explicitly permits deliberate re-bless with changelog note.

## Claude's Discretion

- Module/file organization within the split layout; location of the requires-shaping script list constant.
- Telemetry event naming (preserve or deliberately migrate `[:rendro, :shaper, :missing_glyph]`).
- Edge-script pass/fail calls (Thaana, Ethiopic, Hangul jamo) — each documented.
- HarfBuzz temp-file caching strategy during the module move.

## Deferred Ideas

- Full complex-script shaping → conditional v2.7 (LNCH-03 demand gate); design in `.planning/research/ARCHITECTURE.md`.
- PDF.js render lane → recorded v2 requirement.

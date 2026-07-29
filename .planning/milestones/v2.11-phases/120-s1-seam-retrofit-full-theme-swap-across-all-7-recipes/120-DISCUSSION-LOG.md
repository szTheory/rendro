# Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes
**Areas discussed:** Colorless-recipe theming depth (1 user decision); 3 items locked from research + code evidence

---

## Colorless recipes (Receipt, BrandedInvoice) — theming depth

Both recipes have zero color literals today (implicit black-on-white via primitive
defaults). Note surfaced: Phase 121 dark mode requires their primary text to read
`theme.colors.ink` eventually — the only question was now vs. in 121.

| Option | Description | Selected |
|--------|-------------|----------|
| Seam text→ink now | Explicit `theme.colors.ink` reads on primary text now, default `{0,0,0}` → byte-identical. Themable in 120; Phase 121 dark mode "just works". Slightly larger blast radius, proven by fresh goldens. | ✓ |
| Minimal plumbing now, ink in 121 | Only whitelist `:theme` + thread value in 120; leave text implicit-black; defer ink seam to 121. Tightest 120 blast radius. | |
| Your call — pick per byte-safety | Let planning decide per-recipe by whichever keeps byte-identity cleanest. | |

**User's choice:** Seam text→ink now (Recommended).
**Notes:** Chosen so both recipes are genuinely themable in this phase and dark mode
in Phase 121 renders readable text without a later retrofit.

---

## Items locked from research + code evidence (not separately asked)

### Legacy `:palette` opt — preserve, override-wins
Alternatives: (a) retire `:palette` in favor of `:theme`; (b) preserve via final
`Map.merge(theme.colors, opts[:palette])`. **Chosen: (b) preserve, override-wins.**
Evidence: exactly one test dependent (`invoice_opts_threading_test.exs`) asserts a
`:palette` override changes footer color — preserve keeps it green with zero break.

### Per-literal role mapping — no-theme path byte-identical
Alternatives for non-black literals (Certificate `{34,34,34}`, Statement
`{245,245,245}`/`{0,0,0}`): (a) map to default `rule` and re-bless golden; (b) retrofit
default reproduces the exact literal, themed read maps to role, no re-bless.
**Chosen: (b).** No golden re-bless on the no-theme path; per-recipe defaults reproduce
today's literals (Certificate `rule` default = `{34,34,34}`).

### Typography threading boundary — colors only in 120
Alternatives: (a) also read `theme.typography.*` in 120 (PLUMB-02 wording); (b) thread
whole theme value, read only colors, defer typography reads to Phase 122 (ROADMAP split).
**Chosen: (b).** Thread once in 120; colors now, typography in 122 with no new plumbing.

---

## Claude's Discretion

- Exact `defp` seam helper naming per recipe.
- Whether seamed + retrofit recipes plan as one phase or split slices (retrofit commits
  MUST stay split from swap commits regardless).
- Ordering of the 4 retrofit commits.
- Which specific Receipt/BrandedInvoice elements count as "primary text" for the ink seam.

## Deferred Ideas

- `theme.typography.*` reads into `%Text{}` → Phase 122.
- Light/dark background-fill + `mode` → Phase 121.
- `default/0` tuning, gallery/dark renders, support-matrix `theming.*` rows,
  `guides/theming.md` → Phase 123.
- Retiring `:palette` entirely → future major only.

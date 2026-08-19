# Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-16
**Phase:** 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
**Areas discussed:** Preset distinctiveness, font curation, caller experience, brand-fixture lineup
**Method:** The user selected all four areas and delegated the choices to a one-shot, research-backed synthesis. Three typed `gsd-advisor-researcher` agents covered graphic design/fixtures, fonts/licensing, and Elixir API/DX. The primary agent reconciled their recommendations with the live code, current milestone research, official upstream font releases, the newer living `brand/` system, and applicable `prompts/` material.

---

## Preset Distinctiveness

| Option | Description | Selected |
|--------|-------------|----------|
| Gentle default variants | Small deltas from `Theme.default()` minimize layout risk, but genres collapse at thumbnail size and become palette aliases. | |
| Bespoke brand-led designs | Custom art direction per fixture maximizes surface variety, but mixes brand and preset identity, multiplies fonts/assets, and weakens deterministic comparability. | |
| Quantified genre grammar | Each genre has literal deltas across font roles, hierarchy, leading, rhythm, rules, radius, and neutrals while every recipe reads the same semantic roles. | ✓ |

**User's choice:** “Discuss/consider all” and make the recommendation on their behalf.

**Notes:** The synthesis selected quantified genre grammar. The exact five-preset token matrix is locked in CONTEXT D-10. Minimal-Mono stays `:comfortable` at 1.25 leading because the existing `:compact` resolver forces 1.1. Brutalist remains a complete P2, never a partial sixth preset.

---

## Font Curation

| Option | Description | Selected |
|--------|-------------|----------|
| Four Regular static faces | One unmodified upstream TTF per logical role; smallest truthful package and matches the current role-only authoring API. | ✓ |
| Selected Regular/Bold/Italic faces | Anticipates emphasis, but current `%Rendro.Text{}` exposes no public weight/style selection and the files would be dormant. | |
| Four full families | Uses the existing four-variant registry helper and is future-friendly, but ships 16 binaries with no current consumer path. | |
| Variable/instanced fonts | Flexible and potentially compact, but adds unsupported formats or a build-time font toolchain/provenance boundary. | |

**User's choice:** Delegated to the research synthesis.

**Notes:** Selected Inter 4.1, Source Sans 3.052R, Source Serif 4.005R, and JetBrains Mono 2.304 Regular static TTFs. Official sources show all four are OFL 1.1; this corrects the current milestone research's stale JetBrains Apache-2.0 classification. The files remain unmodified and render-time subsetting handles PDF size. Weight/style variants wait for a real public selection seam.

---

## Caller Experience

| Option | Description | Selected |
|--------|-------------|----------|
| Strict `preset/2` + explicit genre bridge | Canonical atoms, required accent, direct Theme result, actionable errors, and `document |> register_fonts(genre)` preserve purity and Elixir pipe ergonomics. | ✓ |
| Theme-derived registration | Avoids repeating the genre but makes arbitrary modified themes trigger hidden curated-role policy and blurs purity boundaries. | |
| Register all curated fonts | Simplifies the call but registers unused sources, hides dependencies, and weakens missing-role diagnostics. | |
| Permissive aliases/result tuples | Broader input acceptance or `{:ok, theme}` looks defensive, but is inconsistent with existing static constructors and increases public vocabulary. | |

**User's choice:** Delegated to the research synthesis with DX, least surprise, and consumer perspective emphasized.

**Notes:** The public contract is exact and pipeable. Two live-code contradictions were found and explicitly resolved: Certificate currently measures a preset role before post-build registration, and the raw-source guard rejects the very public function PRESET-01 requires. CONTEXT D-06 requires Certificate compatibility with no carve-out; D-07 permits and positively asserts exactly one thin delegation while preserving the guard vocabulary and scanning all remaining `theme.ex` source.

---

## Brand-Fixture Lineup

| Option | Description | Selected |
|--------|-------------|----------|
| One additional brand per domain | Meets the minimum and yields two brands including the existing fixture, but gives Phase 127 little curation choice. | |
| Two additional brands per domain | Produces three candidates per domain, supports a bounded 2-3-brand catalog, and remains cheap data-only work. | ✓ |
| Bespoke module/font system per brand | Maximizes fidelity, but violates brands-as-data, custom-font, package-size, and maintenance boundaries. | |

**User's choice:** Delegated to the research synthesis with JTBD, graphic design, accessibility, psychology, and domain-language lenses requested.

**Notes:** Twelve new fixtures are locked. Each brand carries realistic synthetic domain content, one curated accent, one canonical recommended preset, and a restrained local mark. Northline Logistics and Cedar Mutual intentionally span Invoice/Payslip to prove cross-document brand coherence. Other fixtures expand style and domain range without custom fonts or recipe branches.

---

## the agent's Discretion

- The user explicitly asked the agents to make a coherent one-shot recommendation so they would not need to choose among detailed alternatives.
- Planner discretion is limited to private helper organization, the internal Certificate metric remediation, realistic fixture values, deterministic logo-generation details, test partitioning, and evidence-backed micro-adjustments to token values.

## Deferred Ideas

- Phase 126 owns known dark/hierarchy/payslip visual defects and deeper goldens.
- Phase 127 owns the public catalog, bounded grid, and quality ratchet.
- Phase 128 owns the configurator, codegen, URL state, and Livebook.
- Phase 129 owns final docs/manifest/claim closure.
- Font variants and OpenType feature controls wait for a real public authoring seam.
- Live Studio and arbitrary theme editing remain Milestone D.

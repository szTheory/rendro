# Phase 128: Static configurator, theme codegen & Livebook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-18
**Phase:** 128-static-configurator-theme-codegen-livebook
**Areas discussed:** Missing-preview mapping, Canonical snippet contract, Generated module shape and CLI, Livebook learning flow

---

## Missing-preview mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Exact catalog cell or no preview | Only display a raster for an exact family/preset/accent/mode cell. Maximum truthfulness, but the sparse 32-cell catalog creates frequent empty states. | |
| Accent-only representative mapping | Preserve family/preset/mode, use a manifest row with a different catalog accent, and disclose both accents while copied code keeps the requested one. | ✓ |
| Broad ranked fallback | Cross accent, preset, mode, or family to almost always show a visually related raster. High availability, but misleading and unstable as catalog rows change. | |

**User's choice:** The user selected every area and delegated a one-shot expert recommendation. Accent-only representative mapping was recommended after codebase, UI/JTBD, ecosystem, accessibility, security, and truthful-claims research.
**Notes:** The resolver is exact → same family/preset/mode representative → none. It never uses color distance or crosses semantic dimensions. The canonical state remains the requested code. The literal first manifest cell is an unselectable null/default row, so malformed/empty URLs use the first manifest-ordered non-default cell that can populate all four controls.

---

## Canonical snippet contract

| Option | Description | Selected |
|--------|-------------|----------|
| `Theme.preset/2` only | Small and stable, but does not show recipe placement or the required curated-font registration step. | |
| Preset plus font registration | Makes document-owned font registration explicit, but still leaves recipe placement implicit. | |
| Preset plus recipe usage and font registration | Shows the complete working theme → recipe → font bridge while remaining compact enough for a copy button. | ✓ |
| Fully runnable fixture | Includes data and rendering, independently executable but too large and family-specific for the shared copy surface. | |

**User's choice:** Delegated to the expert recommendation; selected the working recipe fragment.
**Notes:** One Elixir formatter owns atoms, RGB tuple serialization, recipe mappings, and module source. A committed 504-record consumer index gives browser JavaScript complete strings to copy verbatim. Livebook adds runnable context around the same fragment.

---

## Generated module shape and CLI

| Option | Description | Selected |
|--------|-------------|----------|
| Literal `%Rendro.Theme{}` freeze | Freezes resolved tokens and makes dependency-driven token drift visible, but couples consumer source to evolving struct internals and creates large generated files. | |
| Preset-constructor wrapper | Generates a small named application boundary over the stable public constructor plus explicit font registration. | ✓ |
| Generated data/config file | Serializable and externally editable, but adds an unnecessary runtime loader/schema/deployment surface. | |

**User's choice:** Delegated to the expert recommendation; selected the wrapper after a dedicated cross-check against the earlier literal-freeze proposal and existing Phase-128 architecture research.
**Notes:** The command works with only the required preset/accent by deriving `<CurrentApp>.RendroTheme` and its path, while allowing `--module`/`--out`. It uses normal Mix conflict prompts, explicit `--force`, formatter-stable source, and a strictly read-only byte-exact `--check`. Generated `theme/0` has no runtime overrides.

---

## Livebook learning flow

| Option | Description | Selected |
|--------|-------------|----------|
| One focused preset section | Adds one complete themed invoice path to the existing tutorial with bounded execution and maintenance cost. | ✓ |
| Guided multi-preset progression | Teaches comparison well but repeats render/preview work and increases cognitive/maintenance load. | |
| Compact all-presets exploration | Enables scanning, but becomes a second configurator and invites controls, loops, and overclaim. | |
| Separate presets notebook | Isolates advanced material but duplicates setup and splits discoverability. | |

**User's choice:** Delegated to the expert recommendation; selected one focused additive section.
**Notes:** Use Invoice × Swiss × `#2C6BED` × light, the canonical snippet verbatim, one new deterministic render, PDF assertion, SHA/byte evidence, preview, and download. No Kino inputs, all-preset loop, catalog fetch, or new server path.

---

## the agent's Discretion

- Private formatter/helper names and AST/iodata implementation.
- Configurator JSON schema/file split and CSS/JS partitioning.
- Test-module organization and exact accessible status-region wording.
- Safe error handling for unusual umbrella layouts when no app namespace/path can be inferred.

## Deferred Ideas

- Interactive/all-presets Livebook exploration or a separate advanced notebook.
- Arbitrary-color and live-rendered Studio behavior in Milestone D.
- Cross-dimension inspiration fallback and broader catalog curation.
- Expanding the 32-cell catalog without a separate review/cost decision.

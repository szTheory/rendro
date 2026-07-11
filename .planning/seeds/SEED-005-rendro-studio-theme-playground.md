---
id: SEED-005
status: dormant
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: any milestone considering an interactive/admin/dev UI, a theme playground, LiveView tooling, or theming developer-experience — part of the Happy-Path program (optional; needs SEED-003/004; surface whenever an interactive theme/preview UI is considered)
scope: Large (full milestone; optional/deferrable)
part_of: "Happy-Path Home Runs program (Milestone D of 4 — optional; see SEED-003, SEED-004)"
---

# SEED-005: Rendro Studio — Optional Mountable Theme Playground (Milestone D)

An **optional, dev-only, mountable LiveView** dev tool that lets a developer browse the catalog, pick a
preset/theme/accent, **preview it live against their own accent color / fonts / data**, curate favorites,
and **copy the resulting `Rendro.Theme.preset(…)` code** (or generate a theme module) into their app.

**Milestone D of a 4-milestone program — the optional "power tool."** A (**[[SEED-002]]**) → B
(**[[SEED-003]]** theming) → C (**[[SEED-004]]** presets + catalog + *static* configurator) → D (this).
Depends on B + C. Full program plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

## Why This Matters

The user wants an interactive way to browse the catalog, pick a theme + colors, preview, favorite, and
copy code into their app — noting (correctly) that PDF rendering is CPU/memory intensive and that a PG
data model is NOT warranted (rendro is a compute library).

**Sanity-check outcome (researched across UX/prior-art/technical lenses):** the elegant shape is a
**hybrid, not one monolithic live studio**:
- The **static client-side configurator** over the pre-rendered catalog (in [[SEED-004]]) is the DEFAULT
  ("browse → pick → copy code") — zero server compute, no DB, CDN-cacheable. Covers ~90% of the need.
- **This seed (D)** is the OPTIONAL live path for developers who need to preview presets against **their
  own** accent/fonts/data in their dev environment. Because it's dev-only + single-user, compute cost is
  bounded and acceptable. This split keeps the common path free and honors "no DB, compute library."

Prior art the design leans on: **`Phoenix.LiveDashboard` + `Oban.Web`** (mountable router-macro dev tools,
optional dep, `on_mount` auth, ephemeral state, no DB); **Google Fonts** selection-tray → one combined
code snippet; **shadcn/tweakcn** configure → live preview → copy-code, shareable-URL state; **shadcn "own
your code"** export philosophy (a theme is just a struct, so copy-paste is natural).

## When to Surface

**Trigger:** surface whenever a milestone considers an **interactive/admin/dev UI, a theme playground,
LiveView tooling, or theming developer-experience**. Needs SEED-003/004 to exist — recommended after C,
but that's guidance, not a gate. Explicitly **optional/deferrable** — the static configurator (C) may
satisfy the need and D can be skipped or long-deferred; surface it so the option isn't silently lost.

## Scope Estimate

**Large — a full milestone; optional.** New optional LiveView dep + a full interactive UI + caching +
concurrency + codegen wiring.

### Design (locked, subject to D-kickoff refinement)

- **Mount idiom (à la LiveDashboard / Oban.Web):** `import Rendro.Studio.Router` + a single
  `rendro_studio "/rendro"` router macro. New `optional: true` `phoenix_live_view` dep (matches rendro's
  existing optional `phoenix`/`plug`/`oban` — verified in `mix.exs`); proven
  `if Code.ensure_loaded?(Phoenix.LiveView) do … else stub-that-raises end` guard (idiom in
  `lib/rendro/adapters/phoenix.ex`). **Never self-gate on env** — expose an `on_mount` auth hook and
  document the `if Mix.env() == :dev` wrap; the host app owns gating.
- **UX (preset-first, paradox-of-choice-safe):** big preset cards first; accent + token knobs behind an
  "advanced" panel; a **selection/favorites tray** (Google-Fonts-style) that accumulates
  document×preset×accent picks and emits **one consolidated** code block; copy-code is the hero action;
  config in URL state (shareable).
- **Cost discipline (the user's core concern):**
  - **Debounced render-on-apply** (not per-keystroke).
  - Cheap default preview = **inline PDF** via existing `Rendro.Adapters.Phoenix.preview_pdf/2` (browser
    renders natively — NO rasterization). PNG thumbnails only if needed (`Rendro.Adapters.Pdfium`, which
    shells out to external `pdfium-cli` — heavier).
  - **Content-hash preview cache** keyed on hash of (theme+preset+accent+fixture) — FREE because rendro is
    deterministic and `Rendro.render_to_artifact/2` already returns `%Rendro.Artifact{hash: <sha256>}`.
  - **Concurrency cap** (small `Task.Supervisor` pool; coalesce/cancel stale requests) so click-bursts
    can't OOM.
  - Favorites/state = ephemeral socket assigns + URL query string. **No database.**
- **Export parity:** same copy-snippet + `mix rendro.gen.theme` codegen as Milestone C, driven by the
  user's live config.

### Open decision (D-kickoff)

Ship the Studio as a **separate `rendro_studio` Hex package** vs. an **optional in-repo module** gated by
an optional `phoenix_live_view` dep. Lean: **separate package** (keeps LiveView + JS/asset build out of
the core compute library), but decide at kickoff.

## Breadcrumbs

- `lib/rendro/adapters/phoenix.ex` — `preview_pdf/2` (inline PDF, no raster) + the `if Code.ensure_loaded?`
  optional-dep guard idiom to reuse.
- `lib/rendro/adapters/pdfium.ex` — external `pdfium-cli` raster (only if PNG thumbnails needed).
- `lib/rendro/artifact.ex` (`Rendro.render_to_artifact/2` → `%Artifact{hash}`) — the determinism-backed
  hash the preview cache keys on.
- `mix.exs` — optional-dep pattern (`phoenix`/`plug`/`oban` are `optional: true`); add `phoenix_live_view`.
- `examples/phoenix_example/` — dependency-light demo app (no LiveView yet); candidate Studio host, needs
  LiveView/asset scaffolding.
- `lib/rendro/theme.ex` (from [[SEED-003]]), `lib/rendro/theme/presets.ex` +
  `lib/mix/tasks/rendro/gen/theme.ex` (from [[SEED-004]]) — the things the Studio configures + exports.
- New files: `Rendro.Studio.Router` + LiveView (likely a separate `rendro_studio` package). Related:
  [[SEED-003]], [[SEED-004]].

## Notes

Planted 2026-07-10 as the optional Milestone D of the Happy-Path Home Runs program. Deliberately split
from C so the free static configurator (the 90% path) doesn't wait on the heavier live tool. Confirms the
user's instinct that this is a compute library needing no PG model — all state is ephemeral (assigns +
URL).

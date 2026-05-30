---
phase: 78-public-api-surface-definition-cleanup
plan: "02"
subsystem: public-api-surface
tags: [moduledoc, exdoc, tier-tags, stable, adapter, mix-exs, groups-for-modules]
dependency_graph:
  requires: ["78-01"]
  provides: ["@moduledoc tags for all public modules", "before_closing_head_tag badge CSS/JS", "reconciled groups_for_modules"]
  affects: ["priv/public_api.json (Phase 78-03)", "Phase 79 contract test"]
tech_stack:
  added: []
  patterns: ["ExDoc @moduledoc tags: two-attribute form", "before_closing_head_tag CSS/JS injection"]
key_files:
  created: []
  modified:
    - lib/rendro.ex
    - lib/rendro/document.ex
    - lib/rendro/page.ex
    - lib/rendro/page_template.ex
    - lib/rendro/section.ex
    - lib/rendro/region.ex
    - lib/rendro/block.ex
    - lib/rendro/text.ex
    - lib/rendro/table.ex
    - lib/rendro/image.ex
    - lib/rendro/cell.ex
    - lib/rendro/row.ex
    - lib/rendro/component.ex
    - lib/rendro/font_registry.ex
    - lib/rendro/asset_registry.ex
    - lib/rendro/embedded_file_registry.ex
    - lib/rendro/running_content.ex
    - lib/rendro/error.ex
    - lib/rendro/sign.ex
    - lib/rendro/protect.ex
    - lib/rendro/recipes.ex
    - lib/rendro/adapters/phoenix.ex
    - lib/rendro/adapters/oban/render_worker.ex
    - lib/rendro/adapters/threadline.ex
    - lib/rendro/adapters/mailglass.ex
    - lib/rendro/adapters/accrue.ex
    - lib/rendro/sign/adapter.ex
    - lib/rendro/protect/adapter.ex
    - lib/rendro/storage.ex
    - lib/rendro/storage/local.ex
    - lib/rendro/inspector.ex
    - lib/rendro/telemetry.ex
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/branded_invoice.ex
    - lib/rendro/recipes/statement.ex
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/certificate.ex
    - mix.exs
decisions:
  - "Used CRITICAL_PLAN_CORRECTION two-attribute @moduledoc form throughout (separate @moduledoc tags: [...] line after closing prose, not appended to prose attribute)"
  - "Rendro.Metadata skipped in Task 1 — already had tags: [:stable] from 78-01 (be5f5cb)"
  - "FontRegistry and AssetRegistry moved from Registries group to Core Builder API (D-04 stable tier)"
  - "Error moved from Inspection & Observability to Core Builder API (D-04 stable tier)"
  - "Storage and Storage.Local added as new Storage group in groups_for_modules"
  - "PyHanko and Pdfsig moved from Signing to Ecosystem Adapters"
metrics:
  duration: "8 minutes"
  completed: "2026-05-30"
  tasks_completed: 3
  files_modified: 38
---

# Phase 78 Plan 02: @moduledoc Tier Tags + Badge Injection Summary

**One-liner:** Applied `@moduledoc tags: [:stable]` / `[:adapter]` to all 38 public Rendro modules using the ExDoc 0.40 two-attribute form, and updated `mix.exs` to inject colored tier badges and reconcile `groups_for_modules` with the D-04/D-05 tier lists.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add @moduledoc tags: [:stable] to 22 Tier-1 stable modules | 61e303d | 21 files (metadata.ex already tagged by 78-01) |
| 2 | Add @moduledoc tags: [:adapter] to 16 Tier-2 adapter modules | 95b7597 | 16 files |
| 3 | Update mix.exs — badge CSS/JS injection + groups_for_modules reconciliation | cf5583e | mix.exs |

## Verification Results

### Code.fetch_docs tag verification (22 stable modules)

All 22 stable modules confirmed `tags: [:stable]` via `Code.fetch_docs/1 |> elem(5) |> Map.get(:tags)`:
Rendro, Document, Page, PageTemplate, Section, Region, Block, Text, Table, Image, Cell, Row,
Component, FontRegistry, AssetRegistry, EmbeddedFileRegistry, RunningContent, Error, Metadata,
Sign, Protect, Recipes — all `[:stable]`.

### Code.fetch_docs tag verification (adapter-seam modules — D-08 explicit assertions)

All six explicitly required adapter-seam modules confirmed `tags: [:adapter]`:
- `Rendro.Telemetry` → `[:adapter]`
- `Rendro.Inspector` → `[:adapter]`
- `Rendro.Storage` → `[:adapter]`
- `Rendro.Storage.Local` → `[:adapter]`
- `Rendro.Sign.Adapter` → `[:adapter]`
- `Rendro.Protect.Adapter` → `[:adapter]`

### Conditional guard adapters (tagged inside if Code.ensure_loaded? blocks)

Phoenix, Oban.RenderWorker, Threadline, Mailglass, Accrue — all tagged `[:adapter]` inside
their conditional guard blocks (4-space indented moduledoc).

### Recipe implementations

Invoice, BrandedInvoice, Statement, Receipt, Certificate — all `[:adapter]` per D-06 rationale.

### Compilation

- `mix compile --warnings-as-errors` exits 0 — no warnings or errors introduced
- `mix docs` exits 0 — generated `doc/index.html`, `doc/llms.txt`, `doc/Rendro.epub`
  (One pre-existing warning about `Rendro.Format` hidden reference in statement.ex — not introduced by this plan)

### mix.exs acceptance criteria

- `grep -c "before_closing_head_tag" mix.exs` = 3 (key in docs/0 + function head + fallback)
- `tier-stable` and `tier-adapter` CSS class names present in `before_closing_head_tag/1`
- Cell, Row, Component, Metadata all in Core Builder API group

## Deviations from Plan

### Auto-fixed Issues

None.

### Adjustments (CLAUDE.md/plan intent alignment)

**1. [Adjustment] Moved Error, FontRegistry, AssetRegistry to Core Builder API**
- **Found during:** Task 3
- **Issue:** `Rendro.Error` was in "Inspection & Observability"; `FontRegistry` and `AssetRegistry` were in a separate "Registries" group. All three are D-04 stable tier.
- **Fix:** Moved all three to "Core Builder API" per PATTERNS.md `groups_for_modules additions` section. Removed separate "Registries" group (FontRegistry/AssetRegistry absorbed into Core Builder API).
- **Files modified:** mix.exs

**2. [Adjustment] Added Storage group for Storage + Storage.Local**
- **Found during:** Task 3
- **Issue:** `Rendro.Storage` and `Rendro.Storage.Local` were not in any `groups_for_modules` group.
- **Fix:** Added a new "Storage" group to make them discoverable in ExDoc navigation.
- **Files modified:** mix.exs

## Known Stubs

None. All changes are metadata attributes (`@moduledoc tags: [...]`) and static CSS/JS strings. No data flows or UI rendering involved.

## Threat Flags

None. All edits are `@moduledoc` metadata and static `before_closing_head_tag/1` string. No new attack surface as confirmed in the plan's STRIDE threat register (T-78-02-01, T-78-02-02 both `accept`).

## Self-Check: PASSED

---
phase: 84-drawn-path-primitive-visible-polish
plan: "04"
subsystem: certificate-border-frame
tags: [certificate, border, path, validate, frame, wave-3]
dependency_graph:
  requires:
    - 84-02 (Rendro.Path struct + pipeline dispatch, %Rendro.Block{})
  provides:
    - lib/rendro/recipes/certificate.ex (border: option, validate_border!/2, page_template :frame region, sections :certificate_frame, document pass-through)
  affects:
    - test/rendro/recipes/certificate_test.exs (C15-C20 now GREEN)
tech_stack:
  added: []
  patterns:
    - "validate_border!/2 with closed key allowlist, color delegation to Rendro.Color.validate/1, inset bounds check"
    - "resolve_frame_opts/7: geometry-derived defaults (short = min(pw,ph), inset = 0.5 * min(margins), weight = max(1.0, short/400))"
    - "anchor: :fixed :frame region prepended by paginate.ex apply_page_template — layered under body text with no z-index machinery"
    - "%Rendro.Path{ops: [{:rect,0,0,w,h}], stroke: %{color:, width:}} dogfoods Plan 02 pipeline"
    - "border: true/map/false mirrors brand: idiom from branded_invoice.ex"
key_files:
  created: []
  modified:
    - lib/rendro/recipes/certificate.ex
decisions:
  - "resolve_frame_opts/7 is extracted as private helper so page_template and sections share identical geometry-derivation logic without duplication"
  - "document/2 uses _pw/_ph prefixes to suppress unused-variable warning when only margins are needed for min_margin computation"
  - "Frame section uses region: :frame (not target:) — matches Rendro.Section struct field name"
  - "validate_border! runs before page_template construction (fail-early); margin computation duplicated in document/2 to avoid calling page_template twice"
metrics:
  duration: "25m (approx)"
  completed: "2026-06-10"
  tasks_completed: 1
  tasks_total: 1
  files_created: 0
  files_modified: 1
---

# Phase 84 Plan 04: Certificate Border Frame Summary

**One-liner:** Certificate.document/2 border: frame option — geometry-derived keyline dogfooding %Rendro.Path{}, anchored :frame region, validate_border!/2 with closed allowlist + color/inset validation, zero hardcoded numerics.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | certificate.ex border option — validate_border!, page_template, sections, document | db94cb3 | lib/rendro/recipes/certificate.ex |

## What Was Built

### Task 1: certificate.ex border option

**`lib/rendro/recipes/certificate.ex`** — all changes additive-only; `border: false` (default) is byte-identical to prior output.

**`validate_border!/2`** private function:
- Closed key allowlist `[:style, :color, :inset, :gap, :weight]` — unknown keys raise `ArgumentError` with What/Where/Why/Next naming the bad key and valid set
- `:style` must be `:single` or `:double`
- `:color` delegates to `Rendro.Color.validate/1` — canonical hex-footgun error message library-wide; on `{:error, msg}` raises `ArgumentError, msg`
- `:inset` must be numeric and `< min_margin` — violation raises `ArgumentError` naming the safe max: "inset #{inset} would cross into content area. Safe maximum: less than #{min_margin}"
- `:weight` and `:gap` must be numeric
- Returns `:ok` on success

**`resolve_frame_opts/7`** private helper:
- Takes `(border, pw, ph, ml, mr, mt, mb)`, normalizes `true → %{}`
- `short = min(pw, ph)`, `default_inset = 0.5 * Enum.min([ml,mr,mt,mb])`, `default_weight = max(1.0, short / 400)`, `default_color = {34, 34, 34}`
- Merges border_map overrides over defaults; returns `%{style:, color:, inset:, weight:, gap:}`

**`page_template/1`** extension:
- Extracts `border = Keyword.get(opts, :border, false)`
- When truthy: calls `resolve_frame_opts`, builds `:frame` region with `anchor: :fixed`, `x: inset, y: inset, width: pw-2*inset, height: ph-2*inset` — all geometry-derived
- Appends `:frame` region after `:body` in the regions list
- When falsy: regions list unchanged (only `:body`) — byte-identical output

**`sections/2`** extension:
- When `border` truthy: calls `resolve_frame_opts`, computes `region_w/h`, builds `%Rendro.Block{content: %Rendro.Path{ops: [{:rect, 0, 0, region_w, region_h}], stroke: %{color:, width:}}}` — Pitfall 5 guard: block-relative `(0,0)` origin, NOT inset values (region placement handles positioning via paginate.ex)
- Adds `Rendro.section(name: :certificate_frame, region: :frame, content: [frame_block])` to sections list
- When falsy: no `:certificate_frame` section added

**`document/2`** extension:
- Calls `validate_border!(border_map, min_margin)` before `page_template/1` (fail-early)
- Passes `border:` through to both `page_template/1` and `sections/2`

## Deviations from Plan

None — plan executed exactly as written.

The `_pw`/`_ph` prefix deviation (suppress unused-variable warning in `document/2`) is a minor cleanup consistent with Elixir conventions.

## Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| mix test test/rendro/recipes/certificate_test.exs | PASS | 35/35 — C1-C20 all GREEN |
| mix test test/rendro/deterministic_test.exs | PASS | 12 tests + 3 properties — byte-identity preserved |
| mix test (full suite) | PASS | 1061 tests, 11 failures — all from other plans' RED stubs (table_borders_test.exs, path_claims_test.exs) |
| paginate.ex unchanged | PASS | git diff lib/rendro/pipeline/paginate.ex shows no changes |
| Geometry-derived proof | PASS | A4-landscape frame width 769.89 ≠ US-Letter-landscape frame width 720.0 |
| Inset formula | PASS | frame.x = 36.0 = 0.5 * 72 (default margins all 72pt) |
| C15: border: true → re+S | PASS | PDF contains "re" and "S" operators |
| C16: border: false → byte-identical | PASS | Two deterministic renders identical; explicit false = no-border default |
| C17: A4 vs Letter frame width differs | PASS | 769.89 vs 720.0 (difference > 0.01) |
| C18: inset formula verified | PASS | frame.x = frame.y = 36.0 = 0.5 * min(72,72,72,72) |
| C19: custom color in stream | PASS | "1.0000 0.0000 0.0000 RG" appears for border: %{color: {255,0,0}} |
| C20: validate_border! rejects bad input | PASS | unknown keys, hex color, inset >= margin all raise ArgumentError |

## Known Stubs

None — all certificate border functionality is fully wired.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All trust boundaries are covered by `validate_border!/2` per the threat model:

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-84-10 Closed allowlist (unknown keys) | validate_border! rejects unknown keys with ArgumentError naming valid set | DONE |
| T-84-11 Inset bounds check | inset >= min_margin raises ArgumentError naming safe max | DONE |
| T-84-12 Color validation | Delegates to Rendro.Color.validate/1 — canonical hex-footgun message | DONE |

## Self-Check: PASSED

Files verified present:
- lib/rendro/recipes/certificate.ex: FOUND (validate_border!/2, resolve_frame_opts/7, page_template :frame region, sections :certificate_frame, document border: pass-through)

Commits verified:
- db94cb3: feat(84-04): add border: frame option to Certificate recipe

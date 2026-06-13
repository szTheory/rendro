---
phase: 84
slug: drawn-path-primitive-visible-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 84 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (standard library; no new dependency) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/rendro/path_test.exs test/rendro/table_borders_test.exs test/rendro/recipes/certificate_test.exs test/rendro/deterministic_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|-------------|----------|-----------|-------------------|-------------|--------|
| PATH-01 | Path | PATH-01 | `%Rendro.Path{}` `:rect` op renders `re`/`S` ops | unit | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-01 | Path | PATH-01 | Two renders of same Path doc are byte-identical | determinism | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-01 | Path | PATH-01 | Path coords use `format_num` (≤4 decimals) | unit | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-01 | Path | PATH-01 | `:rounded_rect` decomposes to `c` ops via kappa `0.5522847498` | unit | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-01 | Path | PATH-01 | paint-op selection: stroke→`S`, fill→`f`, both→`B`, neither→`n` | unit | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-01 | Color | PATH-01 | D-03 retrofit: Text black-text output stays byte-identical | regression | `mix test test/rendro/deterministic_test.exs -x` | ✅ extend | ⬜ pending |
| PATH-01 | Color | PATH-01 | `Rendro.Color.validate/1` raises `ArgumentError` w/ hex-footgun msg | unit | `mix test test/rendro/path_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | `borders: :all` renders `re`+`S` ops | unit | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | No `borders` field → byte-identical to pre-84 baseline | regression | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | `borders: :none`/`false` → byte-identity | regression | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | `[:outer, :rows]` → perimeter + horizontal rules only | unit | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | Draw-once: no doubled segments at shared boundaries | unit | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-02 | Table | PATH-02 | `header_fill: {r,g,b}` emits `rg…re…f` band | unit | `mix test test/rendro/table_borders_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | `border: true` renders `re`/`S` frame | unit | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | `border: false` (default) byte-identical to baseline | regression | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | Frame coords differ A4 vs US-Letter (geometry-derived) | unit | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | `inset = 0.5*min(margins)` (not hardcoded) | unit | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | `border: %{...}` map merges over defaults | unit | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-03 | Certificate | PATH-03 | `validate_border!` rejects bad keys/color/inset | unit | `mix test test/rendro/recipes/certificate_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-04 | Matrix | PATH-04 | `support_matrix.json` has `path_primitive` w/ deferral rows | docs-contract | `mix test test/docs_contract/path_claims_test.exs -x` | ❌ W0 | ⬜ pending |
| PATH-04 | Matrix | PATH-04 | `public_api.json` contains `Rendro.Path` + `Rendro.path/2` | docs-contract | `mix test test/docs_contract/public_api_contract_test.exs -x` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/path_test.exs` — stubs for PATH-01 (rect/line/curve/rounded_rect determinism, paint-op selection, Color validation)
- [ ] `test/rendro/table_borders_test.exs` — stubs for PATH-02 (borders atoms, byte-identity, draw-once, header_fill)
- [ ] `test/rendro/recipes/certificate_test.exs` — new cases for PATH-03 (frame render, byte-identity, multi-size geometry, validation) appended to existing file
- [ ] `test/docs_contract/path_claims_test.exs` — PATH-04 support-matrix lane
- [ ] Lane self-registration entry in `scripts/verify_docs.exs` for the path claims lane

*Existing `deterministic_test.exs` and `public_api_contract_test.exs` are extended, not created.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rendered rectangle/borders/frame are *visibly* present in rasterized output | PATH-01/02/03 | Visual confirmation of the golden-PNG lane output | Inspect raster golden PNGs produced by the determinism harness; confirm visible rect/cell-rules/keyline frame |

*All structural assertions (content-stream ops, byte-identity, coord precision) are automated; only the visual "looks right" confirmation is manual and is backstopped by golden-PNG fixtures.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

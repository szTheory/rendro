---
phase: 73
slug: page-numbering-running-region-primitive
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-30
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData (ExUnitProperties for property tests) |
| **Config file** | `mix.exs` — `preferred_envs: [ci: :test]`; no separate test config |
| **Quick run command** | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro/deterministic_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds (quick subset ~5s) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

> Task IDs are finalized by the planner; this map binds each phase requirement to its test type and command. The planner MUST ensure every `<task>` carries an `<automated>` verify drawn from this map (or a Wave 0 dependency).

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PAGE-01 | `{{total_pages}}` renders real total on every page in a single pass | integration | `mix test test/rendro/flow_test.exs` | ✅ (flow_test.exs:124) | ✅ green |
| PAGE-01 | `replace_page_numbers/2` (with total) substitutes `{{total_pages}}` in Text + MeasuredText | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ | ✅ green |
| PAGE-02 | `fn {pn, tp} -> content end` block evaluates per-page with correct args | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ (paginate_test.exs:685) | ✅ green |
| PAGE-02 | `Rendro.page_number/1` helper produces correct token block | unit | `mix test test/rendro_builders_test.exs` | ✅ (rendro_builders_test.exs:360) | ✅ green |
| PAGE-02 | `suppress_on: :first` suppresses footer on page 1 but not page 2 | integration | `mix test test/rendro/flow_test.exs` | ✅ (flow_test.exs:146) | ✅ green |
| PAGE-02 | Suppressed page keeps same `body_capacity` as non-suppressed page | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ (paginate_test.exs:772) | ✅ green |
| PAGE-03 | `body_capacity` = `body_h − header_h − footer_h` for non-zero footer | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ | ✅ green |
| PAGE-03 | `flow_layout/1` fallback also subtracts header/footer from `body_capacity` | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ (paginate_test.exs:908, WR-01) | ✅ green |
| PAGE-03 | Body blocks do not overlap footer region (`y + height <= footer.y`) | integration | `mix test test/rendro/flow_test.exs` | ✅ (flow_test.exs:233) | ✅ green |
| PAGE-04 | D-11(a): byte-identical two renders with a running footer | unit | `mix test test/rendro/deterministic_test.exs` | ✅ (deterministic_test.exs:190) | ✅ green |
| PAGE-04 | D-11(b): `body_capacity` identical for 9-page vs 100+-page doc | unit | `mix test test/rendro/deterministic_test.exs` | ✅ | ✅ green |
| PAGE-04 | D-11(c): page count + per-page block assignment identical with `{{total_pages}}` vs static wide placeholder | unit | `mix test test/rendro/deterministic_test.exs` | ✅ (deterministic_test.exs:209) | ✅ green |
| PAGE-04 | D-11(d): `replace_page_numbers/2` leaves `MeasuredText.lines` geometry + block `height` unchanged | unit | `mix test test/rendro/deterministic_test.exs` | ✅ (deterministic_test.exs:231) | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

New test scaffolding that must exist before/alongside implementation tasks:

- [x] New `describe "running-region determinism (D-11)"` block in `test/rendro/deterministic_test.exs` — covers D-11 (a)–(d) (line 190)
- [x] New `page_number/1` helper tests in `test/rendro_builders_test.exs` (line 360)
- [x] New per-page function (`fn {pn, tp}`) evaluation tests in `test/rendro/pipeline/paginate_test.exs` (line 685)
- [x] New suppression selector tests in `test/rendro/flow_test.exs` (line 146) and `test/rendro/pipeline/paginate_test.exs` (line 772)
- [x] New `flow_layout/1` fallback `body_capacity` test in `test/rendro/pipeline/paginate_test.exs` (line 908, WR-01 regression)
- [x] New body-does-not-overlap-footer integration test in `test/rendro/flow_test.exs` (line 233)

*Existing infrastructure (ExUnit + StreamData, `deterministic: true` contract, existing `measure_test`/`paginate_test`/`flow_test`/`deterministic_test`) covers all other requirements — no new framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification — the determinism contract (byte-identity, geometry invariance) is fully assertable in ExUnit.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-30

---

## Validation Audit 2026-05-30

Audited via `/gsd-validate-phase 73` (top-level workflow, run as part of phase 77 / plan 77-03). Coverage verified by execution — all 13 Per-Task Map rows map to tests that exist on disk and run green.

| Metric | Count |
|--------|-------|
| Requirements (Per-Task Map rows) | 13 |
| COVERED (green) | 13 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 0 |
| Tests generated | 0 (all coverage already present from execution) |

**Test run:** `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro/deterministic_test.exs test/rendro_builders_test.exs` → **3 properties, 120 tests, 0 failures**.

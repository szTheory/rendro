---
phase: 85
slug: deterministic-raster-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 85 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in, Elixir 1.19) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/adapters/pdfium_test.exs test/docs_contract/raster_claims_test.exs` |
| **Full suite command** | `mix test` (or `mix ci`) |
| **Raster snapshot command** | `mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` |
| **Estimated runtime** | ~30 seconds (full suite, raster snapshot excluded by default) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/adapters/pdfium_test.exs test/docs_contract/raster_claims_test.exs`
- **After every plan wave:** Run `mix ci` (full suite, raster snapshot tag excluded)
- **Before `/gsd:verify-work`:** Full suite green (`mix ci`) AND raster snapshot advisory lane green in CI
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 85-XX | — | 0 | RAST-01 | T-85-01 | tmp PDF written 0o600, cleaned up after render | unit | `mix test test/rendro/adapters/pdfium_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-01a | — | `render/2` with pdfium-cli absent → `{:error, {:missing_executable, ...}}` | unit | `mix test test/rendro/adapters/pdfium_test.exs` | ✅ extend | ⬜ pending |
| 85-XX | — | 1 | RAST-01b | — | `render/2` with mock runner → `{:ok, [png_binary]}` list | unit | `mix test test/rendro/adapters/pdfium_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-01c | — | `pdfium_pin.json` validates (version + sha256 keys present) | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-02a | — | Hash-equality fast path: golden hash matches (no pdfium-cli) | unit | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-02b | T-85-02 | Bless guard: `MIX_RASTER_BLESS=true` outside `GITHUB_ACTIONS` raises | unit | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-02c | — | Raster snapshot tests run with `--include raster_snapshot` | integration | `mix test --include raster_snapshot` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-03a | — | Advisory lane NOT in `required_contexts` (guardrails JSON) | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-03b | — | `viewer_kind: "pdfium-render"` valid per schema | unit | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ extend | ⬜ pending |
| 85-XX | — | 1 | RAST-03c | T-85-03 | GUI-viewer rows do NOT carry `viewer_kind: "pdfium-render"` | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ W0 | ⬜ pending |
| 85-XX | — | 1 | RAST-03d | — | `support_matrix.json` has `raster` section w/ correct boundary declarations | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ W0 | ⬜ pending |

*Task IDs assigned by planner; this map is the requirement→test contract the plans must satisfy.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/adapters/pdfium_raster_snapshot_test.exs` — stubs for RAST-01b, RAST-02a, RAST-02b, RAST-02c
- [ ] `test/docs_contract/raster_claims_test.exs` — stubs for RAST-01c, RAST-03a, RAST-03c, RAST-03d
- [ ] `priv/raster_refs/` directory (with `.gitkeep` initially) — populated by bless run in CI only
- [ ] `priv/pdfium_pin.json` — pinned version + sha256 for the raster lane binary
- [ ] ExUnit infrastructure already present — no framework install needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden PNG refs blessed in containerized CI | RAST-02 | Refs are platform/font-stack dependent; blessing only valid inside the pinned CI container, never on dev laptops | Trigger the CI bless workflow (`MIX_RASTER_BLESS=true` set only when `GITHUB_ACTIONS=true`); commit resulting `priv/raster_refs/*.sha256` |
| Advisory lane does not gate engine merges | RAST-03 | Requires observing real GitHub branch-protection behavior on a PR with a failing/missing raster lane | Open a PR where the raster-advisory job fails or pdfium-cli download fails; confirm the four required checks (`test`, `signing-live-proof`, `release-proof`, `long-lived-live-proof`) still allow merge |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

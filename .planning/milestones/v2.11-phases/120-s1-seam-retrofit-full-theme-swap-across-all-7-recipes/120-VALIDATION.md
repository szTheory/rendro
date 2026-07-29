---
phase: 120
slug: s1-seam-retrofit-full-theme-swap-across-all-7-recipes
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
---

# Phase 120 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 120-RESEARCH.md § Validation Architecture (HIGH confidence, live-verified).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`use ExUnit.Case, async: true`) |
| **Config file** | `test/test_helper.exs`; goldens under `priv/goldens/<family>/<dim>.sha256` |
| **Quick run command** | `mix test test/rendro/recipes/<recipe>_byte_identity_test.exs test/rendro/recipes/<recipe>_opts_threading_test.exs` |
| **Full suite command** | `mix test` |
| **Golden bless (human-gated)** | `MIX_GOLDEN_BLESS=true mix test <file>` |
| **Estimated runtime** | ~1s per recipe file; full suite < 10s (baseline 78 tests, 0 failures) |

---

## Sampling Rate

- **After every task commit:** Run the touched recipe's `*_byte_identity_test.exs` + `*_opts_threading_test.exs` (< 1s).
- **After every plan wave:** Run `mix test test/rendro/edge_matrix_test.exs test/rendro/recipes/` (byte goldens + all recipe tests).
- **Before `/gsd-verify-work`:** Full `mix test` must be green.
- **Max feedback latency:** ~10 seconds (full suite).

---

## Per-Task Verification Map

> Task IDs are provisional — reconcile against PLAN.md task numbering after planning. The Req → command mapping is authoritative.

| Req ID | Behavior | Wave | Test Type | Automated Command | File Exists | Status |
|--------|----------|------|-----------|-------------------|-------------|--------|
| PLUMB-01 | 4 retrofit recipes render byte-identically after seam (fresh frozen sha256, retrofit commit) | 1 | golden/unit | `mix test test/rendro/recipes/{statement,certificate,receipt,branded_invoice}_byte_identity_test.exs` | ✅ all 4 present | ✅ green |
| PLUMB-01 | Existing matrix goldens stay green through retrofit (no re-bless) | 1 | golden | `mix test test/rendro/edge_matrix_test.exs` | ✅ | ✅ green |
| PLUMB-02 | `:theme` threads all 3 rungs; `page_template` no KeyError; `:palette` override wins (D-01) | 2 | unit | `mix test test/rendro/recipes/*_opts_threading_test.exs` | ✅ 7/7 present w/ `:theme` cases | ✅ green |
| PLUMB-02 | No inline `{r,g,b}` literal remains in section builders (roles only) | 2 | source-scan | `mix test test/rendro/recipes/no_inline_color_literals_test.exs` | ✅ present | ✅ green |
| PLUMB-03 | `document(data)` no-theme = v2.10 bytes for all 7 recipes | 1–2 | golden | `mix test test/rendro/edge_matrix_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ✅ 7/7 (branded_invoice net-new golden) | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/rendro/recipes/statement_byte_identity_test.exs` — freezes retrofit toy sha256 (PLUMB-01)
- [x] `test/rendro/recipes/certificate_byte_identity_test.exs` — retrofit toy sha256, incl. `border: true` `{34,34,34}` frame case (PLUMB-01, stress case)
- [x] `test/rendro/recipes/receipt_byte_identity_test.exs` — retrofit toy sha256 (PLUMB-01)
- [x] `test/rendro/recipes/branded_invoice_byte_identity_test.exs` — **net-new golden** (PLUMB-01/03; not in edge_matrix)
- [x] `*_opts_threading_test.exs` for all 7 recipes with `:theme` cases (PLUMB-02)
- [x] source-scan test `no_inline_color_literals_test.exs` asserting no inline color literal remains in section builders (PLUMB-02)
- [x] Framework install: none — ExUnit + golden infra already present.

*Load-bearing note: the golden bless step is human-gated (`MIX_GOLDEN_BLESS=true`). Wave 0 stubs establish the frozen sha256 baseline BEFORE any theme wiring, so the retrofit commit proves byte-identity independently (split-commit discipline).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh retrofit sha256 goldens are correct at bless time | PLUMB-01 | Blessing a golden is a human trust decision (`MIX_GOLDEN_BLESS=true`) — the value being frozen must match today's literal output | Bless against the un-seamed HEAD render; confirm sha256 unchanged after seam applied with default palette |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (4 byte-identity tests + threading tests + source-scan)
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated — 2026-07-28

---

## Validation Audit 2026-07-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 3 requirements (PLUMB-01/02/03) fully covered by automated tests. Re-ran the phase's validation suite: `mix test *_byte_identity_test.exs *_opts_threading_test.exs no_inline_color_literals_test.exs edge_matrix_test.exs` → **149 tests, 0 failures** (~1.4s). The draft Per-Task Map was stale from plan time (all rows "pending", test files marked "❌ W0 (new)"); execution created all 7 byte-identity + 7 opts-threading + source-scan test files and they run green. Reconciled to `status: validated`, `nyquist_compliant: true`, `wave_0_complete: true`. No auditor needed — no MISSING/PARTIAL gaps.

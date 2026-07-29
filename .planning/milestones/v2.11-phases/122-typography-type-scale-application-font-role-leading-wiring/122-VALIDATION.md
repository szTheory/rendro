---
phase: 122
slug: typography-type-scale-application-font-role-leading-wiring
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
validated: 2026-07-28
---

# Phase 122 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | none — existing infrastructure covers all phase requirements |
| **Quick run command** | `mix test test/rendro/recipes/ test/rendro/edge_matrix_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~1.5s scoped · ~9s full suite |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/recipes/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~9 seconds (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 122-01 | 01 | 1 | TYPE-01 | — | Invoice type scale materialized in `defp typography/1`, threaded into every `%Text{size}`, one display anchor | unit | `mix test test/rendro/recipes/invoice_byte_identity_test.exs test/rendro/recipes/invoice_opts_threading_test.exs` | ✅ | ✅ green |
| 122-01 | 01 | 1 | TYPE-02 | — | Unregistered font role raises `{:unknown_text_font, _}`, never a silent Helvetica substitute | unit | `mix test test/rendro/recipes/invoice_typography_test.exs` | ✅ | ✅ green |
| 122-01 | 01 | 1 | TYPE-03 | — | `default/0` scale/leading a metric no-op — no-theme byte-identity preserved | unit | `mix test test/rendro/recipes/invoice_byte_identity_test.exs` | ✅ | ✅ green |
| 122-02 | 02 | 1 | TYPE-01 | — | Statement/Receipt/Payslip scales materialized + threaded, one display anchor each | unit | `mix test test/rendro/recipes/{statement,receipt,payslip}_byte_identity_test.exs test/rendro/recipes/{statement,receipt,payslip}_opts_threading_test.exs` | ✅ | ✅ green |
| 122-02 | 02 | 1 | TYPE-02 | — | Representative raise-path (Statement): unregistered role raises `{:unknown_text_font, _}` | unit | `mix test test/rendro/recipes/statement_typography_test.exs` | ✅ | ✅ green |
| 122-02 | 02 | 1 | TYPE-03 | — | No-theme byte-identity across Statement/Receipt/Payslip (Payslip `"Helvetica"` string preserves B612 fallback) | unit | `mix test test/rendro/recipes/{statement,receipt,payslip}_byte_identity_test.exs` | ✅ | ✅ green |
| 122-03 | 03 | 1 | TYPE-01 | — | BrandedInvoice/Certificate/Ticket scales materialized; measurement-coupled Certificate centering; brand ⊥ theme font exception | unit | `mix test test/rendro/recipes/{branded_invoice,certificate,ticket}_byte_identity_test.exs test/rendro/recipes/{branded_invoice,certificate,ticket}_opts_threading_test.exs` | ✅ | ✅ green |
| 122-03 | 03 | 1 | TYPE-02 | — | Representative raise-path (Ticket): unregistered role raises `{:unknown_text_font, _}` | unit | `mix test test/rendro/recipes/ticket_typography_test.exs` | ✅ | ✅ green |
| 122-03 | 03 | 1 | TYPE-03 | — | No-theme byte-identity across the 3 RISK recipes; themed goldens re-blessed intentionally, no-theme ZERO re-bless | unit | `mix test test/rendro/recipes/{branded_invoice,certificate,ticket}_byte_identity_test.exs` | ✅ | ✅ green |
| 122-04 | 04 | 1 | TYPE-01 | — | Static-scan teeth test fails the build on any re-introduced inline numeric `size:` literal across all 7 recipes | unit | `mix test test/rendro/recipes/no_inline_size_literals_test.exs` | ✅ | ✅ green |
| 122-04 | 04 | 1 | TYPE-03 | — | Full-suite phase gate: 7 byte-identity goldens + edge_matrix byte-identical, ZERO re-bless | unit | `mix test test/rendro/recipes/ test/rendro/edge_matrix_test.exs` | ✅ | ✅ green |
| 122-05 | 05 | 1 | TYPE-02 | — | Themed Payslip renders own masked-middot + accented data via `render/2` (CR-01); theme branch remaps to fallback-bearing `:payslip_sans` | integration | `mix test test/rendro/recipes/payslip_opts_threading_test.exs` | ✅ | ✅ green |
| 122-05 | 05 | 1 | TYPE-02 | — | Certificate centering measured on emitted `font_role`; non-Helvetica-metric role raises `{:unsupported_centered_font_role, _}` (WR-01) | integration | `mix test test/rendro/recipes/certificate_typography_test.exs` | ✅ | ✅ green |
| 122-05 | 05 | 1 | TYPE-02 | — | 7-recipe themed `render/2` smoke test closes the WR-02 render-path coverage hole | integration | `mix test test/rendro/recipes/themed_render_smoke_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 dependencies — ExUnit + the pre-existing byte-identity/opts-threading harness carried every TYPE-01/02/03 behavior; new tests were added alongside implementation, not as a prerequisite scaffold.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

All phase behaviors have automated verification. (Themed byte-identity is machine-verified via `git diff --exit-code priv/goldens/`; glyph correctness and centering are proven by end-to-end `render/2` assertions, not human review.)

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — no MISSING gaps)
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated — all 3 requirements (TYPE-01, TYPE-02, TYPE-03) have passing automated coverage.

---

## Validation Audit 2026-07-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit method: State-A reconstruction. VALIDATION.md was a raw unfilled template; the per-task map was rebuilt from the 5 plan SUMMARYs + VERIFICATION.md and cross-referenced against on-disk test files. All referenced tests exist and pass — phase-scoped `mix test test/rendro/recipes/ test/rendro/edge_matrix_test.exs` → 3 doctests, 444 tests, 0 failures; full `mix test` → 1697 tests, 0 failures. No auditor spawn required (zero MISSING/PARTIAL requirements).

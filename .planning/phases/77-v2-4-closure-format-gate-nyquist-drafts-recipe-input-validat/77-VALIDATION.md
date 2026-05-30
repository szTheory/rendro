---
phase: 77
slug: v2-4-closure-format-gate-nyquist-drafts-recipe-input-validat
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
---

# Phase 77 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Reconstructed retroactively from phase artifacts (State B) — phase was executed and verified (77-VERIFICATION.md, 14/14) before this record was generated.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + StreamData properties |
| **Config file** | `mix.exs` (`test`/`ci` aliases); `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/receipt_test.exs test/rendro/recipes/certificate_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~2s (recipe slice) · ~10s (full suite, 925 tests) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (per-recipe negative-path + happy-path)
- **After every plan wave:** Run `mix test` (full suite) + `mix test test/rendro/deterministic_test.exs`
- **Before `/gsd-verify-work`:** `mix ci` (format gate first, then full suite) must be green
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 77-01-01 | 01 | 1 | SC-4/D-05 — Statement non-map `:account` → structured `ArgumentError` | T-77-01 | Raw `BadMapError` converted to bounded `What:/Where:/Why:/Next:` error; no stacktrace info leak | unit (negative-path) | `mix test test/rendro/recipes/statement_test.exs` | ✅ statement_test.exs:517 | ✅ green |
| 77-01-01 | 01 | 1 | SC-4/D-09 — cosmetic cleanups change no rendered output | — | Deterministic byte output unchanged | unit (determinism) | `mix test test/rendro/deterministic_test.exs` | ✅ deterministic_test.exs | ✅ green |
| 77-01-02 | 01 | 1 | SC-4/D-06 — Receipt non-map `:customer` → structured `ArgumentError` | T-77-01 | Bounded structured error on untrusted `:customer` | unit (negative-path) | `mix test test/rendro/recipes/receipt_test.exs` | ✅ receipt_test.exs:499 | ✅ green |
| 77-01-02 | 01 | 1 | SC-4/D-06 — Receipt non-`%Date{}` `:date` → structured `ArgumentError` | T-77-01 | `FunctionClauseError` converted to bounded structured error | unit (negative-path) | `mix test test/rendro/recipes/receipt_test.exs` | ✅ receipt_test.exs:507 | ✅ green |
| 77-01-02 | 01 | 1 | SC-4/D-07 — Certificate non-`%Date{}` `:date` → structured `ArgumentError` | T-77-01 | Bounded structured error on untrusted `:date` | unit (negative-path) | `mix test test/rendro/recipes/certificate_test.exs` | ✅ certificate_test.exs:252 | ✅ green |
| 77-01-02 | 01 | 1 | SC-4/D-07 — Certificate non-binary `:body` → structured `ArgumentError`; 2000-byte cap preserved | T-77-02 | Non-binary `:body` rejected before renderer; DoS cap retained as first guard | unit (negative-path) | `mix test test/rendro/recipes/certificate_test.exs` | ✅ certificate_test.exs:260 | ✅ green |
| 77-01-02 | 01 | 1 | SC-4/D-08 — negative-path `assert_raise` test per new validation clause | — | Every new clause has a red-path regression test | unit (negative-path) | `mix test test/rendro/recipes/` | ✅ 4 new + account | ✅ green |
| 77-02-01 | 02 | 1 | SC-2/D-03 — JTBD guide wired into ExDoc; claims stay within `priv/support_matrix.json` | — | Guide makes no claim exceeding the support matrix | contract (docs) | `mix test test/docs_contract/` | ✅ recipes_claims_test.exs | ✅ green |
| 77-03-01 | 03 | 1 | SC-3/D-04 — Phases 73/74/75 VALIDATION.md `nyquist_compliant: true`, non-draft | — | Auditor-produced Nyquist records, not hand-edited | doc gate (automated grep) | `grep -l 'nyquist_compliant: true' .planning/phases/7{3,4,5}-*/*-VALIDATION.md` | ✅ 3 files | ✅ green |
| 77-04-01 | 04 | 2 | SC-1/D-01 — former format offenders pass `--check-formatted` | — | Committed tree has no `mix format` drift | format gate | `mix format --check-formatted test/docs_contract/recipes_claims_test.exs test/guardrails/required_checks_contract_test.exs` | ✅ both committed | ✅ green |
| 77-04-02 | 04 | 2 | SC-1/D-10 — `mix ci` format step green from clean committed tree | — | Required `test` CI lane is green | ci gate | `mix format --check-formatted && git status --porcelain` (empty) | ✅ clean tree | ✅ green |
| 77-04-02 | 04 | 2 | D-10 — full suite (925+) green incl. new negative-path tests | — | No regression across the milestone | full suite | `mix test` | ✅ 925 tests | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. ExUnit, StreamData, the `docs_contract`/`guardrails` test lanes, and the `mix ci` format gate were all in place before Phase 77 — no new framework, config, or fixture scaffolding was needed. The phase added negative-path tests into existing recipe test files rather than new test infrastructure.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

Every requirement maps to an automated command above: ExUnit negative-path tests for the input-validation hardening (SC-4), the `docs_contract` lane for the JTBD guide wiring (SC-2/D-03), an automated grep for the Nyquist-draft fill (SC-3/D-04), and the `mix format --check-formatted` / `git status --porcelain` / `mix test` gates for the format and terminal-gate criteria (SC-1/D-01/D-10). No visual output, external service, or human-judgment behavior is involved.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra covers all)
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30

---

## Validation Audit 2026-05-30

Retroactive reconstruction (State B) — no prior VALIDATION.md existed; built from 77-01..77-04 PLAN/SUMMARY + 77-VERIFICATION.md and confirmed by execution.

| Metric | Count |
|--------|-------|
| Requirements / behaviors mapped | 12 |
| Gaps found | 0 |
| Resolved (auditor-generated tests) | 0 |
| Escalated (manual-only) | 0 |

**Execution evidence:** `mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/receipt_test.exs test/rendro/recipes/certificate_test.exs test/rendro/deterministic_test.exs test/docs_contract/` → 1 doctest, 3 properties, 230 tests, 0 failures. Full suite (`mix test`) reported 925 tests, 0 failures at the terminal gate (77-04-SUMMARY). No tests were generated — every requirement already carried green automated coverage from phase execution.

---
phase: 108
slug: baseline-audit-report
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `108-RESEARCH.md` → Validation Architecture. This phase is **measure-only**:
> the validation surface is (a) one YAML edit to the `test` job (BASE-05) and (b) an audit
> document at `.planning/milestones/C1-AUDIT.md` (BASE-01..04). No new test suite is added —
> "tests" here are `grep` smoke checks on the YAML and anchor/section presence in the doc.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28 built-in) |
| **Config file** | `test/test_helper.exs` (excludes `:live_pdf_tools`, `:live_signing`, `:raster_snapshot`) |
| **Quick run command** | `grep -nE "<assertion>" .github/workflows/ci.yml` (YAML smoke) / `MIX_ENV=test mix test --slowest 20` (evidence capture) |
| **Full suite command** | `mix ci` (format + compile + test + docs + credo + dialyzer) — used ONLY for evidence capture, not modified |
| **Estimated runtime** | grep smokes ~instant; `mix ci` ~327s avg (local proxy, 18 schedulers) |

---

## Sampling Rate

- **After every task commit:** Run the task's `grep` assertion (BASE-05 YAML lines) or confirm the written C1-AUDIT.md section/anchor exists.
- **After every plan wave:** Wave 1 — manual inspection of the modified `test` job YAML stanza + all 3 BASE-05 smoke greps green. Wave 2 — spot-check all 4 `BASE-0N` anchors resolve in `C1-AUDIT.md`.
- **Before `/gsd:verify-work`:** `C1-AUDIT.md` exists with all 4 anchors AND `.github/workflows/ci.yml` passes all 3 BASE-05 smoke greps AND `mix ci` exit-code preservation through `tee` is confirmed (`pipefail`/`PIPESTATUS`).
- **Max feedback latency:** < 5 seconds (grep-based).

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| BASE-05 | `test` job summary step present, correctly guarded, gate-neutral | smoke | `grep -nE "CI Baseline\|if: always\(\)\|continue-on-error" .github/workflows/ci.yml` | ❌ W1 |
| BASE-05 | `tee` capture preserves `mix ci` exit code | smoke | `grep -nE "PIPESTATUS\|pipefail" .github/workflows/ci.yml` | ❌ W1 |
| BASE-05 | setup-beam step exposes version outputs via `id:` | smoke | `grep -n "id: setup-beam" .github/workflows/ci.yml` | ❌ W1 |
| BASE-01 | Baseline table covers 3 workflows × all jobs w/ required columns | manual | inspect `#base-01--baseline-table` anchor in `C1-AUDIT.md` | ❌ W2 |
| BASE-02 | Critical path + duplicated-work map documented | manual | inspect `#base-02--critical-path` anchor | ❌ W2 |
| BASE-03 | All 34 `async: false` modules + lanes classified A–E w/ cited evidence | manual | inspect `#base-03--ae-classification` anchor | ❌ W2 |
| BASE-04 | P0–P3 recs (issue/change/impact/risk/rollback) mapped to 109–113 | manual | inspect `#base-04--p0p3-recommendation-report` anchor | ❌ W2 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mix test --repeat-until-failure 25` × seeds {0,1,2} — bounded flake sweep producing BASE-03 flaky-**candidacy** evidence (not proof of absence; deep proof deferred to Phase 110).
- [ ] Characterize the local `RecipesFacadeDriftTest` failure in isolation BEFORE the flake sweep so it is not conflated with flake data.
- [ ] Human-read the 4 residue `async: false` modules (BrandingContractTest, IntegrationsContractTest, RecipesContractTest, ManifestTest) — grep showed no global state; record concrete reason or flag as Phase 110 `async: true` candidates.

*No test-framework gaps — ExUnit exists. Validation here is document authoring + YAML inspection, not a new suite.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Baseline table accuracy (timings, columns) | BASE-01 | Content correctness can't be asserted by grep | Cross-check table rows against `gh api .../jobs` step durations + ci.yml/hexdocs.yml/release.yml job list |
| Critical-path narrative correctness | BASE-02 | Judgment over the wall-clock chain | Confirm `test → release-proof` = 16–17min and duplicated `setup-beam`/`deps.get` enumerated |
| A–E evidence sufficiency | BASE-03 | Each class needs a cited artifact, not a pattern match | Confirm each category cites a real artifact; `E` cites a named artifact (never "slow" alone) |
| P0–P3 rec quality + phase mapping | BASE-04 | Editorial/prioritization judgment | Confirm each rec has all 5 fields and maps to a 109–113 phase; flagship monolith-decompose rec present |

---

## Validation Sign-Off

- [ ] All tasks have a `grep`/inspection verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify
- [ ] Wave 0 covers flake sweep + residue read + local-failure characterization
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter once planner maps every task

**Approval:** pending

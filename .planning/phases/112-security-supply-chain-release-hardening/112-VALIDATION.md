---
phase: 112
slug: security-supply-chain-release-hardening
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
updated: 2026-07-10
---

# Phase 112 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + GitHub Actions |
| **Config file** | .github/workflows/*.yml |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test` (and workflow logic verification locally)
- **After every plan wave:** Execute GitHub Actions pipeline
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | D-01/02/03 | V14 | Configure Dependabot | syntax | YAML parse / `112-VERIFICATION.md` | ✅ | ✅ green |
| 112-01-02 | 01 | 1 | D-04 | V10 | Advisory Audit | smoke | `mix deps.audit` / `112-VERIFICATION.md` | ✅ | ✅ green |
| 112-01-03 | 01 | 2 | D-06 | T-112-01 | Version Lock | unit | release workflow inspection / `112-VERIFICATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.github/dependabot.yml` — stubs for D-01/02/03
- [x] `.github/workflows/release.yml` — Add Version Lock for D-06
- [x] `.github/workflows/audit.yml` — Stubs for D-05 (Nightly Audit)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Env Gate | D-07 | Requires UI Configuration | Approve via GitHub UI "Approve" button |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-10 from `112-VERIFICATION.md`.

## Validation Audit 2026-07-10

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated/manual-only | 0 |

The validation file was still marked draft even though `112-VERIFICATION.md` passed. This audit reconciles the frontmatter and sign-off with the existing verification evidence.

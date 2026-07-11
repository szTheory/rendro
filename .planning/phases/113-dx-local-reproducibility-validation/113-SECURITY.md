---
phase: 113
slug: dx-local-reproducibility-validation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-10
updated: 2026-07-11
---

# Phase 113 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI to External | CI dependencies execution and log teeing | GitHub Actions commands, CI logs, dependency/cache state |
| Documentation | Contributor instructions | README and CONTRIBUTING claims about required checks and local reproduction commands |
| Analytics | Pipeline measurement | Local/remote CI timing evidence and milestone audit metrics |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-113-01 | Tampering | GitHub Actions CI Guardrails | mitigate | `test/guardrails/required_checks_contract_test.exs` and `test/docs_contract/dx_local_reproducibility_claims_test.exs` enforce scoped CI aliases, split workflow steps, `/tmp/mix-test-output.log` slowest-test summary source, and `ci-success` as the stable required check. | closed |
| T-113-02 | Info Disclosure | Badging | mitigate | README badge targets `ci-success`, and docs-contract coverage enforces the badge plus CONTRIBUTING local reproduction commands so advisory failures do not mask the required gate's true health. | closed |
| T-113-03 | Tampering | Audit Logs | accept | Documentation artifacts only; validation reports now record remote timing/cache evidence from named GitHub runs and docs-contract tests guard against stale or unsupported metric claims. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-113-01 | T-113-03 | Phase 113 audit-log artifacts are documentation-only. The remaining risk is inaccurate or stale measurement prose, mitigated by named-run evidence in `113-METRICS.md` and docs-contract tests that prevent unsupported metric claims. | GSD security gate | 2026-07-11 |

---

## Verification Evidence

| Check | Result |
|-------|--------|
| `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/dx_local_reproducibility_claims_test.exs` | Passed: 21 tests, 0 failures |
| `113-UAT.md` | Complete: 5 passed, 0 issues |
| `113-METRICS.md` | Records local `mix ci.fast` result plus remote p50/p95/cache evidence from three green `ci.yml` runs |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-10 | 3 | 3 | 0 | Codex / gsd-secure-phase |
| 2026-07-11 | 3 | 3 | 0 | Codex / gsd-complete-milestone |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-11

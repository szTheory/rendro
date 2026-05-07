---
phase: 51
slug: protection-api-contract-and-validation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-06
---

# Phase 51 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller -> `Rendro.Protect` | Untrusted authored passwords and options enter the public protection contract here. | Open/owner passwords, adapter selection, algorithm choice, advisory permissions |
| `Rendro.Protect` -> qpdf executable | Validated options cross from pure Elixir into an external process boundary here. | Redacted protect options, qpdf argfile contents, rendered PDF bytes |
| Protected artifact -> application storage/logging | Protected artifact metadata can cross into app-owned persistence, telemetry, or logs here. | `metadata.protection`, audit metadata, protected PDF bytes |
| Support docs -> downstream teams | Public wording can widen product expectations if it overclaims support here. | API guidance, support matrix claims, integration instructions |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-51-01 | Tampering | `Rendro.Protect.password/2` | mitigate | `lib/rendro/protect.ex` rejects invalid adapter, algorithm, password, and advisory-permission input before adapter invocation; covered by `test/rendro/protect_test.exs`. | closed |
| T-51-02 | Information disclosure | `Rendro.Error` / qpdf seam | mitigate | `Rendro.Protect.redact_opts/1` emits password-presence booleans only, and `lib/rendro/adapters/qpdf.ex` collapses qpdf failures to typed reasons without surfacing stderr or argfile contents; covered by `test/rendro/protect_test.exs`, `test/rendro/adapters/qpdf_test.exs`, and `test/rendro/error_test.exs`. | closed |
| T-51-03 | Denial of service / residue | `Rendro.Adapters.Qpdf` | mitigate | `lib/rendro/adapters/qpdf.ex` wraps temp-dir usage in `try ... after File.rm_rf(tmp_dir)` so scratch paths are removed on success, exit failure, and runner exceptions; covered by `test/rendro/adapters/qpdf_test.exs`. | closed |
| T-51-04 | Information disclosure | `metadata.protection` / audit seams | mitigate | `lib/rendro/protect.ex` exposes only minimal safe `metadata.protection` fields, and `lib/rendro/audit.ex` recursively scrubs password keys across nested maps and lists; covered by `test/rendro/protect_test.exs`, `test/rendro/artifact_test.exs`, and `test/rendro/audit_test.exs`. | closed |
| T-51-05 | Repudiation / truth drift | docs + support matrix | mitigate | `guides/api_stability.md`, `guides/integrations.md`, `priv/support_matrix.json`, and `scripts/verify_docs.exs` are locked by `test/docs_contract/protection_claims_test.exs` so protection claims cannot drift silently. | closed |
| T-51-06 | Scope creep | integrations/docs | mitigate | Integration guidance keeps protection artifact-first, forbids password persistence in Oban args, and keeps Mailglass password-agnostic; enforced by `guides/integrations.md` and `test/docs_contract/protection_claims_test.exs`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-06 | 6 | 6 | 0 | Codex (`$gsd-secure-phase 51`) |

### Verification Evidence

- Focused suite passed: `mix test test/rendro/protect_test.exs test/rendro/adapters/qpdf_test.exs test/rendro/error_test.exs test/rendro/artifact_test.exs test/rendro/audit_test.exs test/docs_contract/protection_claims_test.exs`
- Result: `37 tests, 0 failures`

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-06

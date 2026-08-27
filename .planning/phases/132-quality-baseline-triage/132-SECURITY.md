---
phase: 132
slug: quality-baseline-triage
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-26
---

# Phase 132 — Security

> Per-phase security contract for the quality baseline, governance bridge, and required CI roll-up.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Command and CI output → normalized baseline | Ephemeral evidence becomes a durable repository claim. | Source identities, result metadata, hashes, and redaction facts |
| Local or advisory evidence → authoritative proof | A weaker lane could be promoted beyond its authority. | Lane, authority, availability, and rerun facts |
| Planning artifacts → completion decision | Malformed or human-blocking state could produce a false green. | PLAN, SUMMARY, UAT, VALIDATION, and VERIFICATION fields |
| Fixture/process input → repository scan | Untrusted fixture paths or consumers could escape the intended scope. | Repository-relative paths, symlinks, process argv, and environment |
| CI jobs → required branch-protection roll-up | A skipped or advisory governance job could be reported as successful. | GitHub Actions job results and required-check contexts |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-132-01 | Tampering / Repudiation | Normalized baseline | high | mitigate | Source/raw identities, schema validation, mutation tests, and immutable snapshot checks | closed |
| T-132-02 | Spoofing | Evidence authority | high | mitigate | Explicit lane/status/authority semantics and authority-inflation mutations | closed |
| T-132-03 | Tampering | Ledger disposition and closure | high | mitigate | Record-local fields, decision-basis eligibility, and metric-only rejection | closed |
| T-132-04 | Information Disclosure | Transient raw capture | medium | mitigate | Metadata-only committed evidence, redaction classes, ignored bounded raw artifacts | closed |
| T-132-G01 | Tampering / Elevation | Node fixture/process bridge | high | mitigate | Closed manifests, list-form argv, `shell: false`, bounded cwd/environment, safe paths and symlinks | closed |
| T-132-G02 | Tampering | Stale-verifier transition | high | mitigate | One exact verifier path/hash/source-commit triple; full governance accepts no exception | closed |
| T-132-G03 | Spoofing | Evidence authority and Decision basis | high | mitigate | Exact matrix, unavailable semantics, eligibility rules, and semantic mutation cases | closed |
| T-132-G04 | Elevation | Ledger consumers | high | mitigate | Role-scoped inventory, exact maintenance allowlist, and semantic consumer probes | closed |
| T-132-G05 | Tampering | Markdown and planning parsing | high | mitigate | Peer-bounded parsing plus malformed, misplaced, duplicate, and cross-record mutations | closed |
| T-132-G06 | Repudiation | Terminal validation/UAT/summary state | high | mitigate | Central blocking-human matcher, terminal counts, and role/token mutation coverage | closed |
| T-132-G07 | Tampering | Staged-to-full handoff | high | mitigate | Verifier-owned rewrite followed by unexceptioned full governance | closed |
| T-132-G08 | Denial of Service / Tampering | Governance CI job | high | mitigate | Independent always-running job in strict `ci-success.needs` with topology mutations | closed |
| T-132-G09 | Spoofing | Required-context registry | high | mitigate | `ci-success` remains the sole required context; governance is a mandatory roll-up member | closed |
| T-132-SC | Tampering | Package and dependency surface | low | accept | No installs, dependency changes, or package-surface additions; Node built-ins and existing Elixir dependencies only | closed |

*Only open threats at or above `high` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-132-01 | T-132-SC | The governance tooling uses Node built-ins and existing Elixir dependencies. The residual risk of future package-surface drift is bounded by the package, lockfile, and CI contracts and does not justify a new dependency. | Project policy | 2026-08-26 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-26 | 14 | 14 | 0 | gsd-security-auditor |

Focused audit evidence: `node --test scripts/quality_governance.cjs` (9 tests), `mix quality.baseline` (11 tests), `mix quality.governance`, and `mix test test/guardrails/required_checks_contract_test.exs` (28 tests).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-26

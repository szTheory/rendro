---
phase: 68
slug: viewer-evidence-schema-mix-task-and-docs-contract-lane
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-28
---

# Phase 68 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Repo artifacts → Validator | Reads `priv/support_matrix.json`, `priv/viewer_evidence/**/*.md`, JSON schemas only | Matrix JSON, evidence markdown, schema files |
| Validator → Operator output | Error strings cite path + rule id; no file body echo | Error strings, paths |
| Operator shell → Mix task | Reads repo files only; no network; no env secrets | Matrix JSON, cell metadata |
| Mix task → stdout/stderr | Human and JSON output emit cell metadata only | surface, viewer, status, notes |
| CI test runner → Validator | Reads fixtures and production `priv/` artifacts only | Matrix JSON, synthetic fixtures |
| Violation reports → CI logs | Error messages cite rule id + path | Paths, rule identifiers |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-68-01-01 | Tampering | JSON Schema | mitigate | JSV validates matrix structure; `additionalProperties: false` on viewer rows (GUARDRAIL-03) | closed |
| T-68-01-02 | Information Disclosure | Evidence lint | mitigate | `Lint.evidence_body/1` rejects PEM, home paths, operational secrets (GUARDRAIL-04) | closed |
| T-68-01-03 | Denial of Service | Validator | accept | Offline file reads; 65536-byte budget per evidence file | closed |
| T-68-01-04 | Elevation of Privilege | Runtime API | mitigate | `@moduledoc false` modules; no `Rendro.Support.ViewerEvidence`; JSV dev/test only (D-25) | closed |
| T-68-02-01 | Information Disclosure | JSON output | mitigate | `build_payload/2` emits surface, viewer, status, notes only | closed |
| T-68-02-02 | Tampering | argv parsing | accept | Read-only audit tool; no writes to matrix or evidence files | closed |
| T-68-02-03 | Denial of Service | Table rendering | accept | Fixed 26-row matrix enumeration; bounded table output | closed |
| T-68-02-04 | Repudiation | Exit codes | mitigate | D-22 contract in `@moduledoc`; tested in `viewer_evidence_task_test.exs` | closed |
| T-68-03-01 | Tampering | support_matrix.json | mitigate | JSV rejects non-additive viewer-row keys in tier-B fixture tests | closed |
| T-68-03-02 | Tampering | Evidence files | mitigate | Body lint blocks PEM, images, home paths, operational secrets | closed |
| T-68-03-03 | Repudiation | Deferral reasons | mitigate | `Lint.deferral_reason/1` + docs-contract lane (GUARDRAIL-01) | closed |
| T-68-03-04 | Information Disclosure | Fixture tests | mitigate | Synthetic violation strings in `test/support/viewer_evidence/fixtures/` | closed |
| T-68-03-05 | Elevation of Privilege | CI surface | mitigate | Eighth lane in `scripts/verify_docs.exs`; no new GitHub required check (D-18) | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-68-01 | T-68-01-03 | Validator performs offline file reads only with a 65536-byte per-file budget. Unbounded matrix growth is out of scope for v2.3 (26 fixed viewer cells). | gsd-security-auditor | 2026-05-28 |
| AR-68-02 | T-68-02-02 | Mix task is read-only by design (list/validate/missing); no matrix or evidence writes in Phase 68. Tampering risk transferred to git/PR review. | gsd-security-auditor | 2026-05-28 |
| AR-68-03 | T-68-02-03 | Table rendering iterates a fixed 26-cell matrix; no user-controlled loop bounds. DoS via output volume is negligible for operator tooling. | gsd-security-auditor | 2026-05-28 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-28 | 13 | 13 | 0 | gsd-security-auditor |

### Security Audit 2026-05-28

| Metric | Count |
|--------|-------|
| Threats found | 13 |
| Closed | 13 |
| Open | 0 |

#### Threat Verification Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-68-01-01 | `priv/schemas/support_matrix.schema.json:96` (`viewer_row.additionalProperties: false`); `Validator.validate_matrix_structure/1`; `validator_test.exs` forbidden-key tests |
| T-68-01-02 | `lib/rendro/viewer_evidence/lint.ex:6-18` (`evidence_body/1` patterns); docs-contract + validator tests |
| T-68-01-03 | `lint.ex:4` (`@byte_budget 65_536`); `Validator.validate_evidence_file/3` offline reads; accepted risk AR-68-01 |
| T-68-01-04 | All `Rendro.ViewerEvidence.*` modules `@moduledoc false`; no `Rendro.Support.ViewerEvidence` in lib/; `mix.exs:55` JSV `only: [:dev, :test]` |
| T-68-02-01 | `lib/mix/tasks/rendro/viewer_evidence.ex:152-180` (`build_payload/2`, `cell_to_map/2`); JSON test asserts keys surface/viewer/status only |
| T-68-02-02 | Task performs read-only file access; no write paths; accepted risk AR-68-02 |
| T-68-02-03 | `Matrix.enumerate_viewer_cells/1` over fixed production matrix (26 cells); accepted risk AR-68-03 |
| T-68-02-04 | `@moduledoc` D-22 exit codes; `viewer_evidence_task_test.exs:43-49` missing exit 1; validate/list exit 0 tests |
| T-68-03-01 | `viewer_evidence_claims_test.exs` tier-B tests; `validator_test.exs` forbidden promotion keys |
| T-68-03-02 | `Lint.evidence_body/1`; fixture tests for PEM, images, home paths, secrets |
| T-68-03-03 | `Lint.deferral_reason/1`; docs-contract deferral vocabulary tests |
| T-68-03-04 | `test/support/viewer_evidence/fixtures/` synthetic strings (e.g. `passphrase: hunter2` placeholder) |
| T-68-03-05 | `scripts/verify_docs.exs:15` eighth lane tuple; lane registration test in claims test |

#### Unregistered Flags

None — no `## Threat Flags` section in phase summaries.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-28

---
status: gaps_found
phase: 72-closure-audit-polish-and-ship
verified: 2026-05-29T18:00:00Z
requirements: [GUARDRAIL-02]
score: 9/10
---

# Phase 72 Verification Report (Plan 72-02)

**Phase goal:** Operator/release `validate --strict` staleness gate and closure verification ledger with machine matrix export and GUARDRAIL-02 audit evidence.

**Result:** Automated checks PASSED; live GitHub branch-protection audit pending (`GITHUB_TOKEN` unset at verification time).

## Must-Haves Verified

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `validate --strict` exits 0 on production matrix (dates current) | PASS | CLI output below; `recorded_at` 2026-05-28/29 |
| 2 | `validate --strict` exits 1 when `supported` row stale (>180 days) | PASS | `test/mix/tasks/viewer_evidence_task_test.exs` stale-fixture spawn test |
| 3 | Default `validate` keeps staleness advisory (D-17) | PASS | Same test file — advisory path exits 0 with stderr warning |
| 4 | `--strict` not wired into `mix ci` or docs-contract lane 8 | PASS | `mix.exs` `:ci` alias grep; module contract test |
| 5 | Matrix terminal: supported=17, explicit_deferral=9, unverified=0 | PASS | `list --json` summary below |
| 6 | `missing` exits 0 | PASS | CLI output below |
| 7 | Machine `list --json` ledger (no hand-maintained 26-row table) | PASS | Matrix Ledger section |
| 8 | Trust-sensitive spot-check ≥8 rows (D-19) | PASS | Spot-check table below |
| 9 | GUARDRAIL-02 offline contract test green | PASS | 11 tests, 0 failures |
| 10 | Live audit snapshot on `main` | PENDING | `GITHUB_TOKEN` unset — operator run before tag |

## Matrix Ledger (machine export)

Command: `mix rendro.viewer_evidence list --json`

```json
{"cells":[{"notes":"","status":"supported","surface":"embedded_files","viewer":"adobe_acrobat_reader"},{"notes":"Apple Preview Attachments UI still does not discover, open, or extract the representative embedded-artifact fixture after Phase 71 re-verify; v1.9 deferral stands.","status":"explicit_deferral","surface":"embedded_files","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"forms","viewer":"adobe_acrobat_reader"},{"notes":"","status":"supported","surface":"forms","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"forms","viewer":"chrome_pdfium"},{"notes":"PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during Phase 71 operator review; edit_or_toggle persistence is not reliable.","status":"explicit_deferral","surface":"forms","viewer":"pdfjs"},{"notes":"","status":"supported","surface":"links","viewer":"adobe_acrobat_reader"},{"notes":"","status":"supported","surface":"links","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"long_lived_signed_artifact","viewer":"adobe_acrobat_reader"},{"notes":"Apple Preview does not surface long-term-validation timestamp, revocation, or expiry indicators for augmented PDF signatures on the representative certomancer fixture.","status":"explicit_deferral","surface":"long_lived_signed_artifact","viewer":"apple_preview"},{"notes":"pdfium-cli structural open and form extraction do not expose long-term-validation timestamp, revocation, or expiry indicators; LTV posture remains Acrobat-only for viewer promotion.","status":"explicit_deferral","surface":"long_lived_signed_artifact","viewer":"chrome_pdfium"},{"notes":"PDF.js does not implement long-term-validation timestamp, revocation, or expiry indicators for augmented signatures; viewer promotion deferred until LTV UI exists upstream.","status":"explicit_deferral","surface":"long_lived_signed_artifact","viewer":"pdfjs"},{"notes":"","status":"supported","surface":"protection","viewer":"adobe_acrobat_reader"},{"notes":"","status":"supported","surface":"protection","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"signature_widget","viewer":"adobe_acrobat_reader"},{"notes":"","status":"supported","surface":"signature_widget","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"signature_widget","viewer":"chrome_pdfium"},{"notes":"PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support.","status":"explicit_deferral","surface":"signature_widget","viewer":"pdfjs"},{"notes":"","status":"supported","surface":"signed_artifact","viewer":"adobe_acrobat_reader"},{"notes":"Apple Preview does not validate /Sig digital signatures and append-save invalidates signature dictionaries; signed-artifact viewer promotion requires Acrobat or pdfium-cli structural lanes.","status":"explicit_deferral","surface":"signed_artifact","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"signed_artifact","viewer":"chrome_pdfium"},{"notes":"PDF.js exposes no /Sig validation UI or signed-artifact integrity panel for the representative fixture; viewer promotion deferred until signature validation surfaces exist.","status":"explicit_deferral","surface":"signed_artifact","viewer":"pdfjs"},{"notes":"","status":"supported","surface":"signing_preparation","viewer":"adobe_acrobat_reader"},{"notes":"","status":"supported","surface":"signing_preparation","viewer":"apple_preview"},{"notes":"","status":"supported","surface":"signing_preparation","viewer":"chrome_pdfium"},{"notes":"PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support.","status":"explicit_deferral","surface":"signing_preparation","viewer":"pdfjs"}],"summary":{"explicit_deferral":9,"supported":17,"total":26,"unverified":0}}
```

Summary counts verified: **supported=17**, **unverified=0**, **explicit_deferral=9**, **total=26**.

## Trust-Sensitive Spot-Check

| surface | viewer | status | spot-check note |
|---------|--------|--------|-----------------|
| signature_widget | pdfjs | explicit_deferral | mozilla/pdf.js#4202 in matrix + `guides/api_stability.md` deferral mirror |
| signed_artifact | apple_preview | explicit_deferral | /Sig validation gap — matrix `evidence_deferred` names append-save invalidation |
| signing_preparation | apple_preview | supported | inherits signature_widget promotion pointer; evidence at `priv/viewer_evidence/signing_preparation/apple_preview.md` |
| signing_preparation | chrome_pdfium | supported | inherits signature_widget pointer; `viewer_kind: pdfium-cli` |
| long_lived_signed_artifact | apple_preview | explicit_deferral | LTV indicators absent — matrix deferral prose matches api_stability |
| long_lived_signed_artifact | chrome_pdfium | explicit_deferral | LTV indicators absent — pdfium-cli structural lane honesty |
| forms | adobe_acrobat_reader | supported | evidence path `priv/viewer_evidence/forms/adobe_acrobat_reader.md` + `viewer_kind: manual` |
| signature_widget | chrome_pdfium | supported | `viewer_kind: pdfium-cli` honesty in matrix and evidence frontmatter |

## GUARDRAIL-02 Required-Check Audit

### Context mapping (D-18 folded)

| context | pre-v2.3 | v2.3 close | semantics changed |
|---------|----------|------------|-------------------|
| test | required | required | **no** |
| signing-live-proof | required | required | **no** |
| long-lived-live-proof | required | required | **no** |
| release-proof | required | required | **no** |

### Baseline → CI wiring

| baseline context | CI job | command | docs-contract lanes (folded into `test`) |
|------------------|--------|---------|------------------------------------------|
| test | test | `mix ci` | 8 lanes via `mix test` (includes `viewer_evidence_claims_test.exs`) |

Source: `priv/guardrails/required_status_checks.json` (schema_version 1, `strict: true`, `policy: additive_only`).

`viewer-evidence-live-proof` is **advisory** only (not in `required_contexts`).

Offline contract: `test/guardrails/required_checks_contract_test.exs` — **PASS** (11 tests).

### Live audit snapshot

Command: `mix run scripts/audit_branch_protection.exs`

**Not run** — `GITHUB_TOKEN` unset in verification environment. Operator must run before v2.3 tag and paste normalized JSON:

```json
{"strict": true, "contexts": ["long-lived-live-proof", "release-proof", "signing-live-proof", "test"]}
```

## Automated Checks Run

| Command | Result |
|---------|--------|
| `mix rendro.viewer_evidence missing` | **PASS** (exit 0, 0 unverified cells) |
| `mix rendro.viewer_evidence validate` | **PASS** (exit 0) |
| `mix rendro.viewer_evidence validate --strict` | **PASS** (exit 0) |
| `mix test test/guardrails/required_checks_contract_test.exs` | **PASS** (11 tests, 0 failures) |
| `mix run scripts/audit_branch_protection.exs` | **PENDING** (GITHUB_TOKEN unset) |

### CLI captures

**missing:**

```
Viewer evidence: 0 cells (supported=0, unverified=0, explicit_deferral=0)
No unverified cells. Use --json for machine-readable output.
```

**validate:**

```
Viewer evidence validation passed.
```

**validate --strict:**

```
Viewer evidence validation passed.
```

## Gaps

- `GITHUB_TOKEN unset — live audit pending before tag` (D-06). Re-run `mix run scripts/audit_branch_protection.exs` with repo admin read token and update this file with ISO-8601 timestamp + fenced JSON snapshot.

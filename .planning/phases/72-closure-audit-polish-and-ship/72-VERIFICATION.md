---
status: passed
phase: 72-closure-audit-polish-and-ship
verified: 2026-05-29T18:00:00Z
closed: 2026-05-29T19:30:00Z
requirements: [GUARDRAIL-02]
score: 10/10
note: "Recorded gaps_found at phase-verify time pending the token-gated live branch-protection audit; that audit ran and passed during /gsd-audit-milestone v2.3 (2026-05-29T19:30Z), closing the only open item. Status promoted to passed."
---

# Phase 72 Verification Report (Plans 72-01 / 72-02 / 72-03)

**Phase goal:** GUARDRAIL-02 durable baseline (72-01), operator/release `validate --strict` staleness gate + machine matrix ledger (72-02), and surgical guide/docs-contract polish, `v0.3.1` CHANGELOG split, Hex-honesty negative test, release-workflow preflight hardening, and the full ship gate (72-03).

**Result:** All automated ship-gate checks PASSED at `@version 0.3.1`, including the isolated-worktree release-preflight proof (synthetic exact-tag, Overall: PASS). The only open item is the live GitHub branch-protection audit, which requires `GITHUB_TOKEN` (unset in this environment) — an accepted, documented operator action before the `v0.3.1` tag push, not a code or contract gap.

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
| 10 | Live audit snapshot on `main` | PASS | Run 2026-05-29T19:30Z with gh token — exit 0, contexts match baseline (see GUARDRAIL-02 section) |

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

**Run 2026-05-29T19:30Z** during `/gsd-audit-milestone v2.3`, using the repo-admin `gh` token (`GITHUB_TOKEN=$(gh auth token)`). **Result: PASS (exit 0).** Live required-check list matches the baseline exactly (`strict: true`, four engine-level contexts present, none dropped):

```json
{"contexts": ["long-lived-live-proof", "release-proof", "signing-live-proof", "test"], "strict": true}
```

GUARDRAIL-02 satisfied — the required-check list grew or stayed flat, never shrank; no behavioral lane diluted by viewer-evidence work.

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

## Plan 72-03 Ship Gate (polish, v0.3.1 artifacts, release hardening)

### Must-haves verified (72-03)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `guides/viewer_evidence.md` documents Phase 71 automated path, fixes stale manual step 1 (exit 0), adds Appendix D `--strict` row (D-10, D-24) | PASS | commit `2b1140f`; grep `validate --strict` + `trust_sensitive_viewer_evidence_live_test`; no `expected today` |
| 2 | Docs-contract asserts `forms/chrome_pdfium.md` + `signature_widget/chrome_pdfium.md` and deferral-substring mirror (D-26) | PASS | commit `a2c44b6`; `viewer_evidence_claims_test.exs` 21 tests, 0 failures |
| 3 | CHANGELOG splits `0.3.0` (2026-05-08, pre-v2.3) from `0.3.1` (v2.3 viewer bullets); `mix.exs` `@version` `0.3.1` (D-12, D-13) | PASS | commit `20293d8`; grep `## [0.3.1] - Unreleased`, `## [0.3.0] - 2026-05-08`, `@version "0.3.1"` |
| 4 | `mix.exs` `package files:` whitelist unchanged — no `priv/viewer_evidence/` or `priv/support_matrix.json` (D-29) | PASS | whitelist grep clean |
| 5 | Negative hex.build test refutes `priv/viewer_evidence/` + `priv/support_matrix.json` in tarball (D-30) | PASS | commit `fc4a160`; `branding_claims_test.exs` 9 tests, 0 failures |
| 6 | `release.yml` runs `mix release.preflight` before `hex.publish`; `mix ci` retained (D-14) | PASS | commit `fc4a160`; release.yml step grep |
| 7 | `mix docs.contract` 8/8 lanes green; `mix ci` green at `0.3.1` | PASS | docs contract VERIFIED; `mix ci` `done (passed successfully)` |
| 8 | Release-preflight proof green in isolated worktree at synthetic `v0.3.1` exact tag | PASS | `release_preflight_proof.exs --current-version-tag` → Overall: PASS, exit 0 |

### Ship-gate command results (72-03)

| Command | Result |
|---------|--------|
| `mix ci` | **PASS** (format, hex.build, compile --warnings-as-errors, test, docs, credo --strict, dialyzer 0 errors) |
| `mix docs.contract` | **PASS** (8/8 lanes) |
| `mix rendro.viewer_evidence missing` | **PASS** (exit 0, 0 unverified) |
| `mix rendro.viewer_evidence validate` | **PASS** (exit 0) |
| `mix rendro.viewer_evidence validate --strict` | **PASS** (exit 0) |
| `mix test test/guardrails/` | **PASS** (11 tests, 0 failures) |
| `mix test test/docs_contract/` | **PASS** (1 doctest, 59 tests, 0 failures) |
| `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-preflight-72` | **PASS** (Overall: PASS, exit 0; synthetic tag + worktree cleaned up) |
| `mix release.preflight` (direct, main tree) | **Phase 2 PASS**; Phase 1 `Clean worktree`/`Exact tag parity` FAIL by design — no real `v0.3.1` tag yet and execution worktree has the untracked out-of-scope stray. Authoritative green signal is the isolated-worktree proof above. Phase 1 substantive checks (Package metadata, Changelog release tail, Hex Build Artifacts) PASS. |

### Pre-existing blocking issues fixed during 72-03 (deviations)

| Fix | Rule | Detail | Commit |
|-----|------|--------|--------|
| `viewer_evidence.ex` record dispatch | Rule 1 (bug) | `parse_args!` returned a 4-tuple for `record` but `normalize_parsed` only matched the 3-tuple form; `record` subcommand would raise `FunctionClauseError` at runtime, and dialyzer flagged `:record`/`run_record/2` as unreachable dead code. Pre-existing from 72-02/Phase 71. | `3beaf1a` |
| `viewer_evidence_task_test.exs` formatting | Rule 3 (blocking) | Prior-wave commit `7adeae7` left the file unformatted; `mix format --check-formatted` (inside `mix ci`/preflight) failed. | `3beaf1a` |
| `release_preflight_test.exs` stub tags | Rule 1 (bug) | Stubbed `git describe --exact-match` as `v0.3.0`; after the 0.3.1 bump `check_exact_tag` compares against `v0.3.1`, so Phase 1 failed and Phase 2 assertions never ran inside the nested `mix ci` of the preflight proof worktree. | `68f56c5` |

### Operator post-execute sequence (D-15 — not automated in this plan)

1. Merge Phase 72 PR to `main`.
2. Run live GitHub branch-protection audit with a repo-admin token (closes the one remaining gap below):
   `GITHUB_TOKEN=… mix run scripts/audit_branch_protection.exs` → paste normalized JSON into this file.
3. `git tag v0.3.1 && git push origin v0.3.1` → `release.yml` runs `mix ci` + `mix release.preflight`, then publishes to Hex.
4. `/gsd-audit-milestone v2.3`
5. `/gsd-complete-milestone v2.3`

## Gaps

None. The previously-open item — `GITHUB_TOKEN unset — live branch-protection audit pending` (D-06) — was closed on 2026-05-29T19:30Z during `/gsd-audit-milestone v2.3`: `mix run scripts/audit_branch_protection.exs` ran with a repo-admin gh token and returned `{"contexts":["long-lived-live-proof","release-proof","signing-live-proof","test"],"strict":true}` (exit 0). All ship-gate checks are green. Remaining operator action is the tag push itself (`git tag v0.3.1 && git push origin v0.3.1`).

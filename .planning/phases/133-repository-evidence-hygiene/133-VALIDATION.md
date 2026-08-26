---
phase: 133
slug: repository-evidence-hygiene
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-26
---

# Phase 133 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5; existing Node built-in runner for governance support |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/quality/repository_hygiene_test.exs test/scripts/repository_evidence_test.exs` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Focused checks under 30 seconds; full suite uses the current CI baseline |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command for the changed contract.
- **After every plan wave:** Run `mix quality.hygiene` plus affected migration tests.
- **Before `$gsd-verify-work`:** `mix ci.fast` must be green; run `mix ci.proofs` separately under its proof-lane authority.
- **Max feedback latency:** 30 seconds for focused checks; unavailable advisory or remote proof remains explicitly unavailable rather than blocking deterministic completion.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 133-01-01 | 01 | 1 | HYGIENE-02 | T-133-01, T-133-02 | Manifest-to-prerequisite tracer rejects path, schema, digest, binding, collision, and empty failures | unit/contract | `mix test test/scripts/repository_evidence_test.exs` | ✅ | ✅ green |
| 133-02-01 | 02 | 2 | HYGIENE-02 | T-133-03, T-133-04 | Core identity/validation/index roles preserve provenance and reject substitution | unit/contract | `mix test test/scripts/repository_evidence_test.exs` | ✅ | ✅ green |
| 133-03-01 | 03 | 3 | HYGIENE-02 | T-133-05 | Journey batch 001-004 preserves facts, pairs, provenance, redaction, and stable order | unit/contract | `mix test test/scripts/repository_evidence_test.exs` | ✅ | ✅ green |
| 133-04-01 | 04 | 4 | HYGIENE-02 | T-133-06 | Journey batch 005-009 completes nine JSON/eight sidecar cardinality without invention | unit/contract | `mix test test/scripts/repository_evidence_test.exs` | ✅ | ✅ green |
| 133-05-01 | 05 | 5 | HYGIENE-01, HYGIENE-02 | T-133-07, T-133-08 | All active consumers switch atomically and focused scan reaches zero | contract | `mix test test/scripts/repository_evidence_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/guardrails/required_checks_contract_test.exs` | ✅ | ✅ green |
| 133-06-01 | 06 | 6 | HYGIENE-01, HYGIENE-02 | T-133-09 | Legacy journey batch A deletes only after preservation/zero-consumer proof | contract | `mix test test/scripts/repository_evidence_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs` | ✅ | ✅ green |
| 133-07-01 | 07 | 6 | HYGIENE-01, HYGIENE-02 | T-133-10 | Legacy journey batch B deletes only after complete 9/8 preservation proof | contract | `mix test test/scripts/repository_evidence_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs` | ✅ | ✅ green |
| 133-08-01 | 08 | 2 | HYGIENE-03 | T-133-11 | Phase 5 is one provenance-backed Git rename with repaired references | repository | `test ! -e .planning/phases/05-CONTEXT.md && test -f .planning/milestones/v1.0-phases/05-early-ecosystem-recipes/05-CONTEXT.md && git show --summary --find-renames dbc81eb` | ✅ | ✅ green |
| 133-09-01 | 09 | 2 | HYGIENE-03 | T-133-12 | Seven Phase 45 files are provenance-backed Git renames with repaired references | repository | `test ! -e .planning/phases/45-CONTEXT.md && test -f .planning/milestones/v1.8-phases/45-acroform-text-field-foundation/45-02-SUMMARY.md && git show --summary --find-renames=90% 58f649e` | ✅ | ✅ green |
| 133-10-01 | 10 | 2 | HYGIENE-03 | T-133-13 | Complete helper inventory exists and three ownerless scripts are absent | repository | `test -f scripts/README.md && ! test -e scripts/repo_hygiene_check.sh && ! test -e scripts/audit_branch_protection.exs && ! test -e scripts/render_logo.exs` | ✅ | ✅ green |
| 133-11-01 | 11 | 3 | HYGIENE-01, HYGIENE-03, HYGIENE-04 | T-133-14, T-133-15, T-133-16 | Isolated policy rejects artifact, placement, consumer, inventory, and concurrency failures | unit/contract | `mix test test/quality/repository_hygiene_test.exs` | ✅ | ✅ green |
| 133-12-01 | 12 | 7 | HYGIENE-04 | T-133-17, T-133-18 | Real package membership and PDF.js fixture relocation satisfy resolved exact boundary | integration | `mix quality.hygiene && mix test test/quality/repository_hygiene_test.exs test/docs_contract/pdfjs_advisory_claims_test.exs test/docs_contract/comparison_claims_test.exs test/rendro/comparison_test.exs && mix ci.fast` | ✅ | ✅ green |
| 133-13-01 | 13 | 8 | HYGIENE-01, HYGIENE-02, HYGIENE-03, HYGIENE-04 | T-133-19 | QL-002 lifecycle follows focused scan, compatibility, deterministic gates, and separate proof outcome | terminal | `mix quality.hygiene && mix test test/scripts/repository_evidence_test.exs test/quality/repository_hygiene_test.exs && mix ci.fast && mix ci.proofs && mix test --include quality_ledger_contract test/quality/baseline_ledger_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scripts/repository_evidence_test.exs` — manifest, records, digest/binding, path-confinement, and negative-path coverage for HYGIENE-02.
- [x] `test/quality/repository_hygiene_test.exs` — archive-consumer, tracked-placement, script-inventory, and actual-package membership coverage for HYGIENE-01/03/04.
- [x] Dev/test-only evidence loader and hygiene implementation under existing `dev/` compilation paths.
- [x] Versioned expected package-member manifest and capsule schemas/records.

---

## Manual-Only Verifications

No manual completion gate exists. `pdfium-cli` was unavailable during this audit, so its viewer/PDFium observation remains the existing explicit advisory deferral (NS-006) with its recorded rerun trigger; it neither satisfies nor blocks deterministic Phase 133 completion.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated — deterministic task coverage is green; advisory viewer evidence remains explicitly deferred.

## Validation Audit 2026-08-26

| Metric | Count |
|--------|-------|
| Draft/pending map rows audited | 13 |
| Resolved deterministic rows | 13 |
| New tests required | 0 |
| Escalated implementation defects | 0 |
| Advisory explicit deferrals | 1 |

- Ran the consolidated behavioral suite: 127 tests, 0 failures.
- Ran `mix quality.hygiene`, `mix ci.fast`, `mix ci.proofs`, and the included quality-ledger contract; all exited successfully. The proof lane correctly retained unavailable `pdfium-cli` viewer observation as advisory/explicit deferral.
- Replaced obsolete Mix `-x` flags with the equivalent supported commands. Archive checks additionally confirmed the recorded Git renames (`dbc81eb`, `58f649e`) and executable-surface scan found no operational Phase 131/legacy journey/archive consumer outside the narrow named `gsd_tooling` exceptions.

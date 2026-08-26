---
phase: 133
slug: repository-evidence-hygiene
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `mix test test/quality/repository_hygiene_test.exs test/scripts/repository_evidence_test.exs -x` |
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
| 133-01-01 | 01 | 1 | HYGIENE-02 | T-133-01, T-133-02 | Confined schema/digest loader rejects traversal, substitution, and binding mismatch | unit/contract | `mix test test/scripts/repository_evidence_test.exs -x` | ❌ W0 | ⬜ pending |
| 133-01-02 | 01 | 1 | HYGIENE-01, HYGIENE-02 | T-133-03 | Every active consumer resolves durable facts without archive authority | contract | `mix test test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/guardrails/required_checks_contract_test.exs -x` | ✅ existing consumers | ⬜ pending |
| 133-02-01 | 02 | 2 | HYGIENE-03 | T-133-04 | Tracked phase placement and helper ownership are complete and explicit | unit/contract | `mix test test/quality/repository_hygiene_test.exs -x` | ❌ W0 | ⬜ pending |
| 133-03-01 | 03 | 2 | HYGIENE-01, HYGIENE-03, HYGIENE-04 | T-133-03, T-133-05 | Actual Hex payload excludes internal evidence/debris and the policy rejects forbidden placement/consumers | integration/contract | `mix quality.hygiene` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scripts/repository_evidence_test.exs` — manifest, records, digest/binding, path-confinement, and negative-path coverage for HYGIENE-02.
- [ ] `test/quality/repository_hygiene_test.exs` — archive-consumer, tracked-placement, script-inventory, and actual-package membership coverage for HYGIENE-01/03/04.
- [ ] Dev/test-only evidence loader and hygiene implementation under existing `dev/` compilation paths.
- [ ] Versioned expected package-member manifest and capsule schemas/records.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Any unavailable remote or advisory proof is recorded with its evidence lane, reason, and rerun trigger; it does not become a manual passing gate.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

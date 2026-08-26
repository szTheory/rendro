---
phase: 132
slug: quality-baseline-triage
# status lifecycle: draft (seeded by plan-phase) -> validated (set by validate-phase)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 132 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix quality.baseline` (purpose-tagged maintenance contract, default-excluded from ordinary `mix test` and `mix ci.fast`) |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Focused contract: <10 seconds; full lane: record measured runtime in the baseline |

The proof and advisory lanes remain separate commands (`mix ci.proofs`, `mix ci.advisory`) and separate evidence items. A result from one lane cannot satisfy another lane's authority.

---

## Sampling Rate

- **After every task commit:** Run `mix quality.baseline` once Task 132-01-01 creates the Wave 0 contract and explicit invocation boundary.
- **After every plan wave:** Run the focused contract plus the relevant registered baseline commands; run `mix ci.fast` before phase verification.
- **Before `$gsd-verify-work`:** `mix ci.fast` and every locally available registered baseline command must be green or recorded with an explicit truthful unavailable state.
- **Max feedback latency:** 10 seconds for the focused contract; long-running registered commands record their measured duration and execute at the plan/wave boundary rather than after every edit.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 132-01-01 | 01 | 0 | AUDIT-02, AUDIT-03 | T-132-01, T-132-03 | Creates the isolated maintenance lane; invalid evidence/finding fields, enums, IDs, or lifecycle records fail loudly. | schema + mutation contract | `mix quality.baseline && mix ci.fast` | ❌ W0 | ⬜ pending |
| 132-01-02 | 01 | 0 | AUDIT-01 | T-132-01, T-132-02, T-132-04 | Normalized evidence retains source/lane/hash/redaction identity and stable SIG IDs, and cannot promote unavailable advisory evidence. | focused contract + command probes | `mix quality.baseline` | ❌ W0 | ⬜ pending |
| 132-01-03 | 01 | 0 | AUDIT-02, AUDIT-03, AUDIT-04 | T-132-03 | Every durable finding is unique, fully classified, owned, and governed by its disposition/closure rules. | static contract + human evidence review | `mix quality.baseline` | ❌ W0 | ⬜ pending |
| 132-02-01 | 02 | 1 | AUDIT-01, AUDIT-04 | T-132-02, T-132-04 | Full registered baseline results preserve lane authority, mint stable unique SIG IDs, and record unavailable remote/advisory evidence without fabrication. | integration/command evidence | `mix quality.baseline && mix ci.fast` | ✅ after W0 | ⬜ pending |
| 132-02-02 | 02 | 1 | AUDIT-02, AUDIT-03, AUDIT-04 | T-132-01, T-132-03 | Non-empty set equality proves every SIG is classified exactly once; omitted/double-classified mutations and incomplete dispositions fail. | focused inverse contract + human evidence review | `mix quality.baseline` | ✅ after W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/QUALITY.md` — canonical compatibility contract, baseline registry, lifecycle/disposition rules, active/historical/deferred findings, and Phase 137 comparison placeholder.
- [ ] `.planning/quality/schema/baseline-v1.schema.json` — normalized snapshot/evidence-item contract using existing JSV conventions.
- [ ] `.planning/quality/baselines/132-initial.json` — exact-source-SHA initial snapshot with normalized facts and no embedded raw artifact payloads.
- [ ] `test/quality/baseline_ledger_contract_test.exs` — purpose-tagged JSV validation plus mutation, unique-ID, inverse SIG-classification, lifecycle, reference, disposition, and archive-independence checks.
- [ ] `test/test_helper.exs` and `mix.exs` — default exclusion plus explicit `mix quality.baseline` invocation; ordinary test and `mix ci.fast` do not execute the maintenance contract.

No new test framework or runtime dependency is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Qualitative priority and disposition match the cited evidence rather than a metric quota. | AUDIT-03, AUDIT-04 | Cohesion, maintenance impact, and evidence sufficiency require maintainer judgment. | Review every active finding against the rubric; confirm signals alone do not authorize repairs and that each high/medium disposition has its required owner, proof, or trigger. |
| Remote primary-CI, GitHub artifact, or pinned-PDFium evidence is either attached with exact identity or recorded unavailable. | AUDIT-01 | The local environment cannot manufacture authoritative remote/advisory evidence. | Compare each remote/advisory baseline item with the referenced run/artifact, renderer identity, raw hash, retention metadata, and source SHA. If unavailable, confirm the reason and rerun trigger are present and the status is not `passed`. |

---

## Threat Model References

- **T-132-01 — Tampering/repudiation:** raw output changes, expires, or becomes unreachable. Record its SHA-256, byte count, location, expiry, source SHA, and redaction classification in committed normalized evidence.
- **T-132-02 — Spoofing:** a local or advisory observation is presented as primary CI proof. Record lane/authority explicitly and preserve `unavailable` until the authoritative evidence exists.
- **T-132-03 — Tampering:** a finding is closed by relabeling, metric movement, or unrelated green tests. Require the predeclared focused proof, relevant full gate, compatibility evidence, before/after statement, and resolution reference.
- **T-132-04 — Information disclosure:** raw logs contain paths, credentials, or other sensitive output. Redact before committing normalized facts and keep raw evidence bounded outside Git.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency remains below 10 seconds.
- [ ] Deterministic, proof, advisory, and human-review results remain separate.
- [ ] Every unresolved high-severity threat blocks completion regardless of unrelated green tests; ASVS L1 V4/V5/V6 automated and manual checks are recorded.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending

---
phase: 80
slug: stability-contract-migration-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 80-RESEARCH.md `## Validation Architecture` (HIGH confidence, grounded in live repo).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | none — runs via `mix test` |
| **Quick run command** | `mix test test/docs_contract/` |
| **Full suite command** | `mix ci` (compile `--warnings-as-errors` + test + credo + dialyzer + docs) |
| **Docs-contract gate** | `mix docs.contract` (= `mix run scripts/verify_docs.exs`) |
| **Estimated runtime** | ~5–15 seconds (docs-contract subset; no live proofs) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract/`
- **After every plan wave:** Run `mix ci`
- **Before `/gsd:verify-work`:** `mix docs.contract` must be green
- **Max feedback latency:** ~15 seconds (docs-contract subset)

---

## Success Criteria → Test Map

| SC# | Success Criterion | Requirement | Test Type | Automated Command | File Exists |
|-----|-------------------|-------------|-----------|-------------------|-------------|
| SC-1 | `api_stability.md` states two-tier contract + byte-output carve-out + "NOT covered by SemVer" list | STAB-01 | docs-contract claims | `mix test test/docs_contract/api_stability_claims_test.exs` | ❌ W0 (new test) |
| SC-2 | Deprecation policy (soft-first) + Deprecations table (`None as of 1.0.0` sentinel) in guide | STAB-02 | docs-contract claims | `mix test test/docs_contract/api_stability_claims_test.exs` | ❌ W0 (new test) |
| SC-3 | `upgrading_to_1.0.md` exists, wired into ExDoc Policies group | STAB-03 | docs-contract claims + manual ExDoc render | `mix test test/docs_contract/api_stability_claims_test.exs` + `mix docs` | ❌ W0 (new guide + test) |
| SC-4 | No internal milestone/phase labels in public guides; CI-pinned tests updated in lockstep so `release-proof` stays green | STAB-04 | docs-contract claims (regression) | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/docs_contract/embedded_artifact_claims_test.exs` | ✅ exist (must stay green) |
| SC-5 | `api_stability_claims_test.exs` proves every named Tier-1 symbol exists/exported + tier headers + key sentences + upgrade-guide presence + lane registration | STAB-05 | docs-contract claims | `mix test test/docs_contract/api_stability_claims_test.exs` | ❌ W0 (new test) |

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. Every task below maps to the docs-contract suite as its automated verify. Populated after planning; the dominant verify command for nearly every task is `mix test test/docs_contract/`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (assigned by planner) | — | — | STAB-01..05 | — | N/A (docs-only, no runtime surface) | docs-contract | `mix test test/docs_contract/` | mixed (see W0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Files that must exist before STAB-05 (SC-1/2/3/5) can be verified:

- [ ] `test/docs_contract/api_stability_claims_test.exs` — the new STAB-05 claims test (covers SC-1, SC-2, SC-3, SC-5)
- [ ] `guides/upgrading_to_1.0.md` — required by STAB-03, asserted by STAB-05 (SC-3)
- [ ] `scripts/verify_docs.exs` — register the new claims lane as lane #12 (D-10 item 5)

*No test-infrastructure gaps: ExUnit, `test/docs_contract/`, and `scripts/verify_docs.exs` all exist and work today.*

---

## Lockstep Invariant (core regression rule)

Any new pinned substring added to a guide MUST be pinned by a test assertion in the **same commit**:

```
guide edit → test assertion (api_stability_claims_test.exs) → verify_docs.exs lane entry
```

Violating this leaves a window where `mix docs.contract` passes but the substantive claim is unverified. The CI-pinned label scrub (D-05: `protection_claims_test.exs:48,56`) is the inverse case — guide text and pinned substring must change together so `release-proof` stays green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `upgrading_to_1.0.md` renders under the ExDoc **Policies** group | STAB-03 | ExDoc HTML grouping is not asserted by a unit test | Run `mix docs`, open `doc/upgrading_to_1.0.html`, confirm it appears in the Policies sidebar group alongside `api_stability` + `viewer_evidence` |

*All other phase behaviors have automated verification via the docs-contract suite.*

---

## Phase-Level Regression Gate

The phase is complete when ALL of the following are green:

1. `mix test test/docs_contract/` — all 12 lanes (11 existing + new `api_stability_claims` lane)
2. `mix docs.contract` — runs `scripts/verify_docs.exs` (all 12 lanes)
3. `mix ci` — compile `--warnings-as-errors` + test + credo + dialyzer + docs (confirms no warnings regression; D-16)
4. `release-proof` CI lane — runs `mix release.preflight` → includes `mix docs.contract`

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new test, new guide, lane registration)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

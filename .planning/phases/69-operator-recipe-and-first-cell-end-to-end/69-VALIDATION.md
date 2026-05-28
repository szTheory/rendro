---
phase: 69
slug: operator-recipe-and-first-cell-end-to-end
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `mix test test/docs_contract/viewer_evidence_claims_test.exs` |
| **Full suite command** | `mix docs.contract` |
| **Estimated runtime** | ~5 seconds (lane 8); ~5 seconds (full docs.contract) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract/viewer_evidence_claims_test.exs`
- **After every plan wave:** Run `mix docs.contract`
- **Before `/gsd-verify-work`:** `mix docs.contract` must be green (8/8 lanes); `mix rendro.viewer_evidence validate` exit 0 with forms row legacy warning cleared
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01-01 | 01 | 1 | RECIPE-03 | T-69-01-01 | Guide registered in mix.exs Policies extras | unit | `grep -q 'guides/viewer_evidence.md' mix.exs` | ✅ | ⬜ pending |
| 69-01-02 | 01 | 1 | RECIPE-03 | — | Guide file exists with quick-start steps | unit | `test -f guides/viewer_evidence.md` | ❌ W0 | ⬜ pending |
| 69-02-01 | 02 | 2 | RECIPE-01 | T-69-02-01 | Evidence file validates via run_full | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 69-02-02 | 02 | 2 | RECIPE-01 | — | Matrix row has evidence pointer + recorded_at + viewer_kind | unit | `mix rendro.viewer_evidence list` (forms row no legacy note) | ✅ | ⬜ pending |
| 69-03-01 | 03 | 3 | RECIPE-05 | T-69-03-01 | api_stability discipline section present | unit | `grep -q 'Viewer Evidence and CHANGELOG Discipline' guides/api_stability.md` | ❌ W0 | ⬜ pending |
| 69-03-02 | 03 | 3 | RECIPE-05 | — | CHANGELOG Viewer Evidence subsection | unit | `grep -q 'Viewer Evidence (v2.3)' CHANGELOG.md` | ❌ W0 | ⬜ pending |
| 69-03-03 | 03 | 3 | RECIPE-03, RECIPE-05 | — | forms_claims_test guards preserved | integration | `mix test test/docs_contract/forms_claims_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement Coverage

| Requirement | Verification | Status |
|-------------|--------------|--------|
| RECIPE-01 | Evidence file + matrix promotion fields; docs-contract run_full | PENDING |
| RECIPE-03 | Guide + mix.exs registration + optional pointer asserts | PENDING |
| RECIPE-05 | api_stability discipline + CHANGELOG entry | PENDING |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `test/docs_contract/viewer_evidence_claims_test.exs` — lane 8 (Phase 68)
- [x] `test/docs_contract/forms_claims_test.exs` — regression guard for api_stability edits
- [x] `lib/rendro/viewer_evidence/validator.ex` — evidence validation
- [x] `lib/mix/tasks/rendro/viewer_evidence.ex` — operator tooling
- [x] `priv/viewer_evidence/_template.md` — copy source

Phase 69 creates new artifacts (guide, evidence file, fixture PDF) — no new test framework needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Apple Preview spot-check | RECIPE-01 | CI never runs viewers (PITFALLS #7) | Open `test/fixtures/forms_support_fixture.pdf` in Preview; verify all four `proof[]` behaviors; capture viewer_version and platform from About |
| Recipe second-operator readability | RECIPE-03 | Prose quality not lintable | Read guide quick-start; confirm each step has observable check |
| HexDocs Policies navigation | RECIPE-03 SC1 | ExDoc group rendering | `mix docs`; confirm viewer_evidence.md under Policies beside api_stability.md |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

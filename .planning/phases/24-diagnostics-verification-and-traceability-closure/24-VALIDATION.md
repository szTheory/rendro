---
phase: 24
slug: diagnostics-verification-and-traceability-closure
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
updated: 2026-04-30
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for truthful diagnostics docs, focused public proof, and Nyquist normalization.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract lane + `rg` structure checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs test/docs_contract/readme_doctest_test.exs && mix run scripts/verify_docs.exs` |
| **Full suite command** | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs test/docs_contract/readme_doctest_test.exs && mix run scripts/verify_docs.exs && rg -n "^nyquist_compliant: true$" .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md` |
| **Estimated runtime** | ~15-20 seconds |

---

## Sampling Rate

- **After every task commit:** run the smallest affected docs/tests/validation subset.
- **After every plan wave:** run the full Phase 24 quick suite.
- **Before `$gsd-verify-work`:** the quick suite plus validation-structure checks must be green.
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | OBS-05, QUAL-06 | T-24-01 | `Rendro.Document`, `Rendro.render_with_diagnostics/2`, and README describe one truthful map-based diagnostics contract with stable common keys and additive event-specific optional fields. | docs-contract | `! rg -n "%Rendro\\.Document\\.Diagnostic\\{" README.md && rg -n "structured maps" README.md lib/rendro.ex && rg -n "diagnostics: \\[map\\(\\)\\]" lib/rendro/document.ex` | ✅ | ⬜ pending |
| 24-01-02 | 01 | 1 | OBS-05, QUAL-06 | T-24-02 | The focused public proof slice keeps `render_with_diagnostics/2`, pagination diagnostics, inspector output, and README doctests deterministic and reviewable. | unit + docs-contract | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs test/docs_contract/readme_doctest_test.exs && mix run scripts/verify_docs.exs` | ✅ | ⬜ pending |
| 24-01-03 | 01 | 1 | OBS-05, QUAL-06 | T-24-03, T-24-04 | Phase 21, Phase 22, and Phase 24 validation files stay machine-discoverable through one Nyquist convention instead of drifting into prose-only artifacts. | artifact | `rg -n "^nyquist_compliant: true$" .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md && rg -n "^## Per-Task Verification Map$" .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md && rg -n "^## Validation Sign-Off$" .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md && rg -n "^nyquist_compliant: true$" .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md && rg -n "^## Per-Task Verification Map$" .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md && rg -n "^## Validation Sign-Off$" .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md && rg -n "^nyquist_compliant: true$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Test Infrastructure$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Sampling Rate$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Per-Task Verification Map$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Wave 0 Requirements$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Manual-Only Verifications$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md && rg -n "^## Validation Sign-Off$" .planning/phases/24-diagnostics-verification-and-traceability-closure/24-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

---

## Wave 0 Requirements

- [x] The focused diagnostics proof suite already exists in `test/rendro/pipeline/paginate_test.exs`, `test/rendro/pipeline_test.exs`, `test/rendro/inspector_test.exs`, and `test/docs_contract/readme_doctest_test.exs`.
- [x] `mix run scripts/verify_docs.exs` is already part of the repo’s docs-contract lane.
- [x] No secondary validation convention or new framework setup is required.

---

## Manual-Only Verifications

None. Phase 24 should close entirely through deterministic automated proof and file-structure checks.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** focused diagnostics closure lane approved on 2026-04-30.

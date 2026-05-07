---
phase: 49
slug: curated-link-annotation-surface
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-05
updated: 2026-05-05
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for deterministic curated link authoring, pagination-preserving wrappers, and `/Link` annotation serialization.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs test/rendro/link_test.exs test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15-35 seconds |

## Sampling Rate

- After every task commit: run the narrowest touched test target from the per-task map below.
- After Wave 1: run `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs`.
- After Wave 2: run `mix test test/rendro/link_test.exs`.
- After Wave 3: run `mix test test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs`.
- Before execution handoff: run the quick Phase 49 suite once end-to-end.
- Max feedback latency: 35 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | LINK-01, LINK-02 | T-49-01 | `Rendro.link/2` stays explicit, preserves outer block geometry, and rejects unsupported target shapes instead of hiding link semantics in attrs. | unit | `mix test test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | LINK-01, LINK-02 | T-49-02, T-49-03 | Validate rejects malformed/unsupported URIs, invalid page destinations, and links wrapping `%Rendro.FormField{}` before writer serialization. | unit + integration | `mix test test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 2 | LINK-01, LINK-02 | T-49-04 | Measuring linked content preserves the target while keeping width and height on the outer `%Rendro.Block{}`. | unit | `mix test test/rendro/link_test.exs` | ✅ | ⬜ pending |
| 49-02-02 | 02 | 2 | LINK-01, LINK-02 | T-49-05, T-49-06 | Fragmentation rewraps fitting and remaining content with the same validated target and does not widen into non-rectangular hit regions. | unit | `mix test test/rendro/link_test.exs` | ✅ | ⬜ pending |
| 49-03-01 | 03 | 3 | LINK-01, LINK-02 | T-49-07, T-49-08, T-49-09 | Writer emits one `/Subtype /Link` annotation per paginated fragment and delegates `%Rendro.Link{content: inner}` through the existing render path so linked text/table content still renders unchanged while annotations are emitted. | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |
| 49-03-02 | 03 | 3 | LINK-01, LINK-02 | T-49-07, T-49-09 | Deterministic renders keep stable bytes and annotation ordering for identical linked documents. | unit | `mix test test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] Every planned task has an explicit automated verification command.
- [x] Sampling continuity is preserved: no sequence of three tasks lacks automated verification.
- [x] The phase has a narrow quick suite covering builder, validate, measure/fragment, writer, and determinism seams.
- [x] Existing ExUnit infrastructure is sufficient; no external viewer dependency is required for structural proof.
- [ ] `test/rendro/rules/check_links_test.exs` must include the `%Rendro.FormField{}` rejection case alongside URI/page failure tuples.
- [ ] `test/rendro/pdf/writer_test.exs` must include linked-content render-delegation proof showing visible linked text/table output still appears while separate `/Link` annotations are emitted.

## Manual-Only Verifications

- No manual viewer verification is required in Phase 49. Viewer click behavior remains outside the phase boundary; this phase proves authored validation, deterministic pagination semantics, and structural PDF output only.

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 identifies remaining proof gaps for FormField rejection and render-path delegation
- [x] No watch-mode flags
- [x] Feedback latency remains under 60 seconds for the quick suite target
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 49 validation lane revised on 2026-05-05.

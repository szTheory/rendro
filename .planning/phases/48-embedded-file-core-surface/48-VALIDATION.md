---
phase: 48
slug: embedded-file-core-surface
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
updated: 2026-05-05
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for deterministic document-level embedded-file authoring and catalog serialization.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/embedded_file_registry_test.exs test/rendro/rules/check_embedded_files_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs test/rendro/document_test.exs test/rendro_builders_test.exs` |
| **Full suite command** | `mix test test/rendro/embedded_file_registry_test.exs test/rendro/rules/check_embedded_files_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs test/rendro/document_test.exs test/rendro_builders_test.exs` |
| **Estimated runtime** | ~10-25 seconds |

## Sampling Rate

- After every task commit: run the narrowest touched test target.
- After each plan wave: run the full Phase 48 quick suite.
- Before execution handoff: all embedded-file registry, validation, and writer proof tests must be green.
- Max feedback latency: 25 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | EMBED-01, EMBED-02 | T-48-01 | Document-owned registration stores explicit embedded-file bytes and metadata without post-render mutation. | unit | `mix test test/rendro/embedded_file_registry_test.exs test/rendro/document_test.exs test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | EMBED-02, EMBED-03 | T-48-02 | Validation rejects duplicate or malformed embedded-file metadata before render. | unit | `mix test test/rendro/rules/check_embedded_files_test.exs test/rendro/pipeline/validate_test.exs` | ✅ | ⬜ pending |
| 48-02-01 | 02 | 2 | EMBED-01, EMBED-02 | T-48-03 | Writer emits deterministic `/EmbeddedFile` streams and `/Filespec` objects wired through `/EF`. | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |
| 48-02-02 | 02 | 2 | EMBED-01, EMBED-03 | T-48-04 | Catalog `/Names` and `/AF` surfaces are present only when embedded files exist and remain deterministically ordered. | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] Existing document, builder, pipeline, and writer test suites can absorb the new coverage.
- [x] No external viewer dependency is required for Phase 48’s structural proof lane.
- [x] Existing writer substring assertions are sufficient for names-tree and file-spec structural verification.

## Manual-Only Verifications

- No manual viewer proof is required in this phase. Viewer behavior for file attachments remains out of scope until Phase 50 truth-surface closure decides what is supportable.

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers authoring, validation, and serialization proof surfaces
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 48 validation lane approved on 2026-05-05.

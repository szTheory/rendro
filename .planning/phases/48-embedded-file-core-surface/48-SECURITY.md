---
phase: 48
slug: embedded-file-core-surface
status: verified
threats_open: 0
threats_closed: 4
asvs_level: 1
created: 2026-05-05
---

# Phase 48 — Embedded File Core Surface — Security Audit

**Phase:** 48 — embedded-file-core-surface
**ASVS Level:** L1
**Threats Closed:** 4 / 4
**Threats Open:** 0
**Audit Date:** 2026-05-05

---

## Summary

All four declared threats across `48-01` and `48-02` are **CLOSED**.

The audit verified that:

- embedded-file sources are normalized into document-owned bytes before render;
- malformed or ambiguous embedded-file metadata is rejected during `Rendro.Pipeline.Validate`;
- writer allocation and catalog wiring are deterministically sorted for identical authored inputs; and
- the phase stays within its stated scope boundary by emitting document-level catalog/file-spec objects only, without page-level file-attachment annotations.

No accepted-risk or transfer dispositions were needed for this phase.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User API -> Core | Developer-authored embedded-file sources and metadata cross into the trusted document contract through `Rendro.register_embedded_file/4` and `Rendro.Document.register_embedded_file/4`. | Embedded-file bytes, filename, MIME type, optional description, optional authored timestamps |
| Validated registry -> PDF writer | Only validated, normalized embedded-file descriptors should cross from the document-owned registry into PDF object allocation and catalog wiring. | Owned bytes, byte size, filename, MIME type, optional description, optional authored timestamps |

---

## Threat Verification

### Mitigated threats (4)

| Threat ID | Category | Component | File:Line | Evidence |
|-----------|----------|-----------|-----------|----------|
| T-48-01 | Tampering | `Rendro.EmbeddedFileRegistry` | `lib/rendro/embedded_file_registry.ex:31-58` | `register/4` calls `normalize_source/1` immediately and stores `bytes` plus `byte_size` in the descriptor; `{:path, path}` is converted with `File.read!`, so later render stages never depend on a mutable path reference. |
| T-48-02 | Integrity | `Rendro.Rules.CheckEmbeddedFiles` | `lib/rendro/rules/check_embedded_files.ex:6-81`, `lib/rendro/pipeline/validate.ex:13-26` | Duplicate filenames are grouped into `{:duplicate_embedded_file_name, filename}` tuples, malformed filename/MIME/description/timestamp values are emitted as typed validation tuples, and `CheckEmbeddedFiles` is part of `@default_rules`, so invalid embedded-file state fails before serialization. |
| T-48-03 | Integrity | `Rendro.PDF.Writer` | `lib/rendro/pdf/writer.ex:1297-1303`, `lib/rendro/pdf/writer.ex:203-206`, `lib/rendro/pdf/writer.ex:1446-1464` | `collect_embedded_files/1` sorts descriptors by `{filename, logical_name}` before allocation; object numbers, `/Names`, and `/AF` all derive from that sorted list, yielding deterministic catalog wiring for identical inputs. |
| T-48-04 | Scope creep | `Rendro.PDF.Writer` | `lib/rendro/pdf/writer.ex:1444-1464`, `lib/rendro/pdf/writer.ex:1289-1329`, `test/rendro/pdf/writer_test.exs:204-207` | Embedded-file output is isolated to catalog `/Names`, `/EmbeddedFiles`, and `/AF`; page annotations are still produced only from form-field annotation refs, and the writer test explicitly refutes `/Subtype /FileAttachment`. |

---

## Unregistered Flags

None.

The phase summaries do not report any new threat surface outside the declared register, and the inspected implementation stays within the planned boundaries:

- `48-01-SUMMARY.md` records document-owned registry and validate-stage rejection of malformed embedded-file metadata.
- `48-02-SUMMARY.md` records deterministic catalog wiring and explicitly states the attachment surface remains document-level only.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-05 | 4 | 4 | 0 | Codex |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-05

---

## Audit Methodology

For each `mitigate` threat, the audit:

1. Read the declared threat register from `.planning/phases/48-embedded-file-core-surface/48-01-PLAN.md` and `48-02-PLAN.md`.
2. Inspected the implementation files named by the mitigation plan.
3. Verified the concrete control in code and the matching proof in tests.
4. Re-ran the targeted embedded-file, validation, writer, and deterministic suites.

Test verification command:

```sh
mix test test/rendro/embedded_file_registry_test.exs test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/rules/check_embedded_files_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs
```

Observed result: `113 tests, 0 failures`.

Implementation files were treated as read-only during this audit. Only the phase security artifact was added.

---

## Files Inspected

- `lib/rendro/embedded_file_registry.ex`
- `lib/rendro/document.ex`
- `lib/rendro/rules/check_embedded_files.ex`
- `lib/rendro/pipeline/validate.ex`
- `lib/rendro/pdf/writer.ex`
- `test/rendro/embedded_file_registry_test.exs`
- `test/rendro/document_test.exs`
- `test/rendro_builders_test.exs`
- `test/rendro/rules/check_embedded_files_test.exs`
- `test/rendro/pipeline/validate_test.exs`
- `test/rendro/pdf/writer_test.exs`
- `test/rendro/deterministic_test.exs`
- `.planning/phases/48-embedded-file-core-surface/48-01-PLAN.md`
- `.planning/phases/48-embedded-file-core-surface/48-02-PLAN.md`
- `.planning/phases/48-embedded-file-core-surface/48-01-SUMMARY.md`
- `.planning/phases/48-embedded-file-core-surface/48-02-SUMMARY.md`
- `.planning/phases/48-embedded-file-core-surface/48-VERIFICATION.md`

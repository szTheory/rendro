---
phase: 48-embedded-file-core-surface
reviewed: 2026-05-06T01:29:05Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - .planning/phases/48-embedded-file-core-surface/48-01-PLAN.md
  - .planning/phases/48-embedded-file-core-surface/48-02-PLAN.md
  - .planning/phases/48-embedded-file-core-surface/48-01-SUMMARY.md
  - .planning/phases/48-embedded-file-core-surface/48-02-SUMMARY.md
  - lib/rendro/embedded_file_registry.ex
  - lib/rendro/document.ex
  - lib/rendro.ex
  - lib/rendro/rules/check_embedded_files.ex
  - lib/rendro/pipeline/validate.ex
  - lib/rendro/pdf/writer.ex
  - test/rendro/embedded_file_registry_test.exs
  - test/rendro/document_test.exs
  - test/rendro_builders_test.exs
  - test/rendro/rules/check_embedded_files_test.exs
  - test/rendro/pipeline/validate_test.exs
  - test/rendro/pdf/writer_test.exs
  - test/rendro/deterministic_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 48: Code Review Report

**Reviewed:** 2026-05-06T01:29:05Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Reviewed the Phase 48 planning artifacts plus the touched embedded-file core, validation, writer, and test files. The writer/catalog work is structurally consistent with the phase scope, and the focused test suite passes locally, but one contract regression remains: the new public registration surface does not actually require `:filename` and `:mime_type` at registration time, despite both plans and summaries claiming that it does.

## Warnings

### WR-01: Embedded-file registration accepts missing required metadata

**File:** `lib/rendro/embedded_file_registry.ex:36-44`
**Issue:** `register/4` silently drops metadata to a `Map.take/2` whitelist and merges the descriptor without asserting that `:filename` and `:mime_type` are present. That means `Rendro.Document.register_embedded_file/4` and `Rendro.register_embedded_file/4` currently accept malformed registrations such as `filename: nil` or no `mime_type` at all, and only fail later in `Validate.run/1`. This conflicts with the Phase 48 plan (`48-01-PLAN.md`) and both summary artifacts, which describe a narrow explicit API that requires filename and MIME type at registration time. The current tests also do not cover this public-surface contract.
**Fix:**
```elixir
def register(%__MODULE__{} = registry, logical_name, source, metadata)
    when is_atom(logical_name) and is_list(metadata) do
  filename = Keyword.fetch!(metadata, :filename)
  mime_type = Keyword.fetch!(metadata, :mime_type)
  {source_kind, bytes} = normalize_source(source)

  descriptor =
    metadata
    |> Enum.into(%{})
    |> Map.take([:description, :created_at, :modified_at])
    |> Map.merge(%{
      logical_name: logical_name,
      source_kind: source_kind,
      bytes: bytes,
      byte_size: byte_size(bytes),
      filename: filename,
      mime_type: mime_type
    })

  %__MODULE__{registry | files: Map.put(registry.files, logical_name, descriptor)}
end
```

Add coverage in `test/rendro/embedded_file_registry_test.exs`, `test/rendro/document_test.exs`, and/or `test/rendro_builders_test.exs` asserting that missing `:filename` or `:mime_type` is rejected immediately by the public builder surface.

---

_Reviewed: 2026-05-06T01:29:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: 48
slug: embedded-file-core-surface
status: ready
created: 2026-05-05
updated: 2026-05-05
---

# Phase 48: Embedded File Core Surface - Research

**Researched:** 2026-05-05
**Status:** Ready for planning
**Mode:** No phase context provided; recommendations derive from roadmap, requirements, and existing code seams.

## Executive Summary

Phase 48 should add document-level embedded files through the same pure-data, document-owned registration model Rendro already uses for fonts and images. The narrowest truthful path is:

- add one document-owned embedded-file registry plus a thin public builder wrapper;
- validate duplicate or ambiguous authored file state in the existing `Rendro.Pipeline.Validate` pass;
- serialize embedded files only at the catalog/object-graph layer through `/Names`, `/EmbeddedFiles`, `/Filespec`, `/EF`, and `/AF`;
- keep page-level attachment annotations, signatures, and encryption explicitly out of scope.

The existing codebase strongly favors registry-backed authored inputs over freeform metadata maps. That makes a dedicated `Rendro.EmbeddedFileRegistry` a better fit than extending `Rendro.Metadata.custom` or overloading `AssetRegistry`.

## Recommended Architecture

### 1. Use a document-owned embedded-file registry

Recommended surface:

- Add `embedded_file_registry: Rendro.EmbeddedFileRegistry.new()` to `%Rendro.Document{}`.
- Add `Rendro.Document.register_embedded_file/4` and `Rendro.register_embedded_file/4`.
- Accept `{:binary, bytes}` and `{:path, path}` sources, matching existing registry conventions.

Why this fits the repo:

- `Rendro.FontRegistry` and `Rendro.AssetRegistry` already normalize external sources into owned pure data on the document.
- Registries preserve the “core stays pure” rule by resolving filesystem input at registration time, not deep inside rendering.
- Phase 48 needs explicit authored metadata, not ad hoc post-processing, so the document should own the contract directly.

### 2. Keep metadata explicit and deterministic

Each registered embedded file should carry explicit authored metadata needed for requirements `EMBED-01` through `EMBED-03`:

- logical identity: atom key in the registry
- filename: non-empty binary
- MIME type: non-empty binary
- description: optional binary
- authored timestamps: optional `DateTime`s only when the caller provides them
- normalized bytes and byte size

Recommended validation posture:

- reject missing or empty filenames
- reject missing or empty MIME types
- reject duplicate filenames in the same document
- reject non-binary descriptions
- reject non-UTC or non-`DateTime` timestamp shapes if timestamps are present
- do not auto-fill timestamps

Likely typed errors:

- `{:duplicate_embedded_file_name, filename}`
- `{:invalid_embedded_file_filename, filename}`
- `{:invalid_embedded_file_mime_type, mime}`
- `{:invalid_embedded_file_description, description}`
- `{:invalid_embedded_file_timestamp, field, value}`

### 3. Validation belongs in the existing validate-stage pipeline

The current validation architecture already aggregates typed errors across the document tree through `Rendro.Pipeline.Validate`. Phase 48 should follow that pattern by adding a dedicated rule module, not by burying checks inside the writer.

Recommended shape:

- Add `Rendro.Rules.CheckEmbeddedFiles`.
- Register it in `@default_rules` in `lib/rendro/pipeline/validate.ex`.
- Let the rule inspect `%Rendro.Document{}` and return `:ok`, `{:error, reason}`, or `{:errors, reasons}` using the existing tuple-based contract.

Why this matters:

- Duplicate filenames and timestamp ambiguity are authored-boundary errors, not serialization errors.
- The writer should assume validated inputs and focus on deterministic object construction.

### 4. Serialize only the catalog-level embedded-file surface

Phase 48’s PDF work should stay document-level. The strongest narrow implementation is:

- create one `/EmbeddedFile` stream object per registered file
- create one `/Filespec` object per registered file
- add catalog `/Names << /EmbeddedFiles << /Names [...] >> >>`
- add catalog `/AF [...]` referencing the same file specs

Recommended `Filespec` shape:

- `/Type /Filespec`
- `/F` and `/UF` from authored filename
- `/Desc` when description is present
- `/EF << /F <embedded-file-stream-ref> >>`
- `/AFRelationship /Unspecified` for now unless Phase 48 chooses a narrow enum

Recommended embedded-file stream shape:

- `/Type /EmbeddedFile`
- `/Subtype` encoded from MIME type
- `/Params << /Size n /CheckSum <...> /ModDate (...) /CreationDate (...) >>` when applicable

Determinism rule:

- object allocation order should be stable by registry logical name or authored filename
- names-tree key order must be stable
- checksum generation is acceptable because it is a pure function of the registered bytes

### 5. Reuse existing PDF helper seams instead of inventing a second serializer

Important existing seams:

- `build_objects/4` in `lib/rendro/pdf/writer.ex` is the single object-allocation funnel
- `maybe_add_acro_form_entry/2` shows how catalog entries are conditionally injected
- `encode_pdf_name/1` already exists in the writer and can support MIME-name escaping if kept local or promoted carefully
- `Rendro.PDF.Object` already supports refs, arrays, dicts, strings, hex strings, and streams, which is enough for the embedded-file object graph

No new general PDF abstraction appears necessary in this phase.

## Recommended Testing Strategy

### Core authoring lane

- `test/rendro/document_test.exs`
- `test/rendro_builders_test.exs`
- new `test/rendro/embedded_file_registry_test.exs`

Proof points:

- path/binary inputs normalize into owned bytes
- metadata is stored explicitly and not auto-filled
- builder wrappers stay pipeable and pure

### Validation lane

- new `test/rendro/rules/check_embedded_files_test.exs`
- `test/rendro/pipeline/validate_test.exs`

Proof points:

- duplicate filenames fail
- invalid MIME/filename/description/timestamp shapes fail
- validate-stage aggregation preserves the exact tuple errors in `details.errors`

### Writer lane

- `test/rendro/pdf/writer_test.exs`
- optionally `test/rendro/deterministic_test.exs`

Proof points:

- catalog contains `/Names`, `/EmbeddedFiles`, and `/AF`
- file-spec objects include `/Filespec`, `/F`, `/UF`, `/EF`, `/Desc`
- stream objects include `/Type /EmbeddedFile`
- deterministic mode produces stable embedded-file ordering and catalog wiring

## Scope Boundaries To Preserve

- Do not add page-level file-attachment annotations.
- Do not widen into generic annotation dictionaries.
- Do not claim viewer UX behavior for attachments in this phase.
- Do not add encryption, signatures, or permissions semantics.
- Do not store embedded-file state in `Rendro.Metadata.custom`.

## Planning Recommendation

Split Phase 48 into two execution plans:

1. Registry, public API, and authored validation
2. PDF writer object graph, catalog names tree, and deterministic proof

That split matches the current architecture: authored contract first, serialization second.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added

- `[:rendro, :pipeline, :validate, :start | :stop | :exception]` telemetry events for the new trailing post-render validation stage. The stage performs PDF structural sanity checks (`%PDF-` header, `%%EOF` trailer), page-count parity (PDF `/Type /Pages /Count N` vs `length(doc.pages)`), and the `:max_bytes` policy enforcement formerly inlined after `:render`. Closes BLOCKER-04 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- `Rendro.Pipeline.Validate` module exposing `run/2 :: (binary(), Rendro.Document.t()) -> {:ok, binary()} | {:error, atom()}`.
- `Rendro.Error` `:validate`-stage `what`/`next_step` clauses for `:structural_corruption`, `:page_count_mismatch`, and `:max_bytes_exceeded` (D-09).

### Changed (BREAKING)

- Pipeline stage execution order now matches the documented architecture: `build → compose → measure → paginate → render → validate`. Previously stages ran in the order `build → measure → paginate → compose → render`, which inverted compose/measure relative to the spec. Closes BLOCKER-05 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- `max_pages_exceeded` policy errors now fire from the `:paginate` stage stop event rather than mid-pipeline; the policy guard runs after `:paginate` and before `:render`, where page count is final.
- `max_bytes_exceeded` policy errors are now attributed to the `:validate` stage rather than `:render`; the trailing inline `validate_policy(:bytes, ...)` was absorbed into the `:validate` stage body.
- Stage `:stop` events now carry a unified schema across success and error paths: `%{render_id, document_type, deterministic, stage, status, page_count, byte_size}` with an optional `:error` map (`%{kind, stage}`) on `status: :error`. Error-path `page_count` is now derived from the latest known doc state rather than hardcoded to `0`. Closes MINOR-15 from `.planning/v1.0-MILESTONE-AUDIT.md`.
- Top-level `[:rendro, :render, :stop]` event payload mirrors the new stage stop schema (event name unchanged).

### Notes

- Pre-1.0 release; the previous stage order was a bug against the documented architecture (`v1.0-MILESTONE-AUDIT.md` BLOCKER-04, BLOCKER-05). Top-level `[:rendro, :render, :*]` event names are unchanged; only their stop-metadata schema is updated.
- The `Threadline` adapter (`lib/rendro/adapters/threadline.ex`) subscribes only to top-level events and is unaffected by these changes.
- No bridge period, dual emission, or `telemetry_contract_version` field is provided. See `.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md` D-17.

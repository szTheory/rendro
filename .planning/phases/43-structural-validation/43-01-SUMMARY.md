---
phase: 43
plan: 01
status: completed
requirements_completed: [VAL-01]
---

# Plan 43-01 Summary: Hybrid Single-Pass AST Validation

## Work Completed
- Implemented `Rendro.Pipeline.Validate`, a hybrid single-pass AST walker that recursively visits the document structure.
- Implemented validation rules:
  - `CheckReferences` (validates font and image logical names exist in registries)
  - `CheckBounds` (ensures layout bounds are valid)
  - `CheckRequiredKeys` (checks core struct shapes)
- Updated `Rendro.Pipeline` and `Rendro.Telemetry` to run `Validate` immediately before `Render` instead of after `Render`.
- Integrated `max_bytes` size validation directly into `Render` since `Validate` now runs before the binary is generated.
- Added tests in `validate_test.exs` and rule tests.
- Fixed `telemetry_test.exs` to respect the updated stage ordering (`:validate` before `:render`).

## Outcome
The pipeline now structurally validates the document using a single-pass O(N) AST traversal, ensuring correctness before entering the binary generation stage. All tests, including the telemetry event ordering tests, pass successfully.
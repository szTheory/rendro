# Phase 31: Licensing and Hex Metadata

## Goal
Finalize the project's open-source license and ensure Hex package metadata accurately reflects the project.

## Requirements
[REL-01, REL-02]

## Planned work
- Audit `mix.exs` and replace `["UNLICENSED"]` with an SPDX-valid open-source license (e.g., MIT).
- Add the corresponding `LICENSE` file to the repository root.
- Update `mix.exs` project config to include `:description`, `:source_url`, `:homepage_url`, and `:links`.
- Verify the maintainer-facing release copy in `mix.exs`.

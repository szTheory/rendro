# Phase 31 Validation Criteria

This phase is successful if the following conditions are met:

1. **License File:** An SPDX-valid `LICENSE` file (MIT) is present in the repository root.
2. **Hex Package Metadata:** `mix.exs` contains `"MIT"` in the `licenses` package list.
3. **Project Config:** `mix.exs` project config includes `:description`, `:source_url`, `:homepage_url`, and the `:links` property in the `package` function.
4. **Hex Build Verification:** `mix hex.build --unpack` successfully builds the package and includes the `LICENSE` file.
5. **Release Copy Validation:** The `:description` field accurately reflects the maintainer-facing release copy required for public hex.pm packages.
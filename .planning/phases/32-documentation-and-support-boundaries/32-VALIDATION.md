# Phase 32 Validation Criteria

This phase is successful if the following conditions are met:

1. **ExDoc Configuration:** The `mix.exs` file correctly configures `groups_for_extras` to categorize documentation into at least Guides and Policies (or similar rational organization).
2. **README Badges:** The `README.md` file contains status badges for CI, Hex package version, and HexDocs link directly beneath the main heading.
3. **API Stability Policy:** A new guide (e.g., `guides/api_stability.md` or `guides/usage_rules.md`) explicitly details the project's public API stability expectations and release support boundaries for the 0.x.x period.
4. **Verifiable Documentation:** Code examples in the new API stability guide include `# docs-contract: snippet-name` tags to ensure they remain verifiable via the `mix docs.contract` command.
5. **Deprecation Policy:** The API stability guide clearly documents the deprecation policy for public modules.
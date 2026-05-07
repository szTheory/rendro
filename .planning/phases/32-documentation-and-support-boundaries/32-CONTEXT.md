# Phase 32: Documentation and Support Boundaries - Context

**Goal:** Polish the public-facing documentation surfaces and explicitly declare the project's API stability policy before the first public Hex release.

## Decisions

- **D-01: API Stability Document**: Create `guides/api_stability.md` as the authoritative source defining support boundaries and semantic versioning expectations for the `0.1.x` release era.
- **D-02: ExDoc Grouping**: Group additional Markdown files logically using ExDoc's `groups_for_extras` configuration in `mix.exs`, ensuring clear discoverability between conceptual guides and project policies.
- **D-03: README Badges**: Insert CI, Hex.pm, and HexDocs status badges prominently at the top of the `README.md` to indicate repository health and package availability.

## Deferred Ideas

- Additional deep-dive guides or API tutorials are deferred to later milestones post-publication to avoid delaying the `v1.3` release readiness goal.
- Validator-backed compliance and signature surfaces (from Milestone `v1.5`) remain deferred.

## The Agent's Discretion

- Exact wording of `guides/api_stability.md`, but it must cover Elixir ecosystem standards and clarify expectations around core API vs. adapter deprecation policies.
- Specific grouping labels in `mix.exs` `groups_for_extras` (e.g., "Guides" vs. "Policies" or "Documentation"), provided the resulting HexDocs sidebar is well-organized.
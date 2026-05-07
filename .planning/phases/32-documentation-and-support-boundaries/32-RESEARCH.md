# Phase 32: Documentation and Support Boundaries - Research

**Researched:** 2024-05-24
**Domain:** Documentation, ExDoc, API Policy
**Confidence:** HIGH

## Summary

This phase polishes the public-facing documentation and formally declares the API stability boundaries for the `0.1.x` release era. The Elixir ecosystem relies heavily on HexDocs for discoverability and `ex_doc` is already configured in the project. The changes involve modifying `mix.exs` to organize extra files via `groups_for_extras`, updating `README.md` with standard badges, and introducing a new policy document.

**Primary recommendation:** Introduce `guides/api_stability.md` as the primary support boundary document and categorize extras in `mix.exs` using `groups_for_extras: [Guides: [...], Policies: [...]]`.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-03 | The ExDoc `groups_for_extras` configuration must rationally organize the growing list of guides and reference artifacts. | Identified `guides/branding.md`, `guides/integrations.md`, and the new stability doc as the targets for grouping. |
| REL-04 | The README must have appropriate badge state for CI, Hex.pm, and HexDocs. | Provided standard Markdown badge formats pointing to `hex.pm`, `hexdocs.pm`, and GitHub Actions. |
| REL-05 | The project must explicitly define its public API stability policy and release support boundaries (e.g. `usage_rules.md` or similar). | Recommended `guides/api_stability.md` focusing on `@deprecated` tag usage and Semantic Versioning expectations for `0.x.x` vs `1.x.x`. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Documentation Build | Static generation | — | ExDoc processes Markdown and Elixir AST into static HexDocs |
| API Stability Policies | Core API | — | Core maintainers define semantic versioning and deprecation cadence |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ex_doc | ~> 0.40 | Documentation generator | Official Elixir documentation generator, hosts on HexDocs |

## Architecture Patterns

### Recommended Project Structure
```text
guides/
├── branding.md        # Existing
├── integrations.md    # Existing
└── api_stability.md   # New: Explicit API guarantees and support boundaries
```

### Pattern 1: ExDoc Groups for Extras
**What:** Organizing `extras` in the HexDocs sidebar.
**When to use:** When the number of extra Markdown files grows beyond 2-3, preventing clutter in the sidebar.
**Example:**
```elixir
# In mix.exs docs()
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md"
],
groups_for_extras: [
  Guides: [
    "guides/branding.md",
    "guides/integrations.md"
  ],
  Policies: [
    "guides/api_stability.md"
  ]
]
```

### Pattern 2: Standard README Badges
**What:** Visual indicators for package health.
**Example:**
```markdown
# Rendro

[![CI](https://github.com/szTheory/rendro/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/rendro/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/rendro.svg)](https://hex.pm/packages/rendro)
[![HexDocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/rendro)
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build & Tests | ✓ | 1.19.5 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-03 | Configures groups_for_extras | unit | `mix test test/mix/tasks/docs_contract_task_test.exs` | ✅ Wave 0 |
| REL-04 | Validates README badges | unit | `mix test test/docs_contract/readme_doctest_test.exs` | ✅ Wave 0 |
| REL-05 | Verifies policy doc exists | unit | `mix test test/docs_contract/readme_doctest_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- None — existing docs contract tests and pipeline verifications will cover README and mix config changes.

## Sources

### Primary (HIGH confidence)
- Official Elixir ExDoc Documentation - Verified `groups_for_extras` behavior.
- Workspace `mix.exs` - Verified current `ex_doc` usage.
- Workspace `README.md` - Verified current state of the document header.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ExDoc is the standard for Elixir.
- Architecture: HIGH - Grouping extras and badge formats are well known.
- Pitfalls: HIGH - Elixir API stability commonly relies on standard module attributes.

**Research date:** 2024-05-24
**Valid until:** 6 months
<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Audit `mix.exs` and replace `["UNLICENSED"]` with an SPDX-valid open-source license (e.g., MIT).
- Add the corresponding `LICENSE` file to the repository root.
- Update `mix.exs` project config to include `:description`, `:source_url`, `:homepage_url`, and `:links`.
- Verify the maintainer-facing release copy in `mix.exs`.

### the agent's Discretion
None specified in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
None specified in CONTEXT.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Hex metadata updates | Confirmed exact `mix.exs` locations needing updates |
| REL-02 | License verification | Identified standard MIT license text format and files array addition |
</phase_requirements>

# Phase 31: Licensing and Hex Metadata - Research

**Researched:** 2024-05-03
**Domain:** Elixir Hex Packaging and Open Source Licensing
**Confidence:** HIGH

## Summary

The current `mix.exs` defines `"UNLICENSED"` under the `package/0` function in the `:licenses` list. To correctly configure the package for Hex, this needs to be changed to an SPDX-valid license identifier, such as `"MIT"`. We must add an MIT `LICENSE` file at the repository root. We also need to configure `:homepage_url` in the `project/0` definition, and ensure `package/0` exposes the right links. Currently, `:description` and `:source_url` exist in `project/0`, and `:links` exists in `package/0`.

**Primary recommendation:** Replace `"UNLICENSED"` with `"MIT"` in `mix.exs`, add a root `LICENSE` file containing the standard MIT License text, ensure the file is added to the `:files` list in `package/0`, and add `:homepage_url` to the `project/0` function.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hex Package Metadata | Build System | — | `mix.exs` is uniquely responsible for Hex package metadata. |
| Open Source License | Project Root | — | Expected at project root for standard OSS tooling detection. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `Mix.Project` | Any | Build/Packaging | Built-in tooling for configuring Hex packages |

## Architecture Patterns

### Recommended Project Structure
```
/
├── mix.exs         # Package and Project configuration
├── LICENSE         # MIT Open Source License file
└── NOTICE          # (Existing) SIL Open Font License notice for B612 Font
```

### Pattern 1: Hex Package Configuration
**What:** Structuring package metadata for hex.pm.
**When to use:** When publishing an open-source Elixir package.
**Example:**
```elixir
def project do
  [
    app: :rendro,
    version: @version,
    description: "Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination",
    source_url: @source_url,
    homepage_url: @source_url, # Recommended to add this
    package: package(),
    # ...
  ]
end

defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib priv/branded guides .formatter.exs mix.exs README.md LICENSE NOTICE CHANGELOG.md)
  ]
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom License | Custom licensing text | Standard MIT License | Standard licenses are easily recognizable and verified by automated tools like GitHub's license detector. |

## Runtime State Inventory
Step 2.5: SKIPPED (no external dependencies identified / not a refactor/rename phase that affects runtime state)

## Common Pitfalls

### Pitfall 1: Forgetting to include LICENSE in package files
**What goes wrong:** Hex package tarball won't include the license file.
**Why it happens:** The `mix.exs` `:files` list explicitly overrides defaults.
**How to avoid:** Explicitly add `"LICENSE"` to the `:files` array in `mix.exs` under the `package/0` function.

### Pitfall 2: Incorrect License Text Format
**What goes wrong:** Automated tools (like GitHub) fail to detect the MIT license.
**Why it happens:** Typos or missing Copyright year/name.
**How to avoid:** Use the exact standard MIT license text containing:
```text
MIT License

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

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
| REL-01 | Package metadata validation | Unit | `mix hex.build --unpack` | N/A |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements

## Sources

### Primary (HIGH confidence)
- Verified `mix.exs` locally.
- Hex docs verified via `mix help hex.build`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir tools.
- Architecture: HIGH - Defined by standard Mix.Project specs.
- Pitfalls: HIGH - explicitly verified files config in `mix.exs`.

**Research date:** 2024-05-03
**Valid until:** 2025-05-03

# API Stability and Support Boundaries

## Semantic Versioning Expectations

Rendro adheres to Semantic Versioning (SemVer).

### The `0.x.x` Era (Current)
During the `0.1.x` and subsequent `0.x.x` releases, the API is considered stable enough for production use, but minor versions (e.g., `0.1.x` to `0.2.0`) may introduce breaking changes. We commit to providing clear upgrade paths and changelogs for any breaking changes during this era. Patch versions (e.g., `0.1.0` to `0.1.1`) will remain strictly backward compatible and only contain bug fixes or additive features.

### The `1.x.x` Era (Future)
Once Rendro reaches `1.0.0`, breaking changes will only occur in major version bumps (e.g., `1.x.x` to `2.0.0`).

## Core API vs Adapters

- **Core API (`Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.flow/2`):** This is the primary surface area. Breaking changes here will be minimal and heavily telegraphed.
- **Adapters (`Rendro.Adapters.*`):** Adapters integrate with third-party libraries (e.g., Phoenix, Oban, Threadline). Since these depend on external ecosystems, their APIs may need to evolve more frequently. We will strive to align adapter breaking changes with major version changes of their underlying dependencies.
- **Diagnostics (`Rendro.Inspector`, `:diagnostics` map):** The structure of diagnostics maps is intended for developer-facing debugging and is considered stable for common keys (`:level`, `:type`), but additive keys may be introduced in any release.

## Deprecation Policy

When an API is deprecated:
1. It will be marked with Elixir's `@deprecated` attribute.
2. It will continue to function without breaking for at least one minor release in the `0.x.x` era, or one major release in the `1.x.x` era.
3. The documentation will clearly point to the recommended replacement.

# Phase 32: Documentation and Support Boundaries - Pattern Map

**Mapped:** 2024-05-03
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | config | `mix.exs` (self) | exact |
| `README.md` | docs | static | `README.md` (self) | exact |
| `guides/support_boundaries.md` | docs | static | `guides/branding.md` | role-match |

## Pattern Assignments

### `mix.exs` (config, config)

**Analog:** `mix.exs`

**Docs configuration pattern** (lines 79-87):
```elixir
  defp docs do
    [
      main: "Rendro",
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/integrations.md",
        "guides/branding.md"
      ]
    ]
  end
```
*Note:* The new policy file (e.g. `guides/support_boundaries.md`) should be added to the `extras` list here. Additionally, a new `groups_for_extras:` key should be introduced inside the `[ ... ]` keyword list to categorize these guides (and the new policy) rationally. 

**Package files pattern** (lines 66-73):
```elixir
      files: ~w(
        lib
        priv/branded
        guides
        .formatter.exs
        mix.exs
        README.md
        LICENSE
```
*Note:* If the new policy file is placed in `guides/`, it will automatically be included by the `guides` entry in `files: ~w(...)`. If placed in the project root, it must be explicitly added to this list.

### `README.md` (docs, static)

**Analog:** `README.md`

**Header pattern** (lines 1-4):
```markdown
# Rendro

Pure-Elixir PDF generation with deterministic layout and pagination.
```
*Note:* The project does not currently have existing badges. Badges for CI, Hex.pm, and HexDocs should be inserted on line 2, immediately below the `# Rendro` H1 and above the summary paragraph.

### `guides/support_boundaries.md` (docs, static)

**Analog:** `guides/branding.md`

**Guide structure pattern** (lines 1-7):
```markdown
# Branding

This guide shows how to build a branded document with the public font and asset
registration APIs that shipped in Phases 25 through 28. The branded path stays
behind the same truthful scope boundaries as the rest of Rendro: no silent
fallback, no system-font discovery, no remote asset fetching.
```
*Note:* The codebase does not currently contain other project-wide policy files like `CODE_OF_CONDUCT.md` or `CONTRIBUTING.md`. Therefore, the new API stability and support boundaries file should follow the established pattern of standard guides in the `guides/` directory.

**Verified code examples pattern** (from `guides/branding.md`, lines 17-21):
```elixir
# docs-contract: branding-register-assets
doc =
  Rendro.Document.new()
  |> Rendro.Document.register_embedded_font(
```
*Note:* If the support boundaries policy includes any verifiable code examples, they should follow the `# docs-contract: <name>` comment pattern so they are caught by `mix docs.contract`.

## Shared Patterns

### Verified Documentation Snippets
**Source:** `guides/branding.md` and `README.md`
**Apply to:** Any code snippets included in the new documentation guides that can be compiled/evaluated. Use the `# docs-contract: name-of-snippet` marker.

## No Analog Found

None. All files have a suitable analog or are modifying existing established files.

## Metadata

**Analog search scope:** `root`, `guides/`
**Files scanned:** 5 markdown files, 1 config file
**Pattern extraction date:** 2024-05-03
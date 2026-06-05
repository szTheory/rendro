# Phase 82: 1.0.0 Consolidation & Publish - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/release/preflight.ex` | mix task | batch / validation | `lib/mix/tasks/release/preflight.ex` | exact (self) |
| `CHANGELOG.md` | documentation | manual | `CHANGELOG.md` | exact (self) |
| `mix.exs` | config | project config | `mix.exs` | exact (self) |

## Pattern Assignments

### `lib/mix/tasks/release/preflight.ex` (mix task, batch / validation)

**Analog:** `lib/mix/tasks/release/preflight.ex` (existing code to build upon)

**Mix command execution pattern** (lines 10-15):
Add `mix hex.audit` and `mix deps.audit` to the `@phase_2_checks` list so they run automatically using the existing execution pipeline.
```elixir
  @phase_2_checks [
    {"CI", ["ci"]},
    {"Docs Contract", ["docs.contract"]},
    {"Hex Build Unpack", ["hex.build", "--unpack"]},
    {"Hex Publish Dry Run", ["hex.publish", "--dry-run", "--yes"]}
  ]
```

**File artifact verification pattern** (lines 146-163):
Extend this to also check for the absence of `forbidden_paths` like `priv/viewer_evidence/`, `priv/support_matrix.json`, `test/`, etc. Use `File.exists?/1` and `File.dir?/1`.
```elixir
  defp check_hex_artifacts(context, version) do
    case run_command(context, "mix", ["hex.build", "--unpack"]) do
      {_output, 0} ->
        dir = "rendro-#{version}"

        required_files = [
          "LICENSE",
          "README.md",
          "CHANGELOG.md",
          "guides/api_stability.md",
          "guides/branding.md",
          "guides/integrations.md"
        ]

        missing_files =
          Enum.reject(required_files, fn file ->
            File.exists?(Path.join(dir, file))
          end)
```

**Changelog matching pattern** (lines 122-132):
This function needs to be generalized for `1.0.0` and a date `YYYY-MM-DD`, dropping the hardcoded `Unreleased` and brittle text pointers. Use `Regex.match?/2`.
```elixir
  defp check_changelog_release_tail(context) do
    changelog_path = Map.get(context, :changelog_path, "CHANGELOG.md")
    version = context.project_config[:version]

    with {:ok, changelog} <- File.read(changelog_path),
         true <- String.contains?(changelog, "## [#{version}] - Unreleased"),
         true <-
           String.contains?(
             changelog,
             "`render_to_artifact -> Protect.password -> store/deliver`"
           ) do
      pass("Changelog release tail")
```

---

### `CHANGELOG.md` (documentation, manual)

**Analog:** `CHANGELOG.md` (existing format)

**Version Header Pattern** (lines 7-9):
Maintain semantic versioning headers with dates.
```markdown
## [0.3.1] - Unreleased

This release lands the v2.3 Viewer Evidence milestone onto Hex.
```

**Section Structure Pattern** (lines 11-13, 44-46):
Group changes under `### Added`, `### Changed`, etc., and maintain the `### Truthful Boundaries Held` sub-section if applicable.
```markdown
### Added

#### Viewer Evidence (v2.3)
```

---

### `mix.exs` (config, project config)

**Analog:** `mix.exs` (existing file)

**Version declaration pattern** (lines 3-4):
Bump the `@version` module attribute.
```elixir
  @version "0.3.1"
  @source_url "https://github.com/szTheory/rendro"
```

## Shared Patterns

### Validation / Exit Pattern
**Source:** `lib/mix/tasks/release/preflight.ex`
**Apply to:** All preflight check additions
New checks added to `preflight.ex` must follow the `pass/1` or `fail/2` return pattern used throughout the module so they integrate cleanly with `print_summary/2` and exit codes.
```elixir
  defp pass(name), do: %{name: name, status: :pass}
  defp fail(name, output), do: %{name: name, status: :fail, output: output}
```

## Metadata

**Analog search scope:** `lib/mix/tasks/**/*.ex`, `CHANGELOG.md`, `mix.exs`
**Files scanned:** 3
**Pattern extraction date:** 2026-06-05

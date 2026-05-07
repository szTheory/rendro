# Phase 9: CI Scheduler + Release Hardening - Pattern Map

**Mapped:** 2024-04-24
**Files analyzed:** 5
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | config | event-driven | None | no-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `lib/mix/tasks/verify.ex` | utility | batch | `lib/mix/tasks/verify.ex` | exact |
| `scripts/verify_docs.exs` | utility | batch | `scripts/verify_docs.exs` | exact |
| `lib/mix/tasks/release/preflight.ex` | utility | batch | `lib/mix/tasks/release/preflight.ex` | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** None

**Pattern to follow:** Setup a standard Elixir GitHub Actions workflow checking out code, setting up Erlang/Elixir, caching dependencies, and running `mix deps.get` followed by `mix ci`.

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Aliases pattern** (lines 45-49):
```elixir
  defp aliases do
    [
      ci: ["compile --warnings-as-errors", "test", "credo --strict", "dialyzer"]
    ]
  end
```
*Action:* Append `format --check-formatted`, `docs`, and `hex.build` to the existing `ci` alias list to expand it. Update it to be:
```elixir
  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test",
        "credo --strict",
        "dialyzer",
        "docs",
        "hex.build"
      ]
    ]
  end
```

---

### `lib/mix/tasks/verify.ex` (utility, batch)

**Analog:** `lib/mix/tasks/verify.ex`

**Current System.cmd execution pattern (Error Handling)** (lines 20-25):
```elixir
    run_step("Phoenix Example", fn ->
      File.cd!("examples/phoenix_example", fn ->
        {_, 0} = System.cmd("mix", ["compile"])
      end)

      :ok
    end)
```
*Action:* Modify the strict `{_, 0} = System.cmd(...)` match that crashes with a MatchError to run `mix deps.get` first, and use a safe case block returning `:ok` or `:error`.

```elixir
    run_step("Phoenix Example", fn ->
      File.cd!("examples/phoenix_example", fn ->
        System.cmd("mix", ["deps.get"])
        case System.cmd("mix", ["compile"]) do
          {_, 0} -> :ok
          {output, _code} ->
            Mix.shell().error("Compile failed: #{output}")
            :error
        end
      end)
    end)
```

---

### `scripts/verify_docs.exs` (utility, batch)

**Analog:** `scripts/verify_docs.exs`

**Code block verification pattern** (lines 13-25):
```elixir
  rescue
    e ->
      # Skip blocks that are clearly partial or need more context
      if code =~ "..." or code =~ "%{...}" do
        Mix.shell().info("  - Code block (partial) skipped: OK")
      else
        Mix.shell().error("  - Code block failed to compile:\n#{code}\n#{inspect(e)}")
        System.halt(1)
      end
  end
```
*Action:* Update the logic to modify the code block before compiling (e.g. replacing `...` with valid Elixir syntax or `nil`), or switch the message to emit a `Mix.shell().error/info` warning and halt if strict verification is required. Since the requirement is to "exercise code blocks containing ... (or warn rather than silently skipping)", replacing the silently skipping message with a warning is appropriate, or doing a `String.replace(code, "...", ":ok")` before `Code.compile_string/1` to truly exercise it.

---

### `lib/mix/tasks/release/preflight.ex` (utility, batch)

**Analog:** `lib/mix/tasks/release/preflight.ex`

**Version/Tag and system checks pattern** (lines 11-15):
```elixir
    # 1. Check version in mix.exs matches git tag (mocked for now)
    version = Mix.Project.config()[:version]
    Mix.shell().info("Current version: #{version}")
```
*Action:* Implement git tag parity check and dry run hex publish:
```elixir
    # 1. Check version in mix.exs matches git tag
    version = Mix.Project.config()[:version]
    
    case System.cmd("git", ["describe", "--tags", "--abbrev=0"]) do
      {tag, 0} ->
        tag = String.trim(tag)
        expected = "v#{version}"
        if tag != expected do
          Mix.raise("Git tag #{tag} does not match mix.exs version #{expected}")
        end
      _ -> Mix.raise("Failed to retrieve git tag")
    end
    
    # ... after CI and git status checks
    
    Mix.shell().info("Running mix hex.publish --dry-run...")
    case System.cmd("mix", ["hex.publish", "--dry-run"]) do
      {_, 0} -> :ok
      {output, _} -> Mix.raise("Hex publish dry run failed:\n#{output}")
    end
```

## Shared Patterns

### Shell Command Execution
**Source:** `lib/mix/tasks/verify.ex` and `lib/mix/tasks/release/preflight.ex`
**Apply to:** All Mix tasks running shell commands
Always use `System.cmd` safely inside a case statement and bubble up failures gracefully using `:error` or `Mix.raise/1` instead of bare matches like `{_, 0} = System.cmd(...)`.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns if they exist, or standard conventions):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.github/workflows/ci.yml` | config | event-driven | First GitHub Action config in this repo. |

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `scripts/`, `mix.exs`, `.github/`
**Files scanned:** 5
**Pattern extraction date:** 2024-04-24

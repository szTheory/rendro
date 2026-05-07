# Phase 31: Licensing and Hex Metadata - Pattern Map

**Mapped:** 2024-05-27
**Files analyzed:** 2
**Analogs found:** 1 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | config | `mix.exs` | exact |
| `LICENSE` | documentation | static text | `NOTICE` | partial |

## Pattern Assignments

### `mix.exs` (config, config)

**Analog:** `mix.exs`

**Project metadata pattern** (lines 14-20):
```elixir
      name: "Rendro",
      description:
        "Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination",
      source_url: @source_url,
```

**Package config pattern** (lines 60-75):
```elixir
  defp package do
    [
      licenses: ["UNLICENSED"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        priv/branded
        guides
        .formatter.exs
        mix.exs
        README.md
        NOTICE
        CHANGELOG.md
      )
    ]
  end
```

*(Planner should update the `:licenses` key to an SPDX identifier like `["MIT"]` and ensure `homepage_url` or similar fields are present in the `project` or `package` list if needed.)*

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `LICENSE` | documentation | static text | Standard legal text file. No custom pattern necessary; standard MIT/Apache license text should be used. The `NOTICE` file exists but it is specifically for 3rd-party font licensing. |

## Shared Patterns

No cross-cutting shared patterns were identified for this phase, as the scope is limited to project root configuration and licensing metadata.

## Metadata

**Analog search scope:** `**/mix.exs`, root text files
**Files scanned:** 2
**Pattern extraction date:** 2024-05-27

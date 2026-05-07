<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Validation Approach:** External Binary Adapter.
- **Target Validator:** `pdfinfo` (from Poppler).
- **Integration Shape:** `Rendro.Adapters.Poppler` module.
- **Missing Dependency Handling:** Runtime Error Tuple `{:error, {:missing_executable, "pdfinfo"}}`.

### the agent's Discretion
None explicitly stated. The specifics of parsing `pdfinfo` output and ExUnit test integration are left to implementation.

### Deferred Ideas (OUT OF SCOPE)
- Full PDF compliance parser in pure Elixir.
- Heavier, stricter tools like VeraPDF (deferred for now).
</user_constraints>

# Phase 44: Validator-backed Trust Surfaces - Research

**Researched:** 2024-05-24
**Domain:** Elixir External Binary Adapters, PDF Validation
**Confidence:** HIGH

## Summary
The goal is to implement an external binary adapter `Rendro.Adapters.Poppler` that shells out to `pdfinfo` for validating generated PDFs. This validates structural integrity. The adapter will return a validation result (parsed metadata) or standard error tuples, importantly handling missing dependencies with `{:error, {:missing_executable, "pdfinfo"}}` to gracefully fail in constrained environments (like CI without Poppler installed).

**Primary recommendation:** Use `System.find_executable/1` to guard the execution and `System.cmd/3` with `stderr_to_stdout: true` to capture `pdfinfo` output for parsing or error reporting.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PDF Validation | API / Backend | — | The Elixir backend orchestrates external binaries via Adapters to validate generated artifacts. |
| External Binary Guarding | API / Backend | — | Ensuring dependencies exist before shelling out prevents unhandled exceptions in the runtime environment. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `System` (Elixir Core) | n/a | Execution and resolution of external binaries | Built-in robust handling for OS commands. `System.find_executable/1` and `System.cmd/3` are the canonical approach. |
| `pdfinfo` (Poppler) | 22+ | PDF structural validation and metadata extraction | Standard open-source tool; parsing fails on broken PDFs, proving basic validity. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `pdfinfo` | `qpdf --check` | `qpdf` provides deeper structural checks, but `pdfinfo` is lighter and often already installed or easier to get via standard poppler-utils packages. |
| `pdfinfo` | Pure Elixir Parser | Hand-rolling a parser is massive effort, error-prone, and distracts from core rendering engine. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/
└── rendro/
    └── adapters/
        └── poppler.ex      # The external binary adapter logic
test/
└── rendro/
    └── adapters/
        └── poppler_test.exs
```

### Pattern 1: Safe External Binary Execution
**What:** Guarding external binary calls with `System.find_executable/1`.
**When to use:** Whenever shelling out to tools that might not be installed on all target environments (e.g., CI/CD runners, minimal Docker images).
**Example:**
```elixir
// Source: Elixir standard pattern
def validate(file_path) do
  case System.find_executable("pdfinfo") do
    nil ->
      {:error, {:missing_executable, "pdfinfo"}}
    executable ->
      execute_pdfinfo(executable, file_path)
  end
end
```

### Pattern 2: Capturing Stderr and Exit Codes
**What:** Using `System.cmd/3` to accurately determine success or failure.
**When to use:** When evaluating external tools whose success is tied to zero exit codes, and whose error messages may be written to stderr.
**Example:**
```elixir
defp execute_pdfinfo(executable, file_path) do
  case System.cmd(executable, [file_path], stderr_to_stdout: true) do
    {output, 0} -> {:ok, parse_metadata(output)}
    {output, _exit_code} -> {:error, {:invalid_pdf, output}}
  end
end
```

### Anti-Patterns to Avoid
- **Blind Shelling Out:** Calling `System.cmd` without checking if the binary exists using `find_executable/1`. Causes ugly `Erlang error: :enoent` crashes.
- **Ignoring Exit Codes:** Assuming that any output means success. `pdfinfo` will return `1` for corrupt files while still printing errors.
- **Using `Port` when `System.cmd` is sufficient:** `Port` is for long-running processes; validation is a discrete one-off task.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF Validation | Pure Elixir PDF Parser | `pdfinfo` (Poppler) | The PDF spec is notoriously complex. Validating it correctly requires parsing xref tables, objects, streams, etc. An external robust tool guarantees accuracy without maintaining thousands of lines of code. |

**Key insight:** Deferring complex format compliance to established C/C++ libraries reduces the maintenance burden on the Elixir core.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | none |
| Live service config | None | none |
| OS-registered state | None | none |
| Secrets/env vars | None | none |
| Build artifacts | None | none |

## Common Pitfalls

### Pitfall 1: Unhandled :enoent crashes
**What goes wrong:** Test suites crash abruptly if a user runs tests in an environment without `poppler-utils` installed.
**Why it happens:** `System.cmd/3` raises `Erlang error: :enoent` if the binary doesn't exist.
**How to avoid:** Always prepend with `System.find_executable("pdfinfo")`.
**Warning signs:** CI failing on fresh runner images.

### Pitfall 2: Stderr Ignored
**What goes wrong:** Validation fails but the error message is lost.
**Why it happens:** `System.cmd/3` only captures stdout by default. `pdfinfo` (and many tools) write errors to stderr.
**How to avoid:** Pass `[stderr_to_stdout: true]` to `System.cmd`.

### Pitfall 3: Not Handling Whitespace
**What goes wrong:** Parsed metadata has trailing spaces or carriage returns.
**Why it happens:** `pdfinfo` output uses varying amounts of whitespace for alignment (e.g. `Pages:          1`).
**How to avoid:** Use `String.split(line, ":", parts: 2)` and `String.trim/1` when parsing the metadata into a map.

## Code Examples

### PDFInfo Parser Implementation
```elixir
defmodule Rendro.Adapters.Poppler do
  @moduledoc """
  Adapter for Poppler's `pdfinfo` CLI tool.
  """

  @doc """
  Validates a PDF and extracts its metadata using `pdfinfo`.

  Returns `{:ok, metadata_map}` on success.
  Returns `{:error, {:missing_executable, "pdfinfo"}}` if poppler is not installed.
  Returns `{:error, {:invalid_pdf, reason}}` if the PDF is corrupt.
  """
  def validate(file_path) do
    case System.find_executable("pdfinfo") do
      nil ->
        {:error, {:missing_executable, "pdfinfo"}}

      executable ->
        case System.cmd(executable, [file_path], stderr_to_stdout: true) do
          {output, 0} ->
            {:ok, parse_output(output)}

          {output, _exit_code} ->
            {:error, {:invalid_pdf, String.trim(output)}}
        end
    end
  end

  defp parse_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          Map.put(acc, String.trim(key), String.trim(value))

        _ ->
          acc
      end
    end)
  end
end
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `pdfinfo` | `Rendro.Adapters.Poppler` | ✗ (Depends on env) | — | Handled via runtime `{:error, {:missing_executable, "pdfinfo"}}` |

**Missing dependencies with fallback:**
- `pdfinfo`: Handled programmatically so test suites can skip execution.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/adapters/poppler_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Returns missing executable error | unit | `mix test test/rendro/adapters/poppler_test.exs` | ❌ Wave 0 |
| REQ-02 | Validates valid PDF | unit | `mix test test/rendro/adapters/poppler_test.exs` | ❌ Wave 0 |
| REQ-03 | Returns error for invalid PDF | unit | `mix test test/rendro/adapters/poppler_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/rendro/adapters/poppler_test.exs`
- [ ] Shared fixtures for a dummy valid PDF and an invalid PDF.

## Sources

### Primary (HIGH confidence)
- Elixir standard docs - `System.find_executable/1`, `System.cmd/3`
- Poppler documentation (`pdfinfo` standard exit codes and stderr usage)
- `.planning/phases/44-validator-backed-trust-surfaces/44-CONTEXT.md`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir System module is standard.
- Architecture: HIGH - Dictated directly by user context (CONTEXT.md).
- Pitfalls: HIGH - Known Erlang `:enoent` crash issue is well-documented.

**Research date:** 2024-05-24
**Valid until:** 2025-05-24
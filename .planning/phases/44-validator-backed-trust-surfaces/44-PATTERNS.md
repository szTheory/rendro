# Phase 44: Validator-backed Trust Surfaces - Pattern Map

**Mapped:** 2024-05-20
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/adapters/poppler.ex` | adapter | shell-out | `lib/mix/tasks/rendro.visual_uat.ex` | partial match |
| `test/rendro/adapters/poppler_test.exs` | test | shell-out | `test/rendro/pipeline/render_test.exs` | partial match |

## Pattern Assignments

### `lib/rendro/adapters/poppler.ex` (adapter, shell-out)

**Analog:** `lib/mix/tasks/rendro.visual_uat.ex` and `lib/mix/tasks/verify.ex`

**Binary Checking Pattern** (lines 87-97 in `lib/mix/tasks/rendro.visual_uat.ex`):
```elixir
  defp ensure_pdfinfo do
    case System.find_executable("pdfinfo") do
      nil ->
        {:error, {:missing_executable, "pdfinfo"}}

      _path ->
        :ok
    end
  end
```

**Executing Command Pattern** (lines 150-156 in `lib/mix/tasks/verify.ex`):
```elixir
  defp run_system_step(command, args) do
    {output, exit_code} = System.cmd(command, args, stderr_to_stdout: true)

    if exit_code == 0 do
      :ok
    else
      {:error, exit_code, output}
    end
  end
```

---

### `test/rendro/adapters/poppler_test.exs` (test, shell-out)

**Analog:** `test/rendro/pipeline/render_test.exs`

**Conditional Test Execution Pattern** (lines 72-88):
```elixir
    test "validates generated PDF via pdfinfo" do
      case System.find_executable("pdfinfo") do
        nil ->
          IO.puts("Skipping validation test: pdfinfo not installed")
          assert {:error, {:missing_executable, "pdfinfo"}} = Rendro.Adapters.Poppler.validate(pdf_path)

        _ ->
          assert :ok = Rendro.Adapters.Poppler.validate(pdf_path)
      end
    end
```

## Shared Patterns

### Error Tuples
**Apply to:** `lib/rendro/adapters/poppler.ex`
Use standard Elixir error tuples (e.g., `{:error, {:missing_executable, "pdfinfo"}}`) to handle missing dependencies gracefully, allowing callers to handle this condition at runtime without crashing.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`
**Files scanned:** 2
**Pattern extraction date:** 2024-05-20

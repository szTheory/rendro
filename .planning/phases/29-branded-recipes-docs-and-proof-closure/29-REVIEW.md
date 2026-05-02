---
phase: 29-branded-recipes-docs-and-proof-closure
reviewed: 2024-05-20T12:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/rendro/recipes/branded_invoice.ex
  - lib/mix/tasks/rendro.visual_uat.ex
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 29: Code Review Report

**Reviewed:** 2024-05-20T12:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Performed a standard depth review of `lib/rendro/recipes/branded_invoice.ex` and `lib/mix/tasks/rendro.visual_uat.ex`. The codebase is well-structured and securely handles PDF rendering and LLM verification integration. However, a few warnings were identified: a potential crash on non-integer quantities in the invoice recipe, missing validation for required invoice metadata that could obscure errors, and a lack of guaranteed file cleanup for temporary PDFs during Visual UAT. A minor path traversal info-level issue was also identified in the UAT script's CLI argument handling.

## Warnings

### WR-01: Float quantities cause crashes in `body_section`

**File:** `lib/rendro/recipes/branded_invoice.ex:97`
**Issue:** `Integer.to_string(item.qty)` assumes quantity is strictly an integer. If the caller provides a float quantity (e.g., `1.5` hours of consulting), this will raise a `FunctionClauseError` from the `Integer` module.
**Fix:** Use `to_string/1` or string interpolation to safely stringify any number format:
```elixir
      Enum.map(items, fn item ->
        [item.name, to_string(item.qty), "$#{item.price}"]
      end)
```

### WR-02: Missing validation for required invoice data

**File:** `lib/rendro/recipes/branded_invoice.ex:123`
**Issue:** `validate_data!` thoroughly validates `brand`, but does not validate the presence of `:id`, `:date`, or `:items`. If any of these are missing, `header_section` or `body_section` will fail with a confusing `FunctionClauseError` rather than the `ArgumentError` expected by callers.
**Fix:** Add validation for the remaining required fields to prevent opaque errors:
```elixir
  defp validate_data!(%{brand: %{font_name: font_name, logo_name: logo_name}} = data)
       when is_atom(font_name) and is_atom(logo_name) do
    unless Map.has_key?(data, :id) and Map.has_key?(data, :date) and Map.has_key?(data, :items) do
      raise ArgumentError, "data must include :id, :date, and :items keys"
    end
    :ok
  end
```

### WR-03: Temporary PDF file leak on exception

**File:** `lib/mix/tasks/rendro.visual_uat.ex:89-98`
**Issue:** `tmp_pdf` is removed only via explicit `File.rm(tmp_pdf)` calls inside the `System.cmd` match branches. If `System.cmd` raises an exception (e.g., due to memory exhaustion or unexpected VM errors), the temporary file is never cleaned up and leaks into the OS temp directory.
**Fix:** Wrap the command execution and cleanup in a `try...after` block:
```elixir
      File.write!(tmp_pdf, pdf_binary)

      try do
        case System.cmd(
               "pdftoppm",
               ["-png", "-r", Integer.to_string(@raster_dpi), "-singlefile", tmp_pdf, out_prefix],
               stderr_to_stdout: true
             ) do
          {_out, 0} ->
            {:ok, "#{out_prefix}.png"}

          {out, code} ->
            {:error, "pdftoppm failed (code #{code}):\n#{out}"}
        end
      after
        File.rm(tmp_pdf)
      end
```

## Info

### IN-01: Path traversal risk in phase directory lookup

**File:** `lib/mix/tasks/rendro.visual_uat.ex:60`
**Issue:** `locate_phase_dir(phase)` uses the `phase` CLI argument directly in a wildcard glob (`"#{@phases_root}/#{phase}-*"`). While this is a local developer tool, passing directory traversal sequences (like `"../"`) allows traversing out of the phases directory.
**Fix:** Sanitize the CLI input by taking the basename:
```elixir
  defp locate_phase_dir(phase) do
    safe_phase = Path.basename(phase)
    prefix = "#{@phases_root}/#{safe_phase}-"
    # ...
```

---

_Reviewed: 2024-05-20T12:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
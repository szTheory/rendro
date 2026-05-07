---
phase: 16-phoenix-error-boundary-proof
reviewed: 2024-05-24T12:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/rendro/adapters/phoenix.ex
  - test/rendro/adapters/phoenix_test.exs
findings:
  critical: 0
  warning: 3
  info: 1
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2024-05-24T12:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The review evaluated the Phoenix adapter and its test suite for Rendro. The implementation correctly handles the successful generation path and integrates smoothly with Phoenix's response cycle. However, defensive checks are lacking in a few places: there is no catch-all for unknown error formats, the downloaded filename is missing sanitization, and the exception handling strategy for the requested format uses an overly broad rescue. Fixing these warnings will improve the resilience of the adapter.

## Warnings

### WR-01: Missing Fallback Error Clause in Render Cases

**File:** `lib/rendro/adapters/phoenix.ex:18-19`
**Issue:** The `case Rendro.render(doc)` block exclusively pattern-matches `{:ok, binary}` and `{:error, %Rendro.Error{} = error}`. If `Rendro.render/1` ever surfaces a different error type (e.g. `{:error, :timeout}`, `{:error, "File not found"}`), a `CaseClauseError` will occur and the process will abruptly crash instead of returning a 500 status.
**Fix:**
```elixir
      case Rendro.render(doc) do
        {:ok, binary} ->
          # ...
        {:error, %Rendro.Error{} = error} ->
          handle_error(conn, error)
        {:error, other_error} ->
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(500, "Internal Server Error: #{inspect(other_error)}")
      end
```
*(Note: Apply this fallback to both `render_pdf/3` and `preview_pdf/2`.)*

### WR-02: Unsanitized Filename in Content-Disposition Header

**File:** `lib/rendro/adapters/phoenix.ex:15`
**Issue:** The `filename` variable is interpolated directly into the `content-disposition` header. If `filename` includes double quotes (`"`), it breaks the disposition attribute format. Furthermore, if the user controls this filename and it contains `\r` or `\n` characters, `Plug.Conn.put_resp_header/3` will raise an `ArgumentError` and crash the connection.
**Fix:** Sanitize the input filename before interpolation.
```elixir
    def render_pdf(conn, doc, filename \\ "document.pdf") do
      safe_filename = String.replace(filename, ~r/["\r\n]/, "")
      
      case Rendro.render(doc) do
        {:ok, binary} ->
          conn
          |> put_resp_content_type("application/pdf")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{safe_filename}\"")
          |> send_resp(200, binary)
```

### WR-03: Overly Broad Exception Rescue

**File:** `lib/rendro/adapters/phoenix.ex:43`
**Issue:** The error handler uses `rescue _ -> "text"` which catches all exceptions. Overly broad rescue blocks mask unexpected application crashes (such as an invalid `conn` object or entirely unrelated bugs) making debugging more difficult. `Phoenix.Controller.get_format/1` specifically raises `RuntimeError` when the format has not been fetched or stored.
**Fix:** Explicitly rescue `RuntimeError`.
```elixir
      format =
        try do
          Phoenix.Controller.get_format(conn)
        rescue
          RuntimeError -> "text"
        end
```

## Info

### IN-01: Unconditional Test Suite Failure on Missing Optional Dependencies

**File:** `test/rendro/adapters/phoenix_test.exs:71`
**Issue:** If the optional `:phoenix` and `:plug` dependencies are omitted, the test calls `flunk/1`, which explicitly fails the entire test suite. While this guards against silently skipping checks in CI pipelines, it forces consumers running local tests without those dependencies to face failures. 
**Fix:** If the dependencies are truly optional for running the suite locally, consider warning to the console and excluding the test file gracefully, or using `@moduletag :skip`.

---

_Reviewed: 2024-05-24T12:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

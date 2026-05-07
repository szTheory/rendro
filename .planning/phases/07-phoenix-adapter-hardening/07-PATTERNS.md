# Phase 07: Phoenix Adapter Hardening + Example Skeleton - Pattern Map

**Mapped:** 2024-04-27
**Files analyzed:** 4
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/adapters/phoenix.ex` | adapter | request-response | `lib/rendro/adapters/accrue.ex` | role-match |
| `lib/rendro/error.ex` | model | n/a | None | n/a |
| `examples/phoenix_example/mix.exs` | config | n/a | `mix.exs` (root) | role-match |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` | controller | request-response | Existing `pdf_controller.ex` | exact |

## Pattern Assignments

### `lib/rendro/adapters/phoenix.ex` (adapter, request-response)

**Analog:** `lib/rendro/adapters/accrue.ex`

**Conditional Compilation Pattern** (lines 1-2):
The adapter will use a similar top-level `if` block as `accrue.ex`, but with a novel `else` fallback stub:
```elixir
if Code.ensure_loaded?(Plug.Conn) and Code.ensure_loaded?(Phoenix) do
  defmodule Rendro.Adapters.Phoenix do
    # ... actual implementation ...
  end
else
  defmodule Rendro.Adapters.Phoenix do
    @moduledoc false
    
    def render_pdf(_conn, _doc, _filename \\ "document.pdf") do
      raise RuntimeError, """
      The Rendro Phoenix adapter requires :plug and :phoenix dependencies.
      Please add them to your mix.exs to use Rendro.Adapters.Phoenix.
      """
    end

    def preview_pdf(_conn, _doc) do
      raise RuntimeError, """
      The Rendro Phoenix adapter requires :plug and :phoenix dependencies.
      Please add them to your mix.exs to use Rendro.Adapters.Phoenix.
      """
    end
  end
end
```

### `lib/rendro/error.ex` (model, n/a)

**Analog:** None (Novel pattern for Rendro)

**String.Chars Protocol Pattern**:
Implement the built-in `String.Chars` protocol at the bottom of the file to render a formatted string with `what`, `where`, `why`, and `next`:
```elixir
defimpl String.Chars, for: Rendro.Error do
  def to_string(error) do
    """
    Rendro Error in #{error.stage} stage:
    
    What:  #{error.what}
    Where: #{error.where}
    Why:   #{error.why}
    
    Next:  #{error.next}
    """
  end
end
```

### `examples/phoenix_example/mix.exs` (config, n/a)

**Analog:** None (using standard Phoenix >= 1.7 Bandit configuration)

**Server Config Pattern**:
Update deps to include Bandit:
```elixir
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:bandit, "~> 1.0"},
      {:rendro, path: "../.."}
    ]
  end
```

### `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` (controller, request-response)

**Analog:** `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex`

**Error Handling Pattern** (existing `render_pdf` needs updating):
To take advantage of `String.Chars`, update Phoenix adapter to format the struct.

```elixir
# Update in phoenix.ex's render_pdf/preview_pdf:
{:error, %Rendro.Error{} = error} ->
  conn
  |> put_resp_content_type("text/plain")
  |> send_resp(500, to_string(error))
```

## Shared Patterns

### Conditional Compilation & Stubbing
**Source:** `lib/rendro/adapters/phoenix.ex` (New pattern)
**Apply to:** Optional adapters that previously implicitly compiled, to raise explicit `RuntimeError` on missing dependencies.

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/rendro/error.ex` | model | n/a | First struct to explicitly implement `String.Chars` |

## Metadata

**Analog search scope:** `lib/rendro/adapters/*.ex`, `lib/rendro/*.ex`, `examples/phoenix_example/*`
**Files scanned:** 4 target files + analogies
**Pattern extraction date:** 2024-04-27

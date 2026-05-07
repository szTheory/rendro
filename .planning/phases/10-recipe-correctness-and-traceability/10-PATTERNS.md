# Phase 10: Recipe Correctness + Traceability Sync - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/adapters/mailglass.ex` | service | file-I/O | `lib/rendro/adapters/mailglass.ex` | exact |
| `lib/rendro/adapters/accrue.ex` | service | transform | `lib/rendro/adapters/accrue.ex` | exact |
| `test/rendro/adapters/mailglass_test.exs` | test | file-I/O | `test/rendro/adapters/mailglass_test.exs` | exact |
| `test/rendro/adapters/accrue_test.exs` | test | transform | `test/rendro/adapters/accrue_test.exs` | exact |
| `guides/integrations.md` | config | request-response | `guides/integrations.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |

## Pattern Assignments

### `lib/rendro/adapters/mailglass.ex` (service, file-I/O)

**Analog:** `lib/rendro/adapters/mailglass.ex`

**Optional dependency guard + module contract** (lines 1-10, 27-33):
```elixir
if Code.ensure_loaded?(Mailglass) do
  defmodule Rendro.Adapters.Mailglass do
    @moduledoc """
    This module is only compiled when `Mailglass` is available at compile
    time (via `Code.ensure_loaded?/1`). If `:mailglass` is not in your
    project's dependencies, this module is absent and core Rendro is
    unaffected.

    `attach_pdf/3` never raises — all failure paths return an `{:error, _}` tuple:
```

**Public entrypoint + render-then-attach flow** (lines 56-84):
```elixir
@spec attach_pdf(term(), Rendro.Document.t(), String.t()) ::
        term()
        | {:error, Rendro.Error.t()}
        | {:error, {:unrecognized_message_shape, atom() | term()}}
def attach_pdf(email_or_message, document, filename \\ @default_filename)

def attach_pdf(email_or_message, %Rendro.Document{} = document, filename)
    when is_binary(filename) do
  case Rendro.render(document) do
    {:ok, binary} -> attach_binary(email_or_message, binary, filename)
    {:error, _} = err -> err
  end
end

defp attach_binary(email_or_message, binary, filename) do
  attachment = build_attachment(binary, filename)

  cond do
    mailglass_message?(email_or_message) ->
      attach_to_mailglass(email_or_message, attachment)

    swoosh_email?(email_or_message) ->
      Swoosh.Email.attachment(email_or_message, attachment)

    true ->
      {:error,
       Rendro.Error.from_stage(:render, {:invalid_email_target, email_or_message}, %{})}
  end
end
```

**Message-shape admission + extraction pattern** (lines 93-128):
```elixir
defp mailglass_message?(%Mailglass.Message{}), do: true

defp mailglass_message?(value) when is_struct(value) do
  mod = value.__struct__

  mod
  |> Atom.to_string()
  |> String.ends_with?(".Message") and
    function_exported?(mod, :update_swoosh, 2)
end

defp extract_swoosh(%{swoosh: %Swoosh.Email{} = email}), do: {:ok, email}
defp extract_swoosh(%{email: %Swoosh.Email{} = email}), do: {:ok, email}

defp extract_swoosh(other) when is_struct(other),
  do: {:error, {:unrecognized_message_shape, other.__struct__}}
```

**Replacement `put_swoosh/2` shape to copy** (source: `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md` lines 121-143):
```elixir
defp put_swoosh(message, swoosh_email) when is_struct(message) do
  mod = message.__struct__

  cond do
    function_exported?(mod, :update_swoosh, 2) ->
      apply(mod, :update_swoosh, [message, swoosh_email])

    Map.has_key?(message, :swoosh) ->
      %{message | swoosh: swoosh_email}

    Map.has_key?(message, :email) ->
      %{message | email: swoosh_email}

    true ->
      {:error, {:unrecognized_message_shape, mod}}
  end
end
```

### `lib/rendro/adapters/accrue.ex` (service, transform)

**Analog:** `lib/rendro/adapters/accrue.ex`

**Optional dependency guard + typed tuple surface** (lines 1-10, 42-58):
```elixir
if Code.ensure_loaded?(Accrue) do
  defmodule Rendro.Adapters.Accrue do
    @spec recipe(term()) ::
            {:ok, Rendro.Document.t()} | {:error, {:invalid_invoice, term()}}
    def recipe(%Accrue.Invoice{} = invoice) do
      header = build_header(invoice)
      content = build_content(invoice)
      footer = build_footer(invoice)

      doc =
        Rendro.flow(content,
          header: header,
          footer: footer
        )

      {:ok, doc}
    end

    def recipe(other), do: {:error, {:invalid_invoice, other}}
```

**Current build pipeline to preserve** (lines 60-99):
```elixir
defp build_header(%Accrue.Invoice{id: id, issued_at: issued_at, customer: customer}) do
  [
    Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
    Rendro.block(Rendro.text("Issued: #{inspect(issued_at)}", size: 10)),
    Rendro.block(Rendro.text("Bill to: #{customer_name(customer)}", size: 10))
  ]
end

defp build_content(%Accrue.Invoice{line_items: line_items, total: total}) do
  rows =
    Enum.map(line_items || [], fn %Accrue.LineItem{} = item ->
      [
        to_string(item.description),
        to_string(item.quantity),
        format_amount(item.unit_amount),
        format_amount(item.subtotal)
      ]
    end)
```

**Nested validation pattern to copy** (source: `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md` lines 367-387):
```elixir
def recipe(%Accrue.Invoice{line_items: items} = invoice)
    when is_list(items) do
  if Enum.all?(items, &match?(%Accrue.LineItem{}, &1)) do
    # ... build doc ...
    {:ok, doc}
  else
    {:error, {:invalid_invoice, {:invalid_line_items, items}}}
  end
end

def recipe(%Accrue.Invoice{} = invoice) do
  {:error, {:invalid_invoice, invoice}}
end

def recipe(other), do: {:error, {:invalid_invoice, other}}
```

**Issued-at formatting helper shape to add** (source: `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md` lines 480-488, tightened by Phase 10 decisions to date-only):
```elixir
defp format_issued_at(nil), do: ""
defp format_issued_at(%Date{} = d), do: Date.to_iso8601(d)
defp format_issued_at(%NaiveDateTime{} = ndt), do: ndt |> NaiveDateTime.to_date() |> Date.to_iso8601()
defp format_issued_at(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
```

### `test/rendro/adapters/mailglass_test.exs` (test, file-I/O)

**Analog:** `test/rendro/adapters/mailglass_test.exs`

**Fixture + sample document layout** (lines 16-26, 41-50):
```elixir
defmodule Mailglass.Wrapper.Message do
  @moduledoc false
  defstruct [:id, :payload]

  def update_swoosh(%__MODULE__{} = msg, _swoosh), do: msg
end

defp sample_document do
  text = %Rendro.Text{content: "Invoice", font: "Helvetica", size: 12, color: {0, 0, 0}}
  block = %Rendro.Block{content: text, x: 10, y: 20}
  page = %Rendro.Page{blocks: [block]}
  %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Invoice"}}
end
```

**Describe-block organization for happy path vs negative path** (lines 52-71, 101-123, 125-180):
```elixir
describe "attach_pdf/3 with Swoosh.Email input" do
  test "renders the document and adds an attachment" do
    email = Swoosh.Email.new()
    result = Adapter.attach_pdf(email, sample_document(), "invoice.pdf")
```

```elixir
describe "attach_pdf/3 error paths" do
  test "returns {:error, %Rendro.Error{}} when render fails" do
    email = Swoosh.Email.new()

    assert {:error, %Rendro.Error{}} =
             Adapter.attach_pdf(email, failing_document(), "invoice.pdf")
  end
end
```

```elixir
describe "attach_pdf/3 negative paths" do
  test "returns {:error, {:unrecognized_message_shape, _}} for a Mailglass.* struct without :swoosh/:email (CR-01)" do
    wrapper = %Mailglass.Wrapper.Message{id: 1, payload: "data"}

    result =
      try do
        Adapter.attach_pdf(wrapper, sample_document(), "x.pdf")
      rescue
        e -> {:raised, e}
      end

    assert {:error, {:unrecognized_message_shape, Mailglass.Wrapper.Message}} = result
  end
end
```

**Add the missing wrapper-success regression using the same fixture style** (source: `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md` lines 146-157):
- First extend the local fixture to `defstruct [:id, :payload, :swoosh]`.
```elixir
test "Mailglass.* wrapper with :swoosh and own update_swoosh/2 is re-wrapped via the wrapper's module" do
  msg = %Mailglass.Wrapper.Message{
    id: 1,
    payload: "data",
    swoosh: Swoosh.Email.new()
  }

  assert {:ok, %Mailglass.Wrapper.Message{}} =
           Adapter.attach_pdf(msg, sample_document(), "x.pdf")
end
```

### `test/rendro/adapters/accrue_test.exs` (test, transform)

**Analog:** `test/rendro/adapters/accrue_test.exs`

**Sample invoice fixture + happy-path structure** (lines 6-17, 19-37):
```elixir
defp sample_invoice do
  %Accrue.Invoice{
    id: "INV-001",
    customer: %{name: "Acme", email: "billing@acme.test"},
    line_items: [
      %Accrue.LineItem{description: "Widget", quantity: 2, unit_amount: 1500, subtotal: 3000},
      %Accrue.LineItem{description: "Gizmo", quantity: 1, unit_amount: 500, subtotal: 500}
    ],
    total: 3500,
    issued_at: ~D[2026-04-26]
  }
end
```

```elixir
describe "recipe/1 happy path" do
  test "returns {:ok, %Rendro.Document{}} for a valid Accrue.Invoice" do
    assert {:ok, %Rendro.Document{} = doc} = Adapter.recipe(sample_invoice())
    assert is_list(doc.content) and doc.content != []
  end
```

**Validation-block pattern to extend** (lines 47-50):
```elixir
describe "recipe/1 input validation" do
  test "returns {:error, {:invalid_invoice, _}} for non-Invoice input" do
    assert {:error, {:invalid_invoice, :not_an_invoice}} = Adapter.recipe(:not_an_invoice)
  end
end
```

**Add two focused regressions in the same block shape:**
- Invalid nested `line_items` entry returns `{:error, {:invalid_invoice, _}}`.
- `issued_at` rendering asserts `"Issued: 2026-04-26"` and rejects `"~D["` in `inspect(doc, ...)`.

### `guides/integrations.md` (config, request-response)

**Analog:** `guides/integrations.md`

**Section layout to preserve** (lines 158-246 for Mailglass; 250-348 for Accrue):
```md
## Mailglass

### Setup
...

### Verification
...

### Failure diagnostics
| Error tuple | When it occurs | What to check |
```

```md
## Accrue

### Setup
...

### Recipe contract
...

### Verification
...

### Failure diagnostics
| Error tuple | When it occurs | What to check |
```

**Mailglass failure-table wording pattern** (lines 242-246):
```md
| `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` | The first argument is neither a `%Swoosh.Email{}` nor a recognized Mailglass message struct. `value` echoes the caller's input back for inspection. | Ensure the first argument is a `%Swoosh.Email{}` or a `%Mailglass.Message{}` (or a struct whose module name ends in `.Message` and exports `update_swoosh/2`). Do not pass bare maps, atoms, or other types. |
| `{:error, {:unrecognized_message_shape, struct_module}}` | The first argument passes the Mailglass-message check (struct ending in `.Message` exporting `update_swoosh/2`) but has neither a `:swoosh` nor an `:email` field holding a `%Swoosh.Email{}`. `struct_module` names the offending struct module. | Inspect the custom Mailglass-style struct: it must carry its Swoosh email in a field named `:swoosh` or `:email`. |
```

**Accrue contract table to tighten, not replace** (lines 282-290, 333-347):
```md
| `:line_items` | List of `%Accrue.LineItem{}` mapped into a table with columns Description, Qty, Unit, Subtotal. |
| `:issued_at` | Rendered as `"Issued: <date>"` in the header. |

| `{:error, {:invalid_invoice, term()}}` | The argument is not an `%Accrue.Invoice{}` struct. The second element echoes the caller's input for inspection. | Ensure the input is an `%Accrue.Invoice{}` fetched from the Accrue library. Do not pass plain maps, keyword lists, or other structs. |
```

Apply the Phase 10 updates in this same structure:
- State accepted `issued_at` types explicitly: `Date`, `NaiveDateTime`, `DateTime`.
- State that invalid nested `line_items` fail the whole recipe with `{:error, {:invalid_invoice, _}}`.
- Keep the “minimum useful mapping” language at lines 301-304.

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**Requirement checkbox pattern** (lines 26-32, 41-47):
```md
### Integrations and Adapters

- [ ] **ADPT-05**: Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling.

### Quality and Release

- [ ] **QUAL-04**: Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows.
```

**Traceability table shape to preserve** (lines 77-107):
```md
## Traceability

| Requirement | Original Phase | Gap-Closure Phase | Status |
|-------------|----------------|-------------------|--------|
| ADPT-05 | Phase 5 | Phase 8 (timeout) + Phase 10 (recipe + traceability) | Pending |
| QUAL-04 | Phase 4 | Phase 9 (preflight) + Phase 10 (traceability) + Phase 11 (verify) | Pending |
```

Use the same table format and only change the cells justified by verified Phase 10 evidence. The governing evidence source is `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` lines 104-110 plus Phase 10 test/docs closure.

## Shared Patterns

### Optional Dependency Guards
**Sources:** `lib/rendro/adapters/threadline.ex:1-10`, `lib/rendro/adapters/mailglass.ex:1-10`, `lib/rendro/adapters/accrue.ex:1-10`
**Apply to:** Both adapter modules
```elixir
if Code.ensure_loaded?(Threadline) do
  defmodule Rendro.Adapters.Threadline do
```

### Typed Error Tuples Instead of Raises
**Sources:** `lib/rendro/adapters/mailglass.ex:64-67,80-82`, `lib/rendro/adapters/accrue.ex:42-58`
**Apply to:** Mailglass and Accrue adapter fixes
```elixir
case Rendro.render(document) do
  {:ok, binary} -> attach_binary(email_or_message, binary, filename)
  {:error, _} = err -> err
end

def recipe(other), do: {:error, {:invalid_invoice, other}}
```

### Test-Time Optional Adapter Harness
**Sources:** `test/test_helper.exs:1-9`, `test/support/mocks.ex:195-221`
**Apply to:** Any test change that depends on optional adapters existing
```elixir
ExUnit.start()
Rendro.Test.Mocks.ensure_table!()
Rendro.Test.Mocks.AdapterReloader.recompile()
```

```elixir
@adapter_files [
  "lib/rendro/adapters/threadline.ex",
  "lib/rendro/adapters/mailglass.ex",
  "lib/rendro/adapters/accrue.ex"
]
```

### Documentation Contract Shape
**Sources:** `guides/integrations.md:164-246`, `guides/integrations.md:257-348`
**Apply to:** Mailglass and Accrue doc updates
- Keep per-adapter sections in this order: `Setup`, `Verification`, `Failure diagnostics`.
- Use exact failure-mode tables rather than prose-only descriptions.
- Describe optional-dependency discipline explicitly instead of implying it.

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/rendro/adapters/`, `test/rendro/adapters/`, `test/support/`, `guides/`, `.planning/`
**Files scanned:** 14
**Pattern extraction date:** 2026-04-28

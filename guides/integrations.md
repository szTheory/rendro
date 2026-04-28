# Rendro Integrations

## Overview

Rendro ships three optional adapters for common ecosystem workflows: `threadline`
(structured audit logging), `mailglass` (transactional email attachments), and
`accrue` (billing-document recipes). None of them are hard dependencies of Rendro.
Each adapter module is compiled only when its target library is present in your
application's own `mix.exs` — if the library is absent, the adapter module does not
exist and the Rendro core is entirely unaffected.

This guide walks through enabling each adapter, verifying it works end-to-end, and
interpreting the failure modes your code may encounter.

---

## Threadline

`Rendro.Adapters.Threadline` funnels Rendro render lifecycle events into
`Threadline.record_action/2` so every render (success or failure) is captured in
your Threadline audit trail.

### Setup

1. Add `threadline` to your application's `mix.exs`:

   ```elixir-schematic
   defp deps do
     [
       {:rendro, "~> 0.1"},
       {:threadline, "~> 0.2"},
       # ...
     ]
   end
   ```

2. Attach the handler once at application start (e.g. from `Application.start/2`):

   ```elixir-schematic
   defmodule MyApp.Application do
     use Application

     def start(_type, _args) do
       Rendro.Adapters.Threadline.attach()
       # ... supervise children
     end
   end
   ```

   `attach/0` is idempotent — calling it more than once returns `:ok` without
   registering a duplicate handler.

The adapter subscribes to:

- `[:rendro, :render, :stop]` — emitted after every render, successful or not.
- `[:rendro, :render, :exception]` — emitted when the render pipeline crashes.

On `:stop` with `status: :ok` it records `Threadline.record_action(:render_succeeded, metadata)`.
On `:stop` with `status: :error` or on `:exception` it records `Threadline.record_action(:render_failed, metadata)`.

The metadata forwarded to Threadline contains only the allowlisted telemetry keys
(`:render_id`, `:stage`, `:status`, `:page_count`, `:byte_size`, `:duration`,
`:document_type`, `:deterministic`). Document bodies, attachment binaries, and
rendered PDFs are never included.

### Verification

After attaching the handler, render a document and confirm the audit row arrived:

```elixir
# docs-contract: integrations-threadline-happy-path
Rendro.Adapters.Threadline.attach()

{:ok, _pdf} = Rendro.render(
  Rendro.flow([Rendro.block(Rendro.text("Test invoice", size: 12))])
)

Rendro.Adapters.Threadline.detach()
```

The failure-path example below is intentionally schematic. Its public contract is
pinned by direct ExUnit semantic tests instead of by a compile-only docs lane.

```elixir-schematic
doc = Rendro.flow(
  [Rendro.block(Rendro.text("x", size: 12))],
  options: %{policies: [max_pages: 0]}
)
{:error, %Rendro.Error{reason: :max_pages_exceeded}} = Rendro.render(doc)

[action | _] = Threadline.list_actions()
assert action.action == :render_failed
```

To detach the handler (e.g. in test teardown):

```elixir-schematic
Rendro.Adapters.Threadline.detach()
```

### Failure diagnostics

`Rendro.Adapters.Threadline.track_render/2` (invoked internally by the telemetry
handler) can return the following values:

| Return value | When it occurs | What to do |
|---|---|---|
| `:ok` | `Threadline.record_action/2` returned `:ok` or `{:ok, _}`. | Normal; audit row recorded. |
| `{:error, term()}` | `Threadline.record_action/2` returned `{:error, reason}`. | Inspect `reason`; the Threadline backend declined to record. Check Threadline logs. |
| `{:error, {:unexpected_return, term()}}` | `Threadline.record_action/2` returned something other than `:ok`, `{:ok, _}`, or `{:error, _}`. | The Threadline library returned an unexpected shape. Check the Threadline version and its changelog. |
| `{:error, {:exception, Exception.t()}}` | `Threadline.record_action/2` raised an exception; the adapter rescues and wraps it. | Inspect the exception struct. Check connectivity/auth to the Threadline backend. |

Note: the audit handler is invoked asynchronously from the render pipeline. A
non-`:ok` return from `track_render/2` does NOT fail the render — callers still
receive their `{:ok, pdf}` or `{:error, %Rendro.Error{}}`. If you require
guaranteed audit delivery, add monitoring on Threadline's storage directly.

### Known limitation: pipeline timeouts are not audited

Render timeouts enforced by `Rendro.Pipeline.run/1` are NOT currently audited by
`Rendro.Adapters.Threadline`. The Pipeline wraps execution in `Task.async` and
shuts the task down on timeout before the surrounding `:telemetry.span` can emit
`:stop` or `:exception`. Because neither `[:rendro, :render, :stop]` nor
`[:rendro, :render, :exception]` fires, the Threadline handler is never called and
no audit row is written.

Callers still receive `{:error, %Rendro.Error{reason: :timeout}}` from
`Rendro.render/1`, but the corresponding audit row is absent from Threadline.

**Operator mitigation:** If you rely on Threadline as a complete audit trail,
compensate at the call site:

```elixir-schematic
case Rendro.render(doc) do
  {:ok, pdf} ->
    pdf

  {:error, %Rendro.Error{reason: :timeout} = err} ->
    # Manually emit an audit row so the timeout is recorded
    Threadline.record_action(:render_failed, %{
      reason: :timeout,
      render_id: doc.render_id
    })
    {:error, err}

  {:error, _} = err ->
    err
end
```

This is tracked as WR-01 in the Phase 05 review and is planned for a future
Pipeline change.

---

## Mailglass

`Rendro.Adapters.Mailglass` attaches rendered PDF documents to Swoosh emails or
`Mailglass.Message` structs, enabling end-to-end transactional email workflows
without leaving the Rendro boundary.

### Setup

Add `mailglass` and `swoosh` to your application's `mix.exs`:

```elixir-schematic
defp deps do
  [
    {:rendro, "~> 0.1"},
    {:mailglass, "~> 0.1"},
    {:swoosh, "~> 1.0"},
    # ...
  ]
end
```

The canonical pipeline is schematic because delivery depends on your own mailer
module and deployment setup.

```elixir-schematic
email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("customer@example.test")
  |> Swoosh.Email.subject("Your invoice")

email_with_attachment =
  Rendro.Adapters.Mailglass.attach_pdf(email, doc, "invoice.pdf")

MyApp.Mailer.deliver(email_with_attachment)
```

Or in a pipe:

```elixir-schematic
email
|> Rendro.Adapters.Mailglass.attach_pdf(doc, "invoice.pdf")
|> case do
  %Swoosh.Email{} = email_with_pdf -> MyApp.Mailer.deliver(email_with_pdf)
  {:error, reason} -> handle_error(reason)
end
```

### Verification

**Swoosh email path:**

```elixir
# docs-contract: integrations-mailglass-swoosh
doc = Rendro.flow([Rendro.block(Rendro.text("Invoice #001", size: 12))])
email = Swoosh.Email.new() |> Swoosh.Email.to("test@example.test")

result = Rendro.Adapters.Mailglass.attach_pdf(email, doc, "invoice.pdf")

# Confirm the attachment was added
assert length(result.attachments) == 1
[attachment | _] = result.attachments
assert attachment.content_type == "application/pdf"
assert attachment.filename == "invoice.pdf"
assert {:data, pdf} = attachment.data
assert binary_part(pdf, 0, 4) == "%PDF"
```

**Mailglass.Message path:**

When the first argument is a `%Mailglass.Message{}`, `attach_pdf/3` extracts the
underlying Swoosh email, attaches the PDF to it, and re-wraps the result using
`Mailglass.Message.update_swoosh/2` if that function is exported:

```elixir
# docs-contract: integrations-mailglass-message
doc = Rendro.flow([Rendro.block(Rendro.text("Invoice #001", size: 12))])
message = %Mailglass.Message{swoosh: Swoosh.Email.new(), meta: %{campaign_id: "abc"}}

updated_message = Rendro.Adapters.Mailglass.attach_pdf(message, doc, "invoice.pdf")

# The Mailglass wrapper is preserved
assert is_struct(updated_message, Mailglass.Message)
assert length(updated_message.swoosh.attachments) == 1
```

### Failure diagnostics

`attach_pdf/3` never raises. All failure paths return `{:error, _}`:

| Error tuple | When it occurs | What to check |
|---|---|---|
| `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` | The first argument is neither a `%Swoosh.Email{}` nor a recognized Mailglass message struct. `value` echoes the caller's input back for inspection. | Ensure the first argument is a `%Swoosh.Email{}` or a `%Mailglass.Message{}` (or a struct whose module name ends in `.Message` and exports `update_swoosh/2`). Do not pass bare maps, atoms, or other types. |
| `{:error, {:unrecognized_message_shape, struct_module}}` | The first argument passes the Mailglass-message check (struct ending in `.Message` exporting `update_swoosh/2`) but has neither a `:swoosh` nor an `:email` field holding a `%Swoosh.Email{}`. `struct_module` names the offending struct module. | Inspect the custom Mailglass-style struct: it must carry its Swoosh email in a field named `:swoosh` or `:email`. If it uses a different field name, implement `update_swoosh/2` in a way that reads from that field, or pre-extract the Swoosh email before calling `attach_pdf/3`. |
| `{:error, %Rendro.Error{}}` | The document rendering step failed (empty document, max-pages/bytes policy violation, timeout, validation errors, etc.). Inspect `:stage` and `:reason` on the `%Rendro.Error{}`. | Check the `:stage` field (`:build`, `:compose`, `:measure`, `:paginate`, `:render`) to locate where the pipeline failed. Check `:reason` for the specific failure kind (e.g. `:max_pages_exceeded`, `:max_bytes_exceeded`, `:timeout`). Adjust document content or policies accordingly. |

---

## Accrue

`Rendro.Adapters.Accrue` is a billing-document recipe that transforms an
`%Accrue.Invoice{}` into a `%Rendro.Document{}` ready to be passed to
`Rendro.render/1`. The recipe is pure and composable — it does not render,
it only builds the document structure.

### Setup

Add `accrue` to your application's `mix.exs`:

```elixir-schematic
defp deps do
  [
    {:rendro, "~> 0.1"},
    {:accrue, "~> 0.3"},
    # ...
  ]
end
```

The recipe entrypoint is pure, but this high-level application example is
schematic because `MyApp.Billing.fetch_invoice!/1` is app-specific.

```elixir-schematic
invoice = MyApp.Billing.fetch_invoice!(invoice_id)

{:ok, doc} = Rendro.Adapters.Accrue.recipe(invoice)
{:ok, pdf}  = Rendro.render(doc)
```

### Recipe contract

`recipe/1` reads the following fields from the `%Accrue.Invoice{}`:

| Field | Usage |
|---|---|
| `:id` | Rendered as `"INVOICE #<id>"` in the document header. |
| `:customer` | `.name` field extracted for `"Bill to: <name>"` in the header. |
| `:line_items` | List of `%Accrue.LineItem{}` mapped into a table with columns Description, Qty, Unit, Subtotal. |
| `:total` | Rendered as `"Total: $<total>"` beneath the line-items table. |
| `:issued_at` | Rendered as `"Issued: <date>"` in the header. |

`%Accrue.LineItem{}` fields consumed:

| Field | Usage |
|---|---|
| `:description` | Table row — Description column. |
| `:quantity` | Table row — Qty column. |
| `:unit_amount` | Table row — Unit column. |
| `:subtotal` | Table row — Subtotal column. |

The recipe is the **minimum useful** mapping. Teams wanting different layouts,
additional fields, custom styling, or multi-section documents should treat
`Rendro.Adapters.Accrue.recipe/1` as a starting template — copy it into your own
module and customize from there.

### Verification

After calling `recipe/1`, render the document and verify the output:

```elixir
# docs-contract: integrations-accrue-verification
invoice = %Accrue.Invoice{
  id: "INV-001",
  issued_at: ~D[2026-04-26],
  customer: %{name: "Acme Corp"},
  line_items: [
    %Accrue.LineItem{description: "Widget", quantity: 2, unit_amount: 50, subtotal: 100}
  ],
  total: 100
}

{:ok, doc} = Rendro.Adapters.Accrue.recipe(invoice)
{:ok, pdf}  = Rendro.render(doc)

# PDF magic bytes confirm a valid PDF was produced
assert binary_part(pdf, 0, 4) == "%PDF"

# Inspect the document to confirm the invoice id is present
assert inspect(doc) =~ "INV-001"
```

### Failure diagnostics

`recipe/1` can return the following errors:

| Error tuple | When it occurs | What to check |
|---|---|---|
| `{:error, {:invalid_invoice, term()}}` | The argument is not an `%Accrue.Invoice{}` struct. The second element echoes the caller's input for inspection. | Ensure the input is an `%Accrue.Invoice{}` fetched from the Accrue library. Do not pass plain maps, keyword lists, or other structs. |

Render-time errors flow through `Rendro.render/1` (not `recipe/1`) and produce
`{:error, %Rendro.Error{}}` with `:stage` in one of `:build`, `:compose`,
`:measure`, `:paginate`, or `:render`. Inspect the `%Rendro.Error{}` fields for
detail:

| Field | Meaning |
|---|---|
| `:stage` | Pipeline stage where the failure occurred. |
| `:reason` | Structured reason atom or tuple (e.g. `:max_pages_exceeded`, `:timeout`). |

---

## Optional-dependency discipline

None of `threadline`, `mailglass`, or `accrue` appear in Rendro's own `mix.exs`
dependencies. Each adapter module is wrapped in a compile-time guard:

```elixir-schematic
if Code.ensure_loaded?(Threadline) do
  defmodule Rendro.Adapters.Threadline do
    def attach, do: :ok
  end
end
```

When the library is absent from the application's deps, the guard evaluates to
`false` at compile time, the `defmodule` block is skipped entirely, and the
adapter module does not exist. Core Rendro behavior is completely unaffected.

Maintainers should NOT add `:threadline`, `:mailglass`, or `:accrue` to Rendro's
own `mix.exs` deps. Users add them to their own application's `mix.exs`; Rendro
simply detects their presence at compile time.

**Test-time recompilation:** In Rendro's own test suite, the adapter modules need
to be exercisable without adding the ecosystem libraries as real dependencies. This
is accomplished via a two-step mechanism in `test/support/mocks.ex`:

1. Minimal stub modules for `Threadline`, `Mailglass`, `Mailglass.Message`,
   `Swoosh.Email`, `Swoosh.Attachment`, `Accrue`, `Accrue.Invoice`, and
   `Accrue.LineItem` are defined in `test/support/mocks.ex`. These stubs satisfy
   `Code.ensure_loaded?/1` checks during the test compile.

2. `AdapterReloader.recompile/0` (called from `test/test_helper.exs` after
   `ExUnit.start/0`) re-evaluates each adapter file with the stub modules
   already loaded, so the guarded module bodies are compiled and available
   during test runs.

This design lets CI exercise all adapter code paths without any real ecosystem
library installed, preserving the "Rendro core has no ecosystem deps" guarantee
from production builds. See `test/support/mocks.ex` for the full stub definitions.

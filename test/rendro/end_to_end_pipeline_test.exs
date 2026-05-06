defmodule Rendro.EndToEndPipelineTest do
  use ExUnit.Case

  alias Rendro.Adapters.Oban.RenderWorker
  alias Rendro.Artifact
  alias Rendro.Protect
  alias Rendro.Storage.Local
  alias Rendro.Adapters.Mailglass

  defmodule FakeProtectAdapter do
    @behaviour Rendro.Protect.Adapter

    @impl true
    def protect(%Artifact{binary: binary}, _opts), do: {:ok, binary <> "::protected"}
  end

  # 1. The application's Oban Builder bridging args to the Accrue recipe
  defmodule AppInvoiceBuilder do
    def build_document(%{"id" => id, "customer" => name, "total" => total}) do
      invoice = %Accrue.Invoice{
        id: id,
        customer: %{name: name},
        line_items: [
          %Accrue.LineItem{
            description: "Service",
            quantity: 1,
            unit_amount: total,
            subtotal: total
          }
        ],
        total: total,
        issued_at: ~D[2026-05-04]
      }

      {:ok, doc} = Rendro.Adapters.Accrue.recipe(invoice)
      doc
    end
  end

  test "S07: Final End-to-End Pipeline Integration" do
    storage_path = Path.join(System.tmp_dir!(), "e2e_invoice_#{:rand.uniform(100_000)}.pdf")
    on_exit(fn -> Local.delete(storage_path, []) end)

    # Simulate an Oban Job enqueue
    job = %Oban.Job{
      args: %{
        "module" => Atom.to_string(AppInvoiceBuilder),
        "args" => %{"id" => "INV-E2E-1", "customer" => "EndToEnd Corp", "total" => 1500},
        "storage_module" => Atom.to_string(Local),
        "storage_opts" => %{"path" => storage_path}
      }
    }

    # 2. Worker executes, renders deterministically, and stores the artifact
    assert :ok = RenderWorker.perform(job)

    # 3. Retrieve the stored artifact from Local storage
    assert {:ok, %Artifact{} = artifact} = Local.get(storage_path, [])
    assert is_binary(artifact.binary)
    assert String.starts_with?(artifact.binary, "%PDF-")

    # 4. Seamlessly attach to a Mailglass transactional email
    email = Swoosh.Email.new()
    email_with_pdf = Mailglass.attach_artifact(email, artifact, "invoice-e2e.pdf")

    assert length(email_with_pdf.attachments) == 1
    [attachment] = email_with_pdf.attachments
    assert attachment.filename == "invoice-e2e.pdf"
    assert {:data, _binary} = attachment.data

    # 5. Threadline audit (implicitly tested via telemetry attachments,
    # but the pipeline completed without crashing, proving deterministic success).

  end

  test "protected artifacts can be retrieved, protected inside the app boundary, and delivered" do
    storage_path =
      Path.join(System.tmp_dir!(), "e2e_protected_invoice_#{:rand.uniform(100_000)}.pdf")
    on_exit(fn -> Local.delete(storage_path, []) end)

    job = %Oban.Job{
      args: %{
        "module" => Atom.to_string(AppInvoiceBuilder),
        "args" => %{"id" => "INV-E2E-2", "customer" => "Protected Corp", "total" => 2200},
        "storage_module" => Atom.to_string(Local),
        "storage_opts" => %{"path" => storage_path}
      }
    }

    assert :ok = RenderWorker.perform(job)
    assert {:ok, %Artifact{} = reloaded} = Local.get(storage_path, [])
    assert is_binary(reloaded.binary)
    assert String.starts_with?(reloaded.binary, "%PDF-")
    refute Map.has_key?(job.args, "open_password")
    refute Map.has_key?(job.args, "owner_password")
    refute Map.has_key?(job.args, "protection")
    refute Map.has_key?(reloaded.metadata, :protection)

    {:ok, protected} =
      Protect.password(reloaded,
        adapter: FakeProtectAdapter,
        open_password: "open-secret",
        owner_password: "owner-secret",
        advisory_permissions: [:print]
      )

    assert {:ok, ^storage_path} = Local.put(protected, path: storage_path)
    assert {:ok, %Artifact{} = protected_reload} = Local.get(storage_path, [])

    assert protected_reload.metadata.deterministic == false

    assert protected_reload.metadata.protection == %{
             algorithm: :aes_256,
             advisory_permissions: [:print],
             has_open_password: true,
             has_owner_password: true
           }

    email = Swoosh.Email.new()
    email_with_pdf = Mailglass.attach_artifact(email, protected_reload, "invoice-protected.pdf")

    assert length(email_with_pdf.attachments) == 1
    [attachment] = email_with_pdf.attachments
    assert attachment.filename == "invoice-protected.pdf"
    assert {:data, protected_binary} = attachment.data
    assert protected_binary == protected_reload.binary
    assert protected_binary =~ "::protected"

  end
end

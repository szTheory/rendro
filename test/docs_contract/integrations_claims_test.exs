defmodule DocsContractMailglassWrapper.Message do
  @moduledoc false
  defstruct [:id, :payload]

  def update_swoosh(%__MODULE__{} = message, _swoosh), do: message
end

defmodule Rendro.DocsContract.IntegrationsClaimsTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Accrue
  alias Rendro.Adapters.Mailglass, as: MailglassAdapter
  alias Rendro.Adapters.Threadline
  alias Rendro.Test.Mocks

  setup do
    Mocks.reset_threadline()
    :ok = Threadline.attach()

    on_exit(fn ->
      Threadline.detach()
    end)

    :ok
  end

  test "optional adapters stay behind compile-time guards" do
    for {path, dependency} <- [
          {"lib/rendro/adapters/threadline.ex", "Threadline"},
          {"lib/rendro/adapters/mailglass.ex", "Mailglass"},
          {"lib/rendro/adapters/accrue.ex", "Accrue"}
        ] do
      source = File.read!(path)
      assert source =~ "if Code.ensure_loaded?(#{dependency}) do"
    end
  end

  test "threadline timeout limitation remains truthful" do
    content = for i <- 1..200, do: Rendro.block(Rendro.text("timeout me #{i}", size: 12))
    doc = Rendro.flow(content)
    doc = put_in(doc.options[:policies], timeout: 0)

    assert {:error, %Rendro.Error{reason: :timeout}} = Rendro.render(doc)
    assert Mocks.threadline_calls() == []
  end

  test "mailglass failure tuples match the guide contract" do
    document = sample_document()
    email = Swoosh.Email.new() |> Swoosh.Email.to("customer@example.test")
    message = %Elixir.Mailglass.Message{swoosh: Swoosh.Email.new(), meta: %{campaign_id: "abc"}}

    assert %Swoosh.Email{} = MailglassAdapter.attach_pdf(email, document, "invoice.pdf")

    assert %Elixir.Mailglass.Message{} =
             MailglassAdapter.attach_pdf(message, document, "invoice.pdf")

    assert {:error, %Rendro.Error{reason: {:invalid_email_target, :not_an_email}}} =
             MailglassAdapter.attach_pdf(:not_an_email, document, "invoice.pdf")

    wrapper = %DocsContractMailglassWrapper.Message{id: 1, payload: "data"}

    assert {:error, {:unrecognized_message_shape, DocsContractMailglassWrapper.Message}} =
             MailglassAdapter.attach_pdf(wrapper, document, "invoice.pdf")
  end

  test "accrue invalid invoice contract stays truthful" do
    assert {:error, {:invalid_invoice, :not_an_invoice}} = Accrue.recipe(:not_an_invoice)
  end

  defp sample_document do
    text = %Rendro.Text{content: "Invoice", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Invoice"}}
  end
end

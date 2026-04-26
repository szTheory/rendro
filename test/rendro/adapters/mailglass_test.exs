defmodule Rendro.Adapters.MailglassTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Mailglass, as: Adapter

  defp sample_document do
    text = %Rendro.Text{content: "Invoice", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Invoice"}}
  end

  defp failing_document do
    %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
  end

  describe "attach_pdf/3 with Swoosh.Email input" do
    test "renders the document and adds an attachment" do
      email = Swoosh.Email.new()
      result = Adapter.attach_pdf(email, sample_document(), "invoice.pdf")

      assert %Swoosh.Email{} = result
      assert length(result.attachments) == 1

      [attachment] = result.attachments
      assert attachment.filename == "invoice.pdf"
      assert attachment.content_type == "application/pdf"
    end

    test "uses default filename when not provided" do
      email = Swoosh.Email.new()
      result = Adapter.attach_pdf(email, sample_document())

      [attachment] = result.attachments
      assert attachment.filename == "document.pdf"
    end

    test "preserves existing email fields" do
      email =
        Swoosh.Email.new()
        |> Swoosh.Email.subject("Your invoice")
        |> Swoosh.Email.from({"Acme", "billing@acme.test"})
        |> Swoosh.Email.to("customer@example.test")

      result = Adapter.attach_pdf(email, sample_document(), "invoice.pdf")

      assert result.subject == "Your invoice"
      assert result.from == {"Acme", "billing@acme.test"}
      assert result.to == [{"", "customer@example.test"}]
      assert length(result.attachments) == 1
    end

    test "attachment payload is the rendered PDF binary" do
      email = Swoosh.Email.new()
      result = Adapter.attach_pdf(email, sample_document(), "invoice.pdf")

      [attachment] = result.attachments
      assert {:data, binary} = attachment.data
      assert is_binary(binary)
      assert byte_size(binary) > 0
      # PDF magic header
      assert <<"%PDF-", _rest::binary>> = binary
    end
  end

  describe "attach_pdf/3 with Mailglass.Message input" do
    test "unwraps and re-wraps Mailglass.Message via update_swoosh/2" do
      message = %Mailglass.Message{swoosh: Swoosh.Email.new(), meta: %{template: :invoice}}

      result = Adapter.attach_pdf(message, sample_document(), "invoice.pdf")

      assert %Mailglass.Message{} = result
      assert result.meta == %{template: :invoice}
      assert length(result.swoosh.attachments) == 1
      [att] = result.swoosh.attachments
      assert att.filename == "invoice.pdf"
      assert att.content_type == "application/pdf"
    end
  end

  describe "attach_pdf/3 error paths" do
    test "returns {:error, %Rendro.Error{}} when render fails" do
      email = Swoosh.Email.new()

      assert {:error, %Rendro.Error{}} =
               Adapter.attach_pdf(email, failing_document(), "invoice.pdf")
    end
  end
end

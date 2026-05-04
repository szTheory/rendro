# Ad-hoc structs used only for negative-path tests.
# Defined at the top of the test file (outside the test module) so they live
# in the test compilation unit and do NOT pollute `test/support/mocks.ex`.
# They must be at the top level so that %Mailglass.Message{} inside the test
# module continues to resolve to the correct (mocks.ex) stub, not these fixtures.

defmodule Mailglass.UnrecognizedFixture do
  @moduledoc false
  # Lives in `Elixir.Mailglass.*` namespace, ends in `.Fixture` (NOT `.Message`),
  # has no :swoosh / :email field. Used to exercise WR-03 overlap with CR-02:
  # because this struct does NOT end in `.Message`, it is rejected by mailglass_message?/1
  # and falls through to the invalid_email_target error path.
  defstruct [:foo, :bar]
end

defmodule Mailglass.Wrapper.Message do
  @moduledoc false
  # Lives in `Elixir.Mailglass.Wrapper.Message` namespace — module atom string ends in
  # ".Message" (passes the mailglass_message?/1 name-suffix check), exports
  # update_swoosh/2 (satisfies the interface check), but has NO :swoosh or :email field.
  # Used to exercise CR-01: a struct admitted by mailglass_message?/1 but rejected in
  # extract_swoosh/1 with {:error, {:unrecognized_message_shape, _}}.
  defstruct [:id, :payload]

  def update_swoosh(%__MODULE__{} = msg, _swoosh), do: msg
end

defmodule Mailglass.ConfigFixture do
  @moduledoc false
  # Lives in `Elixir.Mailglass.*` namespace, ends in `.ConfigFixture` (NOT `.Message`),
  # has no :swoosh / :email / :update_swoosh function. Used to exercise WR-03:
  # must NOT be classified as a Mailglass message by the narrowed predicate.
  defstruct [:setting]
end

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

  describe "attach_artifact/3" do
    test "attaches an artifact binary directly to the email" do
      email = Swoosh.Email.new()

      artifact = %Rendro.Artifact{
        binary: <<"%PDF-1.4\n">>,
        hash: "dummyhash",
        diagnostics: [],
        metadata: %{}
      }

      result = Adapter.attach_artifact(email, artifact, "receipt.pdf")

      assert %Swoosh.Email{} = result
      assert length(result.attachments) == 1

      [attachment] = result.attachments
      assert attachment.filename == "receipt.pdf"
      assert attachment.content_type == "application/pdf"
      assert {:data, <<"%PDF-1.4\n">>} = attachment.data
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

  describe "attach_pdf/3 negative paths" do
    test "returns {:error, %Rendro.Error{}} for a non-Swoosh, non-Mailglass atom (CR-02)" do
      # Must NOT raise — moduledoc contract promises {:error, Rendro.Error.t()}
      result =
        try do
          Adapter.attach_pdf(:not_an_email, sample_document(), "x.pdf")
        rescue
          e -> {:raised, e}
        end

      assert {:error, %Rendro.Error{reason: {:invalid_email_target, :not_an_email}}} = result
    end

    test "returns {:error, %Rendro.Error{}} for a plain map (CR-02)" do
      result =
        try do
          Adapter.attach_pdf(%{not: :swoosh}, sample_document(), "x.pdf")
        rescue
          e -> {:raised, e}
        end

      assert {:error, %Rendro.Error{reason: {:invalid_email_target, %{not: :swoosh}}}} = result
    end

    test "returns {:error, {:unrecognized_message_shape, _}} for a Mailglass.* struct without :swoosh/:email (CR-01)" do
      # Mailglass.Wrapper.Message ends in .Message and exports update_swoosh/2 so it
      # is admitted by mailglass_message?/1 — but it has no :swoosh/:email field, so
      # extract_swoosh/1 returns {:error, {:unrecognized_message_shape, _}} (CR-01 fix).
      wrapper = %Mailglass.Wrapper.Message{id: 1, payload: "data"}

      result =
        try do
          Adapter.attach_pdf(wrapper, sample_document(), "x.pdf")
        rescue
          e -> {:raised, e}
        end

      assert {:error, {:unrecognized_message_shape, Mailglass.Wrapper.Message}} = result
    end

    test "Mailglass.* struct that does NOT end in .Message is rejected as non-message (WR-03)" do
      config = %Mailglass.ConfigFixture{setting: :anything}

      result =
        try do
          Adapter.attach_pdf(config, sample_document(), "x.pdf")
        rescue
          e -> {:raised, e}
        end

      # Must fall through to the non-email error tuple, NOT into extract_swoosh's
      # CR-01 path. The test passes either if we get the invalid_email_target tuple
      # (correct WR-03 fix) — but MUST FAIL if the struct is silently accepted as a
      # Mailglass message.
      assert {:error, %Rendro.Error{reason: {:invalid_email_target, _}}} = result
    end
  end
end

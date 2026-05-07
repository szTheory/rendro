defmodule Rendro.SignTest do
  use ExUnit.Case, async: true

  alias Rendro.{Artifact, Sign}

  defmodule FakeSignerAdapter do
    @behaviour Rendro.Sign.Adapter

    @impl true
    def prepare(%Artifact{binary: binary}, opts) do
      send(self(), {:fake_signer_adapter_called, opts})

      {:ok, binary, %{fake_signer: %{mode: :detached, adapter: __MODULE__}}}
    end
  end

  defp signature_artifact do
    doc =
      Rendro.fixed([
        Rendro.page(
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [
            Rendro.signature_field("customer_signature",
              x: 10,
              y: 20,
              width: 180,
              height: 48
            )
          ]
        )
      ])

    {:ok, artifact} = Rendro.render_to_artifact(doc, deterministic: true)
    artifact
  end

  test "prepare/2 wraps prepared bytes back into an artifact with a narrow manifest" do
    assert {:ok, prepared} =
             Sign.prepare(signature_artifact(), field: "customer_signature", reserved_bytes: 8192)

    assert prepared.binary != signature_artifact().binary
    assert prepared.hash != signature_artifact().hash
    assert prepared.metadata.page_count == 1
    assert prepared.metadata.deterministic == true

    assert %{
             status: :prepared,
             field: "customer_signature",
             reserved_bytes: 8192,
             byte_range_placeholder: %{
               offset: byte_range_offset,
               length: byte_range_length
             },
             contents_placeholder: %{
               offset: contents_offset,
               length: contents_length
             }
           } = prepared.metadata.signing_preparation

    assert is_integer(byte_range_offset)
    assert byte_range_length > 0
    assert is_integer(contents_offset)
    assert contents_length == 16_384
    assert binary_part(prepared.binary, byte_range_offset, byte_range_length) =~ "/ByteRange ["
    assert binary_part(prepared.binary, contents_offset, contents_length) =~ ~r/\A[0-9A-F]+\z/
    refute Map.has_key?(prepared.metadata.signing_preparation, :adapter)
    refute inspect(prepared.metadata.signing_preparation) =~ "certificate"
    refute inspect(prepared.metadata.signing_preparation) =~ "trust"
    refute inspect(prepared.metadata.signing_preparation) =~ "pkcs7"
  end

  test "prepare/2 rejects malformed top-level options" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.prepare(signature_artifact(), %{field: "customer_signature"})

    assert error.stage == :prepare
    assert error.reason == {:invalid_option, :options, %{field: "customer_signature"}}
  end

  test "prepare/2 requires an explicit signature field name" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.prepare(signature_artifact(), reserved_bytes: 4096)

    assert error.stage == :prepare
    assert error.reason == {:missing_required_option, :field}
  end

  test "prepare/2 requires a positive integer reserved byte count" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.prepare(signature_artifact(), field: "customer_signature", reserved_bytes: 0)

    assert error.stage == :prepare
    assert error.reason == {:invalid_option, :reserved_bytes, 0}
  end

  test "prepare/2 fails when the requested field is not a signature widget" do
    doc =
      Rendro.fixed([
        Rendro.page(
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [
            Rendro.form_field("email", "jon@example.com",
              x: 10,
              y: 20,
              width: 180,
              height: 24
            )
          ]
        )
      ])

    {:ok, artifact} = Rendro.render_to_artifact(doc, deterministic: true)

    assert {:error, %Rendro.Error{} = error} =
             Sign.prepare(artifact, field: "email", reserved_bytes: 4096)

    assert error.stage == :prepare
    assert error.reason == {:field_not_preparable, "email"}
  end

  test "prepare/2 fails when the requested signature field is missing from the artifact bytes" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.prepare(signature_artifact(), field: "missing_signature", reserved_bytes: 4096)

    assert error.stage == :prepare
    assert error.reason == {:field_not_preparable, "missing_signature"}
  end

  test "prepare/2 keeps adapter metadata outside the shared core manifest" do
    assert {:ok, prepared} =
             Sign.prepare(signature_artifact(),
               field: "customer_signature",
               reserved_bytes: 2048,
               adapter: FakeSignerAdapter
             )

    assert_receive {:fake_signer_adapter_called, opts}
    assert opts.field == "customer_signature"
    assert opts.reserved_bytes == 2048

    assert prepared.metadata.signing_preparation.field == "customer_signature"
    assert prepared.metadata.signing_preparation.status == :prepared

    assert prepared.metadata.signing_preparation_adapter == %{
             fake_signer: %{mode: :detached, adapter: FakeSignerAdapter}
           }

    refute Map.has_key?(prepared.metadata.signing_preparation, :fake_signer)
  end
end

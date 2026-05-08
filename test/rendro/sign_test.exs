defmodule Rendro.SignTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias Rendro.{Artifact, Sign}

  defmodule FakeSignerAdapter do
    @behaviour Rendro.Sign.Adapter

    @impl true
    def prepare(%Artifact{binary: binary}, opts) do
      send(self(), {:fake_signer_adapter_called, opts})

      {:ok, binary, %{fake_signer: %{mode: :detached, adapter: __MODULE__}}}
    end

    @impl true
    def sign(%Artifact{binary: binary}, opts) do
      send(self(), {:fake_sign_called, opts})
      {:ok, binary <> "-signed", %{tool: :fake_signer, credential_source: :pemder}}
    end

    @impl true
    def augment(%Artifact{binary: binary}, opts) do
      send(self(), {:fake_augment_called, opts})

      {:ok, binary <> "-augmented",
       %{
         tool: :fake_signer,
         evidence_profile: :pades_lt,
         timestamp: :present,
         revocation: :embedded,
         compliance_evidence: :narrow_supported_path,
         timestamp_authority: :test_tsa,
         revocation_sources: [:ocsp, :crl]
       }}
    end
  end

  defmodule SecretLeakingAdapter do
    @behaviour Rendro.Sign.Adapter

    @impl true
    def prepare(%Artifact{} = artifact, _opts), do: {:ok, artifact.binary, %{}}

    @impl true
    def sign(%Artifact{binary: binary}, _opts) do
      {:ok, binary <> "-signed",
       %{
         tool: :secret_leaker,
         credential_source: :pemder,
         key_path: "/tmp/private-key.pem",
         cert_path: "/tmp/cert.pem",
         passphrase: "super-secret",
         stderr: "sensitive stderr",
         trust_verdict: :trusted
       }}
    end

    @impl true
    def augment(%Artifact{binary: binary}, _opts) do
      {:ok, binary <> "-augmented",
       %{
         tool: :secret_leaker,
         evidence_profile: :pades_lta,
         timestamp: :present,
         revocation: :embedded,
         compliance_evidence: :narrow_supported_path,
         timestamp_authority: :tsa_primary,
         revocation_sources: [:ocsp, :crl],
         passphrase_supplied: true,
         passphrase: "super-secret",
         stderr: "sensitive stderr",
         temp_path: "/tmp/rendro-ltv",
         revocation_blob: "raw-ocsp",
         trust_verdict: :trusted,
         signer_identity: "Rendro Test Signer",
         tsa_url: "https://tsa.example.test"
       }}
    end
  end

  defmodule FailingSignerAdapter do
    @behaviour Rendro.Sign.Adapter

    @impl true
    def prepare(%Artifact{} = artifact, _opts), do: {:ok, artifact.binary, %{}}

    @impl true
    def sign(%Artifact{}, _opts), do: {:error, {:command_failed, RuntimeError}}

    @impl true
    def augment(%Artifact{}, _opts), do: {:error, {:command_failed, RuntimeError}}
  end

  defmodule MissingAugmentCallbackAdapter do
    @behaviour Rendro.Sign.Adapter

    @impl true
    def prepare(%Artifact{} = artifact, _opts), do: {:ok, artifact.binary, %{}}

    @impl true
    def sign(%Artifact{binary: binary}, _opts) do
      {:ok, binary <> "-signed", %{tool: :missing_augment}}
    end
  end

  defmodule FakeValidationAdapter do
    def validate(path, opts) do
      send(
        self(),
        {:fake_validate_called, path, opts, file_mode(Path.dirname(path)), file_mode(path)}
      )

      {:ok,
       %{
         signatures: [
           %{
             field: "customer_signature",
             integrity: :valid,
             trust:
               if(Keyword.get(opts, :skip_certificate_validation, true),
                 do: :skipped,
                 else: :valid
               ),
             total_document_signed: true,
             signer_common_name: "Rendro Test Signer"
           }
         ]
       }}
    end

    defp file_mode(path) do
      path
      |> File.stat!()
      |> Map.fetch!(:mode)
      |> band(0o777)
    end
  end

  defmodule MissingPdfsigAdapter do
    def validate(_path, _opts), do: {:error, {:missing_executable, "pdfsig"}}
  end

  defmodule UnsignedValidationAdapter do
    def validate(_path, _opts), do: {:error, {:invalid_pdf, :no_signatures}}
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

  defp signed_artifact do
    {:ok, artifact} =
      Sign.sign(signature_artifact(),
        field: "customer_signature",
        adapter: FakeSignerAdapter,
        adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
      )

    artifact
  end

  test "prepare/2 proves prepared-artifact coordinates only and not signer or compliance state" do
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
    refute inspect(prepared.metadata.signing_preparation) =~ "signer"
    refute inspect(prepared.metadata.signing_preparation) =~ "certificate"
    refute inspect(prepared.metadata.signing_preparation) =~ "trust"
    refute inspect(prepared.metadata.signing_preparation) =~ "pkcs7"
    refute inspect(prepared.metadata.signing_preparation) =~ "pades"
    refute inspect(prepared.metadata.signing_preparation) =~ "ocsp"
    refute inspect(prepared.metadata.signing_preparation) =~ "crl"
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
    refute inspect(prepared.metadata.signing_preparation_adapter) =~ "certificate"
    refute inspect(prepared.metadata.signing_preparation_adapter) =~ "trust"
  end

  test "sign/2 signs an unsigned artifact through the configured adapter" do
    assert {:ok, signed} =
             Sign.sign(signature_artifact(),
               field: "customer_signature",
               adapter: FakeSignerAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert_receive {:fake_sign_called, opts}
    assert opts.field == "customer_signature"
    assert opts.adapter_opts == [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
    assert signed.binary =~ "-signed"
    assert signed.metadata.deterministic == false
    assert signed.metadata.signing.status == :signed
    assert signed.metadata.signing.field == "customer_signature"
    assert signed.metadata.signing.adapter == FakeSignerAdapter
    assert signed.metadata.signing_adapter == %{tool: :fake_signer, credential_source: :pemder}
  end

  test "sign/2 rejects missing signature fields before adapter execution" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.sign(signature_artifact(),
               field: "missing_signature",
               adapter: FakeSignerAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert error.stage == :sign
    assert error.reason == {:field_not_preparable, "missing_signature"}
    refute_received {:fake_sign_called, _opts}
  end

  test "sign/2 rejects already-signed artifacts through a typed sign-stage error" do
    {:ok, signed} =
      Sign.sign(signature_artifact(),
        field: "customer_signature",
        adapter: FakeSignerAdapter,
        adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
      )

    assert_receive {:fake_sign_called, _opts}

    assert {:error, %Rendro.Error{} = error} =
             Sign.sign(signed,
               field: "customer_signature",
               adapter: FakeSignerAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert error.stage == :sign
    assert error.reason == :already_signed
    refute_received {:fake_sign_called, _opts}
  end

  test "sign/2 rejects prepared artifacts so CLI signers stay on the unsigned artifact seam" do
    {:ok, prepared} =
      Sign.prepare(signature_artifact(), field: "customer_signature", reserved_bytes: 4096)

    assert {:error, %Rendro.Error{} = error} =
             Sign.sign(prepared,
               field: "customer_signature",
               adapter: FakeSignerAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert error.stage == :sign
    assert error.reason == :prepared_artifact_not_signable
  end

  test "sign/2 rejects malformed signing options" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.sign(signature_artifact(), %{field: "customer_signature"})

    assert error.stage == :sign
    assert error.reason == {:invalid_option, :options, %{field: "customer_signature"}}
  end

  test "sign/2 redacts adapter failure details to field, adapter, and option keys only" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.sign(signature_artifact(),
               field: "customer_signature",
               adapter: FailingSignerAdapter,
               adapter_opts: [
                 key: "/tmp/key.pem",
                 cert: "/tmp/cert.pem",
                 passfile: "/tmp/pass.txt"
               ]
             )

    assert error.stage == :sign
    assert error.reason == {:command_failed, RuntimeError}
    assert error.details.field == "customer_signature"
    assert error.details.adapter == FailingSignerAdapter
    assert error.details.adapter_opt_keys == [:cert, :key, :passfile]
    refute inspect(error.details) =~ "/tmp/key.pem"
    refute inspect(error.details) =~ "/tmp/cert.pem"
    refute inspect(error.details) =~ "/tmp/pass.txt"
  end

  test "sign/2 persists only safe adapter-local metadata on signed artifacts" do
    assert {:ok, signed} =
             Sign.sign(signature_artifact(),
               field: "customer_signature",
               adapter: SecretLeakingAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert signed.metadata.signing_adapter == %{
             tool: :secret_leaker,
             credential_source: :pemder
           }

    refute inspect(signed.metadata.signing_adapter) =~ "private-key"
    refute inspect(signed.metadata.signing_adapter) =~ "cert.pem"
    refute inspect(signed.metadata.signing_adapter) =~ "super-secret"
    refute inspect(signed.metadata.signing_adapter) =~ "stderr"
    refute inspect(signed.metadata.signing_adapter) =~ "trust"
  end

  test "augment/2 extends a signed artifact through the configured adapter only" do
    signed = signed_artifact()

    assert {:ok, augmented} =
             Sign.augment(signed,
               adapter: FakeSignerAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test", revocation: :embed]
             )

    assert_receive {:fake_sign_called, _sign_opts}
    assert_receive {:fake_augment_called, opts}
    assert opts.adapter == FakeSignerAdapter
    assert opts.adapter_opts == [tsa_url: "https://tsa.example.test", revocation: :embed]
    assert augmented.binary =~ "-augmented"
    assert augmented.binary != signed.binary
    assert augmented.hash != signed.hash
    assert augmented.metadata.deterministic == false
    assert augmented.metadata.signing.status == :signed
    assert augmented.metadata.long_lived == %{
             status: :augmented,
             adapter: FakeSignerAdapter,
             timestamp: :present,
             revocation: :embedded,
             compliance_evidence: :narrow_supported_path
           }

    assert augmented.metadata.long_lived_adapter == %{
             tool: :fake_signer,
             evidence_profile: :pades_lt,
             timestamp_authority: :test_tsa,
             revocation_sources: [:ocsp, :crl]
           }
  end

  test "augment/2 rejects unsigned artifacts before adapter execution" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(signature_artifact(),
               adapter: FakeSignerAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test"]
             )

    assert error.stage == :augment
    assert error.reason == :unsigned_artifact_not_augmentable
    refute_received {:fake_augment_called, _opts}
  end

  test "augment/2 rejects prepared artifacts before adapter execution" do
    {:ok, prepared} =
      Sign.prepare(signature_artifact(), field: "customer_signature", reserved_bytes: 4096)

    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(prepared,
               adapter: FakeSignerAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test"]
             )

    assert error.stage == :augment
    assert error.reason == :prepared_artifact_not_augmentable
    refute_received {:fake_augment_called, _opts}
  end

  test "augment/2 rejects artifacts missing signing metadata before adapter execution" do
    artifact = Artifact.wrap("signed-bytes", signature_artifact(), %{deterministic: false})

    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(artifact,
               adapter: FakeSignerAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test"]
             )

    assert error.stage == :augment
    assert error.reason == :unsupported_artifact_state
    refute_received {:fake_augment_called, _opts}
  end

  test "augment/2 rejects already-augmented artifacts before adapter execution" do
    signed = signed_artifact()

    already_augmented =
      Artifact.wrap("signed-augmented", signed, %{
        long_lived: %{status: :augmented, adapter: FakeSignerAdapter}
      })

    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(already_augmented,
               adapter: FakeSignerAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test"]
             )

    assert error.stage == :augment
    assert error.reason == :already_augmented
    refute_received {:fake_augment_called, _opts}
  end

  test "augment/2 rejects malformed top-level options" do
    assert {:error, %Rendro.Error{} = error} = Sign.augment(signed_artifact(), %{adapter: nil})

    assert error.stage == :augment
    assert error.reason == {:invalid_option, :options, %{adapter: nil}}
  end

  test "augment/2 requires an explicit adapter" do
    assert {:error, %Rendro.Error{} = error} = Sign.augment(signed_artifact(), adapter_opts: [])

    assert error.stage == :augment
    assert error.reason == {:missing_required_option, :adapter}
  end

  test "augment/2 rejects invalid adapter modules or missing callbacks" do
    assert {:error, %Rendro.Error{} = invalid_adapter} =
             Sign.augment(signed_artifact(), adapter: "bad-adapter", adapter_opts: [])

    assert invalid_adapter.stage == :augment
    assert invalid_adapter.reason == {:invalid_option, :adapter, "bad-adapter"}

    assert {:error, %Rendro.Error{} = missing_callback} =
             Sign.augment(signed_artifact(),
               adapter: MissingAugmentCallbackAdapter,
               adapter_opts: []
             )

    assert missing_callback.stage == :augment
    assert missing_callback.reason ==
             {:invalid_option, :adapter, MissingAugmentCallbackAdapter}
  end

  test "augment/2 rejects invalid adapter option containers" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(signed_artifact(), adapter: FakeSignerAdapter, adapter_opts: "bad")

    assert error.stage == :augment
    assert error.reason == {:invalid_option, :adapter_opts, "bad"}
  end

  test "render_signed/3 signs after rendering through the top-level seam" do
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

    assert {:ok, signed} =
             Rendro.render_signed(doc, [deterministic: true],
               field: "customer_signature",
               adapter: FakeSignerAdapter,
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem"]
             )

    assert signed.metadata.signing.status == :signed
    assert signed.metadata.page_count == 1
  end

  test "validate/2 uses a private temp file and returns a compact integrity-first posture" do
    assert {:ok, posture} =
             Sign.validate(signature_artifact(), adapter: FakeValidationAdapter)

    assert_receive {:fake_validate_called, path, opts, dir_mode, file_mode}
    assert opts == [skip_certificate_validation: true]
    assert dir_mode == 0o700
    assert file_mode == 0o600
    refute File.exists?(path)
    refute File.exists?(Path.dirname(path))

    assert posture == %{
             adapter: FakeValidationAdapter,
             signatures: [
               %{
                 field: "customer_signature",
                 integrity: :valid,
                 trust: :skipped,
                 total_document_signed: true
               }
             ]
           }
  end

  test "validate_trust/2 makes certificate posture explicit" do
    assert {:ok, posture} =
             Sign.validate_trust(signature_artifact(), adapter: FakeValidationAdapter)

    assert_receive {:fake_validate_called, _path, opts, _dir_mode, _file_mode}
    assert opts == [skip_certificate_validation: false]

    assert posture.signatures == [
             %{
               field: "customer_signature",
               integrity: :valid,
               trust: :valid,
               total_document_signed: true
             }
           ]
  end

  test "validate/2 wraps missing pdfsig as a typed validate-stage error" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.validate(signature_artifact(), adapter: MissingPdfsigAdapter)

    assert error.stage == :validate
    assert error.reason == {:missing_executable, "pdfsig"}

    assert error.details == %{
             adapter: MissingPdfsigAdapter,
             deterministic: nil,
             document_type: nil
           }
  end

  test "validate/2 reports unsigned artifacts without exposing temp paths or raw output" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.validate(signature_artifact(), adapter: UnsignedValidationAdapter)

    assert error.stage == :validate
    assert error.reason == {:invalid_pdf, :no_signatures}
    assert error.details.adapter == UnsignedValidationAdapter
    refute inspect(error.details) =~ "rendro-validate-"
    refute inspect(error) =~ "artifact.pdf"
  end

  test "augment/2 redacts adapter failures to adapter identity and adapter option keys only" do
    assert {:error, %Rendro.Error{} = error} =
             Sign.augment(signed_artifact(),
               adapter: FailingSignerAdapter,
               adapter_opts: [
                 tsa_url: "https://tsa.example.test",
                 passfile: "/tmp/pass.txt",
                 revocation_cache: "/tmp/revocation"
               ]
             )

    assert error.stage == :augment
    assert error.reason == {:command_failed, RuntimeError}
    assert error.details.adapter == FailingSignerAdapter
    assert error.details.adapter_opt_keys == [:passfile, :revocation_cache, :tsa_url]
    refute inspect(error.details) =~ "/tmp/pass.txt"
    refute inspect(error.details) =~ "/tmp/revocation"
  end

  test "augment/2 persists only safe long-lived metadata on augmented artifacts" do
    assert {:ok, augmented} =
             Sign.augment(signed_artifact(),
               adapter: SecretLeakingAdapter,
               adapter_opts: [tsa_url: "https://tsa.example.test"]
             )

    assert augmented.metadata.long_lived == %{
             status: :augmented,
             adapter: SecretLeakingAdapter,
             timestamp: :present,
             revocation: :embedded,
             compliance_evidence: :narrow_supported_path
           }

    assert augmented.metadata.long_lived_adapter == %{
             tool: :secret_leaker,
             evidence_profile: :pades_lta,
             timestamp_authority: :tsa_primary,
             revocation_sources: [:ocsp, :crl],
             passphrase_supplied: true
           }

    refute inspect(augmented.metadata.long_lived) =~ "trusted"
    refute inspect(augmented.metadata.long_lived) =~ "Rendro Test Signer"
    refute inspect(augmented.metadata.long_lived) =~ "tsa.example.test"
    refute inspect(augmented.metadata.long_lived_adapter) =~ "super-secret"
    refute inspect(augmented.metadata.long_lived_adapter) =~ "stderr"
    refute inspect(augmented.metadata.long_lived_adapter) =~ "/tmp/rendro-ltv"
    refute inspect(augmented.metadata.long_lived_adapter) =~ "raw-ocsp"
  end
end

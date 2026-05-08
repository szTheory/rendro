defmodule Rendro.Adapters.PdfsigTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfsig

  setup do
    on_exit(fn ->
      Application.delete_env(:rendro, :pdfsig_executable_finder)
      Application.delete_env(:rendro, :pdfsig_command_runner)
    end)

    :ok
  end

  test "returns missing executable when pdfsig is unavailable" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> nil end)

    assert {:error, {:missing_executable, "pdfsig"}} = Pdfsig.validate("/tmp/file.pdf")
  end

  test "parses signature validation output while skipping certificate validation by default" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> "/tmp/pdfsig" end)

    Application.put_env(:rendro, :pdfsig_command_runner, fn "/tmp/pdfsig", args, _opts ->
      assert args == ["-nocert", "/tmp/file.pdf"]

      {"""
       Digital Signature Info of: /tmp/file.pdf
       Signature #1:
         - Signature Field Name: customer_signature
         - Signer Certificate Common Name: Rendro Test Signer
         - Signer full Distinguished Name: CN=Rendro Test Signer
         - Signing Time: May 07 2026 10:55:59
         - Signing Hash Algorithm: SHA-256
         - Signature Type: adbe.pkcs7.detached
         - Signed Ranges: [0 - 3247], [7709 - 8288]
         - Total document signed
         - Signature Validation: Signature is Valid.
       """, 0}
    end)

    assert {:ok, %{signatures: [signature]}} = Pdfsig.validate("/tmp/file.pdf")
    assert signature.field == "customer_signature"
    assert signature.total_document_signed == true
    assert signature.integrity == :valid
    assert signature.trust == :skipped
    refute Map.has_key?(signature, :timestamp)
    refute Map.has_key?(signature, :revocation)
    refute Map.has_key?(signature, :compliance)
  end

  test "parses untrusted certificate posture when cert validation is enabled" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> "/tmp/pdfsig" end)

    Application.put_env(:rendro, :pdfsig_command_runner, fn "/tmp/pdfsig", args, _opts ->
      assert args == ["/tmp/file.pdf"]

      {"""
       Digital Signature Info of: /tmp/file.pdf
       Signature #1:
         - Signature Field Name: customer_signature
         - Signature Validation: Signature is Valid.
         - Certificate Validation: Certificate issuer isn't Trusted.
       """, 0}
    end)

    assert {:ok, %{signatures: [signature]}} =
             Pdfsig.validate("/tmp/file.pdf", skip_certificate_validation: false)

    assert signature.integrity == :valid
    assert signature.trust == :untrusted
  end

  test "classifies empty output as missing signatures" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> "/tmp/pdfsig" end)

    Application.put_env(:rendro, :pdfsig_command_runner, fn "/tmp/pdfsig", _args, _opts ->
      {"", 0}
    end)

    assert {:error, {:invalid_pdf, :no_signatures}} = Pdfsig.validate("/tmp/file.pdf")
  end

  test "parses signature posture from non-zero output when pdfsig still emits signature blocks" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> "/tmp/pdfsig" end)

    Application.put_env(:rendro, :pdfsig_command_runner, fn "/tmp/pdfsig", _args, _opts ->
      {"""
       NSS_Init failed: security library: bad database.
       Digital Signature Info of: /tmp/file.pdf
       Signature #1:
         - Signature Field Name: customer_signature
         - Signature Validation: Signature is Valid.
         - Certificate Validation: Certificate issuer is unknown.
       """, 1}
    end)

    assert {:ok, %{signatures: [signature]}} = Pdfsig.validate("/tmp/file.pdf")
    assert signature.field == "customer_signature"
    assert signature.integrity == :valid
    assert signature.trust == :unknown
  end

  test "classifies runner crashes as redacted tool failures" do
    Application.put_env(:rendro, :pdfsig_executable_finder, fn "pdfsig" -> "/tmp/pdfsig" end)

    Application.put_env(:rendro, :pdfsig_command_runner, fn "/tmp/pdfsig", _args, _opts ->
      raise RuntimeError, "pdfsig stderr with host-specific details"
    end)

    assert {:error, {:invalid_pdf, :tool_failure}} = Pdfsig.validate("/tmp/file.pdf")
  end
end

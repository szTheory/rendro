defmodule Rendro.Adapters.PyHankoTest do
  use ExUnit.Case, async: false

  import Bitwise

  alias Rendro.Adapters.PyHanko
  alias Rendro.Artifact

  setup do
    on_exit(fn ->
      Application.delete_env(:rendro, :pyhanko_executable_finder)
      Application.delete_env(:rendro, :pyhanko_command_runner)
    end)

    :ok
  end

  defp sample_artifact do
    %Artifact{
      binary: "%PDF-sample",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-sample"), case: :lower),
      diagnostics: [],
      metadata: %{page_count: 1}
    }
  end

  defp sample_opts do
    %{
      field: "customer_signature",
      adapter_opts: [
        key: "/tmp/test-key.pem",
        cert: "/tmp/test-cert.pem",
        passfile: "/tmp/test-pass.txt",
        chain: ["/tmp/intermediate.pem"],
        reason: "Approved"
      ]
    }
  end

  defp signed_artifact do
    %Artifact{
      binary: "%PDF-signed",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-signed"), case: :lower),
      diagnostics: [],
      metadata: %{
        page_count: 1,
        deterministic: false,
        signing: %{status: :signed, field: "customer_signature"}
      }
    }
  end

  defp augment_opts do
    %{
      adapter_opts: [
        tsa_url: "https://tsa.example.test",
        trust_roots: ["/tmp/root-ca.pem"],
        other_certs: ["/tmp/intermediate.pem"]
      ]
    }
  end

  test "returns a typed error when pyhanko is missing" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> nil end)

    assert {:error, {:missing_executable, "pyhanko"}} =
             PyHanko.sign(sample_artifact(), sample_opts())
  end

  test "passes pemder args through a private temp directory and returns signed bytes" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path, output_path] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()

      assert file_mode(Path.dirname(input_path)) == 0o700
      assert file_mode(input_path) == 0o600
      assert Enum.take(args, 4) == ["sign", "addsig", "--field", "customer_signature"]
      assert Enum.member?(args, "pemder")
      assert Enum.member?(args, "--key")
      assert Enum.member?(args, "/tmp/test-key.pem")
      assert Enum.member?(args, "--cert")
      assert Enum.member?(args, "/tmp/test-cert.pem")
      assert Enum.member?(args, "--passfile")
      assert Enum.member?(args, "/tmp/test-pass.txt")
      assert Enum.member?(args, "--chain")
      assert Enum.member?(args, "/tmp/intermediate.pem")
      assert Enum.member?(args, "--reason")
      assert Enum.member?(args, "Approved")

      File.write!(output_path, "%PDF-signed")
      {"ok", 0}
    end)

    assert {:ok, "%PDF-signed", metadata} = PyHanko.sign(sample_artifact(), sample_opts())
    assert metadata.tool == :pyhanko
    assert metadata.credential_source == :pemder
    assert metadata.chain_count == 1
    assert metadata.passphrase_supplied == true
  end

  test "cleans up its temp directory and redacts stderr on non-zero exit" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path | _] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()
      send(self(), {:tmp_dir, Path.dirname(input_path)})
      {"pyhanko failed for super-secret-passphrase", 2}
    end)

    assert {:error, {:pyhanko_failed, 2}} = PyHanko.sign(sample_artifact(), sample_opts())
    assert_receive {:tmp_dir, tmp_dir}
    refute File.exists?(tmp_dir)
  end

  test "validates required adapter-local options" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    assert {:error, {:missing_required_adapter_option, :key}} =
             PyHanko.sign(sample_artifact(), %{
               field: "customer_signature",
               adapter_opts: [cert: "/tmp/cert.pem"]
             })

    assert {:error, {:invalid_adapter_option, :chain, :bad}} =
             PyHanko.sign(sample_artifact(), %{
               field: "customer_signature",
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem", chain: :bad]
             })
  end

  test "augment uses a private temp directory, validates its narrow schema, and returns safe metadata" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path, output_path] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()

      assert file_mode(Path.dirname(input_path)) == 0o700
      assert file_mode(input_path) == 0o600
      assert Enum.take(args, 4) == ["sign", "ltvfix", "--field", "customer_signature"]
      assert Enum.member?(args, "--timestamp-url")
      assert Enum.member?(args, "https://tsa.example.test")
      assert Enum.member?(args, "--trust")
      assert Enum.member?(args, "/tmp/root-ca.pem")
      assert Enum.member?(args, "--other-cert")
      assert Enum.member?(args, "/tmp/intermediate.pem")

      File.write!(output_path, "%PDF-augmented")
      {"ok", 0}
    end)

    assert {:ok, "%PDF-augmented", metadata} = PyHanko.augment(signed_artifact(), augment_opts())

    assert metadata == %{
             tool: :pyhanko,
             tool_family: :pyhanko,
             evidence_profile: :timestamp_with_embedded_validation,
             timestamp: :present,
             revocation: :embedded,
             compliance_evidence: :narrow_supported_path,
             timestamp_authority: :configured,
             revocation_sources: [:ocsp, :crl]
           }
  end

  test "augment cleans up temp state and redacts failures on non-zero exit" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path | _] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()
      send(self(), {:augment_tmp_dir, Path.dirname(input_path)})
      {"tsa https://tsa.example.test failed", 9}
    end)

    assert {:error, {:pyhanko_failed, 9}} = PyHanko.augment(signed_artifact(), augment_opts())
    assert_receive {:augment_tmp_dir, tmp_dir}
    refute File.exists?(tmp_dir)
  end

  test "augment rejects malformed adapter-local inputs before command execution" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    assert {:error, {:missing_required_adapter_option, :tsa_url}} =
             PyHanko.augment(signed_artifact(), %{adapter_opts: [trust_roots: ["/tmp/root.pem"]]})

    assert {:error, {:missing_required_adapter_option, :trust_roots}} =
             PyHanko.augment(signed_artifact(), %{adapter_opts: [tsa_url: "https://tsa.example"]})

    assert {:error, {:invalid_adapter_option, :trust_roots, :bad}} =
             PyHanko.augment(signed_artifact(), %{
               adapter_opts: [
                 tsa_url: "https://tsa.example",
                 trust_roots: :bad
               ]
             })
  end

  test "validate decodes helper JSON into explicit evidence posture" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn
      "pyhanko" -> "/tmp/pyhanko"
      "python3" -> "/tmp/python3"
      "python" -> "/tmp/python"
    end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/python3", args, _opts ->
      assert List.last(args) == "/tmp/file.pdf"

      {"""
       {"signatures":[{"field":"customer_signature","integrity":"valid","trust":"valid","timestamp":"present","revocation":"embedded","compliance":{"level":"present","proofs":{"document_timestamp":true,"revocation_info":true},"gaps":[]},"total_document_signed":true}]}
       """, 0}
    end)

    assert {:ok, %{signatures: [signature]}} = PyHanko.validate("/tmp/file.pdf")
    assert signature.field == "customer_signature"
    assert signature.integrity == :valid
    assert signature.trust == :skipped
    assert signature.timestamp == :present
    assert signature.revocation == :embedded

    assert signature.compliance == %{
             scope: :embedded_validation_evidence,
             level: :present,
             proofs: %{document_timestamp: true, revocation_info: true},
             gaps: []
           }
  end

  test "validate maps incomplete evidence and trust-enabled posture without widening into blanket compliance" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn
      "pyhanko" -> "/tmp/pyhanko"
      "python3" -> "/tmp/python3"
      "python" -> "/tmp/python"
    end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/python3", _args, _opts ->
      {"""
       {"signatures":[{"field":"customer_signature","integrity":"valid","trust":"untrusted","timestamp":"missing","revocation":"missing","compliance":{"level":"incomplete","proofs":{"document_timestamp":false,"revocation_info":false},"gaps":["document_timestamp","revocation_info"]},"total_document_signed":false}]}
       """, 0}
    end)

    assert {:ok, %{signatures: [signature]}} =
             PyHanko.validate("/tmp/file.pdf", skip_certificate_validation: false)

    assert signature.trust == :untrusted
    assert signature.timestamp == :missing
    assert signature.revocation == :missing

    assert signature.compliance == %{
             scope: :embedded_validation_evidence,
             level: :incomplete,
             proofs: %{document_timestamp: false, revocation_info: false},
             gaps: ["document_timestamp", "revocation_info"]
           }
  end

  defp file_mode(path) do
    path
    |> File.stat!()
    |> Map.fetch!(:mode)
    |> band(0o777)
  end
end

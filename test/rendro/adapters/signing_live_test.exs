defmodule Rendro.Adapters.SigningLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.{Pdfsig, PyHanko}
  alias Rendro.Sign

  @fixtures_dir Path.expand("../../fixtures/signing", __DIR__)
  @certomancer_dir Path.join(@fixtures_dir, "certomancer")

  @signing_missing_tools [
                           {"pyhanko", System.find_executable("pyhanko")},
                           {"pdfsig", System.find_executable("pdfsig")}
                         ]
                         |> Enum.reject(fn {_tool, path} -> is_binary(path) end)
                         |> Enum.map(&elem(&1, 0))

  @signing_skip_reason (case @signing_missing_tools do
                          [] -> nil
                          [tool] -> "live signing proof requires #{tool} on PATH"
                          tools ->
                            "live signing proof requires #{Enum.join(tools, " and ")} on PATH"
                        end)

  @long_lived_missing_tools [
                              {"pyhanko", System.find_executable("pyhanko")},
                              {"pdfsig", System.find_executable("pdfsig")},
                              {"certomancer", System.find_executable("certomancer")}
                            ]
                            |> Enum.reject(fn {_tool, path} -> is_binary(path) end)
                            |> Enum.map(&elem(&1, 0))

  @long_lived_skip_reason (case @long_lived_missing_tools do
                             [] -> nil
                             [tool] -> "live long-lived proof requires #{tool} on PATH"
                             tools ->
                               "live long-lived proof requires #{Enum.join(tools, " and ")} on PATH"
                           end)

  if @signing_skip_reason do
    @tag skip: @signing_skip_reason
  end

  @tag live_signing: true
  test "real pyhanko plus pdfsig prove the v2.1 signed-artifact path" do
    tmp_dir = tmp_dir("rendro-live-signing")
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    {:ok, signed} =
      Sign.sign(sample_artifact(),
        field: "customer_signature",
        adapter: PyHanko,
        adapter_opts: [
          key: fixture_path("live_signer_key.pem"),
          cert: fixture_path("live_signer_cert.pem"),
          passfile: fixture_path("live_signer_passphrase.txt"),
          reason: "Approved"
        ]
      )

    assert signed.metadata.deterministic == false

    assert {:ok, %{signatures: [signature]}} = Sign.validate(signed)
    assert signature.field == "customer_signature"
    assert signature.integrity == :valid
    assert signature.trust == :skipped
    assert signature.total_document_signed == true

    signed_path = Path.join(tmp_dir, "signed.pdf")
    File.write!(signed_path, signed.binary)

    assert {:ok, %{signatures: [pdfsig_signature]}} = Pdfsig.validate(signed_path)
    assert pdfsig_signature.field == signature.field
    assert pdfsig_signature.integrity == :valid
    assert pdfsig_signature.trust == :skipped
    assert pdfsig_signature.total_document_signed == true
  end

  if @long_lived_skip_reason do
    @tag skip: @long_lived_skip_reason
  end

  @tag live_pdf_tools: true
  test "real pyhanko plus pdfsig prove the canonical long-lived path" do
    tmp_dir = tmp_dir("rendro-live-long-lived-proof")
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    port_number = available_port()
    service_url_prefix = "http://127.0.0.1:#{port_number}"
    certs_dir = Path.join(tmp_dir, "certs")

    {certomancer_pid, certomancer_log} =
      start_certomancer!(port_number, service_url_prefix, tmp_dir)

    on_exit(fn ->
      System.cmd("kill", ["-TERM", Integer.to_string(certomancer_pid)])
    end)

    wait_for_certomancer!(service_url_prefix, certomancer_log)
    export_certificates!(service_url_prefix, certs_dir)

    passfile = Path.join(tmp_dir, "signer-passphrase.txt")
    File.write!(passfile, "secret")

    {:ok, signed} =
      Sign.sign(sample_artifact(),
        field: "customer_signature",
        adapter: PyHanko,
        adapter_opts: [
          key: certomancer_key_path("signer.key.pem"),
          cert: Path.join(certs_dir, "signer1-long.cert.pem"),
          passfile: passfile,
          chain: [Path.join(certs_dir, "interm.cert.pem")]
        ]
      )

    assert signed.metadata.deterministic == false

    {:ok, augmented} =
      Sign.augment(signed,
        adapter: PyHanko,
        adapter_opts: [
          tsa_url: "#{service_url_prefix}/testing-ca/tsa/tsa",
          trust_roots: [Path.join(certs_dir, "root.cert.pem")],
          other_certs: [Path.join(certs_dir, "interm.cert.pem")]
        ]
      )

    assert augmented.metadata.long_lived == %{
             status: :augmented,
             adapter: PyHanko,
             timestamp: :present,
             revocation: :embedded,
             compliance_evidence: :narrow_supported_path
           }

    assert {:ok, %{signatures: [signature]}} =
             Sign.validate(augmented, adapter: PyHanko)

    assert signature.field == "customer_signature"
    assert signature.integrity == :valid
    assert signature.trust == :skipped
    assert signature.timestamp == :present
    assert signature.revocation == :embedded
    assert signature.total_document_signed == true

    assert signature.compliance == %{
             scope: :embedded_validation_evidence,
             level: :present,
             proofs: %{document_timestamp: true, revocation_info: true},
             gaps: []
           }

    augmented_path = Path.join(tmp_dir, "augmented.pdf")
    File.write!(augmented_path, augmented.binary)

    assert {:ok, %{signatures: [pdfsig_signature | _]}} = Pdfsig.validate(augmented_path)
    assert pdfsig_signature.field == signature.field
    assert pdfsig_signature.integrity == :valid
    assert pdfsig_signature.trust == :skipped
  end

  defp sample_artifact do
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

  defp start_certomancer!(port_number, service_url_prefix, tmp_dir) do
    executable = System.find_executable("certomancer") || raise "certomancer not found"
    log_path = Path.join(tmp_dir, "certomancer.log")

    command =
      [
        shell_quote(executable),
        "--config",
        shell_quote(certomancer_config_path()),
        "--key-root",
        shell_quote(@certomancer_dir),
        "--service-url-prefix",
        shell_quote(service_url_prefix),
        "animate",
        "--port",
        Integer.to_string(port_number),
        "--no-web-ui"
      ]
      |> Enum.join(" ")

    {pid, 0} =
      System.cmd("sh", [
        "-c",
        "#{command} > #{shell_quote(log_path)} 2>&1 & echo $!"
      ])

    {String.trim(pid) |> String.to_integer(), log_path}
  end

  defp export_certificates!(service_url_prefix, certs_dir) do
    {_, 0} =
      System.cmd(
        System.find_executable("certomancer") || raise("certomancer not found"),
        [
          "--config",
          certomancer_config_path(),
          "--key-root",
          @certomancer_dir,
          "--service-url-prefix",
          service_url_prefix,
          "mass-summon",
          "testing-ca",
          certs_dir,
          "--flat"
        ],
        stderr_to_stdout: true
      )
  end

  defp wait_for_certomancer!(service_url_prefix, log_path) do
    :inets.start()
    :ssl.start()
    url = String.to_charlist("#{service_url_prefix}/testing-ca/certs/root/ca.crt")

    wait_until(
      fn ->
        case :httpc.request(:get, {url, []}, [], []) do
          {:ok, {{_, 200, _}, _headers, _body}} -> true
          _ -> false
        end
      end,
      50,
      log_path
    )
  end

  defp wait_until(fun, attempts_remaining, log_path) when attempts_remaining > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(100)
      wait_until(fun, attempts_remaining - 1, log_path)
    end
  end

  defp wait_until(_fun, 0, log_path) do
    log =
      case File.read(log_path) do
        {:ok, contents} when contents != "" -> "\n\ncertomancer log:\n#{contents}"
        _ -> ""
      end

    flunk("certomancer did not become ready before timeout#{log}")
  end

  defp available_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {_ip, port_number}} = :inet.sockname(socket)
    :ok = :gen_tcp.close(socket)
    port_number
  end

  defp certomancer_config_path, do: Path.join(@certomancer_dir, "certomancer.yml")
  defp certomancer_key_path(file_name), do: Path.join([@certomancer_dir, "keys-rsa", file_name])
  defp fixture_path(file_name), do: Path.join(@fixtures_dir, file_name)

  defp shell_quote(value) do
    escaped = String.replace(value, "'", "'\"'\"'")
    "'#{escaped}'"
  end

  defp tmp_dir(prefix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(path)
    path
  end
end

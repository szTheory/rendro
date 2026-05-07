defmodule Rendro.Adapters.SigningLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfsig
  alias Rendro.Adapters.PyHanko
  alias Rendro.Sign

  @fixtures_dir Path.expand("../../fixtures/signing", __DIR__)
  @missing_tools [
                   {"pyhanko", System.find_executable("pyhanko")},
                   {"pdfsig", System.find_executable("pdfsig")}
                 ]
                 |> Enum.reject(fn {_tool, path} -> is_binary(path) end)
                 |> Enum.map(&elem(&1, 0))

  @skip_reason (case @missing_tools do
                  [] -> nil
                  [tool] -> "live signing proof requires #{tool} on PATH"
                  tools -> "live signing proof requires #{Enum.join(tools, " and ")} on PATH"
                end)

  if @skip_reason do
    @tag skip: @skip_reason
  end

  @tag live_pdf_tools: true
  test "real pyhanko plus pdfsig prove signed artifact validation" do
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

  defp fixture_path(file_name), do: Path.join(@fixtures_dir, file_name)

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

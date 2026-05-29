defmodule Rendro.Adapters.SignedArtifactViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.SignedArtifactPdfiumProof
  alias Rendro.ViewerEvidence.Recorder

  @fixture "test/fixtures/signed_artifact_viewer_proof.pdf"
  @evidence "priv/viewer_evidence/signed_artifact/chrome_pdfium.md"

  @tag live_pdf_tools: true
  test "pdfium-cli plus pdfsig prove signed_artifact viewer evidence on the committed fixture" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping signed_artifact viewer evidence live test: pdfium-cli is not installed")
      :ok
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)

      on_exit(fn ->
        Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      end)

      assert File.exists?(@fixture)
      assert {:ok, _result} = SignedArtifactPdfiumProof.run(@fixture)
      assert {:ok, _recorded} = Recorder.record("signed_artifact", "chrome_pdfium")
      assert File.exists?(@evidence)
    end
  end
end

defmodule Rendro.Adapters.SignatureWidgetViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.SignatureWidgetPdfiumProof
  alias Rendro.ViewerEvidence.Recorder

  @fixture "test/fixtures/signature_widget_support_fixture.pdf"
  @evidence "priv/viewer_evidence/signature_widget/chrome_pdfium.md"

  @tag live_pdf_tools: true
  test "pdfium-cli proves signature_widget viewer evidence on the committed fixture" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping signature_widget viewer evidence live test: pdfium-cli is not installed")
      :ok
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)

      on_exit(fn ->
        Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      end)

      assert File.exists?(@fixture)
      assert {:ok, _result} = SignatureWidgetPdfiumProof.run(@fixture)
      assert {:ok, _recorded} = Recorder.record("signature_widget", "chrome_pdfium")
      assert File.exists?(@evidence)
    end
  end
end

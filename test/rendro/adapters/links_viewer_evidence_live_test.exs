defmodule Rendro.Adapters.LinksViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.ViewerEvidence.LinksPdfiumProof

  @fixture "test/fixtures/embedded_artifact_support_fixture.pdf"
  @tag live_pdf_tools: true
  test "pdfium-cli proves links viewer evidence behaviors for Acrobat and Preview matrix rows" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping links viewer evidence live test: pdfium-cli is not installed")
      :ok
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)

      on_exit(fn ->
        Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      end)

      assert File.exists?(@fixture)

      assert {:ok, _acrobat} =
               LinksPdfiumProof.run(@fixture, viewer: "adobe_acrobat_reader")

      assert {:ok, _preview} =
               LinksPdfiumProof.run(@fixture, viewer: "apple_preview")
    end
  end
end

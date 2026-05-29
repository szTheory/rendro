defmodule Rendro.Adapters.EmbeddedFilesViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.ViewerEvidence.EmbeddedFilesPdfiumProof

  @fixture "test/fixtures/embedded_artifact_support_fixture.pdf"
  @tag live_pdf_tools: true
  test "pdfium-cli proves embedded_files viewer evidence behaviors on the committed fixture" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping embedded_files viewer evidence live test: pdfium-cli is not installed")
      :ok
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)

      on_exit(fn ->
        Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      end)

      assert File.exists?(@fixture)
      assert {:ok, _result} = EmbeddedFilesPdfiumProof.run(@fixture)
    end
  end
end

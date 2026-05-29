defmodule Rendro.Adapters.FormsViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.ViewerEvidence.{FormsApplePreviewProof, FormsPdfiumProof}

  @fixture "test/fixtures/forms_support_fixture.pdf"
  @tag live_pdf_tools: true
  test "pdfium-cli proves forms viewer evidence behaviors on the committed fixture" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping forms viewer evidence live test: pdfium-cli is not installed")
      :ok
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)

      on_exit(fn ->
        Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      end)

      assert File.exists?(@fixture)
      assert {:ok, _result} = FormsPdfiumProof.run(@fixture)
      assert {:ok, _preview} = FormsApplePreviewProof.run(@fixture)
      assert {:ok, version} = Pdfium.version()
      assert is_binary(version) and version != ""
    end
  end
end

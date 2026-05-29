defmodule Rendro.Adapters.TrustSensitiveViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.ViewerEvidence.Recorder

  setup do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if executable do
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)
    end

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    %{
      pdfium: executable,
      pdfsig: System.find_executable("pdfsig"),
      pyhanko: System.find_executable("pyhanko")
    }
  end

  @tag live_pdf_tools: true
  test "records all Phase 71 structural-proxy evidence files", %{
    pdfium: pdfium,
    pdfsig: pdfsig,
    pyhanko: pyhanko
  } do
    if is_nil(pdfium) do
      IO.puts("Skipping Phase 71 viewer evidence recording: pdfium-cli is not installed")
      :ok
    else
      recordings = [
        {"forms", "adobe_acrobat_reader", "priv/viewer_evidence/forms/adobe_acrobat_reader.md",
         [:pdfium]},
        {"protection", "adobe_acrobat_reader", "priv/viewer_evidence/protection/adobe_acrobat_reader.md",
         [:pdfium]},
        {"signature_widget", "adobe_acrobat_reader",
         "priv/viewer_evidence/signature_widget/adobe_acrobat_reader.md", [:pdfium, :pdfsig]},
        {"signature_widget", "apple_preview", "priv/viewer_evidence/signature_widget/apple_preview.md",
         [:pdfium, :pdfsig]},
        {"signing_preparation", "adobe_acrobat_reader",
         "priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md", [:pdfium]},
        {"signed_artifact", "adobe_acrobat_reader",
         "priv/viewer_evidence/signed_artifact/adobe_acrobat_reader.md", [:pdfium, :pdfsig]},
        {"long_lived_signed_artifact", "adobe_acrobat_reader",
         "priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md",
         [:pdfium, :pyhanko]}
      ]

      tools = %{pdfium: pdfium, pdfsig: pdfsig, pyhanko: pyhanko}

      for {surface, viewer, evidence_path, required} <- recordings do
        missing = Enum.filter(required, &is_nil(Map.fetch!(tools, &1)))

        if missing == [] do
          assert {:ok, _recorded} = Recorder.record(surface, viewer)
          assert File.exists?(evidence_path)
        else
          IO.puts("Skipping #{surface} × #{viewer}: missing #{inspect(missing)}")
        end
      end
    end
  end
end

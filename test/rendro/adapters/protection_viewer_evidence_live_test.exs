defmodule Rendro.Adapters.ProtectionViewerEvidenceLiveTest do
  use ExUnit.Case, async: false

  alias Rendro.ViewerEvidence.ProtectionPopplerProof

  @fixture "test/fixtures/protection_support_fixture.pdf"
  @tag live_pdf_tools: true
  test "pdfinfo and qpdf prove protection viewer evidence behaviors on the committed fixture" do
    if System.find_executable("pdfinfo") && System.find_executable("qpdf") do
      assert File.exists?(@fixture)
      assert {:ok, _result} = ProtectionPopplerProof.run(@fixture)
    else
      IO.puts("Skipping protection viewer evidence live test: pdfinfo or qpdf is not installed")
      :ok
    end
  end
end

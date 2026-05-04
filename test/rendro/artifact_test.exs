defmodule Rendro.ArtifactTest do
  use ExUnit.Case
  alias Rendro.Artifact
  alias Rendro.Document

  test "new/3 calculates SHA-256 hash and assigns defaults" do
    binary = "fake_pdf_bytes"
    doc = %Document{pages: [%Rendro.Page{}], diagnostics: [%{type: :info}]}

    artifact = Artifact.new(binary, doc, %{source: "test"})

    assert artifact.binary == "fake_pdf_bytes"
    assert artifact.hash == Base.encode16(:crypto.hash(:sha256, "fake_pdf_bytes"), case: :lower)
    assert artifact.diagnostics == [%{type: :info}]
    assert artifact.metadata.page_count == 1
    assert artifact.metadata.source == "test"
  end
end

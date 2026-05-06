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

  test "wrap/3 preserves source metadata while allowing a minimal protection contract" do
    original =
      %Artifact{
        binary: "old",
        hash: "ignored",
        diagnostics: [%{type: :warning}],
        metadata: %{page_count: 2, deterministic: true}
      }

    wrapped =
      Artifact.wrap("new", original, %{
        deterministic: false,
        protection: %{
          algorithm: :aes_256,
          advisory_permissions: [:print],
          has_open_password: true,
          has_owner_password: true
        }
      })

    assert wrapped.binary == "new"
    assert wrapped.hash == Base.encode16(:crypto.hash(:sha256, "new"), case: :lower)
    assert wrapped.diagnostics == [%{type: :warning}]
    assert wrapped.metadata.page_count == 2
    assert wrapped.metadata.deterministic == false

    assert wrapped.metadata.protection == %{
             algorithm: :aes_256,
             advisory_permissions: [:print],
             has_open_password: true,
             has_owner_password: true
           }
  end
end

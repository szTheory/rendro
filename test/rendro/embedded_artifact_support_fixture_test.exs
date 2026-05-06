defmodule Rendro.EmbeddedArtifactSupportFixtureTest do
  @moduledoc """
  Lightweight structural proof that the representative embedded-artifact
  fixture really exercises the supported v1.9 surface in one document:

  - one document-level embedded file with explicit deterministic metadata
  - one external `http`/`https` link annotation
  - one internal page-destination link annotation

  This is intentionally narrow. It does NOT prove viewer discoverability,
  extraction, navigation, or any other interactive behavior. Per Phase 50
  D-10 through D-14, those evidence claims live in the manual viewer
  proof lane and not in this automated lane.
  """

  use ExUnit.Case, async: true

  alias Rendro.Test.EmbeddedArtifactSupportFixture

  describe "Rendro.Test.EmbeddedArtifactSupportFixture" do
    test "renders a deterministic PDF binary" do
      {:ok, pdf} = EmbeddedArtifactSupportFixture.render_pdf()
      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-1.4")

      {:ok, pdf_again} = EmbeddedArtifactSupportFixture.render_pdf()
      assert pdf_again == pdf
    end

    test "exercises one document-level embedded file with explicit metadata" do
      {:ok, pdf} = EmbeddedArtifactSupportFixture.render_pdf()

      assert pdf =~ "/Type /EmbeddedFile"
      assert pdf =~ "/Type /Filespec"
      assert pdf =~ "/EmbeddedFiles <<"
      assert pdf =~ "/AF ["
      assert pdf =~ "(invoice.csv)"
      assert pdf =~ "/Desc (Billing export)"
      assert pdf =~ "/CreationDate (D:20260505140000Z)"
    end

    test "exercises one external http/https URI link annotation" do
      {:ok, pdf} = EmbeddedArtifactSupportFixture.render_pdf()

      assert pdf =~ "/Subtype /Link"
      assert pdf =~ "/S /URI"
      assert pdf =~ "/URI (https://example.com/docs)"
    end

    test "exercises one internal page-destination link annotation" do
      {:ok, pdf} = EmbeddedArtifactSupportFixture.render_pdf()

      # Internal page link serializes as a direct /Dest array referencing
      # a later page object. Phase 49 proves this exact shape.
      assert pdf =~ ~r|/Dest \[\d+ 0 R /Fit\]|
    end

    test "writes the fixture to a stable path on disk" do
      path = Path.join(System.tmp_dir!(), "embedded_artifact_fixture_#{System.unique_integer([:positive])}.pdf")

      assert ^path = EmbeddedArtifactSupportFixture.write_fixture(path)
      assert File.exists?(path)

      contents = File.read!(path)
      assert String.starts_with?(contents, "%PDF-1.4")

      File.rm!(path)
    end

    test "does not widen into unsupported surfaces" do
      # Per Phase 50 D-15..D-17 and Phase 49 link scope, the fixture must
      # stay strictly inside the supported v1.9 artifact surface.
      {:ok, pdf} = EmbeddedArtifactSupportFixture.render_pdf()

      refute pdf =~ "/Subtype /FileAttachment"
      refute pdf =~ "/S /Launch"
      refute pdf =~ "/S /JavaScript"
      refute pdf =~ "/S /GoToR"
      refute pdf =~ "/Names /Dests"
    end
  end
end

defmodule Rendro.SigningViewerSupportFixtureTest do
  use ExUnit.Case, async: true

  alias Rendro.Test.SigningViewerSupportFixture

  @widget_fixture "test/fixtures/signature_widget_support_fixture.pdf"
  @preparation_fixture "test/fixtures/signing_preparation_support_fixture.pdf"

  test "signature widget support fixture exists with unsigned /Sig widget" do
    assert File.exists?(@widget_fixture)

    binary = File.read!(@widget_fixture)

    assert binary =~ "%PDF"
    assert binary =~ "/FT /Sig"
    assert binary =~ "/T (customer_signature)"
    refute binary =~ "/ByteRange"
    refute binary =~ "/Contents <"
  end

  test "signing preparation support fixture exists with byte-range layout" do
    assert File.exists?(@preparation_fixture)

    binary = File.read!(@preparation_fixture)

    assert binary =~ "%PDF"
    assert binary =~ "/ByteRange ["
    assert binary =~ "/Contents <"
  end

  test "write_signature_widget_fixture/1 regenerates committed fixture bytes" do
    tmp = Path.join(System.tmp_dir!(), "sig-widget-#{System.unique_integer([:positive])}.pdf")

    try do
      SigningViewerSupportFixture.write_signature_widget_fixture(tmp)
      committed = File.read!(@widget_fixture)
      regenerated = File.read!(tmp)
      assert regenerated =~ "%PDF"
      assert regenerated =~ "/FT /Sig"
      assert byte_size(regenerated) == byte_size(committed)
    after
      File.rm(tmp)
    end
  end

  test "write_signing_preparation_fixture/1 produces valid Sign.prepare/2 output" do
    tmp = Path.join(System.tmp_dir!(), "sig-prep-#{System.unique_integer([:positive])}.pdf")

    try do
      SigningViewerSupportFixture.write_signing_preparation_fixture(tmp)
      binary = File.read!(tmp)

      assert binary =~ "%PDF"
      assert binary =~ "/ByteRange ["
    after
      File.rm(tmp)
    end
  end
end

defmodule Rendro.Forms.AcroformFixtureTest do
  use ExUnit.Case, async: true

  alias Rendro.Test.FormSupportFixture

  test "forms support fixture encodes default AcroForm field values" do
    {:ok, pdf} = FormSupportFixture.render_pdf()
    binary = IO.iodata_to_binary(pdf)

    assert binary =~ "%PDF"
    assert binary =~ "/V (jon@example.test)"
    assert binary =~ "/V /Yes"
    assert binary =~ "/AS /Yes"
    assert binary =~ "/V /email"
    assert binary =~ "/AS /email"
  end
end

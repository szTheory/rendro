defmodule Rendro.ErrorTest do
  use ExUnit.Case, async: true

  test "from_stage/3 builds actionable diagnostics" do
    error =
      Rendro.Error.from_stage(:build, :no_pages, %{
        render_id: "render-123",
        deterministic: true,
        document_type: :pdf
      })

    assert error.stage == :build
    assert error.reason == :no_pages
    assert error.render_id == "render-123"
    assert error.where == "Rendro.Pipeline.Build"
    assert error.what =~ "validation"
    assert error.why == "no pages"
    assert error.next =~ "Add at least one page"
    assert error.details == %{document_type: :pdf, deterministic: true}
  end

  test "render/1 returns Rendro.Error on invalid documents" do
    assert {:error, %Rendro.Error{} = error} = Rendro.render(%Rendro.Document{pages: []})
    assert error.stage == :build
    assert error.reason == :no_pages
    assert is_binary(error.render_id)
  end
end

defmodule Rendro.Adapters.PdfiumTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Pdfium

  test "returns missing executable when pdfium-cli is absent" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> nil end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert {:error, {:missing_executable, "pdfium-cli"}} =
             Pdfium.info("test/fixtures/forms_support_fixture.pdf")
  end

  # T-85-01: un-skip in Plan 02 after render/2 is implemented
  @tag :skip
  test "render/2 returns missing executable error when pdfium-cli is absent" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> nil end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert {:error, {:missing_executable, "pdfium-cli"}} =
             Pdfium.render(<<37, 80, 68, 70>>, [])
  end
end

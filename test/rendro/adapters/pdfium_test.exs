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

  test "render/2 returns missing executable error when pdfium-cli is absent" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> nil end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert {:error, {:missing_executable, "pdfium-cli"}} =
             Pdfium.render(<<37, 80, 68, 70>>, [])
  end

  test "render/2 with mock command runner returns {:ok, [png_binary]}" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/usr/bin/echo" end)

    Application.put_env(:rendro, :pdfium_cli_command_runner, fn _exe, args, _opts ->
      # args = ["render", input_path, output_pattern, "--dpi", dpi_str, "--file-type", "png"]
      # Derive tmp_dir from the output_pattern (third arg, index 2)
      output_pattern = Enum.at(args, 2)
      tmp_dir = Path.dirname(output_pattern)
      File.write!(Path.join(tmp_dir, "page_1.png"), "FAKEPNG")
      {"", 0}
    end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      Application.delete_env(:rendro, :pdfium_cli_command_runner)
    end)

    assert {:ok, [<<"FAKEPNG">>]} = Pdfium.render(<<1, 2, 3>>, dpi: 150)
  end
end

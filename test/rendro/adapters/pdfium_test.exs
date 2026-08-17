defmodule Rendro.Adapters.PdfiumTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Pdfium

  test "executable/0 exposes the configured PDFium binary" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/usr/bin/echo" end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert Pdfium.executable() == {:ok, "/usr/bin/echo"}
  end

  test "provenance_executable/0 accepts a separately pinned artifact for a command wrapper" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/tmp/pdfium-wrapper" end)
    Application.put_env(:rendro, :pdfium_cli_provenance_executable, "/tmp/pinned-pdfium-cli")

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      Application.delete_env(:rendro, :pdfium_cli_provenance_executable)
    end)

    assert Pdfium.executable() == {:ok, "/tmp/pdfium-wrapper"}
    assert Pdfium.provenance_executable() == {:ok, "/tmp/pinned-pdfium-cli"}
  end

  test "provenance_executable/0 accepts the container runner environment override" do
    System.put_env("RENDRO_PDFIUM_PROVENANCE_CLI", "/tmp/pinned-pdfium-cli")

    on_exit(fn ->
      System.delete_env("RENDRO_PDFIUM_PROVENANCE_CLI")
    end)

    assert Pdfium.provenance_executable() == {:ok, "/tmp/pinned-pdfium-cli"}
  end

  test "provenance_executable/0 defaults to the executed binary" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/usr/bin/echo" end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
    end)

    assert Pdfium.provenance_executable() == {:ok, "/usr/bin/echo"}
  end

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

  test "render/2 rejects invalid page range before invoking command runner" do
    test_pid = self()

    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/usr/bin/echo" end)

    Application.put_env(:rendro, :pdfium_cli_command_runner, fn _exe, _args, _opts ->
      send(test_pid, :runner_invoked)
      {"", 0}
    end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      Application.delete_env(:rendro, :pdfium_cli_command_runner)
    end)

    assert Pdfium.render(<<1, 2, 3>>, pages: "--help") ==
             {:error, {:invalid_option, :pages, "must be a page range like \"1-3,5\""}}

    refute_received :runner_invoked
  end

  test "render/2 returns PNGs in numeric page order" do
    Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> "/usr/bin/echo" end)

    Application.put_env(:rendro, :pdfium_cli_command_runner, fn _exe, args, _opts ->
      output_pattern = Enum.at(args, 2)
      tmp_dir = Path.dirname(output_pattern)
      File.write!(Path.join(tmp_dir, "page_10.png"), "TEN")
      File.write!(Path.join(tmp_dir, "page_2.png"), "TWO")
      File.write!(Path.join(tmp_dir, "page_1.png"), "ONE")
      {"", 0}
    end)

    on_exit(fn ->
      Application.delete_env(:rendro, :pdfium_cli_executable_finder)
      Application.delete_env(:rendro, :pdfium_cli_command_runner)
    end)

    assert Pdfium.render(<<1, 2, 3>>, pages: "1-10") == {:ok, ["ONE", "TWO", "TEN"]}
  end
end

defmodule Rendro.Adapters.PopplerTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Poppler

  setup do
    on_exit(fn ->
      Application.delete_env(:rendro, :pdfinfo_executable_finder)
      Application.delete_env(:rendro, :pdfinfo_command_runner)
    end)

    :ok
  end

  describe "validate/2" do
    test "returns missing executable when pdfinfo is unavailable, even with password opts" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> nil end)

      assert {:error, {:missing_executable, "pdfinfo"}} =
               Poppler.validate("dummy.pdf",
                 open_password: "open-secret",
                 owner_password: "owner-secret"
               )
    end

    test "uses only the open password when both passwords are provided" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", args, _opts ->
        assert args == ["-upw", "open-secret", "protected.pdf"]
        {"Pages: 1\nEncrypted: yes\n", 0}
      end)

      assert {:ok, %{"Encrypted" => "yes", "Pages" => "1"}} =
               Poppler.validate("protected.pdf",
                 open_password: "open-secret",
                 owner_password: "owner-secret"
               )
    end

    test "falls back to owner password only when the open password is absent or blank" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", args, _opts ->
        assert args == ["-opw", "owner-secret", "protected.pdf"]
        {"Pages: 1\nEncrypted: yes\n", 0}
      end)

      assert {:ok, %{"Encrypted" => "yes", "Pages" => "1"}} =
               Poppler.validate("protected.pdf",
                 open_password: "   ",
                 owner_password: "owner-secret"
               )
    end

    test "passes no password flags when neither password is present" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", args, _opts ->
        assert args == ["plain.pdf"]
        {"Pages: 1\nEncrypted: no\n", 0}
      end)

      assert {:ok, %{"Encrypted" => "no", "Pages" => "1"}} = Poppler.validate("plain.pdf")
    end

    test "normalizes password-required failures without exposing raw stderr" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        {"Command Line Error: Incorrect password or password required for encrypted document", 1}
      end)

      assert {:error, {:invalid_pdf, :password_required}} = Poppler.validate("protected.pdf")
    end

    test "treats poppler's incorrect-password wording as password_required when no password was supplied" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        {"Command Line Error: Incorrect password", 1}
      end)

      assert {:error, {:invalid_pdf, :password_required}} = Poppler.validate("protected.pdf")
    end

    test "normalizes incorrect-password failures without exposing raw stderr" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        {"Command Line Error: Incorrect password", 1}
      end)

      assert {:error, {:invalid_pdf, :incorrect_password}} =
               Poppler.validate("protected.pdf", open_password: "wrong-secret")
    end

    test "normalizes corrupt-file failures to structural_invalidity" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        {"Syntax Error: Couldn't find trailer dictionary\nSyntax Error: Couldn't read xref table", 1}
      end)

      assert {:error, {:invalid_pdf, :structural_invalidity}} = Poppler.validate("corrupt.pdf")
    end

    test "normalizes unexpected tool failures to tool_failure" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        {"Poppler crashed in /tmp/secret-path", 99}
      end)

      assert {:error, {:invalid_pdf, :tool_failure}} = Poppler.validate("protected.pdf")
    end

    test "returns tool_failure when the runner raises" do
      Application.put_env(:rendro, :pdfinfo_executable_finder, fn "pdfinfo" -> "/tmp/pdfinfo" end)

      Application.put_env(:rendro, :pdfinfo_command_runner, fn "/tmp/pdfinfo", _args, _opts ->
        raise RuntimeError, "boom"
      end)

      assert {:error, {:invalid_pdf, :tool_failure}} = Poppler.validate("protected.pdf")
    end
  end
end

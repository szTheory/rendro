defmodule Rendro.Adapters.QpdfTest do
  use ExUnit.Case, async: false

  import Bitwise

  alias Rendro.Adapters.Qpdf
  alias Rendro.Artifact

  setup do
    on_exit(fn ->
      Application.delete_env(:rendro, :qpdf_executable_finder)
      Application.delete_env(:rendro, :qpdf_command_runner)
    end)

    :ok
  end

  defp sample_artifact do
    %Artifact{
      binary: "%PDF-sample",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-sample"), case: :lower),
      diagnostics: [],
      metadata: %{page_count: 1}
    }
  end

  defp sample_opts do
    %{
      algorithm: :aes_256,
      advisory_permissions: [:copy, :print],
      open_password: "open-secret",
      owner_password: "owner-secret"
    }
  end

  test "returns a typed error when qpdf is missing" do
    Application.put_env(:rendro, :qpdf_executable_finder, fn "qpdf" -> nil end)

    assert {:error, {:missing_executable, "qpdf"}} =
             Qpdf.protect(sample_artifact(), sample_opts())
  end

  test "passes AES-256 args through an @argfile and returns the protected bytes" do
    Application.put_env(:rendro, :qpdf_executable_finder, fn "qpdf" -> "/tmp/fake-qpdf" end)

    Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf",
                                                          ["@" <> path],
                                                          _opts ->
      input_path = Path.join(Path.dirname(path), "input.pdf")
      assert file_mode(Path.dirname(path)) == 0o700
      assert file_mode(path) == 0o600
      assert file_mode(input_path) == 0o600

      [first | rest] = File.read!(path) |> String.split("\n", trim: true)
      assert first == "--encrypt"
      assert Enum.member?(rest, "open-secret")
      assert Enum.member?(rest, "owner-secret")
      assert Enum.member?(rest, "256")
      assert Enum.member?(rest, "--print=full")
      assert Enum.member?(rest, "--extract=y")
      assert Enum.member?(rest, "--modify=none")
      assert Enum.member?(rest, "--")

      output_path = List.last(rest)
      File.write!(output_path, "%PDF-protected")
      {"ok", 0}
    end)

    assert {:ok, "%PDF-protected"} = Qpdf.protect(sample_artifact(), sample_opts())
  end

  test "cleans up its temp directory and redacts qpdf stderr on non-zero exit" do
    Application.put_env(:rendro, :qpdf_executable_finder, fn "qpdf" -> "/tmp/fake-qpdf" end)

    Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf",
                                                          ["@" <> path],
                                                          _opts ->
      send(self(), {:tmp_dir, Path.dirname(path)})
      {"qpdf failed for open-secret", 2}
    end)

    assert {:error, {:qpdf_failed, 2}} = Qpdf.protect(sample_artifact(), sample_opts())
    assert_receive {:tmp_dir, tmp_dir}
    refute File.exists?(tmp_dir)
  end

  test "cleans up its temp directory and returns a typed error when the runner raises" do
    Application.put_env(:rendro, :qpdf_executable_finder, fn "qpdf" -> "/tmp/fake-qpdf" end)

    Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf",
                                                          ["@" <> path],
                                                          _opts ->
      send(self(), {:tmp_dir, Path.dirname(path)})
      raise RuntimeError, "owner-secret"
    end)

    assert {:error, {:command_failed, RuntimeError}} =
             Qpdf.protect(sample_artifact(), sample_opts())

    assert_receive {:tmp_dir, tmp_dir}
    refute File.exists?(tmp_dir)
  end

  defp file_mode(path) do
    path
    |> File.stat!()
    |> Map.fetch!(:mode)
    |> band(0o777)
  end
end

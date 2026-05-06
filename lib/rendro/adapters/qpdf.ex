defmodule Rendro.Adapters.Qpdf do
  @moduledoc """
  Optional runtime adapter for qpdf-based PDF protection.

  qpdf is an external executable, not a Hex dependency. Rendro keeps it behind
  an artifact-first boundary so the core rendering pipeline stays pure Elixir.
  """

  @behaviour Rendro.Protect.Adapter

  @spec protect(Rendro.Artifact.t(), map()) :: {:ok, binary()} | {:error, term()}
  def protect(%Rendro.Artifact{} = artifact, opts) when is_map(opts) do
    with {:ok, executable} <- find_executable(),
         {:ok, tmp_dir} <- make_tmp_dir() do
      try do
        protect_with_tmp_dir(executable, tmp_dir, artifact.binary, opts)
      after
        File.rm_rf(tmp_dir)
      end
    end
  end

  defp find_executable do
    finder = Application.get_env(:rendro, :qpdf_executable_finder, &System.find_executable/1)

    case finder.("qpdf") do
      nil -> {:error, {:missing_executable, "qpdf"}}
      executable -> {:ok, executable}
    end
  end

  defp run_command(executable, args) do
    runner = Application.get_env(:rendro, :qpdf_command_runner, &System.cmd/3)

    try do
      runner.(executable, args, stderr_to_stdout: true)
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp protect_with_tmp_dir(executable, tmp_dir, binary, opts) do
    with {:ok, input_path, output_path} <- write_input_paths(tmp_dir, binary),
         {:ok, argfile_path} <- write_argfile(tmp_dir, input_path, output_path, opts),
         {:ok, protected_binary} <- run_qpdf(executable, argfile_path, output_path) do
      {:ok, protected_binary}
    end
  end

  defp run_qpdf(executable, argfile_path, output_path) do
    case run_command(executable, ["@" <> argfile_path]) do
      {:error, _reason} = error ->
        error

      {_output, 0} ->
        File.read(output_path)

      {_output, exit_code} ->
        {:error, {:qpdf_failed, exit_code}}
    end
  end

  defp make_tmp_dir do
    path =
      Path.join(
        System.tmp_dir!(),
        "rendro-protect-#{System.unique_integer([:positive, :monotonic])}"
      )

    with :ok <- File.mkdir_p(path),
         :ok <- File.chmod(path, 0o700) do
      {:ok, path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_input_paths(tmp_dir, binary) do
    input_path = Path.join(tmp_dir, "input.pdf")
    output_path = Path.join(tmp_dir, "output.pdf")

    case write_private_file(input_path, binary) do
      :ok -> {:ok, input_path, output_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_argfile(tmp_dir, input_path, output_path, opts) do
    argfile_path = Path.join(tmp_dir, "qpdf.args")

    args =
      [
        "--encrypt",
        opts.open_password,
        opts.owner_password,
        "256"
      ] ++ permission_args(opts.advisory_permissions) ++ ["--", input_path, output_path]

    case write_private_file(argfile_path, Enum.join(args, "\n") <> "\n") do
      :ok -> {:ok, argfile_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_private_file(path, contents) do
    File.rm(path)

    with :ok <- File.write(path, contents, [:write, :exclusive, {:mode, 0o600}]),
         :ok <- File.chmod(path, 0o600) do
      :ok
    end
  end

  defp permission_args(permissions) do
    [
      print_arg(permissions),
      modify_arg(permissions),
      yes_no_arg("--extract", :copy in permissions),
      yes_no_arg("--annotate", :annotate in permissions),
      yes_no_arg("--form", :fill_forms in permissions),
      yes_no_arg("--assemble", :assemble in permissions),
      yes_no_arg("--accessibility", :extract_for_accessibility in permissions)
    ]
  end

  defp print_arg(permissions) do
    if :print in permissions, do: "--print=full", else: "--print=none"
  end

  defp modify_arg(permissions) do
    if :modify in permissions, do: "--modify=all", else: "--modify=none"
  end

  defp yes_no_arg(flag, true), do: "#{flag}=y"
  defp yes_no_arg(flag, false), do: "#{flag}=n"
end

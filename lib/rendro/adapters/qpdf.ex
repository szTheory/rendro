defmodule Rendro.Adapters.Qpdf do
  @moduledoc """
  Optional runtime adapter for qpdf-based PDF protection.

  qpdf is an external executable, not a Hex dependency. Rendro keeps it behind
  an artifact-first boundary so the core rendering pipeline stays pure Elixir.
  """
  @moduledoc tags: [:adapter]

  @behaviour Rendro.Protect.Adapter

  @type protect_opts :: %{
          required(:algorithm) => :aes_256,
          required(:advisory_permissions) => [Rendro.Protect.permission()],
          required(:open_password) => String.t(),
          required(:owner_password) => String.t(),
          optional(atom()) => term()
        }

  @spec protect(Rendro.Artifact.t(), protect_opts()) :: {:ok, binary()} | {:error, term()}
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

  @spec protect_with_tmp_dir(String.t(), String.t(), binary(), protect_opts()) ::
          {:ok, binary()} | {:error, term()}
  defp protect_with_tmp_dir(executable, tmp_dir, binary, opts) do
    with {:ok, input_path, output_path} <- write_input_paths(tmp_dir, binary),
         {:ok, argfile_path} <- write_argfile(tmp_dir, input_path, output_path, opts),
         {:ok, protected_binary} <- run_qpdf(executable, argfile_path, output_path) do
      {:ok, protected_binary}
    end
  end

  @spec run_qpdf(String.t(), String.t(), String.t()) :: {:ok, binary()} | {:error, term()}
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

  @spec make_tmp_dir() :: {:ok, String.t()} | {:error, File.posix() | :badarg}
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

  @spec write_input_paths(String.t(), binary()) ::
          {:ok, String.t(), String.t()} | {:error, term()}
  defp write_input_paths(tmp_dir, binary) do
    input_path = Path.join(tmp_dir, "input.pdf")
    output_path = Path.join(tmp_dir, "output.pdf")

    case write_private_file(input_path, binary) do
      :ok -> {:ok, input_path, output_path}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec write_argfile(String.t(), String.t(), String.t(), protect_opts()) ::
          {:ok, String.t()} | {:error, term()}
  defp write_argfile(tmp_dir, input_path, output_path, opts) do
    argfile_path = Path.join(tmp_dir, "qpdf.args")

    args =
      [
        "--encrypt",
        Map.fetch!(opts, :open_password),
        Map.fetch!(opts, :owner_password),
        "256"
      ] ++
        permission_args(Map.fetch!(opts, :advisory_permissions)) ++
        ["--", input_path, output_path]

    case write_private_file(argfile_path, Enum.join(args, "\n") <> "\n") do
      :ok -> {:ok, argfile_path}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec write_private_file(Path.t(), iodata()) :: :ok | {:error, term()}
  defp write_private_file(path, contents) do
    File.rm(path)

    with :ok <- File.write(path, contents, [:write, :exclusive, :binary]),
         :ok <- File.chmod(path, 0o600) do
      :ok
    end
  end

  @spec permission_args([Rendro.Protect.permission()]) :: [String.t()]
  defp permission_args(permissions) do
    [
      print_arg(permissions),
      modify_arg(permissions),
      yes_no_arg("--extract", :copy in permissions),
      yes_no_arg("--annotate", :annotate in permissions),
      yes_no_arg("--form", :fill_forms in permissions),
      yes_no_arg("--assemble", :assemble in permissions)
    ]
  end

  @spec print_arg([Rendro.Protect.permission()]) :: String.t()
  defp print_arg(permissions) do
    if :print in permissions, do: "--print=full", else: "--print=none"
  end

  @spec modify_arg([Rendro.Protect.permission()]) :: String.t()
  defp modify_arg(permissions) do
    if :modify in permissions, do: "--modify=all", else: "--modify=none"
  end

  @spec yes_no_arg(String.t(), boolean()) :: String.t()
  defp yes_no_arg(flag, true), do: "#{flag}=y"
  defp yes_no_arg(flag, false), do: "#{flag}=n"
end

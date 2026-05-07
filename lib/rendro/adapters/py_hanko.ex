defmodule Rendro.Adapters.PyHanko do
  @moduledoc """
  Optional runtime adapter for pyHanko-based PDF signing.

  pyHanko is an external executable, not a Hex dependency. Rendro keeps it
  behind an artifact-first boundary so the core rendering pipeline stays pure
  Elixir and signing credentials stay adapter-local.
  """

  @behaviour Rendro.Sign.Adapter

  @type sign_opts :: %{
          required(:field) => String.t(),
          required(:adapter_opts) => keyword() | map(),
          optional(atom()) => term()
        }

  @impl true
  def prepare(%Rendro.Artifact{} = artifact, _opts) do
    {:ok, artifact.binary, %{}}
  end

  @impl true
  @spec sign(Rendro.Artifact.t(), sign_opts()) :: {:ok, binary(), map()} | {:error, term()}
  def sign(%Rendro.Artifact{} = artifact, opts) when is_map(opts) do
    with {:ok, executable} <- find_executable(),
         {:ok, normalized} <- normalize_adapter_opts(Map.fetch!(opts, :adapter_opts)),
         {:ok, tmp_dir} <- make_tmp_dir() do
      try do
        sign_with_tmp_dir(
          executable,
          tmp_dir,
          artifact.binary,
          Map.fetch!(opts, :field),
          normalized
        )
      after
        File.rm_rf(tmp_dir)
      end
    end
  end

  defp find_executable do
    finder = Application.get_env(:rendro, :pyhanko_executable_finder, &System.find_executable/1)

    case finder.("pyhanko") do
      nil -> {:error, {:missing_executable, "pyhanko"}}
      executable -> {:ok, executable}
    end
  end

  defp normalize_adapter_opts(opts) when is_list(opts) do
    normalize_adapter_opts(Enum.into(opts, %{}))
  end

  defp normalize_adapter_opts(opts) when is_map(opts) do
    with {:ok, key} <- fetch_binary_path(opts, :key),
         {:ok, cert} <- fetch_binary_path(opts, :cert),
         {:ok, passfile} <- fetch_optional_path(opts, :passfile),
         {:ok, chain} <- fetch_chain(opts),
         {:ok, reason} <- fetch_optional_string(opts, :reason) do
      {:ok, %{key: key, cert: cert, passfile: passfile, chain: chain, reason: reason}}
    end
  end

  defp normalize_adapter_opts(opts), do: {:error, {:invalid_adapter_opts, opts}}

  defp fetch_binary_path(opts, key) do
    case Map.fetch(opts, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_adapter_option, key, value}}
      :error -> {:error, {:missing_required_adapter_option, key}}
    end
  end

  defp fetch_optional_path(opts, key) do
    case Map.get(opts, key) do
      nil -> {:ok, nil}
      value when is_binary(value) and value != "" -> {:ok, value}
      value -> {:error, {:invalid_adapter_option, key, value}}
    end
  end

  defp fetch_optional_string(opts, key) do
    case Map.get(opts, key) do
      nil ->
        {:ok, nil}

      value when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, {:invalid_adapter_option, key, value}}
        else
          {:ok, value}
        end

      value ->
        {:error, {:invalid_adapter_option, key, value}}
    end
  end

  defp fetch_chain(opts) do
    case Map.get(opts, :chain, []) do
      values when is_list(values) ->
        if Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          {:ok, values}
        else
          {:error, {:invalid_adapter_option, :chain, values}}
        end

      value ->
        {:error, {:invalid_adapter_option, :chain, value}}
    end
  end

  defp sign_with_tmp_dir(executable, tmp_dir, binary, field, adapter_opts) do
    with {:ok, input_path, output_path} <- write_input_paths(tmp_dir, binary),
         {:ok, signed_binary} <-
           run_pyhanko(executable, input_path, output_path, field, adapter_opts) do
      {:ok, signed_binary,
       %{
         tool: :pyhanko,
         credential_source: :pemder,
         chain_count: length(adapter_opts.chain),
         passphrase_supplied: not is_nil(adapter_opts.passfile)
       }}
    end
  end

  defp run_pyhanko(executable, input_path, output_path, field, opts) do
    args =
      [
        "sign",
        "addsig",
        "--field",
        field
      ] ++
        reason_args(opts.reason) ++
        [
          "pemder",
          "--key",
          opts.key,
          "--cert",
          opts.cert
        ] ++ chain_args(opts.chain) ++ passfile_args(opts.passfile) ++ [input_path, output_path]

    case run_command(executable, args) do
      {:error, _reason} = error ->
        error

      {_output, 0} ->
        File.read(output_path)

      {_output, exit_code} ->
        {:error, {:pyhanko_failed, exit_code}}
    end
  end

  defp run_command(executable, args) do
    runner = Application.get_env(:rendro, :pyhanko_command_runner, &System.cmd/3)

    try do
      runner.(executable, args, stderr_to_stdout: true)
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp reason_args(nil), do: []
  defp reason_args(reason), do: ["--reason", reason]

  defp chain_args(paths), do: Enum.flat_map(paths, &["--chain", &1])
  defp passfile_args(nil), do: []
  defp passfile_args(path), do: ["--passfile", path]

  defp write_input_paths(tmp_dir, binary) do
    input_path = Path.join(tmp_dir, "input.pdf")
    output_path = Path.join(tmp_dir, "output.pdf")

    case write_private_file(input_path, binary) do
      :ok -> {:ok, input_path, output_path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_private_file(path, contents) do
    File.rm(path)

    with :ok <- File.write(path, contents, [:write, :exclusive, :binary]),
         :ok <- File.chmod(path, 0o600) do
      :ok
    end
  end

  defp make_tmp_dir do
    path =
      Path.join(
        System.tmp_dir!(),
        "rendro-sign-#{System.unique_integer([:positive, :monotonic])}"
      )

    with :ok <- File.mkdir_p(path),
         :ok <- File.chmod(path, 0o700) do
      {:ok, path}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end

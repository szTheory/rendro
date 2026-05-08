defmodule Rendro.Adapters.PyHanko do
  @moduledoc """
  Optional runtime adapter for pyHanko-based PDF signing.

  pyHanko is an external executable, not a Hex dependency. Rendro keeps it
  behind an artifact-first boundary so the core rendering pipeline stays pure
  Elixir and signing credentials stay adapter-local.
  """

  @behaviour Rendro.Sign.Adapter

  @validation_helper_path Path.expand("../../../priv/support/pyhanko_validate.py", __DIR__)

  @type sign_opts :: %{
          required(:field) => String.t(),
          required(:adapter_opts) => keyword() | map(),
          optional(atom()) => term()
        }

  @type augment_opts :: %{
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
    with {:ok, executable} <- find_executable("pyhanko"),
         {:ok, normalized} <- normalize_sign_adapter_opts(Map.fetch!(opts, :adapter_opts)),
         {:ok, tmp_dir} <- make_tmp_dir("rendro-sign") do
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

  @impl true
  @spec augment(Rendro.Artifact.t(), augment_opts()) :: {:ok, binary(), map()} | {:error, term()}
  def augment(%Rendro.Artifact{} = artifact, opts) when is_map(opts) do
    with {:ok, executable} <- find_executable("pyhanko"),
         {:ok, field} <- fetch_signed_field(artifact),
         {:ok, normalized} <- normalize_augment_adapter_opts(Map.fetch!(opts, :adapter_opts)),
         {:ok, tmp_dir} <- make_tmp_dir("rendro-augment") do
      try do
        augment_with_tmp_dir(executable, tmp_dir, artifact.binary, field, normalized)
      after
        File.rm_rf(tmp_dir)
      end
    end
  end

  @spec validate(Path.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def validate(file_path, opts \\ [])

  def validate(file_path, opts) when is_binary(file_path) and is_list(opts) do
    with {:ok, _pyhanko} <- find_executable("pyhanko"),
         {:ok, python} <- find_python_executable(),
         {:ok, helper_path} <- validation_helper_path(),
         {:ok, output} <- run_validation_helper(python, helper_path, file_path),
         {:ok, decoded} <- decode_validation_output(output) do
      normalize_validation_output(decoded, opts)
    end
  end

  def validate(_file_path, _opts), do: {:error, {:invalid_pdf, :tool_failure}}

  defp find_executable(name) do
    finder = Application.get_env(:rendro, :pyhanko_executable_finder, &System.find_executable/1)

    case finder.(name) do
      nil -> {:error, {:missing_executable, name}}
      executable -> {:ok, executable}
    end
  end

  defp find_python_executable do
    case find_executable("python3") do
      {:ok, executable} ->
        {:ok, executable}

      {:error, {:missing_executable, "python3"}} ->
        find_executable("python")

      {:error, _reason} = error ->
        error
    end
  end

  defp validation_helper_path do
    if File.exists?(@validation_helper_path) do
      {:ok, @validation_helper_path}
    else
      {:error, {:invalid_pdf, :tool_failure}}
    end
  end

  defp normalize_sign_adapter_opts(opts) when is_list(opts) do
    normalize_sign_adapter_opts(Enum.into(opts, %{}))
  end

  defp normalize_sign_adapter_opts(opts) when is_map(opts) do
    with {:ok, key} <- fetch_binary_path(opts, :key),
         {:ok, cert} <- fetch_binary_path(opts, :cert),
         {:ok, passfile} <- fetch_optional_path(opts, :passfile),
         {:ok, chain} <- fetch_string_list(opts, :chain, []),
         {:ok, reason} <- fetch_optional_string(opts, :reason) do
      {:ok, %{key: key, cert: cert, passfile: passfile, chain: chain, reason: reason}}
    end
  end

  defp normalize_sign_adapter_opts(opts), do: {:error, {:invalid_adapter_opts, opts}}

  defp normalize_augment_adapter_opts(opts) when is_list(opts) do
    normalize_augment_adapter_opts(Enum.into(opts, %{}))
  end

  defp normalize_augment_adapter_opts(opts) when is_map(opts) do
    with {:ok, tsa_url} <- fetch_required_string(opts, :tsa_url),
         {:ok, trust_roots} <- fetch_required_string_list(opts, :trust_roots),
         {:ok, other_certs} <- fetch_string_list(opts, :other_certs, []) do
      {:ok,
       %{
         tsa_url: tsa_url,
         trust_roots: trust_roots,
         other_certs: other_certs
       }}
    end
  end

  defp normalize_augment_adapter_opts(opts), do: {:error, {:invalid_adapter_opts, opts}}

  defp fetch_signed_field(%Rendro.Artifact{metadata: metadata}) when is_map(metadata) do
    case get_in(metadata, [:signing, :field]) do
      field when is_binary(field) and field != "" -> {:ok, field}
      _ -> {:error, :missing_signed_field_metadata}
    end
  end

  defp fetch_signed_field(_artifact), do: {:error, :missing_signed_field_metadata}

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

  defp fetch_required_string(opts, key) do
    case fetch_optional_string(opts, key) do
      {:ok, nil} -> {:error, {:missing_required_adapter_option, key}}
      result -> result
    end
  end

  defp fetch_string_list(opts, key, default) do
    case Map.get(opts, key, default) do
      values when is_list(values) ->
        if Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          {:ok, values}
        else
          {:error, {:invalid_adapter_option, key, values}}
        end

      value ->
        {:error, {:invalid_adapter_option, key, value}}
    end
  end

  defp fetch_required_string_list(opts, key) do
    case Map.fetch(opts, key) do
      :error ->
        {:error, {:missing_required_adapter_option, key}}

      {:ok, values} when is_list(values) and values != [] ->
        if Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          {:ok, values}
        else
          {:error, {:invalid_adapter_option, key, values}}
        end

      {:ok, []} ->
        {:error, {:missing_required_adapter_option, key}}

      {:ok, value} ->
        {:error, {:invalid_adapter_option, key, value}}
    end
  end

  defp sign_with_tmp_dir(executable, tmp_dir, binary, field, adapter_opts) do
    with {:ok, input_path, output_path} <- write_input_paths(tmp_dir, binary),
         {:ok, signed_binary} <-
           run_pyhanko_sign(executable, input_path, output_path, field, adapter_opts) do
      {:ok, signed_binary,
       %{
         tool: :pyhanko,
         credential_source: :pemder,
         chain_count: length(adapter_opts.chain),
         passphrase_supplied: not is_nil(adapter_opts.passfile)
       }}
    end
  end

  defp augment_with_tmp_dir(executable, tmp_dir, binary, field, adapter_opts) do
    with {:ok, input_path, output_path} <- write_input_paths(tmp_dir, binary),
         {:ok, augmented_binary} <-
           run_pyhanko_augment(executable, input_path, output_path, field, adapter_opts) do
      {:ok, augmented_binary,
       %{
         tool: :pyhanko,
         tool_family: :pyhanko,
         evidence_profile: :timestamp_with_embedded_validation,
         timestamp: :present,
         revocation: :embedded,
         compliance_evidence: :narrow_supported_path,
         timestamp_authority: :configured,
         revocation_sources: [:ocsp, :crl]
       }}
    end
  end

  defp run_pyhanko_sign(executable, input_path, output_path, field, opts) do
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

    case run_command(executable, args, stderr_to_stdout: true) do
      {:error, _reason} = error ->
        error

      {_output, 0} ->
        File.read(output_path)

      {_output, exit_code} ->
        {:error, {:pyhanko_failed, exit_code}}
    end
  end

  defp run_pyhanko_augment(executable, input_path, output_path, field, opts) do
    args =
      [
        "sign",
        "ltvfix",
        "--field",
        field,
        "--timestamp-url",
        opts.tsa_url
      ] ++
        trust_args(opts.trust_roots) ++
        other_cert_args(opts.other_certs) ++
        [input_path, output_path]

    case run_command(executable, args, stderr_to_stdout: true) do
      {:error, _reason} = error ->
        error

      {_output, 0} ->
        File.read(output_path)

      {_output, exit_code} ->
        {:error, {:pyhanko_failed, exit_code}}
    end
  end

  defp run_command(executable, args, options) do
    runner = Application.get_env(:rendro, :pyhanko_command_runner, &System.cmd/3)

    try do
      runner.(executable, args, options)
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp run_validation_helper(python, helper_path, file_path) do
    case run_command(python, [helper_path, file_path], cd: File.cwd!(), stderr_to_stdout: true) do
      {:error, _reason} = error ->
        error

      {output, 0} ->
        {:ok, output}

      {_output, _exit_code} ->
        {:error, {:invalid_pdf, :tool_failure}}
    end
  end

  defp decode_validation_output(output) do
    case Jason.decode(output, keys: :atoms) do
      {:ok, %{} = decoded} -> {:ok, decoded}
      {:ok, _decoded} -> {:error, {:invalid_pdf, :tool_failure}}
      {:error, _reason} -> {:error, {:invalid_pdf, :tool_failure}}
    end
  end

  defp normalize_validation_output(%{signatures: signatures}, opts) when is_list(signatures) do
    {:ok,
     %{
       signatures: Enum.map(signatures, &normalize_validation_signature(&1, opts))
     }}
  end

  defp normalize_validation_output(_decoded, _opts), do: {:error, {:invalid_pdf, :no_signatures}}

  defp normalize_validation_signature(signature, opts) when is_map(signature) do
    skip_trust? = Keyword.get(opts, :skip_certificate_validation, true)

    %{
      field: map_string_or_nil(signature, :field),
      integrity: map_status(signature, :integrity, :unknown),
      trust:
        if(skip_trust?,
          do: :skipped,
          else: map_status(signature, :trust, :unknown)
        ),
      timestamp: map_status(signature, :timestamp, :unknown),
      revocation: map_status(signature, :revocation, :unknown),
      compliance: normalize_compliance(Map.get(signature, :compliance)),
      total_document_signed: Map.get(signature, :total_document_signed, false)
    }
  end

  defp normalize_validation_signature(_signature, opts) do
    normalize_validation_signature(%{}, opts)
  end

  defp normalize_compliance(%{} = compliance) do
    proofs = Map.get(compliance, :proofs, %{})

    %{
      scope: :embedded_validation_evidence,
      level: map_status(compliance, :level, :not_assessed),
      proofs: %{
        document_timestamp: Map.get(proofs, :document_timestamp, false),
        revocation_info: Map.get(proofs, :revocation_info, false)
      },
      gaps: Map.get(compliance, :gaps, [])
    }
  end

  defp normalize_compliance(_compliance) do
    %{
      scope: :embedded_validation_evidence,
      level: :not_assessed,
      proofs: %{document_timestamp: false, revocation_info: false},
      gaps: []
    }
  end

  defp map_status(map, key, default) do
    case Map.get(map, key, default) do
      value when is_atom(value) -> value
      value when is_binary(value) -> status_from_string(value, default)
      _ -> default
    end
  end

  defp map_string_or_nil(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp status_from_string(value, default) do
    case value do
      "valid" -> :valid
      "invalid" -> :invalid
      "unknown" -> :unknown
      "skipped" -> :skipped
      "untrusted" -> :untrusted
      "present" -> :present
      "missing" -> :missing
      "embedded" -> :embedded
      "incomplete" -> :incomplete
      "not_assessed" -> :not_assessed
      _ -> default
    end
  end

  defp reason_args(nil), do: []
  defp reason_args(reason), do: ["--reason", reason]

  defp chain_args(paths), do: Enum.flat_map(paths, &["--chain", &1])
  defp trust_args(paths), do: Enum.flat_map(paths, &["--trust", &1])
  defp other_cert_args(paths), do: Enum.flat_map(paths, &["--other-cert", &1])
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

  defp make_tmp_dir(prefix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
      )

    with :ok <- File.mkdir_p(path),
         :ok <- File.chmod(path, 0o700) do
      {:ok, path}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end

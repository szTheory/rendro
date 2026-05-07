defmodule Rendro.Sign do
  @moduledoc """
  Artifact-first signing boundary.

  This surface supports two distinct signing seams over rendered artifacts:

  - `prepare/2` patches deterministic signature placeholders for lower-level
    external workflows.
  - `sign/2` signs the original unsigned rendered artifact through a narrow
    optional adapter boundary.
  """

  alias Rendro.{Artifact, Error}

  @default_adapter Rendro.Adapters.PyHanko
  @default_validation_adapter Rendro.Adapters.Pdfsig
  @max_reserved_bytes 1_048_576

  @type prepare_option ::
          {:field, String.t()}
          | {:reserved_bytes, pos_integer()}
          | {:adapter, module()}

  @type prepare_options :: [prepare_option()]

  @type sign_option ::
          {:field, String.t()}
          | {:adapter, module()}
          | {:adapter_opts, keyword() | map()}

  @type sign_options :: [sign_option()]

  @type validate_option :: {:adapter, module()}

  @type validate_options :: [validate_option()]

  @spec prepare(Artifact.t(), prepare_options()) :: {:ok, Artifact.t()} | {:error, Error.t()}
  def prepare(%Artifact{} = artifact, opts) when is_list(opts) do
    with {:ok, normalized} <- normalize_prepare_opts(opts),
         {:ok, prepared_binary, manifest} <- prepare_binary(artifact.binary, normalized),
         {:ok, prepared_artifact} <-
           maybe_run_prepare_adapter(artifact, prepared_binary, manifest, normalized) do
      {:ok, prepared_artifact}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.from_stage(
           :prepare,
           {:adapter_failure, normalized_prepare_adapter(opts), reason},
           %{details: redact_prepare_opts(opts)}
         )}
    end
  end

  def prepare(%Artifact{}, opts) do
    {:error, Error.from_stage(:prepare, {:invalid_option, :options, opts}, %{})}
  end

  @spec sign(Artifact.t(), sign_options()) :: {:ok, Artifact.t()} | {:error, Error.t()}
  def sign(%Artifact{} = artifact, opts) when is_list(opts) do
    with {:ok, normalized} <- normalize_sign_opts(opts),
         :ok <- ensure_signable_artifact(artifact, normalized.field),
         {:ok, signed_binary, adapter_metadata} <- normalized.adapter.sign(artifact, normalized) do
      metadata_updates = %{
        deterministic: false,
        signing: %{
          status: :signed,
          field: normalized.field,
          adapter: normalized.adapter
        },
        signing_adapter: sanitize_signing_adapter_metadata(adapter_metadata)
      }

      {:ok, Artifact.wrap(signed_binary, artifact, metadata_updates)}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.from_stage(
           :sign,
           reason,
           %{
             details:
               Map.put(
                 redact_sign_opts(opts),
                 :adapter,
                 normalized_sign_adapter(opts)
               )
           }
         )}
    end
  end

  def sign(%Artifact{}, opts) do
    {:error, Error.from_stage(:sign, {:invalid_option, :options, opts}, %{})}
  end

  @spec validate(Artifact.t(), validate_options()) :: {:ok, map()} | {:error, Error.t()}
  def validate(artifact, opts \\ [])

  def validate(%Artifact{} = artifact, opts) when is_list(opts) do
    validate_artifact(artifact, opts, skip_certificate_validation: true)
  end

  def validate(%Artifact{}, opts) do
    {:error, Error.from_stage(:validate, {:invalid_option, :options, opts}, %{})}
  end

  @spec validate_trust(Artifact.t(), validate_options()) :: {:ok, map()} | {:error, Error.t()}
  def validate_trust(artifact, opts \\ [])

  def validate_trust(%Artifact{} = artifact, opts) when is_list(opts) do
    validate_artifact(artifact, opts, skip_certificate_validation: false)
  end

  def validate_trust(%Artifact{}, opts) do
    {:error, Error.from_stage(:validate, {:invalid_option, :options, opts}, %{})}
  end

  @spec render_signed(Rendro.Document.t(), Rendro.render_options(), sign_options()) ::
          {:ok, Artifact.t()} | {:error, Error.t()}
  def render_signed(%Rendro.Document{} = doc, render_opts \\ [], sign_opts)
      when is_list(render_opts) and is_list(sign_opts) do
    Rendro.render_signed(doc, render_opts, sign_opts)
  end

  @spec redact_opts(prepare_options() | map()) :: map()
  def redact_opts(opts), do: redact_prepare_opts(opts)

  @spec redact_prepare_opts(prepare_options() | map()) :: map()
  def redact_prepare_opts(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    |> redact_prepare_opts()
  end

  def redact_prepare_opts(opts) when is_map(opts) do
    %{
      adapter: Map.get(opts, :adapter),
      field: Map.get(opts, :field),
      reserved_bytes: Map.get(opts, :reserved_bytes)
    }
  end

  @spec redact_sign_opts(sign_options() | map()) :: map()
  def redact_sign_opts(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    |> redact_sign_opts()
  end

  def redact_sign_opts(opts) when is_map(opts) do
    adapter_opts =
      opts
      |> Map.get(:adapter_opts, %{})
      |> case do
        values when is_list(values) -> Enum.into(values, %{})
        values when is_map(values) -> values
        _ -> %{}
      end

    %{
      adapter: Map.get(opts, :adapter, @default_adapter),
      field: Map.get(opts, :field),
      adapter_opt_keys: adapter_opts |> Map.keys() |> Enum.sort()
    }
  end

  defp normalize_prepare_opts(opts) do
    with {:ok, field} <- fetch_field(opts, :prepare),
         {:ok, reserved_bytes} <- fetch_reserved_bytes(opts),
         {:ok, adapter} <- fetch_prepare_adapter(opts) do
      {:ok, %{field: field, reserved_bytes: reserved_bytes, adapter: adapter}}
    end
  end

  defp normalize_sign_opts(opts) do
    with {:ok, field} <- fetch_field(opts, :sign),
         {:ok, adapter} <- fetch_sign_adapter(opts),
         {:ok, adapter_opts} <- fetch_sign_adapter_opts(opts) do
      {:ok, %{field: field, adapter: adapter, adapter_opts: adapter_opts}}
    end
  end

  defp fetch_field(opts, stage) do
    case Keyword.fetch(opts, :field) do
      :error ->
        {:error, Error.from_stage(stage, {:missing_required_option, :field}, %{})}

      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, Error.from_stage(stage, {:invalid_option, :field, :empty}, %{})}
        else
          {:ok, value}
        end

      {:ok, value} ->
        {:error, Error.from_stage(stage, {:invalid_option, :field, value}, %{})}
    end
  end

  defp fetch_reserved_bytes(opts) do
    case Keyword.fetch(opts, :reserved_bytes) do
      :error ->
        {:error, Error.from_stage(:prepare, {:missing_required_option, :reserved_bytes}, %{})}

      {:ok, value} when is_integer(value) and value > 0 and value <= @max_reserved_bytes ->
        {:ok, value}

      {:ok, value} when is_integer(value) and value > @max_reserved_bytes ->
        {:error, Error.from_stage(:prepare, {:invalid_option, :reserved_bytes, :too_large}, %{})}

      {:ok, value} ->
        {:error, Error.from_stage(:prepare, {:invalid_option, :reserved_bytes, value}, %{})}
    end
  end

  defp fetch_prepare_adapter(opts) do
    case Keyword.get(opts, :adapter) do
      nil ->
        {:ok, nil}

      adapter when not is_atom(adapter) ->
        {:error, Error.from_stage(:prepare, {:invalid_option, :adapter, adapter}, %{})}

      adapter ->
        cond do
          not Code.ensure_loaded?(adapter) ->
            {:error, Error.from_stage(:prepare, {:invalid_option, :adapter, adapter}, %{})}

          not function_exported?(adapter, :prepare, 2) ->
            {:error, Error.from_stage(:prepare, {:invalid_option, :adapter, adapter}, %{})}

          true ->
            {:ok, adapter}
        end
    end
  end

  defp fetch_sign_adapter(opts) do
    adapter = Keyword.get(opts, :adapter, @default_adapter)

    cond do
      not is_atom(adapter) ->
        {:error, Error.from_stage(:sign, {:invalid_option, :adapter, adapter}, %{})}

      not Code.ensure_loaded?(adapter) ->
        {:error, Error.from_stage(:sign, {:invalid_option, :adapter, adapter}, %{})}

      not function_exported?(adapter, :sign, 2) ->
        {:error, Error.from_stage(:sign, {:invalid_option, :adapter, adapter}, %{})}

      true ->
        {:ok, adapter}
    end
  end

  defp fetch_sign_adapter_opts(opts) do
    case Keyword.get(opts, :adapter_opts, []) do
      values when is_list(values) or is_map(values) ->
        {:ok, values}

      value ->
        {:error, Error.from_stage(:sign, {:invalid_option, :adapter_opts, value}, %{})}
    end
  end

  defp validate_artifact(artifact, opts, adapter_opts) do
    with {:ok, normalized} <- normalize_validate_opts(opts),
         {:ok, tmp_dir} <- make_validation_tmp_dir() do
      try do
        with {:ok, artifact_path} <- write_validation_input(tmp_dir, artifact.binary),
             {:ok, result} <- normalized.adapter.validate(artifact_path, adapter_opts) do
          {:ok, sanitize_validation_result(result, normalized.adapter, adapter_opts)}
        else
          {:error, %Error{} = error} ->
            {:error, error}

          {:error, reason} ->
            {:error,
             Error.from_stage(
               :validate,
               reason,
               %{details: %{adapter: normalized.adapter}}
             )}
        end
      after
        File.rm_rf(tmp_dir)
      end
    else
      {:error, reason} ->
        {:error,
         Error.from_stage(
           :validate,
           reason,
           %{details: %{adapter: normalized_validate_adapter(opts)}}
         )}
    end
  end

  defp normalize_validate_opts(opts) do
    with {:ok, adapter} <- fetch_validate_adapter(opts) do
      {:ok, %{adapter: adapter}}
    end
  end

  defp fetch_validate_adapter(opts) do
    adapter = Keyword.get(opts, :adapter, @default_validation_adapter)

    cond do
      not is_atom(adapter) ->
        {:error, Error.from_stage(:validate, {:invalid_option, :adapter, adapter}, %{})}

      not Code.ensure_loaded?(adapter) ->
        {:error, Error.from_stage(:validate, {:invalid_option, :adapter, adapter}, %{})}

      not function_exported?(adapter, :validate, 2) ->
        {:error, Error.from_stage(:validate, {:invalid_option, :adapter, adapter}, %{})}

      true ->
        {:ok, adapter}
    end
  end

  defp prepare_binary(binary, %{field: field, reserved_bytes: reserved_bytes}) do
    with :ok <- ensure_not_prepared(binary),
         {:ok, object_range} <- locate_signature_widget(binary, field) do
      {patch, manifest_offsets} = signature_patch(reserved_bytes)
      insertion_point = object_range.offset + object_range.insert_at

      prepared_binary =
        [
          binary_part(binary, 0, insertion_point),
          patch,
          binary_part(binary, insertion_point, byte_size(binary) - insertion_point)
        ]
        |> IO.iodata_to_binary()

      manifest = %{
        status: :prepared,
        field: field,
        reserved_bytes: reserved_bytes,
        byte_range_placeholder: %{
          offset: insertion_point + manifest_offsets.byte_range_offset,
          length: manifest_offsets.byte_range_length
        },
        contents_placeholder: %{
          offset: insertion_point + manifest_offsets.contents_offset,
          length: manifest_offsets.contents_length
        }
      }

      {:ok, prepared_binary, manifest}
    end
  end

  defp ensure_not_prepared(binary) do
    if String.contains?(binary, "/ByteRange [") or String.contains?(binary, "/Contents <") do
      {:error, Error.from_stage(:prepare, :already_prepared, %{})}
    else
      :ok
    end
  end

  defp locate_signature_widget(binary, field) do
    escaped_field = Regex.escape(escape_pdf_string(field))

    regex =
      Regex.compile!(
        "\\d+ 0 obj\\n<<\\n(?:(?!\\n>>\\nendobj).)*?/Type /Annot\\n/Subtype /Widget\\n/FT /Sig\\n(?:(?!\\n>>\\nendobj).)*?/T \\(" <>
          escaped_field <>
          "\\)\\n(?:(?!\\n>>\\nendobj).)*?\\n>>\\nendobj",
        [:dotall]
      )

    case Regex.run(regex, binary, return: :index) do
      [{offset, length}] ->
        object_binary = binary_part(binary, offset, length)

        case :binary.match(object_binary, "\n>>\nendobj") do
          {insert_at, _length} ->
            {:ok, %{offset: offset, length: length, insert_at: insert_at}}

          :nomatch ->
            {:error, Error.from_stage(:prepare, {:field_not_preparable, field}, %{})}
        end

      nil ->
        {:error, Error.from_stage(:prepare, {:field_not_preparable, field}, %{})}
    end
  end

  defp signature_patch(reserved_bytes) do
    byte_range = "/ByteRange [0000000000 0000000000 0000000000 0000000000]"
    contents_prefix = "/Contents <"
    contents_hex = String.duplicate("0", reserved_bytes * 2)

    patch =
      [
        "\n/V <<\n",
        "/Type /Sig\n",
        byte_range,
        "\n",
        contents_prefix,
        contents_hex,
        ">\n",
        ">>"
      ]
      |> IO.iodata_to_binary()

    {byte_range_offset, byte_range_length} = :binary.match(patch, byte_range)
    {contents_prefix_offset, _length} = :binary.match(patch, contents_prefix)

    {patch,
     %{
       byte_range_offset: byte_range_offset,
       byte_range_length: byte_range_length,
       contents_offset: contents_prefix_offset + byte_size(contents_prefix),
       contents_length: byte_size(contents_hex)
     }}
  end

  defp maybe_run_prepare_adapter(artifact, prepared_binary, manifest, %{adapter: nil}) do
    {:ok, Artifact.wrap(prepared_binary, artifact, %{signing_preparation: manifest})}
  end

  defp maybe_run_prepare_adapter(
         artifact,
         prepared_binary,
         manifest,
         %{adapter: adapter} = normalized
       ) do
    prepared_artifact = Artifact.wrap(prepared_binary, artifact, %{signing_preparation: manifest})

    with {:ok, adapter_binary, adapter_metadata} <- adapter.prepare(prepared_artifact, normalized),
         true <- is_map(adapter_metadata) do
      metadata_updates = %{
        signing_preparation: manifest,
        signing_preparation_adapter: adapter_metadata
      }

      {:ok, Artifact.wrap(adapter_binary, prepared_artifact, metadata_updates)}
    else
      false ->
        {:error, :invalid_adapter_metadata}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_signable_artifact(%Artifact{metadata: %{signing: %{status: :signed}}}, _field) do
    {:error, Error.from_stage(:sign, :already_signed, %{})}
  end

  defp ensure_signable_artifact(
         %Artifact{metadata: %{signing_preparation: %{status: :prepared}}},
         _field
       ) do
    {:error, Error.from_stage(:sign, :prepared_artifact_not_signable, %{})}
  end

  defp ensure_signable_artifact(%Artifact{binary: binary}, field) do
    case locate_signature_widget(binary, field) do
      {:ok, _object_range} -> :ok
      {:error, _reason} -> {:error, Error.from_stage(:sign, {:field_not_preparable, field}, %{})}
    end
  end

  defp sanitize_signing_adapter_metadata(metadata) when is_map(metadata) do
    metadata
    |> Map.take([:tool, :tool_family, :credential_source, :chain_count, :passphrase_supplied])
  end

  defp sanitize_signing_adapter_metadata(_metadata), do: %{}

  defp sanitize_validation_result(%{signatures: signatures}, adapter, adapter_opts)
       when is_list(signatures) do
    %{
      adapter: adapter,
      signatures: Enum.map(signatures, &sanitize_validation_signature(&1, adapter_opts))
    }
  end

  defp sanitize_validation_result(_result, adapter, adapter_opts) do
    %{
      adapter: adapter,
      signatures: [sanitize_validation_signature(%{}, adapter_opts)]
    }
  end

  defp sanitize_validation_signature(signature, adapter_opts) when is_map(signature) do
    %{
      field: Map.get(signature, :field),
      integrity:
        Map.get(signature, :integrity) ||
          Map.get(signature, :signature_validation) ||
          :unknown,
      trust: normalize_validation_trust(signature, adapter_opts),
      total_document_signed: Map.get(signature, :total_document_signed, false)
    }
  end

  defp sanitize_validation_signature(_signature, adapter_opts) do
    %{
      field: nil,
      integrity: :unknown,
      trust: normalize_validation_trust(%{}, adapter_opts),
      total_document_signed: false
    }
  end

  defp normalize_validation_trust(signature, adapter_opts) do
    if Keyword.get(adapter_opts, :skip_certificate_validation, true) do
      :skipped
    else
      Map.get(signature, :trust) || Map.get(signature, :certificate_validation) || :unknown
    end
  end

  defp make_validation_tmp_dir do
    path =
      Path.join(
        System.tmp_dir!(),
        "rendro-validate-#{System.unique_integer([:positive, :monotonic])}"
      )

    with :ok <- File.mkdir_p(path),
         :ok <- File.chmod(path, 0o700) do
      {:ok, path}
    else
      {:error, _reason} -> {:error, :temp_dir_unavailable}
    end
  end

  defp write_validation_input(tmp_dir, binary) do
    path = Path.join(tmp_dir, "artifact.pdf")

    File.rm(path)

    with :ok <- File.write(path, binary, [:write, :exclusive, :binary]),
         :ok <- File.chmod(path, 0o600) do
      {:ok, path}
    else
      {:error, _reason} -> {:error, :artifact_io_failed}
    end
  end

  defp normalized_prepare_adapter(opts) when is_list(opts), do: Keyword.get(opts, :adapter)
  defp normalized_prepare_adapter(_opts), do: nil

  defp normalized_sign_adapter(opts) when is_list(opts),
    do: Keyword.get(opts, :adapter, @default_adapter)

  defp normalized_validate_adapter(opts) when is_list(opts),
    do: Keyword.get(opts, :adapter, @default_validation_adapter)

  defp normalized_validate_adapter(_opts), do: @default_validation_adapter

  defp escape_pdf_string(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
    |> String.replace("\r", "\\r")
    |> String.replace("\n", "\\n")
  end
end

defmodule Rendro.Sign do
  @moduledoc """
  Artifact-first signing preparation boundary.

  This surface prepares a rendered `%Rendro.Artifact{}` for an external signing
  workflow without changing Rendro's render pipeline or assuming ownership of
  keys, certificates, trust policy, or detached-signature execution.
  """

  alias Rendro.{Artifact, Error}

  @max_reserved_bytes 1_048_576

  @type option ::
          {:field, String.t()}
          | {:reserved_bytes, pos_integer()}
          | {:adapter, module()}

  @type options :: [option()]

  @spec prepare(Artifact.t(), options()) :: {:ok, Artifact.t()} | {:error, Error.t()}
  def prepare(%Artifact{} = artifact, opts) when is_list(opts) do
    with {:ok, normalized} <- normalize_opts(opts),
         {:ok, prepared_binary, manifest} <- prepare_binary(artifact.binary, normalized),
         {:ok, prepared_artifact} <- maybe_run_adapter(artifact, prepared_binary, manifest, normalized) do
      {:ok, prepared_artifact}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.from_stage(
           :prepare,
           {:adapter_failure, normalized_adapter(opts), reason},
           %{details: redact_opts(opts)}
         )}
    end
  end

  def prepare(%Artifact{}, opts) do
    {:error, Error.from_stage(:prepare, {:invalid_option, :options, opts}, %{})}
  end

  @spec redact_opts(options() | map()) :: map()
  def redact_opts(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    |> redact_opts()
  end

  def redact_opts(opts) when is_map(opts) do
    %{
      adapter: Map.get(opts, :adapter),
      field: Map.get(opts, :field),
      reserved_bytes: Map.get(opts, :reserved_bytes)
    }
  end

  defp normalize_opts(opts) do
    with {:ok, field} <- fetch_field(opts),
         {:ok, reserved_bytes} <- fetch_reserved_bytes(opts),
         {:ok, adapter} <- fetch_adapter(opts) do
      {:ok, %{field: field, reserved_bytes: reserved_bytes, adapter: adapter}}
    end
  end

  defp fetch_field(opts) do
    case Keyword.fetch(opts, :field) do
      :error ->
        {:error, Error.from_stage(:prepare, {:missing_required_option, :field}, %{})}

      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, Error.from_stage(:prepare, {:invalid_option, :field, :empty}, %{})}
        else
          {:ok, value}
        end

      {:ok, value} ->
        {:error, Error.from_stage(:prepare, {:invalid_option, :field, value}, %{})}
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

  defp fetch_adapter(opts) do
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

  defp prepare_binary(binary, %{field: field, reserved_bytes: reserved_bytes}) do
    with :ok <- ensure_not_prepared(binary),
         {:ok, object_range} <- locate_signature_widget(binary, field) do
      {patch, manifest_offsets} = signature_patch(reserved_bytes)
      insertion_point = object_range.offset + object_range.insert_at

      prepared_binary = [
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
        "\\d+ 0 obj\\n<<\\n(?:(?!\\n>>\\nendobj).)*?/Type /Annot\\n/Subtype /Widget\\n/FT /Sig\\n(?:(?!\\n>>\\nendobj).)*?/T \\("
          <> escaped_field <>
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

  defp maybe_run_adapter(artifact, prepared_binary, manifest, %{adapter: nil}) do
    {:ok, Artifact.wrap(prepared_binary, artifact, %{signing_preparation: manifest})}
  end

  defp maybe_run_adapter(artifact, prepared_binary, manifest, %{adapter: adapter} = normalized) do
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

  defp normalized_adapter(opts) when is_list(opts), do: Keyword.get(opts, :adapter)
  defp normalized_adapter(_opts), do: nil

  defp escape_pdf_string(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
    |> String.replace("\r", "\\r")
    |> String.replace("\n", "\\n")
  end
end

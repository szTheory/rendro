defmodule Rendro.Storage.Local do
  @moduledoc """
  A simple local filesystem storage adapter for Rendro artifacts.
  """
  @behaviour Rendro.Storage

  alias Rendro.Artifact

  @sidecar_extension ".metadata"

  @impl true
  def put(%Artifact{} = artifact, opts) do
    case Keyword.fetch(opts, :path) do
      {:ok, path} ->
        path |> Path.dirname() |> File.mkdir_p!()

        case File.write(path, artifact.binary) do
          :ok ->
            case persist_manifest(path, artifact.metadata) do
              :ok -> {:ok, path}
              {:error, reason} -> {:error, reason}
            end

          {:error, reason} -> {:error, reason}
        end

      :error ->
        {:error, :missing_path_option}
    end
  end

  @impl true
  def get(identifier, _opts) do
    case File.read(identifier) do
      {:ok, binary} ->
        {:ok,
         %Artifact{
           binary: binary,
           hash: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower),
           diagnostics: [],
           metadata: load_manifest(identifier)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def delete(identifier, _opts) do
    case File.rm(identifier) do
      :ok ->
        case File.rm(sidecar_path(identifier)) do
          :ok -> :ok
          {:error, :enoent} -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp persist_manifest(path, metadata) do
    manifest = manifest_metadata(metadata)

    if map_size(manifest) == 0 do
      :ok
    else
      File.write(sidecar_path(path), :erlang.term_to_binary(manifest))
    end
  end

  defp load_manifest(path) do
    case File.read(sidecar_path(path)) do
      {:ok, binary} ->
        decode_manifest(binary)

      {:error, :enoent} ->
        %{}

      {:error, _reason} ->
        %{}
    end
  end

  defp decode_manifest(binary) do
    case :erlang.binary_to_term(binary, [:safe]) do
      manifest when is_map(manifest) ->
        manifest

      _other ->
        %{}
    end
  rescue
    ArgumentError -> %{}
  end

  defp manifest_metadata(metadata) when is_map(metadata) do
    %{}
    |> maybe_put(:deterministic, Map.get(metadata, :deterministic))
    |> maybe_put(:protection, sanitize_protection(Map.get(metadata, :protection)))
  end

  defp manifest_metadata(_metadata), do: %{}

  defp sanitize_protection(protection) when is_map(protection) do
    %{}
    |> maybe_put(:algorithm, Map.get(protection, :algorithm))
    |> maybe_put(:advisory_permissions, sanitize_permissions(Map.get(protection, :advisory_permissions)))
    |> maybe_put(:has_open_password, Map.get(protection, :has_open_password))
    |> maybe_put(:has_owner_password, Map.get(protection, :has_owner_password))
  end

  defp sanitize_protection(_protection), do: nil

  defp sanitize_permissions(permissions) when is_list(permissions) do
    Enum.filter(permissions, &is_atom/1)
  end

  defp sanitize_permissions(_permissions), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, value) when value == %{}, do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp sidecar_path(path), do: path <> @sidecar_extension
end

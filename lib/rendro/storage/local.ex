defmodule Rendro.Storage.Local do
  @moduledoc """
  A simple local filesystem storage adapter for Rendro artifacts.
  """
  @behaviour Rendro.Storage

  @impl true
  def put(artifact, opts) do
    case Keyword.fetch(opts, :path) do
      {:ok, path} ->
        path |> Path.dirname() |> File.mkdir_p!()

        case File.write(path, artifact.binary) do
          :ok -> {:ok, path}
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
        # Here we only have the binary, so we reconstruct a minimal artifact.
        # Real implementations might also fetch a sidecar metadata JSON.
        {:ok,
         %Rendro.Artifact{
           binary: binary,
           hash: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower),
           diagnostics: [],
           metadata: %{}
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def delete(identifier, _opts) do
    File.rm(identifier)
  end
end

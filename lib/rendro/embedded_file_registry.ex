defmodule Rendro.EmbeddedFileRegistry do
  @moduledoc """
  Pure data registry for document-owned embedded-file registrations.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:files]
  defstruct files: %{}

  @type logical_name :: atom()
  @type source :: {:binary, binary()} | {:path, Path.t()}
  @type descriptor :: %{
          required(:logical_name) => logical_name(),
          required(:source_kind) => :binary | :path,
          required(:bytes) => binary(),
          required(:byte_size) => non_neg_integer(),
          required(:filename) => String.t(),
          required(:mime_type) => String.t(),
          optional(:description) => String.t(),
          optional(:created_at) => DateTime.t(),
          optional(:modified_at) => DateTime.t()
        }
  @type t :: %__MODULE__{files: %{optional(logical_name()) => descriptor()}}

  @spec new() :: t()
  def new, do: %__MODULE__{files: %{}}

  @doc """
  Registers an embedded file as owned bytes plus explicit authored metadata.
  """
  @spec register(t(), logical_name(), source(), keyword()) :: t()
  def register(%__MODULE__{} = registry, logical_name, source, metadata)
      when is_atom(logical_name) and is_list(metadata) do
    {source_kind, bytes} = normalize_source(source)

    descriptor =
      metadata
      |> Enum.into(%{})
      |> Map.take([:filename, :mime_type, :description, :created_at, :modified_at])
      |> Map.merge(%{
        logical_name: logical_name,
        source_kind: source_kind,
        bytes: bytes,
        byte_size: byte_size(bytes)
      })

    %__MODULE__{registry | files: Map.put(registry.files, logical_name, descriptor)}
  end

  @doc """
  Fetches a registered embedded-file descriptor.
  """
  @spec fetch(t(), logical_name()) :: {:ok, descriptor()} | :error
  def fetch(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    Map.fetch(registry.files, logical_name)
  end

  defp normalize_source({:binary, bytes}) when is_binary(bytes), do: {:binary, bytes}
  defp normalize_source({:path, path}) when is_binary(path), do: {:path, File.read!(path)}
end

defmodule Rendro.AssetRegistry do
  @moduledoc """
  State container for registered assets and their metadata.
  """
  @moduledoc tags: [:stable]

  defmodule InvalidAssetError do
    defexception [:message, :logical_name, :reason]
  end

  defstruct assets: %{}

  @type t :: %__MODULE__{
          assets: %{
            optional(atom()) => %{
              binary: binary(),
              width: pos_integer(),
              height: pos_integer(),
              mime: String.t()
            }
          }
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Registers an image into the registry.
  Source can be `{:binary, binary()}` or `{:path, Path.t()}`.
  """
  @spec register_image(t(), atom(), {:binary, binary()} | {:path, Path.t()}) :: t()
  def register_image(%__MODULE__{} = registry, logical_name, source) when is_atom(logical_name) do
    binary =
      case source do
        {:binary, bytes} when is_binary(bytes) -> bytes
        {:path, path} when is_binary(path) -> File.read!(path)
      end

    case Rendro.ImageParser.parse(binary) do
      {:ok, %{width: width, height: height, mime: mime} = info} ->
        asset = %{
          binary: binary,
          width: width,
          height: height,
          mime: mime,
          bit_depth: Map.get(info, :bit_depth),
          color_type: Map.get(info, :color_type),
          interlace: Map.get(info, :interlace)
        }

        %__MODULE__{registry | assets: Map.put(registry.assets, logical_name, asset)}

      {:error, reason} ->
        raise InvalidAssetError,
          message: "Failed to parse image for asset #{inspect(logical_name)}: #{inspect(reason)}",
          logical_name: logical_name,
          reason: reason
    end
  end

  @doc """
  Fetches a registered asset.
  """
  @spec fetch(t(), atom()) :: {:ok, map()} | :error
  def fetch(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    Map.fetch(registry.assets, logical_name)
  end
end

defmodule Rendro.AssetRegistry do
  @moduledoc """
  State container for registered assets and their metadata.
  """

  defmodule InvalidAssetError do
    defexception [:message, :logical_name, :reason]
  end

  defstruct assets: %{}

  def new, do: %__MODULE__{}

  def register_image(_registry, _logical_name, _source) do
    # Not implemented
  end
  
  def fetch(_registry, _logical_name) do
    :error
  end
end

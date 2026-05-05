defmodule Rendro.Rules.CheckReferences do
  @moduledoc false

  alias Rendro.Document
  alias Rendro.AssetRegistry

  def check(%Rendro.Image{logical_name: name}, %Document{} = doc) do
    case AssetRegistry.fetch(doc.asset_registry, name) do
      {:ok, _} -> :ok
      :error -> {:error, {:missing_image_reference, name}}
    end
  end

  def check(%Rendro.Text{font: name}, %Document{} = doc) do
    case Map.fetch(doc.font_registry.fonts, name) do
      {:ok, _} -> :ok
      :error -> {:error, {:missing_font_reference, name}}
    end
  end

  def check(
        %Rendro.Pipeline.MeasuredText{
          resolved_font: %Rendro.PDF.Font{logical_name: logical_name}
        },
        %Document{} = doc
      ) do
    case Map.fetch(doc.font_registry.fonts, logical_name) do
      {:ok, _} -> :ok
      :error -> {:error, {:missing_font_reference, logical_name}}
    end
  end

  def check(_, _doc), do: :ok
end

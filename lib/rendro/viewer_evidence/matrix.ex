defmodule Rendro.ViewerEvidence.Matrix do
  @moduledoc false

  @matrix_path "priv/support_matrix.json"

  @viewer_maps [
    {"forms.viewers", ["forms", "viewers"]},
    {"forms.signature_widget_viewers", ["forms", "signature_widget_viewers"]},
    {"signing_preparation.viewers", ["signing_preparation", "viewers"]},
    {"signing.viewers", ["signing", "viewers"]},
    {"signing.long_lived.viewers", ["signing", "long_lived", "viewers"]},
    {"embedded_files.viewers", ["embedded_files", "viewers"]},
    {"links.viewers", ["links", "viewers"]},
    {"protection.viewers", ["protection", "viewers"]}
  ]

  @surface_by_map %{
    "forms.viewers" => "forms",
    "forms.signature_widget_viewers" => "signature_widget",
    "signing_preparation.viewers" => "signing_preparation",
    "signing.viewers" => "signed_artifact",
    "signing.long_lived.viewers" => "long_lived_signed_artifact",
    "embedded_files.viewers" => "embedded_files",
    "links.viewers" => "links",
    "protection.viewers" => "protection"
  }

  @type cell :: %{
          surface: String.t(),
          viewer: String.t(),
          status: String.t(),
          matrix_path: String.t(),
          proof: [String.t()]
        }

  @spec load!() :: map()
  def load! do
    @matrix_path |> File.read!() |> JSON.decode!()
  end

  @spec surface(String.t(), String.t()) :: String.t()
  def surface(map_path, _viewer) do
    Map.fetch!(@surface_by_map, map_path)
  end

  @spec enumerate_viewer_cells(map()) :: [cell()]
  def enumerate_viewer_cells(matrix) do
    @viewer_maps
    |> Enum.flat_map(fn {map_path, path_keys} ->
      viewers = get_in(matrix, path_keys) || %{}

      Enum.map(viewers, fn {viewer, row} ->
        %{
          surface: surface(map_path, viewer),
          viewer: viewer,
          status: Map.fetch!(row, "status"),
          matrix_path: map_path <> "." <> viewer,
          proof: Map.get(row, "proof", [])
        }
      end)
    end)
    |> Enum.sort_by(fn cell -> {cell.surface, cell.viewer} end)
  end
end

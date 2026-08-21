defmodule Rendro.CatalogReviewReconciliation do
  @moduledoc false

  @local_png_directory "pngs"

  @spec reconcile(map(), map(), map(), String.t()) :: {:ok, map()} | {:error, atom()}
  def reconcile(candidate_manifest, %{"images" => images}, provenance, final_dir)
      when is_map(candidate_manifest) and is_list(images) and is_map(provenance) and
             is_binary(final_dir) do
    with {:ok, %{final: final}} <-
           Rendro.CatalogReviewPayload.classify(
             candidate_manifest,
             Map.fetch!(candidate_manifest, "multipage")
           ),
         expected <- add_candidate_dimensions(final, Map.fetch!(candidate_manifest, "cells")),
         :ok <- validate_exact_identity_order(expected, images),
         {:ok, renderer} <- renderer_identity(candidate_manifest, provenance),
         {:ok, bindings} <- bind_local_paths(expected, images, final_dir) do
      {:ok,
       %{
         "schema_version" => 1,
         "renderer" => renderer,
         "route" => Map.fetch!(provenance, "route"),
         "rendered_source" => Map.fetch!(provenance, "rendered_source"),
         "run" => Map.fetch!(provenance, "run"),
         "bindings" => bindings
       }}
    else
      {:error, _reason} = error -> error
      false -> {:error, :identity_mismatch}
      _ -> {:error, :invalid_reconciliation_input}
    end
  end

  def reconcile(_candidate_manifest, _identity_manifest, _provenance, _final_dir),
    do: {:error, :invalid_reconciliation_input}

  defp validate_exact_identity_order(expected, images) do
    if exact_identity_order?(expected, images), do: :ok, else: {:error, :identity_mismatch}
  end

  defp add_candidate_dimensions(final, cells) do
    cells_by_id = Map.new(cells, &{&1["id"], &1})

    Enum.map(final, fn identity ->
      cell = Map.fetch!(cells_by_id, identity["catalog_id"])
      Map.merge(identity, Map.take(cell, ~w(width_px height_px)))
    end)
  end

  defp exact_identity_order?(expected, images) do
    Enum.map(expected, & &1["catalog_id"]) == Enum.map(images, & &1["catalog_id"]) and
      Enum.zip(expected, images)
      |> Enum.all?(fn {candidate, image} ->
        Map.take(candidate, identity_fields()) == Map.take(image, identity_fields())
      end)
  end

  defp renderer_identity(candidate_manifest, provenance) do
    candidate = Map.fetch!(candidate_manifest, "candidate")
    candidate_renderer = Map.fetch!(candidate, "renderer")
    route_renderer = Map.fetch!(provenance, "renderer")

    if candidate_renderer["kind"] == "pdfium-render" and
         route_renderer["name"] == "pdfium-cli" and
         candidate_renderer["version"] == route_renderer["version"] and
         candidate_renderer["sha256"] == route_renderer["pin_sha256"] and
         candidate_renderer["sha256"] == route_renderer["executable_sha256"] and
         candidate["commit_sha"] == get_in(provenance, ["rendered_source", "sha"]) and
         candidate["run_id"] == get_in(provenance, ["run", "id"]) do
      {:ok,
       %{
         "adapter_kind" => candidate_renderer["kind"],
         "executable_name" => route_renderer["name"],
         "version" => candidate_renderer["version"],
         "pin_sha256" => candidate_renderer["sha256"],
         "executable_sha256" => route_renderer["executable_sha256"]
       }}
    else
      {:error, :provenance_mismatch}
    end
  end

  defp bind_local_paths(expected, images, final_dir) do
    Enum.zip(expected, images)
    |> Enum.map(fn {candidate, image} -> bind_local_path(candidate, image, final_dir) end)
    |> split_results()
  end

  defp bind_local_path(candidate, image, final_dir) do
    local_path =
      Path.join([final_dir, @local_png_directory, "#{image["catalog_id"]}_page_1.png"])

    with {:ok, png} <- File.read(local_path),
         true <- sha256(png) == image["png_sha256"],
         {:ok, {width, height}} <- png_dimensions(png),
         true <- width == candidate["width_px"] and height == candidate["height_px"] do
      {:ok,
       %{
         "catalog_id" => image["catalog_id"],
         "logical_candidate_png_path" => image["png_path"],
         "local_review_png_path" => local_path,
         "png_sha256" => image["png_sha256"],
         "source_pdf_sha256" => image["source_pdf_sha256"],
         "width_px" => width,
         "height_px" => height,
         "mode" => image["mode"],
         "commit_sha" => image["commit_sha"],
         "run_id" => image["run_id"]
       }}
    else
      false -> {:error, :local_binding_mismatch}
    end
  end

  defp identity_fields,
    do:
      ~w(catalog_id mode png_path png_sha256 source_pdf_sha256 renderer_version renderer_sha256 commit_sha run_id)

  defp png_dimensions(
         <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR", width::32, height::32,
           _rest::binary>>
       ),
       do: {:ok, {width, height}}

  defp png_dimensions(_png), do: {:error, :invalid_png}

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp split_results(results) do
    case Enum.find(results, &match?({:error, _reason}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, value} -> value end)}
      {:error, _reason} = error -> error
    end
  end
end

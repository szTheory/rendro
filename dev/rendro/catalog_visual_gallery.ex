defmodule Rendro.CatalogVisualGallery do
  @moduledoc false

  @candidate_root "tmp/phase130-candidate/"
  @target_ids [
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]

  @spec build(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def build(manifest_path, output_dir) when is_binary(manifest_path) and is_binary(output_dir) do
    with false <- File.exists?(output_dir),
         {:ok, contents} <- File.read(manifest_path),
         {:ok, manifest} <- Jason.decode(contents),
         {:ok, images} <- gallery_images(manifest),
         :ok <- File.mkdir_p(Path.join(output_dir, "images")),
         :ok <- copy_images(images, output_dir),
         :ok <-
           File.write(
             Path.join(output_dir, "manifest.json"),
             Jason.encode!(metadata(manifest, images), pretty: true) <> "\n"
           ),
         :ok <- File.write(Path.join(output_dir, "index.html"), html(manifest, images)) do
      {:ok, output_dir}
    else
      true -> {:error, :gallery_output_exists}
      {:error, _reason} -> {:error, :invalid_gallery_input}
      _ -> {:error, :invalid_gallery_input}
    end
  end

  def build(_manifest_path, _output_dir), do: {:error, :invalid_gallery_input}

  defp gallery_images(%{"candidate" => %{"commit_sha" => sha}, "cells" => cells, "diff" => diff})
       when is_binary(sha) and is_list(cells) and is_map(diff) do
    ids = diff["changed_scored"]
    cells_by_id = Map.new(cells, &{&1["id"], &1})

    with true <- ids == @target_ids,
         true <- diff["changed_unscored"] == [],
         true <- length(diff["byte_stable"] || []) == 26,
         true <- Enum.map(cells, & &1["id"]) == Enum.map(Rendro.Catalog.catalog_specs(), & &1.id),
         true <- map_size(cells_by_id) == 32,
         images <- Enum.map(ids, &Map.get(cells_by_id, &1)),
         true <- Enum.all?(images, &valid_image?/1) do
      {:ok, images}
    else
      _ -> {:error, :invalid_gallery_manifest}
    end
  end

  defp gallery_images(_manifest), do: {:error, :invalid_gallery_manifest}

  defp valid_image?(%{"id" => id, "png_path" => path, "png_sha256" => expected_sha})
       when id in @target_ids and is_binary(path) and is_binary(expected_sha) do
    with true <- String.starts_with?(path, @candidate_root),
         {:ok, _safe_path} <- Path.safe_relative(path),
         {:ok, png} <- File.read(path) do
      sha256(png) == expected_sha
    else
      _ -> false
    end
  end

  defp valid_image?(_image), do: false

  defp copy_images(images, output_dir) do
    Enum.reduce_while(images, :ok, fn image, :ok ->
      destination = Path.join([output_dir, "images", image["id"] <> ".png"])

      case File.cp(image["png_path"], destination) do
        :ok -> {:cont, :ok}
        {:error, _reason} -> {:halt, {:error, :copy_failed}}
      end
    end)
  end

  defp metadata(%{"candidate" => candidate}, images) do
    %{
      "schema_version" => 1,
      "authority" => "none",
      "candidate_sha" => candidate["commit_sha"],
      "images" => Enum.map(images, &Map.take(&1, ~w(id mode png_sha256 source_pdf_sha256)))
    }
  end

  defp html(%{"candidate" => candidate}, images) do
    cards =
      Enum.map_join(images, "\n", fn image ->
        id = escape(image["id"])
        mode = escape(image["mode"])

        """
        <article class="sheet" data-mode="#{mode}">
          <img src="images/#{id}.png" alt="#{id} rendered PDF page one" loading="eager">
          <div class="caption"><strong>#{id}</strong><span>#{mode} · sha256: #{escape(image["png_sha256"])}</span></div>
        </article>
        """
      end)

    """
    <!doctype html>
    <html lang="en">
    <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Rendro visual inspection</title>
    <style>
      :root { color-scheme: light dark; font-family: ui-monospace, Menlo, monospace; background: #111314; color: #ecede8; }
      body { margin: 0; padding: 2rem; background: radial-gradient(circle at top right, #254344, #111314 42rem); }
      header { max-width: 1200px; margin: 0 auto 2rem; border-left: 5px solid #e9b44c; padding: .2rem 1rem; }
      h1 { margin: 0; letter-spacing: -.08em; font-size: clamp(2rem, 6vw, 4.5rem); } p { max-width: 76ch; line-height: 1.55; }
      .sha { color: #e9b44c; overflow-wrap: anywhere; } .grid { max-width: 1200px; margin: auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.25rem; }
      .sheet { margin: 0; border: 1px solid #516366; background: #191d1f; box-shadow: 10px 10px 0 #0007; } img { display: block; width: 100%; height: auto; background: #fff; } .caption { padding: .8rem; display: grid; gap: .4rem; font-size: .72rem; overflow-wrap: anywhere; } .caption span { color: #b9c6c3; }
    </style></head>
    <body><header><p>RENDRO / CANDIDATE VISUAL INSPECTION</p><h1>Six changed surfaces</h1><p class="sha">candidate #{escape(candidate["commit_sha"])}</p><p>Convenience-only presentation. This page records no review, disposition, approval, or canonical eligibility. Verify the separate closed Catalog Evidence bundle before relying on its provenance.</p></header><main class="grid">#{cards}</main></body></html>
    """
  end

  defp escape(value),
    do:
      value
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace("\"", "&quot;")

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end

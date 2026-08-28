defmodule Rendro.CatalogVisualGalleryTest do
  use ExUnit.Case, async: false

  alias Rendro.CatalogVisualGallery

  @targets [
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]

  test "builds a six-image convenience gallery without review authority" do
    root = "tmp/catalog-visual-gallery-test-#{System.unique_integer([:positive])}"
    candidate_root = "tmp/phase130-candidate/gallery-test-#{System.unique_integer([:positive])}"
    File.mkdir_p!(candidate_root)

    on_exit(fn ->
      File.rm_rf(root)
      File.rm_rf(candidate_root)
    end)

    manifest = manifest(candidate_root)
    manifest_path = Path.join(candidate_root, "candidate-manifest.json")
    File.write!(manifest_path, Jason.encode!(manifest))

    assert {:ok, ^root} = CatalogVisualGallery.build(manifest_path, root)

    assert File.ls!(Path.join(root, "images")) |> Enum.sort() ==
             @targets |> Enum.map(&(&1 <> ".png")) |> Enum.sort()

    assert %{"authority" => "none", "images" => images} =
             root |> Path.join("manifest.json") |> File.read!() |> JSON.decode!()

    assert Enum.map(images, & &1["id"]) == @targets

    html = File.read!(Path.join(root, "index.html"))
    assert html =~ "Convenience-only presentation"
    assert html =~ "no review, disposition, approval, or canonical eligibility"
  end

  test "rejects reordered targets, non-targets, and hash-mismatched pixels" do
    root = "tmp/catalog-visual-gallery-invalid-#{System.unique_integer([:positive])}"

    candidate_root =
      "tmp/phase130-candidate/gallery-invalid-#{System.unique_integer([:positive])}"

    File.mkdir_p!(candidate_root)

    on_exit(fn ->
      File.rm_rf(root)
      File.rm_rf(candidate_root)
    end)

    for invalid <- [
          put_in(manifest(candidate_root), ["diff", "changed_scored"], Enum.reverse(@targets)),
          put_in(
            manifest(candidate_root),
            ["diff", "changed_scored"],
            List.replace_at(@targets, 0, "not-a-target")
          ),
          hash_mismatch_manifest(candidate_root)
        ] do
      path = Path.join(candidate_root, "#{System.unique_integer([:positive])}.json")
      File.write!(path, Jason.encode!(invalid))
      assert {:error, :invalid_gallery_input} = CatalogVisualGallery.build(path, root)
      refute File.exists?(root)
    end
  end

  defp manifest(candidate_root) do
    cells =
      Enum.map(@targets, fn id ->
        png =
          <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR", 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0,
            0, 0>>

        path = Path.join(candidate_root, "#{id}.png")
        File.write!(path, png)
        [_, _, _, mode] = String.split(id, "--")

        %{
          "id" => id,
          "mode" => mode,
          "png_path" => path,
          "png_sha256" => sha256(png),
          "source_pdf_sha256" => String.duplicate("a", 64)
        }
      end)

    all_ids = Enum.map(Rendro.Catalog.catalog_specs(), & &1.id)

    controls =
      all_ids
      |> Enum.reject(&(&1 in @targets))
      |> Enum.map(fn id -> %{"id" => id, "mode" => List.last(String.split(id, "--"))} end)

    %{
      "candidate" => %{"commit_sha" => String.duplicate("b", 40)},
      "cells" =>
        Enum.map(all_ids, &Enum.find(cells ++ controls, fn cell -> cell["id"] == &1 end)),
      "diff" => %{
        "changed_scored" => @targets,
        "changed_unscored" => [],
        "byte_stable" => Enum.reject(all_ids, &(&1 in @targets))
      }
    }
  end

  defp hash_mismatch_manifest(candidate_root) do
    manifest = manifest(candidate_root)
    index = Enum.find_index(manifest["cells"], &(&1["id"] == hd(@targets)))
    put_in(manifest, ["cells", Access.at(index), "png_sha256"], String.duplicate("f", 64))
  end

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end

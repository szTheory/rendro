defmodule Rendro.DocsContract.CatalogManifestContractTest do
  use ExUnit.Case, async: true

  alias Rendro.Catalog

  @dark_disclosure "Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim."

  defp cell(spec, overrides \\ %{}) do
    %{
      "id" => spec.id,
      "family" => Atom.to_string(spec.family),
      "brand" => spec.brand,
      "preset" => spec.preset,
      "theme" => spec.theme,
      "accent" => spec.accent,
      "mode" => spec.mode,
      "recipe_module" => Atom.to_string(spec.recipe_module),
      "fixture_ref" => spec.fixture_ref,
      "png_path" => spec.png_path,
      "png_sha256" => String.duplicate("a", 64),
      "source_pdf_sha256" => String.duplicate("b", 64),
      "page" => 1,
      "page_count" => 1,
      "dpi" => 96,
      "width_px" => 794,
      "height_px" => 1123,
      "renderer_kind" => "pdfium-render",
      "renderer_version" => "v0.11.0",
      "alt" => "A concrete #{spec.id} preview.",
      "caption" => "A distinct catalog context for #{spec.id}.",
      "preview_copy" => nil,
      "boundary_disclosure" => if(spec.mode == "dark", do: @dark_disclosure, else: nil),
      "quality" => %{"status" => "unscored", "label" => "Not yet scored"}
    }
    |> Map.merge(overrides)
  end

  defp manifest(cells) do
    %{
      "schema_version" => 1,
      "generated_by" => "mix rendro.catalog.gen",
      "renderer" => %{
        "kind" => "pdfium-render",
        "dpi" => 96,
        "pin_sha256" => JSON.decode!(File.read!("priv/pdfium_pin.json"))["sha256"]
      },
      "cells" => cells
    }
  end

  test "consumer manifest requires derived preview copy, disclosure, and quality fields" do
    cells = Enum.map(Catalog.catalog_specs(), &cell/1)
    assert Catalog.manifest_shape_errors(manifest(cells)) == []

    [first | rest] = cells
    errors = Catalog.manifest_shape_errors(manifest([Map.delete(first, "quality") | rest]))

    assert Enum.any?(errors, &String.contains?(&1, "#{first["id"]}: missing quality; add a derived quality projection"))
  end

  test "preview copy is a page-count-only disclosure and cannot call page one complete" do
    [spec | _] = Catalog.catalog_specs()
    multi_page = cell(spec, %{"page_count" => 3, "preview_copy" => "Preview: page 1 of 3"})
    assert Catalog.manifest_shape_errors(manifest([multi_page])) |> Enum.any?(&String.contains?(&1, "cell order"))

    bad = %{multi_page | "preview_copy" => "Complete document"}

    assert Catalog.manifest_shape_errors(manifest([bad]))
           |> Enum.any?(&String.contains?(&1, "#{spec.id}: preview_copy must be Preview: page 1 of 3"))
  end

  test "boundary disclosure derives strictly from mode" do
    dark = Enum.find(Catalog.catalog_specs(), &(&1.mode == "dark"))
    light = Enum.find(Catalog.catalog_specs(), &(&1.mode == "light"))

    dark_errors = Catalog.manifest_shape_errors(manifest([cell(dark, %{"boundary_disclosure" => nil})]))
    assert Enum.any?(dark_errors, &String.contains?(&1, "#{dark.id}: dark boundary_disclosure"))

    light_errors =
      Catalog.manifest_shape_errors(manifest([cell(light, %{"boundary_disclosure" => @dark_disclosure})]))

    assert Enum.any?(light_errors, &String.contains?(&1, "#{light.id}: light boundary_disclosure must be null"))
  end

  test "Hex package retains launch assets while excluding the catalog and private rubric inputs" do
    package_files = Rendro.MixProject.project()[:package][:files]
    assert "assets/rendro/artifacts.json" in package_files
    assert "assets/rendro/gallery" in package_files
    assert "assets/rendro/manual.pdf" in package_files
    refute "assets/rendro" in package_files
  end
end

defmodule Rendro.DocsContract.ConfiguratorPhaseGateTest do
  use ExUnit.Case, async: true

  alias Rendro.Theme.Snippet

  @asset_root "assets/rendro"
  @entrypoint Path.join(@asset_root, "configurator/index.html")
  @index_path Path.join(@asset_root, "configurator/index.json")
  @catalog_path Path.join(@asset_root, "catalog.json")

  test "committed static entry point resolves its local graph without a service or build product" do
    html = File.read!(@entrypoint)

    for reference <- local_references(html) do
      assert Path.type(reference) == :relative

      assert File.regular?(Path.expand(reference, Path.dirname(@entrypoint))),
             "expected committed local asset #{reference} to exist"
    end

    assert local_references(html) == [
             "../../../brand/tokens/tokens.css",
             "configurator.css",
             "configurator.js"
           ]

    refute html =~ ~r{https?://}
    refute html =~ "node"
    refute html =~ "npm"
    refute html =~ "Phoenix"
  end

  test "committed index and catalog retain their closed formatter-owned relationship" do
    index = JSON.decode!(File.read!(@index_path))
    catalog = JSON.decode!(File.read!(@catalog_path))
    records = index["records"]
    catalog_cells = catalog["cells"]

    assert index["schema_version"] == 1
    assert index["generated_by"] == "mix rendro.configurator.gen"
    assert length(records) == 504
    assert length(catalog_cells) == 32
    assert File.read!(@index_path) == Snippet.index_json()

    selection_keys = MapSet.new(records, &selection_key/1)
    assert MapSet.size(selection_keys) == 504

    for cell <- catalog_cells do
      assert safe_catalog_raster?(cell["png_path"])

      assert File.regular?(cell["png_path"]),
             "expected catalog raster #{cell["png_path"]} to exist"

      if Enum.all?(~w(family preset accent mode), &is_binary(cell[&1])) do
        assert MapSet.member?(selection_keys, selection_key(cell))
      end
    end
  end

  test "visible configurator source is committed formatter output rather than browser source generation" do
    javascript = File.read!(Path.join(@asset_root, "configurator/configurator.js"))
    index = JSON.decode!(File.read!(@index_path))

    assert javascript =~ "fetch(\"index.json\")"
    assert javascript =~ "fetch(\"../catalog.json\")"
    assert javascript =~ "snippetCode.textContent = record.snippet"
    assert javascript =~ "navigator.clipboard.writeText(visibleCodeText)"
    refute javascript =~ "Rendro.Theme.preset("
    refute javascript =~ "String.raw"

    for record <- index["records"] do
      assert record["snippet"] ==
               Snippet.usage_snippet(
                 record["family"],
                 record["preset"],
                 record["accent"],
                 record["mode"]
               )
    end
  end

  defp local_references(html) do
    Regex.scan(~r/(?:href|src)="([^"]+)"/, html, capture: :all_but_first)
    |> List.flatten()
  end

  defp selection_key(value),
    do: Enum.map_join(~w(family preset accent mode), "--", &value[&1])

  defp safe_catalog_raster?(path) when is_binary(path),
    do:
      path =~
        ~r/^assets\/rendro\/catalog\/[a-z0-9-]+\/[a-z0-9-]+\/[a-z0-9-]+-(?:light|dark)\.png$/

  defp safe_catalog_raster?(_path), do: false
end

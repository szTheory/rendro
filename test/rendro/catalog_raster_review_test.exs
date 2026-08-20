defmodule Rendro.CatalogRasterReviewTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.CatalogReviewPayload
  alias Rendro.Test.EdgeFixtures

  @candidate_manifest_path "tmp/phase130-candidate/candidate-manifest.json"
  @review_dir_env "RENDRO_CATALOG_REVIEW_DIR"

  @tag raster_snapshot: true
  test "renders only the validated candidate payload into separate final and multipage review directories" do
    manifest = @candidate_manifest_path |> File.read!() |> JSON.decode!()
    review_dir = System.fetch_env!(@review_dir_env)
    final_dir = Path.join(review_dir, "final")
    multipage_dir = Path.join(review_dir, "multipage")

    assert {:ok, %{final: final, multipage: multipage}} =
             CatalogReviewPayload.classify(manifest, Map.fetch!(manifest, "multipage"))

    File.mkdir_p!(final_dir)
    File.mkdir_p!(multipage_dir)

    for identity <- final do
      spec = Enum.find(Rendro.Catalog.catalog_specs(), &(&1.id == identity["catalog_id"]))
      assert spec
      assert sha256(File.read!(identity["png_path"])) == identity["png_sha256"]
      assert {:ok, pdf} = Rendro.Catalog.render_source_pdf(spec)
      assert sha256(pdf) == identity["source_pdf_sha256"]
      assert {:ok, [png]} = Pdfium.render(pdf, dpi: 96, pages: "1")
      assert sha256(png) == identity["png_sha256"]

      File.write!(Path.join(final_dir, "#{identity["catalog_id"]}_page_1.png"), png)
    end

    for proof <- multipage do
      family = String.to_existing_atom(proof["family"])
      document = EdgeFixtures.document(family, :line_items_60_plus)
      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert sha256(pdf) == proof["source_pdf_sha256"]
      assert {:ok, pages} = Pdfium.render(pdf, dpi: 96)
      assert length(pages) > 1

      png = if proof["page"] == "first", do: hd(pages), else: List.last(pages)
      assert sha256(png) == proof["png_sha256"]
      assert sha256(File.read!(proof["png_path"])) == proof["png_sha256"]
      File.write!(Path.join(multipage_dir, "#{proof["id"]}.png"), png)
    end

    File.write!(
      Path.join(final_dir, "identity-manifest.json"),
      Jason.encode!(%{"images" => final}, pretty: true) <> "\n"
    )

    assert final_dir |> File.ls!() |> Enum.count(&String.ends_with?(&1, ".png")) == 12
    assert multipage_dir |> File.ls!() |> Enum.count(&String.ends_with?(&1, ".png")) == 4
  end

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end

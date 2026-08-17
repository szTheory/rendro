defmodule Rendro.CatalogRasterReviewTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.Test.EdgeFixtures

  @review_dir_env "RENDRO_CATALOG_REVIEW_DIR"
  @flagship_ids [
    "invoice--cedar-mutual--corporate-classic--light",
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--light",
    "statement--signal-ledger--minimal-mono--dark",
    "receipt--poppy-and-grain--humanist--light",
    "receipt--poppy-and-grain--humanist--dark",
    "certificate--meridian-arts-fellowship--editorial--light",
    "certificate--meridian-arts-fellowship--editorial--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]

  @tag raster_snapshot: true
  test "writes only the twelve flagship page ones and bounded multipage proof to the caller review directory" do
    review_dir = System.fetch_env!(@review_dir_env)
    manifest = Rendro.Catalog.read_manifest!()
    cells_by_id = Map.new(manifest["cells"], &{&1["id"], &1})

    assert @flagship_ids ==
             Rendro.Catalog.catalog_specs()
             |> Enum.map(& &1.id)
             |> Enum.filter(&(&1 in @flagship_ids))

    for id <- @flagship_ids do
      spec = Enum.find(Rendro.Catalog.catalog_specs(), &(&1.id == id))
      cell = Map.fetch!(cells_by_id, id)
      assert {:ok, pdf} = Rendro.Catalog.render_source_pdf(spec)
      assert {:ok, [png]} = Pdfium.render(pdf, dpi: cell["dpi"], pages: "1")
      assert sha256(png) == cell["png_sha256"]
      assert sha256(File.read!(cell["png_path"])) == cell["png_sha256"]
      File.write!(Path.join(review_dir, "#{id}_page_1.png"), png)
    end

    for {family, prefix} <- [invoice: "invoice", statement: "statement"] do
      document = EdgeFixtures.document(family, :line_items_60_plus)
      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert page_count(pdf) > 1
      last_page = page_count(pdf)
      assert {:ok, [first]} = Pdfium.render(pdf, dpi: 96, pages: "1")
      assert {:ok, [last]} = Pdfium.render(pdf, dpi: 96, pages: Integer.to_string(last_page))
      File.write!(Path.join(review_dir, "#{prefix}_line_items_60_plus_page_first.png"), first)
      File.write!(Path.join(review_dir, "#{prefix}_line_items_60_plus_page_final.png"), last)
    end

    assert review_dir |> File.ls!() |> Enum.sort() |> length() == 16
  end

  defp page_count(pdf), do: :binary.matches(pdf, "/Type /Page") |> length()
  defp sha256(binary), do: binary |> :crypto.hash(:sha256) |> Base.encode16(case: :lower)
end

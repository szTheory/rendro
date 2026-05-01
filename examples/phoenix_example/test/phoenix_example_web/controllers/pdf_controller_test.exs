defmodule PhoenixExampleWeb.PDFControllerTest do
  use PhoenixExampleWeb.ConnCase

  @moduledoc """
  Tests for the PDF controller serving the canonical invoice recipe.
  """

  # Dummy data matching the controller's hardcoded invoice data
  @invoice_data %{
    id: "INV-2026-001",
    date: ~D[2026-04-30],
    items: [
      %{name: "Consulting Services", qty: 10, price: 2_500},
      %{name: "Support Plan", qty: 1, price: 500}
    ]
  }
  @branded_invoice_data Map.put(@invoice_data, :brand, %{
                          font_name: :brand_heading,
                          logo_name: :company_logo
                        })

  describe "GET /download" do
    # Test 1: HTTP 200 with application/pdf content-type
    test "returns 200 with application/pdf content-type", %{conn: conn} do
      conn = get(conn, "/download")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
    end

    # Test 4: Response body begins with PDF magic bytes %PDF-
    test "response body begins with PDF magic bytes", %{conn: conn} do
      conn = get(conn, "/download")
      body = conn.resp_body
      assert is_binary(body)
      assert byte_size(body) > 0
      assert binary_part(body, 0, 5) == "%PDF-"
    end
  end

  describe "Invoice recipe structural assertions" do
    # Test 3: The document built by the recipe has named regions and non-empty sections.
    # We re-run the recipe with the same dummy data used in the controller to verify
    # the canonical recipe is what drives the response.
    test "document has named page_template regions and non-empty sections" do
      doc = Rendro.Recipes.Invoice.document(@invoice_data)

      assert %Rendro.Document{} = doc
      assert doc.page_template == :invoice

      # page_templates must include a template with named regions
      assert [template] = doc.page_templates
      assert template.name == :invoice
      assert length(template.regions) >= 3

      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names

      # sections must be non-empty (proves canonical recipe, not trivial flow)
      assert doc.sections != []
      assert length(doc.sections) == 3

      section_regions = Enum.map(doc.sections, & &1.region)
      assert :header in section_regions
      assert :body in section_regions
      assert :footer in section_regions
    end
  end

  describe "GET /branded/download" do
    test "returns 200 with application/pdf content-type and PDF magic bytes", %{conn: conn} do
      conn = get(conn, "/branded/download")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
      assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
    end
  end

  describe "BrandedInvoice recipe structural assertions" do
    test "document registers the branded font, logo, and logo region" do
      doc = Rendro.Recipes.BrandedInvoice.document(@branded_invoice_data)

      assert %Rendro.Document{} = doc
      assert doc.page_template == :branded_invoice
      assert [template] = doc.page_templates

      region_names = Enum.map(template.regions, & &1.name)
      assert :logo in region_names
      assert length(template.regions) >= 4

      assert Map.has_key?(doc.font_registry.fonts, @branded_invoice_data.brand.font_name)
      assert match?(%{source: :embedded}, doc.font_registry.fonts[@branded_invoice_data.brand.font_name])
      assert Map.has_key?(doc.asset_registry.assets, @branded_invoice_data.brand.logo_name)
    end
  end

  describe "Source-level check: controller uses canonical recipe" do
    # Test 2: The controller source invokes Rendro.Recipes.Invoice.document/2 and
    # does not contain the legacy Rendro.flow literal.
    test "controller source invokes Rendro.Recipes.Invoice.document and not legacy Rendro.flow" do
      source_path =
        Path.join([
          Application.app_dir(:phoenix_example, "priv"),
          "..",
          "..",
          "..",
          "lib",
          "phoenix_example_web",
          "controllers",
          "pdf_controller.ex"
        ])
        |> Path.expand()

      # Fallback: use Mix.Project.app_path-relative path
      source_path =
        if File.exists?(source_path) do
          source_path
        else
          Path.join([
            File.cwd!(),
            "lib",
            "phoenix_example_web",
            "controllers",
            "pdf_controller.ex"
          ])
        end

      assert File.exists?(source_path),
             "Could not locate pdf_controller.ex at #{source_path}"

      source = File.read!(source_path)
      assert source =~ "Rendro.Recipes.Invoice.document",
             "Controller must call Rendro.Recipes.Invoice.document/2"
      assert source =~ "Rendro.Recipes.BrandedInvoice.document",
             "Controller must call Rendro.Recipes.BrandedInvoice.document/1"
      refute source =~ ~r/Rendro\.flow\(\[/,
             "Controller must not use legacy Rendro.flow([ ... ])"
    end
  end
end

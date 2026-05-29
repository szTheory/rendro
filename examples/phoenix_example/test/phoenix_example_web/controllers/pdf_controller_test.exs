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

  @statement_data %{
    period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
    account: %{name: "Acme Corp"},
    opening_balance: Decimal.new("1000.00"),
    lines: [
      %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
      %{date: ~D[2026-05-15], description: "Payment", amount: Decimal.new("-200.00")}
    ]
  }

  @receipt_data %{
    title: "Payment Receipt",
    date: ~D[2026-05-29],
    customer: %{name: "Acme Corp"},
    lines: [
      %{description: "Widget A", amount: Decimal.new("29.99")},
      %{description: "Widget B", amount: Decimal.new("49.99")}
    ],
    totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
  }

  @certificate_data %{
    title: "Certificate of Completion",
    recipient: "Jane Smith",
    date: ~D[2026-05-29],
    body: "For outstanding contribution to deterministic PDF generation.",
    seal_line: "Authorized Signature"
  }

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

  describe "GET /statement/download" do
    test "returns 200 with application/pdf content-type and PDF magic bytes", %{conn: conn} do
      conn = get(conn, "/statement/download")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
      assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
    end
  end

  describe "Statement recipe structural assertions" do
    test "document has statement page_template with header, body, and footer regions" do
      doc = Rendro.Recipes.Statement.document(@statement_data)

      assert %Rendro.Document{} = doc
      assert doc.page_template == :statement

      assert [template] = doc.page_templates
      assert template.name == :statement

      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names

      assert doc.sections != []
    end
  end

  describe "GET /receipt/download" do
    test "returns 200 with application/pdf content-type and PDF magic bytes", %{conn: conn} do
      conn = get(conn, "/receipt/download")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
      assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
    end
  end

  describe "Receipt recipe structural assertions" do
    test "document has receipt page_template with header, body, and footer regions" do
      doc = Rendro.Recipes.Receipt.document(@receipt_data)

      assert %Rendro.Document{} = doc
      assert doc.page_template == :receipt

      assert [template] = doc.page_templates
      assert template.name == :receipt

      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names

      assert doc.sections != []
    end
  end

  describe "GET /certificate/download" do
    test "returns 200 with application/pdf content-type and PDF magic bytes", %{conn: conn} do
      conn = get(conn, "/certificate/download")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/pdf"
      assert binary_part(conn.resp_body, 0, 5) == "%PDF-"
    end
  end

  describe "Certificate recipe structural assertions" do
    test "document has certificate page_template with exactly one body region" do
      doc = Rendro.Recipes.Certificate.document(@certificate_data)

      assert %Rendro.Document{} = doc
      assert doc.page_template == :certificate

      assert [template] = doc.page_templates
      assert template.name == :certificate

      region_names = Enum.map(template.regions, & &1.name)
      assert region_names == [:body]
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
      assert source =~ "Rendro.Recipes.Statement.document",
             "Controller must call Rendro.Recipes.Statement.document/1"
      assert source =~ "Rendro.Recipes.Receipt.document",
             "Controller must call Rendro.Recipes.Receipt.document/1"
      assert source =~ "Rendro.Recipes.Certificate.document",
             "Controller must call Rendro.Recipes.Certificate.document/1"
      refute source =~ ~r/Rendro\.flow\(\[/,
             "Controller must not use legacy Rendro.flow([ ... ])"
    end
  end
end

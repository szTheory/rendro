defmodule Rendro.Recipes.BrandedInvoiceTest do
  use ExUnit.Case, async: true

  import ExUnit.DocTest

  alias Rendro.Recipes.BrandedInvoice

  doctest Rendro.Recipes.BrandedInvoice

  defp sample_data do
    %{
      id: "INV-2026-042",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget A", qty: 3, price: 200},
        %{name: "Widget B", qty: 1, price: 500}
      ],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }
  end

  describe "page_template/1" do
    test "returns a branded page template struct" do
      template = BrandedInvoice.page_template()
      assert %Rendro.PageTemplate{} = template
      assert template.name == :branded_invoice
    end

    test "template has all four named regions" do
      template = BrandedInvoice.page_template()
      region_names = Enum.map(template.regions, & &1.name) |> Enum.sort()
      assert region_names == [:body, :footer, :header, :logo]
    end

    test "accepts page template overrides" do
      template = BrandedInvoice.page_template(name: :custom_branded_invoice)
      assert template.name == :custom_branded_invoice
    end
  end

  describe "sections/2" do
    test "returns four section structs" do
      sections = BrandedInvoice.sections(sample_data())
      assert length(sections) == 4
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections cover logo, header, body, and footer regions" do
      sections = BrandedInvoice.sections(sample_data())
      assert Enum.map(sections, & &1.region) |> Enum.sort() == [:body, :footer, :header, :logo]
    end

    test "section names are branded invoice namespaced" do
      names = sample_data() |> BrandedInvoice.sections() |> Enum.map(& &1.name)
      assert Enum.all?(names, &(to_string(&1) =~ "branded_invoice"))
    end
  end

  describe "document/2" do
    test "returns a branded document" do
      assert %Rendro.Document{} = BrandedInvoice.document(sample_data())
    end

    test "document has the branded template active" do
      doc = BrandedInvoice.document(sample_data())
      assert doc.page_template == :branded_invoice
      assert Enum.map(doc.page_templates, & &1.name) == [:branded_invoice]
    end

    test "brand font is registered as an embedded source" do
      data = sample_data()
      doc = BrandedInvoice.document(data)

      assert Map.has_key?(doc.font_registry.fonts, data.brand.font_name)
      assert match?(%{source: :embedded}, doc.font_registry.fonts[data.brand.font_name])
    end

    test "brand logo is registered under the logical name" do
      data = sample_data()
      doc = BrandedInvoice.document(data)
      assert Map.has_key?(doc.asset_registry.assets, data.brand.logo_name)
    end
  end

  describe "validate_data! (boundary validation D-04)" do
    test "raises when data.brand is missing" do
      assert_raise ArgumentError, ~r/data\.brand/, fn ->
        BrandedInvoice.document(%{id: "INV-001", date: ~D[2026-01-15], items: []})
      end
    end

    test "raises when font_name is not an atom" do
      assert_raise ArgumentError, ~r/data\.brand\.font_name/, fn ->
        BrandedInvoice.document(%{
          id: "INV-001",
          date: ~D[2026-01-15],
          items: [],
          brand: %{font_name: "brand_heading", logo_name: :company_logo}
        })
      end
    end

    test "raises when logo_name is not an atom" do
      assert_raise ArgumentError, ~r/data\.brand\.logo_name/, fn ->
        BrandedInvoice.document(%{
          id: "INV-001",
          date: ~D[2026-01-15],
          items: [],
          brand: %{font_name: :brand_heading, logo_name: "company_logo"}
        })
      end
    end
  end

  describe "regression: full-pipeline render" do
    test "renders a branded PDF with embedded font and image resources" do
      doc = BrandedInvoice.document(sample_data())

      assert {:ok, pdf, final_doc} = Rendro.render_with_diagnostics(doc, deterministic: true)
      assert binary_part(pdf, 0, 5) == "%PDF-"
      assert pdf =~ "/F_BRAND_HEADING"
      assert pdf =~ "/FontFile2"
      assert pdf =~ "/Type /XObject"
      assert pdf =~ "/Subtype /Image"
      assert pdf =~ "/IM_COMPANY_LOGO"
      assert pdf =~ "/Filter /FlateDecode"
      assert pdf =~ "/Width 64"
      assert pdf =~ "/Height 64"
      assert pdf =~ "/Count 1"

      text_blocks =
        final_doc.pages
        |> hd()
        |> Map.fetch!(:blocks)
        |> Enum.filter(&match?(%Rendro.Pipeline.MeasuredText{}, &1.content))

      block_lines = fn block ->
        Enum.map(block.content.lines, fn line -> Enum.map_join(line, "", & &1.text) end)
      end

      brand_block =
        Enum.find(text_blocks, fn block ->
          Enum.any?(block.content.lines, fn line ->
            Enum.any?(line, &(&1.text == "Rendro, Inc."))
          end)
        end)

      id_block =
        Enum.find(text_blocks, fn block ->
          Enum.any?(block.content.lines, fn line ->
            Enum.any?(line, &String.starts_with?(&1.text, "Invoice #"))
          end)
        end)

      assert brand_block, "expected a measured block containing the brand line"
      assert id_block, "expected a measured block containing the invoice id line"

      # Brand and invoice id are now independent blocks. Each renders on a
      # single line — the id stays intact (no mid-token grapheme split) and
      # the brand keeps its prominence. Pins UAT Gap 2 fix.
      assert block_lines.(brand_block) == ["Rendro, Inc."]
      assert block_lines.(id_block) == ["Invoice #INV-2026-042"]
    end
  end

  describe "regression: byte-identical two-render" do
    test "two deterministic renders are byte-identical" do
      doc = BrandedInvoice.document(sample_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  describe "Rendro.Recipes.branded_invoice/1 delegate" do
    test "delegates to BrandedInvoice.document/1" do
      assert Rendro.Recipes.branded_invoice(sample_data()) ==
               BrandedInvoice.document(sample_data())
    end
  end
end

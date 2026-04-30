defmodule Rendro.Recipes.InvoiceTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-042",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget A", qty: 3, price: 200},
        %{name: "Widget B", qty: 1, price: 500}
      ]
    }
  end

  describe "page_template/1" do
    test "returns a %Rendro.PageTemplate{} with name :invoice" do
      template = Invoice.page_template()
      assert %Rendro.PageTemplate{} = template
      assert template.name == :invoice
    end

    test "template has named regions :header, :body, :footer" do
      template = Invoice.page_template()
      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names
    end

    test "accepts opts keyword list without error" do
      template = Invoice.page_template(name: :custom_invoice)
      assert %Rendro.PageTemplate{} = template
      assert template.name == :custom_invoice
    end
  end

  describe "sections/2" do
    test "returns a list of %Rendro.Section{} structs" do
      sections = Invoice.sections(sample_data())
      assert is_list(sections)
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "has sections targeting :header, :body, and :footer regions" do
      sections = Invoice.sections(sample_data())
      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "header section content includes invoice id" do
      sections = Invoice.sections(sample_data())
      header_section = Enum.find(sections, &(&1.region == :header))
      assert header_section != nil
      flat = inspect(header_section, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "INV-042"
    end

    test "body section content includes line items" do
      sections = Invoice.sections(sample_data())
      body_section = Enum.find(sections, &(&1.region == :body))
      assert body_section != nil
      flat = inspect(body_section, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "Widget A"
      assert flat =~ "Widget B"
    end

    test "footer section content is non-empty" do
      sections = Invoice.sections(sample_data())
      footer_section = Enum.find(sections, &(&1.region == :footer))
      assert footer_section != nil
      assert footer_section.content != []
    end
  end

  describe "document/2" do
    test "returns a %Rendro.Document{} struct" do
      doc = Invoice.document(sample_data())
      assert %Rendro.Document{} = doc
    end

    test "document has the invoice page_template in page_templates list" do
      doc = Invoice.document(sample_data())
      template_names = Enum.map(doc.page_templates, & &1.name)
      assert :invoice in template_names
    end

    test "document has page_template set to :invoice" do
      doc = Invoice.document(sample_data())
      assert doc.page_template == :invoice
    end

    test "document has sections covering all three regions" do
      doc = Invoice.document(sample_data())
      region_targets = Enum.map(doc.sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "document does NOT use legacy header/footer fields" do
      doc = Invoice.document(sample_data())
      assert doc.header == []
      assert doc.footer == []
    end

    test "document content includes invoice id and line items" do
      doc = Invoice.document(sample_data())
      flat = inspect(doc, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "INV-042"
      assert flat =~ "Widget A"
    end
  end
end

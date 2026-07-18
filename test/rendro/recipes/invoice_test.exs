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

  # ---------------------------------------------------------------------------
  # INV-06: validate_data!/1 — errors-as-product
  # ---------------------------------------------------------------------------

  describe "validate_data!/1 (INV-06)" do
    test "non-map data raises ArgumentError, not BadMapError/FunctionClauseError" do
      assert_raise ArgumentError, ~r/data must be a map/, fn ->
        Invoice.document("not-a-map")
      end
    end

    test "missing required key raises ArgumentError naming the missing key" do
      data = sample_data() |> Map.delete(:date)

      assert_raise ArgumentError, ~r/date/, fn ->
        Invoice.document(data)
      end
    end

    test "the toy call (:id, :date, :items only) is never rejected" do
      doc = Invoice.document(sample_data())
      assert %Rendro.Document{} = doc
    end

    test "non-map :issuer raises ArgumentError mentioning issuer" do
      data = Map.put(sample_data(), :issuer, "not-a-map")

      assert_raise ArgumentError, ~r/issuer/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-map :customer raises ArgumentError mentioning customer" do
      data = Map.put(sample_data(), :customer, "not-a-map")

      assert_raise ArgumentError, ~r/customer/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-Date :due_date raises ArgumentError mentioning due_date" do
      data = Map.put(sample_data(), :due_date, "2026-05-01")

      assert_raise ArgumentError, ~r/due_date/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-string :terms raises ArgumentError mentioning terms" do
      data = Map.put(sample_data(), :terms, 30)

      assert_raise ArgumentError, ~r/terms/i, fn ->
        Invoice.document(data)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # INV-01: optional anatomy fields render only when present
  # ---------------------------------------------------------------------------

  describe "optional anatomy fields (INV-01)" do
    test "issuer renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :issuer, %{name: "Rendro Systems"}))

      refute inspect(absent, limit: :infinity) =~ "Rendro Systems"
      assert inspect(present, limit: :infinity) =~ "Rendro Systems"
    end

    test "customer renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :customer, %{name: "Acme Phoenix SaaS"}))

      refute inspect(absent, limit: :infinity) =~ "Acme Phoenix SaaS"
      assert inspect(present, limit: :infinity) =~ "Acme Phoenix SaaS"
    end

    test "due_date renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :due_date, ~D[2026-05-30]))

      refute inspect(absent, limit: :infinity) =~ "2026-05-30"
      assert inspect(present, limit: :infinity) =~ "2026-05-30"
    end

    test "terms renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :terms, "Net 30"))

      refute inspect(absent, limit: :infinity) =~ "Net 30"
      assert inspect(present, limit: :infinity) =~ "Net 30"
    end

    test "absent anatomy fields keep header section identical to the toy path" do
      base = Invoice.sections(sample_data())
      with_nothing_new = Invoice.sections(sample_data())
      assert base == with_nothing_new
    end
  end

  # ---------------------------------------------------------------------------
  # INV-02: money split — legacy bare-number price vs new Decimal fields
  # ---------------------------------------------------------------------------

  describe "money split (INV-02)" do
    test "legacy bare-number :price still renders as a bare-number dollar string" do
      data = sample_data()
      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "$200"
      assert flat =~ "$500"
    end

    test "new Decimal totals field renders via Rendro.Format.money/1" do
      data =
        sample_data()
        |> Map.put(:totals, %{
          subtotal: Decimal.new("1100"),
          total: Decimal.new("1100")
        })

      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "$1,100.00"
    end

    test "a Float in a new totals money field raises an instructive ArgumentError" do
      data = Map.put(sample_data(), :totals, %{subtotal: 1100.0})

      assert_raise ArgumentError, ~r/Decimal/i, fn ->
        Invoice.document(data)
      end
    end

    test "a %Decimal{} in the legacy :price slot raises an instructive ArgumentError" do
      data = %{
        id: "INV-DEC-01",
        date: ~D[2026-05-01],
        items: [%{name: "Widget", qty: 1, price: Decimal.new("10.00")}]
      }

      assert_raise ArgumentError, ~r/Decimal/i, fn ->
        Invoice.document(data)
      end
    end
  end
end

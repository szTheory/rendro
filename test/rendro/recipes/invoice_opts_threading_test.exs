defmodule Rendro.Recipes.InvoiceOptsThreadingTest do
  @moduledoc """
  TDD tests for Invoice.sections/2 opts threading (Phase 78 plan 03, D-10/D-11).

  Verifies that Invoice.sections/2 accepts a named `opts` parameter and
  forwards it to all section helpers (arity-2 heads), while preserving
  byte-identical default output (D-11).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-OPTS-01",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget X", qty: 2, price: 100}
      ]
    }
  end

  describe "Invoice.sections/2 opts threading" do
    test "sections/1 (no opts) returns a list of sections" do
      sections = Invoice.sections(sample_data())
      assert is_list(sections)
      assert length(sections) == 3
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 with empty opts returns identical result as sections/1" do
      sections_no_opts = Invoice.sections(sample_data())
      sections_empty_opts = Invoice.sections(sample_data(), [])
      assert sections_no_opts == sections_empty_opts
    end

    test "sections/2 with unknown opts does not crash and returns sections" do
      sections = Invoice.sections(sample_data(), unknown_opt: :ignored, another: :also_ignored)
      assert is_list(sections)
      assert length(sections) == 3
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 regions are :header, :body, :footer regardless of opts" do
      sections = Invoice.sections(sample_data(), some_opt: :value)
      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "sections/2 with empty opts keyword list does not crash" do
      sections = Invoice.sections(sample_data(), [])
      assert length(sections) == 3
    end
  end

  describe "page_template/1 opts whitelist (INV-07)" do
    test ":palette does not reach struct!(PageTemplate, ...) — no KeyError" do
      template = Invoice.page_template(palette: %{ink: {200, 0, 0}})
      assert %Rendro.PageTemplate{} = template
    end

    test ":formatters does not reach struct!(PageTemplate, ...) — no KeyError" do
      template =
        Invoice.page_template(formatters: [amount: fn %Decimal{} = d -> Decimal.to_string(d) end])

      assert %Rendro.PageTemplate{} = template
    end

    test "document/2 with :palette and :formatters opts does not raise" do
      doc = Invoice.document(sample_data(), palette: %{ink: {200, 0, 0}}, formatters: [])
      assert %Rendro.Document{} = doc
    end

    test "whitelisted keys (e.g. :name) still reach the template" do
      template = Invoice.page_template(name: :custom_invoice, palette: %{ink: {200, 0, 0}})
      assert template.name == :custom_invoice
    end
  end

  describe "palette(opts) seam (INV-07 / S1)" do
    test "a :palette override changes only the footer section's color" do
      data = sample_data()
      [header_default, body_default, footer_default] = Invoice.sections(data)

      [header_override, body_override, footer_override] =
        Invoice.sections(data, palette: %{ink: {200, 0, 0}})

      assert header_default == header_override,
             "header section (frozen toy path) must be unaffected by :palette"

      assert body_default == body_override,
             "body section (frozen toy path) must be unaffected by :palette"

      refute footer_default == footer_override,
             "footer section must change when :palette overrides :ink"
    end

    test "default palette (no override) renders byte-identically" do
      data = sample_data()
      assert Invoice.sections(data) == Invoice.sections(data, palette: %{})
    end
  end

  describe "Invoice :theme threading (PLUMB-02 swap)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Invoice.page_template(theme: Rendro.Theme.default())
    end

    test "a themed render differs from the no-theme render" do
      data = sample_data()
      refute Invoice.sections(data) == Invoice.sections(data, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Invoice.sections(data, theme: Rendro.Theme.default())

      overridden =
        Invoice.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200, 0, 0}})

      refute themed == overridden
    end

    test "no-theme sections(data) equals sections(data, []) (PLUMB-03)" do
      data = sample_data()
      assert Invoice.sections(data) == Invoice.sections(data, [])
    end
  end
end

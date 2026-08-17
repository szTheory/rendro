defmodule Rendro.CatalogTest do
  use ExUnit.Case, async: true

  alias Rendro.Catalog

  test "the default invoice catalog entry is a truthful deterministic source PDF" do
    [spec] = Catalog.catalog_specs()

    assert spec.id == "invoice--default--default--light"
    assert spec.fixture_ref == "invoice/acme-phoenix-saas/invoice.json"
    assert spec.brand == nil
    assert spec.preset == nil
    assert spec.accent == nil
    assert spec.theme == "default"
    assert spec.mode == "light"

    assert {:ok, first} = Catalog.render_source_pdf(spec)
    assert {:ok, second} = Catalog.render_source_pdf(spec)
    assert first == second
    assert byte_size(first) > 0
    assert first =~ "%PDF-"
  end

  test "catalog paths reject traversal before I/O" do
    assert_raise ArgumentError, ~r/unsafe catalog/, fn ->
      Catalog.source_document_for(%{id: "invoice--default--default--light", fixture_ref: "../secret.json"})
    end
  end

  test "the literal registry is the locked ordered 32-cell catalog" do
    expected_ids = ~w(
      invoice--default--default--light invoice--northline-logistics--swiss--light invoice--northline-logistics--swiss--dark invoice--cedar-mutual--corporate-classic--light invoice--cedar-mutual--corporate-classic--dark
      statement--default--default--light statement--signal-ledger--minimal-mono--light statement--signal-ledger--minimal-mono--dark statement--aster-research-fund--editorial--light statement--aster-research-fund--editorial--dark
      receipt--default--default--light receipt--poppy-and-grain--humanist--light receipt--poppy-and-grain--humanist--dark receipt--circuit-supply-co--minimal-mono--light receipt--circuit-supply-co--minimal-mono--dark
      certificate--default--default--light certificate--aster-institute--swiss--light certificate--aster-institute--swiss--dark certificate--meridian-arts-fellowship--editorial--light certificate--meridian-arts-fellowship--editorial--dark
      payslip--default--default--light payslip--northline-logistics--swiss--light payslip--northline-logistics--swiss--dark payslip--cedar-mutual--corporate-classic--light payslip--cedar-mutual--corporate-classic--dark
      ticket--default--default--light ticket--field-notes-conference--minimal-mono--light ticket--field-notes-conference--minimal-mono--dark ticket--the-letterpress-hall--editorial--light ticket--the-letterpress-hall--editorial--dark ticket--aurora-live--brutalist--light ticket--aurora-live--brutalist--dark
    )

    specs = Catalog.catalog_specs()
    assert Enum.map(specs, & &1.id) == expected_ids
    assert length(specs) == 32
    assert Catalog.catalog_contract_errors(specs) == []
    assert Enum.uniq(Enum.map(specs, & &1.png_path)) |> length() == 32

    assert Enum.any?(Catalog.catalog_contract_errors(Enum.take(specs, 31)), &String.contains?(&1, "exactly 32"))
    errors = Catalog.catalog_contract_errors(specs ++ [List.last(specs)])
    assert Enum.any?(errors, &String.contains?(&1, "exactly 32"))
    assert Enum.any?(errors, &String.contains?(&1, "ceiling"))
  end
end

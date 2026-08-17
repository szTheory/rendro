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
end

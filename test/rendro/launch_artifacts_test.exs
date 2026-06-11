defmodule Rendro.LaunchArtifactsTest do
  use ExUnit.Case, async: true

  @styled_fixture_ids ~w(invoice branded_invoice statement receipt_report)

  describe "source document fixtures" do
    test "launch table polish is explicit on table-backed gallery documents" do
      for id <- @styled_fixture_ids do
        doc = Rendro.LaunchArtifacts.source_document_for(%{id: id})
        tables = collect_tables(doc)

        assert tables != []

        if id in ~w(statement receipt_report) do
          assert length(tables) > 1
        end

        for table <- tables do
          assert table.borders == [:outer, :rows]
          assert table.header_fill == {247, 243, 234}
          assert table.border_style.color == {216, 210, 195}
          assert table.border_style.width == 0.6
        end
      end
    end

    test "render_source_pdf renders every curated source fixture" do
      for id <- @styled_fixture_ids ++ ["certificate"] do
        assert {:ok, <<"%PDF-", _rest::binary>>} =
                 Rendro.LaunchArtifacts.render_source_pdf(%{id: id})
      end
    end

    test "branded invoice keeps brand font, logo, and readable header blocks" do
      doc = Rendro.LaunchArtifacts.source_document_for(%{id: "branded_invoice"})

      assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
      assert Map.has_key?(doc.asset_registry.assets, :company_logo)

      header = Enum.find(doc.sections, &(&1.name == :branded_invoice_header))
      assert header

      header_texts =
        header.content
        |> Enum.map(&text_content/1)
        |> Enum.reject(&is_nil/1)

      assert "Rendro, Inc." in header_texts
      assert "Invoice #BR-2026-001" in header_texts
      assert "Date: 2026-06-11" in header_texts
    end

    test "certificate fixture keeps the Path-backed frame and does not require table polish" do
      doc = Rendro.LaunchArtifacts.source_document_for(%{id: "certificate"})

      assert Enum.any?(doc.sections, &(&1.region == :frame or &1.name == :certificate_frame))
      assert collect_tables(doc) == []
    end
  end

  test "canonical recipe defaults remain unchanged" do
    doc =
      Rendro.Recipes.Invoice.document(%{
        id: "INV-DEFAULT",
        date: ~D[2026-06-11],
        items: [
          %{name: "Default Row", qty: 1, price: 100}
        ]
      })

    tables = collect_tables(doc)
    assert length(tables) == 1

    for table <- tables do
      assert table.borders in [:none, []]
      assert table.header_fill == nil
      assert table.border_style == nil
    end
  end

  defp collect_tables(%Rendro.Document{sections: sections}) do
    Enum.flat_map(sections, &collect_tables/1)
  end

  defp collect_tables(%Rendro.Section{content: content}) do
    Enum.flat_map(content, &collect_tables/1)
  end

  defp collect_tables(%Rendro.Block{content: %Rendro.Table{} = table}), do: [table]
  defp collect_tables(_other), do: []

  defp text_content(%Rendro.Block{content: %Rendro.Text{content: content}}), do: content
  defp text_content(_other), do: nil
end

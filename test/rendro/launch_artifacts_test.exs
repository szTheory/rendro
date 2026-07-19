defmodule Rendro.LaunchArtifactsTest do
  use ExUnit.Case, async: true

  @styled_fixture_ids ~w(invoice branded_invoice statement receipt_report)

  describe "source document fixtures" do
    test "launch table polish is explicit on table-backed gallery documents" do
      for id <- @styled_fixture_ids do
        doc = Rendro.LaunchArtifacts.source_document_for(%{id: id})
        tables = collect_tables(doc)

        assert tables != []

        for table <- tables do
          assert table.borders == [:outer, :rows]
          assert table.header_fill == {247, 243, 234}
          assert table.border_style.color == {216, 210, 195}
          assert table.border_style.width == 0.6
        end
      end
    end

    test "render_source_pdf renders every curated source fixture" do
      for id <- @styled_fixture_ids ++ ~w(certificate payslip ticket) do
        assert {:ok, <<"%PDF-", _rest::binary>>} =
                 Rendro.LaunchArtifacts.render_source_pdf(%{id: id})
      end
    end

    test "payslip tile is sourced from the payslip fixture (D-07)" do
      doc = Rendro.LaunchArtifacts.source_document_for(%{id: "payslip"})
      texts = all_texts(doc)

      # Realistic employer + earnings line from priv/examples/payslip fixture.
      assert Enum.any?(texts, &(&1 =~ "Aurora Live"))
      assert Enum.any?(texts, &(&1 =~ "Base Salary"))
    end

    test "ticket tile is sourced from the ticket fixture (D-07)" do
      doc = Rendro.LaunchArtifacts.source_document_for(%{id: "ticket"})
      texts = all_texts(doc)

      # Realistic event title + reference code from priv/examples/ticket fixture.
      assert Enum.any?(texts, &(&1 =~ "Indie Night"))
      assert Enum.any?(texts, &(&1 =~ "AUR-88213-GA"))
    end

    test "gallery has exactly seven tiles in the fixed order (D-07)" do
      assert Enum.map(Rendro.LaunchArtifacts.gallery_specs(), & &1.id) == [
               "invoice",
               "branded_invoice",
               "statement",
               "receipt_report",
               "certificate",
               "payslip",
               "ticket"
             ]
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

      for %Rendro.Block{content: %Rendro.Text{} = text} <- header.content do
        assert text.font == Rendro.Text.default_font()
      end
    end

    test "certificate fixture keeps the Path-backed frame and does not require table polish" do
      doc = Rendro.LaunchArtifacts.source_document_for(%{id: "certificate"})

      assert Enum.any?(doc.sections, &(&1.region == :frame or &1.name == :certificate_frame))
      assert collect_tables(doc) == []
    end

    test "tiles are sourced from the realistic priv/examples fixtures (D-06)" do
      # Invoice fixture line items carry the fixture's realistic descriptions
      # (never the old toy "Implementation Sprint" rows).
      invoice = Rendro.LaunchArtifacts.source_document_for(%{id: "invoice"})
      cells = invoice |> collect_tables() |> Enum.flat_map(& &1.rows) |> List.flatten()
      assert Enum.any?(cells, &(is_binary(&1) and &1 =~ "Monthly platform service"))
      refute Enum.any?(cells, &(is_binary(&1) and &1 =~ "Implementation Sprint"))

      # Certificate body text comes from the realistic fixture recipient/body.
      certificate = Rendro.LaunchArtifacts.source_document_for(%{id: "certificate"})

      cert_texts =
        certificate.sections
        |> Enum.flat_map(& &1.content)
        |> Enum.map(&text_content/1)
        |> Enum.reject(&is_nil/1)

      assert "Alex Rivera" in cert_texts
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

  defp all_texts(%Rendro.Document{sections: sections}) do
    sections
    |> Enum.flat_map(&collect_texts/1)
    |> Enum.reject(&is_nil/1)
  end

  defp collect_texts(%Rendro.Section{content: content}), do: Enum.flat_map(content, &collect_texts/1)
  defp collect_texts(%Rendro.Block{content: %Rendro.Text{content: content}}), do: [content]

  defp collect_texts(%Rendro.Block{content: %Rendro.Table{} = table}) do
    [table.header | table.rows]
    |> List.flatten()
    |> Enum.filter(&is_binary/1)
  end

  defp collect_texts(_other), do: []
end

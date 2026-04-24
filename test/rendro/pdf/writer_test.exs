defmodule Rendro.PDF.WriterTest do
  use ExUnit.Case, async: true

  alias Rendro.PDF.Writer

  defp sample_document do
    text = %Rendro.Text{content: "Hello, Rendro!", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 0, y: 0}
    page = %Rendro.Page{blocks: [block]}

    %Rendro.Document{
      pages: [page],
      metadata: %Rendro.Metadata{title: "Test Document", author: "Rendro"}
    }
  end

  describe "render/1" do
    test "returns {:ok, binary} tuple" do
      doc = sample_document()
      assert {:ok, pdf} = Writer.render(doc)
      assert is_binary(pdf)
    end

    test "starts with PDF 1.4 header" do
      {:ok, pdf} = Writer.render(sample_document())
      assert String.starts_with?(pdf, "%PDF-1.4")
    end

    test "ends with %%EOF" do
      {:ok, pdf} = Writer.render(sample_document())
      assert String.ends_with?(String.trim(pdf), "%%EOF")
    end

    test "contains xref section" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "xref\n"
      assert pdf =~ "startxref\n"
    end

    test "contains trailer with Root and Info" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "trailer"
      assert pdf =~ "/Root"
      assert pdf =~ "/Info"
    end

    test "contains Catalog object" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "/Type /Catalog"
    end

    test "contains Pages object" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "/Type /Pages"
      assert pdf =~ "/Count 1"
    end

    test "contains Page object with MediaBox" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "/Type /Page"
      assert pdf =~ "/MediaBox"
    end

    test "contains font reference" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "/BaseFont /Helvetica"
      assert pdf =~ "/Type /Font"
      assert pdf =~ "/Subtype /Type1"
    end

    test "contains text content with Tf/Td/Tj operators" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "/F1"
      assert pdf =~ "Tf"
      assert pdf =~ "Td"
      assert pdf =~ "(Hello, Rendro!) Tj"
    end

    test "content stream has BT/ET markers" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "BT"
      assert pdf =~ "ET"
    end

    test "xref entries have correct 20-byte format" do
      {:ok, pdf} = Writer.render(sample_document())
      xref_section = pdf |> String.split("xref\n") |> List.last() |> String.split("trailer") |> hd()

      xref_section
      |> String.split("\n")
      |> Enum.reject(&(&1 == "" || &1 =~ ~r/^\d+ \d+$/))
      |> Enum.each(fn line ->
        assert String.length(String.trim_trailing(line)) == 18,
               "xref entry not 18 chars (before line ending): #{inspect(line)}"
      end)
    end

    test "renders document with metadata" do
      {:ok, pdf} = Writer.render(sample_document())
      assert pdf =~ "(Test Document)"
      assert pdf =~ "(Rendro)"
      assert pdf =~ "/Producer (Rendro)"
    end

    test "renders document with no metadata" do
      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, pdf} = Writer.render(doc)
      assert pdf =~ "%PDF-1.4"
    end

    test "renders multiple pages" do
      text1 = %Rendro.Text{content: "Page One", font: "Helvetica", size: 12, color: {0, 0, 0}}
      text2 = %Rendro.Text{content: "Page Two", font: "Helvetica", size: 12, color: {0, 0, 0}}
      block1 = %Rendro.Block{content: text1, x: 0, y: 0}
      block2 = %Rendro.Block{content: text2, x: 0, y: 0}

      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: [block1]}, %Rendro.Page{blocks: [block2]}],
        metadata: %Rendro.Metadata{}
      }

      {:ok, pdf} = Writer.render(doc)
      assert pdf =~ "/Count 2"
      assert pdf =~ "(Page One)"
      assert pdf =~ "(Page Two)"
    end

    test "positions text respecting margins and PDF coordinate system" do
      text = %Rendro.Text{content: "Positioned", font: "Helvetica", size: 14, color: {0, 0, 0}}
      block = %Rendro.Block{content: text, x: 10, y: 20}

      page = %Rendro.Page{
        blocks: [block],
        width: 612,
        height: 792,
        margin_left: 72,
        margin_top: 72
      }

      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}
      {:ok, pdf} = Writer.render(doc)

      expected_x = 10 + 72
      expected_y = 792 - 20 - 72 - 14

      assert pdf =~ "#{:erlang.float_to_binary(expected_x * 1.0, decimals: 4)} #{:erlang.float_to_binary(expected_y * 1.0, decimals: 4)} Td"
    end

    test "applies text color as rg operator" do
      text = %Rendro.Text{content: "Red", font: "Helvetica", size: 12, color: {255, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      {:ok, pdf} = Writer.render(doc)
      assert pdf =~ "1.0000 0.0000 0.0000 rg"
    end
  end
end

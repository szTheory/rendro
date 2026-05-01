defmodule Rendro.PDF.WriterTest do
  use ExUnit.Case, async: true

  alias Rendro.PDF.{Font, Writer}
  alias Rendro.Pipeline.MeasuredText
  alias Rendro.TestSupport.FontFixture

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
      assert pdf =~ "/F_DEFAULT"
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

      [_, xref_section] = Regex.run(~r/\nxref\n(.*?)\ntrailer\n/s, pdf)

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

      assert pdf =~ "#{expected_x} #{expected_y} Td"
    end

    test "applies text color as rg operator" do
      text = %Rendro.Text{content: "Red", font: "Helvetica", size: 12, color: {255, 0, 0}}
      block = %Rendro.Block{content: text, x: 0, y: 0}
      page = %Rendro.Page{blocks: [block]}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      {:ok, pdf} = Writer.render(doc)
      assert pdf =~ "1.0000 0.0000 0.0000 rg"
    end

    test "serializes measured wrapped lines as separate text operations" do
      source = Rendro.text("alpha beta gamma", size: 12, line_height: 1.5)

      measured =
        %MeasuredText{
          source: source,
          lines: [
            [%{text: "alpha beta", font: Font.helvetica(), width: 60}],
            [%{text: "gamma", font: Font.helvetica(), width: 30}]
          ],
          line_height: source.line_height,
          width: 60,
          height: 36,
          resolved_font: Font.helvetica()
        }

      block = %Rendro.Block{content: measured, x: 10, y: 20, width: 60, height: 36}

      page = %Rendro.Page{
        blocks: [block],
        width: 612,
        height: 792,
        margin_left: 72,
        margin_top: 72
      }

      {:ok, pdf} = Writer.render(%Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}})

      assert pdf =~ "(alpha beta) Tj"
      assert pdf =~ "(gamma) Tj"
      assert length(Regex.scan(~r/\) Tj/, pdf)) == 2
      assert pdf =~ "0 -18.0000 Td"
      refute pdf =~ "(alpha beta gamma) Tj"
    end

    test "renders a registered logical font through the shared font resource name" do
      doc =
        Rendro.document()
        |> Rendro.register_font(:heading, built_in: :helvetica)
        |> Map.put(:pages, [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: Rendro.text("Heading", font: :heading), x: 0, y: 0}
            ]
          }
        ])

      {:ok, pdf} = Writer.render(doc)

      assert pdf =~ "/F_HEADING"
      assert pdf =~ "/BaseFont /Helvetica"
      assert pdf =~ "(Heading) Tj"
    end

    test "embeds a supported custom font through explicit PDF font objects" do
      %{bytes: bytes} = FontFixture.supported_font()

      doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})
        |> Map.put(:pages, [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: Rendro.text("Brand heading", font: :brand), x: 0, y: 0}
            ]
          }
        ])

      assert {:ok, pdf} = Writer.render(doc, deterministic: true)

      assert pdf =~ "/F_BRAND"
      assert pdf =~ "/Subtype /TrueType"
      assert pdf =~ "/FontDescriptor"
      assert pdf =~ "/FontFile2"
      assert pdf =~ "/Encoding /WinAnsiEncoding"
      assert pdf =~ "(Brand heading) Tj"
      refute pdf =~ "/BaseFont /Helvetica"
    end

    test "fails for an invalid explicit embedded font instead of falling back to a built-in face" do
      doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, "not-a-font"})
        |> Map.put(:pages, [
          %Rendro.Page{
            blocks: [
              %Rendro.Block{content: Rendro.text("Brand heading", font: :brand), x: 0, y: 0}
            ]
          }
        ])

      assert {:error, {:invalid_embedded_font, %{logical_name: :brand, reason: :unsupported_font_format}}} =
               Writer.render(doc)
    end
  end

  describe "render/2 deterministic mode" do
    test "two renders produce identical binaries" do
      doc = sample_document()
      {:ok, pdf1} = Writer.render(doc, deterministic: true)
      {:ok, pdf2} = Writer.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "includes fixed epoch timestamps" do
      doc = sample_document()
      {:ok, pdf} = Writer.render(doc, deterministic: true)
      assert pdf =~ "(D:20000101000000Z)"
    end

    test "includes deterministic trailer ID" do
      doc = sample_document()
      {:ok, pdf} = Writer.render(doc, deterministic: true)
      assert pdf =~ "/ID"
    end

    test "trailer ID is content-derived and stable" do
      doc = sample_document()
      {:ok, pdf1} = Writer.render(doc, deterministic: true)
      {:ok, pdf2} = Writer.render(doc, deterministic: true)

      extract_id = fn pdf ->
        [_, after_id] = String.split(pdf, "/ID", parts: 2)
        after_id |> String.split(">>", parts: 2) |> hd()
      end

      assert extract_id.(pdf1) == extract_id.(pdf2)
    end

    test "non-deterministic mode does not include fixed timestamps" do
      doc = sample_document()
      {:ok, pdf} = Writer.render(doc)
      refute pdf =~ "(D:20000101000000Z)"
    end

    test "non-deterministic mode does not include trailer ID" do
      doc = sample_document()
      {:ok, pdf} = Writer.render(doc)
      refute pdf =~ "/ID"
    end

    test "deterministic mode sorts dictionary keys" do
      doc = sample_document()
      {:ok, pdf} = Writer.render(doc, deterministic: true)

      assert pdf =~ "/Type /Catalog"
      assert pdf =~ "/Pages"
    end

    test "deterministic mode with metadata dates normalizes them" do
      now = DateTime.utc_now()

      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{
          title: "Dated Doc",
          creation_date: now,
          modification_date: now
        }
      }

      {:ok, pdf} = Writer.render(doc, deterministic: true)
      assert pdf =~ "(D:20000101000000Z)"
      refute pdf =~ Calendar.strftime(now, "D:%Y%m%d")
    end

    test "non-deterministic mode with metadata dates includes real dates" do
      now = ~U[2025-06-15 10:30:00Z]

      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{
          title: "Dated Doc",
          creation_date: now,
          modification_date: now
        }
      }

      {:ok, pdf} = Writer.render(doc)
      assert pdf =~ "(D:20250615103000Z)"
    end
  end
end

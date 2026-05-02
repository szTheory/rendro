defmodule Rendro.PDF.FontTest do
  use ExUnit.Case, async: true

  alias Rendro.FontRegistry
  alias Rendro.PDF.Font
  alias Rendro.Pipeline.Build
  alias Rendro.TestSupport.FontFixture

  describe "helvetica/0" do
    test "returns a Font struct with Helvetica" do
      font = Font.helvetica()
      assert %Font{} = font
      assert font.name == "F1"
      assert font.base_font == "Helvetica"
      assert is_map(font.widths)
      assert map_size(font.widths) > 0
    end

    test "has widths for printable ASCII range" do
      font = Font.helvetica()

      for char <- 32..126 do
        assert Map.has_key?(font.widths, char),
               "Missing width for codepoint #{char} (#{<<char::utf8>>})"
      end
    end
  end

  describe "text_width/3" do
    test "returns width in points for given font size" do
      font = Font.helvetica()
      width = Font.text_width(font, "Hello", 12)
      assert is_float(width)
      assert width > 0
    end

    test "empty string has zero width" do
      font = Font.helvetica()
      assert Font.text_width(font, "", 12) == 0.0
    end

    test "width scales linearly with font size" do
      font = Font.helvetica()
      w12 = Font.text_width(font, "Test", 12)
      w24 = Font.text_width(font, "Test", 24)
      assert_in_delta w24, w12 * 2, 0.001
    end

    test "space has non-zero width" do
      font = Font.helvetica()
      width = Font.text_width(font, " ", 12)
      assert width > 0
    end
  end

  describe "logical font resolution" do
    test "resolves a registered logical font through the shared built-in registry contract" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register(:body, built_in: :helvetica)

      assert {:ok, %{source: :built_in, family: :helvetica} = descriptor} =
               FontRegistry.resolve(registry, :body, :default)

      assert %Font{base_font: "Helvetica"} = FontRegistry.built_in(descriptor)
    end

    test "maps the Helvetica compatibility alias through the document default font" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register(:body, built_in: :helvetica)

      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.resolve(registry, "Helvetica", :body)
    end

    test "build fails explicitly for an unknown logical font reference" do
      doc =
        %Rendro.Document{
          pages: [
            %Rendro.Page{
              blocks: [
                Rendro.block(Rendro.text("Missing font", font: :heading))
              ]
            }
          ],
          metadata: %Rendro.Metadata{}
        }

      assert {:error, {:unknown_text_font, :heading}} = Build.run(doc)
    end

    test "preflights an embedded TrueType font into shared metrics data" do
      %{bytes: bytes} = FontFixture.supported_font()

      registry =
        FontRegistry.new()
        |> FontRegistry.register_embedded(:brand, {:binary, bytes})

      assert {:ok, preflighted} = FontRegistry.preflight(registry)
      assert {:ok, descriptor} = FontRegistry.fetch(preflighted, :brand)

      assert %{source: :embedded, source_kind: :binary, pdf_font: %Font{} = font} = descriptor
      assert font.source == :embedded
      assert font.embedded? == true
      assert font.source_kind == :binary
      assert font.units_per_em > 0
      assert font.default_width > 0
      assert map_size(font.widths) > 0
      assert Font.text_width(font, "Hello", 12) > 0
    end

    test "preflight rejects unsupported embedded font data with typed details" do
      registry =
        FontRegistry.new()
        |> FontRegistry.register_embedded(:brand, {:binary, "not-a-font"})

      assert {:error,
              {:invalid_embedded_font,
               %{logical_name: :brand, source_kind: :binary, reason: :unsupported_font_format}}} =
               FontRegistry.preflight(registry)
    end

    test "build rejects non-embeddable explicit fonts before render begins" do
      %{bytes: bytes} = FontFixture.supported_font()

      doc =
        Rendro.document(
          pages: [
            Rendro.page(blocks: [Rendro.block(Rendro.text("Restricted", font: :brand))])
          ]
        )
        |> Rendro.register_embedded_font(:brand, {:binary, FontFixture.restricted_font(bytes)})

      assert {:error,
              {:invalid_embedded_font,
               %{logical_name: :brand, source_kind: :binary, reason: :non_embeddable_font}}} =
               Build.run(doc)

      assert {:error, %Rendro.Error{stage: :build, reason: {:invalid_embedded_font, _details}}} =
               Rendro.render(doc)
    end
  end
end

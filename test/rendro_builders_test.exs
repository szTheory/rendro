defmodule RendroBuildersTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, Metadata, Page, PageTemplate, Region, Section, Table, Text}
  alias Rendro.FontRegistry.EmbeddedFontFamilyError

  describe "builder functions" do
    test "text/2 builds a Text struct" do
      text = Rendro.text("hello")
      assert %Text{content: "hello", font: "Helvetica"} = text
    end

    test "text/2 accepts logical font attribute overrides" do
      text = Rendro.text("bold", font: :heading, size: 18, line_height: 1.5)
      assert text.font == :heading
      assert text.size == 18
      assert text.line_height == 1.5
    end

    test "text/2 keeps the narrow Helvetica compatibility path" do
      text = Rendro.text("compat", font: "helvetica")
      assert text.font == "Helvetica"
    end

    test "text/2 rejects arbitrary string font escape hatches" do
      assert_raise ArgumentError,
                   ~r/only supports logical font atoms or the narrow Helvetica compatibility aliases/,
                   fn ->
                     Rendro.text("bold", font: "Courier")
                   end
    end

    test "block/2 builds a Block with content" do
      text = Rendro.text("hello")
      block = Rendro.block(text, x: 10, y: 20, keep_together: true, break_before: true)
      assert %Block{content: ^text, x: 10, y: 20} = block
      assert block.keep_together
      assert block.break_before
    end

    test "block/2 requires content argument" do
      refute function_exported?(Rendro, :block, 0)
    end

    test "page/1 builds a Page struct" do
      page = Rendro.page(width: 612, height: 792)
      assert %Page{width: 612, height: 792} = page
    end

    test "page/1 with defaults" do
      page = Rendro.page()
      assert page.width == 595.28
      assert page.height == 841.89
    end

    test "page_template/1 builds a PageTemplate struct" do
      template = Rendro.page_template(name: :invoice)
      assert %PageTemplate{name: :invoice} = template
      assert Enum.map(template.regions, & &1.name) == [:header, :body, :footer]
    end

    test "region/1 builds a Region struct" do
      region = Rendro.region(name: :sidebar, role: :sidebar, anchor: :fixed, x: 24, y: 48)
      assert %Region{name: :sidebar, role: :sidebar, anchor: :fixed, x: 24, y: 48} = region
    end

    test "section/1 builds a Section struct" do
      block = Rendro.block(Rendro.text("Summary"))

      section =
        Rendro.section(name: :summary, region: :body, content: [block], page_template: :invoice)

      assert %Section{name: :summary, region: :body, content: [^block], page_template: :invoice} =
               section
    end

    test "document/1 builds a Document struct" do
      doc = Rendro.document()
      assert %Document{pages: [], metadata: %Metadata{}} = doc
    end

    test "register_font/3 and put_default_font/2 wrap the document font registry API" do
      doc =
        Rendro.document()
        |> Rendro.register_font(:heading, built_in: :helvetica)
        |> Rendro.put_default_font(:heading)

      assert doc.default_font == :heading
      assert doc.font_registry.default_font == :heading
      assert doc.font_registry.fonts.heading == %{source: :built_in, family: :helvetica}
    end

    test "register_embedded_font/3 wraps document embedded-font registration" do
      bytes = <<5, 4, 3, 2, 1>>

      doc =
        Rendro.document()
        |> Rendro.register_embedded_font(:brand, {:binary, bytes})

      assert doc.font_registry.fonts.brand.source == :embedded
      assert doc.font_registry.fonts.brand.source_kind == :binary
      assert doc.font_registry.fonts.brand.source_data.bytes == bytes
    end

    test "register_embedded_font_family/3 registers all four narrow variants explicitly" do
      bytes = <<9, 8, 7>>

      doc =
        Rendro.document()
        |> Rendro.register_embedded_font_family(:brand, %{
          regular: {:binary, bytes},
          bold: {:binary, bytes},
          italic: {:binary, bytes},
          bold_italic: {:binary, bytes}
        })

      assert Map.has_key?(doc.font_registry.fonts, :brand)
      assert Map.has_key?(doc.font_registry.fonts, :brand_bold)
      assert Map.has_key?(doc.font_registry.fonts, :brand_italic)
      assert Map.has_key?(doc.font_registry.fonts, :brand_bold_italic)
      assert doc.font_registry.fonts.brand_bold.variant == :bold
    end

    test "register_embedded_font_family/3 exposes missing variant details" do
      error =
        assert_raise EmbeddedFontFamilyError, fn ->
          Rendro.document()
          |> Rendro.register_embedded_font_family(:brand, %{
            regular: {:binary, <<1>>},
            italic: {:binary, <<2>>},
            bold_italic: {:binary, <<3>>}
          })
        end

      assert error.family_name == :brand
      assert error.missing_variants == [:bold]
      assert error.provided_kinds == %{regular: :binary, italic: :binary, bold_italic: :binary}
    end

    test "flow/2 carries explicit template and section data" do
      section =
        Rendro.section(name: :summary, content: [Rendro.block(Rendro.text("Section body"))])

      template = Rendro.page_template(name: :invoice)
      content = [Rendro.block(Rendro.text("Intro"))]

      doc =
        Rendro.flow(
          content,
          page_template: :invoice,
          page_templates: [template],
          sections: [section]
        )

      assert doc.content == content
      assert doc.page_template == :invoice
      assert doc.page_templates == [template]
      assert doc.sections == [section]
    end

    test "metadata/1 builds a Metadata struct" do
      meta = Rendro.metadata(title: "Test", author: "Agent")
      assert %Metadata{title: "Test", author: "Agent"} = meta
    end

    test "table/2 builds a Table struct with canonical row-atomic split policy" do
      table = Rendro.table([["1"]], columns: [{:fixed, 100}], split_policy: :row_atomic)
      assert %Table{rows: [["1"]], columns: [{:fixed, 100}], split_policy: :row_atomic} = table
    end

    test "table/2 normalizes the temporary :atomic split-policy alias" do
      table = Rendro.table([["1"]], columns: [{:fixed, 100}], split_policy: :atomic)
      assert %Table{rows: [["1"]], columns: [{:fixed, 100}], split_policy: :row_atomic} = table
    end

    test "table/2 rejects unsupported split_policy values explicitly" do
      assert_raise ArgumentError,
                   ~r/only supports split_policy: :row_atomic \(or temporary alias :atomic\); got: :whole_table/,
                   fn ->
                     Rendro.table([["1"]], columns: [{:fixed, 100}], split_policy: :whole_table)
                   end
    end

    test "table/2 rejects removed fields like width and border" do
      assert_raise ArgumentError, ~r/no longer supports :width or :border/, fn ->
        Rendro.table([["1"]], width: :fill)
      end

      assert_raise ArgumentError, ~r/no longer supports :width or :border/, fn ->
        Rendro.table([["1"]], border: true)
      end
    end

    test "builders reject unknown keys via struct!" do
      assert_raise KeyError, fn ->
        Rendro.text("hello", bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.page(bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.page_template(bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.region(bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.section(bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.document(bogus: true)
      end
    end
  end

  describe "nested document building" do
    test "builds a complete document tree" do
      doc =
        Rendro.document(
          pages: [
            Rendro.page(
              blocks: [
                Rendro.block(
                  Rendro.text("Hello, World!", font: "Helvetica", size: 24),
                  x: 72,
                  y: 700
                ),
                Rendro.block(
                  Rendro.text("Body text here."),
                  x: 72,
                  y: 650
                )
              ]
            )
          ],
          metadata: Rendro.metadata(title: "Test Doc", author: "Test"),
          options: %{deterministic: true}
        )

      assert length(doc.pages) == 1

      [page] = doc.pages
      assert length(page.blocks) == 2

      [header, body] = page.blocks
      assert header.content.content == "Hello, World!"
      assert header.content.size == 24
      assert header.x == 72
      assert header.y == 700

      assert body.content.content == "Body text here."
      assert body.content.font == "Helvetica"

      assert doc.metadata.title == "Test Doc"
      assert doc.options.deterministic == true
    end

    test "builds multi-page document" do
      doc =
        Rendro.document(
          pages: [
            Rendro.page(blocks: [Rendro.block(Rendro.text("Page 1"))]),
            Rendro.page(blocks: [Rendro.block(Rendro.text("Page 2"))])
          ]
        )

      assert length(doc.pages) == 2
      [p1, p2] = doc.pages
      [b1] = p1.blocks
      [b2] = p2.blocks
      assert b1.content.content == "Page 1"
      assert b2.content.content == "Page 2"
    end
  end

  describe "pure data — no side effects" do
    test "struct creation is pure and repeatable" do
      a = Rendro.document(pages: [Rendro.page()])
      b = Rendro.document(pages: [Rendro.page()])
      assert a == b
    end

    test "layout builders are deterministic" do
      a = Rendro.page_template()
      b = Rendro.page_template()
      assert a == b
    end

    test "structs are plain maps" do
      doc = Rendro.document()
      assert is_map(doc)
      assert Map.has_key?(doc, :__struct__)
      assert doc.__struct__ == Document
    end
  end
end

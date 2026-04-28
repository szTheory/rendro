defmodule RendroBuildersTest do
  use ExUnit.Case, async: true

  alias Rendro.{Block, Document, Metadata, Page, Text}

  describe "builder functions" do
    test "text/2 builds a Text struct" do
      text = Rendro.text("hello")
      assert %Text{content: "hello", font: "Helvetica"} = text
    end

    test "text/2 accepts attribute overrides" do
      text = Rendro.text("bold", font: "Courier", size: 18)
      assert text.font == "Courier"
      assert text.size == 18
    end

    test "block/2 builds a Block with content" do
      text = Rendro.text("hello")
      block = Rendro.block(text, x: 10, y: 20)
      assert %Block{content: ^text, x: 10, y: 20} = block
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

    test "document/1 builds a Document struct" do
      doc = Rendro.document()
      assert %Document{pages: [], metadata: %Metadata{}} = doc
    end

    test "metadata/1 builds a Metadata struct" do
      meta = Rendro.metadata(title: "Test", author: "Agent")
      assert %Metadata{title: "Test", author: "Agent"} = meta
    end

    test "builders reject unknown keys via struct!" do
      assert_raise KeyError, fn ->
        Rendro.text("hello", bogus: true)
      end

      assert_raise KeyError, fn ->
        Rendro.page(bogus: true)
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

    test "structs are plain maps" do
      doc = Rendro.document()
      assert is_map(doc)
      assert Map.has_key?(doc, :__struct__)
      assert doc.__struct__ == Document
    end
  end
end

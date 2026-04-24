defmodule Rendro.IntegrationTest do
  use ExUnit.Case, async: true

  @tmp_dir "tmp/test_pdfs"

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  defp single_page_doc do
    text = Rendro.text("Hello, Rendro!", size: 16)
    block = Rendro.block(text, x: 72, y: 72)
    page = Rendro.page(blocks: [block])
    Rendro.document(pages: [page], metadata: Rendro.metadata(title: "Single Page"))
  end

  defp multi_page_doc do
    page1 =
      Rendro.page(
        blocks: [Rendro.block(Rendro.text("First Page", size: 24), x: 72, y: 72)]
      )

    page2 =
      Rendro.page(
        blocks: [Rendro.block(Rendro.text("Second Page", size: 24), x: 72, y: 72)]
      )

    page3 =
      Rendro.page(
        blocks: [Rendro.block(Rendro.text("Third Page", size: 18), x: 72, y: 144)]
      )

    Rendro.document(
      pages: [page1, page2, page3],
      metadata: Rendro.metadata(title: "Multi Page", author: "Test Suite")
    )
  end

  describe "Rendro.render/1" do
    test "renders a single-page document" do
      doc = single_page_doc()
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
      assert byte_size(pdf) > 0
    end

    test "renders a multi-page document" do
      doc = multi_page_doc()
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "PDF binary starts with %PDF-1.4 header" do
      {:ok, pdf} = Rendro.render(single_page_doc())
      assert String.starts_with?(pdf, "%PDF-1.4")
    end

    test "PDF binary ends with %%EOF" do
      {:ok, pdf} = Rendro.render(single_page_doc())
      assert String.ends_with?(String.trim(pdf), "%%EOF")
    end

    test "PDF contains expected text strings" do
      {:ok, pdf} = Rendro.render(single_page_doc())
      assert pdf =~ "(Hello, Rendro!)"
    end

    test "multi-page PDF contains text from all pages" do
      {:ok, pdf} = Rendro.render(multi_page_doc())
      assert pdf =~ "(First Page)"
      assert pdf =~ "(Second Page)"
      assert pdf =~ "(Third Page)"
    end

    test "multi-page PDF has correct page count" do
      {:ok, pdf} = Rendro.render(multi_page_doc())
      assert pdf =~ "/Count 3"
    end

    test "returns error for document with no pages" do
      doc = Rendro.document(pages: [])
      assert {:error, _reason} = Rendro.render(doc)
    end

    test "renders document with metadata" do
      {:ok, pdf} = Rendro.render(single_page_doc())
      assert pdf =~ "(Single Page)"
      assert pdf =~ "/Producer (Rendro)"
    end

    test "contains valid PDF structure" do
      {:ok, pdf} = Rendro.render(single_page_doc())
      assert pdf =~ "/Type /Catalog"
      assert pdf =~ "/Type /Pages"
      assert pdf =~ "/Type /Page"
      assert pdf =~ "xref"
      assert pdf =~ "trailer"
      assert pdf =~ "startxref"
    end
  end

  describe "Rendro.render/2 with :output option" do
    test "writes PDF to file and returns binary" do
      doc = single_page_doc()
      path = Path.join(@tmp_dir, "output.pdf")

      assert {:ok, pdf} = Rendro.render(doc, output: path)
      assert is_binary(pdf)
      assert File.exists?(path)
      assert File.read!(path) == pdf
    end

    test "creates parent directories for output path" do
      doc = single_page_doc()
      path = Path.join([@tmp_dir, "nested", "dir", "output.pdf"])

      assert {:ok, _pdf} = Rendro.render(doc, output: path)
      assert File.exists?(path)
    end

    test "written file starts with %PDF-1.4" do
      doc = single_page_doc()
      path = Path.join(@tmp_dir, "header_check.pdf")

      Rendro.render(doc, output: path)
      content = File.read!(path)
      assert String.starts_with?(content, "%PDF-1.4")
    end

    test "written file has non-zero size" do
      doc = single_page_doc()
      path = Path.join(@tmp_dir, "size_check.pdf")

      Rendro.render(doc, output: path)
      %{size: size} = File.stat!(path)
      assert size > 0
    end
  end

  describe "Rendro.render/2 without :output option" do
    test "behaves like render/1" do
      doc = single_page_doc()
      assert {:ok, pdf1} = Rendro.render(doc)
      assert {:ok, pdf2} = Rendro.render(doc, [])
      assert pdf1 == pdf2
    end
  end

  describe "write PDF to tmp for manual inspection" do
    test "single-page PDF is a valid file" do
      path = Path.join(@tmp_dir, "single_page.pdf")
      {:ok, pdf} = Rendro.render(single_page_doc())
      File.write!(path, pdf)

      assert File.exists?(path)
      %{size: size} = File.stat!(path)
      assert size > 100
    end

    test "multi-page PDF is a valid file" do
      path = Path.join(@tmp_dir, "multi_page.pdf")
      {:ok, pdf} = Rendro.render(multi_page_doc())
      File.write!(path, pdf)

      assert File.exists?(path)
      %{size: size} = File.stat!(path)
      assert size > 100
    end
  end
end

defmodule RendroTest do
  use ExUnit.Case

  test "module exists" do
    assert Code.ensure_loaded?(Rendro)
  end

  test "render/1 is exported" do
    assert function_exported?(Rendro, :render, 1)
  end

  test "render/2 is exported" do
    assert function_exported?(Rendro, :render, 2)
  end

  describe "render/2 deterministic mode" do
    defp sample_doc do
      text = Rendro.text("Hello, deterministic!", size: 12, font: "Helvetica", color: {0, 0, 0})
      block = Rendro.block(text, x: 10, y: 20)
      page = Rendro.page(blocks: [block])
      Rendro.document(pages: [page], metadata: Rendro.metadata(title: "Test"))
    end

    test "deterministic renders produce identical binaries through public API" do
      doc = sample_doc()
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "deterministic render includes fixed timestamps" do
      doc = sample_doc()
      {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "(D:20000101000000Z)"
    end

    test "deterministic option works alongside output option" do
      doc = sample_doc()
      path = Path.join(System.tmp_dir!(), "rendro_det_test_#{:rand.uniform(100_000)}.pdf")

      try do
        {:ok, pdf} = Rendro.render(doc, deterministic: true, output: path)
        assert File.exists?(path)
        assert pdf =~ "(D:20000101000000Z)"
        assert File.read!(path) == pdf
      after
        File.rm(path)
      end
    end
  end
end

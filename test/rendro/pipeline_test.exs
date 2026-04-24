defmodule Rendro.PipelineTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline

  defp sample_document do
    text = %Rendro.Text{content: "Hello, Pipeline!", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}

    %Rendro.Document{
      pages: [page],
      metadata: %Rendro.Metadata{title: "Pipeline Test"}
    }
  end

  describe "run/1" do
    test "returns {:ok, binary} for a valid document" do
      assert {:ok, pdf} = Pipeline.run(sample_document())
      assert is_binary(pdf)
    end

    test "produced PDF starts with %PDF-1.4 header" do
      {:ok, pdf} = Pipeline.run(sample_document())
      assert String.starts_with?(pdf, "%PDF-1.4")
    end

    test "produced PDF ends with %%EOF" do
      {:ok, pdf} = Pipeline.run(sample_document())
      assert String.ends_with?(String.trim(pdf), "%%EOF")
    end

    test "produced PDF contains expected text content" do
      {:ok, pdf} = Pipeline.run(sample_document())
      assert pdf =~ "(Hello, Pipeline!) Tj"
    end

    test "returns error for document with no pages" do
      doc = %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}
      assert {:error, :no_pages} = Pipeline.run(doc)
    end

    test "returns error for invalid page dimensions" do
      page = %Rendro.Page{blocks: [], width: -1, height: 100}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}
      assert {:error, :invalid_page_dimensions} = Pipeline.run(doc)
    end

    test "handles multi-page documents" do
      text1 = %Rendro.Text{content: "Page 1", font: "Helvetica", size: 12, color: {0, 0, 0}}
      text2 = %Rendro.Text{content: "Page 2", font: "Helvetica", size: 12, color: {0, 0, 0}}

      doc = %Rendro.Document{
        pages: [
          %Rendro.Page{blocks: [%Rendro.Block{content: text1, x: 0, y: 0}]},
          %Rendro.Page{blocks: [%Rendro.Block{content: text2, x: 0, y: 0}]}
        ],
        metadata: %Rendro.Metadata{}
      }

      {:ok, pdf} = Pipeline.run(doc)
      assert pdf =~ "(Page 1)"
      assert pdf =~ "(Page 2)"
      assert pdf =~ "/Count 2"
    end

    test "handles page with empty blocks" do
      doc = %Rendro.Document{
        pages: [%Rendro.Page{blocks: []}],
        metadata: %Rendro.Metadata{}
      }

      assert {:ok, pdf} = Pipeline.run(doc)
      assert String.starts_with?(pdf, "%PDF-1.4")
    end
  end
end

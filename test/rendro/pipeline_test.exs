defmodule Rendro.PipelineTest do
  use ExUnit.Case, async: true

  alias Rendro.{PageTemplate, Pipeline, Region}

  defp sample_document do
    text = %Rendro.Text{
      content: "Hello, Pipeline!",
      font: "Helvetica",
      size: 12,
      color: {0, 0, 0}
    }

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

    test "returns structured diagnostics for document with no pages" do
      doc = %Rendro.Document{pages: [], metadata: %Rendro.Metadata{}}

      assert {:error, %Rendro.Error{} = error} = Pipeline.run(doc)
      assert error.stage == :build
      assert error.reason == :no_pages
      assert error.what =~ "validation"
      assert error.where == "Rendro.Pipeline.Build"
      assert error.next =~ "Add at least one page"
    end

    test "returns structured diagnostics for invalid page dimensions" do
      page = %Rendro.Page{blocks: [], width: -1, height: 100}
      doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

      assert {:error, %Rendro.Error{} = error} = Pipeline.run(doc)
      assert error.stage == :build
      assert error.reason == :invalid_page_dimensions
      assert error.next =~ "positive width and height"
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

  describe "render_with_diagnostics/2" do
    test "returns the final document with public diagnostics access" do
      template =
        %PageTemplate{
          name: :public_diagnostics,
          width: 220,
          height: 180,
          margin_top: 12,
          margin_right: 12,
          margin_bottom: 12,
          margin_left: 12,
          regions: [
            %Region{
              name: :body,
              role: :body,
              anchor: :flow,
              x: 12,
              y: 12,
              width: 196,
              height: 28.8
            }
          ]
        }

      doc =
        Rendro.flow(
          [
            Rendro.block(Rendro.text("Intro")),
            Rendro.block(Rendro.text("Heading"), keep_with_next: true),
            Rendro.block(Rendro.text("Body"))
          ],
          page_template: :public_diagnostics,
          page_templates: [template]
        )

      assert {:ok, pdf, final_doc} = Rendro.render_with_diagnostics(doc, deterministic: true)
      assert is_binary(pdf)
      assert length(final_doc.pages) == 2

      assert [%{level: :info, type: :keep_rule_break, keep_rule: :keep_with_next, page_index: 2}] =
               final_doc.diagnostics
    end
  end
end

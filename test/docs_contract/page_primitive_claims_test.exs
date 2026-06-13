defmodule Rendro.DocsContract.PagePrimitiveClaimsTest do
  use ExUnit.Case, async: true

  @guide_path "guides/page_primitive.md"
  @matrix_path "priv/support_matrix.json"

  setup_all do
    guide = File.read!(@guide_path)
    matrix = Jason.decode!(File.read!(@matrix_path))
    {:ok, guide: guide, matrix: matrix}
  end

  describe "page_primitive guide claim backing" do
    test "guide contains Page X of Y backed phrase", %{guide: guide} do
      assert guide =~ "Page X of Y"
    end

    test "guide names section-local numbering and duplex primitives", %{guide: guide} do
      for phrase <- [
            "page_numbering: [restart: true]",
            "{{section_page_number}}",
            "{{section_total_pages}}",
            "only_on: :odd",
            "only_on: :even",
            "physical PDF page number",
            "does not add recto/verso aliases",
            "insert blank pages"
          ] do
        assert guide =~ phrase
      end
    end

    test "page_numbering single_pass_substitution is supported in matrix", %{matrix: matrix} do
      assert matrix["page_numbering"]["capabilities"]["single_pass_substitution"] == "supported"
    end

    test "page_numbering deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["page_numbering"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "page_numbering records section token support", %{matrix: matrix} do
      assert matrix["page_numbering"]["capabilities"]["section_page_number_token"] == "supported"
      assert matrix["page_numbering"]["capabilities"]["section_total_pages_token"] == "supported"
    end

    test "page_numbering evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["page_numbering"]["evidence"]
      assert is_binary(evidence_path), "page_numbering evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "page_numbering row status is supported", %{matrix: matrix} do
      assert matrix["page_numbering"]["status"] == "supported"
    end

    test "section_page_numbering support row is proof-backed", %{matrix: matrix} do
      row = matrix["section_page_numbering"]

      assert row["surface"] == "section_page_numbering"
      assert row["status"] == "supported"
      assert row["evidence"] == "test/rendro/pipeline/paginate_test.exs"
      assert File.exists?(row["evidence"])
      assert row["capabilities"]["body_section_restart"] == "supported"
      assert row["capabilities"]["section_page_number_token"] == "supported"
      assert row["capabilities"]["section_total_pages_token"] == "supported"
      assert row["capabilities"]["implicit_whole_document_fallback"] == "supported"
      assert row["capabilities"]["public_page_context_api"] == "unsupported"
    end

    test "duplex_running_content support row is proof-backed", %{matrix: matrix} do
      row = matrix["duplex_running_content"]

      assert row["surface"] == "duplex_running_content"
      assert row["status"] == "supported"
      assert row["evidence"] == "test/rendro/pipeline/paginate_test.exs"
      assert File.exists?(row["evidence"])
      assert row["capabilities"]["physical_odd_even_only_on"] == "supported"
      assert row["capabilities"]["header_footer_running_regions"] == "supported"
      assert row["capabilities"]["composes_with_suppress_on"] == "supported"
      assert row["capabilities"]["composes_with_section_page_tokens"] == "supported"
      assert row["capabilities"]["blank_recto_verso_insertion"] == "unsupported"
      assert row["capabilities"]["recto_verso_aliases"] == "unsupported"
    end
  end

  describe "page_primitive guide claim refutations" do
    test "guide does not claim digital signatures", %{guide: guide} do
      refute guide =~ "digital signatures"
    end

    test "guide does not claim full_pdf_compliance", %{guide: guide} do
      refute guide =~ "full_pdf_compliance"
    end

    test "guide names explicit deferrals without implying support", %{guide: guide} do
      for phrase <- [
            "TOC, outlines, anchors, or cross-references",
            "Charts or `%Rendro.Chart{}`",
            "Global text shaping",
            "PDF.js browser-viewer behavior",
            "Full release automation",
            "not GUI-viewer proof"
          ] do
        assert guide =~ phrase
      end
    end

    test "support matrix does not add top-level PDF.js support promotion", %{matrix: matrix} do
      refute Map.has_key?(matrix, "pdfjs")
      refute Map.has_key?(matrix, "pdfjs_support")
      refute Map.has_key?(matrix, "pdfjs_advisory_support")
    end
  end

  describe "docs-contract lane registration" do
    test "verify_docs.exs includes the page-primitive semantic-claims lane" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~r/\{"Page-primitive semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/page_primitive_claims_test\.exs"\]\}/s
    end
  end
end

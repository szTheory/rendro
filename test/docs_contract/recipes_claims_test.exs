defmodule Rendro.DocsContract.RecipesClaimsTest do
  use ExUnit.Case, async: true

  @guide_path "guides/recipes.md"
  @matrix_path "priv/support_matrix.json"

  setup_all do
    guide = File.read!(@guide_path)
    matrix = Jason.decode!(File.read!(@matrix_path))
    {:ok, guide: guide, matrix: matrix}
  end

  describe "statement row claim backing" do
    test "guide contains multi-page table continuation language", %{guide: guide} do
      assert guide =~ "multi-page" or guide =~ "Multi-page"
    end

    test "guide contains running footer page number language", %{guide: guide} do
      assert guide =~ "Page X of Y"
    end

    test "statement multi_page_table_continuation is supported in matrix", %{matrix: matrix} do
      assert matrix["statement"]["capabilities"]["multi_page_table_continuation"] == "supported"
    end

    test "statement running_footer_page_number is supported in matrix", %{matrix: matrix} do
      assert matrix["statement"]["capabilities"]["running_footer_page_number"] == "supported"
    end

    test "statement deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["statement"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "statement evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["statement"]["evidence"]
      assert is_binary(evidence_path), "statement evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "statement row status is supported", %{matrix: matrix} do
      assert matrix["statement"]["status"] == "supported"
    end
  end

  describe "receipt_report row claim backing" do
    test "receipt_report multi_page_table_continuation is supported in matrix", %{matrix: matrix} do
      assert matrix["receipt_report"]["capabilities"]["multi_page_table_continuation"] == "supported"
    end

    test "receipt_report running_footer_page_number is supported in matrix", %{matrix: matrix} do
      assert matrix["receipt_report"]["capabilities"]["running_footer_page_number"] == "supported"
    end

    test "receipt_report deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["receipt_report"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "receipt_report evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["receipt_report"]["evidence"]
      assert is_binary(evidence_path), "receipt_report evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "receipt_report row status is supported", %{matrix: matrix} do
      assert matrix["receipt_report"]["status"] == "supported"
    end
  end

  describe "certificate row claim backing" do
    test "guide contains geometry-derived language", %{guide: guide} do
      assert guide =~ "geometry"
    end

    test "certificate geometry_derived_layout is supported in matrix", %{matrix: matrix} do
      assert matrix["certificate"]["capabilities"]["geometry_derived_layout"] == "supported"
    end

    test "certificate multi_page_size is supported in matrix", %{matrix: matrix} do
      assert matrix["certificate"]["capabilities"]["multi_page_size"] == "supported"
    end

    test "certificate branded_output is supported in matrix", %{matrix: matrix} do
      assert matrix["certificate"]["capabilities"]["branded_output"] == "supported"
    end

    test "certificate deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["certificate"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "certificate evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["certificate"]["evidence"]
      assert is_binary(evidence_path), "certificate evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "certificate row status is supported", %{matrix: matrix} do
      assert matrix["certificate"]["status"] == "supported"
    end
  end

  describe "out-of-matrix claim refutations" do
    test "guide does not claim digital signatures", %{guide: guide} do
      refute guide =~ "digital signatures"
    end

    test "guide does not claim full_pdf_compliance", %{guide: guide} do
      refute guide =~ "full_pdf_compliance"
    end

    test "matrix unsupported array includes full_pdf_compliance", %{matrix: matrix} do
      assert "full_pdf_compliance" in matrix["unsupported"]
    end

    test "matrix unsupported array includes digital_signatures", %{matrix: matrix} do
      assert "digital_signatures" in matrix["unsupported"]
    end
  end

  describe "docs-contract lane registration" do
    test "verify_docs.exs includes the recipes semantic-claims lane" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~s|{"Recipes semantic-claims lane", ["test", "test/docs_contract/recipes_claims_test.exs"]}|
    end
  end
end

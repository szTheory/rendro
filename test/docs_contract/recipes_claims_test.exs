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
      assert matrix["receipt_report"]["capabilities"]["multi_page_table_continuation"] ==
               "supported"
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

  describe "payslip row claim backing" do
    test "payslip net_pay_visual_anchor is supported in matrix", %{matrix: matrix} do
      assert matrix["payslip"]["capabilities"]["net_pay_visual_anchor"] == "supported"
    end

    test "payslip multi_page_ledger_continuation is supported in matrix", %{matrix: matrix} do
      assert matrix["payslip"]["capabilities"]["multi_page_ledger_continuation"] == "supported"
    end

    test "payslip jurisdiction_as_data is supported in matrix", %{matrix: matrix} do
      assert matrix["payslip"]["capabilities"]["jurisdiction_as_data"] == "supported"
    end

    test "payslip deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["payslip"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "payslip evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["payslip"]["evidence"]
      assert is_binary(evidence_path), "payslip evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "payslip row status is supported", %{matrix: matrix} do
      assert matrix["payslip"]["status"] == "supported"
    end
  end

  describe "ticket row claim backing" do
    test "ticket geometry_derived_layout is supported in matrix", %{matrix: matrix} do
      assert matrix["ticket"]["capabilities"]["geometry_derived_layout"] == "supported"
    end

    test "ticket caller_supplied_code_image is supported in matrix", %{matrix: matrix} do
      assert matrix["ticket"]["capabilities"]["caller_supplied_code_image"] == "supported"
    end

    test "ticket no_faux_barcode is supported in matrix", %{matrix: matrix} do
      assert matrix["ticket"]["capabilities"]["no_faux_barcode"] == "supported"
    end

    test "ticket deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["ticket"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "ticket evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["ticket"]["evidence"]
      assert is_binary(evidence_path), "ticket evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "ticket row status is supported", %{matrix: matrix} do
      assert matrix["ticket"]["status"] == "supported"
    end
  end

  describe "demonstration_set row claim backing (SHOW-04/D-15)" do
    test "demonstration_set row is present and supported", %{matrix: matrix} do
      assert matrix["demonstration_set"]["status"] == "supported"
    end

    test "demonstration_set families include the new payslip and ticket families", %{
      matrix: matrix
    } do
      families = matrix["demonstration_set"]["families"]
      assert "payslip" in families
      assert "ticket" in families
    end

    test "every demonstration_set evidence pointer resolves on disk", %{matrix: matrix} do
      evidence = matrix["demonstration_set"]["evidence"]
      assert map_size(evidence) > 0, "demonstration_set must carry at least one evidence pointer"

      for {name, path} <- evidence do
        assert is_binary(path), "evidence pointer #{name} must be a string path"

        assert File.exists?(path),
               "demonstration_set evidence #{name} must resolve on disk: #{path}"
      end
    end

    test "demonstration_set makes no rubric-pass / visual-polish / accessibility claim", %{
      matrix: matrix
    } do
      boundaries = matrix["demonstration_set"]["boundaries"]
      assert boundaries["reader_quality_rubric_pass"] == "unsupported"
      assert boundaries["visual_polish_claim"] == "unsupported"
      assert boundaries["accessibility_conformance_claim"] == "unsupported"
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
               ~r/\{"Recipes semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/recipes_claims_test\.exs"\]\}/s
    end
  end
end

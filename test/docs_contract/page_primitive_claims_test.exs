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

    test "page_numbering single_pass_substitution is supported in matrix", %{matrix: matrix} do
      assert matrix["page_numbering"]["capabilities"]["single_pass_substitution"] == "supported"
    end

    test "page_numbering deterministic_output is supported in matrix", %{matrix: matrix} do
      assert matrix["page_numbering"]["capabilities"]["deterministic_output"] == "supported"
    end

    test "page_numbering evidence path exists on disk", %{matrix: matrix} do
      evidence_path = matrix["page_numbering"]["evidence"]
      assert is_binary(evidence_path), "page_numbering evidence key must be a string"
      assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
    end

    test "page_numbering row status is supported", %{matrix: matrix} do
      assert matrix["page_numbering"]["status"] == "supported"
    end
  end

  describe "page_primitive guide claim refutations" do
    test "guide does not claim digital signatures", %{guide: guide} do
      refute guide =~ "digital signatures"
    end

    test "guide does not claim full_pdf_compliance", %{guide: guide} do
      refute guide =~ "full_pdf_compliance"
    end
  end

  describe "docs-contract lane registration" do
    test "verify_docs.exs includes the page-primitive semantic-claims lane" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~s|{"Page-primitive semantic-claims lane", ["test", "test/docs_contract/page_primitive_claims_test.exs"]}|
    end
  end
end

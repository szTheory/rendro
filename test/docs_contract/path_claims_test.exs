defmodule Rendro.DocsContract.PathClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix has path_primitive section with explicit_deferral entries for transforms, clipping, and gradients" do
    matrix = File.read!("priv/support_matrix.json")

    # Path primitive section must be present
    assert matrix =~ ~s|"path_primitive"|

    # Three explicit deferrals required per PATH-04 / D-23
    assert matrix =~ ~s|"transforms_cm"|
    assert matrix =~ ~s|"clipping_W"|
    assert matrix =~ ~s|"gradients"|

    # Each deferral must have explicit_deferral status
    assert matrix =~
             ~r/"transforms_cm"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"clipping_W"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"gradients"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    # evidence_deferred strings must be non-empty (schema: minLength 40)
    assert matrix =~
             ~r/"transforms_cm".*?"evidence_deferred"\s*:\s*".{40,}"/s

    assert matrix =~
             ~r/"clipping_W".*?"evidence_deferred"\s*:\s*".{40,}"/s

    assert matrix =~
             ~r/"gradients".*?"evidence_deferred"\s*:\s*".{40,}"/s
  end

  test "docs verification script includes the path claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]}|
  end
end

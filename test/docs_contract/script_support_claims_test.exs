defmodule Rendro.DocsContract.ScriptSupportClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix has text_shaping section with four explicit_deferral entries" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"text_shaping"|
    assert matrix =~ ~s|"arabic"|
    assert matrix =~ ~s|"hebrew_rtl"|
    assert matrix =~ ~s|"devanagari"|
    assert matrix =~ ~s|"thai"|

    assert matrix =~
             ~r/"arabic"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"hebrew_rtl"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"devanagari"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"thai"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    # Verify evidence_deferred strings are non-empty (schema: minLength 40)
    assert matrix =~
             ~r/"arabic".*?"evidence_deferred"\s*:\s*".{40,}"/s

    # latin_and_cjk must be "supported", not deferred
    assert matrix =~
             ~r/"latin_and_cjk"\s*:\s*\{.*?"status"\s*:\s*"supported"/s

    refute matrix =~ ~s|"arabic": "supported"|
    refute matrix =~ ~s|"complex scripts are supported"|
  end

  test "docs verification script includes the script support claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Script support claims lane", ["test", "test/docs_contract/script_support_claims_test.exs"]}|
  end
end

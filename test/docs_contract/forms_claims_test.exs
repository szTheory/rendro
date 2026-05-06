defmodule Rendro.DocsContract.FormsClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix exposes the nested forms contract with provisional viewer statuses" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"forms"|
    assert matrix =~ ~s|"widgets"|
    assert matrix =~ ~s|"behaviors"|
    assert matrix =~ ~s|"viewers"|
    assert matrix =~ ~s|"text": "supported"|
    assert matrix =~ ~s|"checkbox": "supported"|
    assert matrix =~ ~s|"radio": "supported"|
    assert matrix =~ ~s|"signature": "unsupported"|
    assert matrix =~ ~s|"hierarchical_field_names": "unsupported"|
    assert matrix =~ ~s|"need_appearances": "unsupported"|
    assert matrix =~ ~s|"xfa": "unsupported"|

    assert matrix =~ ~r/"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
    assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"pdfjs"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    refute matrix =~ ~s|"surfaces"|
  end

  test "public forms wording stays narrow and matches the provisional matrix posture" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~ "Rendro supports authored AcroForm text fields, checkboxes, and radio groups."

    assert guide =~
             "Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior."

    assert guide =~
             "Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist. Adobe Acrobat Reader remains `unverified` until the same checklist records passing open, visible default state, edit/toggle, and save behavior."

    assert guide =~
             "Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them."

    refute guide =~ "standard PDF viewers"
    refute guide =~ "Adobe Acrobat Reader is supported"
  end

  test "the canonical docs verification script includes the forms claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|
  end
end

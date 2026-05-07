defmodule Rendro.DocsContract.FormsClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix exposes the nested forms contract with provisional viewer statuses" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"forms"|
    assert matrix =~ ~s|"authored_helpers"|
    assert matrix =~ ~s|"widgets"|
    assert matrix =~ ~s|"behaviors"|
    assert matrix =~ ~s|"viewers"|
    assert matrix =~ ~s|"signature_field": "supported_unsigned_placeholder_only"|
    assert matrix =~ ~s|"text": "supported"|
    assert matrix =~ ~s|"checkbox": "supported"|
    assert matrix =~ ~s|"radio": "supported"|
    assert matrix =~ ~s|"signature": "unsupported"|
    assert matrix =~ ~s|"digital_signatures": "unsupported"|
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

    assert guide =~
             "Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders."

    assert guide =~
             "Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior."

    assert guide =~
             "The `Rendro.signature_field/2` helper is an authored unsigned-placeholder contract only. Phase 55 does not yet claim rendered signature-widget support, viewer support for signature fields, or digital-signature behavior."

    assert guide =~
             "Digital signatures, signer metadata, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported."

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

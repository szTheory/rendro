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
    assert matrix =~ ~s|"signature": "supported_unsigned_widget_only"|
    assert matrix =~ ~s|"hierarchical_field_names": "unsupported"|
    assert matrix =~ ~s|"need_appearances": "unsupported"|
    assert matrix =~ ~s|"xfa": "unsupported"|

    assert matrix =~ ~r/"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
    assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"pdfjs"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"signature_widget_viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"signature_widget_viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~ ~s|"digital_signatures": "unsupported"|

    refute matrix =~ ~s|"surfaces"|
  end

  test "public forms wording stays narrow and matches the provisional matrix posture" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~
             "Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders."

    assert guide =~
             "Rendro can author an unsigned placeholder, render an artifact, prepare that final artifact for an external signer, and then stop. External signing and verification remain outside Rendro core."

    assert guide =~
             "Supported surface: `Rendro.signature_field/2` authors unsigned signature placeholders, and Rendro renders those placeholders as unsigned `/Sig` widgets only."

    assert guide =~
             "Proof lane: deterministic writer and structural tests prove unsigned widget structure only. Structural proof is not viewer proof and not cryptographic validity proof."

    assert guide =~
             "Unsupported narratives: digital signatures, signer identity or trust, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported."

    assert guide =~
             "Signature-specific viewer rows remain `unverified` in `priv/support_matrix.json` until a recorded checklist exists for that exact viewer and signature surface."

    assert guide =~
             "Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them."

    refute guide =~ "standard PDF viewers"
    refute guide =~ "Adobe Acrobat Reader is supported"
    refute guide =~ "digital signatures are supported"
    refute guide =~ "viewer support for signature fields"
    refute guide =~ "PAdES is supported"
    refute guide =~ "viewer-proofed digital signatures"
  end

  test "the canonical docs verification script includes the forms claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|
  end

  test "signature docs-contract lane keeps explicit negative claim guards" do
    source = File.read!(__ENV__.file)
    [wording_test] =
      Regex.run(~r/test "public forms wording stays narrow.*?\n  end/s, source)

    assert wording_test =~ ~s|refute guide =~ "digital signatures are supported"|
    assert wording_test =~ ~s|refute guide =~ "viewer support for signature fields"|
    assert wording_test =~ ~s|refute guide =~ "PAdES is supported"|
    assert wording_test =~ ~s|refute guide =~ "viewer-proofed digital signatures"|
  end
end

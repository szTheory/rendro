defmodule Rendro.DocsContract.SigningClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix publishes long-lived support as a nested signing subtree" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"signing_preparation"|
    assert matrix =~ ~s|"signing"|
    assert matrix =~ ~s|"long_lived"|
    assert matrix =~ ~s|"pyhanko_sign_augment_validate_existing_field": "supported"|
    assert matrix =~ ~s|"timestamp_posture_via_pyhanko": "supported"|
    assert matrix =~ ~s|"revocation_evidence_via_pyhanko": "supported"|
    assert matrix =~ ~s|"embedded_validation_evidence_posture": "supported"|
    assert matrix =~ ~s|"certificate_trust_is_separate": "supported"|
    assert matrix =~ ~s|"pdfsig_integrity_parity": "supported_secondary"|
    assert matrix =~ ~s|"signer_identity_trust": "unsupported"|
    assert matrix =~ ~s|"viewer_promotion": "unsupported"|
    assert matrix =~ ~s|"lt_lta_profile_marketing": "unsupported"|
    assert matrix =~ ~s|"blanket_compliance_claims": "unsupported"|
    assert matrix =~ ~s|"multi_signature_workflows": "unsupported"|

    assert matrix =~
             ~r/"signing".*?"long_lived".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"signing".*?"long_lived".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/s

    refute matrix =~ ~s|"long_lived": "supported"|
    refute matrix =~ ~s|"tamper_evidence_narratives": "supported"|
    refute matrix =~ ~r/^  "long_lived"\s*:/m
  end

  test "signature-specific and long-lived viewer rows are terminal after Phase 71" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~
             ~r/"signature_widget_viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"signature_widget_viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"signing_preparation".*?"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"signing".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

    assert matrix =~
             ~r/"signing".*?"long_lived".*?"pdfjs"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/s

    refute matrix =~ ~s|targeted for verification|
  end

  test "api stability guide keeps signing, long-lived, trust, and compliance claims separate" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~ "## Signing Preparation Support Boundary"
    assert guide =~ "## Signed Artifact Support Boundary"
    assert guide =~ "## Long-Lived Evidence Support Boundary"

    assert guide =~
             "Supported surface: `Rendro.Sign.prepare/2` is an artifact-first preparation seam over rendered `%Rendro.Artifact{}` bytes. It supports external artifact preparation, final byte handoff, and adapter-local metadata isolation."

    assert guide =~
             "Supported surface: `Rendro.Sign.sign/2` and `Rendro.render_signed/3` sign a rendered unsigned-signature artifact through an optional external adapter."

    assert guide =~
             "Supported surface: take a Rendro-rendered artifact, sign it through `Rendro.Sign.sign/2`, augment it through `Rendro.Sign.augment/2`, and validate timestamp, revocation, and embedded-validation-evidence posture through `Rendro.Sign.validate/2` with `adapter: Rendro.Adapters.PyHanko`."

    assert guide =~
             "Local recipe: `mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs`."

    assert guide =~
             "CI recipe: the dedicated `long-lived-live-proof` job runs the same tagged command after provisioning pyHanko, certomancer, and pdfsig."

    assert guide =~
             "Certificate trust is a separate question from timestamp and revocation evidence posture."

    assert guide =~
             "For viewers other than Adobe Acrobat Reader, `signing_preparation` and `signature_widget` cells are behaviorally indistinguishable"

    assert guide =~ "priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md"

    refute guide =~ "tamper-evident signing"
    refute guide =~ "PAdES is supported"
    refute guide =~ "LT/LTA is supported"
    refute guide =~ "PDF/A is supported"
    refute guide =~ "regulatory approval"
    refute guide =~ "enterprise compliance"
    refute guide =~ "all signature viewers are supported"
    refute guide =~ "viewer portability is guaranteed"
    refute guide =~ "Rendro owns signer identity trust"
  end

  test "docs verification script includes the signing claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]}|
  end
end

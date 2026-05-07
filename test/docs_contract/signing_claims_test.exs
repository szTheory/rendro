defmodule Rendro.DocsContract.SigningClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix publishes signing preparation as a narrow sibling family" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"signing_preparation"|
    assert matrix =~ ~s|"external_artifact_prepare": "supported"|
    assert matrix =~ ~s|"final_byte_handoff": "supported"|
    assert matrix =~ ~s|"adapter_local_metadata_isolation": "supported"|
    assert matrix =~ ~s|"digital_signatures": "unsupported"|
    assert matrix =~ ~s|"signer_identity_trust": "unsupported"|
    assert matrix =~ ~s|"cryptographic_validity": "unsupported"|
    assert matrix =~ ~s|"tamper_evidence": "unsupported"|
    assert matrix =~ ~s|"pades_ltv_tsa_ocsp_crl": "unsupported"|

    assert matrix =~
             ~r/"signing_preparation".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"signing_preparation".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    refute matrix =~ ~s|"digital_signatures": "supported"|
    refute matrix =~ ~s|"tamper_evidence": "supported"|
  end

  test "signature-specific viewer rows stay unverified unless a named checklist promotes that exact surface" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~
             ~r/"signature_widget_viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"signature_widget_viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"signing_preparation".*?"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    refute matrix =~ ~s|targeted for verification|
  end

  test "api stability guide keeps signing preparation separate from digital-signature claims" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~ "## Signing Preparation Support Boundary"

    assert guide =~
             "Supported surface: `Rendro.Sign.prepare/2` is an artifact-first preparation seam over rendered `%Rendro.Artifact{}` bytes. It supports external artifact preparation, final byte handoff, and adapter-local metadata isolation."

    assert guide =~
             "Proof lane: prepare-stage and manifest tests prove prepared-artifact coordinates and metadata boundaries only. This proof lane is separate from viewer behavior, signer execution, and cryptographic validity."

    assert guide =~
             "Unsupported narratives: external signer execution, signer identity or trust policy, digital-signature validity, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported."

    assert guide =~
             "Signature-preparation viewer rows remain `unverified` unless a recorded checklist exists for that exact viewer and prepared-artifact surface."

    refute guide =~ "digital signatures are supported"
    refute guide =~ "tamper-evident signing"
    refute guide =~ "PAdES is supported"
    refute guide =~ "all signature viewers are supported"
  end

  test "docs verification script includes the signing claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]}|
  end
end

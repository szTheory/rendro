defmodule Rendro.DocsContract.ApiStabilityClaimsTest do
  use ExUnit.Case, async: true

  # ASSERTION CATEGORY 1 — Guide prose: tier headers and key promise sentences.
  test "api stability guide ships correct tier headers and key promise sentences" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~ "## Tier-1 Stable"
    assert guide =~ "## Tier-2 Evolving"
    assert guide =~ "## NOT covered by SemVer"
    assert guide =~ "## Deprecation Policy"
    assert guide =~ "## Deprecations"

    # Key promise sentence (byte-output carve-out — D-13 item 1)
    assert guide =~ "deterministic within a version, not frozen across versions"

    # Deprecations table header columns (D-15)
    assert guide =~ "| Symbol |"

    # Deprecations table sentinel row (D-15)
    assert guide =~ "None as of 1.0.0"

    # D-03 banned overclaim phrase guards
    refute guide =~ "secure PDF"
    refute guide =~ "PAdES is supported"
  end

  # ASSERTION CATEGORY 2 — Symbol existence (false-pass-guarded, D-10 item 1).
  test "all named Tier-1 stable modules are loaded and exported" do
    # Stable-tier modules named in the rewritten guide prose (confirmed tier=stable in priv/public_api.json)
    assert Code.ensure_loaded?(Rendro.Document),
           "Expected Rendro.Document to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.PageTemplate),
           "Expected Rendro.PageTemplate to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Section),
           "Expected Rendro.Section to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Metadata),
           "Expected Rendro.Metadata to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Artifact),
           "Expected Rendro.Artifact to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Sign),
           "Expected Rendro.Sign to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Protect),
           "Expected Rendro.Protect to be loaded — was it renamed or deleted?"

    # Adapter-tier modules named in the rewritten guide prose (confirmed tier=adapter; D-10 includes adapters)
    assert Code.ensure_loaded?(Rendro.Adapters.PyHanko),
           "Expected Rendro.Adapters.PyHanko to be loaded — was it renamed or deleted?"

    assert Code.ensure_loaded?(Rendro.Adapters.Qpdf),
           "Expected Rendro.Adapters.Qpdf to be loaded — was it renamed or deleted?"

    # Ensure the top-level Rendro module is loaded before checking function exports
    assert Code.ensure_loaded?(Rendro),
           "Expected Rendro to be loaded — was it renamed or deleted?"

    # Top-level pipeline functions on Rendro (stable tier)
    assert function_exported?(Rendro, :flow, 2),
           "Rendro.flow/2 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro, :signature_field, 2),
           "Rendro.signature_field/2 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro, :render_signed, 3),
           "Rendro.render_signed/3 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro, :render_protected, 3),
           "Rendro.render_protected/3 not exported — was it renamed or deleted?"

    # Rendro.Sign functions (stable tier)
    assert function_exported?(Rendro.Sign, :prepare, 2),
           "Rendro.Sign.prepare/2 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro.Sign, :sign, 2),
           "Rendro.Sign.sign/2 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro.Sign, :augment, 2),
           "Rendro.Sign.augment/2 not exported — was it renamed or deleted?"

    assert function_exported?(Rendro.Sign, :validate, 2),
           "Rendro.Sign.validate/2 not exported — was it renamed or deleted?"

    # Rendro.Protect functions (stable tier)
    assert function_exported?(Rendro.Protect, :password, 2),
           "Rendro.Protect.password/2 not exported — was it renamed or deleted?"

    # Struct existence (false-pass-guard: struct/1 raises ArgumentError if struct is missing)
    assert match?(%Rendro.Artifact{}, struct(Rendro.Artifact)),
           "%Rendro.Artifact{} struct not present — was it deleted?"
  end

  # ASSERTION CATEGORY 3 — Upgrade guide existence (STAB-03, D-10 item 4).
  test "upgrade guide exists" do
    assert File.exists?("guides/upgrading_to_1.0.md"),
           "guides/upgrading_to_1.0.md must exist (STAB-03)"
  end

  # ASSERTION CATEGORY 4 — Lane self-registration (D-10 item 5, lockstep triple).
  test "docs verification script includes the api stability claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}|
  end
end

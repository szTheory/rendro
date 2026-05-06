defmodule Rendro.DocsContract.ProtectionClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix publishes the narrow protection family and leaves viewers unverified" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"protection"|
    assert matrix =~ ~s|"password_to_open": "supported"|
    assert matrix =~ ~s|"external_hook_qpdf": "supported"|
    assert matrix =~ ~s|"native_encryption": "unsupported"|
    assert matrix =~ ~s|"aes_256": "supported"|
    assert matrix =~ ~s|"aes_128": "unsupported"|
    assert matrix =~ ~s|"rc4": "unsupported"|
    assert matrix =~ ~s|"advisory_permissions": "supported"|
    assert matrix =~ ~s|"deterministic_output": "unsupported"|
    assert matrix =~ ~s|"tamper_evidence": "unsupported"|
    assert matrix =~ ~s|"pdf_a_compliance": "unsupported"|
    assert matrix =~ ~s|"digital_signatures": "unsupported"|
    assert matrix =~ ~s|"boundaries"|
    assert matrix =~ ~s|"external_hook_only": "supported"|
    assert matrix =~ ~s|"persisted_async_job_args_passwords": "unsupported"|
    assert matrix =~ ~s|"delivery_and_storage_seams_transport_artifacts_not_passwords": "supported"|

    assert matrix =~
             ~r/"protection".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    assert matrix =~
             ~r/"protection".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

    refute matrix =~ ~s|"native_encryption": "supported"|
    refute matrix =~ ~s|"digital_signatures": "supported"|
  end

  test "api stability guide uses narrow, truthful protection wording" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~
             "Rendro supports password-to-open PDF protection through an external artifact-first boundary."

    assert guide =~ "`Rendro.Protect.password/2`"
    assert guide =~ "Rendro v1.10 supports only `:aes_256`"
    assert guide =~ "Advisory permissions are an honor-system PDF flag surface"
    assert guide =~ "Protection is not compliance, not tamper evidence, and not digital signing."
    assert guide =~ "If validation succeeds only with `owner_password`"
    assert guide =~ "All `protection` viewer rows remain `unverified`"

    refute guide =~ "secure PDF"
    refute guide =~ "tamper-proof"
    refute guide =~ "PDF/A compliant"
  end

  test "integrations guide keeps protection secrets out of persisted job args and delivery seams" do
    guide = File.read!("guides/integrations.md")

    assert guide =~ "The worker also does **not** accept password or protection fields in job args."
    assert guide =~ "Protection secrets do not belong in persisted Oban args."
    assert guide =~ "apply `Rendro.Protect.password/2`"
    assert guide =~ "application-owned credential boundary before storage or delivery."
    assert guide =~ "Mailglass does not need to know the passwords"

    refute guide =~ "persist protection passwords in Oban"
    refute guide =~ "Mailglass manages protection passwords"
  end

  test "docs verification script includes the protection claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}|
  end
end

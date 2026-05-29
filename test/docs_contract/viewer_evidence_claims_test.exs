defmodule Rendro.DocsContract.ViewerEvidenceClaimsTest do
  use ExUnit.Case, async: true

  alias Rendro.ViewerEvidence.{Lint, Matrix, Validator}

  @fixtures_dir "test/support/viewer_evidence/fixtures"

  describe "production tier-A artifacts" do
    test "production support matrix passes structural JSV validation" do
      matrix = Matrix.load!()
      assert :ok = Validator.validate_matrix_structure(matrix)
    end

    test "production evidence tree has no orphan markdown files" do
      orphans = Validator.list_orphan_evidence()

      assert orphans == []
    end

    test "canonical _template.md validates against evidence schema and proof ids" do
      proof = ["open", "default_state_visible", "edit_or_toggle", "save"]

      assert :ok =
               Validator.validate_evidence_file("priv/viewer_evidence/_template.md", proof)
    end

    test "production support matrix is promotion-complete for all supported rows" do
      matrix = Matrix.load!()
      assert :ok = Validator.validate_promotion_complete(matrix)
    end

    test "api stability guide mirrors all consolidated viewer evidence paths" do
      guide = File.read!("guides/api_stability.md")

      for path <- [
            "priv/viewer_evidence/forms/apple_preview.md",
            "priv/viewer_evidence/forms/adobe_acrobat_reader.md",
            "priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md",
            "priv/viewer_evidence/links/adobe_acrobat_reader.md",
            "priv/viewer_evidence/links/apple_preview.md",
            "priv/viewer_evidence/protection/apple_preview.md",
            "priv/viewer_evidence/protection/adobe_acrobat_reader.md",
            "priv/viewer_evidence/signature_widget/adobe_acrobat_reader.md",
            "priv/viewer_evidence/signature_widget/apple_preview.md",
            "priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md",
            "priv/viewer_evidence/signed_artifact/adobe_acrobat_reader.md",
            "priv/viewer_evidence/signed_artifact/chrome_pdfium.md",
            "priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md"
          ] do
        assert guide =~ path
      end
    end

    test "trust-sensitive matrix cells have no bare unverified status" do
      matrix = File.read!("priv/support_matrix.json")
      refute matrix =~ ~r/"signature_widget_viewers".*?"status"\s*:\s*"unverified"/s
      refute matrix =~ ~r/"signing_preparation".*?"status"\s*:\s*"unverified"/s
      refute matrix =~ ~r/"signing".*?"status"\s*:\s*"unverified"/s
    end

    test "viewer evidence guide documents Phase 71 deferral templates" do
      guide = File.read!("guides/viewer_evidence.md")

      assert guide =~ "UPSTREAM_ISSUE"
      assert guide =~ "NO_SIG_VALIDATION"
      assert guide =~ "NO_LTV_INDICATORS"
      assert guide =~ "SURFACE_EQUIVALENCE"
    end

    test "viewer claim sentences do not reference phase summaries instead of evidence files" do
      guide = File.read!("guides/api_stability.md")

      refute guide =~ "Phase 47 viewer checklist"
      refute guide =~ "Phase 54 checklist"
      refute guide =~ "phase validation record"
    end

    test "run_full succeeds on production matrix with no legacy promotion warnings" do
      assert {:ok, warnings} = Validator.run_full()

      refute Enum.any?(warnings, &String.contains?(&1, "missing promotion-complete"))
    end

    test "viewer evidence guide references canonical template and worked example paths" do
      guide = File.read!("guides/viewer_evidence.md")

      assert guide =~ "priv/viewer_evidence/_template.md"
      assert guide =~ "priv/viewer_evidence/forms/chrome_pdfium.md"
    end
  end

  describe "tier-B promotion and deferral violations" do
    test "supported without evidence fails promotion-complete validation" do
      matrix = %{
        "forms" => %{
          "viewers" => %{
            "apple_preview" => %{
              "status" => "supported",
              "proof" => ["open"]
            }
          }
        }
      }

      assert {:error, violations} = Validator.validate_promotion_complete(matrix)
      assert violations != []
      assert Enum.any?(violations, &String.contains?(&1, "evidence"))
    end

    test "explicit_deferral without evidence_deferred fails promotion-complete validation" do
      matrix = %{
        "forms" => %{
          "viewers" => %{
            "pdfjs" => %{"status" => "explicit_deferral"}
          }
        }
      }

      assert {:error, violations} = Validator.validate_promotion_complete(matrix)
      assert Enum.any?(violations, &String.contains?(&1, "evidence_deferred"))
    end

    test "deferral reason lint rejects TBD, vague, short, and deferred-for-later vocabulary" do
      fixture = File.read!("#{@fixtures_dir}/invalid_deferral_tbd.json")
      %{"evidence_deferred" => reason} = JSON.decode!(fixture)
      assert {:error, _} = Lint.deferral_reason(reason)

      assert {:error, _} = Lint.deferral_reason("not yet")
      assert {:error, _} = Lint.deferral_reason("deferred for later")
      assert {:error, _} = Lint.deferral_reason("short deferral reason under forty chars")

      matrix = %{
        "forms" => %{
          "viewers" => %{
            "pdfjs" => %{
              "status" => "explicit_deferral",
              "evidence_deferred" =>
                "Still tracking TBD in issue tracker for this viewer surface."
            }
          }
        }
      }

      assert {:error, violations} = Validator.validate_promotion_complete(matrix)
      assert Enum.any?(violations, &String.contains?(&1, "TBD"))
    end
  end

  describe "tier-B evidence body and file violations" do
    test "evidence body lint rejects image embeds, PEM blocks, home paths, and secrets" do
      image = File.read!("#{@fixtures_dir}/invalid_evidence_image.md")
      {:ok, {_fm, image_body}} = Rendro.ViewerEvidence.Frontmatter.parse(image)
      assert {:error, _} = Lint.evidence_body(image_body)

      assert {:error, _} = Lint.evidence_body("PEM material: -----BEGIN RSA PRIVATE KEY-----")

      assert {:error, _} =
               Lint.evidence_body("Opened from /Users/jon/projects/rendro/tmp/example.pdf")

      secret = File.read!("#{@fixtures_dir}/invalid_evidence_secret.md")
      {:ok, {_fm, secret_body}} = Rendro.ViewerEvidence.Frontmatter.parse(secret)
      assert {:error, _} = Lint.evidence_body(secret_body)

      assert {:error, _} = Lint.evidence_body("Captured passphrase: secret in the viewer UI.")
      assert {:error, _} = Lint.evidence_body("Observed private_key: abc123 in debug output.")
    end

    test "validate_evidence_file rejects fixture files with forbidden body content" do
      proof = ["open"]

      assert {:error, _} =
               Validator.validate_evidence_file(
                 "#{@fixtures_dir}/invalid_evidence_image.md",
                 proof,
                 skip_path_alignment: true
               )

      assert {:error, _} =
               Validator.validate_evidence_file(
                 "#{@fixtures_dir}/invalid_evidence_secret.md",
                 proof,
                 skip_path_alignment: true
               )

      assert {:error, _} =
               Validator.validate_evidence_file(
                 "#{@fixtures_dir}/invalid_evidence_home_path.md",
                 proof,
                 skip_path_alignment: true
               )
    end

    test "byte budget rejects evidence files over 65536 bytes" do
      oversized = String.duplicate("x", 65_537)
      assert {:error, reason} = Lint.byte_budget(oversized)
      assert reason =~ "65536"
    end

    test "orphan evidence file unreferenced by the matrix is detected" do
      orphan_path = "priv/viewer_evidence/forms/orphan_test.md"
      File.mkdir_p!(Path.dirname(orphan_path))

      File.write!(
        orphan_path,
        """
        ---
        schema_version: 1
        surface: forms
        viewer: orphan_test
        viewer_version: "0.0.0"
        platform: "macOS 15 (example)"
        recorded_at: "2026-01-01"
        fixture: "test/fixtures/example.pdf"
        behaviors:
          - behavior: open
            result: pass
            note: "Synthetic orphan fixture for docs-contract tier-B coverage."
        ---

        Orphan evidence file not referenced by the support matrix.
        """
      )

      on_exit(fn -> File.rm(orphan_path) end)

      orphans = Validator.list_orphan_evidence()
      assert orphan_path in orphans
    end
  end

  describe "tier-B matrix schema violations" do
    test "viewer row key compliance_tier is rejected by structural validation" do
      matrix = Matrix.load!()

      invalid =
        put_in(matrix, ["forms", "viewers", "apple_preview", "compliance_tier"], "enterprise")

      assert {:error, reason} = Validator.validate_matrix_structure(invalid)
      assert is_binary(reason)
    end
  end

  describe "docs-contract lane registration" do
    @describetag :lane_registration
    test "verify_docs.exs includes the viewer evidence semantic-claims lane" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~s|{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}|
    end

    test "verify_docs.exs retains the prior seven docs-contract lanes" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~s|{"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]}|

      assert script =~
               ~s|{"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]}|

      assert script =~
               ~s|{"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]}|

      assert script =~
               ~s|{"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]}|

      assert script =~
               ~s|{"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]}|

      assert script =~
               ~s|{"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]}|

      assert script =~
               ~s|{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}|
    end
  end
end

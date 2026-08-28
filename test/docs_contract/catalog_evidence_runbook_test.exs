defmodule Rendro.DocsContract.CatalogEvidenceRunbookTest do
  use ExUnit.Case, async: true

  @runbook_path ".github/workflows/CATALOG-EVIDENCE.md"
  @workflow_path ".github/workflows/catalog-evidence.yml"
  @docs_runner_path "scripts/verify_docs.exs"
  @scripts_readme_path "scripts/README.md"

  test "runbook gives all four operators one current, textual evidence path" do
    runbook = File.read!(@runbook_path)

    for heading <- [
          "## Request evidence for one immutable commit",
          "## Review one complete evidence bundle",
          "## Open the optional visual gallery",
          "## Consume the stable bundle contract in Phase 136",
          "## Audit the control plane and diagnose failures"
        ] do
      assert runbook =~ heading
    end

    for command <- [
          "git rev-parse HEAD",
          "gh workflow run catalog-evidence.yml -f \"candidate_sha=${FULL_SHA}\" -f operation=review",
          "gh workflow run catalog-evidence.yml -f \"candidate_sha=${FULL_SHA}\" -f operation=canonical",
          "gh run watch RUN_ID",
          "gh run download RUN_ID",
          "Rendro.CatalogEvidenceBundle.validate",
          "mix rendro.catalog.candidate",
          "mix rendro.catalog.gen",
          "mix rendro.catalog.check",
          "mix ci.fast"
        ] do
      assert runbook =~ command
    end

    assert runbook =~
             "rendro-catalog-evidence--{operation}--{full_candidate_sha}--run-{run_id}--attempt-{run_attempt}"

    assert runbook =~ "30 days"
    assert runbook =~ "Candidate evidence only — reviewer approval is not recorded here"
    assert runbook =~ "Canonical evidence — materialize only after the catalog check passes"
    assert runbook =~ "Remote Ubuntu/PDFium alone proves raster identity"
    assert runbook =~ "Phase 136 alone owns visual judgment"
    assert runbook =~ "contents: read"
    assert runbook =~ "No secrets, caches, writes, workflow bridge, or attestation"
    assert runbook =~ "control SHA"
    assert runbook =~ "candidate SHA"
    assert runbook =~ "checked-out HEAD"
    assert runbook =~ "priv/pdfium_pin.json"
    assert runbook =~ "Artifact URL"
    assert runbook =~ "Archive digest"
    assert runbook =~ "Next:"
    assert runbook =~ "Validate review bundle"
    assert runbook =~ "Review bundle empty"
    assert runbook =~ "Review bundle loading"
    assert runbook =~ "Review bundle error"
    assert runbook =~ "Review bundle populated"
    assert runbook =~ "Review bundle partial"
    assert runbook =~ "Review bundle overflow"
    assert runbook =~ "Review bundle zero/one/many"
    assert runbook =~ "Review bundle long text"
    assert runbook =~ "validate/3"
    assert runbook =~ "independently trusted default-branch control record"
    assert runbook =~ ~r/Do not derive it from the\s+bundle/
    refute runbook =~ "validate/2"

    assert runbook =~
             "Invoice light → dark, Statement light → dark, Payslip light → dark, Ticket light → dark"

    assert runbook =~ "full-size images"
    assert runbook =~ "rendro-catalog-visual-gallery--FULL_CANDIDATE_SHA--run-RUN_ID--attempt-1"
    assert runbook =~ "convenience-only"
    assert runbook =~ "never crosses into"
    assert runbook =~ "not an\nautomated visual score"
    assert runbook =~ "continue with explicit deferral"

    refute runbook =~ ".planning/phases"
    refute runbook =~ "approves a change"
    refute runbook =~ "publishes a change"
    refute runbook =~ "attests to"
  end

  test "workflow-adjacent docs contract is registered once and discoverable from the helper inventory" do
    runner = File.read!(@docs_runner_path)
    readme = File.read!(@scripts_readme_path)
    workflow = File.read!(@workflow_path)

    assert runner =~
             ~r/\{"Catalog evidence runbook lane",\s*\["test",\s*"test\/docs_contract\/catalog_evidence_runbook_test\.exs"\]\}/s

    lane_entries =
      Regex.scan(
        ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
        runner
      )

    assert length(lane_entries) == 28
    assert readme =~ "[Catalog Evidence runbook](../.github/workflows/CATALOG-EVIDENCE.md)"
    assert workflow =~ "name: Catalog Evidence"
  end
end

defmodule Rendro.DocsContract.LaunchExecutionClaimsTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/phases/88-launch-execution-demand-instrumentation"
  @checklist_path Path.join(@phase_dir, "88-LAUNCH-CHECKLIST.md")
  @copy_path Path.join(@phase_dir, "88-LAUNCH-COPY.md")
  @hexdocs_workflow_path ".github/workflows/hexdocs.yml"
  @public_url_script_path "scripts/verify_public_launch_urls.sh"
  @readiness_labels [
    "Claim-accuracy fixes are shipped",
    "Launch artifacts are published and byte-checked",
    "Comparison guide and Livebook are live",
    "Mobile evidence outcome is recorded",
    "Adoption signal ledger is ready",
    "Proactive outreach"
  ]
  @forbidden_claims [
    "Prawn equivalent",
    "HTML-to-PDF",
    "PDF/A compliant",
    "PDF/UA compliant",
    "works in every viewer",
    "mobile PDF support",
    "broad complex-script support"
  ]

  test "docs verification script includes exactly one launch execution claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"Launch execution claims lane"/, script)) == 1

    assert script =~
             ~r/\{"Launch execution claims lane",\s*\["test",\s*"test\/docs_contract\/launch_execution_claims_test\.exs"\]\}/s
  end

  test "quiet public checklist exposes proof readiness without publication obligations" do
    checklist = File.read!(@checklist_path)

    assert checklist =~ "# Phase 88 Quiet Public Checklist"
    assert checklist =~ "Quiet Public Posture"

    assert checklist =~
             "Rendro is public and findable through GitHub, HexDocs, proof links, and issue templates. No proactive announcement campaign is required."

    for label <- @readiness_labels do
      assert checklist =~ label
    end

    for status <- ["Ready", "Deferred with reason"] do
      assert checklist =~ status
    end

    refute checklist =~ "| Blocked |"

    for target <- [
          "GitHub README",
          "GitHub comparison guide",
          "GitHub Livebook",
          "GitHub ADOPTION.md",
          "HexDocs README",
          "HexDocs comparison guide",
          "HexDocs Livebook page"
        ] do
      assert checklist =~ target
    end
  end

  test "quiet public checklist defers proactive outreach instead of requiring publication order" do
    checklist = File.read!(@checklist_path)

    refute checklist =~ "## Publication Order"

    for label <- [
          "ElixirForum announcement",
          "ElixirStatus post",
          "awesome-elixir PR",
          "Demand-thread replies",
          "Mobile evidence follow-up post",
          "Show HN"
        ] do
      assert checklist =~ label
    end

    assert checklist =~ "Deferred Outreach"
    assert checklist =~ "Do not treat deferred outreach as blocked work"
  end

  test "quiet public copy contract contains first mention, reactive disclosure, and mobile boundary language" do
    copy = File.read!(@copy_path)

    assert copy =~
             "Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome."

    assert copy =~ "Disclosure: I maintain Rendro."
    assert copy =~ "For future readers"
    assert copy =~ "Rendro stays public and discoverable"
    assert copy =~ "Deferred unless explicitly opted in later"
    assert copy =~ "Do not make a blanket mobile-support claim."

    for label <- [
          "ElixirForum announcement",
          "ElixirStatus post",
          "awesome-elixir PR",
          "Demand-thread replies",
          "Mobile evidence follow-up post",
          "Show HN"
        ] do
      assert copy =~ label
    end
  end

  test "launch copy contract refutes unsupported launch claims" do
    copy = File.read!(@copy_path)

    for claim <- @forbidden_claims do
      refute copy =~ claim
    end
  end

  test "HexDocs workflow publishes docs-only from main with a repository secret" do
    workflow = File.read!(@hexdocs_workflow_path)

    assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(workflow)
    assert Map.has_key?(jobs, "verify-docs-ready")
    assert Map.has_key?(jobs, "publish-hexdocs")

    assert workflow =~ "name: HexDocs"
    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "permissions:\n  contents: read"
    assert workflow =~ "concurrency:"
    assert workflow =~ "branches:\n      - main"
    assert workflow =~ "if: github.event_name == 'push' && github.ref == 'refs/heads/main'"
    assert workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert workflow =~ "mix hex.publish docs --yes"
    assert workflow =~ "scripts/verify_public_launch_urls.sh"
    assert workflow =~ "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10"
    assert workflow =~ "erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7"

    refute workflow =~ ~r/mix hex\.publish --yes/
    refute workflow =~ ~r/^\s+environment:/m
  end

  test "public launch URL verifier covers GitHub raw and HexDocs proof routes" do
    script = File.read!(@public_url_script_path)

    assert script =~ "HEXDOCS_RETRIES"
    assert script =~ "https://raw.githubusercontent.com/szTheory/rendro/main/README.md"
    assert script =~ "Rendered Recipe Gallery"
    assert script =~ "https://raw.githubusercontent.com/szTheory/rendro/main/guides/comparison.md"
    assert script =~ "Generating PDFs in Elixir without Chrome"

    assert script =~
             "https://raw.githubusercontent.com/szTheory/rendro/main/guides/livebook/first_invoice.livemd"

    assert script =~ "First Invoice"
    assert script =~ "https://raw.githubusercontent.com/szTheory/rendro/main/ADOPTION.md"
    assert script =~ "# Adoption Signals"
    assert script =~ "https://hexdocs.pm/rendro/readme.html"
    assert script =~ "https://hexdocs.pm/rendro/comparison.html"
    assert script =~ "https://hexdocs.pm/rendro/first_invoice.html"
  end
end

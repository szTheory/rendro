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
    "Adoption signal ledger is ready"
  ]
  @publication_order [
    "ElixirForum announcement",
    "ElixirStatus",
    "awesome-elixir PR",
    "PDF generation without Chromium dependency",
    "Looking for a Prawn-Like PDF Generation Library in Elixir",
    "mobile evidence follow-up"
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

  test "launch checklist exposes CMP-03 and public URL readiness before publication" do
    checklist = File.read!(@checklist_path)

    assert checklist =~ "# Phase 88 Launch Checklist"
    assert checklist =~ "[BLOCKING] Launch readiness"
    assert checklist =~ "CMP-03"

    assert checklist =~
             "Launch is blocked until CMP-03 is reconciled and all required proof links are public. Update the requirements traceability, verify the Livebook link, then re-run the launch checklist."

    for label <- @readiness_labels do
      assert checklist =~ label
    end

    for status <- ["Ready", "Blocked", "Deferred with reason"] do
      assert checklist =~ status
    end

    for target <- [
          "GitHub README",
          "GitHub comparison guide",
          "GitHub Livebook",
          "GitHub ADOPTION.md",
          "HexDocs README",
          "HexDocs comparison guide",
          "HexDocs Livebook page",
          "ElixirForum hub",
          "ElixirStatus post",
          "awesome-elixir PR",
          "Chromium demand-thread reply",
          "Prawn-like demand-thread reply",
          "mobile evidence follow-up"
        ] do
      assert checklist =~ target
    end
  end

  test "launch checklist preserves the canonical publication order" do
    checklist = File.read!(@checklist_path)
    [_before, publication_order] = String.split(checklist, "## Publication Order", parts: 2)

    positions =
      Enum.map(@publication_order, fn label ->
        {label, :binary.match(publication_order, label)}
      end)

    for {label, match} <- positions do
      assert match != :nomatch, "missing publication step #{inspect(label)}"
    end

    assert Enum.map(positions, fn {_label, {position, _length}} -> position end) ==
             positions
             |> Enum.map(fn {_label, {position, _length}} -> position end)
             |> Enum.sort()
  end

  test "launch copy contract contains required title, first mention, disclosure, and mobile beat" do
    copy = File.read!(@copy_path)

    assert copy =~ "Rendro: Elixir-native PDF layout without Chrome"

    assert copy =~
             "Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome."

    assert copy =~ "Disclosure: I maintain Rendro."
    assert copy =~ "for future readers"
    assert copy =~ "What happens when a Rendro PDF reaches a phone?"
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
    assert workflow =~ "actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683"
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

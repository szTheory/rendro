defmodule Rendro.DocsContract.LaunchExecutionClaimsTest do
  use ExUnit.Case, async: true

  @phase_dirs [
    ".planning/phases/88-launch-execution-demand-instrumentation",
    ".planning/milestones/v2.6-phases/88-launch-execution-demand-instrumentation"
  ]
  @checklist_file "88-LAUNCH-CHECKLIST.md"
  @copy_file "88-LAUNCH-COPY.md"
  @hexdocs_workflow_path ".github/workflows/hexdocs.yml"
  @approved_hexdocs_candidate "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
  @approved_hexdocs_ref "v1.3.4"
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
    checklist = read_phase_artifact(@checklist_file)

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
    checklist = read_phase_artifact(@checklist_file)

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
    copy = read_phase_artifact(@copy_file)

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
    copy = read_phase_artifact(@copy_file)

    for claim <- @forbidden_claims do
      refute copy =~ claim
    end
  end

  test "HexDocs workflow publishes docs only from the sealed release identity" do
    workflow = File.read!(@hexdocs_workflow_path)

    assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(workflow)
    assert Map.has_key?(jobs, "verify-docs-ready")
    assert Map.has_key?(jobs, "publish-hexdocs")

    assert workflow =~ "name: HexDocs"
    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "permissions:\n  contents: read"
    assert workflow =~ "concurrency:"
    assert workflow =~ "branches:\n      - main"
    assert workflow =~ "candidate_commit_sha:"
    assert workflow =~ "release_ref:"
    assert workflow =~ "if: github.event_name == 'workflow_dispatch'"
    assert workflow =~ "ref: ${{ github.sha }}"
    assert workflow =~ "fetch-depth: 0"
    assert workflow =~ "Verify approved candidate identity"
    assert workflow =~ "APPROVED_CANDIDATE_SHA=\"f03c78bab54efe1cd1596d51cf3f28193232e2a3\""
    assert workflow =~ "APPROVED_RELEASE_REF=\"v1.3.4\""
    assert workflow =~ "INPUT_CANDIDATE_COMMIT_SHA: ${{ inputs.candidate_commit_sha }}"
    assert workflow =~ "INPUT_RELEASE_REF: ${{ inputs.release_ref }}"

    assert workflow =~
             "git fetch --force origin \"refs/tags/${APPROVED_RELEASE_REF}:refs/tags/${APPROVED_RELEASE_REF}\""

    assert workflow =~ "git checkout --detach \"$APPROVED_CANDIDATE_SHA\""
    assert workflow =~ "ARTIFACT_HEAD=$(git rev-parse HEAD)"
    assert workflow =~ "PEELED_TAG_SHA=$(git rev-parse \"${APPROVED_RELEASE_REF}^{}\")"
    assert workflow =~ "environment: 'Hex Publish'"
    assert workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert workflow =~ "mix hex.publish docs --yes"
    assert workflow =~ "scripts/verify_public_launch_urls.sh"
    assert workflow =~ "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10"
    assert workflow =~ "erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7"

    refute workflow =~ ~r/mix hex\.publish --yes/
  end

  test "docs verification fetches and validates the sealed annotated tag before contracts" do
    workflow = File.read!(@hexdocs_workflow_path)

    assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(workflow)
    verify_steps = jobs["verify-docs-ready"]["steps"]

    checkout_index = step_index!(verify_steps, "Checkout")
    identity_index = step_index!(verify_steps, "Verify sealed release identity")
    beam_index = step_index!(verify_steps, "Setup Beam")
    dependencies_index = step_index!(verify_steps, "Install Dependencies")
    contract_index = step_index!(verify_steps, "Verify Docs Contract")
    identity_step = Enum.at(verify_steps, identity_index)
    identity_run = identity_step["run"]

    assert checkout_index < identity_index
    assert identity_index < beam_index
    assert identity_index < dependencies_index
    assert identity_index < contract_index
    assert identity_run =~ "set -euo pipefail"
    assert identity_run =~ "APPROVED_CANDIDATE_SHA=\"#{@approved_hexdocs_candidate}\""
    assert identity_run =~ "APPROVED_RELEASE_REF=\"#{@approved_hexdocs_ref}\""

    assert identity_run =~
             "git fetch --force origin \"refs/tags/${APPROVED_RELEASE_REF}:refs/tags/${APPROVED_RELEASE_REF}\""

    assert identity_run =~ "TAG_OBJECT_TYPE=$(git cat-file -t \"${APPROVED_RELEASE_REF}\")"
    assert identity_run =~ "test \"$TAG_OBJECT_TYPE\" = tag"
    assert identity_run =~ "PEELED_TAG_SHA=$(git rev-parse \"${APPROVED_RELEASE_REF}^{}\")"
    assert identity_run =~ "test \"$PEELED_TAG_SHA\" = \"$APPROVED_CANDIDATE_SHA\""
    refute identity_run =~ "HEX_API_KEY"
  end

  test "the protected project and HexDocs identities are exact 1.3.4 while public installation stays range-based" do
    assert Mix.Project.config()[:version] == "1.3.4"
    assert File.read!("CHANGELOG.md") =~ "## [1.3.4] - Unreleased"
    assert File.read!("README.md") =~ "{:rendro, \"~> 1.3\"}"

    workflow = File.read!(@hexdocs_workflow_path)
    assert workflow =~ "ref: ${{ github.sha }}"
    assert workflow =~ "fetch-depth: 0"
    assert workflow =~ "test \"$INPUT_CANDIDATE_COMMIT_SHA\" = \"$APPROVED_CANDIDATE_SHA\""
    assert workflow =~ "test \"$INPUT_RELEASE_REF\" = \"$APPROVED_RELEASE_REF\""
    assert workflow =~ "test \"$ARTIFACT_HEAD\" = \"$APPROVED_CANDIDATE_SHA\""
    assert workflow =~ "test \"$PEELED_TAG_SHA\" = \"$APPROVED_CANDIDATE_SHA\""
  end

  test "HexDocs identity gate rejects another valid 1.3.4 commit without requiring a local tag" do
    source = File.read!(@hexdocs_workflow_path)

    refute source =~
             "System.cmd(\"git\", [\"rev-parse\", \"#{@approved_hexdocs_ref}^{}\"]"

    assert workflow_identity_matches_approved?(workflow_identity())

    assert workflow_identity_matches_approved?(%{
             workflow_identity()
             | github_sha: "trusted-control-ref-different-from-artifact"
           })

    other_commit = another_1_3_4_commit!()

    assert other_commit != @approved_hexdocs_candidate

    assert workflow_identity_matches_approved?(%{workflow_identity() | github_sha: other_commit})

    refute workflow_identity_matches_approved?(%{
             workflow_identity()
             | input_candidate_sha: other_commit
           })

    refute workflow_identity_matches_approved?(%{
             workflow_identity()
             | checkout_head: other_commit
           })

    refute workflow_identity_matches_approved?(%{
             workflow_identity()
             | peeled_tag_sha: other_commit
           })
  end

  test "secondary CI matrix uses an available OTP baseline for Elixir 1.19" do
    ci_workflow = File.read!(".github/workflows/ci.yml")

    assert ci_workflow =~ "- otp: '26'\n            elixir: '1.19.0'"
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

  defp read_phase_artifact(filename) do
    path =
      @phase_dirs
      |> Enum.map(&Path.join(&1, filename))
      |> Enum.find(&File.exists?/1)

    path || flunk("Could not find #{filename} in active phase dir or v2.6 milestone archive")
    File.read!(path)
  end

  defp workflow_identity do
    %{
      github_sha: @approved_hexdocs_candidate,
      input_candidate_sha: @approved_hexdocs_candidate,
      input_release_ref: @approved_hexdocs_ref,
      checkout_head: @approved_hexdocs_candidate,
      peeled_tag_sha: @approved_hexdocs_candidate,
      mix_version: "1.3.4"
    }
  end

  defp workflow_identity_matches_approved?(identity) do
    identity.input_candidate_sha == @approved_hexdocs_candidate and
      identity.input_release_ref == @approved_hexdocs_ref and
      identity.checkout_head == @approved_hexdocs_candidate and
      identity.peeled_tag_sha == @approved_hexdocs_candidate and
      identity.mix_version == "1.3.4"
  end

  defp step_index!(steps, name) do
    Enum.find_index(steps, &(&1["name"] == name)) || flunk("Missing workflow step: #{name}")
  end

  defp another_1_3_4_commit! do
    {commits, 0} = System.cmd("git", ["rev-list", "--all"], stderr_to_stdout: true)

    commits
    |> String.split("\n", trim: true)
    |> Enum.find(fn commit ->
      commit != @approved_hexdocs_candidate and version_at_commit?(commit, "1.3.4")
    end)
    |> case do
      nil -> flunk("Could not find another real commit that declares version 1.3.4")
      commit -> commit
    end
  end

  defp version_at_commit?(commit, version) do
    {mix_exs, 0} = System.cmd("git", ["show", "#{commit}:mix.exs"], stderr_to_stdout: true)

    mix_exs =~ ~r/^\s*@version\s+"#{Regex.escape(version)}"\s*$/m
  end
end

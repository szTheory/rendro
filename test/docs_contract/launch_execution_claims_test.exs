defmodule Rendro.DocsContract.LaunchExecutionClaimsTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/phases/88-launch-execution-demand-instrumentation"
  @checklist_path Path.join(@phase_dir, "88-LAUNCH-CHECKLIST.md")
  @copy_path Path.join(@phase_dir, "88-LAUNCH-COPY.md")
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

  @tag skip: "unskip after 88-LAUNCH-CHECKLIST.md is created"
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

  @tag skip: "unskip after 88-LAUNCH-CHECKLIST.md is created"
  test "launch checklist preserves the canonical publication order" do
    checklist = File.read!(@checklist_path)

    positions =
      Enum.map(@publication_order, fn label ->
        {label, :binary.match(checklist, label)}
      end)

    for {label, match} <- positions do
      assert match != :nomatch, "missing publication step #{inspect(label)}"
    end

    assert Enum.map(positions, fn {_label, {position, _length}} -> position end) ==
             positions |> Enum.map(fn {_label, {position, _length}} -> position end) |> Enum.sort()
  end

  @tag skip: "unskip after 88-LAUNCH-COPY.md is created"
  test "launch copy contract contains required title, first mention, disclosure, and mobile beat" do
    copy = File.read!(@copy_path)

    assert copy =~ "Rendro: Elixir-native PDF layout without Chrome"

    assert copy =~
             "Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome."

    assert copy =~ "Disclosure: I maintain Rendro."
    assert copy =~ "for future readers"
    assert copy =~ "What happens when a Rendro PDF reaches a phone?"
  end

  @tag skip: "unskip after 88-LAUNCH-COPY.md is created"
  test "launch copy contract refutes unsupported launch claims" do
    copy = File.read!(@copy_path)

    for claim <- @forbidden_claims do
      refute copy =~ claim
    end
  end
end

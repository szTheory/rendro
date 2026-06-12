defmodule Rendro.DocsContract.AdoptionClaimsTest do
  use ExUnit.Case, async: true

  @adoption_path "ADOPTION.md"
  @required_sections [
    "Purpose",
    "Current Gate: v2.7 Global Text Shaping",
    "Gate Thresholds",
    "Launch Snapshot",
    "Signal Ledger",
    "Download Snapshots",
    "External Contributors",
    "Review Log"
  ]
  @ledger_columns [
    "ID",
    "Date",
    "Source URL",
    "Channel",
    "Requester",
    "Org/App",
    "Gate Area",
    "Script/Language",
    "Document Job",
    "Blocking?",
    "Qualifies?",
    "Count Group",
    "Notes"
  ]
  @threshold_sentences [
    "6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must block production or evaluation.",
    "Since launch snapshot, Hex downloads.all increases by at least 1,500 and downloads.week >= 150 on two snapshots at least 14 days apart after launch week.",
    "At least 1 merged, non-maintainer PR after launch that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case. Typos, bots, Dependabot, and maintainer alternate accounts do not count."
  ]

  test "docs verification script includes exactly one adoption claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"Adoption claims lane"/, script)) == 1

    assert script =~
             ~r/\{"Adoption claims lane",\s*\["test",\s*"test\/docs_contract\/adoption_claims_test\.exs"\]\}/s
  end

  test "ADOPTION.md exists at the repository root with the required section order" do
    adoption = File.read!(@adoption_path)

    assert adoption =~ "# Adoption Signals"

    positions =
      Enum.map(@required_sections, fn section ->
        {section, :binary.match(adoption, "## #{section}")}
      end)

    for {section, match} <- positions do
      assert match != :nomatch, "missing required section #{section}"
    end

    assert Enum.map(positions, fn {_section, {position, _length}} -> position end) ==
             positions |> Enum.map(fn {_section, {position, _length}} -> position end) |> Enum.sort()
  end

  test "adoption gate threshold text and contributor exclusions are exact" do
    adoption = File.read!(@adoption_path)

    for sentence <- @threshold_sentences do
      assert adoption =~ sentence
    end
  end

  test "signal ledger columns and empty states are explicit" do
    adoption = File.read!(@adoption_path)

    assert adoption =~ Enum.join(@ledger_columns, " | ")
    assert adoption =~ "No qualifying shaping signals have been counted yet."
    assert adoption =~ "No post-launch Hex download snapshots recorded yet."
    assert adoption =~ "No qualifying non-maintainer contributor signal has been counted yet."
  end

  test "review cadence and counting exclusions stay measurable" do
    adoption = File.read!(@adoption_path)

    for phrase <- ["L+30", "L+60", "L+90", "monthly", "cannot trigger before L+45"] do
      assert adoption =~ phrase
    end

    for phrase <- [
          "concrete document job",
          "script/language",
          "current blocker",
          "source URL",
          "Same requester/org/use case counts once per 90-day window",
          "Private adopter reports may be anonymized but cap at 2 counted signals per window",
          "generic i18n wishes do not qualify"
        ] do
      assert adoption =~ phrase
    end

    for forbidden <- ["stars count", "+1 counts", "adoption:counted default"] do
      refute adoption =~ forbidden
    end
  end

  test "review workflow commands are documented without runtime telemetry" do
    adoption = File.read!(@adoption_path)

    assert adoption =~ "curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'"
    assert adoption =~ ~s|gh issue list --state all --label "adoption:signal"|
    assert adoption =~ ~s|gh issue list --state all --label "area:text-shaping"|
    assert adoption =~ ~s|gh pr list --state merged --search "merged:>=$LAUNCH_DATE -author:szTheory"|
  end

  @tag skip: "unskip after ADOPTION.md is linked from public docs"
  test "README and comparison guide link to ADOPTION.md" do
    assert File.read!("README.md") =~ "ADOPTION.md"
    assert File.read!("guides/comparison.md") =~ "ADOPTION.md"
  end
end

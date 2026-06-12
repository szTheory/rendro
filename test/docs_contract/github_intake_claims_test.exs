defmodule Rendro.DocsContract.GithubIntakeClaimsTest do
  use ExUnit.Case, async: true

  @issue_dir ".github/ISSUE_TEMPLATE"
  @discussion_path ".github/DISCUSSION_TEMPLATE/use-cases.yml"
  @required_issue_templates [
    ".github/ISSUE_TEMPLATE/01_bug.yml",
    ".github/ISSUE_TEMPLATE/02_blocked_document.yml",
    ".github/ISSUE_TEMPLATE/config.yml"
  ]
  @use_case_fields [
    "document type",
    "Phoenix/Elixir context",
    "blocker",
    "script/language",
    "workaround",
    "production/evaluation"
  ]

  test "docs verification script includes exactly one GitHub intake claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"GitHub intake claims lane"/, script)) == 1

    assert script =~
             ~r/\{"GitHub intake claims lane",\s*\["test",\s*"test\/docs_contract\/github_intake_claims_test\.exs"\]\}/s
  end

  test "Phase 88 requires only the locked issue template set" do
    for path <- @required_issue_templates do
      assert File.exists?(path)
    end

    actual =
      @issue_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".yml"))
      |> Enum.map(&Path.join(@issue_dir, &1))
      |> Enum.sort()

    assert actual == Enum.sort(@required_issue_templates)
  end

  test "blocked-document intake defaults to signal triage without counted labels" do
    blocked = File.read!(".github/ISSUE_TEMPLATE/02_blocked_document.yml")

    assert blocked =~ ~s|labels: ["state:triage", "adoption:signal"]|
    assert blocked =~ "A maintainer applies `adoption:counted` only after checking ADOPTION.md rules"
    refute blocked =~ ~r/^labels:.*adoption:counted/m
  end

  test "GitHub issue config disables blank issues and routes discovery outward" do
    config = File.read!(".github/ISSUE_TEMPLATE/config.yml")

    assert config =~ "blank_issues_enabled: false"
    assert config =~ "Discussions"
    assert config =~ "ElixirForum"
  end

  test "blocked-document form collects adoption-gate review fields" do
    blocked = File.read!(".github/ISSUE_TEMPLATE/02_blocked_document.yml")

    for field <- [
          "document job",
          "expected behavior",
          "blocker",
          "script/language",
          "production/evaluation",
          "workaround",
          "fixture",
          "source URL",
          "permission to quote",
          "anonymize"
        ] do
      assert String.downcase(blocked) =~ String.downcase(field)
    end
  end

  @tag skip: "unskip after GitHub discussion template is created"
  test "use-cases discussion template asks for the six required fields when present" do
    discussion = File.read!(@discussion_path)

    for field <- @use_case_fields do
      assert String.downcase(discussion) =~ String.downcase(field)
    end
  end
end

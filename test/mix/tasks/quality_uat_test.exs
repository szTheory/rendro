defmodule Mix.Tasks.Quality.UatTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Quality.Uat

  defp summary(id, opts \\ []) do
    requirement = Keyword.get(opts, :requirement, "ARCH-01")

    coverage =
      Keyword.get(opts, :coverage, """
        - id: #{id}
          description: deterministic proof #{id}
          requirement: #{requirement}
          verification:
            - kind: integration
              ref: mix test test/mix/tasks/quality_uat_test.exs
              status: pass
          human_judgment: false
      """)

    """
    ---
    phase: 134-core
    plan: \"01\"
    status: complete
    requirements-completed: [#{requirement}]
    coverage:
    #{coverage}
    ---
    # Summary

    Advisory review remains outside coverage and cannot become a UAT item.
    """
  end

  test "parses installed deterministic coverage and renders terminal UAT" do
    assert {:ok, records} = Uat.parse_summary("134-01-SUMMARY.md", summary("D1"))
    assert [%{id: "D1", source: "134-01-SUMMARY.md"}] = records

    output = Uat.render("134", "core", records)
    assert output =~ "status: terminal"
    assert output =~ "### 1. D1 — deterministic proof D1"
    assert output =~ "result: pass\n"
    assert output =~ "passed: 1"
  end

  test "rejects malformed coverage shapes with precise diagnostics" do
    mutations = [
      {"legacy scalar", String.replace(summary("D1"), "coverage:\n", "coverage: legacy\n")},
      {"human", String.replace(summary("D1"), "human_judgment: false", "human_judgment: true")},
      {"nonpass", String.replace(summary("D1"), "status: pass", "status: pending")},
      {"unknown key",
       String.replace(
         summary("D1"),
         "human_judgment: false",
         "extra: nope\n  human_judgment: false"
       )},
      {"duplicate",
       String.replace(
         summary("D1"),
         "human_judgment: false",
         "human_judgment: false\n" <>
           String.trim_leading(
             summary("D1"),
             "---\nphase: 134-core\nplan: \"01\"\nstatus: complete\nrequirements-completed: [ARCH-01]\ncoverage:\n"
           )
       )}
    ]

    for {name, document} <- mutations do
      assert {:error, message} = Uat.parse_summary("134-01-SUMMARY.md", document), name
      assert message =~ "134-01-SUMMARY.md"
    end
  end

  test "accepts same coverage id from distinct summaries but not one source" do
    assert {:ok, _} = Uat.parse_summary("134-01-SUMMARY.md", summary("D1"))
    assert {:ok, _} = Uat.parse_summary("134-02-SUMMARY.md", summary("D1"))

    duplicate =
      String.replace(
        summary("D1"),
        "human_judgment: false",
        "human_judgment: false\n  - id: D1\n    description: duplicate\n    verification:\n      - kind: test\n        ref: mix test\n        status: pass\n    human_judgment: false"
      )

    assert {:error, message} = Uat.parse_summary("134-01-SUMMARY.md", duplicate)
    assert message =~ "duplicate coverage id"
  end

  test "rejects prose, missing targets, shell syntax, and traversal in automated refs" do
    for ref <- [
          "mix test imaginary and focused prose",
          "mix test test/missing_test.exs",
          "mix test test/mix/tasks/quality_uat_test.exs; rm x",
          "mix test test/../mix/tasks/quality_uat_test.exs"
        ] do
      document =
        String.replace(summary("D1"), "mix test test/mix/tasks/quality_uat_test.exs", ref)

      assert {:error, _} = Uat.parse_summary("fixture.md", document)
    end
  end

  test "installed GSD classifier accepts every Phase 134 summary as automated coverage" do
    summaries =
      Path.wildcard(".planning/phases/134-core-architecture-readability/134-*-SUMMARY.md")

    for summary_path <- summaries do
      {output, 0} =
        System.cmd("node", [
          "/Users/jon/.codex/gsd-core/bin/gsd-tools.cjs",
          "uat",
          "classify-coverage",
          "--summary",
          summary_path
        ])

      classified = JSON.decode!(output)
      assert classified["mode"] == "coverage"
      assert classified["errors"] == []
      assert classified["all_auto_covered"] == true
    end
  end

  test "full phase slug resolves through the public Mix task" do
    Mix.Task.reenable("quality.uat")
    assert :ok = Mix.Tasks.Quality.Uat.run(["134-core-architecture-readability", "--check"])
  end
end

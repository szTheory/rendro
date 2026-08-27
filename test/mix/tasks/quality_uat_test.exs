defmodule Mix.Tasks.Quality.UatTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Quality.Uat

  setup do
    root = Path.join(System.tmp_dir!(), "rendro-uat-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, ".planning/phases"))
    on_exit(fn -> File.rm_rf(root) end)
    %{root: root}
  end

  defp write_phase(root, name, uat? \\ true) do
    [_, number, slug] = Regex.run(~r/^(\d+)-(.+)$/, name)
    dir = Path.join([root, ".planning", "phases", name])
    File.mkdir_p!(dir)
    summary_name = "#{number}-01-SUMMARY.md"
    File.write!(Path.join(dir, summary_name), summary("D1", phase: "#{number}-#{slug}"))

    if uat?,
      do:
        File.write!(
          Path.join(dir, "#{number}-UAT.md"),
          Uat.render(String.to_integer(number), slug, [
            %{
              id: "D1",
              description: "deterministic proof D1",
              verification: [%{"ref" => "mix test test/mix/tasks/quality_uat_test.exs"}],
              source: summary_name
            }
          ])
        )

    dir
  end

  defp summary(id, opts \\ []) do
    requirement = Keyword.get(opts, :requirement, "ARCH-01")
    phase = Keyword.get(opts, :phase, "134-core")

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
    phase: #{phase}
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

  test "temporary root accepts numeric and full slug and rejects missing or stale UAT", %{
    root: root
  } do
    dir = write_phase(root, "134-core")
    assert :ok = Uat.run(["134", "--check"], root)
    assert :ok = Uat.run(["134-core", "--check"], root)

    File.write!(Path.join(dir, "134-UAT.md"), "stale\n")
    assert_raise Mix.Error, fn -> Uat.run(["134", "--check"], root) end

    File.write!(
      Path.join(dir, "134-UAT.md"),
      Uat.render(134, "core", [
        %{
          id: "D1",
          description: "deterministic proof D1",
          verification: [%{"ref" => "mix test test/mix/tasks/quality_uat_test.exs"}],
          source: "134-01-SUMMARY.md"
        }
      ])
    )

    File.rm!(Path.join(dir, "134-UAT.md"))
    assert_raise Mix.Error, fn -> Uat.run(["134", "--check"], root) end
  end

  test "temporary root rejects ambiguity and unsafe selectors", %{root: root} do
    write_phase(root, "134-one")
    write_phase(root, "134-two")
    assert_raise Mix.Error, fn -> Uat.run(["134", "--check"], root) end

    for selector <- ["/tmp/no", "../134", "134/foo", "134\\foo"] do
      assert_raise Mix.Error, fn -> Uat.run([selector, "--check"], root) end
    end
  end

  test "all-mode ignores pre-134 phases and check mode performs no writes", %{root: root} do
    write_phase(root, "132-legacy", false)
    dir = write_phase(root, "134-core")
    summary_path = Path.join(dir, "134-01-SUMMARY.md")
    uat_path = Path.join(dir, "134-UAT.md")
    before = {File.read!(summary_path), File.read!(uat_path), Enum.sort(File.ls!(dir))}

    assert :ok = Uat.run(["--all", "--check"], root)
    assert {File.read!(summary_path), File.read!(uat_path), Enum.sort(File.ls!(dir))} == before
  end

  test "phase and summary symlinks fail closed, including outside-root targets", %{root: root} do
    outside =
      Path.join(System.tmp_dir!(), "rendro-uat-outside-#{System.unique_integer([:positive])}")

    File.mkdir_p!(outside)
    on_exit(fn -> File.rm_rf(outside) end)

    outside_phase = Path.join(outside, "phase")
    File.mkdir_p!(outside_phase)
    phase_link = Path.join([root, ".planning", "phases", "134-linked"])
    File.ln_s!(outside_phase, phase_link)

    assert_raise Mix.Error, ~r/symlinked phase directory/, fn ->
      Uat.run(["134-linked", "--check"], root)
    end

    assert_raise Mix.Error, ~r/symlinked phase directory/, fn ->
      Uat.run(["--all", "--check"], root)
    end

    File.rm!(phase_link)
    dir = write_phase(root, "134-core")
    summary_path = Path.join(dir, "134-01-SUMMARY.md")
    outside_summary = Path.join(outside, "134-01-SUMMARY.md")
    File.write!(outside_summary, File.read!(summary_path))
    File.rm!(summary_path)
    File.ln_s!(outside_summary, summary_path)

    assert_raise Mix.Error, ~r/symlinked summary/, fn ->
      Uat.run(["134", "--check"], root)
    end
  end

  test "symlinked UAT cannot satisfy check mode", %{root: root} do
    dir = write_phase(root, "134-core")
    uat_path = Path.join(dir, "134-UAT.md")
    target = Path.join(root, "outside-uat.md")
    File.write!(target, File.read!(uat_path))
    File.rm!(uat_path)
    File.ln_s!(target, uat_path)

    assert_raise Mix.Error, ~r/symlinked UAT/, fn ->
      Uat.run(["134", "--check"], root)
    end
  end
end

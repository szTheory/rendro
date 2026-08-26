defmodule Rendro.RepositoryHygieneTest do
  use ExUnit.Case, async: true

  alias Rendro.RepositoryHygiene

  @manifest "priv/quality/package-members-v1.json"

  test "the expected manifest names the six owned comparison assets and adoption exception" do
    manifest = @manifest |> File.read!() |> JSON.decode!()

    assert manifest["version"] == 1
    assert manifest["members"] == Enum.sort(manifest["members"])

    assert Enum.filter(manifest["members"], &String.starts_with?(&1, "bench/results/")) == [
             "bench/results/comparison.json",
             "bench/results/raw/chromic_pdf.json",
             "bench/results/raw/chromic_pdf_warm_pool.json",
             "bench/results/raw/pdf_generator.json",
             "bench/results/raw/rendro.json",
             "bench/results/raw/typst_cli.json"
           ]

    assert manifest["exceptions"] == [
             %{
               "path" => "priv/adoption_evidence/2026-08-21.json",
               "owner" => "adoption evidence maintainer",
               "reason" => "D-07 public adoption decision evidence",
               "review_trigger" => "Review when the adoption evidence contract changes."
             }
           ]
  end

  test "member policy reports missing unexpected and forbidden paths in stable order" do
    manifest = %{"members" => ["README.md", "lib/rendro.ex"]}

    assert {:error, diagnostics} =
             RepositoryHygiene.check_members(
               [".planning/QUALITY.md", "README.md", "scripts/leak.exs"],
               manifest
             )

    assert diagnostics == Enum.sort(diagnostics)
    assert Enum.any?(diagnostics, &String.contains?(&1, "missing package member: lib/rendro.ex"))

    assert Enum.any?(
             diagnostics,
             &String.contains?(&1, "unexpected package member: .planning/QUALITY.md")
           )

    assert Enum.any?(
             diagnostics,
             &String.contains?(&1, "forbidden package member: scripts/leak.exs")
           )
  end

  test "tracked placement is NUL-safe and permits only active or archived phase shapes" do
    nul_paths =
      ".planning/phases/133-repository-evidence-hygiene/133-11-PLAN.md\0" <>
        ".planning/milestones/v1.8-phases/45-acroform-text-field-foundation/45-01-PLAN.md\0" <>
        ".planning/phases/obsolete plan.md\0"

    assert {:error, diagnostics} = RepositoryHygiene.check_tracked_paths(nul_paths)
    assert diagnostics == Enum.sort(diagnostics)
    assert Enum.any?(diagnostics, &String.contains?(&1, "invalid planning placement"))
  end

  test "operational scans reject archive consumers but allow the narrow gsd tooling exception" do
    sources = %{
      "lib/rendro.ex" => "File.read!(\".planning/phases/131-old/131-FACTS.md\")",
      "scripts/quality_governance.cjs" =>
        "const path = '.planning/phases/132-quality-baseline-triage';",
      "scripts/archive_reader.sh" => "cat .planning/phases/131-old/131-FACTS.md",
      "dev/rendro/repository_hygiene.ex" => "Regex.match?(~r{^\\.planning/phases/}, path)"
    }

    assert {:error, diagnostics} = RepositoryHygiene.check_operational_sources(sources)
    assert Enum.any?(diagnostics, &String.contains?(&1, "archive consumer"))
    assert Enum.any?(diagnostics, &String.contains?(&1, "scripts/archive_reader.sh"))
    refute Enum.any?(diagnostics, &String.contains?(&1, "scripts/quality_governance.cjs"))
    refute Enum.any?(diagnostics, &String.contains?(&1, "dev/rendro/repository_hygiene.ex"))
  end

  test "script inventory requires each tracked script to have an owner-bearing row" do
    inventory =
      "| `scripts/owned.exs` | owner | purpose | inputs | regression | caller | remove trigger |\n"

    assert {:error, diagnostics} =
             RepositoryHygiene.check_script_inventory(inventory, [
               "scripts/owned.exs",
               "scripts/unowned.exs"
             ])

    assert diagnostics == [
             "scripts/unowned.exs: missing owner-bearing inventory row; add the script to scripts/README.md or remove it."
           ]
  end

  test "private runs use distinct temp roots, clean them after failure, and leave authoritative bytes unchanged" do
    authoritative = File.read!(@manifest)

    parent =
      Path.join(System.tmp_dir!(), "rendro-hygiene-test-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(parent) end)
    test_process = self()

    runner = fn root ->
      File.mkdir_p!(root)
      send(test_process, {:hygiene_root, root})
      {:error, ["forced failure"]}
    end

    runs =
      for _ <- 1..2 do
        Task.async(fn ->
          RepositoryHygiene.run(build: runner, temp_parent: parent, skip_checks: true)
        end)
      end

    assert Enum.map(runs, &Task.await(&1, 5_000)) == [
             {:error, ["forced failure"]},
             {:error, ["forced failure"]}
           ]

    assert_receive {:hygiene_root, first_root}
    assert_receive {:hygiene_root, second_root}
    refute File.exists?(first_root)
    refute first_root == second_root
    refute File.exists?(second_root)
    assert File.read!(@manifest) == authoritative
  end
end

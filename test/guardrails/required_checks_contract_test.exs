defmodule Guardrails.RequiredChecksContractTest do
  use ExUnit.Case, async: true

  @baseline_path "priv/guardrails/required_status_checks.json"
  @ci_path ".github/workflows/ci.yml"
  @verify_docs_path "scripts/verify_docs.exs"

  @required_contexts ~w(long-lived-live-proof release-proof signing-live-proof test)

  describe "baseline JSON integrity" do
    test "parses with sorted required contexts, strict policy, and additive_only policy" do
      baseline = load_baseline!()

      assert baseline["schema_version"] == 1
      assert baseline["branch"] == "main"
      assert baseline["strict"] == true
      assert baseline["policy"] == "additive_only"
      assert baseline["since_milestone"] == "v2.3"
      assert baseline["required_contexts"] == Enum.sort(@required_contexts)
      assert length(baseline["contexts"]) == 4

      assert baseline["supersedes_planning_refs"]["pitfalls_7_viewer_evidence_schema_required"] ==
               false

      test_context = Enum.find(baseline["contexts"], &(&1["name"] == "test"))
      assert test_context["notes"] =~ "Phase 68 D-18"
      assert test_context["notes"] =~ "Viewer-evidence"
    end

    test "advisory contexts document viewer-evidence-live-proof as not required" do
      baseline = load_baseline!()

      viewer =
        Enum.find(baseline["advisory_contexts"], &(&1["name"] == "viewer-evidence-live-proof"))

      assert viewer["notes"] =~ "not required"
      assert viewer["notes"] =~ "D-32"

      example = Enum.find(baseline["advisory_contexts"], &(&1["name"] == "example-phoenix"))
      assert example, "example-phoenix advisory context must exist"
      assert example["notes"] =~ "not required"
      assert example["notes"] =~ "REF-03"
      refute "example-phoenix" in baseline["required_contexts"]
    end

    test "raster-advisory remains advisory and documents launch artifact checking" do
      baseline = load_baseline!()

      raster = advisory_context!(baseline, "raster-advisory")

      refute "raster-advisory" in baseline["required_contexts"]

      assert raster["command"] =~
               "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs"

      assert raster["command"] =~ "mix rendro.launch_artifacts.check"
      assert raster["notes"] =~ "Phase 86"
      assert raster["notes"] =~ "not required"
    end

    test "comparison and livebook checks remain advisory and non-required" do
      baseline = load_baseline!()

      expected_advisory_contexts = [
        {"comparison-advisory", "comparison_static_advisory", "mix rendro.comparison.check"},
        {"livebook-advisory", "livebook_execution", "mix rendro.livebook.check"}
      ]

      for {name, semantic_class, command} <- expected_advisory_contexts do
        context = advisory_context!(baseline, name)

        assert context["semantic_class"] == semantic_class
        assert context["ci_job"] == name
        assert context["command"] == command
        assert context["notes"] =~ "Phase 87"
        assert context["notes"] =~ "not required"
        refute name in baseline["required_contexts"]
      end
    end

    test "ci.yml parses as YAML" do
      ci = File.read!(@ci_path)

      assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(ci)
      assert is_map(jobs)
    end
  end

  describe "ci.yml job names" do
    test "contains required and advisory job keys" do
      ci = File.read!(@ci_path)

      for job <-
            @required_contexts ++
              [
                "viewer-evidence-live-proof",
                "example-phoenix",
                "raster-advisory",
                "comparison-advisory",
                "livebook-advisory"
              ] do
        assert ci =~ "  #{job}:"
      end
    end

    test "each required context has a matching jobs block" do
      ci = File.read!(@ci_path)

      for context <- @required_contexts do
        assert ci =~ "  #{context}:"
      end
    end
  end

  describe "behavioral command wiring" do
    test "signing-live-proof runs live_signing against signing_live_test.exs" do
      ci = File.read!(@ci_path)

      assert ci =~ "mix test --include live_signing test/rendro/adapters/signing_live_test.exs"
    end

    test "long-lived-live-proof runs live_pdf_tools against signing_live_test.exs" do
      ci = File.read!(@ci_path)

      assert ci =~
               "mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs"
    end

    test "baseline JSON commands match behavioral wiring substrings" do
      baseline = load_baseline!()

      signing =
        baseline["contexts"]
        |> Enum.find(&(&1["name"] == "signing-live-proof"))

      long_lived =
        baseline["contexts"]
        |> Enum.find(&(&1["name"] == "long-lived-live-proof"))

      assert signing["command"] =~ "live_signing"
      assert signing["command"] =~ "signing_live_test.exs"
      assert long_lived["command"] =~ "live_pdf_tools"
      assert long_lived["command"] =~ "signing_live_test.exs"
    end
  end

  describe "docs-contract lane count" do
    test "verify_docs.exs registers exactly twenty lanes including launch and GitHub intake lanes" do
      script = File.read!(@verify_docs_path)

      lane_entries =
        Regex.scan(
          ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
          script
        )

      assert length(lane_entries) == 20

      assert script =~
               ~r/\{"Viewer evidence semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/viewer_evidence_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Comparison claims lane",\s*\["test",\s*"test\/docs_contract\/comparison_claims_test\.exs"\]\}/s
    end
  end

  describe "mix ci alias structural validation" do
    test "ci alias includes structural validation steps folded into test context" do
      project = Rendro.MixProject.project()
      aliases = Keyword.fetch!(project, :aliases)
      ci_steps = Keyword.fetch!(aliases, :ci)

      assert ci_steps == [
               "format --check-formatted",
               "hex.build",
               "compile --warnings-as-errors",
               "test",
               "docs",
               "credo --strict",
               "dialyzer"
             ]
    end
  end

  describe "required/advisory CI separation" do
    test "required test job runs only the deterministic mix ci lane" do
      ci = File.read!(@ci_path)
      test_block = ci_job_block!(ci, "test")

      assert test_block =~ "run: mix ci"

      forbidden_required_fragments = [
        "pdfium-cli",
        "curl -fsSL",
        "rendro.launch_artifacts.check",
        "Rendro.Adapters.Pdfium.render",
        "rendro.comparison.check",
        "rendro.livebook.check",
        "chrome",
        "wkhtmltopdf",
        "typst",
        "Livebook",
        "Kino",
        "docker"
      ]

      for fragment <- forbidden_required_fragments do
        refute test_block =~ fragment
      end
    end

    test "raster-advisory is graph-disconnected and non-blocking" do
      ci = File.read!(@ci_path)
      raster_block = ci_job_block!(ci, "raster-advisory")

      assert raster_block =~ "continue-on-error: true"

      assert raster_block =~
               "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs"

      assert raster_block =~ "mix rendro.launch_artifacts.check"
      refute raster_block =~ ~r/^\s+needs:/m
    end

    test "comparison and livebook advisory jobs are graph-disconnected and non-blocking" do
      ci = File.read!(@ci_path)

      expected_advisory_jobs = [
        {"comparison-advisory", "mix rendro.comparison.check"},
        {"livebook-advisory", "mix rendro.livebook.check"}
      ]

      for {job, command} <- expected_advisory_jobs do
        block = ci_job_block!(ci, job)

        assert block =~ "continue-on-error: true"
        assert block =~ "run: mix deps.get"
        assert block =~ "run: #{command}"
        refute block =~ ~r/^\s+needs:/m
      end
    end

    test "release-proof is bounded and runs the isolated proof wrapper" do
      ci = File.read!(@ci_path)
      release_block = ci_job_block!(ci, "release-proof")

      assert release_block =~ "timeout-minutes: 45"

      assert release_block =~
               ~s(mix run scripts/release_preflight_proof.exs --current-version-tag --worktree "$RUNNER_TEMP/rendro-release-proof")
    end
  end

  describe "baseline ci_job alignment" do
    test "each required and advisory ci_job exists in ci.yml" do
      baseline = load_baseline!()
      ci = File.read!(@ci_path)

      for context <- baseline["contexts"] ++ baseline["advisory_contexts"] do
        assert ci =~ "  #{context["ci_job"]}:"
      end
    end
  end

  describe "fork-safe offline contract" do
    test "does not reference network APIs or tokens" do
      source = File.read!(__ENV__.file)

      refute source =~ ~r/\bReq\./
      refute source =~ ~r/\bHTTPoison\b/
      refute source =~ Enum.join(["gh", " ", "api"])
      refute source =~ Enum.join(["GITHUB_", "TOKEN"])
    end
  end

  defp load_baseline! do
    @baseline_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp advisory_context!(baseline, name) do
    Enum.find(baseline["advisory_contexts"], &(&1["name"] == name)) ||
      flunk("expected advisory context #{inspect(name)}")
  end

  defp ci_job_block!(ci, job_name) do
    escaped_job_name = Regex.escape(job_name)
    pattern = ~r/^  #{escaped_job_name}:\n(?:(?!^  [A-Za-z0-9_-]+:).*(?:\n|$))*/m

    case Regex.run(pattern, ci) do
      [block] -> block
      _ -> flunk("expected CI job block #{inspect(job_name)}")
    end
  end
end

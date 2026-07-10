defmodule Guardrails.RequiredChecksContractTest do
  use ExUnit.Case, async: true

  @baseline_path "priv/guardrails/required_status_checks.json"
  @ci_path ".github/workflows/ci.yml"
  @hexdocs_path ".github/workflows/hexdocs.yml"
  @release_path ".github/workflows/release.yml"
  @verify_docs_path "scripts/verify_docs.exs"

  @required_contexts ~w(ci-success)

  describe "baseline JSON integrity" do
    test "parses with sorted required contexts, strict policy, and additive_only policy" do
      baseline = load_baseline!()

      assert baseline["schema_version"] == 1
      assert baseline["branch"] == "main"
      assert baseline["strict"] == true
      assert baseline["policy"] == "additive_only"
      assert baseline["since_milestone"] == "v2.3"
      assert baseline["required_contexts"] == Enum.sort(@required_contexts)
      assert length(baseline["contexts"]) == 3

      assert baseline["supersedes_planning_refs"]["pitfalls_7_viewer_evidence_schema_required"] ==
               false

      test_context = Enum.find(baseline["contexts"], &(&1["name"] == "test"))
      assert test_context["notes"] =~ "Phase 68 D-18"
      assert test_context["notes"] =~ "Viewer-evidence"
    end

    test "advisory contexts document combined advisory checks" do
      baseline = load_baseline!()

      advisory =
        Enum.find(baseline["advisory_contexts"], &(&1["name"] == "advisory-checks"))

      assert advisory["notes"] =~ "viewer-evidence-live-proof"
      assert advisory["notes"] =~ "raster-advisory"
      assert advisory["notes"] =~ "D-32"
      assert advisory["notes"] =~ "REF-03"
      assert advisory["command"] =~ "scripts/pdfjs_observer"

      example = Enum.find(baseline["advisory_contexts"], &(&1["name"] == "example-phoenix"))
      assert example, "example-phoenix advisory context must exist"
      assert example["notes"] =~ "not required"
      assert example["notes"] =~ "REF-03"
      refute "example-phoenix" in baseline["required_contexts"]
    end

    test "ci.yml parses as YAML" do
      ci = File.read!(@ci_path)

      assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(ci)
      assert is_map(jobs)
    end

    test "CI, HexDocs, and release workflows use read-only contents permissions" do
      for path <- [@ci_path, @hexdocs_path, @release_path] do
        workflow = load_workflow!(path)

        assert workflow["permissions"] == %{"contents" => "read"},
               "#{path} must set top-level contents: read permissions"
      end
    end
  end

  describe "ci.yml job names" do
    test "contains required and advisory job keys" do
      ci = File.read!(@ci_path)

      for job <-
            @required_contexts ++
              [
                "integration-proofs",
                "advisory-checks",
                "example-phoenix",
                "test"
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
    test "integration-proofs runs live_signing, live_pdf_tools, and release_preflight_proof" do
      ci = File.read!(@ci_path)

      assert ci =~ "mix test --include live_signing test/rendro/adapters/signing_live_test.exs"
      assert ci =~ "mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs"
      assert ci =~ "mix run scripts/release_preflight_proof.exs --current-version-tag --worktree"
    end

    test "baseline JSON commands match behavioral wiring substrings" do
      baseline = load_baseline!()

      integration =
        baseline["contexts"]
        |> Enum.find(&(&1["name"] == "integration-proofs"))

      assert integration["command"] =~ "live_signing"
      assert integration["command"] =~ "signing_live_test.exs"
      assert integration["command"] =~ "live_pdf_tools"
      assert integration["command"] =~ "release_preflight_proof.exs"
    end
  end

  describe "docs-contract lane count" do
    test "verify_docs.exs registers exactly twenty-two lanes including PDF.js advisory, GitHub intake, and DX local reproducibility lanes" do
      script = File.read!(@verify_docs_path)

      lane_entries =
        Regex.scan(
          ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
          script
        )

      assert length(lane_entries) == 22

      assert script =~
               ~r/\{"Viewer evidence semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/viewer_evidence_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Comparison claims lane",\s*\["test",\s*"test\/docs_contract\/comparison_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"PDF\.js advisory claims lane",\s*\["test",\s*"test\/docs_contract\/pdfjs_advisory_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"DX local reproducibility claims lane",\s*\["test",\s*"test\/docs_contract\/dx_local_reproducibility_claims_test\.exs"\]\}/s
    end
  end

  describe "mix ci alias structural validation" do
    test "ci alias includes structural validation steps folded into test context" do
      project = Rendro.MixProject.project()
      aliases = Keyword.fetch!(project, :aliases)
      ci_fast_steps = Keyword.fetch!(aliases, :"ci.fast")
      ci_steps = Keyword.fetch!(aliases, :ci)

      assert ci_steps == ["ci.fast", "ci.proofs"]

      assert ci_fast_steps == [
               "format --check-formatted",
               "hex.build",
               "compile --warnings-as-errors",
               "test --exclude quarantine --slowest 10",
               "docs --warnings-as-errors",
               "credo --strict",
               "dialyzer"
             ]
    end
  end

  describe "required/advisory CI separation" do
    test "required test job runs only the deterministic mix ci lane" do
      ci = File.read!(@ci_path)
      test_block = ci_job_block!(ci, "test")

      assert test_block =~ "run: mix format"
      assert test_block =~ "run: mix compile"
      assert test_block =~ "run: mix test"
      assert test_block =~ "run: mix credo"
      assert test_block =~ "run: mix dialyzer"

      forbidden_required_fragments = [
        "pdfium-cli",
        "curl -fsSL",
        "rendro.launch_artifacts.check",
        "Rendro.Adapters.Pdfium.render",
        "rendro.comparison.check",
        "rendro.livebook.check",
        "setup-node",
        "npm",
        "pdfjs",
        "pdfjs-dist",
        "pdfjs_observer",
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

    test "advisory-checks is graph-disconnected and non-blocking" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")

      assert advisory_block =~ "continue-on-error: true"

      assert advisory_block =~
               "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs"

      assert advisory_block =~ "mix rendro.launch_artifacts.check"
      assert advisory_block =~ "mix rendro.comparison.check"
      assert advisory_block =~ "mix rendro.livebook.check"
      assert advisory_block =~ "node scripts/pdfjs_observer/observe.mjs --check"

      refute advisory_block =~ ~r/^\s+needs:/m
    end

    test "integration-proofs is bounded and runs the isolated proof wrapper" do
      ci = File.read!(@ci_path)
      integration_block = ci_job_block!(ci, "integration-proofs")

      assert integration_block =~ "timeout-minutes:"

      assert integration_block =~
               ~s(mix run scripts/release_preflight_proof.exs --current-version-tag --worktree)
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

  describe "release workflow boundary" do
    test "release workflow stays tag-gated and publishes with Hex credentials only" do
      release = File.read!(@release_path)
      workflow = load_workflow!(@release_path)

      assert release =~ "tags:"
      assert release =~ "'v*.*.*'"
      assert release =~ "mix release.preflight"
      assert release =~ "mix hex.publish --yes"
      assert release =~ "HEX_API_KEY"
      refute release =~ "contents: write"
      refute release =~ "gh release"
      refute release =~ "release-please"
      assert is_map(workflow["jobs"]["publish"])
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

  defp load_workflow!(path) do
    case YamlElixir.read_from_string(File.read!(path)) do
      {:ok, workflow} -> workflow
      {:error, reason} -> flunk("expected #{path} to parse as YAML: #{inspect(reason)}")
    end
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

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
  end

  describe "ci.yml job names" do
    test "contains required and advisory job keys" do
      ci = File.read!(@ci_path)

      for job <- @required_contexts ++ ["viewer-evidence-live-proof", "example-phoenix"] do
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
    test "verify_docs.exs registers exactly fourteen lanes including the recipes, page-primitive, public-api contract, script-support, and path claims lanes" do
      script = File.read!(@verify_docs_path)

      lane_entries = Regex.scan(~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/, script)
      assert length(lane_entries) == 14

      assert script =~
               ~s|{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}|
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

  describe "baseline ci_job alignment" do
    test "each contexts[].ci_job exists in ci.yml" do
      baseline = load_baseline!()
      ci = File.read!(@ci_path)

      for context <- baseline["contexts"] do
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
end

defmodule Guardrails.RequiredChecksContractTest do
  use ExUnit.Case, async: true

  @baseline_path "priv/guardrails/required_status_checks.json"
  @ci_path ".github/workflows/ci.yml"
  @hexdocs_path ".github/workflows/hexdocs.yml"
  @release_path ".github/workflows/release.yml"
  @verify_docs_path "scripts/verify_docs.exs"
  @catalog_evidence_path ".github/workflows/catalog-evidence.yml"

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
      assert length(baseline["contexts"]) == 4

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

  describe "Catalog Evidence workflow boundary" do
    test "is a manual, read-only, exact-SHA-bound control plane with one expiring bundle" do
      workflow = load_workflow!(@catalog_evidence_path)
      source = File.read!(@catalog_evidence_path)
      dispatch = workflow["on"]["workflow_dispatch"]
      inputs = dispatch["inputs"]
      job = workflow["jobs"]["catalog-evidence"]
      steps = job["steps"]

      assert workflow["name"] == "Catalog Evidence"
      assert Map.keys(workflow["on"]) == ["workflow_dispatch"]
      assert workflow["permissions"] == %{"contents" => "read"}
      assert job["timeout-minutes"] == 45

      assert inputs["candidate_sha"] == %{
               "description" => "Full lowercase commit SHA to evaluate",
               "required" => true,
               "type" => "string"
             }

      assert inputs["operation"] == %{
               "description" => "Evidence operation to run",
               "options" => ["review", "canonical"],
               "required" => true,
               "type" => "choice"
             }

      assert job["env"]["CANDIDATE_SHA"] == "${{ inputs.candidate_sha }}"
      assert job["env"]["OPERATION"] == "${{ inputs.operation }}"
      assert job["env"]["CONTROL_SHA"] == "${{ github.sha }}"
      assert source =~ "[[ \"${CANDIDATE_SHA}\" =~ ^[0-9a-f]{40}$ ]]"
      assert source =~ "[[ \"${OPERATION}\" == \"review\" || \"${OPERATION}\" == \"canonical\" ]]"

      assert source =~
               "[[ \"$(git -C \"${CANDIDATE_DIR}\" rev-parse HEAD)\" == \"${CANDIDATE_SHA}\" ]]"

      checkout_steps =
        Enum.filter(steps, &String.contains?(&1["uses"] || "", "actions/checkout@"))

      assert length(checkout_steps) == 2

      assert Enum.all?(checkout_steps, fn step ->
               step["uses"] == "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" and
                 step["with"]["persist-credentials"] == false
             end)

      assert Enum.map(checkout_steps, & &1["with"]["path"]) == ["control", "candidate"]
      assert hd(checkout_steps)["with"]["ref"] == "${{ env.CONTROL_SHA }}"
      assert List.last(checkout_steps)["with"]["ref"] == "${{ env.CANDIDATE_SHA }}"

      assert Enum.any?(
               steps,
               &(&1["uses"] == "erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7")
             )

      upload_steps =
        Enum.filter(steps, &String.contains?(&1["uses"] || "", "actions/upload-artifact@"))

      assert [upload] = upload_steps
      assert upload["uses"] == "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02"

      assert upload["with"]["name"] ==
               "rendro-catalog-evidence--${{ inputs.operation }}--${{ inputs.candidate_sha }}--run-${{ github.run_id }}--attempt-${{ github.run_attempt }}"

      assert upload["with"]["retention-days"] == 30
      assert upload["with"]["if-no-files-found"] == "error"

      assert source =~ "Rendro.CatalogEvidenceBundle.build"
      assert source =~ "Rendro.CatalogEvidenceBundle.validate"
      assert source =~ "priv/pdfium_pin.json"
      assert source =~ "artifact-url"
      assert source =~ "artifact-digest"
      assert source =~ "RENDRO_PRESET_RASTER_REVIEW_DIR"
      assert source =~ "test/rendro/theme/preset_raster_snapshot_test.exs"
      assert source =~ "preset-review/preset.json"

      for forbidden <- [
            "actions/cache",
            "secrets.",
            "contents: write",
            "id-token:",
            "attestations:",
            "workflow_run:"
          ] do
        refute source =~ forbidden
      end
    end

    test "keeps ordinary CI topology and the sole ci-success authority unchanged" do
      ci = load_workflow!(@ci_path)
      catalog = load_workflow!(@catalog_evidence_path)
      ci_success = ci["jobs"]["ci-success"]

      assert Enum.sort(Map.keys(ci["on"])) == ["pull_request", "push", "schedule"]

      assert ci_success["needs"] == [
               "test",
               "configurator-browser",
               "integration-proofs",
               "quality-governance"
             ]

      refute Map.has_key?(ci["jobs"], "catalog-evidence")
      refute Map.has_key?(catalog["jobs"]["catalog-evidence"], "needs")
      refute "catalog-evidence" in ci_success["needs"]
      assert load_baseline!()["required_contexts"] == @required_contexts
    end
  end

  describe "behavioral command wiring" do
    test "integration-proofs runs live_signing, live_pdf_tools, and release_preflight_proof" do
      ci = File.read!(@ci_path)

      assert ci =~ "mix test --include live_signing test/rendro/adapters/signing_live_test.exs"
      assert ci =~ "mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs"

      assert ci =~
               "mix run scripts/release_preflight_proof.exs --current-version-tag --skip-ci --skip-security-audits --worktree"
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
      assert integration["command"] =~ "--skip-ci"
      assert integration["command"] =~ "--skip-security-audits"
    end
  end

  describe "docs-contract lane count" do
    test "verify_docs.exs registers exactly twenty-eight lanes including the catalog evidence, preset public-claims, and accessibility overclaim tripwire lanes" do
      script = File.read!(@verify_docs_path)

      lane_entries =
        Regex.scan(
          ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
          script
        )

      assert length(lane_entries) == 28

      assert script =~
               ~r/\{"Catalog evidence runbook lane",\s*\["test",\s*"test\/docs_contract\/catalog_evidence_runbook_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Preset public-claims lane",\s*\["test",\s*"test\/docs_contract\/presets_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Viewer evidence semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/viewer_evidence_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Comparison claims lane",\s*\["test",\s*"test\/docs_contract\/comparison_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"PDF\.js advisory claims lane",\s*\["test",\s*"test\/docs_contract\/pdfjs_advisory_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"DX local reproducibility claims lane",\s*\["test",\s*"test\/docs_contract\/dx_local_reproducibility_claims_test\.exs"\]\}/s

      assert script =~
               ~r/\{"Accessibility overclaim tripwire lane",\s*\["test",\s*"test\/docs_contract\/accessibility_overclaim_test\.exs"\]\}/s
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
               "quality.hygiene",
               "cmd mix hex.build",
               "compile --warnings-as-errors",
               "test --exclude quarantine --slowest 10",
               "docs --warnings-as-errors",
               "credo --strict",
               "dialyzer"
             ]
    end
  end

  describe "required/advisory CI separation" do
    test "release workflow runs and retains a fresh advisory Phoenix clean-room proof" do
      release = File.read!(@release_path)
      advisory_block = ci_job_block!(release, "phoenix-clean-room-advisory")

      assert advisory_block =~ "continue-on-error: true"
      assert advisory_block =~ "scripts/phoenix_clean_room_proof.exs"
      refute advisory_block =~ "--prerequisite"
      refute advisory_block =~ ".planning/"
      assert advisory_block =~ "github.ref_name == 'v1.3.4'"

      assert advisory_block =~
               "PROOF_ROOT: /tmp/rendro-phoenix-clean-room-${{ github.run_id }}-${{ github.run_attempt }}"

      refute advisory_block =~ "PROOF_ROOT: ${{ runner.temp }}"
      assert advisory_block =~ "proof.outcome !== \"success\""
      assert advisory_block =~ "proof.cleanup !== \"workspace_removed\""
      assert advisory_block =~ "name: phoenix-clean-room-advisory"
      assert advisory_block =~ "if-no-files-found: error"
    end

    test "Phase 130 catalog review accepts only a full-SHA-bound candidate route" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")
      test_block = ci_job_block!(ci, "test")

      assert ci =~ "      - 'gsd/phase-130-catalog-review-*'"
      assert advisory_block =~ "^gsd/phase-130-catalog-review-([0-9a-f]{40})$"
      assert advisory_block =~ "[[ \"${BASH_REMATCH[1]}\" == \"${GITHUB_SHA}\" ]]"
      assert advisory_block =~ "mix rendro.catalog.candidate"

      assert advisory_block =~
               "mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs"

      assert advisory_block =~ "priv/pdfium_pin.json"
      assert advisory_block =~ "name: phase-130-catalog-candidate"
      assert advisory_block =~ "name: phase-130-catalog-final"
      assert advisory_block =~ "name: phase-130-catalog-multipage"
      assert advisory_block =~ "tmp/phase130-candidate"
      assert advisory_block =~ "tmp/phase130-review/final"
      assert advisory_block =~ "tmp/phase130-review/final/pngs"
      assert advisory_block =~ "tmp/phase130-review/multipage"

      assert advisory_block =~
               "find tmp/phase130-candidate -type f -name '*.png' ! -path 'tmp/phase130-candidate/multipage/*'"

      refute advisory_block =~ "tmp/phase130-candidate/catalog"

      refute test_block =~ "phase-130-catalog-review"
      refute test_block =~ "rendro.catalog.candidate"
      refute test_block =~ "RENDRO_CATALOG_REVIEW_DIR"
    end

    test "Phase 130 canonical catalog route is SHA-bound, pinned, and advisory-only" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")
      test_block = ci_job_block!(ci, "test")

      assert ci =~ "      - 'gsd/phase-130-catalog-canonical-*'"
      assert advisory_block =~ "^gsd/phase-130-catalog-canonical-([0-9a-f]{40})$"
      assert advisory_block =~ "mix rendro.catalog.gen"
      assert advisory_block =~ "mix rendro.catalog.check"
      assert advisory_block =~ "name: phase-130-catalog-canonical"
      assert advisory_block =~ "phase130_catalog_canonical"
      assert advisory_block =~ "PAYLOAD_SHA256:"
      assert advisory_block =~ ".generated_by == \"mix rendro.catalog.gen\""
      assert advisory_block =~ "(.cells | length) == 32"
      assert advisory_block =~ "actual_sha"
      assert advisory_block =~ "expected_sha"

      refute test_block =~ "phase-130-catalog-canonical"
    end

    test "Phase 127 catalog blessing is isolated, bounded, and absent from required CI" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")
      test_block = ci_job_block!(ci, "test")

      assert ci =~ "      - 'gsd/phase-127-catalog-bless-*'"

      guard =
        "github.event_name == 'push' && startsWith(github.ref_name, 'gsd/phase-127-catalog-bless-')"

      assert advisory_block =~ guard
      assert advisory_block =~ "mix rendro.catalog.gen"
      assert advisory_block =~ "mix rendro.catalog.candidate"
      assert advisory_block =~ "mix rendro.catalog.check"
      assert advisory_block =~ "mix rendro.catalog.check"

      assert advisory_block =~
               "Skipping catalog check only for the initial isolated hash-capture run."

      assert advisory_block =~
               "jq -er '.catalog_dispositions | length' priv/quality/rubric_scores.json"

      assert advisory_block =~ "\"${disposition_count}\" -lt 32"

      assert advisory_block =~
               "RENDRO_CATALOG_REVIEW_DIR: ${{ runner.temp }}/rendro_phase127_review"

      assert advisory_block =~ "$REVIEW_DIR/final/pngs"
      assert advisory_block =~ "$REVIEW_DIR/final/identity-manifest.json"
      assert advisory_block =~ "$REVIEW_DIR/multipage"

      assert advisory_block =~ "cp -R \"$REVIEW_DIR/final/pngs/.\" \"$ARTIFACT_DIR/review/\""

      for {source, destination} <- [
            {"invoice-line-items-60-plus-page-first.png",
             "invoice_line_items_60_plus_page_first.png"},
            {"invoice-line-items-60-plus-page-final.png",
             "invoice_line_items_60_plus_page_final.png"},
            {"statement-line-items-60-plus-page-first.png",
             "statement_line_items_60_plus_page_first.png"},
            {"statement-line-items-60-plus-page-final.png",
             "statement_line_items_60_plus_page_final.png"}
          ] do
        assert advisory_block =~ "$REVIEW_DIR/multipage/#{source}"
        assert advisory_block =~ "$ARTIFACT_DIR/review/#{destination}"
      end

      assert advisory_block =~
               "find \"$ARTIFACT_DIR/review\" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')\" = \"16\""

      assert advisory_block =~ "name: phase-127-catalog-bless"
      assert advisory_block =~ "if-no-files-found: error"
      assert advisory_block =~ "GITHUB_SHA=${GITHUB_SHA}"
      assert advisory_block =~ "GITHUB_RUN_ID=${GITHUB_RUN_ID}"
      assert advisory_block =~ "PDFIUM_VERSION=$(jq -r '.version' priv/pdfium_pin.json)"
      assert advisory_block =~ "PDFIUM_SHA256=$(jq -r '.sha256' priv/pdfium_pin.json)"

      for path <- [
            "assets/rendro/catalog.json",
            "assets/rendro/catalog",
            "invoice-line-items-60-plus-page-first.png",
            "invoice-line-items-60-plus-page-final.png",
            "statement-line-items-60-plus-page-first.png",
            "statement-line-items-60-plus-page-final.png",
            "invoice_line_items_60_plus_page_first.png",
            "invoice_line_items_60_plus_page_final.png",
            "statement_line_items_60_plus_page_first.png",
            "statement_line_items_60_plus_page_final.png"
          ] do
        assert advisory_block =~ path
      end

      refute test_block =~ "rendro.catalog.gen"
      refute test_block =~ "rendro.catalog.check"
      refute test_block =~ "RENDRO_CATALOG_REVIEW_DIR"
      refute test_block =~ "phase-127-catalog-bless"
      refute advisory_block =~ ~r/^\s+needs:/m
    end

    test "Phase 126 raster blessing accepts only the isolated guarded push ref" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")
      test_block = ci_job_block!(ci, "test")

      assert ci =~ "  push:\n    branches:\n      - main\n      - 'gsd/phase-126-raster-bless-*'"
      assert ci =~ "  pull_request:\n    branches:\n      - main"
      assert ci =~ "  schedule:\n    - cron: '0 2 * * *'"
      refute ci =~ "workflow_dispatch:"

      assert advisory_block =~
               "mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs"

      assert advisory_block =~ "MIX_RASTER_BLESS: \"false\""

      adapter_step = ci_step_block!(advisory_block, "Run Raster Snapshot Tests")
      assert adapter_step =~ "continue-on-error: true"
      assert adapter_step =~ "MIX_RASTER_BLESS: \"false\""

      assert advisory_block =~
               "mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs"

      blessing_guard =
        "github.event_name == 'push' && startsWith(github.ref_name, 'gsd/phase-126-raster-bless-')"

      assert advisory_block =~
               "MIX_RASTER_BLESS: ${{ github.event_name == 'push' && startsWith(github.ref_name, 'gsd/phase-126-raster-bless-') && 'true' || 'false' }}"

      assert advisory_block =~
               "RENDRO_PRESET_RASTER_REVIEW_DIR: ${{ runner.temp }}/rendro_phase126_review"

      assert advisory_block =~ blessing_guard
      assert advisory_block =~ "ARTIFACT_DIR: ${{ runner.temp }}/phase126_preset_raster_bless"
      assert advisory_block =~ "name: phase-126-preset-raster-bless"
      assert advisory_block =~ "path: ${{ runner.temp }}/phase126_preset_raster_bless"
      assert advisory_block =~ "if-no-files-found: error"
      assert advisory_block =~ "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02"

      hash_paths = [
        "priv/raster_refs/presets/swiss/light.sha256",
        "priv/raster_refs/presets/corporate_classic/dark.sha256",
        "priv/raster_refs/presets/editorial/dark.sha256",
        "priv/raster_refs/presets/minimal_mono/dark.sha256",
        "priv/raster_refs/presets/humanist/dark.sha256",
        "priv/raster_refs/presets/brutalist/dark.sha256"
      ]

      review_paths = [
        "swiss_invoice_light_page_1.png",
        "corporate_classic_invoice_dark_page_1.png",
        "editorial_ticket_dark_page_1.png",
        "minimal_mono_ticket_dark_page_1.png",
        "humanist_payslip_dark_page_1.png",
        "brutalist_payslip_dark_page_1.png"
      ]

      for path <- hash_paths do
        assert advisory_block =~ path
        assert advisory_block =~ "$ARTIFACT_DIR/#{path}"
      end

      for path <- review_paths do
        assert advisory_block =~ "$REVIEW_DIR/#{path}"
        assert advisory_block =~ "$ARTIFACT_DIR/review/#{path}"
      end

      assert advisory_block =~ "GITHUB_SHA=${GITHUB_SHA}"
      assert advisory_block =~ "GITHUB_RUN_ID=${GITHUB_RUN_ID}"
      assert advisory_block =~ "PDFIUM_VERSION=$(jq -r '.version' priv/pdfium_pin.json)"
      assert advisory_block =~ "PDFIUM_SHA256=$(jq -r '.sha256' priv/pdfium_pin.json)"
      assert advisory_block =~ "(cd \"$ARTIFACT_DIR\" && find priv review -type f | sort)"
      refute test_block =~ "MIX_RASTER_BLESS"
      refute test_block =~ "RENDRO_PRESET_RASTER_REVIEW_DIR"
      refute test_block =~ "phase126_preset_raster_bless"
      refute test_block =~ "phase-126-preset-raster-bless"
    end

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

    test "advisory-checks is graph-disconnected with only adapter comparison non-blocking" do
      ci = File.read!(@ci_path)
      advisory_block = ci_job_block!(ci, "advisory-checks")
      adapter_step = ci_step_block!(advisory_block, "Run Raster Snapshot Tests")
      preset_step = ci_step_block!(advisory_block, "Run Preset Raster Snapshot Tests")

      staging_step =
        ci_step_block!(advisory_block, "Stage Phase 126 preset raster blessing evidence")

      upload_step =
        ci_step_block!(advisory_block, "Upload Phase 126 preset raster blessing evidence")

      refute advisory_block =~ ~r/^    continue-on-error:/m
      assert adapter_step =~ "continue-on-error: true"
      assert adapter_step =~ "MIX_RASTER_BLESS: \"false\""
      refute preset_step =~ "continue-on-error"
      refute staging_step =~ "continue-on-error"
      refute upload_step =~ "continue-on-error"

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
               ~s(mix run scripts/release_preflight_proof.exs --current-version-tag --skip-ci --skip-security-audits --worktree)

      assert integration_block =~ "--skip-ci"
      assert integration_block =~ "--skip-security-audits"
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

  describe "quality governance CI topology" do
    test "quality-governance is a fail-closed ci-success roll-up member" do
      baseline = load_baseline!()
      workflow = load_workflow!(@ci_path)
      jobs = workflow["jobs"]
      governance = Map.fetch!(jobs, "quality-governance")
      roll_up = Map.fetch!(jobs, "ci-success")

      context = Enum.find(baseline["contexts"], &(&1["name"] == "quality-governance"))
      assert context["semantic_class"] == "deterministic"
      assert context["ci_job"] == "quality-governance"
      assert context["command"] == "mix quality.governance"
      assert context["notes"] =~ "roll-up"

      assert is_nil(governance["needs"])
      assert is_nil(governance["if"])
      refute Map.has_key?(governance, "continue-on-error")
      assert governance["env"] == %{"MIX_ENV" => "test"}

      assert Enum.any?(
               governance["steps"],
               &(&1["uses"] == "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10")
             )

      assert Enum.any?(governance["steps"], fn step ->
               step["uses"] == "erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7" and
                 step["with"] == %{"otp-version" => "28", "elixir-version" => "1.19.5"}
             end)

      assert Enum.any?(governance["steps"], fn step ->
               step["uses"] == "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e" and
                 step["with"] == %{"node-version" => "22.14.0"}
             end)

      assert Enum.any?(governance["steps"], &(&1["run"] == "mix deps.get"))
      assert Enum.any?(governance["steps"], &(&1["run"] == "mix quality.governance"))
      assert "quality-governance" in roll_up["needs"]
      assert roll_up["if"] == "always()"
      refute "quality-governance" in baseline["required_contexts"]
      assert baseline["required_contexts"] == @required_contexts
    end

    test "topology mutations reject governance weakening and required-context inflation" do
      workflow = load_workflow!(@ci_path)
      governance = Map.fetch!(workflow["jobs"], "quality-governance")
      roll_up = Map.fetch!(workflow["jobs"], "ci-success")
      baseline = load_baseline!()

      refute Map.has_key?(governance, "needs")
      refute Map.has_key?(governance, "if")
      refute Map.has_key?(governance, "continue-on-error")
      refute Enum.any?(governance["steps"], &Map.has_key?(&1, "continue-on-error"))
      assert "quality-governance" in roll_up["needs"]
      assert baseline["required_contexts"] == ["ci-success"]
    end
  end

  describe "release workflow boundary" do
    test "release workflow stays tag-gated and publishes with Hex credentials only" do
      release = File.read!(@release_path)
      workflow = load_workflow!(@release_path)

      assert release =~ "tags:"
      assert release =~ "'v*.*.*'"
      assert release =~ "mix release.preflight"
      assert release =~ "mix quality.hygiene"
      assert release =~ "mix hex.publish --yes --no-docs"
      assert release =~ "HEX_API_KEY"
      refute release =~ "contents: write"
      refute release =~ "gh release"
      refute release =~ "release-please"
      assert workflow["jobs"]["validate-and-dry-run"]["timeout-minutes"] == 45
      assert workflow["jobs"]["publish"]["timeout-minutes"] == 15
    end

    test "release relies on credential-free preflight before protected publish" do
      release = File.read!(@release_path)
      workflow = load_workflow!(@release_path)
      validate_job = workflow["jobs"]["validate-and-dry-run"]

      assert is_nil(validate_job["environment"])
      assert Enum.any?(validate_job["steps"], &(&1["name"] == "Run Release Preflight"))
      refute Enum.any?(validate_job["steps"], &(&1["name"] == "Publish to Hex (Dry Run)"))
      refute Enum.any?(validate_job["steps"], &get_in(&1, ["env", "HEX_API_KEY"]))
      refute release =~ "mix hex.publish --dry-run"

      publish_step =
        workflow["jobs"]["publish"]["steps"]
        |> Enum.find(&(&1["name"] == "Publish to Hex"))

      assert publish_step["env"]["HEX_API_KEY"] == "${{ secrets.HEX_API_KEY }}"
    end

    test "candidate proof remains complete-audit only and never creates a tag" do
      proof = File.read!("scripts/release_preflight_proof.exs")

      assert proof =~ "candidate SHA proof cannot bypass CI or security audits"
      assert proof =~ "defp maybe_add_candidate_sha(args, %{candidate_sha: candidate_sha})"
      assert proof =~ "args ++ [\"--candidate-sha\", candidate_sha]"
      assert proof =~ "execute_candidate_sha_proof"
    end
  end

  describe "protected workflow version extraction" do
    @v1_3_0_multiline_fixture ~S"""
    @version "1.3.0"
    source_ref: "v#{@version}"
    """

    test "each protected workflow uses an exact-one top-level @version declaration parser" do
      for path <- [@release_path, @hexdocs_path] do
        workflow = File.read!(path)

        assert workflow =~
                 ~S{VERSION_DECLARATIONS=$(sed -nE 's/^[[:space:]]*@version[[:space:]]+"([^"]+)"[[:space:]]*$/\1/p' mix.exs)}

        assert workflow =~ ~S{VERSION_DECLARATION_COUNT=$(printf '%s\n'}
        assert workflow =~ ~S{$VERSION_DECLARATIONS}
        assert workflow =~ "sed '/^$/d' | wc -l | tr -d ' '"

        assert workflow =~ ~S{if [ "$VERSION_DECLARATION_COUNT" -ne 1 ]; then}
        assert workflow =~ "Expected exactly one top-level @version declaration"
      end
    end

    test "each protected workflow rejects the v1.3.0 multiline incident and ambiguous declarations" do
      for path <- [@release_path, @hexdocs_path] do
        assert legacy_broad_versions(@v1_3_0_multiline_fixture) == ["1.3.0", ~S(v#{@version})],
               "#{path} must retain the failed v1.3.0 broad-match incident as a regression fixture"

        assert extract_exactly_one_version(@v1_3_0_multiline_fixture) == {:ok, "1.3.0"},
               "#{path} must extract only the declaration, not source_ref interpolation"

        assert {:error, zero_diagnostic} = extract_exactly_one_version("source_ref: \"v1.3.0\"\n")
        assert zero_diagnostic =~ "found 0"

        duplicate_fixture = ~S"""
        @version "1.3.0"
        @version "1.3.1"
        """

        assert {:error, duplicate_diagnostic} = extract_exactly_one_version(duplicate_fixture)
        assert duplicate_diagnostic =~ "found 2"
      end
    end
  end

  describe "HexDocs candidate binding" do
    test "publication secrets require protected main and preserve a durable detached-artifact binding" do
      workflow = File.read!(@hexdocs_path)

      assert workflow =~
               "github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main' && github.ref_protected == true"

      assert workflow =~ "git checkout --detach \"$APPROVED_CANDIDATE_SHA\""
      assert workflow =~ "name: hexdocs-candidate-binding"
      assert workflow =~ "requested_artifact_sha"
      assert workflow =~ "peeled_tag_sha"
      assert workflow =~ "detached_artifact_head"
      assert workflow =~ "retention-days: 90"
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

  defp ci_step_block!(job_block, step_name) do
    escaped_step_name = Regex.escape(step_name)
    pattern = ~r/^      - name: #{escaped_step_name}\n(?:(?!^      - name:).*(?:\n|$))*/m

    case Regex.run(pattern, job_block) do
      [block] -> block
      _ -> flunk("expected CI step block #{inspect(step_name)}")
    end
  end

  defp legacy_broad_versions(mix_exs) do
    mix_exs
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, "@version"))
    |> Enum.map(fn line ->
      [version] = Regex.run(~r/.*"([^"]+)".*/, line, capture: :all_but_first)
      version
    end)
  end

  defp extract_exactly_one_version(mix_exs) do
    declarations =
      Regex.scan(~r/^[[:space:]]*@version[[:space:]]+"([^"]+)"[[:space:]]*$/m, mix_exs,
        capture: :all_but_first
      )
      |> List.flatten()

    case declarations do
      [version] ->
        {:ok, version}

      versions ->
        {:error, "expected exactly one top-level @version declaration; found #{length(versions)}"}
    end
  end
end

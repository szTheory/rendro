defmodule Rendro.DocsContract.PdfjsAdvisoryClaimsTest do
  use ExUnit.Case, async: true

  @package_path "scripts/pdfjs_observer/package.json"
  @lockfile_path "scripts/pdfjs_observer/package-lock.json"
  @schema_path "priv/pdfjs_observations/schema.json"
  @observation_paths [
    "priv/pdfjs_observations/embedded_artifact_support_fixture.json",
    "priv/pdfjs_observations/bench_rendro_invoice.json"
  ]
  @required_observation_keys ~w(
    advisory_boundary
    errors
    fixture
    node_version
    observer
    page_count
    pages
    pdfjs_dist_version
    platform
    recorded_at
    schema_version
    warnings
  )
  @optional_observation_keys ~w(first_page_png_sha256)
  @page_keys ~w(height page_number width)
  @public_docs [
    "README.md",
    "guides/api_stability.md",
    "guides/viewer_evidence.md",
    "guides/recipes.md",
    "guides/comparison.md"
  ]
  @pdfjs_deferral_paths [
    ["forms", "viewers", "pdfjs"],
    ["forms", "signature_widget_viewers", "pdfjs"],
    ["signing_preparation", "viewers", "pdfjs"],
    ["signing", "long_lived", "viewers", "pdfjs"],
    ["signing", "viewers", "pdfjs"]
  ]

  test "observer package is private, exact-pinned, and outside mix dependencies" do
    package = @package_path |> File.read!() |> JSON.decode!()
    lockfile = @lockfile_path |> File.read!() |> JSON.decode!()
    aliases = Keyword.fetch!(Rendro.MixProject.project(), :aliases)
    deps = Keyword.fetch!(Rendro.MixProject.project(), :deps)

    assert package["private"] == true
    assert package["type"] == "module"
    assert package["engines"]["node"] == ">=22.13.0 || >=24"
    assert package["dependencies"]["pdfjs-dist"] == "6.0.227"
    refute package["dependencies"]["pdfjs-dist"] =~ "^"

    assert lockfile["packages"][""]["dependencies"]["pdfjs-dist"] == "6.0.227"
    assert lockfile["packages"]["node_modules/pdfjs-dist"]["version"] == "6.0.227"

    assert lockfile["packages"]["node_modules/pdfjs-dist"]["engines"]["node"] ==
             ">=22.13.0 || >=24"

    refute Enum.any?(deps, fn dep ->
             dep_name =
               dep
               |> elem(0)
               |> Atom.to_string()

             dep_name in ["pdfjs-dist", "pdfjs_observer", "setup-node"]
           end)

    assert Keyword.fetch!(aliases, :"ci.advisory") == [
             "test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs",
             "rendro.launch_artifacts.check",
             "rendro.comparison.check",
             "rendro.livebook.check",
             "cmd npm ci --prefix scripts/pdfjs_observer",
             "cmd node scripts/pdfjs_observer/observe.mjs --check",
             "deps.audit",
             "hex.audit"
           ]
  end

  test "observation schema and committed observations use the advisory contract" do
    schema = @schema_path |> File.read!() |> JSON.decode!()

    assert schema["title"] == "Rendro PDF.js advisory observation"
    assert schema["properties"]["pdfjs_dist_version"]["const"] == "6.0.227"
    assert schema["properties"]["observer"]["const"] == "rendro-pdfjs-advisory"

    for path <- @observation_paths do
      observation = path |> File.read!() |> JSON.decode!()

      assert Enum.sort(Map.keys(observation) -- @optional_observation_keys) ==
               Enum.sort(@required_observation_keys)

      assert Map.keys(observation) -- (@required_observation_keys ++ @optional_observation_keys) ==
               []

      assert observation["schema_version"] == 1
      assert observation["observer"] == "rendro-pdfjs-advisory"
      assert observation["advisory_boundary"] =~ "Pinned PDF.js advisory observation only"
      assert observation["advisory_boundary"] =~ "not GUI-viewer proof"
      assert observation["pdfjs_dist_version"] == "6.0.227"
      assert observation["node_version"] =~ ~r/\Av\d+\.\d+\.\d+/
      assert {:ok, _, _} = DateTime.from_iso8601(observation["recorded_at"])
      assert is_binary(observation["platform"])
      assert String.trim(observation["platform"]) != ""
      assert observation["fixture"] in schema["properties"]["fixture"]["enum"]
      refute String.starts_with?(observation["fixture"], "/")

      assert is_integer(observation["page_count"])
      assert observation["page_count"] > 0
      assert length(observation["pages"]) == observation["page_count"]

      for page <- observation["pages"] do
        assert Enum.sort(Map.keys(page)) == @page_keys
        assert is_integer(page["page_number"])
        assert page["page_number"] > 0
        assert is_number(page["width"])
        assert page["width"] > 0
        assert is_number(page["height"])
        assert page["height"] > 0
      end

      assert is_list(observation["warnings"])
      assert is_list(observation["errors"])

      if Map.has_key?(observation, "first_page_png_sha256") do
        assert observation["first_page_png_sha256"] =~ ~r/\A[0-9a-f]{64}\z/
      end
    end
  end

  test "committed observations match the expected fixture facts" do
    embedded =
      "priv/pdfjs_observations/embedded_artifact_support_fixture.json"
      |> File.read!()
      |> JSON.decode!()

    invoice =
      "priv/pdfjs_observations/bench_rendro_invoice.json"
      |> File.read!()
      |> JSON.decode!()

    assert embedded["fixture"] == "test/fixtures/embedded_artifact_support_fixture.pdf"
    assert embedded["page_count"] == 2
    assert Enum.map(embedded["pages"], &{&1["width"], &1["height"]}) == [{612, 792}, {612, 792}]

    assert invoice["fixture"] == "test/fixtures/pdfjs-rendro.pdf"
    assert invoice["page_count"] == 2

    assert Enum.map(invoice["pages"], &{&1["width"], &1["height"]}) == [
             {595.28, 841.89},
             {595.28, 841.89}
           ]
  end

  test "PDF.js observation fixture is test-only and absent from the package boundary" do
    fixture = "test/fixtures/pdfjs-rendro.pdf"
    manifest = "priv/quality/package-members-v1.json" |> File.read!() |> JSON.decode!()

    assert File.regular?(fixture)
    refute fixture in manifest["members"]
  end

  test "public docs do not claim unqualified PDF.js support" do
    banned_phrases = [
      "PDF.js support",
      "PDF.js is supported",
      "supports PDF.js",
      "PDF.js viewer support",
      "PDF.js GUI support"
    ]

    for path <- @public_docs do
      content = File.read!(path)

      for phrase <- banned_phrases do
        refute String.contains?(content, phrase),
               "#{path} contains banned unqualified PDF.js claim #{inspect(phrase)}"
      end
    end
  end

  test "public docs use narrow PDF.js advisory vocabulary" do
    api_stability = File.read!("guides/api_stability.md")

    assert api_stability =~ "Pinned PDF.js advisory observations"
    assert api_stability =~ "priv/pdfjs_observations/"
    assert api_stability =~ "not GUI-viewer proof"
    assert api_stability =~ "do not promote any"
  end

  test "PDF.js support-matrix rows remain explicit deferrals without promotion fields" do
    matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()

    for path <- @pdfjs_deferral_paths do
      row = get_in(matrix, path)

      assert row["status"] == "explicit_deferral", Enum.join(path, ".")
      assert is_binary(row["evidence_deferred"])
      refute Map.has_key?(row, "evidence")
      refute Map.has_key?(row, "recorded_at")
      refute Map.has_key?(row, "viewer_kind")
      refute Map.has_key?(row, "proof")
    end
  end

  test "docs verification script includes exactly one PDF.js advisory lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert length(Regex.scan(~r/\{"PDF\.js advisory claims lane"/, script)) == 1

    assert script =~
             ~r/\{"PDF\.js advisory claims lane",\s*\["test",\s*"test\/docs_contract\/pdfjs_advisory_claims_test\.exs"\]\}/s
  end
end

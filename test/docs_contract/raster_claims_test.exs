defmodule Rendro.DocsContract.RasterClaimsTest do
  use ExUnit.Case, async: true

  alias Rendro.ViewerEvidence.Validator

  # Test 1: GREEN in Plan 03 — raster section added to support_matrix.json in Plan 03
  test "support matrix has raster section with boundary declarations" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"raster"|
    assert matrix =~ ~s|"gui_viewer_equivalence"|
    assert matrix =~ ~s|"unsupported"|
    assert matrix =~ ~s|"pdfium-render"|
  end

  # Test 2: PASSES in Plan 01 — pdfium_pin.json created in this task
  test "pdfium_pin.json exists and has required keys" do
    assert File.exists?("priv/pdfium_pin.json")

    pin = File.read!("priv/pdfium_pin.json") |> JSON.decode!()

    assert Map.has_key?(pin, "version")
    assert Map.has_key?(pin, "sha256")
    assert pin["version"] == "v0.11.0"
    assert pin["sha256"] == "b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a"
  end

  # Test 3: PASSES in Plan 01 — raster-advisory not yet in required_contexts (correctly absent)
  test "advisory lane is not in required_contexts" do
    guardrails =
      File.read!("priv/guardrails/required_status_checks.json") |> JSON.decode!()

    refute "raster-advisory" in guardrails["required_contexts"]
  end

  # Test 4: GREEN in Plan 04 — raster-advisory added to advisory_contexts in Plan 04
  test "advisory lane is in advisory_contexts" do
    guardrails =
      File.read!("priv/guardrails/required_status_checks.json") |> JSON.decode!()

    assert Enum.any?(guardrails["advisory_contexts"], &(&1["name"] == "raster-advisory"))
  end

  # Test 5: PASSES in Plan 01 — no GUI-viewer rows carry pdfium-render viewer_kind
  # Note: uses parsed JSON to check viewer_map rows specifically (regex approach breaks
  # once the raster section adds a top-level evidence.viewer_kind of "pdfium-render")
  test "GUI-viewer rows do not carry viewer_kind pdfium-render" do
    matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()

    viewer_sections = [
      "forms",
      "signing",
      "signing_preparation",
      "embedded_files",
      "links",
      "protection"
    ]

    for section_key <- viewer_sections do
      section = Map.get(matrix, section_key, %{})
      viewers = Map.get(section, "viewers", %{})

      for {viewer, row} <- viewers do
        refute Map.get(row, "viewer_kind") == "pdfium-render",
               "GUI-viewer row #{section_key}.viewers.#{viewer} must not carry viewer_kind pdfium-render"
      end
    end
  end

  test "schema and validator reject pdfium-render on GUI-viewer rows" do
    matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()

    mutated =
      put_in(
        matrix,
        ["forms", "viewers", "adobe_acrobat_reader", "viewer_kind"],
        "pdfium-render"
      )

    assert {:error, schema_reason} = Validator.validate_matrix_structure(mutated)
    assert schema_reason =~ "pdfium-render" or schema_reason =~ "viewer_kind"

    assert {:error, promotion_violations} = Validator.validate_promotion_complete(mutated)

    assert Enum.any?(
             promotion_violations,
             &String.contains?(&1, "forms.viewers.adobe_acrobat_reader")
           )
  end

  test "raster evidence points at committed PNG hash" do
    matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()

    expected_hash =
      File.read!("priv/raster_refs/forms_support_fixture/page_1.sha256") |> String.trim()

    evidence = matrix["raster"]["evidence"]

    assert evidence["fixture"] == "test/fixtures/forms_support_fixture.pdf"
    assert evidence["ref"] == "priv/raster_refs/forms_support_fixture/page_1.sha256"
    assert evidence["png_sha256"] == expected_hash
    assert evidence["png_sha256"] =~ ~r/\A[0-9a-f]{64}\z/
  end

  # Test 6: GREEN in Plan 04 — verify_docs.exs lane registration added in Plan 04
  test "docs verification script includes the raster claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]}|
  end
end

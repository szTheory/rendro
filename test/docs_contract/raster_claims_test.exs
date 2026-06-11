defmodule Rendro.DocsContract.RasterClaimsTest do
  use ExUnit.Case, async: true

  # Test 1: RED in Plan 01 — raster section added to support_matrix.json in Plan 03
  # @tag :skip removed in Plan 03 once support_matrix.json has the raster section
  @tag :skip
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

  # Test 4: RED in Plan 01 — raster-advisory added to advisory_contexts in Plan 03
  # @tag :skip removed in Plan 03 once guardrails JSON has the raster-advisory entry
  @tag :skip
  test "advisory lane is in advisory_contexts" do
    guardrails =
      File.read!("priv/guardrails/required_status_checks.json") |> JSON.decode!()

    assert Enum.any?(guardrails["advisory_contexts"], &(&1["name"] == "raster-advisory"))
  end

  # Test 5: PASSES in Plan 01 — no GUI-viewer rows carry pdfium-render viewer_kind
  test "GUI-viewer rows do not carry viewer_kind pdfium-render" do
    matrix = File.read!("priv/support_matrix.json")

    refute matrix =~ ~r/"forms".*?"viewer_kind"\s*:\s*"pdfium-render"/s
  end

  # Test 6: RED in Plan 01 — verify_docs.exs lane registration added in Plan 03
  # @tag :skip removed in Plan 03 once verify_docs.exs has the raster claims lane entry
  @tag :skip
  test "docs verification script includes the raster claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]}|
  end
end

defmodule Rendro.DocsContract.Phase135TestInventoryContractTest do
  use ExUnit.Case, async: true

  @path ".planning/phases/135-test-ci-cd-simplification/135-test-inventory.md"
  @recipe_ids ["payslip_cr01_duplicate", "certificate_construction_name"]
  @route_ids ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)
  @recipe_columns ~w(row_id old_test retained_replacement_owner preserved_behavior preserved_failure_mode authority_lane oracle negative_control focused_command result)
  @parity_columns ~w(route_id candidate_sha legacy_run_url legacy_run_id legacy_attempt legacy_artifact_identity legacy_upload_digest generic_run_url generic_run_id generic_attempt generic_artifact_identity generic_upload_digest renderer normalized_role_count_hash action_pin_permission status)

  test "pins the ordered bounded recipe inventory and parity matrix" do
    markdown = File.read!(@path)

    assert table_columns(markdown, "Recipe Test Inventory") == @recipe_columns
    assert table_ids(markdown, "Recipe Test Inventory") == @recipe_ids
    assert table_columns(markdown, "Remote Route Parity Matrix") == @parity_columns
    assert table_ids(markdown, "Remote Route Parity Matrix") == @route_ids

    recipe_rows = table_rows(markdown, "Recipe Test Inventory")

    assert Enum.all?(
             recipe_rows,
             &(List.last(&1) in ["pending", "retained-owner-proven", "rename-only"])
           )

    parity_rows = table_rows(markdown, "Remote Route Parity Matrix")

    assert Enum.all?(
             parity_rows,
             &(List.last(&1) in ["pending", "matched", "mismatch", "unavailable"])
           )

    assert parity_rows |> Enum.map(&Enum.at(&1, 1)) |> Enum.uniq() |> length() == 1
  end

  defp table_columns(markdown, heading),
    do: markdown |> table(heading) |> hd() |> Enum.map(&String.trim/1)

  defp table_ids(markdown, heading), do: markdown |> table_rows(heading) |> Enum.map(&hd/1)

  defp table_rows(markdown, heading) do
    markdown
    |> table(heading)
    |> Enum.drop(2)
  end

  defp table(markdown, heading) do
    [_, rest] = String.split(markdown, "## #{heading}\n", parts: 2)

    rest
    |> String.split("\n\n", parts: 2)
    |> hd()
    |> String.split("\n", trim: true)
    |> Enum.map(fn row ->
      row |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1)
    end)
  end
end

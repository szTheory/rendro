defmodule Rendro.DocsContract.Phase135TestInventoryContractTest do
  use ExUnit.Case, async: true

  alias Rendro.CatalogEvidenceParity

  @path ".planning/phases/135-test-ci-cd-simplification/135-test-inventory.md"
  @record_path ".planning/phases/135-test-ci-cd-simplification/135-parity-comparator-record.json"
  @recipe_ids ["payslip_cr01_duplicate", "certificate_construction_name"]
  @route_ids ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)
  @recipe_columns ~w(row_id old_test retained_replacement_owner preserved_behavior preserved_failure_mode authority_lane oracle negative_control focused_command result)
  @parity_columns ~w(route_id candidate_sha legacy_run_url legacy_run_id legacy_attempt legacy_artifact_identity legacy_upload_digest generic_run_url generic_run_id generic_attempt generic_artifact_identity generic_upload_digest renderer normalized_role_count_hash action_pin_permission status)

  test "pins the ordered bounded recipe inventory" do
    markdown = File.read!(@path)

    assert table_columns(markdown, "Recipe Test Inventory") == @recipe_columns
    assert table_ids(markdown, "Recipe Test Inventory") == @recipe_ids

    assert Enum.all?(
             table_rows(markdown, "Recipe Test Inventory"),
             &(List.last(&1) in ["pending", "retained-owner-proven", "rename-only"])
           )
  end

  test "binds every named parity cell to the canonical sealed-record projection" do
    markdown = File.read!(@path)
    record = record()

    assert record["schema_version"] == 2
    assert record["sealed"] == true
    assert :ok = validate_parity_table(markdown, record)

    assert Enum.map(named_rows!(markdown), & &1["route_id"]) == @route_ids

    assert Enum.all?(
             named_rows!(markdown),
             &(Map.keys(&1) |> Enum.sort() == Enum.sort(@parity_columns))
           )

    phase130 = Enum.find(named_rows!(markdown), &(&1["route_id"] == "phase130_review"))
    assert length(String.split(phase130["legacy_artifact_identity"], "; ")) == 3
    assert length(String.split(phase130["legacy_upload_digest"], "; ")) == 3
  end

  test "rejects a one-cell mutation in every parity column" do
    markdown = File.read!(@path)
    record = record()

    for {column, column_index} <- Enum.with_index(@parity_columns) do
      mutated =
        update_parity_table(markdown, fn rows ->
          put_in(rows, [Access.at(2), Access.at(column_index)], "mutated")
        end)

      assert {:error, _} = validate_parity_table(mutated, record),
             "expected mutation of #{column} to fail"
    end
  end

  test "rejects changed header, route order, extra rows, and missing rows" do
    markdown = File.read!(@path)
    record = record()

    mutations = [
      update_parity_table(markdown, &put_in(&1, [Access.at(0), Access.at(1)], "wrong_sha")),
      update_parity_table(markdown, fn rows ->
        first = Enum.at(rows, 2)
        second = Enum.at(rows, 3)

        rows
        |> List.replace_at(2, second)
        |> List.replace_at(3, first)
      end),
      update_parity_table(markdown, &(&1 ++ [List.last(&1)])),
      update_parity_table(markdown, &List.delete_at(&1, -1))
    ]

    for mutated <- mutations,
        do: assert({:error, _} = validate_parity_table(mutated, record))
  end

  defp validate_parity_table(markdown, record) do
    with {:ok, rows} <- named_rows(markdown),
         :ok <- require_route_order(rows),
         {:ok, expected} <- projected_rows(record) do
      if rows == expected, do: :ok, else: {:error, :sealed_record_projection_mismatch}
    end
  end

  defp projected_rows(record) do
    @route_ids
    |> Enum.map(fn route ->
      case CatalogEvidenceParity.inventory_row(record, route) do
        {:ok, row} -> {:ok, Map.put(row, "route_id", route)}
        {:error, reason} -> {:error, reason}
      end
    end)
    |> collect_rows()
  end

  defp collect_rows(rows) do
    case Enum.find(rows, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(rows, fn {:ok, row} -> row end)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp named_rows(markdown) do
    case table(markdown, "Remote Route Parity Matrix") do
      [@parity_columns, _separator | rows] ->
        if Enum.all?(rows, &(length(&1) == length(@parity_columns))) do
          {:ok, Enum.map(rows, &Map.new(Enum.zip(@parity_columns, &1)))}
        else
          {:error, :invalid_row_width}
        end

      _ ->
        {:error, :invalid_header}
    end
  end

  defp named_rows!(markdown) do
    {:ok, rows} = named_rows(markdown)
    rows
  end

  defp require_route_order(rows) do
    if Enum.map(rows, & &1["route_id"]) == @route_ids,
      do: :ok,
      else: {:error, :invalid_route_order}
  end

  defp update_parity_table(markdown, update) do
    block = table_block(markdown, "Remote Route Parity Matrix")

    replacement =
      block
      |> parse_table()
      |> update.()
      |> Enum.map_join("\n", fn row -> "| #{Enum.join(row, " | ")} |" end)

    String.replace(markdown, block, replacement)
  end

  defp table_columns(markdown, heading), do: markdown |> table(heading) |> hd()
  defp table_ids(markdown, heading), do: markdown |> table_rows(heading) |> Enum.map(&hd/1)
  defp table_rows(markdown, heading), do: markdown |> table(heading) |> Enum.drop(2)

  defp table(markdown, heading), do: markdown |> table_block(heading) |> parse_table()

  defp table_block(markdown, heading) do
    [_, rest] = String.split(markdown, "## #{heading}\n", parts: 2)
    rest |> String.split("\n\n", parts: 2) |> hd() |> String.trim()
  end

  defp parse_table(block) do
    block
    |> String.split("\n", trim: true)
    |> Enum.map(fn row ->
      row |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1)
    end)
  end

  defp record, do: @record_path |> File.read!() |> Jason.decode!()
end

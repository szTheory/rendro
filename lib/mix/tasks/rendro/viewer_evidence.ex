defmodule Mix.Tasks.Rendro.ViewerEvidence do
  use Mix.Task

  alias Rendro.ViewerEvidence.{Matrix, Validator}

  @shortdoc "Audit viewer-evidence coverage in the support matrix"

  @moduledoc """
  Operator tooling for viewer-evidence coverage gaps in `priv/support_matrix.json`.

  Each viewer row has one of three **status** values:

    * `supported` — promotion-complete row with `evidence`, `recorded_at`, and
      `viewer_kind` on the matrix (legacy rows without `evidence:` still list as
      supported but warn during `validate`).
    * `unverified` — recording obligation not satisfied; no `evidence:` or
      `evidence_deferred`.
    * `explicit_deferral` — matrix-only deferral with required `evidence_deferred`
      prose; must not carry promotion keys.

  ## Subcommands

      mix rendro.viewer_evidence list [--json]
      mix rendro.viewer_evidence missing [--json]
      mix rendro.viewer_evidence validate

  `list` prints summary counts and a fixed-width table (`surface`, `viewer`,
  `status`, `notes`) sorted by surface then viewer. `missing` filters to
  `status == "unverified"` only. `--json` emits `{"summary": {...}, "cells": [...]}`
  on stdout only; errors go to stderr.

  Evidence files live under `priv/viewer_evidence/<surface>/<viewer>.md` with a
  per-file byte budget of **65_536** bytes (`byte_size/1` on disk).

  ## Exit codes (D-22)

    * `list` — **0** when the matrix parses successfully.
    * `missing` — **1** when any `unverified` cell exists; **0** when none.
    * `validate` — **1** on Tier-A schema errors, evidence-file failures, or orphan
      scans; **0** when only Tier-B legacy-supported warnings and/or staleness
      warnings (180 days) remain.

  ## CI enforcement

  Merge-blocking checks run through `mix docs.contract` (eighth lane:
  `test/docs_contract/viewer_evidence_claims_test.exs`). This task is **not** part
  of the `mix ci` alias in Phase 68 — use it locally before recording promotions.

  Human workflow guide: `guides/viewer_evidence.md`.
  """

  @matrix_path "priv/support_matrix.json"
  @evidence_root "priv/viewer_evidence"

  @impl Mix.Task
  def run(args) do
    {command, json?} = parse_args!(args)
    Mix.Task.run("app.start")

    matrix = Matrix.load!()
    cells = Matrix.enumerate_viewer_cells(matrix)

    case command do
      :list -> run_list(matrix, cells, json?)
      :missing -> run_missing(matrix, cells, json?)
      :validate -> run_validate(json?)
    end
  end

  defp parse_args!([]), do: usage_error!("missing subcommand")

  defp parse_args!(args) do
    {flags, positional} =
      args
      |> Enum.split_with(&(&1 == "--json"))

    json? = flags != []

    case positional do
      [command | rest] when rest == [] ->
        case command do
          "list" -> {:list, json?}
          "missing" -> {:missing, json?}
          "validate" -> {:validate, json?}
          other -> usage_error!("unknown subcommand #{inspect(other)}")
        end

      [command | rest] ->
        usage_error!("unexpected arguments: #{inspect([command | rest])}")

      [] ->
        usage_error!("missing subcommand")
    end
  end

  defp run_list(matrix, cells, json?) do
    payload = build_payload(matrix, cells)

    if json? do
      IO.puts(JSON.encode!(payload))
    else
      print_human(payload, footer: nil)
    end

    :ok
  end

  defp run_missing(matrix, cells, json?) do
    missing_cells = Enum.filter(cells, &(&1.status == "unverified"))
    payload = build_payload(matrix, missing_cells)

    if json? do
      IO.puts(JSON.encode!(payload))
    else
      print_human(payload, footer: missing_footer(missing_cells))
    end

    if missing_cells == [] do
      :ok
    else
      Mix.shell().error(
        "#{length(missing_cells)} unverified viewer cell(s). Record evidence or defer before promotion."
      )

      exit({:shutdown, 1})
    end
  end

  defp run_validate(_json?) do
    case Validator.run_full(@matrix_path, @evidence_root, []) do
      {:ok, warnings} ->
        {advisory, fatal} = partition_warnings(warnings)

        Enum.each(advisory, fn warning -> Mix.shell().error(warning) end)
        Enum.each(fatal, fn warning -> Mix.shell().error(warning) end)

        if fatal == [] do
          print_validate_summary(warnings)
          :ok
        else
          Mix.shell().error("Viewer evidence validation failed.")
          exit({:shutdown, 1})
        end

      {:error, violations} ->
        Enum.each(violations, fn violation -> Mix.shell().error(violation) end)
        Mix.shell().error("Viewer evidence validation failed.")
        exit({:shutdown, 1})
    end
  end

  defp build_payload(matrix, cells) do
    cell_maps = Enum.map(cells, &cell_to_map(&1, matrix))

    %{
      "summary" => summary_from_cells(cell_maps),
      "cells" => cell_maps
    }
  end

  defp summary_from_cells(cell_maps) do
    counts = Enum.frequencies_by(cell_maps, & &1["status"])

    %{
      "total" => length(cell_maps),
      "supported" => Map.get(counts, "supported", 0),
      "unverified" => Map.get(counts, "unverified", 0),
      "explicit_deferral" => Map.get(counts, "explicit_deferral", 0)
    }
  end

  defp cell_to_map(cell, matrix) do
    row = fetch_row(matrix, cell)

    %{
      "surface" => cell.surface,
      "viewer" => cell.viewer,
      "status" => cell.status,
      "notes" => cell_notes(cell, row)
    }
  end

  defp cell_notes(%{status: "supported"}, row) do
    if Map.has_key?(row, "evidence") do
      ""
    else
      "legacy: missing evidence pointer"
    end
  end

  defp cell_notes(%{status: "explicit_deferral"}, row) do
    Map.get(row, "evidence_deferred", "")
  end

  defp cell_notes(_cell, _row), do: ""

  defp print_human(%{"summary" => summary, "cells" => cells}, opts) do
    Mix.shell().info(
      "Viewer evidence: #{summary["total"]} cells " <>
        "(supported=#{summary["supported"]}, unverified=#{summary["unverified"]}, " <>
        "explicit_deferral=#{summary["explicit_deferral"]})"
    )

    Mix.shell().info("")
    print_table(cells)

    case Keyword.get(opts, :footer) do
      nil ->
        :ok

      footer ->
        Mix.shell().info("")
        Mix.shell().info(footer)
    end
  end

  defp print_table(cells) do
    columns = [
      %{key: "surface", label: "surface", width: 28},
      %{key: "viewer", label: "viewer", width: 24},
      %{key: "status", label: "status", width: 18},
      %{key: "notes", label: "notes", width: 40}
    ]

    header =
      columns
      |> Enum.map(fn col -> String.pad_trailing(col.label, col.width) end)
      |> Enum.join("  ")

    Mix.shell().info(header)
    Mix.shell().info(String.duplicate("-", String.length(header)))

    Enum.each(cells, fn cell ->
      line =
        columns
        |> Enum.map(fn col ->
          cell[col.key] |> truncate(col.width) |> String.pad_trailing(col.width)
        end)
        |> Enum.join("  ")

      Mix.shell().info(line)
    end)
  end

  defp truncate(value, width) do
    value = to_string(value)

    if String.length(value) <= width do
      value
    else
      String.slice(value, 0, width - 1) <> "…"
    end
  end

  defp missing_footer([]),
    do: "No unverified cells. Use --json for machine-readable output."

  defp missing_footer(_cells),
    do: "Record evidence or set explicit_deferral on listed cells. Use --json for scripting."

  defp print_validate_summary(warnings) do
    Mix.shell().info("Viewer evidence validation passed.")

    if warnings != [] do
      Mix.shell().info("#{length(warnings)} warning(s) emitted to stderr.")
    end
  end

  defp partition_warnings(warnings) do
    Enum.split_with(warnings, &advisory_warning?/1)
  end

  defp advisory_warning?(warning) do
    String.contains?(warning, "missing promotion-complete") or
      String.contains?(warning, "is older than")
  end

  defp fetch_row(matrix, %{matrix_path: path}) do
    case String.split(path, ".") do
      ["forms", "viewers", viewer] ->
        get_in(matrix, ["forms", "viewers", viewer]) || %{}

      ["forms", "signature_widget_viewers", viewer] ->
        get_in(matrix, ["forms", "signature_widget_viewers", viewer]) || %{}

      ["signing_preparation", "viewers", viewer] ->
        get_in(matrix, ["signing_preparation", "viewers", viewer]) || %{}

      ["signing", "viewers", viewer] ->
        get_in(matrix, ["signing", "viewers", viewer]) || %{}

      ["signing", "long_lived", "viewers", viewer] ->
        get_in(matrix, ["signing", "long_lived", "viewers", viewer]) || %{}

      ["embedded_files", "viewers", viewer] ->
        get_in(matrix, ["embedded_files", "viewers", viewer]) || %{}

      ["links", "viewers", viewer] ->
        get_in(matrix, ["links", "viewers", viewer]) || %{}

      ["protection", "viewers", viewer] ->
        get_in(matrix, ["protection", "viewers", viewer]) || %{}

      _ ->
        %{}
    end
  end

  defp usage_error!(message) do
    Mix.shell().error(message)
    Mix.shell().error("Usage: mix rendro.viewer_evidence list|validate|missing [--json]")
    exit({:shutdown, 1})
  end
end

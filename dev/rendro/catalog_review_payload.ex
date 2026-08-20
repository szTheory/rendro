defmodule Rendro.CatalogReviewPayload do
  @moduledoc false

  @candidate_root "tmp/phase130-candidate/"
  @final_ids [
    "invoice--cedar-mutual--corporate-classic--light",
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--light",
    "statement--signal-ledger--minimal-mono--dark",
    "receipt--poppy-and-grain--humanist--light",
    "receipt--poppy-and-grain--humanist--dark",
    "certificate--meridian-arts-fellowship--editorial--light",
    "certificate--meridian-arts-fellowship--editorial--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]
  @multipage_ids [
    "invoice-line-items-60-plus-page-first",
    "invoice-line-items-60-plus-page-final",
    "statement-line-items-60-plus-page-first",
    "statement-line-items-60-plus-page-final"
  ]
  @forbidden_fields ~w(quality scores passed disposition sign_off sign-off signoff)

  @spec classify(map(), [map()]) ::
          {:ok, %{final: [map()], multipage: [map()]}} | {:error, atom()}
  def classify(%{"candidate" => candidate, "cells" => cells}, proofs)
      when is_map(candidate) and is_list(cells) and is_list(proofs) do
    with :ok <- validate_candidate(candidate),
         {:ok, final_cells} <- validate_cells(cells, candidate),
         :ok <- validate_proofs(proofs),
         false <-
           quality_bearing?(candidate) or quality_bearing?(cells) or quality_bearing?(proofs) do
      {:ok,
       %{
         final: Enum.map(final_cells, &identity(&1, candidate)),
         multipage: Enum.map(proofs, &proof_identity(&1, candidate))
       }}
    else
      true -> {:error, :quality_bearing_input}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_candidate_payload}
    end
  end

  def classify(_manifest, _proofs), do: {:error, :invalid_candidate_payload}

  defp validate_candidate(%{
         "commit_sha" => commit_sha,
         "run_id" => run_id,
         "renderer" => %{"version" => version, "sha256" => renderer_sha}
       }) do
    if sha?(commit_sha, 40) and valid_run_id?(run_id) and valid_version?(version) and
         sha?(renderer_sha, 64) do
      :ok
    else
      {:error, :invalid_candidate_identity}
    end
  end

  defp validate_candidate(_candidate), do: {:error, :invalid_candidate_identity}

  defp validate_cells(cells, candidate) do
    final_cells = Enum.filter(cells, &(&1["id"] in @final_ids))

    if Enum.map(cells, &Map.get(&1, "id")) == Enum.map(Rendro.Catalog.catalog_specs(), & &1.id) and
         Enum.map(final_cells, &Map.get(&1, "id")) == @final_ids and
         Enum.all?(cells, &valid_candidate_cell?(&1, candidate)) do
      {:ok, final_cells}
    else
      {:error, :invalid_final_payload}
    end
  end

  defp valid_candidate_cell?(cell, candidate) when is_map(cell) do
    id = cell["id"]

    cell["family"] == id |> String.split("--") |> hd() and
      cell["mode"] == id |> String.split("--") |> List.last() and
      cell["page"] == 1 and
      safe_candidate_path?(cell["png_path"]) and
      sha?(cell["png_sha256"], 64) and
      sha?(cell["source_pdf_sha256"], 64) and
      cell["renderer_version"] == get_in(candidate, ["renderer", "version"]) and
      cell["renderer_sha256"] == get_in(candidate, ["renderer", "sha256"])
  end

  defp valid_candidate_cell?(_cell, _candidate), do: false

  defp validate_proofs(proofs) do
    if Enum.map(proofs, &Map.get(&1, "id")) == @multipage_ids and
         Enum.all?(proofs, &valid_proof?/1) do
      :ok
    else
      {:error, :invalid_multipage_payload}
    end
  end

  defp valid_proof?(proof) when is_map(proof) do
    [family, "line", "items", "60", "plus", "page", page] =
      String.split(proof["id"] || "", "-")

    proof["family"] == family and
      proof["page"] == page and
      safe_candidate_path?(proof["png_path"]) and
      sha?(proof["png_sha256"], 64) and
      sha?(proof["source_pdf_sha256"], 64)
  end

  defp valid_proof?(_proof), do: false

  defp identity(cell, candidate) do
    Map.take(
      cell,
      ~w(mode png_path png_sha256 source_pdf_sha256 renderer_version renderer_sha256)
    )
    |> Map.put("catalog_id", cell["id"])
    |> Map.put("commit_sha", candidate["commit_sha"])
    |> Map.put("run_id", candidate["run_id"])
  end

  defp proof_identity(proof, candidate) do
    proof
    |> Map.take(~w(id family page png_path png_sha256 source_pdf_sha256))
    |> Map.put("renderer_version", get_in(candidate, ["renderer", "version"]))
    |> Map.put("renderer_sha256", get_in(candidate, ["renderer", "sha256"]))
    |> Map.put("commit_sha", candidate["commit_sha"])
    |> Map.put("run_id", candidate["run_id"])
  end

  defp safe_candidate_path?(path) when is_binary(path) do
    String.starts_with?(path, @candidate_root) and
      match?({:ok, _safe_path}, Path.safe_relative(path))
  end

  defp safe_candidate_path?(_path), do: false

  defp sha?(value, length) when is_binary(value),
    do: Regex.match?(~r/\A[0-9a-f]+\z/, value) and byte_size(value) == length

  defp sha?(_value, _length), do: false
  defp valid_version?(version), do: is_binary(version) and String.trim(version) != ""

  defp valid_run_id?(run_id),
    do: is_binary(run_id) and Regex.match?(~r/\A[A-Za-z0-9._-]+\z/, run_id)

  defp quality_bearing?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} -> key in @forbidden_fields or quality_bearing?(nested) end)
  end

  defp quality_bearing?(value) when is_list(value), do: Enum.any?(value, &quality_bearing?/1)
  defp quality_bearing?(_value), do: false
end

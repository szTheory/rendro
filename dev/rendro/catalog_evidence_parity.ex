defmodule Rendro.CatalogEvidenceParity do
  @moduledoc false

  # This is deliberately an extractor, not a comparison of caller supplied
  # summaries.  The only accepted inputs are an unpacked retained artifact, or
  # a versioned sealed record retained with this phase.
  @routes ~w(phase126_preset_review phase127_catalog_review phase130_review phase130_canonical)a
  @sha ~r/\A[0-9a-f]{64}\z/
  @git_sha ~r/\A[0-9a-f]{40}\z/
  @selected_presets ~w(
    brutalist_payslip_dark_page_1 corporate_classic_invoice_dark_page_1
    editorial_ticket_dark_page_1 humanist_payslip_dark_page_1
    minimal_mono_ticket_dark_page_1 swiss_invoice_light_page_1
  )

  @spec compare(map(), map(), atom() | String.t()) :: {:ok, map()} | {:error, [atom()]}
  def compare(%{"root" => legacy}, %{"root" => generic}, route)
      when is_binary(legacy) and is_binary(generic) do
    with {:ok, route} <- route(route),
         {:ok, left} <- extract(legacy, :legacy, route),
         {:ok, right} <- extract(generic, :generic, route) do
      result(route, left, right)
    end
  end

  # A durable record is accepted only through this explicit sealed boundary;
  # compare/3 never treats arbitrary payload maps as evidence.
  def compare(%{"sealed_record" => record}, %{"sealed_record" => record}, route),
    do: verify_record(record, route)

  def compare(_, _, _), do: {:error, [:invalid_parity_input]}

  @spec verify_record(map(), atom() | String.t()) :: {:ok, map()} | {:error, [atom()]}
  def verify_record(record, requested_route \\ nil)

  def verify_record(record, requested_route) when is_map(record) do
    with :ok <- validate_record(record),
         {:ok, routes} <- record_routes(record, requested_route) do
      routes
      |> Enum.map(fn {route, facts} ->
        with :ok <- candidate_identity?(record["transport"], facts),
             :ok <- valid_side?(facts["legacy"]),
             :ok <- valid_side?(facts["generic"]),
             {:ok, status} <- result(route, facts["legacy"]["roles"], facts["generic"]["roles"]),
             true <- status["status"] == facts["status"] do
          {:ok, {Atom.to_string(route), status}}
        else
          false -> {:error, :fabricated_status}
          {:error, reason} -> {:error, reason}
        end
      end)
      |> collect()
      |> case do
        {:ok, values} when is_nil(requested_route) -> {:ok, Map.new(values)}
        {:ok, [{_, value}]} -> {:ok, value}
        error -> error
      end
    end
  end

  def verify_record(_, _), do: {:error, [:invalid_sealed_record]}

  defp extract(root, side, route) do
    case {side, route} do
      {:generic, :phase126_preset_review} ->
        json_role(root, "preset-review/preset.json", @selected_presets)

      {:generic, :phase127_catalog_review} ->
        generic_review(root)

      {:generic, :phase130_review} ->
        generic_review(root)

      {:generic, :phase130_canonical} ->
        json_role(root, "canonical/catalog.json", :all)

      {:legacy, :phase126_preset_review} ->
        png_role(root, "review", @selected_presets)

      {:legacy, :phase127_catalog_review} ->
        legacy_flat_review(root)

      {:legacy, :phase130_review} ->
        legacy_flat_review(root)

      {:legacy, :phase130_canonical} ->
        canonical_manifest(root)
    end
  end

  defp generic_review(root) do
    with {:ok, candidate} <- json_role(root, "candidate/catalog.json", :all),
         {:ok, final} <- json_role(root, "final-review/final.json", :all),
         {:ok, multipage} <- checksum_role(root, "multipage-review/multipage.json") do
      {:ok,
       %{
         "candidate32" => candidate["candidate32"],
         "final12" => final["final12"],
         "multipage4" => multipage["multipage4"]
       }}
    end
  end

  # The historical artifacts used underscores in file names and did not retain
  # the current role directories.  Normalize only that documented spelling
  # difference; never infer identifiers from arbitrary caller strings.
  defp legacy_flat_review(root) do
    with {:ok, files} <- regular_files(root),
         candidate = Enum.filter(files, &String.ends_with?(&1, ".png")),
         true <- candidate != [] do
      records = Enum.map(candidate, &file_record(root, &1))

      {multi, finals} =
        Enum.split_with(records, &String.contains?(&1["id"], "line-items-60-plus-page"))

      {:ok, %{"candidate32" => records, "final12" => finals, "multipage4" => multi}}
    else
      false -> {:error, [:missing_legacy_files]}
      error -> error
    end
  end

  defp canonical_manifest(root) do
    path = Path.join(root, "manifest.txt")

    with {:ok, text} <- File.read(path),
         lines <- Regex.scan(~r/([0-9a-f]{64})  assets\/rendro\/catalog\/(.+\.png)/, text),
         true <- lines != [] do
      {:ok,
       %{
         "canonical32" =>
           Enum.map(lines, fn [_, sha, file] ->
             %{"id" => canonical_id(file), "sha256" => sha}
           end)
       }}
    else
      false -> {:error, [:invalid_legacy_manifest]}
      _ -> {:error, [:invalid_legacy_manifest]}
    end
  end

  defp png_role(root, dir, selected) do
    with {:ok, files} <- regular_files(Path.join(root, dir)) do
      records =
        Enum.map(files, fn file ->
          %{
            "id" => file |> Path.basename() |> Path.rootname(),
            "sha256" =>
              file
              |> File.read!()
              |> then(&:crypto.hash(:sha256, &1))
              |> Base.encode16(case: :lower)
          }
        end)

      selected_records = Enum.filter(records, &(&1["id"] in selected))

      if length(selected_records) == length(selected),
        do: {:ok, %{"preset6" => selected_records}},
        else: {:error, [:preset_selection_mismatch]}
    end
  end

  defp json_role(root, relative, selected) do
    with {:ok, json} <- root |> Path.join(relative) |> File.read(),
         {:ok, decoded} <- Jason.decode(json),
         entries when is_list(entries) <- decoded["images"] || decoded["cells"] do
      records =
        Enum.map(entries, fn e ->
          %{"id" => e["id"] || e["catalog_id"], "sha256" => e["sha256"] || e["png_sha256"]}
        end)

      records =
        if selected == :all, do: records, else: Enum.filter(records, &(&1["id"] in selected))

      if valid_records?(records) and (selected == :all or length(records) == length(selected)),
        do: {:ok, %{role(relative) => records}},
        else: {:error, [:invalid_json_role]}
    else
      _ -> {:error, [:invalid_json_role]}
    end
  end

  defp checksum_role(root, relative) do
    with {:ok, text} <- root |> Path.join(relative) |> File.read() do
      records =
        for [_, sha, path] <- Regex.scan(~r/([0-9a-f]{64})  (.+)/, text),
            do: %{"id" => id(path), "sha256" => sha}

      if valid_records?(records),
        do: {:ok, %{role(relative) => records}},
        else: {:error, [:invalid_checksum_role]}
    end
  end

  defp result(route, legacy, generic) when is_map(legacy) and is_map(generic) do
    expected = expected(route)

    with :ok <- expected_roles(legacy, expected), :ok <- expected_roles(generic, expected) do
      status = if canonical(legacy) == canonical(generic), do: "matched", else: "mismatch"

      {:ok,
       %{"route" => Atom.to_string(route), "status" => status, "roles" => canonical(generic)}}
    end
  end

  defp result(_, _, _), do: {:error, [:invalid_normalized_evidence]}

  defp expected(:phase126_preset_review), do: %{"preset6" => 6}
  defp expected(:phase130_canonical), do: %{"canonical32" => 32}
  defp expected(_), do: %{"candidate32" => 32, "final12" => 12, "multipage4" => 4}

  defp expected_roles(value, expected),
    do:
      if(
        Map.keys(value) |> Enum.sort() == Map.keys(expected) |> Enum.sort() and
          Enum.all?(expected, fn {k, n} -> valid_records?(value[k]) and length(value[k]) == n end),
        do: :ok,
        else: {:error, [:route_cardinality_mismatch]}
      )

  defp canonical(value),
    do:
      value
      |> Enum.map(fn {role, records} -> {role, Enum.sort_by(records, & &1["id"])} end)
      |> Enum.sort()

  defp valid_record?(record) do
    record["schema_version"] == 2 and record["sealed"] == true and
      valid_transport?(record["transport"]) and is_map(record["routes"])
  end

  defp validate_record(record) do
    if valid_record?(record), do: :ok, else: {:error, [:invalid_sealed_record]}
  end

  defp candidate_identity?(%{"candidate_sha" => candidate}, %{
         "legacy" => legacy,
         "generic" => generic
       }) do
    if get_in(legacy, ["transport", "candidate_sha"]) == candidate and
         get_in(generic, ["transport", "candidate_sha"]) == candidate,
       do: :ok,
       else: {:error, :candidate_identity_mismatch}
  end

  defp candidate_identity?(_, _), do: {:error, :candidate_identity_mismatch}

  defp valid_side?(%{"transport" => transport, "roles" => roles}) when is_map(roles) do
    if valid_transport?(transport), do: :ok, else: {:error, :invalid_transport}
  end

  defp valid_side?(_), do: {:error, :invalid_side}

  defp valid_transport?(%{
         "candidate_sha" => sha,
         "run_url" => url,
         "run_id" => run_id,
         "run_attempt" => attempt,
         "artifact_identity" => identity,
         "archive_sha256" => digest,
         "renderer" => renderer,
         "actions" => %{"checkout" => pin},
         "permissions" => %{"contents" => "read"}
       }) do
    Regex.match?(@git_sha, sha) and Regex.match?(@git_sha, pin) and Regex.match?(@sha, digest) and
      is_binary(url) and String.starts_with?(url, "https://github.com/") and is_binary(run_id) and
      Regex.match?(~r/\A\d+\z/, run_id) and is_integer(attempt) and attempt > 0 and
      is_binary(identity) and identity != "" and valid_renderer?(renderer)
  end

  defp valid_transport?(_), do: false

  defp valid_renderer?(%{"version" => v, "binary_sha256" => sha, "dpi" => dpi}),
    do: is_binary(v) and Regex.match?(@sha, sha) and is_integer(dpi) and dpi > 0

  defp valid_renderer?(_), do: false
  defp record_routes(record, nil), do: record_routes(record, :all)

  defp record_routes(record, :all) do
    routes =
      for route <- @routes,
          facts = record["routes"][Atom.to_string(route)],
          do: {route, facts}

    {:ok, routes}
  end

  defp record_routes(record, requested),
    do:
      with(
        {:ok, route} <- route(requested),
        facts when is_map(facts) <- record["routes"][Atom.to_string(route)],
        do: {:ok, [{route, facts}]},
        else: (_ -> {:error, [:missing_route_record]})
      )

  defp route(route) when route in @routes, do: {:ok, route}

  defp route(route) when is_binary(route),
    do:
      Enum.find_value(@routes, {:error, [:invalid_route]}, fn r ->
        if Atom.to_string(r) == route, do: {:ok, r}
      end)

  defp route(_), do: {:error, [:invalid_route]}

  defp collect(results),
    do:
      if(Enum.all?(results, &match?({:ok, _}, &1)),
        do: {:ok, Enum.map(results, fn {:ok, v} -> v end)},
        else:
          {:error,
           results
           |> Enum.find_value(fn x ->
             case x do
               {:error, e} -> e
               _ -> nil
             end
           end)
           |> List.wrap()}
      )

  defp regular_files(root),
    do:
      if(File.dir?(root),
        do: {:ok, root |> Path.join("**/*") |> Path.wildcard() |> Enum.filter(&File.regular?/1)},
        else: {:error, [:missing_artifact_root]}
      )

  defp file_record(root, path),
    do: %{
      "id" => id(Path.relative_to(path, root)),
      "sha256" =>
        path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    }

  defp id(path),
    do:
      path
      |> Path.basename()
      |> Path.rootname()
      |> String.replace("_page_1", "")
      |> String.replace("_", "-")

  # Canonical manifests retain recipe/scenario/preset-theme as path segments.
  # Those segments are semantic identity: collapsing to a basename merges
  # otherwise distinct records such as invoice/default/default-light.
  defp canonical_id(path),
    do:
      path
      |> Path.rootname()
      |> String.split("/")
      |> then(fn [recipe, scenario, preset_theme] ->
        Enum.join([recipe, scenario, String.replace(preset_theme, ~r/-([^-]+)$/, "--\\1")], "--")
      end)

  defp role("candidate/catalog.json"), do: "candidate32"
  defp role("final-review/final.json"), do: "final12"
  defp role("multipage-review/multipage.json"), do: "multipage4"
  defp role("preset-review/preset.json"), do: "preset6"
  defp role("canonical/catalog.json"), do: "canonical32"

  defp valid_records?(records),
    do:
      is_list(records) and records != [] and
        length(Enum.uniq_by(records, & &1["id"])) == length(records) and
        Enum.all?(records, fn
          %{"id" => id, "sha256" => sha} ->
            is_binary(id) and id != "" and is_binary(sha) and Regex.match?(@sha, sha)

          _ ->
            false
        end)
end

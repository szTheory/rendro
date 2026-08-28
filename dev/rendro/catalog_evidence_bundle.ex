defmodule Rendro.CatalogEvidenceBundle do
  @moduledoc false

  @schema_version 1
  @root_files ["README.md", "checksums.sha256", "manifest.json"]
  @roles %{
    review: [
      "candidate/catalog.json",
      "final-review/final.json",
      "multipage-review/multipage.json",
      "preset-review/preset.json"
    ],
    canonical: ["canonical/catalog.json"]
  }
  @role_counts %{
    "candidate/catalog.json" => 32,
    "final-review/final.json" => 12,
    "multipage-review/multipage.json" => 4,
    "preset-review/preset.json" => 12,
    "canonical/catalog.json" => 32
  }

  @spec build(atom() | String.t(), [map()], map(), Path.t()) :: :ok | {:error, [atom()]}
  def build(operation, payload_sources, provenance, output_root)
      when is_list(payload_sources) and is_map(provenance) and is_binary(output_root) do
    operation = normalize_operation(operation)

    with :ok <- validate_input(operation, payload_sources, provenance, output_root),
         :ok <- write_bundle(operation, payload_sources, provenance, output_root),
         :ok <- validate(output_root, operation, provenance.control_sha) do
      :ok
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
      {:error, reason} -> {:error, [reason]}
    end
  end

  def build(_operation, _payload_sources, _provenance, _output_root),
    do: {:error, [:invalid_bundle_input]}

  @spec validate(Path.t(), atom() | String.t(), String.t()) :: :ok | {:error, [atom()]}
  def validate(output_root, operation, expected_control_sha)
      when is_binary(output_root) and is_binary(expected_control_sha) do
    operation = normalize_operation(operation)

    with {:ok, pin} <- read_renderer_pin(),
         {:ok, checkout_control_sha} <- checked_out_control_sha(),
         {:ok, manifest} <- read_manifest(output_root),
         :ok <-
           validate_manifest(
             operation,
             manifest,
             expected_control_sha,
             checkout_control_sha,
             pin
           ),
         :ok <- validate_files(output_root, manifest),
         :ok <- validate_checksums(output_root, manifest) do
      :ok
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
      {:error, reason} -> {:error, [reason]}
    end
  end

  def validate(_output_root, _operation, _expected_control_sha),
    do: {:error, [:invalid_bundle_root]}

  defp validate_input(operation, sources, provenance, output_root) do
    reasons =
      []
      |> invalid_unless(operation in Map.keys(@roles), :invalid_operation)
      |> invalid_unless(valid_provenance?(provenance), :invalid_provenance)
      |> invalid_unless(valid_sha?(provenance[:candidate_sha]), :invalid_candidate_sha)
      |> invalid_unless(
        provenance[:candidate_sha] == provenance[:checked_out_head],
        :head_mismatch
      )
      |> invalid_unless(safe_output_root?(output_root), :unsafe_output_root)
      |> invalid_unless(valid_sources?(sources, operation), :invalid_payload_roles)
      |> invalid_unless(valid_source_record_counts?(sources), :invalid_payload_counts)
      |> invalid_unless(
        operation != :review or not Map.has_key?(provenance, :reviewer_approval),
        :candidate_reviewer_approval_forbidden
      )

    if reasons == [], do: :ok, else: {:error, Enum.reverse(reasons)}
  end

  defp write_bundle(operation, sources, provenance, output_root) do
    with :ok <- File.mkdir_p(output_root),
         :ok <- copy_payloads(sources, output_root),
         :ok <- write_readme(output_root, operation, provenance),
         :ok <- write_manifest(output_root, operation, sources, provenance),
         :ok <- write_checksums(output_root, sources) do
      :ok
    end
  end

  defp copy_payloads(sources, output_root) do
    sources
    |> Enum.map(fn %{role: role, source: source} ->
      target = Path.join(output_root, role)
      with :ok <- File.mkdir_p(Path.dirname(target)), do: File.cp(source, target)
    end)
    |> first_error()
  end

  defp write_readme(output_root, operation, provenance) do
    contents = """
    # Rendro Catalog Evidence

    **Operation:** #{operation}
    **Candidate SHA:** #{provenance.candidate_sha}
    **Control SHA:** #{provenance.control_sha}

    This is one bounded transport bundle. #{evidence_state(operation)}.
    Validate it with the catalog evidence validator before relying on its payload facts.
    """

    File.write(Path.join(output_root, "README.md"), contents)
  end

  defp write_manifest(output_root, operation, sources, provenance) do
    manifest = %{
      "schema_version" => @schema_version,
      "evidence_state" => evidence_state(operation),
      "operation" => Atom.to_string(operation),
      "control" => %{"workflow_sha" => provenance.control_sha},
      "candidate_sha" => provenance.candidate_sha,
      "checked_out_head" => provenance.checked_out_head,
      "event" => provenance.event,
      "run_id" => provenance.run_id,
      "run_attempt" => provenance.run_attempt,
      "renderer" => renderer(provenance),
      "commands" => commands(operation),
      "payloads" => payloads(sources, output_root),
      "authority" => authority(operation)
    }

    File.write(
      Path.join(output_root, "manifest.json"),
      Jason.encode!(manifest, pretty: true) <> "\n"
    )
  end

  defp write_checksums(output_root, sources) do
    paths = (@root_files -- ["checksums.sha256"]) ++ Enum.map(sources, & &1.role)

    contents =
      paths
      |> Enum.map(fn path -> "#{sha256_file!(Path.join(output_root, path))}  #{path}" end)
      |> Enum.sort()
      |> Enum.join("\n")
      |> Kernel.<>("\n")

    File.write(Path.join(output_root, "checksums.sha256"), contents)
  end

  defp validate_manifest(operation, manifest, expected_control_sha, checkout_control_sha, pin) do
    expected_roles = Map.get(@roles, operation, [])
    payloads = Map.get(manifest, "payloads", [])

    reasons =
      []
      |> invalid_unless(operation in Map.keys(@roles), :invalid_operation)
      |> invalid_unless(manifest["schema_version"] == @schema_version, :invalid_schema_version)
      |> invalid_unless(manifest["operation"] == Atom.to_string(operation), :operation_mismatch)
      |> invalid_unless(valid_sha?(manifest["candidate_sha"]), :invalid_candidate_sha)
      |> invalid_unless(manifest["candidate_sha"] == manifest["checked_out_head"], :head_mismatch)
      |> invalid_unless(
        valid_sha?(get_in(manifest, ["control", "workflow_sha"])),
        :invalid_control_sha
      )
      |> invalid_unless(valid_sha?(expected_control_sha), :invalid_expected_control_sha)
      |> invalid_unless(
        get_in(manifest, ["control", "workflow_sha"]) == expected_control_sha,
        :control_sha_mismatch
      )
      |> invalid_unless(
        expected_control_sha == checkout_control_sha,
        :control_checkout_mismatch
      )
      |> invalid_unless(valid_run_id?(manifest["run_id"]), :invalid_run_id)
      |> invalid_unless(valid_run_attempt?(manifest["run_attempt"]), :invalid_run_attempt)
      |> invalid_unless(valid_renderer?(manifest["renderer"], pin), :renderer_pin_mismatch)
      |> invalid_unless(
        valid_payloads?(payloads, expected_roles, operation),
        :invalid_payload_roles
      )
      |> invalid_unless(valid_authority?(manifest, operation), :invalid_authority)

    if reasons == [], do: :ok, else: {:error, Enum.reverse(reasons)}
  end

  defp validate_files(output_root, manifest) do
    payloads = manifest["payloads"]
    expected = @root_files ++ Enum.map(payloads, & &1["path"])

    reasons =
      []
      |> invalid_unless(
        Enum.sort(relative_files(output_root)) == Enum.sort(expected),
        :unexpected_bundle_files
      )
      |> Kernel.++(payload_file_errors(output_root, payloads))
      |> Kernel.++(payload_record_count_errors(output_root, payloads))

    if reasons == [], do: :ok, else: {:error, Enum.uniq(reasons)}
  end

  defp validate_checksums(output_root, manifest) do
    expected_paths =
      ["README.md", "manifest.json"] ++ Enum.map(manifest["payloads"], & &1["path"])

    checksum_path = Path.join(output_root, "checksums.sha256")

    with {:ok, contents} <- File.read(checksum_path),
         {:ok, entries} <- parse_checksums(contents) do
      if valid_checksum_entries?(entries, expected_paths, output_root) do
        :ok
      else
        {:error, [:checksum_mismatch]}
      end
    else
      {:error, _reason} -> {:error, [:invalid_checksums]}
    end
  end

  defp read_manifest(output_root) do
    with {:ok, contents} <- File.read(Path.join(output_root, "manifest.json")),
         {:ok, manifest} <- Jason.decode(contents) do
      {:ok, manifest}
    else
      _ -> {:error, :invalid_manifest}
    end
  end

  defp valid_sources?(sources, operation) do
    Enum.map(sources, &Map.get(&1, :role)) == Map.get(@roles, operation, []) and
      Enum.all?(sources, fn source ->
        valid_source?(source) and Path.safe_relative(source.role) != :error
      end)
  end

  defp valid_source_record_counts?(sources) do
    Enum.all?(sources, fn source ->
      source.count == Map.get(@role_counts, source.role) and
        record_count(source.role, source.source) == {:ok, source.count}
    end)
  end

  defp valid_source?(%{role: role, source: source, media_type: media_type, count: count}) do
    is_binary(role) and is_binary(source) and is_binary(media_type) and is_integer(count) and
      count > 0 and
      File.regular?(source)
  end

  defp valid_source?(_source), do: false

  defp valid_payloads?(payloads, expected_roles, _operation) when is_list(payloads) do
    Enum.map(payloads, &Map.get(&1, "role")) == expected_roles and
      Enum.all?(payloads, fn payload ->
        payload["path"] == payload["role"] and
          Path.safe_relative(payload["path"] || "") != :error and
          valid_sha256?(payload["sha256"]) and
          payload["count"] == Map.get(@role_counts, payload["role"]) and
          is_binary(payload["media_type"])
      end)
  end

  defp valid_payloads?(_payloads, _expected_roles, _operation), do: false

  defp valid_authority?(manifest, operation) do
    authority = manifest["authority"]

    is_map(authority) and authority["transport"] == "advisory" and
      (operation != :review or authority["reviewer_approval_recorded"] == false)
  end

  defp valid_renderer?(%{"version" => version, "binary_sha256" => sha, "dpi" => dpi}, pin),
    do:
      is_binary(version) and valid_sha256?(sha) and is_integer(dpi) and dpi > 0 and
        version == pin["version"] and sha == pin["sha256"]

  defp valid_renderer?(_renderer, _pin), do: false

  defp payload_file_errors(output_root, payloads) do
    Enum.flat_map(payloads, fn payload ->
      path = Path.join(output_root, payload["path"])

      cond do
        not File.regular?(path) -> [:missing_payload]
        sha256_file!(path) != payload["sha256"] -> [:payload_hash_mismatch]
        true -> []
      end
    end)
  end

  defp payload_record_count_errors(output_root, payloads) do
    Enum.flat_map(payloads, fn payload ->
      count = payload["count"]

      case record_count(payload["role"], Path.join(output_root, payload["path"])) do
        {:ok, ^count} -> []
        _ -> [:payload_count_mismatch]
      end
    end)
  end

  # Counts come from the closed record collection in each payload, not metadata.
  defp record_count("multipage-review/multipage.json", path) do
    with {:ok, contents} <- File.read(path) do
      records = String.split(contents, "\n", trim: true)

      if Enum.all?(records, &Regex.match?(~r/\A[0-9a-f]{64}  .+\z/, &1)),
        do: {:ok, length(records)},
        else: :error
    end
  end

  defp record_count(role, path)
       when role in [
              "candidate/catalog.json",
              "final-review/final.json",
              "preset-review/preset.json",
              "canonical/catalog.json"
            ] do
    with {:ok, contents} <- File.read(path),
         {:ok, decoded} <- Jason.decode(contents),
         records when is_list(records) <- Map.get(decoded, "images", decoded) do
      {:ok, length(records)}
    else
      _ -> :error
    end
  end

  defp record_count(_role, _path), do: :error

  defp payloads(sources, output_root) do
    Enum.map(sources, fn source ->
      %{
        "role" => source.role,
        "path" => source.role,
        "media_type" => source.media_type,
        "sha256" => sha256_file!(Path.join(output_root, source.role)),
        "count" => source.count
      }
    end)
  end

  defp renderer(provenance) do
    {:ok, pin} = read_renderer_pin()

    %{
      "version" => pin["version"],
      "binary_sha256" => pin["sha256"],
      "dpi" => provenance.dpi
    }
  end

  defp commands(:review), do: ["mix rendro.catalog.candidate", "mix rendro.catalog.check"]
  defp commands(:canonical), do: ["mix rendro.catalog.gen", "mix rendro.catalog.check"]

  defp authority(:review),
    do: %{
      "transport" => "advisory",
      "reviewer_approval_recorded" => false,
      "limit" => "Candidate evidence only — reviewer approval is not recorded here."
    }

  defp authority(:canonical),
    do: %{
      "transport" => "advisory",
      "limit" => "Canonical evidence — materialize only after the catalog check passes."
    }

  defp evidence_state(:review), do: "candidate_evidence_only"
  defp evidence_state(:canonical), do: "canonical_evidence"

  defp valid_provenance?(provenance) do
    Enum.all?(
      [:candidate_sha, :checked_out_head, :control_sha, :event, :run_id, :run_attempt, :dpi],
      &Map.has_key?(provenance, &1)
    ) and
      valid_sha?(provenance[:control_sha]) and is_binary(provenance[:event]) and
      valid_run_id?(provenance[:run_id]) and valid_run_attempt?(provenance[:run_attempt]) and
      is_integer(provenance[:dpi])
  end

  defp safe_output_root?(path), do: path != "" and not String.contains?(path, "\0")

  defp read_renderer_pin do
    with {:ok, contents} <- File.read("priv/pdfium_pin.json"),
         {:ok, pin} <- Jason.decode(contents),
         true <- is_binary(pin["version"]) and valid_sha256?(pin["sha256"]) do
      {:ok, pin}
    else
      _ -> {:error, :invalid_renderer_pin}
    end
  end

  defp checked_out_control_sha do
    case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} ->
        sha = String.trim(sha)
        if valid_sha?(sha), do: {:ok, sha}, else: {:error, :invalid_control_checkout}

      _ ->
        {:error, :invalid_control_checkout}
    end
  end

  defp valid_sha?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{40}\z/, value)
  defp valid_sha256?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)
  defp valid_run_id?(value), do: is_binary(value) and Regex.match?(~r/\A[1-9][0-9]*\z/, value)
  defp valid_run_attempt?(value), do: is_integer(value) and value > 0

  defp sha256_file!(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp relative_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, root))
  end

  defp parse_checksums(contents) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case String.split(line, "  ", parts: 2) do
        [digest, path] when byte_size(digest) == 64 -> {digest, path}
        _ -> :invalid
      end
    end)
    |> then(fn entries ->
      if :invalid in entries, do: {:error, :invalid}, else: {:ok, entries}
    end)
  end

  defp valid_checksum_entries?(entries, expected_paths, output_root) do
    Enum.sort(Enum.map(entries, &elem(&1, 1))) == Enum.sort(expected_paths) and
      Enum.all?(entries, fn {digest, path} ->
        digest == sha256_file!(Path.join(output_root, path))
      end)
  end

  defp first_error(results) do
    case Enum.find(results, &(&1 != :ok)) do
      nil -> :ok
      error -> error
    end
  end

  defp invalid_unless(reasons, true, _reason), do: reasons
  defp invalid_unless(reasons, false, reason), do: [reason | reasons]

  defp normalize_operation(operation) when operation in [:review, :canonical], do: operation
  defp normalize_operation("review"), do: :review
  defp normalize_operation("canonical"), do: :canonical
  defp normalize_operation(_operation), do: :invalid
end

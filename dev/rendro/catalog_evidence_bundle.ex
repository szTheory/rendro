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
  @target_ids [
    "invoice--cedar-mutual--corporate-classic--dark",
    "statement--signal-ledger--minimal-mono--dark",
    "payslip--northline-logistics--swiss--light",
    "payslip--northline-logistics--swiss--dark",
    "ticket--aurora-live--brutalist--light",
    "ticket--aurora-live--brutalist--dark"
  ]
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
  @preset_ids [
    "brutalist_payslip_dark_page_1",
    "brutalist_receipt_light_page_1",
    "corporate_classic_branded_invoice_light_page_1",
    "corporate_classic_invoice_dark_page_1",
    "editorial_certificate_light_page_1",
    "editorial_ticket_dark_page_1",
    "humanist_payslip_dark_page_1",
    "humanist_receipt_light_page_1",
    "minimal_mono_statement_light_page_1",
    "minimal_mono_ticket_dark_page_1",
    "swiss_certificate_dark_page_1",
    "swiss_invoice_light_page_1"
  ]
  @forbidden_authority_fields ~w(quality scores passed disposition sign_off sign-off signoff reviewer reviewer_approval approval canonical_eligible publication_authorization publication_result)

  @spec build(atom() | String.t(), [map()], map(), Path.t()) :: :ok | {:error, [atom()]}
  def build(operation, payload_sources, provenance, output_root)
      when is_list(payload_sources) and is_map(provenance) and is_binary(output_root) do
    operation = normalize_operation(operation)

    with {:ok, pin} <- read_renderer_pin(),
         :ok <- validate_input(operation, payload_sources, provenance, output_root),
         :ok <- validate_semantic_sources(operation, payload_sources, provenance, pin),
         :ok <- write_bundle(operation, payload_sources, provenance, output_root, pin),
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
         :ok <- validate_checksums(output_root, manifest),
         :ok <- validate_bundle_semantics(output_root, operation, manifest, pin) do
      :ok
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
      {:error, reason} -> {:error, [reason]}
    end
  end

  def validate(_output_root, _operation, _expected_control_sha),
    do: {:error, [:invalid_bundle_root]}

  @spec inspect_review(Path.t(), String.t()) :: {:ok, map()} | {:error, [atom()]}
  def inspect_review(output_root, expected_control_sha) do
    with :ok <- validate(output_root, :review, expected_control_sha),
         {:ok, pin} <- read_renderer_pin(),
         {:ok, candidate} <- read_json(Path.join(output_root, "candidate/catalog.json")),
         {:ok, final} <- read_json(Path.join(output_root, "final-review/final.json")),
         {:ok, preset} <- read_json(Path.join(output_root, "preset-review/preset.json")),
         {:ok, multipage} <-
           read_checksum_payload(Path.join(output_root, "multipage-review/multipage.json")) do
      {:ok,
       %{
         candidate: candidate,
         final: final,
         multipage: multipage,
         preset: preset,
         renderer: pin,
         root: output_root
       }}
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
      {:error, reason} -> {:error, [reason]}
    end
  end

  @spec validate_renderer_pin(Path.t()) :: :ok | {:error, [atom()]}
  def validate_renderer_pin(path) when is_binary(path) do
    case read_renderer_pin(path) do
      {:ok, _pin} -> :ok
      {:error, _reason} -> {:error, [:invalid_renderer_pin]}
    end
  end

  def validate_renderer_pin(_path), do: {:error, [:invalid_renderer_pin]}

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

  defp write_bundle(operation, sources, provenance, output_root, pin) do
    with :ok <- File.mkdir_p(output_root),
         :ok <- copy_payloads(sources, output_root),
         :ok <- write_readme(output_root, operation, provenance),
         :ok <- write_manifest(output_root, operation, sources, provenance, pin),
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

  defp write_manifest(output_root, operation, sources, provenance, pin) do
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
      "renderer" => renderer(provenance, pin),
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

  defp record_count("candidate/catalog.json", path), do: json_record_count(path, "cells")

  defp record_count("canonical/catalog.json", path), do: json_record_count(path, "cells")

  defp record_count(role, path)
       when role in [
              "final-review/final.json",
              "preset-review/preset.json"
            ] do
    json_record_count(path, "images")
  end

  defp record_count(_role, _path), do: :error

  defp json_record_count(path, collection) do
    with {:ok, contents} <- File.read(path),
         {:ok, decoded} <- Jason.decode(contents),
         records when is_list(records) <- Map.get(decoded, collection) do
      {:ok, length(records)}
    else
      _ -> :error
    end
  end

  defp validate_bundle_semantics(output_root, operation, manifest, pin) do
    sources =
      Map.get(@roles, operation, [])
      |> Enum.map(fn role ->
        %{
          role: role,
          source: Path.join(output_root, role),
          media_type: "application/json",
          count: @role_counts[role]
        }
      end)

    provenance = %{
      candidate_sha: manifest["candidate_sha"],
      checked_out_head: manifest["checked_out_head"],
      control_sha: get_in(manifest, ["control", "workflow_sha"]),
      event: manifest["event"],
      run_id: manifest["run_id"],
      run_attempt: manifest["run_attempt"],
      dpi: get_in(manifest, ["renderer", "dpi"])
    }

    validate_semantic_sources(operation, sources, provenance, pin)
  end

  defp validate_semantic_sources(:review, sources, provenance, pin) do
    by_role = Map.new(sources, &{&1.role, &1.source})

    with {:ok, candidate} <- read_json(by_role["candidate/catalog.json"]),
         {:ok, final} <- read_json(by_role["final-review/final.json"]),
         {:ok, multipage} <- read_checksum_payload(by_role["multipage-review/multipage.json"]),
         {:ok, preset} <- read_json(by_role["preset-review/preset.json"]) do
      reasons =
        []
        |> add_unless(
          valid_candidate_payload?(candidate, provenance, pin),
          :invalid_candidate_payload
        )
        |> add_unless(valid_final_payload?(final, provenance, pin), :invalid_final_payload)
        |> add_unless(valid_multipage_payload?(multipage), :invalid_multipage_payload)
        |> add_unless(valid_preset_payload?(preset, provenance, pin), :invalid_preset_payload)
        |> add_unless(
          cross_payloads_match?(candidate, final, multipage),
          :cross_payload_identity_mismatch
        )

      if reasons == [], do: :ok, else: {:error, Enum.reverse(reasons)}
    else
      _ -> {:error, [:invalid_role_payload]}
    end
  end

  defp validate_semantic_sources(:canonical, [source], provenance, pin) do
    with {:ok, canonical} <- read_json(source.source) do
      if valid_canonical_payload?(canonical, provenance, pin),
        do: :ok,
        else: {:error, [:invalid_canonical_payload]}
    else
      _ -> {:error, [:invalid_canonical_payload]}
    end
  end

  defp validate_semantic_sources(:canonical, _sources, _provenance, _pin),
    do: {:error, [:invalid_canonical_payload]}

  defp validate_semantic_sources(_operation, _sources, _provenance, _pin),
    do: {:error, [:invalid_operation]}

  defp valid_candidate_payload?(payload, provenance, pin) when is_map(payload) do
    ids = canonical_ids()
    cells = payload["cells"]
    candidate = payload["candidate"]
    renderer = payload["renderer"]
    diff = payload["diff"]
    controls = Enum.reject(ids, &(&1 in @target_ids))

    is_list(cells) and Enum.map(cells, &Map.get(&1, "id")) == ids and
      length(Enum.uniq(ids)) == 32 and
      Enum.all?(cells, &valid_candidate_cell?(&1, pin)) and
      is_map(candidate) and candidate["commit_sha"] == provenance.candidate_sha and
      candidate["baseline_commit_sha"] == provenance.control_sha and
      candidate["run_id"] == provenance.run_id and
      candidate["run_attempt"] == provenance.run_attempt and
      valid_candidate_renderer?(candidate["renderer"], provenance, pin) and
      valid_candidate_renderer?(renderer, provenance, pin, "pin_sha256") and
      is_map(diff) and diff["changed_targets"] == @target_ids and
      diff["byte_stable"] == controls and
      diff["changed_scored"] ++ diff["changed_unscored"] == @target_ids and
      MapSet.disjoint?(MapSet.new(diff["changed_targets"]), MapSet.new(diff["byte_stable"])) and
      not authority_bearing?(payload)
  rescue
    _ -> false
  end

  defp valid_candidate_payload?(_payload, _provenance, _pin), do: false

  defp valid_candidate_cell?(cell, pin) when is_map(cell) do
    id = cell["id"]

    case String.split(id || "", "--") do
      [family, _brand, _preset, mode] ->
        id in canonical_ids() and cell["family"] == family and cell["mode"] == mode and
          cell["page"] == 1 and is_integer(cell["page_count"]) and cell["page_count"] > 0 and
          safe_relative?(cell["png_path"], "tmp/phase130-candidate/") and
          valid_sha256?(cell["png_sha256"]) and valid_sha256?(cell["source_pdf_sha256"]) and
          cell["renderer_kind"] == "pdfium-render" and
          cell["renderer_version"] == pin["version"] and
          cell["renderer_sha256"] == pin["sha256"] and is_integer(cell["width_px"]) and
          cell["width_px"] > 0 and is_integer(cell["height_px"]) and cell["height_px"] > 0

      _ ->
        false
    end
  end

  defp valid_candidate_cell?(_cell, _pin), do: false

  defp valid_candidate_renderer?(renderer, provenance, pin, digest_key \\ "sha256")

  defp valid_candidate_renderer?(renderer, provenance, pin, digest_key) when is_map(renderer) do
    renderer["kind"] == "pdfium-render" and renderer["version"] == pin["version"] and
      renderer[digest_key] == pin["sha256"] and renderer["dpi"] == provenance.dpi and
      renderer["pin_path"] == "priv/pdfium_pin.json"
  end

  defp valid_candidate_renderer?(_renderer, _provenance, _pin, _digest_key), do: false

  defp valid_final_payload?(payload, provenance, pin) when is_map(payload) do
    images = payload["images"]

    Map.keys(payload) |> Enum.sort() ==
      Enum.sort(~w(candidate_sha control_sha images renderer run_attempt run_id)) and
      payload["candidate_sha"] == provenance.candidate_sha and
      payload["control_sha"] == provenance.control_sha and payload["run_id"] == provenance.run_id and
      payload["run_attempt"] == provenance.run_attempt and
      payload["renderer"] == %{"version" => pin["version"], "sha256" => pin["sha256"]} and
      is_list(images) and Enum.map(images, &Map.get(&1, "catalog_id")) == @final_ids and
      Enum.all?(images, &valid_final_image?(&1, provenance, pin)) and
      not authority_bearing?(payload)
  end

  defp valid_final_payload?(_payload, _provenance, _pin), do: false

  defp valid_final_image?(image, provenance, pin) when is_map(image) do
    id = image["catalog_id"]
    mode = id && List.last(String.split(id, "--"))

    Map.keys(image) |> Enum.sort() ==
      Enum.sort(
        ~w(catalog_id commit_sha control_sha mode png_path png_sha256 renderer_sha256 renderer_version run_attempt run_id source_pdf_sha256)
      ) and
      id in @final_ids and image["mode"] == mode and
      safe_relative?(image["png_path"], "tmp/phase130-candidate/") and
      valid_sha256?(image["png_sha256"]) and valid_sha256?(image["source_pdf_sha256"]) and
      image["renderer_version"] == pin["version"] and image["renderer_sha256"] == pin["sha256"] and
      image["commit_sha"] == provenance.candidate_sha and
      image["control_sha"] == provenance.control_sha and
      image["run_id"] == provenance.run_id and image["run_attempt"] == provenance.run_attempt
  end

  defp valid_final_image?(_image, _provenance, _pin), do: false

  defp valid_multipage_payload?(entries) when is_list(entries) do
    Enum.map(entries, &elem(&1, 1)) == Enum.map(@multipage_ids, &(&1 <> ".png")) and
      Enum.all?(entries, fn {digest, path} -> valid_sha256?(digest) and safe_relative?(path) end)
  end

  defp valid_multipage_payload?(_entries), do: false

  defp valid_preset_payload?(payload, provenance, pin) when is_map(payload) do
    images = payload["images"]

    Map.keys(payload) |> Enum.sort() == Enum.sort(~w(candidate_sha images renderer)) and
      payload["candidate_sha"] == provenance.candidate_sha and
      payload["renderer"] == %{"version" => pin["version"], "sha256" => pin["sha256"]} and
      is_list(images) and Enum.map(images, &Map.get(&1, "id")) == @preset_ids and
      Enum.all?(images, fn image ->
        Map.keys(image) |> Enum.sort() == Enum.sort(~w(id path sha256)) and
          image["id"] in @preset_ids and safe_relative?(image["path"], "preset-review/") and
          valid_sha256?(image["sha256"])
      end) and not authority_bearing?(payload)
  end

  defp valid_preset_payload?(_payload, _provenance, _pin), do: false

  defp valid_canonical_payload?(payload, provenance, pin) when is_map(payload) do
    cells = payload["cells"]
    renderer = payload["renderer"]

    is_list(cells) and Enum.map(cells, &Map.get(&1, "id")) == canonical_ids() and
      Enum.all?(cells, fn cell ->
        cell["id"] in canonical_ids() and
          safe_relative?(cell["png_path"], "assets/rendro/catalog/") and
          valid_sha256?(cell["png_sha256"]) and valid_sha256?(cell["source_pdf_sha256"]) and
          cell["renderer_kind"] == "pdfium-render" and cell["renderer_version"] == pin["version"]
      end) and renderer["kind"] == "pdfium-render" and renderer["version"] == pin["version"] and
      renderer["pin_sha256"] == pin["sha256"] and
      payload["source_commit_sha"] == provenance.control_sha
  rescue
    _ -> false
  end

  defp valid_canonical_payload?(_payload, _provenance, _pin), do: false

  defp cross_payloads_match?(candidate, final, multipage) do
    cells = Map.new(candidate["cells"] || [], &{&1["id"], &1})
    proofs = Map.new(candidate["multipage"] || [], &{&1["id"], &1})

    Enum.all?(final["images"] || [], fn image ->
      cell = cells[image["catalog_id"]]

      is_map(cell) and image["png_path"] == cell["png_path"] and
        image["png_sha256"] == cell["png_sha256"] and
        image["source_pdf_sha256"] == cell["source_pdf_sha256"]
    end) and
      Enum.all?(multipage, fn {digest, path} ->
        id = String.trim_trailing(path, ".png")
        is_map(proofs[id]) and proofs[id]["png_sha256"] == digest
      end)
  rescue
    _ -> false
  end

  defp read_json(path) when is_binary(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, decoded} when is_map(decoded) <- Jason.decode(contents),
         do: {:ok, decoded},
         else: (_ -> {:error, :invalid_json_payload})
  end

  defp read_json(_path), do: {:error, :invalid_json_payload}

  defp read_checksum_payload(path) when is_binary(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, entries} <- parse_checksums(contents),
         do: {:ok, entries},
         else: (_ -> {:error, :invalid_checksum_payload})
  end

  defp read_checksum_payload(_path), do: {:error, :invalid_checksum_payload}

  defp canonical_ids do
    case File.read("assets/rendro/catalog.json") do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, %{"cells" => cells}} when is_list(cells) -> Enum.map(cells, & &1["id"])
          _ -> []
        end

      _ ->
        []
    end
  end

  defp safe_relative?(path, prefix \\ nil)

  defp safe_relative?(path, prefix) when is_binary(path) do
    path != "" and not String.contains?(path, ["\0", "\\"]) and Path.type(path) == :relative and
      match?({:ok, _}, Path.safe_relative(path)) and
      (is_nil(prefix) or String.starts_with?(path, prefix))
  end

  defp safe_relative?(_path, _prefix), do: false

  defp authority_bearing?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} ->
      key in @forbidden_authority_fields or authority_bearing?(nested)
    end)
  end

  defp authority_bearing?(value) when is_list(value), do: Enum.any?(value, &authority_bearing?/1)
  defp authority_bearing?(_value), do: false

  defp add_unless(reasons, true, _reason), do: reasons
  defp add_unless(reasons, false, reason), do: [reason | reasons]

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

  defp renderer(provenance, pin) do
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

  defp read_renderer_pin(path \\ "priv/pdfium_pin.json") do
    with {:ok, contents} <- File.read(path),
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

defmodule Rendro.CatalogVisualGallery do
  @moduledoc false

  @candidate_root "tmp/phase130-candidate/"
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
  @review_roles [
    {"invoice_light_control", "invoice--cedar-mutual--corporate-classic--light", "control"},
    {"invoice_dark_target", "invoice--cedar-mutual--corporate-classic--dark", "target"},
    {"statement_light_control", "statement--signal-ledger--minimal-mono--light", "control"},
    {"statement_dark_target", "statement--signal-ledger--minimal-mono--dark", "target"},
    {"payslip_light_target", "payslip--northline-logistics--swiss--light", "target"},
    {"payslip_dark_target", "payslip--northline-logistics--swiss--dark", "target"},
    {"ticket_light_target", "ticket--aurora-live--brutalist--light", "target"},
    {"ticket_dark_target", "ticket--aurora-live--brutalist--dark", "target"}
  ]
  @role_names Enum.map(@review_roles, &elem(&1, 0))
  @review_ids Enum.map(@review_roles, &elem(&1, 1))
  @authority_statement "Navigation and review presentation only; no evidence, review, approval, disposition, or canonical authority."
  @receipt_complete_keys ~w(artifacts candidate control receipt_id renderer review_images roles run schema_version status validation)
  @receipt_unavailable_keys ~w(artifacts candidate control failure receipt_id renderer review_images revision_gate run schema_version status targets_unpromoted)
  @review_receipt_keys ~w(artifacts candidate_sha canonical control_sha failed_target_ids failure intake missing_fields missing_target_ids parent_receipt_id renderer review_receipt_id review_status reviews revision_gate run_attempt run_id schema_version)
  @score_fields ~w(content_hierarchy layout_balance typography color_contrast content_integrity visual_cohesion)
  @review_record_keys ~w(catalog_id packet_path png_sha256 print_safety rationale reading_order review_date reviewer scores source_pdf_sha256)
  @intake_keys ~w(control_checkout_sha download_nonce evidence packet receipt_id review_images schema_version validated_at validation)
  @canonical_paths [
    "assets/rendro/catalog.json",
    "assets/rendro/catalog/invoice/cedar-mutual/corporate-classic-dark.png",
    "assets/rendro/catalog/statement/signal-ledger/minimal-mono-dark.png",
    "assets/rendro/catalog/payslip/northline-logistics/swiss-light.png",
    "assets/rendro/catalog/payslip/northline-logistics/swiss-dark.png",
    "assets/rendro/catalog/ticket/aurora-live/brutalist-light.png",
    "assets/rendro/catalog/ticket/aurora-live/brutalist-dark.png"
  ]

  @spec build(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def build(candidate_path, final_path, output_dir)
      when is_binary(candidate_path) and is_binary(final_path) and is_binary(output_dir) do
    with false <- File.exists?(output_dir),
         {:ok, candidate} <- read_json(candidate_path),
         {:ok, final} <- read_json(final_path),
         {:ok, images} <- gallery_images(candidate, final),
         :ok <- File.mkdir_p(Path.join(output_dir, "images")),
         :ok <- copy_images(images, output_dir),
         :ok <-
           File.write(
             Path.join(output_dir, "manifest.json"),
             Jason.encode!(metadata(candidate, final, images), pretty: true) <> "\n"
           ),
         :ok <- File.write(Path.join(output_dir, "index.html"), html(candidate, images)) do
      {:ok, output_dir}
    else
      true -> {:error, :gallery_output_exists}
      {:error, _reason} -> {:error, :invalid_gallery_input}
      _ -> {:error, :invalid_gallery_input}
    end
  end

  def build(_candidate_path, _final_path, _output_dir), do: {:error, :invalid_gallery_input}

  @deprecated "Pass candidate and final identity manifests explicitly"
  def build(_manifest_path, _output_dir), do: {:error, :final_manifest_required}

  defp gallery_images(
         %{"candidate" => candidate, "cells" => cells, "diff" => diff},
         %{"images" => final_images} = final
       )
       when is_map(candidate) and is_list(cells) and is_map(diff) and is_list(final_images) do
    cells_by_id = Map.new(cells, &{&1["id"], &1})
    final_by_id = Map.new(final_images, &{&1["catalog_id"], &1})
    catalog_ids = Enum.map(Rendro.Catalog.catalog_specs(), & &1.id)

    with true <- diff["changed_targets"] == @target_ids,
         true <- (diff["changed_scored"] || []) ++ (diff["changed_unscored"] || []) == @target_ids,
         true <- diff["byte_stable"] == Enum.reject(catalog_ids, &(&1 in @target_ids)),
         true <- Enum.map(cells, & &1["id"]) == catalog_ids,
         true <- map_size(cells_by_id) == 32,
         true <- Enum.map(final_images, & &1["catalog_id"]) == @final_ids,
         true <- valid_final_identity?(candidate, final),
         true <- valid_final_images?(candidate, final, final_images, cells_by_id),
         images <-
           Enum.with_index(@review_roles, 1)
           |> Enum.map(fn {{role, id, kind}, ordinal} ->
             packet_image(
               role,
               id,
               kind,
               ordinal,
               cells_by_id[id],
               final_by_id[id],
               candidate,
               final
             )
           end),
         true <- Enum.all?(images, &valid_source_image?/1) do
      {:ok, images}
    else
      _ -> {:error, :invalid_gallery_manifest}
    end
  end

  defp gallery_images(_candidate, _final), do: {:error, :invalid_gallery_manifest}

  defp valid_source_image?(%{source_path: path, png_sha256: expected_sha}) do
    with true <- String.starts_with?(path, @candidate_root),
         true <- safe_relative?(path),
         {:ok, png} <- File.read(path) do
      sha256(png) == expected_sha
    else
      _ -> false
    end
  end

  defp valid_source_image?(_image), do: false

  defp valid_final_identity?(candidate, final) do
    final["candidate_sha"] == candidate["commit_sha"] and
      final["control_sha"] == candidate["baseline_commit_sha"] and
      final["run_id"] == candidate["run_id"] and
      final["run_attempt"] == candidate["run_attempt"] and
      get_in(final, ["renderer", "version"]) == get_in(candidate, ["renderer", "version"]) and
      get_in(final, ["renderer", "sha256"]) == get_in(candidate, ["renderer", "sha256"])
  end

  defp valid_final_images?(candidate, final, images, cells_by_id) do
    Enum.all?(images, fn image ->
      cell = cells_by_id[image["catalog_id"]]

      is_map(cell) and image["png_path"] == cell["png_path"] and
        image["png_sha256"] == cell["png_sha256"] and
        image["source_pdf_sha256"] == cell["source_pdf_sha256"] and
        image["mode"] == cell["mode"] and image["commit_sha"] == candidate["commit_sha"] and
        image["control_sha"] == candidate["baseline_commit_sha"] and
        image["run_id"] == candidate["run_id"] and
        image["run_attempt"] == candidate["run_attempt"] and
        image["renderer_version"] == final["renderer"]["version"] and
        image["renderer_sha256"] == final["renderer"]["sha256"]
    end)
  end

  defp packet_image(role, id, kind, ordinal, cell, image, candidate, final)
       when is_map(cell) and is_map(image) do
    if image["catalog_id"] == id and image["png_path"] == cell["png_path"] and
         image["png_sha256"] == cell["png_sha256"] and
         image["source_pdf_sha256"] == cell["source_pdf_sha256"] and
         image["mode"] == cell["mode"] and
         image["commit_sha"] == candidate["commit_sha"] and
         image["control_sha"] == candidate["baseline_commit_sha"] and
         image["run_id"] == candidate["run_id"] and
         image["run_attempt"] == candidate["run_attempt"] and
         image["renderer_version"] == final["renderer"]["version"] and
         image["renderer_sha256"] == final["renderer"]["sha256"] do
      %{
        review_role: role,
        ordinal: ordinal,
        catalog_id: id,
        kind: kind,
        path: "images/#{role}.png",
        source_path: image["png_path"],
        png_sha256: image["png_sha256"],
        source_pdf_sha256: image["source_pdf_sha256"],
        bundle_role: "final-review/final.json",
        bundle_path: image["png_path"]
      }
    end
  end

  defp packet_image(_role, _id, _kind, _ordinal, _cell, _image, _candidate, _final), do: nil

  defp copy_images(images, output_dir) do
    Enum.reduce_while(images, :ok, fn image, :ok ->
      destination = Path.join(output_dir, image.path)

      case File.cp(image.source_path, destination) do
        :ok -> {:cont, :ok}
        {:error, _reason} -> {:halt, {:error, :copy_failed}}
      end
    end)
  end

  defp metadata(%{"candidate" => candidate}, final, images) do
    %{
      "schema_version" => 1,
      "authority" => "none",
      "authority_statement" => @authority_statement,
      "candidate_sha" => candidate["commit_sha"],
      "control_sha" => candidate["baseline_commit_sha"],
      "run_id" => candidate["run_id"],
      "run_attempt" => candidate["run_attempt"],
      "renderer" => final["renderer"],
      "images" =>
        Enum.map(images, fn image ->
          image
          |> Map.drop([:source_path])
          |> Map.new(fn {key, value} -> {Atom.to_string(key), value} end)
        end)
    }
  end

  defp html(%{"candidate" => candidate}, images) do
    cards =
      Enum.map_join(images, "\n", fn image ->
        role = escape(image.review_role)
        id = escape(image.catalog_id)
        kind = escape(image.kind)

        """
        <article class="sheet" data-kind="#{kind}">
          <img src="images/#{role}.png" alt="#{id} rendered PDF page one" loading="eager">
          <div class="caption"><strong>#{role}</strong><span>#{id}</span><span>#{kind} · sha256: #{escape(image.png_sha256)}</span></div>
        </article>
        """
      end)

    """
    <!doctype html>
    <html lang="en">
    <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Rendro visual inspection</title>
    <style>
      :root { color-scheme: light dark; font-family: ui-monospace, Menlo, monospace; background: #111314; color: #ecede8; }
      body { margin: 0; padding: 2rem; background: radial-gradient(circle at top right, #254344, #111314 42rem); }
      header { max-width: 1200px; margin: 0 auto 2rem; border-left: 5px solid #e9b44c; padding: .2rem 1rem; }
      h1 { margin: 0; letter-spacing: -.08em; font-size: clamp(2rem, 6vw, 4.5rem); } p { max-width: 76ch; line-height: 1.55; }
      .sha { color: #e9b44c; overflow-wrap: anywhere; } .grid { max-width: 1200px; margin: auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.25rem; }
      .sheet { margin: 0; border: 1px solid #516366; background: #191d1f; box-shadow: 10px 10px 0 #0007; } img { display: block; width: 100%; height: auto; background: #fff; } .caption { padding: .8rem; display: grid; gap: .4rem; font-size: .72rem; overflow-wrap: anywhere; } .caption span { color: #b9c6c3; }
    </style></head>
    <body><header><p>RENDRO / SEALED REVIEW NAVIGATION</p><h1>Review packet / eight full-size surfaces</h1><p class="sha">candidate #{escape(candidate["commit_sha"])}</p><p>#{@authority_statement} Verify the separate closed Catalog Evidence bundle before relying on any provenance.</p></header><main class="grid">#{cards}</main></body></html>
    """
  end

  @spec validate(Path.t(), Path.t(), String.t()) :: :ok | {:error, [atom()]}
  def validate(packet_root, bundle_root, expected_control_sha)
      when is_binary(packet_root) and is_binary(bundle_root) and is_binary(expected_control_sha) do
    with {:ok, bundle} <-
           Rendro.CatalogEvidenceBundle.inspect_review(bundle_root, expected_control_sha),
         {:ok, manifest} <- read_json(Path.join(packet_root, "manifest.json")),
         :ok <- validate_manifest(manifest, bundle_facts(bundle)),
         :ok <- validate_packet_files(packet_root, manifest) do
      :ok
    else
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
    end
  end

  def validate(_packet_root, _bundle_root, _expected_control_sha),
    do: {:error, [:invalid_packet_input]}

  @spec validate_manifest(map(), map()) :: :ok | {:error, [atom()]}
  def validate_manifest(manifest, facts) when is_map(manifest) and is_map(facts) do
    images = manifest["images"]
    expected_roles = Enum.map(@review_roles, &elem(&1, 0))
    expected_ids = Enum.map(@review_roles, &elem(&1, 1))
    expected_kinds = Enum.map(@review_roles, &elem(&1, 2))
    fact_images = Map.new(facts.images || [], &{&1["catalog_id"], &1})

    valid =
      exact_keys?(
        manifest,
        ~w(authority authority_statement candidate_sha control_sha images renderer run_attempt run_id schema_version)
      ) and manifest["schema_version"] == 1 and manifest["authority"] == "none" and
        manifest["authority_statement"] == @authority_statement and
        manifest["candidate_sha"] == facts.candidate_sha and
        manifest["control_sha"] == facts.control_sha and manifest["run_id"] == facts.run_id and
        manifest["run_attempt"] == facts.run_attempt and manifest["renderer"] == facts.renderer and
        is_list(images) and Enum.map(images, & &1["review_role"]) == expected_roles and
        Enum.map(images, & &1["catalog_id"]) == expected_ids and
        Enum.map(images, & &1["kind"]) == expected_kinds and
        Enum.map(images, & &1["ordinal"]) == Enum.to_list(1..8) and
        Enum.uniq_by(images, & &1["path"]) == images and
        Enum.all?(images, &valid_packet_image?(&1, fact_images))

    if valid, do: :ok, else: {:error, [:invalid_packet_manifest]}
  rescue
    _ -> {:error, [:invalid_packet_manifest]}
  end

  def validate_manifest(_manifest, _facts), do: {:error, [:invalid_packet_manifest]}

  @spec validate_intake(map() | Path.t()) :: :ok | {:error, [atom()]}
  def validate_intake(input) do
    with {:ok, intake} <- normalize_document(input),
         true <- valid_intake_shape?(intake),
         true <- fresh_intake_paths?(intake),
         :ok <-
           Rendro.CatalogEvidenceBundle.validate(
             intake["evidence"]["bundle_root"],
             :review,
             intake["control_checkout_sha"]
           ),
         :ok <-
           validate(
             intake["packet"]["packet_root"],
             intake["evidence"]["bundle_root"],
             intake["control_checkout_sha"]
           ),
         {:ok, packet_manifest} <-
           read_json(Path.join(intake["packet"]["packet_root"], "manifest.json")),
         true <- intake["review_images"] == packet_manifest["images"] do
      :ok
    else
      false -> {:error, [:invalid_review_intake]}
      {:error, reasons} -> {:error, List.wrap(reasons)}
    end
  rescue
    _ -> {:error, [:invalid_review_intake]}
  end

  @spec validate_receipt(map() | Path.t()) :: :ok | {:error, [atom()]}
  def validate_receipt(input) do
    with {:ok, receipt} <- normalize_document(input) do
      case receipt["status"] do
        "complete" -> validate_complete_receipt(receipt)
        "unavailable" -> validate_unavailable_receipt(receipt)
        _ -> {:error, [:invalid_receipt_status]}
      end
    end
  rescue
    _ -> {:error, [:invalid_receipt]}
  end

  @spec require_complete_receipt(map() | Path.t()) :: :ok | {:error, [atom()]}
  def require_complete_receipt(input) do
    with {:ok, receipt} <- normalize_document(input),
         :ok <- validate_receipt(receipt),
         true <- receipt["status"] == "complete",
         :ok <- validate_fresh_receipt_artifacts(receipt) do
      :ok
    else
      false -> {:error, [:complete_receipt_required]}
      {:error, reasons} -> {:error, List.wrap(reasons)}
    end
  end

  @spec validate_review_receipt(map() | Path.t()) :: :ok | {:error, [atom()]}
  def validate_review_receipt(input) do
    with {:ok, receipt} <- normalize_document(input),
         true <- exact_keys?(receipt, @review_receipt_keys),
         true <- valid_review_identity?(receipt),
         true <- valid_review_status?(receipt) do
      :ok
    else
      _ -> {:error, [:invalid_review_receipt]}
    end
  rescue
    _ -> {:error, [:invalid_review_receipt]}
  end

  @spec require_qualified_review_receipt(map() | Path.t()) :: :ok | {:error, [atom()]}
  def require_qualified_review_receipt(input) do
    with {:ok, receipt} <- normalize_document(input),
         :ok <- validate_review_receipt(receipt),
         true <- receipt["review_status"] == "qualified",
         true <- Enum.all?(receipt["reviews"], &qualifies?/1),
         :ok <- require_fresh_parent_if_path(input, receipt) do
      :ok
    else
      false -> {:error, [:qualified_review_receipt_required]}
      {:error, reasons} -> {:error, List.wrap(reasons)}
    end
  end

  defp bundle_facts(bundle) do
    final = bundle.final

    %{
      candidate_sha: final["candidate_sha"],
      control_sha: final["control_sha"],
      run_id: final["run_id"],
      run_attempt: final["run_attempt"],
      renderer: final["renderer"],
      images: final["images"]
    }
  end

  defp valid_packet_image?(image, fact_images) when is_map(image) do
    fact = fact_images[image["catalog_id"]]

    exact_keys?(
      image,
      ~w(bundle_path bundle_role catalog_id kind ordinal path png_sha256 review_role source_pdf_sha256)
    ) and image["review_role"] in @role_names and image["catalog_id"] in @review_ids and
      image["kind"] in ["control", "target"] and image["bundle_role"] == "final-review/final.json" and
      safe_relative?(image["path"], "images/") and
      safe_relative?(image["bundle_path"], @candidate_root) and
      sha256?(image["png_sha256"]) and sha256?(image["source_pdf_sha256"]) and is_map(fact) and
      image["bundle_path"] == fact["png_path"] and image["png_sha256"] == fact["png_sha256"] and
      image["source_pdf_sha256"] == fact["source_pdf_sha256"]
  end

  defp valid_packet_image?(_image, _facts), do: false

  defp validate_packet_files(packet_root, manifest) do
    expected = ["index.html", "manifest.json" | Enum.map(manifest["images"], & &1["path"])]

    actual =
      packet_root
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&Path.relative_to(&1, packet_root))

    valid =
      Enum.sort(actual) == Enum.sort(expected) and
        Enum.all?(manifest["images"], fn image ->
          path = Path.join(packet_root, image["path"])
          File.regular?(path) and sha256_file(path) == image["png_sha256"]
        end)

    if valid, do: :ok, else: {:error, [:packet_file_mismatch]}
  end

  defp validate_complete_receipt(receipt) do
    valid =
      exact_keys?(receipt, @receipt_complete_keys) and receipt["schema_version"] == 1 and
        concrete?(receipt["receipt_id"]) and full_sha?(get_in(receipt, ["candidate", "sha"]), 40) and
        exact_keys?(receipt["candidate"], ~w(sha)) and
        exact_keys?(receipt["control"], ~w(ref sha)) and
        concrete?(get_in(receipt, ["control", "ref"])) and
        full_sha?(get_in(receipt, ["control", "sha"]), 40) and
        valid_run?(receipt["run"]) and valid_renderer?(receipt["renderer"]) and
        valid_artifact_pair?(receipt["artifacts"]) and valid_roles?(receipt["roles"]) and
        valid_receipt_images?(receipt["review_images"]) and
        valid_validation_shape?(receipt["validation"]) and
        receipt["validation"]["control_checkout_sha"] == receipt["control"]["sha"]

    if valid, do: :ok, else: {:error, [:invalid_complete_receipt]}
  end

  defp validate_unavailable_receipt(receipt) do
    valid =
      exact_keys?(receipt, @receipt_unavailable_keys) and receipt["schema_version"] == 1 and
        concrete?(receipt["receipt_id"]) and full_sha?(get_in(receipt, ["candidate", "sha"]), 40) and
        exact_keys?(receipt["control"], ~w(ref sha)) and
        full_sha?(get_in(receipt, ["control", "sha"]), 40) and
        nullable_valid?(receipt["run"], &valid_run?/1) and
        nullable_valid?(receipt["renderer"], &valid_renderer?/1) and
        nullable_valid?(receipt["artifacts"], &valid_artifact_pair?/1) and
        valid_failure?(receipt["failure"]) and receipt["targets_unpromoted"] == @target_ids and
        receipt["review_images"] == [] and valid_revision_gate?(receipt["revision_gate"], false)

    if valid, do: :ok, else: {:error, [:invalid_unavailable_receipt]}
  end

  defp valid_review_identity?(receipt) do
    receipt["schema_version"] == 1 and concrete?(receipt["review_receipt_id"]) and
      concrete?(receipt["parent_receipt_id"]) and full_sha?(receipt["candidate_sha"], 40) and
      full_sha?(receipt["control_sha"], 40) and concrete?(receipt["run_id"]) and
      is_integer(receipt["run_attempt"]) and receipt["run_attempt"] > 0 and
      exact_keys?(receipt["renderer"], ~w(sha256 version)) and
      full_sha?(receipt["renderer"]["sha256"], 64) and valid_artifact_pair?(receipt["artifacts"]) and
      valid_review_intake?(receipt["intake"]) and valid_canonical_hashes?(receipt["canonical"]) and
      valid_revision_gate?(receipt["revision_gate"], receipt["review_status"] == "qualified")
  end

  defp valid_review_status?(%{"review_status" => "qualified"} = receipt) do
    exact_review_ids?(receipt["reviews"]) and
      Enum.all?(receipt["reviews"], &valid_review_record?/1) and
      Enum.all?(receipt["reviews"], &qualifies?/1) and receipt["failed_target_ids"] == [] and
      receipt["missing_target_ids"] == [] and receipt["missing_fields"] == %{} and
      is_nil(receipt["failure"])
  end

  defp valid_review_status?(%{"review_status" => "missed"} = receipt) do
    exact_review_ids?(receipt["reviews"]) and
      Enum.all?(receipt["reviews"], &valid_review_record?/1) and
      receipt["failed_target_ids"] ==
        Enum.filter(@target_ids, fn id ->
          receipt["reviews"]
          |> Enum.find(&(&1["catalog_id"] == id))
          |> qualifies?()
          |> Kernel.not()
        end) and receipt["failed_target_ids"] != [] and receipt["missing_target_ids"] == [] and
      receipt["missing_fields"] == %{} and is_nil(receipt["failure"])
  end

  defp valid_review_status?(%{"review_status" => "incomplete"} = receipt) do
    missing_fields = computed_missing_fields(receipt["reviews"])
    missing_ids = Enum.filter(@target_ids, &Map.has_key?(missing_fields, &1))
    complete = Enum.filter(receipt["reviews"], &valid_review_record?/1)

    failed =
      Enum.filter(@target_ids, fn id ->
        record = Enum.find(complete, &(&1["catalog_id"] == id))
        is_map(record) and not qualifies?(record)
      end)

    canonical_subset?(Enum.map(receipt["reviews"], & &1["catalog_id"])) and
      receipt["missing_target_ids"] == missing_ids and missing_ids != [] and
      receipt["missing_fields"] == missing_fields and receipt["failed_target_ids"] == failed and
      is_nil(receipt["failure"])
  end

  defp valid_review_status?(%{"review_status" => "unavailable"} = receipt) do
    receipt["reviews"] == [] and receipt["failed_target_ids"] == [] and
      receipt["missing_target_ids"] == @target_ids and receipt["missing_fields"] == %{} and
      valid_failure?(receipt["failure"])
  end

  defp valid_review_status?(_receipt), do: false

  defp valid_review_record?(record) do
    exact_keys?(
      record,
      @review_record_keys
    ) and record["catalog_id"] in @target_ids and exact_keys?(record["scores"], @score_fields) and
      Enum.all?(record["scores"], fn {_name, score} -> is_integer(score) and score in 1..5 end) and
      is_boolean(record["reading_order"]) and is_boolean(record["print_safety"]) and
      concrete?(record["rationale"]) and concrete?(record["reviewer"]) and
      Regex.match?(~r/\A\d{4}-\d{2}-\d{2}\z/, record["review_date"] || "") and
      record["packet_path"] == packet_path_for(record["catalog_id"]) and
      safe_relative?(record["packet_path"], "images/") and full_sha?(record["png_sha256"], 64) and
      full_sha?(record["source_pdf_sha256"], 64)
  end

  defp qualifies?(record) when is_map(record) do
    scores = record["scores"] || %{}

    scores["content_hierarchy"] == 5 and record["reading_order"] == true and
      Enum.all?(Map.drop(scores, ["content_hierarchy"]), fn {_name, score} -> score >= 4 end)
  end

  defp qualifies?(_record), do: false

  defp exact_review_ids?(reviews), do: Enum.map(reviews, & &1["catalog_id"]) == @target_ids

  defp canonical_subset?(ids),
    do: ids == Enum.filter(@target_ids, &(&1 in ids)) and length(ids) == length(Enum.uniq(ids))

  defp computed_missing_fields(reviews) do
    Map.new(@target_ids, fn id ->
      case Enum.find(reviews, &(&1["catalog_id"] == id)) do
        nil -> {id, @review_record_keys}
        record -> {id, @review_record_keys -- Map.keys(record)}
      end
    end)
    |> Map.reject(fn {_id, fields} -> fields == [] end)
  end

  defp packet_path_for(id) do
    case Enum.find(@review_roles, &(elem(&1, 1) == id)) do
      {role, _id, _kind} -> "images/#{role}.png"
      nil -> nil
    end
  end

  defp require_fresh_parent_if_path(path, receipt) when is_binary(path) do
    parent_path = Path.join(Path.dirname(path), "136-12-RECEIPT.json")

    with {:ok, parent} <- normalize_document(parent_path),
         true <- parent["receipt_id"] == receipt["parent_receipt_id"],
         :ok <- require_complete_receipt(parent),
         true <- review_matches_parent?(receipt, parent),
         :ok <- require_fresh_intake(path, receipt) do
      :ok
    else
      false -> {:error, [:parent_receipt_mismatch]}
      {:error, reasons} -> {:error, List.wrap(reasons)}
    end
  end

  defp require_fresh_parent_if_path(_map, _receipt), do: :ok

  defp validate_fresh_receipt_artifacts(receipt) do
    validation = receipt["validation"]
    evidence = receipt["artifacts"]["evidence"]
    packet = receipt["artifacts"]["reviewer_packet"]

    valid =
      validation["download_nonce"] != "stale" and
        validation["control_checkout_sha"] == receipt["control"]["sha"] and
        File.regular?(validation["evidence_archive_path"]) and
        File.regular?(validation["packet_archive_path"]) and
        File.dir?(validation["evidence_bundle_root"]) and File.dir?(validation["packet_root"]) and
        sha256_file(validation["evidence_archive_path"]) == evidence["archive_sha256"] and
        sha256_file(validation["packet_archive_path"]) == packet["archive_sha256"]

    if valid do
      with :ok <-
             Rendro.CatalogEvidenceBundle.validate(
               validation["evidence_bundle_root"],
               :review,
               receipt["control"]["sha"]
             ),
           {:ok, bundle} <-
             Rendro.CatalogEvidenceBundle.inspect_review(
               validation["evidence_bundle_root"],
               receipt["control"]["sha"]
             ),
           {:ok, bundle_manifest} <-
             read_json(Path.join(validation["evidence_bundle_root"], "manifest.json")),
           {:ok, packet_manifest} <-
             read_json(Path.join(validation["packet_root"], "manifest.json")),
           :ok <-
             validate(
               validation["packet_root"],
               validation["evidence_bundle_root"],
               receipt["control"]["sha"]
             ),
           true <- fresh_receipt_matches?(receipt, bundle, bundle_manifest, packet_manifest) do
        :ok
      else
        false -> {:error, [:fresh_receipt_identity_mismatch]}
        {:error, reasons} -> {:error, List.wrap(reasons)}
      end
    else
      {:error, [:stale_receipt_artifacts]}
    end
  end

  defp fresh_receipt_matches?(receipt, bundle, bundle_manifest, packet_manifest) do
    final = bundle.final

    receipt["candidate"]["sha"] == final["candidate_sha"] and
      receipt["control"]["sha"] == final["control_sha"] and
      receipt["run"]["id"] == final["run_id"] and
      receipt["run"]["attempt"] == final["run_attempt"] and
      receipt["renderer"]["version"] == final["renderer"]["version"] and
      receipt["renderer"]["binary_sha256"] == final["renderer"]["sha256"] and
      receipt["renderer"]["dpi"] == bundle_manifest["renderer"]["dpi"] and
      receipt["roles"] ==
        Enum.map(bundle_manifest["payloads"], &Map.take(&1, ~w(count path role sha256))) and
      receipt["review_images"] == packet_manifest["images"]
  end

  defp review_matches_parent?(review, parent) do
    parent_images = Map.new(parent["review_images"], &{&1["catalog_id"], &1})

    review["candidate_sha"] == parent["candidate"]["sha"] and
      review["control_sha"] == parent["control"]["sha"] and
      review["run_id"] == parent["run"]["id"] and
      review["run_attempt"] == parent["run"]["attempt"] and
      review["renderer"] == %{
        "version" => parent["renderer"]["version"],
        "sha256" => parent["renderer"]["binary_sha256"]
      } and review["artifacts"] == parent["artifacts"] and
      review["intake"]["review_images"] == parent["review_images"] and
      Enum.all?(review["reviews"], fn record ->
        image = parent_images[record["catalog_id"]]

        is_map(image) and record["packet_path"] == image["path"] and
          record["png_sha256"] == image["png_sha256"] and
          record["source_pdf_sha256"] == image["source_pdf_sha256"]
      end)
  end

  defp require_fresh_intake(review_path, receipt) do
    sibling_path = Path.join(Path.dirname(review_path), "phase136-review-intake.json")

    intake_path =
      if File.regular?(sibling_path), do: sibling_path, else: "tmp/phase136-review-intake.json"

    with :ok <- validate_intake(intake_path),
         {:ok, intake} <- normalize_document(intake_path),
         true <- intake["receipt_id"] == receipt["parent_receipt_id"],
         true <- intake["download_nonce"] == receipt["intake"]["download_nonce"],
         true <- intake["validated_at"] == receipt["intake"]["validated_at"],
         true <- intake["review_images"] == receipt["intake"]["review_images"],
         true <- intake_matches_artifacts?(intake, receipt["artifacts"]) do
      :ok
    else
      false -> {:error, [:review_intake_mismatch]}
      {:error, reasons} -> {:error, List.wrap(reasons)}
    end
  end

  defp intake_matches_artifacts?(intake, artifacts) do
    intake["evidence"]["artifact_id"] == artifacts["evidence"]["id"] and
      intake["evidence"]["archive_sha256"] == artifacts["evidence"]["archive_sha256"] and
      intake["packet"]["artifact_id"] == artifacts["reviewer_packet"]["id"] and
      intake["packet"]["archive_sha256"] == artifacts["reviewer_packet"]["archive_sha256"]
  end

  defp valid_run?(run),
    do:
      exact_keys?(run, ~w(attempt id)) and concrete?(run["id"]) and is_integer(run["attempt"]) and
        run["attempt"] > 0

  defp valid_renderer?(renderer),
    do:
      exact_keys?(renderer, ~w(binary_sha256 dpi version)) and concrete?(renderer["version"]) and
        full_sha?(renderer["binary_sha256"], 64) and is_integer(renderer["dpi"]) and
        renderer["dpi"] > 0

  defp valid_artifact_pair?(%{"evidence" => evidence, "reviewer_packet" => packet} = pair) do
    exact_keys?(pair, ~w(evidence reviewer_packet)) and valid_artifact?(evidence) and
      valid_artifact?(packet) and evidence["id"] != packet["id"] and
      evidence["name"] != packet["name"] and
      evidence["url"] != packet["url"]
  end

  defp valid_artifact_pair?(_pair), do: false

  defp valid_artifact?(artifact) do
    exact_keys?(artifact, ~w(archive_sha256 id name provider_digest url)) and
      concrete?(artifact["id"]) and concrete?(artifact["name"]) and
      String.starts_with?(artifact["url"] || "", "https://") and
      artifact["provider_digest"] == "sha256:" <> artifact["archive_sha256"] and
      full_sha?(artifact["archive_sha256"], 64)
  end

  defp valid_roles?(roles) when is_list(roles) do
    expected = [
      {"candidate/catalog.json", 32},
      {"final-review/final.json", 12},
      {"multipage-review/multipage.json", 4},
      {"preset-review/preset.json", 12}
    ]

    Enum.map(roles, &{&1["role"], &1["count"]}) == expected and
      Enum.all?(roles, fn role ->
        exact_keys?(role, ~w(count path role sha256)) and role["path"] == role["role"] and
          safe_relative?(role["path"]) and full_sha?(role["sha256"], 64)
      end)
  end

  defp valid_roles?(_roles), do: false

  defp valid_receipt_images?(images) when is_list(images) do
    length(images) == 8 and Enum.map(images, & &1["review_role"]) == @role_names and
      Enum.map(images, & &1["catalog_id"]) == @review_ids and
      Enum.map(images, & &1["kind"]) == Enum.map(@review_roles, &elem(&1, 2)) and
      Enum.map(images, & &1["ordinal"]) == Enum.to_list(1..8) and
      Enum.uniq_by(images, & &1["path"]) == images and
      Enum.all?(images, fn image ->
        exact_keys?(
          image,
          ~w(bundle_path bundle_role catalog_id kind ordinal path png_sha256 review_role source_pdf_sha256)
        ) and image["bundle_role"] == "final-review/final.json" and
          safe_relative?(image["path"], "images/") and
          safe_relative?(image["bundle_path"], @candidate_root) and
          full_sha?(image["png_sha256"], 64) and
          full_sha?(image["source_pdf_sha256"], 64)
      end)
  end

  defp valid_receipt_images?(_images), do: false

  defp valid_validation_shape?(validation) do
    exact_keys?(
      validation,
      ~w(closed_bundle_result control_checkout_sha download_nonce evidence_archive_path evidence_bundle_root packet_archive_path packet_binding_result packet_root validated_at)
    ) and full_sha?(validation["control_checkout_sha"], 40) and
      validation["closed_bundle_result"] == "ok" and validation["packet_binding_result"] == "ok" and
      concrete?(validation["download_nonce"]) and concrete?(validation["validated_at"]) and
      Enum.all?(
        ~w(evidence_archive_path evidence_bundle_root packet_archive_path packet_root),
        &concrete?(validation[&1])
      )
  end

  defp valid_intake_shape?(intake) do
    exact_keys?(intake, @intake_keys) and intake["schema_version"] == 1 and
      concrete?(intake["receipt_id"]) and concrete?(intake["download_nonce"]) and
      concrete?(intake["validated_at"]) and full_sha?(intake["control_checkout_sha"], 40) and
      exact_keys?(intake["evidence"], ~w(archive_path archive_sha256 artifact_id bundle_root)) and
      exact_keys?(intake["packet"], ~w(archive_path archive_sha256 artifact_id packet_root)) and
      Enum.all?([intake["evidence"], intake["packet"]], fn artifact ->
        concrete?(artifact["artifact_id"]) and concrete?(artifact["archive_path"]) and
          full_sha?(artifact["archive_sha256"], 64)
      end) and concrete?(intake["evidence"]["bundle_root"]) and
      concrete?(intake["packet"]["packet_root"]) and
      exact_keys?(intake["validation"], ~w(closed_bundle_result packet_binding_result)) and
      intake["validation"] == %{
        "closed_bundle_result" => "ok",
        "packet_binding_result" => "ok"
      } and valid_receipt_images?(intake["review_images"])
  end

  defp valid_review_intake?(intake) do
    exact_keys?(intake, ~w(download_nonce review_images validated_at)) and
      concrete?(intake["download_nonce"]) and concrete?(intake["validated_at"]) and
      valid_receipt_images?(intake["review_images"])
  end

  defp valid_canonical_hashes?(canonical) do
    exact_keys?(canonical, ~w(after before)) and canonical["before"] == canonical["after"] and
      Enum.sort(Map.keys(canonical["before"] || %{})) == Enum.sort(@canonical_paths) and
      Enum.all?(canonical["before"] || %{}, fn {_path, digest} -> full_sha?(digest, 64) end)
  end

  defp fresh_intake_paths?(intake) do
    evidence = intake["evidence"]
    packet = intake["packet"]

    File.regular?(evidence["archive_path"]) and File.regular?(packet["archive_path"]) and
      File.dir?(evidence["bundle_root"]) and File.dir?(packet["packet_root"]) and
      sha256_file(evidence["archive_path"]) == evidence["archive_sha256"] and
      sha256_file(packet["archive_path"]) == packet["archive_sha256"]
  end

  defp valid_failure?(failure) do
    exact_keys?(failure, ~w(code expected message next_action observed stage)) and
      Enum.all?(~w(code message next_action stage), &concrete?(failure[&1])) and
      is_map(failure["expected"]) and is_map(failure["observed"])
  end

  defp valid_revision_gate?(gate, qualified?) do
    exact_keys?(gate, ~w(cap iteration prior_receipt_ids status)) and
      is_integer(gate["iteration"]) and
      gate["iteration"] > 0 and gate["cap"] == 3 and is_list(gate["prior_receipt_ids"]) and
      gate["status"] in if(qualified?,
        do: ["not_required"],
        else: ["retry_required", "escalated"]
      )
  end

  defp normalize_document(input) when is_map(input), do: {:ok, input}
  defp normalize_document(path) when is_binary(path), do: read_json(path)
  defp normalize_document(_input), do: {:error, [:invalid_document]}

  defp read_json(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, decoded} when is_map(decoded) <- Jason.decode(contents) do
      {:ok, decoded}
    else
      _ -> {:error, [:invalid_json]}
    end
  end

  defp exact_keys?(map, keys) when is_map(map), do: Enum.sort(Map.keys(map)) == Enum.sort(keys)
  defp exact_keys?(_map, _keys), do: false
  defp nullable_valid?(nil, _validator), do: true
  defp nullable_valid?(value, validator), do: validator.(value)
  defp concrete?(value), do: is_binary(value) and String.trim(value) != ""

  defp full_sha?(value, length),
    do: is_binary(value) and byte_size(value) == length and Regex.match?(~r/\A[0-9a-f]+\z/, value)

  defp sha256?(value), do: full_sha?(value, 64)

  defp safe_relative?(path, prefix \\ nil) do
    is_binary(path) and path != "" and not String.contains?(path, ["\0", "\\"]) and
      Path.type(path) == :relative and match?({:ok, _}, Path.safe_relative(path)) and
      (is_nil(prefix) or String.starts_with?(path, prefix))
  end

  defp sha256_file(path), do: path |> File.read!() |> sha256()

  defp escape(value),
    do:
      value
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace("\"", "&quot;")

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
end

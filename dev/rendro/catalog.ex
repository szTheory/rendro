defmodule Rendro.Catalog do
  @moduledoc false

  @asset_root "assets/rendro/catalog"
  @manifest_path "assets/rendro/catalog.json"
  @pdfium_pin_path "priv/pdfium_pin.json"
  @dpi 96
  @schema_version 1
  @renderer_kind "pdfium-render"
  @generated_by "mix rendro.catalog.gen"
  @candidate_generated_by "mix rendro.catalog.candidate"
  @canonical_staging_root "assets/rendro/catalog.staging"
  @canonical_manifest_staging_path "assets/rendro/catalog.json.staging"
  @candidate_root "tmp/phase130-candidate"
  @candidate_staging_root "tmp/phase130-candidate.staging"
  @candidate_multipage_ids [
    "invoice-line-items-60-plus-page-first",
    "invoice-line-items-60-plus-page-final",
    "statement-line-items-60-plus-page-first",
    "statement-line-items-60-plus-page-final"
  ]
  @dark_boundary_disclosure "Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim."
  # This list is intentionally literal and ordered. It is the only membership
  # source; fixture discovery may validate a row but must never add one.
  @catalog_specs [
    {:invoice, "default", "default", "light", "invoice/acme-phoenix-saas/invoice.json", nil, nil},
    {:invoice, "northline-logistics", "swiss", "light",
     "invoice/northline-logistics/invoice.json", "#2C6BED", :swiss},
    {:invoice, "northline-logistics", "swiss", "dark", "invoice/northline-logistics/invoice.json",
     "#2C6BED", :swiss},
    {:invoice, "cedar-mutual", "corporate-classic", "light", "invoice/cedar-mutual/invoice.json",
     "#1F4FB8", :corporate_classic},
    {:invoice, "cedar-mutual", "corporate-classic", "dark", "invoice/cedar-mutual/invoice.json",
     "#1F4FB8", :corporate_classic},
    {:statement, "default", "default", "light", "statement/northwind-ledger-co/statement.json",
     nil, nil},
    {:statement, "signal-ledger", "minimal-mono", "light",
     "statement/signal-ledger/statement.json", "#0E7C76", :minimal_mono},
    {:statement, "signal-ledger", "minimal-mono", "dark",
     "statement/signal-ledger/statement.json", "#0E7C76", :minimal_mono},
    {:statement, "aster-research-fund", "editorial", "light",
     "statement/aster-research-fund/statement.json", "#6E3CB8", :editorial},
    {:statement, "aster-research-fund", "editorial", "dark",
     "statement/aster-research-fund/statement.json", "#6E3CB8", :editorial},
    {:receipt, "default", "default", "light", "receipt/harbor-and-oak-cafe/receipt.json", nil,
     nil},
    {:receipt, "poppy-and-grain", "humanist", "light", "receipt/poppy-and-grain/receipt.json",
     "#147A4B", :humanist},
    {:receipt, "poppy-and-grain", "humanist", "dark", "receipt/poppy-and-grain/receipt.json",
     "#147A4B", :humanist},
    {:receipt, "circuit-supply-co", "minimal-mono", "light",
     "receipt/circuit-supply-co/receipt.json", "#2C6BED", :minimal_mono},
    {:receipt, "circuit-supply-co", "minimal-mono", "dark",
     "receipt/circuit-supply-co/receipt.json", "#2C6BED", :minimal_mono},
    {:certificate, "default", "default", "light",
     "certificate/summit-training-institute/certificate.json", nil, nil},
    {:certificate, "aster-institute", "swiss", "light",
     "certificate/aster-institute/certificate.json", "#1F4FB8", :swiss},
    {:certificate, "aster-institute", "swiss", "dark",
     "certificate/aster-institute/certificate.json", "#1F4FB8", :swiss},
    {:certificate, "meridian-arts-fellowship", "editorial", "light",
     "certificate/meridian-arts-fellowship/certificate.json", "#6E3CB8", :editorial},
    {:certificate, "meridian-arts-fellowship", "editorial", "dark",
     "certificate/meridian-arts-fellowship/certificate.json", "#6E3CB8", :editorial},
    {:payslip, "default", "default", "light", "payslip/aurora-live/payslip.json", nil, nil},
    {:payslip, "northline-logistics", "swiss", "light",
     "payslip/northline-logistics/payslip.json", "#2C6BED", :swiss},
    {:payslip, "northline-logistics", "swiss", "dark", "payslip/northline-logistics/payslip.json",
     "#2C6BED", :swiss},
    {:payslip, "cedar-mutual", "corporate-classic", "light", "payslip/cedar-mutual/payslip.json",
     "#1F4FB8", :corporate_classic},
    {:payslip, "cedar-mutual", "corporate-classic", "dark", "payslip/cedar-mutual/payslip.json",
     "#1F4FB8", :corporate_classic},
    {:ticket, "default", "default", "light", "ticket/aurora-live/ticket.json", nil, nil},
    {:ticket, "field-notes-conference", "minimal-mono", "light",
     "ticket/field-notes-conference/ticket.json", "#0E7C76", :minimal_mono},
    {:ticket, "field-notes-conference", "minimal-mono", "dark",
     "ticket/field-notes-conference/ticket.json", "#0E7C76", :minimal_mono},
    {:ticket, "the-letterpress-hall", "editorial", "light",
     "ticket/the-letterpress-hall/ticket.json", "#C24132", :editorial},
    {:ticket, "the-letterpress-hall", "editorial", "dark",
     "ticket/the-letterpress-hall/ticket.json", "#C24132", :editorial},
    {:ticket, "aurora-live", "brutalist", "light", "ticket/aurora-live/ticket.json", "#C78600",
     :brutalist},
    {:ticket, "aurora-live", "brutalist", "dark", "ticket/aurora-live/ticket.json", "#C78600",
     :brutalist}
  ]

  # The catalog owns the exact, ordered visual-change allowlist. Recipes only
  # receive these generic private presentation values, never catalog identity.
  @visual_target_profiles %{
    "invoice--cedar-mutual--corporate-classic--dark" => %{semantic_ink: :primary_secondary},
    "statement--signal-ledger--minimal-mono--dark" => %{semantic_ink: :primary_secondary},
    "payslip--northline-logistics--swiss--light" => %{ledger_layout: :sequential_measured},
    "payslip--northline-logistics--swiss--dark" => %{ledger_layout: :sequential_measured},
    "ticket--aurora-live--brutalist--light" => %{locator_layout: :atomic_equal_share},
    "ticket--aurora-live--brutalist--dark" => %{locator_layout: :atomic_equal_share}
  }

  @spec asset_root() :: String.t()
  def asset_root, do: @asset_root

  @spec manifest_path() :: String.t()
  def manifest_path, do: @manifest_path

  @spec catalog_specs() :: [map()]
  def catalog_specs do
    Enum.map(@catalog_specs, fn {family, brand, preset, mode, fixture_ref, accent, preset_atom} ->
      id = Enum.join([family, brand, preset, mode], "--")

      %{
        id: id,
        family: family,
        brand: if(brand == "default", do: nil, else: brand),
        preset: if(preset == "default", do: nil, else: preset),
        theme: if(preset_atom, do: "preset", else: "default"),
        accent: accent,
        mode: mode,
        recipe_module: recipe_module(family),
        fixture_ref: fixture_ref,
        png_path:
          Path.join([@asset_root, Atom.to_string(family), brand, "#{preset}-#{mode}.png"]),
        alt: "#{String.capitalize(Atom.to_string(family))} #{brand} #{mode} catalog preview.",
        caption:
          "#{String.capitalize(Atom.to_string(family))} #{brand} #{preset} #{mode} catalog cell.",
        preset_atom: preset_atom
      }
    end)
  end

  @spec source_document_for(map()) :: Rendro.Document.t()
  def source_document_for(spec) when is_map(spec) do
    fixture_ref = Map.fetch!(spec, :fixture_ref)
    validate_safe_path!(fixture_ref, "fixture")

    if Map.has_key?(spec, :png_path),
      do: validate_safe_path!(Map.fetch!(spec, :png_path), "asset")

    family = Map.fetch!(spec, :family)

    data =
      fixture_ref |> Rendro.Examples.load!() |> then(&Rendro.ExamplesData.transform(family, &1))

    theme = theme_for(spec)
    opts = recipe_options(spec, theme)
    doc = Map.fetch!(spec, :recipe_module).document(data, opts)

    if preset = Map.get(spec, :preset_atom),
      do: Rendro.Theme.Presets.register_fonts(doc, preset),
      else: doc
  end

  defp recipe_options(spec, theme) do
    [theme: theme, catalog_layout: true]
    |> maybe_put_presentation_profile(presentation_profile(spec))
  end

  defp presentation_profile(spec) do
    Map.get(@visual_target_profiles, spec.id)
  end

  defp maybe_put_presentation_profile(opts, nil), do: opts

  defp maybe_put_presentation_profile(opts, profile),
    do: Keyword.put(opts, :presentation_profile, profile)

  @spec render_source_pdf(map()) :: {:ok, binary()} | {:error, term()}
  def render_source_pdf(spec) do
    spec
    |> source_document_for()
    |> Rendro.render(deterministic: true)
  end

  @spec page_count(binary()) :: non_neg_integer()
  def page_count(pdf) when is_binary(pdf), do: Regex.scan(~r{/Type\s*/Page\b}, pdf) |> length()

  @spec generate(keyword()) :: :ok | {:error, term()}
  def generate(opts \\ []) do
    with_pdfium(opts, fn ->
      cleanup_canonical_staging()

      result =
        with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
             {:ok, source_commit_sha} <- current_commit_sha(),
             :ok <- File.mkdir_p(@canonical_staging_root),
             {:ok, cells} <-
               build_cells(renderer_version, @canonical_staging_root, @asset_root),
             {:ok, cells} <- apply_quality_projections(cells, read_rubric_scores()),
             :ok <-
               File.write(
                 @canonical_manifest_staging_path,
                 encode_manifest(canonical_manifest(cells, renderer_version, source_commit_sha)) <>
                   "\n"
               ),
             :ok <- publish_canonical_staging() do
          :ok
        end

      case result do
        :ok ->
          :ok

        {:error, _reason} = error ->
          cleanup_canonical_staging()
          error
      end
    end)
  end

  @doc false
  @spec generate_candidate(keyword()) :: :ok | {:error, term()}
  def generate_candidate(opts \\ []) do
    with_pdfium(opts, fn ->
      cleanup_candidate()

      result =
        with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
             :ok <- File.mkdir_p(@candidate_staging_root),
             baseline <- read_manifest!(),
             :ok <- valid_candidate_baseline(baseline),
             {:ok, baseline_commit_sha} <- baseline_commit_sha(),
             {:ok, cells} <-
               build_cells(renderer_version, @candidate_staging_root, @candidate_root),
             :ok <- validate_candidate_staging(cells),
             {:ok, multipage} <- build_multipage_proofs(),
             {:ok, manifest} <-
               candidate_manifest(
                 cells,
                 baseline,
                 read_rubric_scores(),
                 renderer_version,
                 current_commit_sha!(),
                 multipage,
                 baseline_commit_sha
               ),
             :ok <-
               File.write(
                 Path.join(@candidate_staging_root, "candidate-manifest.json"),
                 encode_manifest(manifest) <> "\n"
               ),
             :ok <- File.rename(@candidate_staging_root, @candidate_root) do
          :ok
        end

      case result do
        :ok ->
          :ok

        {:error, _reason} = error ->
          cleanup_candidate()
          error
      end
    end)
  end

  @doc false
  @spec candidate_manifest([map()], map(), map(), String.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  def candidate_manifest(cells, baseline, rubric, renderer_version, commit_sha)
      when is_list(cells) and is_map(baseline) and is_map(rubric) and is_binary(renderer_version) and
             is_binary(commit_sha) do
    candidate_manifest(cells, baseline, rubric, renderer_version, commit_sha, [])
  end

  def candidate_manifest(_cells, _baseline, _rubric, _renderer_version, _commit_sha),
    do: {:error, :invalid_candidate_manifest_input}

  @doc false
  def candidate_manifest(cells, baseline, rubric, renderer_version, commit_sha, multipage)
      when is_list(cells) and is_map(baseline) and is_map(rubric) and is_binary(renderer_version) and
             is_binary(commit_sha) and is_list(multipage) do
    with {:ok, baseline_commit_sha} <- baseline_commit_sha() do
      candidate_manifest(
        cells,
        baseline,
        rubric,
        renderer_version,
        commit_sha,
        multipage,
        baseline_commit_sha
      )
    end
  end

  def candidate_manifest(_cells, _baseline, _rubric, _renderer_version, _commit_sha, _multipage),
    do: {:error, :invalid_candidate_manifest_input}

  @doc false
  def candidate_manifest(
        cells,
        baseline,
        rubric,
        renderer_version,
        commit_sha,
        multipage,
        baseline_commit_sha
      )
      when is_list(cells) and is_map(baseline) and is_map(rubric) and is_binary(renderer_version) and
             is_binary(commit_sha) and is_list(multipage) and is_binary(baseline_commit_sha) do
    with :ok <- valid_candidate_baseline(baseline),
         :ok <- valid_candidate_cells(cells),
         :ok <- valid_candidate_multipage(multipage),
         true <- full_commit_sha?(commit_sha),
         true <- full_commit_sha?(baseline_commit_sha) do
      baseline_by_id = Map.new(baseline["cells"], &{&1["id"], &1})
      dispositions = Map.new(rubric["catalog_dispositions"] || [], &{&1["catalog_id"], &1})
      pin = read_pdfium_pin()

      {candidate_cells, diff} =
        Enum.map_reduce(
          cells,
          %{changed_targets: [], changed_scored: [], changed_unscored: [], byte_stable: []},
          fn cell, acc ->
            baseline_cell = Map.fetch!(baseline_by_id, cell["id"])

            {status, bucket} =
              candidate_status(cell, baseline_cell, dispositions[cell["id"]] || %{})

            candidate_cell =
              cell
              |> Map.delete("quality")
              |> Map.put("review_status", status)
              |> Map.put("renderer_sha256", pin["sha256"])
              |> maybe_put_candidate_hashes(status, baseline_cell)

            acc = Map.update!(acc, bucket, &(&1 ++ [cell["id"]]))

            acc =
              if bucket == :byte_stable,
                do: acc,
                else: Map.update!(acc, :changed_targets, &(&1 ++ [cell["id"]]))

            {candidate_cell, acc}
          end
        )

      case valid_candidate_diff(diff) do
        :ok ->
          {:ok,
           %{
             "schema_version" => @schema_version,
             "generated_by" => @candidate_generated_by,
             "candidate" => %{
               "commit_sha" => commit_sha,
               "baseline_commit_sha" => baseline_commit_sha,
               "run_id" => System.get_env("GITHUB_RUN_ID") || "local-#{commit_sha}",
               "run_attempt" => workflow_run_attempt(),
               "renderer" => %{
                 "kind" => @renderer_kind,
                 "version" => renderer_version,
                 "dpi" => @dpi,
                 "pin_path" => @pdfium_pin_path,
                 "sha256" => pin["sha256"]
               }
             },
             "renderer" => %{
               "kind" => @renderer_kind,
               "version" => renderer_version,
               "dpi" => @dpi,
               "pin_path" => @pdfium_pin_path,
               "pin_sha256" => pin["sha256"]
             },
             "cells" => candidate_cells,
             "multipage" => multipage,
             "diff" => Map.new(diff, fn {bucket, ids} -> {Atom.to_string(bucket), ids} end)
           }}

        {:error, _reason} = error ->
          error
      end
    else
      false -> {:error, :invalid_candidate_identity}
      {:error, _reason} = error -> error
    end
  end

  def candidate_manifest(
        _cells,
        _baseline,
        _rubric,
        _renderer_version,
        _commit_sha,
        _multipage,
        _baseline_commit_sha
      ),
      do: {:error, :invalid_candidate_manifest_input}

  @doc false
  @spec baseline_commit_sha(keyword()) :: {:ok, String.t()} | {:error, atom()}
  def baseline_commit_sha(opts \\ []) do
    repo_root = opts |> Keyword.get(:repo_root, File.cwd!()) |> Path.expand()

    manifest_path =
      opts
      |> Keyword.get(:manifest_path, @manifest_path)
      |> then(&Path.expand(&1, repo_root))

    with {:ok, manifest_bytes} <- read_baseline_manifest(manifest_path),
         {:ok, repo_path} <- baseline_repo_path(repo_root, manifest_path),
         :ok <- baseline_path_is_tracked(repo_root, repo_path),
         :ok <- baseline_path_is_clean(repo_root, repo_path),
         {:ok, commit_sha} <- resolve_baseline_commit(repo_root, repo_path, opts),
         :ok <- validate_full_commit_sha(commit_sha),
         {:ok, blob} <- read_commit_blob(repo_root, commit_sha, repo_path),
         true <- blob == manifest_bytes do
      {:ok, commit_sha}
    else
      false -> {:error, :baseline_manifest_mismatch}
      {:error, _reason} = error -> error
    end
  end

  @doc false
  @spec canonical_manifest([map()], String.t(), String.t()) :: map()
  def canonical_manifest(cells, renderer_version, source_commit_sha)
      when is_list(cells) and is_binary(renderer_version) and is_binary(source_commit_sha) do
    unless full_commit_sha?(source_commit_sha),
      do: raise(ArgumentError, "canonical source_commit_sha must be a full lowercase Git SHA")

    pin = read_pdfium_pin()

    %{
      "schema_version" => @schema_version,
      "generated_by" => @generated_by,
      "source_commit_sha" => source_commit_sha,
      "renderer" => %{
        "kind" => @renderer_kind,
        "version" => renderer_version,
        "dpi" => @dpi,
        "pin_path" => @pdfium_pin_path,
        "pin_sha256" => pin["sha256"]
      },
      "cells" => cells
    }
  end

  @spec check(keyword()) :: :ok | {:error, [String.t()]}
  def check(opts \\ []) do
    with_pdfium(opts, fn ->
      manifest = Keyword.get(opts, :manifest)
      rubric = Keyword.get(opts, :rubric, read_rubric_scores())

      errors =
        if manifest,
          do: static_contract_errors(manifest, rubric),
          else: static_contract_errors(read_manifest!(), rubric)

      errors =
        if errors == [] do
          errors ++ rendered_contract_errors(manifest || read_manifest!())
        else
          errors
        end

      if errors == [], do: :ok, else: {:error, errors}
    end)
  end

  @spec static_contract_errors() :: [String.t()]
  def static_contract_errors do
    if File.exists?(@manifest_path),
      do: static_contract_errors(read_manifest!()),
      else: ["missing catalog manifest: #{@manifest_path}; run mix rendro.catalog.gen"]
  end

  @spec static_contract_errors(map()) :: [String.t()]
  def static_contract_errors(manifest) when is_map(manifest),
    do: static_contract_errors(manifest, read_rubric_scores())

  @spec static_contract_errors(map(), map()) :: [String.t()]
  def static_contract_errors(manifest, rubric) when is_map(manifest) and is_map(rubric) do
    manifest_shape_errors(manifest) ++
      catalog_contract_errors(catalog_specs()) ++
      quality_contract_errors(manifest, rubric)
  end

  @spec artifact_contract_errors(map()) :: [String.t()]
  def artifact_contract_errors(%{"cells" => cells}) when is_list(cells) do
    Enum.flat_map(cells, &artifact_contract_errors_for_cell/1)
  end

  def artifact_contract_errors(_manifest),
    do: ["catalog manifest cells are required for artifact checks"]

  @spec quality_contract_errors(map(), map()) :: [String.t()]
  def quality_contract_errors(%{"cells" => cells}, %{"catalog_dispositions" => dispositions})
      when is_list(cells) and is_list(dispositions) do
    cells_by_id = Map.new(cells, &{&1["id"], &1})
    dispositions_by_id = Enum.group_by(dispositions, & &1["catalog_id"])

    orphan_errors =
      dispositions_by_id
      |> Map.keys()
      |> Enum.reject(&Map.has_key?(cells_by_id, &1))
      |> Enum.sort()
      |> Enum.map(&"catalog orphan disposition #{&1}; remove it or restore its catalog cell")

    cell_errors =
      Enum.flat_map(cells, fn cell ->
        id = cell["id"]

        case Map.get(dispositions_by_id, id, []) do
          [] ->
            [
              "catalog #{id}: missing disposition; add one scored or reasoned-unscored reviewer record"
            ]

          [disposition] ->
            disposition_errors(cell, disposition) ++ projection_errors(cell, disposition)

          _ ->
            ["catalog #{id}: expected exactly one disposition; remove duplicate reviewer records"]
        end
      end)

    orphan_errors ++ cell_errors
  end

  def quality_contract_errors(%{"cells" => _cells}, _rubric),
    do: [
      "catalog quality records missing catalog_dispositions; add the additive reviewer-owned array"
    ]

  def quality_contract_errors(_manifest, _rubric),
    do: ["catalog manifest cells are required for the quality join"]

  @spec manifest_shape_errors(map()) :: [String.t()]
  def manifest_shape_errors(manifest) when is_map(manifest) do
    cells = Map.get(manifest, "cells", [])
    expected_ids = Enum.map(catalog_specs(), & &1.id)
    pin = read_pdfium_pin()

    []
    |> add_unless(
      Map.get(manifest, "schema_version") == @schema_version,
      "catalog schema_version must be #{@schema_version}"
    )
    |> add_unless(
      Map.get(manifest, "generated_by") == @generated_by,
      "catalog generated_by must be #{@generated_by}"
    )
    |> add_unless(is_list(cells), "catalog cells must be a list")
    |> add_unless(
      Enum.map(cells, &Map.get(&1, "id")) == expected_ids,
      "catalog cell order must match the literal registry"
    )
    |> add_unless(
      get_in(manifest, ["renderer", "kind"]) == @renderer_kind,
      "catalog renderer kind must be #{@renderer_kind}"
    )
    |> add_unless(
      get_in(manifest, ["renderer", "dpi"]) == @dpi,
      "catalog renderer dpi must be #{@dpi}"
    )
    |> add_unless(
      get_in(manifest, ["renderer", "pin_sha256"]) == pin["sha256"],
      "catalog renderer pin must match #{@pdfium_pin_path}"
    )
    |> Enum.concat(Enum.flat_map(cells, &cell_shape_errors/1))
  end

  @spec read_manifest!() :: map()
  def read_manifest!, do: @manifest_path |> File.read!() |> JSON.decode!()

  defp validate_safe_path!(path, label) when is_binary(path) do
    case Path.safe_relative(path) do
      {:ok, _safe} -> :ok
      :error -> raise ArgumentError, "unsafe catalog #{label} path rejected: #{inspect(path)}"
    end
  end

  defp validate_safe_path!(path, label),
    do: raise(ArgumentError, "unsafe catalog #{label} path rejected: #{inspect(path)}")

  @spec catalog_contract_errors([map()]) :: [String.t()]
  def catalog_contract_errors(specs) when is_list(specs) do
    ids = Enum.map(specs, &Map.get(&1, :id))
    paths = Enum.map(specs, &Map.get(&1, :png_path))
    expected_ids = Enum.map(catalog_specs(), & &1.id)

    []
    |> add_unless(length(specs) == 32, "catalog must contain exactly 32 literal cells")
    |> add_unless(length(specs) <= 32, "catalog exceeds the 32-cell hard ceiling")
    |> add_unless(Enum.uniq(ids) == ids, "catalog contains duplicate IDs")
    |> add_unless(Enum.uniq(paths) == paths, "catalog contains duplicate PNG paths")
    |> add_unless(ids == expected_ids, "catalog IDs are not in canonical literal order")
  end

  defp theme_for(%{preset_atom: nil}), do: Rendro.Theme.default()

  defp theme_for(%{preset_atom: preset, accent: accent, mode: mode}),
    do: Rendro.Theme.preset(preset, accent: accent, mode: catalog_mode!(mode))

  defp catalog_mode!("light"), do: :light
  defp catalog_mode!("dark"), do: :dark
  defp catalog_mode!(mode), do: raise(ArgumentError, "unsupported catalog mode: #{inspect(mode)}")

  defp recipe_module(:invoice), do: Rendro.Recipes.Invoice
  defp recipe_module(:statement), do: Rendro.Recipes.Statement
  defp recipe_module(:receipt), do: Rendro.Recipes.Receipt
  defp recipe_module(:certificate), do: Rendro.Recipes.Certificate
  defp recipe_module(:payslip), do: Rendro.Recipes.Payslip
  defp recipe_module(:ticket), do: Rendro.Recipes.Ticket

  defp build_cells(renderer_version, write_root, manifest_root) do
    catalog_specs()
    |> Enum.map(fn spec ->
      relative_path = Path.relative_to(spec.png_path, @asset_root)
      write_path = Path.join(write_root, relative_path)
      spec = %{spec | png_path: Path.join(manifest_root, relative_path)}

      with {:ok, pdf} <- render_source_pdf(spec),
           {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1"),
           :ok <- File.mkdir_p(Path.dirname(write_path)),
           :ok <- File.write(write_path, png) do
        {:ok, {width, height}} = png_dimensions(png)

        {:ok,
         Map.merge(stringify_spec(spec), %{
           "png_sha256" => sha256(png),
           "source_pdf_sha256" => sha256(pdf),
           "page" => 1,
           "page_count" => page_count(pdf),
           "dpi" => @dpi,
           "width_px" => width,
           "height_px" => height,
           "renderer_kind" => @renderer_kind,
           "renderer_version" => renderer_version,
           "preview_copy" =>
             if(page_count(pdf) == 1, do: nil, else: "Preview: page 1 of #{page_count(pdf)}")
         })}
      else
        {:error, reason} -> {:error, {spec.id, reason}}
        other -> {:error, {spec.id, other}}
      end
    end)
    |> split_results()
  end

  defp rendered_contract_errors(manifest) do
    cells = Map.new(manifest["cells"], &{&1["id"], &1})

    artifact_contract_errors(manifest) ++
      Enum.flat_map(catalog_specs(), fn spec ->
        case {cells[spec.id], render_source_pdf(spec)} do
          {nil, _} ->
            ["catalog #{spec.id}: manifest cell missing; run mix rendro.catalog.gen"]

          {cell, {:ok, pdf}} ->
            []
            |> add_unless(
              cell["source_pdf_sha256"] == sha256(pdf),
              "catalog #{spec.id}: source PDF hash drift; run mix rendro.catalog.gen"
            )
            |> add_unless(
              cell["page_count"] == page_count(pdf),
              "catalog #{spec.id}: page count drift; inspect the recipe before regenerating"
            )

          {_cell, {:error, reason}} ->
            ["catalog #{spec.id}: source PDF render failed: #{inspect(reason)}"]
        end
      end)
  end

  defp artifact_contract_errors_for_cell(%{"id" => id, "png_path" => path} = cell)
       when is_binary(path) do
    case Path.safe_relative(path) do
      {:ok, _safe_path} -> png_file_contract_errors(id, path, cell)
      :error -> ["catalog #{id}: unsafe PNG path; regenerate the catalog manifest"]
    end
  end

  defp artifact_contract_errors_for_cell(%{"id" => id}),
    do: ["catalog #{id}: PNG path missing; regenerate the catalog manifest"]

  defp artifact_contract_errors_for_cell(_cell),
    do: ["catalog artifact cell is malformed; regenerate the catalog manifest"]

  defp png_file_contract_errors(id, path, cell) do
    case File.read(path) do
      {:ok, png} ->
        []
        |> add_unless(
          sha256(png) == cell["png_sha256"],
          "catalog #{id}: PNG hash drift; run mix rendro.catalog.gen"
        )
        |> Kernel.++(png_dimension_errors(id, png, cell))

      {:error, :enoent} ->
        ["catalog #{id}: PNG missing at #{path}; run mix rendro.catalog.gen"]

      {:error, reason} ->
        ["catalog #{id}: PNG unreadable at #{path}: #{inspect(reason)}"]
    end
  end

  defp png_dimension_errors(id, png, cell) do
    case png_dimensions(png) do
      {:ok, {width, height}} ->
        []
        |> add_unless(
          width == cell["width_px"],
          "catalog #{id}: PNG width drift; run mix rendro.catalog.gen"
        )
        |> add_unless(
          height == cell["height_px"],
          "catalog #{id}: PNG height drift; run mix rendro.catalog.gen"
        )

      :error ->
        ["catalog #{id}: PNG dimensions are unreadable; regenerate the catalog artifact"]
    end
  end

  defp cell_shape_errors(cell) when is_map(cell) do
    id = cell["id"] || inspect(cell)

    required =
      ~w(id family brand preset theme accent mode recipe_module fixture_ref png_path png_sha256 source_pdf_sha256 page page_count dpi width_px height_px renderer_kind renderer_version alt caption preview_copy boundary_disclosure quality)

    Enum.map(required -- Map.keys(cell), &missing_field_error(id, &1)) ++
      preview_copy_errors(cell, id) ++
      boundary_disclosure_errors(cell, id) ++ quality_errors(cell, id)
  end

  defp cell_shape_errors(other), do: ["catalog cell must be a map: #{inspect(other)}"]

  defp stringify_spec(spec) do
    %{
      "id" => spec.id,
      "family" => Atom.to_string(spec.family),
      "brand" => spec.brand,
      "preset" => spec.preset,
      "theme" => spec.theme,
      "accent" => spec.accent,
      "mode" => spec.mode,
      "recipe_module" => Atom.to_string(spec.recipe_module),
      "fixture_ref" => spec.fixture_ref,
      "png_path" => spec.png_path,
      "alt" => spec.alt,
      "caption" => spec.caption,
      "boundary_disclosure" => boundary_disclosure(spec.mode),
      "quality" => %{"status" => "unscored", "label" => "Not yet scored"}
    }
  end

  defp missing_field_error(id, "quality"),
    do: "catalog #{id}: missing quality; add a derived quality projection"

  defp missing_field_error(id, field),
    do: "catalog #{id}: missing #{field}; regenerate the catalog manifest"

  defp preview_copy_errors(cell, id) do
    page_count = cell["page_count"]
    preview_copy = cell["preview_copy"]

    cond do
      not is_integer(page_count) or page_count < 1 ->
        ["catalog #{id}: page_count must be a positive integer; inspect the complete source PDF"]

      cell["page"] != 1 ->
        ["catalog #{id}: page must be physical page 1; regenerate the page-one preview"]

      page_count == 1 and not is_nil(preview_copy) ->
        [
          "catalog #{id}: preview_copy must be null for a one-page document; remove the page-one disclosure"
        ]

      page_count > 1 and preview_copy != "Preview: page 1 of #{page_count}" ->
        [
          "catalog #{id}: preview_copy must be Preview: page 1 of #{page_count}; derive it from page_count without claiming a complete document"
        ]

      true ->
        []
    end
  end

  defp boundary_disclosure_errors(cell, id) do
    case {cell["mode"], cell["boundary_disclosure"]} do
      {"dark", @dark_boundary_disclosure} ->
        []

      {"dark", _} ->
        [
          "catalog #{id}: dark boundary_disclosure must be the fixed screen-oriented claim; derive it from mode"
        ]

      {"light", nil} ->
        []

      {"light", _} ->
        ["catalog #{id}: light boundary_disclosure must be null; remove the dark-mode claim"]

      _ ->
        ["catalog #{id}: mode must be light or dark; correct the catalog registry"]
    end
  end

  defp quality_errors(%{"quality" => %{"status" => status, "label" => label}}, _id)
       when {status, label} in [
              {"passes", "Scored — passes current rubric"},
              {"needs_work", "Scored — needs work"},
              {"unscored", "Not yet scored"}
            ],
       do: []

  defp quality_errors(_cell, id),
    do: [
      "catalog #{id}: quality must be one of the derived three-state projections; run the rubric contract check"
    ]

  defp boundary_disclosure("dark"), do: @dark_boundary_disclosure
  defp boundary_disclosure("light"), do: nil

  defp disposition_errors(cell, disposition) do
    id = cell["id"]

    []
    |> add_unless(
      disposition["family"] == cell["family"],
      "catalog #{id}: family is stale; refresh the reviewer binding"
    )
    |> add_unless(
      disposition["brand"] == cell["brand"],
      "catalog #{id}: brand is stale; refresh the reviewer binding"
    )
    |> add_unless(
      disposition["preset"] == cell["preset"],
      "catalog #{id}: preset is stale; refresh the reviewer binding"
    )
    |> add_unless(
      disposition["mode"] == cell["mode"],
      "catalog #{id}: mode is stale; refresh the reviewer binding"
    )
    |> add_unless(
      disposition["evidence_ref"] == cell["png_path"],
      "catalog #{id}: evidence path is stale; deliberately rebind this artifact"
    )
    |> add_unless(
      disposition["png_sha256"] == cell["png_sha256"],
      "catalog #{id}: PNG hash is stale; deliberately rebind this artifact"
    )
    |> add_unless(
      disposition["source_pdf_sha256"] == cell["source_pdf_sha256"],
      "catalog #{id}: source PDF hash is stale; deliberately rebind this artifact"
    )
    |> Kernel.++(review_status_errors(id, disposition))
  end

  defp review_status_errors(id, %{"review_status" => "unscored", "reason" => reason})
       when is_binary(reason) do
    if concrete?(reason),
      do: [],
      else: [
        "catalog #{id}: unscored disposition needs a non-empty reason; record why review is pending"
      ]
  end

  defp review_status_errors(id, %{"review_status" => "unscored"}),
    do: [
      "catalog #{id}: unscored disposition needs a non-empty reason; record why review is pending"
    ]

  defp review_status_errors(id, %{"review_status" => "scored"} = disposition) do
    scores = disposition["dimension_scores"]
    gates = disposition["gate_results"]
    passed = disposition["passed"]

    cond do
      not is_map(scores) or not is_map(gates) or not is_boolean(passed) ->
        ["catalog #{id}: scored disposition needs dimensions, gates, and passed verdict"]

      passed != rubric_passed?(scores, gates) ->
        ["catalog #{id}: passed must match the rubric thresholds; correct the recorded verdict"]

      true ->
        scored_evidence_errors(id, disposition)
    end
  end

  defp review_status_errors(id, _),
    do: ["catalog #{id}: review_status must be scored or unscored; correct the reviewer record"]

  defp scored_evidence_errors(id, disposition) do
    []
    |> add_unless(
      concrete?(disposition["signed_off_by"]),
      "catalog #{id}: scored disposition needs a non-empty signed_off_by"
    )
    |> add_unless(
      valid_iso_date?(disposition["signed_off_at"]),
      "catalog #{id}: scored disposition needs a valid ISO calendar signed_off_at date"
    )
    |> add_unless(
      exact_justifications?(disposition["justifications"]),
      "catalog #{id}: scored disposition needs exactly the six non-empty justification dimensions"
    )
    |> add_unless(
      concrete?(disposition["resolution_ref"]),
      "catalog #{id}: scored disposition needs a non-empty behavioral resolution_ref"
    )
    |> add_unless(
      concrete?(disposition["supersedes_evidence_ref"]),
      "catalog #{id}: scored disposition needs a concrete prior or superseded evidence reference"
    )
  end

  defp exact_justifications?(justifications) when is_map(justifications) do
    required =
      ~w(information_architecture content_hierarchy domain_fit reader_affordances typographic_craft restraint_cohesion)
      |> Enum.sort()

    Enum.sort(Map.keys(justifications)) == required and
      Enum.all?(justifications, fn {_dimension, value} -> concrete?(value) end)
  end

  defp exact_justifications?(_), do: false

  defp valid_iso_date?(value) when is_binary(value),
    do: match?({:ok, _}, Date.from_iso8601(value))

  defp valid_iso_date?(_), do: false

  defp projection_errors(%{"quality" => quality} = cell, disposition) do
    if quality == quality_projection(disposition),
      do: [],
      else: [
        "catalog #{cell["id"]}: quality projection drift; regenerate from the reviewer disposition"
      ]
  end

  defp projection_errors(_cell, _disposition), do: []

  defp quality_projection(%{"review_status" => "unscored"}),
    do: %{"status" => "unscored", "label" => "Not yet scored"}

  defp quality_projection(%{"review_status" => "scored", "passed" => true}),
    do: %{"status" => "passes", "label" => "Scored — passes current rubric"}

  defp quality_projection(%{"review_status" => "scored", "passed" => false}),
    do: %{"status" => "needs_work", "label" => "Scored — needs work"}

  defp apply_quality_projections(cells, rubric) do
    if rubric["catalog_dispositions"] == [] do
      # The initial pinned render establishes the hashes that reviewer-owned
      # dispositions must bind. The read-only checker remains fail-closed until
      # those records are deliberately added and a subsequent generation
      # projects them back into the manifest.
      {:ok, cells}
    else
      apply_bound_quality_projections(cells, rubric)
    end
  end

  defp apply_bound_quality_projections(cells, rubric) do
    join_cells = Enum.map(cells, &Map.delete(&1, "quality"))
    errors = quality_contract_errors(%{"cells" => join_cells}, rubric)

    if errors == [] do
      dispositions_by_id = Map.new(rubric["catalog_dispositions"], &{&1["catalog_id"], &1})

      {:ok,
       Enum.map(cells, fn cell ->
         Map.put(cell, "quality", quality_projection(dispositions_by_id[cell["id"]]))
       end)}
    else
      {:error, errors}
    end
  end

  defp rubric_passed?(scores, gates) do
    scores["content_hierarchy"] == 5 and
      Map.delete(scores, "content_hierarchy")
      |> Enum.all?(fn {_dimension, score} -> is_integer(score) and score >= 4 end) and
      Enum.all?(gates, fn {_gate, result} -> result == true end)
  end

  defp concrete?(value), do: is_binary(value) and byte_size(String.trim(value)) > 0
  defp read_rubric_scores, do: "priv/quality/rubric_scores.json" |> File.read!() |> JSON.decode!()

  defp encode_manifest(manifest), do: Jason.encode!(manifest, pretty: true)
  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp png_dimensions(
         <<137, 80, 78, 71, 13, 10, 26, 10, _::binary-size(8), width::32, height::32, _::binary>>
       ),
       do: {:ok, {width, height}}

  defp png_dimensions(_), do: :error

  defp read_pdfium_pin, do: @pdfium_pin_path |> File.read!() |> JSON.decode!()

  defp split_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, value}, {:ok, acc} -> {:cont, {:ok, acc ++ [value]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
  end

  defp valid_candidate_baseline(%{"cells" => cells}) when is_list(cells) do
    expected_ids = Enum.map(catalog_specs(), & &1.id)

    if Enum.map(cells, & &1["id"]) == expected_ids and
         Enum.all?(cells, &valid_candidate_baseline_cell?/1) do
      :ok
    else
      {:error, :invalid_candidate_baseline}
    end
  end

  defp valid_candidate_baseline(_), do: {:error, :invalid_candidate_baseline}

  defp valid_candidate_baseline_cell?(%{
         "png_path" => path,
         "png_sha256" => png_sha,
         "source_pdf_sha256" => pdf_sha
       }) do
    match?({:ok, _}, Path.safe_relative(path)) and sha256?(png_sha) and sha256?(pdf_sha)
  end

  defp valid_candidate_baseline_cell?(_), do: false

  defp valid_candidate_cells(cells) do
    expected_ids = Enum.map(catalog_specs(), & &1.id)

    cond do
      not Enum.all?(cells, &valid_candidate_cell?/1) ->
        {:error, :invalid_candidate_cells}

      Enum.map(cells, & &1["id"]) != expected_ids ->
        {:error, :invalid_candidate_scope}

      true ->
        :ok
    end
  end

  defp valid_candidate_cell?(%{
         "png_path" => path,
         "png_sha256" => png_sha,
         "source_pdf_sha256" => pdf_sha,
         "width_px" => width,
         "height_px" => height,
         "page_count" => page_count
       }) do
    String.starts_with?(path, @candidate_root <> "/") and
      match?({:ok, _}, Path.safe_relative(path)) and sha256?(png_sha) and sha256?(pdf_sha) and
      is_integer(width) and width > 0 and is_integer(height) and height > 0 and
      is_integer(page_count) and page_count > 0
  end

  defp valid_candidate_cell?(_), do: false

  defp valid_candidate_multipage(multipage) do
    if Enum.map(multipage, & &1["id"]) == @candidate_multipage_ids and
         Enum.all?(multipage, &valid_candidate_multipage_proof?/1) do
      :ok
    else
      {:error, :invalid_candidate_multipage}
    end
  end

  defp valid_candidate_multipage_proof?(%{
         "id" => id,
         "family" => family,
         "page" => page,
         "png_path" => path,
         "png_sha256" => png_sha,
         "source_pdf_sha256" => pdf_sha
       }) do
    id in @candidate_multipage_ids and family in ["invoice", "statement"] and
      page in ["first", "final"] and String.starts_with?(path, @candidate_root <> "/") and
      match?({:ok, _}, Path.safe_relative(path)) and sha256?(png_sha) and sha256?(pdf_sha)
  end

  defp valid_candidate_multipage_proof?(_), do: false

  defp build_multipage_proofs do
    for {family, page} <- [
          {:invoice, "first"},
          {:invoice, "final"},
          {:statement, "first"},
          {:statement, "final"}
        ] do
      with {:ok, pdf} <- Rendro.render(multipage_document(family), deterministic: true),
           {:ok, pages} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi),
           true <- length(pages) > 1,
           png <- if(page == "first", do: hd(pages), else: List.last(pages)),
           relative_path <- "multipage/#{family}-#{page}.png",
           :ok <- File.mkdir_p(Path.join(@candidate_staging_root, "multipage")),
           :ok <- File.write(Path.join(@candidate_staging_root, relative_path), png) do
        {:ok,
         %{
           "id" => "#{family}-line-items-60-plus-page-#{page}",
           "family" => Atom.to_string(family),
           "page" => page,
           "png_path" => Path.join(@candidate_root, relative_path),
           "png_sha256" => sha256(png),
           "source_pdf_sha256" => sha256(pdf)
         }}
      else
        false -> {:error, {:multipage_not_rendered, family}}
        {:error, reason} -> {:error, {family, reason}}
      end
    end
    |> split_results()
  end

  defp multipage_document(:invoice) do
    Rendro.Recipes.Invoice.document(%{
      id: "INV-1001",
      date: ~D[2026-01-15],
      items: Enum.map(1..65, &%{name: "Line item #{&1}", qty: 1, price: 100})
    })
  end

  defp multipage_document(:statement) do
    Rendro.Recipes.Statement.document(%{
      period: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
      account: %{name: "Acme Corp"},
      opening_balance: Decimal.new("1000.00"),
      lines:
        Enum.map(1..65, fn index ->
          %{
            date: ~D[2026-01-05],
            description: "Line item #{index}",
            amount: Decimal.new("100.00")
          }
        end)
    })
  end

  defp candidate_status(cell, baseline_cell, disposition) do
    if cell["png_sha256"] == baseline_cell["png_sha256"] and
         cell["source_pdf_sha256"] == baseline_cell["source_pdf_sha256"] do
      {"byte_stable", :byte_stable}
    else
      if disposition["review_status"] == "scored",
        do: {"review_required", :changed_scored},
        else: {"changed_unscored", :changed_unscored}
    end
  end

  defp valid_candidate_diff(%{
         changed_targets: changed_targets,
         changed_scored: changed_scored,
         changed_unscored: changed_unscored,
         byte_stable: byte_stable
       }) do
    target_ids = visual_target_ids()
    control_ids = Enum.reject(Enum.map(catalog_specs(), & &1.id), &(&1 in target_ids))

    descriptive_targets =
      Enum.filter(target_ids, &(&1 in changed_scored or &1 in changed_unscored))

    descriptive_buckets_are_ordered =
      changed_scored == Enum.filter(target_ids, &(&1 in changed_scored)) and
        changed_unscored == Enum.filter(target_ids, &(&1 in changed_unscored))

    if map_size(@visual_target_profiles) == 6 and changed_targets == target_ids and
         descriptive_targets == target_ids and
         length(changed_scored) + length(changed_unscored) == length(target_ids) and
         descriptive_buckets_are_ordered and byte_stable == control_ids do
      :ok
    else
      {:error, :invalid_candidate_scope}
    end
  end

  defp valid_candidate_diff(_), do: {:error, :invalid_candidate_scope}

  defp visual_target_ids do
    catalog_specs()
    |> Enum.map(& &1.id)
    |> Enum.filter(&Map.has_key?(@visual_target_profiles, &1))
  end

  defp validate_candidate_staging(cells) do
    errors =
      Enum.flat_map(cells, fn cell ->
        staging_path =
          String.replace_prefix(cell["png_path"], @candidate_root, @candidate_staging_root)

        case File.read(staging_path) do
          {:ok, png} ->
            []
            |> add_unless(
              sha256(png) == cell["png_sha256"],
              "candidate #{cell["id"]}: PNG hash drift"
            )
            |> add_unless(
              png_dimensions(png) == {:ok, {cell["width_px"], cell["height_px"]}},
              "candidate #{cell["id"]}: PNG dimensions drift"
            )

          {:error, reason} ->
            ["candidate #{cell["id"]}: PNG staging read failed: #{inspect(reason)}"]
        end
      end)

    if errors == [], do: :ok, else: {:error, errors}
  end

  defp maybe_put_candidate_hashes(cell, "byte_stable", _baseline), do: cell

  defp maybe_put_candidate_hashes(cell, _status, baseline) do
    cell
    |> Map.put("prior_png_sha256", baseline["png_sha256"])
    |> Map.put("candidate_png_sha256", cell["png_sha256"])
    |> Map.put("prior_source_pdf_sha256", baseline["source_pdf_sha256"])
    |> Map.put("candidate_source_pdf_sha256", cell["source_pdf_sha256"])
  end

  defp cleanup_candidate do
    File.rm_rf!(@candidate_staging_root)
    File.rm_rf!(@candidate_root)
  end

  defp cleanup_canonical_staging do
    File.rm_rf!(@canonical_staging_root)
    File.rm_rf!(@canonical_manifest_staging_path)
  end

  defp publish_canonical_staging do
    publish_canonical_staging(%{
      asset_root: @asset_root,
      manifest_path: @manifest_path,
      asset_staging_root: @canonical_staging_root,
      manifest_staging_path: @canonical_manifest_staging_path,
      asset_backup_root: @asset_root <> ".previous",
      manifest_backup_path: @manifest_path <> ".previous"
    })
  end

  @doc false
  def publish_canonical_staging(paths, opts \\ [])

  def publish_canonical_staging(paths, opts) when is_map(paths) and is_list(opts) do
    with {:ok, staged} <- staged_generation(paths),
         :ok <- backups_are_absent(paths) do
      state = %{
        asset_backed_up: false,
        manifest_backed_up: false,
        asset_installed: false,
        manifest_installed: false
      }

      case run_publication_steps(paths, staged, state, opts) do
        {:ok, _state} ->
          cleanup_publication_backups(paths)

        {:error, reason, failed_state} ->
          case rollback_publication(paths, failed_state) do
            :ok -> {:error, reason}
            {:error, rollback_errors} -> {:error, {:rollback_failed, reason, rollback_errors}}
          end
      end
    end
  end

  def publish_canonical_staging(_paths, _opts), do: {:error, :invalid_publication_paths}

  defp staged_generation(paths) do
    with {:ok, assets} <- directory_snapshot(paths.asset_staging_root),
         true <- map_size(assets) > 0,
         {:ok, manifest} <- File.read(paths.manifest_staging_path),
         true <- byte_size(manifest) > 0 do
      {:ok, %{assets: assets, manifest: manifest}}
    else
      false -> {:error, :incomplete_canonical_staging}
      {:error, _reason} -> {:error, :incomplete_canonical_staging}
    end
  end

  defp backups_are_absent(paths) do
    if File.exists?(paths.asset_backup_root) or File.exists?(paths.manifest_backup_path),
      do: {:error, :ambiguous_canonical_backup},
      else: :ok
  end

  defp run_publication_steps(paths, staged, initial_state, opts) do
    steps = [
      {:backup_assets,
       &backup_if_present(&1, paths.asset_root, paths.asset_backup_root, :asset_backed_up)},
      {:backup_manifest,
       &backup_if_present(
         &1,
         paths.manifest_path,
         paths.manifest_backup_path,
         :manifest_backed_up
       )},
      {:install_assets,
       &install_staging(&1, paths.asset_staging_root, paths.asset_root, :asset_installed)},
      {:install_manifest,
       &install_staging(
         &1,
         paths.manifest_staging_path,
         paths.manifest_path,
         :manifest_installed
       )},
      {:verify_assets, &verify_installed_assets(&1, paths.asset_root, staged.assets)},
      {:verify_manifest, &verify_installed_manifest(&1, paths.manifest_path, staged.manifest)}
    ]

    Enum.reduce_while(steps, {:ok, initial_state}, fn {step, operation}, {:ok, state} ->
      if Keyword.get(opts, :fail_at) == step do
        {:halt, {:error, {:injected_failure, step}, state}}
      else
        case operation.(state) do
          {:ok, next_state} -> {:cont, {:ok, next_state}}
          {:error, reason} -> {:halt, {:error, {step, reason}, state}}
        end
      end
    end)
  end

  defp backup_if_present(state, source, target, state_key) do
    if File.exists?(source) do
      case File.rename(source, target) do
        :ok -> {:ok, Map.put(state, state_key, true)}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, state}
    end
  end

  defp install_staging(state, source, target, state_key) do
    case File.rename(source, target) do
      :ok -> {:ok, Map.put(state, state_key, true)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_installed_assets(state, root, expected) do
    case directory_snapshot(root) do
      {:ok, ^expected} -> {:ok, state}
      {:ok, _other} -> {:error, :installed_assets_mismatch}
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_installed_manifest(state, path, expected) do
    case File.read(path) do
      {:ok, ^expected} -> {:ok, state}
      {:ok, _other} -> {:error, :installed_manifest_mismatch}
      {:error, reason} -> {:error, reason}
    end
  end

  defp rollback_publication(paths, state) do
    errors =
      []
      |> maybe_remove_installed(state.asset_installed, paths.asset_root)
      |> maybe_remove_installed(state.manifest_installed, paths.manifest_path)
      |> maybe_restore_backup(state.asset_backed_up, paths.asset_backup_root, paths.asset_root)
      |> maybe_restore_backup(
        state.manifest_backed_up,
        paths.manifest_backup_path,
        paths.manifest_path
      )
      |> remove_transaction_path(paths.asset_staging_root)
      |> remove_transaction_path(paths.manifest_staging_path)
      |> remove_transaction_path(paths.asset_backup_root)
      |> remove_transaction_path(paths.manifest_backup_path)

    if errors == [], do: :ok, else: {:error, errors}
  end

  defp cleanup_publication_backups(paths) do
    errors =
      []
      |> remove_transaction_path(paths.asset_backup_root)
      |> remove_transaction_path(paths.manifest_backup_path)

    if errors == [], do: :ok, else: {:error, {:backup_cleanup_failed, errors}}
  end

  defp maybe_remove_installed(errors, false, _path), do: errors
  defp maybe_remove_installed(errors, true, path), do: remove_transaction_path(errors, path)

  defp maybe_restore_backup(errors, false, _backup, _target), do: errors

  defp maybe_restore_backup(errors, true, backup, target) do
    case File.rename(backup, target) do
      :ok -> errors
      {:error, reason} -> errors ++ [{:restore_failed, backup, target, reason}]
    end
  end

  defp remove_transaction_path(errors, path) do
    case File.rm_rf(path) do
      {:ok, _removed} -> errors
      {:error, reason, failed_path} -> errors ++ [{:remove_failed, failed_path, reason}]
    end
  end

  defp directory_snapshot(root) do
    if File.dir?(root) do
      assets =
        root
        |> Path.join("**/*")
        |> Path.wildcard(match_dot: true)
        |> Enum.filter(&File.regular?/1)
        |> Map.new(fn path -> {Path.relative_to(path, root), File.read!(path)} end)

      {:ok, assets}
    else
      {:error, :missing_directory}
    end
  rescue
    _ -> {:error, :unreadable_directory}
  end

  defp current_commit_sha! do
    case current_commit_sha() do
      {:ok, sha} -> sha
      {:error, reason} -> raise "candidate commit identity unavailable: #{inspect(reason)}"
    end
  end

  defp current_commit_sha do
    case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} ->
        sha = String.trim(sha)
        if full_commit_sha?(sha), do: {:ok, sha}, else: {:error, :invalid_candidate_identity}

      {_reason, _status} ->
        {:error, :candidate_commit_identity_unavailable}
    end
  end

  defp read_baseline_manifest(path) do
    case File.read(path) do
      {:ok, bytes} -> {:ok, bytes}
      {:error, :enoent} -> {:error, :baseline_manifest_missing}
      {:error, _reason} -> {:error, :baseline_manifest_unreadable}
    end
  end

  defp baseline_repo_path(repo_root, manifest_path) do
    relative = Path.relative_to(manifest_path, repo_root)

    if relative == ".." or String.starts_with?(relative, "../"),
      do: {:error, :baseline_manifest_outside_repository},
      else: {:ok, relative}
  end

  defp baseline_path_is_tracked(repo_root, repo_path) do
    case git(repo_root, ["ls-files", "--error-unmatch", "--", repo_path]) do
      {:ok, _output} -> :ok
      {:error, _status, _output} -> {:error, :baseline_manifest_untracked}
    end
  end

  defp baseline_path_is_clean(repo_root, repo_path) do
    case git(repo_root, ["status", "--porcelain=v1", "--", repo_path]) do
      {:ok, ""} -> :ok
      {:ok, _changes} -> {:error, :baseline_manifest_dirty}
      {:error, _status, _output} -> {:error, :baseline_git_unavailable}
    end
  end

  defp resolve_baseline_commit(repo_root, repo_path, opts) do
    case Keyword.get(opts, :commit_sha) || System.get_env("RENDRO_CATALOG_BASELINE_COMMIT_SHA") do
      nil ->
        case git(repo_root, ["log", "-1", "--format=%H", "--", repo_path]) do
          {:ok, ""} -> {:error, :baseline_commit_unavailable}
          {:ok, sha} -> {:ok, sha}
          {:error, _status, _output} -> {:error, :baseline_commit_unavailable}
        end

      sha when is_binary(sha) ->
        {:ok, sha}

      _other ->
        {:error, :invalid_baseline_commit_sha}
    end
  end

  defp validate_full_commit_sha(sha) do
    if full_commit_sha?(sha), do: :ok, else: {:error, :invalid_baseline_commit_sha}
  end

  defp read_commit_blob(repo_root, commit_sha, repo_path) do
    case git(repo_root, ["show", "#{commit_sha}:#{repo_path}"], trim: false) do
      {:ok, blob} -> {:ok, blob}
      {:error, _status, _output} -> {:error, :baseline_commit_unavailable}
    end
  end

  defp git(repo_root, args, opts \\ []) do
    case System.cmd("git", args, cd: repo_root, stderr_to_stdout: true) do
      {output, 0} ->
        output = if Keyword.get(opts, :trim, true), do: String.trim(output), else: output
        {:ok, output}

      {output, status} ->
        {:error, status, String.trim(output)}
    end
  end

  defp workflow_run_attempt do
    case Integer.parse(System.get_env("GITHUB_RUN_ATTEMPT") || "1") do
      {attempt, ""} when attempt > 0 -> attempt
      _ -> 1
    end
  end

  defp full_commit_sha?(value),
    do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{40}\z/, value)

  defp sha256?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)

  defp with_pdfium(opts, fun) do
    case Keyword.get(opts, :pdfium) do
      nil ->
        fun.()

      path when is_binary(path) ->
        previous = Application.get_env(:rendro, :pdfium_cli_executable_finder)
        Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> path end)

        try do
          fun.()
        after
          if(previous,
            do: Application.put_env(:rendro, :pdfium_cli_executable_finder, previous),
            else: Application.delete_env(:rendro, :pdfium_cli_executable_finder)
          )
        end
    end
  end

  defp add_unless(errors, true, _message), do: errors
  defp add_unless(errors, false, message), do: errors ++ [message]
end

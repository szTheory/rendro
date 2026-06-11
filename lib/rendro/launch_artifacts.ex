defmodule Rendro.LaunchArtifacts do
  @moduledoc false

  alias Rendro.Document

  @asset_root "assets/rendro"
  @gallery_dir Path.join(@asset_root, "gallery")
  @manual_path Path.join(@asset_root, "manual.pdf")
  @manifest_path Path.join(@asset_root, "artifacts.json")
  @readme_path "README.md"
  @recipes_guide_path "guides/recipes.md"
  @pdfium_pin_path "priv/pdfium_pin.json"
  @dpi 96
  @schema_version 1
  @renderer_kind "pdfium-render"
  @generated_by "mix rendro.launch_artifacts.gen"
  @manual_source "Rendro.LaunchArtifacts.render_manual_pdf/0"
  @sha256_regex ~r/^[0-9a-f]{64}$/
  @gallery_required_keys ~w(id title recipe_module png_path png_sha256 source_pdf_sha256 page dpi width_px height_px renderer_kind renderer_version alt caption)
  @expected_gallery_dimensions %{
    "invoice" => {794, 1123},
    "branded_invoice" => {794, 1123},
    "statement" => {794, 1123},
    "receipt_report" => {794, 1123},
    "certificate" => {1123, 794}
  }

  @readme_start "<!-- rendro-launch-artifacts-start -->"
  @readme_end "<!-- rendro-launch-artifacts-end -->"
  @recipes_start "<!-- rendro-recipe-gallery-start -->"
  @recipes_end "<!-- rendro-recipe-gallery-end -->"

  @gallery_specs [
    %{
      id: "invoice",
      title: "Invoice",
      module: Rendro.Recipes.Invoice,
      png_path: Path.join(@gallery_dir, "invoice.png"),
      asset_name: :gallery_invoice,
      fit: {320, 452},
      alt: "Rendered invoice PDF showing invoice header, line-item table, and thank-you footer.",
      caption: "Standard invoice from Elixir data through the canonical Invoice recipe."
    },
    %{
      id: "branded_invoice",
      title: "Branded Invoice",
      module: Rendro.Recipes.BrandedInvoice,
      png_path: Path.join(@gallery_dir, "branded_invoice.png"),
      asset_name: :gallery_branded_invoice,
      fit: {320, 452},
      alt:
        "Rendered branded invoice PDF showing Rendro logo, embedded brand font, and invoice table.",
      caption: "Branded invoice with registered font and logo assets."
    },
    %{
      id: "statement",
      title: "Statement",
      module: Rendro.Recipes.Statement,
      png_path: Path.join(@gallery_dir, "statement.png"),
      asset_name: :gallery_statement,
      fit: {320, 452},
      alt:
        "Rendered account statement PDF showing transaction rows, running balances, and Page 1 of 2 footer.",
      caption: "Multi-page statement with carried-forward balances and running page numbers."
    },
    %{
      id: "receipt_report",
      title: "Receipt / Report",
      module: Rendro.Recipes.Receipt,
      png_path: Path.join(@gallery_dir, "receipt_report.png"),
      asset_name: :gallery_receipt_report,
      fit: {320, 452},
      alt:
        "Rendered receipt report PDF showing repeated table header, line items, totals, and Page 1 of 2 footer.",
      caption: "Receipt recipe scaled into a multi-page tabular report."
    },
    %{
      id: "certificate",
      title: "Certificate",
      module: Rendro.Recipes.Certificate,
      png_path: Path.join(@gallery_dir, "certificate.png"),
      asset_name: :gallery_certificate,
      fit: {390, 276},
      alt:
        "Rendered landscape certificate PDF showing recipient text and geometry-derived keyline border.",
      caption: "Landscape certificate with a Path-backed, geometry-derived border frame."
    }
  ]

  @spec asset_root() :: String.t()
  def asset_root, do: @asset_root

  @spec manifest_path() :: String.t()
  def manifest_path, do: @manifest_path

  @spec manual_path() :: String.t()
  def manual_path, do: @manual_path

  @spec readme_markers() :: {String.t(), String.t()}
  def readme_markers, do: {@readme_start, @readme_end}

  @spec recipes_markers() :: {String.t(), String.t()}
  def recipes_markers, do: {@recipes_start, @recipes_end}

  @spec gallery_specs() :: [map()]
  def gallery_specs, do: @gallery_specs

  @spec generate(keyword()) :: :ok | {:error, term()}
  def generate(opts \\ []) do
    with_pdfium(opts, fn ->
      with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
           :ok <- ensure_asset_dirs(),
           {:ok, gallery_entries} <- build_gallery_entries(renderer_version),
           {:ok, manual_sha256} <- write_manual_pdf(),
           {:ok, manifest} <- build_manifest(gallery_entries, manual_sha256, renderer_version),
           :ok <- write_manifest(manifest),
           :ok <- write_docs_blocks(manifest) do
        :ok
      end
    end)
  end

  @spec check(keyword()) :: :ok | {:error, [String.t()]}
  def check(opts \\ []) do
    with_pdfium(opts, fn ->
      manifest = read_manifest!()
      static_errors = static_contract_errors(manifest)

      raster_errors =
        case Rendro.Adapters.Pdfium.version() do
          {:ok, renderer_version} -> raster_contract_errors(manifest, renderer_version)
          {:error, reason} -> ["pdfium version check failed: #{inspect(reason)}"]
        end

      case static_errors ++ raster_errors do
        [] -> :ok
        errors -> {:error, errors}
      end
    end)
  end

  @spec static_contract_errors() :: [String.t()]
  def static_contract_errors do
    @manifest_path
    |> File.exists?()
    |> case do
      true -> static_contract_errors(read_manifest!())
      false -> ["missing launch artifact manifest: #{@manifest_path}"]
    end
  end

  @spec static_contract_errors(map()) :: [String.t()]
  def static_contract_errors(manifest) when is_map(manifest) do
    []
    |> collect_manifest_shape_errors(manifest)
    |> collect_asset_hash_errors(manifest)
    |> collect_source_pdf_errors(manifest)
    |> collect_manual_render_errors(manifest)
    |> collect_docs_block_errors(manifest)
  end

  @spec read_manifest!() :: map()
  def read_manifest! do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  @spec readme_block(map()) :: String.t()
  def readme_block(manifest) do
    gallery = Map.fetch!(manifest, "gallery")
    manual = Map.fetch!(manifest, "manual")

    images =
      gallery
      |> Enum.map(fn entry ->
        ~s|<a href="#{entry["png_path"]}"><img src="#{entry["png_path"]}" alt="#{entry["alt"]}" width="150"></a>|
      end)
      |> Enum.join("\n")

    """
    #{@readme_start}
    ## Rendered Recipe Gallery

    These previews are rendered by Rendro from deterministic recipe fixtures. Source PDFs are byte-checked by the docs contract; the PNG rasters are regenerated through the pinned `pdfium-render` advisory lane.

    <p>
    #{images}
    </p>

    Self-rendered manual: [manual.pdf](#{manual["path"]})

    SHA-256: `#{manual["sha256"]}`
    #{@readme_end}
    """
    |> String.trim()
  end

  @spec recipes_block(map()) :: String.t()
  def recipes_block(manifest) do
    gallery = Map.fetch!(manifest, "gallery")
    manual = Map.fetch!(manifest, "manual")

    entries =
      gallery
      |> Enum.map(fn entry ->
        """
        ### #{entry["title"]}

        <a href="#{entry["png_path"]}"><img src="#{entry["png_path"]}" alt="#{entry["alt"]}" width="320"></a>

        #{entry["caption"]}

        - Source PDF SHA-256: `#{entry["source_pdf_sha256"]}`
        - PNG SHA-256: `#{entry["png_sha256"]}`
        """
      end)
      |> Enum.join("\n")

    """
    #{@recipes_start}
    ## Rendered Gallery

    These images are generated from the current recipe code and recorded in `assets/rendro/artifacts.json`. The required docs contract byte-checks the source PDFs and manifest; the advisory pdfium lane regenerates the PNG rasters.

    #{entries}

    ## Self-Rendered Manual

    Rendro also renders its own compact launch manual: [manual.pdf](#{manual["path"]}).

    SHA-256: `#{manual["sha256"]}`
    #{@recipes_end}
    """
    |> String.trim()
  end

  @spec render_source_pdf(map()) :: {:ok, binary()} | {:error, term()}
  def render_source_pdf(%{id: "invoice"}) do
    render_doc(Rendro.Recipes.Invoice.document(invoice_data()))
  end

  def render_source_pdf(%{id: "branded_invoice"}) do
    render_doc(Rendro.Recipes.BrandedInvoice.document(branded_invoice_data()))
  end

  def render_source_pdf(%{id: "statement"}) do
    render_doc(Rendro.Recipes.Statement.document(statement_data(45)))
  end

  def render_source_pdf(%{id: "receipt_report"}) do
    render_doc(Rendro.Recipes.Receipt.document(receipt_data(58)))
  end

  def render_source_pdf(%{id: "certificate"}) do
    render_doc(Rendro.Recipes.Certificate.document(certificate_data(), border: true))
  end

  @spec render_manual_pdf() :: {:ok, binary()} | {:error, term()}
  def render_manual_pdf do
    render_doc(manual_document())
  end

  defp render_doc(%Rendro.Document{} = doc) do
    Rendro.render(doc, deterministic: true)
  end

  defp ensure_asset_dirs do
    File.mkdir_p!(@gallery_dir)
    :ok
  end

  defp build_gallery_entries(renderer_version) do
    entries =
      Enum.map(@gallery_specs, fn spec ->
        with {:ok, pdf} <- render_source_pdf(spec),
             {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1") do
          File.write!(spec.png_path, png)
          {width, height} = png_dimensions(png)

          {:ok,
           %{
             "id" => spec.id,
             "title" => spec.title,
             "recipe_module" => Atom.to_string(spec.module),
             "png_path" => spec.png_path,
             "png_sha256" => sha256(png),
             "source_pdf_sha256" => sha256(pdf),
             "page" => 1,
             "dpi" => @dpi,
             "width_px" => width,
             "height_px" => height,
             "renderer_kind" => @renderer_kind,
             "renderer_version" => renderer_version,
             "alt" => spec.alt,
             "caption" => spec.caption
           }}
        else
          {:error, reason} -> {:error, {spec.id, reason}}
          other -> {:error, {spec.id, other}}
        end
      end)

    split_results(entries)
  end

  defp write_manual_pdf do
    with {:ok, manual} <- render_manual_pdf() do
      File.write!(@manual_path, manual)
      {:ok, sha256(manual)}
    end
  end

  defp build_manifest(gallery_entries, manual_sha256, renderer_version) do
    pin = read_pdfium_pin()

    {:ok,
     %{
       "schema_version" => @schema_version,
       "generated_by" => @generated_by,
       "renderer" => %{
         "kind" => @renderer_kind,
         "version" => renderer_version,
         "dpi" => @dpi,
         "pin_path" => @pdfium_pin_path,
         "pin_version" => pin["version"],
         "pin_sha256" => pin["sha256"]
       },
       "manual" => %{
         "path" => @manual_path,
         "sha256" => manual_sha256,
         "source" => @manual_source
       },
       "gallery" => gallery_entries
     }}
  end

  defp write_manifest(manifest) do
    File.write!(@manifest_path, encode_manifest(manifest) <> "\n")
    :ok
  end

  defp write_docs_blocks(manifest) do
    replace_block!(@readme_path, @readme_start, @readme_end, readme_block(manifest))
    replace_block!(@recipes_guide_path, @recipes_start, @recipes_end, recipes_block(manifest))
    :ok
  end

  defp collect_manifest_shape_errors(errors, manifest) do
    expected_ids = Enum.map(@gallery_specs, & &1.id)
    renderer = manifest |> Map.get("renderer") |> map_or_empty()
    manual = manifest |> Map.get("manual") |> map_or_empty()
    gallery = manifest |> Map.get("gallery") |> list_or_empty()
    pin = read_pdfium_pin()

    errors
    |> add_error_unless(
      Map.get(manifest, "schema_version") == @schema_version,
      "schema_version must be #{@schema_version}"
    )
    |> add_error_unless(
      Map.get(manifest, "generated_by") == @generated_by,
      "generated_by must be #{@generated_by}"
    )
    |> add_error_unless(is_map(Map.get(manifest, "renderer")), "manifest renderer must be a map")
    |> add_error_unless(is_map(Map.get(manifest, "manual")), "manifest manual must be a map")
    |> add_error_unless(is_list(Map.get(manifest, "gallery")), "manifest gallery must be a list")
    |> add_error_unless(
      renderer["kind"] == @renderer_kind,
      "renderer.kind must be #{@renderer_kind}"
    )
    |> add_error_unless(renderer["dpi"] == @dpi, "renderer.dpi must be #{@dpi}")
    |> add_error_unless(
      renderer["pin_path"] == @pdfium_pin_path,
      "renderer.pin_path must be #{@pdfium_pin_path}"
    )
    |> add_error_unless(
      renderer["pin_version"] == pin["version"],
      "renderer.pin_version must match #{@pdfium_pin_path} version"
    )
    |> add_error_unless(
      sha256_hex?(renderer["pin_sha256"]),
      "renderer.pin_sha256 must be a lowercase 64-character SHA-256 hex digest"
    )
    |> add_error_unless(
      renderer["pin_sha256"] == pin["sha256"],
      "renderer.pin_sha256 must match #{@pdfium_pin_path} sha256"
    )
    |> add_error_unless(manual["path"] == @manual_path, "manual.path must be #{@manual_path}")
    |> add_error_unless(
      manual["source"] == @manual_source,
      "manual.source must be #{@manual_source}"
    )
    |> add_error_unless(
      sha256_hex?(manual["sha256"]),
      "manual.sha256 must be a lowercase 64-character SHA-256 hex digest"
    )
    |> add_error_unless(
      Enum.map(gallery, &entry_id/1) == expected_ids,
      "manifest gallery ids must be #{inspect(expected_ids)}"
    )
    |> Enum.concat(gallery_entry_shape_errors(gallery))
  end

  defp gallery_entry_shape_errors(gallery) do
    Enum.flat_map(gallery, fn
      entry when is_map(entry) ->
        label = entry["id"] || inspect(entry)
        expected_dimensions = @expected_gallery_dimensions[entry["id"]]

        @gallery_required_keys
        |> Enum.reject(&Map.has_key?(entry, &1))
        |> Enum.map(&"gallery #{label} missing #{&1}")
        |> add_error_unless(
          sha256_hex?(entry["png_sha256"]),
          "gallery #{label} png_sha256 must be a lowercase 64-character SHA-256 hex digest"
        )
        |> add_error_unless(
          sha256_hex?(entry["source_pdf_sha256"]),
          "gallery #{label} source_pdf_sha256 must be a lowercase 64-character SHA-256 hex digest"
        )
        |> add_error_unless(
          entry["renderer_kind"] == @renderer_kind,
          "gallery #{label} renderer_kind must be #{@renderer_kind}"
        )
        |> add_error_unless(entry["dpi"] == @dpi, "gallery #{label} dpi must be #{@dpi}")
        |> add_error_unless(entry["page"] == 1, "gallery #{label} page must be 1")
        |> add_error_unless(
          non_empty_string?(entry["alt"]),
          "gallery #{label} alt must be a non-empty string"
        )
        |> add_error_unless(
          non_empty_string?(entry["caption"]),
          "gallery #{label} caption must be a non-empty string"
        )
        |> add_error_unless(
          is_nil(expected_dimensions) or
            {entry["width_px"], entry["height_px"]} == expected_dimensions,
          "gallery #{label} dimensions must be #{format_dimensions(expected_dimensions)}"
        )

      entry ->
        ["gallery entry must be a map: #{inspect(entry)}"]
    end)
  end

  defp sha256_hex?(value), do: is_binary(value) and value =~ @sha256_regex

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp map_or_empty(value) when is_map(value), do: value
  defp map_or_empty(_value), do: %{}

  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []

  defp entry_id(entry) when is_map(entry), do: entry["id"]
  defp entry_id(_entry), do: nil

  defp format_dimensions(nil), do: "a known gallery size"
  defp format_dimensions({width, height}), do: "#{width}x#{height}"

  defp collect_asset_hash_errors(errors, manifest) do
    manual = manifest |> Map.get("manual") |> map_or_empty()
    gallery = manifest |> Map.get("gallery") |> list_or_empty()

    errors =
      errors ++
        file_hash_errors(manual["path"], manual["sha256"], "manual")

    Enum.reduce(gallery, errors, fn entry, acc ->
      acc ++ file_hash_errors(entry["png_path"], entry["png_sha256"], "gallery #{entry["id"]}")
    end)
  end

  defp collect_source_pdf_errors(errors, manifest) do
    entries_by_id =
      manifest
      |> Map.get("gallery")
      |> list_or_empty()
      |> Enum.filter(&is_map/1)
      |> Map.new(&{&1["id"], &1})

    Enum.reduce(@gallery_specs, errors, fn spec, acc ->
      entry = entries_by_id[spec.id]

      if is_map(entry) do
        case render_source_pdf(spec) do
          {:ok, pdf} ->
            actual = sha256(pdf)

            add_error_unless(
              acc,
              actual == entry["source_pdf_sha256"],
              "source PDF hash drift for #{spec.id}: expected #{entry["source_pdf_sha256"]}, got #{actual}; run mix rendro.launch_artifacts.gen"
            )

          {:error, reason} ->
            acc ++ ["source PDF render failed for #{spec.id}: #{inspect(reason)}"]
        end
      else
        acc ++ ["source PDF manifest entry missing for #{spec.id}"]
      end
    end)
  end

  defp collect_manual_render_errors(errors, manifest) do
    expected = manifest |> Map.get("manual") |> map_or_empty() |> Map.get("sha256")

    case render_manual_pdf() do
      {:ok, pdf} ->
        actual = sha256(pdf)

        add_error_unless(
          errors,
          actual == expected,
          "manual.pdf hash drift: expected #{expected}, got #{actual}; run mix rendro.launch_artifacts.gen"
        )

      {:error, reason} ->
        errors ++ ["manual.pdf render failed: #{inspect(reason)}"]
    end
  end

  defp collect_docs_block_errors(errors, manifest) do
    expected_readme = readme_block(manifest)
    expected_recipes = recipes_block(manifest)

    errors
    |> add_error_unless(
      extract_block(File.read!(@readme_path), @readme_start, @readme_end) == expected_readme,
      "README launch artifact block is stale; run mix rendro.launch_artifacts.gen"
    )
    |> add_error_unless(
      extract_block(File.read!(@recipes_guide_path), @recipes_start, @recipes_end) ==
        expected_recipes,
      "guides/recipes.md rendered gallery block is stale; run mix rendro.launch_artifacts.gen"
    )
  end

  defp raster_contract_errors(manifest, renderer_version) do
    entries_by_id =
      manifest
      |> Map.get("gallery")
      |> list_or_empty()
      |> Enum.filter(&is_map/1)
      |> Map.new(&{&1["id"], &1})

    Enum.flat_map(@gallery_specs, fn spec ->
      entry = entries_by_id[spec.id]

      if is_map(entry) do
        with {:ok, pdf} <- render_source_pdf(spec),
             {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1") do
          {width, height} = png_dimensions(png)
          actual = sha256(png)

          []
          |> add_error_unless(
            actual == entry["png_sha256"],
            "PNG hash drift for #{spec.id}: expected #{entry["png_sha256"]}, got #{actual}"
          )
          |> add_error_unless(
            width == entry["width_px"] and height == entry["height_px"],
            "PNG dimensions drift for #{spec.id}: expected #{entry["width_px"]}x#{entry["height_px"]}, got #{width}x#{height}"
          )
          |> add_error_unless(
            renderer_version == entry["renderer_version"],
            "renderer version drift for #{spec.id}: expected #{entry["renderer_version"]}, got #{renderer_version}"
          )
        else
          {:error, reason} -> ["PNG regeneration failed for #{spec.id}: #{inspect(reason)}"]
          other -> ["PNG regeneration failed for #{spec.id}: #{inspect(other)}"]
        end
      else
        ["PNG manifest entry missing for #{spec.id}"]
      end
    end)
  end

  defp file_hash_errors(nil, _hash, label), do: ["#{label} path missing in manifest"]
  defp file_hash_errors(_path, nil, label), do: ["#{label} sha256 missing in manifest"]

  defp file_hash_errors(path, expected, label) do
    cond do
      not File.exists?(path) ->
        ["#{label} file missing: #{path}"]

      true ->
        actual = path |> File.read!() |> sha256()

        if actual == expected do
          []
        else
          [
            "#{label} hash drift for #{path}: expected #{expected}, got #{actual}; run mix rendro.launch_artifacts.gen"
          ]
        end
    end
  end

  defp manual_document do
    template =
      Rendro.page_template(
        name: :manual,
        width: 595.28,
        height: 841.89,
        margin_top: 54,
        margin_right: 54,
        margin_bottom: 54,
        margin_left: 54,
        regions: [
          Rendro.region(
            name: :body,
            role: :body,
            anchor: :flow,
            x: 54,
            y: 54,
            width: 487.28,
            height: 690
          ),
          Rendro.region(
            name: :footer,
            role: :footer,
            anchor: :bottom,
            x: 54,
            y: 770,
            width: 487.28,
            height: 20
          )
        ]
      )

    base_doc =
      Document.new()
      |> Document.add_template(template)
      |> Document.set_template(:manual)

    base_doc =
      Enum.reduce(@gallery_specs, base_doc, fn spec, doc ->
        Document.register_image(doc, spec.asset_name, {:path, spec.png_path})
      end)

    body =
      Rendro.section(
        name: :manual_body,
        region: :body,
        content: manual_blocks()
      )

    footer =
      Rendro.section(
        name: :manual_footer,
        region: :footer,
        content: [
          Rendro.page_number(
            format: "Rendro manual - Page {{page_number}} of {{total_pages}}",
            size: 9,
            color: {31, 41, 55}
          )
        ]
      )

    base_doc
    |> Document.add_section(body)
    |> Document.add_section(footer)
  end

  defp manual_blocks do
    ([
       manual_page([
         heading("Native PDF layout for Elixir", 26),
         body_text("Rendro renders deterministic business PDFs from Elixir data."),
         body_text("No Chrome, browser automation, or hidden webpage layout step."),
         spacer(12),
         path_rule({44, 107, 237}, 2.0),
         spacer(16),
         body_text("Generated by Rendro itself from the same public recipe pipeline."),
         body_text("The SHA-256 is published outside this PDF for byte checks."),
         body_text("Use this manual as a fit check; use HexDocs for API reference.")
       ]),
       manual_page([
         heading("Fit Check", 20),
         body_text("Use Rendro when your app owns structured document data."),
         body_text("Good fits: invoices, statements, receipts, reports, certificates."),
         body_text("Use HTML-to-PDF when browser CSS fidelity is the requirement."),
         spacer(10),
         subheading("Boundaries"),
         body_text("No arbitrary HTML/CSS rendering. No blanket PDF/A or PDF/UA claim."),
         body_text("Pdfium rasters are not GUI-viewer proof."),
         body_text("Complex scripts require the shaping seam."),
         body_text("Transforms, clipping, and gradients remain deferred path work.")
       ])
     ] ++
       Enum.map(@gallery_specs, &recipe_page/1) ++
       [
         [
           heading("Determinism Proof", 20),
           body_text("The checked-in manifest records source PDF hashes and PNG hashes."),
           body_text("It also records renderer metadata and this manual hash."),
           body_text("Run mix rendro.launch_artifacts.check in a pinned pdfium environment."),
           body_text("The task regenerates and compares the full artifact set."),
           spacer(14),
           subheading("Path primitive proof"),
           body_text("The certificate frame and diagram are authored as Rendro Path data."),
           body_text("Both render through the same standard pipeline."),
           spacer(8),
           path_diagram(),
           spacer(14),
           body_text("The required docs contract checks source PDFs and the manual."),
           body_text("The advisory raster lane checks PNG raster drift.")
         ]
       ])
    |> flatten_pages()
  end

  defp recipe_page(spec) do
    [
      heading(spec.title, 20),
      body_text(spec.caption),
      spacer(8),
      Rendro.Component.image(spec.asset_name, fit: spec.fit),
      spacer(8),
      body_text("Rendered from #{inspect(spec.module)} with deterministic: true."),
      body_text("Recorded in assets/rendro/artifacts.json.")
    ]
  end

  defp manual_page(blocks), do: blocks

  defp flatten_pages(pages) do
    pages
    |> Enum.with_index()
    |> Enum.flat_map(fn {blocks, index} ->
      if index == length(pages) - 1 do
        blocks
      else
        mark_break_after(blocks)
      end
    end)
  end

  defp mark_break_after([]), do: []

  defp mark_break_after(blocks) do
    {last, rest_reversed} = blocks |> Enum.reverse() |> List.pop_at(0)
    Enum.reverse([%{last | break_after: true} | rest_reversed])
  end

  defp heading(text, size), do: Rendro.block(Rendro.text(text, size: size, color: {16, 24, 39}))
  defp subheading(text), do: Rendro.block(Rendro.text(text, size: 13, color: {44, 107, 237}))
  defp body_text(text), do: Rendro.block(Rendro.text(text, size: 10.5, color: {31, 41, 55}))
  defp spacer(size), do: Rendro.block(Rendro.text(" ", size: size))

  defp path_rule(color, width) do
    Rendro.path([{:move, 0, 4}, {:line, 440, 4}],
      width: 440,
      height: 8,
      stroke: %{color: color, width: width}
    )
  end

  defp path_diagram do
    Rendro.path(
      [
        {:rect, 0, 0, 440, 110},
        {:move, 40, 30},
        {:line, 400, 30},
        {:move, 40, 60},
        {:line, 400, 60},
        {:move, 40, 90},
        {:line, 280, 90}
      ],
      width: 440,
      height: 120,
      stroke: %{color: {14, 124, 118}, width: 1.2, dash: [6, 4]}
    )
  end

  defp invoice_data do
    %{
      id: "INV-2026-001",
      date: ~D[2026-06-11],
      items: [
        %{name: "Implementation Sprint", qty: 2, price: 2400},
        %{name: "Support Retainer", qty: 1, price: 800},
        %{name: "Validation Report", qty: 1, price: 450}
      ]
    }
  end

  defp branded_invoice_data do
    invoice_data()
    |> Map.put(:id, "BR-2026-001")
    |> Map.put(:brand, %{font_name: :brand_heading, logo_name: :company_logo})
  end

  defp statement_data(n) do
    opening = Decimal.new("1000.00")

    lines =
      for i <- 1..n do
        amount = if rem(i, 2) == 1, do: Decimal.new("100.00"), else: Decimal.new("-50.00")

        %{
          date: Date.add(~D[2026-05-01], i - 1),
          description: "Transaction #{i}",
          amount: amount
        }
      end

    %{
      period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      account: %{name: "Acme Corp"},
      opening_balance: opening,
      lines: lines
    }
  end

  defp receipt_data(n) do
    lines =
      for i <- 1..n do
        %{description: "Report line #{i}", amount: Decimal.new("10.00")}
      end

    subtotal = Decimal.mult(Decimal.new("10.00"), Decimal.new(n))

    %{
      title: "Payment Receipt",
      date: ~D[2026-06-11],
      customer: %{name: "Acme Corp"},
      lines: lines,
      totals: %{subtotal: subtotal, total: subtotal}
    }
  end

  defp certificate_data do
    %{
      title: "Certificate of Completion",
      recipient: "Jane Smith",
      body: "For shipping deterministic PDFs from composable Elixir data.",
      date: ~D[2026-06-11],
      seal_line: "Generated by Rendro"
    }
  end

  defp split_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, value}, {:ok, acc} -> {:cont, {:ok, acc ++ [value]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
  end

  defp encode_manifest(manifest) do
    gallery =
      manifest["gallery"]
      |> Enum.map(&ordered_gallery_entry/1)

    ordered =
      ordered_object([
        {"schema_version", manifest["schema_version"]},
        {"generated_by", manifest["generated_by"]},
        {"renderer",
         ordered_object([
           {"kind", manifest["renderer"]["kind"]},
           {"version", manifest["renderer"]["version"]},
           {"dpi", manifest["renderer"]["dpi"]},
           {"pin_path", manifest["renderer"]["pin_path"]},
           {"pin_version", manifest["renderer"]["pin_version"]},
           {"pin_sha256", manifest["renderer"]["pin_sha256"]}
         ])},
        {"manual",
         ordered_object([
           {"path", manifest["manual"]["path"]},
           {"sha256", manifest["manual"]["sha256"]},
           {"source", manifest["manual"]["source"]}
         ])},
        {"gallery", gallery}
      ])

    Jason.encode!(ordered, pretty: true)
  end

  defp ordered_gallery_entry(entry) do
    ordered_object([
      {"id", entry["id"]},
      {"title", entry["title"]},
      {"recipe_module", entry["recipe_module"]},
      {"png_path", entry["png_path"]},
      {"png_sha256", entry["png_sha256"]},
      {"source_pdf_sha256", entry["source_pdf_sha256"]},
      {"page", entry["page"]},
      {"dpi", entry["dpi"]},
      {"width_px", entry["width_px"]},
      {"height_px", entry["height_px"]},
      {"renderer_kind", entry["renderer_kind"]},
      {"renderer_version", entry["renderer_version"]},
      {"alt", entry["alt"]},
      {"caption", entry["caption"]}
    ])
  end

  defp ordered_object(values), do: %Jason.OrderedObject{values: values}

  defp png_dimensions(
         <<137, 80, 78, 71, 13, 10, 26, 10, _len::32, "IHDR", width::32, height::32,
           _rest::binary>>
       ),
       do: {width, height}

  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp add_error_unless(errors, true, _message), do: errors
  defp add_error_unless(errors, false, message), do: errors ++ [message]

  defp read_pdfium_pin do
    @pdfium_pin_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp replace_block!(path, start_marker, end_marker, replacement) do
    content = File.read!(path)

    case {String.contains?(content, start_marker), String.contains?(content, end_marker)} do
      {true, true} ->
        updated =
          Regex.replace(
            ~r/#{Regex.escape(start_marker)}.*?#{Regex.escape(end_marker)}/s,
            content,
            replacement
          )

        File.write!(path, updated)

      _ ->
        raise ArgumentError,
              "#{path} is missing generated block markers #{start_marker} / #{end_marker}"
    end
  end

  defp extract_block(content, start_marker, end_marker) do
    pattern = ~r/#{Regex.escape(start_marker)}.*?#{Regex.escape(end_marker)}/s

    case Regex.run(pattern, content) do
      [block] -> String.trim(block)
      _ -> nil
    end
  end

  defp with_pdfium(opts, fun) do
    pdfium = Keyword.get(opts, :pdfium) || System.get_env("RENDRO_PDFIUM_CLI")

    if is_binary(pdfium) and pdfium != "" do
      previous = Application.get_env(:rendro, :pdfium_cli_executable_finder)

      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn
        "pdfium-cli" -> pdfium
        "pdfium" -> pdfium
        _ -> nil
      end)

      try do
        fun.()
      after
        if previous do
          Application.put_env(:rendro, :pdfium_cli_executable_finder, previous)
        else
          Application.delete_env(:rendro, :pdfium_cli_executable_finder)
        end
      end
    else
      fun.()
    end
  end
end

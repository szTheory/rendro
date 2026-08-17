defmodule Rendro.Catalog do
  @moduledoc false

  @asset_root "assets/rendro/catalog"
  @manifest_path "assets/rendro/catalog.json"
  @pdfium_pin_path "priv/pdfium_pin.json"
  @dpi 96
  @schema_version 1
  @renderer_kind "pdfium-render"
  @generated_by "mix rendro.catalog.gen"
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
    doc = Map.fetch!(spec, :recipe_module).document(data, theme: theme)

    if preset = Map.get(spec, :preset_atom),
      do: Rendro.Theme.Presets.register_fonts(doc, preset),
      else: doc
  end

  @spec render_source_pdf(map()) :: {:ok, binary()} | {:error, term()}
  def render_source_pdf(spec) do
    spec
    |> source_document_for()
    |> Rendro.render(deterministic: true)
  end

  @spec generate(keyword()) :: :ok | {:error, term()}
  def generate(opts \\ []) do
    with_pdfium(opts, fn ->
      with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
           :ok <- File.mkdir_p(@asset_root),
           {:ok, cells} <- build_cells(renderer_version),
           :ok <-
             File.write(
               @manifest_path,
               encode_manifest(build_manifest(cells, renderer_version)) <> "\n"
             ) do
        :ok
      end
    end)
  end

  @spec check(keyword()) :: :ok | {:error, [String.t()]}
  def check(opts \\ []) do
    with_pdfium(opts, fn ->
      errors = static_contract_errors()

      errors =
        if errors == [] do
          manifest = read_manifest!()
          errors ++ rendered_contract_errors(manifest)
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
  def static_contract_errors(manifest) when is_map(manifest) do
    manifest_shape_errors(manifest) ++ catalog_contract_errors(catalog_specs())
  end

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
    do: Rendro.Theme.preset(preset, accent: accent, mode: String.to_existing_atom(mode))

  defp recipe_module(:invoice), do: Rendro.Recipes.Invoice
  defp recipe_module(:statement), do: Rendro.Recipes.Statement
  defp recipe_module(:receipt), do: Rendro.Recipes.Receipt
  defp recipe_module(:certificate), do: Rendro.Recipes.Certificate
  defp recipe_module(:payslip), do: Rendro.Recipes.Payslip
  defp recipe_module(:ticket), do: Rendro.Recipes.Ticket

  defp build_cells(renderer_version) do
    catalog_specs()
    |> Enum.map(fn spec ->
      with {:ok, pdf} <- render_source_pdf(spec),
           {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1"),
           :ok <- File.mkdir_p(Path.dirname(spec.png_path)),
           :ok <- File.write(spec.png_path, png) do
        {width, height} = png_dimensions(png)

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

  defp build_manifest(cells, renderer_version) do
    pin = read_pdfium_pin()

    %{
      "schema_version" => @schema_version,
      "generated_by" => @generated_by,
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

  defp rendered_contract_errors(manifest) do
    cells = Map.new(manifest["cells"], &{&1["id"], &1})

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

  defp cell_shape_errors(cell) when is_map(cell) do
    id = cell["id"] || inspect(cell)

    required =
      ~w(id family brand preset theme accent mode recipe_module fixture_ref png_path png_sha256 source_pdf_sha256 page page_count dpi width_px height_px renderer_kind renderer_version alt caption preview_copy)

    Enum.map(required -- Map.keys(cell), &"catalog #{id}: missing #{&1}")
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
      "caption" => spec.caption
    }
  end

  defp encode_manifest(manifest), do: Jason.encode!(manifest, pretty: true)
  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
  defp page_count(pdf), do: :binary.matches(pdf, "/Type /Page") |> length()

  defp png_dimensions(
         <<137, 80, 78, 71, 13, 10, 26, 10, _::binary-size(8), width::32, height::32, _::binary>>
       ), do: {width, height}

  defp read_pdfium_pin, do: @pdfium_pin_path |> File.read!() |> JSON.decode!()

  defp split_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, value}, {:ok, acc} -> {:cont, {:ok, acc ++ [value]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
  end

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

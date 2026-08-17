defmodule Rendro.Catalog do
  @moduledoc false

  @asset_root "assets/rendro/catalog"
  @manifest_path "assets/rendro/catalog.json"
  # This list is intentionally literal and ordered. It is the only membership
  # source; fixture discovery may validate a row but must never add one.
  @catalog_specs [
    {:invoice, "default", "default", "light", "invoice/acme-phoenix-saas/invoice.json", nil, nil},
    {:invoice, "northline-logistics", "swiss", "light", "invoice/northline-logistics/invoice.json", "#2C6BED", :swiss},
    {:invoice, "northline-logistics", "swiss", "dark", "invoice/northline-logistics/invoice.json", "#2C6BED", :swiss},
    {:invoice, "cedar-mutual", "corporate-classic", "light", "invoice/cedar-mutual/invoice.json", "#1F4FB8", :corporate_classic},
    {:invoice, "cedar-mutual", "corporate-classic", "dark", "invoice/cedar-mutual/invoice.json", "#1F4FB8", :corporate_classic},
    {:statement, "default", "default", "light", "statement/northwind-ledger-co/statement.json", nil, nil},
    {:statement, "signal-ledger", "minimal-mono", "light", "statement/signal-ledger/statement.json", "#0E7C76", :minimal_mono},
    {:statement, "signal-ledger", "minimal-mono", "dark", "statement/signal-ledger/statement.json", "#0E7C76", :minimal_mono},
    {:statement, "aster-research-fund", "editorial", "light", "statement/aster-research-fund/statement.json", "#6E3CB8", :editorial},
    {:statement, "aster-research-fund", "editorial", "dark", "statement/aster-research-fund/statement.json", "#6E3CB8", :editorial},
    {:receipt, "default", "default", "light", "receipt/harbor-and-oak-cafe/receipt.json", nil, nil},
    {:receipt, "poppy-and-grain", "humanist", "light", "receipt/poppy-and-grain/receipt.json", "#147A4B", :humanist},
    {:receipt, "poppy-and-grain", "humanist", "dark", "receipt/poppy-and-grain/receipt.json", "#147A4B", :humanist},
    {:receipt, "circuit-supply-co", "minimal-mono", "light", "receipt/circuit-supply-co/receipt.json", "#2C6BED", :minimal_mono},
    {:receipt, "circuit-supply-co", "minimal-mono", "dark", "receipt/circuit-supply-co/receipt.json", "#2C6BED", :minimal_mono},
    {:certificate, "default", "default", "light", "certificate/summit-training-institute/certificate.json", nil, nil},
    {:certificate, "aster-institute", "swiss", "light", "certificate/aster-institute/certificate.json", "#1F4FB8", :swiss},
    {:certificate, "aster-institute", "swiss", "dark", "certificate/aster-institute/certificate.json", "#1F4FB8", :swiss},
    {:certificate, "meridian-arts-fellowship", "editorial", "light", "certificate/meridian-arts-fellowship/certificate.json", "#6E3CB8", :editorial},
    {:certificate, "meridian-arts-fellowship", "editorial", "dark", "certificate/meridian-arts-fellowship/certificate.json", "#6E3CB8", :editorial},
    {:payslip, "default", "default", "light", "payslip/aurora-live/payslip.json", nil, nil},
    {:payslip, "northline-logistics", "swiss", "light", "payslip/northline-logistics/payslip.json", "#2C6BED", :swiss},
    {:payslip, "northline-logistics", "swiss", "dark", "payslip/northline-logistics/payslip.json", "#2C6BED", :swiss},
    {:payslip, "cedar-mutual", "corporate-classic", "light", "payslip/cedar-mutual/payslip.json", "#1F4FB8", :corporate_classic},
    {:payslip, "cedar-mutual", "corporate-classic", "dark", "payslip/cedar-mutual/payslip.json", "#1F4FB8", :corporate_classic},
    {:ticket, "default", "default", "light", "ticket/aurora-live/ticket.json", nil, nil},
    {:ticket, "field-notes-conference", "minimal-mono", "light", "ticket/field-notes-conference/ticket.json", "#0E7C76", :minimal_mono},
    {:ticket, "field-notes-conference", "minimal-mono", "dark", "ticket/field-notes-conference/ticket.json", "#0E7C76", :minimal_mono},
    {:ticket, "the-letterpress-hall", "editorial", "light", "ticket/the-letterpress-hall/ticket.json", "#C24132", :editorial},
    {:ticket, "the-letterpress-hall", "editorial", "dark", "ticket/the-letterpress-hall/ticket.json", "#C24132", :editorial},
    {:ticket, "aurora-live", "brutalist", "light", "ticket/aurora-live/ticket.json", "#C78600", :brutalist},
    {:ticket, "aurora-live", "brutalist", "dark", "ticket/aurora-live/ticket.json", "#C78600", :brutalist}
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
        id: id, family: family, brand: if(brand == "default", do: nil, else: brand),
        preset: if(preset == "default", do: nil, else: preset),
        theme: if(preset_atom, do: "preset", else: "default"), accent: accent, mode: mode,
        recipe_module: recipe_module(family), fixture_ref: fixture_ref,
        png_path: Path.join([@asset_root, Atom.to_string(family), brand, "#{preset}-#{mode}.png"]),
        alt: "#{String.capitalize(Atom.to_string(family))} #{brand} #{mode} catalog preview.",
        caption: "#{String.capitalize(Atom.to_string(family))} #{brand} #{preset} #{mode} catalog cell.",
        preset_atom: preset_atom
      }
    end)
  end

  @spec source_document_for(map()) :: Rendro.Document.t()
  def source_document_for(spec) when is_map(spec) do
    fixture_ref = Map.fetch!(spec, :fixture_ref)
    validate_safe_path!(fixture_ref, "fixture")

    if Map.has_key?(spec, :png_path), do: validate_safe_path!(Map.fetch!(spec, :png_path), "asset")
    family = Map.fetch!(spec, :family)
    data = fixture_ref |> Rendro.Examples.load!() |> then(&Rendro.ExamplesData.transform(family, &1))
    theme = theme_for(spec)
    doc = Map.fetch!(spec, :recipe_module).document(data, theme: theme)
    if preset = Map.get(spec, :preset_atom), do: Rendro.Theme.Presets.register_fonts(doc, preset), else: doc
  end

  @spec render_source_pdf(map()) :: {:ok, binary()} | {:error, term()}
  def render_source_pdf(spec) do
    spec
    |> source_document_for()
    |> Rendro.render(deterministic: true)
  end

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

  defp add_unless(errors, true, _message), do: errors
  defp add_unless(errors, false, message), do: errors ++ [message]
end

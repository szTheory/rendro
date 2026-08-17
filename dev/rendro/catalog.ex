defmodule Rendro.Catalog do
  @moduledoc false

  @asset_root "assets/rendro/catalog"
  @manifest_path "assets/rendro/catalog.json"
  @default_invoice %{
    id: "invoice--default--default--light",
    family: :invoice,
    brand: nil,
    preset: nil,
    theme: "default",
    accent: nil,
    mode: "light",
    recipe_module: Rendro.Recipes.Invoice,
    fixture_ref: "invoice/acme-phoenix-saas/invoice.json",
    png_path: "assets/rendro/catalog/invoice/default/default-light.png",
    alt: "Default Invoice preview with customer, line items, and total due.",
    caption: "Default Invoice baseline rendered from the Acme Phoenix SaaS fixture."
  }

  @spec asset_root() :: String.t()
  def asset_root, do: @asset_root

  @spec manifest_path() :: String.t()
  def manifest_path, do: @manifest_path

  @spec catalog_specs() :: [map()]
  def catalog_specs, do: [@default_invoice]

  @spec source_document_for(map()) :: Rendro.Document.t()
  def source_document_for(spec) when is_map(spec) do
    fixture_ref = Map.fetch!(spec, :fixture_ref)
    validate_safe_path!(fixture_ref, "fixture")

    data = fixture_ref |> Rendro.Examples.load!() |> then(&Rendro.ExamplesData.transform(:invoice, &1))
    Rendro.Recipes.Invoice.document(data, theme: Rendro.Theme.default())
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
end

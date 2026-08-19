defmodule Rendro.Theme.SnippetTest do
  use ExUnit.Case, async: true

  alias Rendro.Document
  alias Rendro.Theme.Snippet

  test "formats the Invoice Swiss light tracer as a working document fragment" do
    snippet = Snippet.usage_snippet("invoice", "swiss", "#2C6BED", "light")

    assert snippet == """
           preset = :swiss

           theme =
             Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

           document =
             invoice
             |> Rendro.Recipes.Invoice.document(theme: theme)
             |> Rendro.Theme.Presets.register_fonts(preset)
           """

    assert Code.string_to_quoted!(snippet)

    {document, _binding} =
      Code.eval_string(snippet, invoice: %{id: "INV-128", date: ~D[2026-08-18], items: []})

    assert %Document{} = document
  end

  test "owns the complete closed vocabulary in a deterministic index" do
    index = Snippet.index_json()
    assert index == Snippet.index_json()

    decoded = JSON.decode!(index)
    assert decoded["schema_version"] == 1
    assert decoded["generated_by"] == "mix rendro.configurator.gen"

    assert Enum.map(decoded["options"]["families"], & &1["value"]) ==
             ~w(invoice statement receipt certificate payslip ticket)

    assert length(decoded["options"]["presets"]) == 6
    assert length(decoded["options"]["accents"]) == 7
    assert Enum.map(decoded["options"]["modes"], & &1["value"]) == ~w(light dark)
    assert length(decoded["records"]) == 504
    assert Enum.uniq_by(decoded["records"], & &1["key"]) == decoded["records"]
    assert Enum.uniq_by(decoded["records"], & &1["snippet"]) == decoded["records"]
    assert File.read!("assets/rendro/configurator/index.json") == index
  end

  test "every committed formatter string is trusted, fresh, parseable, and executable" do
    decoded = Snippet.index_json() |> JSON.decode!()
    bindings = family_bindings()

    Enum.each(decoded["records"], fn record ->
      assert record["snippet"] ==
               Snippet.usage_snippet(
                 record["family"],
                 record["preset"],
                 record["accent"],
                 record["mode"]
               )

      assert Code.string_to_quoted!(record["snippet"])
      {document, _binding} = Code.eval_string(record["snippet"], bindings[record["family"]])
      assert %Document{} = document
    end)
  end

  test "module source shares the canonical preset serialization and font bridge" do
    source = Snippet.module_source("MyApp.RendroTheme", "editorial", "#0E7C76", "dark")

    assert source =~ "Rendro.Theme.preset(:editorial, accent: {14, 124, 118}, mode: :dark)"
    assert source =~ "Rendro.Theme.Presets.register_fonts(document, :editorial)"
    assert Code.string_to_quoted!(source)
  end

  test "representative family snippets render after their explicit font bridge" do
    bindings = family_bindings()

    for family <- ~w(invoice statement receipt certificate payslip ticket) do
      snippet = Snippet.usage_snippet(family, "swiss", "#2C6BED", "light")
      {document, _binding} = Code.eval_string(snippet, bindings[family])

      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert pdf =~ "%PDF-"
    end
  end

  test "rejects values outside the closed source vocabulary without creating atoms" do
    for {function, args} <- [
          {:usage_snippet, ["Invoice", "swiss", "#2C6BED", "light"]},
          {:usage_snippet, ["invoice", "Swiss", "#2C6BED", "light"]},
          {:usage_snippet, ["invoice", "swiss", "#2c6bed", "light"]},
          {:usage_snippet, ["invoice", "swiss", "#2C6BED", "LIGHT"]}
        ] do
      assert_raise ArgumentError, fn -> apply(Snippet, function, args) end
    end
  end

  defp family_bindings do
    Rendro.Catalog.catalog_specs()
    |> Enum.uniq_by(& &1.family)
    |> Map.new(fn spec ->
      data =
        spec.fixture_ref
        |> Rendro.Examples.load!()
        |> then(&Rendro.ExamplesData.transform(spec.family, &1))

      {Atom.to_string(spec.family), [{spec.family, data}]}
    end)
  end
end

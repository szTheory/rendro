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
end

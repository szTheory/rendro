defmodule Rendro.DocsContract.PresetsClaimsTest do
  use ExUnit.Case, async: true

  alias Rendro.Theme.Snippet

  @capability_keys [
    "strict_six_preset_constructors",
    "deterministic_rendering",
    "explicit_font_registration",
    "bounded_catalog_previews",
    "canonical_snippet_and_codegen",
    "focused_livebook_example"
  ]

  @boundary_keys [
    "design_quality_guarantee",
    "accessibility_pdf_ua_guarantee",
    "wcag_contrast_guarantee",
    "print_safety_guarantee",
    "universal_viewer_fidelity_guarantee",
    "exhaustive_catalog_coverage",
    "live_arbitrary_preview"
  ]

  @forbidden_terms [
    "design_quality",
    "accessibility",
    "pdf_ua",
    "pdf-ua",
    "wcag",
    "print",
    "universal_viewer",
    "exhaustive_catalog",
    "live_arbitrary_preview"
  ]

  @boundary_sentence "Each preset is a strong starting point: choose a style, supply your accent, and review the rendered document for your content. Presets are not design-quality, accessibility, PDF/UA, WCAG, or print-safety guarantees."

  defp extract_marked_snippet!(guide) do
    [_, snippet] =
      Regex.run(~r/# rendro-theme-snippet:start\n(.*?)# rendro-theme-snippet:end/s, guide)

    snippet
  end

  defp flatten_string_leaves(map, prefix \\ "") do
    Enum.flat_map(map, fn {key, value} ->
      path = if prefix == "", do: to_string(key), else: "#{prefix}.#{key}"

      case value do
        %{} = nested -> flatten_string_leaves(nested, path)
        leaf when is_binary(leaf) -> [{path, leaf}]
        _ -> []
      end
    end)
  end

  defp promoted_boundary?(presets) do
    presets
    |> flatten_string_leaves()
    |> Enum.any?(fn {path, value} ->
      Enum.any?(@forbidden_terms, &String.contains?(path, &1)) and value != "unsupported"
    end)
  end

  defp index_of(binary, substring) do
    case :binary.match(binary, substring) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  describe "tripwire integrity" do
    test "required key and forbidden-term lists are non-empty" do
      refute @capability_keys == [], "capability list must not be empty (guard would be vacuous)"
      refute @boundary_keys == [], "boundary list must not be empty (guard would be vacuous)"
      refute @forbidden_terms == [], "forbidden-term list must not be empty (guard would be vacuous)"
    end

    test "predicate fails when a boundary is promoted" do
      assert promoted_boundary?(%{
               "boundaries" => %{"print_safety_guarantee" => "supported"}
             })
    end

    test "predicate permits explicitly unsupported boundaries" do
      refute promoted_boundary?(%{
               "boundaries" => %{
                 "print_safety_guarantee" => "unsupported",
                 "wcag_contrast_guarantee" => "unsupported"
               }
             })
    end
  end

  describe "canonical preset public claim" do
    setup do
      guide = File.read!("guides/presets.md")
      matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()
      {:ok, guide: guide, presets: matrix["theming"]["presets"]}
    end

    test "the marker-bounded guide source is the formatter-owned Invoice Swiss light snippet and evaluates with the realistic fixture",
         %{guide: guide} do
      snippet = extract_marked_snippet!(guide)

      assert snippet == Snippet.usage_snippet("invoice", "swiss", "#2C6BED", "light")
      assert Code.string_to_quoted!(snippet)

      invoice =
        "invoice/acme-phoenix-saas/invoice.json"
        |> Rendro.Examples.load!()
        |> Rendro.ExamplesData.transform_invoice()

      {document, _binding} = Code.eval_string(snippet, invoice: invoice)

      assert document.__struct__ == Rendro.Document
      assert snippet =~ "Rendro.Theme.preset"
      assert snippet =~ "Rendro.Theme.Presets.register_fonts"
      assert index_of(snippet, "Rendro.Theme.preset") <
               index_of(snippet, "Rendro.Theme.Presets.register_fonts")
    end

    test "the exact strong-starting-point boundary follows the canonical example", %{guide: guide} do
      snippet_end = index_of(guide, "# rendro-theme-snippet:end")
      boundary_start = index_of(guide, @boundary_sentence)

      assert snippet_end != nil
      assert boundary_start != nil
      assert snippet_end < boundary_start
    end

    test "support matrix proves every capability and keeps every guarantee boundary unsupported",
         %{presets: presets} do
      assert presets["status"] == "supported"
      assert is_map(presets["capabilities"])
      assert is_map(presets["boundaries"])

      for key <- @capability_keys do
        assert presets["capabilities"][key] == "supported",
               "expected theming.presets.capabilities.#{key} to be supported"
      end

      for key <- @boundary_keys do
        assert presets["boundaries"][key] == "unsupported",
               "expected theming.presets.boundaries.#{key} to be unsupported"
      end

      refute promoted_boundary?(presets)
    end

    test "removing a required capability or boundary fails the required-key predicates", %{presets: presets} do
      missing_capability = put_in(presets, ["capabilities"], Map.delete(presets["capabilities"], hd(@capability_keys)))
      missing_boundary = put_in(presets, ["boundaries"], Map.delete(presets["boundaries"], hd(@boundary_keys)))

      refute Enum.all?(@capability_keys, &Map.has_key?(missing_capability["capabilities"], &1))
      refute Enum.all?(@boundary_keys, &Map.has_key?(missing_boundary["boundaries"], &1))
    end
  end
end

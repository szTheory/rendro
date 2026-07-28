defmodule Rendro.DocsContract.ThemingClaimsTest do
  use ExUnit.Case, async: true

  # D-09 theming-overclaim tripwire.
  #
  # The milestone's honesty line: dark mode is a screen-oriented convenience,
  # not a print, accessibility, PDF-UA, or WCAG-contrast claim. This lane
  # binds every theming boundary key to `"unsupported"` proof in
  # priv/support_matrix.json, trips on any future key that pairs a
  # print/PDF-UA/WCAG term with a `supported*` status, and asserts
  # Rendro.Theme.dark/1's @doc carries the explicit non-print boundary
  # sentence. Mirrors accessibility_overclaim_test.exs's co-occurrence
  # predicate + non-vacuity teeth so this guard can never go vacuous.

  @boundary_keys [
    "print_recommended",
    "accessibility_pdf_ua_claim",
    "wcag_contrast_claim",
    "gui_viewer_visual_fidelity_claim"
  ]

  # Terms that, if ever paired with a `supported*` status anywhere under the
  # `theming` matrix section, indicate an overclaim (print-safety,
  # accessibility-standard, or WCAG-contrast support Rendro does not provide).
  @overclaim_terms ["print", "pdf_ua", "pdf-ua", "wcag", "accessibility"]

  @dark_doc_boundary_sentence "screen-oriented, not recommended for print"

  # Recursively flattens a nested map into {dotted_key_path, string_value}
  # pairs, keeping only leaves whose value is a string (status/claim values).
  defp flatten_string_leaves(map, prefix \\ "") do
    Enum.flat_map(map, fn {k, v} ->
      path = if prefix == "", do: to_string(k), else: "#{prefix}.#{k}"

      case v do
        %{} = nested -> flatten_string_leaves(nested, path)
        value when is_binary(value) -> [{path, value}]
        _ -> []
      end
    end)
  end

  # The co-occurrence predicate under test: a `theming` matrix section
  # overclaims when any leaf whose key path names a print/PDF-UA/WCAG term
  # carries a status that starts with "supported" (i.e. is NOT exactly
  # "unsupported").
  defp theming_overclaims?(theming_section) do
    theming_section
    |> flatten_string_leaves()
    |> Enum.any?(fn {key_path, value} ->
      key_matches_term? = Enum.any?(@overclaim_terms, &String.contains?(key_path, &1))
      key_matches_term? and value != "unsupported"
    end)
  end

  describe "tripwire integrity (non-vacuity / teeth)" do
    test "boundary-key list and overclaim-term list are both non-empty" do
      refute @boundary_keys == [],
             "boundary-key list must not be empty (guard would be vacuous)"

      refute @overclaim_terms == [],
             "overclaim-term list must not be empty (guard would be vacuous)"
    end

    test "predicate FLAGS a theming section that pairs a print/UA/WCAG term with a supported status" do
      overclaiming_section = %{
        "dark" => %{
          "status" => "supported_screen_oriented",
          "boundaries" => %{
            "print_recommended" => "supported"
          }
        }
      }

      assert theming_overclaims?(overclaiming_section)
    end

    test "predicate IGNORES a theming section where every boundary is unsupported" do
      honest_section = %{
        "dark" => %{
          "status" => "supported_screen_oriented",
          "boundaries" => %{
            "print_recommended" => "unsupported",
            "wcag_contrast_claim" => "unsupported"
          }
        }
      }

      refute theming_overclaims?(honest_section)
    end
  end

  describe "priv/support_matrix.json theming rows (D-09)" do
    setup do
      matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()
      {:ok, matrix: matrix}
    end

    test "support matrix has a theming section with light and dark entries", %{matrix: matrix} do
      raw = File.read!("priv/support_matrix.json")

      assert raw =~ ~s|"theming"|
      assert raw =~ ~s|"supported_screen_oriented"|
      assert raw =~ ~s|"unsupported"|

      assert %{"theming" => theming} = matrix
      assert Map.has_key?(theming, "light")
      assert Map.has_key?(theming, "dark")
    end

    test "theming.dark status is supported_screen_oriented", %{matrix: matrix} do
      assert matrix["theming"]["dark"]["status"] == "supported_screen_oriented"
    end

    test "every boundary key is present and unsupported", %{matrix: matrix} do
      boundaries = matrix["theming"]["dark"]["boundaries"]

      assert is_map(boundaries)

      for key <- @boundary_keys do
        assert Map.has_key?(boundaries, key),
               "expected theming.dark.boundaries to declare #{inspect(key)}"

        assert boundaries[key] == "unsupported",
               "expected theming.dark.boundaries.#{key} == \"unsupported\", got #{inspect(boundaries[key])}"
      end
    end

    test "no theming row carries a print/PDF-UA/WCAG support term (overclaim tripwire)", %{
      matrix: matrix
    } do
      refute theming_overclaims?(matrix["theming"]),
             "priv/support_matrix.json theming section pairs a print/PDF-UA/WCAG term with " <>
               "a supported* status (D-09 overclaim tripwire). Dark mode is screen-oriented " <>
               "only; it makes no print, accessibility, PDF-UA, or WCAG-contrast support claim."
    end
  end

  describe "Rendro.Theme.dark/1 @doc boundary sentence (D-09)" do
    test "the @doc for dark/1 states the screen-oriented, not-for-print boundary" do
      assert {:docs_v1, _, _, _, _module_doc, _, function_docs} = Code.fetch_docs(Rendro.Theme)

      dark_doc =
        Enum.find_value(function_docs, fn
          {{:function, :dark, 1}, _anno, _sig, %{"en" => doc}, _meta} -> doc
          _ -> nil
        end)

      assert dark_doc != nil, "expected Rendro.Theme.dark/1 to carry a doc string"

      assert dark_doc =~ @dark_doc_boundary_sentence,
             "expected Rendro.Theme.dark/1's @doc to contain the boundary sentence " <>
               inspect(@dark_doc_boundary_sentence)
    end

    test "source scan corroborates the boundary sentence lives in the dark/1 doc block" do
      source = File.read!("lib/rendro/theme.ex")

      assert source =~ @dark_doc_boundary_sentence
    end
  end

  test "guides/theming.md is not created this phase (deferred to Phase 123, CONTRACT-02)" do
    refute File.exists?("guides/theming.md")
  end
end

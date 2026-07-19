defmodule Rendro.DocsContract.AccessibilityOverclaimTest do
  use ExUnit.Case, async: true

  # D-14 accessibility-overclaim tripwire.
  #
  # The milestone's honesty line: "production-grade" (and kin) describes
  # information-design CRAFT only. Rendro makes NO tagged-PDF / PDF-UA /
  # screen-reader / accessibility-standard-conformance claim anywhere. This
  # test fails the build if any showcase term ever co-occurs, in the same
  # public doc (README.md or guides/**/*.md), with an accessibility-standard
  # claim term.
  #
  # Deliberate exclusion: "logical reading order" is an INTERNAL rubric GATE
  # phrase, never a public accessibility-standard claim — it is intentionally
  # absent from @accessibility_terms so honest rubric-gate vocabulary does not
  # trip the tripwire. The terms below target standard/conformance/assistive-tech
  # claims, not the reading-order gate.

  @showcase_terms [
    "production-grade",
    "production grade",
    "production-quality",
    "production quality"
  ]

  @accessibility_terms [
    "PDF/UA",
    "PDF-UA",
    "PDF/A-1a",
    "tagged PDF",
    "tagged-PDF",
    "screen reader",
    "screen-reader",
    "assistive technology",
    "assistive-technology",
    "WCAG",
    "Section 508",
    "accessibility conformance",
    "accessibility-conformant",
    "accessibility conformant",
    "accessible document standard"
  ]

  @doc_paths ["README.md" | Path.wildcard("guides/**/*.md")]

  # The co-occurrence predicate under test: a doc overclaims when it pairs any
  # showcase term with any accessibility-standard term.
  defp overclaim?(content) do
    Enum.any?(@showcase_terms, &String.contains?(content, &1)) and
      Enum.any?(@accessibility_terms, &String.contains?(content, &1))
  end

  describe "tripwire integrity (non-vacuity / teeth)" do
    test "showcase and accessibility term lists are both non-empty" do
      refute @showcase_terms == [],
             "showcase term list must not be empty (guard would be vacuous)"

      refute @accessibility_terms == [],
             "accessibility term list must not be empty (guard would be vacuous)"
    end

    test "predicate FLAGS a doc that pairs showcase wording with an accessibility claim" do
      assert overclaim?("Rendro renders production-grade, PDF/UA tagged PDF output.")
      assert overclaim?("A production quality document, validated for screen reader use.")
    end

    test "predicate IGNORES showcase wording that stands alone" do
      refute overclaim?("Rendro renders production-grade business documents deterministically.")
    end

    test "predicate IGNORES the honest 'logical reading order' rubric-gate phrase" do
      # Reading order is a rubric GATE, not a public accessibility claim: showcase
      # wording beside it must NOT trip the tripwire.
      refute overclaim?(
               "Every demo is checked for logical reading order as a production-grade craft gate."
             )
    end

    test "the scanned doc set is non-empty and includes README.md" do
      assert "README.md" in @doc_paths
      assert length(@doc_paths) > 1, "expected README plus guides/**/*.md in the scan set"
    end
  end

  describe "no public doc pairs showcase wording with an accessibility-standard claim (D-14)" do
    for path <- @doc_paths do
      @tag path: path
      test "#{path} carries no accessibility overclaim" do
        content = File.read!(unquote(path))

        if Enum.any?(@showcase_terms, &String.contains?(content, &1)) do
          for term <- @accessibility_terms do
            refute String.contains?(content, term),
                   "#{unquote(path)}: showcase wording must not co-occur with the " <>
                     "accessibility-standard claim #{inspect(term)} (D-14 overclaim tripwire). " <>
                     "\"production-grade\" is information-design craft only; Rendro makes no " <>
                     "tagged-PDF / PDF-UA / screen-reader conformance claim."
          end
        end
      end
    end
  end
end

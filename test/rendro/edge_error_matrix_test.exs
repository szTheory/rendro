defmodule Rendro.EdgeErrorMatrixTest do
  # EDGE-02 typed-error assertion matrix (D-08 sibling to edge_matrix_test.exs).
  #
  # This module intentionally covers ENGINE-LEVEL representative inputs, NOT
  # per-family cases: overflow / tall-row (paginate stage) and the two RTL
  # refusal modes (measure stage) are pipeline concerns identical across all six
  # recipes. Per-family `validate_data!/1` `ArgumentError` coverage already lives
  # in each recipe's own test file and is out of scope here (D-08).
  #
  # Assertion idiom (D-07): match the typed `%Rendro.Error{}` struct first, then
  # assert `stage`/`reason` precisely and `next`/`why` as SUBSTRINGS — never
  # assert on a raw internal tuple escaping to the caller, and never on full
  # error-prose equality (wording may drift; the TYPE/STAGE/REASON contract may
  # not). `render/2` wraps the pipeline's internal throw/catch shape in
  # `Rendro.Error` before returning; only the WRAPPED struct is a legitimate
  # assertion target.
  #
  # `render/2` is pure — safe to run these concurrently.
  use ExUnit.Case, async: true

  alias Rendro.Test.EdgeFixtures

  # The 4 engine-level representative EDGE-02 inputs this module covers. Not a
  # second full @matrix — a lightweight exhaustiveness marker mirroring D-02's
  # discipline at this module's smaller scale (D-08). Per-family
  # validate_data!/1 ArgumentError coverage lives in each recipe's own test file.
  @error_cases [:overflow, :tall_row, :rtl_default_font, :rtl_shaping_required]

  describe "EDGE-02: overflow and tall-row (D-05)" do
    test "a plain block exceeding body height raises typed :content_overflow with a :block detail" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = error} =
               Rendro.render(EdgeFixtures.overflow_document())

      # D-07 idiom: assert `next` as a SUBSTRING, never full prose equality —
      # wording may drift; the {stage, reason} contract and this guidance keyword
      # may not.
      assert error.next =~ "does not auto-fit"

      # Generic check_overflow!/4 path merges a :block rect into details.
      assert is_map(error.details.block)
    end

    test "a single row taller than the body raises the SAME typed error via the row-overflow path (no :block)" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = error} =
               Rendro.render(EdgeFixtures.tall_row_document())

      # Identical next guidance — next_step/2 pattern-matches only on {stage, reason}.
      # D-07 idiom: substring, not full-prose equality.
      assert error.next =~ "does not auto-fit"

      # The table-row-overflow branch identifies the offending row, never silently
      # truncating it.
      assert is_number(error.details.row_height)
      assert error.details.row_height > 0

      # Structural distinction from the generic overflow case: this path's details
      # map never merges in a :block key, proving both entry points into
      # :content_overflow are genuinely exercised (D-05).
      refute Map.has_key?(error.details, :block)
    end
  end

  describe "EDGE-02: RTL refusal, both paths (D-06)" do
    test "Hebrew under the default shaper raises {:unsupported_glyph, char} at :measure" do
      assert {:error, %Rendro.Error{stage: :measure, reason: {:unsupported_glyph, char}} = error} =
               Rendro.render(EdgeFixtures.rtl_default_font_document())

      # A single Hebrew grapheme — glyph resolution fails before shaping.
      assert is_binary(char)
      assert String.length(char) == 1
      assert error.next =~ "fallback font"
    end

    test "Arabic under a glyph-capable but shaping-incapable font raises {:shaping_required, :arab, hint}" do
      assert {:error,
              %Rendro.Error{stage: :measure, reason: {:shaping_required, :arab, hint}} = error} =
               Rendro.render(EdgeFixtures.rtl_shaping_required_document())

      # Rendro has no UAX #9 reordering — it refuses rather than mis-render.
      assert is_binary(hint)
      assert error.next =~ "shaping adapter"
      assert error.why =~ ":arab"
    end

    # D-06 negative regression lock: render/2 must NEVER silently succeed for RTL
    # under the default shaper. Hebrew/Arabic rendered LTR would be silently-wrong
    # output — the worst outcome for an auditable-documents library.
    test "render/2 never returns {:ok, _} for RTL default-font text (regression lock)" do
      refute match?({:ok, _}, Rendro.render(EdgeFixtures.rtl_default_font_document()))
    end

    test "render/2 never returns {:ok, _} for RTL shaping-required text (regression lock)" do
      refute match?({:ok, _}, Rendro.render(EdgeFixtures.rtl_shaping_required_document()))
    end
  end

  describe "EDGE-02: coverage discipline (D-08)" do
    test "every covered engine-level input maps to a real EdgeFixtures builder (non-vacuous)" do
      # Engine-level granularity (D-08): overflow/tall-row (paginate) + both RTL
      # refusal modes (measure) are pipeline concerns identical across all six
      # recipes. This is deliberately NOT a per-family matrix.
      #
      # A coverage-honesty phase must not ship a coverage guard that can't fail.
      # Tie each declared case to its `<case>_document/0` builder so the marker
      # tracks the actual fixtures the tests above exercise: declaring a 5th case
      # without a fixture, or renaming/removing a fixture, trips this guard.
      Code.ensure_loaded!(EdgeFixtures)

      for c <- @error_cases do
        builder = :"#{c}_document"

        assert function_exported?(EdgeFixtures, builder, 0),
               "EDGE-02 case #{inspect(c)} has no EdgeFixtures.#{builder}/0 builder"
      end

      assert length(@error_cases) == 4
      assert Enum.uniq(@error_cases) == @error_cases
    end
  end
end

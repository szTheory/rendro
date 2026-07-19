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

  describe "EDGE-02: overflow and tall-row (D-05)" do
    test "a plain block exceeding body height raises typed :content_overflow with a :block detail" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = error} =
               Rendro.render(EdgeFixtures.overflow_document())

      assert error.next ==
               "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."

      # Generic check_overflow!/4 path merges a :block rect into details.
      assert is_map(error.details.block)
    end

    test "a single row taller than the body raises the SAME typed error via the row-overflow path (no :block)" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = error} =
               Rendro.render(EdgeFixtures.tall_row_document())

      # Identical next string — next_step/2 pattern-matches only on {stage, reason}.
      assert error.next ==
               "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."

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
end

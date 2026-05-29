defmodule Rendro.MeasureRowsTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Measure
  alias Rendro.TestSupport.FontFixture

  @width 400

  defp sample_rows do
    [
      ["row1col1", "row1col2"],
      ["row2col1", "row2col2"],
      ["row3col1", "row3col2"]
    ]
  end

  defp table_opts do
    [header: ["h1", "h2"], columns: [{:share, 1}, {:share, 1}]]
  end

  # Measure the SAME table through the engine's own public measure path
  # (Measure.run over a block on a page) and return its {header_height, row_heights}.
  defp engine_geometry(doc, rows, width, table_opts) do
    table = Rendro.table(rows, table_opts)
    block = %Rendro.Block{content: table, width: width}
    page = %Rendro.Page{blocks: [block]}
    doc = %{doc | pages: [page]}

    {:ok, measured} = Measure.run(doc)
    [measured_page] = measured.pages
    [measured_block] = measured_page.blocks

    {measured_block.content.header_height, measured_block.content.row_heights}
  end

  describe "Rendro.measure_rows/4" do
    test "returns a header_height and one row_height per row" do
      doc = FontFixture.document_with_helvetica()
      rows = sample_rows()

      {header_height, row_heights} = Rendro.measure_rows(rows, @width, doc, table_opts())

      assert is_number(header_height)
      assert header_height > 0
      assert is_list(row_heights)
      assert length(row_heights) == length(rows)
      assert Enum.all?(row_heights, &(is_number(&1) and &1 > 0))
    end

    test "heights are IDENTICAL to the engine's own measurement of the same table" do
      doc = FontFixture.document_with_helvetica()
      rows = sample_rows()

      helper = Rendro.measure_rows(rows, @width, doc, table_opts())
      engine = engine_geometry(doc, rows, @width, table_opts())

      # Exact equality (not approximate-with-large-tolerance): the helper must
      # use the engine's own numbers, proving it is not a recipe-local estimate.
      assert helper == engine
    end

    test "works without a header (header_height 0, row_heights still match the engine)" do
      doc = FontFixture.document_with_helvetica()
      rows = sample_rows()
      opts = [columns: [{:share, 1}, {:share, 1}]]

      {header_height, row_heights} = Rendro.measure_rows(rows, @width, doc, opts)

      assert header_height == 0
      assert length(row_heights) == length(rows)
      assert {header_height, row_heights} == engine_geometry(doc, rows, @width, opts)
    end

    test "is read-only: a subsequent unrelated render still succeeds (no engine state mutated)" do
      doc = FontFixture.document_with_helvetica()
      rows = sample_rows()

      # Call the helper (must not raise, must not mutate global/engine state).
      assert {_h, _rh} = Rendro.measure_rows(rows, @width, doc, table_opts())

      # An unrelated document must still render successfully afterwards.
      text = Rendro.text("Hello statement", font: :helvetica, size: 12)
      block = Rendro.block(text, width: @width)
      render_doc = %{doc | content: [block]}

      assert {:ok, pdf} = Rendro.render(render_doc)
      assert is_binary(pdf)

      # The helper is also idempotent: calling it again returns the same geometry.
      assert Rendro.measure_rows(rows, @width, doc, table_opts()) ==
               Rendro.measure_rows(rows, @width, doc, table_opts())
    end
  end
end

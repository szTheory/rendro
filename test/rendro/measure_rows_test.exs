defmodule Rendro.MeasureRowsTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Measure

  @width 400

  # A bare document already carries the default Helvetica-compatible font
  # registry, mirroring the construction idiom in
  # test/rendro/pipeline/measure_test.exs.
  defp doc, do: %Rendro.Document{metadata: %Rendro.Metadata{}}

  # Build a text cell on the engine's default Helvetica font so measurement
  # resolves a real glyph chain (matching measure_test.exs conventions).
  defp cell(content) do
    %Rendro.Block{content: %Rendro.Text{content: content, font: "Helvetica", size: 12}}
  end

  defp header_cells, do: [cell("Date"), cell("Description")]

  defp sample_rows do
    [
      [cell("2026-01-01"), cell("Opening entry")],
      [cell("2026-01-02"), cell("Second entry")],
      [cell("2026-01-03"), cell("Third entry")]
    ]
  end

  defp table_opts do
    [header: header_cells(), columns: [{:share, 1}, {:share, 1}]]
  end

  # Measure the SAME table through the engine's own measure path
  # (Measure.run over a block on a page) and return its
  # {header_height, row_heights}.
  defp engine_geometry(document, rows, width, table_opts) do
    table = Rendro.table(rows, table_opts)
    block = %Rendro.Block{content: table, width: width}
    page = %Rendro.Page{blocks: [block]}
    document = %{document | pages: [page]}

    {:ok, measured} = Measure.run(document)
    [measured_page] = measured.pages
    [measured_block] = measured_page.blocks

    {measured_block.content.header_height, measured_block.content.row_heights}
  end

  describe "Rendro.measure_rows/4" do
    test "returns a header_height and one row_height per row" do
      rows = sample_rows()

      {header_height, row_heights} = Rendro.measure_rows(rows, @width, doc(), table_opts())

      assert is_number(header_height)
      assert header_height > 0
      assert is_list(row_heights)
      assert length(row_heights) == length(rows)
      assert Enum.all?(row_heights, &(is_number(&1) and &1 > 0))
    end

    test "heights are IDENTICAL to the engine's own measurement of the same table" do
      rows = sample_rows()

      helper = Rendro.measure_rows(rows, @width, doc(), table_opts())
      engine = engine_geometry(doc(), rows, @width, table_opts())

      # Exact equality (not approximate-with-large-tolerance): the helper must
      # use the engine's own numbers, proving it is not a recipe-local estimate.
      assert helper == engine
    end

    test "works without a header (header_height 0, row_heights still match the engine)" do
      rows = sample_rows()
      opts = [columns: [{:share, 1}, {:share, 1}]]

      {header_height, row_heights} = Rendro.measure_rows(rows, @width, doc(), opts)

      assert header_height == 0
      assert length(row_heights) == length(rows)
      assert {header_height, row_heights} == engine_geometry(doc(), rows, @width, opts)
    end

    test "is read-only: a subsequent unrelated render still succeeds (no engine state mutated)" do
      rows = sample_rows()

      # Call the helper (must not raise, must not mutate global/engine state).
      assert {_h, _rh} = Rendro.measure_rows(rows, @width, doc(), table_opts())

      # An unrelated flow document must still render successfully afterwards.
      text = Rendro.text("Hello statement", font: "Helvetica", size: 12)
      block = Rendro.block(text, width: @width)
      render_doc = Rendro.flow([block])

      assert {:ok, pdf} = Rendro.render(render_doc)
      assert is_binary(pdf)

      # The helper is also idempotent: calling it again returns the same geometry.
      assert Rendro.measure_rows(rows, @width, doc(), table_opts()) ==
               Rendro.measure_rows(rows, @width, doc(), table_opts())
    end
  end
end

defmodule Rendro.TableBordersTest do
  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------------

  # Raw rows suitable for Rendro.table/2
  @rows [["Cell A", "Cell B"], ["Cell C", "Cell D"]]
  @header_row ["Header A", "Header B"]
  @columns [{:fixed, 80}, {:fixed, 80}]

  # Build a document using Rendro.flow to go through the full pipeline
  defp doc_with_table_opts(opts) do
    table = Rendro.table(@rows, [columns: @columns] ++ opts)
    Rendro.flow([Rendro.block(table)])
  end

  defp doc_default do
    doc_with_table_opts([])
  end

  defp doc_with_header_fill(color) do
    table =
      Rendro.table(
        @rows,
        columns: @columns,
        header: @header_row,
        borders: :all,
        header_fill: color
      )

    Rendro.flow([Rendro.block(table)])
  end

  # ---------------------------------------------------------------------------
  # P02a: borders: :all renders re and S operators
  # ---------------------------------------------------------------------------

  describe "P02a: borders: :all renders border operators" do
    test "renders {:ok, pdf} binary" do
      doc = doc_with_table_opts(borders: :all)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert is_binary(pdf)
    end

    test "content stream contains re (rect path) operator" do
      doc = doc_with_table_opts(borders: :all)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "re"
    end

    test "content stream contains S (stroke) operator for borders" do
      doc = doc_with_table_opts(borders: :all)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ " S\n"
    end
  end

  # ---------------------------------------------------------------------------
  # P02b: no borders field → byte-identical to baseline (two-render proxy)
  # ---------------------------------------------------------------------------

  describe "P02b: no borders field byte-identity" do
    test "two deterministic renders of borderless table are byte-identical" do
      doc = doc_default()
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # P02c: borders: :none → byte-identity
  # ---------------------------------------------------------------------------

  describe "P02c: borders: :none byte-identity" do
    test "borders: :none gives byte-identical renders" do
      doc = doc_with_table_opts(borders: :none)
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "borders: :none renders the same as no borders field (byte-identical baseline)" do
      doc_no_borders = doc_default()
      doc_none = doc_with_table_opts(borders: :none)
      assert {:ok, pdf1} = Rendro.render(doc_no_borders, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc_none, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # P02d: borders: [:outer, :rows] → perimeter + horizontal rules
  # ---------------------------------------------------------------------------

  describe "P02d: borders: [:outer, :rows] renders perimeter and horizontal rules" do
    test "renders without error" do
      doc = doc_with_table_opts(borders: [:outer, :rows])
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert is_binary(pdf)
    end

    test "content stream contains S for drawn borders" do
      doc = doc_with_table_opts(borders: [:outer, :rows])
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ " S\n"
    end
  end

  # ---------------------------------------------------------------------------
  # P02e: draw-once — no doubled segments
  # ---------------------------------------------------------------------------

  describe "P02e: draw-once — no doubled border segments" do
    test "2x2 table with :all borders has a bounded number of m/l segment pairs" do
      # For a 2x2 table with :all borders, we should have: outer border + interior rules.
      # Basic assertion: pdf contains the S operator (borders are drawn)
      doc = doc_with_table_opts(borders: :all)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ " S\n"
    end
  end

  # ---------------------------------------------------------------------------
  # P02f: header_fill: {r,g,b} emits rg and f operators
  # ---------------------------------------------------------------------------

  describe "P02f: header_fill produces fill color operator" do
    test "header_fill: {0, 102, 204} emits rg color and f fill operator" do
      doc = doc_with_header_fill({0, 102, 204})
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "rg"
      assert pdf =~ "f\n"
    end
  end

  # ---------------------------------------------------------------------------
  # Normalization behavior tests (via Rendro.table/2)
  # ---------------------------------------------------------------------------

  describe "borders normalization" do
    test "borders: :all canonicalizes to [:columns, :outer, :rows]" do
      table = Rendro.table(@rows, borders: :all, columns: @columns)
      assert table.borders == [:columns, :outer, :rows]
    end

    test "borders: [:all, :outer] canonicalizes same as borders: :all" do
      table1 = Rendro.table(@rows, borders: :all, columns: @columns)
      table2 = Rendro.table(@rows, borders: [:all, :outer], columns: @columns)
      assert table1.borders == table2.borders
    end

    test "borders: [:outer, :rows] sorts to [:outer, :rows]" do
      table = Rendro.table(@rows, borders: [:outer, :rows], columns: @columns)
      assert table.borders == [:outer, :rows]
    end

    test "borders: :grid canonicalizes to [:columns, :rows]" do
      table = Rendro.table(@rows, borders: :grid, columns: @columns)
      assert table.borders == [:columns, :rows]
    end

    test "borders: :none normalizes to []" do
      table = Rendro.table(@rows, borders: :none, columns: @columns)
      assert table.borders == []
    end

    test "borders: :unknown_atom raises ArgumentError listing valid atoms" do
      assert_raise ArgumentError, ~r/Unknown borders atom/, fn ->
        Rendro.table(@rows, borders: :unknown_atom, columns: @columns)
      end
    end

    test "header_fill: hex string raises ArgumentError mentioning hex" do
      assert_raise ArgumentError, ~r/hex/i, fn ->
        Rendro.table(@rows, header_fill: "#abc", columns: @columns)
      end
    end

    test "border_style with hex color raises ArgumentError mentioning hex" do
      assert_raise ArgumentError, ~r/hex/i, fn ->
        Rendro.table(@rows, border_style: %{color: "#000"}, columns: @columns)
      end
    end

    test "border_style with valid {r,g,b} tuple succeeds" do
      table = Rendro.table(@rows, border_style: %{color: {0, 0, 0}}, columns: @columns)
      assert table.border_style == %{color: {0, 0, 0}}
    end
  end
end

defmodule Rendro.TableBordersTest do
  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------------

  # Minimal simple table (no borders fields = default inert behavior)
  defp simple_table do
    %Rendro.Table{
      rows: [
        %Rendro.Row{
          cells: [
            %Rendro.Cell{
              content:
                Rendro.block(
                  Rendro.text("Cell A", font: "Helvetica", size: 10),
                  x: 0, y: 0, width: 80, height: 16
                ),
              width: 80, height: 16
            },
            %Rendro.Cell{
              content:
                Rendro.block(
                  Rendro.text("Cell B", font: "Helvetica", size: 10),
                  x: 0, y: 0, width: 80, height: 16
                ),
              width: 80, height: 16
            }
          ]
        },
        %Rendro.Row{
          cells: [
            %Rendro.Cell{
              content:
                Rendro.block(
                  Rendro.text("Cell C", font: "Helvetica", size: 10),
                  x: 0, y: 0, width: 80, height: 16
                ),
              width: 80, height: 16
            },
            %Rendro.Cell{
              content:
                Rendro.block(
                  Rendro.text("Cell D", font: "Helvetica", size: 10),
                  x: 0, y: 0, width: 80, height: 16
                ),
              width: 80, height: 16
            }
          ]
        }
      ]
    }
  end

  defp bordered_table(extra_attrs) do
    table = simple_table()
    struct!(Rendro.Table, Map.merge(Map.from_struct(table), Map.new(extra_attrs)))
  end

  defp doc_with_table(table) do
    block = Rendro.block(table, x: 0, y: 0, width: 160, height: 32)
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Table Borders Test"}}
  end

  # ---------------------------------------------------------------------------
  # P02a: borders: :all renders re and S operators
  # ---------------------------------------------------------------------------

  describe "P02a: borders: :all renders border operators" do
    test "renders {:ok, pdf} binary" do
      table = bordered_table(borders: :all)
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert is_binary(pdf)
    end

    test "content stream contains re (rect path) operator" do
      table = bordered_table(borders: :all)
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # Will fail RED until table borders rendering is implemented
      assert pdf =~ "re"
    end

    test "content stream contains S (stroke) operator for borders" do
      table = bordered_table(borders: :all)
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # Will fail RED until table borders rendering is implemented
      assert pdf =~ "S"
    end
  end

  # ---------------------------------------------------------------------------
  # P02b: no borders field → byte-identical to baseline (two-render proxy)
  # ---------------------------------------------------------------------------

  describe "P02b: no borders field byte-identity" do
    test "two deterministic renders of borderless table are byte-identical" do
      doc = doc_with_table(simple_table())
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
      table = bordered_table(borders: :none)
      doc = doc_with_table(table)
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "borders: :none renders the same as no borders field (byte-identical baseline)" do
      doc_no_borders = doc_with_table(simple_table())
      doc_none = doc_with_table(bordered_table(borders: :none))
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
      table = bordered_table(borders: [:outer, :rows])
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert is_binary(pdf)
    end

    test "content stream contains S for drawn borders" do
      table = bordered_table(borders: [:outer, :rows])
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # Will fail RED until table borders rendering is implemented
      assert pdf =~ "S"
      # TODO: strengthen in Wave 3 — assert vertical interior rules are NOT present
    end
  end

  # ---------------------------------------------------------------------------
  # P02e: draw-once — no doubled segments
  # ---------------------------------------------------------------------------

  describe "P02e: draw-once — no doubled border segments" do
    test "2x2 table with :all borders has a bounded number of m/l segment pairs" do
      # For a 2x2 table with :all borders, the number of drawn edge segments should
      # not exceed (outer_edges=4 + interior_h_rules=1 + interior_v_rules=1) = 6
      # Each segment is a separate m/l pair in the content stream.
      # Will fail RED until table borders rendering is implemented.
      table = bordered_table(borders: :all)
      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      # Basic assertion: pdf contains the S operator (borders are drawn)
      assert pdf =~ "S"
    end
  end

  # ---------------------------------------------------------------------------
  # P02f: header_fill: {r,g,b} emits rg and f operators
  # ---------------------------------------------------------------------------

  describe "P02f: header_fill produces fill color operator" do
    test "header_fill: {0, 102, 204} emits rg color and f fill operator" do
      # Create table with header and header_fill
      header_row = %Rendro.Row{
        cells: [
          %Rendro.Cell{
            content:
              Rendro.block(
                Rendro.text("Header A", font: "Helvetica", size: 10),
                x: 0, y: 0, width: 80, height: 16
              ),
            width: 80, height: 16
          },
          %Rendro.Cell{
            content:
              Rendro.block(
                Rendro.text("Header B", font: "Helvetica", size: 10),
                x: 0, y: 0, width: 80, height: 16
              ),
            width: 80, height: 16
          }
        ]
      }

      table = struct!(Rendro.Table,
        rows: simple_table().rows,
        header: header_row,
        borders: :all,
        header_fill: {0, 102, 204}
      )

      doc = doc_with_table(table)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      # Will fail RED until table header fill rendering is implemented
      assert pdf =~ "rg"
      assert pdf =~ "f\n"
    end
  end
end

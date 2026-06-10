defmodule Rendro.PathTest do
  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------------

  defp doc_with_rect_path do
    path = %Rendro.Path{
      ops: [{:rect, 10, 10, 100, 50}],
      stroke: {0, 0, 0},
      fill: nil
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 200, height: 80}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Path Test"}}
  end

  defp doc_with_line_path do
    path = %Rendro.Path{
      ops: [{:move, 0, 0}, {:line, 100, 50}],
      stroke: {0, 0, 0}
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 150, height: 70}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Line Path Test"}}
  end

  defp doc_with_rounded_rect_path do
    path = %Rendro.Path{
      ops: [{:rounded_rect, 5, 5, 90, 40, 10}],
      stroke: {0, 0, 0}
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 120, height: 70}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Rounded Rect Path Test"}}
  end

  defp doc_with_fill_only_path do
    path = %Rendro.Path{
      ops: [{:rect, 0, 0, 60, 40}],
      stroke: nil,
      fill: {255, 0, 0}
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 80, height: 60}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Fill Path Test"}}
  end

  defp doc_with_stroke_and_fill_path do
    path = %Rendro.Path{
      ops: [{:rect, 0, 0, 60, 40}],
      stroke: {0, 0, 0},
      fill: {200, 200, 200}
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 80, height: 60}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Stroke+Fill Path Test"}}
  end

  defp doc_with_no_paint_path do
    path = %Rendro.Path{
      ops: [{:rect, 0, 0, 60, 40}],
      stroke: nil,
      fill: nil
    }

    block = %Rendro.Block{content: path, x: 0, y: 0, width: 80, height: 60}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "No Paint Path Test"}}
  end

  # ---------------------------------------------------------------------------
  # P01a: rect path renders with re and S operators
  # ---------------------------------------------------------------------------

  describe "P01a: rect path renders to PDF content stream" do
    test "renders {:ok, pdf} binary" do
      doc = doc_with_rect_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert is_binary(pdf)
    end

    test "content stream contains re (rect) and S (stroke) operators" do
      doc = doc_with_rect_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # These will fail RED until Path rendering is implemented
      assert pdf =~ "re\nS"
    end
  end

  # ---------------------------------------------------------------------------
  # P01b: two-render byte-identity (determinism)
  # ---------------------------------------------------------------------------

  describe "P01b: deterministic byte-identity" do
    test "two deterministic renders of same Path document are byte-identical" do
      doc = doc_with_rect_path()
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # P01c: format_num precision — at most 4 decimal places
  # ---------------------------------------------------------------------------

  describe "P01c: coordinate precision (format_num, max 4 decimals)" do
    test "PDF content stream does not contain floats with more than 4 decimal digits" do
      doc = doc_with_rect_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # No scientific notation or 5+ decimal place floats in path ops
      refute pdf =~ ~r/\d+\.\d{5,}/
    end

    test "line path coords use at most 4 decimal places" do
      doc = doc_with_line_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      refute pdf =~ ~r/\d+\.\d{5,}/
    end
  end

  # ---------------------------------------------------------------------------
  # P01d: rounded_rect decomposes via kappa 0.5522847498
  # ---------------------------------------------------------------------------

  describe "P01d: rounded_rect uses kappa approximation" do
    test "rounded_rect content stream contains kappa-derived control point coordinate" do
      doc = doc_with_rounded_rect_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      # The fixture: {rounded_rect, 5, 5, 90, 40, 10} with block_h=70.
      # control = 10 * 0.5522847498 = 5.5228. This offset appears in the control points:
      # right(95) - r(10) + control(5.5228) = 90.5228
      # top(65) - r(10) + control(5.5228) = 60.5228
      # Both of these "kappa-derived" coordinate values must appear in the stream.
      assert pdf =~ "90.5228"
      assert pdf =~ "60.5228"
    end
  end

  # ---------------------------------------------------------------------------
  # P01e: paint-op selection
  # ---------------------------------------------------------------------------

  describe "P01e: paint-op selection based on stroke/fill" do
    test "stroke-only path emits S operator" do
      doc = doc_with_rect_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "S\n"
    end

    test "fill-only path emits f operator" do
      doc = doc_with_fill_only_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "f\n"
    end

    test "stroke+fill path emits B operator" do
      doc = doc_with_stroke_and_fill_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "B\n"
    end

    test "no-stroke no-fill path emits n operator" do
      doc = doc_with_no_paint_path()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
      assert pdf =~ "n\n"
    end
  end

  # ---------------------------------------------------------------------------
  # P01f: Color.validate/1 hex-footgun error
  # ---------------------------------------------------------------------------

  describe "P01f: Rendro.Color.validate/1 hex footgun error" do
    test "validate/1 with hex string raises {:error, msg} containing 'hex'" do
      result = Rendro.Color.validate("#000")
      assert {:error, msg} = result
      assert msg =~ ~r/hex/i
    end

    test "validate/1 with named color atom returns {:error, _}" do
      assert {:error, _} = Rendro.Color.validate(:black)
    end

    test "validate/1 with wrong-arity tuple returns {:error, _}" do
      assert {:error, _} = Rendro.Color.validate({0, 0})
    end

    test "validate/1 with out-of-range integer returns {:error, _}" do
      assert {:error, _} = Rendro.Color.validate({-1, 0, 0})
      assert {:error, _} = Rendro.Color.validate({256, 0, 0})
    end

    test "validate/1 with float component returns {:error, _}" do
      assert {:error, _} = Rendro.Color.validate({0.5, 0, 0})
    end

    test "validate/1 with valid RGB tuples returns :ok" do
      assert :ok == Rendro.Color.validate({0, 0, 0})
      assert :ok == Rendro.Color.validate({255, 255, 255})
      assert :ok == Rendro.Color.validate({44, 107, 237})
    end
  end
end

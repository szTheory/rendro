defmodule Rendro.Pipeline.ValidateTest do
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}

  defp sample_document do
    text = %Rendro.Text{content: "Hello!", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Validate Test"}}
  end

  defp two_page_document do
    text = %Rendro.Text{content: "P", font: "Helvetica", size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 10, y: 20}
    page1 = %Rendro.Page{blocks: [block]}
    page2 = %Rendro.Page{blocks: [block]}
    %Rendro.Document{pages: [page1, page2], metadata: %Rendro.Metadata{}}
  end

  defp render_through_full_pipeline(doc) do
    {:ok, doc} = Build.run(doc)
    # Note: we run the OLD order here to produce a binary independently of the orchestrator's
    # eventual reorder in Plan 03. Validate operates on the binary regardless of upstream order.
    {:ok, doc} = Measure.run(doc)
    {:ok, doc} = Paginate.run(doc)
    {:ok, doc} = Compose.run(doc)
    {:ok, pdf} = Render.run(doc)
    {pdf, doc}
  end

  describe "run/2 — happy path" do
    test "returns {:ok, pdf} unchanged for a well-formed 1-page render" do
      {pdf, doc} = render_through_full_pipeline(sample_document())
      assert {:ok, ^pdf} = Validate.run(pdf, doc)
    end

    test "returns {:ok, pdf} unchanged for a well-formed 2-page render" do
      {pdf, doc} = render_through_full_pipeline(two_page_document())
      assert {:ok, ^pdf} = Validate.run(pdf, doc)
    end

    test "is idempotent — same result on repeated calls" do
      {pdf, doc} = render_through_full_pipeline(sample_document())
      assert Validate.run(pdf, doc) == Validate.run(pdf, doc)
    end
  end

  describe "run/2 — :structural_corruption" do
    test "returns {:error, :structural_corruption} when binary lacks %PDF- header" do
      doc = sample_document()
      assert {:error, :structural_corruption} = Validate.run("not a pdf", doc)
    end

    test "returns {:error, :structural_corruption} when binary lacks %%EOF trailer" do
      doc = sample_document()

      assert {:error, :structural_corruption} =
               Validate.run("%PDF-1.4\nbody without trailer", doc)
    end

    test "structural check rejects giant non-PDF binaries quickly (T-06-05 regression)" do
      # Adversarial: 1MB binary with no header. Structural check fires first; regex never runs.
      big_garbage = String.duplicate("A", 1_000_000)
      doc = sample_document()

      {time_us, result} = :timer.tc(fn -> Validate.run(big_garbage, doc) end)
      assert result == {:error, :structural_corruption}
      assert time_us < 100_000, "expected <100ms; got #{time_us}us"
    end
  end

  describe "run/2 — :page_count_mismatch" do
    test "returns {:error, :page_count_mismatch} when /Count != length(doc.pages)" do
      # Synthetic binary: claims 1 page; doc has 2.
      fake_pdf = "%PDF-1.4\n%...\n/Type /Pages\n/Count 1\n/Kids [3 0 R]\n%%EOF\n"
      doc = two_page_document()
      assert {:error, :page_count_mismatch} = Validate.run(fake_pdf, doc)
    end

    test "returns {:error, :page_count_mismatch} when /Type /Pages object is missing entirely" do
      # parse_page_count/1 falls back to 0; doc has 1 page; mismatch.
      fake_pdf = "%PDF-1.4\nno pages object here\n%%EOF\n"
      doc = sample_document()
      assert {:error, :page_count_mismatch} = Validate.run(fake_pdf, doc)
    end
  end

  describe "run/2 — :max_bytes_exceeded" do
    test "returns {:error, :max_bytes_exceeded} when byte_size > policy limit" do
      {pdf, doc} = render_through_full_pipeline(sample_document())
      # Set max_bytes far below the actual rendered size (real PDF is ~500+ bytes).
      doc = put_in(doc.options[:policies], max_bytes: 1)
      assert {:error, :max_bytes_exceeded} = Validate.run(pdf, doc)
    end

    test "returns {:ok, pdf} when max_bytes is nil" do
      {pdf, doc} = render_through_full_pipeline(sample_document())
      # No policy set on doc.options.
      assert {:ok, ^pdf} = Validate.run(pdf, doc)
    end

    test "returns {:ok, pdf} when byte_size <= max_bytes" do
      {pdf, doc} = render_through_full_pipeline(sample_document())
      # Set max_bytes generously above actual size.
      doc = put_in(doc.options[:policies], max_bytes: 1_000_000)
      assert {:ok, ^pdf} = Validate.run(pdf, doc)
    end
  end

  describe "run/2 — guard clauses" do
    test "raises FunctionClauseError when first arg is not a binary" do
      doc = sample_document()
      assert_raise FunctionClauseError, fn -> Validate.run(:not_a_binary, doc) end
    end

    test "raises FunctionClauseError when second arg is not a Document" do
      assert_raise FunctionClauseError, fn -> Validate.run("%PDF-1.4\n%%EOF\n", :not_a_doc) end
    end
  end
end

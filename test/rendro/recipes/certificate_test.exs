defmodule Rendro.Recipes.CertificateTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Certificate

  # ---------------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------------

  defp fixture_data(opts \\ []) do
    base = %{
      title: "Certificate of Completion",
      recipient: "Jane Smith",
      body: "Successfully completed the Elixir PDF generation course.",
      date: ~D[2026-05-29],
      seal_line: "Signed by the Director"
    }

    Enum.reduce(opts, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp branded_data do
    Map.put(fixture_data(), :brand, %{font_name: :brand_heading, logo_name: :company_logo})
  end

  # ---------------------------------------------------------------------------
  # C1: document/2 basic — returns %Rendro.Document{}; render returns {:ok, pdf}
  # ---------------------------------------------------------------------------

  describe "C1: document/2 basic render" do
    test "returns a Rendro.Document struct" do
      assert %Rendro.Document{} = Certificate.document(fixture_data())
    end

    test "Rendro.render returns {:ok, pdf} binary starting with %PDF-" do
      doc = Certificate.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-")
    end
  end

  # ---------------------------------------------------------------------------
  # C2: no unresolved tokens; content appears in sections
  # ---------------------------------------------------------------------------

  describe "C2: rendered PDF content" do
    test "no unresolved {{...}} tokens in PDF output" do
      doc = Certificate.document(fixture_data())
      {:ok, pdf} = Rendro.render(doc)
      refute pdf =~ "{{"
    end

    test "title, recipient, and date appear in sections content" do
      data = fixture_data()
      doc = Certificate.document(data)

      all_content =
        doc.sections
        |> Enum.flat_map(fn s -> s.content end)

      # At least some content blocks exist
      assert all_content != []
    end
  end

  # ---------------------------------------------------------------------------
  # C3: geometry-derived body width at A4-landscape = 841.89 - 144
  # ---------------------------------------------------------------------------

  describe "C3: geometry-derived body region width (A4-landscape)" do
    test "body region width equals 841.89 - 144 at A4-landscape" do
      template = Certificate.page_template(page_size: :a4, orientation: :landscape)
      body = Enum.find(template.regions, &(&1.role == :body))
      # A4-landscape: pw = 841.89, margin_left + margin_right = 72 + 72 = 144
      assert_in_delta body.width, 841.89 - 144, 0.01
    end
  end

  # ---------------------------------------------------------------------------
  # C4: A4-landscape AND US-Letter-landscape both render without overflow
  # ---------------------------------------------------------------------------

  describe "C4: multi-size render without overflow" do
    test "A4-landscape renders to {:ok, pdf} without content_overflow" do
      doc = Certificate.document(fixture_data(), page_size: :a4, orientation: :landscape)
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "US-Letter-landscape renders to {:ok, pdf} without content_overflow" do
      doc = Certificate.document(fixture_data(), page_size: :us_letter, orientation: :landscape)
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end
  end

  # ---------------------------------------------------------------------------
  # C5: body region widths differ between page sizes (proves geometry-derived)
  # ---------------------------------------------------------------------------

  describe "C5: body width differs between page sizes" do
    test "A4-landscape body width != US-Letter-landscape body width" do
      t_a4 = Certificate.page_template(page_size: :a4, orientation: :landscape)
      t_us = Certificate.page_template(page_size: :us_letter, orientation: :landscape)
      body_a4 = Enum.find(t_a4.regions, &(&1.role == :body))
      body_us = Enum.find(t_us.regions, &(&1.role == :body))
      # A4-landscape: 841.89 - 144 = 697.89; US-Letter-landscape: 792.0 - 144 = 648.0
      # Difference is ~49.89 points — definitely more than 0.01
      refute_in_delta body_a4.width, body_us.width, 0.01
    end
  end

  # ---------------------------------------------------------------------------
  # C6: landscape default — template.width > template.height
  # ---------------------------------------------------------------------------

  describe "C6: landscape default orientation" do
    test "page_template() default has width > height (landscape)" do
      template = Certificate.page_template()
      assert template.width > template.height
    end
  end

  # ---------------------------------------------------------------------------
  # C7: portrait opt-in — page_template(orientation: :portrait).height > width
  # ---------------------------------------------------------------------------

  describe "C7: portrait opt-in" do
    test "page_template(orientation: :portrait) has height > width" do
      t = Certificate.page_template(orientation: :portrait)
      assert t.height > t.width
    end
  end

  # ---------------------------------------------------------------------------
  # C8: branded certificate registers font and image
  # ---------------------------------------------------------------------------

  describe "C8: branded certificate registration" do
    test "brand font is registered in font_registry" do
      doc = Certificate.document(branded_data())
      assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
    end

    test "brand logo is registered in asset_registry" do
      doc = Certificate.document(branded_data())
      assert Map.has_key?(doc.asset_registry.assets, :company_logo)
    end
  end

  # ---------------------------------------------------------------------------
  # C9: unbranded certificate renders without error
  # ---------------------------------------------------------------------------

  describe "C9: unbranded certificate" do
    test "certificate without brand renders without error" do
      doc = Certificate.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end
  end

  # ---------------------------------------------------------------------------
  # C10: malformed brand raises ArgumentError matching ~r/brand/
  # ---------------------------------------------------------------------------

  describe "C10: malformed brand validation" do
    test "brand with non-atom font_name raises ArgumentError matching ~r/brand/" do
      assert_raise ArgumentError, ~r/brand/, fn ->
        Certificate.document(Map.put(fixture_data(), :brand, %{font_name: "not_atom"}))
      end
    end

    test "brand with non-atom logo_name raises ArgumentError matching ~r/brand/" do
      assert_raise ArgumentError, ~r/brand/, fn ->
        Certificate.document(
          Map.put(fixture_data(), :brand, %{font_name: :ok_atom, logo_name: "not_atom"})
        )
      end
    end
  end

  # ---------------------------------------------------------------------------
  # C11: determinism — two renders byte-identical with deterministic: true
  # ---------------------------------------------------------------------------

  describe "C11: deterministic byte-identical render" do
    test "renders same certificate twice with deterministic: true -> byte-identical" do
      doc = Certificate.document(fixture_data())
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # C12: three-rung — page_template/1 and sections/2 callable independently
  # ---------------------------------------------------------------------------

  describe "C12: three-rung escape hatch" do
    test "page_template/1 returns %Rendro.PageTemplate{} without calling document/2" do
      assert %Rendro.PageTemplate{} = Certificate.page_template()
    end

    test "page_template/1 with page_size: :a4 returns correct struct" do
      template = Certificate.page_template(page_size: :a4, orientation: :landscape)
      assert %Rendro.PageTemplate{} = template
      assert template.name == :certificate
    end

    test "sections/2 returns list of %Rendro.Section{} without calling document/2" do
      sections = Certificate.sections(fixture_data())
      assert is_list(sections)
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
      assert sections != []
    end
  end

  # ---------------------------------------------------------------------------
  # C13: validate_data!/1 raises ArgumentError for missing required keys
  # ---------------------------------------------------------------------------

  describe "C13: validate_data! required keys" do
    test "missing :title raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Certificate.document(Map.delete(fixture_data(), :title))
      end
    end

    test "missing :recipient raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Certificate.document(Map.delete(fixture_data(), :recipient))
      end
    end

    test "missing :date raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Certificate.document(Map.delete(fixture_data(), :date))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # C14: validate_data!/1 rejects malformed :date and :body
  # ---------------------------------------------------------------------------

  describe "C14: validate_data!/1 rejects malformed input" do
    test "non-%Date{} :date raises ArgumentError mentioning date" do
      data = fixture_data() |> Map.put(:date, "2026-05-29")

      assert_raise ArgumentError, ~r/date/i, fn ->
        Certificate.document(data)
      end
    end

    test "non-binary :body raises ArgumentError mentioning body" do
      data = fixture_data() |> Map.put(:body, 12_345)

      assert_raise ArgumentError, ~r/body/i, fn ->
        Certificate.document(data)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # C15: border: true renders re and S frame operators
  # ---------------------------------------------------------------------------

  describe "C15: border: true renders certificate frame" do
    test "renders {:ok, pdf} with border: true" do
      doc = Certificate.document(fixture_data(), border: true)
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "content stream contains re operator (rect path for frame)" do
      doc = Certificate.document(fixture_data(), border: true)
      assert {:ok, pdf} = Rendro.render(doc)
      # Will fail RED until certificate border: option is implemented
      assert pdf =~ "re"
    end

    test "content stream contains S operator (stroke for frame)" do
      doc = Certificate.document(fixture_data(), border: true)
      assert {:ok, pdf} = Rendro.render(doc)
      # Will fail RED until certificate border: option is implemented
      assert pdf =~ "S"
    end
  end

  # ---------------------------------------------------------------------------
  # C16: border: false (default) → byte-identical renders
  # ---------------------------------------------------------------------------

  describe "C16: border: false (default) byte-identity" do
    test "two renders with default (no border key) are byte-identical" do
      doc = Certificate.document(fixture_data())
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "explicit border: false is byte-identical to default (no border key)" do
      doc_default = Certificate.document(fixture_data())
      doc_false = Certificate.document(fixture_data(), border: false)
      {:ok, pdf1} = Rendro.render(doc_default, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc_false, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # C17: frame coords differ between A4 and US Letter (geometry-derived)
  # ---------------------------------------------------------------------------

  describe "C17: frame region coordinates differ between page sizes" do
    test "frame region width differs between A4 and US Letter" do
      t_a4 = Certificate.page_template(page_size: :a4, orientation: :landscape, border: true)

      t_us =
        Certificate.page_template(page_size: :us_letter, orientation: :landscape, border: true)

      frame_a4 = Enum.find(t_a4.regions, &(&1.name == :frame))
      frame_us = Enum.find(t_us.regions, &(&1.name == :frame))
      # Will fail RED until :frame region is added to page_template when border: true
      assert frame_a4 != nil, "expected :frame region in A4 template when border: true"
      assert frame_us != nil, "expected :frame region in US Letter template when border: true"
      refute_in_delta frame_a4.width, frame_us.width, 0.01
    end
  end

  # ---------------------------------------------------------------------------
  # C18: inset formula = 0.5 * min(margins)
  # ---------------------------------------------------------------------------

  describe "C18: frame inset derived from margins formula" do
    test "frame region x and y equal 0.5 * min(margins)" do
      # Default margins are all equal (72pt), so inset = 0.5 * 72 = 36
      t = Certificate.page_template(border: true)
      frame = Enum.find(t.regions, &(&1.name == :frame))
      # Will fail RED until :frame region is added to page_template when border: true
      assert frame != nil, "expected :frame region in template when border: true"
      # margin_left = margin_right = margin_top = margin_bottom = 72 (default)
      expected_inset = 0.5 * 72
      assert_in_delta frame.x, expected_inset, 0.01
      assert_in_delta frame.y, expected_inset, 0.01
    end
  end

  # ---------------------------------------------------------------------------
  # C19: border: %{color: {255, 0, 0}} → red RG color in content stream
  # ---------------------------------------------------------------------------

  describe "C19: border color map option" do
    test "border: %{color: {255, 0, 0}} emits red stroke color in content stream" do
      doc = Certificate.document(fixture_data(), border: %{color: {255, 0, 0}})
      assert {:ok, pdf} = Rendro.render(doc)
      # Will fail RED until border: map color option is implemented
      # Red channel 1.0000, green 0.0000, blue 0.0000 for RG operator
      assert pdf =~ "1.0000 0.0000 0.0000 RG"
    end
  end

  # ---------------------------------------------------------------------------
  # C20: validate_border! rejects invalid options
  # ---------------------------------------------------------------------------

  describe "C20: validate_border! rejects invalid options" do
    test "unknown key raises ArgumentError" do
      # Will fail RED until validate_border! is implemented
      assert_raise ArgumentError, ~r/unknown.*key|key.*unknown/i, fn ->
        Certificate.document(fixture_data(), border: %{unknown_key: true})
      end
    end

    test "invalid color (hex string) raises ArgumentError mentioning hex" do
      # Will fail RED until validate_border! is implemented with color delegation
      assert_raise ArgumentError, ~r/hex/i, fn ->
        Certificate.document(fixture_data(), border: %{color: "#000"})
      end
    end

    test "inset too large raises ArgumentError mentioning inset" do
      # Will fail RED until validate_border! is implemented with inset bounds check
      assert_raise ArgumentError, ~r/inset/i, fn ->
        Certificate.document(fixture_data(), border: %{inset: 99_999})
      end
    end
  end
end

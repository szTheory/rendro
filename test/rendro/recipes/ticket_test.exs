defmodule Rendro.Recipes.TicketTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket

  # 2x2 PNG -- reused verbatim from test/rendro/image_parser_test.exs, a
  # proven-valid fixture the codebase already trusts for ImageParser.parse/1
  # HEADER-ONLY validation (validate_data!/1's D-10 pre-check never fully
  # decodes pixel data, only the signature/IHDR chunk).
  @valid_png_bytes Base.decode64!(
                     "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVQIW2NkYGD4z8DAwMgAI0AMADjKAu09+3WTAAAAAElFTkSuQmCC"
                   )

  # A real, fully-decodable PNG (used by test/rendro/pipeline/render_test.exs
  # for the same reason) -- needed wherever a test actually renders a
  # document with an embedded image, since the writer's PDF.PNG chunk
  # decoder requires a genuinely well-formed IDAT stream that the minimal
  # @valid_png_bytes fixture above does not provide.
  @embeddable_png_path "priv/branded/images/rendro-logo.png"

  # ---------------------------------------------------------------------------
  # Test Fixture Helpers
  # ---------------------------------------------------------------------------

  # Fictional-only ticket fixture -- Aurora Live, the milestone's canonical
  # live-events fixture business (D-01). No code.image by default.
  defp fixture_data(opts \\ []) do
    overrides = Map.new(opts)

    base = %{
      issuer: %{name: "Aurora Live"},
      title: "Indie Night: The Lumen Set",
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ],
      code: %{reference: "AUR-88213-GA"}
    }

    Map.merge(base, overrides)
  end

  # ---------------------------------------------------------------------------
  # page_template/1 (D-03 geometry)
  # ---------------------------------------------------------------------------

  describe "page_template/1" do
    test "returns a %Rendro.PageTemplate{} with :main/:stub/:terms regions, correct role/anchor" do
      template = Ticket.page_template()
      assert %Rendro.PageTemplate{} = template

      by_name = Map.new(template.regions, &{&1.name, &1})

      assert %{anchor: :fixed} = by_name[:main]
      assert %{anchor: :fixed} = by_name[:stub]
      assert Map.has_key?(by_name, :terms)

      for region <- [by_name[:main], by_name[:stub], by_name[:terms]] do
        refute region.role in [:header, :footer, :sidebar]
      end

      assert by_name[:main].role == :custom
      assert by_name[:stub].role == :custom
    end

    test "page_size: :us_letter yields different geometry than the default" do
      default = Ticket.page_template()
      letter = Ticket.page_template(page_size: :us_letter)

      refute {default.width, default.height} == {letter.width, letter.height}
    end

    test "118-08: page_template() defaults to native A6 (SHOW-01 — no ~65% empty A4 canvas)" do
      template = Ticket.page_template()
      assert {template.width, template.height} == Rendro.PageSize.resolve(:a6, :portrait)
      # Sanity: A6 is far smaller than A4 in both dimensions.
      {a4_w, a4_h} = Rendro.PageSize.resolve(:a4, :portrait)
      assert template.width < a4_w
      assert template.height < a4_h
    end

    test "118-08: the :main region occupies most of the (now much smaller) page — seat-locator focal" do
      template = Ticket.page_template()
      main = Enum.find(template.regions, &(&1.name == :main))

      # main width is the D-03 @stub_ratio complement (0.68) of the band —
      # the placement grid gets the majority of the ticket band's width.
      assert main.width / template.width > 0.5
    end
  end

  # ---------------------------------------------------------------------------
  # validate_data!/1 (via Ticket.document/2) -- D-04/D-10 shape/type checks
  # ---------------------------------------------------------------------------

  describe "validate_data!/1 (D-04/D-10 shape/type checks)" do
    test "does NOT raise for a well-formed minimal payload with code.image: nil" do
      data = Map.put(fixture_data(), :code, %{reference: "AUR-1", image: nil})
      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "does NOT raise for the same payload with code.image omitted entirely" do
      data = fixture_data()
      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "does NOT raise for a valid PNG binary in code.image" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:binary, @valid_png_bytes}
        })

      assert %Rendro.Document{} = Ticket.document(data)
    end

    test "raises an instructive ArgumentError for missing :title" do
      data = fixture_data() |> Map.delete(:title)

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for empty :placement" do
      data = fixture_data(placement: [])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a 5-entry :placement (over the D-02 cap)" do
      placement = for i <- 1..5, do: %{label: "L#{i}", value: "V#{i}"}
      data = fixture_data(placement: placement)

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :placement entry missing :label" do
      data = fixture_data(placement: [%{value: "GA"}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :placement entry missing :value" do
      data = fixture_data(placement: [%{label: "Section"}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for missing code.reference" do
      data = Map.put(fixture_data(), :code, %{})

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a blank code.reference" do
      data = Map.put(fixture_data(), :code, %{reference: ""})

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for a :title exceeding its byte guard" do
      data = fixture_data(title: String.duplicate("x", 201))

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Ticket.document(data)
      end
    end

    test "raises an instructive ArgumentError for malformed code.image bytes, naming data.code.image, never leaking InvalidAssetError" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:binary, "not a real image"}
        })

      error =
        assert_raise ArgumentError, fn ->
          Ticket.document(data)
        end

      assert error.message =~ "data.code.image"
      refute error.message =~ "InvalidAssetError"
      assert error.message =~ ~r/What:.*Where:.*Why:.*Next:/s
    end
  end

  # ---------------------------------------------------------------------------
  # sections/2, document/2, D-02 placement-grid anchor (Task 2)
  # ---------------------------------------------------------------------------

  describe "sections/2 and document/2" do
    test "atomic equal-share profile preserves the real Aurora Section/GA through Gate/B association" do
      data =
        fixture_data(
          placement: [
            %{label: "Section", value: "GA"},
            %{label: "Row", value: "H"},
            %{label: "Seat", value: "24"},
            %{label: "Gate", value: "B"}
          ]
        )

      main =
        Ticket.sections(data,
          theme: Rendro.Theme.preset(:brutalist, accent: "#C78600", mode: :light),
          catalog_layout: true,
          presentation_profile: %{locator_layout: :atomic_equal_share}
        )
        |> Enum.find(&(&1.region == :main))

      [grid_block] = Enum.filter(main.content, &is_struct(&1.content, Rendro.Table))
      table = grid_block.content

      assert table.columns == List.duplicate({:share, 1}, 4)
      assert Enum.map(table.header, &cell_text/1) == ["SECTION", "ROW", "SEAT", "GATE"]
      assert [value_cells] = table.rows
      assert Enum.map(value_cells, &cell_text/1) == ["GA", "H", "24", "B"]
      assert Enum.all?(value_cells, &match?(%Rendro.Cell{split_policy: :atomic}, &1))
      refute Enum.any?(value_cells, &(cell_text(&1) == "24B"))
      assert Enum.all?(value_cells, &(cell_text(&1) in ["GA", "H", "24", "B"]))
      assert Enum.all?(value_cells, &(cell_size(&1) == 34))
    end

    test "sections/2 returns %Section{} structs including :main and :stub regions" do
      sections = Ticket.sections(fixture_data())
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))

      region_names = Enum.map(sections, & &1.region)
      assert :main in region_names
      assert :stub in region_names
    end

    test "document/2 renders {:ok, pdf} starting with the PDF magic bytes" do
      doc = Ticket.document(fixture_data())
      assert %Rendro.Document{} = doc

      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "the rendered PDF text stream contains every placement label and value" do
      doc = Ticket.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc)

      for %{label: label, value: value} <- fixture_data().placement do
        assert pdf =~ "(#{String.upcase(label)})"
        assert pdf =~ "(#{value})"
      end
    end

    test "the SAME recipe renders a boarding-pass-shaped anchor with zero lib/ changes (D-01)" do
      data =
        fixture_data(
          placement: [
            %{label: "Gate", value: "B12"},
            %{label: "Seat", value: "14C"},
            %{label: "Group", value: "2"}
          ]
        )

      doc = Ticket.document(data)
      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
      assert pdf =~ "(B12)"
      assert pdf =~ "(14C)"
    end

    test "a caller-supplied PNG registers under the fixed :ticket_code name" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:path, @embeddable_png_path}
        })

      doc = Ticket.document(data)
      assert {:ok, _asset} = Rendro.AssetRegistry.fetch(doc.asset_registry, :ticket_code)

      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "the placement-grid value cells (118-08: 26pt) are the single largest text in :main content (D-02)" do
      sections = Ticket.sections(fixture_data())
      main_section = Enum.find(sections, &(&1.region == :main))

      sizes = collect_text_sizes(main_section)
      assert Enum.max(sizes) == 26
    end
  end

  describe "themed hierarchy (POLISH-02)" do
    @genres [:swiss, :humanist, :editorial, :corporate_classic, :minimal_mono, :brutalist]

    test "every supplied default or preset theme keeps placement above title above reference" do
      themes =
        [
          {:default, Rendro.Theme.default()}
          | Enum.map(@genres, &{&1, Rendro.Theme.preset(&1, accent: "#2C6BED")})
        ]

      for {name, theme} <- themes do
        sections = Ticket.sections(fixture_data(), theme: theme, page_size: :a4)
        main = Enum.find(sections, &(&1.region == :main))
        stub = Enum.find(sections, &(&1.region == :stub))
        texts = Map.merge(text_sizes(main), text_sizes(stub))

        placement = Map.fetch!(texts, "GA")
        title = Map.fetch!(texts, "Indie Night: The Lumen Set")
        reference = Map.fetch!(texts, "AUR-88213-GA")

        assert placement > title and title > reference,
               "#{name} must keep placement > title > reference, got #{inspect({placement, title, reference})}"
      end
    end

    test "a caller typography override remains authoritative after themed role selection" do
      scale = %{display: 30, title: 20, subtitle: 15, body: 10, small: 9, caption: 8}

      sections =
        Ticket.sections(fixture_data(),
          theme: Rendro.Theme.default(),
          typography: %{scale: scale}
        )

      texts = Enum.reduce(sections, %{}, &Map.merge(&2, text_sizes(&1)))

      assert texts["GA"] == 30
      assert texts["Indie Night: The Lumen Set"] == 20
      assert texts["AUR-88213-GA"] == 8
    end

    test "Brutalist public themes bind the placement grid with a hard rule without changing catalog rank" do
      for mode <- [:light, :dark] do
        theme = Rendro.Theme.preset(:brutalist, accent: "#2C6BED", mode: mode)

        public_sections = Ticket.sections(fixture_data(), theme: theme)
        catalog_sections = Ticket.sections(fixture_data(), theme: theme, catalog_layout: true)

        public_main = Enum.find(public_sections, &(&1.region == :main))
        catalog_main = Enum.find(catalog_sections, &(&1.region == :main))

        public_sizes =
          Map.merge(
            text_sizes(public_main),
            public_sections |> Enum.find(&(&1.region == :stub)) |> text_sizes()
          )

        catalog_sizes =
          Map.merge(
            text_sizes(catalog_main),
            catalog_sections |> Enum.find(&(&1.region == :stub)) |> text_sizes()
          )

        assert public_sizes["GA"] > public_sizes["Indie Night: The Lumen Set"]
        assert public_sizes["Indie Night: The Lumen Set"] > public_sizes["AUR-88213-GA"]
        assert public_sizes == catalog_sizes

        assert Enum.any?(public_main.content, fn
                 %Rendro.Block{
                   content: %Rendro.Path{
                     ops: [{:move, 0, 0}, {:line, _width, 0}],
                     stroke: %{color: color, width: width}
                   }
                 } ->
                   color == theme.colors.rule and width == theme.rules.thick

                 _other ->
                   false
               end)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Stub composition: code box, reference, perforation, PNG fit-contain,
  # overflow, byte-identity (Task 3)
  # ---------------------------------------------------------------------------

  describe "stub_section/2 — code box, reference, perforation (D-05/D-06/D-07/D-09)" do
    test "no-image: PDF text stream contains the upper-cased reference and the reference caption" do
      doc = Ticket.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc)

      assert pdf =~ "(AUR-88213-GA)"
      assert pdf =~ "(Reference)"
    end

    test "no-image: the stub region's Path ops are exactly the perforation line + the one code-box rounded_rect (no faux barcode, D-07)" do
      sections = Ticket.sections(fixture_data())
      stub_section = Enum.find(sections, &(&1.region == :stub))

      path_blocks =
        Enum.filter(stub_section.content, &match?(%Rendro.Block{content: %Rendro.Path{}}, &1))

      assert length(path_blocks) == 2

      all_ops = Enum.flat_map(path_blocks, fn %{content: %Rendro.Path{ops: ops}} -> ops end)

      rounded_rects = Enum.filter(all_ops, &match?({:rounded_rect, _, _, _, _, _}, &1))
      assert length(rounded_rects) == 1

      # No additional {:rect, ...} ops -- would signal a hand-drawn faux
      # barcode/QR stripe pattern rather than the single bordered code box.
      refute Enum.any?(all_ops, &match?({:rect, _, _, _, _}, &1))
    end

    test "code box is >= 60x60pt (square) at the 118-08 A6-default geometry (D-05), derived not hardcoded" do
      sections = Ticket.sections(fixture_data())
      stub_section = Enum.find(sections, &(&1.region == :stub))

      [{:rounded_rect, _x, _y, w, h, _radius}] =
        stub_section.content
        |> Enum.flat_map(fn
          %Rendro.Block{content: %Rendro.Path{ops: ops}} -> ops
          _other -> []
        end)
        |> Enum.filter(&match?({:rounded_rect, _, _, _, _, _}, &1))

      assert w >= 60
      assert h >= 60
      assert_in_delta w, h, 0.01
    end

    test "code box size differs between A6 (default) and A4 geometry (derived, not hardcoded)" do
      a6_sections = Ticket.sections(fixture_data())
      a4_sections = Ticket.sections(fixture_data(), page_size: :a4)

      box_side = fn sections ->
        stub = Enum.find(sections, &(&1.region == :stub))

        [{:rounded_rect, _x, _y, w, _h, _radius}] =
          stub.content
          |> Enum.flat_map(fn
            %Rendro.Block{content: %Rendro.Path{ops: ops}} -> ops
            _other -> []
          end)
          |> Enum.filter(&match?({:rounded_rect, _, _, _, _, _}, &1))

        w
      end

      refute_in_delta box_side.(a6_sections), box_side.(a4_sections), 0.01
    end

    test "PNG-supplied: code.reference STILL appears in the text stream (D-06 always-on)" do
      data =
        Map.put(fixture_data(), :code, %{
          reference: "AUR-1",
          image: {:path, @embeddable_png_path}
        })

      doc = Ticket.document(data)
      assert {:ok, pdf} = Rendro.render(doc)
      assert pdf =~ "(AUR-1)"
    end

    test "code.image: nil is byte-identical to code.image omitted (D-08)" do
      data_with_nil = Map.put(fixture_data(), :code, %{reference: "AUR-88213-GA", image: nil})
      data_omitted = fixture_data()

      doc_with_nil = Ticket.document(data_with_nil)
      doc_omitted = Ticket.document(data_omitted)

      assert {:ok, pdf_with_nil} = Rendro.render(doc_with_nil, deterministic: true)
      assert {:ok, pdf_omitted} = Rendro.render(doc_omitted, deterministic: true)

      assert pdf_with_nil == pdf_omitted
    end

    test "a placement value that cannot fit the grid table's narrow column at 22pt raises :content_overflow, never a crash" do
      data =
        fixture_data(
          placement: [
            %{label: "Section", value: String.duplicate("X", 40)},
            %{label: "Row", value: "H"},
            %{label: "Seat", value: "24"}
          ]
        )

      doc = Ticket.document(data)

      assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
      assert error.stage == :paginate
      assert error.reason == :content_overflow
    end

    test "two deterministic renders of the same fixture are byte-identical" do
      doc = Ticket.document(fixture_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # Recursive %Rendro.Text{} size collector — a table's header/rows/cells may
  # wrap Rendro.Block/Rendro.Cell content, or be plain (unmeasured) strings,
  # per lib/rendro/pipeline/measure.ex's normalize_cells/1. Mirrors the
  # collector established in test/rendro/recipes/payslip_test.exs.
  # ---------------------------------------------------------------------------

  defp collect_text_sizes(%Rendro.Section{content: content}) do
    Enum.flat_map(content, &collect_from_block/1)
  end

  defp collect_from_block(%Rendro.Block{content: %Rendro.Text{size: size}}), do: [size]

  defp collect_from_block(%Rendro.Block{content: %Rendro.Table{} = table}) do
    collect_from_table(table)
  end

  defp collect_from_block(_other), do: []

  defp collect_from_table(table) do
    header_sizes = if table.header, do: collect_from_row(table.header), else: []
    row_sizes = Enum.flat_map(table.rows, &collect_from_row/1)
    header_sizes ++ row_sizes
  end

  defp collect_from_row(%Rendro.Row{cells: cells}), do: Enum.flat_map(cells, &collect_from_cell/1)
  defp collect_from_row(cells) when is_list(cells), do: Enum.flat_map(cells, &collect_from_cell/1)

  defp collect_from_cell(%Rendro.Cell{content: content}), do: collect_from_cell_content(content)
  defp collect_from_cell(content), do: collect_from_cell_content(content)

  defp collect_from_cell_content(%Rendro.Block{} = block), do: collect_from_block(block)
  defp collect_from_cell_content(%Rendro.Text{size: size}), do: [size]
  defp collect_from_cell_content(_other), do: []

  defp cell_text(%Rendro.Block{content: %Rendro.Text{content: content}}), do: content
  defp cell_text(%Rendro.Text{content: content}), do: content
  defp cell_text(%Rendro.Cell{content: content}), do: cell_text(content)

  defp cell_size(%Rendro.Block{content: %Rendro.Text{size: size}}), do: size
  defp cell_size(%Rendro.Text{size: size}), do: size
  defp cell_size(%Rendro.Cell{content: content}), do: cell_size(content)

  defp text_sizes(%Rendro.Section{content: content}) do
    content
    |> Enum.flat_map(&texts_from_block/1)
    |> Map.new()
  end

  defp texts_from_block(%Rendro.Block{content: %Rendro.Text{content: content, size: size}}),
    do: [{content, size}]

  defp texts_from_block(%Rendro.Block{content: %Rendro.Table{} = table}) do
    ((table.header || []) ++ List.flatten(table.rows))
    |> Enum.flat_map(fn
      %Rendro.Block{} = block -> texts_from_block(block)
      _ -> []
    end)
  end

  defp texts_from_block(_other), do: []
end

defmodule Rendro.Recipes.TicketTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket

  # 2x2 PNG -- reused verbatim from test/rendro/image_parser_test.exs, a
  # proven-valid fixture the codebase already trusts for ImageParser.parse/1.
  @valid_png_bytes Base.decode64!(
                      "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVQIW2NkYGD4z8DAwMgAI0AMADjKAu09+3WTAAAAAElFTkSuQmCC"
                    )

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

    test "page_size: :us_letter yields different geometry than the :a4 default" do
      a4 = Ticket.page_template()
      letter = Ticket.page_template(page_size: :us_letter)

      refute {a4.width, a4.height} == {letter.width, letter.height}
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
          image: {:binary, @valid_png_bytes}
        })

      doc = Ticket.document(data)
      assert {:ok, _asset} = Rendro.AssetRegistry.fetch(doc.asset_registry, :ticket_code)

      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "the placement-grid value cells (22pt) are the single largest text in :main content (D-02)" do
      sections = Ticket.sections(fixture_data())
      main_section = Enum.find(sections, &(&1.region == :main))

      sizes = collect_text_sizes(main_section)
      assert Enum.max(sizes) == 22
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
end

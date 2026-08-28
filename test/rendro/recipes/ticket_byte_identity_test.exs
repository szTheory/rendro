defmodule Rendro.Recipes.TicketByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket
  alias Rendro.Theme.Presets

  # Frozen golden, computed by actually running a render on pristine (fully
  # implemented) `ticket.ex` via `mix run` -- never hand-typed. A fresh
  # render of the SAME fixed, deterministic fixture must keep hashing to
  # this exact value. Changing this hash is a defect, not a golden-file
  # refresh, unless a human explicitly re-authorizes a new baseline.
  #
  # 118-08 gap-closure (SHOW-01): re-blessed after switching the ticket's
  # default page size from A4 to its native A6 (with A6-appropriate margins,
  # re-tuned stub text sizes, and a taller @band_ratio so a realistic full
  # ticket's main-region content fits) — an authorized, reviewed geometry
  # change, not drift.
  @toy_golden_sha256 "4697ac9340c1677320de14eed1d9d9e7c4d2a48ae0264cc7538cbfd1192eb2bf"

  # Fixed, deterministic minimal fixture (no anatomy variance) -- Aurora
  # Live, one 3-cell placement grid, no image, no subtitle/terms -- so the
  # golden hash exercises the frozen happy path exactly.
  defp fixture_data do
    %{
      issuer: %{name: "Aurora Live"},
      title: "Indie Night: The Lumen Set",
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ],
      code: %{reference: "AUR-88213-GA"}
    }
  end

  describe "D-08/D-09 byte-identity baseline" do
    test "two deterministic renders are byte-identical" do
      doc = Ticket.document(fixture_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen golden" do
      doc = Ticket.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "ticket render drifted from the frozen byte-identity baseline. " <>
               "If this drift is an intentional, human-approved change, " <>
               "recompute @toy_golden_sha256 and update it deliberately."
    end
  end

  describe "D-08: code.image nil vs omitted byte-identity" do
    test "code.image: nil and code.image omitted produce byte-identical output" do
      data_with_nil = Map.put(fixture_data(), :code, %{reference: "AUR-88213-GA", image: nil})
      data_omitted = fixture_data()

      doc_with_nil = Ticket.document(data_with_nil)
      doc_omitted = Ticket.document(data_omitted)

      assert {:ok, pdf_with_nil} = Rendro.render(doc_with_nil, deterministic: true)
      assert {:ok, pdf_omitted} = Rendro.render(doc_omitted, deterministic: true)

      assert pdf_with_nil == pdf_omitted
    end
  end

  describe "136-04 target profile geometry and determinism" do
    test "light and dark atomic locator profiles retain identical geometry and deterministic bytes" do
      profile = [
        catalog_layout: true,
        presentation_profile: %{locator_layout: :atomic_equal_share}
      ]

      data =
        Map.merge(fixture_data(), %{
          placement: [
            %{label: "Section", value: "GA"},
            %{label: "Row", value: "H"},
            %{label: "Seat", value: "24"},
            %{label: "Gate", value: "B"}
          ],
          subtitle: "Doors 7:00 PM - Show 8:00 PM - Saturday 27 June 2026",
          terms: "Non-transferable. Present this reference at the gate for scanning."
        })

      light = Rendro.Theme.preset(:brutalist, accent: "#C78600", mode: :light)
      dark = Rendro.Theme.preset(:brutalist, accent: "#C78600", mode: :dark)

      light_doc = Ticket.document(data, [theme: light] ++ profile)
      dark_doc = Ticket.document(data, [theme: dark] ++ profile)

      assert locator_geometry(light_doc) == locator_geometry(dark_doc)

      for doc <- [light_doc, dark_doc] do
        doc = Presets.register_fonts(doc, :brutalist)
        assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
        assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
        assert pdf1 == pdf2
      end
    end
  end

  describe "136-10 held-out prose boundaries" do
    test "long Ticket subtitle, terms, and reference wrap without disturbing the locator contract" do
      light = Rendro.Theme.preset(:brutalist, accent: "#C78600", mode: :light)
      dark = Rendro.Theme.preset(:brutalist, accent: "#C78600", mode: :dark)

      cases = [
        %{name: :empty, subtitle: "", terms: "", reference: repeat("REF", 3), lines: {0, 0, 1}},
        %{
          name: :exact_fit,
          subtitle: repeat("subtitle", 4),
          terms: repeat("terms", 11),
          reference: repeat("REF", 3),
          lines: {1, 1, 1}
        },
        %{
          name: :one_step_over,
          subtitle: repeat("subtitle", 5),
          terms: repeat("terms", 12),
          reference: repeat("REF", 4),
          lines: {2, 2, 2}
        },
        %{
          name: :multiline,
          subtitle: repeat("subtitle", 9),
          terms: repeat("terms", 16),
          reference: repeat("REF", 7),
          lines: {3, 2, 3}
        }
      ]

      for scenario <- cases, theme <- [light, dark] do
        data = held_out_data(scenario)
        document = profiled_document(data, theme)

        assert_locator_contract(document)

        assert {:ok, first_pdf, final_document} =
                 Rendro.render_with_diagnostics(document, deterministic: true)

        assert {:ok, second_pdf} = Rendro.render(document, deterministic: true)
        assert first_pdf == second_pdf, "#{scenario.name} must render deterministically"

        expected_prose =
          ["Aurora Live", "Indie Night"] ++
            present(scenario.subtitle) ++
            ["Reference", String.upcase(scenario.reference), "Present this reference at entry."] ++
            present(scenario.terms)

        assert measured_prose(final_document) == expected_prose

        assert prose_line_count(final_document, scenario.subtitle) == elem(scenario.lines, 0)
        assert prose_line_count(final_document, scenario.terms) == elem(scenario.lines, 1)

        assert prose_line_count(final_document, String.upcase(scenario.reference)) ==
                 elem(scenario.lines, 2)

        assert_prose_containment(final_document)
        assert_rendered_locator(final_document)
      end

      for scenario <- cases do
        light_document = profiled_document(held_out_data(scenario), light)
        dark_document = profiled_document(held_out_data(scenario), dark)
        assert locator_geometry(light_document) == locator_geometry(dark_document)

        assert {:ok, _light_pdf, light_final} =
                 Rendro.render_with_diagnostics(light_document, deterministic: true)

        assert {:ok, _dark_pdf, dark_final} =
                 Rendro.render_with_diagnostics(dark_document, deterministic: true)

        assert rendered_locator_geometry(light_final) == rendered_locator_geometry(dark_final)
      end

      empty = hd(cases)
      omitted = held_out_data(%{empty | subtitle: nil, terms: nil})

      assert locator_geometry(profiled_document(held_out_data(empty), light)) ==
               locator_geometry(profiled_document(omitted, light))

      assert {:ok, _empty_pdf, empty_final} =
               Rendro.render_with_diagnostics(
                 profiled_document(held_out_data(empty), light),
                 deterministic: true
               )

      assert {:ok, _omitted_pdf, omitted_final} =
               Rendro.render_with_diagnostics(
                 profiled_document(omitted, light),
                 deterministic: true
               )

      assert rendered_locator_geometry(empty_final) ==
               rendered_locator_geometry(omitted_final)

      default_document = Ticket.document(fixture_data())
      assert {:ok, default_pdf} = Rendro.render(default_document, deterministic: true)
      assert {:ok, repeated_default_pdf} = Rendro.render(default_document, deterministic: true)
      assert default_pdf == repeated_default_pdf
      assert Base.encode16(:crypto.hash(:sha256, default_pdf), case: :lower) == @toy_golden_sha256
    end
  end

  defp held_out_data(scenario) do
    Map.merge(fixture_data(), %{
      title: "Indie Night",
      subtitle: scenario.subtitle,
      terms: scenario.terms,
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"},
        %{label: "Gate", value: "B"}
      ],
      code: %{reference: scenario.reference}
    })
  end

  defp profiled_document(data, theme) do
    data
    |> Ticket.document(
      theme: theme,
      catalog_layout: true,
      presentation_profile: %{locator_layout: :atomic_equal_share}
    )
    |> Presets.register_fonts(:brutalist)
  end

  defp assert_locator_contract(document) do
    main = Enum.find(document.sections, &(&1.region == :main))
    [grid_block] = Enum.filter(main.content, &is_struct(&1.content, Rendro.Table))
    table = grid_block.content

    assert table.columns == List.duplicate({:share, 1}, 4)
    assert length(table.rows) == 1
    assert Enum.map(table.header, &text_content/1) == ["SECTION", "ROW", "SEAT", "GATE"]
    assert table.rows |> hd() |> Enum.map(&text_content/1) == ["GA", "H", "24", "B"]

    assert Enum.all?(table.header ++ hd(table.rows), fn cell ->
             match?(%Rendro.Cell{split_policy: :atomic}, cell)
           end)
  end

  defp assert_rendered_locator(final_document) do
    [table] =
      final_document.pages
      |> Enum.flat_map(& &1.blocks)
      |> Enum.flat_map(fn
        %Rendro.Block{content: %Rendro.Table{} = table} -> [table]
        _other -> []
      end)

    assert length(table.rows) == 1
    assert Enum.uniq_by(table.column_widths, &Float.round(&1, 4)) |> length() == 1

    assert Enum.map(table.header.cells, &measured_cell/1) == [
             {"SECTION", 1},
             {"ROW", 1},
             {"SEAT", 1},
             {"GATE", 1}
           ]

    assert table.rows |> hd() |> Map.fetch!(:cells) |> Enum.map(&measured_cell/1) ==
             [{"GA", 1}, {"H", 1}, {"24", 1}, {"B", 1}]
  end

  defp measured_cell(%Rendro.Cell{
         split_policy: :atomic,
         content: %Rendro.Block{
           content: %Rendro.Pipeline.MeasuredText{source: %{content: source}, lines: lines}
         }
       }) do
    {source, length(lines)}
  end

  defp measured_prose(final_document) do
    final_document.pages
    |> Enum.flat_map(& &1.blocks)
    |> Enum.flat_map(fn
      %Rendro.Block{content: %Rendro.Pipeline.MeasuredText{source: %{content: source}}} ->
        [source]

      _other ->
        []
    end)
  end

  defp rendered_locator_geometry(final_document) do
    [block] =
      final_document.pages
      |> Enum.flat_map(& &1.blocks)
      |> Enum.filter(&match?(%Rendro.Block{content: %Rendro.Table{}}, &1))

    table = block.content

    {block.x, block.y, block.width, block.height, table.column_widths, table.header_height,
     table.row_heights, Enum.map(table.header.cells, &cell_geometry/1),
     table.rows |> hd() |> Map.fetch!(:cells) |> Enum.map(&cell_geometry/1)}
  end

  defp cell_geometry(cell), do: {cell.x, cell.y, cell.width, cell.height}

  defp prose_line_count(_final_document, prose) when prose in [nil, ""], do: 0

  defp prose_line_count(final_document, prose) do
    final_document.pages
    |> Enum.flat_map(& &1.blocks)
    |> Enum.find_value(fn
      %Rendro.Block{
        content: %Rendro.Pipeline.MeasuredText{source: %{content: ^prose}, lines: lines}
      } ->
        length(lines)

      _other ->
        nil
    end)
  end

  defp assert_prose_containment(final_document) do
    template =
      Enum.find(final_document.page_templates, &(&1.name == final_document.page_template))

    final_document.pages
    |> Enum.flat_map(& &1.blocks)
    |> Enum.filter(&match?(%Rendro.Block{content: %Rendro.Pipeline.MeasuredText{}}, &1))
    |> Enum.each(fn block ->
      assert block.x >= 0
      assert block.y >= 0
      assert block.x + block.width <= template.width
      assert block.y + block.height <= template.height
    end)
  end

  defp repeat(word, count), do: Enum.map_join(1..count, " ", fn _ -> word end)
  defp present(value) when value in [nil, ""], do: []
  defp present(value), do: [value]

  defp locator_geometry(doc) do
    main = Enum.find(doc.sections, &(&1.region == :main))
    terms = Enum.find(doc.sections, &(&1.region == :terms))

    [grid_block] = Enum.filter(main.content, &is_struct(&1.content, Rendro.Table))
    table = grid_block.content

    {doc.page_template, table.columns, Enum.map(table.header, &text_content/1),
     table.rows |> Enum.map(fn row -> Enum.map(row, &text_content/1) end),
     Enum.map(terms.content, &text_content/1)}
  end

  defp text_content(%Rendro.Cell{content: content}), do: text_content(content)
  defp text_content(%Rendro.Block{content: content}), do: text_content(content)
  defp text_content(%Rendro.Text{content: content}), do: content
  defp text_content(_other), do: nil
end

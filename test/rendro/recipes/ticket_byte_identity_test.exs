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

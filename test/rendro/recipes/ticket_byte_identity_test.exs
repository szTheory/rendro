defmodule Rendro.Recipes.TicketByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket

  # Frozen golden, computed by actually running a render on pristine (fully
  # implemented) `ticket.ex` via `mix run` -- never hand-typed. A fresh
  # render of the SAME fixed, deterministic fixture must keep hashing to
  # this exact value. Changing this hash is a defect, not a golden-file
  # refresh, unless a human explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "97643571d8f29f3e389bf35a25718b804a6e302491529dc6928cd540fb172d95"

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
end

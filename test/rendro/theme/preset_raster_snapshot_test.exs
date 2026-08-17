defmodule Rendro.Theme.PresetRasterSnapshotTest do
  use ExUnit.Case, async: false

  alias Rendro.Adapters.Pdfium
  alias Rendro.Recipes.{Certificate, Invoice, Payslip, Receipt, Ticket}
  alias Rendro.Theme.Presets

  @review_dir_env "RENDRO_PRESET_RASTER_REVIEW_DIR"
  @rows [
    {:swiss_invoice_light, :swiss, :light, :invoice},
    {:swiss_certificate_dark, :swiss, :dark, :certificate},
    {:humanist_receipt_light, :humanist, :light, :receipt},
    {:humanist_payslip_dark, :humanist, :dark, :payslip},
    {:editorial_certificate_light, :editorial, :light, :certificate},
    {:editorial_ticket_dark, :editorial, :dark, :ticket}
  ]

  @tag raster_snapshot: true
  test "first three genre pairs render through pinned PDFium to committed page-one hashes" do
    assert_pinned_pdfium!()

    for {id, genre, mode, recipe} <- @rows do
      theme = Rendro.Theme.preset(genre, accent: "#2C6BED", mode: mode)
      document = recipe |> document_for(theme) |> Presets.register_fonts(genre)

      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert {:ok, [png]} = Pdfium.render(pdf, dpi: 150, pages: "1")

      write_review_png(id, png)
      assert_page_one_hash(genre, mode, png)
    end
  end

  defp assert_pinned_pdfium! do
    pin = File.read!("priv/pdfium_pin.json") |> JSON.decode!()

    assert {:ok, version} = Pdfium.version()
    assert version == pin["version"], "raster snapshots require the project-pinned PDFium version"
  end

  defp assert_page_one_hash(genre, mode, png) do
    expected_hash =
      Path.join(["priv", "raster_refs", "presets", Atom.to_string(genre), "#{mode}.sha256"])
      |> File.read!()
      |> String.trim()

    actual_hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)

    assert actual_hash == expected_hash,
           "pinned PDFium page-one hash mismatch for #{genre}/#{mode}; review the advisory raster in the bounded caller-provided directory before updating the reference"
  end

  defp write_review_png(id, png) do
    case System.get_env(@review_dir_env) do
      nil ->
        :ok

      "" ->
        :ok

      directory ->
        expanded_directory = Path.expand(directory)
        project_root = File.cwd!() |> Path.expand()

        if expanded_directory == project_root or
             String.starts_with?(expanded_directory, project_root <> "/") do
          raise ArgumentError,
                "#{@review_dir_env} must point outside the repository so generated rasters stay untracked"
        end

        File.mkdir_p!(expanded_directory)
        File.write!(Path.join(expanded_directory, "#{id}_page_1.png"), png)
    end
  end

  defp document_for(:invoice, theme) do
    Invoice.document(
      %{
        id: "INV-MATRIX-001",
        date: ~D[2026-08-16],
        items: [%{name: "Layout audit", qty: 1, price: 250}]
      },
      theme: theme,
      header_height: 90
    )
  end

  defp document_for(:certificate, theme) do
    Certificate.document(
      %{
        title: "Certificate of Completion",
        recipient: "Jane Smith",
        date: ~D[2026-08-16],
        body: "For outstanding achievement and dedication.",
        seal_line: "Awarded 2026"
      },
      theme: theme
    )
  end

  defp document_for(:receipt, theme) do
    Receipt.document(
      %{
        title: "Payment Receipt",
        date: ~D[2026-08-16],
        customer: %{name: "Acme Corp"},
        lines: [%{description: "Layout audit", amount: Decimal.new("250.00")}],
        totals: %{subtotal: Decimal.new("250.00"), total: Decimal.new("250.00")}
      },
      theme: theme
    )
  end

  defp document_for(:payslip, theme) do
    Payslip.document(
      %{
        employer: %{name: "Aurora Textiles Co."},
        employee: %{name: "Jordan Rivera", id: "E-4821", tax_code: "1257L"},
        period: %{from: ~D[2026-07-01], to: ~D[2026-07-31]},
        pay_date: ~D[2026-08-05],
        earnings: [
          %{
            description: "Base Salary",
            amount: Decimal.new("4200.00"),
            ytd: Decimal.new("25200.00")
          }
        ],
        deductions: [
          %{
            description: "Federal Income Tax",
            amount: Decimal.new("620.00"),
            ytd: Decimal.new("3720.00")
          }
        ],
        net_pay: Decimal.new("3580.00"),
        payment_method: "Direct Deposit 4321"
      },
      theme: theme
    )
  end

  defp document_for(:ticket, theme) do
    Ticket.document(
      %{
        issuer: %{name: "Aurora Live"},
        title: "Indie Night: The Lumen Set",
        placement: [
          %{label: "Section", value: "GA"},
          %{label: "Row", value: "H"},
          %{label: "Seat", value: "24"}
        ],
        code: %{reference: "AUR-88213-GA"}
      },
      theme: theme,
      page_size: :a4
    )
  end
end
